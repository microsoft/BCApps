# E-Doc. Import Context Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enrich generic E-Document import error messages with field-level context so users can diagnose validation failures.

**Architecture:** A new SingleInstance codeunit `"E-Doc. Import Context"` (ID 6199) captures validation context via `OnBeforeValidate` event subscribers (for `Record.Validate`) and a manual `SetAdditionalFieldContext` procedure (for `FieldRef.Validate`). `RunConfiguredImportStep` binds/unbinds the subscribers and wraps caught errors with context.

**Tech Stack:** AL (Business Central), SingleInstance codeunit with Manual EventSubscriberInstance

**Spec:** `docs/superpowers/specs/2026-04-02-edoc-import-context-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| **Create** | `src/Apps/W1/EDocument/App/src/Processing/Import/EDocImportContext.Codeunit.al` | SingleInstance codeunit: tracks validation context, OnBeforeValidate subscribers, Bind/Unbind API |
| **Modify** | `src/Apps/W1/EDocument/App/src/Processing/EDocImport.Codeunit.al:135-160` | `RunConfiguredImportStep`: bind context before Run, wrap error, unbind + clear after |
| **Modify** | `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/History/EDocPurchaseHistMapping.Codeunit.al:212-250` | Remove `ValidateFieldValueOrLogWarning`, use `SetAdditionalFieldContext`/`ClearAdditionalFieldContext` around `FieldRef.Validate` |
| **Modify** | `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al` | Add 7 test procedures for error message enrichment |

---

### Task 1: Create the E-Doc. Import Context codeunit

**Files:**
- Create: `src/Apps/W1/EDocument/App/src/Processing/Import/EDocImportContext.Codeunit.al`

- [ ] **Step 1: Create the codeunit file**

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.Purchases.Document;

codeunit 6199 "E-Doc. Import Context"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        CurrentContext: Text;
        IsBound: Boolean;
        AdditionalFieldContextLbl: Label 'While applying additional field "%1" (ID %2) with value ''%3''', Comment = '%1 = Field Name, %2 = Field Number, %3 = Value';
        ValidatingFieldLbl: Label 'While validating field "%1"', Comment = '%1 = Field Caption';
        WrapErrorLbl: Label '%1: %2', Comment = '%1 = Context, %2 = Original Error';

    procedure Bind()
    begin
        if not IsBound then begin
            BindSubscription(this);
            IsBound := true;
        end;
    end;

    procedure Unbind()
    begin
        if IsBound then begin
            UnbindSubscription(this);
            IsBound := false;
        end;
    end;

    procedure HasContext(): Boolean
    begin
        exit(CurrentContext <> '');
    end;

    procedure WrapErrorMessage(OriginalError: Text): Text
    begin
        if CurrentContext = '' then
            exit(OriginalError);
        exit(StrSubstNo(WrapErrorLbl, CurrentContext, OriginalError));
    end;

    procedure SetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)
    begin
        Unbind();
        CurrentContext := StrSubstNo(AdditionalFieldContextLbl, FieldName, FieldNo, Value);
    end;

    procedure ClearAdditionalFieldContext()
    begin
        CurrentContext := '';
        Bind();
    end;

    // Purchase Header OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Document Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDocDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Document Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Due Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDueDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Due Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Vendor Invoice No.", false, false)]
    local procedure OnBeforeValidatePurchHdrVendInvNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Vendor Invoice No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Currency Code", false, false)]
    local procedure OnBeforeValidatePurchHdrCurrCode(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Currency Code"));
    end;

    // Purchase Line OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "No.", false, false)]
    local procedure OnBeforeValidatePurchLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Allow Invoice Disc.", false, false)]
    local procedure OnBeforeValidatePurchLineAllowInvDisc(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Allow Invoice Disc."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Item Reference No.", false, false)]
    local procedure OnBeforeValidatePurchLineItemRefNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Item Reference No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, Quantity, false, false)]
    local procedure OnBeforeValidatePurchLineQty(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption(Quantity));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Direct Unit Cost", false, false)]
    local procedure OnBeforeValidatePurchLineDirectUnitCost(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Direct Unit Cost"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Line Discount Amount", false, false)]
    local procedure OnBeforeValidatePurchLineLineDiscAmt(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Line Discount Amount"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Deferral Code", false, false)]
    local procedure OnBeforeValidatePurchLineDeferralCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Deferral Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Dimension Set ID", false, false)]
    local procedure OnBeforeValidatePurchLineDimSetId(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Dimension Set ID"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 1 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim1(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 1 Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 2 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim2(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 2 Code"));
    end;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `al compile` (or equivalent build)
Expected: No compilation errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/EDocImportContext.Codeunit.al
git commit -m "feat: add E-Doc. Import Context codeunit for error enrichment"
```

