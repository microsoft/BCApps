#if DEVELOPMENT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

codeunit 3329 "PA Development Settings"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R;

    var
        SetupKeyTok: Label 'SETUP', Locked = true;
        UnknownEvaluationVersionErr: Label 'An evaluation must select version 1 or version 2 of the Payables Agent.';
        NotPayablesAgentTaskErr: Label 'Agent task %1 is not a Payables Agent work item in this company.', Comment = '%1 = Agent Task ID';

    internal procedure EnsureSettingsAndGetV2Enabled(): Boolean
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetOrCreateSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Enable V2");
    end;

    internal procedure SetEvaluationVersionOverride(Version: Integer)
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        if not (Version in [1, 2]) then
            Error(UnknownEvaluationVersionErr);
        GetOrCreateSettings(DevelopmentSettings);
        if DevelopmentSettings."Evaluation Version Override" = Version then
            exit;
        DevelopmentSettings."Evaluation Version Override" := Version;
        DevelopmentSettings.Modify();
    end;

    internal procedure EnsureSettingsAndGetEvaluationVersionOverride(): Integer
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetOrCreateSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Evaluation Version Override");
    end;

    internal procedure ClearEvaluationVersionOverride()
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetOrCreateSettings(DevelopmentSettings);
        if DevelopmentSettings."Evaluation Version Override" = DevelopmentSettings."Evaluation Version Override"::Default then
            exit;
        DevelopmentSettings."Evaluation Version Override" := DevelopmentSettings."Evaluation Version Override"::Default;
        DevelopmentSettings.Modify();
    end;

    // Read-only: callers run on ordinary page opens, so a missing settings row means no simulation.
    internal procedure TryGetSimulatedAgentTaskId(var AgentTaskId: BigInteger): Boolean
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        AgentTaskId := 0;
        if not DevelopmentSettings.Get(SetupKeyTok) then
            exit(false);
        if not DevelopmentSettings."Simulate Agent Experience" then
            exit(false);
        AgentTaskId := DevelopmentSettings."Simulated Agent Task ID";
        exit(true);
    end;

    internal procedure ValidateSimulatedAgentTaskId(AgentTaskId: BigInteger)
    var
        WorkItem: Codeunit "PA Work Item";
    begin
        if AgentTaskId = 0 then
            exit;
        if not WorkItem.LoadByAgentTaskId(AgentTaskId) then
            Error(NotPayablesAgentTaskErr, AgentTaskId);
    end;

    internal procedure LookupSimulatedAgentTaskId(var AgentTaskId: BigInteger): Boolean
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        PASetup: Codeunit "PA Setup";
    begin
        AgentTask.SetRange("Company Name", CompanyName());
        if PASetup.TryFindAgent(Agent) then
            AgentTask.SetRange("Agent User Security ID", Agent."User Security ID");
        if AgentTask.Get(AgentTaskId) then;
        if Page.RunModal(Page::"Agent Task List", AgentTask) <> Action::LookupOK then
            exit(false);
        AgentTaskId := AgentTask.ID;
        exit(true);
    end;

    internal procedure GetOrCreateSettings(var DevelopmentSettings: Record "PA Development Settings")
    begin
        if DevelopmentSettings.Get(SetupKeyTok) then
            exit;

        DevelopmentSettings.Init();
        DevelopmentSettings."Primary Key" := SetupKeyTok;
        DevelopmentSettings.Insert();
    end;

}
#endif
