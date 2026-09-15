# Import pipeline business logic

## Pipeline overview

*Updated: 2026-07-29 -- Flow now shows reader selection, process draft routing, purchase credit memo, and sales order outcomes.*

```mermaid
flowchart TD
    A["Unprocessed<br/>(raw blob)"] --> S["Structure received data<br/>IEDocFileFormat chooses structuring"]
    S --> B["Readable<br/>(structured blob)"]
    B --> R["Read into draft<br/>IStructuredFormatReader parses content"]
    R --> C["Ready for draft<br/>(staging tables populated)"]
    C --> P{ "Process draft impl." }
    P -->|"Purchase Invoice"| PI["Prepare purchase invoice draft"]
    P -->|"Purchase Credit Memo"| PC["Prepare purchase credit memo draft"]
    P -->|"Sales Order"| SO["Prepare sales order draft"]
    PI --> D["Draft ready<br/>(BC entities resolved)"]
    PC --> D
    SO --> D
    D --> F{ "E-Document Type" }
    F -->|"Purchase Invoice"| FI["Create or link purchase invoice"]
    F -->|"Purchase Credit Memo"| FC["Create or link purchase credit memo"]
    F -->|"Sales Order"| FS["Create sales order"]
    FI --> E["Processed"]
    FC --> E
    FS --> E
    E -.->|"Undo finish"| D
    D -.->|"Undo prepare"| C
    C -.->|"Undo read"| B
    B -.->|"Undo structure"| A
```

The pipeline is driven by `ImportEDocumentProcess.Codeunit.al`. Its `OnRun()` trigger checks the service's import process version. V1 services skip straight to a legacy code path. V2 services dispatch to one of four procedures based on the configured step. After each step, the processing status is advanced or rolled back and the E-Document status is recalculated.

## Stage 1 -- Structure received data

*Updated: 2026-07-29 -- PDF now prefers MLLM, with ADI as fallback rather than the primary PDF path.*

**Transition:** Unprocessed --> Readable

The E-Document arrives with an `Unstructured Data Entry No.` pointing to a raw blob in `E-Doc. Data Storage`. The Structure step loads that blob, resolves the file format via `IEDocFileFormat`, and asks it for `PreferredStructureDataImplementation()` when the document has not already chosen one.

For XML and JSON, the preferred implementation is `Already Structured`; the raw data entry becomes the structured data entry. For PDF, `E-Doc. PDF File Format` now returns `MLLM`. `E-Document MLLM Handler` sends the PDF to Azure OpenAI with a UBL-shaped schema and the `EDocMLLMExtraction-SystemPrompt.md` resource. That prompt explicitly tells the model to extract only visible values, keep customer and vendor roles separate, use XML decimal format, and avoid combining post-discount prices with discount percentages. If MLLM returns empty text, invalid JSON, or JSON missing required vendor fields, the handler falls back to ADI.

`E-Document ADI Handler` still implements both structuring and reading. It registers the E-Document Analysis capability when needed, calls `AzureDocumentIntelligence.AnalyzeInvoice()`, stores JSON when it succeeds, and switches to `Blank Draft` when ADI returns an empty result. The ADI reader maps Azure field names such as `vendorName`, `invoiceId`, `productCode`, `taxRate`, and `tax` into purchase staging fields.

When the data is converted, the original unstructured blob is saved as a document attachment on the E-Document. The structured result is stored as a new `E-Doc. Data Storage` entry through the log, and its entry number is saved on the E-Document. A structuring implementation can also force the next reader by returning a non-`Unspecified` `GetReadIntoDraftImpl()` value; this overrides a reader that was already on the E-Document and logs telemetry.

## Stage 2 -- Read into draft

*Updated: 2026-07-29 -- Added PEPPOL credit notes, orders, order responses, Data Exchange bridge, and external XRechnung/OIOUBL readers.*

**Transition:** Readable --> Ready for draft

The structured blob is loaded and passed to the `IStructuredFormatReader` determined in Stage 1. If the E-Document still has `Read into Draft Impl. = Unspecified`, the read step uses the service's `Read into Draft Impl.` field. This field is shown as **Draft Format** on the service card for V2 services, so already-structured services must choose a reader such as PEPPOL, Data Exchange Purchase, or a country-app reader.

Built-in readers in the core import folder are:

- **PEPPOL** (`EDocumentPEPPOLHandler.Codeunit.al`): Parses UBL Invoice, CreditNote, Order, and OrderResponse XML. Invoices route to `Purchase Invoice`, credit notes route to `Purchase Credit Memo`, and orders route to `Sales Order`. Order responses are stored as messages on the matching outbound E-Document and then stop the import carrier.

- **ADI** (`EDocumentADIHandler.Codeunit.al`): Parses the ADI JSON schema into purchase staging. It treats zero or negative quantity as one, resolves VAT rate from `taxRate` first, and falls back to computing a percentage from a tax amount when the subtotal is available.

- **MLLM** (`EDocumentMLLMHandler.Codeunit.al`): Parses the model's UBL-shaped JSON through `EDocMLLMSchemaHelper`. Decimal parsing uses XML decimal format with evaluation style 9, matching the prompt instruction that model output must use `.` as decimal separator and no thousands separators.

