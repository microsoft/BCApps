# Import pipeline extensibility

The import pipeline is built on extensible enums backed by interfaces. Every stage dispatches through an interface, so extensions replace behavior by adding enum values with implementations. The import-specific interfaces are selected by `ImportEDocumentProcess.Codeunit.al`; the contracts live in `src/Processing/Interfaces/` and, for sales-specific providers, under `Import/Sales/`.

*Updated: 2026-07-29 -- Added the current reader selection chain, Data Exchange bridge, purchase credit memo, and sales order extension points.*

## Add a new inbound format

*Updated: 2026-07-29 -- Documented service Draft Format fallback and the process draft value returned by each reader.*

To support a new structured inbound format, the central extension point is `E-Doc. Read into Draft`. The user or service integration selects the implementation through `E-Document."Read into Draft Impl."`; if the document does not set one, V2 import falls back to `E-Document Service."Read into Draft Impl."`, shown as **Draft Format** on the service card.

Extend the enum with a value whose implementation parses the structured blob into staging records and returns the next process draft route:

```al
interface IStructuredFormatReader
    procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft"
    procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob")
```

A purchase invoice reader inserts `E-Document Purchase Header` and `E-Document Purchase Line` records and returns `Purchase Invoice`. A purchase credit memo reader uses the same purchase staging tables and returns `Purchase Credit Memo`. A sales order reader inserts `E-Document Sales Header` and `E-Document Sales Line` records and returns `Sales Order`.

Built-in examples:

- PEPPOL reads invoices, credit notes, orders, and order responses in `EDocumentPEPPOLHandler.Codeunit.al`.

- Data Exchange Purchase runs configured Data Exchange definitions and bridges intermediate data into purchase staging.

- MLLM and ADI read JSON output from their structuring stage into purchase staging.

Country apps follow the same pattern. XRechnung and OIOUBL extend `E-Doc. Read into Draft`, implement `IStructuredFormatReader`, populate purchase staging, and return either `Purchase Invoice` or `Purchase Credit Memo`.

## Add a new file type or structuring mechanism

*Updated: 2026-07-29 -- Updated PDF default to MLLM and clarified reader override behavior from structured data.*

Use these interfaces when your source blob is not already in the shape your reader consumes.

**File format detection.** Extend the `E-Doc. File Format` enum with an `IEDocFileFormat` implementation:

```al
interface IEDocFileFormat
    procedure FileExtension(): Text
    procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob")
    procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc."
```

XML and JSON return `Already Structured`. PDF now returns `MLLM`; ADI remains available but is no longer the default PDF preference in the core PDF file format.

**Structuring.** Extend the `Structure Received E-Doc.` enum with an `IStructureReceivedEDocument` implementation:

```al
interface IStructureReceivedEDocument
    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType
```

Your implementation returns an `IStructuredDataType` object:

```al
interface IStructuredDataType
    procedure GetFileFormat(): Enum "E-Doc. File Format"
    procedure GetContent(): Text
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft"
```

`GetReadIntoDraftImpl()` is important. If it returns a value other than `Unspecified`, the structure step writes it to the E-Document and the read step uses it, even if the service has a different Draft Format. Use this when the conversion result implies exactly one downstream reader, such as MLLM JSON or ADI JSON.

## Use Data Exchange definitions in V2

*Updated: 2026-07-29 -- Added bridge pattern guidance.*

If your format is already modeled as Data Exchange Definitions, use or mimic the `Data Exchange Purchase` reader rather than duplicating the final document creation logic. The bridge pattern is:

1. Configure one or more import Data Exchange Definitions on the E-Document Service.
2. Let `EDocDataExchPurchHandler` choose a definition by XML root namespace.
3. Run `DataExchDef.ProcessDataExchange()` so the standard Data Exchange framework fills `Intermediate Data Import`.
4. Map intermediate rows into `E-Document Purchase Header` and `E-Document Purchase Line`.
5. Return `Purchase Invoice` or `Purchase Credit Memo` so the normal V2 Prepare and Finish stages handle vendor resolution, matching, validation, links, attachments, and history.

This bridge exists to preserve older Data Exchange mapping investments while still gaining the V2 draft review and finalization pipeline. It should not bypass staging tables or create the purchase document directly.

## Customize purchase resolution

*Updated: 2026-07-29 -- Added current provider behavior and VAT product posting group note.*

Extend the `E-Doc. Proc. Customizations` enum. This multi-interface enum bundles the provider and finalizer interfaces used during Prepare Draft and Finish Draft.

For purchase drafts, the default value provides:

```al
interface IVendorProvider
    procedure GetVendor(EDocument: Record "E-Document"): Record Vendor

interface IPurchaseOrderProvider
    procedure GetPurchaseOrder(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Record "Purchase Header"

interface IUnitOfMeasureProvider
    procedure GetUnitOfMeasure(EDocument: Record "E-Document"; EDocumentLineId: Integer; ExternalUnitOfMeasure: Text): Record "Unit of Measure"

interface IPurchaseLineProvider
    procedure GetPurchaseLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line")
```

The default vendor provider tries VAT ID and GLN, service participant, then name and address. Purchase history can still fill a missing vendor after the provider runs. The default line provider tries item references and then Text-to-Account Mapping. VAT product posting group resolution is not an interface; it is controlled by purchase setup and uses the vendor VAT business posting group plus the extracted line VAT rate.

`IPurchaseLineAccountProvider` is obsolete as of v27 and should not be used for new work.

## Customize purchase finalization

*Updated: 2026-07-29 -- Added credit memo creation and clarified when to override create versus finish contracts.*

