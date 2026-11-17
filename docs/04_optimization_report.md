# Phase 4 — Query Optimization Report

## Benchmark setup

The comparison uses the committed baseline on the 120,000-listing seed dataset and the optimized benchmark run recorded under `benchmarks/results/optimized/`. Baseline timings average three runs; optimized timings average five runs, as required by the Phase 4 command. All measurements are milliseconds from the same database run (`karun`) on PostgreSQL 18.6, as recorded for the project. The optimized benchmark was run with `sql/06_optimized_queries.sql` after applying `sql/05_indexes.sql`.

The first five timing columns below preserve the Phase 3 run-by-run values. The `After` value is the five-run optimized average from `summary.csv`.

## Combined timing and optimization table

| Query | Type | Before run 1 | Before run 2 | Before run 3 | Before avg | Problem in baseline plan | Optimization applied | After avg (5 runs) | Improvement | Same result? |
|---|---|---:|---:|---:|---:|---|---|---:|---:|---|
| R01 | READ | 10.553 | 8.655 | 8.564 | 9.257 | Sequential scan of listings | Partial B-tree on active category, city, and price | 0.425 | 95.4% (21.8×) | Needs equivalence proof |
| R02 | READ | 6.952 | 6.194 | 5.874 | 6.340 | Sequential scan; JSON filters applied row by row | Partial expression index on car fuel, year, and kilometres | 0.047 | 99.3% (134.9×) | Needs equivalence proof |
| R03 | READ | 19.094 | 19.215 | 18.952 | 19.087 | Sequential scan for leading-wildcard `ILIKE` | Partial trigram GIN on active titles; active price B-tree for ordering | 0.717 | 96.2% (26.6×) | Needs equivalence proof |
| R04 | READ | 0.377 | 0.370 | 0.363 | 0.370 | Rating rows scanned to calculate seller average | Covering index on ratings by seller including stars | 0.198 | 46.5% (1.9×) | Needs equivalence proof |
| R05 | READ | 7.672 | 7.487 | 7.521 | 7.560 | Sequential scan of listings for seller 1042 | Covering index on seller, status, and listing ID | 0.069 | 99.1% (109.6×) | Needs equivalence proof |
| R06 | READ | 95.318 | 97.732 | 87.306 | 93.452 | Sequential scans of threads, listings, and messages; OR spans buyer/seller | UNION of buyer and seller thread paths; indexed latest-message lookup | 0.327 | 99.7% (285.8×) | Needs equivalence proof |
| R07 | READ | 6.166 | 8.855 | 6.142 | 7.054 | Scans unread messages before narrowing to the user's conversations | UNION of user threads, then partial index for unread messages | 0.093 | 98.7% (75.8×) | Needs equivalence proof |
| R08 | READ | 6.461 | 7.049 | 6.159 | 6.556 | Sequential scan for category/model/date filters | B-tree expression index on category and model with posted time | 1.461 | 77.7% (4.5×) | Needs equivalence proof |
| R09 | READ | 6.666 | 7.222 | 6.759 | 6.882 | Sequential scan for active furniture in the coordinate box | Partial coordinate indexes; plan used the longitude index | 0.121 | 98.2% (56.9×) | Needs equivalence proof |
| R10 | READ | 6.006 | 6.358 | 5.873 | 6.079 | Sequential scan for active ads in an expiry range | Partial B-tree on expiry time for active ads | 0.165 | 97.3% (36.8×) | Needs equivalence proof |
| R11 | READ | 2.034 | 2.003 | 1.984 | 2.007 | Sequential scan of reports; join occurs before report aggregation | Partial covering index on open reports; aggregate before joining titles | 1.011 | 49.6% (2.0×) | Needs equivalence proof |
| R12 | READ | 34.553 | 34.066 | 35.909 | 34.843 | Full-table grouping by seller and posting date | Kept sequential scan; query must group all listings and the plan still chose a scan | 52.566 | -50.9% (0.7×) | Needs equivalence proof |
| R13 | READ | 13.942 | 14.103 | 14.357 | 14.134 | `NOT IN` returns no rows when its subquery contains NULL package IDs | Replaced with `NOT EXISTS`; full scan remains reasonable for the small package table | 10.372 | 26.6% (1.4×) | Intentional correction: original NULL bug fixed |
| R14 | READ | 9.456 | 9.892 | 9.377 | 9.575 | Year extracted from every `sold_at` value | Replaced `EXTRACT(YEAR...)` with a 2026 timestamp range and partial sold-date index | 6.801 | 29.0% (1.4×) | Needs equivalence proof |
| R15 | READ | 11.723 | 11.487 | 11.129 | 11.446 | Broad aggregation scans offers and listings | Kept scans; query aggregates most offer rows, so index access was not chosen | 11.379 | 0.6% (1.0×) | Unchanged SQL; verify in proof run |
| R16 | READ | 11.883 | 11.665 | 11.735 | 11.761 | Scans favourites and listings for recent saves | B-tree on save time and listing ID; aggregate favourites before joining active ads | 3.562 | 69.7% (3.3×) | Needs equivalence proof |
| R17 | READ | 13.155 | 12.207 | 12.152 | 12.505 | Broad grouped average over listings | Kept sequential aggregation; most listing rows contribute | 12.122 | 3.1% (1.0×) | Unchanged SQL; verify in proof run |
| R18 | READ | 35.030 | 34.361 | 34.449 | 34.613 | Full-table duplicate grouping by seller, title, and price | Added composite grouping index; planner still chose sequential scan | 34.089 | 1.5% (1.0×) | Unchanged SQL; verify in proof run |
| R19 | READ | 1841.215 | 1750.793 | 1830.801 | 1807.603 | Correlated count and latest-message subqueries repeatedly visit chat tables | Replaced with LEFT JOIN aggregation and `COUNT(DISTINCT thread_id)`; indexes on threads/messages | 1.059 | 99.9% (1706.0×) | Needs equivalence proof |
| R20 | READ | 7.867 | 7.565 | 7.894 | 7.775 | `posted_at::date` prevents a direct timestamp range scan | Replaced date predicate with June timestamp boundaries; retained local-date grouping | 0.926 | 88.1% (8.4×) | Needs equivalence proof |
| R21 | READ | 8.493 | 8.536 | 8.323 | 8.451 | Full rating aggregation before user lookup | Aggregate and limit top 20 sellers before joining user names | 2.349 | 72.2% (3.6×) | Needs equivalence proof |
| R22 | READ | 16.833 | 21.014 | 15.900 | 17.916 | Sequential scan and discard 50,000 rows for OFFSET pagination | Keyset seek from the verified page-2,000 boundary; descending covering index | 0.059 | 99.7% (303.7×) | Cursor matches seed CSV; SQL equivalence proof pending |
| R23 | READ | 0.024 | 0.026 | 0.024 | 0.025 | Already uses unique phone index | No rewrite; existing unique phone index handles lookup | 0.084 | -236.0% (3.4× slower) | Unchanged SQL; likely timing variance; verify |
| R24 | READ | 11.397 | 11.549 | 11.373 | 11.440 | Sequential scan of active ads before category rollup | Active partial index can feed the category count | 4.641 | 59.4% (2.5×) | Unchanged SQL; verify in proof run |
| R25 | READ | 77.406 | 55.652 | 56.083 | 63.047 | Full scans and aggregation over messages, threads, and listings | Existing message/thread indexes were not selected for this broad aggregation | 55.037 | 12.7% (1.1×) | Unchanged SQL; verify in proof run |
| W01 | WRITE | 0.632 | 0.556 | 0.561 | 0.583 | Insert has no lookup scan | Index maintenance adds work to listing insert | 1.348 | -131.2% (2.3× slower) | Same write; benchmark rolls it back |
| W02 | WRITE | 9.446 | 9.031 | 8.970 | 9.149 | Sequential scan to find seller's oldest active listing | Seller/status/listing index finds target directly | 0.403 | 95.6% (22.7×) | Same write; benchmark rolls it back |
| W03 | WRITE | 0.492 | 0.482 | 0.477 | 0.484 | Primary-key lookup for most recent buyer thread | Buyer/thread index supports lookup; added index maintenance is small | 0.545 | -12.6% (1.1× slower) | Same write; benchmark rolls it back |
| W04 | WRITE | 16.488 | 16.734 | 17.264 | 16.829 | Sequential scan to locate expired active ads | Partial expiry index narrows target rows; updating status still costs time | 29.932 | -77.9% (1.8× slower) | Same update; benchmark rolls it back |
| W05 | WRITE | 1.272 | 1.216 | 1.196 | 1.228 | Sequential scan to find pending offers for one listing | Composite listing/status/price index finds offers and top offer | 0.417 | 66.0% (2.9×) | Same update; benchmark rolls it back |
| **Total of averages** | | | | | **2238.051** | | | **232.325** | **89.6% lower (9.6×)** | |

Improvement is `(before average − after average) / before average × 100`. Negative values mean the optimized run was slower. The total compares the sum of per-query averages, not benchmark wall-clock time. The optimized run used five samples while the baseline used three.

## Main findings

- R19 improved from 1,807.603 ms to 1.059 ms after eliminating the repeated correlated work and using indexes for chat lookup.
- R06, R07, R02, R05, and R22 also fell below 0.4 ms in this run.
- R12 and R25 still read and aggregate broad portions of the dataset. Their sequential scans were not automatically a defect at this scale.
- W01, W03, and W04 became slower. W04 increased by 13.103 ms per run on average; the expiry index narrows candidate rows, but each status update must still write the affected rows and maintain indexes. The observed increase is material for a batch job and should be considered again on the large dataset.
- R13 fixes a correctness bug: because some listings have `boost_package_id IS NULL`, `NOT IN` evaluates to unknown and the original query returns no packages. `NOT EXISTS` returns packages with no matching listing. This is an intentional correction, so the result is not byte-for-byte equal to the original wrong answer.

## Before/after plans for the five largest improvements

Each link contains the full raw plans for all recorded runs.

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
