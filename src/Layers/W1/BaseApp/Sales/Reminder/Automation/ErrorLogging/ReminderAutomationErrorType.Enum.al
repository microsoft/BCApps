// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Specifies the type of action that failed during reminder automation processing.
/// </summary>
enum 6752 "Reminder Automation Error Type"
{
    Extensible = true;

    /// <summary>
    /// Indicates that an error occurred during the creation of reminder documents.
    /// </summary>
    value(1; "Create Reminder")
    {
        Caption = 'Create Reminder failed';
    }
    /// <summary>
    /// Indicates that an error occurred during the issuing of reminder documents.
    /// </summary>
    value(2; "Issue Reminder")
    {
        Caption = 'Issue Reminder failed';
    }
    /// <summary>
    /// Indicates that an error occurred during the sending of reminder documents.
    /// </summary>
    value(3; "Send Reminder")
    {
        Caption = 'Send Reminder failed';
    }
    /// <summary>
    /// Indicates that an error occurred when sending a reminder by email.
    /// </summary>
    value(4; "Email Reminder")
    {
        Caption = 'Email Reminder failed';
    }
    /// <summary>
    /// Indicates that an error occurred when printing a reminder document.
    /// </summary>
    value(5; "Print Reminder")
    {
        Caption = 'Print Reminder failed';
    }
}