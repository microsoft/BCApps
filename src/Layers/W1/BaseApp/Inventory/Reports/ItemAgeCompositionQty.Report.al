// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 5807 "Item Age Composition - Qty."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemAgeCompositionQty.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item Age Composition - Quantity';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TblCptnItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(Item2PeriodStartDate; Format(PeriodStartDate[2] + 1))
            {
            }
            column(Item3PeriodStartDate; Format(PeriodStartDate[3]))
            {
            }
            column(Item31PeriodStartDate; Format(PeriodStartDate[3] + 1))
            {
            }
            column(Item4PeriodStartDate; Format(PeriodStartDate[4]))
            {
            }
            column(Item41PeriodStartDate; Format(PeriodStartDate[4] + 1))
            {
            }
            column(Item5PeriodStartDate; Format(PeriodStartDate[5]))
            {
            }
            column(No_Item; "No.")
            {
            }
            column(ItemAgeCompositionQtyCaption; ItemAgeCompositionQtyCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AfterCaption; AfterCaptionLbl)
            {
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
            }
            column(TotalInvtQtyCaption; TotalInvtQtyCaptionLbl)
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(InvtQty1_ItemLedgEntry; InvtQty[1])
            {
                DecimalPlaces = 0 : 2;
            }
            column(InvtQty2_ItemLedgEntry; InvtQty[2])
            {
                DecimalPlaces = 0 : 2;
            }
            column(InvtQty3_ItemLedgEntry; InvtQty[3])
            {
                DecimalPlaces = 0 : 2;
            }
            column(InvtQty4_ItemLedgEntry; InvtQty[4])
            {
                DecimalPlaces = 0 : 2;
            }
            column(InvtQty5_ItemLedgEntry; InvtQty[5])
            {
                DecimalPlaces = 0 : 2;
            }
            column(TotalInvtQty; TotalInvtQty)
            {
                DecimalPlaces = 0 : 2;
            }
            column(Desc_Item; Description)
            {
            }
            column(PrintLine; PrintLine)
            {
            }

            trigger OnAfterGetRecord()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
            begin
                PrintLine := false;

                TotalInvtQty := 0;
                for i := 1 to 5 do
                    InvtQty[i] := 0;

                ItemLedgEntry.FilterLinesWithItemToPlan(Item, false);
                if ItemLedgEntry.FindSet() then
                    repeat
                        PrintLine := true;
                        TotalInvtQty := TotalInvtQty + ItemLedgEntry."Remaining Quantity";
                        for i := 1 to 5 do
                            if (ItemLedgEntry."Posting Date" > PeriodStartDate[i]) and (ItemLedgEntry."Posting Date" <= PeriodStartDate[i + 1]) then
                                InvtQty[i] := InvtQty[i] + ItemLedgEntry."Remaining Quantity";
                    until ItemLedgEntry.Next() = 0;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Age Composition – Quantity';
        AboutText = 'Review the age of stock in your warehouse by quantity to determine obsolescence and identify slow moving inventory. View your open inventory value split across 5 aging buckets based on the period length and ending date. Filter the report by Location to determine the age of Inventory by warehouse.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EndingDate; PeriodStartDate[5])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        begin
                            if PeriodStartDate[5] = 0D then
                                Error(Text002);
                        end;
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';

                        trigger OnValidate()
                        begin
                            if Format(PeriodLength) = '' then
                                Evaluate(PeriodLength, '<0D>');
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[5] = 0D then
                PeriodStartDate[5] := CalcDate('<CM>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        NegPeriodLength: DateFormula;
    begin
        ItemFilter := Item.GetFilters();

        PeriodStartDate[6] := DMY2Date(31, 12, 9999);
        Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));
        for i := 1 to 3 do
            PeriodStartDate[5 - i] := CalcDate(NegPeriodLength, PeriodStartDate[6 - i]);
    end;

    var
        PeriodLength: DateFormula;
        ItemFilter: Text;
        InvtQty: array[6] of Decimal;
        PeriodStartDate: array[7] of Date;
        i: Integer;
        TotalInvtQty: Decimal;
        PrintLine: Boolean;

#pragma warning disable AA0074
        Text002: Label 'Enter the ending date';
#pragma warning restore AA0074
        ItemAgeCompositionQtyCaptionLbl: Label 'Item Age Composition - Quantity';
        PageNoCaptionLbl: Label 'Page';
        AfterCaptionLbl: Label 'After...';
        BeforeCaptionLbl: Label '...Before';
        TotalInvtQtyCaptionLbl: Label 'Inventory';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';

    procedure InitializeRequest(NewEndingDate: Date; NewPeriodLength: DateFormula)
    begin
        PeriodStartDate[5] := NewEndingDate;
        PeriodLength := NewPeriodLength;
    end;
}

