// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.Environment.Configuration;

codeunit 6922 "EA Setup Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = rm;

    internal procedure ResolveAgentUserSecurityID(): Guid
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        AgentUserSecurityID: Guid;
    begin
        if ExpenseAgentSetup.Get() then
            AgentUserSecurityID := ExpenseAgentSetup."User Security ID";

        if not IsNullGuid(AgentUserSecurityID) then
            if Agent.Get(AgentUserSecurityID) then
                exit(AgentUserSecurityID);

        // Recover an existing company Agent when the per-company setup pointer is missing or stale.
        exit(FindCompanyAgentUserSecurityID());
    end;

    internal procedure GetAgentSetupChangesMade(var AgentSetupBuffer: Record "Agent Setup Buffer"): Boolean
    var
        AgentSetup: Codeunit "Agent Setup";
    begin
        exit(AgentSetup.GetChangesMade(AgentSetupBuffer));
    end;

    internal procedure SaveAgentSetup(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetup: Codeunit "Agent Setup";
    begin
        AgentSetup.SaveChanges(AgentSetupBuffer);
    end;

    local procedure FindCompanyAgentUserSecurityID(): Guid
    var
        Agent: Record Agent;
        TempUserSettings: Record "User Settings" temporary;
        AgentCU: Codeunit Agent;
    begin
        Agent.SetRange("Agent Metadata Provider", "Agent Metadata Provider"::"Expense Agent");
        if Agent.FindSet() then
            repeat
                Clear(TempUserSettings);
                AgentCU.GetUserSettings(Agent."User Security ID", TempUserSettings);
                // The originating company is stored in the Agent user settings.
                if TempUserSettings.Company = CopyStr(CompanyName(), 1, MaxStrLen(TempUserSettings.Company)) then
                    exit(Agent."User Security ID");
            until Agent.Next() = 0;
    end;

    internal procedure UpdateActivatorAttribution(AgentUserSecurityId: Guid)
    var
        Agent: Record Agent;
    begin
        if Agent.Get(AgentUserSecurityId) then begin
            Agent."Display Name" := Agent."Display Name";
            Agent.Modify();
        end;
    end;
}
