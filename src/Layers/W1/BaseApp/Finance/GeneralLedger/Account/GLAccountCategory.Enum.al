// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

enum 15 "G/L Account Category"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Assets)
    {
        Caption = 'Assets';
    }
    value(2; Liabilities)
    {
        Caption = 'Liabilities';
    }
    value(3; Equity)
    {
        Caption = 'Equity';
    }
    value(4; "Income")
    {
        Caption = 'Income';
    }
    value(5; "Cost of Goods Sold")
    {
        Caption = 'Cost of Goods Sold';
    }
    value(6; "Expense")
    {
        Caption = 'Expense';
    }
}
