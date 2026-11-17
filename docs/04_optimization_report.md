# Query Optimization Report

## Benchmark setup
The optimized benchmark used `sql/06_optimized_queries.sql` after applying `sql/05_indexes.sql`.

## Combined timing and optimization table

| Query | Type | Before avg | Problem in baseline plan | Optimization applied (plain language) | Optimized run 1 | Optimized run 2 | Optimized run 3 | Optimized avg | Improvement | Same result? |
|---|---|---:|---|---|---:|---:|---:|---:|---:|---|
| R01 | READ | 9.257 | Scans all listings | Added an index for active ads by category, city, and price | 0.409 | 0.367 | 0.329 | 0.368 | 96.0% | Needs proof |
| R02 | READ | 6.340 | Scans all listings and checks car details one by one | Added an index for the car filters | 0.049 | 0.041 | 0.048 | 0.046 | 99.3% | Needs proof |
| R03 | READ | 19.087 | Scans all titles for the text match | Added a text-search index for active ads and a price index | 0.780 | 0.714 | 0.690 | 0.728 | 96.2% | Needs proof |
| R04 | READ | 0.370 | Scans seller ratings to get the average | Added an index with seller IDs and rating stars | 0.125 | 0.081 | 0.074 | 0.093 | 74.8% | Needs proof |
| R05 | READ | 7.560 | Scans all listings for this seller | Added an index for seller, status, and listing ID | 0.058 | 0.067 | 0.072 | 0.066 | 99.1% | Needs proof |
| R06 | READ | 93.452 | Scans chats, listings, and messages | Looks up buyer and seller chats separately, then finds each latest message | 0.199 | 0.158 | 0.153 | 0.170 | 99.8% | Needs proof |
| R07 | READ | 7.054 | Scans messages before finding the user's chats | Finds the user's chats first, then checks unread messages in them | 0.094 | 0.098 | 0.092 | 0.095 | 98.7% | Needs proof |
| R08 | READ | 6.556 | Scans listings for category, model, and date | Added an index for category, model, and posting time | 1.404 | 1.353 | 1.463 | 1.407 | 78.5% | Needs proof |
| R09 | READ | 6.882 | Scans listings for nearby furniture | Added coordinate indexes for active furniture | 0.109 | 0.109 | 0.108 | 0.109 | 98.4% | Needs proof |
| R10 | READ | 6.079 | Scans active listings for expiry dates | Added an index on expiry time for active listings | 0.173 | 0.155 | 0.155 | 0.161 | 97.4% | Needs proof |
| R11 | READ | 2.007 | Scans all reports before joining listing titles | Counts open reports first, then looks up listing titles | 0.437 | 0.420 | 0.432 | 0.430 | 78.6% | Needs proof |
| R12 | READ | 34.843 | Must group every listing by seller and day | Kept the full scan because every listing is needed for this report | 52.561 | 52.910 | 53.163 | 52.878 | -51.8% | Needs proof |
| R13 | READ | 14.134 | `NOT IN` gives no rows when listing package IDs contain NULL | Used `NOT EXISTS` so unused packages are found correctly | 10.241 | 10.429 | 10.793 | 10.488 | 25.8% | Intentional NULL bug fix |
| R14 | READ | 9.575 | Extracts the year from every sale timestamp | Filters sales with a 2026 date range and an index | 6.792 | 6.661 | 6.631 | 6.695 | 30.1% | Needs proof |
| R15 | READ | 11.446 | Scans and groups most offers and listings | Kept the broad scan; most rows are used in this report | 11.731 | 10.756 | 10.905 | 11.131 | 2.8% | Same SQL; verify |
| R16 | READ | 11.761 | Scans favourites and listings for recent saves | Counts recent saves first, then joins active listings | 3.387 | 3.313 | 3.296 | 3.332 | 71.7% | Needs proof |
| R17 | READ | 12.505 | Groups views across nearly all listings | Kept the broad scan because most listings are included | 11.512 | 11.860 | 12.060 | 11.811 | 5.6% | Same SQL; verify |
| R18 | READ | 34.613 | Groups all listings to find duplicates | Added an index for seller, title, and price; planner still scans the table | 36.968 | 34.043 | 34.469 | 35.160 | -1.6% | Same SQL; verify |
| R19 | READ | 1807.603 | Repeats chat counts and latest-message lookups for each listing | Joins chats and messages once, then counts chats and finds the latest time | 0.919 | 0.907 | 0.934 | 0.920 | 99.9% | Needs proof |
| R20 | READ | 7.775 | Converts every posting timestamp to a date before filtering | Filters June by timestamp range and keeps the same day grouping | 0.845 | 0.936 | 0.998 | 0.926 | 88.1% | Needs proof |
| R21 | READ | 8.451 | Joins user names before ranking sellers | Ranks the top sellers first, then looks up their names | 2.100 | 2.090 | 2.104 | 2.098 | 75.2% | Needs proof |
| R22 | READ | 17.916 | Skips 50,000 rows to reach page 2,001 | Starts from the verified end of page 2,000 and reads the next 25 | 0.056 | 0.057 | 0.038 | 0.050 | 99.7% | Cursor checked; proof pending |
| R23 | READ | 0.025 | Already uses the phone-number index | No query change; kept the existing phone index | 0.023 | 0.022 | 0.022 | 0.022 | 10.7% | Same SQL; verify |
| R24 | READ | 11.440 | Scans active listings before counting by category | Uses the active-listing index for the category count | 1.982 | 3.530 | 4.424 | 3.312 | 71.0% | Same SQL; verify |
| R25 | READ | 63.047 | Reads and groups messages across many chats | Kept the query; the plan still scans the broad message history | 56.474 | 54.185 | 48.294 | 52.984 | 16.0% | Same SQL; verify |
| W01 | WRITE | 0.583 | Insert touches no rows to find | Indexes add work when a new listing is inserted | 1.144 | 1.081 | 1.154 | 1.126 | -93.2% | Same write; rolled back |
| W02 | WRITE | 9.149 | Scans listings to find the seller's oldest active ad | Uses the seller/status index to find the ad | 0.307 | 0.242 | 0.253 | 0.267 | 97.1% | Same write; rolled back |
| W03 | WRITE | 0.484 | Uses the primary-key index to find the buyer's latest chat | Uses the buyer/thread index; added cost is small | 0.367 | 0.356 | 0.357 | 0.360 | 25.6% | Same write; rolled back |
| W04 | WRITE | 16.829 | Scans all listings to find expired active ads | Uses the expiry index, but updating many rows still takes time | 95.536 | 34.931 | 27.597 | 52.688 | -213.1% | Same update; rolled back |
| W05 | WRITE | 1.228 | Scans offers to find pending offers for one listing | Uses an index to find pending offers and the highest price | 0.248 | 0.179 | 0.215 | 0.214 | 82.6% | Same update; rolled back |
| **Total of averages** | | **2238.051** | | | | | | **250.135** | **88.8% lower (8.9×)** | |

