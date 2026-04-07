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
                exit; // Full VAT and Sales Tax — rate comparison is not applicable
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
```

The `TableRelation` provides basic validation and standard lookup. The `OnLookup` trigger overrides the default lookup to open the VAT Posting Setup page filtered by the vendor's VAT Bus. Posting Group, so the user only sees relevant posting groups. When the user selects a row, it calls `Validate` which runs the `OnValidate` trigger above, re-evaluating the mismatch.

This means:
- If the user clears the posting group, the mismatch flag is set.
- If the user picks a posting group with Full VAT or Sales Tax calculation type, the mismatch evaluation is skipped (rate comparison is not applicable for those types).
- If the user picks a Normal VAT or Reverse Charge VAT posting group, the trigger compares `VAT %` to the line's `"VAT Rate"` with exact equality. This works for zero-rated lines too — a line with `"VAT Rate" = 0` only clears the warning if the setup also has `VAT % = 0`.
- The lookup is filtered to only show Normal VAT and Reverse Charge VAT setups for the vendor's VAT Bus. Posting Group.

### 3. Set the Flag in Prepare Draft

**File:** `PreparePurchaseEDocDraft.Codeunit.al` — `ResolveVATProductPostingGroups`

Replace the `HasUnresolvedVATLines` boolean and notification call with direct field assignment:

- When `FindVATProductPostingGroup` returns blank and `VATRate > 0`: set `"[BC] VAT Rate Mismatch" := true`.
- When `FindVATProductPostingGroup` returns a value: set `"[BC] VAT Rate Mismatch" := false`.
- Remove the `EDocumentNotification` variable and the `AddVATRateMismatchNotification` call.

**`FindVATProductPostingGroup`** must filter to only `"VAT Calculation Type"` in `["Normal VAT", "Reverse Charge VAT"]`. Full VAT and Sales Tax setups do not use `VAT %` for rate-based matching and must be excluded from the query to avoid false positives (zero-match or wrong-match results).

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

### 6. Update and Add Tests

**`EDocProcessTest.Codeunit.al`:**

#### Update existing tests

- **`PreparingPurchaseDraftResolvesVATProductPostingGroupFromLineVATRate`**: Add assertion that `"[BC] VAT Rate Mismatch"` is `false` when resolution succeeds.
- **`PreparingPurchaseDraftCreatesNotificationWhenNoMatchingVATSetup`**: Rename to `PreparingPurchaseDraftSetsVATRateMismatchWhenNoMatchingVATSetup`. Replace the notification record assertion with: assert `"[BC] VAT Rate Mismatch"` is `true`. Remove notification cleanup.

#### New tests

**Prepare Draft — VAT Calculation Type filtering:**

- **`PreparingDraftIgnoresFullVATSetupWhenResolvingPostingGroup`**: Create a VAT Posting Setup with `"VAT Calculation Type" = "Full VAT"` and `VAT % = 10`. Create a line with `"VAT Rate" = 10`. Run Prepare Draft. Assert `"[BC] VAT Prod. Posting Group"` is blank — Full VAT setups must not be matched. Assert `"[BC] VAT Rate Mismatch"` is `true`.

- **`PreparingDraftIgnoresSalesTaxSetupWhenResolvingPostingGroup`**: Same as above but with `"VAT Calculation Type" = "Sales Tax"`. Assert the setup is not matched.

- **`PreparingDraftResolvesReverseChargeVATPostingGroup`**: Create a VAT Posting Setup with `"VAT Calculation Type" = "Reverse Charge VAT"` and `VAT % = 20`. Create a line with `"VAT Rate" = 20`. Run Prepare Draft. Assert `"[BC] VAT Prod. Posting Group"` is resolved and `"[BC] VAT Rate Mismatch"` is `false`.

**OnValidate — mismatch re-evaluation:**

- **`ValidatingVATProdPostingGroupClearsMismatchWhenRateMatches`**: Create a line with `"VAT Rate" = 20` and `"[BC] VAT Rate Mismatch" = true`. Create a Normal VAT setup with `VAT % = 20`. Validate `"[BC] VAT Prod. Posting Group"` to that setup's group. Assert `"[BC] VAT Rate Mismatch"` is `false`.

- **`ValidatingVATProdPostingGroupKeepsMismatchWhenRateDiffers`**: Create a line with `"VAT Rate" = 20` and `"[BC] VAT Rate Mismatch" = true`. Create a Normal VAT setup with `VAT % = 10`. Validate `"[BC] VAT Prod. Posting Group"` to that setup's group. Assert `"[BC] VAT Rate Mismatch"` is still `true`.

- **`ValidatingVATProdPostingGroupSetsMismatchWhenCleared`**: Create a line with `"VAT Rate" = 20`, `"[BC] VAT Prod. Posting Group" = 'STANDARD'`, and `"[BC] VAT Rate Mismatch" = false`. Validate `"[BC] VAT Prod. Posting Group"` to `''`. Assert `"[BC] VAT Rate Mismatch"` is `true`.

- **`ValidatingVATProdPostingGroupSkipsMismatchForFullVAT`**: Create a line with `"VAT Rate" = 5` and `"[BC] VAT Rate Mismatch" = false`. Create a Full VAT setup with `VAT % = 0`. Validate `"[BC] VAT Prod. Posting Group"` to that setup's group. Assert `"[BC] VAT Rate Mismatch"` is unchanged (`false`) — Full VAT skips the comparison.

- **`ValidatingVATProdPostingGroupMatchesZeroRate`**: Create a line with `"VAT Rate" = 0`. Create a Normal VAT setup with `VAT % = 0`. Validate `"[BC] VAT Prod. Posting Group"` to that setup's group. Assert `"[BC] VAT Rate Mismatch"` is `false`.

## Key Files

| File | Change |
|---|---|
| `EDocumentPurchaseLine.Table.al` | Add field 111 `[BC] VAT Rate Mismatch`; add OnValidate and OnLookup to field 110 |
| `PreparePurchaseEDocDraft.Codeunit.al` | Set mismatch flag instead of calling notification; filter by VAT Calculation Type |
| `EDocPurchaseDraftSubform.Page.al` | Add inline warning column with visibility, style, drill-down |
| `EDocumentNotification.Codeunit.al` | Remove all VAT notification procedures |
| `EDocumentNotificationType.Enum.al` | Remove `"VAT Rate Mismatch"` enum value |
| `EDocProcessTest.Codeunit.al` | Update existing test assertions; add 7 new tests for calculation type filtering and OnValidate mismatch logic |