---

### Task 2: Integrate context into RunConfiguredImportStep

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/EDocImport.Codeunit.al:135-160`

- [ ] **Step 1: Add the using directive if needed**

Check if `Microsoft.eServices.EDocument.Processing.Import` is already in the using list. If not, add:

```al
using Microsoft.eServices.EDocument.Processing.Import;
```

- [ ] **Step 2: Modify RunConfiguredImportStep**

Replace the current procedure (lines 135-160) with:

```al
    local procedure RunConfiguredImportStep(var ImportEDocumentProcess: Codeunit "Import E-Document Process"; EDocument: Record "E-Document"): Boolean
    var
        EDocDraftSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        EDocImportContext: Codeunit "E-Doc. Import Context";
        LastErrorText: Text;
    begin
        EDocumentErrorHelper.ClearErrorMessages(EDocument);
        Commit();
        EDocImportContext.Bind();
        if not ImportEDocumentProcess.Run() then begin
            LastErrorText := GetLastErrorText();
            if LastErrorText <> '' then begin // We don't insert an error when empty, following the convention of empty error meaning "operation cancelled by user"
                LastErrorText := EDocImportContext.WrapErrorMessage(LastErrorText);
                EDocument.SetRecFilter();
                EDocument.FindFirst();

                EDocErrorHelper.LogSimpleErrorMessage(EDocument, LastErrorText);
                EDocument.CalcFields("Import Processing Status");
                EDocumentLog.InsertLog(Enum::"E-Document Service Status"::"Imported Document Processing Error", EDocument."Import Processing Status");
                EDocumentProcessing.ModifyServiceStatus(EDocument, EDocument.GetEDocumentService(), Enum::"E-Document Service Status"::"Imported Document Processing Error");
                EDocumentProcessing.ModifyEDocumentStatus(EDocument);
            end;
            EDocDraftSessionTelemetry.SetText('Step', Format(ImportEDocumentProcess.GetStep()));
            EDocDraftSessionTelemetry.SetBool('Success', false);
            EDocImportContext.Unbind();
            Clear(EDocImportContext);
            exit(false);
        end;
        EDocImportContext.Unbind();
        Clear(EDocImportContext);
        exit(true);
    end;
```

Key changes from original:
1. Added `EDocImportContext` variable
2. `EDocImportContext.Bind()` after `Commit()`
3. `LastErrorText := EDocImportContext.WrapErrorMessage(LastErrorText)` before logging
4. `EDocImportContext.Unbind()` and `Clear(EDocImportContext)` on both success and failure paths

- [ ] **Step 3: Verify it compiles**

Run: `al compile`
Expected: No compilation errors.

- [ ] **Step 4: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/EDocImport.Codeunit.al
git commit -m "feat: bind E-Doc. Import Context in RunConfiguredImportStep for error enrichment"
```

---

### Task 3: Modify ApplyAdditionalFieldsFromHistoryToPurchaseLine

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/History/EDocPurchaseHistMapping.Codeunit.al:206-250`

- [ ] **Step 1: Replace ApplyAdditionalFieldsFromHistoryToPurchaseLine and remove ValidateFieldValueOrLogWarning**

Remove the XML doc comment about "Validation failures are skipped and logged as warnings" (lines 206-209) and the `ValidateFieldValueOrLogWarning` procedure entirely (lines 236-250).

Replace `ApplyAdditionalFieldsFromHistoryToPurchaseLine` (lines 212-234) with:

```al
    /// <summary>
    /// Applies the values configured as additional fields in the posted line, if the line had a historic match the values are retrieved from the Purchase Invoice Line.
    /// </summary>
    /// <param name="EDocumentPurchaseLine"></param>
    /// <param name="PurchaseLine"></param>
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

Key changes:
1. Removed `EDocument` record variable and `EDocument.Get(...)` call — no longer needed since we don't log warnings here
2. Removed `ValidateFieldValueOrLogWarning` call, replaced with direct `FieldRef.Validate` wrapped by `SetAdditionalFieldContext`/`ClearAdditionalFieldContext`
3. Removed the entire `ValidateFieldValueOrLogWarning` procedure
4. Added `using Microsoft.eServices.EDocument.Processing.Import;` to the using list if not already present

- [ ] **Step 2: Remove unused using directives**

Remove `using System.Log;` if it was only used by the `EDocumentErrorHelper` reference that no longer exists. Also remove `using Microsoft.eServices.EDocument;` if the `EDocument` record is no longer referenced in this codeunit. Check each using directive — only remove those that are no longer needed.

