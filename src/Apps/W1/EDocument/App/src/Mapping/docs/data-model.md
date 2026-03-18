# Data model

The Mapping data model consists of two tables: E-Doc. Mapping (configuration storage) and E-Doc. Mapping Log (applied transformation audit trail). The model supports service-specific rules, table/field targeting, and transformation tracking.

## Entity overview

```mermaid
erDiagram
    E-DOCUMENT-SERVICE ||--o{ E-DOC-MAPPING : "has mapping rules"
    E-DOC-MAPPING {
        int EntryNo PK
        code20 Code FK
        int TableID
        int FieldID
        code20 TransformationRule
        text250 FindValue
        text250 ReplacValue
        bool Used
        int LineNo
        bool ForImport
    }

    E-DOCUMENT ||--o{ E-DOC-MAPPING-LOG : "has transformation logs"
    E-DOC-MAPPING-LOG {
        int EDocEntryNo PK_FK
        int EntryNo PK
        int TableID
        int FieldID
        text250 FindValue
        text250 ReplaceValue
        code20 TransformationRule
        int LineNo
    }

    TRANSFORMATION-RULE ||--o{ E-DOC-MAPPING : "referenced by"
    TRANSFORMATION-RULE {
        code20 Code PK
        text100 Description
        enum TransformationType
    }
```

## E-Doc. Mapping table

**Purpose:** Stores transformation rules associated with E-Document Services, defining how to modify field values before export or after import.

**Primary key:** (Code, Entry No.)
- Code: E-Document Service Code (multi-tenancy support)
- Entry No.: Auto-incremented sequence per service

**Field descriptions:**

| Field | Type | Purpose |
|-------|------|---------|
| Entry No. | Integer | Unique identifier within service scope, auto-incremented |
| Code | Code[20] | Links to E-Document Service.Code, defines which service uses this rule |
| Table ID | Integer | Target table number (0 = all tables), validated against AllObjWithCaption |
| Field ID | Integer | Target field number (0 = all fields on table), validated against Field table |
| Transformation Rule | Code[20] | Links to Transformation Rule table for complex transformations |
| Find Value | Text[250] | For simple find-replace: value to search for |
| Replace Value | Text[250] | For simple find-replace: value to replace with |
| Indent | Integer | Preview UI indentation level (0 = header, 1 = line) |
| Used | Boolean | Runtime flag indicating rule was applied in current session |
| Line No. | Integer | For line-level tracking: stores source line identifier |
| For Import | Boolean | If true, rule applies during import; if false, during export |

**Table properties:**
- Access = Public (extensible by partners)
- Extensible = false (schema locked for stability)
- ReplicateData = false (configuration data, not replicated across companies)

**Key indexes:**

```al
keys
{
    key(Key1; Code, "Entry No.") { Clustered = true; }
    key(Key2; "Line No.") { }
    key(Key3; Used, Code, "For Import") { }
}
```

**Key1 (primary):** Enables fast lookup of all rules for a service (filter Code, iterate Entry No.)

**Key2 (Line No.):** Supports line-level filtering in preview/log UIs

**Key3 (Used, Code, For Import):** Optimizes queries for "which rules were actually applied during this session" (filter Used = true, Code = service code)

**Validation rules:**
- Code: NotBlank = true, validates against E-Document Service table
- Table ID: TableRelation to AllObjWithCaption filtered by Object Type = Table
- Field ID: TableRelation to Field filtered by TableNo = Table ID

## E-Doc. Mapping Log table

**Purpose:** Audit trail of applied transformations, recording every field modification during mapping execution.

**Primary key:** (E-Doc Entry No., Entry No.)
- E-Doc Entry No.: Links to E-Document."Entry No"
- Entry No.: Auto-incremented sequence per E-Document

**Field descriptions:**

| Field | Type | Purpose |
|-------|------|---------|
| E-Doc Entry No. | Integer | Foreign key to E-Document table |
| Entry No. | Integer | Sequence number within E-Document scope |
| Table ID | Integer | Source table number where transformation occurred |
| Field ID | Integer | Source field number that was modified |
| Find Value | Text[250] | Original field value before transformation |
| Replace Value | Text[250] | New field value after transformation |
| Transformation Rule | Code[20] | Name of applied rule (if used) |
| Line No. | Integer | Source line identifier (for line-level changes) |

**Table properties:**
- DataClassification = CustomerContent (audit data)
- Permissions: tabledata "E-Doc. Mapping Log" = im (restricted to mapping codeunit)

**Key structure:**

```al
keys
{
    key(Key1; "E-Doc Entry No.", "Entry No.") { Clustered = true; }
}
```

**Key1:** Enables fast retrieval of all logs for an E-Document in application order.

**Usage pattern:**

