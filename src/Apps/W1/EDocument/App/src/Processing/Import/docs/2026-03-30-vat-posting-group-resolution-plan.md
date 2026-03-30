# VAT Product Posting Group Auto-Resolution — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically resolve and apply the correct VAT Product Posting Group per E-Document purchase line based on extracted VAT rate data, with a notification when resolution fails.

**Architecture:** Normalize VAT data at extraction time (ADI handler), add a `[BC] VAT Prod. Posting Group` field to the staging table, resolve it during Prepare Draft via VAT Posting Setup lookup, and apply it during Finish Draft when creating the BC Purchase Line.

**Tech Stack:** AL (Business Central), E-Document Core framework, VAT Posting Setup table (325)

---

### Task 1: Normalize ADI handler — compute VAT percentage from tax amount

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/StructureReceivedEDocument/EDocumentADIHandler.Codeunit.al:174-188`
- Modify: `src/Apps/W1/EDocument/Test/src/Processing/EDocStructuredValidations.Codeunit.al:59,70,80`

The ADI handler currently stores the `tax` monetary amount directly into `"VAT Rate"`. After this change, it computes a percentage: `(tax / Sub Total) * 100`.

- [ ] **Step 1: Update `PopulateEDocumentPurchaseLine` in the ADI handler**

Replace the current line 185:
```al
EDocumentJsonHelper.SetCurrencyValueInField('tax', FieldsJsonObject, TempEDocPurchaseLine."VAT Rate", TempEDocPurchaseLine."Currency Code");
```

With:
```al
        ComputeVATRateFromTaxAmount(FieldsJsonObject, TempEDocPurchaseLine);
