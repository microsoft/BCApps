// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Manages the creation and updating of log entries to track reminder automation execution progress.
/// </summary>
codeunit 6751 "Reminder Action Progress"
{
    /// <summary>
    /// Creates a new log entry for tracking the execution of a reminder action group.
    /// </summary>
    /// <param name="ReminderActionGroup">Specifies the reminder action group to create a log entry for.</param>
    /// <param name="ReminderActionGroupLog">Returns the created reminder action group log record.</param>
    procedure CreateGroupEntry(var ReminderActionGroup: Record "Reminder Action Group"; var ReminderActionGroupLog: Record "Reminder Action Group Log")
    begin
        ReminderActionGroupLog."Reminder Action Group ID" := ReminderActionGroup.Code;
        ReminderActionGroupLog."Started On" := CurrentDateTime();
        ReminderActionGroupLog.Insert();
    end;

    /// <summary>
    /// Retrieves the most recent log entry for the specified reminder action group.
    /// </summary>
    /// <param name="ReminderActionGroupCode">Specifies the reminder action group code to find the last entry for.</param>
    /// <param name="ReminderActionGroupLog">Returns the last reminder action group log record if found.</param>
    /// <returns>True if a log entry was found; otherwise, false.</returns>
    procedure GetLastEntryForGroup(ReminderActionGroupCode: Code[50]; var ReminderActionGroupLog: Record "Reminder Action Group Log"): Boolean
    begin
        ReminderActionGroupLog.Reset();
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", ReminderActionGroupCode);
        ReminderActionGroupLog.SetCurrentKey("Run Id");
        exit(ReminderActionGroupLog.FindLast());
    end;

    /// <summary>
    /// Retrieves the most recent log entry for the specified reminder action in the current run.
    /// </summary>
    /// <param name="ReminderAction">Specifies the reminder action to find the last entry for.</param>
    /// <param name="ReminderActionLog">Returns the last reminder action log record if found.</param>
    /// <returns>True if a log entry was found; otherwise, false.</returns>
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

    /// <summary>
    /// Creates a new log entry for tracking the execution of a specific reminder action.
    /// </summary>
    /// <param name="ReminderAction">Specifies the reminder action to create a log entry for.</param>
    /// <param name="ReminderActionLogStatus">Specifies the initial status for the log entry.</param>
    /// <param name="ReminderActionLog">Returns the created reminder action log record.</param>
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

    /// <summary>
    /// Updates the status of an existing reminder action group log entry.
    /// </summary>
    /// <param name="ReminderActionGroupLog">Specifies the reminder action group log to update.</param>
    /// <param name="ReminderActionLogStatus">Specifies the new status for the log entry.</param>
    procedure UpdateGroupEntry(var ReminderActionGroupLog: Record "Reminder Action Group Log"; ReminderActionLogStatus: Enum "Reminder Log Status")
    begin
        ReminderActionGroupLog.Status := ReminderActionLogStatus;
        if ReminderActionGroupLog.Status in [ReminderActionGroupLog.Status::Failed, ReminderActionGroupLog.Status::Completed] then
            ReminderActionGroupLog."Completed On" := CurrentDateTime();
        ReminderActionGroupLog.Modify();
    end;

    /// <summary>
    /// Updates the status and last processed record of a reminder action log entry.
    /// </summary>
    /// <param name="ReminderAction">Specifies the reminder action whose log entry should be updated.</param>
    /// <param name="LastRecordID">Specifies the record ID of the last processed record.</param>
    /// <param name="ReminderActionLogStatus">Specifies the new status for the log entry.</param>
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

    /// <summary>
    /// Updates the total records processed count and status summary text for a reminder action log entry.
    /// </summary>
    /// <param name="ReminderAction">Specifies the reminder action whose log entry should be updated.</param>
    /// <param name="TotalRecordsProcessed">Specifies the total number of records processed so far.</param>
    /// <param name="StatusText">Specifies the status summary text to display.</param>
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