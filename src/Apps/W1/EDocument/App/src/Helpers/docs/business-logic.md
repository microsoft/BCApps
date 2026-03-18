# Helpers — Business Logic

Utility procedures supporting E-Document import matching, error management, and log retrieval. These stateless helpers are invoked from import flows and export workflows to perform focused data lookups and validation.

## Core workflows

### Unit of measure resolution

1. **Import line contains UOM code** -- Inbound XML/JSON has `<UnitCode>EA</UnitCode>` or similar
2. **ResolveUnitOfMeasureFromDataImport(EDocument, TempDocumentLine)** -- Called from import helper with RecordRef pointing to temp Purchase Line record
3. **Extract UOM field** -- Gets UOMCodeFieldRef from TempDocumentLine.Field(PurchaseLine.FieldNo("Unit of Measure Code"))
4. **Try Code exact match** -- UnitOfMeasure.SetRange(Code, UOMCodeFieldRef.Value()), if found: UOMCodeFieldRef.Value(UnitOfMeasure.Code), return true
5. **Try International Standard Code** -- UnitOfMeasure.SetRange("International Standard Code", UOMCodeFieldRef.Value()), if found: update FieldRef, return true
6. **Try Description match** -- UnitOfMeasure.SetRange(Description, UOMCodeFieldRef.Value()), if found: update FieldRef, return true
7. **Log error** -- EDocErrorHelper.LogErrorMessage(EDocument, UnitOfMeasure, Code, StrSubstNo(UOMNotFoundErr, UOMCodeFieldRef.Value())), return false
8. **Caller decides** -- Import flow checks return value, either skips line or aborts document creation

### Item reference lookup

1. **Import line contains vendor item reference** -- XML has `<ItemReferenceNo>VENDOR-SKU-123</ItemReferenceNo>`
2. **FindItemReferenceForLine(EDocument, TempDocumentLine)** -- Called after UOM resolution
3. **Get vendor** -- Vendor.Get(EDocument."Bill-to/Pay-to No."), ensures vendor context available
4. **Extract fields** -- ItemRefFieldRef (Item Reference No.), TypeFieldRef (Type), NoFieldRef (No.), UOMCodeFieldRef (Unit of Measure Code)
5. **Filter item references** -- ItemReference.SetRange("Reference Type", Vendor) + SetRange("Reference Type No.", VendorNo) + SetRange("Reference No.", ItemRefFieldRef.Value())
6. **Match with UOM** -- FindMatchingItemReference(ItemReference, UOMCodeFieldRef.Value()) finds record matching both reference no. and UOM
7. **Update line fields** -- TypeFieldRef.Value(PurchaseLine.Type::Item), NoFieldRef.Value(ItemReference."Item No."), ResolveUnitOfMeasureFromItemReference(ItemReference, EDocument, TempDocumentLine)
8. **Return result** -- True if item found, false if not (error logged by caller)

### GTIN-based item lookup

1. **Import line contains GTIN** -- XML has `<GTIN>8712345678901</GTIN>` in item identifier field
2. **FindItemForLine(EDocument, TempDocumentLine)** -- Called if FindItemReferenceForLine() returned false
3. **Extract GTIN** -- NoFieldRef := TempDocumentLine.Field(PurchaseLine.FieldNo("No.")), GTIN := NoFieldRef.Value
4. **Validate length** -- If StrLen(GTIN) > MaxStrLen(Item.GTIN), return false (invalid GTIN format)
5. **Lookup item** -- Item.SetRange(GTIN, GTIN), if not found: return false
6. **Update line** -- TypeFieldRef.Value(Item), NoFieldRef.Value(Item."No."), return true
7. **Fallback to account mapping** -- If GTIN lookup fails, caller tries FindGLAccountForLine()

### Error accumulation pattern

1. **Import starts** -- EDocErrorHelper.ClearErrorMessages(EDocument) removes previous errors
2. **Validate company** -- If validation fails: LogErrorMessage(EDocument, CompanyInfo, FieldNo("VAT Registration No."), 'Receiving company VAT mismatch')
3. **Validate lines** -- For each line: ResolveUnitOfMeasureFromDataImport() → FindItemReferenceForLine() → FindItemForLine() → FindGLAccountForLine()
4. **Check totals** -- VerifyTotals(EDocument, TempDocumentHeader) logs error if sum ≠ total
5. **Query error state** -- If EDocErrorHelper.HasErrors(EDocument): set status to "Error", exit; else: continue to document creation
6. **Display errors** -- User opens E-Document page, clicks "Show Errors" action, filtered Error Message list appears with all accumulated errors

