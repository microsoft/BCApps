namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy CT Order Tax Lines Part (ID 30479).
/// ListPart variant of the Shopify Order Tax Lines surface, designed to be embedded as a
/// subform on the Shopify Order Card page. The platform renders AI confidence indicators
/// on Activity Log-anchored fields when they appear on a Card or in a ListPart embedded
/// in a Card — so embedding this part is what makes per-tax-line Copilot indicators
/// visible without forcing the user to drill into individual records.
/// </summary>
page 30479 "Shpfy CT Order Tax Lines Part"
{
    Caption = 'Tax Lines';
    PageType = ListPart;
    SourceTable = "Shpfy Order Tax Line";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of the tax line as imported from Shopify.';
                }
                field(Rate; Rec.Rate)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rate of the tax line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the tax line.';
                }
                field("Presentment Amount"; Rec."Presentment Amount")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the tax line in presentment currency.';
                    Visible = PresentmentCurrencyVisible;
                }
                field("Rate %"; Rec."Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rate percentage of the tax line.';
                }
                field("Channel Liable"; Rec."Channel Liable")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the channel that submitted the tax line is liable for remitting.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Business Central Tax Jurisdiction matched to this Shopify tax line.';
                }
            }
        }
    }

    var
        PresentmentCurrencyVisible: Boolean;

    trigger OnAfterGetRecord()
    begin
        SetShowPresentmentCurrencyVisibility();
    end;

    local procedure SetShowPresentmentCurrencyVisibility()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
    begin
        OrderLine.SetRange("Line Id", Rec."Parent Id");
        if not OrderLine.FindFirst() then
            exit;
        if not OrderHeader.Get(OrderLine."Shopify Order Id") then
            exit;
        PresentmentCurrencyVisible := OrderHeader.IsPresentmentCurrencyOrder();
    end;
}
