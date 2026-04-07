# VAT Rate Mismatch Inline Warning Field — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the page-level VAT rate mismatch notification with a persisted boolean field and inline warning column on the E-Document Purchase Draft Subform, following the PO matching warning pattern.

**Architecture:** Add `[BC] VAT Rate Mismatch` boolean field to `E-Document Purchase Line`, set it during Prepare Draft when resolution fails, re-evaluate it on user edits via `OnValidate`, and display it as a per-line warning column with conditional visibility on the draft subform. Remove all notification infrastructure for VAT mismatch.

**Tech Stack:** AL (Business Central), E-Document Core framework, VAT Posting Setup table (325)

**Spec:** `src/Apps/W1/EDocument/App/src/Processing/Import/docs/2026-04-03-vat-warning-field-design.md`

---

### Task 1: Add `[BC] VAT Rate Mismatch` field and update `[BC] VAT Prod. Posting Group` triggers

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseLine.Table.al:212-217`

- [ ] **Step 1: Add field 111 and update field 110 with OnValidate and OnLookup**

Replace the current field 110 block (lines 212–217):

```al
        field(110; "[BC] VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group resolved from the extracted VAT rate.';
            TableRelation = "VAT Product Posting Group";
        }
```

With:

```al
        field(110; "[BC] VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group resolved from the extracted VAT rate.';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                EDocumentPurchaseHeader: Record "E-Document Purchase Header";
                Vendor: Record Vendor;
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                if "[BC] VAT Prod. Posting Group" = '' then begin
                    "[BC] VAT Rate Mismatch" := true;
                    exit;
                end;
                if not EDocumentPurchaseHeader.Get("E-Document Entry No.") then
                    exit;
                if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
                    exit;
                if VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", "[BC] VAT Prod. Posting Group") then begin
                    if not (VATPostingSetup."VAT Calculation Type" in
                        [VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                         VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT"])
                    then
                        exit;
                    "[BC] VAT Rate Mismatch" := VATPostingSetup."VAT %" <> "VAT Rate";
                end else
                    "[BC] VAT Rate Mismatch" := true;
            end;

            trigger OnLookup()
            var
                EDocumentPurchaseHeader: Record "E-Document Purchase Header";
                Vendor: Record Vendor;
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                if not EDocumentPurchaseHeader.Get("E-Document Entry No.") then
                    exit;
                if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
                    exit;
                VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
                VATPostingSetup.SetFilter("VAT Calculation Type", '%1|%2',
                    VATPostingSetup."VAT Calculation Type"::"Normal VAT",
                    VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
                if Page.RunModal(Page::"VAT Posting Setup", VATPostingSetup) = Action::LookupOK then
                    Validate("[BC] VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            end;
        }
        field(111; "[BC] VAT Rate Mismatch"; Boolean)
        {
            Caption = 'VAT Rate Mismatch';
            ToolTip = 'Specifies whether the VAT Product Posting Group could not be resolved from the extracted VAT rate.';
        }
```

The `using Microsoft.Finance.VAT.Setup;` and `using Microsoft.Purchases.Vendor;` are already present at lines 14 and 20 of the table file — no new usings needed.

- [ ] **Step 2: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseLine.Table.al
git commit -m "feat: add VAT Rate Mismatch field and OnValidate/OnLookup to VAT Prod. Posting Group

Field 111 [BC] VAT Rate Mismatch persists whether VAT resolution failed.
OnValidate re-evaluates mismatch by comparing VAT Posting Setup rate
against extracted rate, filtering to Normal/Reverse Charge VAT only.
OnLookup opens VAT Posting Setup filtered by vendor's bus posting group."
```

---

### Task 2: Update `ResolveVATProductPostingGroups` to set mismatch flag instead of notification

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/PreparePurchaseEDocDraft.Codeunit.al:188-248`

- [ ] **Step 1: Replace `ResolveVATProductPostingGroups` and `FindVATProductPostingGroup`**

Replace the current `ResolveVATProductPostingGroups` procedure (lines 188–232):

```al
    local procedure ResolveVATProductPostingGroups(EDocumentEntryNo: Integer; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        EDocumentNotification: Codeunit "E-Document Notification";
        VATBusPostingGroup: Code[20];
        VATRate: Decimal;
        LineCount: Integer;
        HasUnresolvedVATLines: Boolean;
    begin
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then
            exit;
        if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
            exit;
        VATBusPostingGroup := Vendor."VAT Bus. Posting Group";
        if VATBusPostingGroup = '' then
            exit;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        LineCount := EDocumentPurchaseLine.Count();
        if LineCount = 0 then
            exit;

        if EDocumentPurchaseLine.FindSet() then
            repeat
                VATRate := EDocumentPurchaseLine."VAT Rate";

                // Single-line fallback: compute from header Total VAT
                if (VATRate = 0) and (LineCount = 1) and
                   (EDocumentPurchaseHeader."Total VAT" > 0) and (EDocumentPurchaseHeader."Sub Total" > 0)
                then
                    VATRate := Round((EDocumentPurchaseHeader."Total VAT" / EDocumentPurchaseHeader."Sub Total") * 100, 0.01);

                if VATRate > 0 then begin
                    EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" :=
                        FindVATProductPostingGroup(VATBusPostingGroup, VATRate);
                    if EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" = '' then
                        HasUnresolvedVATLines := true;
                    EDocumentPurchaseLine.Modify();
                end;
            until EDocumentPurchaseLine.Next() = 0;

        if HasUnresolvedVATLines then
            EDocumentNotification.AddVATRateMismatchNotification(EDocumentEntryNo);
    end;
```

With:

```al
    local procedure ResolveVATProductPostingGroups(EDocumentEntryNo: Integer; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        VATBusPostingGroup: Code[20];
        VATRate: Decimal;
        LineCount: Integer;
    begin
        if EDocumentPurchaseHeader."[BC] Vendor No." = '' then
            exit;
        if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
            exit;
        VATBusPostingGroup := Vendor."VAT Bus. Posting Group";
        if VATBusPostingGroup = '' then
            exit;

        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocumentEntryNo);
        LineCount := EDocumentPurchaseLine.Count();
        if LineCount = 0 then
            exit;

        if EDocumentPurchaseLine.FindSet() then
            repeat
                VATRate := EDocumentPurchaseLine."VAT Rate";

                // Single-line fallback: compute from header Total VAT
                if (VATRate = 0) and (LineCount = 1) and
                   (EDocumentPurchaseHeader."Total VAT" > 0) and (EDocumentPurchaseHeader."Sub Total" > 0)
                then
                    VATRate := Round((EDocumentPurchaseHeader."Total VAT" / EDocumentPurchaseHeader."Sub Total") * 100, 0.01);

                if VATRate > 0 then begin
                    EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" :=
                        FindVATProductPostingGroup(VATBusPostingGroup, VATRate);
                    EDocumentPurchaseLine."[BC] VAT Rate Mismatch" :=
                        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" = '';
                    EDocumentPurchaseLine.Modify();
                end;
            until EDocumentPurchaseLine.Next() = 0;
    end;
```

- [ ] **Step 2: Replace `FindVATProductPostingGroup` to filter by VAT Calculation Type**

Replace the current `FindVATProductPostingGroup` procedure (lines 234–248):

```al
    local procedure FindVATProductPostingGroup(VATBusPostingGroup: Code[20]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        RoundingTolerance: Decimal;
    begin
        RoundingTolerance := 0.01;
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT %", '>=%1&<=%2', VATRate - RoundingTolerance, VATRate + RoundingTolerance);
        if VATPostingSetup.Count() = 1 then begin
            VATPostingSetup.FindFirst();
            exit(VATPostingSetup."VAT Prod. Posting Group");
        end;
        // Zero or multiple matches — return blank to signal resolution failure
        exit('');
    end;
```

With:

```al
    local procedure FindVATProductPostingGroup(VATBusPostingGroup: Code[20]; VATRate: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        RoundingTolerance: Decimal;
    begin
        RoundingTolerance := 0.01;
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT Calculation Type", '%1|%2',
            VATPostingSetup."VAT Calculation Type"::"Normal VAT",
            VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.SetFilter("VAT %", '>=%1&<=%2', VATRate - RoundingTolerance, VATRate + RoundingTolerance);
        if VATPostingSetup.Count() = 1 then begin
            VATPostingSetup.FindFirst();
            exit(VATPostingSetup."VAT Prod. Posting Group");
        end;
        exit('');
    end;
```

- [ ] **Step 3: Remove unused `using Microsoft.eServices.EDocument;` if it was only for notification**

Check the `using` statements at the top of `PreparePurchaseEDocDraft.Codeunit.al`. The `using Microsoft.eServices.EDocument;` at line 7 is still needed for the `"E-Document"` record type used elsewhere in the codeunit. No using changes needed.

- [ ] **Step 4: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/PreparePurchaseEDocDraft.Codeunit.al
git commit -m "refactor: set VAT Rate Mismatch flag instead of notification in Prepare Draft

Replace HasUnresolvedVATLines + notification call with direct
[BC] VAT Rate Mismatch field assignment. Filter FindVATProductPostingGroup
to Normal VAT and Reverse Charge VAT calculation types only."
```

---

### Task 3: Add VAT warning column to draft subform page

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocPurchaseDraftSubform.Page.al`

- [ ] **Step 1: Add the warning field in the repeater**

After the `"VAT Prod. Posting Group"` field block (after line 78, the closing `}` of that field), insert:

```al
                field(VATWarning; VATWarningCaption)
                {
                    ApplicationArea = All;
                    Caption = 'VAT warnings';
                    Editable = false;
                    Visible = HasVATWarnings;
                    StyleExpr = VATWarningStyleExpr;
                    ToolTip = 'Specifies whether the VAT Product Posting Group could not be resolved from the extracted VAT rate.';

                    trigger OnDrillDown()
                    begin
                        ShowVATWarningDetails();
                    end;
                }
```

- [ ] **Step 2: Add page-level variables**

In the `var` section (line 339), add the new variables. Replace line 339:

```al
        AdditionalColumns, OrderMatchedCaption, MatchWarningsCaption, MatchWarningsStyleExpr : Text;
```

With:

```al
        AdditionalColumns, OrderMatchedCaption, MatchWarningsCaption, MatchWarningsStyleExpr, VATWarningCaption, VATWarningStyleExpr : Text;
```

In the boolean line (line 341), replace:

```al
        DimVisible1, DimVisible2, HasAdditionalColumns, IsEDocumentMatchedToAnyPOLine, IsLineMatchedToOrderLine, IsLineMatchedToReceiptLine, HasEDocumentOrderMatchWarnings : Boolean;
```

With:

```al
        DimVisible1, DimVisible2, HasAdditionalColumns, HasVATWarnings, IsEDocumentMatchedToAnyPOLine, IsLineMatchedToOrderLine, IsLineMatchedToReceiptLine, HasEDocumentOrderMatchWarnings : Boolean;
```

- [ ] **Step 3: Add `UpdateVATWarnings()` call to `OnOpenPage` and `OnAfterGetCurrRecord`**

Replace `OnOpenPage` (lines 344–348):

```al
    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
        UpdatePOMatching();
    end;
```

With:

```al
    trigger OnOpenPage()
    begin
        SetDimensionsVisibility();
        UpdatePOMatching();
        UpdateVATWarnings();
    end;
```

Replace `OnAfterGetCurrRecord` (lines 355–358):

```al
    trigger OnAfterGetCurrRecord()
    begin
        UpdatePOMatching();
    end;
```

With:

```al
    trigger OnAfterGetCurrRecord()
    begin
        UpdatePOMatching();
        UpdateVATWarnings();
    end;
```

- [ ] **Step 4: Add `UpdateVATWarningForLine()` call to `OnAfterGetRecord`**

At the end of `OnAfterGetRecord` (after `UpdateMatchWarnings();` at line 369), add:

```al
        UpdateVATWarningForLine();
```

- [ ] **Step 5: Add the three new procedures**

Add before the closing `}` of the page (before line 573):

```al
    local procedure UpdateVATWarnings()
    var
        EDocPurchLine: Record "E-Document Purchase Line";
    begin
        EDocPurchLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
        EDocPurchLine.SetRange("[BC] VAT Rate Mismatch", true);
        HasVATWarnings := not EDocPurchLine.IsEmpty();
    end;

    local procedure UpdateVATWarningForLine()
    var
        VATGroupNotResolvedLbl: Label 'VAT group not resolved';
    begin
        if Rec."[BC] VAT Rate Mismatch" then begin
            VATWarningCaption := VATGroupNotResolvedLbl;
            VATWarningStyleExpr := 'Ambiguous';
        end else begin
            VATWarningCaption := '';
            VATWarningStyleExpr := 'None';
        end;
    end;

    local procedure ShowVATWarningDetails()
    var
        VATWarningDetailLbl: Label 'VAT rate %1% was extracted from the invoice but could not be matched to a single VAT Posting Setup for the vendor. Please select the correct VAT Product Posting Group manually.', Comment = '%1 = VAT rate percentage';
    begin
        if not Rec."[BC] VAT Rate Mismatch" then
            exit;
        Message(VATWarningDetailLbl, Rec."VAT Rate");
    end;
```

- [ ] **Step 6: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 7: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocPurchaseDraftSubform.Page.al
git commit -m "feat: add inline VAT warning column to draft subform page

Per-line warning with Ambiguous styling, conditional visibility when
any line has a mismatch, and drill-down showing the extracted VAT rate.
Follows the PO matching warning pattern."
```

---

### Task 4: Remove VAT notification infrastructure

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotificationType.Enum.al`
- Modify: `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al`

- [ ] **Step 1: Remove enum value from `EDocumentNotificationType.Enum.al`**

Remove lines 19–22:

```al
    value(2; "VAT Rate Mismatch")
    {
        Caption = 'VAT Rate Mismatch';
    }
```

- [ ] **Step 2: Remove `AddVATRateMismatchNotification` from `EDocumentNotification.Codeunit.al`**

Remove lines 39–57 (the entire `AddVATRateMismatchNotification` procedure).

- [ ] **Step 3: Revert `SendPurchaseDocumentDraftNotifications` filter**

Replace lines 70–73:

```al
        EDocumentNotification.SetFilter(Type, '%1|%2',
            "E-Document Notification Type"::"Vendor Matched By Name Not Address",
            "E-Document Notification Type"::"VAT Rate Mismatch");
```

With:

```al
        EDocumentNotification.SetRange(Type, "E-Document Notification Type"::"Vendor Matched By Name Not Address");
```

- [ ] **Step 4: Remove `DismissVATRateMismatchNotification` and `DisableVATRateMismatchNotification`**

Remove lines 119–145 (both procedures).

- [ ] **Step 5: Revert `AddActionsToNotification` to only handle vendor notification**

Replace the current `AddActionsToNotification` (lines 162–181):

```al
    local procedure AddActionsToNotification(var Notification: Notification; EDocumentNotification: Record "E-Document Notification")
    var
        DismissMsg: Label 'Dismiss';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
    begin
        Notification.SetData(EDocumentNotification.FieldName("E-Document Entry No."), Format(EDocumentNotification."E-Document Entry No."));
        Notification.SetData(EDocumentNotification.FieldName(ID), EDocumentNotification.ID);
        case EDocumentNotification.Type of
            "E-Document Notification Type"::"Vendor Matched By Name Not Address":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissVendorMatchedByNameNotAddressNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableVendorMatchedByNameNotAddressNotification');
                end;
            "E-Document Notification Type"::"VAT Rate Mismatch":
                begin
                    Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissVATRateMismatchNotification');
                    Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableVATRateMismatchNotification');
                end;
        end;
    end;
```

With:

```al
    local procedure AddActionsToNotification(var Notification: Notification; EDocumentNotification: Record "E-Document Notification")
    var
        DismissMsg: Label 'Dismiss';
        DontShowThisAgainMsg: Label 'Don''t show this again.';
    begin
        if EDocumentNotification.Type <> "E-Document Notification Type"::"Vendor Matched By Name Not Address" then
            exit;
        Notification.SetData(EDocumentNotification.FieldName("E-Document Entry No."), Format(EDocumentNotification."E-Document Entry No."));
        Notification.SetData(EDocumentNotification.FieldName(ID), EDocumentNotification.ID);
        Notification.AddAction(DismissMsg, Codeunit::"E-Document Notification", 'DismissVendorMatchedByNameNotAddressNotification');
        Notification.AddAction(DontShowThisAgainMsg, Codeunit::"E-Document Notification", 'DisableVendorMatchedByNameNotAddressNotification');
    end;
```

- [ ] **Step 6: Remove `GetVATRateMismatchNotificationId`**

Remove lines 188–191:

```al
    local procedure GetVATRateMismatchNotificationId(): Guid
    begin
        exit('d4a7e1c3-5f92-4b8a-ae67-1c3d5f924b8a');
    end;
```

- [ ] **Step 7: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 8: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotificationType.Enum.al
git add src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al
git commit -m "refactor: remove VAT Rate Mismatch notification infrastructure

Notification replaced by persisted [BC] VAT Rate Mismatch field
and inline warning column on draft subform."
```

---

### Task 5: Update existing tests to assert mismatch flag instead of notification

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al:297-415`

- [ ] **Step 1: Update the successful resolution test**

In `PreparingPurchaseDraftResolvesVATProductPostingGroupFromLineVATRate` (line 298), after the existing assertion at line 351:

```al
        Assert.AreEqual(VATProductPostingGroup.Code, EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'The VAT Prod. Posting Group should be resolved from the matching VAT Posting Setup.');
```

Add:

```al
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be false when resolution succeeds.');
```

- [ ] **Step 2: Rewrite the mismatch test**

Replace the entire `PreparingPurchaseDraftCreatesNotificationWhenNoMatchingVATSetup` procedure (lines 362–415) with:

```al
    [Test]
    procedure PreparingPurchaseDraftSetsVATRateMismatchWhenNoMatchingVATSetup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        // [SCENARIO] When a draft line has a VAT Rate but no matching VAT Posting Setup exists, Prepare Draft leaves the field blank and sets the mismatch flag
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor with a known VAT Bus. Posting Group
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] E-Document purchase header and line with VAT Rate = 99 (no matching setup)
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test VAT mismatch';
        EDocumentPurchaseLine."VAT Rate" := 99;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] The VAT Prod. Posting Group is blank and mismatch flag is set
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'The VAT Prod. Posting Group should be blank when no matching VAT Posting Setup exists.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when resolution fails.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
    end;
```

- [ ] **Step 3: Remove unused `using` if needed**

Check whether `"E-Document Notification Type"` enum is still referenced in the test file. If the only usage was in the deleted test, the `using` for it can be removed. The `using Microsoft.Finance.VAT.Setup;` at line 17 is still needed. No changes expected here.

- [ ] **Step 4: Compile and run tests**

Run: `al compile` and `al run_tests` for the E-Document test app.
Expected: Both updated tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: update VAT resolution tests to assert mismatch flag instead of notification

Rename and rewrite the mismatch test to assert [BC] VAT Rate Mismatch
boolean. Add mismatch=false assertion to the successful resolution test."
```

---

### Task 6: Add tests for VAT Calculation Type filtering in Prepare Draft

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

These tests validate that `FindVATProductPostingGroup` only matches Normal VAT and Reverse Charge VAT setups.

- [ ] **Step 1: Add `PreparingDraftIgnoresFullVATSetupWhenResolvingPostingGroup`**

Insert after the `PreparingPurchaseDraftSetsVATRateMismatchWhenNoMatchingVATSetup` procedure:

```al
    [Test]
    procedure PreparingDraftIgnoresFullVATSetupWhenResolvingPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Full VAT setups must not be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Full VAT Posting Setup with VAT % = 10
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Full VAT";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 10
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Full VAT ignored';
        EDocumentPurchaseLine."VAT Rate" := 10;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Full VAT setup is not matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Full VAT setups must not be matched.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when only Full VAT setups exist.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 2: Add `PreparingDraftIgnoresSalesTaxSetupWhenResolvingPostingGroup`**

```al
    [Test]
    procedure PreparingDraftIgnoresSalesTaxSetupWhenResolvingPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Sales Tax setups must not be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Sales Tax Posting Setup with VAT % = 10
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Sales Tax";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 10
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Sales Tax ignored';
        EDocumentPurchaseLine."VAT Rate" := 10;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Sales Tax setup is not matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual('', EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Sales Tax setups must not be matched.');
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be true when only Sales Tax setups exist.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 3: Add `PreparingDraftResolvesReverseChargeVATPostingGroup`**

```al
    [Test]
    procedure PreparingDraftResolvesReverseChargeVATPostingGroup()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocImport: Codeunit "E-Doc. Import";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] Reverse Charge VAT setups should be matched during VAT Posting Group resolution
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Reverse Charge VAT Posting Setup with VAT % = 20
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Reverse Charge VAT";
        VATPostingSetup2."VAT %" := 20;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] E-Document line with VAT Rate = 20
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Vendor VAT Id" := Vendor2."VAT Registration No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine.Description := 'Test Reverse Charge resolved';
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine.Insert();

        // [WHEN] Prepare Draft is run
        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Ready for draft");
        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, TempEDocImportParameters);

        // [THEN] Reverse Charge VAT setup is matched
        EDocumentPurchaseLine.SetRecFilter();
        EDocumentPurchaseLine.FindFirst();
        Assert.AreEqual(VATProductPostingGroup.Code, EDocumentPurchaseLine."[BC] VAT Prod. Posting Group", 'Reverse Charge VAT setups should be matched.');
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'VAT Rate Mismatch should be false when Reverse Charge VAT matches.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 4: Compile and run tests**

Run: `al compile` and `al run_tests` for the E-Document test app.
Expected: All three new tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: add tests for VAT Calculation Type filtering in Prepare Draft

Full VAT and Sales Tax setups are excluded from resolution.
Reverse Charge VAT setups are matched successfully."
```

---

### Task 7: Add tests for OnValidate mismatch re-evaluation

**Files:**
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al`

These tests validate the `OnValidate` trigger on field 110 `[BC] VAT Prod. Posting Group`. They operate directly on the `E-Document Purchase Line` record without running the full Prepare Draft pipeline.

- [ ] **Step 1: Add `ValidatingVATProdPostingGroupClearsMismatchWhenRateMatches`**

```al
    [Test]
    procedure ValidatingVATProdPostingGroupClearsMismatchWhenRateMatches()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate clears mismatch when selected posting group's VAT % matches the line's VAT Rate
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 20
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 20;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 20 and mismatch = true
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the matching setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is cleared
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be false when VAT % matches VAT Rate.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 2: Add `ValidatingVATProdPostingGroupKeepsMismatchWhenRateDiffers`**

```al
    [Test]
    procedure ValidatingVATProdPostingGroupKeepsMismatchWhenRateDiffers()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate keeps mismatch when selected posting group's VAT % differs from VAT Rate
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 10 (different from line's 20)
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 10;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 20 and mismatch = true
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to a non-matching setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch remains true
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should remain true when VAT % does not match VAT Rate.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 3: Add `ValidatingVATProdPostingGroupSetsMismatchWhenCleared`**

```al
    [Test]
    procedure ValidatingVATProdPostingGroupSetsMismatchWhenCleared()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] OnValidate sets mismatch when posting group is cleared
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A line with VAT Rate = 20, a posting group, and no mismatch
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 20;
        EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" := 'STANDARD';
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := false;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User clears the posting group
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", '');
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is set
        Assert.IsTrue(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be true when posting group is cleared.');
    end;
```

- [ ] **Step 4: Add `ValidatingVATProdPostingGroupSkipsMismatchForFullVAT`**

```al
    [Test]
    procedure ValidatingVATProdPostingGroupSkipsMismatchForFullVAT()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate skips mismatch evaluation for Full VAT — flag stays unchanged
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Full VAT setup with VAT % = 0
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Full VAT";
        VATPostingSetup2."VAT %" := 0;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 5 and mismatch = false
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 5;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := false;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the Full VAT setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch flag is unchanged (still false) — Full VAT skips comparison
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should remain unchanged for Full VAT calculation type.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 5: Add `ValidatingVATProdPostingGroupMatchesZeroRate`**

```al
    [Test]
    procedure ValidatingVATProdPostingGroupMatchesZeroRate()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor2: Record Vendor;
        CompanyInformation: Record "Company Information";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        LibraryERM: Codeunit "Library - ERM";
    begin
        // [SCENARIO] OnValidate clears mismatch when both VAT Rate and VAT % are 0
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] A vendor
        CompanyInformation.GetRecordOnce();
        Vendor2."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor2."No." := 'EDOC001';
        Vendor2."VAT Registration No." := 'XXXXXXX001';
        Vendor2."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor2.Insert();

        // [GIVEN] A Normal VAT setup with VAT % = 0 (zero-rated)
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup2."VAT Bus. Posting Group" := Vendor2."VAT Bus. Posting Group";
        VATPostingSetup2."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup2."VAT Calculation Type" := VATPostingSetup2."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup2."VAT %" := 0;
        VATPostingSetup2."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup2.Insert();

        // [GIVEN] A line with VAT Rate = 0
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."[BC] Vendor No." := Vendor2."No.";
        EDocumentPurchaseHeader.Insert();
        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."VAT Rate" := 0;
        EDocumentPurchaseLine."[BC] VAT Rate Mismatch" := true;
        EDocumentPurchaseLine.Insert();

        // [WHEN] User validates the posting group to the zero-rated setup
        EDocumentPurchaseLine.Validate("[BC] VAT Prod. Posting Group", VATProductPostingGroup.Code);
        EDocumentPurchaseLine.Modify();

        // [THEN] Mismatch is cleared — both rates are 0
        Assert.IsFalse(EDocumentPurchaseLine."[BC] VAT Rate Mismatch", 'Mismatch should be false when both VAT Rate and VAT % are 0.');

        // Cleanup
        Vendor2.SetRecFilter();
        Vendor2.Delete();
        VATPostingSetup2.SetRecFilter();
        VATPostingSetup2.Delete();
        VATProductPostingGroup.SetRecFilter();
        VATProductPostingGroup.Delete();
    end;
```

- [ ] **Step 6: Compile and run all tests**

Run: `al compile` and `al run_tests` for the E-Document test app.
Expected: All tests pass — both the updated existing tests and all 8 new tests.

- [ ] **Step 7: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocProcessTest.Codeunit.al
git commit -m "test: add OnValidate mismatch re-evaluation tests

Covers: rate match clears mismatch, rate mismatch persists,
clearing group sets mismatch, Full VAT skips comparison,
zero-rate matching works."
```
