// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Specifies which date is used to find the currency exchange rate for expenses.
/// </summary>
enum 6904 "Expense Exchange Rate"
{
    Extensible = false;
    Caption = 'Expense Exchange Rate';

    value(0; "Expense Date")
    {
        Caption = 'Expense Date';
    }
    value(1; "Posting Date")
    {
        Caption = 'Posting Date';
    }
}