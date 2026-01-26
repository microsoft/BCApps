// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;

page 10041 "Sales Invoice Stats."
{
    Caption = 'Sales Invoice Statistics';
    Editable = false;
    PageType = ListPlus;
    SourceTable = "Sales Invoice Header";

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
                    ToolTip = 'Specifies the transaction amount.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the entire sales document. If the Calc. Inv. Discount field in the Sales & Receivables Setup window is selected, the discount is automatically calculated.';
                }
                field(CustAmount; CustAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount less any invoice discount amount and exclusive of VAT for the posted document.';
                }
                field(TaxAmount; TaxAmount)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    ToolTip = 'Specifies the tax amount.';
                }
                field(AmountInclTax; AmountInclTax)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. Tax';
                    ToolTip = 'Specifies the total amount, including tax, that has been posted as invoiced.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales ($)';
                    ToolTip = 'Specifies the sales amount.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit ($)';
                    ToolTip = 'Specifies the profit, expressed as an amount, that was associated with the sales order when it was originally posted.';
                }
                field(AdjProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit ($)';
                    ToolTip = 'Specifies the difference between the amounts in the Amount and Cost fields on the sales order.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the profit, expressed as a percentage, that was associated with the sales order when it was originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the adjusted profit of the sales order expressed as a percentage.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item quantity.';
                }
                field(TotalParcels; TotalParcels)
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the net weight of items on the sales order.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the gross weight of items on the document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the volume of the invoiced items.';
                }
                field(CostLCY; CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost ($)';
                    ToolTip = 'Specifies the original cost of the items on the sales document.';
                }
                field(TotalAdjCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost ($)';
                    ToolTip = 'Specifies the adjusted cost of the items on the sales order.';
                }
                field("TotalAdjCostLCY - CostLCY"; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount ($)';
                    ToolTip = 'Specifies the adjusted cost of the sales order based on the total adjusted cost, total sales, and unit cost.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries();
                    end;
                }
                label(BreakdownTitle)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(BreakdownTitle);
                    Editable = false;
                }
                field("BreakdownAmt[1]"; BreakdownAmt[1])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1]);
                    Editable = false;
                    ToolTip = 'Specifies for the Sales Tax Breakdown: Print Description from Tax Jurisdiction and value';
                }
                field("BreakdownAmt[2]"; BreakdownAmt[2])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2]);
                    Editable = false;
                    ToolTip = 'Specifies for the Sales Tax Breakdown: Print Description from Tax Jurisdiction and value';
                }
                field("BreakdownAmt[3]"; BreakdownAmt[3])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3]);
                    Editable = false;
                    ToolTip = 'Specifies for the Sales Tax Breakdown: Print Description from Tax Jurisdiction and value';
                }
                field("BreakdownAmt[4]"; BreakdownAmt[4])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[4]);
                    Editable = false;
                    ToolTip = 'Specifies for the Sales Tax Breakdown: Print Description from Tax Jurisdiction and value';
                }
            }
            part(Subform; "Sales Tax Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    ToolTip = 'Specifies the customer''s balance. ';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit ($)';
                    ToolTip = 'Specifies the customer''s credit limit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit ($)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies how must of the customer''s credit is used, expressed as a percentage of the credit limit.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
    begin
        ClearAll();
        TaxArea.Get(Rec."Tax Area Code");

        if Rec."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(Rec."Currency Code");

        SalesInvLine.SetRange("Document No.", Rec."No.");

        if SalesInvLine.Find('-') then
            repeat
                CustAmount := CustAmount + SalesInvLine.Amount;
                AmountInclTax := AmountInclTax + SalesInvLine."Amount Including VAT";
                if Rec."Prices Including VAT" then
                    InvDiscAmount := InvDiscAmount + SalesInvLine."Inv. Discount Amount" / (1 + SalesInvLine."VAT %" / 100)
                else
                    InvDiscAmount := InvDiscAmount + SalesInvLine."Inv. Discount Amount";
                CostLCY := CostLCY + (SalesInvLine.Quantity * SalesInvLine."Unit Cost (LCY)");
                LineQty := LineQty + SalesInvLine.Quantity;
                TotalNetWeight := TotalNetWeight + (SalesInvLine.Quantity * SalesInvLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (SalesInvLine.Quantity * SalesInvLine."Gross Weight");
                TotalVolume := TotalVolume + (SalesInvLine.Quantity * SalesInvLine."Unit Volume");
                if SalesInvLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(SalesInvLine.Quantity / SalesInvLine."Units per Parcel", 1, '>');
                if SalesInvLine."VAT %" <> TaxPercentage then
                    if TaxPercentage = 0 then
                        TaxPercentage := SalesInvLine."VAT %"
                    else
                        TaxPercentage := -1;
                TotalAdjCostLCY := TotalAdjCostLCY + CostCalcMgt.CalcSalesInvLineCostLCY(SalesInvLine);
                OnAfterGetRecordOnAfterSalesInvLineLoopIteration(SalesInvLine, Rec, CustAmount, AmountInclTax, InvDiscAmount, CostLCY, TotalAdjCostLCY, LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels);
            until SalesInvLine.Next() = 0;
        TaxAmount := AmountInclTax - CustAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if Rec."Currency Code" = '' then
            AmountLCY := CustAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), Rec."Currency Code", CustAmount, Rec."Currency Factor");
        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;
        if AmountLCY <> 0 then
            AdjProfitPct := Round(100 * AdjProfitLCY / AmountLCY, 0.1);

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);
        if Cust."Credit Limit (LCY)" = 0 then
            CreditLimitLCYExpendedPct := 0
        else
            if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0 then
                CreditLimitLCYExpendedPct := 0
            else
                if Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1 then
                    CreditLimitLCYExpendedPct := 10000
                else
                    CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);

        SalesTaxCalculate.StartSalesTaxCalculation();
        TempSalesTaxLine.DeleteAll();
        OnAfterCalculateSalesTax(SalesInvLine, TempSalesTaxLine, TempSalesTaxAmtLine, SalesTaxCalculationOverridden);
        if not SalesTaxCalculationOverridden then
            if TaxArea."Use External Tax Engine" then
                SalesTaxCalculate.CallExternalTaxEngineForDoc(DATABASE::"Sales Invoice Header", 0, Rec."No.")
            else begin
                SalesTaxCalculate.AddSalesInvoiceLines(Rec."No.");
                SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
            end;

        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine);

        if not SalesTaxCalculationOverridden then
            SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);

        if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
            BreakdownTitle := Text006
        else
            BreakdownTitle := Text007;

        TempSalesTaxAmtLine.Reset();
        TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
        if TempSalesTaxAmtLine.Find('-') then
            repeat
                if (TempSalesTaxAmtLine."Print Order" = 0) or
                   (TempSalesTaxAmtLine."Print Order" <> PrevPrintOrder) or
                   (TempSalesTaxAmtLine."Tax %" <> PrevTaxPercent)
                then begin
                    BrkIdx := BrkIdx + 1;
                    if BrkIdx > ArrayLen(BreakdownAmt) then begin
                        BrkIdx := BrkIdx - 1;
                        BreakdownLabel[BrkIdx] := Text008;
                    end else
                        BreakdownLabel[BrkIdx] := CopyStr(StrSubstNo(TempSalesTaxAmtLine."Print Description", TempSalesTaxAmtLine."Tax %"), 1, MaxStrLen(BreakdownLabel[BrkIdx]));
                end;
                BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + TempSalesTaxAmtLine."Tax Amount";
            until TempSalesTaxAmtLine.Next() = 0;
        CurrPage.Subform.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        CurrPage.Subform.PAGE.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        Cust: Record Customer;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        Currency: Record Currency;
        TaxArea: Record "Tax Area";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        TotalAdjCostLCY: Decimal;
        CustAmount: Decimal;
        AmountInclTax: Decimal;
        InvDiscAmount: Decimal;
        TaxAmount: Decimal;
        CostLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        AmountLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        TaxPercentage: Decimal;
        BreakdownTitle: Text[35];
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Sales Tax Breakdown:';
        Text008: Label 'Other Taxes';
        SalesTaxCalculationOverridden: Boolean;

    protected var
        SalesInvLine: Record "Sales Invoice Line";

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterSalesInvLineLoopIteration(var SalesInvoiceLine: Record "Sales Invoice Line"; SalesInvoiceHeader: Record "Sales Invoice Header"; var CustAmount: Decimal; var AmountInclTax: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;
}

