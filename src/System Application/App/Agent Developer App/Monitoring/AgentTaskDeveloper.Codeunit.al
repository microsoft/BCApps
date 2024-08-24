// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

codeunit 4399 "Agent Task Developer"
{
    Access = Internal;

    internal procedure SelectAgent(var Agent: Record "Agent")
    begin
        Agent.SetRange(State, Agent.State::Enabled);
        if Agent.Count() = 0 then
            Error(NoActiveAgentsErr);

        if Agent.Count() = 1 then begin
            Agent.FindFirst();
            exit;
        end;

        if not (Page.RunModal(Page::"Agent List", Agent) in [Action::LookupOK, Action::OK]) then
            Error('');
    end;

    procedure RestartTask(var AgentTask: Record "Agent Task"; UserConfirm: Boolean)
    begin
        if UserConfirm then
            if not Confirm(AreYouSureThatYouWantToRestartTheTaskQst) then
                exit;

        AgentTask.Status := AgentTask.Status::Ready;
        AgentTask.Modify(true);
    end;

    var
        AreYouSureThatYouWantToRestartTheTaskQst: Label 'Are you sure that you want to restart the task?';
        NoActiveAgentsErr: Label 'There are no active agents setup on the system.';
}