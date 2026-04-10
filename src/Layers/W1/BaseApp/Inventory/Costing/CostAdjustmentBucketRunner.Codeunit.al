// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

codeunit 5822 "Cost Adjustment Bucket Runner"
{
    TableNo = "Cost Adj. Item Bucket";

    trigger OnRun()
    var
        Item: Record Item;
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        if not LockTables() then
            exit;

        Item.SetFilter("No.", Rec."Item Filter");
        InventoryAdjustmentHandler.SetFilterItem(Item);
        SetCostAdjustmentParameters(CostAdjustmentParamsMgt, Rec);
        InventoryAdjustmentHandler.MakeInventoryAdjustment(CostAdjustmentParamsMgt);

        if Rec."Post to G/L" then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    local procedure LockTables(): Boolean
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        ItemApplicationEntry: Record "Item Application Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
    begin
        ItemApplicationEntry.LockTable();
        if ItemApplicationEntry.GetLastEntryNo() = 0 then
            exit(false);

        ItemLedgerEntry.LockTable();
        if ItemLedgerEntry.GetLastEntryNo() = 0 then
            exit(false);

        ValueEntry.LockTable();
        if ValueEntry.GetLastEntryNo() = 0 then
            exit(false);

        AvgCostEntryPointHandler.LockBuffer();

        exit(true);
    end;

    local procedure SetCostAdjustmentParameters(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt."; CostAdjItemBucket: Record "Cost Adj. Item Bucket");
    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
    begin
        CostAdjustmentParameter.Init();
        CostAdjustmentParameter."Online Adjustment" := false;
        CostAdjustmentParameter."Post to G/L" := CostAdjItemBucket."Post to G/L";
        CostAdjustmentParameter."Item-By-Item Commit" := false;
        if CostAdjItemBucket.Trace then
            CostAdjustmentParameter."Max Duration" := CostAdjItemBucket."Timeout (Minutes)" * 60 * 1000;
        OnAfterSetCostAdjustmentParameter(CostAdjustmentParameter);

        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        OnAfterSetCostAdjustmentParameterOnAfterSetParameters(CostAdjustmentParamsMgt);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostAdjustmentParameter(var CostAdjustmentParameter: Record "Cost Adjustment Parameter")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCostAdjustmentParameterOnAfterSetParameters(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    begin
    end;
}
