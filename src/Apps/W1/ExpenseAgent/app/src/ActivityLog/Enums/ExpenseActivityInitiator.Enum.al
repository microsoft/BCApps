// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6923 "Expense Activity Initiator"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Activity Initiator';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; User)
    {
        Caption = 'User';
    }
    value(2; Agent)
    {
        Caption = 'Agent';
    }
}
