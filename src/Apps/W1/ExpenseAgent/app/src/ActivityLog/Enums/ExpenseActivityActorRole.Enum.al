// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6924 "Expense Activity Actor Role"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Activity Actor Role';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Submitter)
    {
        Caption = 'Submitter';
    }
    value(2; Approver)
    {
        Caption = 'Approver';
    }
    value(3; Administrator)
    {
        Caption = 'Administrator';
    }
}
