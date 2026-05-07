// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Utilities;

using Microsoft.QualityManagement.Setup;

/// <summary>
/// Provides configuration-related helper functions for Quality Management.
/// Handles system limits, defaults, and configuration value retrieval.
/// 
/// This codeunit follows the Single Responsibility Principle by focusing solely
/// on configuration concerns: limits, defaults, and setup-driven values.
/// </summary>
codeunit 20432 "Qlty. Configuration Helpers"
{
    Access = Internal;

    #region Recursion Limits

    /// <summary>
    /// The maximum recursion to use when creating inspections.
    /// Used for traversal on source table configuration when finding applicable generation rules, 
    /// and also when populating source fields.
    /// 
    /// This limit prevents infinite loops in complex configuration hierarchies and ensures 
    /// reasonable performance when traversing multi-level table relationships.
    /// </summary>
    /// <returns>The maximum recursion depth allowed (currently 20 levels)</returns>
    procedure GetArbitraryMaximumRecursion(): Integer
    begin
        exit(20);
    end;

    #endregion Recursion Limits

    #region Field Lookup Limits

    /// <summary>
    /// Gets the maximum number of rows to return for field lookups.
    /// First checks if a value is configured in Quality Management Setup;
    /// if not configured or zero, returns the system default (100).
    /// 
    /// This limit prevents excessive data retrieval in lookup scenarios
    /// and ensures reasonable UI performance.
    /// </summary>
    /// <returns>The configured or default maximum rows for field lookups</returns>
    procedure GetDefaultMaximumRowsFieldLookup(): Integer
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
    begin
        if QltyManagementSetup.GetSetupRecord() then
            if QltyManagementSetup."Max Rows Field Lookups" > 0 then
                exit(QltyManagementSetup."Max Rows Field Lookups");

        exit(100);
    end;

    /// <summary>
    /// Returns the system default for maximum rows in field lookups.
    /// This is the fallback value when no setup configuration exists.
    /// </summary>
    /// <returns>The default maximum rows (100)</returns>
    procedure GetDefaultMaxRowsFieldLookupConstant(): Integer
    begin
        exit(100);
    end;

    #endregion Field Lookup Limits

    #region Record Fetch Limits

    /// <summary>
    /// Returns the absolute maximum number of records that can be fetched in a single operation.
    /// This is a safety limit to prevent runaway queries.
    /// </summary>
    /// <returns>The maximum record fetch limit (1000)</returns>
    procedure GetMaxRecordsFetchLimit(): Integer
    begin
        exit(1000);
    end;

    #endregion Record Fetch Limits
}
