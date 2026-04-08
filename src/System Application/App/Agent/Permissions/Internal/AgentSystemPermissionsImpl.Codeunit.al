// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Consumption;
using System.Security.AccessControl;
using System.Security.User;

codeunit 4318 "Agent System Permissions Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CurrentUserCanSeeConsumptionData(): Boolean
    var
        DummyUserAIConsumptionData: Record "User AI Consumption Data";
    begin
        exit(DummyUserAIConsumptionData.ReadPermission());
    end;

    procedure CurrentUserHasCanManageAllAgentsInAllCompaniesPermission(): Boolean
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        exit(AgentUtilities.CurrentUserHasConfigureAllAgentsPermissionInAllCompanies());
    end;

    procedure CurrentUserHasCanManageAllAgentsPermission(): Boolean
    begin
        exit(CurrentUserHasExecuteSystemPermission(9665)); // "Configure All Agents"
    end;

    procedure CurrentUserHasTroubleshootAllAgents(): Boolean
    begin
        exit(CurrentUserHasExecuteSystemPermission(9666)); // "Troubleshoot All Agents"
    end;

    procedure CurrentUserHasCanCreateCustomAgent(): Boolean
    begin
        // exit(CurrentUserHasExecuteSystemPermission(9667)); // "Create Custom Agent", not supported yet.
        exit(false);
    end;

    procedure CurrentUserCanUseAgent(AgentUserSecurityId: Guid): Boolean
    var
        Agent: Record Agent;
    begin
        if (CurrentUserHasCanManageAllAgentsPermission()) then
            exit(true);

        if Agent.Get(AgentUserSecurityId) then
            exit(Agent."Can Current User Use Agent");

        exit(false);
    end;

    procedure CurrentUserCanManageAgent(AgentUserSecurityId: Guid): Boolean
    var
        Agent: Record Agent;
    begin
        if (CurrentUserHasCanManageAllAgentsPermission()) then
            exit(true);

        if Agent.Get(AgentUserSecurityId) then
            exit(Agent."Can Curr. User Configure Agent");

        exit(false);
    end;

    local procedure CurrentUserHasExecuteSystemPermission(PermissionId: Integer): Boolean
    var
        TempPermission: Record "Expanded Permission" temporary;
        UserPermissions: Codeunit "User Permissions";
    begin
        TempPermission := UserPermissions.GetEffectivePermission(TempPermission."Object Type"::System, PermissionId);
        exit(TempPermission."Execute Permission" = TempPermission."Execute Permission"::Yes);
    end;
}