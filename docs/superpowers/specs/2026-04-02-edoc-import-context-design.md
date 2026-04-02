# E-Doc. Import Context: Enriched Error Messages for E-Document Import

## Problem

When the E-Document import process fails (e.g., during `FieldRef.Validate` for additional fields or `Record.Validate` for standard fields), the error message surfaced to the user via `GetLastErrorText()` is generic. It contains no information about which field, value, or operation caused the failure. The user cannot easily diagnose the root cause.

The current approach on the branch (`[ErrorBehavior(ErrorBehavior::Collect)]` on `ValidateFieldValueOrLogWarning`) does not work because `FieldRef.Validate` errors escape the `ErrorBehavior::Collect` mechanism.

## Solution

Introduce a new **SingleInstance** codeunit `"E-Doc. Import Context"` that tracks the current operation context during the import process. When an error is caught in `RunConfiguredImportStep`, the context is read and prepended to the error message.

### Key Properties

- `SingleInstance = true` — one instance per session, state survives across `Codeunit.Run()` boundaries
- `EventSubscriberInstance = Manual` — event subscribers are only active when explicitly bound via `BindSubscription`/`UnbindSubscription`

### How It Works

#### Standard field validates (`Record.Validate`)

The codeunit subscribes to `OnBeforeValidate` events on key Purchase Header and Purchase Line fields. When bound, each subscriber automatically captures the field caption and value being validated into `CurrentContext`. No changes needed at callsites in `CreatePurchaseInvoice` or `CreatePurchaseInvoiceLine`.

**Subscribed Purchase Header fields:** `"Document Date"`, `"Due Date"`, `"Vendor Invoice No."`, `"Currency Code"`

**Subscribed Purchase Line fields:** `"No."`, `"Allow Invoice Disc."`, `"Item Reference No."`, `Quantity`, `"Direct Unit Cost"`, `"Line Discount Amount"`, `"Deferral Code"`, `"Dimension Set ID"`, `"Shortcut Dimension 1 Code"`, `"Shortcut Dimension 2 Code"`

#### Additional field validates (`FieldRef.Validate`)

`OnBeforeValidate` field-level events may fire for `FieldRef.Validate` too, but additional fields are user-configured and could be any field. A dedicated procedure `SetAdditionalFieldContext(FieldName, FieldNo, Value)` is called from the loop in `ApplyAdditionalFieldsFromHistoryToPurchaseLine` before each `FieldRef.Validate`. This procedure also calls `Unbind()` internally to disable the `OnBeforeValidate` subscribers, preventing them from overwriting the richer additional field context.

After a successful `FieldRef.Validate`, `ClearAdditionalFieldContext()` is called, which re-enables subscribers via `Bind()`.

#### Bind state tracking

A boolean `IsBound` prevents double `BindSubscription`/`UnbindSubscription` calls. This is critical on the failure path: if `FieldRef.Validate` fails after `SetAdditionalFieldContext` (which unbinds), the error bubbles up to `RunConfiguredImportStep` which also calls `Unbind()`. The boolean guard makes this safe.

#### Error enrichment in `RunConfiguredImportStep`

After catching the error via `GetLastErrorText()`, the procedure calls `ImportContext.WrapErrorMessage(LastErrorText)` which returns an enriched message if context is available, or the original message if not.

## New Codeunit: "E-Doc. Import Context"

### State

```al
var
    CurrentContext: Text;
    IsBound: Boolean;
```

### Public API

| Procedure | Description |
|-----------|-------------|
| `Bind()` | Calls `BindSubscription(this)` if not already bound. Sets `IsBound := true`. |
| `Unbind()` | Calls `UnbindSubscription(this)` if bound. Sets `IsBound := false`. |
| `HasContext(): Boolean` | Returns `CurrentContext <> ''` |
| `WrapErrorMessage(OriginalError: Text): Text` | If context is set, returns `StrSubstNo(WrapLbl, CurrentContext, OriginalError)`. Otherwise returns `OriginalError`. Clears context after reading. |
| `SetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)` | Calls `Unbind()`, then sets `CurrentContext` with additional field details. |
| `ClearAdditionalFieldContext()` | Clears `CurrentContext`, then calls `Bind()`. |

### Event Subscribers

Each `OnBeforeValidate` subscriber sets `CurrentContext` with the field caption. Example:

```al
[EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "No.", false, false)]
local procedure OnBeforeValidatePurchLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
begin
    CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("No."));
end;
```

## Changes to Existing Code

### `RunConfiguredImportStep` in `EDocImport.Codeunit.al`

```al
local procedure RunConfiguredImportStep(var ImportEDocumentProcess: Codeunit "Import E-Document Process"; EDocument: Record "E-Document"): Boolean
var
    EDocImportContext: Codeunit "E-Doc. Import Context";
    ...
begin
    EDocumentErrorHelper.ClearErrorMessages(EDocument);
    Commit();
    EDocImportContext.Bind();
    if not ImportEDocumentProcess.Run() then begin
        LastErrorText := GetLastErrorText();
        if LastErrorText <> '' then begin
            LastErrorText := EDocImportContext.WrapErrorMessage(LastErrorText);
            // ... existing error logging with enriched LastErrorText
        end;
        ...
    end;
    EDocImportContext.Unbind();
    ...
end;
```

