# Extensibility

Processing interfaces provide 18 extensibility points organized by customization goal. This document details each interface group with implementation patterns and integration points.

## File format interfaces

**IEDocFileFormat** -- Identifies blob type and defines how to preview content. Implementations include XML, JSON, PDF format handlers.

```al
interface IEDocFileFormat
{
    procedure FileExtension(): Text;
    procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob");
    procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc.";
}
```

**IStructureReceivedEDocument** -- Parses unstructured blob into structured data. PDF implementation uses MLLM, XML returns self (already structured).

```al
interface IStructureReceivedEDocument
{
    procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType;
}
```

**IStructuredFormatReader** -- Extracts field values from structured data using path expressions (ADI approach).

```al
interface IStructuredFormatReader
{
    procedure GetValue(Path: Text): Text;
    procedure GetValues(Paths: List of [Text]): Dictionary of [Text, Text];
}
```

**IStructuredDataType** -- Container for structured data with metadata about format and preferred read implementation.

```al
interface IStructuredDataType
{
    procedure GetContent(): Text;
    procedure GetFileFormat(): Enum "E-Doc. File Format";
    procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft";
}
```

**IBlobType** -- Identifies blob content type from magic bytes or file extension.

**IBlobToStructuredDataConverter** -- Converts blob from one format to another (e.g., PDF to image, TIFF to PNG).

## AI system interfaces

**IEDocAISystem** -- Defines contract for AI-powered extraction. AOAI Function implementation uses structured prompt with tool definitions.

```al
interface IEDocAISystem
{
    procedure ExtractData(EDocument: Record "E-Document"; StructuredData: Text): Boolean;
    procedure GetCapabilityDescription(): Text;
}
```

AOAI Function implementations receive structured prompts with JSON schema definitions, call Azure OpenAI with function calling, and parse tool invocations to populate E-Document Purchase Header/Line records.

## Data resolution interfaces

**IVendorProvider** -- Resolves external vendor identifier (tax ID, GLN, email) to Vendor No.

```al
interface IVendorProvider
{
    procedure GetVendor(VendorId: Text; var Vendor: Record Vendor): Boolean;
    procedure GetVendorByTaxId(TaxId: Text; var Vendor: Record Vendor): Boolean;
}
```

**IItemProvider** -- Resolves external item code (supplier part number, GTIN) to Item No.

```al
interface IItemProvider
{
    procedure GetItem(ItemId: Text; var Item: Record Item): Boolean;
    procedure GetItemByGTIN(GTIN: Code[50]; var Item: Record Item): Boolean;
}
```

**IUnitOfMeasureProvider** -- Resolves external UOM code (ISO code, UN/ECE code) to Unit of Measure Code.

```al
interface IUnitOfMeasureProvider
{
    procedure GetUnitOfMeasure(UOMCode: Text; var UnitOfMeasure: Record "Unit of Measure"): Boolean;
}
```

**IPurchaseLineAccountProvider** -- Determines G/L Account No. for non-item purchase lines (services, charges).

**IPurchaseLineProvider** -- Creates Purchase Line record from imported line data. Enables custom line type logic.

**IPurchaseOrderProvider** -- Creates Purchase Header record from imported header data. Enables custom header field mapping.

Default implementations use standard field assignments. Custom implementations can add business rules (default dimension assignment, approval workflow triggers, external system integration).

## Lifecycle customization interfaces

**IExportEligibilityEvaluator** -- Determines if a document qualifies for e-document export.

```al
interface IExportEligibilityEvaluator
{
    procedure IsEligible(SourceDocumentHeader: RecordRef): Boolean;
}
```

Default implementation checks Document Sending Profile configuration. Custom implementations can add rules (customer must have GLN, amount above threshold, specific document types only).

**IProcessStructuredData** -- Processes structured data after Structure step, before Read step. Enables pre-extraction enrichment.

```al
interface IProcessStructuredData
{
    procedure Process(var StructuredData: Text): Boolean;
}
```

Use cases: Add company-specific fields, normalize external identifiers, apply data quality rules.

**IPrepareDraft** -- Customizes draft preparation during Prepare step. Default implementation resolves vendors, items, UOMs via provider interfaces.

```al
interface IPrepareDraft
{
    procedure Prepare(EDocument: Record "E-Document"; var EDocumentPurchaseHeader: Record "E-Document Purchase Header" temporary; var EDocumentPurchaseLine: Record "E-Document Purchase Line" temporary): Boolean;
}
```

Custom implementations can add default dimensions, calculate custom fields, validate business rules before creating final drafts.

**IEDocumentFinishDraft** -- Customizes purchase draft creation during Finish step, after Purchase Header/Line records are created but before Modify.

```al
interface IEDocumentFinishDraft
{
    procedure FinishDraft(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Boolean;
}
```

Use cases: Assign approval workflow, add purchase line dimensions, create related records (blanket order releases, drop shipments).

**IEDocumentCreatePurchaseInvoice** -- Customizes purchase invoice creation specifically (subset of IEDocumentFinishDraft for invoice-only logic).

## Implementation registration

Interfaces are implemented by codeunits and registered via enum extensions:

```al
enumextension 50100 "My Format" extends "E-Doc. File Format"
{
    value(50100; "My XML Format")
    {
        Caption = 'My XML Format';
        Implementation = IEDocFileFormat = "My XML Format Impl";
    }
}

codeunit 50100 "My XML Format Impl" implements IEDocFileFormat
{
    procedure FileExtension(): Text
    begin
        exit('xml');
    end;
    // ... other methods
}
```

The E-Document Service configuration stores the enum value. At runtime, the processing engine assigns the enum to an interface variable, invoking the registered implementation.

## Event integration

Processing codeunits fire events before and after interface calls:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Export", OnBeforeCallIEDocFileFormat, '', false, false)]
local procedure OnBeforeCallIEDocFileFormat(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var Handled: Boolean)
begin
    // Override interface logic entirely
    if MyCondition then begin
        GenerateMyFormat(EDocument, TempBlob);
        Handled := true;
    end;
end;
```

Events enable bypassing interface logic for specific scenarios without replacing the entire interface implementation.

## Error handling patterns

Interfaces return Boolean for success/failure. Processing engine checks return value and logs errors:

```al
if not IVendorProvider.GetVendor(ExternalVendorId, Vendor) then begin
    EDocumentLog.InsertLog(EDocument, EDocumentService, Enum::"E-Document Service Status"::Error,
        StrSubstNo('Vendor %1 not found', ExternalVendorId));
    exit(false);
end;
```

This pattern enables batch processing to continue despite individual document errors. Errors accumulate in E-Document Log table for later review.

## Testing custom interfaces

Test codeunits should mock interface implementations using enum extensions with test-only implementations:

```al
enumextension 50199 "Test Vendor Provider" extends "E-Doc. Vendor Provider"
{
    value(50199; "Test Provider")
    {
        Implementation = IVendorProvider = "Test Vendor Provider Impl";
    }
}

codeunit 50199 "Test Vendor Provider Impl" implements IVendorProvider
{
    procedure GetVendor(VendorId: Text; var Vendor: Record Vendor): Boolean
    begin
        // Return hardcoded test vendor
        Vendor.Get('V001');
        exit(true);
    end;
}
```

Test scenarios configure E-Document Service to use test enum values, isolating interface behavior from production providers.
