// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Company;
using System.AI;
using System.Environment;
using System.Environment.Configuration;

codeunit 6992 "Install Expense Agent Setup"
{
    Access = Internal;
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UpgradeExpReportVATSpec: Codeunit "Upgrade Exp. Report VAT Spec";
        AppInfo: ModuleInfo;
    begin
        ExpenseAgentSetup.InitRecord();
        NavApp.GetCurrentModuleInfo(AppInfo);
        if AppInfo.DataVersion() = Version.Create('0.0.0.0') then
            UpgradeExpReportVATSpec.SetBackfillReimbursementAmountsUpgradeTag();
    end;

    trigger OnInstallAppPerDatabase()
    begin
        RegisterCapability();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.InitRecord();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Copilot AI Capabilities", 'OnRegisterCopilotCapability', '', false, false)]
    local procedure OnRegisterCopilotCapability()
    begin
        RegisterCapability();
    end;

    internal procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2351709', Locked = true;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Expense Agent") then
                CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Expense Agent",
                Enum::"Copilot Availability"::Preview,
                Enum::"Copilot Billing Type"::"Microsoft Billed",
                LearnMoreUrlTxt);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    begin
        if NewCompanyName = '' then
            exit;

        ClearPerCompanyAgentState(NewCompanyName);
    end;

    /// <summary>
    /// Wipes per-company Expense Agent runtime state in the specified company so the agent must
    /// be re-provisioned there. The Expense Agent Setup row itself is preserved (general expense
    /// configuration such as number series, posting groups, rules and rates is still meaningful
    /// in the copied company); only the agent linkage is reset by clearing "Enable Agent" and
    /// "User Security ID". Access Control rows are kept so existing administrators can still
    /// configure the agent in the new company. Pass an empty TargetCompanyName to operate on the
    /// current company.
    /// </summary>
    internal procedure ClearPerCompanyAgentState(TargetCompanyName: Text)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseAgentAccessControl: Record "Expense Agent Access Control";
        ExpenseAgentStatus: Record "Expense Agent Status";
        EAKPI: Record "EA KPI";
        EAKPIEntry: Record "EA KPI Entry";
        EASchedulerTask: Record "EA Scheduler Task";
        EAEmail: Record "EA Email";
        EAEmailAttachment: Record "EA Email Attachment";
        EAOutboxEmail: Record "EA Outbox Email";
        NullGuid: Guid;
    begin
        if TargetCompanyName <> '' then begin
            ExpenseAgentSetup.ChangeCompany(TargetCompanyName);
            ExpenseAgentAccessControl.ChangeCompany(TargetCompanyName);
            ExpenseAgentStatus.ChangeCompany(TargetCompanyName);
            EAKPI.ChangeCompany(TargetCompanyName);
            EAKPIEntry.ChangeCompany(TargetCompanyName);
            EASchedulerTask.ChangeCompany(TargetCompanyName);
            EAEmail.ChangeCompany(TargetCompanyName);
            EAEmailAttachment.ChangeCompany(TargetCompanyName);
            EAOutboxEmail.ChangeCompany(TargetCompanyName);
        end;

        if ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup."Enable Agent" := false;
            ExpenseAgentSetup."User Security ID" := NullGuid;
            if ExpenseAgentSetup.Modify() then;
        end;

        ExpenseAgentAccessControl.SetRange("Can Work on Behalf", true);
        ExpenseAgentAccessControl.ModifyAll("Can Work on Behalf", false);

        ExpenseAgentStatus.DeleteAll();

        EAKPI.DeleteAll();

        EAKPIEntry.DeleteAll();

        EASchedulerTask.DeleteAll();

        EAEmail.DeleteAll();

        EAEmailAttachment.DeleteAll();

        EAOutboxEmail.DeleteAll();
    end;
}