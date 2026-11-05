// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

// Yields loaded work items; presentation alone owns sortable page rows and formatting.
codeunit 3342 "PA Work Item Collection"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R;

    var
        AgentTaskCandidates: Record "Agent Task";
        RejectedWorkItems: Record "Payables Agent Work Item";
        AgentTaskCursor: Option NotStarted,Reading,Exhausted;
        RejectedCursor: Option NotStarted,Reading,Exhausted;
        Opened: Boolean;
        AgentSessionScope: Boolean;
        HasStateFilter: Boolean;
        ScopeState: Enum "PA Work Item State";
        CollectionNotOpenErr: Label 'Open the work item collection before enumerating it.';

    internal procedure OpenAll()
    begin
        Opened := false;
        Clear(AgentTaskCandidates);
        Clear(RejectedWorkItems);
        AgentTaskCursor := AgentTaskCursor::NotStarted;
        RejectedCursor := RejectedCursor::NotStarted;
        HasStateFilter := false;
        Clear(ScopeState);
        AgentSessionScope := InitializeTaskCandidates(AgentTaskCandidates);
        RejectedWorkItems.SetRange("Admission Status", "PA Work Item Admission Status"::Rejected);
        RejectedWorkItems.SetRange("Agent Task ID", 0);
        RejectedWorkItems.SetLoadFields(SystemId);
        Opened := true;
    end;

    internal procedure OpenByState(State: Enum "PA Work Item State")
    begin
        OpenAll();
        HasStateFilter := true;
        ScopeState := State;
    end;

    internal procedure Next(var WorkItem: Codeunit "PA Work Item"): Boolean
    begin
        if NextAccepted(WorkItem) then
            exit(true);
        exit(NextRejected(WorkItem));
    end;

    local procedure NextAccepted(var WorkItem: Codeunit "PA Work Item"): Boolean
    begin
        Clear(WorkItem);
        RequireOpen();
        if HasStateFilter and (ScopeState = "PA Work Item State"::Rejected) then
            exit(false);
        while MoveNextTask() do
            if WorkItem.LoadByAgentTaskId(AgentTaskCandidates.ID) then begin
                if not HasStateFilter then
                    exit(true);
                if WorkItem.GetState() = ScopeState then
                    exit(true);
            end;
        Clear(WorkItem);
        exit(false);
    end;

    local procedure NextRejected(var WorkItem: Codeunit "PA Work Item"): Boolean
    begin
        Clear(WorkItem);
        RequireOpen();
        if AgentSessionScope or (HasStateFilter and (ScopeState <> "PA Work Item State"::Rejected)) then
            exit(false);
        while MoveNextRejectedWorkItem() do
            if WorkItem.Load(RejectedWorkItems.SystemId) then
                exit(true);
        Clear(WorkItem);
        exit(false);
    end;

    internal procedure GetCountsByState(var Counts: Dictionary of [Enum "PA Work Item State", Integer])
    var
        Candidates: Record "Agent Task";
        AgentScope: Boolean;
        WorkItem: Codeunit "PA Work Item";
        State: Enum "PA Work Item State";
        Ordinal: Integer;
    begin
        Clear(Counts);
        foreach Ordinal in Enum::"PA Work Item State".Ordinals() do
            Counts.Add(Enum::"PA Work Item State".FromInteger(Ordinal), 0);

        // Local candidates preserve this collection's cursor and reuse exactly the same runtime scope.
        AgentScope := InitializeTaskCandidates(Candidates);
        if Candidates.FindSet() then
            repeat
                if WorkItem.LoadByAgentTaskId(Candidates.ID) then begin
                    State := WorkItem.GetState();
                    Counts.Set(State, Counts.Get(State) + 1);
                end;
            until Candidates.Next() = 0;
        Counts.Set("PA Work Item State"::Rejected, CountRejectedWorkItems(AgentScope));
    end;

    local procedure MoveNextTask(): Boolean
    begin
        case AgentTaskCursor of
            AgentTaskCursor::NotStarted:
                if AgentTaskCandidates.FindSet() then begin
                    AgentTaskCursor := AgentTaskCursor::Reading;
                    exit(true);
                end;
            AgentTaskCursor::Reading:
                if AgentTaskCandidates.Next() <> 0 then
                    exit(true);
        end;
        AgentTaskCursor := AgentTaskCursor::Exhausted;
        exit(false);
    end;

    local procedure MoveNextRejectedWorkItem(): Boolean
    begin
        case RejectedCursor of
            RejectedCursor::NotStarted:
                if RejectedWorkItems.FindSet() then begin
                    RejectedCursor := RejectedCursor::Reading;
                    exit(true);
                end;
            RejectedCursor::Reading:
                if RejectedWorkItems.Next() <> 0 then
                    exit(true);
        end;
        RejectedCursor := RejectedCursor::Exhausted;
        exit(false);
    end;

    local procedure InitializeTaskCandidates(var Candidates: Record "Agent Task"): Boolean
    var
        AgentAccess: Codeunit "PA Agent Access";
        AgentTaskId: BigInteger;
    begin
        Clear(Candidates);
        Candidates.SetRange("Company Name", CompanyName());
        Candidates.SetLoadFields(ID);
        if not AgentAccess.TryGetAgentViewTaskId(AgentTaskId) then
            exit(false);
        Candidates.SetRange(ID, AgentTaskId);
        exit(true);
    end;

    local procedure CountRejectedWorkItems(AgentScope: Boolean): Integer
    var
        StoredWorkItem: Record "Payables Agent Work Item";
    begin
        if AgentScope then
            exit(0);
        StoredWorkItem.SetRange("Admission Status", "PA Work Item Admission Status"::Rejected);
        StoredWorkItem.SetRange("Agent Task ID", 0);
        exit(StoredWorkItem.Count());
    end;

    local procedure RequireOpen()
    begin
        if not Opened then
            Error(CollectionNotOpenErr);
    end;
}
