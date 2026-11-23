# Phase 5 — Scalability Report

## 1. First Try Testing (Before Phase 5 Scale Fixes)

First 3-run benchmark of `sql/06_optimized_queries.sql` on `large_data/` (`karun2`, 2.4M listings) using the Phase 4 indexes, compared against `benchmarks/results/optimized/summary.csv` on `seed_data/` (`karun`, 120k listings).

`R22` cursor was updated for `large_data` using `OFFSET 49999 LIMIT 1` → `('2026-06-19 14:18:43+05:30', 2349875)` (the exact last row of page 2,000 on 2.4M rows).

### Table 1: Large-data results (First Try Testing)

| Query | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
|---|---:|---:|---:|:---:|---|
| R01 | 3.903 | 54.586 | 14.0× | No | Fixed in Step 3 below (target < 5 ms) |
| R02 | 0.291 | 1.865 | 6.4× | Yes | — |
| R03 | 7.180 | 693.292 | 96.6× | No | Fixed in Step 3 below (target < 5 ms) |
| R04 | 0.354 | 0.317 | 0.9× | Yes | — |
| R05 | 0.174 | 0.164 | 0.9× | Yes | — |
| R06 | 1.698 | 1.158 | 0.7× | Yes | — |
| R07 | 0.091 | 0.229 | 2.5× | Yes | — |
| R08 | 5.819 | 78.243 | 13.4× | Yes | — |
| R09 | 0.457 | 1.486 | 3.3× | Yes | — |
| R10 | 1.191 | 11.112 | 9.3× | Yes | — |
| R11 | 2.610 | 12.351 | 4.7× | Yes | — |
| R12 | 55.212 | 1137.371 | 20.6× | Yes | — |
| R13 | 10.069 | 204.624 | 20.3× | Yes | — |
| R14 | 7.167 | 85.508 | 11.9× | Yes | — |
| R15 | 12.249 | 182.331 | 14.9× | Yes | — |
| R16 | 5.098 | 83.939 | 16.5× | Yes | — |
| R17 | 12.716 | 188.605 | 14.8× | Yes | — |
| R18 | 34.181 | 451.554 | 13.2× | Yes | — |
| R19 | 6.350 | 48.682 | 7.7× | Yes | — |
| R20 | 1.011 | 16.021 | 15.8× | Yes | — |
| R21 | 2.975 | 35.836 | 12.0× | Yes | — |
| R22 | 0.026 | 0.164 | 6.3× | Yes | — |
| R23 | 0.173 | 0.217 | 1.3× | Yes | — |
| R24 | 2.066 | 18.167 | 8.8× | Yes | — |
| R25 | 58.220 | 896.882 | 15.4× | Yes | — |
| W01 | 1.989 | 2.524 | 1.3× | Yes | — |
| W02 | 0.589 | 0.315 | 0.5× | Yes | — |
| W03 | 0.752 | 0.831 | 1.1× | Yes | — |
| W04 | 280.397 | 6643.895 | 23.7× | No | Fixed in Step 3 below (target < 1,000 ms) |
| W05 | 0.590 | 0.242 | 0.4× | Yes | — |
| **Total** | **515.598** | **10852.511** | **21.0×** | **27 / 30** | **3 queries missed target: R01, R03, W04** |

### Table 2: Performance targets on the large dataset

| Query group | Queries | Target (average of 3 runs) |
|---|---|---:|
| Real-time / user-facing | R01, R02, R03, R04, R05, R06, R07, R09, R23, W01, W02, W03, W05 | under 5 ms |
| Interactive tools | R10, R11, R13, R16, R22 | under 250 ms |
| Reports and analytics | R08, R12, R14, R15, R17, R18, R19, R20, R21, R24, R25 | under 5,000 ms |
| Batch jobs | W04 | under 1,000 ms |

---

## 2. Final Results (After Phase 5 Scale Fixes — 30 / 30 Passed)

After fixing `R01`, `R03`, and `W04` in `sql/05_indexes.sql` and `sql/06_optimized_queries.sql` and running `VACUUM ANALYZE olx.listings;`, all 30 queries were re-benchmarked (`./benchmarks/run_benchmark.sh karun2 large 3 sql/06_optimized_queries.sql`). Every number below matches `benchmarks/results/large/summary.csv`.

