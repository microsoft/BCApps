namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Copilot Tax Review (ID 30471).
/// Card view that summarizes what Copilot tax matching did for a single Shopify order:
/// the resolved Tax Area (with the platform AI confidence indicator), the ship-to context
/// Copilot reasoned over, and each tax line with its matched Tax Jurisdiction Code. Hosts
/// the Review / Review and Approve action that releases the order from review-blocked state
/// (when the shop requires review) or simply records the review (when it does not).
/// </summary>
page 30471 "Shpfy Copilot Tax Review"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Shpfy Order Header";
    Caption = 'Copilot Tax Match Review';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataCaptionExpression = DataCaption();
    LinksAllowed = false;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'Copilot Tax Match';

                field("Shopify Order No."; Rec."Shopify Order No.")
                {
                    ToolTip = 'Specifies the Shopify order that Copilot matched tax for.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ToolTip = 'Specifies the Tax Area that Copilot resolved for this order from the matched tax jurisdictions. The AI confidence indicator shows how confident Copilot was about the resolved Tax Area.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ToolTip = 'Specifies whether the order is liable for tax.';
                }
                field("Copilot Tax Match Reviewed"; Rec."Copilot Tax Match Reviewed")
                {
                    Caption = 'Reviewed';
                    ToolTip = 'Specifies whether the Copilot tax match has been reviewed. When the shop requires review, a Sales Document is not created until this is set via the Review and Approve action.';
                }
            }
            group(ShipTo)
            {
                Caption = 'Ship-to (geographic context)';

                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ToolTip = 'Specifies the ship-to country/region Copilot used as geographic context when matching tax jurisdictions.';
                }
                field("Ship-to County"; Rec."Ship-to County")
                {
                    ToolTip = 'Specifies the ship-to state/county Copilot used as geographic context when matching tax jurisdictions.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ToolTip = 'Specifies the ship-to city Copilot used as geographic context when matching tax jurisdictions.';
                }
            }
            part(TaxLines; "Shpfy CT Order Tax Lines Part")
            {
                ApplicationArea = All;
                Caption = 'Tax Lines';
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ReviewAndApprove)
            {
                ApplicationArea = All;
                Caption = 'Review and Approve';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = ReviewRequired and not Rec."Copilot Tax Match Reviewed";
                ToolTip = 'Confirms that you have reviewed the Copilot tax match for this order and approves it. Because the shop requires review, a Sales Document is not created until you approve. Review the resolved Tax Area and the per-line Tax Jurisdiction Codes, together with the AI confidence indicators, before approving.';

                trigger OnAction()
                begin
                    ApproveReview();
                end;
            }
            action(MarkReviewed)
            {
                ApplicationArea = All;
                Caption = 'Review';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Visible = (not ReviewRequired) and not Rec."Copilot Tax Match Reviewed";
                ToolTip = 'Marks the Copilot tax match for this order as reviewed so the review prompt no longer appears. The shop does not require approval before the Sales Document is created.';

                trigger OnAction()
                begin
                    ApproveReview();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ResolveShopSettings();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ResolveShopSettings();
        CurrPage.TaxLines.Page.SetTaxLineFilter(BuildTaxLineFilter());
    end;

    local procedure ResolveShopSettings()
    var
        Shop: Record "Shpfy Shop";
    begin
        if Shop.Get(Rec."Shop Code") then
            ReviewRequired := Shop."Tax Match Review Required"
        else
            ReviewRequired := false;
    end;

    local procedure BuildTaxLineFilter(): Text
    var
        OrderLine: Record "Shpfy Order Line";
        FilterBuilder: TextBuilder;
    begin
        OrderLine.SetRange("Shopify Order Id", Rec."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                if FilterBuilder.Length() > 0 then
                    FilterBuilder.Append('|');
                FilterBuilder.Append(Format(OrderLine."Line Id"));
            until OrderLine.Next() = 0;
        exit(FilterBuilder.ToText());
    end;

    local procedure ApproveReview()
    var
        OrderHeader: Record "Shpfy Order Header";
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        OrderHeader := Rec;
        OrderHeader."Copilot Tax Match Reviewed" := true;
        OrderHeader.Modify();
        CopilotTaxNotify.SyncReviewedFromOrder(OrderHeader);
        CurrPage.Update(false);

        if ReviewRequired then
            Message(ApprovedMsg)
        else
            Message(ReviewedMsg);
    end;

    local procedure DataCaption(): Text
    begin
        exit(StrSubstNo(DataCaptionTok, Rec."Shopify Order No."));
    end;

    var
        ReviewRequired: Boolean;
        ApprovedMsg: Label 'Copilot tax match approved. The Sales Document will be created the next time this order is processed.';
        ReviewedMsg: Label 'Copilot tax match marked as reviewed.';
        DataCaptionTok: Label 'Copilot Tax Match Review - Order %1', Comment = '%1 = Shopify Order No.';
}
