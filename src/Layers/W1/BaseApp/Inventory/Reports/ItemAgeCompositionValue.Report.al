// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Utilities;

report 5808 "Item Age Composition - Value"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Age Composition by Quantity and Value';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    DefaultRenderingLayout = Excel;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.") where(Type = const(Inventory));
            RequestFilterFields = "No.", "Inventory Posting Group", "Statistics Group", "Location Filter";
#if not CLEAN28
            column(TodayFormatted; Format(Today, 0, 4))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemTableCaptItemFilter; TableCaption + ': ' + ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemFilter; ItemFilter)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] + 1))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] + 1))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4]))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] + 1))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5]))
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValueRTC1; InvtValueRTC[1])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValueRTC2; InvtValueRTC[2])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValueRTC5; InvtValueRTC[5])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValueRTC4; InvtValueRTC[4])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValueRTC3; InvtValueRTC[3])
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TotalInvtValueRTC; TotalInvtValueRTC)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValue1_Item; InvtValue[1])
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValue2_Item; InvtValue[2])
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValue3_Item; InvtValue[3])
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValue4_Item; InvtValue[4])
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InvtValue5_Item; InvtValue[5])
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TotalInvtValue_Item; TotalInvtValue_Item)
            {
                AutoFormatType = 1;
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemAgeCompositionValueCaption; ItemAgeCompositionValueCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(AfterCaption; AfterCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(BeforeCaption; BeforeCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(InventoryValueCaption; InventoryValueCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
            column(TotalCaption; TotalCaptionLbl)
            {
                ObsoleteState = Pending;
                ObsoleteReason = 'RDLC Only layout column. To be removed along with the RDLC layout.';
                ObsoleteTag = '28.0';
            }
#endif
            column(PrintLine; PrintLine)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Item No.", Open) where(Open = const(true));

                trigger OnAfterGetRecord()
                begin
                    if "Remaining Quantity" = 0 then
                        CurrReport.Skip();
                    PrintLine := true;
                    CalcRemainingQty();
                    RemainingQty += TotalInvtQty;

                    if Item."Costing Method" = Item."Costing Method"::Average then begin
                        InvtValue[i] += AverageCost[i] * InvtQty[i];
                        InvtValueRTC[i] += AverageCost[i] * InvtQty[i];
                    end else begin
                        CalcUnitCost();
                        TotalInvtValue_Item += UnitCost * Abs(TotalInvtQty);
                        InvtValue[i] += UnitCost * Abs(InvtQty[i]);

                        TotalInvtValueRTC += UnitCost * Abs(TotalInvtQty);
                        InvtValueRTC[i] += UnitCost * Abs(InvtQty[i]);
                    end
                end;

                trigger OnPostDataItem()
                var
                    AvgCostCurr: Decimal;
                begin
                    if Item."Costing Method" = Item."Costing Method"::Average then begin
                        AvgCostCurr := CalculateAverageCost(DMY2Date(31, 12, 9999));
                        TotalInvtValue_Item := AvgCostCurr * RemainingQty;
                        TotalInvtValueRTC += TotalInvtValue_Item;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    TotalInvtValue_Item := 0;
                    for i := 1 to 5 do
                        InvtValue[i] := 0;
                    RemainingQty := 0;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TotalInvtValue_ItemLedgEntry; TotalInvtValue_Item)
                {
                    AutoFormatType = 1;
                }
                column(InvtValue5_ItemLedgEntry; InvtValue[5])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue4_ItemLedgEntry; InvtValue[4])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue3_ItemLedgEntry; InvtValue[3])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue2_ItemLedgEntry; InvtValue[2])
                {
                    AutoFormatType = 1;
                }
                column(InvtValue1_ItemLedgEntry; InvtValue[1])
                {
                    AutoFormatType = 1;
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
                column(Description_Item; Item.Description)
                {
                    IncludeCaption = true;
                }
                column(No_Item; Item."No.")
                {
                    IncludeCaption = true;
                }
                column(InventoryPostingGroup_Item; Item."Inventory Posting Group")
                {
                    IncludeCaption = true;
                }
                column(StatisticsGroup_Item; Item."Statistics Group")
                {
                    IncludeCaption = true;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Costing Method" = "Costing Method"::Average then begin
                    for i := 2 to 5 do
                        AverageCost[i] := CalculateAverageCost(PeriodStartDate[i + 1]);
                    AverageCost[1] := CalculateAverageCost(PeriodStartDate[2]);
                end;

                PrintLine := false;
            end;

            trigger OnPreDataItem()
            begin
                Clear(InvtValue);
                Clear(TotalInvtValue_Item);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Age Composition by Quantity and Value';
        AboutText = 'Review the age of stock in your warehouse by value to determine obsolescence and identify slow moving inventory. View your open inventory value split across 5 aging buckets based on the period length and ending date. Filter the report by Location to determine the age of Inventory by warehouse.';
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
                        ToolTip = 'Specifies the end date of the report. The report calculates backwards from this date and sets up three periods of the length specified in the Period Length field.';

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
                        ToolTip = 'Specifies the length of the three periods in the report.';

                        trigger OnValidate()
                        begin
                            if Format(PeriodLength) = '' then
                                Evaluate(PeriodLength, '<0D>');
                        end;
                    }
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
            if PeriodStartDate[5] = 0D then
                PeriodStartDate[5] := CalcDate('<CM>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;

        trigger OnClosePage()
        var
            NegPeriodLength: DateFormula;
        begin
            PeriodStartDate[6] := DMY2Date(31, 12, 9999);
            Evaluate(NegPeriodLength, StrSubstNo('-%1', Format(PeriodLength)));
            for i := 1 to 3 do
                PeriodStartDate[5 - i] := CalcDate(NegPeriodLength, PeriodStartDate[6 - i]);
            UpdateRequestPageFilterValues();
        end;
    }

    rendering
    {
        layout(Excel)
        {
            Caption = 'Item Age Composition by Quantity and Value Excel';
            Type = Excel;
            LayoutFile = './Inventory/Reports/ItemAgeCompositionValue.xlsx';
            Summary = 'Report layout primarily made for data analysis. Use an Excel editor to modify the layout.';
        }
#if not CLEAN28
        layout(RDLC)
        {
            Caption = 'Item Age Composition by Quantity and Value RDLC';
            Type = RDLC;
            LayoutFile = './Inventory/Reports/ItemAgeCompositionValue.rdlc';
            ObsoleteState = Pending;
            ObsoleteReason = 'The RDLC layout has been replaced by the Excel layout and will be removed in a future release.';
            ObsoleteTag = '28.0';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
        }
#endif
    }

    labels
    {
        ItemAgeCompositionValueLbl = 'Item Age Composition - Value';
        ItemAgeCompositionQtyLbl = 'Item Age Composition - Quantity';
        ItemAgeComposValuePrintLbl = 'Item Age Com. - Val. (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemAgeComposQtyPrintLbl = 'Item Age Com. - Qty. (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        ItemAgeComposValueAnalysisLbl = 'Item Age Com. - Val. (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrievedLbl = 'Data retrieved:';
        BeforeLbl = '...before';
        AfterLbl = 'after...';
        InvValueBeforeLbl = '...before (Inventory Value)';
        InvValueAfterLbl = 'after... (Inventory Value)';
        InvBeforeLbl = '...before (Inventory)';
        InvAfterLbl = 'after... (Inventory)';
        InventoryValue2Lbl = 'Inventory Value for Period 2';
        InventoryValue3Lbl = 'Inventory Value for Period 3';
        InventoryValue4Lbl = 'Inventory Value for Period 4';
        Inventory2Lbl = 'Inventory for Period 2';
        Inventory3Lbl = 'Inventory for Period 3';
        Inventory4Lbl = 'Inventory for Period 4';
        InventoryValueLbl = 'Inventory Value';
        InventoryLbl = 'Inventory';
        // About the report labels
        AboutTheReportLbl = 'About the report';
        EnvironmentLbl = 'Environment';
        CompanyLbl = 'Company';
        UserLbl = 'User';
        RunOnLbl = 'Run on';
        ReportNameLbl = 'Report name';
        DocumentationLbl = 'Documentation';
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
        UpdateRequestPageFilterValues();
    end;

    var
        PeriodLength: DateFormula;
        ItemFilter: Text;
        InvtValue: array[6] of Decimal;
        InvtValueRTC: array[6] of Decimal;
        InvtQty: array[6] of Decimal;
        UnitCost: Decimal;
        PeriodStartDate: array[6] of Date;
        i: Integer;
        TotalInvtValue_Item: Decimal;
        TotalInvtValueRTC: Decimal;
        TotalInvtQty: Decimal;
        PrintLine: Boolean;
        AverageCost: array[5] of Decimal;
        RemainingQty: Decimal;
        Period1Text: Text;
        Period2Text: Text;
        Period3Text: Text;
#pragma warning disable AA0074
        Text002: Label 'Enter the ending date';
#pragma warning restore AA0074
#if not CLEAN28
        ItemAgeCompositionValueCaptionLbl: Label 'Item Age Composition - Value';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AfterCaptionLbl: Label 'After...';
        BeforeCaptionLbl: Label '...Before';
        InventoryValueCaptionLbl: Label 'Inventory Value';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemNoCaptionLbl: Label 'Item No.';
        TotalCaptionLbl: Label 'Total';
#endif

    local procedure CalcRemainingQty()
    begin
        for i := 1 to 5 do
            InvtQty[i] := 0;

        TotalInvtQty := "Item Ledger Entry"."Remaining Quantity";
        for i := 1 to 5 do
            if ("Item Ledger Entry"."Posting Date" > PeriodStartDate[i]) and
               ("Item Ledger Entry"."Posting Date" <= PeriodStartDate[i + 1])
            then
                if "Item Ledger Entry"."Remaining Quantity" <> 0 then begin
                    InvtQty[i] := "Item Ledger Entry"."Remaining Quantity";
                    exit;
                end;
    end;

    local procedure CalcUnitCost()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
        UnitCost := 0;

        if ValueEntry.Find('-') then
            repeat
                if ValueEntry."Partial Revaluation" then
                    SumUnitCost(UnitCost, ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)", ValueEntry."Valued Quantity")
                else
                    SumUnitCost(UnitCost, ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)", "Item Ledger Entry".Quantity);
            until ValueEntry.Next() = 0;
    end;

    local procedure CalculateAverageCost(EndDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Amount: Decimal;
    begin
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Valuation Date", 0D, EndDate);
        ValueEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ValueEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        Amount := ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)";
        if Amount = 0 then
            exit(0);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Posting Date", 0D, EndDate);
        ItemLedgerEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ItemLedgerEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.CalcSums("Remaining Quantity");
        if ItemLedgerEntry."Remaining Quantity" = 0 then
            exit(0);

        exit(Amount / ItemLedgerEntry."Remaining Quantity");
    end;

    local procedure SumUnitCost(var UnitCost: Decimal; CostAmount: Decimal; Quantity: Decimal)
    begin
        UnitCost := UnitCost + CostAmount / Abs(Quantity);
    end;

    procedure InitializeRequest(NewEndingDate: Date; NewPeriodLength: DateFormula)
    begin
        PeriodStartDate[5] := NewEndingDate;
        PeriodLength := NewPeriodLength;
    end;

    local procedure UpdateRequestPageFilterValues()
    begin
        if (PeriodStartDate[2] <> 0D) and (PeriodStartDate[3] <> 0D) and (PeriodStartDate[4] <> 0D) then begin
            Period1Text := Format(PeriodStartDate[2] + 1) + '..' + Format(PeriodStartDate[3]);
            Period2Text := Format(PeriodStartDate[3] + 1) + '..' + Format(PeriodStartDate[4]);
            Period3Text := Format(PeriodStartDate[4] + 1) + '..' + Format(PeriodStartDate[5]);
        end;
    end;
}

