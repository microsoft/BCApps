// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.DataAdministration;
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
}