namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy CT Order (ID 30479) extends Shpfy Order (page 30113).
/// Embeds the Tax Lines list directly inside the Shopify Order Card page (after the
/// Invoice Details group) so that the platform's AI confidence indicators render on
/// the Tax Jurisdiction Code field for each Copilot-matched line. The part follows
/// the currently selected order line via the Provider link, and is visible only when
/// the order's shop has Copilot Tax Matching enabled — keeping the page uncluttered
/// for shops that do not use the feature.
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

    trigger OnAfterGetCurrRecord()
    var
        Shop: Record "Shpfy Shop";
    begin
        if Shop.Get(Rec."Shop Code") then
            CopilotTaxMatchingEnabled := Shop."Copilot Tax Matching Enabled"
        else
            CopilotTaxMatchingEnabled := false;
    end;

    var
        CopilotTaxMatchingEnabled: Boolean;
}
