// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 839 "Reminder View Attachment Text"
{
    PageType = ListPart;
    SourceTable = "Reminder Attachment Text";
    Caption = 'Attachment Text';
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code';
                    ToolTip = 'Specifies the language code for the text communications.';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Caption = 'File Name';
                    ToolTip = 'Specifies the file name of the attachment.';
                }
                field("Inline Fee Description"; Rec."Inline Fee Description")
                {
                    ApplicationArea = All;
                    Caption = 'Inline Fee Description';
                    ToolTip = 'Specifies the description line that will appear in the attachment along side the fee.';
                }
                field("Beginning Line"; HasBeginningLine)
                {
                    ApplicationArea = All;
                    Caption = 'Beginning Line';
                    ToolTip = 'Specifies the first line of the attachment.';
                }
                field("Ending Line"; HasEndingLine)
                {
                    ApplicationArea = All;
                    Caption = 'Ending Line';
                    ToolTip = 'Specifies the last line of the attachment.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
    begin
        HasBeginningLine := false;
        HasEndingLine := false;
        ReminderAttachmentTextLine.SetRange(Id, Rec.Id);
        ReminderAttachmentTextLine.SetRange("Language Code", Rec."Language Code");
        ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Beginning Line");
        if not ReminderAttachmentTextLine.IsEmpty() then
            HasBeginningLine := true;

        ReminderAttachmentTextLine.SetRange(Position, ReminderAttachmentTextLine.Position::"Ending Line");
        if not ReminderAttachmentTextLine.IsEmpty() then
            HasEndingLine := true;
    end;

    var
        HasBeginningLine: Boolean;
        HasEndingLine: Boolean;
}