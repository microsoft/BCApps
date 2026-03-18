// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;

codeunit 5823 "Cost Adjustment Item Runner"
{
    TableNo = Item;

    var
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CurrentCostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";

    trigger OnRun()
    var
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        UpdateAnalysisView: Codeunit "Update Analysis View";
    begin
        CurrentCostAdjustmentParamsMgt.GetParameters(CostAdjustmentParameter);
        InventoryAdjustmentHandler.SetFilterItem(Rec);
        InventoryAdjustmentHandler.MakeInventoryAdjustment(CurrentCostAdjustmentParamsMgt);

        if CostAdjustmentParameter."Post to G/L" then
            UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    procedure SetPostToGL(NewPostToGL: Boolean)
    begin
        CostAdjustmentParameter."Post to G/L" := NewPostToGL;
        CurrentCostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
    end;

    procedure SetParameters(var CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.")
    begin
        CurrentCostAdjustmentParamsMgt := CostAdjustmentParamsMgt;
        CurrentCostAdjustmentParamsMgt.GetParameters(CostAdjustmentParameter);
    end;
}
