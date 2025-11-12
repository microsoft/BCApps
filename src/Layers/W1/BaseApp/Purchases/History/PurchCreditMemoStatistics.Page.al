// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

page 401 "Purch. Credit Memo Statistics"
{
    Caption = 'Purch. Credit Memo Statistics';
    Editable = false;
    LinksAllowed = false;
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
                    ToolTip = 'Specifies the net amount of all the lines in the purchase document.';
                }
                field(InvDiscAmount; InvDiscAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the purchase document.';
                }
                field(VendAmount; VendAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total';
                    ToolTip = 'Specifies the total amount, less any invoice discount amount, and excluding VAT for the purchase document.';
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the purchase document.';
                }
                field(AmountInclVAT; AmountInclVAT)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Total Incl. VAT';
                    ToolTip = 'Specifies the total amount, including VAT, that will be posted to the vendor''s account for all the lines in the purchase document.';
                }
                field(AmountLCY; AmountLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase (LCY)';
                    ToolTip = 'Specifies your total purchases.';
                }
                field(LineQty; LineQty)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items and/or resources in the purchase document.';
                }
                field(TotalParcels; TotalParcels)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total number of parcels in the purchase document.';
                }
                field(TotalNetWeight; TotalNetWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total net weight of the items in the purchase document.';
                }
                field(TotalGrossWeight; TotalGrossWeight)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total gross weight of the items in the purchase document.';
                }
                field(TotalVolume; TotalVolume)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total volume of the items in the purchase document.';
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            group(Vendor)
            {
                Caption = 'Vendor';
#pragma warning disable AA0100
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the balance in LCY on the vendor''s account.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        ClearAll();

        Currency.Initialize(Rec."Currency Code");

        CalculateTotals();

        VATAmount := AmountInclVAT - VendAmount;
        InvDiscAmount := Round(InvDiscAmount, Currency."Amount Rounding Precision");

        if VATPercentage <= 0 then
            VATAmountText := Text000
        else
            VATAmountText := StrSubstNo(Text001, VATPercentage);

        if Rec."Currency Code" = '' then
            AmountLCY := VendAmount
        else
            AmountLCY :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                WorkDate(), Rec."Currency Code", VendAmount, Rec."Currency Factor");

        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document No.", Rec."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::"Credit Memo");
        VendLedgEntry.SetRange("Vendor No.", Rec."Pay-to Vendor No.");
        if VendLedgEntry.FindFirst() then
            AmountLCY := VendLedgEntry."Purchase (LCY)";

        if not Vend.Get(Rec."Pay-to Vendor No.") then
            Clear(Vend);
        Vend.CalcFields("Balance (LCY)");

        PurchCrMemoLine.CalcVATAmountLines(Rec, TempVATAmountLine);
        CurrPage.SubForm.Page.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.Page.InitGlobals(Rec."Currency Code", false, false, false, false, Rec."VAT Base Discount %");
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'VAT Amount';
#pragma warning disable AA0470
        Text001: Label '%1% VAT';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrExchRate: Record "Currency Exchange Rate";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Vend: Record Vendor;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        VendAmount: Decimal;
        AmountInclVAT: Decimal;
        InvDiscAmount: Decimal;
        AmountLCY: Decimal;
        LineQty: Decimal;
        TotalNetWeight: Decimal;
        TotalGrossWeight: Decimal;
        TotalVolume: Decimal;
        TotalParcels: Decimal;
        VATAmount: Decimal;
        VATPercentage: Decimal;
        VATAmountText: Text[30];

    local procedure CalculateTotals()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(
            Rec, VendAmount, AmountInclVAT, InvDiscAmount,
            LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, IsHandled);
        if IsHandled then
            exit;

        PurchCrMemoLine.SetRange("Document No.", Rec."No.");
        if PurchCrMemoLine.Find('-') then
            repeat
                VendAmount += PurchCrMemoLine.Amount;
                AmountInclVAT += PurchCrMemoLine."Amount Including VAT";
                if Rec."Prices Including VAT" then
                    InvDiscAmount += PurchCrMemoLine."Inv. Discount Amount" / (1 + PurchCrMemoLine.GetVATPct() / 100)
                else
                    InvDiscAmount += PurchCrMemoLine."Inv. Discount Amount";
                LineQty += PurchCrMemoLine.Quantity;
                TotalNetWeight += PurchCrMemoLine.Quantity * PurchCrMemoLine."Net Weight";
                TotalGrossWeight += PurchCrMemoLine.Quantity * PurchCrMemoLine."Gross Weight";
                TotalVolume += PurchCrMemoLine.Quantity * PurchCrMemoLine."Unit Volume";
                if PurchCrMemoLine."Units per Parcel" > 0 then
                    TotalParcels += Round(PurchCrMemoLine.Quantity / PurchCrMemoLine."Units per Parcel", 1, '>');
                if PurchCrMemoLine."VAT %" <> VATPercentage then
                    if VATPercentage = 0 then
                        VATPercentage := PurchCrMemoLine.GetVATPct()
                    else
                        VATPercentage := -1;

                OnCalculateTotalsOnAfterAddLineTotals(
                    PurchCrMemoLine, VendAmount, AmountInclVAT, InvDiscAmount,
                    LineQty, TotalNetWeight, TotalGrossWeight, TotalVolume, TotalParcels, VATPercentage, Rec)
            until PurchCrMemoLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."; var VendAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateTotalsOnAfterAddLineTotals(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var VendAmount: Decimal; var AmountInclVAT: Decimal; var InvDiscAmount: Decimal; var LineQty: Decimal; var TotalNetWeight: Decimal; var TotalGrossWeight: Decimal; var TotalVolume: Decimal; var TotalParcels: Decimal; var VATPercentage: Decimal; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}

