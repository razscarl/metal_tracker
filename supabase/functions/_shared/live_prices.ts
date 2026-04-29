// Live price scrapers — mirrors Dart GbaLivePriceService, GsLivePriceService, ImpLivePriceService
import { parse } from 'npm:node-html-parser';
import { fetchHtml, fetchHtmlPost, parsePrice } from './scraper_base.ts';
import type { LivePriceScrapeResult, ScraperSetting } from './types.ts';

// ── GBA ──────────────────────────────────────────────────────────────────────

export async function scrapeGbaLivePrices(
  retailerId: string,
  settings: ScraperSetting[],
): Promise<LivePriceScrapeResult> {
  const url = 'https://www.goldbullionaustralia.com.au/live-charts-prices/';
  const errors: string[] = [];
  const prices: Record<string, { sell: number; buyback: number }> = {};

  try {
    const html = await fetchHtml(url);
    const doc = parse(html);

    for (const setting of settings) {
      if (!setting.is_active || !setting.metal_type) continue;
      const metalType = setting.metal_type;
      const searchString = setting.search_string;

      try {
        const rows = doc.querySelectorAll('tr');
        let found = false;

        for (const row of rows) {
          if (!row.text.toLowerCase().includes(searchString.toLowerCase())) continue;
          const cells = row.querySelectorAll('td');
          if (cells.length >= 3) {
            const sell = parsePrice(cells[1].text);
            const buyback = parsePrice(cells[2].text);
            if (sell > 0 && buyback > 0) {
              prices[metalType] = { sell, buyback };
            } else {
              errors.push(`${metalType}: Row found but prices are zero`);
            }
          } else {
            errors.push(`${metalType}: Row found but insufficient columns`);
          }
          found = true;
          break;
        }

        if (!found) errors.push(`${metalType}: Not found: "${searchString}"`);
      } catch (e) {
        errors.push(`${metalType}: Failed - ${e}`);
      }
    }
  } catch (e) {
    return { retailerId, prices: {}, scrapeStatus: 'failed', scrapeErrors: [`Fatal error: ${e}`] };
  }

  return {
    retailerId,
    prices,
    scrapeStatus: Object.keys(prices).length === 0 ? 'failed' : errors.length > 0 ? 'partial' : 'success',
    scrapeErrors: errors,
  };
}

// ── GS ───────────────────────────────────────────────────────────────────────
// NOTE: The PHPSESSID cookie below may expire and need refreshing.

const GS_AJAX_URL = 'https://goldsecure.com.au/wp-admin/admin-ajax.php';
const GS_AJAX_ACTION = 'get_posts_ajax_live_price';

const GS_HEADERS: Record<string, string> = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
  'X-Requested-With': 'XMLHttpRequest',
  'Referer': 'https://goldsecure.com.au/live-price/',
  'Accept': '*/*',
  'Accept-Language': 'en-US,en;q=0.9',
  'Cookie': 'PHPSESSID=03aab98d5f424688be08af1d3f9495d3',
};

export async function scrapeGsLivePrices(
  retailerId: string,
  settings: ScraperSetting[],
): Promise<LivePriceScrapeResult> {
  const errors: string[] = [];
  const prices: Record<string, { sell: number; buyback: number }> = {};

  for (const setting of settings) {
    if (!setting.is_active || !setting.metal_type) continue;
    const metalType = setting.metal_type;
    const searchString = setting.search_string;

    try {
      const html = await fetchHtmlPost(
        GS_AJAX_URL,
        {
          action: GS_AJAX_ACTION,
          metal_tab: metalType.toLowerCase(),
          brand_weight: 'weight',
          end_tab: 'all',
        },
        GS_HEADERS,
      );

      const doc = parse(html);
      const rows = doc.querySelectorAll('tr');
      let found = false;

      for (const row of rows) {
        const cells = row.querySelectorAll('td');
        if (cells.length < 3) continue;
        if (!cells[0].text.toLowerCase().includes(searchString.toLowerCase())) continue;

        const sell = parsePrice(cells[1].text);
        const buyback = parsePrice(cells[2].text);
        if (sell > 0 && buyback > 0) {
          prices[metalType] = { sell, buyback };
        } else {
          errors.push(`${metalType}: Row found but prices are zero`);
        }
        found = true;
        break;
      }

      if (!found) errors.push(`${metalType}: Not found: "${searchString}"`);
    } catch (e) {
      errors.push(`${metalType}: Failed - ${e}`);
    }
  }

  return {
    retailerId,
    prices,
    scrapeStatus: Object.keys(prices).length === 0 ? 'failed' : errors.length > 0 ? 'partial' : 'success',
    scrapeErrors: errors,
  };
}

// ── IMP ──────────────────────────────────────────────────────────────────────

const IMP_DEFAULT_URL = 'https://pricing.imperialbullion.com.au/pricing-feed.json';

const IMP_HEADERS: Record<string, string> = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Accept': 'application/json',
  'Origin': 'https://imperialbullion.com.au',
};

export async function scrapeImpLivePrices(
  retailerId: string,
  settings: ScraperSetting[],
): Promise<LivePriceScrapeResult> {
  const errors: string[] = [];
  const prices: Record<string, { sell: number; buyback: number }> = {};

  const apiEndpoint = settings[0]?.search_url ?? IMP_DEFAULT_URL;

  try {
    const response = await fetch(apiEndpoint, {
      headers: IMP_HEADERS,
      signal: AbortSignal.timeout(30_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);

    const data: Record<string, { SellPrice: number; BuyPrice: number }> = await response.json();

    for (const setting of settings) {
      if (!setting.is_active || !setting.metal_type) continue;
      const metalType = setting.metal_type;
      const apiKey = setting.search_string;

      try {
        const metalData = data[apiKey];
        if (!metalData) {
          errors.push(`${metalType}: API key "${apiKey}" not found in response`);
          continue;
        }

        const sell = Number(metalData.SellPrice);
        const buyback = Number(metalData.BuyPrice);

        if (sell > 0 && buyback > 0) {
          prices[metalType] = { sell, buyback };
        } else {
          errors.push(`${metalType}: Prices are zero`);
        }
      } catch (e) {
        errors.push(`${metalType}: Failed - ${e}`);
      }
    }
  } catch (e) {
    return { retailerId, prices: {}, scrapeStatus: 'failed', scrapeErrors: [`Fatal error: ${e}`] };
  }

  return {
    retailerId,
    prices,
    scrapeStatus: Object.keys(prices).length === 0 ? 'failed' : errors.length > 0 ? 'partial' : 'success',
    scrapeErrors: errors,
  };
}
