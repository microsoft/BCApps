# VAT Rate Mismatch — Inline Warning Field on Draft Subform

**Date:** 2026-04-03
**Status:** Draft
**Author:** Artur Ventsel

## Problem

The current branch introduces a page-level notification banner for VAT rate mismatch (when VAT Prod. Posting Group resolution fails during Prepare Draft). This notification pattern has drawbacks:

1. It does not indicate **which** lines have the issue — the user must inspect each line manually.
2. It cannot react to user edits — dismissing the notification is a manual action unrelated to actually fixing the mismatch.
3. It adds significant plumbing (enum value, 4 procedures, GUID, My Notifications integration) for what is essentially a per-line data quality indicator.

The PO matching feature already solves a similar problem with inline warning fields on the draft subform: a per-line column with `StyleExpr` styling, conditional visibility when any line has warnings, and drill-down for details.

## Design

Replace the notification approach with a persisted boolean field on the E-Document Purchase Line and an inline warning column on the draft subform page.

### 1. New Field on E-Document Purchase Line

**File:** `EDocumentPurchaseLine.Table.al`

Add field 111 in the `[BC]` validated fields range (101–200), after field 110:

```al
field(111; "[BC] VAT Rate Mismatch"; Boolean)
{
    Caption = 'VAT Rate Mismatch';
    ToolTip = 'Specifies whether the VAT Product Posting Group could not be resolved from the extracted VAT rate.';
}
```

### 2. OnValidate Trigger for VAT Prod. Posting Group

**File:** `EDocumentPurchaseLine.Table.al` — field 110 (`[BC] VAT Prod. Posting Group`)

Add an OnValidate trigger that re-evaluates the mismatch by comparing the chosen posting group's VAT % against the extracted VAT rate on the line:

```al
field(110; "[BC] VAT Prod. Posting Group"; Code[20])
{
    ...
    trigger OnValidate()
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        RoundingTolerance: Decimal;
    begin
        if "VAT Rate" = 0 then begin
            "[BC] VAT Rate Mismatch" := false;
            exit;
        end;
        if "[BC] VAT Prod. Posting Group" = '' then begin
            "[BC] VAT Rate Mismatch" := true;
            exit;
        end;
        if not EDocumentPurchaseHeader.Get("E-Document Entry No.") then
            exit;
        if not Vendor.Get(EDocumentPurchaseHeader."[BC] Vendor No.") then
            exit;
        RoundingTolerance := 0.01;
        if VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", "[BC] VAT Prod. Posting Group") then
            "[BC] VAT Rate Mismatch" :=
                (VATPostingSetup."VAT %" < "VAT Rate" - RoundingTolerance) or
                (VATPostingSetup."VAT %" > "VAT Rate" + RoundingTolerance)
        else
            "[BC] VAT Rate Mismatch" := true;
    end;
}
```

This means:
- If the line has no extracted VAT rate, there is no mismatch (nothing to compare against).
- If the user clears the posting group while a VAT rate exists, the mismatch flag is set.
- If the user picks a posting group, the trigger looks up the VAT Posting Setup for the vendor's VAT Bus. Posting Group + the chosen VAT Prod. Posting Group, compares `VAT %` to the line's `"VAT Rate"` with rounding tolerance, and sets the mismatch flag accordingly. Only a matching rate clears the warning.

### 3. Set the Flag in Prepare Draft

**File:** `PreparePurchaseEDocDraft.Codeunit.al` — `ResolveVATProductPostingGroups`

Replace the `HasUnresolvedVATLines` boolean and notification call with direct field assignment:

- When `FindVATProductPostingGroup` returns blank and `VATRate > 0`: set `"[BC] VAT Rate Mismatch" := true`.
- When `FindVATProductPostingGroup` returns a value: set `"[BC] VAT Rate Mismatch" := false`.
- Remove the `EDocumentNotification` variable and the `AddVATRateMismatchNotification` call.

### 4. Warning Column on Draft Subform Page

**File:** `EDocPurchaseDraftSubform.Page.al`

Add a new field in the repeater, positioned after the `"VAT Prod. Posting Group"` field:

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

**Page-level variables:**

```al
VATWarningCaption, VATWarningStyleExpr : Text;
HasVATWarnings : Boolean;
```

**Page-level visibility** (`HasVATWarnings`): Computed in `OnOpenPage` and `OnAfterGetCurrRecord` by a new `UpdateVATWarnings()` procedure:

```al
local procedure UpdateVATWarnings()
var
    EDocPurchLine: Record "E-Document Purchase Line";
begin
    EDocPurchLine.SetRange("E-Document Entry No.", EDocumentPurchaseHeader."E-Document Entry No.");
    EDocPurchLine.SetRange("[BC] VAT Rate Mismatch", true);
    HasVATWarnings := not EDocPurchLine.IsEmpty();
end;
```

**Per-line caption and style**: Computed in `OnAfterGetRecord` by a new `UpdateVATWarningForLine()` procedure:

```al
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
```

**Drill-down** (`ShowVATWarningDetails`): Shows a `Message()` with the extracted VAT rate:

```al
local procedure ShowVATWarningDetails()
var
    VATWarningDetailLbl: Label 'VAT rate %1% was extracted from the invoice but could not be matched to a single VAT Posting Setup for the vendor. Please select the correct VAT Product Posting Group manually.', Comment = '%1 = VAT rate percentage';
begin
    if not Rec."[BC] VAT Rate Mismatch" then
        exit;
    Message(VATWarningDetailLbl, Rec."VAT Rate");
end;
```

### 5. Remove Notification Infrastructure

Remove all VAT-related notification code added in earlier commits:

**`EDocumentNotificationType.Enum.al`:** Remove `value(2; "VAT Rate Mismatch")`.

**`EDocumentNotification.Codeunit.al`:** Remove:
- `AddVATRateMismatchNotification` procedure
- `DismissVATRateMismatchNotification` procedure
- `DisableVATRateMismatchNotification` procedure
- `GetVATRateMismatchNotificationId` procedure
- The `"VAT Rate Mismatch"` case branch in `AddActionsToNotification`
- The `"VAT Rate Mismatch"` filter in `SendPurchaseDocumentDraftNotifications`

Revert these to their pre-branch state (only handling `"Vendor Matched By Name Not Address"`).

### 6. Update Tests

**`EDocProcessTest.Codeunit.al`:**

- **`PreparingPurchaseDraftResolvesVATProductPostingGroupFromLineVATRate`**: Add assertion that `"[BC] VAT Rate Mismatch"` is `false` when resolution succeeds.
- **`PreparingPurchaseDraftCreatesNotificationWhenNoMatchingVATSetup`**: Rename to `PreparingPurchaseDraftSetsVATRateMismatchWhenNoMatchingVATSetup`. Replace the notification record assertion with: assert `"[BC] VAT Rate Mismatch"` is `true`. Remove notification cleanup.

## Key Files

| File | Change |
|---|---|
| `EDocumentPurchaseLine.Table.al` | Add field 111 `[BC] VAT Rate Mismatch`; add OnValidate to field 110 |
| `PreparePurchaseEDocDraft.Codeunit.al` | Set mismatch flag instead of calling notification |
| `EDocPurchaseDraftSubform.Page.al` | Add inline warning column with visibility, style, drill-down |
| `EDocumentNotification.Codeunit.al` | Remove all VAT notification procedures |
| `EDocumentNotificationType.Enum.al` | Remove `"VAT Rate Mismatch"` enum value |
| `EDocProcessTest.Codeunit.al` | Update test assertions from notification to boolean field |
