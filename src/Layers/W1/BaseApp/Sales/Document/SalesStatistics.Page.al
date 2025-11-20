// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;

#pragma warning disable AS0106 // Protected variables TempVATAmountLinePrep, TempVATAmountLineTot, TempTotVATAmountLinePrep, TempTotVATAmountLineTot were removed before AS0106 was introduced.
page 160 "Sales Statistics"
#pragma warning restore AS0106
{
    Caption = 'Sales Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    SourceTable = "Sales Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Amount; TotalSalesLine."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the net amount of all the lines in the sales document.';
                }
                field(InvDiscountAmount; TotalSalesLine."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';

                    trigger OnValidate()
                    begin
                        if Rec."Document Type" in [Rec."Document Type"::Order, Rec."Document Type"::Invoice] then
                            Rec.TestStatusOpen();
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
                    ToolTip = 'Specifies the total amount less any invoice discount amount and excluding VAT for the sales document.';

                    trigger OnValidate()
                    begin
                        UpdateTotalAmount();
                    end;
                }
                field(VATAmount; VATAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = '3,' + Format(VATAmountText);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the sales document.';
                }
                field(TotalAmount2; TotalAmount2)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Caption = 'Total Incl. VAT';
                    Editable = false;
                    ToolTip = 'Specifies the total amount including VAT that will be posted to the customer''s account for all the lines in the sales document. This is the amount that the customer owes based on this sales document. If the document is a credit memo, it is the amount that you owe to the customer.';
                }
                field("TotalSalesLineLCY.Amount"; TotalSalesLineLCY.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';
                }
                field(ProfitLCY; ProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field(AdjProfitLCY; AdjProfitLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field(ProfitPct; ProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                }
                field(AdjProfitPct; AdjProfitPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of profit for all sales, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalSalesLine.Quantity"; TotalSalesLine.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the sales document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the sales document plus one.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine.""Units per Parcel"""; TotalSalesLine."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine.""Net Weight"""; TotalSalesLine."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine.""Gross Weight"""; TotalSalesLine."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine.""Unit Volume"""; TotalSalesLine."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLineLCY.""Unit Cost (LCY)"""; TotalSalesLineLCY."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the sales document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field(TotalAdjCostLCY; TotalAdjCostLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the sales document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
#pragma warning disable AA0100
                field("TotalAdjCostLCY - TotalSalesLineLCY.""Unit Cost (LCY)"""; TotalAdjCostLCY - TotalSalesLineLCY."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the sales document.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
            }
            part(SubForm; "VAT Specification Subform")
            {
                ApplicationArea = Basic, Suite;
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
                    Editable = false;
                    ToolTip = 'Specifies the balance on the customer''s account.';
                }
#pragma warning disable AA0100
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    Editable = false;
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
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));
        if PrevNo = Rec."No." then begin
            GetVATSpecification();
            exit;
        end;

        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        CalculateTotals();
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
        OnOpenPageOnBeforeSetEditable(AllowInvDisc, AllowVATDifference, Rec, SalesSetup);
        CurrPage.Editable := AllowVATDifference or AllowInvDisc;
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
        if TempVATAmountLine.GetAnyLineModified() then
            UpdateVATOnSalesLines();
        exit(true);
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales %1 Statistics';
#pragma warning restore AA0470
        Text001: Label 'Total';
        Text002: Label 'Amount';
#pragma warning disable AA0470
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because there is a %1 record for %2 %3.', Comment = 'You cannot change the invoice discount because there is a Cust. Invoice Disc. record for Invoice Disc. Code 30000.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        TotalSalesLine: Record "Sales Line";
        TotalSalesLineLCY: Record "Sales Line";
        Cust: Record Customer;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        TotalAmount1: Decimal;
        TotalAmount2: Decimal;
        VATAmountText: Text[30];
        ProfitLCY: Decimal;
        ProfitPct: Decimal;
        AdjProfitLCY: Decimal;
        AdjProfitPct: Decimal;
        TotalAdjCostLCY: Decimal;
        CreditLimitLCYExpendedPct: Decimal;
        PrevNo: Code[20];
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;
        VATAmount: Decimal;

    local procedure UpdateHeaderInfo()
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
    begin
        TotalSalesLine."Inv. Discount Amount" := TempVATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1 :=
          TotalSalesLine."Line Amount" - TotalSalesLine."Inv. Discount Amount";
        VATAmount := TempVATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1 := TempVATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2 := TotalAmount1 - VATAmount;
            TotalSalesLine."Line Amount" := TotalAmount1 + TotalSalesLine."Inv. Discount Amount";
        end else
            TotalAmount2 := TotalAmount1 + VATAmount;

        if Rec."Prices Including VAT" then
            TotalSalesLineLCY.Amount := TotalAmount2
        else
            TotalSalesLineLCY.Amount := TotalAmount1;
        if Rec."Currency Code" <> '' then begin
            if (Rec."Document Type" in [Rec."Document Type"::"Blanket Order", Rec."Document Type"::Quote]) and
               (Rec."Posting Date" = 0D)
            then
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

        AdjProfitLCY := TotalSalesLineLCY.Amount - TotalAdjCostLCY;
        if TotalSalesLineLCY.Amount = 0 then
            AdjProfitPct := 0
        else
            AdjProfitPct := Round(100 * AdjProfitLCY / TotalSalesLineLCY.Amount, 0.01);

        OnAfterUpdateHeaderInfo(TotalSalesLineLCY, TotalAmount1, TotalAmount2);
    end;

    local procedure GetVATSpecification()
    begin
        CurrPage.SubForm.PAGE.GetTempVATAmountLine(TempVATAmountLine);
        if TempVATAmountLine.GetAnyLineModified() then
            UpdateHeaderInfo();
    end;

    local procedure SetVATSpecification()
    begin
        CurrPage.Subform.PAGE.SetSourceHeader(Rec);
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        CurrPage.SubForm.PAGE.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
    end;

    protected procedure UpdateTotalAmount()
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

    protected procedure UpdateInvDiscAmount()
    var
        InvDiscBaseAmount: Decimal;
    begin
        CheckAllowInvDisc();
        InvDiscBaseAmount := TempVATAmountLine.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");
        if InvDiscBaseAmount = 0 then
            Error(Text003, TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        if TotalSalesLine."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalSalesLine.FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine.FieldCaption("Inv. Disc. Base Amount"));

        TempVATAmountLine.SetInvoiceDiscountAmount(
          TotalSalesLine."Inv. Discount Amount", Rec."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");
        CurrPage.SubForm.PAGE.SetTempVATAmountLine(TempVATAmountLine);
        UpdateHeaderInfo();

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalSalesLine."Inv. Discount Amount";
        Rec.Modify();
        UpdateVATOnSalesLines();
    end;

    protected procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);

        exit('2,0,' + FieldCaption);
    end;

    procedure UpdateVATOnSalesLines()
    var
        SalesLine: Record "Sales Line";
    begin
        GetVATSpecification();
        if TempVATAmountLine.GetAnyLineModified() then begin
            SalesLine.UpdateVATOnLines(0, Rec, SalesLine, TempVATAmountLine);
            SalesLine.UpdateVATOnLines(1, Rec, SalesLine, TempVATAmountLine);
        end;
        PrevNo := '';
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst());
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

    local procedure CalculateTotals()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        Clear(SalesLine);
        Clear(TotalSalesLine);
        Clear(TotalSalesLineLCY);
        Clear(SalesPost);

        SalesPost.GetSalesLines(Rec, TempSalesLine, 0, true, true);
        OnCalculateTotalsOnAfterGetSalesLines(Rec, TempSalesLine);
        Clear(SalesPost);
        SalesPost.SumSalesLinesTemp(
          Rec, TempSalesLine, 0, TotalSalesLine, TotalSalesLineLCY,
          VATAmount, VATAmountText, ProfitLCY, ProfitPct, TotalAdjCostLCY, true, true);

        AdjProfitLCY := TotalSalesLineLCY.Amount - TotalAdjCostLCY;
        if TotalSalesLineLCY.Amount <> 0 then
            AdjProfitPct := Round(AdjProfitLCY / TotalSalesLineLCY.Amount * 100, 0.1);

        if Rec."Prices Including VAT" then begin
            TotalAmount2 := TotalSalesLine.Amount;
            TotalAmount1 := TotalAmount2 + VATAmount;
            TotalSalesLine."Line Amount" := TotalAmount1 + TotalSalesLine."Inv. Discount Amount";
        end else begin
            TotalAmount1 := TotalSalesLine.Amount;
            TotalAmount2 := TotalSalesLine."Amount Including VAT";
        end;

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

        SalesLine.CalcVATAmountLines(0, Rec, TempSalesLine, TempVATAmountLine);
        TempVATAmountLine.ModifyAll(Modified, false);
        SetVATSpecification();

        OnAfterCalculateTotals(Rec, TotalSalesLine, TotalSalesLineLCY, TempVATAmountLine, TotalAmount1, TotalAmount2);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalculateTotals(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var TempVATAmountLine: Record "VAT Amount Line" temporary; var TotalAmt1: Decimal; var TotalAmt2: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(TotalSalesLineLCY: Record "Sales Line"; var TotalAmount1: Decimal; var TotalAmount2: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateTotalsOnAfterGetSalesLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetEditable(var AllowInvDisc: Boolean; var AllowVATDifference: Boolean; SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup")
    begin
    end;
}
