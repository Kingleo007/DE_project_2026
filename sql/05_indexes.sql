-- Phase 4 indexes for the OLX
-- Apply after sql/01_schema.sql and sql/02_load_data.sql, before benchmarking.

CREATE EXTENSION IF NOT EXISTS pg_trgm;
SET search_path TO olx, public;

-- R01, R19: category and city are equality filters. Price narrows R01's range;
-- posted_at is carried as a trailing key, though the price range may still need a
-- sort for the requested global newest-first order. The partial index drops inactive ads.
CREATE INDEX IF NOT EXISTS idx_listings_active_cat_city_price_posted
    ON listings (category_id, city_id, price, posted_at DESC)
    WHERE status = 'ACTIVE';

-- R02: equality filters precede the JSON attribute filters. Year and kilometres
-- match the integer casts used by the query; fuel is checked by exact equality.
CREATE INDEX IF NOT EXISTS idx_listings_active_car_filters
    ON listings (category_id, city_id, (attributes ->> 'fuel'),
                 ((attributes ->> 'year')::integer),
                 ((attributes ->> 'km_driven')::integer))
    WHERE status = 'ACTIVE';

-- R03: trigram GIN supports the leading-wildcard ILIKE search. The partial B-tree
-- lets the planner choose a price-ordered active scan for the LIMIT when cheaper.
CREATE INDEX IF NOT EXISTS idx_listings_active_title_trgm
    ON listings USING gin (title gin_trgm_ops)
    WHERE status = 'ACTIVE';
CREATE INDEX IF NOT EXISTS idx_listings_active_price
    ON listings (price)
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

-- R08: category/model equality followed by the 2026 posting-time range; condition
-- and price are included for grouped median calculation.
CREATE INDEX IF NOT EXISTS idx_listings_category_model_posted
    ON listings (category_id, (attributes ->> 'model'), posted_at)
    INCLUDE (item_condition, price);

-- R09: the active-furniture bounding box checks latitude and longitude ranges.
-- Separate partial B-trees can combine through a BitmapAnd on the two ranges.
CREATE INDEX IF NOT EXISTS idx_listings_active_furniture_lat
    ON listings (latitude)
    WHERE status = 'ACTIVE' AND category_id = 9;
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

-- R18: groups on exactly these columns; the compact ordered index can feed the
-- duplicate aggregation without sorting the entire listings table.
CREATE INDEX IF NOT EXISTS idx_listings_seller_title_price
    ON listings (seller_id, title, price);

-- R20: supports the sargable June timestamp range in the optimized query.
CREATE INDEX IF NOT EXISTS idx_listings_posted_at
    ON listings (posted_at);

-- R22: matches newest-first pagination and carries all selected values for an
-- index-only scan when the visibility map allows it.
CREATE INDEX IF NOT EXISTS idx_listings_posted_desc
    ON listings (posted_at DESC)
    INCLUDE (listing_id, seller_id, category_id, title, status);

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
