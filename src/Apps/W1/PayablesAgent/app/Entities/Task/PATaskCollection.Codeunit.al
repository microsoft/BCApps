// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

// Enumerates logical task identities. Presentation owns projection into temporary page rows.
codeunit 3342 "PA Task Collection"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R;

    internal procedure GetTaskIds(var TaskIds: List of [BigInteger])
    var
        AgentTask: Record "Agent Task";
        Task: Codeunit "Payables Agent Task";
    begin
        Clear(TaskIds);
        if IsAgentSession() then begin
            if Task.LoadCurrentSession() then
                TaskIds.Add(Task.GetAgentTaskId());
            exit;
        end;

        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetLoadFields(ID);
        if AgentTask.FindSet() then
            repeat
                if Task.Load(AgentTask.ID) then
                    TaskIds.Add(AgentTask.ID);
            until AgentTask.Next() = 0;
    end;

    internal procedure GetTaskIdsByState(State: Enum "PA Task State"; var TaskIds: List of [BigInteger])
    var
        Task: Codeunit "Payables Agent Task";
        AllTaskIds: List of [BigInteger];
        TaskId: BigInteger;
    begin
        Clear(TaskIds);
        GetTaskIds(AllTaskIds);
        foreach TaskId in AllTaskIds do
            if Task.Load(TaskId) then
                if Task.GetState() = State then
                    TaskIds.Add(TaskId);
    end;

    internal procedure GetRejectedSourceIds(var SourceIds: List of [Guid])
    var
        StoredTask: Record "Payables Agent Task";
    begin
        Clear(SourceIds);
        if IsAgentSession() then
            exit;
        StoredTask.SetRange("Intake Status", "PA Task Intake Status"::Rejected);
        StoredTask.SetRange("Agent Task ID", 0);
        StoredTask.SetLoadFields(SystemId);
        if StoredTask.FindSet() then
            repeat
                SourceIds.Add(StoredTask.SystemId);
            until StoredTask.Next() = 0;
    end;

    internal procedure CountByState(State: Enum "PA Task State"): Integer
    var
        SourceIds: List of [Guid];
        TaskIds: List of [BigInteger];
    begin
        if State = "PA Task State"::Rejected then begin
            GetRejectedSourceIds(SourceIds);
            exit(SourceIds.Count());
        end;
        GetTaskIdsByState(State, TaskIds);
        exit(TaskIds.Count());
    end;

    local procedure IsAgentSession(): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        Provider: Enum "Agent Metadata Provider";
    begin
        if not AgentSession.IsAgentSession(Provider) then
            exit(false);
        exit(Provider = Provider::"Payables Agent");
    end;
}
