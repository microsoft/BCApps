#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Finance.FinancialReports;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 10825 "Feature - Reports FR" implements "Feature Data Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'Feature Reports FR will be enabled by default in version 33.0.';
    ObsoleteTag = '30.0';
    Permissions = tabledata "Feature Data Update Status" = rimd,
                  tabledata Company = r;

    var
        DescriptionTxt: Label 'Migrate French financial schedules and initialize French report layouts. Existing custom, user-specific, and other extension Check layouts are preserved.';
        FeatureKeyTok: Label 'FRReports', Locked = true;
        CannotDisableErr: Label 'Reports FR cannot be disabled after French financial schedules have been migrated. The replacement schedules remain authoritative.';

    procedure IsDataUpdateRequired(): Boolean
    var
        Migration: Codeunit "FR Fin. Schedule Migration";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        exit(not Migration.IsMigrated() or not UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()));
    end;

    procedure ReviewData()
    begin
        Message(DescriptionTxt);
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureKey: Record "Feature Key";
        ReportsFR: Codeunit "Reports FR";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
    begin
        FeatureDataUpdateStatus.TestField("Feature Key", ReportsFR.GetFeatureKeyId());
        FeatureDataUpdateStatus.TestField("Company Name", CompanyName());
        FeatureKey.Get(ReportsFR.GetFeatureKeyId());
        ReportLayoutsFR.VerifyFeatureMetadata(FeatureKey);
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Migrate French financial reporting', CurrentDateTime());
        ReportLayoutsFR.MigrateCompanyData();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        // Migration and its completion tag precede the framework's Complete status, in one transaction.
        // The framework owns status updates; no other company's status is changed here.
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnInitializeFeatureDataUpdateStatus', '', false, false)]
    local procedure InitializeStatus(var FeatureDataUpdateStatus: Record "Feature Data Update Status"; var InitializeHandled: Boolean)
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureDataUpdateStatus."Feature Key" <> FeatureKeyTok then
            exit;
        FeatureDataUpdateStatus."Data Update Required" := true;
        if not IsDataUpdateRequired() then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete
        else begin
            FeatureKey.Get(FeatureKeyTok);
            if FeatureKey.Enabled = FeatureKey.Enabled::None then
                FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled
            else
                FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Pending;
        end;
        InitializeHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnBeforeSetFeatureStatusForOtherCompanies', '', false, false)]
    local procedure PreserveCompanyReadiness(var FeatureDataUpdateStatus: Record "Feature Data Update Status"; var IsHandled: Boolean)
    var
        Migration: Codeunit "FR Fin. Schedule Migration";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if FeatureDataUpdateStatus.GetFilter("Feature Key") <> FeatureKeyTok then
            exit;
        if FeatureDataUpdateStatus.FindSet(true) then
            repeat
                FeatureDataUpdateStatus."Data Update Required" :=
                    not UpgradeTag.HasUpgradeTag(Migration.GetUpgradeTag(), FeatureDataUpdateStatus."Company Name") or
                    not UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag(), FeatureDataUpdateStatus."Company Name");
                if FeatureDataUpdateStatus."Data Update Required" then
                    FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Pending
                else
                    FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete;
                FeatureDataUpdateStatus.Modify();
            until FeatureDataUpdateStatus.Next() = 0;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure PreventDisablingMigratedFeature(FeatureKey: Record "Feature Key")
    var
        Company: Record Company;
        Migration: Codeunit "FR Fin. Schedule Migration";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if FeatureKey.ID <> FeatureKeyTok then
            exit;
        if Company.FindSet() then
            repeat
                if UpgradeTag.HasUpgradeTag(Migration.GetUpgradeTag(), Company.Name) then
                    Error(CannotDisableErr);
            until Company.Next() = 0;
    end;
}
#endif
