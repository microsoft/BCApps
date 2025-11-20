// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;

page 398 "Sales Credit Memo Statistics"
{
    Caption = 'Sales Credit Memo Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Sales Cr.Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("CustAmount + InvDiscAmount"; CustAmount + InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines in the sales document.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';
                }
                field(CustAmount; CustAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount, less any invoice discount amount, and excluding VAT for the sales document.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the sales document.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount, including VAT, that will be posted to the customer''s account for all the lines in the sales document.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field(AdjustedProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the sales document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
                field(CostLCY; CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items and/or resources in the sales document.';
                }
                field(AdjustedCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted sales credit memo, adjusted for any changes in the original costs of these items.';
                }
                field("TotalAdjCostLCY - CostLCY"; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the posted sales credit memo.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries();
                    end;
                }
            }
            part(Subform; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Customer)
            {
                Caption = 'Customer';
#pragma warning disable AA0100
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
#pragma warning disable AA0100
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies the credit limit of the customer on the sales document. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ClearAll();

        Currency.Initialize(Rec."Currency Code");

        CalculateTotals();

        VATAmount := AmountInclVAT - CustAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if VATpercentage <= 0 then
            VATAmountText := Text000
        else
            VATAmountText := StrSubstNo(Text001, VATpercentage);

        if Rec."Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), Rec."Currency Code", CustAmount, Rec."Currency Factor");

        OnAfterGetRecordOnBeforeCalculateProfitLCY(Rec, AmountLCY, CostLCY, TotalAdjCostLCY, CustAmount, AmountInclVAT);
        ProfitLCY := AmountLCY - CostLCY;

        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;

        OnAfterGetRecordOnAfterCalculateAdjProfitLCY(Rec, AdjProfitLCY, AmountLCY, TotalAdjCostLCY);

        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);

        case true of
            Cust."Credit Limit (LCY)" = 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1:
                CreditLimitLCYExpendedPct := 10000;
            else
                CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
        end;

        SalesCrMemoLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.Subform.Page.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.Subform.Page.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TotalAdjCostLCY: Decimal;
        VATAmount: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        VATpercentage: Decimal;
        VATAmountText: Text[30];

#pragma warning disable AA0074
        Text000: Label 'VAT Amount';
#pragma warning disable AA0470
        Text001: Label '%1% VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        Currency: Record Currency;
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        AmountInclVAT: Decimal;
        AmountLCY: Decimal;
        CostLCY: Decimal;
        CustAmount: Decimal;
        InvDiscAmount: Decimal;

    local procedure CalculateTotals()
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(
            Rec, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
            LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled, VATpercentage);
        if IsHandled then
            exit;

        SalesCrMemoLine.SetRange("Document No.", Rec."No.");
        OnCalculateTotalsOnAfterSalesCrMemoLineSetFilters(SalesCrMemoLine, Rec);
        if SalesCrMemoLine.Find('-') then
            repeat
                CustAmount += SalesCrMemoLine.Amount;
                AmountInclVAT += SalesCrMemoLine."Amount Including VAT";
                if Rec."Prices Including VAT" then
                    InvDiscAmount += SalesCrMemoLine."Inv. Discount Amount" / (1 + SalesCrMemoLine.GetVATPct() / 100)
                else
                    InvDiscAmount += SalesCrMemoLine."Inv. Discount Amount";
                CostLCY += SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Cost (LCY)";
                LineQty += SalesCrMemoLine.Quantity;
                TotalNetWeight += SalesCrMemoLine.Quantity * SalesCrMemoLine."Net Weight";
                TotalGrossWeight += SalesCrMemoLine.Quantity * SalesCrMemoLine."Gross Weight";
                TotalVolume += SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Volume";
                if SalesCrMemoLine."Units per Parcel" > 0 then
                    TotalParcels += Round(SalesCrMemoLine.Quantity / SalesCrMemoLine."Units per Parcel", 1, '>');
                if SalesCrMemoLine."VAT %" <> VATpercentage then
                    if VATpercentage = 0 then
                        VATpercentage := SalesCrMemoLine.GetVATPct()
                    else
                        VATpercentage := -1;
                TotalAdjCostLCY +=
                  CostCalcMgt.CalcSalesCrMemoLineCostLCY(SalesCrMemoLine) + CostCalcMgt.CalcSalesCrMemoLineNonInvtblCostAmt(SalesCrMemoLine);

                OnCalculateTotalsOnAfterAddLineTotals(
                    SalesCrMemoLine, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
                    LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, Rec)
            until SalesCrMemoLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCalculateAdjProfitLCY(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var AdjProfitLCY: Decimal; AmountLCY: Decimal; TotalAdjCostLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean; var VATpercentage: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterSalesCrMemoLineSetFilters(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeCalculateProfitLCY(var SalesInvoiceHeader: Record "Sales Cr.Memo Header"; var AmountLCY: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var CustAmount: Decimal; var AmountInclVAT: Decimal)
    begin
    end;
}
