# Baseline Benchmark

## 1. What we wanted to do
Before optimizing any SQL queries, we measured how the original workload performs.

We ran 30 queries:
- 25 read queries: `R01` to `R25`
- 5 write queries: `W01` to `W05`
- Each query was executed 3 times.
The workload file was kept unchanged.

## 2. Database and dataset
| Detail | Value |
|---|---|
| Benchmark date | 11 November 2026 |
| PostgreSQL | 18.6 |
| Database | `karun` |
| Schema | `olx` |
| Total queries | 30 |
| Runs per query | 3 |

### Table row counts
| Table | Rows |
|---|---:|
| cities | 10 |
| categories | 12 |
| boost_packages | 6 |
| users | 50,000 |
| listings | 120,000 |
| chat_threads | 59,855 |
| chat_messages | 209,529 |
| offers | 19,943 |
| favourites | 70,000 |
| reports | 7,999 |
| seller_ratings | 11,244 |

## 3. Preparation
First, we connected to the database:

```bash
psql -U karun -d karun
```

All project tables are inside the `olx` schema.
We loaded the dataset and checked the table row counts and relationships. The data loading was already complete, so we did not load the CSV files again.
We then updated the planner statistics by running `ANALYZE` on the tables:

```sql
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
```

This helps PostgreSQL make better decisions when choosing how to execute queries.

## 4. Small changes needed for write queries

While checking the workload, we found that some INSERT queries did not provide values for required `NOT NULL` columns.
To allow those workload queries to run without changing the workload file, we added defaults to the database:

```sql
ALTER TABLE olx.listings
ALTER COLUMN is_negotiable SET DEFAULT FALSE;

ALTER TABLE olx.listings
ALTER COLUMN view_count SET DEFAULT 0;

ALTER TABLE olx.chat_messages
ALTER COLUMN is_read SET DEFAULT FALSE;
```

These defaults are used when an INSERT does not provide a value for those columns. Existing rows were not changed.

## 5. Running the benchmark

We used the benchmark script already present in the project:

```bash
./benchmarks/run_benchmark.sh <database_name (here = karun)> before
```

The script:
- Runs all 30 queries.
- Executes each query 3 times.
- Records execution plans and timings.
- Saves the results in `benchmarks/results/before/`.

The benchmark output included:
- `R01.txt` to `R25.txt`
- `W01.txt` to `W05.txt`
- `summary.csv`

The write queries are run in a way that rolls back their changes, so benchmark testing does not leave those test writes in the database.

We checked that the summary contained 30 query results:

```bash
wc -l benchmarks/results/before/summary.csv
```

The output was `31` (one header row plus 30 query rows).

We also checked the saved plan files:

```bash
ls -lh benchmarks/results/before/
```

## 6. Baseline timings

All times are in milliseconds. Each average is based on the three recorded runs.

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01 | READ | 10.553 | 8.655 | 8.564 | 9.257 |
| R02 | READ | 6.952 | 6.194 | 5.874 | 6.340 |
| R03 | READ | 19.094 | 19.215 | 18.952 | 19.087 |
| R04 | READ | 0.377 | 0.370 | 0.363 | 0.370 |
| R05 | READ | 7.672 | 7.487 | 7.521 | 7.560 |
| R06 | READ | 95.318 | 97.732 | 87.306 | 93.452 |
| R07 | READ | 6.166 | 8.855 | 6.142 | 7.054 |
| R08 | READ | 6.461 | 7.049 | 6.159 | 6.556 |
| R09 | READ | 6.666 | 7.222 | 6.759 | 6.882 |
| R10 | READ | 6.006 | 6.358 | 5.873 | 6.079 |
| R11 | READ | 2.034 | 2.003 | 1.984 | 2.007 |
| R12 | READ | 34.553 | 34.066 | 35.909 | 34.843 |
| R13 | READ | 13.942 | 14.103 | 14.357 | 14.134 |
| R14 | READ | 9.456 | 9.892 | 9.377 | 9.575 |
| R15 | READ | 11.723 | 11.487 | 11.129 | 11.446 |
| R16 | READ | 11.883 | 11.665 | 11.735 | 11.761 |
| R17 | READ | 13.155 | 12.207 | 12.152 | 12.505 |
| R18 | READ | 35.030 | 34.361 | 34.449 | 34.613 |
| R19 | READ | 1841.215 | 1750.793 | 1830.801 | 1807.603 |
| R20 | READ | 7.867 | 7.565 | 7.894 | 7.775 |
| R21 | READ | 8.493 | 8.536 | 8.323 | 8.451 |
| R22 | READ | 16.833 | 21.014 | 15.900 | 17.916 |
| R23 | READ | 0.024 | 0.026 | 0.024 | 0.025 |
| R24 | READ | 11.397 | 11.549 | 11.373 | 11.440 |
| R25 | READ | 77.406 | 55.652 | 56.083 | 63.047 |
| W01 | WRITE | 0.632 | 0.556 | 0.561 | 0.583 |
| W02 | WRITE | 9.446 | 9.031 | 8.970 | 9.149 |
| W03 | WRITE | 0.492 | 0.482 | 0.477 | 0.484 |
| W04 | WRITE | 16.488 | 16.734 | 17.264 | 16.829 |
| W05 | WRITE | 1.272 | 1.216 | 1.196 | 1.228 |
| **Total of averages** | | | | | **2238.051** |

