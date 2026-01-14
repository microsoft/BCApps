// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

table 5310 "Item Statistics Cache"
{
    Caption = 'Item Statistics Cache';
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMD;
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Item No."; Code[20])
        {
        }
        field(2; ItemLedgerEntryNoLatest; Integer)
        {
        }
        field(3; ValueEntryNoLatest; Integer)
        {
        }
        field(4; LastUpdated; Date)
        {
        }
        field(5; "CurrentInventoryValue"; Decimal)
        {
        }
        field(6; "ExpiredStockValue"; Decimal)
        {
        }
        #region This period
        field(7; "SalesGrowthRateThisPeriod"; Decimal)
        {
        }
        field(8; "NetSalesLCYThisPeriod"; Decimal)
        {
        }
        field(9; "GrossMarginThisPeriod"; Decimal)
        {
        }
        field(10; "ReturnRateThisPeriod"; Decimal)
        {
        }
        #endregion
        #region This fiscal year
        field(11; "SalesGrowthRateThisFY"; Decimal)
        {
        }
        field(12; "NetSalesLCYThisFY"; Decimal)
        {
        }
        field(13; "GrossMarginThisFY"; Decimal)
        {
        }
        field(14; "ReturnRateThisFY"; Decimal)
        {
        }
        #endregion
        #region Last fiscal year
        field(15; "SalesGrowthRateLastFY"; Decimal)
        {
        }
        field(16; "NetSalesLCYLastFY"; Decimal)
        {
        }
        field(17; "GrossMarginLastFY"; Decimal)
        {
        }
        field(18; "ReturnRateLastFY"; Decimal)
        {
        }
        #endregion
        #region Lifetime
        field(19; "NetSalesLCYLifetime"; Decimal)
        {
        }
        field(20; "GrossMarginLifetime"; Decimal)
        {
        }
        field(21; "ReturnRateLifetime"; Decimal)
        {
        }
        #endregion
    }

    keys
    {
        key(Key1; "Item No.")
        {
            Clustered = true;
        }
    }

    procedure InitAndInsert(ItemNo: Code[20])
    begin
        Rec.Init();
        Rec."Item No." := ItemNo;
        Rec.Insert();
    end;

    /// <summary>
    /// Update the Item Statistics Cache record if there are new Item Ledger entries or Value entries, or if the month has changed.
    /// </summary>
    procedure UpdateIfNeeded(Item: Record Item; CurrentDate: Date; ItemDateFilters: array[4] of Text[30]; PriorPeriodItemDateFilters: array[4] of Text[30])
    var
        WasUpdated: Boolean;
        ShouldUpdateAll: Boolean;
    begin
        if Rec.LastUpdated = 0D then
            ShouldUpdateAll := true
        else
            ShouldUpdateAll := (CurrentDate > CalcDate('<+1M>', Rec.LastUpdated));

        if ShouldUpdateAll then begin
            UpdateForItemLedgerEntry(Item, ItemDateFilters);
            UpdateForValueEntry(Item, ItemDateFilters, PriorPeriodItemDateFilters);
            WasUpdated := true;
        end else begin
            if IsUpdateNeededItemLedgerEntry() then begin
                UpdateForItemLedgerEntry(Item, ItemDateFilters);
                WasUpdated := true;
            end;
            if IsUpdateNeededValueEntry() then begin
                UpdateForValueEntry(Item, ItemDateFilters, PriorPeriodItemDateFilters);
                WasUpdated := true;
            end;
        end;

        if WasUpdated then begin
            Rec.LastUpdated := CurrentDate;
            Rec.Modify();
        end;
    end;

    local procedure IsUpdateNeededItemLedgerEntry(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
        if ItemLedgerEntry.FindLast() then
            if ItemLedgerEntry."Entry No." > Rec.ItemLedgerEntryNoLatest then begin
                Rec.ItemLedgerEntryNoLatest := ItemLedgerEntry."Entry No.";
                exit(true);
            end;

        exit(false);
    end;

    local procedure IsUpdateNeededValueEntry(): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        ValueEntry.SetRange("Item No.", Rec."Item No.");
        if ValueEntry.FindLast() then
            if ValueEntry."Entry No." > Rec.ValueEntryNoLatest then begin
                Rec.ValueEntryNoLatest := ValueEntry."Entry No.";
                exit(true);
            end;

        exit(false);
    end;

    local procedure UpdateForItemLedgerEntry(Item: Record Item; ItemDateFilters: array[4] of Text[30])
    var
        ItemStatistics: Codeunit "Item Statistics";
    begin
        ReturnRateThisPeriod := ItemStatistics.CalculateProductReturnRate(Item, ItemDateFilters[1]) / 100;
        ReturnRateThisFY := ItemStatistics.CalculateProductReturnRate(Item, ItemDateFilters[2]) / 100;
        ReturnRateLastFY := ItemStatistics.CalculateProductReturnRate(Item, ItemDateFilters[3]) / 100;
        ReturnRateLifetime := ItemStatistics.CalculateProductReturnRate(Item, ItemDateFilters[4]) / 100;
    end;

    local procedure UpdateForValueEntry(Item: Record Item; ItemDateFilters: array[4] of Text[30]; PriorPeriodItemDateFilters: array[4] of Text[30])
    var
        ItemStatistics: Codeunit "Item Statistics";
    begin
        CurrentInventoryValue := ItemStatistics.CalculateCurrentInventoryValue(Item);
        ExpiredStockValue := ItemStatistics.CalculateExpiredStockValue(Item);

        SalesGrowthRateThisPeriod := ItemStatistics.CalculateSalesGrowthRate(Item, ItemDateFilters[1], PriorPeriodItemDateFilters[1]) / 100;
        SalesGrowthRateThisFY := ItemStatistics.CalculateSalesGrowthRate(Item, ItemDateFilters[2], PriorPeriodItemDateFilters[2]) / 100;
        SalesGrowthRateLastFY := ItemStatistics.CalculateSalesGrowthRate(Item, ItemDateFilters[3], PriorPeriodItemDateFilters[3]) / 100;

        NetSalesLCYThisPeriod := ItemStatistics.CalculateNetSales(Item, ItemDateFilters[1]);
        NetSalesLCYThisFY := ItemStatistics.CalculateNetSales(Item, ItemDateFilters[2]);
        NetSalesLCYLastFY := ItemStatistics.CalculateNetSales(Item, ItemDateFilters[3]);
        NetSalesLCYLifetime := ItemStatistics.CalculateNetSales(Item, ItemDateFilters[4]);

        GrossMarginThisPeriod := ItemStatistics.CalculateGrossMarginPercentage(Item, ItemDateFilters[1]) / 100;
        GrossMarginThisFY := ItemStatistics.CalculateGrossMarginPercentage(Item, ItemDateFilters[2]) / 100;
        GrossMarginLastFY := ItemStatistics.CalculateGrossMarginPercentage(Item, ItemDateFilters[3]) / 100;
        GrossMarginLifetime := ItemStatistics.CalculateGrossMarginPercentage(Item, ItemDateFilters[4]) / 100;
    end;
}