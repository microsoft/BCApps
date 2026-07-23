namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

/// <summary>
/// PageExtension Shpfy TMA Sales Order (ID 30476) extends Sales Order (page 42).
/// Surfaces the Tax Match Applied marker as a read-only badge on the Sales Order
/// and adds a Review Tax Match action that opens the Tax Match Review page
/// for the originating Shopify order, where the resolved Tax Area and per-line Tax
/// Jurisdiction Codes are shown with AI confidence indicators.
/// </summary>
pageextension 30476 "Shpfy TMA Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("Tax Liable")
        {
            field("Tax Match Applied"; Rec."Tax Match Applied")
            {
                ApplicationArea = All;
                Editable = false;
                Importance = Additional;
                ToolTip = 'Specifies that the Tax Matching Agent populated the Tax Area Code on the originating Shopify order. Use the Review Tax Match action to review the AI-generated decisions.';
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action(ShpfyReviewTaxMatch)
            {
                ApplicationArea = All;
                Caption = 'Review Tax Match';
                Image = SparkleFilled;
                ToolTip = 'Opens the tax match review for the originating Shopify order, where you can see the resolved Tax Area and per-line Tax Jurisdiction Codes together with the AI confidence and explanation for each agent-matched field.';
                Visible = Rec."Tax Match Applied";

                trigger OnAction()
                var
                    TMANotify: Codeunit "Shpfy TMA Notify";
                    OrderMgt: Codeunit "Shpfy Order Mgt.";
                    VariantRec: Variant;
                begin
                    if not TMANotify.RunReviewForSalesHeader(Rec) then begin
                        VariantRec := Rec;
                        OrderMgt.ShowShopifyOrder(VariantRec);
                    end;
                end;
            }
        }
    }

    var
        NotifiedSystemId: Guid;

    trigger OnAfterGetCurrRecord()
    var
        TMANotify: Codeunit "Shpfy TMA Notify";
    begin
        if not Rec."Tax Match Applied" then
            exit;
        if NotifiedSystemId = Rec.SystemId then
            exit;
        NotifiedSystemId := Rec.SystemId;
        TMANotify.SendForCurrentSalesHeader(Rec);
    end;
}