The total is the sum of the 30 average query times. It is not the total wall-clock time taken by the benchmark script.

## 7. What the results tell us

Query | Scan Type | Why is it fast or slow?
R01 | Parallel Seq Scan on listings | Scans many listings to find matching records, making it moderately slow.
R02 | Seq Scan on listings | Checks listings to find matching records; no suitable index is used.
R03 | Seq Scan on listings | Scans a large number of listings to apply filters, increasing execution time.
R04 | Index Scan on listings and users; Seq Scan on seller_ratings | Uses indexes to locate records quickly, resulting in very low execution time.
R05 | Seq Scan on listings | Scans listings to find the required records, resulting in moderate execution time.
R06 | Seq Scan on chat_threads, listings and chat_messages | Scans multiple large tables, making it one of the slower queries.
R07 | Seq Scan on chat_messages; Index Scan on chat_threads and listings | Scans chat messages but uses indexes for related lookups, keeping execution time relatively low.
R08 | Seq Scan on listings | Scans listings to apply the required conditions.
R09 | Seq Scan on listings | Checks listings for matching records; execution time remains relatively low.
R10 | Seq Scan on listings | Performs a table scan, but the query conditions are not very expensive.
R11 | Seq Scan on reports; Index Scan on listings | Scans reports and uses an index to find related listings, resulting in fast execution.
R12 | Seq Scan on listings | Processes a large number of listing records, resulting in higher execution time.
R13 | Seq Scan on boost_packages and listings | Scans listings and boost packages to find matching records.
R14 | Seq Scan on listings and categories | Scans both tables to retrieve the required information.
R15 | Seq Scan on listings, offers and categories | Scans multiple tables and processes related records, increasing execution time.
R16 | Seq Scan on listings and favourites | Scans listings and favourites to find matching records.
R17 | Seq Scan on listings and categories | Scans listings and categories to retrieve the required results.
R18 | Seq Scan on listings | Processes a large number of listings, resulting in higher execution time.
R19 | Seq Scan on listings, chat_threads and chat_messages | Very slow because it repeatedly processes large tables through correlated subqueries.
R20 | Seq Scan on listings | Scans listings to find the required records; execution time is relatively low.
R21 | Seq Scan on seller_ratings and users | Scans both tables to retrieve the required information.
R22 | Seq Scan on listings | Processes many listing records, resulting in moderate execution time.
R23 | Index Scan on users_phone_key | Uses an index to locate a user directly using their phone number, making it extremely fast.
R24 | Seq Scan on listings and categories | Scans both tables to find the required results.
R25 | Seq Scan on chat_messages, chat_threads, listings and categories | Scans multiple tables and processes related chat and listing data, making it relatively slow.
W01 | No scan | Simple INSERT operation; no table scan is required.
W02 | Seq Scan on listings; Index Scan on listings primary key | Scans listings to identify matching records before performing the update.
W03 | Index Scan on chat_threads primary key | Uses the primary-key index to locate the target record quickly.
W04 | Seq Scan on listings | Scans listings to identify the records to update, making it the slowest write query.
W05 | Seq Scan on offers | Scans offers to locate the records required for the write operation.

## Main Findings

1. R19 - Main bottleneck: Its average execution time is 1807.603 ms. Repeated processing of large tables makes it significantly slower than the other queries.
2. R06 and R25: Both involve multiple large tables and sequential scans, resulting in higher execution times.
3. R23 - Best performing read: Its index scan on users_phone_key allows PostgreSQL to find the record extremely quickly.
4. W04 - Slowest write: Its sequential scan on listings increases the time required to identify records for updating.
5. Sequential scans: These appear frequently because PostgreSQL reads table records to find matching data. They are not necessarily inefficient; their performance depends on table size and query conditions.

Note: A query can use both sequential and index scans. The scan type alone does not determine performance; the amount of data processed and the query structure also matter.
Sequential Scan =>    checks every row in the table to find matching records
Index Scan =>     uses an index to find the required rows directly, instead of checking every row

## Conclusion

The original workload was successfully benchmarked: all 30 queries ran three times, and their plans and timings were saved.

**R19 is the first query to investigate in the next phase.** The `before` results should be kept unchanged for a fair comparison with the optimized workload.
