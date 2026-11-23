-- Phase 5: Declarative RANGE Partitioning on listings (by posted_at, monthly)
-- Run on large database: psql -U karun -d karun2 -v ON_ERROR_STOP=1 -f sql/08_partitioning.sql
--
-- Notes:
-- 1. Uses a separate table (olx.listings_part) so olx.listings stays untouched.
-- 2. PostgreSQL Primary-Key Rule: the partition key (posted_at) MUST be included
--    in the PRIMARY KEY and any UNIQUE constraint -> PRIMARY KEY (listing_id, posted_at).
-- 3. Monthly partitions match the 30-day ad lifecycle, enable partition pruning on
--    date-range queries (R08, R20), and allow instant archiving via DETACH/DROP PARTITION.

SET search_path TO olx, public;

DROP TABLE IF EXISTS listings_part CASCADE;

CREATE TABLE listings_part (
    listing_id       INTEGER NOT NULL,
    seller_id        INTEGER NOT NULL,
    category_id      INTEGER NOT NULL,
    title            VARCHAR(255) NOT NULL,
    description      TEXT,
    price            NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    is_negotiable    BOOLEAN NOT NULL DEFAULT FALSE,
    item_condition   VARCHAR(20) NOT NULL CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')),
    attributes       JSONB NOT NULL,
    city_id          INTEGER NOT NULL,
    locality         VARCHAR(150) NOT NULL,
    latitude         NUMERIC(9, 6) NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude        NUMERIC(9, 6) NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    image_count      INTEGER NOT NULL CHECK (image_count >= 0),
    view_count       INTEGER NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    boost_package_id INTEGER,
    status           VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')),
    posted_at        TIMESTAMPTZ NOT NULL,
    expires_at       TIMESTAMPTZ NOT NULL,
    sold_at          TIMESTAMPTZ,
    PRIMARY KEY (listing_id, posted_at),
    CONSTRAINT fk_listings_part_seller   FOREIGN KEY (seller_id)        REFERENCES users (user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_listings_part_category FOREIGN KEY (category_id)      REFERENCES categories (category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_listings_part_city     FOREIGN KEY (city_id)          REFERENCES cities (city_id) ON DELETE RESTRICT,
    CONSTRAINT fk_listings_part_boost    FOREIGN KEY (boost_package_id) REFERENCES boost_packages (package_id) ON DELETE SET NULL
) PARTITION BY RANGE (posted_at);

-- Monthly partitions: Jan 2025 through Jul 2026 + default safety partition
CREATE TABLE listings_part_2025_01 PARTITION OF listings_part FOR VALUES FROM ('2025-01-01 00:00:00+05:30') TO ('2025-02-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_02 PARTITION OF listings_part FOR VALUES FROM ('2025-02-01 00:00:00+05:30') TO ('2025-03-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_03 PARTITION OF listings_part FOR VALUES FROM ('2025-03-01 00:00:00+05:30') TO ('2025-04-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_04 PARTITION OF listings_part FOR VALUES FROM ('2025-04-01 00:00:00+05:30') TO ('2025-05-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_05 PARTITION OF listings_part FOR VALUES FROM ('2025-05-01 00:00:00+05:30') TO ('2025-06-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_06 PARTITION OF listings_part FOR VALUES FROM ('2025-06-01 00:00:00+05:30') TO ('2025-07-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_07 PARTITION OF listings_part FOR VALUES FROM ('2025-07-01 00:00:00+05:30') TO ('2025-08-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_08 PARTITION OF listings_part FOR VALUES FROM ('2025-08-01 00:00:00+05:30') TO ('2025-09-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_09 PARTITION OF listings_part FOR VALUES FROM ('2025-09-01 00:00:00+05:30') TO ('2025-10-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_10 PARTITION OF listings_part FOR VALUES FROM ('2025-10-01 00:00:00+05:30') TO ('2025-11-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_11 PARTITION OF listings_part FOR VALUES FROM ('2025-11-01 00:00:00+05:30') TO ('2025-12-01 00:00:00+05:30');
CREATE TABLE listings_part_2025_12 PARTITION OF listings_part FOR VALUES FROM ('2025-12-01 00:00:00+05:30') TO ('2026-01-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_01 PARTITION OF listings_part FOR VALUES FROM ('2026-01-01 00:00:00+05:30') TO ('2026-02-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_02 PARTITION OF listings_part FOR VALUES FROM ('2026-02-01 00:00:00+05:30') TO ('2026-03-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_03 PARTITION OF listings_part FOR VALUES FROM ('2026-03-01 00:00:00+05:30') TO ('2026-04-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_04 PARTITION OF listings_part FOR VALUES FROM ('2026-04-01 00:00:00+05:30') TO ('2026-05-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_05 PARTITION OF listings_part FOR VALUES FROM ('2026-05-01 00:00:00+05:30') TO ('2026-06-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_06 PARTITION OF listings_part FOR VALUES FROM ('2026-06-01 00:00:00+05:30') TO ('2026-07-01 00:00:00+05:30');
CREATE TABLE listings_part_2026_07 PARTITION OF listings_part FOR VALUES FROM ('2026-07-01 00:00:00+05:30') TO ('2026-08-01 00:00:00+05:30');
CREATE TABLE listings_part_default PARTITION OF listings_part DEFAULT;

-- Load all 2.4M rows from olx.listings into the partitioned table
INSERT INTO listings_part SELECT * FROM listings;

-- Partitioned indexes (automatically created per child partition)
CREATE INDEX idx_listings_part_posted_desc
    ON listings_part (posted_at DESC, listing_id DESC);
CREATE INDEX idx_listings_part_model_posted
    ON listings_part ((attributes ->> 'model'), posted_at)
    INCLUDE (item_condition, price)
    WHERE category_id = 5;

ANALYZE listings_part;

-- Partition distribution summary (row counts & sizes)
SELECT c.relname AS partition_name,
       s.n_live_tup AS est_rows,
       pg_size_pretty(pg_table_size(c.oid)) AS table_size,
       pg_size_pretty(pg_indexes_size(c.oid)) AS index_size
FROM pg_inherits i
JOIN pg_class c ON c.oid = i.inhrelid
JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE i.inhparent = 'olx.listings_part'::regclass
ORDER BY c.relname;

-- Proof 1: Partition pruning on R20 (June 2026 growth) -> scans ONLY listings_part_2026_06 (1 of 20 partitions)
EXPLAIN (ANALYZE, BUFFERS)
SELECT day, ads, sum(ads) OVER (ORDER BY day) AS running_total
FROM (
    SELECT posted_at::date AS day, count(*) AS ads
    FROM listings_part
    WHERE posted_at >= '2026-06-01 00:00:00+05:30'::timestamptz
      AND posted_at <  '2026-07-01 00:00:00+05:30'::timestamptz
    GROUP BY 1
) d
ORDER BY day;

-- Proof 2: Partition pruning on R08 (2026 iPhone 13 price guide) -> prunes all 12 partitions of 2025
EXPLAIN (ANALYZE, BUFFERS)
SELECT item_condition, count(*) AS ads,
       percentile_cont(0.5) WITHIN GROUP (ORDER BY price) AS median_price
FROM listings_part
WHERE category_id = 5
  AND attributes ->> 'model' = 'iPhone 13'
  AND posted_at >= '2026-01-01 00:00:00+05:30'::timestamptz
GROUP BY item_condition
ORDER BY median_price DESC;
