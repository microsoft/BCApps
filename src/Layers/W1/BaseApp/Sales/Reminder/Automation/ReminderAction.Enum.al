// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Defines the available automation action types for reminder processing: create, issue, and send.
/// </summary>
enum 6750 "Reminder Action" implements "Reminder Action"
{
    Extensible = true;

    /// <summary>
    /// Specifies the action to create reminder documents for customers with overdue entries.
    /// </summary>
    value(0; "Create Reminder")
    {
        Caption = 'Create Reminder';
        Implementation = "Reminder Action" = "Create Reminder Action";
    }
    /// <summary>
    /// Specifies the action to issue draft reminders, making them official and posting related entries.
    /// </summary>
    value(1; "Issue Reminder")
    {
        Caption = 'Issue Reminder';
        Implementation = "Reminder Action" = "Issue Reminder Action";
    }
    /// <summary>
    /// Specifies the action to send issued reminders to customers via email or print.
    /// </summary>
    value(2; "Send Reminder")
    {
        Caption = 'Send Reminder';
        Implementation = "Reminder Action" = "Send Reminder Action";
    }
}