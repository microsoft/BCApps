// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Check;
using Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 10845 "Report Layouts FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Layout Selection" = rim,
                  tabledata "Tenant Report Layout Selection" = rim;

    internal procedure UpgradeCheckLayout()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag()) then
            exit;

        SetDefaultCheckLayout();
        UpgradeTag.SetUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag());
    end;

    internal procedure SetDefaultCheckLayout()
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CurrentModuleInfo: ModuleInfo;
        BaseApplicationId: Guid;
        EmptyGuid: Guid;
        SelectedCompany: Text[30];
        HasCompanySelection: Boolean;
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if ReportLayoutSelection.Get(Report::Check, SelectedCompany) then
            if (ReportLayoutSelection.Type <> ReportLayoutSelection.Type::"RDLC (built-in)") or
               (ReportLayoutSelection."Custom Report Layout Code" <> '')
            then
                exit;

        HasCompanySelection := TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, EmptyGuid);
        if not HasCompanySelection then
            if not TenantReportLayoutSelection.Get(Report::Check, '', EmptyGuid) then
                TenantReportLayoutSelection.Init();

        BaseApplicationId := BaseApplicationIdTok;
        if TenantReportLayoutSelection."Report ID" <> 0 then
            if (TenantReportLayoutSelection."App ID" <> BaseApplicationId) or
               (TenantReportLayoutSelection."Layout Name" <> 'RDLCLayout')
            then
                exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        ReportLayoutList.SetRange("Report ID", Report::Check);
        ReportLayoutList.SetRange("Application ID", CurrentModuleInfo.Id());
        ReportLayoutList.SetRange(Name, 'CheckFR');
        ReportLayoutList.FindFirst();

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
    end;

    var
        BaseApplicationIdTok: Label '437dbf0e-84ff-417a-965d-ed2bb9650972', Locked = true;
}
