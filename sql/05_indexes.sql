-- Phase 4 indexes for the OLX
-- Apply after sql/01_schema.sql and sql/02_load_data.sql, before benchmarking.

CREATE EXTENSION IF NOT EXISTS pg_trgm;
SET search_path TO olx, public;

-- R01, R19: category and city are equality filters; posted_at DESC comes before price
-- so R01 walks newest active cars first, filters price in-index, and stops at LIMIT 40
-- without sorting thousands of rows.
-- Replaced in Phase 5 (old order put price before posted_at DESC, causing 3,570-row sort at 20x):
-- CREATE INDEX IF NOT EXISTS idx_listings_active_cat_city_price_posted
--     ON listings (category_id, city_id, price, posted_at DESC)
--     WHERE status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_listings_active_cat_city_posted_price
    ON listings (category_id, city_id, posted_at DESC, price)
    WHERE status = 'ACTIVE';

-- R02: equality filters precede the JSON attribute filters. Year and kilometres
-- match the integer casts used by the query; fuel is checked by exact equality.
CREATE INDEX IF NOT EXISTS idx_listings_active_car_filters
    ON listings (category_id, city_id, (attributes ->> 'fuel'),
                 ((attributes ->> 'year')::integer),
                 ((attributes ->> 'km_driven')::integer))
    WHERE status = 'ACTIVE';

-- R03: partial covering index ordered by price with pre-lowercased title allows an
-- Index-Only Scan (0 heap fetches) for strpos(lower(title), ...) ORDER BY price LIMIT 40.
-- Replaced in Phase 5 (idx_listings_active_price caused 50,608 heap fetches on 20x data):
-- CREATE INDEX IF NOT EXISTS idx_listings_active_price
--     ON listings (price)
--     WHERE status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_listings_active_title_trgm
    ON listings USING gin (title gin_trgm_ops)
    WHERE status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_listings_active_price_ltitle
    ON listings (price, lower(title))
    INCLUDE (title, listing_id, city_id, item_condition)
    WHERE status = 'ACTIVE';

-- R04, R21: seller equality/grouping is the leading key; stars cover the average.
CREATE INDEX IF NOT EXISTS idx_seller_ratings_seller_stars
    ON seller_ratings (seller_id) INCLUDE (stars);

-- R05, W02, R06: seller lookup first, then status and listing order for My Ads
-- and selecting the oldest active ad. The seller_id prefix also helps seller chats.
CREATE INDEX IF NOT EXISTS idx_listings_seller_status_id
    ON listings (seller_id, status, listing_id) INCLUDE (view_count);

-- R06, R07: locate a user's buyer threads; listing_id locates threads for the
-- seller side and for per-listing chat counts in R19.
CREATE INDEX IF NOT EXISTS idx_chat_threads_buyer_listing
    ON chat_threads (buyer_id, listing_id, thread_id);
CREATE INDEX IF NOT EXISTS idx_chat_threads_listing
    ON chat_threads (listing_id, thread_id);

-- R06, R19, R25: thread first supports latest-message lookups and thread joins;
-- descending sent_at supports newest-first LIMIT 1. INCLUDE covers message fields.
CREATE INDEX IF NOT EXISTS idx_chat_messages_thread_latest
    ON chat_messages (thread_id, sent_at DESC)
    INCLUDE (body, sender_id, is_read);

-- R07: count unread messages only for a user's selected threads. A partial index
-- avoids carrying read messages; thread_id is the join key, sender_id is covered.
CREATE INDEX IF NOT EXISTS idx_chat_messages_unread_thread
    ON chat_messages (thread_id) INCLUDE (sender_id)
    WHERE is_read = false;

-- R08: partial index restricted to category_id = 5 (Phones) so W04 skips ~90% of listings.
-- Replaced in Phase 5 (was non-partial across all 2.4M listings):
-- CREATE INDEX IF NOT EXISTS idx_listings_category_model_posted
--     ON listings (category_id, (attributes ->> 'model'), posted_at)
--     INCLUDE (item_condition, price);
CREATE INDEX IF NOT EXISTS idx_listings_category_model_posted
    ON listings ((attributes ->> 'model'), posted_at)
    INCLUDE (item_condition, price)
    WHERE category_id = 5;