- [ ] **Step 3: Verify it compiles**

Run: `al compile`
Expected: No compilation errors.

- [ ] **Step 4: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/History/EDocPurchaseHistMapping.Codeunit.al
git commit -m "refactor: use E-Doc. Import Context for additional field validation instead of ErrorBehavior::Collect"
```

---

### Task 4: Test — Additional field with invalid value enriches error

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Replace the existing `AdditionalFieldValueExceedingFieldLengthShouldWarn` test**

The old test asserts warnings and a successful document creation. The new behavior is an error with enriched message and no document created. Replace it with:

```al
    [Test]
    procedure AdditionalFieldWithInvalidValueEnrichesErrorMessage()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        ErrorMessage: Record "Error Message";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        // [SCENARIO] An additional field is configured with an invalid value that fails FieldRef.Validate.
        // The error message should contain the additional field name, ID, and value.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An additional field is configured for Location Code (Code[10])
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();

        // [GIVEN] An inbound e-document is received and a draft created
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] A value that does not exist as a Location Code
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineField."Code Value" := 'INVALID';
        EDocPurchLineField.Insert();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams);

        // [THEN] The e-document should have an error
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should have errors');

        // [THEN] The error message should reference the additional field name, ID, and value
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage('Location Code', ErrorMessage."Message");
        Assert.ExpectedMessage(Format(PurchaseInvoiceLine.FieldNo("Location Code")), ErrorMessage."Message");
        Assert.ExpectedMessage('INVALID', ErrorMessage."Message");

        // [THEN] No purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Verify the test compiles**

Run: `al compile`
Expected: No compilation errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: additional field with invalid value enriches error message"
```

---

### Task 5: Test — Additional field with value exceeding field length enriches error

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Add the test**

```al
    [Test]
    procedure AdditionalFieldValueExceedingFieldLengthEnrichesErrorMessage()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        ErrorMessage: Record "Error Message";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        FieldValue: Code[2048];
    begin
        // [SCENARIO] An additional field is configured with a value that exceeds the target field's maximum length.
        // The error message should reference the additional field name, ID, and the overlong value.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An additional field is configured for Location Code (Code[10])
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();

        // [GIVEN] An inbound e-document is received and a draft created
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] A value that exceeds the target field length (Code[10])
        FieldValue := 'LONGLOCCODE1'; // 12 characters, exceeds Code[10]
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineField."Code Value" := FieldValue;
        EDocPurchLineField.Insert();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams);

        // [THEN] The e-document should have an error
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should have errors');

        // [THEN] The error message should reference the additional field name and value
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage('Location Code', ErrorMessage."Message");
        Assert.ExpectedMessage(FieldValue, ErrorMessage."Message");

        // [THEN] No purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: additional field exceeding field length enriches error message"
```

---

### Task 6: Test — Standard field validation failure enriches error

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Add the test**

This test creates a draft and then corrupts the currency code on the purchase header to an invalid value before finalizing, so that `PurchaseHeader.Validate("Currency Code", ...)` fails during `CreatePurchaseInvoice`.

```al
    [Test]
    procedure StandardFieldValidationFailureEnrichesErrorMessage()
    var
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        // [SCENARIO] A standard field validation fails during purchase invoice creation.
        // The error message should contain the field caption.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document is received and a draft created
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] The draft has an invalid currency code
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader."Currency Code" := 'INVALIDCURR';
        EDocumentPurchaseHeader.Modify();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams);

        // [THEN] The e-document should have an error
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should have errors');

        // [THEN] The error message should reference the Currency Code field
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage('Currency Code', ErrorMessage."Message");

        // [THEN] No purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: standard field validation failure enriches error message"
