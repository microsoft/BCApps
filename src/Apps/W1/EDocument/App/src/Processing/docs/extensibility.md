# Processing extensibility

The Processing module exposes 18 interfaces (in `Interfaces/`) organized around specific developer scenarios. All are in the `Microsoft.eServices.EDocument.Processing.Interfaces` namespace unless noted.

## How to add a new file format handler

These interfaces let you support a new file type (e.g., EDI, CSV) in the import pipeline.

**IEDocFileFormat** -- describes the file format itself. Implement this to define the extension, preview behavior, and which structuring implementation should be used by default.

```al
procedure FileExtension(): Text;
procedure PreviewContent(FileName: Text; TempBlob: Codeunit "Temp Blob");
procedure PreferredStructureDataImplementation(): Enum "Structure Received E-Doc.";
```

**IBlobType** (obsolete, `#if not CLEAN26`) -- the predecessor to IEDocFileFormat. Checked whether a blob was structured, had a converter, and returned the converter. Replaced by the IEDocFileFormat + IStructureReceivedEDocument split.

**IBlobToStructuredDataConverter** (obsolete, `#if not CLEAN26`) -- old conversion interface. Replaced by IStructureReceivedEDocument.

## How to customize document structuring

These interfaces control how raw received data becomes structured data that the pipeline can parse.

**IStructureReceivedEDocument** -- the main structuring hook. Given the raw `E-Doc. Data Storage` record, produce an `IStructuredDataType` that holds the structured output. The built-in implementations are the PEPPOL handler (XML pass-through), the ADI handler (PDF-to-JSON via Azure Document Intelligence), and the MLLM handler (LLM-based structuring).

```al
procedure StructureReceivedEDocument(EDocumentDataStorage: Record "E-Doc. Data Storage"): Interface IStructuredDataType;
```

**IStructuredDataType** -- returned by the structuring step. Encapsulates the file format, content text, and which `IStructuredFormatReader` implementation should parse it. This is how a single file format (e.g., JSON) can have multiple schemas (ADI JSON vs MLLM JSON).

```al
procedure GetFileFormat(): Enum "E-Doc. File Format";
procedure GetContent(): Text;
procedure GetReadIntoDraftImpl(): Enum "E-Doc. Read into Draft";
```

**IStructuredFormatReader** -- parses structured data into the draft purchase tables. The `ReadIntoDraft` method populates `E-Document Purchase Header` and `E-Document Purchase Line` records. Returns an enum specifying which `IProcessStructuredData` runs next.

```al
procedure ReadIntoDraft(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob"): Enum "E-Doc. Process Draft";
procedure View(EDocument: Record "E-Document"; TempBlob: Codeunit "Temp Blob");
```

## How to customize draft preparation

These interfaces control how external draft data is resolved into BC entities (vendor, items, accounts).

**IPrepareDraft** -- a simpler alternative to `IProcessStructuredData` for scenarios that don't need the full vendor/line resolution pipeline. Just receives the E-Document and import parameters and returns the document type.

```al
procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type";
```

**IProcessStructuredData** -- the full draft preparation interface used by `PreparePurchaseEDocDraft`. Resolves vendors, opens the draft page, and handles cleanup. The default implementation orchestrates vendor resolution, line matching, and AI invocation.

```al
procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): Enum "E-Document Type";
procedure GetVendor(EDocument: Record "E-Document"; Customizations: Enum "E-Doc. Proc. Customizations"): Record Vendor;
procedure OpenDraftPage(var EDocument: Record "E-Document");
procedure CleanUpDraft(EDocument: Record "E-Document");
```

## How to customize draft finalization

These interfaces control how a fully prepared draft becomes an actual BC document.

**IEDocumentFinishDraft** -- creates the BC document from the draft and supports reversal. `ApplyDraftToBC` returns the RecordId of the created document. `RevertDraftActions` deletes it.

```al
procedure ApplyDraftToBC(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters"): RecordId;
procedure RevertDraftActions(EDocument: Record "E-Document");
```

**IEDocumentCreatePurchaseInvoice** -- a narrower hook specifically for changing how purchase invoices are created from the draft. The default implementation creates a standard purchase invoice and copies lines from the draft.

```al
procedure CreatePurchaseInvoice(EDocument: Record "E-Document"): Record "Purchase Header";
```

## How to provide custom data for matching

These provider interfaces supply data during the "Prepare draft" step. They are resolved from the `E-Doc. Proc. Customizations` enum, which means a single enum value implements all of them. The default implementation is `EDocProviders.Codeunit.al`.

**IVendorProvider** -- resolves the vendor for an incoming e-document.

```al
procedure GetVendor(EDocument: Record "E-Document"): Record Vendor;
```

**IItemProvider** -- resolves an item for a given e-document line, vendor, and unit of measure.

```al
procedure GetItem(EDocument: Record "E-Document"; EDocumentLineId: Integer; Vendor: Record Vendor; UnitOfMeasure: Record "Unit of Measure"): Record Item;
```

**IUnitOfMeasureProvider** -- resolves the BC unit of measure from the external unit string.

```al
procedure GetUnitOfMeasure(EDocument: Record "E-Document"; EDocumentLineId: Integer; ExternalUnitOfMeasure: Text): Record "Unit of Measure";
```

**IPurchaseLineProvider** -- resolves purchase line fields (type, number, variant, item reference) for a draft line. Replaces the older `IPurchaseLineAccountProvider`.

```al
procedure GetPurchaseLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line");
```

**IPurchaseLineAccountProvider** (obsolete, tag 27.0) -- the predecessor. Only returned account type and number, now replaced by `IPurchaseLineProvider` which can set all line fields.

**IPurchaseOrderProvider** -- finds a matching purchase order for the incoming invoice based on the order number in the e-document.

```al
procedure GetPurchaseOrder(EDocumentPurchaseHeader: Record "E-Document Purchase Header"): Record "Purchase Header";
```

## How to customize export eligibility

**IExportEligibilityEvaluator** -- called during export to determine whether a specific document should be exported via a given service. The default implementation always returns true. Override this to suppress exports based on customer, document fields, or external criteria.

```al
procedure ShouldExport(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean;
```

## How to add AI capabilities

**IEDocAISystem** (in namespace `Microsoft.eServices.EDocument.Processing.AI`) -- defines an AI processing scenario. Implement this alongside the `AOAI Function` interface to add a new AI tool to the E-Document matching pipeline. The `E-Doc. AI Tool Processor` uses `IEDocAISystem` to get the system prompt and tool list, then calls Azure OpenAI with function-calling.

```al
procedure GetSystemPrompt(UserLanguage: Text): SecretText;
procedure GetTools(): List of [Interface "AOAI Function"];
procedure GetFeatureName(): Text;
```

The built-in implementations (`EDocHistoricalMatching`, `EDocGLAccountMatching`, `EDocDeferralMatching`) each implement both `IEDocAISystem` and `AOAI Function` on the same codeunit -- the codeunit is both the AI system configuration and the function tool the LLM can call.
