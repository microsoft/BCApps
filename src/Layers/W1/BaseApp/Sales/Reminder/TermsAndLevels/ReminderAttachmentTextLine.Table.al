// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

/// <summary>
/// Stores individual text lines for reminder attachment beginning and ending sections.
/// </summary>
table 504 "Reminder Attachment Text Line"
{
    Caption = 'Reminder Attachment Text Line';

    fields
    {
        /// <summary>
        /// Specifies the parent attachment text configuration to which this line belongs.
        /// </summary>
        field(1; Id; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the language code for this text line.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies whether this line appears at the beginning or ending of the attachment.
        /// </summary>
        field(3; Position; Option)
        {
            Caption = 'Position';
            OptionMembers = "Beginning Line","Ending Line";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the sequence number for ordering text lines within a position.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Contains the text content that appears on this line of the reminder attachment.
        /// </summary>
        field(5; Text; Text[100])
        {
            Caption = 'Text';
            ToolTip = 'Specifies the text of the reminder attachment ending line for the selected language.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; Id, "Language Code", Position, "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        if not ReminderAttachmentText.Get(Rec.Id, Rec."Language Code") then
            Error(MissingReminderAttachmentTextErr, Rec.Id, Rec."Language Code");
    end;

    var
        MissingReminderAttachmentTextErr: Label 'The reminder attachment text with a %1 ID and language code %2 doesn''t exist.', Comment = '%1=ID, %2=Language Code';
}