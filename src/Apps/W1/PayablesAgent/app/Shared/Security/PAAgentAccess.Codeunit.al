// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.History;
using System.Agents;
using System.AI;
using System.Security.AccessControl;

// Determines who may create or use this agent and grants access to eligible invoice-creating users.
codeunit 3350 "PA Agent Access"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure CanShowAgentActions(): Boolean
    var
        Agent: Record Agent;
        PASetup: Codeunit "PA Setup";
        AgentSession: Codeunit "Agent Session";
        AgentUtilities: Codeunit "Agent Utilities";
        CopilotCapability: Codeunit "Copilot Capability";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        // Upload and setup actions are for people supervising the agent, never for the agent runtime user.
        if AgentSession.IsAgentSession(AgentMetadataProvider) then
            exit(false);
        if not AgentUtilities.IsAgentsFeatureEnabled() then
            exit(false);
        if not CopilotCapability.IsCapabilityActive("Copilot Capability"::"Payables Agent") then
            exit(false);
        if not PASetup.TryFindAgent(Agent) then
            exit(AllowCreateNewAgent());

        // Payables Agent is created. It has to be enabled and user has to have permissions to use it in order to show the agent actions.
        if Agent.State = Agent.State::Disabled then
            exit(false);

        exit(Agent."Can Current User Use Agent");
    end;

    internal procedure AllowCreateNewAgent(): Boolean
    var
        Agent: Record Agent;
        PASetup: Codeunit "PA Setup";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        AgentUtilities: Codeunit "Agent Utilities";
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not AgentUtilities.IsAgentsFeatureEnabled() then
            exit(false);
        if not CopilotCapability.IsCapabilityActive("Copilot Capability"::"Payables Agent") then
            exit(false);
        if PASetup.TryFindAgent(Agent) then
            exit(false);

        // No payables agent exists
        if AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            exit(true);
        if not AgentUtilities.CanCurrentUserCreateAgent(Enum::"Agent Metadata Provider"::"Payables Agent") then
            exit(false);

        exit(HasUserCreatedPostedPurchInvoice());
    end;

    internal procedure HasUserCreatedPostedPurchInvoice(): Boolean
    var
        PurchaseInvHeader: Record "Purch. Inv. Header";
        Days30Ago: Date;
    begin
        Days30Ago := CalcDate('<-30D>', Today());

        PurchaseInvHeader.SetRange(SystemCreatedAt, CreateDateTime(Days30Ago, 0T), CurrentDateTime());
        PurchaseInvHeader.SetRange(SystemCreatedBy, UserSecurityId());
        exit(not PurchaseInvHeader.IsEmpty());
    end;

    internal procedure GetUsersThatHaveCreatedPostedPurchInvoice(): List of [Guid]
    var
        User: Record User;
        PAPostedPurchInvUsers: Query "PA Posted Purch. Inv. Users";
        Users: List of [Guid];
        Days30Ago: Date;
    begin
        Days30Ago := CalcDate('<-30D>', Today());
        PAPostedPurchInvUsers.SetRange(SystemCreatedAt, CreateDateTime(Days30Ago, 0T), CurrentDateTime());
        PAPostedPurchInvUsers.Open();
        while PAPostedPurchInvUsers.Read() do
            if User.Get(PAPostedPurchInvUsers.SystemCreatedBy) then
                if User."License Type" <> User."License Type"::Agent then
                    Users.Add(PAPostedPurchInvUsers.SystemCreatedBy);
        PAPostedPurchInvUsers.Close();
        exit(Users);
    end;

    internal procedure InsertAccessControlForEligibleUsers(AgentUserSecurityId: Guid)
    var
        AgentAccessControl: Record "Agent Access Control";
        UserSecIds: List of [Guid];
        SecId: Guid;
    begin
        UserSecIds := GetUsersThatHaveCreatedPostedPurchInvoice();
        foreach SecId in UserSecIds do begin
            Clear(AgentAccessControl);

            // Platform Bug 630717: Access Control Table is virtual (Doing a if then on the insert does not capture the error, it gets surfaced)
            AgentAccessControl.SetRange("Agent User Security ID", AgentUserSecurityId);
            AgentAccessControl.SetRange("Company Name", CompanyName());
            AgentAccessControl.SetRange("User Security ID", SecId);
            if not AgentAccessControl.IsEmpty() then
                continue;

            AgentAccessControl."Agent User Security ID" := AgentUserSecurityId;
            AgentAccessControl."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentAccessControl."Company Name"));
            AgentAccessControl."User Security ID" := SecId;
            AgentAccessControl.Insert();
        end;
    end;
}
