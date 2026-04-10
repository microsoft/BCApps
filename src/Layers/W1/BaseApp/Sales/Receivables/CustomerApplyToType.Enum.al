// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Defines the method used to identify which customer ledger entries to apply, either by document number or by Applies-to ID.
/// </summary>
enum 234 "Customer Apply-to Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that no specific application method is selected.
    /// </summary>
    value(0; " ") { }
    /// <summary>
    /// Indicates that the application uses a specific document number to identify the entry to apply.
    /// </summary>
    value(1; "Applies-to Doc. No.") { }
    /// <summary>
    /// Indicates that the application uses an Applies-to ID to group multiple entries for application.
    /// </summary>
    value(2; "Applies-to ID") { }
}
