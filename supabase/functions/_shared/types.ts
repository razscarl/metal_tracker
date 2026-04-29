// Shared TypeScript types for Metal Tracker automation Edge Functions

export interface ScraperSetting {
  id: string;
  retailer_id: string;
  scraper_type: string;
  metal_type: string | null;
  is_active: boolean;
  search_url: string | null;
  search_string: string;
}

export interface Retailer {
  id: string;
  name: string;
  retailer_abbr: string | null;
  base_url: string | null;
  is_active: boolean;
}

export interface LivePriceScrapeResult {
  retailerId: string;
  prices: Record<string, { sell: number; buyback: number }>;
  scrapeStatus: 'success' | 'partial' | 'failed';
  scrapeErrors: string[];
}

export interface LocalSpotScrapeResult {
  prices: Record<string, number>; // metalType → price
  errors: string[];
}

export interface GlobalSpotScrapeResult {
  displayName: string;
  prices: Record<string, number>; // 'gold' | 'silver' | 'platinum' → price
  errorMessage?: string;
}

export interface ScrapedListing {
  listingName: string;
  sellPrice: number;
  metalType: string | null;
  capturedStatus: string | null;
}

export interface ProductListingScrapeResult {
  retailerId: string;
  listings: ScrapedListing[];
  status: 'success' | 'partial' | 'failed';
  errors: string[];
}

export interface AutomationJob {
  id: string;
  job_type: string;
  retailer_id: string | null;
  retailer_name: string | null;
  scheduled_at: string;
  started_at: string | null;
  completed_at: string | null;
  status: string;
  attempt_number: number;
  parent_job_id: string | null;
  triggered_by: string;
  error_log: Record<string, unknown> | null;
  result_summary: Record<string, unknown> | null;
  created_at: string;
}

export interface GlobalSpotPref {
  id: string;
  user_id: string;
  provider_key: string; // 'metalsdev' | 'metalpriceapi'
  api_key: string;
  is_active: boolean;
}
