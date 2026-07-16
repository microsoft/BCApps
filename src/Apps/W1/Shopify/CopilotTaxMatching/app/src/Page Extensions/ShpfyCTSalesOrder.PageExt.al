namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

/// <summary>
/// PageExtension Shpfy CT Sales Order (ID 30476) extends Sales Order (page 42).
/// Surfaces the Copilot Tax Match Applied marker as a read-only badge on the Sales Order
/// and adds a Review Copilot Tax Match action that opens the Copilot Tax Match Review page
/// for the originating Shopify order, where the resolved Tax Area and per-line Tax
/// Jurisdiction Codes are shown with AI confidence indicators.
/// </summary>
pageextension 30476 "Shpfy CT Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("Tax Liable")
        {
            field("Copilot Tax Match Applied"; Rec."Copilot Tax Match Applied")
            {
                ApplicationArea = All;
                Editable = false;
                Importance = Additional;
                ToolTip = 'Specifies that Copilot populated the Tax Area Code on the originating Shopify order. Use the Review Copilot Tax Match action to review the AI-generated decisions.';
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action(ShpfyReviewCopilotTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Review Copilot Tax Match';
                Image = SparkleFilled;
                ToolTip = 'Opens the Copilot tax match review for the originating Shopify order, where you can see the resolved Tax Area and per-line Tax Jurisdiction Codes together with the AI confidence and explanation for each Copilot-matched field.';
                Visible = Rec."Copilot Tax Match Applied";

                trigger OnAction()
                var
                    CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
                    OrderMgt: Codeunit "Shpfy Order Mgt.";
                    VariantRec: Variant;
                begin
                    if not CopilotTaxNotify.RunReviewForSalesHeader(Rec) then begin
                        VariantRec := Rec;
                        OrderMgt.ShowShopifyOrder(VariantRec);
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        if not Rec."Copilot Tax Match Applied" then
            exit;
        if NotifiedSystemId = Rec.SystemId then
            exit;
        NotifiedSystemId := Rec.SystemId;
        CopilotTaxNotify.SendForCurrentSalesHeader(Rec);
    end;

    var
        NotifiedSystemId: Guid;
}
