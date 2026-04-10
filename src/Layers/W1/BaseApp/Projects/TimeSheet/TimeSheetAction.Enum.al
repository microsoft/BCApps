// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

enum 953 "Time Sheet Action"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; "Submit")
    {
        Caption = 'Submit';
    }
    value(1; "Reopen Submitted")
    {
        Caption = 'Reopen Submitted';
    }
    value(2; "Approve")
    {
        Caption = 'Approve';
    }
    value(3; "Reopen Approved")
    {
        Caption = 'Reopen Approved';
    }
    value(4; "Reject")
    {
        Caption = 'Reject';
    }
}
