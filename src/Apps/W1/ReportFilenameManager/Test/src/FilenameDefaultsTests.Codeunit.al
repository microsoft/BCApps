// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Reports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Inventory.Reports;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Upgrade;
using System.Utilities;

codeunit 149550 "Filename Defaults Tests"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    RequiredTestIsolation = Codeunit;

    var
        Assert: Codeunit "Library Assert";
        ReportTableDefaultErr: Label 'Report %1 must have one table default.', Locked = true, Comment = '%1 = Report ID.';
        ReportSpecificDefaultErr: Label 'Report %1 must have one report default.', Locked = true, Comment = '%1 = Report ID.';
        ReportEnabledErr: Label 'Report %1 must be enabled.', Locked = true, Comment = '%1 = Report ID.';
        RecordIndependentReportErr: Label 'Record-independent report %1 must resolve without a document.', Locked = true, Comment = '%1 = Report ID.';
        SingleRecordReportErr: Label 'Report %1 must name a single record.', Locked = true, Comment = '%1 = Report ID.';
        ReportIdentifierErr: Label 'Report %1 must include its actual record identifier: %2.', Locked = true, Comment = '%1 = Report ID, %2 = Resolved file name.';
        MultipleRecordReportErr: Label 'Report %1 must name a multi-record run.', Locked = true, Comment = '%1 = Report ID.';

    [Test]
    procedure NewCompanyGetsEnabledDefaults()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        Initialize();
        GeneralLedgerSetup.DeleteAll();

        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        GeneralLedgerSetup.Init();
        GeneralLedgerSetup.Insert();
        ReportFilenameDefaults.OnCompanyInitialize();

        AssertSetup(true, 100);
        AssertDefaults();
    end;

    [Test]
    procedure ExistingCompanyWithoutSetupIsNotEnabledByUpgrade()
    var
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        Initialize();

        ReportFilenameUpgrade.UpgradeDefaults();

        AssertSetup(false, 100);
        AssertDefaults();
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(ReportFilenameUpgrade.GetDefaultPatternsUpgradeTag()), 'Upgrade must be recorded.');
    end;

    [Test]
    procedure DefaultsResolveDocumentKindAndNumberForAllFourTables()
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
        TempPurchInvHeader: Record "Purch. Inv. Header" temporary;
        TempPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr." temporary;
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        DocumentRecRef: RecordRef;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        TempSalesInvoiceHeader."No." := 'DEFAULT-100';
        TempSalesInvoiceHeader.Insert();
        DocumentRecRef.GetTable(TempSalesInvoiceHeader);
        AssertDefaultName(DocumentRecRef);
        DocumentRecRef.Close();

        TempSalesCrMemoHeader."No." := 'DEFAULT-100';
        TempSalesCrMemoHeader.Insert();
        DocumentRecRef.GetTable(TempSalesCrMemoHeader);
        AssertDefaultName(DocumentRecRef);
        DocumentRecRef.Close();

        TempPurchInvHeader."No." := 'DEFAULT-100';
        TempPurchInvHeader.Insert();
        DocumentRecRef.GetTable(TempPurchInvHeader);
        AssertDefaultName(DocumentRecRef);
        DocumentRecRef.Close();

        TempPurchCrMemoHdr."No." := 'DEFAULT-100';
        TempPurchCrMemoHdr.Insert();
        DocumentRecRef.GetTable(TempPurchCrMemoHdr);
        AssertDefaultName(DocumentRecRef);
        DocumentRecRef.Close();
    end;

    [Test]
    procedure PlatformNamingPreservesServerPathsAndStillNamesClientOutput()
    var
        TempSalesInvoiceHeader: Record "Sales Invoice Header" temporary;
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportFilenameSubscribers: Codeunit "Report Filename Subscribers";
        DocumentRecRef: RecordRef;
        Payload: JsonObject;
        FileName: Text;
        ServerPath: Text;
        Success: Boolean;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        TempSalesInvoiceHeader."No." := 'DEFAULT-100';
        TempSalesInvoiceHeader.Insert();
        DocumentRecRef.GetTable(TempSalesInvoiceHeader);
        Payload.Add('intent', 'Save');
        ServerPath := 'C:\Temp\report-filename-defaults.pdf';
        FileName := ServerPath;

        ReportFilenameSubscribers.NameFromPlatformEvent(
            Report::"Standard Sales - Invoice", Payload, '.pdf', DocumentRecRef, FileName, Success);

        Assert.AreEqual(ServerPath, FileName, 'The caller must be able to reopen its explicit server output path.');
        Assert.IsFalse(Success, 'Preserving a server path must leave platform naming unhandled.');

        Clear(FileName);
        ReportFilenameSubscribers.NameFromPlatformEvent(
            Report::"Standard Sales - Invoice", Payload, '.pdf', DocumentRecRef, FileName, Success);

        Assert.IsTrue(Success, 'A server render must not suppress the next client filename.');
        Assert.AreNotEqual('', FileName, 'The default must still name a client Save operation.');
        Assert.IsTrue(FileName.EndsWith('.pdf'), 'Client output must retain its file extension.');
        DocumentRecRef.Close();
    end;

    [Test]
    procedure EveryRequestedReportResolvesSingleAndMultipleRecords()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Subject: RecordRef;
        ReportIds: List of [Integer];
        ReportId: Integer;
        FileName: Text;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        RequestedReportIds(ReportIds);

        foreach ReportId in ReportIds do begin
            Pattern.Reset();
            Pattern.SetRange("Report ID", ReportId);
            if not Pattern.FindFirst() then begin
                Pattern.SetRange("Report ID", 0);
                Pattern.SetRange("Table No.", ReportFilenameMgt.SubjectTableNo(ReportId));
                Assert.AreEqual(1, Pattern.Count(), StrSubstNo(ReportTableDefaultErr, ReportId));
                Pattern.FindFirst();
            end else
                Assert.AreEqual(1, Pattern.Count(), StrSubstNo(ReportSpecificDefaultErr, ReportId));
            Assert.IsTrue(Pattern.Enabled, StrSubstNo(ReportEnabledErr, ReportId));

            if Pattern."Table No." = 0 then begin
                Clear(Subject);
                Assert.IsTrue(ReportFilenameMgt.TryResolve(ReportId, "Report Filename Output Route"::Save, Subject, '', FileName),
                    StrSubstNo(RecordIndependentReportErr, ReportId));
                Assert.AreNotEqual('', FileName, 'The report name and run date must have values.');
            end else begin
                Assert.AreEqual(ReportFilenameMgt.SubjectTableNo(ReportId), Pattern."Table No.", 'The default must name the actual report subject.');
                Subject.Open(Pattern."Table No.", true);
                InsertTemporarySubject(Subject, '100');
                Assert.IsTrue(ReportFilenameMgt.TryResolve(ReportId, "Report Filename Output Route"::Save, Subject, '', FileName),
                    StrSubstNo(SingleRecordReportErr, ReportId));
                Assert.IsTrue(FileName.Contains('DEFAULT-100'), StrSubstNo(ReportIdentifierErr, ReportId, FileName));

                InsertTemporarySubject(Subject, '200');
                Assert.IsTrue(ReportFilenameMgt.TryResolve(ReportId, "Report Filename Output Route"::Save, Subject, '', FileName),
                    StrSubstNo(MultipleRecordReportErr, ReportId));
                Assert.IsTrue(FileName.Contains('DEFAULT-100'), 'A multi-record name must retain the first identifier.');
                Assert.IsTrue(FileName.Contains('DEFAULT-200'), 'A multi-record name must retain the second identifier.');
                Subject.Close();
            end;
        end;
    end;

    [Test]
    procedure ExistingTableChoiceSuppressesMoreSpecificReportDefaults()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        EntryNo: Integer;
    begin
        Initialize();
        Pattern.Validate("Table No.", Database::"Sales Header");
        Pattern.Validate("File Name Pattern", 'Custom-[No.]');
        Pattern.Insert(true);
        EntryNo := Pattern."Entry No.";

        ReportFilenameDefaults.InitializeSetup(false);
        ReportFilenameDefaults.InitializeSetup(false);

        Pattern.SetRange("Table No.", Database::"Sales Header");
        Assert.AreEqual(1, Pattern.Count(), 'No report default may shadow an existing disabled table choice.');
        Pattern.FindFirst();
        Assert.AreEqual(EntryNo, Pattern."Entry No.", 'The existing table pattern must remain untouched.');
        Assert.IsFalse(Pattern.Enabled, 'Initialization must not enable an existing choice.');
    end;

    [Test]
    procedure DisabledReportChoiceDoesNotSuppressOtherReportsOnItsTable()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        EntryNo: Integer;
    begin
        Initialize();
        Pattern.Validate("Report ID", Report::"Standard Sales - Quote");
        Pattern.Validate("File Name Pattern", 'Custom-[No.]');
        Pattern.Insert(true);
        EntryNo := Pattern."Entry No.";

        ReportFilenameDefaults.InitializeSetup(true);
        ReportFilenameDefaults.InitializeSetup(true);

        Pattern.SetRange("Report ID", Report::"Standard Sales - Quote");
        Assert.AreEqual(1, Pattern.Count(), 'An existing report choice must not get a competing default.');
        Pattern.FindFirst();
        Assert.AreEqual(EntryNo, Pattern."Entry No.", 'The existing report pattern must remain untouched.');
        Assert.IsFalse(Pattern.Enabled, 'Disabled report patterns must remain disabled.');
        Pattern.SetRange("Report ID", Report::"Standard Sales - Order Conf.");
        Assert.AreEqual(1, Pattern.Count(), 'Other requested reports on the same table still need their own defaults.');
    end;

    [Test]
    procedure ContactCoverSheetNamesEitherSourceWithoutInventingANumber()
    var
        TempContact: Record Contact temporary;
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Subject: RecordRef;
        ContactName: Text;
        SegmentName: Text;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        TempContact."No." := 'CONTACT-100';
        TempContact.Insert();
        TempContact."No." := 'CONTACT-200';
        TempContact.Insert();
        Subject.GetTable(TempContact);

        Assert.IsTrue(ReportFilenameMgt.TryResolve(Report::"Contact Cover Sheet", "Report Filename Output Route"::Save, Subject, '', ContactName),
            'The contact-driven cover sheet must resolve for multiple contacts.');
        Subject.Close();
        Subject.Open(ReportFilenameMgt.SubjectTableNo(Report::"Contact Cover Sheet"), true);
        InsertTemporarySubject(Subject, '100');
        InsertTemporarySubject(Subject, '200');
        Assert.IsTrue(ReportFilenameMgt.TryResolve(Report::"Contact Cover Sheet", "Report Filename Output Route"::Save, Subject, '', SegmentName),
            'The segment-driven cover sheet must resolve for multiple segments.');

        Assert.AreEqual(ContactName, SegmentName, 'Both sources use the report caption and run date, not the wrong table number.');
        Assert.IsFalse(ContactName.Contains('CONTACT-'), 'A record-independent pattern must not invent a segment number for contacts.');
        Subject.Close();
    end;

    [Test]
    procedure TrackingDefaultsDoNotNeedPersistentRecordsOrVirtualLoopNumbers()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportFilenameSubscribers: Codeunit "Report Filename Subscribers";
        Subject: RecordRef;
        LoopNumber: FieldRef;
        Payload: JsonObject;
        FileName: Text;
        Success: Boolean;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        Payload.Add('intent', 'Save');

        ReportFilenameSubscribers.NameFromPlatformEvent(Report::"Item Tracing Specification", Payload, '.pdf', Subject, FileName, Success);
        Assert.IsTrue(Success, 'An Integer-only tracing report must be named without a source record.');
        Assert.IsTrue(FileName.EndsWith('.pdf'), 'The output route must preserve the format extension.');

        Subject.Open(Database::Integer);
        LoopNumber := Subject.Field(1);
        LoopNumber.SetRange(1, 5);
        Clear(FileName);
        Success := false;
        ReportFilenameSubscribers.NameFromPlatformEvent(Report::"Item Tracking Appendix", Payload, '.pdf', Subject, FileName, Success);
        Assert.IsTrue(Success, 'A multi-row virtual loop must use only report-level placeholders.');
        Assert.IsFalse(FileName.Contains('1-2-3'), 'Integer loop counters are not document numbers.');
        Subject.Close();
    end;

    [Test]
    procedure InstallingIntoExistingCompanyDoesNotEnableIt()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        Initialize();
        EnsureGeneralLedgerSetup();

        ReportFilenameDefaults.InitializeExistingCompany();

        AssertSetup(false, 100);
        AssertDefaults();
    end;

    [Test]
    procedure InstallationDoesNotEnableAnUninitializedExistingCompany()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        Initialize();
        GeneralLedgerSetup.DeleteAll();

        ReportFilenameDefaults.InitializeExistingCompany();
        AssertSetup(false, 100);
        AssertDefaults();
        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        ReportFilenameDefaults.OnCompanyInitialize();

        AssertSetup(false, 100);
        AssertDefaults();
    end;

    [Test]
    procedure ReinitializingExistingCompanyWithoutSetupDoesNotEnableIt()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        Initialize();
        EnsureGeneralLedgerSetup();

        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        ReportFilenameDefaults.OnCompanyInitialize();

        AssertSetup(false, 100);
        AssertDefaults();
    end;

    [Test]
    procedure UpgradePreservesEnabledSetupAndCustomPattern()
    begin
        VerifyUpgradePreservesConfiguration(true);
    end;

    [Test]
    procedure UpgradePreservesDisabledSetupAndCustomPattern()
    begin
        VerifyUpgradePreservesConfiguration(false);
    end;

    [Test]
    procedure UpgradePreservesEnabledCustomizedTablePattern()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
        EntryNo: Integer;
        AppId: Guid;
    begin
        Initialize();
        CreateSetup(true);
        AppId := CreateGuid();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", 'Custom-[No.]');
        Pattern.Validate(Separator, '_');
        Pattern.Validate("Max. Values Named", 5);
        Pattern."App ID" := AppId;
        Pattern.Validate(Enabled, true);
        Pattern.Insert(true);
        EntryNo := Pattern."Entry No.";

        ReportFilenameUpgrade.UpgradeDefaults();

        Pattern.Get(EntryNo);
        Assert.IsTrue(Pattern.Enabled, 'Enabled custom patterns must remain enabled.');
        Assert.AreEqual('Custom-[No.]', Pattern."File Name Pattern", 'Custom naming must not be overwritten.');
        Assert.AreEqual('_', Pattern.Separator, 'Custom separators must be preserved.');
        Assert.AreEqual(5, Pattern."Max. Values Named", 'Custom aggregation settings must be preserved.');
        Assert.AreEqual(AppId, Pattern."App ID", 'The inserting app must be preserved.');
        Assert.AreEqual(69, Pattern.Count(), 'A customized table pattern must suppress a competing default.');
    end;

    [Test]
    procedure MissingSetupWithCustomPatternIsNotANewCompany()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
        EntryNo: Integer;
    begin
        Initialize();
        CreateCustomPattern(Pattern);
        EntryNo := Pattern."Entry No.";

        ReportFilenameUpgrade.UpgradeDefaults();

        AssertSetup(false, 100);
        AssertCustomPattern(EntryNo);
        Assert.AreEqual(69, Pattern.Count(), 'The custom pattern replaces its table default without preventing other defaults.');
    end;

    [Test]
    procedure RepeatedInitializationDoesNotDuplicateOrReenablePatterns()
    var
        Setup: Record "Report Filename Setup";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        EntryNo: Integer;
    begin
        Initialize();
        ReportFilenameDefaults.InitializeSetup(true);
        Setup.Get();
        Setup.Enabled := false;
        Setup.Modify();
        Pattern.SetRange("Table No.", Database::"Sales Invoice Header");
        Pattern.FindFirst();
        EntryNo := Pattern."Entry No.";
        Pattern.Validate(Enabled, false);
        Pattern.Modify(true);

        ReportFilenameDefaults.InitializeSetup(true);
        ReportFilenameDefaults.InitializeSetup(false);
        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        ReportFilenameDefaults.OnCompanyInitialize();

        AssertSetup(false, 100);
        Pattern.Get(EntryNo);
        Assert.IsFalse(Pattern.Enabled, 'Initialization must not reenable a disabled default.');
        Pattern.Reset();
        Assert.AreEqual(69, Pattern.Count(), 'Repeated initialization must not duplicate defaults.');
    end;

    [Test]
    procedure RepeatedUpgradeDoesNotRestoreDeletedDefaults()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
    begin
        Initialize();
        ReportFilenameUpgrade.UpgradeDefaults();
        Pattern.SetRange("Table No.", Database::"Sales Invoice Header");
        Pattern.DeleteAll();

        ReportFilenameUpgrade.UpgradeDefaults();

        Assert.IsTrue(Pattern.IsEmpty(), 'A completed upgrade must not undo a subsequent deletion.');
        Pattern.Reset();
        Assert.AreEqual(68, Pattern.Count(), 'Upgrade must run only once.');
    end;

    [Test]
    procedure CompanyInitializePreservesCopiedDisabledConfiguration()
    begin
        VerifyCompanyInitializePreservesConfiguration(false);
    end;

    [Test]
    procedure CompanyInitializePreservesCopiedEnabledConfiguration()
    begin
        VerifyCompanyInitializePreservesConfiguration(true);
    end;

    local procedure VerifyUpgradePreservesConfiguration(Enabled: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
        EntryNo: Integer;
    begin
        Initialize();
        CreateSetup(Enabled);
        CreateCustomPattern(Pattern);
        EntryNo := Pattern."Entry No.";

        ReportFilenameUpgrade.UpgradeDefaults();
        ReportFilenameUpgrade.UpgradeDefaults();
        ReportFilenameDefaults.InitializeExistingCompany();
        ReportFilenameDefaults.InitializeExistingCompany();

        AssertSetup(Enabled, 75);
        AssertCustomPattern(EntryNo);
        Assert.AreEqual(69, Pattern.Count(), 'Custom report-specific patterns must suppress a competing table default.');
    end;

    local procedure VerifyCompanyInitializePreservesConfiguration(Enabled: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
        EntryNo: Integer;
    begin
        Initialize();
        CreateSetup(Enabled);
        CreateCustomPattern(Pattern);
        EntryNo := Pattern."Entry No.";

        // Model the configuration already copied by CopyCompany. Do not copy business data in a unit test.
        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        ReportFilenameDefaults.OnCompanyInitialize();
        ReportFilenameDefaults.OnBeforeCompanyInitialize();
        ReportFilenameDefaults.OnCompanyInitialize();

        AssertSetup(Enabled, 75);
        AssertCustomPattern(EntryNo);
        Assert.AreEqual(1, Pattern.Count(), 'Company initialization must leave a copied configuration unchanged.');
    end;

    local procedure Initialize()
    var
        Setup: Record "Report Filename Setup";
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        ReportFilenameUpgrade: Codeunit "Report Filename Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        Setup.DeleteAll();
        Pattern.DeleteAll();
        if UpgradeTag.HasUpgradeTag(ReportFilenameUpgrade.GetDefaultPatternsUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(ReportFilenameUpgrade.GetDefaultPatternsUpgradeTag(), CopyStr(CompanyName(), 1, 30));
    end;

    local procedure EnsureGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Init();
            GeneralLedgerSetup.Insert();
        end;
    end;

    local procedure CreateSetup(Enabled: Boolean)
    var
        Setup: Record "Report Filename Setup";
    begin
        Setup.Init();
        Setup.Enabled := Enabled;
        Setup."Max. File Name Length" := 75;
        Setup.Insert();
    end;

    local procedure CreateCustomPattern(var Pattern: Record "Report Filename Pattern")
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", 'Custom-[No.]');
        Pattern.Validate(Enabled, false);
        Pattern.Insert(true);
    end;

    local procedure AssertCustomPattern(EntryNo: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Get(EntryNo);
        Assert.AreEqual('Custom-[No.]', Pattern."File Name Pattern", 'Custom naming must not be overwritten.');
        Assert.AreEqual(Report::"Standard Sales - Invoice", Pattern."Report ID", 'Custom report scope must not be overwritten.');
        Assert.IsFalse(Pattern.Enabled, 'Disabled custom patterns must remain disabled.');
    end;

    local procedure AssertSetup(Enabled: Boolean; MaxLength: Integer)
    var
        Setup: Record "Report Filename Setup";
    begin
        Setup.Get();
        Assert.AreEqual(Enabled, Setup.Enabled, 'Unexpected company feature state.');
        Assert.AreEqual(MaxLength, Setup."Max. File Name Length", 'Unexpected maximum filename length.');
    end;

    local procedure AssertDefaults()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Assert.AreEqual(69, Pattern.Count(), 'The full requested report catalogue must be seeded without overlapping defaults.');
        AssertDefault(Database::"Sales Invoice Header");
        AssertDefault(Database::"Sales Cr.Memo Header");
        AssertDefault(Database::"Purch. Inv. Header");
        AssertDefault(Database::"Purch. Cr. Memo Hdr.");
    end;

    local procedure RequestedReportIds(var ReportIds: List of [Integer])
    begin
        ReportIds.AddRange(
            110, 208, 210, 214, 215, 216, 310, 404, 405, 406, 407, 408, 410, 415, 416, 417, 418,
            715, 752, 780, 902, 910, 1016, 1017, 1302, 1303, 1304, 1305, 1306, 1307, 1308, 1309, 1322,
            5055, 5056, 5060, 5064, 5065, 5066, 5067, 5068, 5085, 5174, 5176, 5500,
            5703, 5704, 5705, 5751, 5752, 5878, 5879, 5900, 5901, 5902, 5911, 5912, 5913,
            5970, 5971, 5972, 5973, 6520, 6521, 6631, 6636, 6641, 6646, 7050);
    end;

    local procedure InsertTemporarySubject(var Subject: RecordRef; Suffix: Text)
    var
        KeyField: FieldRef;
        SubjectKey: KeyRef;
        FieldIndex: Integer;
    begin
        Subject.Init();
        SubjectKey := Subject.KeyIndex(1);
        for FieldIndex := 1 to SubjectKey.FieldCount do begin
            KeyField := SubjectKey.FieldIndex(FieldIndex);
            case KeyField.Type of
                FieldType::Code, FieldType::Text:
                    KeyField.Value := 'DEFAULT-' + Suffix;
                FieldType::Integer:
                    KeyField.Value := 1;
            end;
        end;
        Subject.Insert();
    end;

    local procedure AssertDefault(TableNo: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.SetRange("Table No.", TableNo);
        Assert.AreEqual(1, Pattern.Count(), 'Each document table must have exactly one default.');
        Pattern.FindFirst();
        Pattern.CalcFields("Placeholder Binding", "Table Filter");
        Assert.AreEqual('[Kind of Document]-[No.]', Pattern."File Name Pattern", 'Use the existing document-kind placeholder.');
        Assert.IsTrue(Pattern.Enabled, 'Default patterns must be enabled.');
        Assert.IsTrue(Pattern."Placeholder Binding".HasValue(), 'Default placeholders must be bound by validation.');
        Assert.IsFalse(Pattern."Table Filter".HasValue(), 'Defaults must not filter out documents.');
        Assert.AreEqual(0, Pattern."Report ID", 'Defaults must support every report on the document table.');
        Assert.AreEqual('', Pattern."Language Code", 'Defaults must not restrict the document language.');
        Assert.AreEqual('', Pattern."Output Route Filter", 'Defaults must support every output route.');
        Assert.IsFalse(IsNullGuid(Pattern."App ID"), 'Defaults must retain their owning app.');
    end;

    local procedure AssertDefaultName(var DocumentRecRef: RecordRef)
    var
        Pattern: Record "Report Filename Pattern";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentKind: Text;
        FileName: Text;
    begin
        Pattern.SetRange("Table No.", DocumentRecRef.Number());
        Pattern.FindFirst();
        DocumentKind := ReportDistributionManagement.GetFullDocumentTypeText(DocumentRecRef);
        Assert.AreNotEqual('', DocumentKind, 'Business Central must recognize each default document kind.');
        Assert.IsTrue(ReportFilenameMgt.TryResolveWithPattern(Pattern, 0, DocumentRecRef, FileName), 'The seeded pattern must resolve.');
        Assert.AreEqual(
            ReportFilenameMgt.Sanitise(DocumentKind + '-DEFAULT-100'), FileName,
            'The filename must contain the existing document-kind text and the document number.');
    end;
}
