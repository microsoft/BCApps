# Power BI Report Synchronization

The report synchronizer uploads Power BI reports (PBIX files) on behalf of users. It supports multiple report types — system blobs, customer uploads, and partner-defined deployable reports — through a polymorphic interface design. Each upload step runs inside a `Codeunit.Run()` boundary so that a single failure is captured and recorded without crashing the job.

## How the pieces fit together

```
                        ┌─────────────────────────────┐
                        │   Report Synchronizer (6325)│  Job queue entry point.
                        │   Orchestrator — owns the   │  Loops over reports, runs steps,
                        │   error-isolation loop.     │  handles failures.
                        └──────────────┬──────────────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    ▼                                     ▼
     ┌──────────────────────────┐        ┌──────────────────────────────┐
     │  Report Aggregator (6327)│        │  Upload Step Runner (6334)   │
     │  Loads pending reports   │        │  Executes ONE upload step    │
     │  from all sources into   │        │  inside a Codeunit.Run()     │
     │  a unified iterator.     │        │  boundary.                   │
     └──────────────────────────┘        └──────────────────────────────┘
                    │                                      │
                    │ returns                              │ uses
                    ▼                                      ▼
    ┌────────────────────────────────────────────────────────────────────┐
    │                        Interfaces                                  │
    │                                                                    │
    │  «Power BI Uploadable Report»         «Power BI Upload Tracker»   │
    │  What to upload: name, PBIX stream,   How progress is persisted:  │
    │  version, dataset parameters.         status, transitions, retry, │
    │                                       failure recording.          │
    └────────────────────────────────────────────────────────────────────┘
                    │                                      │
        ┌───────────┼───────────┐              ┌───────────┴──────────┐
        ▼           ▼           ▼              ▼                      ▼
   System blob  Customer   Deployable    System Upload         Deploy Upload
   Report       Report     Report Impl   Tracker (6322)        Tracker (6329)
   (6323)       (6326)     (6330)        wraps Report          wraps Deployment +
                           adapts enum   Uploads table         DeploymentState tables
                           → interface                         (step-level history)
```

**Upload state machine** — each transition is one step runner call:

`NotStarted → ImportStarted → ImportFinished → ParametersUpdated → DataRefreshed → Completed`

At any step the report can fail (error recorded, loop moves on) or schedule a retry (job queue re-runs later).

### Uploadable Report vs. Deployable Report

`Uploadable Report` is the internal interface — the *how to upload* contract. It covers the full upload lifecycle (stream, tracker, finalize) and is implemented by all report types. `Deployable Report` is the public interface — the *what to upload* contract. It only asks for the essentials (name, stream, version, parameters). An adapter (codeunit 6330) bridges the two, so partners never deal with upload internals.

## Adding a new deployable report

Partners register reports by extending an enum and implementing one interface — no changes to the synchronizer needed.

1. **Extend the enum** (`Power BI Deployable Report`, enum 6316):
   ```al
   enumextension 50000 "My Reports" extends "Power BI Deployable Report"
   {
       value(50000; "My Sales Report")
       {
           Caption = 'My Sales Report';
           Implementation = "Power BI Deployable Report" = "My Sales Report Impl.";
       }
   }
   ```

2. **Implement the interface** (`Power BI Deployable Report`):
   ```al
   codeunit 50000 "My Sales Report Impl." implements "Power BI Deployable Report"
   {
       procedure GetReportName(): Text[200]
       begin
           exit('Sales');
       end;

       procedure GetStream(var InStr: InStream)
       begin
           NavApp.GetResource('Sales.pbix', InStr);
       end;

       procedure GetVersion(): Integer
       begin
           exit(1);  // Bump to trigger re-upload
       end;

       procedure GetDatasetParameters(): Dictionary of [Text, Text]
       var
           Params: Dictionary of [Text, Text];
       begin
           Params.Add('COMPANY', CompanyName());
           Params.Add('ENVIRONMENT', GetEnvironmentName());
           exit(Params);
       end;
   }
   ```

3. **Embed the PBIX** as an app resource (`resourceFolders` in `app.json`).

The aggregator, step runner, and deployment management page pick it up automatically.