### Table 3: Final Large-data results (After Phase 5 Fixes)

| Query | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
|---|---:|---:|---:|:---:|---|
| R01 | 3.903 | 0.098 | 0.03× | Yes | Fixed (was 54.586 ms): index key order `(category_id, city_id, posted_at DESC, price)` |
| R02 | 0.291 | 0.199 | 0.7× | Yes | — |
| R03 | 7.180 | 3.294 | 0.5× | Yes | Fixed (was 693.292 ms): dropped `idx_listings_active_price`, added covering `(price, lower(title))` index + `strpos(lower(title), 'iphone 13') > 0` (`0` row diff) |
| R04 | 0.354 | 0.234 | 0.7× | Yes | — |
| R05 | 0.174 | 0.055 | 0.3× | Yes | — |
| R06 | 1.698 | 1.119 | 0.7× | Yes | — |
| R07 | 0.091 | 0.118 | 1.3× | Yes | — |
| R08 | 5.819 | 43.994 | 7.6× | Yes | Made `idx_listings_category_model_posted` partial (`WHERE category_id = 5`) |
| R09 | 0.457 | 0.989 | 2.2× | Yes | — |
| R10 | 1.191 | 2.666 | 2.2× | Yes | — |
| R11 | 2.610 | 5.301 | 2.0× | Yes | — |
| R12 | 55.212 | 1138.834 | 20.6× | Yes | — |
| R13 | 10.069 | 207.971 | 20.7× | Yes | — |
| R14 | 7.167 | 58.949 | 8.2× | Yes | — |
| R15 | 12.249 | 179.551 | 14.7× | Yes | — |
| R16 | 5.098 | 16.734 | 3.3× | Yes | — |
| R17 | 12.716 | 178.770 | 14.1× | Yes | — |
| R18 | 34.181 | 1156.743 | 33.8× | Yes | Dropped `idx_listings_seller_title_price` to speed up `W04`; still well under 5,000 ms |
| R19 | 6.350 | 53.277 | 8.4× | Yes | — |
| R20 | 1.011 | 17.961 | 17.8× | Yes | Dropped duplicate `idx_listings_posted_at`; uses `idx_listings_posted_desc` |
| R21 | 2.975 | 35.237 | 11.8× | Yes | — |
| R22 | 0.026 | 0.034 | 1.3× | Yes | Updated keyset cursor for 2.4M rows; slimmed `idx_listings_posted_desc` |
| R23 | 0.173 | 0.200 | 1.2× | Yes | — |
| R24 | 2.066 | 16.129 | 7.8× | Yes | — |
| R25 | 58.220 | 837.766 | 14.4× | Yes | — |
| W01 | 1.989 | 1.645 | 0.8× | Yes | Faster after dropping redundant `listings` indexes |
| W02 | 0.589 | 0.210 | 0.4× | Yes | — |
| W03 | 0.752 | 0.745 | 1.0× | Yes | — |
| W04 | 280.397 | 549.635 | 2.0× | Yes | Fixed (was 6643.895 ms): pruned/slimmed `listings` indexes + `CLUSTER` on `(status, expires_at)` |
| W05 | 0.590 | 0.147 | 0.2× | Yes | — |
| **Total** | **515.598** | **4508.605** | **8.7×** | **30 / 30** | **All 30 queries pass (total cut from 10,852.5 ms → 4,508.6 ms)** |

---

## 3. Growth Analysis (20× Data)

| Growth Group | Queries | Why |
|---|---|---|
| **Stayed roughly the same (~0.03× – 3.3×)** | `R01, R02, R03, R04, R05, R06, R07, R09, R10, R11, R16, R22, R23, W01, W02, W03, W04, W05` | B-tree point/range lookups grow as $O(\log n)$, keyset/LIMIT queries stop after a fixed row count, and Phase 5 index/cluster fixes eliminated cold-cache/sort overhead on `R01`, `R03`, and `W04`. |
| **Grew ~8× – 21× (roughly linear)** | `R08 (7.6×), R12 (20.6×), R13 (20.7×), R14 (8.2×), R15 (14.7×), R17 (14.1×), R19 (8.4×), R20 (17.8×), R21 (11.8×), R24 (7.8×), R25 (14.4×)` | These read a fixed percentage of the table (full table or all rows in 2026 / June 2026), so work scales linearly ($O(n)$) when row counts grow 20×. |
| **Grew > 20×** | **Before fixes:** `R03 (96.6×)`, `W04 (23.7×)`<br>**After fixes:** `R18 (33.8×)` | `R03` and `W04` broke at scale and were fixed (Section 4). `R18` grew to `1156.7 ms` intentionally because we dropped `idx_listings_seller_title_price` to speed up `W04`; `R18` still easily passes `< 5,000 ms`. |

