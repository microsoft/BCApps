# Processing interfaces

All interfaces that define how the V2 import pipeline and the export eligibility system are extended live here. These are the primary extension points for partners and localization apps building on the E-Document framework.

## How it works

The import pipeline interfaces form a chain. `IStructureReceivedEDocument` converts raw blobs (PDF, images) into structured data, returning an `IStructuredDataType` that carries the content and its file format. `IStructuredFormatReader` then reads that structured content (XML, JSON) into the E-Document draft tables. `IProcessStructuredData` takes the populated draft and resolves BC values -- vendor, items, accounts. Finally, `IEDocumentFinishDraft` creates real BC documents from the draft.

Provider interfaces (`IVendorProvider`, `IItemProvider`, `IUnitOfMeasureProvider`, `IPurchaseLineProvider`, `IPurchaseLineAccountProvider`, `IPurchaseOrderProvider`) are consumed during the "prepare draft" step. They are implemented by default in `EDocProviders.Codeunit.al` and dispatched through the `Processing Customizations` enum, making them swappable per-service.

On the export side, `IExportEligibilityEvaluator` lets services control which documents they accept for export beyond the type-support check. `IEDocFileFormat` defines file-format metadata (extension, preview, preferred structuring).

## Things to know

- `IStructuredDataType` is a return value from `IStructureReceivedEDocument`, not a standalone extension point. It carries format, content, and crucially the `GetReadIntoDraftImpl()` that tells the pipeline which reader to use next.

- `IEDocumentFinishDraft` is dispatched via the `E-Document Type` enum, not the service. This means the "Purchase Invoice" type enum value implements `ApplyDraftToBC` differently from "Purchase Order".

- `IProcessStructuredData` is dispatched via the `E-Doc. Process Draft` enum, which is returned by `IStructuredFormatReader.ReadIntoDraft`. This creates a two-step dispatch chain: the reader picks the processor.

- `IBlobType` and `IBlobToStructuredDataConverter` are obsolete (CLEAN26). They are replaced by `IEDocFileFormat` and `IStructureReceivedEDocument`.

- `IPrepareDraft` exists as a simpler alternative to `IProcessStructuredData` for scenarios that only need to determine the document type without full vendor/line resolution.

- Provider interfaces return records, not codes. `IVendorProvider.GetVendor` returns a `Vendor` record -- a blank `"No."` means no vendor was found, which is handled gracefully in the pipeline rather than throwing errors.
