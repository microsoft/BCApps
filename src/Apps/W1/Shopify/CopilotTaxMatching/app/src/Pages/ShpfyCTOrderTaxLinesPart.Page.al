namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy CT Order Tax Lines Part (ID 30479).
/// ListPart variant of the Shopify Order Tax Lines surface, embedded as a subform on the
/// Copilot Tax Match Review page (page 30471). The platform renders AI confidence indicators
/// on Activity Log-anchored fields when they appear on a Card or in a ListPart embedded
/// in a Card — so embedding this part is what makes per-tax-line Copilot indicators
/// visible. The host page calls SetTaxLineFilter to scope the part to a single order's
/// tax lines (tax lines link to order lines via Parent Id, so the host passes the order's
/// order line ids).
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

    trigger OnOpenPage()
    begin
        // Start empty; the host page scopes the part to a single order via SetTaxLineFilter.
        Rec.SetRange("Parent Id", 0);
    end;

    trigger OnAfterGetRecord()
    begin
        SetShowPresentmentCurrencyVisibility();
    end;

    /// <summary>
    /// Scopes the part to the tax lines of a single order. The host passes a filter
    /// expression of the order's order line ids (e.g. '1001|1002'), since tax lines link
    /// to order lines through Parent Id. An empty expression leaves the part empty.
    /// </summary>
    procedure SetTaxLineFilter(ParentIdFilter: Text)
    begin
        if ParentIdFilter = '' then
            Rec.SetRange("Parent Id", 0)
        else
            Rec.SetFilter("Parent Id", ParentIdFilter);
        CurrPage.Update(false);
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
