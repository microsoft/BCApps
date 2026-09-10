// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6900 "Expense Communication Channel"
{
    Access = Internal;
    Caption = 'Expense Communication Channel';

    value(0; Mail)
    {
        Caption = 'Mail';
    }
    value(1; Teams)
    {
        Caption = 'Teams';
    }
}