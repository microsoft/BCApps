namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy CT Order (ID 30479) extends Shpfy Order (page 30113).
/// Surfaces the Copilot tax match on the Shopify order: an actionable notification and a
/// review action (Copilot icon) that opens the Copilot Tax Match Review page (page 30471),
/// where the resolved Tax Area and per-line Tax Jurisdiction Codes are shown with AI
/// confidence indicators and the match is approved. The action is captioned "Review and
/// Approve Copilot Tax Match" while approval is still pending (shop requires review and the
/// order is not yet approved) and "Review Copilot Tax Match" otherwise. When the shop has
/// Copilot Tax Match Review Required enabled, the connector skips Sales Document creation
/// until the match is approved on the review page.
/// </summary>
pageextension 30479 "Shpfy CT Order" extends "Shpfy Order"
{
    actions
    {
        addafter(CancelOrder)
        {
            action(ShpfyReviewAndApproveCopilotTax)
            {
                ApplicationArea = All;
                Caption = 'Review and Approve Copilot Tax Match';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the Copilot tax match review for this order. Because the shop requires review, the Sales Document is not created until you approve the match on the review page.';
                Visible = ShowReviewEntry and ReviewRequired and not Rec."Copilot Tax Match Reviewed";

                trigger OnAction()
                begin
                    OpenReviewPage();
                end;
            }
            action(ShpfyReviewCopilotTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Review Copilot Tax Match';
                Image = SparkleFilled;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the Copilot tax match review for this order, where you can see the resolved Tax Area and the per-line Tax Jurisdiction Codes that Copilot matched.';
                Visible = ShowReviewEntry and ((not ReviewRequired) or Rec."Copilot Tax Match Reviewed");

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
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        if Shop.Get(Rec."Shop Code") then begin
            CopilotTaxMatchingEnabled := Shop."Copilot Tax Matching Enabled";
            ReviewRequired := Shop."Tax Match Review Required";
        end else begin
            CopilotTaxMatchingEnabled := false;
            ReviewRequired := false;
        end;

        ShowReviewEntry := CopilotTaxMatchingEnabled and Rec."Copilot Tax Match Applied";

        if ShowReviewEntry and (not Rec."Copilot Tax Match Reviewed") and (NotifiedOrderId <> Rec."Shopify Order Id") then begin
            CopilotTaxNotify.SendOrderReviewNotification(Rec);
            NotifiedOrderId := Rec."Shopify Order Id";
        end;
    end;

    local procedure OpenReviewPage()
    var
        OrderHeader: Record "Shpfy Order Header";
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        OrderHeader := Rec;
        CopilotTaxNotify.RunReviewPage(OrderHeader);
        CurrPage.Update(false);
    end;

    var
        CopilotTaxMatchingEnabled: Boolean;
        ReviewRequired: Boolean;
        ShowReviewEntry: Boolean;
        NotifiedOrderId: BigInteger;
}
