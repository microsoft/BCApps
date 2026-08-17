// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

interface "Cost Adjustment With Params" extends "Inventory Adjustment"
{
    /// <summary>
    /// The method run inventory cost adjustment codeunit. 
    /// </summary>
    procedure MakeMultiLevelAdjmt(var CostAdjustmentParameter: Codeunit "Cost Adjustment Params Mgt.")
}