// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays a summary of attachment text configurations for reminder documents as a card part.
/// </summary>
page 833 "Reminder Attachment Text"
{
    Caption = 'Attachment Texts';
    PageType = CardPart;
    SourceTable = "Reminder Attachment Text";
    Editable = true;
    UsageCategory = None;
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(AttachmentTexts)
            {
                ShowCaption = false;
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'File Name';
                }
                field("Inline Fee Description"; Rec."Inline Fee Description")
                {
                    ApplicationArea = All;
                    Caption = 'Inline Fee Description';
                }
                field("Beginning Line"; Rec."Beginning Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Beginning Line';
                    Editable = false;
                    Enabled = false;
                }
                field("Ending Line"; Rec."Ending Lines")
                {
                    ApplicationArea = All;
                    Caption = 'Ending Line';
                    Editable = false;
                    Enabled = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Edit Text Lines")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Text Lines';
                ToolTip = 'Edit the attachment text lines that would be generated in the reminder.';
                Image = EditLines;

                trigger OnAction()
                var
                    ReminderAttachmentTLTerm: Page "Reminder Attachment T.L. Term";
                    ReminderAttachmentTLLevel: Page "Reminder Attachment T.L. Level";
                begin
                    case SourceRecord of
                        SourceRecord::"Reminder Term":
                            begin
                                ReminderAttachmentTLTerm.SetRecord(Rec);
                                ReminderAttachmentTLTerm.Run();
                            end;
                        SourceRecord::"Reminder Level":
                            begin
                                ReminderAttachmentTLLevel.SetRecord(Rec);
                                ReminderAttachmentTLLevel.Run();
                            end;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if LanguageCode = '' then
            exit;

        if not Rec.Get(Rec.Id, LanguageCode) then
            Error(NoAttachmentTextFoundErr, LanguageCode);
    end;

    var
        LanguageCode: Code[10];
        SourceRecord: Option "Reminder Term","Reminder Level";
        NoAttachmentTextFoundErr: Label 'No attachment text found for the selected language %1.', Comment = '%1 = Language code';

    internal procedure SetSourceDataAsTerm(SelectedLanguageCode: Code[10])
    begin
        LanguageCode := SelectedLanguageCode;
        SourceRecord := SourceRecord::"Reminder Term";
    end;

    internal procedure SetSourceDataAsLevel(SelectedLanguageCode: Code[10])
    begin
        LanguageCode := SelectedLanguageCode;
        SourceRecord := SourceRecord::"Reminder Level";
    end;
}