- **Data Exchange Purchase** (`EDocDataExchPurchHandler.Codeunit.al`): Detects the configured Data Exchange Definition by matching the XML root namespace against service data exchange setup, runs the standard Data Exchange pipeline, and bridge-maps `Intermediate Data Import` into the V2 purchase staging tables.

External apps extend the same enum. XRechnung and OIOUBL both add `E-Doc. Read into Draft` values with `IStructuredFormatReader` implementations that populate the same purchase staging tables and return either `Purchase Invoice` or `Purchase Credit Memo`.

Both purchase and sales staging tables keep the same design: fields 2-100 store extracted source data, while fields 101-200 store validated BC references that users or providers can change before finishing.

Reader errors are intentionally caught one level above the reader. `E-Doc. Import.RunConfiguredImportStep()` runs `Import E-Document Process` through `Codeunit.Run`, wraps any available validation context, and logs the error against the E-Document. This is especially important for JSON readers such as ADI and MLLM, where malformed structured data should become an import error instead of an untrappable session failure.

### Data Exchange bridge

*Updated: 2026-07-29 -- Documented why the bridge exists and how it maps legacy Data Exchange output into V2 staging.*

The Data Exchange reader exists so older Data Exchange Definition investments can feed the V2 import pipeline. It does not ask Data Exchange to create the final purchase document. Instead, it runs `ProcessDataExchange()` to populate Data Exchange's intermediate tables, then maps those intermediate rows into `E-Document Purchase Header` and `E-Document Purchase Line`.

The bridge handles work that declarative mappings cannot express cleanly:

- It selects a definition by XML namespace from `E-Doc. Service Data Exch. Def.`.

- It pre-inserts the purchase staging header so the Data Exchange post-mapping codeunit can write to it.

- It applies BC's blank-LCY currency convention after mapping.

- It promotes PEPPOL document-level charges into extra purchase staging lines through `E-Doc. PEPPOL DX Post-Mapping`.

- It decodes embedded attachments from intermediate data and attaches them to the E-Document.

After bridging, the temporary Data Exchange and intermediate records are deleted. The V2 pipeline continues with Prepare Draft exactly as if a native reader had populated the staging tables.

## Stage 3 -- Prepare draft

*Updated: 2026-07-29 -- Split purchase and sales preparation, added VAT rate resolution, VAT difference handling, and vendor telemetry.*

**Transition:** Ready for draft --> Draft ready

Prepare Draft resolves extracted data into BC entities. `E-Doc. Process Draft` chooses the implementation.

### Purchase preparation

`Prepare Purchase E-Doc. Draft` and `EDoc Prepare Cr. Memo Draft` both delegate to `EDoc Prepare Purch. Draft`. The shared purchase helper resolves vendor, purchase order, unit of measure, purchase line type and number, VAT product posting group, historical values, GL account suggestions, and deferral suggestions.

Vendor resolution uses the `IVendorProvider` from processing customizations. The default provider tries VAT ID and GLN, then service participant by external ID scoped to the service and then unscoped, then name and address. If the provider does not assign a vendor, history is searched by GLN, VAT ID, company name, and address, newest first. The import session telemetry records whether vendor information was present, whether a vendor was assigned, and whether the source was already assigned, provider, history, or none.

Line enrichment runs only after a vendor is known. The default UOM provider tries code, international standard code, and description. The default purchase line provider tries item references by vendor, product code, UOM, and validity dates, then falls back to Text-to-Account Mapping. Each successful provider path stores activity-log reasoning.

After direct provider matching, `ResolveVATProductPostingGroups()` can fill `[BC] VAT Prod. Posting Group` from the extracted line VAT rate when purchase setup enables `Resolve VAT Group Purch EDoc`. It uses the vendor's VAT business posting group and looks for a single normal or reverse charge VAT Posting Setup at that rate. If no unique setup exists, the draft line gets an activity-log explanation.

Then AI-assisted matching runs in this order:

1. Historical matching applies posted purchase invoice history to unresolved lines.
2. GL account matching uses the prompt in `GLAccountMatching-SystemPrompt.md` and processes all plausible lines.
3. Deferral matching suggests deferral codes for lines with a type but no deferral.

Each AI step commits before running. Deferral matching is deliberately non-blocking.

Finally, the helper computes a VAT amount difference from the staged total VAT and line VAT amounts. The difference is only considered usable when purchase setup enables E-Document VAT differences, purchase setup allows VAT differences generally, and the value does not exceed the General Ledger Setup maximum. The decision is logged on the header either way.

### Sales order preparation

`Prepare Sales E-Doc. Draft` delegates to `EDoc Prepare Sales Draft`. It resolves `[BC] Customer No.` through `ICustomerProvider` and resolves each sales line through `ISalesLineProvider`.

The default customer provider tries buyer GLN on Customer, service participant by buyer GLN, service participant by buyer external ID, buyer VAT ID on Customer, then name and address. The default sales line provider tries seller item ID directly against Item, standard item ID through Item GTIN or bar-code item reference, then buyer item ID through customer item reference. Successful matches log activity reasoning and line telemetry.

