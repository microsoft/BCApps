// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Approval status of a VAT reclaim row on an expense report line.
/// </summary>
enum 6988 "Expense Reclaim Status"
{
    Extensible = false;

    value(0; "Pending")
    {
        Caption = 'Pending';
    }
    value(1; Approved)
    {
        Caption = 'Approved';
    }
    value(2; Rejected)
    {
        Caption = 'Rejected';
    }
}
