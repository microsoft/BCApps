// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;

page 6033 "Service Invoice Statistics"
{
    Caption = 'Service Invoice Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Service Invoice Header";

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
                    ToolTip = 'Specifies the net amount of all the lines in the posted service invoice. ';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the entire service invoice. If there is a check mark in the Calc. Inv. Discount field in the Sales & Receivables Setup window, the discount was calculated automatically.';
                }
                field(PmtDiscAmount; PmtDiscAmount)
                {
                    ApplicationArea = Service;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Pmt. Discount Amount';
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
                    ToolTip = 'Specifies the total amount, including VAT, that has been posted as invoiced to the customer''s account.';
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
                    ToolTip = 'Specifies the amount of profit on the service invoice (in LCY), prior to any item cost adjustments. The program calculates the amount as the difference between the values in the Amount and the Original Cost (LCY) fields.';
                }
                field(AdjProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    ToolTip = 'Specifies the amount of profit for the service invoice, in LCY, adjusted for any changes in the original item costs. ';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the profit amount for the invoiced quantity, expressed in percentage, prior to any item cost adjustments on the service order.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Service;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies the amount of the adjusted profit on the service invoice, expressed as percentage of the amount in the Amount field.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Service;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of all G/L account entries, costs, items and/or resource hours in the posted service invoice.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Service;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels that were invoiced.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the invoiced items.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the invoiced items.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Service;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the invoiced items.';
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
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the posted service invoice, adjusted for any changes in the original costs of these items.';
                }
                field(CostAdjmtAmountLCY; TotalAdjCostLCY - CostLCY)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the posted service invoice.';

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
            currency.InitRoundingPrecision()
        else
            currency.Get(Rec."Currency Code");

        ServInvLine.SetRange("Document No.", Rec."No.");

        if ServInvLine.Find('-') then
            repeat
                CustAmount := CustAmount + ServInvLine.Amount;
                AmountInclVAT := AmountInclVAT + ServInvLine."Amount Including VAT";
                if Rec."Prices Including VAT" then begin
                    InvDiscAmount := InvDiscAmount + ServInvLine."Inv. Discount Amount" / (1 + ServInvLine.GetVATPct() / 100);
                    PmtDiscAmount := PmtDiscAmount + ServInvLine."Pmt. Discount Amount" / (1 + ServInvLine.GetVATPct() / 100);
                end else begin
                    InvDiscAmount := InvDiscAmount + ServInvLine."Inv. Discount Amount";
                    PmtDiscAmount := PmtDiscAmount + ServInvLine."Pmt. Discount Amount";
                end;
                CostLCY := CostLCY + (ServInvLine.Quantity * ServInvLine."Unit Cost (LCY)");
                LineQty := LineQty + ServInvLine.Quantity;
                TotalNetWeight := TotalNetWeight + (ServInvLine.Quantity * ServInvLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (ServInvLine.Quantity * ServInvLine."Gross Weight");
                TotalVolume := TotalVolume + (ServInvLine.Quantity * ServInvLine."Unit Volume");
                if ServInvLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(ServInvLine.Quantity / ServInvLine."Units per Parcel", 1, '>');
                if ServInvLine."VAT %" <> VATPercentage then
                    if VATPercentage = 0 then
                        VATPercentage := ServInvLine.GetVATPct()
                    else
                        VATPercentage := -1;
                TotalAdjCostLCY := TotalAdjCostLCY + ServCostCalculationMgt.CalcServInvLineCostLCY(ServInvLine);
                OnAfterGetRecordOnAfterAddLineTotals(
                    Rec, ServInvLine, CustAmount, AmountInclVAT, InvDiscAmount, CostLCY, TotalAdjCostLCY,
                    LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels);
            until ServInvLine.Next() = 0;
        VATAmount := AmountInclVAT - CustAmount;
        InvDiscAmount := Round(InvDiscAmount, currency."Amount Rounding Precision");

        if VATPercentage <= 0 then
            VATAmountText := Text000
        else
            VATAmountText := StrSubstNo(Text001, VATPercentage);

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

        ServInvLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.Subform.Page.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.Subform.Page.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        ServInvLine: Record "Service Invoice Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        currency: Record Currency;
        CustAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        VATAmount: Decimal;
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
        CreditLimitLCYExpendedPct: Decimal;
        VATPercentage: Decimal;
        VATAmountText: Text[30];
        PmtDiscAmount: Decimal;

#pragma warning disable AA0074
        Text000: Label 'VAT Amount';
#pragma warning disable AA0470
        Text001: Label '%1% VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        AmountLCY: Decimal;
        CostLCY: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterClearAll(ServiceInvoiceHeader: Record "Service Invoice Header"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterAddLineTotals(ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvLine: Record "Service Invoice Line"; var CustAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var CostLCY: Decimal; var TotalAdjCostLCY: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCalculateAdjProfitLCY(ServiceInvoiceHeader: Record "Service Invoice Header"; var AdjProfitLCY: Decimal)
    begin
    end;
}
