// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 6761 "Create Aut. Event Handler"
{
    EventSubscriberInstance = Manual;

    var
        GlobalReminderAction: Record "Reminder Action";
        RemindersCreatedTxt: Label '%1 reminders were created.', Comment = '%1 number of reminders created';
        NoRemindersCreatedTxt: Label 'No reminders were created.';
        NumberOfRemindersCreated: Integer;

    procedure SetReminderAction(var ReminderAction: Record "Reminder Action")
    begin
        GlobalReminderAction := ReminderAction;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reminders Action Job", 'OnCreateReminderSafe', '', false, false)]
    local procedure CreateReminderSafeHandler(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderHeader: Record "Reminder Header"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var FeeCustLedgEntryLine: Record "Cust. Ledger Entry"; var Success: Boolean)
    begin
        CreateReminders(Customer, CustLedgEntry, ReminderHeader, OverdueEntriesOnly, IncludeEntriesOnHold, FeeCustLedgEntryLine, Success);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure CreateReminders(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; var ReminderHeader: Record "Reminder Header"; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean; var FeeCustLedgEntryLine: Record "Cust. Ledger Entry"; var Success: Boolean)
    var
        ReminderMake: Codeunit "Reminder-Make";
    begin
        ReminderMake.Set(Customer, CustLedgEntry, ReminderHeader, OverdueEntriesOnly, IncludeEntriesOnHold, FeeCustLedgEntryLine);
        ReminderMake.Code();
        Success := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Make", 'OnMakeReminderOnBeforeReminderHeaderModify', '', false, false)]
    local procedure HandlerReminderCreated(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; var NextLineNo: Integer; MaxReminderLevel: Integer)
    var
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        NumberOfRemindersCreated += 1;
        ReminderActionProgress.UpdateStatusAndTotalRecordsProcessed(GlobalReminderAction, NumberOfRemindersCreated, StrSubstNo(RemindersCreatedTxt, NumberOfRemindersCreated));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reminder-Make", 'OnBeforeReminderHeaderModify', '', false, false)]
    local procedure BeforeReminderHeaderModify(var ReminderHeader: Record "Reminder Header"; var ReminderHeaderReq: Record "Reminder Header"; HeaderExists: Boolean; ReminderTerms: Record "Reminder Terms"; Customer: Record Customer; ReminderLevel: Record "Reminder Level"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        ReminderHeader."Reminder Automation Code" := GlobalReminderAction."Reminder Action Group Code";
        ReminderHeader.Modify();
    end;

    procedure UpdateStatusAfterRun()
    var
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if not ReminderActionProgress.GetLastActionEntry(GlobalReminderAction, ReminderActionLog) then
            ReminderActionProgress.CreateNewActionEntry(GlobalReminderAction, Enum::"Reminder Log Status"::Completed, ReminderActionLog);

        if NumberOfRemindersCreated = 0 then
            ReminderActionLog."Status summary" := NoRemindersCreatedTxt
        else
            ReminderActionLog."Status summary" := CopyStr(StrSubstNo(RemindersCreatedTxt, NumberOfRemindersCreated), 1, MaxStrLen(ReminderActionLog."Status summary"));

        ReminderActionLog.Modify();
    end;
}