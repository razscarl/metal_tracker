-- =============================================================================
-- Migration 006: Auto-map product_listings to product profiles on insert
-- Apply via: Supabase Dashboard → SQL Editor → paste and run
--
-- Problem: automated pg_cron scrapes insert new listing rows every day without
-- looking up prior mappings. Manually-mapped profile links are lost each day.
--
-- Solution: BEFORE INSERT trigger that copies product_profile_id from the most
-- recent prior row with the same listing_name + retailer_id combination.
-- Works regardless of whether the insert comes from the Dart app or an edge
-- function — single source of truth at the database level.
-- =============================================================================

CREATE OR REPLACE FUNCTION auto_map_listing_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Only act when no profile has been explicitly assigned
    IF NEW.product_profile_id IS NULL THEN
        SELECT product_profile_id
        INTO   NEW.product_profile_id
        FROM   product_listings
        WHERE  retailer_id        = NEW.retailer_id
          AND  listing_name       = NEW.listing_name
          AND  product_profile_id IS NOT NULL
        ORDER  BY scrape_date DESC
        LIMIT  1;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_map_listing_profile_trigger ON product_listings;

CREATE TRIGGER auto_map_listing_profile_trigger
BEFORE INSERT ON product_listings
FOR EACH ROW EXECUTE FUNCTION auto_map_listing_profile();

-- =============================================================================
-- End of migration 006
-- =============================================================================
