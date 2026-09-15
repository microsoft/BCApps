// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Enum 1207 "Credit Transfer Account Type" defines the types of accounts that can receive credit transfers.
/// Used in credit transfer entries to specify whether the recipient is a customer, vendor, or employee.
/// </summary>
enum 1207 "Credit Transfer Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Customer account type for credit transfers to customers.
    /// </summary>
    value(0; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Vendor account type for credit transfers to vendors.
    /// </summary>
    value(1; "Vendor") { Caption = 'Vendor'; }
    /// <summary>
    /// Employee account type for credit transfers to employees.
    /// </summary>
    value(2; "Employee") { Caption = 'Employee'; }
}