1. Mapping codeunit creates temporary Mapping records during MapRecord execution
2. After processing completes, caller inserts temp records into Mapping Log table
3. Users view Mapping Logs page filtered by E-Doc Entry No. to see transformation history

**Data retention:** Mapping logs are deleted when parent E-Document is deleted (cascading delete in E-Document.CleanupDocument).

## Transformation Rule integration

The Mapping system leverages the system-wide **Transformation Rule** table from System.IO:

```al
table 1237 "Transformation Rule"
{
    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; "Transformation Type"; Enum "Transformation Rule Type") { }
        field(4; "Find Value"; Text[250]) { }
        field(5; "Replace Value"; Text[250]) { }
        field(10; "Start Position"; Integer) { }
        field(11; "Length"; Integer) { }
        // ... custom transformation fields
    }
}
```

**Standard transformation types:**
- UPPERCASE, LOWERCASE, TITLECASE
- TRIM, TRIMSTART, TRIMEND
- SUBSTRING (extract portion of text)
- REPLACE (regex-based replacement)
- DATEFORMAT (date formatting)
- CUSTOM (codeunit-based transformation)

**Custom transformations:** Partners can extend via OnTransformation event:

```al
[EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnTransformation', '', false, false)]
local procedure CustomTransform(TransformationCode: Code[20]; InputText: Text; var OutputText: Text)
begin
    case TransformationCode of
        'REMOVE-PREFIX':
            OutputText := InputText.Replace('ITEM-', '');
        'ADD-COUNTRY-CODE':
            OutputText := 'US-' + InputText;
    end;
end;
```

## Configuration patterns

**Pattern 1: Service-specific date formatting**

Create mapping rule:
- Code = "PEPPOL-SERVICE"
- Table ID = 36 (Sales Header)
- Field ID = 0 (all fields)
- Transformation Rule = "ISO-DATE-FORMAT"

Result: All date fields on Sales Header are formatted to ISO 8601 before PEPPOL export.

**Pattern 2: Global currency normalization**

Create mapping rule:
- Code = "PEPPOL-SERVICE"
- Table ID = 0 (all tables)
- Field ID = 0 (all fields)
- Find Value = "USD"
- Replace Value = "US Dollar"

Result: Any field containing "USD" across all tables gets expanded.

**Pattern 3: Import-only field mapping**

Create mapping rule:
- Code = "IMPORT-SERVICE"
- Table ID = 38 (Purchase Header)
- Field ID = 79 (Vendor Order No.)
- For Import = true
- Transformation Rule = "TRIM-WHITESPACE"

Result: Vendor Order No. is trimmed during import only, not during export.

## Runtime behavior

**Temporary record pattern:**

```al
procedure MapRecord(var EDocumentMapping: Record "E-Doc. Mapping"; RecordSource: RecordRef; var TempRecordTarget: RecordRef; var TempEDocMapping: Record "E-Doc. Mapping" temporary)
begin
    if not TempRecordTarget.IsTemporary() then
        Error(NonTempRecordErr);

    TempRecordTarget.Copy(RecordSource);
    // Apply transformations...
    TempRecordTarget.Insert();
end;
```

**Why temporary RecordRef?** Prevents accidental modification of committed database records. Caller must explicitly insert the modified record after validation.

**Used flag lifecycle:**

1. PreviewMapping calls `ModifyAll(Used, false)` to reset all rules
2. MapRecord sets `Used = true` on each applied rule
3. Preview filters `Used = true` to show only applied rules
4. Next session resets flags again

**Line number tracking:**

```al
EDocMapping.SetFirstRun();  // Reset indent counter
for each SalesLine do begin
    EDocMapping.SetLineNo(SalesLine."Line No.");
    EDocMapping.MapRecord(...);  // Logs include Line No. = 10000, 20000, etc.
end;
```

This enables line-level filtering in logs: "Show only transformations for Line No. 10000".

## Performance considerations

**Key2 (Line No.) index:** Without this index, filtering logs by line number requires full table scan. With it, queries are logarithmic.

**Key3 (Used, Code, For Import) index:** Optimizes preview queries that filter `Used = true AND Code = @ServiceCode`. Without it, query plans use full table scan on Used boolean field.

**ReplicateData = false:** Prevents unnecessary replication of configuration data across companies in multi-company environments, reducing database size.

**Entry No. auto-increment:** Uses database sequence for performance (no need to query MAX(Entry No.) on each insert).

## Schema extensibility

Partners can extend E-Doc. Mapping via table extension:

```al
tableextension 50100 "My Mapping Ext" extends "E-Doc. Mapping"
{
    fields
    {
        field(50100; "Custom Field 1"; Text[100]) { }
        field(50101; "Custom Field 2"; Integer) { }
    }
}
```

However, core codeunit logic won't automatically use extended fields. Partners must subscribe to OnAfterParseInvoice/OnAfterParseCreditMemo events to inject custom mapping logic.
