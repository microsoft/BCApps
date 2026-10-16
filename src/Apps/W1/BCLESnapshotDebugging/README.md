# BCLE Snapshot Debugging and Profiling

This sandbox-only sample contains two independent demonstrations. It retains the
BCLE Snapshot Debugging app ID, name, and BC 29 minimum application and platform
versions. The demo apps use publisher **Artur Ventsel** because cloud environments
do not permit tenant-scoped publication with publisher **Microsoft**.

## Snapshot debugging

Codeunit 99999, **Advanced Posting Logic**, subscribes to purchase document posting.
It raises **Advanced checks failed** when Payment Terms Code, Payment Method Code,
or Payment Reference is blank.

## Sampling profiling

The profiling objects use IDs 70950 through 70959. They generate deliberately
inefficient SQL and AL work against synthetic data in the app's own buffer table.
Do not run this workload in a production environment or against shared resources
that cannot tolerate sustained load.

After compiling and publishing the app to a sandbox:

1. Assign permission set **BCLE PROFILING DEMO** to the presenting user.
2. Open **BCLE Sampling Profiler Demo** (page 70950).
3. Select **1. Seed heavy SQL data**. The default creates 10,000 BLOB rows.
4. Select **2. Start scheduled workload**.
5. Select **Refresh progress** to see the current phase, anchor session ID, workload
   session ID, and completed pass count.
6. Use external sampling profiling tools to capture the background workload.
7. Select **Stop scheduled workload** after the demonstration.

The controller initializes or raises the row count to at least 10,000 and the run
window to at least 30 minutes. The default interval is 10 seconds between passes.
Each pass runs a grouped, unindexed self-join twice, then loads and processes BLOBs
one row at a time. These inefficiencies are intentional demonstration material.

The initial pass executes in the long-lived Task Scheduler anchor session.
Subsequent passes execute in fresh background sessions, providing separate
profiling activities. The page exposes both numeric NST session IDs; use the
anchor session ID when configuring an external profiling schedule. The app does
not start or collect profiler captures itself.

The **Run once in web session** action executes the same workload synchronously in
the current web session instead of scheduling background passes.

The profiling workload does not post purchase documents, and purchase posting does
not start the profiling workload. Seeding replaces only the synthetic profiling
buffer data. To remove all sample data after the event, uninstall the sample app
with data deletion from the disposable sandbox.

## Test project

The separate `test` project depends on this app, **Library Assert**, and
**Library Variable Storage**. Codeunit 99998, **My Demo Close Income Tests**,
contains `NoDimensionsConsolidatesClosingJournalLinesWithoutARC`.

The test posts three transactions for 100, 200, and 300 to a new income statement
account, explicitly clears the user's selected dimensions for report 70955,
**My Demo Close Income Statement**, and closes into an empty journal batch. It
expects a closing total of -600 and exactly one closing line.

The current test deliberately contains a fixture mistake for the snapshot demo:
the 300 transaction is posted one day after the fiscal year ends, while the
expected amount still includes all three transactions. The fixed report correctly
creates one closing line for -300, and the test intentionally fails the amount
assertion. The original consolidation bug is not reintroduced. To restore the
passing regression, post the third transaction on `FiscalYearEndingDate` again.
The additional reporting currency variation is not covered.

The test uses automatic rollback and ignores nested commits so its setup changes,
accounts, fiscal year, and journal/ledger entries are rolled back even on failure.
Its fixtures use public application APIs and the installed test libraries without
requiring **Tests-TestLibraries** or provisioning another environment.

For snapshot debugging, arm report snappoints in the G/L Entry `OnPreDataItem`
trigger after setting its posting-date range, `OnAfterGetRecord` after buffer
accumulation, and `OnPostDataItem` before emitting closing lines. An additional
snappoint before `RunWithCheck` in the test's posting helper shows each original
transaction's posting date and amount. The snapshot should explain why only the
100 and 200 transactions fall within the report's fiscal-year filter.
Initialize the snapshot
context for **WebClient**, run codeunit 99998 through the snapshot proxy's
`run_tests`, and always finalize the context with `stop_snapshot_debugging`,
including after a test failure. The test itself reproduces the
scenario; no manual financial posting is required.
