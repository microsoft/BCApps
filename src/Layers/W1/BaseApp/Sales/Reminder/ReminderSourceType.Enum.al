// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Specifies the type of source data for a reminder line, such as G/L account or customer ledger entry.
/// </summary>
enum 296 "Reminder Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Represents an unspecified or blank source type.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Indicates that the reminder line is sourced from a general ledger account.
    /// </summary>
    value(1; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Indicates that the reminder line is sourced from a customer ledger entry.
    /// </summary>
    value(2; "Customer Ledger Entry") { Caption = 'Customer Ledger Entry'; }
    /// <summary>
    /// Indicates that the reminder line represents a line fee charge.
    /// </summary>
    value(3; "Line Fee") { Caption = 'Line Fee'; }
}
