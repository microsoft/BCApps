// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;

report 10157 "Sales History"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SalesHistory.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Sales History';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Location Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(OnlyItemsWithSales; OnlyItemsWithSales)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(STRSUBSTNO_Text000_DateRange_1__DateRange_2__1_; StrSubstNo(Text000, DateRange[1], DateRange[2] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_2__DateRange_3__1_; StrSubstNo(Text000, DateRange[2], DateRange[3] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_3__DateRange_4__1_; StrSubstNo(Text000, DateRange[3], DateRange[4] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_4__DateRange_5__1_; StrSubstNo(Text000, DateRange[4], DateRange[5] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_5__DateRange_6__1_; StrSubstNo(Text000, DateRange[5], DateRange[6] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_6__DateRange_7__1_; StrSubstNo(Text000, DateRange[6], DateRange[7] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_7__DateRange_8__1_; StrSubstNo(Text000, DateRange[7], DateRange[8] - 1))
            {
            }
            column(STRSUBSTNO_Text000_DateRange_8__DateRange_9__1_; StrSubstNo(Text000, DateRange[8], DateRange[9] - 1))
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(QuantitySold_1_; QuantitySold[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_2_; QuantitySold[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_3_; QuantitySold[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_4_; QuantitySold[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_5_; QuantitySold[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_6_; QuantitySold[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_7_; QuantitySold[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySold_8_; QuantitySold[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Sold__1_; "$Sold"[1])
            {
            }
            column(Sold__2_; "$Sold"[2])
            {
            }
            column(Sold__3_; "$Sold"[3])
            {
            }
            column(Sold__4_; "$Sold"[4])
            {
            }
            column(Sold__5_; "$Sold"[5])
            {
            }
            column(Sold__6_; "$Sold"[6])
            {
            }
            column(Sold__7_; "$Sold"[7])
            {
            }
            column(Sold__8_; "$Sold"[8])
            {
            }
            column(Profit___1_; "Profit%"[1])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___2_; "Profit%"[2])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___3_; "Profit%"[3])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___4_; "Profit%"[4])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___5_; "Profit%"[5])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___6_; "Profit%"[6])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___7_; "Profit%"[7])
            {
                DecimalPlaces = 1 : 1;
            }
            column(Profit___8_; "Profit%"[8])
            {
                DecimalPlaces = 1 : 1;
            }
            column(QuantitySoldPRYR_1_; QuantitySoldPRYR[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_2_; QuantitySoldPRYR[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_3_; QuantitySoldPRYR[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_4_; QuantitySoldPRYR[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_5_; QuantitySoldPRYR[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_6_; QuantitySoldPRYR[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_7_; QuantitySoldPRYR[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(QuantitySoldPRYR_8_; QuantitySoldPRYR[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Sales_HistoryCaption; Sales_HistoryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Items_with_no_sales_during_these_time_periods_are_not_included_Caption; Items_with_no_sales_during_these_time_periods_are_not_included_CaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            column(Qty_SoldCaption; Qty_SoldCaptionLbl)
            {
            }
            column(SoldCaption; SoldCaptionLbl)
            {
            }
            column(Profit__Caption; Profit__CaptionLbl)
            {
            }
            column(Qty_Last_YearCaption; Qty_Last_YearCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                PrintLine := false;
                Clear(QuantitySold);
                Clear("$Sold");
                Clear("Profit%");
                Clear(QuantitySoldPRYR);
                for i := 1 to ArrayLen(QuantitySold) do begin
                    SetRange("Date Filter", DateRange[i], DateRange[i + 1] - 1);
                    CalcFields("Sales (Qty.)", "Sales (LCY)", "COGS (LCY)");
                    if "Sales (Qty.)" <> 0 then begin
                        QuantitySold[i] := "Sales (Qty.)";
                        "$Sold"[i] := "Sales (LCY)";
                        Profit := "Sales (LCY)" - "COGS (LCY)";
                        if "Sales (LCY)" <> 0 then begin
                            "Profit%"[i] := Round(Profit / "Sales (LCY)" * 100, 0.1);
                            PrintLine := true;
                        end else
                            "Profit%"[i] := 0;
                        SetRange("Date Filter", PriorYRMin[i], PriorYRMax[i]);
                        CalcFields("Sales (Qty.)");
                        QuantitySoldPRYR[i] := "Sales (Qty.)";
                    end;
                end;

                if (not PrintLine) and OnlyItemsWithSales then
                    CurrReport.Skip();
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
                    field("DateRange[1]"; DateRange[1])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(TimeDivision; TimeDivision)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Period (1M,2W,29D)';
                        MultiLine = true;
                        ToolTip = 'Specifies the length of the each history period. For example, enter 30D to base history on 30-day intervals.';
                    }
                    field(OnlyItemsWithSales; OnlyItemsWithSales)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Only Items with Sales';
                        ToolTip = 'Specifies if you want to see only items which have been sold during the six calculated periods. If you do not select this check box, the report will print items in inventory even if no sales have occurred.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DateRange[1] = 0D then
                DateRange[1] := WorkDate();
            if Format(TimeDivision) = '' then
                Evaluate(TimeDivision, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        for i := 2 to ArrayLen(DateRange) do
            DateRange[i] := CalcDate(TimeDivision, DateRange[i - 1]);
        for i := 1 to ArrayLen(PriorYRMin) do begin
            PriorYRMin[i] := CalcDate('<-1Y>', DateRange[i]);
            PriorYRMax[i] := CalcDate('<-1Y>', DateRange[i + 1]) - 1;
        end;
    end;

    var
        CompanyInformation: Record "Company Information";
        OnlyItemsWithSales: Boolean;
        TimeDivision: DateFormula;
        ItemFilter: Text;
        DateRange: array[9] of Date;
        PriorYRMin: array[8] of Date;
        PriorYRMax: array[8] of Date;
        QuantitySold: array[8] of Decimal;
        "$Sold": array[8] of Decimal;
        "Profit%": array[8] of Decimal;
        QuantitySoldPRYR: array[8] of Decimal;
        Profit: Decimal;
        i: Integer;
        PrintLine: Boolean;
        Text000: Label '%1 thru %2';
        Sales_HistoryCaptionLbl: Label 'Sales History';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Items_with_no_sales_during_these_time_periods_are_not_included_CaptionLbl: Label 'Items with no sales during these time periods are not included.';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit of Measure:';
        Qty_SoldCaptionLbl: Label 'Qty Sold';
        SoldCaptionLbl: Label '$ Sold';
        Profit__CaptionLbl: Label 'Profit %';
        Qty_Last_YearCaptionLbl: Label 'Qty Last Year';
}

