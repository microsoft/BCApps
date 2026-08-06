namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy TMA Order (ID 30479) extends Shpfy Order (page 30113).
/// Surfaces the tax match on the Shopify order: an actionable notification and a
/// review action (review icon) that opens the Tax Match Review page (page 30471),
/// where the resolved Tax Area and per-line Tax Jurisdiction Codes are shown with AI
/// confidence indicators and the match is approved. The action is captioned "Review and
/// Approve Tax Match" while approval is still pending (the order is held — the shop
/// requires review or there is a rate conflict — and it is not yet approved) and "Review
/// Tax Match" otherwise. A held order's Sales Document is not created until the match
/// is approved on the review page.
/// </summary>
pageextension 30479 "Shpfy TMA Order" extends "Shpfy Order"
{
    actions
    {
        addafter(CancelOrder)
        {
            action(ShpfyReviewAndApproveTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Review and Approve Tax Match';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the tax match review for this order. Because this order is held for review, the Sales Document is not created until you approve the match on the review page.';
                Visible = ShowReviewEntry and not Rec."Tax Match Reviewed" and (ReviewRequired or Rec."Tax Rate Conflict");

                trigger OnAction()
                begin
                    OpenReviewPage();
                end;
            }
            action(ShpfyReviewTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Review Tax Match';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the tax match review for this order, where you can see the resolved Tax Area and the per-line Tax Jurisdiction Codes that the Tax Matching Agent matched.';
                Visible = ShowReviewEntry and (Rec."Tax Match Reviewed" or not (ReviewRequired or Rec."Tax Rate Conflict"));

                trigger OnAction()
                begin
                    OpenReviewPage();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Shop: Record "Shpfy Shop";
        TMANotify: Codeunit "Shpfy TMA Notify";
    begin
        if Shop.Get(Rec."Shop Code") then begin
            TaxMatchingAgentEnabled := Shop."Tax Matching Agent Enabled";
            ReviewRequired := Shop."Tax Match Review Required";
        end else begin
            TaxMatchingAgentEnabled := false;
            ReviewRequired := false;
        end;

        ShowReviewEntry := TaxMatchingAgentEnabled and Rec."Tax Match Applied";

        if ShowReviewEntry and (not Rec."Tax Match Reviewed") and (NotifiedOrderId <> Rec."Shopify Order Id") then begin
            TMANotify.SendOrderReviewNotification(Rec);
            NotifiedOrderId := Rec."Shopify Order Id";
        end;
    end;

    var
        TaxMatchingAgentEnabled: Boolean;
        ReviewRequired: Boolean;
        ShowReviewEntry: Boolean;
        NotifiedOrderId: BigInteger;

    local procedure OpenReviewPage()
    var
        OrderHeader: Record "Shpfy Order Header";
        TMANotify: Codeunit "Shpfy TMA Notify";
    begin
        OrderHeader := Rec;
        TMANotify.RunReviewPage(OrderHeader);
        CurrPage.Update(false);
    end;
}