---

## 4. What Broke at Scale & How We Fixed It

### Fix 1: `R01` — `54.586 ms` → `0.098 ms` (557× faster, target `< 5 ms`)
- **Problem:** Index `(category_id, city_id, price, posted_at DESC)` put the `price` range before `posted_at DESC`, forcing Postgres to fetch all 3,570 matching cars across 3,230 heap pages and sort them just to return 40.
- **Fix:** Changed index order to `(category_id, city_id, posted_at DESC, price) WHERE status = 'ACTIVE'`. Postgres now walks newest cars first, checks `price` in-index, and stops at 40 rows with zero sort.

```text
-- BEFORE (avg 54.586 ms, Run 1: 154.394 ms)
Limit (actual time=154.369..154.371 rows=40)
  -> Sort (Sort Key: posted_at DESC, top-N heapsort)
       -> Bitmap Heap Scan on listings (Heap Blocks: exact=3230, rows=3570)
            -> Bitmap Index Scan on idx_listings_active_cat_city_price_posted (rows=3570)
Execution Time: 154.394 ms

-- AFTER (avg 0.098 ms, Run 1: 0.100 ms)
Limit (actual time=0.042..0.088 rows=40) Buffers: shared hit=39 read=3
  -> Index Scan using idx_listings_active_cat_city_posted_price on listings (rows=40)
       Index Cond: (category_id = 2 AND city_id = 1 AND price >= 300000 AND price <= 600000)
Execution Time: 0.100 ms
```

### Fix 2: `R03` — `693.292 ms` → `3.294 ms` (210× faster, target `< 5 ms`)
- **Problem:** At 20× scale, the planner stopped using the GIN trigram index and picked `idx_listings_active_price`, scanning and discarding **50,608 heap rows** (`50,070` buffers). Dropping it fell back to GIN, which still fetched 6,034 random heap pages (`37.3 ms`). Even a covering index with `ILIKE` spent `8.4 ms` in per-row locale-aware case folding.
- **Fix:** Dropped `idx_listings_active_price`, created a partial covering index `(price, lower(title)) INCLUDE (title, listing_id, city_id, item_condition) WHERE status = 'ACTIVE'`, and rewrote `title ILIKE '%iphone 13%'` to `strpos(lower(title), 'iphone 13') > 0` (verified `0` row difference via bidirectional `EXCEPT ALL`). Also note: running `VACUUM` kept `Heap Fetches: 0` (without `VACUUM` after a write rollback test, `14,484` heap fetches raised `R03` to `8.495 ms`).

```text
-- BEFORE (avg 693.292 ms, Run 1: 1970.153 ms)
Limit (actual time=1938.160..1970.140 rows=40) Buffers: shared hit=25120 read=24950
  -> Index Scan using idx_listings_active_price on listings (rows=40)
       Filter: (title ~~* '%iphone 13%')
       Rows Removed by Filter: 50608
Execution Time: 1970.153 ms

-- AFTER (avg 3.294 ms, Run 1: 3.741 ms, Run 2: 3.112 ms, Run 3: 3.030 ms)
Limit (actual time=3.643..3.729 rows=40) Buffers: shared hit=1 read=484
  -> Index Only Scan using idx_listings_active_price_ltitle on listings (rows=40)
       Filter: (strpos(lower(title), 'iphone 13') > 0)
       Rows Removed by Filter: 50666  |  Heap Fetches: 0
Execution Time: 3.741 ms
```

