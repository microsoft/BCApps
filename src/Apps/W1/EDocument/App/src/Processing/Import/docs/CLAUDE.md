# Import

The staged import pipeline (V2) for incoming e-documents. This directory owns the state machine that takes an e-document from raw blob through structured data, draft population, BC value resolution, and finally to a real purchase document. It also contains the `E-Doc. Import Parameters` table that configures how each import run behaves.

## How it works

`ImportEDocumentProcess` is the core codeunit. It is configured with a step and an undo flag, then executed via `Codeunit.Run`. Each run transitions the e-document by one step. The caller (`EDocImport.GetEDocumentToDesiredStatus`) loops through steps to reach a target status, undoing steps first if going backward.

The four steps are: "Structure received data" (convert blob to XML/JSON), "Read into Draft" (parse structured data into `E-Document Purchase Header/Line`), "Prepare draft" (resolve vendor, items, UOM, apply Copilot matching), and "Finish draft" (create real BC purchase document). Each step dispatches to an interface implementation selected by enum values that cascade from previous steps.

The `E-Doc. Import Parameters` table is temporary -- it is never persisted. It configures a single processing run: which step to execute (or which final status to reach), V1 fallback behavior, and an optional `Existing Doc. RecordId` for linking to pre-existing purchase documents.

## Things to know

- The pipeline supports both forward and backward traversal. "Undo" cleans up the artifacts of a step -- for example, undoing "Prepare draft" deletes header mappings and clears vendor assignments. This makes reprocessing safe.

- V1 documents tunnel through the V2 state machine. When `ImportProcessVersion` is V1, only the "Finish draft" step fires, which calls the legacy `V1_ProcessEDocument` path. All other steps are skipped.

- `ImportEDocProcStatus` and `ImportEDocumentSteps` are tightly coupled enums. Status values 0-4 map to step transitions: Unprocessed-to-Readable is step 0 ("Structure received data"), Readable-to-ReadyForDraft is step 1, etc.

- The `EDocImportParameters."Step to Run / Desired Status"` option switches between two modes: run-a-specific-step (which undoes and reruns that step) vs reach-a-desired-status (which runs/undoes as many steps as needed).

- `EDocUnspecifiedImpl` is the fallback for unset enum values -- it provides no-op implementations of the pipeline interfaces to prevent runtime errors when an e-document has not yet been assigned a specific processing path.

- The `PrepareDraft/` subdirectory contains the default `IProcessStructuredData` implementation for purchase documents, including Copilot-powered line matching (historical, GL account, deferral).

- The `FileFormat/` subdirectory has XML and JSON `IEDocFileFormat` implementations that declare themselves as "already structured" since they need no conversion step.
