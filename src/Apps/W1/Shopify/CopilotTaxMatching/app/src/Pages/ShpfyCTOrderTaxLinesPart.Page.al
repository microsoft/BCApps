namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy CT Order Tax Lines Part (ID 30479).
/// ListPart variant of the Shopify Order Tax Lines surface, embedded as a subform on the
/// Copilot Tax Match Review page (page 30471). The platform renders AI confidence indicators
/// on Activity Log-anchored fields when they appear on a Card or in a ListPart embedded
/// in a Card — so embedding this part is what makes per-tax-line Copilot indicators
/// visible. The Tax Jurisdiction Code is editable so a reviewer can correct or complete a
/// match, and each line shows Business Central's Tax Detail rate next to Shopify's rate with
/// the row highlighted green when they agree and red when they differ. The host page calls
/// SetTaxLineFilter to scope the part to a single order's tax lines (tax lines link to order
/// lines via Parent Id, so the host passes the order's order line ids).
/// </summary>
page 30479 "Shpfy CT Order Tax Lines Part"
{
    Caption = 'Tax Lines';
    PageType = ListPart;
    SourceTable = "Shpfy Order Tax Line";
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(AppliesToItemNo; AppliesToItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Item No.';
                    Editable = false;
                    ToolTip = 'Specifies the item number of the order line this tax line is charged on.';
                }
                field(AppliesToItem; AppliesToItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Item';
                    Editable = false;
                    ToolTip = 'Specifies the description of the order line this tax line is charged on, so you can see which item each tax line corresponds to.';
                }
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the title of the tax line as imported from Shopify.';
                }
                field(Rate; Rec.Rate)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the rate of the tax line.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the tax line.';
                }
                field("Presentment Amount"; Rec."Presentment Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the amount of the tax line in presentment currency.';
                    Visible = PresentmentCurrencyVisible;
                }
                field("Rate %"; Rec."Rate %")
                {
                    ApplicationArea = All;
                    Caption = 'Shopify Rate %';
                    Editable = false;
                    StyleExpr = RateStyleExpr;
                    ToolTip = 'Specifies the rate percentage Shopify charged on this tax line.';
                }
                field(BCRate; BCRatePct)
                {
                    ApplicationArea = All;
                    Caption = 'BC Rate %';
                    AutoFormatType = 0;
                    BlankZero = true;
                    Editable = false;
                    StyleExpr = RateStyleExpr;
                    ToolTip = 'Specifies the Business Central Tax Detail rate that applies to this line''s item for the assigned Tax Jurisdiction as of the order date. When it differs from Shopify''s rate the line is highlighted red; approving the order posts at this Business Central rate. It is blank when no Tax Jurisdiction is assigned or no Tax Detail exists yet.';
                }
                field("Channel Liable"; Rec."Channel Liable")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies if the channel that submitted the tax line is liable for remitting.';
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = All;
                    StyleExpr = RateStyleExpr;
                    ToolTip = 'Specifies the Business Central Tax Jurisdiction matched to this Shopify tax line. You can change it to correct or complete the match; the Tax Area is rebuilt from these codes when you approve.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Start empty; the host page scopes the part to a single order via SetTaxLineFilter.
        Rec.SetRange("Parent Id", 0);
    end;

    trigger OnAfterGetRecord()
    begin
        ResolveLineContext();
        ResolveBcRate();
    end;

    var
        PresentmentCurrencyVisible: Boolean;
        AppliesToItemNo: Code[20];
        AppliesToItemDescription: Text[100];
        BCRatePct: Decimal;
        RateStyleExpr: Text;

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

    local procedure ResolveLineContext()
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
    begin
        Clear(AppliesToItemNo);
        Clear(AppliesToItemDescription);
        PresentmentCurrencyVisible := false;

        // A tax line is charged either on a product order line (Parent Id = "Line Id") or on a
        // shipping charge (Parent Id = "Shopify Shipping Line Id"). Show the item for the former
        // and the shipping title for the latter.
        OrderLine.SetRange("Line Id", Rec."Parent Id");
        if OrderLine.FindFirst() then begin
            AppliesToItemNo := OrderLine."Item No.";
            AppliesToItemDescription := OrderLine.Description;
            if OrderHeader.Get(OrderLine."Shopify Order Id") then
                PresentmentCurrencyVisible := OrderHeader.IsPresentmentCurrencyOrder();
            exit;
        end;

        if ShippingCharge.Get(Rec."Parent Id") then begin
            AppliesToItemDescription := CopyStr(ShippingCharge.Title, 1, MaxStrLen(AppliesToItemDescription));
            if OrderHeader.Get(ShippingCharge."Shopify Order Id") then
                PresentmentCurrencyVisible := OrderHeader.IsPresentmentCurrencyOrder();
        end;
    end;

    local procedure ResolveBcRate()
    var
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
    begin
        Clear(BCRatePct);
        if not CopilotTaxMatcher.TryGetEffectiveItemRate(Rec, BCRatePct) then begin
            // No jurisdiction assigned yet or no Tax Detail bracket — nothing to compare.
            RateStyleExpr := 'Standard';
            exit;
        end;

        if BCRatePct = Rec."Rate %" then
            RateStyleExpr := 'Favorable'
        else
            RateStyleExpr := 'Unfavorable';
    end;
}
