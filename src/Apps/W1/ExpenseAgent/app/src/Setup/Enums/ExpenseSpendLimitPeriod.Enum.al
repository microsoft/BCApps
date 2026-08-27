// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6926 "Expense Spend Limit Period"
{
    Extensible = true;

    value(0; Day)
    {
        Caption = 'Day';
    }
    value(1; Week)
    {
        Caption = 'Week';
    }
    value(2; Month)
    {
        Caption = 'Month';
    }
    value(3; Quarter)
    {
        Caption = 'Quarter';
    }
    value(4; Year)
    {
        Caption = 'Year';
    }
}
