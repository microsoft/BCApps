// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.DataAdministration;
using System.DateTime;
using System.Diagnostics;
using System.Upgrade;

codeunit 8390 "Financial Report Auditing"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Financial Report Audit Log" = ri;

    procedure LogReportUsage(ReportName: Code[10]; Format: Enum "Financial Report Format")
    begin
        LogReportUsage(ReportName, Format, false);
    end;

    procedure LogReportUsage(ReportName: Code[10]; Format: Enum "Financial Report Format"; Scheduled: Boolean)
    var
        FinancialReportAuditLog: Record "Financial Report Audit Log";
    begin
        FinancialReportAuditLog.Init();
        FinancialReportAuditLog."Report Name" := ReportName;
        FinancialReportAuditLog.User := CopyStr(UserId(), 1, MaxStrLen(FinancialReportAuditLog.User));
        FinancialReportAuditLog.Format := Format;
        FinancialReportAuditLog.Scheduled := Scheduled;
        FinancialReportAuditLog.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report Audit Log", OnBeforeInsertEvent, '', false, false)]
    local procedure FinancialReportAuditLogOnBeforeInsert(var Rec: Record "Financial Report Audit Log")
    var
        DotNetDateTimeOffset: Codeunit DotNet_DateTimeOffset;
        UTCDateTime: DateTime;
    begin
        UTCDateTime := DotNetDateTimeOffset.ConvertToUtcDateTime(CurrentDateTime());
        Rec."Run at Date (UTC)" := UTCDateTime.Date;
        Rec."Run at Time (UTC)" := UTCDateTime.Time;
    end;

    procedure AddRetentionPolicy()
    var
        FinancialReportAuditLog: Record "Financial Report Audit Log";
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetFinRepAuditLogAddRetentionUpgradeTag()) then
            exit;

        RetenPolAllowedTables.AddAllowedTable(Database::"Financial Report Audit Log", FinancialReportAuditLog.FieldNo(SystemCreatedAt));
        CreateRetentionPolicySetup(Database::"Financial Report Audit Log", RetentionPolicySetup.FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Year"));

        UpgradeTag.SetUpgradeTag(GetFinRepAuditLogAddRetentionUpgradeTag());
    end;

    local procedure CreateRetentionPolicySetup(TableId: Integer; RetentionPeriodCode: Code[20])
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        if RetentionPolicySetup.Get(TableId) then
            exit;
        RetentionPolicySetup.Validate("Table Id", TableId);
        RetentionPolicySetup.Validate("Apply to all records", true);
        RetentionPolicySetup.Validate("Retention Period", RetentionPeriodCode);
        RetentionPolicySetup.Validate(Enabled, false);
        RetentionPolicySetup.Insert(true);
    end;

    local procedure GetFinRepAuditLogAddRetentionUpgradeTag(): Code[250]
    begin
        exit('612825-FinancialReportAuditLogAddRetentionPolicy-20251124');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnGetPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetFinRepAuditLogAddRetentionUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnAfterIsAlwaysLoggedTable', '', false, false)]
    local procedure OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
        if TableID in
            [Database::"Acc. Schedule Name",
             Database::"Financial Report",
             Database::"Financial Report User Filters",
             Database::"Column Layout Name",
             Database::"Fin. Report Excel Template",
             Database::"Financial Report Schedule",
             Database::"Financial Report Export Log",
             Database::"Financial Report Recipient",
             Database::"Financial Report Package",
             Database::"Fin. Report Package Report",
             Database::"Fin. Report Package Schedule",
             Database::"Fin. Report Package Recipient",
             Database::"Fin. Rep. Package Export Log",
             Database::"Financial Report Audit Log",
             Database::"Financial Report Category",
             Database::"Financial Report Status"]
        then
            AlwaysLogTable := true;
    end;
}