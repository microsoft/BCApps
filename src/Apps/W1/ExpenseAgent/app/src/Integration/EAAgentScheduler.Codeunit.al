// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Email;
using System.Security.AccessControl;
using System.Telemetry;

codeunit 6935 "EA Agent Scheduler"
{
    Access = Internal;
    Permissions = tabledata "Email Inbox" = rd, tabledata User = R;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CannotCreateTaskErr: Label 'The current user does not have permission to create scheduled tasks. Contact your administrator.';
        TelemetryEASetupRecordNotValidLbl: Label 'EA Setup record is not valid.', Locked = true;
        TelemetryAgentScheduledTaskCancelledLbl: Label 'Agent scheduled task cancelled.', Locked = true;
        TelemetryRecoveryScheduledTaskCancelledLbl: Label 'Recovery scheduled task cancelled.', Locked = true;
        TelemetryAgentScheduledLbl: Label 'Agent scheduled.', Locked = true;
        HasNoAccessControlErr: Label 'Expense agent setup page specifies that you cannot configure the agent.';

    internal procedure ScheduleAgent(EASetup: Record "Expense Agent Setup")
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
        ExpenseAgentAccessControl: Record "Expense Agent Access Control";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if IsNullGuid(EASetup.SystemId) then begin
            FeatureTelemetry.LogError('0000QL1', EASetup.GetFeatureName(), 'Invalid EA Setup', TelemetryEASetupRecordNotValidLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        if not TaskScheduler.CanCreateTask() then
            Error(CannotCreateTaskErr);

        ExpenseAgentAccessControl.ReadIsolation(IsolationLevel::UpdLock);

        if not ExpenseAgentAccessControl.GetByUserSecurityID(UserSecurityID()) then
            Error(HasNoAccessControlErr);
        if not ExpenseAgentAccessControl."Can Configure Agent" then
            Error(HasNoAccessControlErr);
        if not ExpenseAgentAccessControl."Can Work on Behalf" then begin
            ExpenseAgentAccessControl.Validate("Can Work on Behalf", true);  // automatically disables the other(s)
            ExpenseAgentAccessControl.Modify();
        end;
        ExpenseAgentStatus.GetOrCreate();
        RemoveAgentTask(ExpenseAgentStatus);

        ExpenseAgentStatus."Agent Task ID" := TaskScheduler.CreateTask(Codeunit::"EA Agent Dispatcher", Codeunit::"EA Agent Error Handler", true, CompanyName(), CurrentDateTime() + ScheduleDelay(), EASetup.RecordId);
        ExpenseAgentStatus."Agent Recovery Task ID" := TaskScheduler.CreateTask(Codeunit::"EA Agent Recovery", Codeunit::"EA Agent Recovery", true, CompanyName(), CurrentDateTime() + ScheduleRecoveryDelay(), EASetup.RecordId);
        ExpenseAgentStatus.Modify();
        Commit();

        FeatureTelemetry.LogUsage('0000QL2', EASetup.GetFeatureName(), TelemetryAgentScheduledLbl, TelemetryDimensions);
    end;

    internal procedure RemoveAgentTasks()
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        ExpenseAgentStatus.GetOrCreate();
        if not IsNullGuid(ExpenseAgentStatus."Agent Task ID") or not IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID") then
            RemoveAgentTask(ExpenseAgentStatus);
    end;

    internal procedure RemoveAgentTask(var ExpenseAgentStatus: Record "Expense Agent Status")
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        NullGuid: Guid;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if TaskScheduler.TaskExists(ExpenseAgentStatus."Agent Task ID") then begin
            if TaskScheduler.CancelTask(ExpenseAgentStatus."Agent Task ID") then;
            FeatureTelemetry.LogUsage('0000QL3', ExpenseAgentSetup.GetFeatureName(), TelemetryAgentScheduledTaskCancelledLbl, TelemetryDimensions);
        end;

        if TaskScheduler.TaskExists(ExpenseAgentStatus."Agent Recovery Task ID") then begin
            if TaskScheduler.CancelTask(ExpenseAgentStatus."Agent Recovery Task ID") then;
            FeatureTelemetry.LogUsage('0000QL4', ExpenseAgentSetup.GetFeatureName(), TelemetryRecoveryScheduledTaskCancelledLbl, TelemetryDimensions);
        end;

        ExpenseAgentStatus."Agent Task ID" := NullGuid;
        ExpenseAgentStatus."Agent Recovery Task ID" := NullGuid;
        ExpenseAgentStatus.Modify();
    end;

    local procedure ScheduleDelay(): Integer
    begin
        exit(60 * 1000) // 1 minute
    end;

    local procedure ScheduleRecoveryDelay(): Integer
    begin
        exit(4 * 60 * 60 * 1000) // 4 hours
    end;

    internal procedure GetProcessLimitPerDay(var EASetup: Record "Expense Agent Setup"): Integer
    begin
        exit(100);
    end;

    procedure RemoveTaskLogsOlderThan24hrs()
    var
        EASchedulerTask: Record "EA Scheduler Task";
        Limit: DateTime;
    begin
        Limit := CreateDateTime(CalcDate('<-1D>', DT2Date(CurrentDateTime())), 0T);

        EASchedulerTask.SetFilter(SystemCreatedAt, '<%1', Limit);
        if not EASchedulerTask.FindSet() then
            exit;

        EASchedulerTask.DeleteAll();
        Commit();
    end;
}
