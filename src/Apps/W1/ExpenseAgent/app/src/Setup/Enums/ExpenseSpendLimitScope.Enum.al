// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Expense Spend Limit Scope"
{
    Extensible = true;

    value(0; Employee)
    {
        Caption = 'Employee';
    }
    value(1; Team)
    {
        Caption = 'Team';
    }
    value(2; Company)
    {
        Caption = 'Company';
    }
}
