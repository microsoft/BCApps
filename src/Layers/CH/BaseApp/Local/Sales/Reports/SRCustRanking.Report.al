// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Sales.Customer;
using System.Utilities;

report 11539 "SR Cust. Ranking"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustRanking.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Ranking';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer Posting Group", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                NoOfRecs := NoOfRecs + 1;

                for i := 1 to 2 do
                    case Column[i] of
                        Column[i] ::Balance:
                            begin
                                CalcFields("Balance (LCY)");
                                TmpAmt[i] := "Balance (LCY)";
                            end;
                        Column[i] ::Movement:
                            begin
                                CalcFields("Net Change");
                                TmpAmt[i] := "Net Change";
                            end;
                        Column[i] ::"Due Balance":
                            begin
                                CalcFields("Balance Due (LCY)");
                                TmpAmt[i] := "Balance Due (LCY)";
                            end;
                        Column[i] ::Sales:
                            begin
                                CalcFields("Sales (LCY)");
                                TmpAmt[i] := "Sales (LCY)";
                            end;
                        Column[i] ::Profit:
                            begin
                                CalcFields("Profit (LCY)");
                                TmpAmt[i] := "Profit (LCY)";
                            end;
                        Column[i] ::"Invoice Amount":
                            begin
                                CalcFields("Inv. Amounts (LCY)");
                                TmpAmt[i] := "Inv. Amounts (LCY)";
                            end;
                        Column[i] ::"Credit Memos ":
                            begin
                                CalcFields("Cr. Memo Amounts (LCY)");
                                TmpAmt[i] := "Cr. Memo Amounts (LCY)";
                            end;
                        Column[i] ::Payments:
                            begin
                                CalcFields("Payments (LCY)");
                                TmpAmt[i] := "Payments (LCY)";
                            end;
                        Column[i] ::Backlog:
                            begin
                                CalcFields("Outstanding Orders (LCY)");
                                TmpAmt[i] := "Outstanding Orders (LCY)";
                            end;
                        Column[i] ::"Shipped not Invoiced":
                            begin
                                CalcFields("Shipped Not Invoiced (LCY)");
                                TmpAmt[i] := "Shipped Not Invoiced (LCY)";
                            end;
                        Column[i] ::"Credit Limit":
                            TmpAmt[i] := "Credit Limit (LCY)";
                        Column[i] ::"Budget Amount":
                            TmpAmt[i] := "Budgeted Amount";
                    end;

                if (TmpAmt[1] = 0) and (TmpAmt[2] = 0) then
                    CurrReport.Skip();

                CustAmt.Init();
                CustAmt."Amount (LCY)" := TmpAmt[1];
                CustAmt."Amount 2 (LCY)" := TmpAmt[2];
                CustAmt."Customer No." := "No.";
                CustAmt.Insert();

                Col1TotalAllRecs := Col1TotalAllRecs + CustAmt."Amount (LCY)";
                Col2TotalAllRecs := Col2TotalAllRecs + CustAmt."Amount 2 (LCY)";

                if CustAmt."Amount (LCY)" > Col1MaxAmt then
                    Col1MaxAmt := CustAmt."Amount (LCY)";

                if CustAmt."Amount 2 (LCY)" > Col2MaxAmt then
                    Col2MaxAmt := CustAmt."Amount 2 (LCY)";
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if NoOfRecs = 0 then
                    Error(
                      Text004);
            end;

            trigger OnPreDataItem()
            begin
                CustAmt.DeleteAll();
                Window.Open(Text003);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CustDateFilter; Text006 + CustDateFilter)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustFilter; Text007 + CustFilter)
            {
            }
            column(ShareCol1Txt; Text008 + Col1Txt)
            {
            }
            column(Col1Txt; Col1Txt)
            {
            }
            column(Col2Txt; Col2Txt)
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(CustomerNo; Customer."No.")
            {
            }
            column(CustomerName; Customer.Name)
            {
            }
            column(Col1Amt; Col1Amt)
            {
            }
            column(Col2Amt; Col2Amt)
            {
            }
            column(BarTxt; BarTxt)
            {
            }
            column(Pct; Pct)
            {
            }
            column(Col2TotalStat; Col2TotalStat)
            {
            }
            column(Col1TotalStat; Col1TotalStat)
            {
            }
            column(Number; Number - 1)
            {
            }
            column(V100; 100.0)
            {
                DecimalPlaces = 2 : 2;
            }
            column(Col2TotalAllRecs; Col2TotalAllRecs)
            {
            }
            column(Col1TotalAllRecs; Col1TotalAllRecs)
            {
                AutoFormatType = 1;
            }
            column(NoOfRecs; NoOfRecs)
            {
            }
            column(Col1TotalAllRecsCol1TotalStat; Col1TotalAllRecs - Col1TotalStat)
            {
                AutoFormatType = 1;
            }
            column(Col2TotalAllRecsCol2TotalStat; Col2TotalAllRecs - Col2TotalStat)
            {
                AutoFormatType = 1;
            }
            column(V100Pct; 100 - Pct)
            {
            }
            column(NoOfRecsNumber; NoOfRecs - Number + 1)
            {
            }
            column(CustRankingCaption; CustRankingCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(CustNameCaption; CustNameCaptionLbl)
            {
            }
            column(CustNoCaption; CustNoCaptionLbl)
            {
            }
            column(RankCaption; RankCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(NoofselectedCustCaption; NoofselectedCustCaptionLbl)
            {
            }
            column(OutofStatisticRangeCaption; OutofStatisticRangeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not CustAmt.Find('-') then
                        CurrReport.Break();
                end else
                    if (CustAmt.Next() = 0) or ((MaxNoOfRecs > 0) and (Number > MaxNoOfRecs)) then
                        CurrReport.Break();

                Customer.Get(CustAmt."Customer No.");
                Col1Amt := CustAmt."Amount (LCY)";
                Col2Amt := CustAmt."Amount 2 (LCY)";
                Col1TotalStat := Col1TotalStat + Col1Amt;
                Col2TotalStat := Col2TotalStat + Col2Amt;

                if Col1MaxAmt > 0 then
                    Pct := Round(Col1Amt / Col1TotalAllRecs * 100, 0.01);

                BarTxt := '';
                if (Col1Amt > 0) and (Col1MaxAmt > 0) then
                    BarTxt := PadStr('', Round(Col1Amt / Col1MaxAmt * 25, 1), 'n');
            end;

            trigger OnPreDataItem()
            begin
                if Sorting = Sorting::Ascending then
                    CustAmt.Ascending(false);

                if Column[2] <> Column[2] ::"<blank>" then
                    Col2Txt := SelectStr(Column[2] + 1, Text009);

                Col1Txt := SelectStr(Column[1] + 1, Text009);
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
                    field("Column[1]"; Column[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column 1';
                        OptionCaption = 'Balance,Movement,Due Balance,Sales,Profit,Invoice Amount,Credit Memos ,Payments,Backlog,Shipped not Invoiced,Budget Amount,Credit Limit,<blank>';
                        ToolTip = 'Specifies the key figure shown in the first column that is the basis for the rankings list, the variance in percent, and the bar chart.';
                    }
                    field("Column[2]"; Column[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column 2';
                        OptionCaption = 'Balance,Movement,Due Balance,Sales,Profit,Invoice Amount,Credit Memos ,Payments,Backlog,Shipped not Invoiced,Budget Amount,Credit Limit,<blank>';
                        ToolTip = 'Specifies the key figure shown in the second column (blank <empty>, when only one column is of interest). This column is supplemental information and is not sorted.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Descending,Ascending';
                        ToolTip = 'Specifies how the information is sorted.';
                    }
                    field(MaxNoOfRecs; MaxNoOfRecs)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Max. No. of Records';
                        ToolTip = 'Specifies the maximum number of records to be shown on the report.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if Column[1] = Column[2] then
            Column[2] := Column[2] ::"<blank>";

        if MaxNoOfRecs = 0 then
            MaxNoOfRecs := 20;
    end;

    trigger OnPreReport()
    begin
        if Column[1] = Column[2] then
            Error(Text000);

        if Column[1] = Column[1] ::"<blank>" then
            Error(Text002);

        CustFilter := Customer.GetFilters();
        CustDateFilter := Customer.GetFilter("Date Filter");
    end;

    var
        Text000: Label 'Columns 1 and 2 must show different values. Select the option <blank> if only one column should be displayed.';
        Text002: Label 'Column 1 must not be empty because this is the base for the ranking.';
        Text003: Label 'Prepare statistic      #1##########';
        Text004: Label 'The amounts of the selected records are zero. Check the filters in the request window.';
        Text006: Label 'Period: ';
        Text007: Label 'Filter: ';
        Text008: Label 'Share ';
        CustAmt: Record "Customer Amount" temporary;
        Window: Dialog;
        CustFilter: Text[250];
        CustDateFilter: Text[30];
        MaxNoOfRecs: Integer;
        Sorting: Option "Ascending","Descending";
        NoOfRecs: Integer;
        Column: array[2] of Option Balance,Movement,"Due Balance",Sales,Profit,"Invoice Amount","Credit Memos ",Payments,Backlog,"Shipped not Invoiced","Budget Amount","Credit Limit","<blank>";
        TmpAmt: array[2] of Decimal;
        Col2Txt: Text[30];
        Col1Txt: Text[30];
        Col1TotalAllRecs: Decimal;
        Col2TotalAllRecs: Decimal;
        Col1TotalStat: Decimal;
        Col2TotalStat: Decimal;
        Col1Amt: Decimal;
        Col2Amt: Decimal;
        Col1MaxAmt: Decimal;
        Col2MaxAmt: Decimal;
        Pct: Decimal;
        BarTxt: Text[50];
        i: Integer;
        Text009: Label 'Balance,Movement,Due Balance,Sales,Profit,Invoice Amount,Credit Memos ,Payments,Backlog,Shipped not Invoiced,Budget Amount,Credit Limit,<blank>';
        CustRankingCaptionLbl: Label 'Customer Ranking';
        PageNoCaptionLbl: Label 'Page';
        CustNameCaptionLbl: Label 'Customer Name';
        CustNoCaptionLbl: Label 'Customer No.';
        RankCaptionLbl: Label 'Rank';
        EmptyStringCaptionLbl: Label '%';
        TotalCaptionLbl: Label 'Total ';
        NoofselectedCustCaptionLbl: Label 'No. of selected Customers';
        OutofStatisticRangeCaptionLbl: Label 'Out of Statistic Range';
}

