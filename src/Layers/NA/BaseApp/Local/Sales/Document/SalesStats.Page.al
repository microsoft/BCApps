// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.SalesTax;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;

page 10042 "Sales Stats."
{
    Caption = 'Sales Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Sales Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("TotalSalesLine.""Line Amount"""; TotalSalesLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines on the sales document.';
                }
                field("TotalSalesLine.""Inv. Discount Amount"""; TotalSalesLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';

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
                    CaptionClass = GetCaptionClass(Text001, false);
                    Caption = 'Total';
                    Editable = false;
                    ToolTip = 'Specifies the total amount less any invoice discount amount (excluding tax) for the sales document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount();
                    end;
                }
                field(TaxAmount; TaxAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Tax Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total tax amount that has been calculated for all the lines in the sales document.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. Tax';
                    Editable = false;
                    ToolTip = 'Specifies the total amount including tax that will be posted to the customer''s account for all the lines in the sales document. This is the amount that the customer owes based on this sales document. If the document is a credit memo, it is the amount that you owe to the customer.';
                }
                field("TotalSalesLineLCY.Amount"; TotalSalesLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales ($)';
                    Editable = false;
                    ToolTip = 'Specifies your total sales turnover in the fiscal year. It is calculated from amounts excluding tax on all completed and open sales invoices and credit memos.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit ($)';
                    Editable = false;
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the original profit percentage that was associated with the sales when they were originally posted.';
                }
                field("TotalSalesLine.Quantity"; TotalSalesLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the sales document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the sales document plus one.';
                }
                field("TotalSalesLine.""Units per Parcel"""; TotalSalesLine."Units per Parcel")
                {
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the number of parcels on the document.';
                }
                field("TotalSalesLine.""Net Weight"""; TotalSalesLine."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
                field("TotalSalesLine.""Gross Weight"""; TotalSalesLine."Gross Weight")
                {
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of items listed on the document.';
                }
                field("TotalSalesLine.""Unit Volume"""; TotalSalesLine."Unit Volume")
                {
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the volume of the items in the sales order.';
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
            group(Customer)
            {
                Caption = 'Customer';
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance ($)';
                    Editable = false;
                    ToolTip = 'Specifies the customer''s balance. ';
                }
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit ($)';
                    Editable = false;
                    ToolTip = 'Specifies the credit limit in dollars of the customer on the sales document. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit ($)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the Expended Percentage of Credit Limit ($).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));
        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);
        Clear(SalesLine);
        Clear(TotalSalesLine);
        Clear(TotalSalesLineLCY);
        Clear(SalesPost);
        Clear(TaxAmount);
        SalesTaxCalculate.StartSalesTaxCalculation();
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."No.");
        SalesLine.SetFilter(Type, '>0');
        SalesLine.SetFilter(Quantity, '<>0');
        if SalesLine.Find('-') then
            repeat
                TempSalesLine.Copy(SalesLine);
                TempSalesLine.Insert();
                if not TaxArea."Use External Tax Engine" then
                    SalesTaxCalculate.AddSalesLine(TempSalesLine);
            until SalesLine.Next() = 0;
        TempSalesTaxLine.DeleteAll();

        OnBeforeCalculateSalesTaxSalesStats(Rec, TempSalesTaxLine, TempSalesTaxAmtLine, SalesTaxCalculationOverridden);

        if not SalesTaxCalculationOverridden then begin
            if TaxArea."Use External Tax Engine" then
                SalesTaxCalculate.CallExternalTaxEngineForSales(Rec, true)
            else
                SalesTaxCalculate.EndSalesTaxCalculation(Rec."Posting Date");

            SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxLine);
            SalesTaxCalculate.DistTaxOverSalesLines(TempSalesLine);
        end;

        SalesPost.SumSalesLinesTemp(
          Rec, TempSalesLine, 0, TotalSalesLine, TotalSalesLineLCY,
          TaxAmount, TaxAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY);

        if Rec."Prices Including VAT" then begin
            TotalAmount2 := TotalSalesLine.Amount;
            TotalAmount1 := TotalAmount2 + TaxAmount;
            TotalSalesLine."Line Amount" := TotalAmount1 + TotalSalesLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalSalesLine.Amount;
            TotalAmount2 := TotalSalesLine."Amount Including VAT";
        end;

        if not SalesTaxCalculationOverridden then
            SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
        UpdateTaxBreakdown(TempSalesTaxAmtLine, true);
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

        TempSalesTaxLine.ModifyAll(Modified, false);
        SetVATSpecification();
        OnActivateForm();
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
        SalesSetup.Get();
        AllowInvDisc :=
          not (SalesSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          SalesSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote, Rec."Document Type"::"Blanket Order"]);
        CurrPage.Editable :=
          AllowVATDifference or AllowInvDisc;
        TaxArea.Get(Rec."Tax Area Code");
        SetVATSpecification();
    end;

    trigger OnClosePage()
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        GetVATSpecification();
        if TempSalesTaxLine.GetAnyLineModified() then
            UpdateVATOnSalesLines();
        exit(true);
    end;

    var
        Text000: Label 'Sales %1 Statistics';
        Text001: Label 'Total';
        Text002: Label 'Amount';
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.';
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        Cust: Record Customer;
        TempSalesTaxLine: Record "Sales Tax Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        TaxArea: Record "Tax Area";
        SalesTaxDifference: Record "Sales Tax Amount Difference";
        SalesPost: Codeunit "Sales-Post";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        TaxAmount: Decimal;
        TaxAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
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
        SalesTaxCalculationOverridden: Boolean;

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalAmount1 :=
          TotalSalesLine."Line Amount" - TotalSalesLine."Inv. Discount Amount";
        if not SalesTaxCalculationOverridden then
            TaxAmount := TempSalesTaxLine.GetTotalTaxAmountFCY();
        if Rec."Prices Including VAT" then
            TotalAmount2 := TotalSalesLine.Amount
        else
            TotalAmount2 := TotalAmount1 + TaxAmount;

        OnUpdateHeaderInfoOnAfterCalcTotalAmount(Rec, TotalAmount1, TotalAmount2, TaxAmount);

        if Rec."Prices Including VAT" then
            TotalSalesLineLCY.Amount := TotalAmount2
        else
            TotalSalesLineLCY.Amount := TotalAmount1;
        if Rec."Currency Code" <> '' then begin
            if Rec."Document Type" = Rec."Document Type"::Quote then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";
            TotalSalesLineLCY.Amount :=
              CurrExchRate.ExchangeAmtFCYToLCY(
                UseDate, Rec."Currency Code", TotalSalesLineLCY.Amount, Rec."Currency Factor");
        end;
        ProfitLCY := TotalSalesLineLCY.Amount - TotalSalesLineLCY."Unit Cost (LCY)";
        if TotalSalesLineLCY.Amount = 0 then
            ProfitPct := 0
        else
            ProfitPct := Round(100 * ProfitLCY / TotalSalesLineLCY.Amount, 0.01);
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
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1;
            UpdateInvDiscAmount();
            TotalAmount1 := SaveTotalAmount;
        end;
        TotalSalesLine."Inv. Discount Amount" := TotalSalesLine."Line Amount" - TotalAmount1;
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

        if TotalSalesLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalSalesLine.FieldCaption("Inv. Discount Amount"),
              TempSalesTaxLine.FieldCaption("Inv. Disc. Base Amount"));

        TempSalesTaxLine.SetInvoiceDiscountAmount(
          TotalSalesLine."Inv. Discount Amount", Rec."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");
        CurrPage.SubForm.PAGE.SetTempTaxAmountLine(TempSalesTaxLine);
        UpdateHeaderInfo();

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalSalesLine."Inv. Discount Amount";
        Rec.Modify();
        UpdateVATOnSalesLines();
    end;

    local procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);

        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateVATOnSalesLines()
    var
        SalesLine: Record "Sales Line";
    begin
        GetVATSpecification();

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", Rec."Document Type");
        SalesLine.SetRange("Document No.", Rec."No.");
        SalesLine.FindFirst();

        if TempSalesTaxLine.GetAnyLineModified() then begin
            SalesTaxCalculate.StartSalesTaxCalculation();
            SalesTaxCalculate.PutSalesTaxAmountLineTable(
              TempSalesTaxLine,
              SalesTaxDifference."Document Product Area"::Sales.AsInteger(),
              Rec."Document Type".AsInteger(), Rec."No.");
            SalesTaxCalculate.DistTaxOverSalesLines(SalesLine);
            SalesTaxCalculate.SaveTaxDifferences();
        end;

        PrevNo := '';
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst())
    end;

    local procedure CheckAllowInvDisc()
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        if not AllowInvDisc then
            Error(
              Text005,
              CustInvDisc.TableCaption(), Rec.FieldCaption("Invoice Disc. Code"), Rec."Invoice Disc. Code");
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
    end;

    local procedure OnActivateForm()
    begin
        if Rec."No." = PrevNo then
            GetVATSpecification();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxSalesStats(var SalesHeader: Record "Sales Header"; var SalesTaxAmountLine: Record "Sales Tax Amount Line"; var SalesTaxAmountLine2: Record "Sales Tax Amount Line"; var SalesTaxCalculationOverridden: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHeaderInfoOnAfterCalcTotalAmount(SalesHeader: Record "Sales Header"; TotalAmount1: Decimal; var TotalAmount2: Decimal; TaxAmount: Decimal)
    begin
    end;
}
