// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6908 "Expense Justification"
{
    Access = Internal;
    Caption = 'Justification Mandatory';

    value(0; " ")
    {
        Caption = 'None';
    }
    value(1; Always)
    {
        Caption = 'Always';
    }
    value(2; "Against Conditions")
    {
        Caption = 'Against Conditions';
    }
}