# Business logic

The Import subsystem implements the 4-step state machine described in the app-level business logic documentation. This document details step implementation and data flow.

## Step 1: Structure

Goal: Parse unstructured blob into structured format for extraction.

Entry point: ImportEDocumentProcess.StructureReceivedData

Process flow:

1. Load unstructured blob from E-Doc. Data Storage using "Unstructured Data Entry No." field
2. Determine file format from blob (IEDocFileFormat.FileExtension)
3. Get preferred structure implementation (IEDocFileFormat.PreferredStructureDataImplementation)
4. If implementation is "Unspecified", use service-configured default
5. Call IStructureReceivedEDocument.StructureReceivedEDocument with blob
6. For MLLM: Call Azure OpenAI with PDF base64 + UBL schema, parse JSON response
7. For XML/JSON: Validate structure, return self as IStructuredDataType
8. For PDF with ADI: Convert to images, prepare for OCR extraction
9. Save structured data to new E-Doc. Data Storage record
10. Attach original unstructured blob as Document Attachment for reference
11. Set "Structured Data Entry No." field and "Structure Done" flag

On MLLM failure, system automatically falls back to ADI if available. If no fallback exists, step fails with error status.

## Step 2: Read

Goal: Extract header and line data from structured format into temporary purchase records.

Entry point: ImportEDocumentProcess.ReadIntoDraft

Process flow for MLLM:

1. Load structured data blob from "Structured Data Entry No." reference
2. Call EDocumentMLLMHandler.ReadData with JSON schema
3. Handler uses IStructuredFormatReader to extract fields via JSON paths
4. Map extracted values to E-Document Purchase Header temporary record (invoice date, vendor name, amounts)
5. Map line data to E-Document Purchase Line temporary records (description, quantity, unit price)
6. Validate minimum required fields (vendor name OR vendor address required)
7. Insert temporary records with "E-Document Entry No." as parent reference
8. Set "Read Done" flag

Process flow for ADI:

1. Load structured data blob from "Structured Data Entry No." reference
2. Instantiate IStructuredFormatReader from format (XML reader, JSON reader)
3. Execute mapping rules from E-Document Header Mapping and E-Document Line Mapping tables
4. For each mapping rule, call GetValue(Path) to extract field via XPath/JSONPath
5. Apply transformation rules (external codes to internal codes)
6. Populate temporary purchase records
7. Validate and insert, set "Read Done" flag

Extracted data includes both external values (vendor company name, sales invoice no.) and Business Central references populated later ([BC] Vendor No., [BC] Item No.).

## Step 3: Prepare

Goal: Resolve external identifiers to Business Central master data and match to existing purchase orders.

Entry point: ImportEDocumentProcess.PrepareDraft

Process flow:

1. Load temporary purchase header from Read step
2. Call IVendorProvider.GetVendor with vendor company name or tax ID
3. On success, set "[BC] Vendor No." field on header
4. Load temporary purchase lines from Read step
5. For each line:
   - Call IItemProvider.GetItem with external item code/GTIN
   - Call IUnitOfMeasureProvider.GetUnitOfMeasure with external UOM code
   - Set "[BC] Item No." and "[BC] Unit of Measure" fields
6. If line has no item, call IPurchaseLineAccountProvider.GetGLAccount with description
7. If historical matching enabled, call AI Tools to suggest vendor/GL account from past purchases
8. If Copilot PO matching enabled:
   - Load available purchase order lines for vendor
   - Call EDocPOCopilotMatching.MatchWithCopilot with imported lines and PO lines
   - Receive match suggestions with confidence scores
   - Create E-Doc. Purchase Line PO Match records for accepted matches
9. Validate all lines have either item or GL account assignments
10. Set "Prepare Done" flag

Provider interfaces can create missing master data records (auto-create items, auto-create UOMs) based on service configuration. Historical matching uses AOAI Function to analyze line descriptions against past purchase invoice lines, suggesting best-match vendors and GL accounts.

## Step 4: Finish

Goal: Create final Purchase Header and Purchase Line records from validated temporary data.

Entry point: ImportEDocumentProcess.FinishDraft

Process flow:

1. Load temporary purchase header and lines from Prepare step
2. Validate required fields populated ("[BC] Vendor No." mandatory)
3. Call EDocumentCreate.CreatePurchaseDocument
4. Transform temporary header to real Purchase Header:
   - Copy standard fields (Document Date, Due Date, Vendor Invoice No.)
   - Apply vendor defaults (payment terms, location code)
   - Link to E-Document via "E-Document Entry No." field
5. Transform temporary lines to real Purchase Line:
   - Set Type (Item, G/L Account, Charge (Item)) from "[BC] Purchase Type" field
   - Copy quantity, unit price, description
   - Apply matched PO line references if exists (match-to-order scenario)
   - Link to E-Document via "E-Document Line Entry No." field
6. Call IEDocumentFinishDraft.FinishDraft for customization
7. Insert Purchase Header and Purchase Line records
8. Set "Finish Done" flag and overall status to "Processed"

Created purchase documents are drafts requiring user review before posting. Users can modify fields, add approvals, or reject drafts. Rejected drafts can be deleted or re-created by undoing Finish step.

## Match-to-order scenario

When Copilot suggests PO line matches or users manually match lines, the Finish step creates Purchase Invoice documents linked to existing purchase orders rather than standalone invoices:

1. For matched lines, set "Order No." and "Order Line No." references
2. System copies PO line details (item, quantity, price) and validates against imported values
3. If imported quantity exceeds PO outstanding quantity, show warning
4. If imported price differs from PO price by more than configured threshold, show warning
5. Users review warnings before accepting invoice

Match-to-order enables 3-way matching (PO + Receipt + Invoice) and prevents over-invoicing.

## Undo implementation

Each undo operation is implemented by a dedicated method in ImportEDocumentProcess:

**UndoStructure:**
- Clear "Structure Done" flag
- Delete structured data blob from E-Doc. Data Storage
- Cascade to UndoRead

**UndoRead:**
- Clear "Read Done" flag
- Delete E-Document Purchase Header temporary records
- Delete E-Document Purchase Line temporary records
- Cascade to UndoPrepare

**UndoPrepare:**
- Clear "Prepare Done" flag
- Delete E-Doc. Purchase Line PO Match records
- Clear "[BC]" field assignments on temporary records
- Cascade to UndoFinish

**UndoFinish:**
- Clear "Finish Done" flag
- Delete Purchase Header records where "E-Document Entry No." matches
- Delete Purchase Line records where "E-Document Line Entry No." matches
- Delete E-Doc. Record Link associations

Undo operations check for downstream dependencies. For example, if a Purchase Invoice created by Finish step has been posted, UndoFinish fails with error "Cannot undo finished document that has been posted".

## Automatic processing

Services configure "E-Doc. Automatic Processing" to specify how far to process documents automatically:

- **Unprocessed** -- Manual processing only, stop at import
- **Structure** -- Auto-structure, stop before read
- **Read** -- Auto-structure + auto-read, stop before prepare
- **Prepare** -- Auto-structure + auto-read + auto-prepare, stop before finish
- **Finish** -- Full automatic processing, create purchase drafts

When EDocImport.ReceiveAndProcessAutomatically runs, it queries all documents with "Import Processing Status" = "Unprocessed" and processes each to the configured level. Documents requiring user review (status = "Prepare Done") appear in the E-Document list for manual Finish.

This enables hybrid workflows: AI extracts data automatically, users review before finalizing drafts.
