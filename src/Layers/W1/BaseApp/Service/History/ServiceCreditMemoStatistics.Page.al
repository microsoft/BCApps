// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;

page 6034 "Service Credit Memo Statistics"
{
    Caption = 'Service Credit Memo Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Service Cr.Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount; CustAmount + InvDiscAmount + PmtDiscAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the net amount of all the lines in the posted service credit memo. ';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the entire service credit memo. If there is a check mark in the Calc. Inv. Discount field in the Sales & Receivables Setup window, the discount was calculated automatically.';
                }
                field(PmtDiscAmount; PmtDiscAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Pmt. Discount Amount';
                    Editable = true;
                    ToolTip = 'Specifies the payment discount amount that you have granted to customers. ';
                }
                field(CustAmount; CustAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total net amount less any invoice discount amount for the posted service invoice. The amount does not include VAT.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount on the posted service invoice.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount on the service credit memo, including VAT, which has been posted to the customer''s account.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    ToolTip = 'Specifies your total service sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open service sales invoices and credit memos.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    ToolTip = 'Specifies the amount of profit for the posted service credit memo (in LCY), prior to any item cost adjustment. The program calculates the amount as the difference between the values in the Amount and the Original Cost (LCY) fields.';
                }
                field(AdjProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted service credit memo, adjusted for any changes in the original costs of these items.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the original profit amount expressed in percentage.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the amount of profit for the service credit memo, in LCY, adjusted for any changes in the original item costs. ';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the posted service credit memo.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the posted service credit memo.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the posted service credit memo.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the posted service credit memo.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the posted service credit memo.';
                }
                field(CostLCY; CostLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    ToolTip = 'Specifies the total cost (in LCY) of the G/L account entries, costs, items and/or resources on the posted service credit memo. The cost was calculated as a product of unit cost multiplied by quantity of the relevant items, resources and/or costs on the posted credit memo.';
                }
                field(TotalAdjCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted service credit memo, adjusted for any changes in the original costs of these items.';
                }
                field(CostAdjmtAmountLCY; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the posted service credit memo.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries();
                    end;
                }
            }
            part(Subform; "VAT Specification Subform")
            {
                ApplicationArea = Service;
                Editable = false;
            }
            group(Customer)
            {
                Caption = 'Customer';
#pragma warning disable AA0100
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the customer''s account.';
                }
                field(CreditLimitLCY; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    ToolTip = 'Specifies the credit limit of the customer on the service document. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Service;
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
    var
        ServCostCalculationMgt: Codeunit "Serv. Cost Calculation Mgt.";
        IsHandled: Boolean;
    begin
        ClearAll();

        IsHandled := false;
        OnAfterGetRecordOnAfterClearAll(
            Rec, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
            LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        if Rec."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(Rec."Currency Code");

        ServCrMemoLine.SetRange("Document No.", Rec."No.");

        if ServCrMemoLine.Find('-') then
            repeat
                CustAmount := CustAmount + ServCrMemoLine.Amount;
                AmountInclVAT := AmountInclVAT + ServCrMemoLine."Amount Including VAT";
                if Rec."Prices Including VAT" then begin
                    InvDiscAmount := InvDiscAmount + ServCrMemoLine."Inv. Discount Amount" / (1 + ServCrMemoLine.GetVATPct() / 100);
                    PmtDiscAmount := PmtDiscAmount + ServCrMemoLine."Pmt. Discount Amount" / (1 + ServCrMemoLine.GetVATPct() / 100)
                end else begin
                    InvDiscAmount := InvDiscAmount + ServCrMemoLine."Inv. Discount Amount";
                    PmtDiscAmount := PmtDiscAmount + ServCrMemoLine."Pmt. Discount Amount"
                end;
                CostLCY := CostLCY + (ServCrMemoLine.Quantity * ServCrMemoLine."Unit Cost (LCY)");
                LineQty := LineQty + ServCrMemoLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ServCrMemoLine.Quantity * ServCrMemoLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ServCrMemoLine.Quantity * ServCrMemoLine."Gross Weight");
                TotalVolume := TotalVolume + (ServCrMemoLine.Quantity * ServCrMemoLine."Unit Volume");
                if ServCrMemoLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ServCrMemoLine.Quantity / ServCrMemoLine."Units per Parcel", 1, '>');
                if ServCrMemoLine."VAT %" <> VATpercentage then
                    if VATpercentage = 0 then
                        VATpercentage := ServCrMemoLine.GetVATPct()
                    else
                        VATpercentage := -1;
                TotalAdjCostLCY := TotalAdjCostLCY + ServCostCalculationMgt.CalcServCrMemoLineCostLCY(ServCrMemoLine);
                OnAfterGetRecordOnAfterAddLineTotals(
                    Rec, ServCrMemoLine, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
                    LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels);
            until ServCrMemoLine.Next() = 0;
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

        ProfitLCY := AmountLCY - CostLCY;
        if AmountLCY <> 0 then
            ProfitPct := Round(100 * ProfitLCY / AmountLCY, 0.1);

        AdjProfitLCY := AmountLCY - TotalAdjCostLCY;
        OnAfterGetRecordOnAfterCalculateAdjProfitLCY(Rec, AdjProfitLCY);
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

        ServCrMemoLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.Subform.Page.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.Subform.Page.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        ServCrMemoLine: Record "Service Cr.Memo Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        CustAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        VATAmount: Decimal;
        CostLCY: Decimal;
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        AmountLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        VATpercentage: Decimal;
        VATAmountText: Text[30];
        PmtDiscAmount: Decimal;

#pragma warning disable AA0074
        Text000: Label 'VAT Amount';
#pragma warning disable AA0470
        Text001: Label '%1% VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCalculateAdjProfitLCY(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var AdjProfitLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterAddLineTotals(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; ServiceCrMemoLine: Record "Service Cr.Memo Line"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterClearAll(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;
}
