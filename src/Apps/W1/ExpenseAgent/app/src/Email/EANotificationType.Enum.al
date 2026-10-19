// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

enum 6985 "EA Notification Type"
{
    Extensible = false;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; Welcome)
    {
        Caption = 'Welcome';
    }
    value(2; Reminder)
    {
        Caption = 'Reminder';
    }
    value(3; Reimbursement)
    {
        Caption = 'Reimbursement';
    }
    value(4; Approval)
    {
        Caption = 'Approval';
    }
}
