namespace Microsoft.Integration.Shopify;

/// <summary>
/// PageExtension Shpfy CT Order Tax Lines (ID 30478) extends Shpfy Order Tax Lines (page 30168).
/// Adds the Tax Jurisdiction Code column to the standalone tax lines list — visible only when
/// the order's shop has Copilot Tax Matching enabled. The column lives in the Copilot app so
/// the standard connector page is uncluttered for tenants that do not use the feature.
/// </summary>
pageextension 30478 "Shpfy CT Order Tax Lines" extends "Shpfy Order Tax Lines"
{
    layout
    {
        addafter("Channel Liable")
        {
            field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the Business Central Tax Jurisdiction matched to this Shopify tax line.';
                Visible = ShpfyCopilotTaxMatchingEnabled;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        OrderLine: Record "Shpfy Order Line";
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
    begin
        ShpfyCopilotTaxMatchingEnabled := false;
        OrderLine.SetRange("Line Id", Rec."Parent Id");
        if not OrderLine.FindFirst() then
            exit;
        if not OrderHeader.Get(OrderLine."Shopify Order Id") then
            exit;
        if not Shop.Get(OrderHeader."Shop Code") then
            exit;
        ShpfyCopilotTaxMatchingEnabled := Shop."Copilot Tax Matching Enabled";
    end;

    var
        ShpfyCopilotTaxMatchingEnabled: Boolean;
}
