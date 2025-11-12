// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

table 504 "Reminder Attachment Text Line"
{
    Caption = 'Reminder Attachment Text Line';

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
            DataClassification = SystemMetadata;
        }
        field(3; Position; Option)
        {
            Caption = 'Position';
            OptionMembers = "Beginning Line","Ending Line";
            DataClassification = SystemMetadata;
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(5; Text; Text[100])
        {
            Caption = 'Text';
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