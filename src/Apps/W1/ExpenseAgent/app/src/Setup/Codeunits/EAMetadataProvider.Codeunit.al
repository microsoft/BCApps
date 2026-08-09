// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.ExpenseAgent;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

codeunit 6998 "EA Metadata Provider" implements IAgentMetadata, IAgentFactory
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(ExpenseAgentInitialsTok);
    end;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit(ExpenseAgentInitialsTok);
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"Expense Agent Setup Wizard");
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Expense Agent Setup Wizard");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"EA KPI");
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        // Only users with the system-wide agent management permission may create a new agent —
        if not AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            exit(false);

        // Block if this company already has a provisioned Expense Agent. The Expense Agent Setup
        // record is per-company and stores the provisioned agent's user security id; if the agent
        // user still exists, we must not offer to create another one.
        if ExpenseAgentSetup.Get() then
            if not IsNullGuid(ExpenseAgentSetup."User Security ID") then
                if Agent.Get(ExpenseAgentSetup."User Security ID") then
                    exit(false);

        exit(true);
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Expense Agent");
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    begin
        Clear(Annotations); //TODO: Add default annotation for Expense Agent similar to SOA
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(0);
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        Agent: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        Agent.PopulateDefaultProfile(ExpenseAgentProfileTok, ModuleInfo.Id, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := ModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := ExpenseAgentPermissionSetTok;
        TempAccessControlBuffer.Insert();
    end;

    var
        ExpenseAgentInitialsTok: Label 'EA', Locked = true, MaxLength = 4;
        ExpenseAgentProfileTok: Label 'EXPENSE MANAGER', Locked = true;
        ExpenseAgentPermissionSetTok: Label 'Expense Agent', Locked = true;
}
