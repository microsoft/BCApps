# Import pipeline

The V2 import pipeline converts a received blob (XML, JSON, PDF) into a posted BC purchase invoice through four discrete stages, each producing an intermediate status that can be undone and re-run. The pipeline is orchestrated by `ImportEDocumentProcess.Codeunit.al`, which dispatches to interface implementations so that every stage is replaceable by extensions.

## How it works

An incoming E-Document enters the pipeline at status `Unprocessed` with a raw blob in `E-Doc. Data Storage`. Each step advances the status by one notch: **Structure** converts unstructured data (e.g. a PDF via Azure Document Intelligence) into a structured blob and moves to `Readable`. **Read into draft** parses that structured blob into purchase staging tables (`E-Document Purchase Header` / `E-Document Purchase Line`) and moves to `Ready for draft`. **Prepare draft** resolves vendor, items, UOM, GL accounts, and purchase order matches -- filling in the `[BC]` validated columns on those staging tables -- then moves to `Draft ready`. **Finish draft** creates the actual BC purchase invoice (or links to an existing document), writes `E-Doc. Record Link` entries for traceability, and moves to `Processed`.

Each step is undoable. Undoing Finish Draft deletes the purchase invoice and restores PO matches. Undoing Prepare Draft clears header mappings, vendor assignment, and resets Document Type. Undoing Structure clears the structured data pointer. The user can fix data at any stage and re-run forward from there.

V1 services are still supported: when `GetImportProcessVersion()` returns `Version 1.0`, the pipeline collapses all stages into a single "Finish draft" call that delegates to the legacy `E-Doc. Import` codeunit.

## Things to know

- The pipeline status is an ordered enum (`Unprocessed` = 0 through `Processed` = 4). `StatusStepIndex()` maps each status to a numeric index used for comparison and navigation -- this is how `GetNextStep()` / `GetPreviousStep()` work.

- The `E-Doc. Import Parameters` table is temporary and controls pipeline execution: which step to run, whether to target a step or a desired status, processing customizations, and V1-compatibility flags.

- Interface dispatch is layered: `IEDocFileFormat` determines the preferred `IStructureReceivedEDocument`, which returns an `IStructuredDataType` that specifies the `IStructuredFormatReader`, which returns the `IProcessStructuredData` enum. Each stage's output feeds the next stage's interface selection.

- The `E-Doc. Proc. Customizations` enum is a multi-interface enum that bundles `IVendorProvider`, `IPurchaseOrderProvider`, `IPurchaseLineProvider`, `IUnitOfMeasureProvider`, and `IEDocumentCreatePurchaseInvoice` with defaults from `EDocProviders.Codeunit.al`. Extensions add a new enum value to swap all five at once.

- AI-assisted matching runs during Prepare Draft: historical matching first, then Copilot GL account matching for remaining unresolved lines, then deferral matching. Each step commits before invoking the next codeunit to isolate failures.

- The history system is populated by event subscribers on `Purch.-Post`: `OnAfterPurchInvLineInsert` and `OnAfterPostPurchaseDoc` create entries in `E-Doc. Purchase Line History` and `E-Doc. Vendor Assign. History`, completing the learning loop.

- See `../docs/CLAUDE.md` for the parent Processing module context. The `src/Processing/Interfaces/` folder defines 18 interfaces that underpin this pipeline.