### Log retrieval for resume

1. **Import paused at "Structure Done"** -- User clicks "Undo Structure" to revert, or continues to "Read into Draft"
2. **GetDocumentLog(EDocument, Service, Status = "Imported")** -- Retrieves most recent log with Status = Imported, Service Code = service
3. **Extract blob** -- EDocumentLog.GetDataStorage(TempBlob) loads structured XML/JSON from log's Data Storage Entry No.
4. **Resume processing** -- Import flow uses TempBlob content to continue from Read step instead of re-receiving document

### JSON path navigation

1. **Data Exchange export** -- Export mapping needs to extract nested JSON value: `"invoice": { "lines": [{ "item": { "code": "1000" } }] }`
2. **GetJsonToken(JsonText, "invoice.lines[0].item.code")** -- Parses JsonText, navigates path
3. **Path parsing** -- Splits on '.', for each segment: if ends with `[N]`, extracts array index, calls JsonArray.Get(index), else calls JsonObject.Get(key)
4. **Return token** -- Returns JsonToken at path, or null token if path doesn't exist
5. **Caller extracts value** -- JsonToken.AsValue().AsText() or AsInteger() depending on expected type
6. **SetJsonValueInPath(JsonText, Path, Value)** -- Reverse operation: navigates to path, replaces value, returns modified JsonText

## Key procedures

### E-Document Import Helper

