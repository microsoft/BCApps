// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

/// <summary>
/// Page Shpfy TMA Review (ID 30471).
/// Card view that lets a human review — and adjust — what Tax Matching Agent did for a
/// single Shopify order: the resolved Tax Area (with the platform AI confidence indicator),
/// the ship-to context the Tax Matching Agent reasoned over, and each tax line with the item it taxes and
/// its matched Tax Jurisdiction Code. The Tax Jurisdiction on each line is editable, and each
/// line shows Business Central's Tax Detail rate next to Shopify's rate (a difference is
/// highlighted). The Approve action rebuilds the Tax Area from the (possibly edited) line
/// jurisdictions and releases the order from review-blocked state.
/// </summary>
page 30471 "Shpfy TMA Review"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Shpfy Order Header";
    Caption = 'Tax Match Review';
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    DataCaptionExpression = DataCaption();
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Overview';

                field("Shopify Order No."; Rec."Shopify Order No.")
                {
                    Editable = false;
                    ToolTip = 'Specifies the Shopify order that the Tax Matching Agent matched tax for.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the Tax Area that the Tax Matching Agent resolved for this order from the matched tax jurisdictions. The AI confidence indicator shows how confident the Tax Matching Agent was about the resolved Tax Area.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    Editable = false;
                    ToolTip = 'Specifies whether the order is liable for tax.';
                }
                field("Tax Match Reviewed"; Rec."Tax Match Reviewed")
                {
                    Caption = 'Reviewed';
                    Editable = false;
                    ToolTip = 'Specifies whether the tax match has been reviewed. When the shop requires review, a Sales Document is not created until this is set via the Approve action.';
                }
                field(RateConflictGuidance; RateConflictGuidanceTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    Visible = RateConflict;
                    StyleExpr = RateConflictStyleTxt;
                    ToolTip = 'Explains that one or more matched tax rates differ from Business Central and what approving the order will do.';
                }
            }
            part(TaxLines; "Shpfy TMA Order Tax Lines Part")
            {
                ApplicationArea = All;
                Caption = 'Tax Lines';
                UpdatePropagation = Both;
            }
            group(ShipTo)
            {
                Caption = 'Ship-to (geographic context)';

                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the ship-to country/region the Tax Matching Agent used as geographic context when matching tax jurisdictions.';
                }
                field("Ship-to County"; Rec."Ship-to County")
                {
                    Editable = false;
                    ToolTip = 'Specifies the ship-to state/county the Tax Matching Agent used as geographic context when matching tax jurisdictions.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    Editable = false;
                    ToolTip = 'Specifies the ship-to city the Tax Matching Agent used as geographic context when matching tax jurisdictions.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Approve)
            {
                ApplicationArea = All;
                Caption = 'Approve';
                Image = Approve;
                Visible = Rec."Tax Match Applied" and not Rec."Tax Match Reviewed" and (ReviewRequired or Rec."Tax Rate Conflict" or Rec."Tax Match Incomplete");
                ToolTip = 'Confirms the tax match for this order and approves it. The Tax Area is (re)built from the Tax Jurisdiction Codes on the tax lines below — including any you changed — and the order is released so a Sales Document can be created. Review the per-line Business Central rates against Shopify''s (differences are highlighted) before approving.';

                trigger OnAction()
                begin
                    ApproveReview();
                end;
            }
            action(UndoApproval)
            {
                ApplicationArea = All;
                Caption = 'Undo Approval';
                Image = Undo;
                // Only meaningful while the order is approved, still held-when-unapproved, and no
                // Sales Document has been created yet — undoing cannot un-create an existing document.
                Visible = Rec."Tax Match Applied" and Rec."Tax Match Reviewed" and (Rec."Sales Order No." = '') and (Rec."Sales Invoice No." = '') and (ReviewRequired or Rec."Tax Rate Conflict" or Rec."Tax Match Incomplete");
                ToolTip = 'Reverses the approval of this order''s tax match. The order is held for review again and no Sales Document is created until it is approved once more. Available only before the Sales Document has been created.';

                trigger OnAction()
                begin
                    UndoApprovalReview();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Approve_Promoted; Approve) { }
                actionref(UndoApproval_Promoted; UndoApproval) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ResolveShopSettings();
        RateConflict := Rec."Tax Rate Conflict";
        RateConflictGuidanceTxt := RateConflictGuidanceMsg;
        RateConflictStyleTxt := 'Unfavorable';
        SnapshotTaxLines();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ResolveShopSettings();
        CurrPage.TaxLines.Page.SetTaxLineFilter(BuildTaxLineFilter());
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        ResolveShopSettings();
        // Tax-jurisdiction edits made on this page only take effect on Approve. If the user closes
        // without approving, discard those edits so the persisted tax lines stay consistent with
        // the stored Tax Rate Conflict flag (the single source of truth).
        if HasPendingEdits() then begin
            if not Confirm(DiscardChangesQst, false) then
                exit(false);
            RevertTaxLineEdits();
            exit(true);
        end;
        // No edits: warn if the order is still held for review and not yet approved.
        if (not Rec."Tax Match Reviewed") and (ReviewRequired or Rec."Tax Rate Conflict" or Rec."Tax Match Incomplete") then
            exit(Confirm(CloseWithoutApproveQst, false));
        exit(true);
    end;

    var
        ReviewRequired: Boolean;
        SnapshotJurisdictions: Dictionary of [Text, Code[10]];
        RateConflictGuidanceTxt: Text;
        RateConflictStyleTxt: Text;
        RateConflict: Boolean;
        CloseWithoutApproveQst: Label 'The tax match for this order has not been approved. The Sales Document will not be created until it is approved. Close without approving?';
        DiscardChangesQst: Label 'You have changed one or more Tax Jurisdictions but have not approved the match. If you close now, your changes will be discarded. Close without approving?';
        UndoApprovalQst: Label 'Undo the approval for this order? It will be held for review again and no Sales Document will be created until it is approved once more.';
        RateConflictGuidanceMsg: Label 'One or more tax lines have a rate that differs from Business Central''s Tax Detail (highlighted in red). Approving accepts Business Central''s rates for this order. To use a different rate, correct the Tax Detail, or change the Tax Jurisdiction on the line, before approving.';
        UnmatchedLinesErr: Label 'One or more tax lines do not have a Tax Jurisdiction Code. Assign a Tax Jurisdiction to every tax line before approving, so the order''s tax is fully resolved.';
        NoTaxAreaErr: Label 'A Tax Area could not be resolved for the selected Tax Jurisdictions. Turn on Auto Create Tax Areas on the Shopify Shop Card, or create a Tax Area that covers these jurisdictions, then approve again. The order stays held for review until then.';
        LineKeyTok: Label '%1|%2', Locked = true, Comment = '%1 = Parent Id, %2 = Line No.';
        DataCaptionTok: Label 'Tax Match Review - Order %1', Comment = '%1 = Shopify Order No.';

    local procedure ResolveShopSettings()
    var
        Shop: Record "Shpfy Shop";
        TMAEvents: Codeunit "Shpfy TMA Events";
    begin
        if Shop.Get(Rec."Shop Code") then
            ReviewRequired := TMAEvents.IsHeldForReviewPreference(Rec, Shop)
        else
            ReviewRequired := false;
    end;

    /// <summary>
    /// Snapshots the current Tax Jurisdiction Code of every tax line on the order, so edits made
    /// on this page can be discarded if the user closes without approving. Refreshed after Approve
    /// so the approved state becomes the new baseline.
    /// </summary>
    local procedure SnapshotTaxLines()
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        FilterText: Text;
    begin
        Clear(SnapshotJurisdictions);
        FilterText := BuildTaxLineFilter();
        if FilterText = '' then
            exit;
        OrderTaxLine.SetFilter("Parent Id", FilterText);
        OrderTaxLine.SetLoadFields("Line No.", "Tax Jurisdiction Code");
        if OrderTaxLine.FindSet() then
            repeat
                SnapshotJurisdictions.Set(LineKey(OrderTaxLine), OrderTaxLine."Tax Jurisdiction Code");
            until OrderTaxLine.Next() = 0;
    end;

    local procedure HasPendingEdits(): Boolean
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        LineKeyText: Text;
        FilterText: Text;
    begin
        FilterText := BuildTaxLineFilter();
        if FilterText = '' then
            exit(false);
        OrderTaxLine.SetFilter("Parent Id", FilterText);
        OrderTaxLine.SetLoadFields("Line No.", "Tax Jurisdiction Code");
        if OrderTaxLine.FindSet() then
            repeat
                LineKeyText := LineKey(OrderTaxLine);
                if SnapshotJurisdictions.ContainsKey(LineKeyText) then
                    if SnapshotJurisdictions.Get(LineKeyText) <> OrderTaxLine."Tax Jurisdiction Code" then
                        exit(true);
            until OrderTaxLine.Next() = 0;
        exit(false);
    end;

    local procedure RevertTaxLineEdits()
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        LineKeyText: Text;
        FilterText: Text;
    begin
        FilterText := BuildTaxLineFilter();
        if FilterText = '' then
            exit;
        OrderTaxLine.SetFilter("Parent Id", FilterText);
        OrderTaxLine.SetLoadFields("Line No.", "Tax Jurisdiction Code");
        if OrderTaxLine.FindSet() then
            repeat
                LineKeyText := LineKey(OrderTaxLine);
                if SnapshotJurisdictions.ContainsKey(LineKeyText) then
                    if OrderTaxLine."Tax Jurisdiction Code" <> SnapshotJurisdictions.Get(LineKeyText) then begin
                        OrderTaxLine."Tax Jurisdiction Code" := SnapshotJurisdictions.Get(LineKeyText);
                        OrderTaxLine.Modify();
                    end;
            until OrderTaxLine.Next() = 0;
    end;

    local procedure LineKey(OrderTaxLine: Record "Shpfy Order Tax Line"): Text
    begin
        exit(StrSubstNo(LineKeyTok, OrderTaxLine."Parent Id", OrderTaxLine."Line No."));
    end;

    /// <summary>
    /// Builds a Parent Id filter covering every tax line on the order — both product-line tax
    /// lines (Parent Id = order line "Line Id") and shipping-charge tax lines (Parent Id =
    /// "Shopify Shipping Line Id") — so the tax-lines part, the snapshot/revert, and the
    /// unmatched/edit checks all see the full set.
    /// </summary>
    local procedure BuildTaxLineFilter(): Text
    var
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        FilterBuilder: TextBuilder;
    begin
        OrderLine.SetRange("Shopify Order Id", Rec."Shopify Order Id");
        OrderLine.SetLoadFields("Line Id");
        if OrderLine.FindSet() then
            repeat
                AppendParentId(FilterBuilder, OrderLine."Line Id");
            until OrderLine.Next() = 0;
        ShippingCharge.SetRange("Shopify Order Id", Rec."Shopify Order Id");
        ShippingCharge.SetLoadFields("Shopify Shipping Line Id");
        if ShippingCharge.FindSet() then
            repeat
                AppendParentId(FilterBuilder, ShippingCharge."Shopify Shipping Line Id");
            until ShippingCharge.Next() = 0;
        exit(FilterBuilder.ToText());
    end;

    local procedure AppendParentId(var FilterBuilder: TextBuilder; ParentId: BigInteger)
    begin
        if FilterBuilder.Length() > 0 then
            FilterBuilder.Append('|');
        FilterBuilder.Append(Format(ParentId));
    end;

    local procedure ApproveReview()
    var
        Shop: Record "Shpfy Shop";
        OrderHeader: Record "Shpfy Order Header";
        TMAMatcher: Codeunit "Shpfy TMA Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        CTActivityLog: Codeunit "Shpfy TMA Activity Log";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        ResolvedTaxAreaCode: Code[20];
        TaxAreaWasCreated: Boolean;
        HasRateConflict: Boolean;
    begin
        if HasUnmatchedTaxLine() then
            Error(UnmatchedLinesErr);

        OrderHeader := Rec;

        // Rebuild the Tax Area from the jurisdictions currently on the tax lines (the human may
        // have changed or completed them), re-seeding brackets and re-detecting rate conflicts.
        // If a Tax Area cannot be resolved for the selected jurisdictions (e.g. the reviewer
        // changed them to a set with no existing Tax Area and Auto Create Tax Areas is off), do
        // NOT release the order — otherwise it would be created against the pre-edit Tax Area and
        // post the wrong tax. Surface an actionable error instead and keep the order held.
        if not Shop.Get(OrderHeader."Shop Code") then
            Error(NoTaxAreaErr);
        if not TMAMatcher.ReapplyFromAssignedLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict) then
            Error(NoTaxAreaErr);
        if not TaxAreaBuilder.FindOrCreateTaxArea(OrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then
            Error(NoTaxAreaErr);

        OrderHeader."Tax Rate Conflict" := HasRateConflict;
        // Approval is blocked above unless every tax line has a jurisdiction (HasUnmatchedTaxLine),
        // so once we get here the match is complete.
        OrderHeader."Tax Match Incomplete" := false;
        CTActivityLog.LogTaxAreaEntry(OrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);

        OrderHeader."Tax Match Reviewed" := true;
        OrderHeader.Modify();

        // A human has approved this order, so mark every Tax Jurisdiction it uses as verified.
        // This clears the provisional state of any agent-created jurisdiction so later matches to
        // it are no longer forced to low confidence and held for review.
        MarkJurisdictionsVerified(MatchedJurisdictions);

        Rec := OrderHeader;
        // Refresh the guidance flag from the rechecked state so the red message clears when the
        // conflict was resolved. The approved state is now the baseline — refresh the snapshot so
        // closing the page does not try to revert what was just approved.
        RateConflict := OrderHeader."Tax Rate Conflict";
        SnapshotTaxLines();
        CurrPage.Update(false);
    end;

    local procedure MarkJurisdictionsVerified(MatchedJurisdictions: List of [Code[10]])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        JurisdictionCode: Code[10];
    begin
        // For an agent-created jurisdiction this clears its provisional state so future
        // high-confidence matches to it are no longer forced to low confidence and held.
        // Non-agent and already-verified jurisdictions are skipped (no-op).
        foreach JurisdictionCode in MatchedJurisdictions do
            if TaxJurisdiction.Get(JurisdictionCode) then
                if TaxJurisdiction."Shpfy Created by Agent" and not TaxJurisdiction."Shpfy Verified" then begin
                    TaxJurisdiction."Shpfy Verified" := true;
                    TaxJurisdiction.Modify();
                end;
    end;

    local procedure UndoApprovalReview()
    var
        OrderHeader: Record "Shpfy Order Header";
        TMANotify: Codeunit "Shpfy TMA Notify";
    begin
        if not Confirm(UndoApprovalQst, false) then
            exit;

        OrderHeader := Rec;
        TMANotify.UndoApproval(OrderHeader);

        Rec := OrderHeader;
        CurrPage.Update(false);
    end;

    local procedure HasUnmatchedTaxLine(): Boolean
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        FilterText: Text;
    begin
        FilterText := BuildTaxLineFilter();
        if FilterText = '' then
            exit(false);
        OrderTaxLine.SetFilter("Parent Id", FilterText);
        OrderTaxLine.SetRange("Tax Jurisdiction Code", '');
        exit(not OrderTaxLine.IsEmpty());
    end;

    local procedure DataCaption(): Text
    begin
        exit(StrSubstNo(DataCaptionTok, Rec."Shopify Order No."));
    end;
}
