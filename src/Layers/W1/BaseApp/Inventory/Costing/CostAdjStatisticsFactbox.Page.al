// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

page 5812 "Cost Adj. Statistics Factbox"
{
    PageType = CardPart;
    ApplicationArea = Basic, Suite;
    SourceTable = Item;
    Editable = false;
    Caption = 'Cost Adjustment Statistics';
    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = r,
                  tabledata "Inventory Adjmt. Entry (Order)" = r;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                Caption = 'No.';
                ToolTip = 'Specifies the item number';
                TableRelation = Item;
            }
            field(Description; Rec.Description)
            {
                Caption = 'Description';
                ToolTip = 'Specifies the description of the item';
            }
            field("Description 2"; Rec."Description 2")
            {
                Caption = 'Description 2';
                ToolTip = 'Specifies information in addition to the description.';
                Visible = false;
            }
            group("No. of Entries")
            {
                Caption = 'No. of Entries';

                field("Item Ledger Entries"; ItemEntries)
                {
                    Caption = 'Item ledger entries';
                    ToolTip = 'Specifies the number of item ledger entries for the item.';

                    trigger OnDrillDown()
                    begin
                        GetItemLedgerEntries(true);
                    end;
                }
                field("Entries Marked For Adjmt."; EntriesMarkedToAdjust)
                {
                    Caption = 'Entries marked for adjustment';
                    ToolTip = 'Specifies the number of inbound item ledger entries that will be processed by the next cost adjustment run.';

                    trigger OnDrillDown()
                    begin
                        GetEntriesMarkedToAdjust(true);
                    end;
                }
                field("Cost Adjmt. Entry Points"; AvgCostEntryPointsToAdjust)
                {
                    Caption = 'Cost adjmt. entry points';
                    ToolTip = 'Specifies the number of combinations of item, location, variant, and valuation date that will be processed by the next cost adjustment run.';

                    trigger OnDrillDown()
                    begin
                        GetAvgCostAdjmtEntryPoints(true);
                    end;
                }
                field("Earliest Date to Adjust"; EarliestDateToAdjust)
                {
                    Caption = 'Earliest date to adjust';
                    ToolTip = 'Specifies the earliest valuation date that will be processed by the next cost adjustment run.';
                }
                field("Production Orders to Adjust"; ProdOrdersToAdjust)
                {
                    Caption = 'Production orders to adjust';
                    ToolTip = 'Specifies the number of production orders that will be processed by the next cost adjustment run.';

                    trigger OnDrillDown()
                    begin
                        GetProductionOrdersToAdjust(true);
                    end;
                }
                field("Assembly Orders to Adjust"; AssemblyOrdersToAdjust)
                {
                    Caption = 'Assembly orders to adjust';
                    ToolTip = 'Specifies the number of assembly orders that will be processed by the next cost adjustment run.';

                    trigger OnDrillDown()
                    begin
                        GetAssemblyOrdersToAdjust(true);
                    end;
                }
            }
            group("Cost Adjustments")
            {
                Caption = 'Cost Adjustments';

                field(Runs; TotalRuns)
                {
                    Caption = 'Total runs';
                    ToolTip = 'Specifies the number of times that the cost adjustment process has been run for the item.';
                }
                field("Total Duration"; TotalDuration)
                {
                    Caption = 'Total duration';
                    ToolTip = 'Specifies the total duration of all cost adjustment runs for the item.';
                }
            }
        }
    }


    var
        ItemEntries, EntriesMarkedToAdjust, AvgCostEntryPointsToAdjust, ProdOrdersToAdjust, AssemblyOrdersToAdjust : Integer;
        EarliestDateToAdjust: Date;
        TotalRuns: Integer;
        TotalDuration: Duration;

    trigger OnAfterGetRecord()
    begin
        GetItemLedgerEntries(false);
        GetEntriesMarkedToAdjust(false);
        GetAvgCostAdjmtEntryPoints(false);
        GetProductionOrdersToAdjust(false);
        GetAssemblyOrdersToAdjust(false);
        GetItemAdjustmentStats();
    end;

    local procedure GetItemLedgerEntries(ShowEntries: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: Page "Item Ledger Entries";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.Ascending(false);
        ItemLedgerEntry.SetRange("Item No.", Rec."No.");
        if ShowEntries then begin
            ItemLedgerEntries.SetTableView(ItemLedgerEntry);
            ItemLedgerEntries.ShowCostAdjustmentActions();
            ItemLedgerEntries.Run();
            exit;
        end;
        ItemEntries := ItemLedgerEntry.Count();
    end;

    local procedure GetEntriesMarkedToAdjust(ShowEntries: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: Page "Item Ledger Entries";
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.", "Applied Entry to Adjust");
        ItemLedgerEntry.Ascending(false);
        ItemLedgerEntry.SetRange("Item No.", Rec."No.");
        ItemLedgerEntry.SetRange("Applied Entry to Adjust", true);
        if ShowEntries then begin
            ItemLedgerEntries.SetTableView(ItemLedgerEntry);
            ItemLedgerEntries.ShowCostAdjustmentActions();
            ItemLedgerEntries.Run();
            exit;
        end;
        EntriesMarkedToAdjust := ItemLedgerEntry.Count();
    end;

    local procedure GetAvgCostAdjmtEntryPoints(ShowEntries: Boolean)
    var
        AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        AvgCostAdjmtEntryPoint.SetCurrentKey("Item No.", "Cost Is Adjusted", "Valuation Date");
        AvgCostAdjmtEntryPoint.SetRange("Item No.", Rec."No.");
        AvgCostAdjmtEntryPoint.SetRange("Cost Is Adjusted", false);
        if ShowEntries then begin
            Page.RunModal(0, AvgCostAdjmtEntryPoint);
            exit;
        end;
        AvgCostEntryPointsToAdjust := AvgCostAdjmtEntryPoint.Count();
        if AvgCostAdjmtEntryPoint.FindFirst() then
            EarliestDateToAdjust := AvgCostAdjmtEntryPoint."Valuation Date"
        else
            EarliestDateToAdjust := 0D;
    end;

    local procedure GetProductionOrdersToAdjust(ShowEntries: Boolean)
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Production);
        InventoryAdjmtEntryOrder.SetRange("Is Finished", true);
        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Item No.", Rec."No.");
        if ShowEntries then begin
            Page.RunModal(0, InventoryAdjmtEntryOrder);
            exit;
        end;
        ProdOrdersToAdjust := InventoryAdjmtEntryOrder.Count();
    end;

    local procedure GetAssemblyOrdersToAdjust(ShowEntries: Boolean)
    var
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        InventoryAdjmtEntryOrder.SetRange("Order Type", InventoryAdjmtEntryOrder."Order Type"::Assembly);
        InventoryAdjmtEntryOrder.SetRange("Cost is Adjusted", false);
        InventoryAdjmtEntryOrder.SetRange("Item No.", Rec."No.");
        if ShowEntries then begin
            Page.RunModal(0, InventoryAdjmtEntryOrder);
            exit;
        end;
        AssemblyOrdersToAdjust := InventoryAdjmtEntryOrder.Count();
    end;

    local procedure GetItemAdjustmentStats()
    var
        CostAdjustmentDetailedLog: Record "Cost Adjustment Detailed Log";
    begin
        CostAdjustmentDetailedLog.SetRange("Item No.", Rec."No.");
        CostAdjustmentDetailedLog.CalcSums(Duration);
        TotalRuns := CostAdjustmentDetailedLog.Count();
        TotalDuration := CostAdjustmentDetailedLog.Duration;
    end;
}
