// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6986 "Expense Participant Type"
{
    Access = Internal;
    Caption = 'Participant Type';

    value(0; Employee)
    {
        Caption = 'Employee';
    }
    value(1; External)
    {
        Caption = 'External';
    }
}