// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 6750 "Reminder Action" implements "Reminder Action"
{
    Extensible = true;

    value(0; "Create Reminder")
    {
        Caption = 'Create Reminder';
        Implementation = "Reminder Action" = "Create Reminder Action";
    }
    value(1; "Issue Reminder")
    {
        Caption = 'Issue Reminder';
        Implementation = "Reminder Action" = "Issue Reminder Action";
    }
    value(2; "Send Reminder")
    {
        Caption = 'Send Reminder';
        Implementation = "Reminder Action" = "Send Reminder Action";
    }
}