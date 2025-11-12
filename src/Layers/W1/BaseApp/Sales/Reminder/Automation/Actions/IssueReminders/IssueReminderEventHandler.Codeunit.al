// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 6756 "Issue Reminder Event Handler"
{
    Permissions = tabledata "Issued Reminder Header" = rmid;
    EventSubscriberInstance = Manual;

    var
        GlobalReminderAction: Record "Reminder Action";
        GlobalReminderActionProgress: Codeunit "Reminder Action Progress";
        NoRemindersIssuedTxt: Label 'No reminders were issued.';
        RemindersIssuedTxt: Label '%1 reminders were issued.', Comment = '%1 number of reminders issued';
        NumberOfIssuedReminders: Integer;

    internal procedure SetReminderAction(ReminderAction: Record "Reminder Action")
    begin
        GlobalReminderAction.Copy(ReminderAction);
    end;

    internal procedure SetReminderActionProgress(ReminderActionProgress: Codeunit "Reminder Action Progress")
    begin
        GlobalReminderActionProgress := ReminderActionProgress;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Issue Reminder Action Job", 'OnIssueReminderSafe', '', false, false)]
    local procedure HandleIssueReminderSafe(var ReminderHeader: Record "Reminder Header"; ReplacePostingDate: Boolean; NewPostingDate: Date; ReplaceVATDate: Boolean; NewVATDate: Date; var GenJournalBatch: Record "Gen. Journal Batch"; var Success: Boolean)
    begin
        IssueReminderSafe(ReminderHeader, ReplacePostingDate, NewPostingDate, ReplaceVATDate, NewVATDate, GenJournalBatch, Success);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure IssueReminderSafe(var ReminderHeader: Record "Reminder Header"; ReplacePostingDate: Boolean; NewPostingDate: Date; ReplaceVATDate: Boolean; NewVATDate: Date; var GenJournalBatch: Record "Gen. Journal Batch"; var Success: Boolean)
    var
        IssueReminder: Codeunit "Reminder-Issue";
    begin
        IssueReminder.Set(ReminderHeader, ReplacePostingDate, NewPostingDate, ReplaceVATDate, NewVATDate);
        IssueReminder.SetGenJnlBatch(GenJournalBatch);
        IssueReminder.Run();
        Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Issue", 'OnAfterIssueReminder', '', false, false)]
    local procedure UpdateStatusWhenReminderIsIssued(var ReminderHeader: Record "Reminder Header"; IssuedReminderNo: Code[20]; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        NumberOfIssuedReminders += 1;
        GlobalReminderActionProgress.UpdateStatusAndTotalRecordsProcessed(GlobalReminderAction, NumberOfIssuedReminders, StrSubstNo(RemindersIssuedTxt, NumberOfIssuedReminders));
        IssuedReminderHeader.Get(IssuedReminderNo);
        IssuedReminderHeader."Reminder Automation Code" := GlobalReminderAction."Reminder Action Group Code";
        IssuedReminderHeader.Modify();
    end;

    procedure UpdateStatusAfterRun()
    var
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if not ReminderActionProgress.GetLastActionEntry(GlobalReminderAction, ReminderActionLog) then
            ReminderActionProgress.CreateNewActionEntry(GlobalReminderAction, Enum::"Reminder Log Status"::Completed, ReminderActionLog);

        if NumberOfIssuedReminders = 0 then
            ReminderActionLog."Status summary" := NoRemindersIssuedTxt
        else
            ReminderActionLog."Status summary" := CopyStr(StrSubstNo(RemindersIssuedTxt, NumberOfIssuedReminders), 1, MaxStrLen(ReminderActionLog."Status summary"));
        ReminderActionLog.Modify();
    end;
}