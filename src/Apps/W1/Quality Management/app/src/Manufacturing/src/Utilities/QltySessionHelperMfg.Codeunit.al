// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.Manufacturing.Document;

/// <summary>
/// This exists to help keep track of variables to work around a variety of BC issues.
/// </summary>
codeunit 20431 "Qlty. Session Helper - Mfg."
{
    SingleInstance = true;
    InherentPermissions = X;

    var
        ProductionOrderBeforeChangingStatus: Record "Production Order";

    #region Manufacturing - Production Order Status Change Handling
    internal procedure SetProductionOrderBeforeChangingStatus(var ProductionOrderToSet: Record "Production Order")
    begin
        ProductionOrderBeforeChangingStatus := ProductionOrderToSet;
    end;

    internal procedure GetProductionOrderBeforeChangingStatus(var ProductionOrderToGet: Record "Production Order")
    begin
        ProductionOrderToGet := ProductionOrderBeforeChangingStatus;
    end;
    #endregion Manufacturing - Production Order Status Change Handling

}