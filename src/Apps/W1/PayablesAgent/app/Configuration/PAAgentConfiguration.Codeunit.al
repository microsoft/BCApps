// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

codeunit 3307 "PA Agent Configuration"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Agent configuration

    internal procedure IsAgentEnabled(): Boolean
    var
        Agent: Record Agent;
    begin
        PASetup.GetSetup();
        if not Agent.Get(PASetup.GetUserSecurityId()) then
            exit(false);
        exit(Agent.State = Agent.State::Enabled);
    end;

    procedure GetAgent(var Agent: Record Agent): Boolean
    begin
        exit(GetAgent(Agent, true));
    end;

    procedure GetAgent(var Agent: Record Agent; UpdateSetup: Boolean): Boolean
    var
        AgentUserId: Guid;
    begin
        // Locate by the stored ID first, then by name; read-only lookup does not create setup.
        if PASetup.GetSetup(UpdateSetup) then;
        AgentUserId := PASetup.GetUserSecurityId();
        if Agent.Get(AgentUserId) then
            exit(true);
        Clear(AgentUserId);
        Agent.SetRange("User Name", AgentUserName());
        if Agent.FindFirst() then
            AgentUserId := Agent."User Security ID";
        if UpdateSetup then
            PASetup.SaveUserSecurityId(AgentUserId);
        exit(not IsNullGuid(AgentUserId));
    end;

    #endregion

    #region Agent identity
    // The summary still describes the draft-based (v1) agent.

    internal procedure AgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentUserNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    internal procedure AgentDisplayName(): Text[80]
    begin
        exit(CopyStr(AgentDisplayNameLbl, 1, 80));
    end;

    internal procedure AgentSummary(): Text
    begin
        exit(AgentSummaryLbl);
    end;

    #endregion

    var
        PASetup: Codeunit "PA Setup";
        AgentUserNameLbl: Label 'Payables Agent', Comment = 'User name of the agent.', Locked = true;
        AgentSummaryLbl: Label 'Monitors incoming emails for vendor invoices, matches senders to registered vendors, and creates purchase document drafts for review.';
        AgentDisplayNameLbl: Label 'Payables Agent', Locked = true, Comment = 'Display name of the agent.';
}
