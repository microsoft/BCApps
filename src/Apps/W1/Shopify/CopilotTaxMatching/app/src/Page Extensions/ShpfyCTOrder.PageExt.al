namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy CT Order (ID 30479) extends Shpfy Order (page 30113).
/// Embeds the Tax Lines list directly inside the Shopify Order Card page (after the
/// Invoice Details group) so that the platform's AI confidence indicators render on
/// the Tax Jurisdiction Code field for each Copilot-matched line. Adds the Approve
/// Copilot Tax Match action that the user clicks once they have reviewed the AI's
/// decisions; without that approval, the connector skips Sales Document creation
/// when the shop has Copilot Tax Match Review Required enabled.
/// </summary>
pageextension 30479 "Shpfy CT Order" extends "Shpfy Order"
{
    layout
    {
        addafter(InvoiceDetails)
        {
            part(ShpfyCTOrderTaxLines; "Shpfy CT Order Tax Lines Part")
            {
                ApplicationArea = All;
                Caption = 'Tax Lines';
                Provider = ShopifyOrderLines;
                SubPageLink = "Parent Id" = field("Line Id");
                UpdatePropagation = Both;
                Visible = CopilotTaxMatchingEnabled;
            }
        }
    }
    actions
    {
        addafter(CancelOrder)
        {
            action(ShpfyApproveCopilotTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Approve Copilot Tax Match';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Approves the Copilot tax match for this order. Required before a Sales Document is created when the shop has Copilot Tax Match Review Required enabled. Review the matched Tax Area, the per-line Tax Jurisdiction Codes, and the AI confidence indicators on each tax line before approving.';
                Visible = ShowApproveAction;

                trigger OnAction()
                begin
                    Rec."Copilot Tax Match Reviewed" := true;
                    Rec.Modify();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Shop: Record "Shpfy Shop";
    begin
        if Shop.Get(Rec."Shop Code") then begin
            CopilotTaxMatchingEnabled := Shop."Copilot Tax Matching Enabled";
            TaxMatchReviewRequired := Shop."Tax Match Review Required";
        end else begin
            CopilotTaxMatchingEnabled := false;
            TaxMatchReviewRequired := false;
        end;

        ShowApproveAction := TaxMatchReviewRequired and Rec."Copilot Tax Match Applied" and not Rec."Copilot Tax Match Reviewed";
    end;

    var
        CopilotTaxMatchingEnabled: Boolean;
        TaxMatchReviewRequired: Boolean;
        ShowApproveAction: Boolean;
}
