// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

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
        ReviewIncomingInvoiceToEmailReviewPolicy();
        AllowCreditMemosOnAgentEDocumentService();
#if not CLEAN30
        MigrateFinalizedEDocumentKPI();
#endif
    end;

    trigger OnUpgradePerDatabase()
    begin
        RegisterCapability();
        AddBillingTypeToCapability();
        RegisterTrial();
    end;

    local procedure RegisterTrial()
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
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
        PayablesAgent: Codeunit "Payables Agent Metadata";
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
        PASetup: Codeunit "PA Setup";
        PAAgentInstructions: Codeunit "PA Agent Instructions";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;
        if PASetup.FindAgentAndReconcileSetup(Agent) then
            PAAgentInstructions.SetAgentInstructions(Agent."User Security ID");
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

    local procedure ReviewIncomingInvoiceToEmailReviewPolicy()
    var
        PayablesAgentSetup: Record "Payables Agent Setup";
    begin
        if UpgradeTag.HasUpgradeTag(GetMapEmailReviewPolicyTag()) then
            exit;
        if PayablesAgentSetup.FindFirst() then
            if PayablesAgentSetup."Email Review Policy" = "PA Email Review Policy"::Unset then begin
                PayablesAgentSetup."Email Review Policy" := PayablesAgentSetup."Review Incoming Invoice" ? "PA Email Review Policy"::Always : "PA Email Review Policy"::OnlyIfUntrusted;
                PayablesAgentSetup.Modify();
            end;
        UpgradeTag.SetUpgradeTag(GetMapEmailReviewPolicyTag());
    end;

    local procedure AllowCreditMemosOnAgentEDocumentService()
    var
        DraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        if UpgradeTag.HasUpgradeTag(GetAllowCreditMemosOnAgentEDocumentServiceTag()) then
            exit;

        DraftBasedSetup.AllowCreditMemosOnAgentEDocumentService();
        UpgradeTag.SetUpgradeTag(GetAllowCreditMemosOnAgentEDocumentServiceTag());
    end;

    local procedure GetAllowCreditMemosOnAgentEDocumentServiceTag(): Code[250]
    begin
        exit('MS-650500-AllowCreditMemosOnAgentEDocumentService-20261013');
    end;

#if not CLEAN30
    local procedure MigrateFinalizedEDocumentKPI()
    var
        NewAggregate: Record "Payables Agent KPI";
        OtherAggregate: Record "Payables Agent KPI";
        MigratedCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetMigrateFinalizedEDocumentKPITag()) then
            exit;

        NewAggregate.LockTable();
        MigratedCount := MigrateLegacyKPIScenario("PA KPI Scenario"::"Agent E-Docs Finalized by Agent");
        MigratedCount += MigrateLegacyKPIScenario("PA KPI Scenario"::"Agent E-Docs Finalized by User");

        NewAggregate.SetRange("Is Aggregate", true);
        NewAggregate.SetRange("KPI Scenario", "PA KPI Scenario"::"Purchase Invoices created by Agent");
        if not NewAggregate.FindFirst() then begin
            NewAggregate."Is Aggregate" := true;
            NewAggregate."KPI Scenario" := "PA KPI Scenario"::"Purchase Invoices created by Agent";
            NewAggregate.Insert();
        end;

        // There is exactly one aggregate for the new scenario after migration, even if one was already created.
        OtherAggregate.SetRange("Is Aggregate", true);
        OtherAggregate.SetRange("KPI Scenario", "PA KPI Scenario"::"Purchase Invoices created by Agent");
        OtherAggregate.SetFilter(Id, '<>%1', NewAggregate.Id);
        while OtherAggregate.FindFirst() do begin
            MigratedCount += OtherAggregate.Count;
            OtherAggregate.Delete();
        end;
        NewAggregate.Count += MigratedCount;
        NewAggregate.Modify();
        UpgradeTag.SetUpgradeTag(GetMigrateFinalizedEDocumentKPITag());
    end;

    local procedure MigrateLegacyKPIScenario(LegacyScenario: Enum "PA KPI Scenario") MigratedCount: Integer
    var
        LegacyKPI: Record "Payables Agent KPI";
        GranularCount: Integer;
    begin
        LegacyKPI.SetRange("KPI Scenario", LegacyScenario);
        LegacyKPI.SetRange("Is Aggregate", false);
        if LegacyKPI.FindSet() then
            repeat
                GranularCount += LegacyKPI.Count;
            until LegacyKPI.Next() = 0;
        // Reclassifying the existing entries preserves their SystemCreatedAt for feedback thresholds.
        LegacyKPI.ModifyAll("KPI Scenario", "PA KPI Scenario"::"Purchase Invoices created by Agent");

        LegacyKPI.SetRange("Is Aggregate", true);
        if LegacyKPI.FindSet() then
            repeat
                MigratedCount += LegacyKPI.Count;
            until LegacyKPI.Next() = 0;
        LegacyKPI.DeleteAll();
        if MigratedCount = 0 then
            MigratedCount := GranularCount;
    end;

    local procedure GetMigrateFinalizedEDocumentKPITag(): Code[250]
    begin
        exit('MS-PayablesAgent-MigrateInvoiceKPI-V2');
    end;
#endif

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
        exit('MS-625413-MapPayablesAgentEmailReviewPolicy-20260703');
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
        PerCompanyUpgradeTags.Add(GetAllowCreditMemosOnAgentEDocumentServiceTag());
#if not CLEAN30
        PerCompanyUpgradeTags.Add(GetMigrateFinalizedEDocumentKPITag());
#endif
    end;

}