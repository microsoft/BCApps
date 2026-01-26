// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11557 "SR Vendor Ranking"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/SRVendorRanking.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Ranking';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";

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
                        Column[i] ::"Balance Due":
                            begin
                                CalcFields("Balance Due (LCY)");
                                TmpAmt[i] := "Balance Due (LCY)";
                            end;
                        Column[i] ::Purchase:
                            begin
                                CalcFields("Purchases (LCY)");
                                TmpAmt[i] := "Purchases (LCY)";
                            end;
                        Column[i] ::"Invoice Amount":
                            begin
                                CalcFields("Inv. Amounts (LCY)");
                                TmpAmt[i] := "Inv. Amounts (LCY)";
                            end;
                        Column[i] ::"Credit Memos":
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
                                CalcFields("Amt. Rcd. Not Invoiced (LCY)");
                                TmpAmt[i] := "Amt. Rcd. Not Invoiced (LCY)";
                            end;
                        Column[i] ::"Budget Amount":
                            TmpAmt[i] := "Budgeted Amount";
                    end;

                if (TmpAmt[1] = 0) and (TmpAmt[2] = 0) then
                    CurrReport.Skip();

                VendAmt.Init();
                VendAmt."Amount (LCY)" := TmpAmt[1];
                VendAmt."Amount 2 (LCY)" := TmpAmt[2];
                VendAmt."Vendor No." := "No.";
                VendAmt.Insert();

                Col1TotalAllRecs := Col1TotalAllRecs + VendAmt."Amount (LCY)";
                Col2TotalAllRecs := Col2TotalAllRecs + VendAmt."Amount 2 (LCY)";

                if VendAmt."Amount (LCY)" > Col1MaxAmt then
                    Col1MaxAmt := VendAmt."Amount (LCY)";

                if VendAmt."Amount 2 (LCY)" > Col2MaxAmt then
                    Col2MaxAmt := VendAmt."Amount 2 (LCY)";
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if NoOfRecs = 0 then
                    Error(Text004);
                Col2MaxAmt := VendAmt."Amount 2 (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                VendAmt.DeleteAll();
                Window.Open(Text003);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(VendDateFilter; Text006 + VendDateFilter)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendFilter; Text007 + VendFilter)
            {
            }
            column(BlankCol1Txt; Text008 + Col1Txt)
            {
            }
            column(Col2Txt; Col2Txt)
            {
            }
            column(Col1Txt; Col1Txt)
            {
            }
            column(IntegerNumber; Number)
            {
            }
            column(NoVend; Vendor."No.")
            {
            }
            column(NameVend; Vendor.Name)
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
            column(Number1; Number - 1)
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
            column(VendorRankingCaption; VendorRankingCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(VendorNameCaption; VendorNameCaptionLbl)
            {
            }
            column(VendorNoCaption; VendorNoCaptionLbl)
            {
            }
            column(RankCaption; RankCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalselectedVendsCaption; TotalselectedVendsCaptionLbl)
            {
            }
            column(OutOfStatisticRangeCaption; OutOfStatisticRangeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not VendAmt.FindSet() then
                        CurrReport.Break();
                end else
                    if (VendAmt.Next() = 0) or ((MaxNoOfRecs > 0) and (Number > MaxNoOfRecs)) then
                        CurrReport.Break();

                Vendor.Get(VendAmt."Vendor No.");
                Col1Amt := VendAmt."Amount (LCY)";
                Col2Amt := VendAmt."Amount 2 (LCY)";
                Col1TotalStat := Col1TotalStat + Col1Amt;
                Col2TotalStat := Col2TotalStat + Col2Amt;

                if Col1MaxAmt > 0 then
                    Pct := Round(Col1Amt / Col1TotalAllRecs * 100, 0.01);

                BarTxt := '';
                if (Col1Amt > 0) and (Col1MaxAmt > 0) then
                    BarTxt := PadStr('', Round(Col1Amt / Col1MaxAmt * 25, 1), 'n');
            end;

            trigger OnPostDataItem()
            begin
                Col2Amt := VendAmt."Amount 2 (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                if Sorting = Sorting::Ascending then
                    VendAmt.Ascending(false);

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
                        OptionCaption = 'Balance,Movement,Balance Due,Purchase,Invoice Amount,Credit Memos,Payments,Backlog,Shipped not Invoiced,Budget Amount,<blank>';
                        ToolTip = 'Specifies the key figure shown in the first column that is the basis for the rankings list, the variance in percent, and the bar chart.';
                    }
                    field("Column[2]"; Column[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column 2';
                        OptionCaption = 'Balance,Movement,Balance Due,Purchase,Invoice Amount,Credit Memos,Payments,Backlog,Shipped not Invoiced,Budget Amount,<blank>';
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

    trigger OnPostReport()
    begin
        VendDateFilter := Vendor.GetFilter("Date Filter");
    end;

    trigger OnPreReport()
    begin
        if Column[1] = Column[2] then
            Error(Text000);

        if Column[1] = Column[1] ::"<blank>" then
            Error(Text002);

        VendFilter := Vendor.GetFilters();
        VendDateFilter := Vendor.GetFilter("Date Filter");
    end;

    var
        Text000: Label 'Columns 1 and 2 must show different values. Select the option <blank> if only one column should be displayed.';
        Text002: Label 'Column 1 must not be empty because this is the base for the ranking.';
        Text003: Label 'Prepare statistic      #1##########';
        Text004: Label 'The amounts of the selected records are zero. Check the filters in the request window.';
        Text006: Label 'Period: ';
        Text007: Label 'Filter: ';
        Text008: Label 'Share ';
        VendAmt: Record "Vendor Amount" temporary;
        Window: Dialog;
        VendFilter: Text[250];
        VendDateFilter: Text[30];
        MaxNoOfRecs: Integer;
        Sorting: Option "Ascending","Descending";
        NoOfRecs: Integer;
        Column: array[2] of Option Balance,Movement,"Balance Due",Purchase,"Invoice Amount","Credit Memos",Payments,Backlog,"Shipped not Invoiced","Budget Amount","<blank>";
        TmpAmt: array[2] of Decimal;
        Col1Txt: Text[30];
        Col2Txt: Text[30];
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
        Text009: Label 'Balance,Movement,Balance Due,Purchase,Invoice Amount,Credit Memos,Payments,Backlog,Shipped not Invoiced,Budget Amount,<blank>';
        VendorRankingCaptionLbl: Label 'Vendor Ranking';
        PageNoCaptionLbl: Label 'Page';
        EmptyStringCaptionLbl: Label '%';
        VendorNameCaptionLbl: Label 'Vendor Name';
        VendorNoCaptionLbl: Label 'Vendor No.';
        RankCaptionLbl: Label 'Rank';
        TotalCaptionLbl: Label 'Total ';
        TotalselectedVendsCaptionLbl: Label 'Total selected Vendors';
        OutOfStatisticRangeCaptionLbl: Label 'Out of Statistic Range';
}