### Fix 3: `W04` — `6643.895 ms` → `549.635 ms` (12.1× faster, target `< 1,000 ms`)
- **Problem:** Updating 45,275 expired active rows disabled HOT updates and wrote to 6 non-partial indexes on `listings` (including two wide indexes carrying `title`), while the 45,275 target rows were scattered across **35,315 heap pages** (~1 row/page), dirtying ~155,000 pages per run.
- **Fix:**
  1. Dropped redundant/wide non-partial indexes (`idx_listings_posted_at`, `idx_listings_seller_title_price`, unused `idx_listings_active_furniture_lat`).
  2. Slimmed `idx_listings_posted_desc` to `(posted_at DESC, listing_id DESC)` (removed wide `INCLUDE` columns).
  3. Made `idx_listings_category_model_posted` partial (`WHERE category_id = 5`) so ~90% of `W04` rows skip it.
  4. Ran `CLUSTER` on `(status, expires_at)` (then dropped the temp index), packing active rows from **35,315 scattered pages** into **7,168 contiguous pages**.

```text
-- BEFORE (avg 6643.895 ms, Run 1: 11891.805 ms)
Update on listings (actual time=11891.759..11891.759)
  Buffers: shared hit=967282 read=152256 dirtied=153275 written=129373
  -> Index Scan using idx_listings_active_expires on listings (rows=45275)
       Buffers: shared hit=191 read=35315 written=29556
Execution Time: 11891.805 ms

-- AFTER (avg 549.635 ms, Run 1: 532.795 ms)
Update on listings (actual time=532.746..532.746)
  Buffers: shared hit=630708 read=66362 dirtied=61755 written=52141
  -> Bitmap Heap Scan on listings (Heap Blocks: exact=7168, rows=45275)
       -> Bitmap Index Scan on idx_listings_active_car_filters (rows=198517)
Execution Time: 532.795 ms
```

---

## 5. Storage

| Dataset | Total database size | Table size | Index size |
|---|---:|---:|---:|
| Seed (`karun`, 120k listings) | 162 MB | 64 MB | 90 MB |
| Large (`karun2`, before fixes) | 2590 MB | 1272 MB | 1309 MB |
| Large (`karun2`, after fixes) | 2348 MB | 1309 MB | 1030 MB |
| Projected 100× (12M listings, ~5× large) | ~11.7 GB | ~6.5 GB | ~5.2 GB |

Pruning and slimming `listings` indexes saved **279 MB** (`1309 MB → 1030 MB`) while cutting total query time by **58%**.

---

## 6. Architecture for 100× (12M Listings, ~21M Chat Messages)

### 6.1 Partitioning (`sql/08_partitioning.sql`)
- **Table & strategy:** Partition `listings` by **`RANGE (posted_at)`** into monthly partitions (and `chat_messages` by `RANGE (sent_at)` at 100×).
- **Why:** Ads expire after 30 days, so monthly partitions match the ad lifecycle (~35–40 MB table + ~10 MB index per month at 20×; ~190 MB/month at 100×). Old months can be archived instantly with `DETACH PARTITION` + `DROP TABLE` instead of slow `DELETE` + `VACUUM`.
- **Primary-key rule:** PostgreSQL requires the partition key inside any `PRIMARY KEY` or `UNIQUE` constraint, so `listings_part` uses **`PRIMARY KEY (listing_id, posted_at)`**. Child tables referencing `listings` must either carry `(listing_id, posted_at)` or enforce the FK in the application layer.
- **Partition pruning proof (measured on `karun2`, 2.4M rows across 20 partitions in `sql/08_partitioning.sql`):**
  - **`R20` (June 2026 growth):** Scanned **1 of 20 partitions** (`listings_part_2026_06`, `Index Only Scan`, `Heap Fetches: 0`, `39.897 ms`) — **19 partitions pruned**.
  - **`R08` (2026 iPhone 13 price guide):** Scanned only 2026 partitions (`2026_01`–`2026_07` + `default`, `100.391 ms`) — **all 12 partitions of 2025 pruned**.

```text
-- R20 partition pruning on olx.listings_part (2.4M rows, 20 partitions)
-> Index Only Scan using listings_part_2026_06_posted_at_listing_id_idx on listings_part_2026_06
     Index Cond: (posted_at >= '2026-06-01 00:00:00+05:30' AND posted_at < '2026-07-01 00:00:00+05:30')
     Heap Fetches: 0
Execution Time: 39.897 ms   (only 1 of 20 partitions scanned)
```

