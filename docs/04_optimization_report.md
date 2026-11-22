# Query Optimization Report

## Benchmark setup
The optimized benchmark ran `./benchmarks/run_benchmark.sh karun optimized 3 sql/06_optimized_queries.sql` after applying `sql/05_indexes.sql`. Every timing below matches `benchmarks/results/baseline/` and `benchmarks/results/optimized/`.

## Combined timing and optimization table

| Query | Type | Before avg | Problem in baseline plan | Optimization applied (plain language) | Optimized run 1 | Optimized run 2 | Optimized run 3 | Optimized avg | Improvement | Same result? |
|---|---|---:|---|---|---:|---:|---:|---:|---:|---|
| R01 | READ | 9.257 | Scans all listings | Added an index for active ads by category, city, and price | 11.010 | 0.362 | 0.337 | 3.903 | 57.8% | Needs proof |
| R02 | READ | 6.340 | Scans all listings and checks car details one by one | Added an index for the car filters | 0.770 | 0.055 | 0.048 | 0.291 | 95.4% | Needs proof |
| R03 | READ | 19.087 | Scans all titles for the text match | Added a text-search index for active ads and a price index | 20.265 | 0.632 | 0.644 | 7.180 | 62.4% | Needs proof |
| R04 | READ | 0.370 | Scans seller ratings to get the average | Added an index with seller IDs and rating stars | 0.926 | 0.066 | 0.070 | 0.354 | 4.3% | Needs proof |
| R05 | READ | 7.560 | Scans all listings for this seller | Added an index for seller, status, and listing ID | 0.409 | 0.060 | 0.054 | 0.174 | 97.7% | Needs proof |
| R06 | READ | 93.452 | Scans chats, listings, and messages | Looks up buyer and seller chats separately, then finds each latest message | 4.799 | 0.142 | 0.152 | 1.698 | 98.2% | Needs proof |
| R07 | READ | 7.054 | Scans messages before finding the user's chats | Finds the user's chats first, then checks unread messages in them | 0.116 | 0.078 | 0.080 | 0.091 | 98.7% | Needs proof |
| R08 | READ | 6.556 | Scans listings for category, model, and date | Added an index for category, model, and posting time | 15.018 | 1.225 | 1.215 | 5.819 | 11.2% | Needs proof |
| R09 | READ | 6.882 | Scans listings for nearby furniture | Added coordinate indexes for active furniture | 1.195 | 0.089 | 0.087 | 0.457 | 93.4% | Needs proof |
| R10 | READ | 6.079 | Scans active listings for expiry dates | Added an index on expiry time for active listings | 3.264 | 0.146 | 0.162 | 1.191 | 80.4% | Needs proof |
| R11 | READ | 2.007 | Scans all reports before joining listing titles | Counts open reports first, then looks up listing titles | 7.022 | 0.415 | 0.392 | 2.610 | -30.0% | Needs proof |
| R12 | READ | 34.843 | Must group every listing by seller and day | Kept the full scan because every listing is needed for this report | 56.292 | 55.006 | 54.337 | 55.212 | -58.5% | Needs proof |
| R13 | READ | 14.134 | `NOT IN` gives no rows when listing package IDs contain NULL | Used `NOT EXISTS` so unused packages are found correctly | 9.767 | 10.124 | 10.315 | 10.069 | 28.8% | Intentional NULL bug fix |
| R14 | READ | 9.575 | Extracts the year from every sale timestamp | Filters sales with a 2026 date range and an index | 7.863 | 6.905 | 6.732 | 7.167 | 25.1% | Needs proof |
| R15 | READ | 11.446 | Scans and groups most offers and listings | Kept the broad scan; most rows are used in this report | 13.279 | 11.624 | 11.844 | 12.249 | -7.0% | Same SQL; verify |
| R16 | READ | 11.761 | Scans favourites and listings for recent saves | Counts recent saves first, then joins active listings | 7.977 | 3.700 | 3.618 | 5.098 | 56.7% | Needs proof |
| R17 | READ | 12.505 | Groups views across nearly all listings | Kept the broad scan because most listings are included | 12.739 | 12.939 | 12.470 | 12.716 | -1.7% | Same SQL; verify |
| R18 | READ | 34.613 | Groups all listings to find duplicates | Added an index for seller, title, and price; planner still scans the table | 34.228 | 34.808 | 33.508 | 34.181 | 1.2% | Same SQL; verify |
| R19 | READ | 1807.603 | Repeats chat counts and latest-message lookups for each listing | Joins chats and messages once, then counts chats and finds the latest time | 17.161 | 0.952 | 0.937 | 6.350 | 99.6% | Needs proof |
| R20 | READ | 7.775 | Converts every posting timestamp to a date before filtering | Filters June by timestamp range and keeps the same day grouping | 1.459 | 0.783 | 0.791 | 1.011 | 87.0% | Needs proof |
| R21 | READ | 8.451 | Joins user names before ranking sellers | Ranks the top sellers first, then looks up their names | 4.679 | 2.127 | 2.120 | 2.975 | 64.8% | Needs proof |
| R22 | READ | 17.916 | Skips 50,000 rows to reach page 2,001 | Starts from the verified end of page 2,000 and reads the next 25 | 0.026 | 0.027 | 0.024 | 0.026 | 99.9% | Cursor checked; proof pending |
| R23 | READ | 0.025 | Already uses the phone-number index | No query change; kept the existing phone index | 0.467 | 0.027 | 0.024 | 0.173 | -592.0% | Same SQL; verify |
| R24 | READ | 11.440 | Scans active listings before counting by category | Uses an active-listing index for the category count | 2.380 | 1.895 | 1.923 | 2.066 | 81.9% | Same SQL; verify |
| R25 | READ | 63.047 | Reads and groups messages across many chats | Kept the query; the plan still scans the broad message history | 61.653 | 56.308 | 56.698 | 58.220 | 7.7% | Same SQL; verify |
| W01 | WRITE | 0.583 | Insert touches no rows to find | Indexes add work when a new listing is inserted | 3.690 | 1.177 | 1.100 | 1.989 | -241.2% | Same write; rolled back |
| W02 | WRITE | 9.149 | Scans listings to find the seller's oldest active ad | Uses the seller/status index to find the ad | 1.247 | 0.262 | 0.257 | 0.589 | 93.6% | Same write; rolled back |
| W03 | WRITE | 0.484 | Uses the primary-key index to find the buyer's latest chat | Uses the buyer/thread index; Run 1 cold cache raises the average | 1.516 | 0.370 | 0.370 | 0.752 | -55.4% | Same write; rolled back |
| W04 | WRITE | 16.829 | Scans all listings to find expired active ads | Uses the expiry index, but updating many rows across 12 indexes is slow | 794.841 | 23.107 | 23.242 | 280.397 | -1566.2% | Same update; rolled back |
| W05 | WRITE | 1.228 | Scans offers to find pending offers for one listing | Uses an index to find pending offers and the highest price | 1.409 | 0.189 | 0.173 | 0.590 | 52.0% | Same update; rolled back |
| **Total of averages** | | **2238.051** | | | | | | **515.598** | **77.0% lower (4.3×)** | |

