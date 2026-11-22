// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Specifies how a missing receipt attachment is handled for an expense: not enforced, a warning, or an error.
/// </summary>
enum 6914 "Expense Attachment Enforcement"
{
    Caption = 'Attachment Enforcement';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Error)
    {
        Caption = 'Error';
    }
    value(3; "Not needed under limit")
    {
        Caption = 'Not needed under limit';
    }
}