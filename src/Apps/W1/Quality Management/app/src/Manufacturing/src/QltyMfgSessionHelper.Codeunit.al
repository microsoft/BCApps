// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

using Microsoft.Manufacturing.Document;

/// <summary>
/// Helper for managing manufacturing-specific session state in Quality Management.
/// </summary>
codeunit 20471 "Qlty. Mfg. Session Helper"
{
    SingleInstance = true;
    InherentPermissions = X;

    var
        ProductionOrderBeforeChangingStatus: Record "Production Order";

    #region Manufacturing - Production Order Status Change Handling
    /// <summary>
    /// Sets the production order before status change for tracking purposes.
    /// </summary>
    /// <param name="ProductionOrderToSet">The production order to store</param>
    internal procedure SetProductionOrderBeforeChangingStatus(var ProductionOrderToSet: Record "Production Order")
    begin
        ProductionOrderBeforeChangingStatus := ProductionOrderToSet;
    end;

    /// <summary>
    /// Gets the previously stored production order before status change.
    /// </summary>
    /// <param name="ProductionOrderToGet">The production order to retrieve</param>
    internal procedure GetProductionOrderBeforeChangingStatus(var ProductionOrderToGet: Record "Production Order")
    begin
        ProductionOrderToGet := ProductionOrderBeforeChangingStatus;
    end;
    #endregion Manufacturing - Production Order Status Change Handling
}
