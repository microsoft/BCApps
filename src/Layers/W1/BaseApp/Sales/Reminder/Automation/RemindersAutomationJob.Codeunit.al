// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Threading;

codeunit 6750 "Reminders Automation Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        ReminderAction: Record "Reminder Action";
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
        ReminderActionInterface: Interface "Reminder Action";
        ErrorOccured: Boolean;
    begin
        InitializeRun(ReminderAction, Rec, ReminderActionGroupLog);
        Commit();

        if not ReminderAction.FindSet() then
            exit;

        repeat
            ReminderActionInterface := ReminderAction.GetReminderActionInterface();
            ReminderActionInterface.Invoke(ErrorOccured);
            if ErrorOccured and ReminderAction."Stop on Error" then begin
                ReminderActionProgress.UpdateGroupEntry(ReminderActionGroupLog, ReminderActionGroupLog.Status::Failed);
                Commit();
                exit;
            end;
            Commit();
            Clear(ErrorOccured);
        until ReminderAction.Next() = 0;

        ReminderActionProgress.UpdateGroupEntry(ReminderActionGroupLog, ReminderActionGroupLog.Status::Completed);
        Commit();
    end;

    local procedure InitializeRun(var ReminderAction: Record "Reminder Action"; var JobQueueEntry: Record "Job Queue Entry"; var ReminderActionGroupLog: Record "Reminder Action Group Log")
    var
        ReminderActionGroup: Record "Reminder Action Group";
    begin
        if not ReminderActionGroup.Get(JobQueueEntry."Record ID to Process") then
            exit;

        ReminderAction.SetRange("Reminder Action Group Code", ReminderActionGroup.Code);
        ReminderAction.SetCurrentKey(Order);
        ReminderAction.Ascending(true);
        InsertOrUpdateStatus(ReminderAction, JobQueueEntry, ReminderActionGroupLog, ReminderActionGroup);

        ReminderActionGroupLog.Status := ReminderActionGroupLog.Status::Running;
        ReminderActionGroupLog.Modify();
    end;

    local procedure InsertOrUpdateStatus(var ReminderAction: Record "Reminder Action"; var JobQueueEntry: Record "Job Queue Entry"; var ReminderActionGroupLog: Record "Reminder Action Group Log"; var ReminderActionGroup: Record "Reminder Action Group")
    var
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if JobQueueEntry."No. of Attempts to Run" > 0 then
            if ReminderActionProgress.GetLastEntryForGroup(ReminderActionGroup.Code, ReminderActionGroupLog) then begin
                ReminderAction.SetFilter(Order, '>=%1', ReminderActionGroupLog."Last Step ID");
                exit;
            end;

        ReminderActionProgress.CreateGroupEntry(ReminderActionGroup, ReminderActionGroupLog)
    end;
}