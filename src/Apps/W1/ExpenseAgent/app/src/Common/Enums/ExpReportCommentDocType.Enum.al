// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Specifies the type of document that an expense report comment line belongs to.
/// </summary>
enum 6920 "Exp. Report Comment Doc. Type"
{
    Caption = 'Expense Report Comment Document Type';

    value(0; "Expense Report")
    {
        Caption = 'Expense Report';
    }
    value(1; "Posted Expense Report")
    {
        Caption = 'Posted Expense Report';
    }
}