// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Check;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 10822 "Report Layouts FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Layout Selection" = rim,
                  tabledata "Tenant Report Layout Selection" = rim,
#if not CLEAN30
                  tabledata "Feature Data Update Status" = m,
#endif
                  tabledata "Report Layout List" = r;

    internal procedure InitializeCompany()
#if not CLEAN30
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN30
        if not FeatureKey.Get(ReportsFR.GetFeatureKeyId()) then
            exit;
        if FeatureKey."Data Update Required" then
            PrepareCompanyFeatureStatus(FeatureKey, FeatureDataUpdateStatus);
        if not IsActivationConfigured(FeatureKey) then
            exit;

        // Use configured activation, not IsEnabled: a company's pending update must run first.
        if FeatureDataUpdateStatus."Feature Status" = "Feature Status"::Complete then
            MigrateCheckLayout()
        else begin
            // A seeded historical tag is not proof that this company's pending setup has run.
            InitializeCheckLayout();
            FeatureManagementFacade.UpdateData(FeatureDataUpdateStatus);
        end;
#else
        InitializeCheckLayout();
#endif
    end;

#if not CLEAN30
    internal procedure PrepareCompanyFeatureStatus(FeatureKey: Record "Feature Key"; var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
    begin
        FeatureKey.TestField(ID, ReportsFR.GetFeatureKeyId());
        FeatureKey.TestField("Data Update Required", true);
        FeatureManagementFacade.GetFeatureDataUpdateStatus(FeatureKey, FeatureDataUpdateStatus);
        if FeatureDataUpdateStatus."Data Update Required" then
            exit;

        // Existing status rows retain the metadata from their creation, even after the platform changes it.
        FeatureDataUpdateStatus."Data Update Required" := true;
        FeatureDataUpdateStatus.Modify();
    end;

    internal procedure IsActivationConfigured(FeatureKey: Record "Feature Key"): Boolean
    begin
        if FeatureKey.Enabled = FeatureKey.Enabled::None then
            exit(false);
        VerifyFeatureMetadata(FeatureKey);
        exit(true);
    end;

    internal procedure VerifyFeatureMetadata(FeatureKey: Record "Feature Key")
    var
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
    begin
        FeatureKey.TestField(ID, ReportsFR.GetFeatureKeyId());
        // These are platform-owned flags. AL must not simulate a reversible, update-free feature.
        FeatureKey.TestField("Is One Way", true);
        FeatureKey.TestField("Data Update Required", true);
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        InitializeCompany();
    end;

    internal procedure MigrateCheckLayout()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetCheckLayoutUpgradeTag()) then
            exit;

        InitializeCheckLayout();
    end;

    internal procedure InitializeCheckLayout()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        InitializeCheckLayout(CurrentModuleInfo.Id());
    end;

    internal procedure InitializeCheckLayout(AppId: Guid)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        SetDefaultCheckLayout(AppId);
        if not UpgradeTag.HasUpgradeTag(GetCheckLayoutUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(GetCheckLayoutUpgradeTag());
    end;

    internal procedure GetCheckLayoutUpgradeTag(): Code[250]
    begin
        // Do not register this completion tag with SetAllUpgradeTags: new companies need layout setup.
        exit('MS-ReportsFR-CheckLayout-20261017');
    end;

    internal procedure SetDefaultCheckLayout(): Boolean
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(SetDefaultCheckLayout(CurrentModuleInfo.Id()));
    end;

    local procedure SetDefaultCheckLayout(AppId: Guid): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        BaseApplicationId: Guid;
        EmptyGuid: Guid;
        SelectedCompany: Text[30];
        HasCompanySelection: Boolean;
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if not ReportLayoutSelection.Get(Report::Check, SelectedCompany) then
            if not ReportLayoutSelection.Get(Report::Check, '') then
                ReportLayoutSelection.Init();
        if ReportLayoutSelection."Report ID" <> 0 then
            if (ReportLayoutSelection.Type <> ReportLayoutSelection.Type::"RDLC (built-in)") or
               (ReportLayoutSelection."Custom Report Layout Code" <> '')
            then
                exit(true);

        HasCompanySelection := TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, EmptyGuid);
        if not HasCompanySelection then
            if not TenantReportLayoutSelection.Get(Report::Check, '', EmptyGuid) then
                TenantReportLayoutSelection.Init();

        BaseApplicationId := BaseApplicationIdTok;
        if TenantReportLayoutSelection."Report ID" <> 0 then
            if (TenantReportLayoutSelection."App ID" <> BaseApplicationId) or
               (TenantReportLayoutSelection."Layout Name" <> 'RDLCLayout')
            then
                exit(true);

        GetCheckLayout(ReportLayoutList, AppId);

        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
        TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
        if HasCompanySelection then
            TenantReportLayoutSelection.Modify(true)
        else
            TenantReportLayoutSelection.Insert(true);

        if not ReportLayoutSelection.Get(Report::Check, SelectedCompany) then begin
            ReportLayoutSelection.Init();
            ReportLayoutSelection."Report ID" := Report::Check;
            ReportLayoutSelection."Company Name" := SelectedCompany;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection.Insert(true);
        end;

        exit(true);
    end;

    internal procedure GetCheckLayout(var ReportLayoutList: Record "Report Layout List"; AppId: Guid)
    begin
        if not ReportLayoutList.Get(Report::Check, 'CheckFR', AppId) then
            Error(MissingCheckLayoutErr);
    end;

    var
        BaseApplicationIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
        MissingCheckLayoutErr: Label 'The CheckFR layout from Reports FR is not available. Install the Reports FR layout and retry the feature data update. Check layout migration has not completed.';
}
