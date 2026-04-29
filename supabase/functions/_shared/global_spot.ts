// Global spot price fetchers — mirrors Dart MetalsDevService and MetalPriceApiService
import type { GlobalSpotScrapeResult } from './types.ts';

// ── Metals.dev ────────────────────────────────────────────────────────────────

export async function fetchMetalsDev(apiKey: string): Promise<GlobalSpotScrapeResult> {
  const url = `https://api.metals.dev/v1/latest?api_key=${encodeURIComponent(apiKey)}&currency=AUD&unit=toz`;

  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    const body = await response.json() as Record<string, unknown>;

    if (body['status'] !== 'success') {
      const code = String(body['error_code'] ?? '');
      const msg = METALS_DEV_ERRORS[code] ?? String(body['error_message'] ?? `Unknown error (code ${code})`);
      return { displayName: 'Metals.dev', prices: {}, errorMessage: msg };
    }

    const metals = (body['metals'] as Record<string, number>) ?? {};
    const prices: Record<string, number> = {};
    if (metals['gold'] != null) prices['gold'] = Number(metals['gold']);
    if (metals['silver'] != null) prices['silver'] = Number(metals['silver']);
    if (metals['platinum'] != null) prices['platinum'] = Number(metals['platinum']);

    return { displayName: 'Metals.dev', prices };
  } catch (e) {
    return { displayName: 'Metals.dev', prices: {}, errorMessage: `Network error: ${e}` };
  }
}

const METALS_DEV_ERRORS: Record<string, string> = {
  '1101': 'The API key provided is invalid.',
  '1201': 'The plan is not active due to failed payments.',
  '1202': 'The account is not active or disabled.',
  '1203': 'Monthly quota (including grace usage) exceeded.',
  '2101': 'Unsupported input parameter.',
  '2102': 'Mandatory input parameters missing.',
  '2103': 'Unsupported currency code.',
};

// ── Metal Price API ───────────────────────────────────────────────────────────

export async function fetchMetalPriceApi(apiKey: string): Promise<GlobalSpotScrapeResult> {
  const url = `https://api.metalpriceapi.com/v1/latest?api_key=${encodeURIComponent(apiKey)}&base=AUD&currencies=XAU,XAG,XPT`;

  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    const body = await response.json() as Record<string, unknown>;

    if (body['success'] !== true) {
      const error = body['error'] as Record<string, unknown> | undefined;
      const code = String(error?.['code'] ?? '');
      const msg = METAL_PRICE_API_ERRORS[code] ?? String(error?.['info'] ?? `Unknown error (code ${code})`);
      return { displayName: 'Metal Price API', prices: {}, errorMessage: msg };
    }

    const rates = (body['rates'] as Record<string, number>) ?? {};
    const prices: Record<string, number> = {};

    // Metal Price API returns rates as AUDXAU, AUDXAG, AUDXPT
    if (rates['AUDXAU'] != null) prices['gold'] = Number(rates['AUDXAU']);
    else if (rates['XAU'] != null) prices['gold'] = Number(rates['XAU']);

    if (rates['AUDXAG'] != null) prices['silver'] = Number(rates['AUDXAG']);
    else if (rates['XAG'] != null) prices['silver'] = Number(rates['XAG']);

    if (rates['AUDXPT'] != null) prices['platinum'] = Number(rates['AUDXPT']);
    else if (rates['XPT'] != null) prices['platinum'] = Number(rates['XPT']);

    return { displayName: 'Metal Price API', prices };
  } catch (e) {
    return { displayName: 'Metal Price API', prices: {}, errorMessage: `Network error: ${e}` };
  }
}

const METAL_PRICE_API_ERRORS: Record<string, string> = {
  '101': 'No API key was supplied.',
  '102': 'Account is inactive.',
  '104': 'Monthly API request limit has been reached.',
  '201': 'Invalid base currency.',
  '202': 'Invalid currency codes.',
  '701': 'Too many requests.',
  '800': 'Internal API error.',
  '900': 'Service temporarily unavailable.',
};

// ── Dispatcher ────────────────────────────────────────────────────────────────

// Normalises a provider key — lowercases and strips non-alphanumeric.
// Mirrors GlobalSpotPriceServiceFactory._normalise() in Flutter so that
// keys stored as 'metals_dev', 'MetalsDev', or 'metalsdev' all resolve correctly.
function normaliseKey(key: string): string {
  return key.toLowerCase().replace(/[^a-z0-9]/g, '');
}

export async function fetchGlobalSpot(
  providerKey: string,
  apiKey: string,
): Promise<GlobalSpotScrapeResult> {
  switch (normaliseKey(providerKey)) {
    case 'metalsdev':
      return fetchMetalsDev(apiKey);
    case 'metalpriceapi':
      return fetchMetalPriceApi(apiKey);
    default:
      return {
        displayName: providerKey,
        prices: {},
        errorMessage: `Unknown provider key: "${providerKey}"`,
      };
  }
}
