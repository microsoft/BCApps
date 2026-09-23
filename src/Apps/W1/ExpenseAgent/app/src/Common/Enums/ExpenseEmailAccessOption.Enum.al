// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6903 "Expense Email Access Option"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Enable Agent to use my Email';

    value(0; Mailbox)
    {
        Caption = 'Mailbox';
    }
    value(1; Calendar)
    {
        Caption = 'Calendar';
    }
    value(2; "Mailbox+Calendar")
    {
        Caption = 'Mailbox+Calendar';
    }
}