-- R09: active-furniture longitude range (latitude index was unused by planner and dropped in Phase 5).
-- CREATE INDEX IF NOT EXISTS idx_listings_active_furniture_lat
--     ON listings (latitude)
--     WHERE status = 'ACTIVE' AND category_id = 9;
CREATE INDEX IF NOT EXISTS idx_listings_active_furniture_lon
    ON listings (longitude)
    WHERE status = 'ACTIVE' AND category_id = 9;

-- R10, W04: expiration range plus active status; only active rows occupy the index.
CREATE INDEX IF NOT EXISTS idx_listings_active_expires
    ON listings (expires_at)
    WHERE status = 'ACTIVE';

-- R11: open-report queue groups by listing and returns distinct reasons.
CREATE INDEX IF NOT EXISTS idx_reports_open_listing
    ON reports (listing_id) INCLUDE (reason)
    WHERE status = 'OPEN';

-- R14: sold_at range (the optimized query rewrites EXTRACT(YEAR) to a range).
CREATE INDEX IF NOT EXISTS idx_listings_sold_at
    ON listings (sold_at)
    WHERE status = 'SOLD';

-- W05: equality on listing and pending status, then highest offer price and a
-- deterministic offer_id tie-breaker used by ORDER BY ... LIMIT 1.
CREATE INDEX IF NOT EXISTS idx_offers_listing_status_price
    ON offers (listing_id, status, offer_price DESC, offer_id);

-- R16: recent-saves range first; listing_id is available for the join/grouping.
CREATE INDEX IF NOT EXISTS idx_favourites_saved_listing
    ON favourites (saved_at, listing_id);

-- Dropped in Phase 5 to reduce write amplification on W04 (R18 still passes < 5,000 ms via scan,
-- and idx_listings_posted_at duplicated idx_listings_posted_desc):
-- CREATE INDEX IF NOT EXISTS idx_listings_seller_title_price
--     ON listings (seller_id, title, price);
-- CREATE INDEX IF NOT EXISTS idx_listings_posted_at
--     ON listings (posted_at);

-- R20, R22: slim index on (posted_at DESC, listing_id DESC) supports R22 keyset seek and
-- R20 index-only date range scan without carrying wide INCLUDE columns on every W04 update.
-- Replaced in Phase 5 (old INCLUDE carried title/status on all 2.4M rows):
-- CREATE INDEX IF NOT EXISTS idx_listings_posted_desc
--     ON listings (posted_at DESC)
--     INCLUDE (listing_id, seller_id, category_id, title, status);
CREATE INDEX IF NOT EXISTS idx_listings_posted_desc
    ON listings (posted_at DESC, listing_id DESC);

-- Phase 5 physical clustering for W04: pack ACTIVE rows by expires_at so nightly expiry
-- updates contiguous heap pages instead of 35,000+ scattered pages, then drop temp index.
CREATE INDEX IF NOT EXISTS idx_listings_status_expires_cluster
    ON listings (status, expires_at);
CLUSTER olx.listings USING idx_listings_status_expires_cluster;
DROP INDEX IF EXISTS idx_listings_status_expires_cluster;

-- R13/R15/R17/R21/R24 are small or broad aggregations at seed size; a full scan
-- may be cheaper than extra indexes. R23 already uses users.phone's UNIQUE index.

ANALYZE olx.cities;
ANALYZE olx.categories;
ANALYZE olx.boost_packages;
ANALYZE olx.users;
ANALYZE olx.listings;
ANALYZE olx.chat_threads;
ANALYZE olx.chat_messages;
ANALYZE olx.offers;
ANALYZE olx.favourites;
ANALYZE olx.reports;
ANALYZE olx.seller_ratings;
