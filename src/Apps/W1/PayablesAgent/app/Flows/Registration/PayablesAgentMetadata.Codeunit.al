// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Utilities;
using System.Agents;
using System.AI;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;

codeunit 3352 "Payables Agent Metadata" implements IAgentMetadata, IAgentFactory, IAgentArchiving
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;
    Permissions = tabledata User = R, tabledata Agent = R, tabledata "Agent Task Message" = R;

    #region IAgentMetadata
    var
        PayablesAgentInitialsTok: Label 'PA', Locked = true, Comment = 'Initials for payables agent.', MaxLength = 4;
        AgentDisplayNameLbl: Label 'Payables Agent', Locked = true, Comment = 'Display name of the agent.';
        AgentSummaryLbl: Label 'Monitors incoming emails for vendor invoices, matches senders to registered vendors, and creates purchase document drafts for review.';


    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit(PayablesAgentInitialsTok);
    end;

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Payables Agent Setup");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Payables Agent KPI");
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid) PageId: Integer
    var
        Presentation: Codeunit "PA Task Presentation";
    begin
        PageId := Presentation.GetMessagePageId(MessageId);
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    var
        Agent: Codeunit Agent;
    begin
        if not Agent.IsActive(AgentUserId) then
            exit;
        Clear(Annotations);
    end;
    #endregion
    #region IAgentFactory
    procedure GetDefaultInitials(): Text[4]
    begin
        exit(PayablesAgentInitialsTok);
    end;

    internal procedure AgentDisplayName(): Text[80]
    begin
        exit(AgentDisplayNameLbl);
    end;

    // The summary still describes the draft-based (v1) agent.
    internal procedure AgentSummary(): Text
    begin
        exit(AgentSummaryLbl);
    end;

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"Payables Agent Setup");
    end;

    procedure ShowCanCreateAgent(): Boolean
    var
        PAAgentAccess: Codeunit "PA Agent Access";
    begin
        exit(PAAgentAccess.AllowCreateNewAgent());
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Payables Agent");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        PASetup: Codeunit "PA Setup";
        Agent: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        PASetup.GetSetup();
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        Agent.PopulateDefaultProfile(PASetup.GetAgentProfile(), ModuleInfo.Id, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        PASetup: Codeunit "PA Setup";
        ModuleInfo: ModuleInfo;
    begin
        PASetup.GetSetup();
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := ModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := PASetup.GetAgentPermissionSet();
        TempAccessControlBuffer.Insert();
    end;
    #endregion
    #region IAgentArchiving
    procedure IsArchivingSupported(): Boolean
    begin
        exit(false);
    end;
    #endregion

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", OnCreateEvaluationDataOnAfterClassifyTablesToNormal, '', false, false)]
    local procedure ClassifyDataSensitivity()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payables Agent Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"Payables Agent KPI");
#if not CLEAN28
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Demo File");
#endif
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Billing Log");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Billing Task Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(Database::"PA Known Sender");
    end;

    internal procedure RegisterCapability()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTok: Label 'https://go.microsoft.com/fwlink/?linkid=2304779', Locked = true;
    begin
        // It's only possible to register the copilot capability in SaaS environments
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;
        // If already registered we want to keep the capability registered, and make sure it marked as generally available
        if CopilotCapability.IsCapabilityRegistered("Copilot Capability"::"Payables Agent") then
            CopilotCapability.ModifyCapability("Copilot Capability"::"Payables Agent", "Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTok)
        else// If not registered, we register it and marked it as generally available.
            CopilotCapability.RegisterCapability("Copilot Capability"::"Payables Agent", "Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTok);
    end;

    internal procedure PayablesAgentExistsAcrossAllCompanies(): Boolean
    var
        User: Record User;
        Agent: Record Agent;
    begin
        // Waiting for platform bug: 631913 to be fixed, in order to do IsEmpty with filter on Agent table.
        User.SetLoadFields("User Security ID");
        if User.FindSet() then
            repeat
                if Agent.Get(User."User Security ID") then
                    if Agent."Agent Metadata Provider" = "Agent Metadata Provider"::"Payables Agent" then
                        exit(true);
            until User.Next() = 0;
        exit(false);
    end;

    procedure IsPayablesAgentSession(var SessionTaskID: BigInteger): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        CurrentAgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not AgentSession.IsAgentSession(CurrentAgentMetadataProvider) then
            exit(false);
        if CurrentAgentMetadataProvider <> "Agent Metadata Provider"::"Payables Agent" then
            exit(false);

        SessionTaskID := AgentSession.GetCurrentSessionAgentTaskId();
        exit(true);
    end;
}