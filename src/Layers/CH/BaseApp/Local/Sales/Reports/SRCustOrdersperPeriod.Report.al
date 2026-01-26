// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;

report 11535 "SR Cust. Orders per Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustOrdersperPeriod.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Orders per Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterCustFilter; Text003 + CustFilter)
            {
            }
            column(KeyDatePeriodStartDate; Text004 + Format(PeriodStartDate[1]))
            {
            }
            column(AmtFilterTxt; AmtFilterTxt)
            {
            }
            column(PrevDayOfPeriodStartDt4; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PrevDayOfPeriodStartDt3; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PrevDayOfPeriodStartDt2; Format(PeriodStartDate[2] - 1))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(SaleAmtInOrderLCY1; SaleAmtInOrderLCY[1])
            {
                AutoFormatType = 1;
            }
            column(SaleAmtInOrderLCY2; SaleAmtInOrderLCY[2])
            {
                AutoFormatType = 1;
            }
            column(SaleAmtInOrderLCY3; SaleAmtInOrderLCY[3])
            {
                AutoFormatType = 1;
            }
            column(SaleAmtInOrderLCY4; SaleAmtInOrderLCY[4])
            {
                AutoFormatType = 1;
            }
            column(SaleAmtInOrderLCY5; SaleAmtInOrderLCY[5])
            {
                AutoFormatType = 1;
            }
            column(OrderAmtLCY; OrderAmtLCY)
            {
                AutoFormatType = 1;
            }
            column(CustomerOrdersPerPeriodCaption; CustomerOrdersPerPeriodCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(CustomerCaption; CustomerCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
            }
            column(No_Customer; "No.")
            {
            }
            column(GlobalDimension1Filter_Customer; "Global Dimension 1 Filter")
            {
            }
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Bill-to Customer No." = field("No."), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Currency Code" = field("Currency Filter");
                DataItemTableView = sorting("Document Type", "Bill-to Customer No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(CurrencyCode_SalesLine; "Currency Code")
                {
                }
                column(OrderAmt; OrderAmt)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SaleAmtInOrder5; SaleAmtInOrder[5])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SaleAmtInOrder4; SaleAmtInOrder[4])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SaleAmtInOrder3; SaleAmtInOrder[3])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SaleAmtInOrder2; SaleAmtInOrder[2])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SaleAmtInOrder1; SaleAmtInOrder[1])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CustomerName; Customer.Name)
                {
                }
                column(CustomerNo; Customer."No.")
                {
                }
                column(ShowAmtInLCY; ShowAmtInLCY)
                {
                }
                column(SalesLineSaleAmtInOrderLCY1; SaleAmtInOrderLCY[1])
                {
                    AutoFormatType = 1;
                }
                column(SalesLineSaleAmtInOrderLCY2; SaleAmtInOrderLCY[2])
                {
                    AutoFormatType = 1;
                }
                column(SalesLineSaleAmtInOrderLCY3; SaleAmtInOrderLCY[3])
                {
                    AutoFormatType = 1;
                }
                column(SalesLineSaleAmtInOrderLCY4; SaleAmtInOrderLCY[4])
                {
                    AutoFormatType = 1;
                }
                column(SalesLineSaleAmtInOrderLCY5; SaleAmtInOrderLCY[5])
                {
                    AutoFormatType = 1;
                }
                column(SalesLineOrderAmtLCY; OrderAmtLCY)
                {
                    AutoFormatType = 1;
                }
                column(DocumentNo_SalesLine; "Document No.")
                {
                }
                column(BilltoCustomerNo_SalesLine; "Bill-to Customer No.")
                {
                }
                column(ShortcutDimension1Code_SalesLine; "Shortcut Dimension 1 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PeriodNo := 1;
                    while "Shipment Date" >= PeriodStartDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    SalesHeader.Get("Document Type", "Document No.");
                    if "Currency Code" <> '' then
                        Currency.Get("Currency Code")
                    else
                        Currency.InitRoundingPrecision();

                    OrderAmt := "Line Amount" - GetInvDisc();
                    if SalesHeader."Prices Including VAT" then
                        OrderAmt := Round(OrderAmt / (100 + "Sales Line"."VAT %") * 100, Currency."Amount Rounding Precision");
                    OrderAmt := Round(OrderAmt * "Outstanding Quantity" / Quantity, Currency."Amount Rounding Precision");
                    OrderAmtLCY := OrderAmt;

                    if "Currency Code" <> '' then
                        if SalesHeader."Currency Factor" <> 0 then
                            OrderAmtLCY := Round(CurrExRate.ExchangeAmtFCYToLCY
                                (WorkDate(), "Currency Code", OrderAmt, SalesHeader."Currency Factor"));

                    SaleAmtInOrder[PeriodNo] := OrderAmt;
                    SaleAmtInOrderLCY[PeriodNo] := OrderAmtLCY;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(OrderAmtLCY);
                    Clear(SaleAmtInOrderLCY);
                    Clear(OrderAmt);
                    Clear(SaleAmtInOrder);
                end;
            }

            trigger OnPreDataItem()
            begin
                Clear(OrderAmtLCY);
                Clear(SaleAmtInOrderLCY);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Start Date"; PeriodStartDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field("Period Length"; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(ShowAmtInLCY; ShowAmtInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := WorkDate();

            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CustFilter := Customer.GetFilters();

        SalesSetup.Get();
        GLSetup.Get();

        if ShowAmtInLCY then
            AmtFilterTxt := StrSubstNo(Text000, GLSetup."LCY Code")
        else
            AmtFilterTxt := Text001;

        if Format(PeriodLength) = '' then
            Error(Text002);

        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLength, PeriodStartDate[i]);
        PeriodStartDate[5] := 99991231D;
    end;

    var
        Text000: Label 'All amounts without VAT in %1.';
        Text001: Label 'Amounts without VAT in Currency of Customer';
        Text002: Label 'The period length is not defined.';
        Text003: Label 'Filter: ';
        Text004: Label 'Key Date: ';
        CurrExRate: Record "Currency Exchange Rate";
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CustFilter: Text[250];
        OrderAmt: Decimal;
        OrderAmtLCY: Decimal;
        AmtFilterTxt: Text[100];
        PeriodLength: DateFormula;
        PeriodStartDate: array[5] of Date;
        SaleAmtInOrderLCY: array[5] of Decimal;
        ShowAmtInLCY: Boolean;
        PeriodNo: Integer;
        SaleAmtInOrder: array[5] of Decimal;
        i: Integer;
        CustomerOrdersPerPeriodCaptionLbl: Label 'Customer Orders per Period';
        PageCaptionLbl: Label 'Page';
        TotalCaptionLbl: Label 'Total';
        AfterCaptionLbl: Label 'after';
        BeforeCaptionLbl: Label 'before';
        CustomerCaptionLbl: Label 'Customer';
        NumberCaptionLbl: Label 'Number';
        TotalLCYCaptionLbl: Label 'Total LCY';

    [Scope('OnPrem')]
    procedure GetInvDisc(): Decimal
    var
        Salesline2: Record "Sales Line" temporary;
        SalesPost: Codeunit "Sales-Post";
        SalesCalcDisc: Codeunit "Sales-Calc. Discount";
    begin
        if "Sales Line"."Allow Invoice Disc." and SalesSetup."Calc. Inv. Discount" then begin
            Salesline2.SetHideValidationDialog(true);
            SalesPost.GetSalesLines(SalesHeader, Salesline2, 0);
            SalesCalcDisc.CalculateWithSalesHeader(SalesHeader, Salesline2);
            Salesline2.Get("Sales Line"."Document Type", "Sales Line"."Document No.", "Sales Line"."Line No.");
            exit(Salesline2."Inv. Discount Amount");
        end;
    end;
}