### `ApplyAdditionalFieldsFromHistoryToPurchaseLine` in `EDocPurchaseHistMapping.Codeunit.al`

Remove `ValidateFieldValueOrLogWarning` and the `[ErrorBehavior(ErrorBehavior::Collect)]` approach. Replace with direct `FieldRef.Validate` wrapped by context:

```al
procedure ApplyAdditionalFieldsFromHistoryToPurchaseLine(EDocumentPurchaseLine: Record "E-Document Purchase Line"; var PurchaseLine: Record "Purchase Line")
var
    EDocImportContext: Codeunit "E-Doc. Import Context";
    EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
    EDocPurchLineField: Record "E-Document Line - Field";
    NewPurchLineRecordRef: RecordRef;
    NewPurchLineFieldRef: FieldRef;
    FieldValue: Variant;
begin
    if not EDocPurchLineFieldSetup.FindSet() then
        exit;
    NewPurchLineRecordRef.GetTable(PurchaseLine);
    repeat
        if EDocPurchLineFieldSetup.IsOmitted() then
            continue;
        EDocPurchLineField.Get(EDocumentPurchaseLine, EDocPurchLineFieldSetup);
        NewPurchLineFieldRef := NewPurchLineRecordRef.Field(EDocPurchLineFieldSetup."Field No.");
        FieldValue := EDocPurchLineField.GetValue();
        EDocImportContext.SetAdditionalFieldContext(NewPurchLineFieldRef.Name(), EDocPurchLineFieldSetup."Field No.", Format(FieldValue));
        NewPurchLineFieldRef.Validate(FieldValue);
        EDocImportContext.ClearAdditionalFieldContext();
    until EDocPurchLineFieldSetup.Next() = 0;
    NewPurchLineRecordRef.SetTable(PurchaseLine);
end;
```

### `CreatePurchaseInvoiceLine` in `EDocCreatePurchaseInvoice.Codeunit.al`

No changes needed. The `OnBeforeValidate` event subscribers automatically capture context for every `PurchaseLine.Validate(...)` and `PurchaseHeader.Validate(...)` call.

## Error Message Format

**For additional fields:**
> While applying additional field "Payment Method Code" (ID 81) with value "BANK": <original error>

**For standard field validates:**
> While validating field "Currency Code": <original error>

**When no context is set:**
> <original error> (unchanged)

## Test Plan

All tests use the existing `Initialize` + `LibraryEDoc.CreateInboundPEPPOLDocumentToState` pattern from `EDocProcessTest.Codeunit.al`.

### Test 1: Additional field with invalid value enriches error message
- **Setup:** Configure an additional field (e.g., "Location Code") with an invalid value (e.g., a non-existent location code that fails validation).
- **Action:** Finalize the draft.
- **Assert:** The E-Document has an error. The error message contains the additional field name, field ID, value, AND the original validation error.

### Test 2: Additional field with value exceeding field length enriches error message
- **Setup:** Configure an additional field (e.g., "Location Code" which is Code[10]) with a value that exceeds the field length (e.g., "LONGLOCCODE1").
- **Action:** Finalize the draft.
- **Assert:** The E-Document has an error. The error message references "Location Code", the field ID, and the overlong value.

### Test 3: Standard field validation failure enriches error message
- **Setup:** Create a draft where a standard field will fail validation (e.g., set an invalid "Currency Code" on the purchase header, or an invalid item "No." on a line).
- **Action:** Finalize the draft.
- **Assert:** The E-Document has an error. The error message contains the field caption (e.g., "Currency Code") alongside the original error.

### Test 4: Successful import produces no error context leakage
- **Setup:** Create a valid draft with valid additional fields configured.
- **Action:** Finalize the draft.
- **Assert:** The purchase invoice is created successfully. No errors or warnings on the E-Document.

### Test 5: Multiple additional fields — failure on second field has correct context
- **Setup:** Configure two additional fields. First field has a valid value. Second field has an invalid value.
- **Action:** Finalize the draft.
- **Assert:** The error message references the *second* field (not the first), proving context is correctly updated per iteration.

### Test 6: Additional field failure followed by standard field context does not leak
- **Setup:** This is inherently covered by the bind/unbind mechanism — after `SetAdditionalFieldContext` unbinds, `OnBeforeValidate` subscribers won't fire. But we can verify: configure a valid additional field, and then have a standard field fail after the additional fields loop.
- **Action:** Finalize the draft.
- **Assert:** The error message references the standard field, not the additional field.

### Test 7: No additional fields configured — standard field failure still enriched
- **Setup:** No additional fields configured. A standard field validation fails (e.g., invalid vendor, invalid item no.).
- **Action:** Finalize the draft.
- **Assert:** The error message is enriched with the standard field context.
