// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 6752 "Reminder Automation Error Type"
{
    Extensible = true;

    value(1; "Create Reminder")
    {
        Caption = 'Create Reminder failed';
    }
    value(2; "Issue Reminder")
    {
        Caption = 'Issue Reminder failed';
    }
    value(3; "Send Reminder")
    {
        Caption = 'Send Reminder failed';
    }
    value(4; "Email Reminder")
    {
        Caption = 'Email Reminder failed';
    }
    value(5; "Print Reminder")
    {
        Caption = 'Print Reminder failed';
    }
}