```

---

### Task 7: Test — Successful import with additional fields has no error leakage

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Add the test**

This is similar to the existing `AdditionalFieldsFromHistoryAreAppliedToPurchaseLine` test but explicitly verifies no errors/warnings exist after successful import with additional fields.

```al
    [Test]
    procedure SuccessfulImportWithAdditionalFieldsHasNoErrors()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        ErrorMessage: Record "Error Message";
        Location: Record Location;
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        // [SCENARIO] Additional fields are configured with valid values.
        // The import should succeed with no errors or warnings.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An additional field is configured for Location Code
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();

        // [GIVEN] A valid location exists
        Location.Code := 'VALIDLOC';
        Location.Insert();

        // [GIVEN] An inbound e-document is received and a draft created
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] The additional field has a valid value
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineField."Code Value" := 'VALIDLOC';
        EDocPurchLineField.Insert();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        Assert.IsTrue(EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams), 'The finalization should succeed');

        // [THEN] The e-document should have no errors
        EDocument.Get(EDocument."Entry No");
        Assert.IsFalse(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should not have errors');

        // [THEN] No error or warning messages should exist
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        Assert.RecordIsEmpty(ErrorMessage);

        // [THEN] A purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsNotEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: successful import with additional fields has no errors"
```

---

### Task 8: Test — Multiple additional fields, failure on second has correct context

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Add the test**

```al
    [Test]
    procedure MultipleAdditionalFieldsFailureOnSecondHasCorrectContext()
    var
        EDocPurchLineFieldSetup: Record "ED Purchase Line Field Setup";
        PurchaseInvoiceLine: Record "Purch. Inv. Line";
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocPurchLineField: Record "E-Document Line - Field";
        EDocPurchaseLine: Record "E-Document Purchase Line";
        ErrorMessage: Record "Error Message";
        Location: Record Location;
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        // [SCENARIO] Two additional fields are configured. The first has a valid value, the second has an invalid value.
        // The error message should reference the second field, not the first.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] Two additional fields configured: Location Code and Bin Code
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineFieldSetup.Insert();
        Clear(EDocPurchLineFieldSetup);
        EDocPurchLineFieldSetup."Field No." := PurchaseInvoiceLine.FieldNo("Bin Code");
        EDocPurchLineFieldSetup.Insert();

        // [GIVEN] A valid location exists
        Location.Code := 'VALIDLOC';
        Location.Insert();

        // [GIVEN] An inbound e-document is received and a draft created
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] First field (Location Code) has a valid value, second field (Bin Code) has an invalid value
        EDocPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPurchaseLine.FindFirst();

        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Location Code");
        EDocPurchLineField."Code Value" := 'VALIDLOC';
        EDocPurchLineField.Insert();

        Clear(EDocPurchLineField);
        EDocPurchLineField."E-Document Entry No." := EDocument."Entry No";
        EDocPurchLineField."Line No." := EDocPurchaseLine."Line No.";
        EDocPurchLineField."Field No." := PurchaseInvoiceLine.FieldNo("Bin Code");
        EDocPurchLineField."Code Value" := 'INVALIDBIN';
        EDocPurchLineField.Insert();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams);

        // [THEN] The e-document should have an error
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should have errors');

        // [THEN] The error message should reference the second field (Bin Code), not the first (Location Code)
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage('Bin Code', ErrorMessage."Message");
        Assert.ExpectedMessage('INVALIDBIN', ErrorMessage."Message");

        // [THEN] No purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: multiple additional fields - failure on second has correct context"
```

---

### Task 9: Test — No additional fields, standard field failure still enriched

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

- [ ] **Step 1: Add the test**

```al
    [Test]
    procedure NoAdditionalFieldsStandardFieldFailureStillEnriched()
    var
        EDocument: Record "E-Document";
        EDocImportParams: Record "E-Doc. Import Parameters";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        // [SCENARIO] No additional fields are configured. A standard field validation fails.
        // The error message should still be enriched with the field context.
        Initialize(Enum::"Service Integration"::"Mock");

        // [GIVEN] An inbound e-document is received and a draft created (no additional fields configured)
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        WorkDate(DMY2Date(1, 1, 2027));
        Assert.IsTrue(LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', EDocImportParams), 'The draft for the e-document should be created');

        // [GIVEN] The draft has an invalid currency code
        EDocumentPurchaseHeader.GetFromEDocument(EDocument);
        EDocumentPurchaseHeader."Currency Code" := 'BADCURR';
        EDocumentPurchaseHeader.Modify();

        // [WHEN] Finalizing the draft
        EDocImportParams."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParams);

        // [THEN] The e-document should have an error
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(EDocumentErrorHelper.HasErrors(EDocument), 'The e-document should have errors');

        // [THEN] The error message should contain the Currency Code field context
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.FindFirst();
        Assert.ExpectedMessage('Currency Code', ErrorMessage."Message");

        // [THEN] No purchase invoice should have been created
        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;
```

- [ ] **Step 2: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: no additional fields - standard field failure still enriched"
```

---

### Task 10: Final compilation and integration test run

- [ ] **Step 1: Full compile**

Run: `al compile` on the entire E-Document app and test app.
Expected: No compilation errors.

- [ ] **Step 2: Run all E-Document process tests**

Run the full test suite for `EDocProcessTest` codeunit (139883).
Expected: All tests pass.

- [ ] **Step 3: Commit any fixes if needed**

If any test adjustments are required after running, fix and commit.
