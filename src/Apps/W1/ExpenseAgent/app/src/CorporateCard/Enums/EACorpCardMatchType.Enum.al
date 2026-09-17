// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 7223 "EA Corp Card Match Type"
{
    Caption = 'Corp Card Match Type';

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; Employee)
    {
        Caption = 'Employee';
    }
    value(2; Expense)
    {
        Caption = 'Expense';
    }
    value(3; Receipt)
    {
        Caption = 'Receipt';
    }
    value(4; Full)
    {
        Caption = 'Full';
    }
}