Purchase invoice creation is controlled by `IEDocumentCreatePurchaseInvoice`, and purchase credit memo creation by `IEDocumentCreatePurchaseCreditMemo`. Both are bundled into `E-Doc. Proc. Customizations`.

```al
interface IEDocumentCreatePurchaseInvoice
    procedure CreatePurchaseInvoice(EDocument: Record "E-Document"): Record "Purchase Header"

interface IEDocumentCreatePurchaseCreditMemo
    procedure CreatePurchaseCreditMemo(EDocument: Record "E-Document"): Record "Purchase Header"
```

The Finish Draft dispatcher itself uses `IEDocumentFinishDraft`, selected from `E-Document Type`:

```al
interface IEDocumentFinishDraft
    procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId
    procedure RevertDraftActions(EDocument: Record "E-Document")
```

Override the create interfaces when you only need to alter how the BC purchase document is built. Add or replace an `IEDocumentFinishDraft` implementation only when you are introducing a new document type or a different finish or undo contract.

## Customize sales order import

*Updated: 2026-07-29 -- Added inbound sales order providers and finalizer.*

Sales order import uses the same pipeline but different staging tables and providers. Extend `E-Doc. Proc. Customizations` to provide custom implementations for:

```al
interface ICustomerProvider
    procedure GetCustomer(EDocument: Record "E-Document"): Record Customer

interface ISalesLineProvider
    procedure GetSalesLine(var EDocumentSalesLine: Record "E-Document Sales Line")

interface IEDocumentCreateSalesOrder
    procedure CreateSalesOrder(EDocument: Record "E-Document"): Record "Sales Header"
```

The default customer provider tries buyer GLN, service participant identifiers, buyer VAT ID, and name plus address. The default sales line provider tries seller item ID, GTIN or bar-code item reference, then buyer item reference for the resolved customer. Override these when partner identifiers or line matching rules differ from the built-in assumptions.

The sales route itself is driven by `IProcessStructuredDataSales`, which extends `IProcessStructuredData` with the sales-specific draft operations. `Prepare Sales E-Doc. Draft` (codeunit 6429) is the built-in implementation, so a new sales reader implements the extended interface rather than the purchase one.

## Add a new draft preparation strategy

*Updated: 2026-07-29 -- Updated current routes and obsoleted `Purchase Document` guidance.*

Extend `E-Doc. Process Draft` to add a new `IProcessStructuredData` implementation:

```al
interface IProcessStructuredData
    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type"
    procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor
    procedure OpenDraftPage(var EDocument: Record "E-Document")
    procedure CleanUpDraft(EDocument: Record "E-Document")
```

Current core routes are `Purchase Invoice`, `Purchase Credit Memo`, and `Sales Order`. The obsolete `Purchase Document` value remains only behind a cleanup symbol and should not be used for new readers.

A reader controls routing by returning the process draft enum value from `ReadIntoDraft()`.

## Register AI tools for line matching

*Updated: 2026-07-29 -- Added prompt-resource guidance and obsoleted PO Matching Copilot note.*

The import-time AI matching subsystem uses `IEDocAISystem` and AOAI Function implementations. The built-in systems include historical matching, similar descriptions, GL account matching, and deferral matching.

```al
interface IEDocAISystem
    procedure GetSystemPrompt(UserLanguage: Text): SecretText
    procedure GetTools(): List of [Interface "AOAI Function"]
    procedure GetFeatureName(): Text
```

Prompts live in `App/.resources/Prompts/`. The MLLM extraction prompt now includes a content and format monitoring section that tells the model to extract only visible values, distinguish buyer from vendor using the prefilled customer party, and emit decimals in XML format. The GL account matching prompt now tells the model to process every plausible line and call one tool per line.

The older Purchase Order Matching Copilot objects are obsolete. New AI work should plug into the import-time tool processor or a new `IEDocAISystem`, not the old PO matching Copilot pages and buffers.

## Extension patterns summary

*Updated: 2026-07-29 -- Updated current enum and interface matrix.*

| Goal | Extend this enum | Implement this interface |
|------|-----------------|--------------------------|
| New file type detection | `E-Doc. File Format` | `IEDocFileFormat` |
| New structuring method | `Structure Received E-Doc.` | `IStructureReceivedEDocument` and `IStructuredDataType` |
| New structured reader or inbound format | `E-Doc. Read into Draft` | `IStructuredFormatReader` |
| Reuse Data Exchange definitions in V2 | `E-Doc. Read into Draft` or service Draft Format | `IStructuredFormatReader` that bridges intermediate data to staging |
| New draft preparation route | `E-Doc. Process Draft` | `IProcessStructuredData` |
| Custom purchase providers | `E-Doc. Proc. Customizations` | `IVendorProvider`, `IPurchaseOrderProvider`, `IPurchaseLineProvider`, `IUnitOfMeasureProvider` |
| Custom sales providers | `E-Doc. Proc. Customizations` | `ICustomerProvider`, `ISalesLineProvider` |
| Custom purchase invoice creation | `E-Doc. Proc. Customizations` | `IEDocumentCreatePurchaseInvoice` |
| Custom purchase credit memo creation | `E-Doc. Proc. Customizations` | `IEDocumentCreatePurchaseCreditMemo` |
| Custom sales order creation | `E-Doc. Proc. Customizations` | `IEDocumentCreateSalesOrder` |
| New AI matching tool | AI system implementation | `IEDocAISystem` and `AOAI Function` |
| Custom finish or undo contract | `E-Document Type` | `IEDocumentFinishDraft` |

Two interfaces in `src/Processing/Interfaces/` are not part of the current import route: `IExportEligibilityEvaluator` is for outbound filtering, and `IBlobToStructuredDataConverter` / `IBlobType` are obsolete as of v26, replaced by `IEDocFileFormat` and `IStructureReceivedEDocument`.
