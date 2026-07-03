// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.AI;
using System.Environment;
using System.Upgrade;

codeunit 3305 "Payables Agent Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;

    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UpgradeTag: Codeunit "Upgrade Tag";

    trigger OnUpgradePerCompany()
    begin
        AlwaysUpdateAgentInformationOnUpgrade();
        UpdatePayablesAgentSetupToUseUserSecurityId();
        MapReviewIncomingInvoiceToEmailReviewPolicy();
    end;

    trigger OnUpgradePerDatabase()
    begin
        RegisterCapability();
        AddBillingTypeToCapability();
        RegisterTrial();
    end;

    local procedure RegisterTrial()
    var
        PayablesAgent: Codeunit "Payables Agent";
        PATrial: Codeunit "PA Trial";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if UpgradeTag.HasUpgradeTag(GetMarkTrialEndedIfPayablesAgentExistsTag()) then
            exit;

        if not EnvironmentInformation.IsSaaSInfrastructure() then begin
            UpgradeTag.SetUpgradeTag(GetMarkTrialEndedIfPayablesAgentExistsTag());
            exit;
        end;

        if PayablesAgent.PayablesAgentExistsAcrossAllCompanies() then
            PATrial.MarkTrialEnded();

        UpgradeTag.SetUpgradeTag(GetMarkTrialEndedIfPayablesAgentExistsTag());
    end;

    local procedure RegisterCapability()
    var
        PayablesAgent: Codeunit "Payables Agent";
    begin
        if not UpgradeTag.HasUpgradeTag(GetRegisterPayablesAgentCapabilityTag()) then begin
            PayablesAgent.RegisterCapability();

            UpgradeTag.SetUpgradeTag(GetRegisterPayablesAgentCapabilityTag());
        end;
    end;

    local procedure AlwaysUpdateAgentInformationOnUpgrade()
    var
        Agent: Record Agent;
        EnvironmentInformation: Codeunit "Environment Information";
        PayablesAgent: Codeunit "Payables Agent Setup";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if PayablesAgent.GetAgent(Agent) then
            PayablesAgent.SetAgentInstructions(Agent."User Security ID");
    end;

    local procedure AddBillingTypeToCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2304779', Locked = true;
    begin
        if not UpgradeTag.HasUpgradeTag(GetAddBillingTypeToPACapabilityTag()) then begin
            if EnvironmentInformation.IsSaaSInfrastructure() then
                if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Payables Agent") then
                    CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Payables Agent", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTxt);

            UpgradeTag.SetUpgradeTag(GetAddBillingTypeToPACapabilityTag());
        end;
    end;

    local procedure UpdatePayablesAgentSetupToUseUserSecurityId()
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if not UpgradeTag.HasUpgradeTag(GetUpdatePayablesAgentSetupToUseUserSecurityIdTag()) then begin
            if PayablesAgentSetup.FindFirst() then begin
                PayablesAgentSetup."User Security Id" := PayablesAgentSetup."Agent User Security Id";
                PayablesAgentSetup.Modify();
            end;
            UpgradeTag.SetUpgradeTag(GetUpdatePayablesAgentSetupToUseUserSecurityIdTag());
        end;
    end;

    // Preserves the behavior of existing tenants when the all-or-nothing "Review Incoming Invoice"
    // boolean is replaced by the "Email Review Policy" enum: always-review maps to Always, while
    // review-off adopts the new secure smart-skip default (Only if untrusted).
    local procedure MapReviewIncomingInvoiceToEmailReviewPolicy()
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if UpgradeTag.HasUpgradeTag(GetMapEmailReviewPolicyTag()) then
            exit;

        if PayablesAgentSetup.FindFirst() then
            if PayablesAgentSetup."Email Review Policy" = "PA Email Review Policy"::Unset then begin
                if PayablesAgentSetup."Review Incoming Invoice" then
                    PayablesAgentSetup."Email Review Policy" := "PA Email Review Policy"::Always
                else
                    PayablesAgentSetup."Email Review Policy" := "PA Email Review Policy"::OnlyIfUntrusted;
                PayablesAgentSetup.Modify();
            end;

        UpgradeTag.SetUpgradeTag(GetMapEmailReviewPolicyTag());
    end;

    local procedure GetRegisterPayablesAgentCapabilityTag(): Code[250]
    begin
        exit('MS-575373-PayablesAgentCapability-20251021');
    end;

    local procedure GetAddBillingTypeToPACapabilityTag(): Code[250]
    begin
        exit('MS-581366-BillingTypeToPayablesAgentCapability-20250731');
    end;

    local procedure GetUpdatePayablesAgentSetupToUseUserSecurityIdTag(): Code[250]
    begin
        exit('MS-617049-UpdatePayablesAgentSetupToUseUserSecurityId-20260224');
    end;

    local procedure GetMarkTrialEndedIfPayablesAgentExistsTag(): Code[250]
    begin
        exit('MS-631300-MarkTrialEndedIfPayablesAgentExists-20260417');
    end;

    local procedure GetMapEmailReviewPolicyTag(): Code[250]
    begin
        exit('MS-620883-MapPayablesAgentEmailReviewPolicy-20260703');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetAddBillingTypeToPACapabilityTag());
        PerDatabaseUpgradeTags.Add(GetMarkTrialEndedIfPayablesAgentExistsTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpdatePayablesAgentSetupToUseUserSecurityIdTag());
        PerCompanyUpgradeTags.Add(GetMapEmailReviewPolicyTag());
    end;

}