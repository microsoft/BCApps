// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

codeunit 5824 "Cost Adjustment Params Mgt."
{
    InherentPermissions = X;

    var
        CurrentCostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CurrentAvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point";
        CurrentInventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CurrentParameter: Variant;
        CurrentItemsToAdjust: List of [Code[20]];

    procedure SetParameters(var CostAdjustmentParameter: Record "Cost Adjustment Parameter")
    begin
        CurrentCostAdjustmentParameter.Copy(CostAdjustmentParameter);
    end;

    procedure GetParameters(var CostAdjustmentParameter: Record "Cost Adjustment Parameter")
    begin
        CostAdjustmentParameter.Copy(CurrentCostAdjustmentParameter);
    end;

    procedure SetAvgCostAdjmtEntryPoint(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
        CurrentAvgCostAdjmtEntryPoint.Copy(AvgCostAdjmtEntryPoint);
    end;

    procedure GetAvgCostAdjmtEntryPoint(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
        AvgCostAdjmtEntryPoint.Copy(CurrentAvgCostAdjmtEntryPoint);
    end;

    procedure SetInventoryAdjmtEntryOrder(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        CurrentInventoryAdjmtEntryOrder.Copy(InventoryAdjmtEntryOrder);
    end;

    procedure GetInventoryAdjmtEntryOrder(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        InventoryAdjmtEntryOrder.Copy(CurrentInventoryAdjmtEntryOrder);
    end;

    procedure SetItemsToAdjust(var ItemsToAdjust: List of [Code[20]])
    begin
        CurrentItemsToAdjust := ItemsToAdjust;
    end;

    procedure GetItemsToAdjust(var ItemsToAdjust: List of [Code[20]])
    begin
        ItemsToAdjust := CurrentItemsToAdjust;
    end;

    procedure SetParameter(var Parameter: Variant)
    begin
        CurrentParameter := Parameter;
    end;

    procedure GetParameter(var Parameter: Variant)
    begin
        Parameter := CurrentParameter;
    end;
}
