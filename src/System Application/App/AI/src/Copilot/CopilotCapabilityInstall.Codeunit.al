// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;
using System.Privacy;

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
        SummarizeLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2284702', Locked = true;
        AutofillLearnMoreLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2298223', Locked = true;

    internal procedure RegisterCapabilities()
    begin
        RegisterSaaSCapability(Enum::"Copilot Capability"::"Analyze List", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed", AnalyzeListLearnMoreLbl);
        RegisterSaaSCapability(Enum::"Copilot Capability"::Autofill, Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Not Billed", AutofillLearnMoreLbl);
        RegisterSaaSCapability(Enum::"Copilot Capability"::Chat, Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Not Billed", ChatLearnMoreLbl);
        RegisterSaaSCapability(Enum::"Copilot Capability"::Summarize, Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Not Billed", SummarizeLearnMoreLbl);
    end;

    local procedure RegisterSaaSCapability(Capability: Enum "Copilot Capability"; Availability: Enum "Copilot Availability"; BillingType: Enum "Copilot Billing Type"; LearnMoreUrl: Text[2048])
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not CopilotCapability.IsCapabilityRegistered(Capability) then
                CopilotCapability.RegisterCapability(Capability, Availability, BillingType, LearnMoreUrl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapabilities();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copilot Capability", 'OnGetRequiredPrivacyNotices', '', false, false)]
    local procedure OnGetRequiredPrivacyNotices(CopilotCapability: Enum "Copilot Capability"; AppId: Guid; var RequiredPrivacyNotices: List of [Code[50]])
    var
        SystemPrivacyNoticeReg: Codeunit "System Privacy Notice Reg.";
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);

        if AppId <> ModuleInfo.Id then
            exit;

        if CopilotCapability <> Enum::"Copilot Capability"::Chat then
            exit;

        if not RequiredPrivacyNotices.Contains(SystemPrivacyNoticeReg.GetMicrosoftLearnID()) then
            RequiredPrivacyNotices.Add(SystemPrivacyNoticeReg.GetMicrosoftLearnID());
    end;
}