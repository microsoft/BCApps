// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using System.Utilities;

report 11577 "SR Item Ranking"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/SRItemRanking.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Ranking';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Variant Filter", "Location Filter";

            trigger OnAfterGetRecord()
            begin
                // Store calculated amt and item no in temp table
                Window.Update(1, "No.");
                NoOfRecs := NoOfRecs + 1;

                // Calc total per item for col 1 and 2
                for i := 1 to 2 do
                    case Column[i] of
                        Column[i] ::Stock:
                            begin
                                CalcFields(Inventory);
                                TmpAmount[i] := Inventory;
                            end;
                        Column[i] ::"Inv. Stock":
                            begin
                                CalcFields("Net Invoiced Qty.");
                                TmpAmount[i] := "Net Invoiced Qty.";
                            end;
                        Column[i] ::"Net Change":
                            begin
                                CalcFields("Net Change");
                                TmpAmount[i] := "Net Change";
                            end;
                        Column[i] ::"Purch. Qty":
                            begin
                                CalcFields("Purchases (Qty.)");
                                TmpAmount[i] := "Purchases (Qty.)";
                            end;
                        Column[i] ::"Sales Qty":
                            begin
                                CalcFields("Sales (Qty.)");
                                TmpAmount[i] := "Sales (Qty.)";
                            end;
                        Column[i] ::"Pos. Adj.":
                            begin
                                CalcFields("Positive Adjmt. (Qty.)");
                                TmpAmount[i] := "Positive Adjmt. (Qty.)";
                            end;
                        Column[i] ::"Neg. Adj.":
                            begin
                                CalcFields("Negative Adjmt. (Qty.)");
                                TmpAmount[i] := "Negative Adjmt. (Qty.)";
                            end;
                        Column[i] ::"On Purch. Order":
                            begin
                                CalcFields("Qty. on Purch. Order");
                                TmpAmount[i] := "Qty. on Purch. Order";
                            end;
                        Column[i] ::"On Sales Order":
                            begin
                                CalcFields("Qty. on Sales Order");
                                TmpAmount[i] := "Qty. on Sales Order";
                            end;
                        Column[i] ::"Purch. Amt.":
                            begin
                                CalcFields("Purchases (LCY)");
                                TmpAmount[i] := "Purchases (LCY)";
                            end;
                        Column[i] ::"Sales Amt.":
                            begin
                                CalcFields("Sales (LCY)");
                                TmpAmount[i] := "Sales (LCY)";
                            end;
                        Column[i] ::Profit:
                            begin
                                CalcFields("Sales (LCY)", "COGS (LCY)");
                                TmpAmount[i] := "Sales (LCY)" - "COGS (LCY)";
                            end;
                        Column[i] ::"Unit Price":
                            TmpAmount[i] := "Unit Price";
                        Column[i] ::"Direct Cost":
                            TmpAmount[i] := "Unit Cost";
                    end;  // case

                if (TmpAmount[1] = 0) and (TmpAmount[2] = 0) then
                    CurrReport.Skip();

                // Write buffer records
                ItemAmount.Init();

                ItemAmount.Amount := TmpAmount[1];
                ItemAmount."Amount 2" := TmpAmount[2];
                ItemAmount."Item No." := "No.";
                ItemAmount.Insert();

                // Total of all recs
                Col1TotalAllRecs := Col1TotalAllRecs + ItemAmount.Amount;
                Col2TotalAllRecs := Col2TotalAllRecs + ItemAmount."Amount 2";

                // Save highest amt
                if ItemAmount.Amount > Col1MaxAmount then
                    Col1MaxAmount := ItemAmount.Amount;

                if ItemAmount."Amount 2" > Col2MaxAmount then
                    Col2MaxAmount := ItemAmount."Amount 2";
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if NoOfRecs = 0 then
                    Error(Text001);
            end;

            trigger OnPreDataItem()
            begin
                ItemAmount.DeleteAll();  // Temp table
                Window.Open(Text004);
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(PeriodItemDateFilter; Text007 + ItemDateFilter)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterItemFilter; 'Filter: ' + ItemFilter)
            {
            }
            column(ShareColumnStock; Text006 + SelectStr(Column[1] + 1, Text005))
            {
            }
            column(Col2Text; Col2Text)
            {
            }
            column(ColumnStock; SelectStr(Column[1] + 1, Text005))
            {
            }
            column(Number_IntegerLine; Number)
            {
            }
            column(ItemNo; Item."No.")
            {
            }
            column(ItemDescription; Item.Description)
            {
            }
            column(Col1Amount; Col1Amount)
            {
            }
            column(Col2Amount; Col2Amount)
            {
            }
            column(BarText; BarText)
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
            column(V1000; 100.0)
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
            column(NoOfRecsNumber1; NoOfRecs - Number + 1)
            {
            }
            column(ItemRankingCaption; ItemRankingCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }
            column(RankCaption; RankCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalSelectedItemsCaption; TotalSelectedItemsCaptionLbl)
            {
            }
            column(OutOfStatisticRangeCaption; OutOfStatisticRangeCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                // Loop temp record ItemAmt. Break on last rec or at max. number
                if Number = 1 then begin
                    if not ItemAmount.FindSet() then
                        CurrReport.Break();
                end else
                    if (ItemAmount.Next() = 0) or ((MaxNoOfRecs > 0) and (Number > MaxNoOfRecs)) then
                        CurrReport.Break();

                Item.Get(ItemAmount."Item No.");
                Col1Amount := ItemAmount.Amount;
                Col2Amount := ItemAmount."Amount 2";
                Col1TotalStat := Col1TotalStat + Col1Amount;
                Col2TotalStat := Col2TotalStat + Col2Amount;

                // Pct of all recs
                if Col1MaxAmount > 0 then
                    Pct := Round(Col1Amount / Col1TotalAllRecs * 100, 0.01);

                // Bar in relation to max. value. Font: WingDings
                BarText := '';
                if (Col1Amount > 0) and (Col1MaxAmount > 0) then
                    BarText := PadStr('', Round(Col1Amount / Col1MaxAmount * 25, 1), 'n');
            end;

            trigger OnPreDataItem()
            begin
                // Sort ranking
                if Sorting = Sorting::Ascending then
                    ItemAmount.Ascending(false);

                if Column[2] <> Column[2] ::"<blank>" then
                    Col2Text := SelectStr(Column[2] + 1, Text005);
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
                        OptionCaption = 'Stock,Inv. Stock,Net Change,Purch. Qty,Sales Qty,Pos. Adj.,Neg. Adj.,On Purch. Order,On Sales Order,Purch. Amt.,Sales Amt.,Profit,Unit Price,Direct Cost,<blank>';
                        ToolTip = 'Specifies the key figure shown in the first column that is the basis for the rankings list, the variance in percent, and the bar chart.';
                    }
                    field("Column[2]"; Column[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Column 2';
                        OptionCaption = 'Stock,Inv. Stock,Net Change,Purch. Qty,Sales Qty,Pos. Adj.,Neg. Adj.,On Purch. Order,On Sales Order,Purch. Amt.,Sales Amt.,Profit,Unit Price,Direct Cost,<blank>';
                        ToolTip = 'Specifies the key figure shown in the second column (blank <empty>, when only one column is of interest). This column is supplemental information and is not sorted.';
                    }
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Ascending,Descending';
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
        ItemDateFilter := Item.GetFilter("Date Filter");
    end;

    trigger OnPreReport()
    begin
        // Different values for col 1 and 2
        if Column[1] = Column[2] then
            Error(Text002);

        if Column[1] = Column[1] ::"<blank>" then
            Error(Text003);

        ItemFilter := Item.GetFilters();
        ItemDateFilter := Item.GetFilter("Date Filter");
    end;

    var
        ItemAmount: Record "Item Amount" temporary;
        Window: Dialog;
        ItemFilter: Text[250];
        ItemDateFilter: Text[30];
        MaxNoOfRecs: Integer;
        Sorting: Option "Ascending","Descending";
        NoOfRecs: Integer;
        Column: array[2] of Option Stock,"Inv. Stock","Net Change","Purch. Qty","Sales Qty","Pos. Adj.","Neg. Adj.","On Purch. Order","On Sales Order","Purch. Amt.","Sales Amt.",Profit,"Unit Price","Direct Cost","<blank>";
        TmpAmount: array[2] of Decimal;
        Col2Text: Text[30];
        Col1TotalAllRecs: Decimal;
        Col2TotalAllRecs: Decimal;
        Col1TotalStat: Decimal;
        Col2TotalStat: Decimal;
        Col1Amount: Decimal;
        Col2Amount: Decimal;
        Col1MaxAmount: Decimal;
        Col2MaxAmount: Decimal;
        Pct: Decimal;
        BarText: Text[50];
        i: Integer;
        Text001: Label 'The amounts of the selected records are zero. Check the filters in the request window.';
        Text002: Label 'Column 1 and 2 must show different values. Choose <blank> for column 2 if only one column should be processed.';
        Text003: Label 'Column 1 must no be empty because this is the base for the ranking.';
        Text004: Label 'Prepare statistic      #1#########';
        Text005: Label 'Stock,Inv. Stock,Net Change,Purch. Qty,Sales Qty,Pos. Adj.,Neg. Adj.,On Purch. Order,On Sales Order,Purch. Amt.,Sales Amt.,Profit,Unit Price,Direct Cost,<blank>';
        Text006: Label 'Share ';
        Text007: Label 'Period: ';
        ItemRankingCaptionLbl: Label 'Item Ranking';
        PageCaptionLbl: Label 'Page';
        EmptyStringCaptionLbl: Label '%';
        DescriptionCaptionLbl: Label 'Description';
        NumberCaptionLbl: Label 'Number';
        RankCaptionLbl: Label 'Rank';
        TotalCaptionLbl: Label 'Total ';
        TotalSelectedItemsCaptionLbl: Label 'Total selected items';
        OutOfStatisticRangeCaptionLbl: Label 'Out of Statistic Range';
}