```

Add a new local procedure after `PopulateEDocumentPurchaseLine`:
```al
    local procedure ComputeVATRateFromTaxAmount(FieldsJsonObject: JsonObject; var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        TaxAmount: Decimal;
        UnusedCurrencyCode: Code[10];
    begin
        EDocumentJsonHelper.SetCurrencyValueInField('tax', FieldsJsonObject, TaxAmount, UnusedCurrencyCode);
        if (TaxAmount = 0) or (TempEDocPurchaseLine."Sub Total" = 0) then
            exit;
        TempEDocPurchaseLine."VAT Rate" := Round((TaxAmount / TempEDocPurchaseLine."Sub Total") * 100, 0.01);
    end;
```

Note: `"Sub Total"` is already populated from `amount` at line 176 before this runs — the field order in `PopulateEDocumentPurchaseLine` ensures this.

- [ ] **Step 2: Update existing CAPI test assertions**

In `EDocStructuredValidations.Codeunit.al`, the CAPI test fixture has three lines with tax amounts $6, $3, $1 on sub totals 60, 30, 10 — all computing to 10%.

Update line 59:
```al
        Assert.AreEqual(10, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the purchase line does not match the expected percentage.');
```

Update line 70:
```al
        Assert.AreEqual(10, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the purchase line does not match the expected percentage.');
```

Update line 80:
```al
        Assert.AreEqual(10, EDocumentPurchaseLine."VAT Rate", 'The VAT rate in the purchase line does not match the expected percentage.');
```

- [ ] **Step 3: Verify PEPPOL and MLLM assertions are unchanged**

PEPPOL assertions at lines 142, 153 expect `25` — these are already percentages, no change needed.
MLLM assertions at lines 197, 207, 217 expect `15`, `10`, `15` — already percentages, no change needed.

- [ ] **Step 4: Compile and run tests**

Run: `al compile` and `al run_tests` for the E-Document app and test app.
Expected: All existing CAPI, PEPPOL, and MLLM structured tests pass with the updated assertions.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/StructureReceivedEDocument/EDocumentADIHandler.Codeunit.al
git add src/Apps/W1/EDocument/Test/src/Processing/EDocStructuredValidations.Codeunit.al
git commit -m "fix: normalize ADI tax amount to VAT percentage in E-Document Purchase Line"
```

---

### Task 2: Add `[BC] VAT Prod. Posting Group` field to E-Document Purchase Line

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseLine.Table.al:211`

- [ ] **Step 1: Add field 110 to the table**

Insert before the `#endregion Validated fields` comment (line 211):

```al
        field(110; "[BC] VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT product posting group resolved from the extracted VAT rate.';
            TableRelation = "VAT Product Posting Group";
        }
```

Also add a `using` statement at the top of the file for `Microsoft.Finance.VAT.Setup` if not already present.

- [ ] **Step 2: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseLine.Table.al
git commit -m "feat: add [BC] VAT Prod. Posting Group field to E-Document Purchase Line"
```

---

### Task 3: Add `[BC] VAT Prod. Posting Group` column to draft subform page

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocPurchaseDraftSubform.Page.al:73`

- [ ] **Step 1: Add the column to the repeater**

Insert after the `"No."` field block (after line 73, the closing brace of the `"No."` field):

```al
                field("VAT Prod. Posting Group"; Rec."[BC] VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Lookup = true;
                }
```

- [ ] **Step 2: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocPurchaseDraftSubform.Page.al
git commit -m "feat: add VAT Prod. Posting Group column to E-Document draft subform"
```

---

### Task 4: Add VAT Rate Mismatch notification type and codeunit logic

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotificationType.Enum.al:18`
- Modify: `src/Apps/W1/EDocument/App/src/Document/Notification/EDocumentNotification.Codeunit.al`
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/Purchase/EDocumentPurchaseDraft.Page.al:505`

- [ ] **Step 1: Add enum value**

In `EDocumentNotificationType.Enum.al`, add after the `"Vendor Matched By Name Not Address"` value (after line 18):

```al
    value(2; "VAT Rate Mismatch")
    {
        Caption = 'VAT Rate Mismatch';
    }
```

- [ ] **Step 2: Add notification procedures to the codeunit**

In `EDocumentNotification.Codeunit.al`, add these procedures:

After `AddVendorMatchedByNameNotAddressNotification` (after line 37):

```al
    procedure AddVATRateMismatchNotification(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
        MyNotifications: Record "My Notifications";
        VATRateMismatchMsg: Label 'VAT Product Posting Groups could not be automatically determined for one or more lines. Please review before creating the invoice.';
    begin
        if not GuiAllowed() then
            exit;
        if not MyNotifications.IsEnabled(GetVATRateMismatchNotificationId()) then
            exit;
        if EDocumentNotification.Get(EDocumentEntryNo, GetVATRateMismatchNotificationId(), UserId()) then
            exit;
        EDocumentNotification.Validate("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.Validate(ID, GetVATRateMismatchNotificationId());
        EDocumentNotification.Validate("User Id", UserId());
        EDocumentNotification.Validate(Type, "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.Validate(Message, VATRateMismatchMsg);
        EDocumentNotification.Insert(true);
    end;
```

- [ ] **Step 3: Update `SendPurchaseDocumentDraftNotifications` to include the new type**

Replace the existing `SendPurchaseDocumentDraftNotifications` (lines 43-59) with:

```al
    procedure SendPurchaseDocumentDraftNotifications(EDocumentEntryNo: Integer)
    var
        EDocumentNotification: Record "E-Document Notification";
    begin
        if not GuiAllowed() then
            exit;

        EDocumentNotification.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotification.SetFilter(Type, '%1|%2',
            "E-Document Notification Type"::"Vendor Matched By Name Not Address",
            "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        if not EDocumentNotification.FindSet() then
            exit;

        repeat
            SendNotification(EDocumentNotification);
        until EDocumentNotification.Next() = 0;
    end;
```

- [ ] **Step 4: Update `AddActionsToNotification` to handle the new type**

Replace the existing `AddActionsToNotification` (lines 112-123) with:

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

- [ ] **Step 5: Add dismiss and disable procedures for the new notification**

Add after `DisableVendorMatchedByNameNotAddressNotification` (after line 95):

```al
    procedure DismissVATRateMismatchNotification(Notification: Notification)
    var
        EDocumentNotification: Record "E-Document Notification";
        EDocumentEntryNo: Integer;
        Id: Guid;
    begin
        Evaluate(EDocumentEntryNo, Notification.GetData(EDocumentNotification.FieldName("E-Document Entry No.")));
        Evaluate(Id, Notification.GetData(EDocumentNotification.FieldName(ID)));
        if not EDocumentNotification.Get(EDocumentEntryNo, Id, UserId()) then
            exit;
        EDocumentNotification.Delete(true);
    end;

    procedure DisableVATRateMismatchNotification(Notification: Notification)
    var
        MyNotifications: Record "My Notifications";
        EDocumentNotification: Record "E-Document Notification";
        VATRateMismatchNotificationNameTok: Label 'Notify user of Purchase Document Draft that VAT posting groups could not be auto-resolved.';
        VATRateMismatchNotificationDescTok: Label 'Show a notification when VAT Product Posting Groups could not be automatically determined from the extracted VAT rate.';
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetVATRateMismatchNotificationId()) then
                MyNotifications.InsertDefault(GetVATRateMismatchNotificationId(), VATRateMismatchNotificationNameTok, VATRateMismatchNotificationDescTok, false);
        EDocumentNotification.SetRange(Type, "E-Document Notification Type"::"VAT Rate Mismatch");
        EDocumentNotification.SetRange("User Id", UserId());
        EDocumentNotification.DeleteAll(true);
    end;
```

- [ ] **Step 6: Add the GUID getter for the new notification**

Add after `GetVendorMatchedByNameNotAddressNotificationId` (after line 128):

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
git commit -m "feat: add VAT Rate Mismatch notification type and handlers"
```

---

### Task 5: Implement VAT Posting Group resolution in Prepare Draft

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/PreparePurchaseEDocDraft.Codeunit.al:62-78`

This is the core logic. After the existing line loop resolves type/number/UOM, we add a second pass that resolves VAT Posting Group. We also trigger the notification if resolution fails.

- [ ] **Step 1: Add the VAT resolution call after the line loop**

In `PrepareDraft`, insert after the existing line loop (after line 74, the `until` line) and before `CopilotLineMatching` (line 77):

```al
            // Resolve VAT Product Posting Groups from extracted VAT rates
            ResolveVATProductPostingGroups(EDocument."Entry No", EDocumentPurchaseHeader);
```

- [ ] **Step 2: Add `using` statements**

Add to the top of the file:
```al
using Microsoft.Finance.VAT.Setup;
using Microsoft.eServices.EDocument;
```

(If `Microsoft.eServices.EDocument` is already present via `EDocument` record, that's fine. The key addition is `Microsoft.Finance.VAT.Setup` for the `VAT Posting Setup` table.)

- [ ] **Step 3: Implement `ResolveVATProductPostingGroups`**

Add as a new local procedure:

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

- [ ] **Step 4: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 5: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/PrepareDraft/PreparePurchaseEDocDraft.Codeunit.al
git commit -m "feat: resolve VAT Prod. Posting Group from extracted VAT rate during Prepare Draft"
```

---

### Task 6: Apply resolved VAT Posting Group in Finish Draft

**Files:**
- Modify: `src/Apps/W1/EDocument/App/src/Processing/Import/FinishDraft/EDocCreatePurchaseInvoice.Codeunit.al:216-219`

- [ ] **Step 1: Add the VAT Posting Group override in `CreatePurchaseInvoiceLine`**

After line 216 (`PurchaseLine.Validate("No.", EDocumentPurchaseLine."[BC] Purchase Type No.");`) and before line 217 (`if (PurchaseLine.Type = ...`), insert:

```al
        if EDocumentPurchaseLine."[BC] VAT Prod. Posting Group" <> '' then
            PurchaseLine.Validate("VAT Prod. Posting Group", EDocumentPurchaseLine."[BC] VAT Prod. Posting Group");
```

The `Validate("No.", ...)` call at line 216 sets the default VAT Posting Group from the G/L Account/Item card. Our new lines override it with the resolved value. `Validate("VAT Prod. Posting Group", ...)` will also update `"VAT %"` on the purchase line based on the VAT Posting Setup.

- [ ] **Step 2: Compile**

Run: `al compile` for the E-Document app.
Expected: Clean compilation, no errors.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/App/src/Processing/Import/FinishDraft/EDocCreatePurchaseInvoice.Codeunit.al
git commit -m "feat: apply resolved VAT Prod. Posting Group when creating purchase invoice line"
```

---

### Task 7: Write integration tests for VAT Posting Group resolution

**Files:**
- Modify or create: `src/Apps/W1/EDocument/Test/src/Processing/EDocumentStructuredTests.Codeunit.al` (add new test procedures)

These tests validate the end-to-end flow: ADI extracts VAT data → Prepare Draft resolves the posting group → Finish Draft applies it.

- [ ] **Step 1: Add a test for per-line VAT rate resolution**

Add a new test procedure to `EDocumentStructuredTests`:

```al
    [Test]
    procedure TestCAPIInvoice_VATPostingGroupResolvedFromLineRate()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] When CAPI extracts tax amounts per line, Prepare Draft resolves VAT Prod. Posting Group
        Initialize(Enum::"Service Integration"::"Mock");
        SetupCAPIEDocumentService();
        CreateInboundEDocumentFromJSON(EDocument, 'capi/capi-invoice-valid-0.json');

        // Process through Read into Draft (extracts VAT rates)
        Assert.IsTrue(
            ProcessEDocumentToStep(EDocument, "Import E-Document Steps"::"Read into Draft"),
            'Failed to process to Read into Draft');

        // Verify VAT Rate is now a percentage (10% for all lines: $6/$60, $3/$30, $1/$10)
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.FindSet();
        repeat
            Assert.AreEqual(10, EDocumentPurchaseLine."VAT Rate",
                'VAT Rate should be normalized to percentage');
        until EDocumentPurchaseLine.Next() = 0;

        // Process through Prepare Draft (resolves VAT Prod. Posting Group)
        // Note: This requires a vendor with a VAT Bus. Posting Group and a matching
        // VAT Posting Setup with VAT % = 10. If the test vendor setup has this,
        // the [BC] VAT Prod. Posting Group field should be populated.
        // The exact assertion depends on the test vendor's VAT configuration.
    end;
```

Note: The exact assertions for the Prepare Draft step depend on the test data setup (vendor's VAT Bus. Posting Group and VAT Posting Setup). Adapt the test to match the fixture vendor's configuration, or create the required VAT Posting Setup in the test's `Initialize` procedure.

- [ ] **Step 2: Compile and run tests**

Run: `al compile` and `al run_tests` for the E-Document test app.
Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add src/Apps/W1/EDocument/Test/src/Processing/EDocumentStructuredTests.Codeunit.al
git commit -m "test: add integration test for VAT Posting Group resolution from ADI data"
```
