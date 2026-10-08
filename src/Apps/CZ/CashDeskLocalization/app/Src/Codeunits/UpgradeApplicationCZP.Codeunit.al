// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft;
using Microsoft.Bank.BankAccount;
#if not CLEANSCHEMA32
using Microsoft.Foundation.Reporting;
#endif
using System.Environment.Configuration;
#if not CLEANSCHEMA32
using System.Reflection;
#endif
using System.Upgrade;

#pragma warning disable AL0432
codeunit 31107 "Upgrade Application CZP"
{
    Subtype = Upgrade;
    Permissions = tabledata "Cash Desk User CZP" = m,
                  tabledata "Cash Desk Event CZP" = m,
                  tabledata "Cash Document Line CZP" = m,
                  tabledata "Posted Cash Document Hdr. CZP" = m,
                  tabledata "Posted Cash Document Line CZP" = m,
                  tabledata "Report Selections" = rim;

    var
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitionsCZP: Codeunit "Upgrade Tag Definitions CZP";
        InstallApplicationsMgtCZL: Codeunit "Install Applications Mgt. CZL";
        AppInfo: ModuleInfo;

    trigger OnUpgradePerDatabase()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();
        UpgradePermission();
        SetDatabaseUpgradeTags();
    end;

    trigger OnUpgradePerCompany()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();
        BindSubscription(InstallApplicationsMgtCZL);
        UpgradeUsage();
#if not CLEANSCHEMA32
        UpgradeReportSelections();
#endif
        UnbindSubscription(InstallApplicationsMgtCZL);
        SetCompanyUpgradeTags();
    end;

    local procedure UpgradePermission()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerDatabaseUpgradeTag()) then
            exit;

        NavApp.GetCurrentModuleInfo(AppInfo);
        InstallApplicationsMgtCZL.InsertTableDataPermissions(AppInfo.Id(), Database::"Bank Account", Database::"Cash Desk CZP");
    end;

    local procedure UpgradeUsage()
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerDatabaseUpgradeTag()) then
            exit;

        InstallApplicationsMgtCZL.InsertTableDataUsage(Database::"Bank Account", Database::"Cash Desk CZP");
    end;
#if not CLEANSCHEMA32

    local procedure UpgradeReportSelections()
    var
        CashDeskRepSelectionsCZP: Record "Cash Desk Rep. Selections CZP";
        ReportSelections: Record "Report Selections";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetUseReportSelectionsUpgradeTag()) then
            exit;

        if CashDeskRepSelectionsCZP.FindSet(false) then
            repeat
                case CashDeskRepSelectionsCZP.Usage of
                    CashDeskRepSelectionsCZP.Usage::"Cash Receipt":
                        begin
                            if not ReportSelections.Get(Enum::"Report Selection Usage"::"Cash Receipt CZP", CashDeskRepSelectionsCZP.Sequence) then
                                ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Cash Receipt CZP", CashDeskRepSelectionsCZP."Sequence", CashDeskRepSelectionsCZP."Report ID");
                            AddEmailBodyLayout(ReportSelections, 'ReceiptCashDocumentEmail.docx');
                        end;
                    CashDeskRepSelectionsCZP.Usage::"Cash Withdrawal":
                        if not ReportSelections.Get(Enum::"Report Selection Usage"::"Cash Withdrawal CZP", CashDeskRepSelectionsCZP.Sequence) then
                            ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Cash Withdrawal CZP", CashDeskRepSelectionsCZP.Sequence, CashDeskRepSelectionsCZP."Report ID");
                    CashDeskRepSelectionsCZP.Usage::"Posted Cash Receipt":
                        begin
                            if not ReportSelections.Get(Enum::"Report Selection Usage"::"Posted Cash Receipt CZP", CashDeskRepSelectionsCZP.Sequence) then
                                ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Posted Cash Receipt CZP", CashDeskRepSelectionsCZP."Sequence", CashDeskRepSelectionsCZP."Report ID");
                            AddEmailBodyLayout(ReportSelections, 'PostedRcptCashDocumentEmail.docx');
                        end;
                    CashDeskRepSelectionsCZP.Usage::"Posted Cash Withdrawal":
                        if not ReportSelections.Get(Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP", CashDeskRepSelectionsCZP.Sequence) then
                            ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Posted Cash Withdrawal CZP", CashDeskRepSelectionsCZP.Sequence, CashDeskRepSelectionsCZP."Report ID");
                end;
            until CashDeskRepSelectionsCZP.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetUseReportSelectionsUpgradeTag());
    end;

    local procedure AddEmailBodyLayout(ReportSelections: Record "Report Selections"; ReportLayoutName: Text[250])
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportSelections."Report ID");
        ReportLayoutList.SetRange(Name, ReportLayoutName);
        if not ReportLayoutList.FindFirst() then
            exit;

        ReportSelections."Use for Email Body" := true;
        ReportSelections."Email Body Layout Name" := CopyStr(ReportLayoutName, 1, MaxStrLen(ReportSelections."Email Body Layout Name"));
        ReportSelections."Email Body Layout AppID" := ReportLayoutList."Application ID";
        ReportSelections.Modify(false);
    end;
#endif

    local procedure SetDatabaseUpgradeTags();
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion173PerDatabaseUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion173PerDatabaseUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerDatabaseUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerDatabaseUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion180PerDatabaseUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion180PerDatabaseUpgradeTag());
    end;

    local procedure SetCompanyUpgradeTags();
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion173PerCompanyUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion173PerCompanyUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerCompanyUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion174PerCompanyUpgradeTag());
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion180PerCompanyUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZP.GetDataVersion180PerCompanyUpgradeTag());
    end;
}
