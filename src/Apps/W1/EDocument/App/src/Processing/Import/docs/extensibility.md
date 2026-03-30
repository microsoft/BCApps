# Import pipeline extensibility

The import pipeline is built on extensible enums backed by interfaces. Every stage dispatches through an interface, so extensions replace behavior by adding enum values with new implementations. The interfaces live in `src/Processing/Interfaces/`.

## Add a new document format parser

To support a new file format (e.g. CSV invoices), implement two things:

**File format detection.** Extend the `"E-Doc. File Format"` enum with a new value whose `IEDocFileFormat` implementation returns the file extension, a content preview method, and a preferred structure implementation:

```
interface IEDocFileFormat
    procedure FileExtension(): Text
    procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
    procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
```

The built-in implementations are in `FileFormat/`: XML returns `"Already Structured"`, PDF returns `"ADI"`, JSON returns `"Already Structured"`. Your format should point to whichever structuring implementation makes sense.

**Structured format reader.** Extend the `"E-Doc. Read into Draft"` enum with a new value whose `IStructuredFormatReader` implementation parses the structured blob into `E-Document Purchase Header` / `E-Document Purchase Line` records:

```
interface IStructuredFormatReader
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
```

`ReadIntoDraft` must insert the staging records and return the `"E-Doc. Process Draft"` enum value that determines which Prepare Draft implementation runs. See `EDocumentPEPPOLHandler.Codeunit.al` for a complete XML example and `EDocumentADIHandler.Codeunit.al` for a JSON example.

## Add a new structuring mechanism

If you have a non-trivial conversion step (e.g. a custom OCR service for scanned documents), extend the `"Structure Received E-Doc."` enum with a new value whose `IStructureReceivedEDocument` implementation converts the raw blob:

```
interface IStructureReceivedEDocument
    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
```

Your implementation receives the raw blob and must return an `IStructuredDataType` -- a stateful object that holds the file format, the text content, and optionally specifies which `IStructuredFormatReader` to use downstream:

```
interface IStructuredDataType
    procedure GetFileFormat(): Enum "E-Doc. File Format"
    procedure GetContent(): Text
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
```

The ADI handler (`EDocumentADIHandler.Codeunit.al`) implements all three interfaces (`IStructureReceivedEDocument`, `IStructuredDataType`, `IStructuredFormatReader`) in a single codeunit because it owns the entire chain from PDF to staging tables.

## Customize vendor resolution

Extend the `"E-Doc. Proc. Customizations"` enum. This is a multi-interface enum that bundles five provider interfaces with defaults from `EDocProviders.Codeunit.al`. Your new enum value provides custom implementations for any or all of:

```
interface IVendorProvider
    procedure GetVendor(EDocument: Record "E-Document"): Record Vendor
```

The default implementation (`EDocProviders.GetVendor`) tries VAT ID + GLN lookup, then Service Participant matching, then name + address search. Replace it to add your own vendor matching logic -- for example, looking up a custom identifier from a localized field.

## Customize line resolution

The same `"E-Doc. Proc. Customizations"` enum also controls line-level resolution:

```
interface IPurchaseLineProvider
    procedure GetPurchaseLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line")
```

The default implementation tries Item Reference by vendor + product code, then Text-to-Account Mapping by description. Your implementation receives the draft line with external data populated and should set `[BC] Purchase Line Type`, `[BC] Purchase Type No.`, and related fields.

Note: `IPurchaseLineAccountProvider` (same signature pattern but with explicit out-parameters for account type and number) is **obsolete as of v27** -- replaced by `IPurchaseLineProvider`.

```
interface IUnitOfMeasureProvider
    procedure GetUnitOfMeasure(EDocument: Record "E-Document"; EDocumentLineId: Integer; ExternalUnitOfMeasure: Text): Record "Unit of Measure"
```

The default tries UOM Code, then International Standard Code, then Description. Override this if your vendors use non-standard UOM identifiers.

## Customize purchase order matching

```
interface IPurchaseOrderProvider
    procedure GetPurchaseOrder(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Record "Purchase Header"
```

The default looks up `"Purchase Order No."` from the draft header. Override to implement custom PO matching logic -- for example, matching by a combination of vendor and date range.

## Customize invoice creation

```
interface IEDocumentCreatePurchaseInvoice
    procedure CreatePurchaseInvoice(EDocument: Record "E-Document"): Record "Purchase Header"
```

The `"E-Doc. Create Purchase Invoice"` enum is extensible and defaults to `EDocCreatePurchaseInvoice.Codeunit.al`. Override to change how purchase invoices are created -- for example, to set custom fields, apply different discount logic, or create credit memos instead.

The Finish Draft step also uses:

```
interface IEDocumentFinishDraft
    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    procedure RevertDraftActions(EDocument: Record "E-Document")
```

This is controlled by the `"E-Document Type"` enum set during Prepare Draft. Currently only `"Purchase Invoice"` is implemented, routing to `EDocCreatePurchaseInvoice.Codeunit.al`.

## Register AI tools for line matching

The Copilot matching subsystem uses `IEDocAISystem` to register AI-powered processing tools:

```
interface IEDocAISystem
    procedure GetSystemPrompt(UserLanguage: Text): SecretText
    procedure GetTools(): List of [Interface "AOAI Function"]
    procedure GetFeatureName(): Text
```

Extensions can register new AI systems by extending the `"E-Doc. AI System"` enum. Each system provides a system prompt, a set of AOAI Function tool implementations (for function-calling), and a feature name for telemetry. The built-in systems cover historical matching, GL account matching, and deferral matching. Add your own to support custom matching scenarios -- for example, matching lines to projects or jobs.

## Add a new draft preparation strategy

Extend the `"E-Doc. Process Draft"` enum to add a new `IProcessStructuredData` implementation:

```
interface IProcessStructuredData
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor
    procedure OpenDraftPage(var EDocument: Record "E-Document")
    procedure CleanUpDraft(EDocument: Record "E-Document")
```

Currently only `"Purchase Document"` exists. A future value could handle general journal lines or service invoices. Your `IStructuredFormatReader.ReadIntoDraft()` returns the appropriate enum value to route to your preparation logic.

## Extension patterns summary

| Goal | Extend this enum | Implement this interface |
|------|-----------------|------------------------|
| New file type detection | `"E-Doc. File Format"` | `IEDocFileFormat` |
| New structuring method (OCR, etc.) | `"Structure Received E-Doc."` | `IStructureReceivedEDocument` + `IStructuredDataType` |
| New format reader | `"E-Doc. Read into Draft"` | `IStructuredFormatReader` |
| New draft preparation | `"E-Doc. Process Draft"` | `IProcessStructuredData` |
| Custom providers (vendor, item, UOM, PO, invoice) | `"E-Doc. Proc. Customizations"` | Any combination of 5 provider interfaces |
| New AI matching tool | `"E-Doc. AI System"` | `IEDocAISystem` |
| Custom invoice creation | `"E-Doc. Create Purchase Invoice"` | `IEDocumentCreatePurchaseInvoice` |

Two interfaces in `src/Processing/Interfaces/` are not part of the import pipeline: `IExportEligibilityEvaluator` (outbound filtering) and `IBlobToStructuredDataConverter` / `IBlobType` (obsolete as of v26, replaced by `IEDocFileFormat` and `IStructureReceivedEDocument`).
