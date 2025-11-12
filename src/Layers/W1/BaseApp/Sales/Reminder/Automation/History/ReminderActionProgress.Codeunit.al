// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

codeunit 6751 "Reminder Action Progress"
{
    procedure CreateGroupEntry(var ReminderActionGroup: Record "Reminder Action Group"; var ReminderActionGroupLog: Record "Reminder Action Group Log")
    begin
        ReminderActionGroupLog."Reminder Action Group ID" := ReminderActionGroup.Code;
        ReminderActionGroupLog."Started On" := CurrentDateTime();
        ReminderActionGroupLog.Insert();
    end;

    procedure GetLastEntryForGroup(ReminderActionGroupCode: Code[50]; var ReminderActionGroupLog: Record "Reminder Action Group Log"): Boolean
    begin
        ReminderActionGroupLog.Reset();
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", ReminderActionGroupCode);
        ReminderActionGroupLog.SetCurrentKey("Run Id");
        exit(ReminderActionGroupLog.FindLast());
    end;

    procedure GetLastActionEntry(var ReminderAction: Record "Reminder Action"; var ReminderActionLog: Record "Reminder Action Log"): Boolean
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
    begin
        if not GetLastEntryForGroup(ReminderAction."Reminder Action Group Code", ReminderActionGroupLog) then
            exit(false);

        ReminderActionLog.SetRange("Reminder Action ID", ReminderAction.Code);
        ReminderActionLog.SetRange("Run Id", ReminderActionGroupLog."Run Id");
        ReminderActionLog.SetCurrentKey(Id);
        exit(ReminderActionLog.FindLast());
    end;

    procedure CreateNewActionEntry(var ReminderAction: Record "Reminder Action"; ReminderActionLogStatus: Enum "Reminder Log Status"; var ReminderActionLog: Record "Reminder Action Log")
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
    begin
        if not GetLastEntryForGroup(ReminderAction."Reminder Action Group Code", ReminderActionGroupLog) then
            Error(ThereIsNoLastReminderActionGroupLogErr);

        ReminderActionLog."Reminder Action Group ID" := ReminderAction."Reminder Action Group Code";
        ReminderActionLog."Run Id" := ReminderActionGroupLog."Run Id";
        ReminderActionLog."Reminder Action ID" := ReminderAction.Code;
        ReminderActionLog.Status := ReminderActionLogStatus;
        ReminderActionLog.Insert(true);
    end;

    procedure UpdateGroupEntry(var ReminderActionGroupLog: Record "Reminder Action Group Log"; ReminderActionLogStatus: Enum "Reminder Log Status")
    begin
        ReminderActionGroupLog.Status := ReminderActionLogStatus;
        if ReminderActionGroupLog.Status in [ReminderActionGroupLog.Status::Failed, ReminderActionGroupLog.Status::Completed] then
            ReminderActionGroupLog."Completed On" := CurrentDateTime();
        ReminderActionGroupLog.Modify();
    end;

    procedure UpdateActionEntry(var ReminderAction: Record "Reminder Action"; LastRecordID: RecordId; ReminderActionLogStatus: Enum "Reminder Log Status")
    var
        ReminderActionLog: Record "Reminder Action Log";
    begin
        if not GetLastActionEntry(ReminderAction, ReminderActionLog) then
            CreateNewActionEntry(ReminderAction, ReminderActionLogStatus, ReminderActionLog);

        ReminderActionLog.Status := ReminderActionLogStatus;
        ReminderActionLog."Last Record Processed" := LastRecordID;
        ReminderActionLog.Modify();
    end;

    procedure UpdateStatusAndTotalRecordsProcessed(var ReminderAction: Record "Reminder Action"; TotalRecordsProcessed: Integer; StatusText: Text)
    var
        ReminderActionLog: Record "Reminder Action Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        ReminderActionProgress.GetLastActionEntry(ReminderAction, ReminderActionLog);
        ReminderActionLog."Total Records Processed" := TotalRecordsProcessed;
        ReminderActionLog."Status summary" := CopyStr(StatusText, 1, MaxStrLen(ReminderActionLog."Status summary"));
        ReminderActionLog.Modify();
    end;

    var
        ThereIsNoLastReminderActionGroupLogErr: Label 'There is no action group for the specific reminder action log to be created.';
}