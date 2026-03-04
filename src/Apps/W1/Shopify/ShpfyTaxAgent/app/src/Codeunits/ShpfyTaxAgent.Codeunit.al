// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;
using System.AI;
using System.Reflection;
using System.Security.AccessControl;

/// <summary>
/// Main agent codeunit implementing IAgentFactory and IAgentMetadata for the Shopify Tax Matching Agent.
/// Also doubles as the Install codeunit to register the Copilot capability.
/// </summary>
codeunit 30470 "Shpfy Tax Agent" implements IAgentMetadata, IAgentFactory
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;
    Permissions = tabledata "Shpfy Tax Agent Setup" = R;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    #region IAgentMetadata

    procedure GetSetupPageId(AgentUserId: Guid): Integer
    begin
        exit(Page::"Shpfy Tax Agent Setup");
    end;

    procedure GetSummaryPageId(AgentUserId: Guid): Integer
    begin
        exit(0); // No summary page for prototype
    end;

    procedure GetAgentAnnotations(AgentUserId: Guid; var Annotations: Record "Agent Annotation")
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not CopilotCapability.IsCapabilityRegistered("Copilot Capability"::"Shpfy Tax Agent") then begin
            Annotations.Code := 'CAP_NOT_REGISTERED';
            Annotations.Severity := Annotations.Severity::Error;
            Annotations.Message := CapabilityNotRegisteredMsg;
            Annotations.Insert();
        end;
    end;

    procedure GetAgentTaskMessagePageId(AgentUserId: Guid; MessageId: Guid): Integer
    begin
        exit(0); // Use default agent task message page
    end;

    procedure GetDefaultInitials(): Text[4]
    begin
        exit(ShpfyTaxAgentInitialsTok);
    end;

    procedure GetInitials(AgentUserId: Guid): Text[4]
    begin
        exit(ShpfyTaxAgentInitialsTok);
    end;

    #endregion

    #region IAgentFactory

    procedure GetFirstTimeSetupPageId(): Integer
    begin
        exit(Page::"Shpfy Tax Agent Setup");
    end;

    procedure ShowCanCreateAgent(): Boolean
    begin
        exit(true);
    end;

    procedure GetCopilotCapability(): Enum "Copilot Capability"
    begin
        exit("Copilot Capability"::"Shpfy Tax Agent");
    end;

    procedure GetDefaultProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        AgentCU: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        AgentCU.PopulateDefaultProfile(ShpfyTaxAgentProfileTok, ModuleInfo.Id, TempAllProfile);
    end;

    procedure GetDefaultAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    begin
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := '00000000-0000-0000-0000-000000000000';
        TempAccessControlBuffer."Role ID" := SuperPermissionSetTok;
        TempAccessControlBuffer.Insert();
    end;

    #endregion

    procedure SetAgentInstructions(AgentUserSecurityID: Guid)
    var
        Agent: Codeunit Agent;
        InstructionsTxt: Text;
        InstructionsSecret: SecretText;
    begin
        InstructionsTxt := NavApp.GetResourceAsText('Prompts/ShpfyTaxAgent-SystemPrompt.md', TextEncoding::UTF8);
        InstructionsSecret := InstructionsTxt;
        Agent.SetInstructions(AgentUserSecurityID, InstructionsSecret);
    end;

    internal procedure AgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentUserNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    internal procedure AgentDisplayName(): Text[80]
    begin
        exit(AgentDisplayNameLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", OnRegisterCopilotCapability, '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    local procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTok: Label 'https://go.microsoft.com/fwlink/?linkid=868966', Locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered("Copilot Capability"::"Shpfy Tax Agent") then
            CopilotCapability.RegisterCapability(
                "Copilot Capability"::"Shpfy Tax Agent",
                "Copilot Availability"::Preview,
                Enum::"Copilot Billing Type"::"Microsoft Billed",
                LearnMoreUrlTok);
    end;

    var
        ShpfyTaxAgentInitialsTok: Label 'STA', Locked = true, MaxLength = 4;
        ShpfyTaxAgentProfileTok: Label 'Shpfy Tax Agent', Locked = true;
        AgentUserNameLbl: Label 'Shpfy Tax Agent', Locked = true;
        AgentDisplayNameLbl: Label 'Shopify Tax Matching Agent', Locked = true;
        SuperPermissionSetTok: Label 'SUPER', Locked = true;
        CapabilityNotRegisteredMsg: Label 'The Shopify Tax Agent capability is not registered. Please activate it on the Copilot & AI Capabilities page.';
}
