// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Counting.Reports;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Reports;
using Microsoft.Pricing.Reports;
using Microsoft.Projects.Project.Reports;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reports;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Reports;
using Microsoft.Warehouse.Reports;
using System.Upgrade;

codeunit 8143 "Report Filename Defaults"
{
    Access = Internal;
    // The two Company-Initialize events must share the pre-initialization state.
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Filename Setup" = ri,
                  tabledata "Report Filename Pattern" = ri;

    var
        CompanyWasInitialized: Boolean;
        DefaultPatternTok: Label '[Kind of Document]-[No.]', Locked = true;
        ReportNumberPatternTok: Label '[Report Name]-[No.]', Locked = true;
        ArchivePatternTok: Label '[Report Name]-[No.]-[Doc. No. Occurrence]-[Version No.]', Locked = true;
        RecordingPatternTok: Label '[Report Name]-[Order No.]-[Recording No.]', Locked = true;
        ContractPatternTok: Label '[Report Name]-[Contract No.]', Locked = true;
        QuestionnairePatternTok: Label '[Report Name]-[Code]', Locked = true;
        ReportRunPatternTok: Label '[Report Name]-[Report Run Date]', Locked = true;
        CertificatePatternTok: Label '[Report Name]-[Document Type]-[Document No.]', Locked = true;
        JobTaskPatternTok: Label '[Report Name]-[Job No.]-[Job Task No.]', Locked = true;
        ProductionOrderPatternTok: Label '[Report Name]-[Status]-[No.]', Locked = true;
        ServiceItemLinePatternTok: Label '[Report Name]-[Document Type]-[Document No.]-[Line No.]', Locked = true;

    internal procedure InitializeSetup(EnableForNewCompany: Boolean)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Enabled := EnableForNewCompany;
            ReportFilenameSetup.Insert(true);
        end;

        InsertDefaultPattern(Database::"Sales Invoice Header");
        InsertDefaultPattern(Database::"Sales Cr.Memo Header");
        InsertDefaultPattern(Database::"Purch. Inv. Header");
        InsertDefaultPattern(Database::"Purch. Cr. Memo Hdr.");
        InsertReportDefaults();
    end;

    internal procedure InitializeExistingCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // Both install and upgrade must leave subsequent user deletions intact.
        if UpgradeTag.HasUpgradeTag(GetDefaultPatternsUpgradeTag()) then
            exit;

        InitializeSetup(false);
        UpgradeTag.SetUpgradeTag(GetDefaultPatternsUpgradeTag());
    end;

    internal procedure GetDefaultPatternsUpgradeTag(): Code[250]
    begin
        exit('MS-658065-ReportFilenameDefaults-20261105');
    end;

    local procedure InsertDefaultPattern(TableNo: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // Even a disabled, filtered or report-specific pattern is an existing choice.
        Pattern.SetRange("Table No.", TableNo);
        if not Pattern.IsEmpty() then
            exit;

        Pattern.Init();
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", DefaultPatternTok);
        Pattern.Validate(Enabled, true);
        Pattern.Insert(true);
    end;

    local procedure InsertReportDefaults()
    begin
        // The four posted invoice/credit memo reports already use the table defaults above.
        InsertReportPattern(Report::"Customer - Labels", ReportNumberPatternTok);
        InsertReportPattern(Report::"Sales - Shipment", ReportNumberPatternTok);
        InsertReportPattern(Report::"Blanket Sales Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Pick Instruction", ReportNumberPatternTok);
        InsertReportPattern(Report::"Archived Sales Quote", ArchivePatternTok);
        InsertReportPattern(Report::"Archived Sales Order", ArchivePatternTok);
        InsertReportPattern(Report::"Vendor - Labels", ReportNumberPatternTok);
        InsertReportPattern(Report::"Purchase - Quote", ReportNumberPatternTok);
        InsertReportPattern(Report::Order, ReportNumberPatternTok);
        InsertReportPattern(Report::"Purchase - Receipt", ReportNumberPatternTok);
        InsertReportPattern(Report::"Blanket Purchase Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Archived Purchase Quote", ArchivePatternTok);
        InsertReportPattern(Report::"Archived Purchase Order", ArchivePatternTok);
        InsertReportPattern(Report::"Arch.Purch. Return Order", ArchivePatternTok);
        InsertReportPattern(Report::"Arch. Sales Return Order", ArchivePatternTok);
        InsertReportPattern(Report::"Price List", ReportNumberPatternTok);
        InsertReportPattern(Report::"Work Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Certificate of Supply", CertificatePatternTok);
        InsertReportPattern(Report::"Assembly Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Posted Assembly Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Job Quote", ReportNumberPatternTok);
        InsertReportPattern(Report::"Job Task Quote", JobTaskPatternTok);
        InsertReportPattern(Report::"Standard Sales - Pro Forma Inv", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Sales - Draft Invoice", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Sales - Quote", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Sales - Order Conf.", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Sales - Shipment", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Sales - Return Rcpt.", ReportNumberPatternTok);
        InsertReportPattern(Report::"Standard Purchase - Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Contact - Cover Sheet", ReportNumberPatternTok);
        InsertReportPattern(Report::"Contact - Labels", ReportNumberPatternTok);
        InsertReportPattern(Report::"Campaign - Details", ReportNumberPatternTok);
        InsertReportPattern(Report::"Segment - Cover Sheet", ReportNumberPatternTok);
        InsertReportPattern(Report::"Segment - Labels", ReportNumberPatternTok);
        InsertReportPattern(Report::"Questionnaire - Handouts", QuestionnairePatternTok);
        InsertReportPattern(Report::"Questionnaire - Test", QuestionnairePatternTok);
        InsertReportPattern(Report::"Opportunity - Details", ReportNumberPatternTok);
        // This report can run from either Contact or Segment, so neither number describes every run.
        InsertReportPattern(Report::"Contact Cover Sheet", ReportRunPatternTok, true);
        InsertReportPattern(Report::"Archived Blanket Purch. Order", ArchivePatternTok);
        InsertReportPattern(Report::"Archived Blanket Sales Order", ArchivePatternTok);
        InsertReportPattern(Report::"Prod. Order Comp. and Routing", ProductionOrderPatternTok);
        InsertReportPattern(Report::"Transfer Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Transfer Shipment", ReportNumberPatternTok);
        InsertReportPattern(Report::"Transfer Receipt", ReportNumberPatternTok);
        InsertReportPattern(Report::"Put-away List", ReportNumberPatternTok);
        InsertReportPattern(Report::"Picking List", ReportNumberPatternTok);
        InsertReportPattern(Report::"Phys. Invt. Recording", RecordingPatternTok);
        InsertReportPattern(Report::"Posted Phys. Invt. Recording", RecordingPatternTok);
        InsertReportPattern(Report::"Service Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Service Item Line Labels", ServiceItemLinePatternTok);
        InsertReportPattern(Report::"Service Quote", ReportNumberPatternTok);
        InsertReportPattern(Report::"Service - Invoice", ReportNumberPatternTok);
        InsertReportPattern(Report::"Service - Credit Memo", ReportNumberPatternTok);
        InsertReportPattern(Report::"Service - Shipment", ReportNumberPatternTok);
        InsertReportPattern(Report::"Service Contract", ContractPatternTok);
        InsertReportPattern(Report::"Service Contract-Detail", ContractPatternTok);
        InsertReportPattern(Report::"Service Contract Quote", ContractPatternTok);
        InsertReportPattern(Report::"Service Contract Quote-Detail", ContractPatternTok);
        // Both datasets contain only Integer loops over private temporary tracking buffers.
        InsertReportPattern(Report::"Item Tracing Specification", ReportRunPatternTok, true);
        InsertReportPattern(Report::"Item Tracking Appendix", ReportRunPatternTok, true);
        InsertReportPattern(Report::"Return Order Confirmation", ReportNumberPatternTok);
        InsertReportPattern(Report::"Purchase - Return Shipment", ReportNumberPatternTok);
        InsertReportPattern(Report::"Return Order", ReportNumberPatternTok);
        InsertReportPattern(Report::"Sales - Return Receipt", ReportNumberPatternTok);
        InsertReportPattern(Report::"Item Price List", ReportNumberPatternTok);
    end;

    local procedure InsertReportPattern(ReportId: Integer; PatternText: Text[250])
    begin
        InsertReportPattern(ReportId, PatternText, false);
    end;

    local procedure InsertReportPattern(ReportId: Integer; PatternText: Text[250]; RecordIndependent: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        TableNo: Integer;
    begin
        // Never introduce a more specific default over an existing table-level choice,
        // or compete with a report-specific choice, even when it is disabled or filtered.
        Pattern.SetRange("Report ID", ReportId);
        if not Pattern.IsEmpty() then
            exit;
        TableNo := ReportFilenameMgt.SubjectTableNo(ReportId);
        if HasTablePattern(TableNo) then
            exit;
        if ReportId = Report::"Contact Cover Sheet" then
            if HasTablePattern(Database::Contact) then
                exit;

        Pattern.Init();
        Pattern.Validate("Report ID", ReportId);
        if RecordIndependent then
            Pattern.Validate("Table No.", 0);
        Pattern.Validate("File Name Pattern", PatternText);
        Pattern.Validate(Enabled, true);
        Pattern.Insert(true);
    end;

    local procedure HasTablePattern(TableNo: Integer): Boolean
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.SetRange("Table No.", TableNo);
        Pattern.SetRange("Report ID", 0);
        exit(not Pattern.IsEmpty());
    end;

    internal procedure OnBeforeCompanyInitialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // A manual rerun in an existing company is not a new-company signal.
        CompanyWasInitialized := GeneralLedgerSetup.Get();
    end;

    internal procedure OnCompanyInitialize()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        EnableForNewCompany: Boolean;
    begin
        EnableForNewCompany := not CompanyWasInitialized;
        CompanyWasInitialized := true;
        // Copied settings and subsequent initialization must retain the user's choices.
        if ReportFilenameSetup.Get() then
            exit;
        // Company-Initialize has already set all upgrade tags before this event.
        // New-company seeding must not use the install/upgrade completion guard.
        InitializeSetup(EnableForNewCompany);
    end;
}
