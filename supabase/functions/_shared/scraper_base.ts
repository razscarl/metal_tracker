// Shared HTTP and parsing utilities — mirrors Dart BaseScraperService

const DEFAULT_UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

export async function fetchHtml(
  url: string,
  extraHeaders: Record<string, string> = {},
): Promise<string> {
  const response = await fetch(url, {
    headers: { 'User-Agent': DEFAULT_UA, ...extraHeaders },
    signal: AbortSignal.timeout(30_000),
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} from ${url}`);
  }
  return response.text();
}

export async function fetchHtmlPost(
  url: string,
  payload: Record<string, string>,
  extraHeaders: Record<string, string> = {},
): Promise<string> {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'User-Agent': DEFAULT_UA,
      'Content-Type': 'application/x-www-form-urlencoded',
      ...extraHeaders,
    },
    body: new URLSearchParams(payload).toString(),
    signal: AbortSignal.timeout(30_000),
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} from POST ${url}`);
  }
  return response.text();
}

export function parsePrice(text: string): number {
  const cleaned = text.replace(/[^0-9.]/g, '');
  return parseFloat(cleaned) || 0;
}

export function decodeHtmlEntities(s: string): string {
  return s
    .replace(/&#8211;/g, '–')
    .replace(/&#8212;/g, '—')
    .replace(/&#8216;/g, '\u2018')
    .replace(/&#8217;/g, '\u2019')
    .replace(/&#8220;/g, '\u201C')
    .replace(/&#8221;/g, '\u201D')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&nbsp;/g, ' ');
}

export function inferMetalType(text: string): string | null {
  const lower = text.toLowerCase();
  if (lower.includes('platinum')) return 'platinum';
  if (lower.includes('silver')) return 'silver';
  if (lower.includes('gold')) return 'gold';
  return null;
}

export function metalFromUrl(href: string): string | null {
  return inferMetalType(href);
}
