// Local spot price scrapers — mirrors Dart GbaLocalSpotService, GsLocalSpotService, ImpLocalSpotService
import { parse } from 'npm:node-html-parser';
import { fetchHtml, fetchHtmlPost, parsePrice } from './scraper_base.ts';
import type { LocalSpotScrapeResult, ScraperSetting } from './types.ts';

// ── GBA ──────────────────────────────────────────────────────────────────────
// Gold + Silver: AJAX JSON endpoint
// Platinum: HTML CSS class selector

const GBA_AJAX_URL =
  'https://www.goldbullionaustralia.com.au/wp-admin/admin-ajax.php?action=get_live_price_update';
const GBA_BASE_URL = 'https://www.goldbullionaustralia.com.au';

export async function scrapeGbaLocalSpot(
  settings: ScraperSetting[],
): Promise<LocalSpotScrapeResult> {
  const result: Record<string, number> = {};
  const errors: string[] = [];

  const goldSetting = settings.find((s) => s.metal_type === 'gold');
  const silverSetting = settings.find((s) => s.metal_type === 'silver');
  const platSetting = settings.find((s) => s.metal_type === 'platinum');

  // Gold + Silver via AJAX JSON
  if (goldSetting || silverSetting) {
    try {
      const body = await fetchHtml(GBA_AJAX_URL);
      const json = JSON.parse(body) as Record<string, string>;

      if (goldSetting) {
        const raw = json['gold'];
        if (raw) {
          const price = parseFloat(raw.replace(/,/g, ''));
          if (!isNaN(price) && price > 0) result['gold'] = price;
        }
      }
      if (silverSetting) {
        const raw = json['silver'];
        if (raw) {
          const price = parseFloat(raw.replace(/,/g, ''));
          if (!isNaN(price) && price > 0) result['silver'] = price;
        }
      }
    } catch (e) {
      errors.push(`GBA AJAX error: ${e}`);
    }
  }

  // Platinum via HTML CSS class
  if (platSetting) {
    const fetchUrl = platSetting.search_url ?? GBA_BASE_URL;
    try {
      const html = await fetchHtml(fetchUrl);
      const doc = parse(html);
      const el = doc.querySelector(`[class~="${platSetting.search_string}"]`);
      if (el) {
        const price = parsePrice(el.text);
        if (price > 0) result['platinum'] = price;
        else errors.push(`GBA: platinum element found but price is zero`);
      } else {
        errors.push(`GBA: no element with class "${platSetting.search_string}"`);
      }
    } catch (e) {
      errors.push(`GBA HTML error for platinum: ${e}`);
    }
  }

  return { prices: result, errors };
}

// ── GS ───────────────────────────────────────────────────────────────────────
// POST to admin-ajax.php with action=update_prices — returns JSON with all metals

const GS_AJAX_URL = 'https://goldsecure.com.au/wp-admin/admin-ajax.php';

const GS_LOCAL_SPOT_HEADERS: Record<string, string> = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
  'X-Requested-With': 'XMLHttpRequest',
  'Origin': 'https://goldsecure.com.au',
  'Referer': 'https://goldsecure.com.au/live-price/',
  'Accept': 'application/json, text/javascript, */*; q=0.01',
  'Accept-Language': 'en-US,en;q=0.9',
};

export async function scrapeGsLocalSpot(
  settings: ScraperSetting[],
): Promise<LocalSpotScrapeResult> {
  const result: Record<string, number> = {};
  const errors: string[] = [];

  try {
    const body = await fetchHtmlPost(
      GS_AJAX_URL,
      { action: 'update_prices', currency_name: 'aud' },
      GS_LOCAL_SPOT_HEADERS,
    );

    const json = JSON.parse(body) as { success: boolean; data: Record<string, string> };
    if (json.success !== true) {
      throw new Error(`GS update_prices returned success=false`);
    }

    const data = json.data;

    for (const s of settings) {
      if (!s.metal_type) continue;
      const key = (s.search_string || s.metal_type).toLowerCase();
      const raw = data[key];
      if (raw == null) {
        errors.push(`GS: key "${key}" not found in response`);
        continue;
      }
      const price = parseFloat(raw.replace(/,/g, ''));
      if (!isNaN(price) && price > 0) {
        result[s.metal_type] = price;
      } else {
        errors.push(`GS: ${s.metal_type} price is zero or invalid`);
      }
    }
  } catch (e) {
    errors.push(`GS fatal error: ${e}`);
  }

  return { prices: result, errors };
}

// ── IMP ──────────────────────────────────────────────────────────────────────
// GET page, find element by CSS class word [class~="word"]

export async function scrapeImpLocalSpot(
  settings: ScraperSetting[],
): Promise<LocalSpotScrapeResult> {
  const result: Record<string, number> = {};
  const errors: string[] = [];

  // Group settings by URL to fetch each page only once
  const byUrl = new Map<string, ScraperSetting[]>();
  for (const s of settings) {
    const url = s.search_url ?? 'https://www.imperialbullion.com.au';
    const group = byUrl.get(url) ?? [];
    group.push(s);
    byUrl.set(url, group);
  }

  for (const [url, group] of byUrl) {
    try {
      const html = await fetchHtml(url);
      const doc = parse(html);

      for (const s of group) {
        if (!s.metal_type) continue;
        const el = doc.querySelector(`[class~="${s.search_string}"]`);
        if (!el) {
          errors.push(`IMP: no element with class "${s.search_string}"`);
          continue;
        }
        const price = parsePrice(el.text);
        if (price > 0) {
          result[s.metal_type] = price;
        } else {
          errors.push(`IMP: ${s.metal_type} element found but price is zero`);
        }
      }
    } catch (e) {
      errors.push(`IMP fetch error for ${url}: ${e}`);
    }
  }

  return { prices: result, errors };
}
