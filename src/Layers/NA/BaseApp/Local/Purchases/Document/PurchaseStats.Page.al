// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

page 10043 "Purchase Stats."
{
    Caption = 'Purchase Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Purchase Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TotalPurchLine.""Line Amount"""; TotalPurchLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the transaction amount.';
                }
                field("TotalPurchLine.""Inv. Discount Amount"""; TotalPurchLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the entire sales document. If the Calc. Inv. Discount field in the Purchases & Payables Setup window is selected, the discount is automatically calculated.';

                    trigger OnValidate()
                    begin
                        UpdateInvDiscAmount();
                    end;
                }
                field(TotalAmount1; TotalAmount1)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount and exclusive of VAT for the posted document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount();
                    end;
                }
                field(TaxAmount; TaxAmount)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the tax amount.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = SalesTax;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount, including tax, that has been posted as invoiced.';
                }
                field("TotalPurchLineLCY.Amount"; TotalPurchLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Purchase ($)';
                    Editable = false;
                    ToolTip = 'Specifies the purchase amount.';
                }
                field("TotalPurchLine.Quantity"; TotalPurchLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the item quantity.';
                }
                field("TotalPurchLine.""Units per Parcel"""; TotalPurchLine."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalPurchLine.""Net Weight"""; TotalPurchLine."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of items on the sales order.';
                }
                field("TotalPurchLine.""Gross Weight"""; TotalPurchLine."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items on the document.';
                }
                field("TotalPurchLine.""Unit Volume"""; TotalPurchLine."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
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
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vend.""Balance (LCY)"""; Vend."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    Editable = false;
                    ToolTip = 'Specifies the balance on the vendor''s account.';
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
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
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
        Clear(PurchPost);
        Clear(TaxAmount);

        SalesTaxCalculate.StartSalesTaxCalculation();
        OnAfterStartSalesTaxCalculation();

        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');
        if PurchLine.Find('-') then
            repeat
                TempPurchLine.Copy(PurchLine);
                TempPurchLine.Insert();
                if not TaxArea."Use External Tax Engine" then
                    SalesTaxCalculate.AddPurchLine(TempPurchLine);
            until PurchLine.Next() = 0;
        TempSalesTaxLine.DeleteAll();
        if TaxArea."Use External Tax Engine" then
            SalesTaxCalculate.CallExternalTaxEngineForPurch(Rec, true)
        else
            SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");
        SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine);

        SalesTaxCalculate.DistTaxOverPurchLines(TempPurchLine);
        PurchPost.SumPurchLinesTemp(
          Rec, TempPurchLine, 0, TotalPurchLine, TotalPurchLineLCY, TaxAmount, TaxAmountText);

        if Rec."Prices Including VAT" then begin
            TotalAmount2 := TotalPurchLine.Amount;
            TotalAmount1 := TotalPurchLine."Line Amount" - TotalPurchLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalPurchLine.Amount;
            TotalAmount2 := TotalPurchLine."Amount Including VAT";
        end;

        SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
        UpdateTaxBreakdown(TempSalesTaxAmtLine, true);

        if Vend.Get(Rec."Pay-to Vendor No.") then
            Vend.CalcFields("Balance (LCY)")
        else
            Clear(Vend);

        TempSalesTaxLine.ModifyAll(Modified, false);
        SetVATSpecification();

        GetVATSpecification();

        OnAfterOnAfterGetRecord(TotalAmount2, TaxAmount);
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
        AllowInvDisc :=
          not (PurchSetup."Calc. Inv. Discount" and VendInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          PurchSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote, Rec."Document Type"::"Blanket Order"]);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
        TaxArea.Get(Rec."Tax Area Code");
        SetVATSpecification();

        OnAfterOnOpenPage(AllowVATDifference);
    end;

    trigger OnClosePage()
    var
        PurchCalcDiscountByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchCalcDiscountByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQueryClosePage(IsHandled);
        if IsHandled then
            exit(true);

        GetVATSpecification();
        if TempSalesTaxLine.GetAnyLineModified() then
            UpdateVATOnPurchLines();
        exit(true);
    end;

    var
        Text000: Label 'Purchase %1 Statistics';
        Text001: Label 'Amount';
        Text002: Label 'Total';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.';
        TotalPurchLine: Record "Purchase Line";
        TotalPurchLineLCY: Record "Purchase Line";
        Vend: Record Vendor;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        PurchSetup: Record "Purchases & Payables Setup";
        TaxArea: Record "Tax Area";
        PurchPost: Codeunit "Purch.-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        TaxAmount: Decimal;
        TaxAmountText: Text[30];
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        BreakdownTitle: Text[35];
        BreakdownLabel: array[4] of Text[30];
        BreakdownAmt: array[4] of Decimal;
        BrkIdx: Integer;
        Text006: Label 'Tax Breakdown:';
        Text007: Label 'Sales Tax Breakdown:';
        Text008: Label 'Other Taxes';

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalAmount1 :=
          TotalPurchLine."Line Amount" - TotalPurchLine."Inv. Discount Amount";
        TaxAmount := TempSalesTaxLine.GetTotalTaxAmountFCY();
        if Rec."Prices Including VAT" then
            TotalAmount2 := TotalPurchLine.Amount
        else
            TotalAmount2 := TotalAmount1 + TaxAmount;

        if Rec."Prices Including VAT" then
            TotalPurchLineLCY.Amount := TotalAmount2
        else
            TotalPurchLineLCY.Amount := TotalAmount1;
        if Rec."Currency Code" <> '' then begin
            if Rec."Document Type" = Rec."Document Type"::Quote then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";
            TotalPurchLineLCY.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, Rec."Currency Code", TotalPurchLineLCY.Amount, Rec."Currency Factor");
        end;
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempTaxAmountLine(TempSalesTaxLine);
        UpdateHeaderInfo();
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
    end;

    local procedure UpdateTotalAmount()
    begin
        CheckAllowInvDisc();
        TotalPurchLine."Inv. Discount Amount" := TotalPurchLine."Line Amount" - TotalAmount1;
        UpdateInvDiscAmount();
    end;

    local procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        InvDiscBaseAmount := TempSalesTaxLine.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003, TempSalesTaxLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalPurchLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalPurchLine.FieldCaption("Inv. Discount Amount"),
              TempSalesTaxLine.FieldCaption("Inv. Disc. Base Amount"));

        TempSalesTaxLine.SetInvoiceDiscountAmount(
          TotalPurchLine."Inv. Discount Amount", Rec."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        UpdateHeaderInfo();

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalPurchLine."Inv. Discount Amount";
        Rec.Modify();
        UpdateVATOnPurchLines();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);

        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateVATOnPurchLines()
    var
        PurchLine: Record "Purchase Line";
    begin
        GetVATSpecification();

        PurchLine.Reset();
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.FindFirst();

        if TempSalesTaxLine.GetAnyLineModified() then begin
            SalesTaxCalculate.StartSalesTaxCalculation();
            SalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine,
              "Sales Tax Document Area"::Purchase.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            OnBeforeDistTaxOverPurchLines(PurchLine);
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

    local procedure UpdateTaxBreakdown(var TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary; UpdateTaxAmount: Boolean)
    var
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
    begin
        Clear(BreakdownLabel);
        Clear(BreakdownAmt);
        BrkIdx := 0;
        PrevPrintOrder := 0;
        PrevTaxPercent := 0;
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
                if UpdateTaxAmount then
                    TaxAmount := TaxAmount + TempSalesTaxAmtLine."Tax Amount"
                else
                    BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + TempSalesTaxAmtLine."Tax Difference";
            until TempSalesTaxAmtLine.Next() = 0;

        OnAfterUpdateTaxBreakdown(TotalAmount2, TaxAmount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQueryClosePage(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDistTaxOverPurchLines(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStartSalesTaxCalculation()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var TotalAmount2: Decimal; var TaxAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateTaxBreakdown(var TotalAmount2: Decimal; var TaxAmount: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var AllowVATDifference: Boolean)
    begin
    end;
}

