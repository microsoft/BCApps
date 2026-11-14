// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Exp. Spend Limit Period"
{
    Access = Internal;
    Caption = 'Expense Spend Limit Period';

    value(0; Month)
    {
        Caption = 'Month';
    }
    value(1; Quarter)
    {
        Caption = 'Quarter';
    }
    value(2; Year)
    {
        Caption = 'Year';
    }
    value(3; "Accounting Period")
    {
        Caption = 'Accounting Period';
    }
}