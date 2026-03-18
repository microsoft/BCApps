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
            AutoFormatType = 0;
            ToolTip = 'Specifies the current inventory value (in local currency), calculated as the sum of Cost Amount (Actual) + Cost Amount (Expected) on posted Value Entries for this item. Run the Adjust Cost - Item Entries batch job to ensure the amount is up to date.';
        }
        field(6; "ExpiredStockValue"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the inventory value (in local currency) of quantities whose expiration date is earlier than the work date. Calculated as the sum of Cost Amount (Actual) + Cost Amount (Expected) from Value Entries applied to open Item Ledger Entries (Remaining Qty. > 0) with Expiration Date < Work Date. Run the Adjust Cost - Item Entries batch job to ensure the value is up to date. Only meaningful for items where expiration/lot dates are tracked.';
        }
        #region This period
        field(7; "SalesGrowthRateThisPeriod"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage change in sales compared to the previous period in the fiscal year, calculated as ((Sales in the current period in the fiscal year - Sales in the prior period in the fiscal year) ÷ Sales in the prior period in the fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';
        }
        field(8; "NetSalesLCYThisPeriod"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the total revenue (in local currency) from sales for the current period in fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the fiscal year. Calculated as: Net Sales = Total sales in the period  - Total returns - Total given discounts.';
        }
        field(9; "GrossMarginThisPeriod"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current period in the fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';
        }
        field(10; "ReturnRateThisPeriod"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current period in the fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';
        }
        #endregion
        #region This fiscal year
        field(11; "SalesGrowthRateThisFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in current fiscal year - Sales in the last fiscal year) ÷ Sales in the last fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';
        }
        field(12; "NetSalesLCYThisFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the total revenue (in local currency) from sales for the current fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the fiscal year. Calculated as: Net Sales = Total sales in the fiscal year - Total returns in the fiscal year - Total given discounts in the fiscal year.';
        }
        field(13; "GrossMarginThisFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';
        }
        field(14; "ReturnRateThisFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';
        }
        #endregion
        #region Last fiscal year
        field(15; "SalesGrowthRateLastFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in the last fiscal year - Sales in the prior fiscal year) ÷ Sales in the prior fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';
        }
        field(16; "NetSalesLCYLastFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the total revenue (in local currency) from sales for the last fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the last fiscal year. Calculated as: Net Sales = Total sales in the last fiscal year - Total returns in the last fiscal year - Total given discounts in the last fiscal year.';
        }
        field(17; "GrossMarginLastFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the last fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';
        }
        field(18; "ReturnRateLastFY"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of sold quantity that were returned during the last fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';
        }
        #endregion
        #region Lifetime
        field(19; "NetSalesLCYLifetime"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the total revenue (in local currency) from sales after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the lifetime. Calculated as: Net Sales = Total sales so far - Total returns so far - Total given discounts so far.';
        }
        field(20; "GrossMarginLifetime"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the lifetime. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';
        }
        field(21; "ReturnRateLifetime"; Decimal)
        {
            AutoFormatType = 0;
            ToolTip = 'Specifies the percentage of sold quantity that were returned during the lifetime. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';
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