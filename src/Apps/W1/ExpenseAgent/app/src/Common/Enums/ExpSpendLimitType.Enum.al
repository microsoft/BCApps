// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6926 "Exp. Spend Limit Type"
{
    Access = Internal;
    Caption = 'Expense Spend Limit Type';

    value(0; User)
    {
        Caption = 'User';
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