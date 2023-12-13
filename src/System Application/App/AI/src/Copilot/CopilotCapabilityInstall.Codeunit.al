// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;

codeunit 7777 "Copilot Capability Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapabilities();
    end;

    var
        ChatLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2255821', Locked = true;

    internal procedure RegisterCapabilities()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        RegisterSaaSCapability(Enum::"Copilot Capability"::Chat, Enum::"Copilot Availability"::Preview, ChatLearnMoreLbl);
    end;

    local procedure RegisterSaaSCapability(Capability: Enum "Copilot Capability"; Availability: Enum "Copilot Availability"; LearnMoreUrl: Text)
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not CopilotCapability.IsCapabilityRegistered(Capability) then
                CopilotCapability.RegisterCapability(Capability, Availability, LearnMoreUrl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapabilities();
    end;
}