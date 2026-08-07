// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6906 "Expense Report Frequency"
{
    Access = Internal;
    Extensible = true;
    Caption = 'Expense Report Frequency';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Daily)
    {
        Caption = 'Daily';
    }
    value(2; "Weekly")
    {
        Caption = 'Weekly';
    }
    value(3; "Monthly")
    {
        Caption = 'Monthly';
    }
    value(4; Custom)
    {
        Caption = 'Custom';
    }
}