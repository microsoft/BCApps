// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Specifies what happens when an expense is older than the allowed age.
/// </summary>
enum 6982 "Expense Age Handling"
{
    Caption = 'Expense Age Handling';

    value(0; " ")
    {
        Caption = '';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Justification)
    {
        Caption = 'Justification';
    }
    value(3; Error)
    {
        Caption = 'Error';
    }
}