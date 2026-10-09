// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.AI;
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
        TelemetryTaskCancellationFailedLbl: Label 'The task could not be cancelled. It may already be running; its identifier has been retained.', Locked = true;
        HasNoAccessControlErr: Label 'You do not have permission to configure the Expense Agent. Ask an administrator to grant you "%1" access on the %2 page.', Comment = '%1 = Can Configure Agent field caption, %2 = Expense Agent Setup page caption';

    internal procedure ScheduleAgent(EASetup: Record "Expense Agent Setup")
    var
        CompletedTaskId: Guid;
    begin
        ReconcileCommunicationScheduling(EASetup, CompletedTaskId);
        Commit();
    end;

    internal procedure CompleteAgentTask(EASetup: Record "Expense Agent Setup"; CompletedTaskId: Guid)
    begin
        ReconcileCommunicationScheduling(EASetup, CompletedTaskId);
        Commit();
    end;

    local procedure ReconcileCommunicationScheduling(RequestedSetup: Record "Expense Agent Setup"; CompletedTaskId: Guid)
    var
        EASetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
        ExpenseAgentAccessControl: Record "Expense Agent Access Control";
        AzureOpenAI: Codeunit "Azure OpenAI";
        ExpenseAgentSetupPage: Page "Expense Agent Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        // Setup is always locked before access control and task status, including saves and deletion.
        // Never use the caller's pre-HTTP or temporary configuration to create a successor.
        EASetup.ReadIsolation(IsolationLevel::UpdLock);
        if not EASetup.Get(RequestedSetup."Primary Key") then begin
            FeatureTelemetry.LogError('0000QL1', EASetup.GetFeatureName(), 'Invalid EA Setup', TelemetryEASetupRecordNotValidLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        EASetup.RepairMissingEmailAccounts(true);

        if not EASetup.ShouldScheduleAgentTask(EASetup."Enable Agent") or
           not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"Expense Agent", true)
        then begin
            if GetTaskStatus(ExpenseAgentStatus) then begin
                ReleaseCompletedTask(ExpenseAgentStatus, CompletedTaskId);
                CancelPendingTasks(ExpenseAgentStatus);
            end;
            exit;
        end;

        if not TaskScheduler.CanCreateTask() then
            Error(CannotCreateTaskErr);

        ExpenseAgentAccessControl.ReadIsolation(IsolationLevel::UpdLock);

        if not ExpenseAgentAccessControl.GetByUserSecurityID(UserSecurityID()) then
            Error(HasNoAccessControlErr, ExpenseAgentAccessControl.FieldCaption("Can Configure Agent"), ExpenseAgentSetupPage.Caption);
        if not ExpenseAgentAccessControl."Can Configure Agent" then
            Error(HasNoAccessControlErr, ExpenseAgentAccessControl.FieldCaption("Can Configure Agent"), ExpenseAgentSetupPage.Caption);
        if not ExpenseAgentAccessControl."Can Work on Behalf" then begin
            ExpenseAgentAccessControl.Validate("Can Work on Behalf", true);  // automatically disables the other(s)
            ExpenseAgentAccessControl.Modify();
        end;
        ExpenseAgentStatus.GetOrCreate();
        ReleaseCompletedTask(ExpenseAgentStatus, CompletedTaskId);
        CancelPendingTasks(ExpenseAgentStatus);

        // A failed cancellation must not lose a running task or create a duplicate of it.
        if IsNullGuid(ExpenseAgentStatus."Agent Task ID") then
            ExpenseAgentStatus."Agent Task ID" := TaskScheduler.CreateTask(Codeunit::"EA Agent Dispatcher", Codeunit::"EA Agent Error Handler", true, CompanyName(), CurrentDateTime() + ScheduleDelay(), EASetup.RecordId);
        if IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID") then
            ExpenseAgentStatus."Agent Recovery Task ID" := TaskScheduler.CreateTask(Codeunit::"EA Agent Recovery", Codeunit::"EA Agent Recovery", true, CompanyName(), CurrentDateTime() + ScheduleRecoveryDelay(), EASetup.RecordId);
        ExpenseAgentStatus.Modify();

        FeatureTelemetry.LogUsage('0000QL2', EASetup.GetFeatureName(), TelemetryAgentScheduledLbl, TelemetryDimensions);
    end;

    internal procedure RemoveAgentTasks()
    begin
        RemoveAgentTasksForCompany(CompanyName());
    end;

    internal procedure RemoveAgentTasksForCompany(TargetCompanyName: Text)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        ExpenseAgentSetup.ChangeCompany(TargetCompanyName);
        ExpenseAgentStatus.ChangeCompany(TargetCompanyName);
        ExpenseAgentSetup.ReadIsolation(IsolationLevel::UpdLock);
        if ExpenseAgentSetup.Get() then;
        if GetTaskStatus(ExpenseAgentStatus) then
            CancelPendingTasks(ExpenseAgentStatus);
    end;

    local procedure GetTaskStatus(var ExpenseAgentStatus: Record "Expense Agent Status"): Boolean
    begin
        ExpenseAgentStatus.ReadIsolation(IsolationLevel::UpdLock);
        exit(ExpenseAgentStatus.Get());
    end;

    local procedure ReleaseCompletedTask(var ExpenseAgentStatus: Record "Expense Agent Status"; CompletedTaskId: Guid)
    begin
        if IsNullGuid(CompletedTaskId) then
            exit;
        // Completion is not cancellation. Only retire the slot captured by this execution;
        // a newer configuration save may already have installed a different successor.
        if ExpenseAgentStatus."Agent Task ID" = CompletedTaskId then
            Clear(ExpenseAgentStatus."Agent Task ID");
        if ExpenseAgentStatus."Agent Recovery Task ID" = CompletedTaskId then
            Clear(ExpenseAgentStatus."Agent Recovery Task ID");
    end;

    local procedure CancelPendingTasks(var ExpenseAgentStatus: Record "Expense Agent Status")
    begin
        CancelPendingTask(ExpenseAgentStatus."Agent Task ID", '0000QL3', TelemetryAgentScheduledTaskCancelledLbl);
        CancelPendingTask(ExpenseAgentStatus."Agent Recovery Task ID", '0000QL4', TelemetryRecoveryScheduledTaskCancelledLbl);
        ExpenseAgentStatus.Modify();
    end;

    local procedure CancelPendingTask(var TaskId: Guid; TelemetryId: Text; CancelledMessage: Text)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if IsNullGuid(TaskId) then
            exit;
        if not TaskScheduler.TaskExists(TaskId) then begin
            Clear(TaskId);
            exit;
        end;

        TelemetryDimensions.Add('TaskId', Format(TaskId));
        if TaskScheduler.CancelTask(TaskId) then begin
            Clear(TaskId);
            FeatureTelemetry.LogUsage(TelemetryId, ExpenseAgentSetup.GetFeatureName(), CancelledMessage, TelemetryDimensions);
            exit;
        end;

        if not TaskScheduler.TaskExists(TaskId) then
            Clear(TaskId)
        else
            FeatureTelemetry.LogError('', ExpenseAgentSetup.GetFeatureName(), 'Cancel task', TelemetryTaskCancellationFailedLbl, '', TelemetryDimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifySetup(var Rec: Record "Expense Agent Setup"; var xRec: Record "Expense Agent Setup"; RunTrigger: Boolean)
    var
        CompletedTaskId: Guid;
    begin
        if Rec.IsTemporary() or not RunTrigger then
            exit;
        if Rec.HasSchedulingChanges(xRec) then
            ReconcileCommunicationScheduling(Rec, CompletedTaskId);
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
