#if CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 10816 "Sales FR Report Layouts"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Layout Selection" = ri,
                  tabledata "Tenant Report Layout Selection" = ri;

    var
        MissingLayoutMsg: Label 'The Sales FR layout "%1" is not available for report %2.', Comment = '%1 = layout name, %2 = report ID';

    /// <summary>
    /// Initializes French Word defaults once for reports without existing selections.
    /// Preserves current-company legacy choices and tenant selections for this company or all companies, for any user.
    /// Logs missing packaged layouts and leaves initialization pending for retry.
    /// </summary>
    internal procedure SetDefaultReportLayouts()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagSalesFR: Codeunit "Upg. Tag Sales FR";
        CurrentModuleInfo: ModuleInfo;
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag()) then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if not SetDefaultReportLayout(Report::"Standard Sales - Invoice", 'StandardSalesInvoiceFR.docx', CurrentModuleInfo.Id) then
            exit;
        if not SetDefaultReportLayout(Report::"Standard Sales - Credit Memo", 'StandardSalesCreditMemoFR.docx', CurrentModuleInfo.Id) then
            exit;
        if not SetDefaultReportLayout(Report::"Standard Sales - Draft Invoice", 'StandardSalesDraftInvoiceFR.docx', CurrentModuleInfo.Id) then
            exit;

        UpgradeTag.SetUpgradeTag(UpgTagSalesFR.GetSalesFRReportLayoutsUpgradeTag());
    end;

    local procedure SetDefaultReportLayout(ReportID: Integer; LayoutName: Text[250]; SalesFRAppId: Guid): Boolean
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        EmptyGuid: Guid;
        SelectedCompany: Text[30];
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if ReportLayoutSelection.Get(ReportID, SelectedCompany) then
            exit(true);

        // A new company default must not compete with existing selections at either scope, for any user.
        TenantReportLayoutSelection.SetRange("Report ID", ReportID);
        TenantReportLayoutSelection.SetRange("Company Name", SelectedCompany);
        if not TenantReportLayoutSelection.IsEmpty() then
            exit(true);
        TenantReportLayoutSelection.SetRange("Company Name", '');
        if not TenantReportLayoutSelection.IsEmpty() then
            exit(true);

        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange("Application ID", SalesFRAppId);
        ReportLayoutList.SetRange(Name, LayoutName);
        if not ReportLayoutList.FindFirst() then begin
            LogMissingLayout(LayoutName, ReportID);
            exit(false);
        end;
        ReportLayoutList.TestField("Layout Format", ReportLayoutList."Layout Format"::Word);

        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := ReportID;
        ReportLayoutSelection."Company Name" := SelectedCompany;
        ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Word (built-in)");

        TenantReportLayoutSelection.Reset();
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := ReportID;
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        TenantReportLayoutSelection."App ID" := SalesFRAppId;
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection.Insert(true);
        ReportLayoutSelection.Insert(true);
        exit(true);
    end;

    local procedure LogMissingLayout(LayoutName: Text[250]; ReportID: Integer)
    begin
        Session.LogMessage('0000W52', StrSubstNo(MissingLayoutMsg, LayoutName, ReportID),
            Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Sales FR');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() < 31 then
            exit;

        SetDefaultReportLayouts();
    end;
}
#endif