Improvement is `(before average − optimized average) / before average × 100`. Negative values mean the optimized query was slower. Each optimized run shown is itself an average of five executions; `Optimized avg` averages the three benchmark runs. The total is the sum of query averages, not total wall-clock time.

## Main findings

- R19 improved from 1,807.603 ms to an average of 0.920 ms after eliminating the repeated correlated work and using indexes for chat lookup.
- R06, R07, R02, R05, and R22 also fell below 0.4 ms in this run.
- R12 and R25 still read and aggregate broad portions of the dataset. Their sequential scans were not automatically a defect at this scale.
- W01 and W04 became slower. W04 increased by 35.859 ms per run on average; the expiry index narrows candidate rows, but each status update must still write the affected rows and maintain indexes. This increase is material for a batch job and should be investigated on the large dataset. W03 was slightly faster in the three optimized runs.
- R13 fixes a correctness bug: because some listings have `boost_package_id IS NULL`, `NOT IN` evaluates to unknown and the original query returns no packages. `NOT EXISTS` returns packages with no matching listing. This is an intentional correction, so the result is not byte-for-byte equal to the original wrong answer.

## Before/after plans for the five largest improvements

Each link contains the raw plans saved by the most recent benchmark invocation. Earlier optimized invocations were printed in the supplied terminal output, but the script replaced the plan files each time.

| Query | Before plan | After plan | Change observed |
|---|---|---|---|
| R19 | [baseline R19](../benchmarks/results/baseline/R19.txt) | [optimized R19](../benchmarks/results/optimized/R19.txt) | Sequential scans and correlated lookups → bitmap listing filter plus indexed thread/message lookups |
| R06 | [baseline R06](../benchmarks/results/baseline/R06.txt) | [optimized R06](../benchmarks/results/optimized/R06.txt) | Three table scans → buyer/seller thread indexes and latest-message index |
| R22 | [baseline R22](../benchmarks/results/baseline/R22.txt) | [optimized R22](../benchmarks/results/optimized/R22.txt) | Listing sequential scan with OFFSET → index-only keyset scan |
| R02 | [baseline R02](../benchmarks/results/baseline/R02.txt) | [optimized R02](../benchmarks/results/optimized/R02.txt) | Listing sequential scan → expression index on car attributes |
| R07 | [baseline R07](../benchmarks/results/baseline/R07.txt) | [optimized R07](../benchmarks/results/optimized/R07.txt) | Full message scan → selected-thread lookup and partial unread-message index |

## Result-equivalence proof status

The benchmark summary and `EXPLAIN ANALYZE` plans contain timings and plan row counts, but they do not contain result checksums or `EXCEPT` comparisons. Therefore, result equality has not yet been proven for the rewritten reads. Before marking those rows as same-result, compare original and optimized query outputs in the same unchanged database using bidirectional `EXCEPT ALL` (or compare row counts plus a stable checksum). R13 is the documented exception: it corrects the original NULL bug. R22 uses the last skipped row from the supplied seed CSV (`2025-11-16 07:06:36+05:30`, listing `70176`); re-check that boundary if the dataset changes.

## Index storage

Index sizes were not captured in the supplied benchmark output, so no storage figures are claimed here. Collect them after the indexes are created with:

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

The explicit exclusion removes common constraint indexes; if your database uses different names, compare the output with `sql/05_indexes.sql` and the schema's PRIMARY KEY/UNIQUE constraints.
