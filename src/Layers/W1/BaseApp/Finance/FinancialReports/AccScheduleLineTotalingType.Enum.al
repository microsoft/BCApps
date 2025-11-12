// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#pragma warning disable AL0659
enum 85 "Acc. Schedule Line Totaling Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Posting Accounts")
    {
        Caption = 'Posting Accounts';
    }
    value(1; "Total Accounts")
    {
        Caption = 'Total Accounts';
    }
    value(2; Formula)
    {
        Caption = 'Formula';
    }
    value(5; "Set Base For Percent")
    {
        Caption = 'Set Base For Percent';
    }
    value(6; "Cost Type")
    {
        Caption = 'Cost Type';
    }
    value(7; "Cost Type Total")
    {
        Caption = 'Cost Type Total';
    }
    value(8; "Cash Flow Entry Accounts")
    {
        Caption = 'Cash Flow Entry Accounts';
    }
    value(9; "Cash Flow Total Accounts")
    {
        Caption = 'Cash Flow Total Accounts';
    }
    value(10; "Account Category")
    {
        Caption = 'Account Category';
    }
}