- **ResolveUnitOfMeasureFromDataImport(EDocument, TempDocumentLine)** -- 3-stage UOM lookup (Code → Int'l Standard Code → Description), updates FieldRef if found
- **FindItemReferenceForLine(EDocument, TempDocumentLine)** -- Matches vendor item reference + UOM, updates Type/No./UOM fields
- **FindItemForLine(EDocument, TempDocumentLine)** -- GTIN-based item lookup, updates Type/No. fields
- **FindGLAccountForLine(EDocument, TempDocumentLine)** -- E-Doc. Mapping rule lookup for external account codes → G/L Account No.
- **ResolveUnitOfMeasureFromItemReference(ItemReference, EDocument, TempDocumentLine)** -- Sets UOM from item reference's UOM Code if specified
- **VerifyTotals(EDocument, TempDocumentHeader)** -- Sums line amounts, compares to header total, logs error if mismatch
- **ValidateReceivingCompany(EDocument, CompanyInfo)** -- Checks E-Document."Receiving Company VAT Reg. No." matches CompanyInfo."VAT Registration No."
- **FindMatchingItemReference(ItemReference, UOMCode)** -- Filters item references, finds first match with optional UOM constraint

### E-Document Error Helper

- **ErrorMessageCount(EDocument)** -- Returns count of errors (ErrorMessage."Message Type"::Error) for this E-Document
- **WarningMessageCount(EDocument)** -- Returns count of warnings
- **HasErrors(EDocument)** -- Boolean check, faster than ErrorMessageCount() > 0
- **ClearErrorMessages(EDocument)** -- Deletes all Error Message records with Context Record ID = EDocument.RecordId()
- **LogErrorMessage(EDocument, RelatedRec, FieldNo, Message)** -- Logs error + telemetry (FeatureTelemetry.LogError)
- **LogWarningMessage(EDocument, RelatedRec, FieldNo, Message)** -- Logs warning (no telemetry)
- **LogSimpleErrorMessage(EDocument, Message)** -- Logs error without RelatedRec/FieldNo context (used for document-level errors)

### E-Document Log Helper

- **GetDocumentLog(EDocument, Service, Status)** -- Returns most recent log matching E-Doc Entry No + Service Code + Status
- **GetServiceFromLog(EDocument)** -- Returns Service Code from latest log entry (FindLast on logs for this E-Document)
- **GetDocumentBlobFromLog(EDocument, Service, Status, out TempBlob)** -- Retrieves blob from log's Data Storage Entry No.

### E-Document JSON Helper

- **GetJsonToken(JsonText, Path)** -- Navigates JSON path ("obj.arr[0].field"), returns JsonToken
- **SetJsonValueInPath(JsonText, Path, Value)** -- Replaces value at path, returns modified JsonText
- **ParseJsonPath(Path, out Segments)** -- Splits path into array of segment objects (key, index)
- **NavigateJsonPath(JsonToken, Segments)** -- Traverses JsonToken using parsed segments

### E-Document Helper

- **GetEDocTok()** -- Returns 'E-Document' (locked label) for feature telemetry
- **GetTelemetryDimensions(Service, EDocument, out Dimensions)** -- Populates dictionary with SystemId, Service Code, Document Type, Status for all telemetry calls
- **IsElectronicDocument(RecordRef)** -- Checks if RecordRef.Number = Database::"E-Document"

## Validation rules

- **UOM Code must exist or map** -- ResolveUnitOfMeasureFromDataImport() requires match via Code, Int'l Standard Code, or Description; no automatic creation
- **Item Reference requires vendor context** -- FindItemReferenceForLine() errors if EDocument."Bill-to/Pay-to No." not a valid Vendor No.
- **GTIN length validated** -- FindItemForLine() checks StrLen(GTIN) <= MaxStrLen(Item.GTIN) before lookup
- **JSON path must be valid** -- GetJsonToken() returns null token if path doesn't exist; caller must check IsNull() before extracting value
- **Error Message context required** -- LogErrorMessage() requires non-blank EDocument."Entry No" (Context Record ID derived from RecordId())

## Integration patterns

### Conditional import parameter checks

```al
if Service."Resolve Unit Of Measure" then
    if not ImportHelper.ResolveUnitOfMeasureFromDataImport(EDocument, TempPurchaseLine) then
        // Log error, continue or abort based on policy

if Service."Lookup Item Reference" then
    if not ImportHelper.FindItemReferenceForLine(EDocument, TempPurchaseLine) then
        if Service."Lookup Item GTIN" then
            if not ImportHelper.FindItemForLine(EDocument, TempPurchaseLine) then
                if Service."Lookup Account Mapping" then
                    ImportHelper.FindGLAccountForLine(EDocument, TempPurchaseLine);
```

### Error-aware import flow

```al
EDocErrorHelper.ClearErrorMessages(EDocument);
ValidateCompany(EDocument);
ValidateLines(EDocument, TempLines);
if EDocErrorHelper.HasErrors(EDocument) then begin
    EDocument.Status := "E-Document Status"::"Imported Document Processing Error";
    EDocument.Modify();
    exit(false);
end;
CreatePurchaseDocument(EDocument, TempLines);
```

### JSON transformation in Data Exchange format

```al
JsonToken := JsonHelper.GetJsonToken(JsonText, "invoice.buyer.taxId");
if not JsonToken.IsNull then
    VATRegNo := JsonToken.AsValue().AsText();

ModifiedJson := JsonHelper.SetJsonValueInPath(JsonText, "invoice.currency", 'EUR');
```

## Error handling

- **UOMNotFoundErr** -- 'Unit of Measure %1 not found. Check Code, International Standard Code, or Description.'
- **ItemNotFoundErr** -- 'Item not found by vendor reference %1 or GTIN %2.'
- **AccountNotFoundErr** -- 'G/L Account mapping not found for external account code %1.'
- **TotalAmountMismatchErr** -- 'Document total %1 does not match sum of lines %2. Difference: %3.'
- **InvalidGTINErr** -- 'GTIN %1 exceeds maximum length of 14 characters.'
- **VATMismatchErr** -- 'Receiving company VAT %1 does not match company VAT %2.'

## Performance notes

- **Item Reference lookup uses composite index** -- SetRange(Reference Type) + SetRange(Reference Type No.) + SetRange(Reference No.) leverages covering index
- **Error Message context filter cached** -- SetContext(EDocument) called once, ErrorMessageCount() reuses filter for multiple checks
- **UOM lookup tries cheapest first** -- Code exact match (O(1) on PK) → Int'l Standard Code (indexed) → Description (full scan fallback)
- **Log Helper uses FindLast()** -- GetDocumentLog() relies on Entry No. clustered index for efficient "most recent" retrieval
- **JSON navigation avoids reparsing** -- Caller parses JSON once, GetJsonToken() navigates in-memory JsonObject structure
