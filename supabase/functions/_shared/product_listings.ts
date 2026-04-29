// Product listing scrapers — mirrors Dart GbaProductListingService, GsProductListingService, ImpProductListingService
import { parse } from 'npm:node-html-parser';
import { fetchHtml, parsePrice, decodeHtmlEntities, inferMetalType, metalFromUrl } from './scraper_base.ts';
import type { ProductListingScrapeResult, ScrapedListing, ScraperSetting } from './types.ts';

// ── GBA ──────────────────────────────────────────────────────────────────────
// WooCommerce + Elementor. Paginated via /buy/gold/paged/2/
// Each setting = one category URL (gold / silver / platinum)

const GBA_UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

export async function scrapeGbaListings(
  retailerId: string,
  settings: ScraperSetting[],
): Promise<ProductListingScrapeResult> {
  const listings: ScrapedListing[] = [];
  const errors: string[] = [];

  for (const setting of settings) {
    const metalType = setting.metal_type;
    if (!metalType) continue;

    const startUrl = setting.search_url;
    if (!startUrl) {
      errors.push(`${metalType}: no URL configured`);
      continue;
    }

    try {
      let currentUrl: string | null = startUrl;
      let pageNum = 1;

      while (currentUrl && pageNum <= 50) {
        const html = await fetchHtml(currentUrl, { 'User-Agent': GBA_UA });
        const doc = parse(html);
        const cards = doc.querySelectorAll('article.card');

        for (const card of cards) {
          // Name: heading with link
          let name = card.querySelector('h2 a, h3 a, h4 a')?.text.trim() ?? '';
          if (!name) name = card.querySelector('h2, h3, h4')?.text.trim() ?? '';
          if (!name) continue;

          // Price: bdi (WooCommerce), then spans containing '$'
          let price = 0;
          const bdi = card.querySelector('bdi');
          if (bdi) price = parsePrice(bdi.text);
          if (price <= 0) {
            for (const span of card.querySelectorAll('span')) {
              const t = span.text.trim();
              if (t.startsWith('$') && t.length > 1) {
                price = parsePrice(t);
                if (price > 0) break;
              }
            }
          }
          if (price <= 0) continue;

          const classes = card.getAttribute('class') ?? '';
          const capturedStatus = classes.includes('outofstock') ? 'outofstock' : null;
          listings.push({ listingName: name, sellPrice: price, metalType, capturedStatus });
        }

        const nextLink = doc.querySelector('a[rel="next"]');
        currentUrl = nextLink?.getAttribute('href') ?? null;
        pageNum++;
      }
    } catch (e) {
      errors.push(`${metalType}: ${e}`);
    }
  }

  return {
    retailerId,
    listings,
    status: listings.length === 0 ? 'failed' : errors.length > 0 ? 'partial' : 'success',
    errors,
  };
}

// ── GS ───────────────────────────────────────────────────────────────────────
// WooCommerce Store API (public, no auth). All products in one paginated request.

const GS_API_BASE = 'https://goldsecure.com.au/wp-json/wc/store/v1/products';
const GS_HEADERS: Record<string, string> = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
  'Accept': 'application/json, */*',
  'Accept-Language': 'en-AU,en;q=0.9',
  'X-Requested-With': 'XMLHttpRequest',
  'Referer': 'https://goldsecure.com.au/buy-gold/',
};

export async function scrapeGsListings(
  retailerId: string,
  _settings: ScraperSetting[],
): Promise<ProductListingScrapeResult> {
  const listings: ScrapedListing[] = [];
  const errors: string[] = [];

  try {
    let page = 1;
    while (true) {
      const response = await fetch(`${GS_API_BASE}?per_page=100&page=${page}`, {
        headers: GS_HEADERS,
        signal: AbortSignal.timeout(30_000),
      });

      if (!response.ok) throw new Error(`Gold Secure API returned ${response.status}`);

      const products = await response.json() as Array<Record<string, unknown>>;
      if (!products.length) break;

      for (const product of products) {
        const name = String(product['name'] ?? '').trim();
        const priceStr = (product['prices'] as Record<string, string> | undefined)?.['price'] ?? '0';
        const price = (parseFloat(priceStr) || 0) / 100;
        if (!name || price <= 0) continue;

        const stockClass = (product['stock_availability'] as Record<string, string> | undefined)?.['class'];
        const inStock = product['is_in_stock'] as boolean | undefined ?? false;
        const capturedStatus = stockClass ?? (inStock ? 'in-stock' : 'out-of-stock');

        listings.push({
          listingName: name,
          sellPrice: price,
          metalType: inferMetalType(name),
          capturedStatus,
        });
      }

      if (products.length < 100) break;
      page++;
    }
  } catch (e) {
    errors.push(`${e}`);
  }

  return {
    retailerId,
    listings,
    status: listings.length === 0 ? 'failed' : errors.length > 0 ? 'partial' : 'success',
    errors,
  };
}