### 6.2 Sharding
- **Choice: Shard by `city_id` (city groups)** — not by category or seller:
  - *Why not category?* Breaks seller "My Ads" (`R05`) and chat inbox (`R06`, `R07`) across every shard.
  - *Why not seller?* Breaks local browse (`R01`, `R02`, `R09`) across every shard.
  - *Why city?* OLX is hyper-local: browsing (`R01`, `R02`, `R09`, `R19`) and most deals stay inside one city shard.
- **Handling cross-shard chats (buyer and seller in different cities):**
  - Co-locate `chat_threads` and `chat_messages` with the **listing's `city_id` shard** so ad pages and seller chats stay single-shard.
  - Maintain a small global index `(user_id → active_shard_ids)` (e.g., in Redis or a tiny routing DB) so `R06`/`R07` only query the 1–2 shards where that user has chats instead of broadcasting to every shard.
- **Cross-shard queries & how to handle them:**
  - `R23` (login by phone): small global `users` routing DB / shard directory keyed by `phone`.
  - `R03` (nationwide text search): offload to a dedicated search engine (OpenSearch/Elasticsearch) synced via CDC.
  - Platform-wide analytics & moderation (`R08, R11, R12, R13, R14, R15, R16, R17, R18, R20, R21, R22, R24, R25`): run on an aggregated read replica or analytics store, never as scatter-gather on live OLTP primaries.

### 6.3 Read Replicas & Caching

| Tier | Queries | Reason / TTL |
|---|---|---|
| **Primary (read/write)** | `W01–W05`, `R04`, `R05`, `R06`, `R07`, `R23` | All writes, login auth, and read-after-write consistency (seller immediately sees new/sold ad; chat shows sent/read state). |
| **Read Replicas** | `R10, R11, R12, R13, R14, R15, R17, R18, R19, R20, R21, R22, R25` | Heavy scans, moderation queues, and analytics tolerate slight replication lag (milliseconds to seconds) and stay off the primary. |
| **Cache (Redis / CDN)** | `R01, R02, R03, R09` (15–30s TTL); `R24` (60s); `R16` (5 min); `R04` seller rating (5 min); `R08, R13` (hourly/daily) | High-traffic browse/home/price-guide reads repeat the same filters; short TTLs cut DB load by >80%. |

### 6.4 Maintenance
- **VACUUM / autovacuum on `listings`:** Lower `autovacuum_vacuum_scale_factor = 0.02` and `autovacuum_analyze_scale_factor = 0.01` on `listings` (default `0.2` waits for 480k dead rows at 2.4M scale). Run `VACUUM ANALYZE olx.listings` immediately after the nightly `W04` expiry job to keep visibility maps clean for Index-Only Scans (like `R03`).
- **Archiving old data:** Detach and drop partitions older than 12 months (`ALTER TABLE listings_part DETACH PARTITION listings_part_YYYY_MM CONCURRENTLY;`), after exporting to cold storage (S3).
- **Summary tables / materialized views:** Pre-compute heavy reports (`R12, R14, R15, R17, R18, R20, R21, R25`) in nightly materialized views refreshed with `REFRESH MATERIALIZED VIEW CONCURRENTLY`.

---

## 7. Conclusion

**Yes — the database is ready for next year's 20× volume.**
- All **30 / 30** queries meet their Phase 5 performance targets on 2.4M listings (`4,508.6 ms` total vs `10,852.5 ms` before fixes), and the entire database (`2.35 GB`) fits comfortably in RAM on a single PostgreSQL server.
- **Remaining risks as volume grows toward 100×:**
  1. `R13` (`208.0 ms` vs `250 ms` target) still scans `listings`; adding a tiny partial index `ON listings (boost_package_id) WHERE boost_package_id IS NOT NULL` will drop it under `1 ms`.
  2. `W04` depends on physical clustering of active rows; at 100×, switch `W04` to batched updates (e.g., 10k rows per batch) or partition by `posted_at`/`status` so expired pages stay localized.
  3. Full-table analytics (`R12`, `R18`, `R25` at `~0.8–1.2 s` at 20×) will approach the `5,000 ms` limit at 100× and should move to read replicas or nightly materialized views.
