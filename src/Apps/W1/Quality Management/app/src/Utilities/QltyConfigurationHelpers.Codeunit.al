// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Setup.Setup;

/// <summary>
/// Provides configuration-related helper utilities for Quality Management.
/// Handles retrieval of configuration values, limits, and setup parameters.
/// </summary>
codeunit 20598 "Qlty. Configuration Helpers"
{
    /// <summary>
    /// The maximum recursion to use when creating tests.
    /// Used for traversal on source table configuration when finding applicable generation rules, and also when populating source fields.
    /// 
    /// This limit prevents infinite loops in complex configuration hierarchies and ensures reasonable performance
    /// when traversing multi-level table relationships.
    /// </summary>
    /// <returns>The maximum recursion depth allowed (currently 20 levels)</returns>
    internal procedure GetArbitraryMaximumRecursion(): Integer
    begin
        exit(20);
    end;

    /// <summary>
    /// Retrieves the default maximum number of rows to display in field lookups.
    /// Checks Quality Management Setup for user-defined limit, falls back to default of 100.
    /// 
    /// This limit prevents performance issues when displaying large lookup lists.
    /// Can be overridden via OnBeforeGetDefaultMaximumRowsToShowInLookup event.
    /// </summary>
    /// <returns>The maximum number of rows to show in lookup fields</returns>
    internal procedure GetDefaultMaximumRowsFieldLookup() ResultRowsCount: Integer
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        Handled: Boolean;
    begin
        ResultRowsCount := 100;
        OnBeforeGetDefaultMaximumRowsToShowInLookup(ResultRowsCount, Handled);
        if Handled then
            exit;

        if not QltyManagementSetup.GetSetupRecord() then
            exit;

        if QltyManagementSetup."Max Rows Field Lookups" > 0 then
            ResultRowsCount := QltyManagementSetup."Max Rows Field Lookups";
    end;

    /// <summary>
    /// Provides an opportunity for customizations to alter the default maximum rows shown
    /// for a table lookup in a quality inspector field.
    /// Changing the default to a larger number can introduce performance issues.
    /// </summary>
    /// <param name="Rows">The number of rows to display</param>
    /// <param name="Handled">True if event subscriber handled the request</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultMaximumRowsToShowInLookup(var Rows: Integer; var Handled: Boolean)
    begin
    end;
}
