// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;
using System;

codeunit 7760 "Copilot Capability Install"
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
        AnalyzeListLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2252783', Locked = true;

    internal procedure RegisterCapabilities()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        WithinEUDB: Boolean;
        ApplicationFamily: Text;
    begin
        ApplicationFamily := EnvironmentInformation.GetApplicationFamily();
        if TryGetIsWithinEUDB(WithinEUDB) then;

        if ApplicationFamily in ['US', 'MX'] or WithinEUDB then
            RegisterSaaSCapability(Enum::"Copilot Capability"::Chat, Enum::"Copilot Availability"::Preview, ChatLearnMoreLbl);

        RegisterSaaSCapability(Enum::"Copilot Capability"::"Analyze List", Enum::"Copilot Availability"::Preview, AnalyzeListLearnMoreLbl);
    end;

    local procedure RegisterSaaSCapability(Capability: Enum "Copilot Capability"; Availability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048])
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not CopilotCapability.IsCapabilityRegistered(Capability) then
                CopilotCapability.RegisterCapability(Capability, Availability, LearnMoreUrl);
    end;

    [TryFunction]
    local procedure TryGetIsWithinEUDB(var WithinEUDB: Boolean)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        WithinEUDB := ALCopilotFunctions.IsWithinEUDB();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapabilities();
    end;
}