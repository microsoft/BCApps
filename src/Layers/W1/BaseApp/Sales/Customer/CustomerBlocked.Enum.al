// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Defines the blocking levels for customers: no block, ship only, invoice only, or all transactions.
/// </summary>
enum 139 "Customer Blocked"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the customer is not blocked and all transactions are allowed.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Indicates that the customer is blocked from shipping transactions only.
    /// </summary>
    value(1; "Ship") { Caption = 'Ship'; }
    /// <summary>
    /// Indicates that the customer is blocked from invoicing transactions only.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Indicates that the customer is blocked from all sales transactions.
    /// </summary>
    value(3; "All") { Caption = 'All'; }
}
