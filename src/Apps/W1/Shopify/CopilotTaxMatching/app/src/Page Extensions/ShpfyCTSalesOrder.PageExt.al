namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;

/// <summary>
/// PageExtension Shpfy CT Sales Order (ID 30476) extends Sales Order (page 42).
/// Surfaces the Copilot Tax Match Applied marker as a read-only badge on the Sales Order
/// and adds an action that takes the user to the originating Shopify order, where the BC
/// platform shows AI confidence indicators on each Copilot-decided field.
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
                ToolTip = 'Specifies that Copilot populated the Tax Area Code on the originating Shopify order. Use the Show Copilot Tax Decisions action to review the AI-generated decisions.';
            }
        }
    }
    actions
    {
        addlast(navigation)
        {
            action(ShpfyShowCopilotTaxDecisions)
            {
                ApplicationArea = All;
                Caption = 'Show Copilot Tax Decisions';
                Image = Log;
                ToolTip = 'Opens the Shopify order where the Business Central platform displays the AI confidence and explanation for each Copilot-matched tax field.';
                Visible = Rec."Copilot Tax Match Applied";

                trigger OnAction()
                var
                    ShopifyOrderMgt: Codeunit "Shpfy Order Mgt.";
                    VariantRec: Variant;
                begin
                    VariantRec := Rec;
                    ShopifyOrderMgt.ShowShopifyOrder(VariantRec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Notify: Codeunit "Shpfy Copilot Tax Notify";
    begin
        if Rec."Copilot Tax Match Applied" then
            Notify.SendForCurrentSalesHeader(Rec);
    end;
}
