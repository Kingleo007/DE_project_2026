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

- **R19 was the slowest query**, taking an average of 1807.603 ms (about 1.81 seconds).
- **R06** was the next slowest read query at 93.452 ms.
- **R25** took 63.047 ms on average.
- **R23 was the fastest query**, at 0.025 ms.
- **W04 was the slowest write query**, at 16.829 ms.

The plans showed many sequential scans, including scans on the larger `listings`, `chat_threads` and `chat_messages` tables. R19 is the main query to investigate during the optimization phase.

A sequential scan is not automatically bad. PostgreSQL may choose one when it estimates that reading a large part of a table is cheaper than using an index.

## 8. Files saved

The baseline results were saved here:

```text
benchmarks/results/before/
```

This folder contains the 30 raw plan files and `summary.csv`.

We kept these baseline results so that we can compare them with the timings after optimization.

## 9. Conclusion

The original workload was successfully benchmarked: all 30 queries ran three times, and their plans and timings were saved.

**R19 is the first query to investigate in the next phase.** The `before` results should be kept unchanged for a fair comparison with the optimized workload.
