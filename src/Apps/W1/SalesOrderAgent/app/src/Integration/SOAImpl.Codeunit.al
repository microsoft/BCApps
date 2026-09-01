// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.AI;
using System.Email;
using System.Environment;
using System.Security.AccessControl;
using System.Telemetry;

codeunit 4587 "SOA Impl"
{
    Access = Internal;
    Permissions = tabledata "Email Inbox" = rd, tabledata User = R;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CantCreateTaskErr: Label 'User cannot create tasks.';
        TelemetrySOASetupRecordNotValidLbl: Label 'SOA Setup record is not valid.', Locked = true;
        TelemetryAgentScheduledTaskCancelledLbl: Label 'Agent scheduled task cancelled.', Locked = true;
        TelemetryRecoveryScheduledTaskCancelledLbl: Label 'Recovery scheduled task cancelled.', Locked = true;
        TelemetryAgentScheduledLbl: Label 'Agent scheduled.', Locked = true;
        TelemetryInactiveAgentTasksRemovedLbl: Label 'Scheduled tasks removed because the agent is not active.', Locked = true;
        TelemetryInactiveAgentTasksLeftLbl: Label 'Some scheduled tasks of an inactive agent could not be cancelled.', Locked = true;

    internal procedure ScheduleSOAgent(var SOASetup: Record "SOA Setup")
    var
        SOASetupCU: Codeunit "SOA Setup";
        ScheduledTaskId: Guid;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if IsNullGuid(SOASetup.SystemId) then begin
            FeatureTelemetry.LogError('0000NDU', SOASetupCU.GetFeatureName(), 'Invalid SOA Setup', TelemetrySOASetupRecordNotValidLbl, GetLastErrorCallStack(), TelemetryDimensions);
            exit;
        end;

        if not TaskScheduler.CanCreateTask() then
            Error(CantCreateTaskErr);

        SOASetup.Modify();
        SOASetup.LockTable(); // Ensure that no other process can change the setup while we are scheduling the task
        SOASetup.GetBySystemId(SOASetup.SystemId);
        RemoveScheduledTask(SOASetup);

        ScheduledTaskId := TaskScheduler.CreateTask(Codeunit::"SOA Dispatcher", Codeunit::"SOA Error Handler", true, CompanyName(), CurrentDateTime() + ScheduleDelay(SOASetupCU, SOASetup), SOASetup.RecordId);
        SOASetup."Agent Scheduled Task ID" := ScheduledTaskId;
        ScheduleSOARecovery(SOASetup);

        SOASetup.Modify();
        Commit();
        FeatureTelemetry.LogUsage('0000NGM', SOASetupCU.GetFeatureName(), TelemetryAgentScheduledLbl, TelemetryDimensions);
    end;

    /// <summary>
    /// Checks if the agent is active in the current company.
    /// Method must work even for users that have no access to Agent, thus we need to use User table to check if the agent is enabled.
    /// </summary>
    /// <returns>True if active agent exists, false otherwise.</returns>
    procedure ActiveAgentExistInCurrentCompany(): Boolean
    var
        SOASetup: Record "SOA Setup";
        User: Record User;
    begin
        SOASetup.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not SOASetup.FindSet() then
            exit(false);

        // Picking safe option to assume it is enabled if no read permissions are in the system and there is SOA setup.
        User.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not User.ReadPermission() then
            exit(true);

        repeat
            if User.Get(SOASetup."User Security ID") then
                if User.State = User.State::Enabled then
                    exit(true);
        until SOASetup.Next() = 0;

        exit(false);
    end;

    local procedure ScheduleSOARecovery(var SOASetup: Record "SOA Setup")
    var
        ScheduledTaskId: Guid;
    begin
        ScheduledTaskId := TaskScheduler.CreateTask(Codeunit::"SOA Recovery", Codeunit::"SOA Recovery", true, CompanyName(), CurrentDateTime() + ScheduleRecoveryDelay(), SOASetup.RecordId);
        SOASetup."Recovery Scheduled Task ID" := ScheduledTaskId;
    end;

    /// <summary>
    /// Cancels the scheduled tasks of an agent that is no longer live, either deactivated or archived,
    /// and clears them from the setup record. Deactivation already removes the tasks when it goes through
    /// the agent setup, so this covers tasks that survived, for example when the agent was deactivated
    /// from the agent list.
    /// </summary>
    internal procedure RemoveScheduledTasksIfAgentNotActive(var SOASetup: Record "SOA Setup"): Boolean
    var
        CurrentSOASetup: Record "SOA Setup";
        SOASetupCU: Codeunit "SOA Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if SOASetupCU.IsAgentActive(SOASetup."User Security ID") then
            exit(false);

        if CurrentSOASetup.Get(SOASetup.ID) then begin
            RemoveScheduledTask(CurrentSOASetup);
            CurrentSOASetup.Modify();
            SOASetup."Agent Scheduled Task ID" := CurrentSOASetup."Agent Scheduled Task ID";
            SOASetup."Recovery Scheduled Task ID" := CurrentSOASetup."Recovery Scheduled Task ID";
        end else
            CancelScheduledTasksForRecord(SOASetup.RecordId);

        // The caller is a scheduled task that is about to stop, so make the cleanup durable right away.
        Commit();

        TelemetryDimensions.Add('SOASetupId', Format(SOASetup.ID));
        // Report what is actually left rather than assuming the cancellations removed everything.
        if not ScheduledTasksExistForRecord(SOASetup.RecordId) then
            FeatureTelemetry.LogUsage('0000V3K', SOASetupCU.GetFeatureName(), TelemetryInactiveAgentTasksRemovedLbl, TelemetryDimensions)
        else
            // A task that survived is picked up the next time cleanup runs.
            FeatureTelemetry.LogError('0000V3L', SOASetupCU.GetFeatureName(), 'Remove scheduled tasks of inactive agent', TelemetryInactiveAgentTasksLeftLbl, '', TelemetryDimensions);
        exit(true);
    end;

    internal procedure RemoveScheduledTask(var SOASetup: Record "SOA Setup")
    var
        SOASetupCU: Codeunit "SOA Setup";
        NullGuid: Guid;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        if TaskScheduler.TaskExists(SOASetup."Agent Scheduled Task ID") then begin
            TaskScheduler.CancelTask(SOASetup."Agent Scheduled Task ID");
            FeatureTelemetry.LogUsage('0000NGN', SOASetupCU.GetFeatureName(), TelemetryAgentScheduledTaskCancelledLbl, TelemetryDimensions);
        end;

        if TaskScheduler.TaskExists(SOASetup."Recovery Scheduled Task ID") then begin
            TaskScheduler.CancelTask(SOASetup."Recovery Scheduled Task ID");
            FeatureTelemetry.LogUsage('0000NGO', SOASetupCU.GetFeatureName(), TelemetryRecoveryScheduledTaskCancelledLbl, TelemetryDimensions);
        end;

        SOASetup."Agent Scheduled Task ID" := NullGuid;
        SOASetup."Recovery Scheduled Task ID" := NullGuid;

        // The ids above only cover the tasks this setup record still knows about. Tasks whose id was lost,
        // for example when a scheduling attempt was rolled back, would otherwise keep running forever, so
        // cancel everything that is still registered for this setup record.
        CancelScheduledTasksForRecord(SOASetup.RecordId);
    end;

    local procedure CancelScheduledTasksForRecord(SOASetupRecordId: RecordId)
    begin
        CancelScheduledTasksForCodeunit(Codeunit::"SOA Dispatcher", SOASetupRecordId);
        CancelScheduledTasksForCodeunit(Codeunit::"SOA Recovery", SOASetupRecordId);
    end;

    local procedure CancelScheduledTasksForCodeunit(RunCodeunitId: Integer; SOASetupRecordId: RecordId)
    var
        ScheduledTask: Record "Scheduled Task";
        TaskIds: List of [Guid];
        TaskId: Guid;
    begin
        ScheduledTask.SetRange("Run Codeunit", RunCodeunitId);
        ScheduledTask.SetRange(Company, CompanyName());
        ScheduledTask.SetRange(Record, SOASetupRecordId);
        if not ScheduledTask.FindSet() then
            exit;

        // Cancelling removes the row, so the ids are collected before anything is cancelled.
        repeat
            TaskIds.Add(ScheduledTask.ID);
        until ScheduledTask.Next() = 0;

        foreach TaskId in TaskIds do
            if TaskScheduler.TaskExists(TaskId) then
                TaskScheduler.CancelTask(TaskId);
    end;

    local procedure ScheduledTasksExistForRecord(SOASetupRecordId: RecordId): Boolean
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        ScheduledTask.SetFilter("Run Codeunit", '%1|%2', Codeunit::"SOA Dispatcher", Codeunit::"SOA Recovery");
        ScheduledTask.SetRange(Company, CompanyName());
        ScheduledTask.SetRange(Record, SOASetupRecordId);
        exit(not ScheduledTask.IsEmpty());
    end;

    local procedure ScheduleDelay(SOASetupCU: Codeunit "SOA Setup"; var SOASetup: Record "SOA Setup"): Integer
    var
        InstanceOffset: Integer;
        BaseDelaySeconds: Integer;
        IncrementSeconds: Integer;
    begin
        InstanceOffset := GetInstanceOffset(SOASetup);

        BaseDelaySeconds := SOASetupCU.GetDispatcherBaseDelaySeconds();
        IncrementSeconds := SOASetupCU.GetDispatcherDelayIncrementSeconds();
        exit((BaseDelaySeconds + (InstanceOffset * IncrementSeconds)) * 1000);
    end;

    local procedure GetInstanceOffset(var SOASetup: Record "SOA Setup"): Integer
    var
        OtherSOASetup: Record "SOA Setup";
        SOASetupCU: Codeunit "SOA Setup";
        OwnerUserSecurityID: Guid;
    begin
        // Give each instance a distinct ordinal (0-based) based on its position among the same owner user's
        // instances, so dispatcher staggering aligns with per-user task scheduling limits.
        // Archived agents never run, so they must not push the remaining instances further out.
        OwnerUserSecurityID := SOASetup."Owner User Security ID";
        if IsNullGuid(OwnerUserSecurityID) then
            OwnerUserSecurityID := SOASetup."User Security ID";

        OtherSOASetup.ReadIsolation := IsolationLevel::ReadUncommitted;
        OtherSOASetup.SetRange("Owner User Security ID", OwnerUserSecurityID);
        OtherSOASetup.SetFilter(ID, '<%1', SOASetup.ID);
        exit(SOASetupCU.CountNonArchivedSetups(OtherSOASetup));
    end;

    local procedure ScheduleRecoveryDelay(): Integer
    begin
        exit(4 * 60 * 60 * 1000) // 4 hours
    end;

    internal procedure GetProcessLimitPerDay(var SOASetup: Record "SOA Setup"): Integer
    begin
        exit(SOASetup."Message Limit");
    end;

    procedure RemoveTaskLogsOlderThan24hrs()
    var
        SOATask: Record "SOA Task";
        Limit: DateTime;
    begin
        Limit := CreateDateTime(CalcDate('<-1D>', CurrentDateTime().Date), 0T);

        SOATask.SetFilter(SystemCreatedAt, '<%1', Limit);
        if not SOATask.FindSet() then
            exit;

        SOATask.DeleteAll();
        Commit();
    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2281481', Locked = true;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Sales Order Agent") then
            CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Sales Order Agent", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTxt)
        else
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Sales Order Agent", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTxt);
    end;
}