Improvement is `(before average − optimized average) / before average × 100`. Negative values mean the optimized average was slower. Each query ran 3 times; Run 1 includes cold buffer-cache reads while Runs 2 and 3 reflect warm cache. The total is the sum of query averages, not wall-clock time.

## Main findings

- `R19` dropped from `1,807.603 ms` to `6.350 ms` average (`0.937 ms` warm) after removing correlated subqueries and indexing chat lookups.
- `R22` (`0.026 ms`), `R07` (`0.091 ms`), `R05` (`0.174 ms`), `R02` (`0.291 ms`), and `R06` (`1.698 ms`, `0.142 ms` warm) saw 95–99.9% speed-ups.
- `R12`, `R15`, `R17`, `R18`, and `R25` scan most of their tables for full analytics/grouping, so sequential scans remain expected at seed size.
- Write overhead: `W01` (`0.583 → 1.989 ms`), `W03` (`0.484 → 0.752 ms`), and especially `W04` (`16.829 → 280.397 ms`; `794.841 ms` on cold Run 1, `~23.2 ms` warm) got slower because updating `listings` maintains 12 extra indexes. `W02` and `W05` got faster.
- `R13` fixes a NULL bug: `NOT IN` returns 0 rows whenever `listings.boost_package_id` contains `NULL`. `NOT EXISTS` returns the unused packages correctly.

## Before/after plans for the five largest improvements

| Query | Before plan | After plan | Change observed |
|---|---|---|---|
| R19 | [baseline R19](../benchmarks/results/baseline/R19.txt) | [optimized R19](../benchmarks/results/optimized/R19.txt) | Sequential scans + correlated subqueries → bitmap listing filter + indexed thread/message lookups |
| R22 | [baseline R22](../benchmarks/results/baseline/R22.txt) | [optimized R22](../benchmarks/results/optimized/R22.txt) | Full scan + `OFFSET 50000` → keyset cursor stopping after 25 rows |
| R07 | [baseline R07](../benchmarks/results/baseline/R07.txt) | [optimized R07](../benchmarks/results/optimized/R07.txt) | Full message scan → selected-thread lookup + partial unread-message index |
| R06 | [baseline R06](../benchmarks/results/baseline/R06.txt) | [optimized R06](../benchmarks/results/optimized/R06.txt) | Three table scans → buyer/seller thread indexes + latest-message index |
| R05 | [baseline R05](../benchmarks/results/baseline/R05.txt) | [optimized R05](../benchmarks/results/optimized/R05.txt) | Sequential scan on listings → index-only scan on `(seller_id, status, listing_id)` |

## Result-equivalence proof status

The benchmark plans record timings and row counts, not checksums or `EXCEPT ALL` diffs. Compare original and optimized read outputs with bidirectional `EXCEPT ALL` before marking rows verified. `R13` is the documented NULL-bug fix.

## Index storage

Total storage measured on `karun` (seed): **162 MB** database (**64 MB** tables, **90 MB** indexes). Per-index sizes can be listed with:

```sql
SELECT i.relname AS index_name,
       pg_size_pretty(pg_relation_size(i.oid)) AS index_size,
       t.relname AS table_name,
       pg_size_pretty(pg_relation_size(t.oid)) AS table_size
FROM pg_class i
JOIN pg_index x ON x.indexrelid = i.oid
JOIN pg_class t ON t.oid = x.indrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'olx'
  AND i.relname NOT IN ('cities_pkey', 'categories_pkey', 'boost_packages_pkey',
                        'users_pkey', 'users_phone_key', 'users_email_key',
                        'listings_pkey', 'chat_threads_pkey', 'chat_messages_pkey',
                        'offers_pkey', 'favourites_pkey', 'reports_pkey',
                        'seller_ratings_pkey')
ORDER BY pg_relation_size(i.oid) DESC;
```