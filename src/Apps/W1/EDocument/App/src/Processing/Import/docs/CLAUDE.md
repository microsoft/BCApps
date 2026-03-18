# Import

The Import subfolder implements the V2 multi-step import pipeline for incoming
e-documents. It owns the state machine orchestrator, the draft staging tables, user
override mappings, and all the subfolder logic for purchase document creation,
historical matching, PO reconciliation, and file format handling.

## How it works

The pipeline is orchestrated by `ImportEDocumentProcess.Codeunit.al`, which executes
a single configured step per `Run()` invocation. The caller (`EDocImport`) drives the
state machine by computing which steps need to run (or undo) to reach a desired
status, then calls `ConfigureImportRun` + `Run()` in a loop.

The four stages populate and refine draft tables before creating a real BC document.
The `E-Document Purchase Header` and `E-Document Purchase Line` tables serve as the
staging area -- they hold both the external data extracted from the incoming file
(fields 2-100, read-only) and BC-resolved data (fields 101+, prefixed `[BC]`, user-
editable). This dual-field design lets users see exactly what the original document
said alongside the BC entity the system resolved it to.

Historical matching is vendor-scoped. When a draft line has a product code or
description that was previously mapped for the same vendor, the system reuses that
mapping automatically. History is stored in `E-Doc. Purchase Line History` and
`E-Doc. Vendor Assign. History`, both linked to the posted purchase invoice via
SystemId. History records are immutable once created.

PO matching (in Purchase/PurchaseOrderMatching/) handles the three-way match scenario:
an incoming invoice references a purchase order, and the system matches invoice lines
to PO lines and receipt lines. The `E-Doc. PO Matching Setup` table controls matching
behavior per vendor or globally (fall back when no vendor-specific setup exists).

## Things to know

- The V2 status progression is: Unprocessed -> Readable -> Ready for draft ->
  Draft ready -> Processed. Each transition is one step, each step is independently
  undoable.

- Draft tables are ephemeral. They exist only while the e-document is between
  "Ready for draft" and "Processed" states. The `E-Document Purchase Header` row is
  created during Read into Draft and deleted when the BC document is finalized (or
  when the e-document is deleted).

- `E-Document Header Mapping` and `E-Document Line Mapping` store user overrides.
  When the user changes the vendor, item, or UOM on the draft page, the mapping
  record captures that choice so it persists across re-processing.

- PO matching setup can be per-vendor (via `"Vendor No."` on `E-Doc. PO Matching
  Setup`) or global (blank vendor). The `GetSetup` procedure falls back from
  vendor-specific to global.

- The AdditionalFields/ subfolder provides an extensibility mechanism for
  service-specific fields on draft lines. `E-Document Line - Field` is a key-value
  table keyed by (E-Document Entry No., Line No., Field No.) that stores typed
  values (Text, Decimal, Date, Boolean, Code, Integer). The field definitions come
  from `ED Purchase Line Field Setup`.

- `EDocImportParameters.Table.al` is a temporary table -- it is never persisted. It
  configures a single processing run: which step to execute, whether to target a
  specific status, V1 behavior overrides, and an optional existing document RecordId
  for linking instead of creating.

- File format handlers in FileFormat/ (PDF, XML, JSON) implement `IEDocFileFormat`
  and provide the file extension and preferred structuring implementation. They do not
  parse content -- that is the job of `IStructureReceivedEDocument` implementations
  in StructureReceivedEDocument/.
