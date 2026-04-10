// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays a read-only view of all communication text configurations for a reminder level or term.
/// </summary>
page 842 "Reminder View Communication"
{
    PageType = ListPlus;
    UsageCategory = None;
    Caption = 'Reminder View Communication Texts';
    SourceTable = "Reminder Attachment Text";
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    MultipleNewLines = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                part(ReminderAttachmentText; "Reminder View Attachment Text")
                {
                    Caption = 'Attachment Text';
                    ApplicationArea = All;
                    SubPageLink = Id = field(Id);
                }
                part(ReminderEmailText; "Reminder View Email Text")
                {
                    Caption = 'Email Text';
                    ApplicationArea = All;
                    SubPageLink = Id = field(Id);
                }
            }
        }
    }
}