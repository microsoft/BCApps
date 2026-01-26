// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;

page 10046 "Purch. Credit Memo Stats."
{
    Caption = 'Purch. Credit Memo Statistics';
    Editable = false;
    PageType = ListPlus;
    SourceTable = "Purch. Cr. Memo Hdr.";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("VendAmount + InvDiscAmount"; VendAmount + InvDiscAmount)
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
                    ToolTip = 'Specifies the invoice discount amount for the entire sales document. If the Calc. Inv. Discount field in the Purchases & Payables Setup window is selected, the discount is automatically calculated.';
                }
                field(VendAmount; VendAmount)
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
                field(AmountInclVAT; AmountInclVAT)
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
                    Caption = 'Purchase ($)';
                    ToolTip = 'Specifies the purchase amount.';
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
                    ShowCaption = false;
                }
                field("BreakdownAmt[2]"; BreakdownAmt[2])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("BreakdownAmt[3]"; BreakdownAmt[3])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3]);
                    Editable = false;
                    ShowCaption = false;
                }
                field("BreakdownAmt[4]"; BreakdownAmt[4])
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[4]);
                    Editable = false;
                    ShowCaption = false;
                }
            }
            part(SubForm; "Sales Tax Lines Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    ToolTip = 'Specifies the customer''s balance. ';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
        SalesTaxCalculationOverridden: Boolean;
    begin
        ClearAll();
        TaxArea.Get(Rec."Tax Area Code");

        if Rec."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(Rec."Currency Code");

        PurchCrMemoLine.SetRange("Document No.", Rec."No.");

        if PurchCrMemoLine.Find('-') then
            repeat
                VendAmount := VendAmount + PurchCrMemoLine.Amount;
                AmountInclVAT := AmountInclVAT + PurchCrMemoLine."Amount Including VAT";
                if Rec."Prices Including VAT" then
                    InvDiscAmount := InvDiscAmount + PurchCrMemoLine."Inv. Discount Amount" / (1 + PurchCrMemoLine."VAT %" / 100)
                else
                    InvDiscAmount := InvDiscAmount + PurchCrMemoLine."Inv. Discount Amount";
                LineQty := LineQty + PurchCrMemoLine.Quantity;
                TotalNetWeight := TotalNetWeight + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Net Weight");
                TotalGrossWeight := TotalGrossWeight + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Gross Weight");
                TotalVolume := TotalVolume + (PurchCrMemoLine.Quantity * PurchCrMemoLine."Unit Volume");
                if PurchCrMemoLine."Units per Parcel" > 0 then
                    TotalParcels := TotalParcels + Round(PurchCrMemoLine.Quantity / PurchCrMemoLine."Units per Parcel", 1, '>');
                if PurchCrMemoLine."VAT %" <> TaxPercentage then
                    if TaxPercentage = 0 then
                        TaxPercentage := PurchCrMemoLine."VAT %"
                    else
                        TaxPercentage := -1;
            until PurchCrMemoLine.Next() = 0;
        TaxAmount := AmountInclVAT - VendAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if Rec."Currency Code" = '' then
            AmountLCY := VendAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), Rec."Currency Code", VendAmount, Rec."Currency Factor");

        if not Vend.Get(Rec."Pay-to Vendor No.") then
            Clear(Vend);
        Vend.CalcFields("Balance (LCY)");

        AmountInclVAT := VendAmount;
        TaxAmount := 0;

        SalesTaxCalculate.StartSalesTaxCalculation();
        TempSalesTaxLine.DeleteAll();

        SalesTaxCalculationOverridden := false;
        OnAfterCalculateSalesTax(PurchCrMemoLine, TempSalesTaxLine, TempSalesTaxAmtLine, SalesTaxCalculationOverridden);
        if not SalesTaxCalculationOverridden then
            if TaxArea."Use External Tax Engine" then
                SalesTaxCalculate.CallExternalTaxEngineForDoc(DATABASE::"Purch. Cr. Memo Hdr.", 0, Rec."No.")
            else begin
                SalesTaxCalculate.AddPurchCrMemoLines(Rec."No.");
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
        if TempSalesTaxAmtLine.FindSet() then begin
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
                TaxAmount := TaxAmount + TempSalesTaxAmtLine."Tax Amount";
            until TempSalesTaxAmtLine.Next() = 0;
            AmountInclVAT := AmountInclVAT + TaxAmount;
        end;
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        CurrPage.SubForm.PAGE.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Vend: Record Vendor;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        Currency: Record Currency;
        TaxArea: Record "Tax Area";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VendAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        AmountLCY: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        TaxAmount: Decimal;
        TaxPercentage: Decimal;
        BreakdownTitle: Text[35];
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Sales Tax Breakdown:';
        Text008: Label 'Other Taxes';

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateSalesTax(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
    end;
}

