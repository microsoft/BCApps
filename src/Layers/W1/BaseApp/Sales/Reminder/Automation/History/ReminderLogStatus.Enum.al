// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Defines the execution status options for reminder automation log entries.
/// </summary>
enum 6751 "Reminder Log Status"
{
    Extensible = true;

    /// <summary>
    /// Represents an unspecified or initial status before processing begins.
    /// </summary>
    value(0; " ")
    {
    }
    /// <summary>
    /// Indicates that the reminder automation action is currently in progress.
    /// </summary>
    value(1; "Running")
    {
        Caption = 'Running';
    }
    /// <summary>
    /// Indicates that the reminder automation action failed to complete successfully.
    /// </summary>
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    /// <summary>
    /// Indicates that the reminder automation action completed successfully.
    /// </summary>
    value(3; Completed)
    {
        Caption = 'Completed';
    }
}