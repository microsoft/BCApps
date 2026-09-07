// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6922 "Expense Activity Event Type"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Activity Event Type';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Created)
    {
        Caption = 'Created';
    }
    value(2; ExpenseAddedToReport)
    {
        Caption = 'Expense added to report';
    }
    value(3; ExpenseRemovedFromReport)
    {
        Caption = 'Expense removed from report';
    }
    value(10; Submitted)
    {
        Caption = 'Submitted';
    }
    value(11; Resubmitted)
    {
        Caption = 'Resubmitted';
    }
    value(12; Recalled)
    {
        Caption = 'Recalled';
    }
    value(20; Approved)
    {
        Caption = 'Approved';
    }
    value(21; Rejected)
    {
        Caption = 'Rejected';
    }
    value(22; ReopenedByApprover)
    {
        Caption = 'Reopened by approver';
    }
    value(23; InterimApproverAssigned)
    {
        Caption = 'Interim approver assigned';
    }
    value(24; InterimApproved)
    {
        Caption = 'Interim approved';
    }
    value(30; CommentAdded)
    {
        Caption = 'Comment added';
    }
    value(40; PolicyEvaluated)
    {
        Caption = 'Policy evaluated';
    }
    value(50; Edited)
    {
        Caption = 'Edited';
    }
    value(100; Posted)
    {
        Caption = 'Posted';
    }
}
