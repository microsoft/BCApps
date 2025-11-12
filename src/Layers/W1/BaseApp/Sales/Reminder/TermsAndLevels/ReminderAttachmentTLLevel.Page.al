// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 549 "Reminder Attachment T.L. Level"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Reminder Attachment Text";
    Caption = 'Reminder Attachment Text Line List';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field(ReminderTermCode; ReminderTermCode)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Reminder Term Code';
                    ToolTip = 'Specifies the reminder code of the reminder level for the beginning and ending lines.';
                    Enabled = false;
                    Editable = false;
                }
                field(ReminderLevelNo; ReminderLevelNo)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Reminder Level';
                    ToolTip = 'Specifies the position of the reminder level in the reminder level hierarchy for the beginning and ending lines.';
                    Enabled = false;
                    Editable = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Language Code';
                    ToolTip = 'Specifies the language code of the beginning and ending lines.';
                    Enabled = false;
                    Editable = false;
                }
            }
            part(BeginningLines; "Reminder Attach Beginning Line")
            {
                Caption = 'Beginning Lines';
                ApplicationArea = All;
                SubPageLink = Id = field(Id),
                             "Language Code" = field("Language Code"),
                             Position = const("Beginning Line");
            }
            part(EndingLines; "Reminder Attach Ending Line")
            {
                Caption = 'Ending Lines';
                ApplicationArea = All;
                SubPageLink = Id = field(Id),
                             "Language Code" = field("Language Code"),
                             Position = const("Ending Line");
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.SetRange("Reminder Attachment Text", Rec.Id);
        if not ReminderLevel.FindFirst() then
            Error(NoReminderTermFoundErr);
        ReminderTermCode := ReminderLevel."Reminder Terms Code";
        ReminderLevelNo := ReminderLevel."No.";
    end;

    var
        ReminderTermCode: Code[10];
        ReminderLevelNo: Integer;
        NoReminderTermFoundErr: Label 'No reminder level found for the current reminder attachment text.';
}