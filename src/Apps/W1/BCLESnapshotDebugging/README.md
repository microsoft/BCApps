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

The separate `test` project is a scaffold for future automated tests. It depends
on this app, **Library Assert**, and **Library Variable Storage**; it contains no
test cases yet. Add **Tests-TestLibraries** when tests need application test
helpers and that package is available in the target environment.
