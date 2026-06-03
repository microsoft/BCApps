// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.CRM.Contact;
#if not CLEANSCHEMA32
using Microsoft.Foundation.Reporting;
#endif
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 31263 "Upgrade Application CZC"
{
    Subtype = Upgrade;

    var
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitionsCZC: Codeunit "Upgrade Tag Definitions CZC";

    trigger OnUpgradePerDatabase()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();
    end;

    trigger OnUpgradePerCompany()
    begin
        DataUpgradeMgt.SetUpgradeInProgress();
        UpgradeCompensationLanguage();
        UpgradePostedCompensationLanguage();
#if not CLEANSCHEMA32
        UpgradeReportSelections();
#endif
    end;

    local procedure UpgradeCompensationLanguage()
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZC.GetCompensationLanguageCodeUpgradeTag()) then
            exit;

        CompensationHeaderCZC.SetLoadFields("Company Type", "Company No.", "Language Code", "Format Region");
        if CompensationHeaderCZC.FindSet(true) then
            repeat
                CompensationHeaderCZC."Language Code" :=
                    GetLanguageCode(CompensationHeaderCZC."Company Type", CompensationHeaderCZC."Company No.");
                CompensationHeaderCZC."Format Region" :=
                    GetFormatRegion(CompensationHeaderCZC."Company Type", CompensationHeaderCZC."Company No.");
                CompensationHeaderCZC.Modify();
            until CompensationHeaderCZC.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZC.GetCompensationLanguageCodeUpgradeTag());
    end;

    local procedure UpgradePostedCompensationLanguage()
    var
        PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZC.GetPostedCompensationLanguageCodeUpgradeTag()) then
            exit;

        PostedCompensationHeaderCZC.SetLoadFields("Company Type", "Company No.", "Language Code", "Format Region");
        if PostedCompensationHeaderCZC.FindSet(true) then
            repeat
                PostedCompensationHeaderCZC."Language Code" :=
                    GetLanguageCode(PostedCompensationHeaderCZC."Company Type", PostedCompensationHeaderCZC."Company No.");
                PostedCompensationHeaderCZC."Format Region" :=
                    GetFormatRegion(PostedCompensationHeaderCZC."Company Type", PostedCompensationHeaderCZC."Company No.");
                PostedCompensationHeaderCZC.Modify();
            until PostedCompensationHeaderCZC.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZC.GetPostedCompensationLanguageCodeUpgradeTag());
    end;
#if not CLEANSCHEMA32

    local procedure UpgradeReportSelections()
    var
        CompensReportSelectionsCZC: Record "Compens. Report Selections CZC";
        ReportSelections: Record "Report Selections";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitionsCZC.GetUseReportSelectionsUpgradeTag()) then
            exit;

        if CompensReportSelectionsCZC.FindSet(false) then
            repeat
                case CompensReportSelectionsCZC.Usage of
                    CompensReportSelectionsCZC.Usage::"Compensation":
                        begin
                            ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Compensation CZC", CompensReportSelectionsCZC."Sequence", CompensReportSelectionsCZC."Report ID");
                            AddEmailBodyLayout(ReportSelections, 'CompensationEmail.docx');
                        end;
                    CompensReportSelectionsCZC.Usage::"Posted Compensation":
                        begin
                            ReportSelections.InsertRecord(Enum::"Report Selection Usage"::"Posted Compensation CZC", CompensReportSelectionsCZC.Sequence, CompensReportSelectionsCZC."Report ID");
                            AddEmailBodyLayout(ReportSelections, 'PostedCompensationEmail.docx');
                        end;
                end;
            until CompensReportSelectionsCZC.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitionsCZC.GetUseReportSelectionsUpgradeTag());
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
        ReportSelections.Modify();
    end;
#endif

    internal procedure GetLanguageCode(CompanyType: Enum "Compensation Company Type CZC"; CompanyNo: Code[20]): Code[10]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        case CompanyType of
            CompanyType::Customer:
                begin
                    Customer.SetLoadFields("Language Code");
                    if Customer.Get(CompanyNo) then
                        exit(Customer."Language Code");
                end;
            CompanyType::Contact:
                begin
                    Contact.SetLoadFields("Language Code");
                    if Contact.Get(CompanyNo) then
                        exit(Contact."Language Code");
                end;
            CompanyType::Vendor:
                begin
                    Vendor.SetLoadFields("Language Code");
                    if Vendor.Get(CompanyNo) then
                        exit(Vendor."Language Code");
                end;
        end;
    end;

    internal procedure GetFormatRegion(CompanyType: Enum "Compensation Company Type CZC"; CompanyNo: Code[20]): Text[80]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        case CompanyType of
            CompanyType::Customer:
                begin
                    Customer.SetLoadFields("Format Region");
                    if Customer.Get(CompanyNo) then
                        exit(Customer."Format Region");
                end;
            CompanyType::Contact:
                begin
                    Contact.SetLoadFields("Format Region");
                    if Contact.Get(CompanyNo) then
                        exit(Contact."Format Region");
                end;
            CompanyType::Vendor:
                begin
                    Vendor.SetLoadFields("Format Region");
                    if Vendor.Get(CompanyNo) then
                        exit(Vendor."Format Region");
                end;
        end;
    end;
}
