# Business logic

Additional fields support custom data extraction and storage for e-document fields beyond standard purchase line schema.

## Field definition

Users configure custom fields via E-Doc. Additional Fields Setup page:

1. Open E-Document Service card
2. Navigate to Additional Fields setup
3. Click New to add field definition:
   - Field No. (integer in 50000+ range)
   - Field Caption (display name)
   - Field Type (Text, Decimal, Date, Boolean, Code, Integer)
   - Default Value (optional, used if source data omits field)
4. For Option type fields, define allowed values in separate table
5. Save field definition

Field definitions are stored in E-Doc. Purch. Line Field Setup table, filtered by service code. Multiple services can define fields with the same number but different captions/types.

## Value extraction during Read step

When Read step extracts line data, the system checks for custom field values:

**MLLM extraction:**
1. AOAI response includes JSON object per line
2. System iterates response fields
3. For each field not in standard Purchase Line mapping:
   - Check if field name matches configured custom field caption
   - If found, insert E-Document Line - Field record with appropriate type value
4. Apply default values for missing configured fields

**ADI extraction:**
1. E-Document Line Mapping table includes custom field mappings
2. Mapping rules specify source path (XPath/JSONPath) and target field number (50000+ range)
3. For each custom field mapping:
   - Extract value via IStructuredFormatReader.GetValue(path)
   - Insert E-Document Line - Field record with value in type-specific column
4. Apply transformation rules if specified

Example mapping rule:
```
Source Path: /Invoice/Line/CustomTaxCode
Target Field No.: 50100
Field Type: Code
Transformation Rule: TaxCodeMapping (converts external codes to internal)
```

## Value validation

Before inserting E-Document Line - Field records, the system validates:

- Field number exists in E-Doc. Purch. Line Field Setup for the service
- Value matches field type (text can convert to code/integer, but not to date)
- For Option fields, value exists in allowed options list
- Value length doesn't exceed type limits (2048 chars for text/code)

Invalid values log warnings but don't fail the Read step. Line is marked with validation warning icon, users can correct values during review.

## User review and editing

Imported lines with custom fields show a FactBox on the E-Document Purchase Draft page:

1. User opens E-Document with status "Read Done" or "Prepare Done"
2. Navigates to Lines tab
3. Selects a line
4. FactBox shows "Additional Fields" section
5. Each custom field appears as read-only or editable field based on type:
   - Text: Edit control
   - Decimal: Decimal input with formatting
   - Date: Date picker
   - Boolean: Checkbox
   - Code: Lookup to allowed options (if Option type)
   - Integer: Integer input
6. User modifies values if needed
7. Changes save immediately to E-Document Line - Field table

The E-Doc. Line Values page provides grid view for bulk editing:

1. From Line action menu, choose "Edit Additional Fields"
2. Page shows all custom fields as columns
3. User can filter, sort, and edit multiple lines at once
4. Changes commit on page close

## Value application during Finish step

IEDocumentFinishDraft implementations can read custom field values and apply to Purchase Line:

```al
codeunit 50100 "My Finish Draft" implements IEDocumentFinishDraft
{
    procedure FinishDraft(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"): Boolean
    var
        EDocLineField: Record "E-Document Line - Field";
    begin
        EDocLineField.SetRange("E-Document Entry No.", PurchaseHeader."E-Document Entry No.");
        EDocLineField.SetRange("Line No.", PurchaseLine."E-Document Line Entry No.");
        EDocLineField.SetRange("Field No.", 50100); // Custom Tax Code field
        if EDocLineField.FindFirst() then
            PurchaseLine."My Custom Tax Code" := EDocLineField."Code Value"; // Extension field
        exit(true);
    end;
}
```

Custom field values can also populate:
- Purchase Line dimensions
- Item Cross References
- Routing/work center notes
- Compliance tracking records

## Historical persistence

Custom field values remain in E-Document Line - Field table after Finish step completes. This enables:

- Audit of extracted vs. applied values
- Re-processing if custom field mapping changes
- Reporting on custom field usage across documents
- Troubleshooting extraction accuracy

When users undo Read step, custom field values are deleted (part of cascade delete). When users undo Prepare or Finish, custom field values are preserved (only [BC] reference fields are cleared).

## Option field handling

Option fields restrict values to a predefined list:

1. Define option field in E-Doc. Purch. Line Field Setup with type Option
2. Add allowed values to EDPurchaseLineFieldSetup table:
   - Field No. (matches field definition)
   - Option Value (code)
   - Option Caption (display text)
3. During extraction, if value doesn't match any option, use default or log warning
4. During editing, E-Doc. Option Value Selector page shows allowed values only
5. On Finish, validate option value still exists (in case setup changed)

Example: Payment terms field with options "Net30", "Net60", "Net90". If extracted value is "N30", transformation rule maps to "Net30" option.
