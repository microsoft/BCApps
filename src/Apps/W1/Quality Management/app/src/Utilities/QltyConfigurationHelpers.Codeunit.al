// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Setup;

codeunit 20597 "Qlty. Configuration Helpers"
{
    /// <summary>
    /// The maximum recursion to use when creating inspections.
    /// Used for traversal on source table configuration when finding applicable generation rules, and also when populating source fields.
    /// 
    /// This limit prevents infinite loops in complex configuration hierarchies and ensures reasonable performance
    /// when traversing multi-level table relationships.
    /// </summary>
    /// <returns>The maximum recursion depth allowed (currently 20 levels)</returns>
    procedure GetArbitraryMaximumRecursion(): Integer
    begin
        exit(20);
    end;

    /// <summary>
    /// Returns the maximum number of rows to show in field lookup dialogs.
    /// Uses setup configuration if defined, otherwise defaults to 100.
    /// 
    /// Lookup order:
    /// 1. OnBeforeGetDefaultMaximumRowsToShowInLookup event (if handled)
    /// 2. Qlty. Management Setup."Max Rows Field Lookups" (if > 0)
    /// 3. Default value of 100
    /// </summary>
    /// <returns>Maximum number of rows for field lookups</returns>
    procedure GetDefaultMaximumRowsFieldLookup() ResultRowsCount: Integer
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
    /// <param name="Rows">The number of rows to show</param>
    /// <param name="Handled">Set to true if the event was handled</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultMaximumRowsToShowInLookup(var Rows: Integer; var Handled: Boolean)
    begin
    end;
}
