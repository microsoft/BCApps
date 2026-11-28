// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Bank.Reports;
#if not CLEAN30
using Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
#endif

codeunit 148009 "Library - Reports FR"
{
    EventSubscriberInstance = Manual;

    var
        Migration: Codeunit "FR Fin. Schedule Migration";
        InjectFailure: Boolean;
#if not CLEAN30
        FeatureStateConfigured: Boolean;
        Enabled: Boolean;
        LegacyReportDateFilter: Text;
        LegacyNamesPageOpened: Boolean;
#endif

    procedure Migrate()
    begin
        Migration.Migrate();
    end;

    procedure IsMigrated(): Boolean
    begin
        exit(Migration.IsMigrated());
    end;

    procedure GetUpgradeTag(): Code[250]
    begin
        exit(Migration.GetUpgradeTag());
    end;

    procedure MigrateConfigurationPackages(PackageCode: Code[20])
    begin
        Migration.MigrateConfigurationPackages(PackageCode);
    end;

    procedure InitializeCompany()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.InitializeCompany();
    end;

    procedure MigrateCompanyData()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.MigrateCompanyData();
    end;

    procedure SetDefaultReportLayouts()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.SetDefaultReportLayouts();
    end;

    procedure InitializeCheckLayout()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.InitializeCheckLayout();
    end;

    procedure InitializeCheckLayout(AppId: Guid)
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.InitializeCheckLayout(AppId);
    end;

    procedure GetCheckLayoutUpgradeTag(): Code[250]
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        exit(ReportLayoutsFR.GetCheckLayoutUpgradeTag());
    end;

    procedure OnBeforeFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10]; var IsHandled: Boolean)
    var
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
    begin
        CheckAmountWordingFR.HandleBeforeFormatNoText(NoText, No, CurrencyCode, IsHandled);
    end;

#if not CLEAN30
    procedure PrepareCompanyFeatureStatus(FeatureKey: Record "Feature Key"; var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.PrepareCompanyFeatureStatus(FeatureKey, FeatureDataUpdateStatus);
    end;

    procedure VerifyFeatureMetadata(FeatureKey: Record "Feature Key")
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.VerifyFeatureMetadata(FeatureKey);
    end;

    procedure IsDataUpdateRequired(): Boolean
    var
#pragma warning disable AL0432
        FeatureReportsFR: Codeunit "Feature - Reports FR";
#pragma warning restore AL0432
    begin
        exit(FeatureReportsFR.IsDataUpdateRequired());
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
#pragma warning disable AL0432
        FeatureReportsFR: Codeunit "Feature - Reports FR";
#pragma warning restore AL0432
    begin
        FeatureReportsFR.UpdateData(FeatureDataUpdateStatus);
    end;
#endif

    procedure SetInjectFailure()
    begin
        InjectFailure := true;
    end;

#if not CLEAN30
    procedure SetFeatureEnabled(NewEnabled: Boolean)
    begin
        Enabled := NewEnabled;
        FeatureStateConfigured := true;
    end;

    procedure GetLegacyReportDateFilter(): Text
    begin
        exit(LegacyReportDateFilter);
    end;

    procedure GetLegacyNamesPageOpened(): Boolean
    begin
        exit(LegacyNamesPageOpened);
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reports FR", 'OnAfterCheckFeatureEnabled', '', false, false)]
    local procedure SetReportsFeatureState(var IsEnabled: Boolean)
    begin
        if FeatureStateConfigured then
            IsEnabled := Enabled;
    end;

    [EventSubscriber(ObjectType::Page, Page::"FR Account Schedule Names", 'OnBeforeOpenFinancialScheduleNames', '', false, false)]
    local procedure ObserveLegacyNamesPage()
    begin
        LegacyNamesPageOpened := true;
    end;
#pragma warning restore AL0432

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure ObserveLegacyReportContext(ReportId: Integer; RecordRef: RecordRef)
    begin
        if (ReportId = 10811) and (RecordRef.Number = 10801) then
            LegacyReportDateFilter := RecordRef.Field(11).GetFilter();
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FR Fin. Schedule Migration", 'OnBeforeCompleteMigration', '', false, false)]
    local procedure BeforeCompleteMigration()
    begin
        if InjectFailure then
            Error('Injected migration interruption');
    end;
}
