// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using System.Environment;

page 10039 "Purchase Order Stats."
{
    Caption = 'Purchase Order Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Purchase Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TotalPurchLine[1].""Line Amount"""; TotalPurchLine[1]."Line Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines on the purchase document.';
                }
                field("TotalPurchLine[1].""Inv. Discount Amount"""; TotalPurchLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire purchase order.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount(1);
                    end;
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount (excluding tax) for the purchase document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount(1);
                    end;
                }
                field(TaxAmount; VATAmount[1])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount that has been calculated for all the lines in the purchase order.';
                }
                field("TotalAmount2[1]"; TotalAmount2[1])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount, including taxes.';
                }
                field("TotalPurchLineLCY[1].Amount"; TotalPurchLineLCY[1].Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase ($)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the purchase order in dollars.';
                }
                field("TotalPurchLine[1].Quantity"; TotalPurchLine[1].Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, fixed assets, and/or items in the purchase order.';
                }
                field("TotalPurchLine[1].""Units per Parcel"""; TotalPurchLine[1]."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalPurchLine[1].""Net Weight"""; TotalPurchLine[1]."Net Weight")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the purchase order.';
                }
                field("TotalPurchLine[1].""Gross Weight"""; TotalPurchLine[1]."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items in the purchase order.';
                }
                field("TotalPurchLine[1].""Unit Volume"""; TotalPurchLine[1]."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total volume of the items in the purchase order.';
                }
                label(BreakdownTitle)
                {
                    ApplicationArea = Suite;
                    CaptionClass = Format(BreakdownTitle);
                    Editable = false;
                }
                field("BreakdownAmt[1,1]"; BreakdownAmt[1, 1])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 1]);
                    Editable = false;
                    ShowCaption = false;
                }
                field(BreakdownAmt2; BreakdownAmt[1, 2])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 2]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt3; BreakdownAmt[1, 3])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 3]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt4; BreakdownAmt[1, 4])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[1, 4]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(NoOfVATLines; TempSalesTaxLine1.Count)
                {
                    ApplicationArea = Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of sales tax lines on the purchase order.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempSalesTaxLine1, false, ActiveTab::General);
                        UpdateHeaderInfo(1, TempSalesTaxLine1);
                    end;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("TotalPurchLine[2].""Line Amount"""; TotalPurchLine[2]."Line Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines on the purchase document.';
                }
                field("TotalPurchLine[2].""Inv. Discount Amount"""; TotalPurchLine[2]."Inv. Discount Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire purchase document.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount(2);
                    end;
                }
                field("TotalAmount1[2]"; TotalAmount1[2])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount (excluding tax) for the purchase document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount(2);
                    end;
                }
                field("VATAmount[2]"; VATAmount[2])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount that has been calculated from all the lines in the purchase document.';
                }
                field("TotalAmount2[2]"; TotalAmount2[2])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount, including taxes.';
                }
                field("TotalPurchLineLCY[2].Amount"; TotalPurchLineLCY[2].Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase ($)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the purchase order in dollars.';
                }
                field("TotalPurchLine[2].Quantity"; TotalPurchLine[2].Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, fixed assets, and/or items in the purchase order.';
                }
                field("TotalPurchLine[2].""Units per Parcel"""; TotalPurchLine[2]."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalPurchLine[2].""Net Weight"""; TotalPurchLine[2]."Net Weight")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the purchase order.';
                }
                field("TotalPurchLine[2].""Gross Weight"""; TotalPurchLine[2]."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items in the purchase order.';
                }
                field("TotalPurchLine[2].""Unit Volume"""; TotalPurchLine[2]."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels on the document.';
                }
                label(BreakdownTitle2)
                {
                    ApplicationArea = Suite;
                    CaptionClass = Format(BreakdownTitle);
                }
                field(BreakdownAmt5; BreakdownAmt[2, 1])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2, 1]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt6; BreakdownAmt[2, 2])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2, 2]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt7; BreakdownAmt[2, 3])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2, 3]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt8; BreakdownAmt[2, 4])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[2, 4]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(NoOfVATLines_Invoice; TempSalesTaxLine2.Count)
                {
                    ApplicationArea = Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of sales tax lines on the purchase order.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempSalesTaxLine2, true, ActiveTab::Invoicing);
                        UpdateHeaderInfo(2, TempSalesTaxLine2);
                    end;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("TotalPurchLine[3].""Line Amount"""; TotalPurchLine[3]."Line Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines on the purchase document.';
                }
                field("TotalPurchLine[3].""Inv. Discount Amount"""; TotalPurchLine[3]."Inv. Discount Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire purchase document.';
                }
                field("TotalAmount1[3]"; TotalAmount1[3])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount (excluding tax) for the purchase document.';
                }
                field("VATAmount[3]"; VATAmount[3])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount that has been calculated from all the lines in the purchase document.';
                }
                field("TotalAmount2[3]"; TotalAmount2[3])
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount, including taxes.';
                }
                field("TotalPurchLineLCY[3].Amount"; TotalPurchLineLCY[3].Amount)
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase ($)';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the purchase order in dollars.';
                }
                field("TotalPurchLine[3].Quantity"; TotalPurchLine[3].Quantity)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, fixed assets, and/or items in the purchase order.';
                }
                field("TotalPurchLine[3].""Units per Parcel"""; TotalPurchLine[3]."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalPurchLine[3].""Net Weight"""; TotalPurchLine[3]."Net Weight")
                {
                    ApplicationArea = Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the purchase order.';
                }
                field("TotalPurchLine[3].""Gross Weight"""; TotalPurchLine[3]."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items in the purchase order.';
                }
                field("TotalPurchLine[3].""Unit Volume"""; TotalPurchLine[3]."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels on the document.';
                }
                label(BreakdownTitle3)
                {
                    ApplicationArea = Suite;
                    CaptionClass = Format(BreakdownTitle);
                }
                field(BreakdownAmt9; BreakdownAmt[3, 1])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3, 1]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt10; BreakdownAmt[3, 2])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3, 2]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt11; BreakdownAmt[3, 3])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3, 3]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(BreakdownAmt12; BreakdownAmt[3, 4])
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    CaptionClass = Format(BreakdownLabel[3, 4]);
                    Caption = 'BreakdownAmt';
                    Editable = false;
                }
                field(NoOfVATLines_Shipping; TempSalesTaxLine3.Count)
                {
                    ApplicationArea = Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of sales tax lines on the purchase order.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempSalesTaxLine3, false, ActiveTab::Shipping);
                        UpdateHeaderInfo(3, TempSalesTaxLine3);
                    end;
                }
            }
            group(Prepayment)
            {
                Caption = 'Prepayment';
                field(PrepmtTotalAmount; PrepmtTotalAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006, false);

                    trigger OnValidate()
                    begin
                        UpdatePrepmtAmount();
                    end;
                }
                field(PrepmtVATAmount; PrepmtVATAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(PrepmtVATAmountText);
                    Caption = 'Prepayment Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies the total prepayment amount that has been invoiced for the purchase order.';
                }
                field(PrepmtTotalAmount2; PrepmtTotalAmount2)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006, true);
                    Caption = 'Prepmt. Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies the total prepayment amount that has been invoiced for the purchase order.';
                }
                field("TotalPurchLine[1].""Prepmt. Amt. Inv."""; TotalPurchLine[1]."Prepmt. Amt. Inv.")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text007, false);
                    Editable = false;
                }
                field(PrepmtInvPct; PrepmtInvPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced % of Prepayment Amt.';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the Invoiced Percentage of Prepayment Amt.';
                }
                field("TotalPurchLine[1].""Prepmt Amt Deducted"""; TotalPurchLine[1]."Prepmt Amt Deducted")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text008, false);
                    Editable = false;
                }
                field(PrepmtDeductedPct; PrepmtDeductedPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Deducted % of Prepayment Amt. to Deduct';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the Deducted Percentage of Prepayment Amt. to Deduct.';
                }
                field("TotalPurchLine[1].""Prepmt Amt to Deduct"""; TotalPurchLine[1]."Prepmt Amt to Deduct")
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text009, false);
                    Editable = false;
                }
                field(NoOfVATLines_Prepayment; TempVATAmountLine4.Count)
                {
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of sales tax lines on the purchase order.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempSalesTaxLine1, false, ActiveTab::Prepayment);
                        UpdateHeaderInfo(1, TempSalesTaxLine1);
                    end;
                }
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance in local currency.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        PurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        PurchPostPrepmt: Codeunit "Purchase-Post Prepayments";
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));

        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        Clear(PurchLine);
        Clear(TotalPurchLine);
        Clear(TotalPurchLineLCY);
        Clear(BreakdownLabel);
        Clear(BreakdownAmt);

        PurchLine.Reset();

        for i := 1 to 3 do begin
            TempPurchLine.DeleteAll();
            Clear(TempPurchLine);
            Clear(PurchPost);
            PurchPost.GetPurchLines(Rec, TempPurchLine, i - 1);
            Clear(PurchPost);
            SalesTaxCalculate.StartSalesTaxCalculation();
            TempPurchLine.SetFilter(Type, '>0');
            TempPurchLine.SetFilter(Quantity, '<>0');
            if TempPurchLine.Find('-') then
                repeat
                    SalesTaxCalculate.AddPurchLine(TempPurchLine);
                until TempPurchLine.Next() = 0;
            TempPurchLine.Reset();
            case i of
                1:
                    begin
                        TempSalesTaxLine1.DeleteAll();
                        SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine1);
                    end;
                2:
                    begin
                        TempSalesTaxLine2.DeleteAll();
                        SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine2);
                    end;
                3:
                    begin
                        TempSalesTaxLine3.DeleteAll();
                        SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
                        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine3);
                    end;
            end;

            if Rec.Status = Rec.Status::Open then
                SalesTaxCalculate.DistTaxOverPurchLines(TempPurchLine);
            PurchPost.SumPurchLinesTemp(
              Rec, TempPurchLine, i - 1, TotalPurchLine[i], TotalPurchLineLCY[i],
              VATAmount[i], VATAmountText[i]);
            TotalAmount1[i] := TotalPurchLine[i].Amount;
            TotalAmount2[i] := TotalAmount1[i];
            VATAmount[i] := 0;

            SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
            BrkIdx := 0;
            PrevPrintOrder := 0;
            PrevTaxPercent := 0;
            if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
                BreakdownTitle := Text1020010
            else
                BreakdownTitle := Text1020011;
            TempSalesTaxAmtLine.Reset();
            TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
            if TempSalesTaxAmtLine.Find('-') then
                repeat
                    if (TempSalesTaxAmtLine."Print Order" = 0) or
                       (TempSalesTaxAmtLine."Print Order" <> PrevPrintOrder) or
                       (TempSalesTaxAmtLine."Tax %" <> PrevTaxPercent)
                    then begin
                        BrkIdx := BrkIdx + 1;
                        if BrkIdx > ArrayLen(BreakdownAmt, 2) then begin
                            BrkIdx := BrkIdx - 1;
                            BreakdownLabel[i, BrkIdx] := Text1020012;
                        end else
                            BreakdownLabel[i, BrkIdx] := CopyStr(StrSubstNo(TempSalesTaxAmtLine."Print Description", TempSalesTaxAmtLine."Tax %"), 1, MaxStrLen(BreakdownLabel[i, BrkIdx]));
                    end;
                    BreakdownAmt[i, BrkIdx] := BreakdownAmt[i, BrkIdx] + TempSalesTaxAmtLine."Tax Amount";
                    VATAmount[i] := VATAmount[i] + TempSalesTaxAmtLine."Tax Amount";
                until TempSalesTaxAmtLine.Next() = 0;
            TotalAmount2[i] := TotalAmount2[i] + VATAmount[i];
        end;
        TempPurchLine.DeleteAll();
        Clear(TempPurchLine);
        PurchPostPrepmt.GetPurchLines(Rec, 0, TempPurchLine);
        PurchPostPrepmt.SumPrepmt(
          Rec, TempPurchLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText);
        PrepmtInvPct :=
          Pct(TotalPurchLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalPurchLine[1]."Prepmt Amt Deducted", TotalPurchLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;

        if Vend.Get(Rec."Pay-to Vendor No.") then
            Vend.CalcFields("Balance (LCY)")
        else
            Clear(Vend);

        TempSalesTaxLine1.ModifyAll(Modified, false);
        TempSalesTaxLine2.ModifyAll(Modified, false);
        TempSalesTaxLine3.ModifyAll(Modified, false);

        PrevTab := NullTab;
    end;

    trigger OnOpenPage()
    begin
#if not CLEAN26
        if not Rec.SkipStatisticsPreparation() then
            Rec.PrepareOpeningDocumentStatistics();
        Rec.ResetSkipStatisticsPreparationFlag();
#else
        Rec.PrepareOpeningDocumentStatistics();
#endif
        PurchSetup.Get();
        NullTab := -1;
        AllowInvDisc :=
          not (PurchSetup."Calc. Inv. Discount" and VendInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          PurchSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote, Rec."Document Type"::"Blanket Order"]);
        VATLinesFormIsEditable := AllowVATDifference or AllowInvDisc or (Rec."Tax Area Code" <> '');
        CurrPage.Editable := VATLinesFormIsEditable;
        TaxArea.Get(Rec."Tax Area Code");
    end;

    trigger OnClosePage()
    var
        PurchCalcDiscountByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchCalcDiscountByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification(PrevTab);
        if TempSalesTaxLine1.GetAnyLineModified() or TempSalesTaxLine2.GetAnyLineModified() then
            UpdateTaxonPurchLines();
        exit(true);
    end;

    var
        Text000: Label 'Purchase %1 Statistics';
        Text001: Label 'Total';
        Text002: Label 'Amount';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.';
        TotalPurchLine: array[3] of Record "Purchase Line";
        TotalPurchLineLCY: array[3] of Record "Purchase Line";
        Vend: Record Vendor;
        TempSalesTaxLine1: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxLine2: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxLine3: Record "Sales Tax Amount Line" temporary;
        TempVATAmountLine4: Record "VAT Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TaxArea: Record "Tax Area";
        PurchPost: Codeunit "Purch.-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        VATLinesForm: Page "Sales Tax Lines Subform Dyn";
        PrepmtTotalAmount: Decimal;
        PrepmtVATAmount: Decimal;
        PrepmtTotalAmount2: Decimal;
        PrepmtVATAmountText: Text[30];
        PrepmtInvPct: Decimal;
        PrepmtDeductedPct: Decimal;
        VATAmountText: array[3] of Text[30];
        i: Integer;
        PrevNo: Code[20];
        ActiveTab: Option General,Invoicing,Shipping,Prepayment;
        PrevTab: Option General,Invoicing,Shipping,Prepayment;
        NullTab: Integer;
        VATLinesFormIsEditable: Boolean;
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        Text006: Label 'Prepmt. Amount';
        Text007: Label 'Prepmt. Amt. Invoiced';
        Text008: Label 'Prepmt. Amt. Deducted';
        Text009: Label 'Prepmt. Amt. to Deduct';
        BreakdownTitle: Text[35];
        BreakdownLabel: array[3, 4] of Text[30];
        BreakdownAmt: array[3, 4] of Decimal;
        BrkIdx: Integer;
        Text1020010: Label 'Tax Breakdown:';
        Text1020011: Label 'Sales Tax Breakdown:';
        Text1020012: Label 'Other Taxes';

    protected var
        TotalAmount1: array[3] of Decimal;
        TotalAmount2: array[3] of Decimal;
        VATAmount: array[3] of Decimal;

    local procedure UpdateHeaderInfo(IndexNo: Integer; var VATAmountLine: Record "Sales Tax Amount Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalPurchLine[IndexNo]."Inv. Discount Amount" := VATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] :=
          TotalPurchLine[IndexNo]."Line Amount" - TotalPurchLine[IndexNo]."Inv. Discount Amount";
        VATAmount[IndexNo] := VATAmountLine.GetTotalTaxAmountFCY();
        if Rec."Prices Including VAT" then
            TotalAmount2[IndexNo] := TotalPurchLine[IndexNo].Amount
        else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

        if Rec."Prices Including VAT" then
            TotalPurchLineLCY[IndexNo].Amount := TotalAmount2[IndexNo]
        else
            TotalPurchLineLCY[IndexNo].Amount := TotalAmount1[IndexNo];
        if Rec."Currency Code" <> '' then begin
            if (Rec."Document Type" in [Rec."Document Type"::"Blanket Order", Rec."Document Type"::Quote]) and
               (Rec."Posting Date" = 0D)
            then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";

            TotalPurchLineLCY[IndexNo].Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, Rec."Currency Code", TotalPurchLineLCY[IndexNo].Amount, Rec."Currency Factor");
        end;
    end;

    local procedure GetVATSpecification(StatisticsTab: Option General,Invoicing,Shipping)
    begin
        case StatisticsTab of
            StatisticsTab::General:
                begin
                    VATLinesForm.GetTempTaxAmountLine(TempSalesTaxLine1);
                    UpdateHeaderInfo(1, TempSalesTaxLine1);
                end;
            StatisticsTab::Invoicing:
                begin
                    VATLinesForm.GetTempTaxAmountLine(TempSalesTaxLine2);
                    UpdateHeaderInfo(2, TempSalesTaxLine2);
                end;
            StatisticsTab::Shipping:
                VATLinesForm.GetTempTaxAmountLine(TempSalesTaxLine3);
        end;
    end;

    local procedure SetEditableForVATLinesForm(StatisticsTab: Option General,Invoicing,Shipping,Prepayment)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        case StatisticsTab of
            StatisticsTab::General, StatisticsTab::Invoicing:
                if Rec.Status = Rec.Status::Open then begin
                    if EnvironmentInfo.IsSaaS() then
                        VATLinesForm.Editable := VATLinesFormIsEditable
                    else
                        VATLinesForm.Editable := false;
                end else
                    VATLinesForm.Editable := VATLinesFormIsEditable;
            StatisticsTab::Shipping:
                VATLinesForm.Editable := false;
            StatisticsTab::Prepayment:
                VATLinesForm.Editable := VATLinesFormIsEditable;
        end;
    end;

    local procedure UpdateTotalAmount(IndexNo: Integer)
    begin
        CheckAllowInvDisc();
        TotalPurchLine[IndexNo]."Inv. Discount Amount" := TotalPurchLine[IndexNo]."Line Amount" - TotalAmount1[IndexNo];
        UpdateInvDiscAmount(IndexNo);
    end;

    local procedure UpdateInvDiscAmount(ModifiedIndexNo: Integer)
    var
        PartialInvoicing: Boolean;
        MaxIndexNo: Integer;
        IndexNo: array[2] of Integer;
        i: Integer;
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if not (ModifiedIndexNo in [1, 2]) then
            exit;

        if ModifiedIndexNo = 1 then
            InvDiscBaseAmount := TempSalesTaxLine1.GetTotalInvDiscBaseAmount(false, Rec."Currency Code")
        else
            InvDiscBaseAmount := TempSalesTaxLine2.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");

        if InvDiscBaseAmount = 0 then
            Error(Text003, TempSalesTaxLine2.FieldCaption("Inv. Disc. Base Amount"));

        if TotalPurchLine[ModifiedIndexNo]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalPurchLine[ModifiedIndexNo].FieldCaption("Inv. Discount Amount"),
              TempSalesTaxLine2.FieldCaption("Inv. Disc. Base Amount"));

        PartialInvoicing := (TotalPurchLine[1]."Line Amount" <> TotalPurchLine[2]."Line Amount");

        IndexNo[1] := ModifiedIndexNo;
        IndexNo[2] := 3 - ModifiedIndexNo;
        if (ModifiedIndexNo = 2) and PartialInvoicing then
            MaxIndexNo := 1
        else
            MaxIndexNo := 2;

        if not PartialInvoicing then
            if ModifiedIndexNo = 1 then
                TotalPurchLine[2]."Inv. Discount Amount" := TotalPurchLine[1]."Inv. Discount Amount"
            else
                TotalPurchLine[1]."Inv. Discount Amount" := TotalPurchLine[2]."Inv. Discount Amount";

        for i := 1 to MaxIndexNo do begin
            if (i = 1) or not PartialInvoicing then
                if IndexNo[i] = 1 then
                    TempSalesTaxLine1.SetInvoiceDiscountAmount(
                      TotalPurchLine[IndexNo[i]]."Inv. Discount Amount", TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %")
                else
                    TempSalesTaxLine2.SetInvoiceDiscountAmount(
                      TotalPurchLine[IndexNo[i]]."Inv. Discount Amount", TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");

            if (i = 2) and PartialInvoicing then
                if IndexNo[i] = 1 then begin
                    InvDiscBaseAmount := TempSalesTaxLine2.GetTotalInvDiscBaseAmount(false, TotalPurchLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempSalesTaxLine1.SetInvoiceDiscountPercent(
                          0, TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempSalesTaxLine1.SetInvoiceDiscountPercent(
                          100 * TempSalesTaxLine2.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end else begin
                    InvDiscBaseAmount := TempSalesTaxLine1.GetTotalInvDiscBaseAmount(false, TotalPurchLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempSalesTaxLine2.SetInvoiceDiscountPercent(
                          0, TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempSalesTaxLine2.SetInvoiceDiscountPercent(
                          100 * TempSalesTaxLine1.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalPurchLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end;
        end;

        UpdateHeaderInfo(1, TempSalesTaxLine1);
        UpdateHeaderInfo(2, TempSalesTaxLine2);

        if ModifiedIndexNo = 1 then
            VATLinesForm.SetTempTaxAmountLine(TempSalesTaxLine1)
        else
            VATLinesForm.SetTempTaxAmountLine(TempSalesTaxLine2);

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalPurchLine[1]."Inv. Discount Amount";
        Rec.Modify();
        UpdateTaxonPurchLines();
    end;

    local procedure UpdatePrepmtAmount()
    var
        TempPurchLine: Record "Purchase Line" temporary;
        PurchPostPrepmt: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepmt.UpdatePrepmtAmountOnPurchLines(Rec, PrepmtTotalAmount);
        PurchPostPrepmt.GetPurchLines(Rec, 0, TempPurchLine);
        PurchPostPrepmt.SumPrepmt(
          Rec, TempPurchLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText);
        PrepmtInvPct :=
          Pct(TotalPurchLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalPurchLine[1]."Prepmt Amt Deducted", TotalPurchLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;
        Rec.Modify();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);

        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateTaxonPurchLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        GetVATSpecification(ActiveTab);

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.FindFirst();

        if TempSalesTaxLine1.GetAnyLineModified() then begin
            SalesTaxCalculate.StartSalesTaxCalculation();
            SalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine1,
              "Sales Tax Document Area"::Purchase.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            SalesTaxCalculate.DistTaxOverPurchLines(PurchLine);
            SalesTaxCalculate.SaveTaxDifferences();
        end;
        if TempSalesTaxLine2.GetAnyLineModified() then begin
            SalesTaxCalculate.StartSalesTaxCalculation();
            SalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine2,
              "Sales Tax Document Area"::Purchase.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            SalesTaxCalculate.DistTaxOverPurchLines(PurchLine);
            SalesTaxCalculate.SaveTaxDifferences();
        end;
        PrevNo := '';
    end;

    local procedure VendInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        VendInvDisc.SetRange(Code, InvDiscCode);
        exit(VendInvDisc.FindFirst())
    end;

    local procedure CheckAllowInvDisc()
    var
        VendInvDisc: Record "Vendor Invoice Disc.";
    begin
        if not AllowInvDisc then
            Error(
              Text005,
              VendInvDisc.TableCaption(), Rec.FieldCaption("Invoice Disc. Code"), Rec."Invoice Disc. Code");
    end;

    local procedure Pct(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        if Denominator = 0 then
            exit(0);
        exit(Round(Numerator / Denominator * 10000, 1));
    end;

    procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "Sales Tax Amount Line"; ThisTabAllowsVATEditing: Boolean; ActiveTab: Option General,Invoicing,Shipping,Prepayment)
    begin
        Clear(VATLinesForm);
        VATLinesForm.SetTempTaxAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
        SetEditableForVATLinesForm(ActiveTab);
        VATLinesForm.RunModal();
        VATLinesForm.GetTempTaxAmountLine(VATLinesToDrillDown);
    end;
}

