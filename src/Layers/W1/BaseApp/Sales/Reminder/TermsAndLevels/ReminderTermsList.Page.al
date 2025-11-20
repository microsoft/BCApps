// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 837 "Reminder Terms List"
{
    ApplicationArea = All;
    Caption = 'Reminder Terms';
    PageType = List;
    SourceTable = "Reminder Terms";
#if not CLEAN26
    UsageCategory = None;
#else
    UsageCategory = Lists;
#endif
    CardPageID = "Reminder Terms Setup";
    DataCaptionFields = Code;
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    Caption = 'Code';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this set of reminder terms.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the reminder terms.';
                }
                field("Max. No. of Reminders"; Rec."Max. No. of Reminders")
                {
                    Caption = 'Maximum Number of Reminders';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of reminders that can be created for an invoice.';
                }
                field("Post Interest"; Rec."Post Interest")
                {
                    Caption = 'Post Interest';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any interest listed on the reminder to the general ledger and customer accounts.';
                }
                field("Post Additional Fee"; Rec."Post Additional Fee")
                {
                    Caption = 'Post Additional Fee';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any additional fee listed on the reminder to the general ledger and customer accounts.';
                }
                field("Post Add. Fee per Line"; Rec."Post Add. Fee per Line")
                {
                    Caption = 'Post Additional Fee per Line';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to post any additional fee listed on the finance charge memo to the general ledger and customer accounts when the memo is issued.';
                }
                field("Minimum Amount (LCY)"; Rec."Minimum Amount (LCY)")
                {
                    Caption = 'Minimum Amount (LCY)';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum amount for which a reminder will be created.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reminders)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reminders';
                Image = Reminder;
                Tooltip = 'Open the list of Reminders.';

                trigger OnAction()
                var
                    ReminderHeader: Record "Reminder Header";
                begin
                    FilterRemindersBasedOnSelectedReminderTerms(ReminderHeader);
                    Page.Run(Page::"Reminder List", ReminderHeader);
                end;
            }
            action(IssuedReminders)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Issued Reminders';
                Image = Reminder;
                Tooltip = 'Open the list of Issued Reminders.';

                trigger OnAction()
                var
                    IssuedReminderHeader: Record "Issued Reminder Header";
                begin
                    FilterIssuedRemindersBasedOnSelectedReminderTerms(IssuedReminderHeader);
                    Page.Run(Page::"Issued Reminder List", IssuedReminderHeader);
                end;
            }
            action(TransferOldTexts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Transfer texts';
                Image = Reminder;
                Tooltip = 'Copy the existing reminder text and translations to the new communication tables.';

                trigger OnAction()
                var
                    ReminderAttachmentText: Record "Reminder Attachment Text";
                    ReminderCommunication: Codeunit "Reminder Communication";
                begin
                    if ReminderAttachmentText.Count() > 0 then
                        if not Confirm(OverwriteExistinTextMsg) then
                            exit;
                    ReminderCommunication.TransferReminderText();
                    ReminderCommunication.TransferReminderTermsTranslations();
                    ReminderCommunication.TransferReminderTermsLineFeeDescription();
                    ReminderCommunication.TransferReminderLevelLineFeeDescription();
                    Message(FinishedTransferMsg);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Reminders_Promoted; Reminders)
                {
                }
                actionref(IssuedReminders_Promoted; IssuedReminders)
                {
                }
            }
        }
    }

    var
        ReminderTermsNotSelectedErr: Label 'You need to select one Reminder Term.';
        OverwriteExistinTextMsg: Label 'This action will overwrite any existing reminder texts and translations that you have setup for the new communication tables. Do you want to continue?';
        FinishedTransferMsg: Label 'The reminder texts and translations have been transferred to the new communication tables.';

    local procedure FilterRemindersBasedOnSelectedReminderTerms(var ReminderHeader: Record "Reminder Header")
    var
        ReminderTerms: Record "Reminder Terms";
        RemindersTermCodeFilter: Text;
        FirstEntry: Boolean;
    begin
        CurrPage.SetSelectionFilter(ReminderTerms);
        if ReminderTerms.IsEmpty() then
            Error(ReminderTermsNotSelectedErr);

        ReminderTerms.FindSet();
        FirstEntry := true;
        repeat
            if FirstEntry then begin
                FirstEntry := false;
                RemindersTermCodeFilter := ReminderTerms.Code;
            end
            else
                RemindersTermCodeFilter += '|' + ReminderTerms.Code;
        until ReminderTerms.Next() = 0;
        ReminderHeader.SetFilter("Reminder Terms Code", RemindersTermCodeFilter);
        if not ReminderHeader.IsEmpty() then
            ReminderHeader.FindSet();
    end;

    local procedure FilterIssuedRemindersBasedOnSelectedReminderTerms(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        ReminderTerms: Record "Reminder Terms";
        RemindersTermCodeFilter: Text;
        FirstEntry: Boolean;
    begin
        CurrPage.SetSelectionFilter(ReminderTerms);
        if ReminderTerms.IsEmpty() then
            Error(ReminderTermsNotSelectedErr);

        ReminderTerms.FindSet();
        FirstEntry := true;
        repeat
            if FirstEntry then begin
                FirstEntry := false;
                RemindersTermCodeFilter := ReminderTerms.Code;
            end
            else
                RemindersTermCodeFilter += '|' + ReminderTerms.Code;
        until ReminderTerms.Next() = 0;
        IssuedReminderHeader.SetFilter("Reminder Terms Code", RemindersTermCodeFilter);
        if not IssuedReminderHeader.IsEmpty() then
            IssuedReminderHeader.FindSet();
    end;
}