### Dates on the E-Document

After Prepare Draft, `ImportEDocumentProcess` copies purchase staging `Document Date` and `Due Date` onto the E-Document when present. This is why incoming document lists and factboxes can show the document dates before a purchase document is finalized.

## Stage 4 -- Finish draft

*Updated: 2026-07-29 -- Added finalization routing, credit memo and sales order paths, posting description, dimensions, VAT difference, and validation context.*

**Transition:** Draft ready --> Processed

Finish Draft chooses an `IEDocumentFinishDraft` implementation from `E-Document Type`.

```mermaid
flowchart TD
    A["Finish draft"] --> B{ "Document Type" }
    B -->|"None"| Z["Exit without creating a BC document"]
    B -->|"Purchase Invoice"| PI["Validate PO matches and draft lines"]
    B -->|"Purchase Credit Memo"| PC["Validate draft lines"]
    B -->|"Sales Order"| SO["Validate sales draft lines"]
    PI --> L{ "Existing Doc. RecordId set?" }
    PC --> L
    L -->|"Yes"| X["Link E-Document to existing purchase document"]
    L -->|"No invoice"| CI["Create purchase invoice"]
    L -->|"No credit memo"| CC["Create purchase credit memo"]
    SO --> CS["Create sales order"]
    CI --> H["Set dates, posting description, currency, lines, links, attachments"]
    CC --> H
    X --> H
    CS --> SH["Set customer, external document number, lines, link, attachments"]
    H --> V["Apply discounts and VAT difference where relevant"]
    SH --> E["Processed"]
    V --> E
```

### Purchase invoice finalization

`E-Doc. Create Purchase Invoice` first validates PO matches. Matched lines must be valid for the current receipt configuration, must not exceed invoiceable quantity, and must have required UOM information. It then either links to `Existing Doc. RecordId` or delegates invoice creation to `IEDocumentCreatePurchaseInvoice` from processing customizations.

The default invoice creator:

- Requires all draft lines to have both type and number.

- Creates a purchase invoice for the resolved vendor.

- Validates `Document Date`, `Due Date`, `Vendor Invoice No.`, currency, line quantity, direct unit cost, discounts, deferral code, dimensions, VAT product posting group, and item reference through `E-Doc. Purch. Doc. Helper`.

- Checks duplicate posted purchase invoices by external document number after the document date is validated, so the duplicate check uses the draft document date context.

- Applies the configured posting date default from purchase setup when it is set to Document Date.

- Copies the staged `Posting Description` to the purchase invoice.

- Creates non-PO lines first, then receipt-grouped matched lines with comment separators.

- Transfers PO match records from the E-Document to the invoice.

- Applies invoice discount and distributes any allowed VAT difference across purchase lines.

- Writes header and line `E-Doc. Record Link` entries for posting history.

- Copies attachments from the E-Document to the purchase header, sets `E-Document Link`, stores document totals, and validates totals through a try function.

Manual dimensions are preserved because the helper combines the purchase line's default dimension set with the draft line's `[BC] Dimension Set ID`, then validates both shortcut dimension codes. Additional fields are also applied through FieldRef validation, and failures are wrapped with field context by `E-Doc. Import Error Context`.

### Purchase credit memo finalization

`E-Doc. Create Purch. Cr. Memo` uses the same purchase helper for lines, dimensions, attachments, default posting date, currency validation, and record links. It creates a purchase credit memo, validates duplicate external document numbers against posted vendor ledger entries, carries `Posting Description`, and resolves `Applies-to Doc. No.` directly or through `Vendor Invoice No.` when possible.

### Sales order finalization

`E-Doc. Create Sales Order` creates a sales order from `E-Document Sales Header` and `E-Document Sales Line`. It requires every sales draft line to have type and number, prevents duplicate sales orders by customer and external document number, sets document date and requested delivery date when extracted, copies customer reference and note, applies currency and invoice discount, creates sales lines with dimensions and item references, then sets `E-Document Link` and moves attachments to the sales order.

### Undo finish

Undo Finish calls the same `IEDocumentFinishDraft` implementation used to finish. Purchase invoices transfer PO matches back before attachments are moved back and the purchase header link is cleared. Purchase credit memos and sales orders move attachments back and clear the link. The helper does not delete the BC document; it detaches it so the E-Document can be reprocessed or linked again.

## The learning loop

*Updated: 2026-07-29 -- Historical matching is again part of Prepare Draft and history still graduates record links on posting.*

When a purchase invoice created by this pipeline is posted, event subscribers on `Purch.-Post` fire:

- `OnAfterPurchInvLineInsert` writes to `E-Doc. Purchase Line History`, recording the vendor, product code, description, and the posted invoice line's SystemId. If allocation accounts replaced the original line, the code falls back through the allocation purchase line SystemId.

- `OnAfterPostPurchaseDoc` writes to `E-Doc. Vendor Assign. History`, recording the vendor identifiers from the original draft header and the posted invoice header's SystemId.

Both event subscribers delete the matching `E-Doc. Record Link` entries after history is created. Those links are temporary bridges from draft records to BC records; history is the permanent learning data used by future imports.