// ── IMP ──────────────────────────────────────────────────────────────────────
// Page 1: static HTML (article.wpgb-card)
// Pages 2+: WooCommerce Store API (same pattern as GS)
// IMP requires a single "all metals" setting with no metal_type and a shop URL

export async function scrapeImpListings(
  retailerId: string,
  settings: ScraperSetting[],
): Promise<ProductListingScrapeResult> {
  const errors: string[] = [];

  // Find the "all metals" setting (metalType = null)
  const allMetalSetting = settings.find((s) => !s.metal_type);
  if (!allMetalSetting) {
    return {
      retailerId,
      listings: [],
      status: 'failed',
      errors: ['No "all metals" setting found. Add a product_listing setting with Metal Type = None.'],
    };
  }

  const shopUrl = allMetalSetting.search_url ?? '';
  if (!shopUrl) {
    return {
      retailerId,
      listings: [],
      status: 'failed',
      errors: ['Product listing setting has no URL configured.'],
    };
  }

  const raw: Array<{ name: string; price: number; metalType: string | null }> = [];

  try {
    const base = shopUrl.endsWith('/') ? shopUrl : `${shopUrl}/`;

    // Page 1: static HTML
    const page1Html = await fetchHtml(base);
    const page1Doc = parse(page1Html);

    const seenNames = new Set<string>();
    for (const card of page1Doc.querySelectorAll('article.wpgb-card')) {
      const nameAnchor = card.querySelector('h3 a');
      const name = decodeHtmlEntities(nameAnchor?.text.trim() ?? '');
      if (!name || seenNames.has(name)) continue;
      const priceEl = card.querySelector('div.wpgb-block-5');
      const price = priceEl ? parsePrice(priceEl.text) : 0;
      if (price <= 0) continue;
      const href = nameAnchor?.getAttribute('href') ?? '';
      seenNames.add(name);
      raw.push({ name, price, metalType: metalFromUrl(href) });
    }

    // Pages 2+: WooCommerce Store API
    const baseHost = new URL(base).origin;
    const wcBase = `${baseHost}/wp-json/wc/store/v1/products`;
    const wcRaw: Array<{ name: string; price: number; metalType: string | null }> = [];
    const wcSeen = new Set<string>();
    let wcWorked = false;
    let wcPage = 1;

    while (true) {
      try {
        const res = await fetch(`${wcBase}?per_page=100&page=${wcPage}&status=publish`, {
          signal: AbortSignal.timeout(30_000),
        });
        if (!res.ok) break;

        const items = await res.json() as Array<Record<string, unknown>>;
        if (!Array.isArray(items) || items.length === 0) break;
        wcWorked = true;

        for (const item of items) {
          const rawName = decodeHtmlEntities(String(item['name'] ?? ''));
          if (!rawName || wcSeen.has(rawName)) continue;

          const priceStr = (item['prices'] as Record<string, string> | undefined)?.['price'] ?? '0';
          const decimals = ((item['prices'] as Record<string, number> | undefined)?.['currency_minor_unit'] ?? 2) as number;
          const price = (parseInt(priceStr) || 0) / Math.pow(10, decimals);
          if (price <= 0) continue;

          wcSeen.add(rawName);
          const permalink = String(item['permalink'] ?? '');
          wcRaw.push({ name: rawName, price, metalType: metalFromUrl(permalink) });
        }

        if (items.length < 100) break;
        wcPage++;
      } catch {
        break;
      }
    }

    if (wcWorked) {
      raw.length = 0;
      raw.push(...wcRaw);
    }
  } catch (e) {
    return {
      retailerId,
      listings: [],
      status: 'failed',
      errors: [`${e}`],
    };
  }

  const listings: ScrapedListing[] = raw.map((r) => ({
    listingName: r.name,
    sellPrice: r.price,
    metalType: r.metalType,
    capturedStatus: null,
  }));

  return {
    retailerId,
    listings,
    status: listings.length === 0 ? 'failed' : 'success',
    errors,
  };
}
