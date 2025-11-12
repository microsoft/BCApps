// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Utilities;

report 107 "Customer - Order Summary"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer - Order Summary';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = Word;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Customer Posting Group", "Currency Filter";
#if not CLEAN27
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            column(PrintAmountsInLCY; PrintAmountsInLCY)
            {
            }
            column(CustFilter; CustFilterTxt)
            {
            }
            column(CustFilter1; CustFilter)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1]))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(SalesAmtOnOrderLCY1; SalesAmtOnOrderLCY[1])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY2; SalesAmtOnOrderLCY[2])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY3; SalesAmtOnOrderLCY[3])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY4; SalesAmtOnOrderLCY[4])
            {
                AutoFormatType = 1;
            }
            column(SalesAmtOnOrderLCY5; SalesAmtOnOrderLCY[5])
            {
                AutoFormatType = 1;
            }
            column(SalesOrderAmountLCY; SalesOrderAmountLCY)
            {
                AutoFormatType = 1;
            }
            column(No_Cust; "No.")
            {
            }
            column(AllAmountsAreInLCYTxt; AllAmountsAreInLCYTxt)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
#if not CLEAN27
            column(CustomerOrderSummaryCaption; CustomerOrderSummaryCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(OutstandingOrdersCaption; OutstandingOrdersCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustomerNoCaption; CustomerNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(CustomerNameCaption; CustomerNameCap)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(AfterCaption; AfterCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
            column(TotalLCYCaption; TotalLCYCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '27.0';
            }
#endif
            dataitem("Sales Line"; "Sales Line")
            {
                DataItemLink = "Bill-to Customer No." = field("No."), "Shortcut Dimension 1 Code" = field("Global Dimension 1 Filter"), "Shortcut Dimension 2 Code" = field("Global Dimension 2 Filter"), "Currency Code" = field("Currency Filter");
                DataItemTableView = sorting("Document Type", "Bill-to Customer No.", "Currency Code") where("Document Type" = const(Order), "Outstanding Quantity" = filter(<> 0));
                column(SalesOrderAmount; SalesOrderAmount)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder5; SalesAmtOnOrder[5])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder4; SalesAmtOnOrder[4])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder3; SalesAmtOnOrder[3])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder2; SalesAmtOnOrder[2])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(SalesAmtOnOrder1; SalesAmtOnOrder[1])
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrencyCode_SalesLine; "Currency Code")
                {
                    IncludeCaption = true;
                }
                column(Name_Cust; Customer.Name)
                {
                    IncludeCaption = true;
                }
                column(SalesLineBilltoNo_Customer; "Bill-to Customer No.")
                {
                    IncludeCaption = true;
                }
                column(GroupNumber; GroupNumber)
                {
                }
                trigger OnAfterGetRecord()
                begin
                    PeriodNo := 1;
                    while "Shipment Date" >= PeriodStartDate[PeriodNo] do
                        PeriodNo := PeriodNo + 1;

                    Currency.InitRoundingPrecision();
                    if "VAT Calculation Type" in ["VAT Calculation Type"::"Normal VAT", "VAT Calculation Type"::"Reverse Charge VAT"] then
                        SalesOrderAmount :=
                          Round(
                            (Amount + "VAT Base Amount" * "VAT %" / 100) * "Outstanding Quantity" / Quantity / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision")
                    else
                        SalesOrderAmount :=
                          Round(
                            "Outstanding Amount" / (1 + "VAT %" / 100),
                            Currency."Amount Rounding Precision");
                    SalesOrderAmountLCY := SalesOrderAmount;

                    for i := 1 to ArrayLen(SalesAmtOnOrder) do begin
                        SalesAmtOnOrder[i] := 0;
                        SalesAmtOnOrderLCY[i] := 0;
                    end;

                    if "Currency Code" <> '' then begin
                        SalesHeader.Get(1, "Document No.");
                        if SalesHeader."Currency Factor" <> 0 then
                            SalesOrderAmountLCY :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToLCY(
                                  WorkDate(), SalesHeader."Currency Code",
                                  SalesOrderAmount, SalesHeader."Currency Factor"));
                    end;

                    SalesAmtOnOrder[PeriodNo] := SalesOrderAmount;
                    SalesAmtOnOrderLCY[PeriodNo] := SalesOrderAmountLCY;

                    if NewCustomer then begin
                        GroupNumber += 1;
                        GroupNumberChanged := true;
                    end else
                        if not PrintAmountsInLCY and ("Currency Code" <> LastCurrencyCode) then begin
                            GroupNumber += 1;
                            GroupNumberChanged := true;
                        end;

                    if GroupNumberChanged then begin
                        SalesOrderAmountLCY1 := 0;
                        clear(SalesAmtOnOrderLCY1);
                        SalesOrderAmount1 := 0;
                        clear(SalesAmtOnOrder1);
                    end;

                    SalesOrderAmount1 += SalesOrderAmount;
                    SalesOrderAmountLCY1 += SalesOrderAmountLCY;
                    SalesAmtOnOrder1[PeriodNo] += SalesAmtOnOrder[PeriodNo];
                    SalesAmtOnOrderLCY1[PeriodNo] += SalesAmtOnOrderLCY[PeriodNo];
                    if PrintAmountsInLCY then begin
                        InsertModifyTempSalesLine(TempSalesLine, SalesAmtOnOrderLCY1, PrintAmountsInLCY);
                        TotalText := TotalLCYCaptionLbl;
                    end else begin
                        InsertModifyTempSalesLine(TempSalesLine, SalesAmtOnOrder1, PrintAmountsInLCY);
                        TotalText := TotalCaptionLbl;
                    end;
                    InsertModifyTempSalesLine(TempTotalSalesLine, SalesAmtOnOrderLCY1, true);
                    NewCustomer := false;
                    GroupNumberChanged := false;
                    LastCurrencyCode := "Currency Code";
                end;
            }
            trigger OnAfterGetRecord()
            begin
                NewCustomer := true;
                GroupNumberChanged := true;
                LineNo := 0;
            end;

            trigger OnPreDataItem()
            begin
                ClearAmounts();
            end;
        }

        dataitem(SalesLineBuffer_Integer; Integer)
        {
            DataItemTableView = sorting(Number);
            column(Number; Number)
            {
            }
            column(SalesLineBuffer_BilltoCustomerNo; TempSalesLine."Bill-to Customer No.")
            {
            }
            column(SalesLineBuffer_CustomerName; TempSalesLine.Description)
            {
            }
            column(SalesLineBuffer_CurrencyCode; TempSalesLine."Currency Code")
            {
            }
            column(SalesLineBuffer_SalesOrderAmount; TempSalesLine.Amount)
            {
                AutoFormatType = 1;
            }
            column(SalesLineBuffer_SalesAmtOnOrder1; TempSalesLine."Unit Price")
            {
                AutoFormatType = 1;
            }
            column(SalesLineBuffer_SalesAmtOnOrder2; TempSalesLine."Unit Cost")
            {
                AutoFormatType = 1;
            }
            column(SalesLineBuffer_SalesAmtOnOrder3; TempSalesLine."Outstanding Amount")
            {
                AutoFormatType = 1;
            }
            column(SalesLineBuffer_SalesAmtOnOrder4; TempSalesLine."Amount Including VAT")
            {
                AutoFormatType = 1;
            }
            column(SalesLineBuffer_SalesAmtOnOrder5; TempSalesLine."Line Amount")
            {
                AutoFormatType = 1;
            }
            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempSalesLine.FindFirst()
                else
                    TempSalesLine.Next();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, TempSalesLine.Count());
            end;
        }
        dataitem(Totals; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Totals_Sales_Order_Amount; TotalSalesOrderAmount)
            {
                AutoFormatType = 1;
            }
            column(Totals_Sales_Amt_On_Order1; TotalSalesAmtOnOrder[1])
            {
                AutoFormatType = 1;
            }
            column(Totals_Sales_Amt_On_Order2; TotalSalesAmtOnOrder[2])
            {
                AutoFormatType = 1;
            }
            column(Totals_Sales_Amt_On_Order3; TotalSalesAmtOnOrder[3])
            {
                AutoFormatType = 1;
            }
            column(Totals_Sales_Amt_On_Order4; TotalSalesAmtOnOrder[4])
            {
                AutoFormatType = 1;
            }
            column(Totals_Sales_Amt_On_Order5; TotalSalesAmtOnOrder[5])
            {
                AutoFormatType = 1;
            }
            column(Totals_TotalText; TotalText)
            {
            }
            trigger OnPreDataItem()
            begin
                TempTotalSalesLine.Reset();
                TempTotalSalesLine.CalcSums(Amount, "Unit Price", "Unit Cost", "Outstanding Amount", "Amount Including VAT", "Line Amount");
                TotalSalesOrderAmount := TempTotalSalesLine.Amount;
                TotalSalesAmtOnOrder[1] := TempTotalSalesLine."Unit Price";
                TotalSalesAmtOnOrder[2] := TempTotalSalesLine."Unit Cost";
                TotalSalesAmtOnOrder[3] := TempTotalSalesLine."Outstanding Amount";
                TotalSalesAmtOnOrder[4] := TempTotalSalesLine."Amount Including VAT";
                TotalSalesAmtOnOrder[5] := TempTotalSalesLine."Line Amount";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Customer - Order Summary';
        AboutText = 'Analyse your nonshipped orders in order to understand your expected sales volume. See order details with the quantity not yet shipped for each customer in three periods of 30 days each, starting from the specified date.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShwAmtinLCY; PrintAmountsInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if the reported amounts are shown in the local currency.';
                    }
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    // Used to set the date filter on the report header across multiple languages
                    field(RequestPeriod1Text; Period1Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 1';
                        ToolTip = 'Specifies Period 1 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod2Text; Period2Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 2';
                        ToolTip = 'Specifies Period 2 on this report.';
                        Visible = false;
                    }
                    field(RequestPeriod3Text; Period3Text)
                    {
                        ApplicationArea = All;
                        Caption = 'Period 3';
                        ToolTip = 'Specifies Period 3 on this report.';
                        Visible = false;
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
        end;

        trigger OnClosePage()
        begin
            for i := 1 to 3 do
                PeriodStartDate[i + 1] := CalcDate('<1M>', PeriodStartDate[i]);
            PeriodStartDate[5] := DMY2Date(31, 12, 9999);
            UpdateRequestPageFilterValues();
        end;
    }
    rendering
    {
        layout(Excel)
        {
            Caption = 'Customer Order Summary Excel';
            LayoutFile = '.\Sales\Reports\CustomerOrderSummary.xlsx';
            Type = Excel;
            Summary = 'Built in layout for the Customer Order Summary excel report.';
        }
        layout(Word)
        {
            Caption = 'Customer Order Summary Word';
            LayoutFile = '.\Sales\Reports\CustomerOrderSummary.docx';
            Type = Word;
            Summary = 'Built in layout for the Customer Order Summary word report.';
        }
#if not CLEAN27
        layout(RDLC)
        {
            Caption = 'Customer Order Summary RDLC';
            Type = RDLC;
            LayoutFile = '.\Sales\Reports\CustomerOrderSummary.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel and Word layouts and will be removed in a future release.';
            ObsoleteTag = '27.0';
        }
#endif
    }
    labels
    {
        DataRetrieved = 'Data retrieved:';
        CustomerOrderSummary = 'Customer Order Summary';
        CustOrderSummaryLCYPrint = 'Cust. Order Summary LCY (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CustomerOrderSummaryPrint = 'Customer Order Summary (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CustomerOrderSummaryAnalysis = 'Cust. Order Summary (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        PostingDateFilterLabel = 'Posting Date Filter:';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
        StartingDateLbl = 'Starting Date';
        BeforeLbl = '...before (LCY)';
        Before1Lbl = '...before';
        AfterLbl = 'after (LCY)...';
        After1Lbl = 'after...';
        OutstandingOrdersLbl = 'Outstanding Orders';
        CustomerNoLbl = 'Customer No.';
        CustomerNameLbl = 'Customer Name';
        Period2StartDateLbl = 'Period 2 Start Date';
        Period2EndDateLbl = 'Period 2 End Date';
        Period3StartDateLbl = 'Period 3 Start Date';
        Period3EndDateLbl = 'Period 3 End Date';
        Period4StartDateLbl = 'Period 4 Start Date';
        Period4EndDateLbl = 'Period 4 End Date';
        SalesAmtOnOrderLCY2Lbl = 'Sales Amt. on Order (LCY) for Period 2';
        SalesAmtOnOrder2Lbl = 'Sales Amt. on Order for Period 2';
        SalesAmtOnOrderLCY3Lbl = 'Sales Amt. on Order (LCY) for Period 3';
        SalesAmtOnOrder3Lbl = 'Sales Amt. on Order for Period 3';
        SalesAmtOnOrderLCY4Lbl = 'Sales Amt. on Order (LCY) for Period 4';
        SalesAmtOnOrder4Lbl = 'Sales Amt. on Order for Period 4';
        TotalCaptionLbl = 'Total';
        TotalLCYCaptionLbl = 'Total (LCY)';
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
        if CustFilter <> '' then
            CustFilterTxt := Customer.TableCaption + ': ' + CustFilter;
        if not PrintAmountsInLCY then begin
            AllAmountsAreInLCYTxt := '';
            Currency.SetFilter(Code, Customer.GetFilter("Currency Filter"));
            if Currency.Count = 1 then
                Currency.FindFirst();
        end else
            AllAmountsAreInLCYTxt := AllAmountsAreInLCYCaptionLbl;

        if PeriodStartDate[1] = 0D then
            PeriodStartDate[1] := WorkDate();
        for i := 1 to 3 do
            PeriodStartDate[i + 1] := CalcDate('<1M>', PeriodStartDate[i]);
        PeriodStartDate[5] := DMY2Date(31, 12, 9999);
        UpdateRequestPageFilterValues();
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        TempSalesLine: Record "Sales Line" temporary;
        TempTotalSalesLine: Record "Sales Line" temporary;
        CustFilter: Text;
        CustFilterTxt: Text;
        SalesOrderAmount: Decimal;
        SalesOrderAmountLCY: Decimal;
        SalesOrderAmount1: Decimal;
        SalesOrderAmountLCY1: Decimal;
        TotalSalesOrderAmount: Decimal;
        TotalSalesAmtOnOrder: array[5] of Decimal;
        PeriodStartDate: array[5] of Date;
        PrintAmountsInLCY: Boolean;
        AllAmountsAreInLCYTxt: Text;
        Period1Text: Text;
        Period2Text: Text;
        Period3Text: Text;
        TotalText: Text;
        i: Integer;
        GroupNumber: Integer;
        LineNo: Integer;
        NewCustomer: Boolean;
        GroupNumberChanged: Boolean;
        LastCurrencyCode: Code[10];
        AllAmountsAreInLCYCaptionLbl: Label 'All amounts are in LCY';
        TotalCaptionLbl: Label 'Total';
        TotalLCYCaptionLbl: Label 'Total (LCY)';

    protected var
        SalesAmtOnOrderLCY: array[5] of Decimal;
        SalesAmtOnOrderLCY1: array[5] of Decimal;
        PeriodNo: Integer;
        SalesAmtOnOrder: array[5] of Decimal;
        SalesAmtOnOrder1: array[5] of Decimal;

#if not CLEAN27    
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CustomerOrderSummaryCaptionLbl: Label 'Customer - Order Summary';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        PageNoCaptionLbl: Label 'Page';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        OutstandingOrdersCaptionLbl: Label 'Outstanding Orders';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CustomerNoCaptionLbl: Label 'Customer No.';
#pragma warning disable AA0074
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        CustomerNameCap: Label 'Name';
#pragma warning restore AA0074
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        BeforeCaptionLbl: Label '...before';
        [Obsolete('RDLC Only layout field caption. To be removed along with the RDLC layout', '27.0')]
        AfterCaptionLbl: Label 'after...';
#endif
    procedure InitializeRequest(StartingDate: Date; ShowAmountInLCY: Boolean)
    begin
        PeriodStartDate[1] := StartingDate;
        PrintAmountsInLCY := ShowAmountInLCY;
    end;

    local procedure ClearAmounts()
    begin
        Clear(SalesOrderAmountLCY);
        Clear(SalesAmtOnOrderLCY);
        Clear(SalesOrderAmount);
        Clear(SalesAmtOnOrder);
    end;
    // Ensures Layout Filter Headings are up to date
    local procedure UpdateRequestPageFilterValues()
    begin
        Period1Text := Format(PeriodStartDate[1]) + '..' + Format(PeriodStartDate[2] - 1);
        Period2Text := Format(PeriodStartDate[2]) + '..' + Format(PeriodStartDate[3] - 1);
        Period3Text := Format(PeriodStartDate[3]) + '..' + Format(PeriodStartDate[4] - 1);
    end;

    local procedure InsertModifyTempSalesLine(var SalesLineTemp: Record "Sales Line" temporary; SalesAmtOnOrderArr: array[5] of Decimal; PrintAmountsInLCYIn: Boolean)
    begin
        if GroupNumberChanged then begin
            SalesLineTemp.Init();
            SalesLineTemp."Document Type" := SalesLineTemp."Document Type"::Quote;
            SalesLineTemp."Document No." := Customer."No.";
            SalesLineTemp."Line No." := LineNo;
            SalesLineTemp."Bill-to Customer No." := "Sales Line"."Bill-to Customer No.";
            SalesLineTemp.Description := Customer.Name;
            if PrintAmountsInLCYIn then
                SalesLineTemp.Amount := SalesOrderAmountLCY1
            else begin
                SalesLineTemp."Currency Code" := "Sales Line"."Currency Code";
                SalesLineTemp.Amount := SalesOrderAmount1;
            end;
            if PeriodNo = 1 then
                SalesLineTemp."Unit Price" := SalesAmtOnOrderArr[1];
            if PeriodNo = 2 then
                SalesLineTemp."Unit Cost" := SalesAmtOnOrderArr[2];
            if PeriodNo = 3 then
                SalesLineTemp."Outstanding Amount" := SalesAmtOnOrderArr[3];
            if PeriodNo = 4 then
                SalesLineTemp."Amount Including VAT" := SalesAmtOnOrderArr[4];
            if PeriodNo = 5 then
                SalesLineTemp."Line Amount" := SalesAmtOnOrderArr[5];
            SalesLineTemp.Insert();
            LineNo += 1;
        end else begin
            if PrintAmountsInLCYIn then
                SalesLineTemp.Amount := SalesOrderAmountLCY1
            else
                SalesLineTemp.Amount := SalesOrderAmount1;
            if PeriodNo = 1 then
                SalesLineTemp."Unit Price" := SalesAmtOnOrderArr[1];
            if PeriodNo = 2 then
                SalesLineTemp."Unit Cost" := SalesAmtOnOrderArr[2];
            if PeriodNo = 3 then
                SalesLineTemp."Outstanding Amount" := SalesAmtOnOrderArr[3];
            if PeriodNo = 4 then
                SalesLineTemp."Amount Including VAT" := SalesAmtOnOrderArr[4];
            if PeriodNo = 5 then
                SalesLineTemp."Line Amount" := SalesAmtOnOrderArr[5];
            SalesLineTemp.Modify();
        end;
    end;
}
