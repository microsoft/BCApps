// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5833 "Item Statistics"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Normal;

    /// <summary>
    /// Calculates the sales growth rate for an item over a specified period compared to a prior period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <param name="PriorPeriodDateFilter">Date filter for the prior period</param>
    /// <returns>Sales growth rate as a decimal</returns>
    internal procedure CalculateSalesGrowthRate(var Item: Record Item; DateFilterText: Text; PriorPeriodDateFilter: Text): Decimal
    var
        CurrentPeriodSales: Decimal;
        PreviousPeriodSales: Decimal;
    begin
        // Retrieve sales data for the previous periods
        PreviousPeriodSales := GetSalesAmount(Item, PriorPeriodDateFilter);

        // Retrieve sales data for the current period and calculate and return the sales growth rate
        if PreviousPeriodSales <> 0 then begin
            CurrentPeriodSales := GetSalesAmount(Item, DateFilterText);
            exit(((CurrentPeriodSales - PreviousPeriodSales) / PreviousPeriodSales) * 100);
        end;
        exit(0);
    end;

    /// <summary>
    /// Drilldown into detailed sales data for the current and prior periods to analyze sales growth.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <param name="PriorPeriodDateFilter">Date filter for the prior period</param>
    internal procedure DrilldownSalesGrowthRate(var Item: Record Item; DateFilterText: Text; PriorPeriodDateFilter: Text)
    begin
        // Filter and open sales data for current and prior periods
        DrilldownSalesAmount(Item, StrSubstNo('(%1)|(%2)', PriorPeriodDateFilter, DateFilterText));
    end;

    /// <summary>
    /// Calculates the net sales for an item over a specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <returns>Net sales as a decimal</returns>
    internal procedure CalculateNetSales(var Item: Record "Item"; DateFilterText: Text): Decimal
    var
        CurrentPeriodSales: Decimal;
    begin
        // Retrieve net sales data for the current period
        CurrentPeriodSales := GetSalesAmount(Item, DateFilterText);

        exit(CurrentPeriodSales);
    end;

    /// <summary>
    /// Calculates the gross margin percentage for an item over a specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <returns>Gross margin percentage as a decimal</returns>
    internal procedure CalculateGrossMarginPercentage(var Item: Record "Item"; DateFilterText: Text): Decimal
    var
        CurrentPeriodSales: Decimal;
        CurrentPeriodCost: Decimal;
    begin
        // Retrieve sales data for the current period
        CurrentPeriodSales := GetSalesAmount(Item, DateFilterText);
        if CurrentPeriodSales <> 0 then begin
            // Retrieve cost data for the current period
            CurrentPeriodCost := GetCostAmount(Item, DateFilterText);
            // Calculate and return the gross margin percentage
            exit(((CurrentPeriodSales - CurrentPeriodCost) / CurrentPeriodSales) * 100);
        end;
        exit(0);
    end;

    /// <summary>
    /// Calculates the product return rate for an item over a specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <returns>Product return rate as a decimal</returns>
    internal procedure CalculateProductReturnRate(var Item: Record "Item"; DateFilterText: Text): Decimal
    begin
        exit(GetProductReturnData(Item, DateFilterText));
    end;

    /// <summary>
    /// Drilldown into detailed item ledger entries to analyze product returns for the specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    internal procedure DrilldownProductReturnRate(var Item: Record "Item"; DateFilterText: Text)
    begin
        DrilldownProductReturnData(Item, DateFilterText);
    end;

    /// <summary>
    /// Calculates the current inventory value for an item based on its value entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <returns>Current inventory value as a decimal</returns>
    internal procedure CalculateCurrentInventoryValue(var Item: Record "Item"): Decimal
    begin
        exit(GetItemValueAmount(Item));
    end;

    /// <summary>
    /// Drilldown into detailed value entries to analyze the current inventory value for the item.
    /// </summary>
    /// <param name="Item">Item record</param>
    internal procedure DrilldownCurrentInventoryValue(var Item: Record "Item")
    begin
        DrilldownItemValueAmount(Item);
    end;

    /// <summary>
    /// Calculates the value of expired stock for an item based on its item to value entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <returns>Expired stock value as a decimal</returns>
    internal procedure CalculateExpiredStockValue(var Item: Record Item): Decimal
    var
        ItemToValueEntries: Query "Item to Value Entries";
        EmptyTextLbl: Label '''''';
        FilterText: Text;
    begin
        FilterText := StrSubstNo('<>%1 & < %2', EmptyTextLbl, WorkDate());
        ItemToValueEntries.SetRange(Item_No, Item."No.");
        ItemToValueEntries.SetFilter(Expiration_Date, FilterText);
        ItemToValueEntries.SetFilter(Remaining_Quantity, '>0');
        ItemToValueEntries.Open();
        if ItemToValueEntries.Read() then
            exit(ItemToValueEntries.Cost_Amount__Actual_ + ItemToValueEntries.Cost_Amount__Expected);
    end;

    /// <summary>
    /// Drilldown into detailed item ledger entries to analyze the expired stock value for the item.
    /// </summary>
    /// <param name="Item">Item record</param>
    internal procedure DrilldownExpiredStockValue(var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EmptyTextLbl: Label '''''';
        FilterText: Text;
    begin
        FilterText := StrSubstNo('<>%1 & < %2', EmptyTextLbl, WorkDate());
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Expiration Date", FilterText);
        ItemLedgerEntry.SetFilter("Remaining Quantity", '>0');
        Page.RunModal(0, ItemLedgerEntry);
    end;

    /// <summary>
    /// Gets the sales amount for an item based on its value entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    local procedure GetSalesAmount(var Item: Record Item; DateFilterText: Text): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Posting Date", DateFilterText);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.CalcSums("Sales Amount (Actual)", "Sales Amount (Expected)");
        exit(ValueEntry."Sales Amount (Actual)" + ValueEntry."Sales Amount (Expected)");
    end;

    /// <summary>
    /// Drilldown into detailed sales data for an item over a specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    internal procedure DrilldownSalesAmount(var Item: Record Item; DateFilterText: Text)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Posting Date", DateFilterText);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.CalcSums("Sales Amount (Actual)", "Sales Amount (Expected)");
        Page.RunModal(0, ValueEntry);
    end;

    /// <summary>
    /// Gets the cost amount for an item based on its value entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <returns>Cost amount as a decimal</returns>
    local procedure GetCostAmount(var Item: Record Item; DateFilterText: Text): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetFilter("Posting Date", DateFilterText);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(-(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)"));
    end;

    /// <summary>
    /// Gets the current inventory value for an item based on its value entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <returns>Inventory value as a decimal</returns>
    local procedure GetItemValueAmount(var Item: Record Item): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        exit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)");
    end;

    /// <summary>
    /// Drilldown into detailed value entries to analyze the current inventory value for the item.
    /// </summary>
    /// <param name="Item">Item record</param>
    local procedure DrilldownItemValueAmount(var Item: Record Item)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetRange("Item No.", Item."No.");
        Page.RunModal(0, ValueEntry);
    end;

    /// <summary>
    /// Gets the product return data for an item based on its item ledger entries.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    /// <returns>Product return data as a decimal</returns>
    local procedure GetProductReturnData(var Item: Record Item; DateFilterText: Text): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitsSold: Decimal;
        UnitsReturned: Decimal;
    begin
        ItemLedgerEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Posting Date", DateFilterText);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange(Positive, false); // Only Sales
        ItemLedgerEntry.CalcSums(Quantity);
        UnitsSold := -ItemLedgerEntry.Quantity; // Sales are negative quantities

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Posting Date", DateFilterText);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange(Positive, true); // Only Returns
        ItemLedgerEntry.CalcSums(Quantity); // Sum of positive quantities
        UnitsReturned := ItemLedgerEntry.Quantity;
        if UnitsSold <> 0 then
            exit((UnitsReturned / UnitsSold) * 100);

        exit(0);
    end;

    /// <summary>
    /// Drilldown into detailed item ledger entries to analyze product returns for the specified period.
    /// </summary>
    /// <param name="Item">Item record</param>
    /// <param name="DateFilterText">Date filter for the current period</param>
    local procedure DrilldownProductReturnData(var Item: Record Item; DateFilterText: Text)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetFilter("Posting Date", DateFilterText);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Page.RunModal(0, ItemLedgerEntry);
    end;

}
