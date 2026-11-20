// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.TestLibraries.Environment;

codeunit 148016 "IRS Reporting Period Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        AnnualFixturePrepared: Boolean;
        IdentityCopySummary: Text;
        StartingEndingDateOverlapErr: Label 'The starting date and ending date overlap with an existing reporting period.';
        AmountShouldBeResetErr: Label 'Amount should be reset to 0';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapWithStartingDate()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20240101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapWithEndingDate()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20241231D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20250101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapStartingInTheMiddle()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240501D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20250101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapEndinggInTheMiddle()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20240501D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodBeforeExisting()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan can create a new reporting period before the existing one

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        IRSReportingPeriod.Validate("Ending Date", 20231231D);
        IRSReportingPeriod.Insert();

        Assert.RecordCount(IRSReportingPeriod, 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodAfterExisting()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan can create a new reporting period after the existing one

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20250101D);
        IRSReportingPeriod.Validate("Ending Date", 20251231D);
        IRSReportingPeriod.Insert();

        Assert.RecordCount(IRSReportingPeriod, 2);
    end;

    [Test]
    procedure IRSFormsGuideCreatesReportingPeriodOnFinish()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        IRS1099Form: Record "IRS 1099 Form";
        IRSFormsGuidePage: TestPage "IRS Forms Guide";
        ReportingYear: Integer;
    begin
        // [SCENARIO 615776] When user specifies the "Init Reporting Year" and finishes the IRS Forms Guide, a reporting period with forms is created

        Initialize();
        ReportingYear := Date2DMY(WorkDate(), 3) + 10;
        // [GIVEN] No reporting period exists for the year
        IRSReportingPeriod.SetRange("No.", Format(ReportingYear));
        IRSReportingPeriod.DeleteAll();

        // [GIVEN] IRS Forms Guide page is opened
        IRSFormsGuidePage.OpenEdit();
        // [GIVEN] User navigates to the Data step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [GIVEN] User sets the Reporting Year to the specified year
        IRSFormsGuidePage.ReportingYearControl.SetValue(ReportingYear);
        // [GIVEN] User navigates to the Features step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [GIVEN] User navigates to the Finish step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [WHEN] User clicks Finish
        IRSFormsGuidePage.ActionFinish.Invoke();

        // [THEN] IRS Reporting Period is created for the specified year
        IRSReportingPeriod.SetRange("No.", Format(ReportingYear));
        Assert.RecordIsNotEmpty(IRSReportingPeriod);
        IRSReportingPeriod.FindFirst();
        Assert.AreEqual(DMY2Date(1, 1, ReportingYear), IRSReportingPeriod."Starting Date", 'Starting Date should be Jan 1');
        Assert.AreEqual(DMY2Date(31, 12, ReportingYear), IRSReportingPeriod."Ending Date", 'Ending Date should be Dec 31');
        // [THEN] IRS 1099 Forms are created for the reporting period
        IRS1099Form.SetRange("Period No.", IRSReportingPeriod."No.");
        Assert.RecordIsNotEmpty(IRS1099Form);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure VendorFormBoxAdjustmentAmountIsResetWhenCopyingSetup()
    var
        IRS1099VendorFormBoxAdj: Record "IRS 1099 Vendor Form Box Adj.";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        FromStartDate: Date;
        FromEndDate: Date;
        ToStartDate: Date;
        ToEndDate: Date;
    begin
        // [SCENARIO 623874] When copying reporting period setup with vendor form box adjustments, the Amount field is reset to 0 in the target period
        Initialize();

        // [GIVEN] Reporting period for current year with vendor form box adjustment "V" for form "MISC" box "01" with Amount = 1000
        FromStartDate := CalcDate('<-CY>', WorkDate());
        FromEndDate := CalcDate('<CY>', WorkDate());
        FromPeriodNo := LibraryIRSReportingPeriod.CreateReportingPeriod(FromStartDate, FromEndDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(FromStartDate, FromEndDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(FromStartDate, FromEndDate, FormNo);
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(FromStartDate, FromEndDate, FormNo, FormBoxNo);
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryIRS1099FormBox.AddAdjustmentAmountForVendor(FromStartDate, FromEndDate, VendorNo, FormNo, FormBoxNo, Amount);

        // [GIVEN] Reporting period for next year exists
        ToStartDate := CalcDate('<1Y>', FromStartDate);
        ToEndDate := CalcDate('<1Y>', FromEndDate);
        ToPeriodNo := LibraryIRSReportingPeriod.CreateReportingPeriod(ToStartDate, ToEndDate);

        // [WHEN] Copy setup from current year to next year
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Vendor form box adjustment is copied to next year with Amount = 0
        IRS1099VendorFormBoxAdj.SetRange("Period No.", ToPeriodNo);
        IRS1099VendorFormBoxAdj.SetRange("Vendor No.", VendorNo);
        IRS1099VendorFormBoxAdj.SetRange("Form No.", FormNo);
        IRS1099VendorFormBoxAdj.SetRange("Form Box No.", FormBoxNo);
        Assert.RecordIsNotEmpty(IRS1099VendorFormBoxAdj);
        IRS1099VendorFormBoxAdj.FindFirst();
        Assert.AreEqual(0, IRS1099VendorFormBoxAdj.Amount, AmountShouldBeResetErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFreshDefaultsUseTheReportingYear()
    var
        Definition: Record "IRS 1099 Suppl. Box";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalLineCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Fresh tax-year defaults change only the seven selected 2026 categories.
        Initialize();

        // [GIVEN] Fresh 2025 and 2026 setup.
        SupplementalLineCount := SupplLine.Count();
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);

        // [WHEN] The standard thresholds and definitions are read.
        // [THEN] Historical exceptions, other categories and typed setup remain distinct.
        VerifyAnnualThresholds('2025', 600, 1, 0);
        VerifyAnnualThresholds('2026', 2000, 2000, 2000);
        VerifyYearInstructions('2025', false);
        VerifyYearInstructions('2026', true);
        Definition.SetRange("Period No.", '2025');
        Assert.RecordIsEmpty(Definition);
        Definition.SetRange("Period No.", '2026');
        Assert.RecordCount(Definition, 6);
        VerifyStandardDefinitions('2026');
        Assert.AreEqual(SupplementalLineCount, SupplLine.Count(), 'Seeding annual setup must not create saved document disclosures.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFutureDefaultsIncludeSupplementalSetup()
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        // [SCENARIO] Annual setup carries the supplemental definitions and statement instructions into future years.
        Initialize();
        CreateAnnualSetup(2027);

        Definition.SetRange("Period No.", '2027');
        Assert.RecordCount(Definition, 6);
        VerifyStandardDefinitions('2027');
        VerifyAnnualThresholds('2027', 2000, 2000, 2000);
        VerifyYearInstructions('2027', true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure AnnualCopyReconcilesAndPreservesOverrides()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Copying 2025 to 2026 converges without inheriting schema overrides or duplicating setup.
        Initialize();

        // [GIVEN] Source setup has overrides and the target has none.
        CreateAnnualSetup(2025);
        ReportingPeriod.Get('2025');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"5.0.7";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"2.0.3";
        ReportingPeriod.Modify();
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2026', 20260101D, 20261231D);

        // [WHEN] Setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] Only the target defaults change and its new overrides remain empty.
        VerifyAnnualThresholds('2025', 600, 1, 0);
        VerifyAnnualThresholds('2026', 2000, 2000, 2000);
        VerifyYearInstructions('2025', false);
        VerifyYearInstructions('2026', true);
        VerifyOverrides('2026', Enum::"XML Schema Version IRIS"::" ", Enum::"XML Schema Version IRIS"::" ");
        StatementLine.Get('2025', 'NEC', 10000);
        Assert.AreEqual('Nonemployee Compensation', StatementLine.Description, 'The source-year label is unchanged.');
        StatementLine.Get('2026', 'NEC', 10000);
        Assert.AreEqual('Nonemployee Compensation (box 1a)', StatementLine.Description, 'Recognized prior-standard compensation labels follow the target year.');
        StatementLine.Get('2026', 'NEC', 12500);
        Assert.AreEqual(StatementLine."Value Source"::"Supplemental Line", StatementLine."Value Source", 'Copied setup gains explicit supplemental selectors.');

        // [GIVEN] The target now has explicit overrides and a customized threshold.
        ReportingPeriod.Get('2026');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"2.0.3";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"5.0.7";
        ReportingPeriod.Modify();
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2500;
        FormBox.Modify();

        // [WHEN] The copy is repeated into existing setup.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] Existing target choices remain and no definitions are duplicated.
        VerifyOverrides('2026', Enum::"XML Schema Version IRIS"::"2.0.3", Enum::"XML Schema Version IRIS"::"5.0.7");
        VerifyMinimum('2026', 'NEC', 'NEC-01', 2500);
        Definition.SetRange("Period No.", '2026');
        Assert.RecordCount(Definition, 6);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualReconciliationPreservesCustomizationsAndReportsConflicts()
    var
        FormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reconciliation inserts absent defaults, recognizes prior standards and preserves custom choices.
        Initialize();

        // [GIVEN] An existing target has an absent box, old standard and custom setup.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'MISC', 'MISC-01');
        FormBox.Delete(true);
        FormBox.Get('2026', 'MISC', 'MISC-09');
        FormBox."Minimum Reportable Amount" := 1;
        FormBox.Modify();
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2500;
        FormBox.Description := 'Custom compensation';
        FormBox.Modify();
        Definition.Get('2026', 'NEC', 'NEC-01B');
        Definition.Description := 'Custom tips label';
        Definition.Modify(true);
        Definition.Get('2026', 'NEC', 'NEC-01D');
        Definition."XML Element Name" := 'CUSTOM';
        Definition.Modify();

        // [WHEN] The explicit reconciliation is repeated.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] The custom values are preserved and identified for explicit resolution.
        VerifyMinimum('2026', 'MISC', 'MISC-01', 2000);
        VerifyMinimum('2026', 'MISC', 'MISC-09', 2000);
        VerifyMinimum('2026', 'NEC', 'NEC-01', 2500);
        FormBox.Get('2026', 'NEC', 'NEC-01');
        Assert.AreEqual('Custom compensation', FormBox.Description, 'Custom financial descriptions must survive.');
        Definition.Get('2026', 'NEC', 'NEC-01B');
        Assert.AreEqual('Custom tips label', Definition.Description, 'Compatible supplemental labels must survive.');
        Definition.Get('2026', 'NEC', 'NEC-01D');
        Assert.AreEqual('CUSTOM', Definition."XML Element Name", 'Conflicts must not be silently repaired.');
        Assert.IsTrue(Details.Contains('custom minimum'), 'Identify the custom threshold.');
        Assert.IsTrue(Details.Contains('NEC-01D'), 'Identify the incompatible supplemental definition.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure AnnualUpdateDoesNotRepurposeHistoricalMisc14()
    var
        Definition: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The old financial MISC-14 migration is never applied to a 2025-to-2026 update.
        Initialize();

        // [GIVEN] A target retains a historical financial identifier with an old meaning.
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'MISC', 130000);
        StatementLine.Delete(true);
        Definition.Get('2026', 'MISC', 'MISC-14');
        Definition.Delete(true);
        FormBox."Period No." := '2026';
        FormBox."Form No." := 'MISC';
        FormBox."No." := 'MISC-14';
        FormBox.Description := 'Historical parachute payments';
        FormBox.Insert(true);

        // [WHEN] The real consecutive-year update and reconciliation are repeated.
        LibraryIRSReportingPeriod.UpdateDataForNewTaxYear('2025', '2026');
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] Financial history is not reused as supplemental overtime or moved to NEC.
        FormBox.Get('2026', 'MISC', 'MISC-14');
        Assert.AreEqual('Historical parachute payments', FormBox.Description, 'Never reinterpret old financial identifiers.');
        Assert.IsFalse(Definition.Get('2026', 'MISC', 'MISC-14'), 'An identifier conflict requires explicit resolution.');
        Assert.IsTrue(Details.Contains('is already used by a form box'), 'Identify the conflict instead of failing setup or silently repurposing it.');
        VerifyMinimum('2026', 'NEC', 'NEC-03', 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFinancialParentDeletionIsBlocked()
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A financial parent cannot be deleted while supplemental setup references it.
        Initialize();

        // [GIVEN] Six supported definitions reference the financial parents.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'NEC', 'NEC-01');

        // [WHEN] The parent is deleted.
        asserterror FormBox.Delete(true);

        // [THEN] The dependent definition is identified.
        Assert.ExpectedError('parent of supplemental box NEC-01B');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFinancialParentRenameIsBlocked()
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A financial parent cannot be renamed while supplemental setup references it.
        Initialize();

        // [GIVEN] MISC other income is the parent of the tips definition.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'MISC', 'MISC-03');

        // [WHEN] The parent is renamed.
        asserterror FormBox.Rename('2026', 'MISC', 'RENAMED');

        // [THEN] The reverse-reference guard identifies the dependent setup.
        Assert.ExpectedError('parent of supplemental box MISC-13A');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFormAndPeriodCleanupRemovesContainedSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Allowed deletion removes statements before definitions and financial parents without orphans.
        Initialize();

        // [GIVEN] A period contains financial and supplemental setup, but no documents.
        CreateAnnualSetup(2026);

        // [WHEN] NEC setup is deleted.
        Form.Get('2026', 'NEC');
        Form.Delete(true);

        // [THEN] MISC remains and no NEC dependencies remain.
        Definition.SetRange("Period No.", '2026');
        Definition.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(Definition);
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(StatementLine);
        FormBox.SetRange("Period No.", '2026');
        FormBox.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(FormBox);
        Definition.SetRange("Form No.", 'MISC');
        Assert.RecordCount(Definition, 3);

        // [WHEN] The remaining period is deleted.
        ReportingPeriod.Get('2026');
        ReportingPeriod.Delete(true);

        // [THEN] Its contained setup is removed too.
        Assert.RecordIsEmpty(Definition);
        StatementLine.SetRange("Form No.");
        Assert.RecordIsEmpty(StatementLine);
        FormBox.SetRange("Form No.");
        Assert.RecordIsEmpty(FormBox);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualReconciliationOnlyIdentifiesAffectedOpenDocuments()
    var
        OpenDocHeader: Record "IRS 1099 Form Doc. Header";
        SubmittedDocHeader: Record "IRS 1099 Form Doc. Header";
        CurrentDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherPeriodDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        DocLine: Record "IRS 1099 Form Doc. Line";
        TransmissionLog: Record "Transmission Log IRIS";
        OriginalDocHeader: Record "IRS 1099 Form Doc. Header";
        OriginalSupplLine: Record "IRS 1099 Doc. Suppl. Line";
        OriginalLog: Record "Transmission Log IRIS";
        ContentOutStream: OutStream;
        ContentInStream: InStream;
        Content: Text;
        Details: Text;
        OpenDocumentTok: Label 'document %1 with status Open ', Locked = true, Comment = '%1 = document ID';
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Setup identifies only stale Open documents and preserves saved snapshots and payload history.
        Initialize();

        // [GIVEN] Stale Open/submitted documents, a current Open document and another period.
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);
        CreateStoredDocument(OpenDocHeader, '2026', OpenDocHeader.Status::Open, 600);
        CreateStoredDocument(SubmittedDocHeader, '2026', SubmittedDocHeader.Status::Submitted, 600);
        CreateStoredDocument(CurrentDocHeader, '2026', CurrentDocHeader.Status::Open, 2000);
        CreateStoredDocument(OtherPeriodDocHeader, '2025', OtherPeriodDocHeader.Status::Open, 600);
        SupplLine."Document ID" := OpenDocHeader.ID;
        SupplLine.Validate("Supplemental Box No.", 'NEC-01B');
        SupplLine.Validate(Amount, 100);
        SupplLine.Insert(true);
        TransmissionLog."Period No." := '2026';
        TransmissionLog."Receipt ID" := 'HISTORICAL';
        TransmissionLog."Transmission Content".CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('<historical>unchanged</historical>');
        TransmissionLog.Insert();
        OriginalDocHeader := SubmittedDocHeader;
        OriginalSupplLine := SupplLine;
        OriginalLog := TransmissionLog;

        // [WHEN] Annual setup is reconciled twice.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] Only the stale Open identity is reported; stored data is not recalculated.
        Assert.IsTrue(Details.Contains(StrSubstNo(OpenDocumentTok, OpenDocHeader.ID)), 'Identify the affected Open document.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, SubmittedDocHeader.ID)), 'Submitted documents must not be offered.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, CurrentDocHeader.ID)), 'Current Open documents need no notice.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, OtherPeriodDocHeader.ID)), 'Another period must not be offered.');
        DocLine.SetRange("Document ID", OpenDocHeader.ID);
        DocLine.FindFirst();
        Assert.AreEqual(600, DocLine."Minimum Reportable Amount", 'Setup must not rewrite a financial snapshot.');
        Assert.IsTrue(DocLine."Include In 1099", 'Stored inclusion changes only after explicit recalculation.');
        SubmittedDocHeader.Get(SubmittedDocHeader.ID);
        Assert.AreEqual(OriginalDocHeader.SystemModifiedAt, SubmittedDocHeader.SystemModifiedAt, 'Submitted data changed.');
        SupplLine.Get(OpenDocHeader.ID, 'NEC-01B');
        Assert.AreEqual(OriginalSupplLine.SystemModifiedAt, SupplLine.SystemModifiedAt, 'Saved disclosures changed.');
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'Saved parent snapshots must not be retargeted.');
        TransmissionLog.Get(OriginalLog."Line ID");
        Assert.AreEqual(OriginalLog.SystemModifiedAt, TransmissionLog.SystemModifiedAt, 'Historical transmission changed.');
        TransmissionLog.CalcFields("Transmission Content");
        TransmissionLog."Transmission Content".CreateInStream(ContentInStream);
        ContentInStream.ReadText(Content);
        Assert.AreEqual('<historical>unchanged</historical>', Content, 'Stored XML must remain unchanged.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInUseDefinitionConflictPreservesSnapshot()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        Definition: Record "IRS 1099 Suppl. Box";
        SupplLine: Record "IRS 1099 Doc. Suppl. Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Annual setup never repairs a structural conflict by retargeting a saved parent.
        Initialize();

        // [GIVEN] A saved supplemental line and an incompatible imported definition.
        CreateAnnualSetup(2026);
        CreateStoredDocument(DocHeader, '2026', DocHeader.Status::Open, 600);
        SupplLine."Document ID" := DocHeader.ID;
        SupplLine.Validate("Supplemental Box No.", 'NEC-01B');
        SupplLine.Validate(Amount, 100);
        SupplLine.Insert(true);
        Definition.Get('2026', 'NEC', 'NEC-01B');
        Definition."Parent Form Box No." := 'NEC-03';
        Definition.Modify();

        // [WHEN] Setup is reconciled.
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] The conflict is explicit and neither the definition nor snapshot is silently reinterpreted.
        Assert.IsTrue(Details.Contains('NEC-01B'), 'Identify the structural conflict for explicit resolution.');
        Definition.Get('2026', 'NEC', 'NEC-01B');
        Assert.AreEqual('NEC-03', Definition."Parent Form Box No.", 'Annual setup must not silently repair in-use structure.');
        SupplLine.Get(DocHeader.ID, 'NEC-01B');
        Assert.AreEqual('NEC-01', SupplLine."Parent Form Box No.", 'Annual setup must preserve the saved parent.');
        Assert.AreEqual(100, SupplLine.Amount, 'Annual setup must preserve saved values.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualPeriodDeletionChecksDocumentsBeforeCleanup()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Period deletion checks all document use before removing any setup.
        Initialize();

        // [GIVEN] The period contains a submitted document.
        CreateAnnualSetup(2026);
        CreateStoredDocument(DocHeader, '2026', DocHeader.Status::Submitted, 600);
        ReportingPeriod.Get('2026');

        // [WHEN] Period deletion is attempted.
        asserterror ReportingPeriod.Delete(true);

        // [THEN] A document-use error precedes dependency cleanup.
        Assert.ExpectedError('used by 1099 form documents');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure AnnualReconciliationIsCompanyScoped()
    var
        OtherCompany: Record Company;
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        OtherMinimum: Decimal;
        DefinitionCount: Integer;
        StatementCount: Integer;
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Definitions validate against the target company's period and parents, not ambient company data.
        Initialize();

        // [GIVEN] A disposable company contains a target period absent from the current company.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 777;
        FormBox.Modify();
        OtherCompany.Name := CopyStr('IRS Annual ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        ReportingPeriod.ChangeCompany(OtherCompany.Name);
        ReportingPeriod."No." := 'OTHER2026';
        ReportingPeriod."Starting Date" := 20260101D;
        ReportingPeriod."Ending Date" := 20261231D;
        ReportingPeriod.Insert();

        // [WHEN] That company's target setup is reconciled twice.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('OTHER2026', OtherCompany.Name);
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('OTHER2026', OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        FormBox.Get('OTHER2026', 'NEC', 'NEC-01');
        OtherMinimum := FormBox."Minimum Reportable Amount";
        Definition.ChangeCompany(OtherCompany.Name);
        Definition.SetRange("Period No.", 'OTHER2026');
        DefinitionCount := Definition.Count();
        StatementLine.ChangeCompany(OtherCompany.Name);
        StatementLine.SetRange("Period No.", 'OTHER2026');
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        StatementCount := StatementLine.Count();
        Commit();
        OtherCompany.Delete(true);

        // [THEN] The company-scoped setup converges without touching the current company.
        Assert.AreEqual(2000, OtherMinimum, 'Target-company defaults must be reconciled.');
        Assert.AreEqual(6, DefinitionCount, 'Target-company definitions must be complete and unique.');
        Assert.AreEqual(6, StatementCount, 'Supplemental selectors must belong only to the target company and period.');
        Assert.AreEqual('', Details, 'A repeated standard reconciliation must have no conflicts.');
        VerifyMinimum('2026', 'NEC', 'NEC-01', 777);
        ReportingPeriod.ChangeCompany(CompanyName());
        ReportingPeriod.Get('2026');
        ReportingPeriod.Delete(true);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorBlocksDefinitionDeletion()
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Active statement selectors protect definitions even without document values.
        Initialize();

        // [GIVEN] Definition B is selected by a standard statement row.
        CreateAnnualSetup(2026);
        Definition.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] Definition B is deleted.
        asserterror Definition.Delete(true);

        // [THEN] The dependent row is identified.
        Assert.ExpectedError('used by statement row NEC-01B');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorBlocksDefinitionRename()
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Renaming a definition cannot orphan an active selector.
        Initialize();

        // [GIVEN] Definition B is selected by a standard statement row.
        CreateAnnualSetup(2026);
        Definition.Get('2026', 'NEC', 'NEC-01C');

        // [WHEN] Definition B is renamed.
        asserterror Definition.Rename('2026', 'NEC', 'RENAMED');

        // [THEN] The dependent row is identified.
        Assert.ExpectedError('used by statement row NEC-01C');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorBlocksStructuralDefinitionEdit()
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A structurally incompatible edit identifies the dependent statement before breaking its reference.
        Initialize();

        // [GIVEN] Definition B is selected by a standard statement row.
        CreateAnnualSetup(2026);
        Definition.Get('2026', 'NEC', 'NEC-01D');
        Definition."Parent Form Box No." := 'NEC-03';

        // [WHEN] Its stored parent is changed through a direct AL modify.
        asserterror Definition.Modify(true);

        // [THEN] The reference guard protects the dependent statement.
        Assert.ExpectedError('used by statement row NEC-01D');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInactiveStatementSelectorDoesNotReferenceDefinition()
    var
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A financial row retains its filters and does not activate a stale supplemental selector.
        Initialize();

        // [GIVEN] Row S uses financial filters rather than its inactive supplemental selector.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine.Validate("Value Source", StatementLine."Value Source"::"Document Line");
        StatementLine.SetFormBoxFilter('NEC-01');
        StatementLine.Modify(true);
        Definition.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] The otherwise unused supplemental definition is deleted.
        Definition.Delete(true);

        // [THEN] Financial configuration is retained without an active reverse reference.
        Assert.IsFalse(Definition.Get('2026', 'NEC', 'NEC-01B'), 'Only active supplemental selectors are reverse references.');
        StatementLine.Get('2026', 'NEC', 12500);
        Assert.AreEqual('NEC-01B', StatementLine."Supplemental Box No.", 'Changing source must not silently erase the saved configuration.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementReconciliationPreservesCustomSelectorsAndOrder()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeat annual updates insert absent rows without retargeting custom sources, boxes, labels or order.
        Initialize();

        // [GIVEN] Rows S have custom source, selector, description and ordering; one default is absent.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine.Validate("Supplemental Box No.", 'NEC-01D');
        StatementLine.Modify(true);
        StatementLine.Get('2026', 'NEC', 17500);
        StatementLine."Value Source" := StatementLine."Value Source"::"Document Line";
        StatementLine.SetFormBoxFilter('NEC-01');
        StatementLine.Modify(true);
        StatementLine.Get('2026', 'NEC', 15000);
        StatementLine.Description := 'My occupations';
        StatementLine.Modify(true);
        StatementLine.Rename('2026', 'NEC', 5000);
        StatementLine.Get('2026', 'MISC', 125000);
        StatementLine.Delete(true);

        // [WHEN] Annual reconciliation is repeated.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] Custom values are preserved and reported, and absent defaults are inserted only once.
        StatementLine.Get('2026', 'NEC', 12500);
        Assert.AreEqual('NEC-01D', StatementLine."Supplemental Box No.", 'Never retarget a custom box selector.');
        StatementLine.Get('2026', 'NEC', 17500);
        Assert.AreEqual(StatementLine."Value Source"::"Document Line", StatementLine."Value Source", 'Never change a custom source.');
        StatementLine.Get('2026', 'NEC', 5000);
        Assert.AreEqual('My occupations', StatementLine.Description, 'Preserve both custom label and position.');
        Assert.IsFalse(StatementLine.Get('2026', 'NEC', 15000), 'Do not duplicate a moved row at the supplied position.');
        StatementLine.Get('2026', 'MISC', 125000);
        Assert.AreEqual(StatementLine."Value Source"::"Supplemental Line", StatementLine."Value Source", 'Insert absent standard supplemental sources.');
        Assert.IsTrue(Details.Contains('statement row NEC-01B'), 'Report custom selectors.');
        Assert.IsTrue(Details.Contains('statement row NEC-01C'), 'Report custom description/order.');
        Assert.IsTrue(Details.Contains('statement row NEC-01D'), 'Report custom sources.');
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetFilter("Row No.", 'NEC-01B|NEC-01C|NEC-01D|MISC-13A|MISC-13B|MISC-14');
        Assert.RecordCount(StatementLine, 6);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementReconciliationPreservesOccupiedDefaultPosition()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A customer row at a supplied insertion point is never replaced.
        Initialize();

        // [GIVEN] Row S occupies a standard insertion point with custom content.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine."Row No." := 'CUSTOM';
        StatementLine.Description := 'My row';
        StatementLine.Modify(true);

        // [WHEN] Annual reconciliation is requested.
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] The customer row is preserved and its conflict reported.
        StatementLine.Get('2026', 'NEC', 12500);
        Assert.AreEqual('CUSTOM', StatementLine."Row No.", 'Do not replace an occupied standard position.');
        Assert.AreEqual('My row', StatementLine.Description, 'Preserve customer content.');
        Assert.IsTrue(Details.Contains('statement row NEC-01B'), 'Report the blocked default insertion.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorIsScopedToPeriodAndForm()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A selector cannot borrow a definition from another form in the same year.
        Initialize();

        // [GIVEN] Row S belongs to NEC.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);

        // [WHEN] A MISC supplemental definition is selected.
        asserterror StatementLine.Validate("Supplemental Box No.", 'MISC-13A');

        // [THEN] The filtered relation rejects the cross-form selector.
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    trigger OnRun()
    begin
        // [FEATURE] [1099]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInstructionsRepairRecognizedEarlierStandards()
    var
        Instruction: Record "IRS 1099 Form Instruction";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Explicit updates repair recognized stale 2025 instructions without touching earlier years.
        Initialize();

        // [GIVEN] Period P has the released stale instructions, while historical period H has the same text.
        CreateAnnualSetup(2025);
        SetInstruction('2025', 'NEC', 7, 'Box 3.', 'Reserved for future use.');
        SetInstruction('2025', 'MISC', 18, 'Box 14.', 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.');
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('HISTORY2024', 20240101D, 20241231D);
        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(20240101D, 20241231D, 'NEC');
        Instruction.Get('2025', 'NEC', 7);
        Instruction."Period No." := 'HISTORY2024';
        Instruction.Insert();

        // [WHEN] Both periods are explicitly reconciled, with the current one repeated.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('2025', CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2025', CompanyName());
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('HISTORY2024', CompanyName());

        // [THEN] The supported year converges without conflicts or duplicates and historical text remains.
        VerifyYearInstructions('2025', false);
        Assert.AreEqual('', Details, 'Already-current instructions do not require a resolution.');
        Instruction.Get('HISTORY2024', 'NEC', 7);
        Assert.AreEqual('Reserved for future use.', Instruction.Description, 'Historical instructions are not rewritten.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInstructionsPreserveCustomTextAndOrdering()
    var
        Instruction: Record "IRS 1099 Form Instruction";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Annual instructions preserve custom text and moved rows while restoring absent defaults.
        Initialize();

        // [GIVEN] Period P has customized and moved instructions and a missing standard instruction.
        CreateAnnualSetup(2026);
        SetInstruction('2026', 'NEC', 7, 'Box 3.', 'Custom parachute guidance');
        SetInstruction('2026', 'MISC', 17, 'My FATCA guidance', 'Custom account reporting');
        Instruction.Get('2026', 'NEC', 12);
        Instruction.Delete();
        Instruction."Line No." := 1200;
        Instruction.Insert();
        Instruction.Get('2026', 'MISC', 23);
        Instruction.Delete();

        // [WHEN] The annual update is repeated.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup('2026', CompanyName());

        // [THEN] Customizations and ordering survive, missing defaults return and conflicts are actionable.
        Instruction.Get('2026', 'NEC', 7);
        Assert.AreEqual('Custom parachute guidance', Instruction.Description, 'Custom text must survive.');
        Instruction.Get('2026', 'MISC', 17);
        Assert.AreEqual('My FATCA guidance', Instruction.Header, 'Custom headers must survive.');
        Instruction.Get('2026', 'NEC', 1200);
        Assert.AreEqual('Box 1b.', Instruction.Header, 'Moved instructions must survive.');
        Assert.IsFalse(Instruction.Get('2026', 'NEC', 12), 'Do not duplicate a moved instruction.');
        Instruction.Get('2026', 'MISC', 23);
        Assert.AreEqual('Box 13a.', Instruction.Header, 'Insert missing defaults.');
        Assert.IsTrue(Details.Contains('instruction line 7'), 'Identify custom NEC guidance.');
        Assert.IsTrue(Details.Contains('instruction line 17'), 'Identify custom FATCA guidance.');
        Assert.IsTrue(Details.Contains('instruction line 12'), 'Identify moved guidance.');
        Instruction.SetRange("Period No.", '2026');
        Instruction.SetRange("Form No.", 'NEC');
        Assert.RecordCount(Instruction, 14);
    end;

    [Test]
    procedure HiddenSchemaOverrideCannotBeEditedThroughTestPage()
    var
        ReportingPeriods: TestPage "IRS Reporting Periods";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] TestPage omits the hidden control and cannot substitute for client personalization.
        Initialize();

        // [GIVEN] The current BC environment is a sandbox.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);

        // [WHEN] The actual page is opened without personalization.
        ReportingPeriods.OpenEdit();

        // [THEN] An attempted control edit is rejected because the hidden field is not exposed.
        asserterror ReportingPeriods.IRISXmlSchemaVersion.SetValue("XML Schema Version IRIS"::"5.0.7");
        Assert.ExpectedError('is not found on the page');
        ReportingPeriods.Close();

        // [WHEN] The same page is opened in production.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        ReportingPeriods.OpenEdit();

        // [THEN] Its hidden production control is similarly unavailable to TestPage.
        asserterror ReportingPeriods.IRISXmlSchemaVersion.SetValue("XML Schema Version IRIS"::"5.0.7");
        Assert.ExpectedError('is not found on the page');
        ReportingPeriods.Close();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupReadPermissionsOpenSandboxPeriods()
    var
        ReportingPeriods: TestPage "IRS Reporting Periods";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Read opens and evaluates the sandbox page even though its schema control is hidden.
        Initialize();

        // [GIVEN] A sandbox period with a hidden schema override.
        PrepareReadPermissionFixture(true, true);

        // [WHEN] The page evaluates its period using only normal Read permissions.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] The period is readable without a configuration execute-permission failure.
        ReportingPeriods."No.".AssertEquals('2099');
        ReportingPeriods.Close();
        RestorePermissionEnvironment();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupReadPermissionsOpenProductionPeriods()
    var
        ReportingPeriods: TestPage "IRS Reporting Periods";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Read opens the production page without making the schema override visible.
        Initialize();

        // [GIVEN] A production period with a hidden schema override.
        PrepareReadPermissionFixture(true, false);

        // [WHEN] The page evaluates its period using only normal Read permissions.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] Production evaluation needs no blanket execute grant.
        ReportingPeriods."No.".AssertEquals('2099');
        ReportingPeriods.Close();
        RestorePermissionEnvironment();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupReadPermissionsOpenOnPremPeriods()
    var
        ReportingPeriods: TestPage "IRS Reporting Periods";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Normal Read page evaluation also works in OnPrem without changing environment guards.
        Initialize();

        // [GIVEN] An OnPrem period with a hidden schema override.
        PrepareReadPermissionFixture(false, false);

        // [WHEN] The page evaluates its period using only normal Read permissions.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] No SaaS mock is required to authorize the configuration codeunit.
        ReportingPeriods."No.".AssertEquals('2099');
        ReportingPeriods.Close();
        RestorePermissionEnvironment();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupEditPermissionsAllowSchemaOverrideWrites()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        CanWrite: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Normal IRS setup-edit permissions allow validated override writes for an unverified year.
        Initialize();

        // [GIVEN] An unverified period is edited with only the normal IRS edit permission set.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Edit');
        ReportingPeriod.Get('2099');
        CanWrite := ReportingPeriod.WritePermission();

        // [WHEN] Both stored environment selections are validated and saved.
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify(true);
        ReportingPeriod.Get('2099');
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);

        // [THEN] The values are saved without requiring a verified filing year.
        Assert.IsTrue(CanWrite, 'The normal edit permission set must permit setup writes.');
        Assert.AreEqual("XML Schema Version IRIS"::"5.0.7", ReportingPeriod."IRIS XML Schema Version Test", 'TEST override is saved.');
        Assert.AreEqual("XML Schema Version IRIS"::"2.0.3", ReportingPeriod."IRIS XML Schema Version Live", 'Production override is saved independently.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupReadPermissionsRejectSchemaOverrideWrite()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        CanWrite: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Hiding the override is not security; the normal read permission set rejects a write.
        Initialize();

        // [GIVEN] A period is read with only the normal IRS read permission set.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Read');
        ReportingPeriod.Get('2099');
        CanWrite := ReportingPeriod.WritePermission();
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");

        // [WHEN] A direct write attempts to bypass the hidden control.
        asserterror ReportingPeriod.Modify(true);

        // [THEN] Platform authorization rejects the write and rolls back the uncommitted fixture.
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        Assert.ExpectedError('permission');
        Assert.ExpectedErrorCode('DB:ClientModifyDenied');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        Assert.IsFalse(CanWrite, 'The normal read permission set must not grant setup writes.');
        Assert.IsFalse(ReportingPeriod.Get('2099'), 'The rejected operation must not persist an override or its uncommitted fixture.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinancialInsertRejectsSupplementalIdentity()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Financial insertion cannot turn an existing supplemental definition into a posting destination.
        Initialize();

        // [GIVEN] A committed owned period P has supplemental box NEC-01B.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        Commit();
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'NEC-01B');

        // [WHEN] A form box is inserted at that identity.
        asserterror FinancialFormBox.Insert(true);

        // [THEN] The collision is rejected and the existing definition remains unchanged.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFinancialIdentity(PeriodNo, CompanyName());
        DeleteIdentityPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SupplementalInsertRejectsFinancialIdentity()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The existing supplemental-to-financial rejection remains effective.
        Initialize();

        // [GIVEN] A committed owned period P has a custom form box.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'CUSTOM');
        FinancialFormBox.Description := 'Financial meaning';
        FinancialFormBox.Insert(true);
        Commit();
        Definition."Period No." := PeriodNo;
        Definition."Form No." := 'NEC';
        Definition."No." := 'CUSTOM';
        Definition."Parent Form Box No." := 'NEC-01';

        // [WHEN] A supplemental definition is inserted with the same identity.
        asserterror Definition.Insert(true);

        // [THEN] The original financial meaning survives without a supplemental replacement.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedSupplementalIdentity(PeriodNo);
        DeleteIdentityPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinancialRenameChecksAllDestinationKeys()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Changing any financial key component must validate the complete rename destination.
        Initialize();

        // [GIVEN] Three unused form boxes have distinct keys outside a supplemental identity.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        OtherPeriodNo := CreateIdentityPeriod(CompanyName());
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'CUSTOM');
        FinancialFormBox.Insert(true);
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'MISC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        PrepareFinancialBox(FinancialFormBox, OtherPeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        Commit();

        // [WHEN] Only the box number changes into the occupied supplemental identity.
        FinancialFormBox.Get(PeriodNo, 'NEC', 'CUSTOM');
        asserterror FinancialFormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] The box-number destination is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Only the form changes into the occupied supplemental identity.
        FinancialFormBox.Get(PeriodNo, 'MISC', 'NEC-01B');
        asserterror FinancialFormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] The form destination is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Only the period changes into the occupied supplemental identity.
        FinancialFormBox.Get(OtherPeriodNo, 'NEC', 'NEC-01B');
        asserterror FinancialFormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] All source keys and the supplemental definition remain intact.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFinancialRenames(PeriodNo, OtherPeriodNo);
        DeleteIdentityPeriod(PeriodNo);
        DeleteIdentityPeriod(OtherPeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure FinancialCopyReportsSupplementalCollision()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Triggerless financial setup copy reports and skips a target supplemental collision.
        Initialize();

        // [GIVEN] Source P1 has a form box and target P2 uses that identity for a supplemental box.
        FromPeriodNo := CreateIdentityPeriod(CompanyName());
        ToPeriodNo := CreateIdentityPeriod(CompanyName());
        PrepareFinancialBox(FinancialFormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Description := 'Source financial meaning';
        FinancialFormBox.Insert(true);
        CreateIdentityDefinition(ToPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());

        // [WHEN] The supported copy path bypasses financial table insert triggers.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] No collision is inserted, the source is unchanged, and the summary names the rejected target.
        VerifyRejectedFinancialIdentity(ToPeriodNo, CompanyName());
        VerifyFinancialCopyConflict(FromPeriodNo, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinancialIdentityScopesAllowValidDestinations()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        JournalLine: Record "Gen. Journal Line";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Identical numbers in another form or period remain valid financial posting destinations.
        Initialize();

        // [GIVEN] P1 has supplemental NEC-01B while P2 and form MISC do not.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        OtherPeriodNo := CreateIdentityPeriod(CompanyName());
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'MISC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        PrepareFinancialBox(FinancialFormBox, OtherPeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Vendor and journal setup select valid same-number financial destinations.
        VendorSetup.Validate("Period No.", PeriodNo);
        VendorSetup.Validate("Vendor No.", Vendor."No.");
        VendorSetup.Validate("Form No.", 'MISC');
        VendorSetup.Validate("Form Box No.", 'NEC-01B');
        VendorSetup.Insert(true);
        JournalLine.Validate("IRS 1099 Reporting Period", OtherPeriodNo);
        JournalLine.Validate("IRS 1099 Form No.", 'NEC');
        JournalLine.Validate("IRS 1099 Form Box No.", 'NEC-01B');

        // [THEN] Financial lookup relations remain scoped to their own period and form.
        VerifyValidFinancialDestinations(VendorSetup, JournalLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FinancialIdentityGuardUsesChangedCompany()
    var
        OtherCompany: Record Company;
        FinancialFormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Changed-company insertion uses target definitions, never ambient-company definitions.
        Initialize();

        // [GIVEN] Owned company B has a collision absent from A and a free identity occupied only in A.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        OtherCompany.Name := CopyStr('IRS Identity ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateIdentityPeriodInCompany(PeriodNo, OtherCompany.Name);
        OtherPeriodNo := CreateIdentityPeriod(OtherCompany.Name);
        CreateIdentityDefinition(OtherPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', OtherCompany.Name);
        FinancialFormBox.ChangeCompany(OtherCompany.Name);
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        Commit();
        PrepareFinancialBox(FinancialFormBox, OtherPeriodNo, 'NEC', 'NEC-01B');

        // [WHEN] A triggered insert targets B's supplemental definition.
        asserterror FinancialFormBox.Insert(true);

        // [THEN] B's collision is rejected, whereas A's matching identifier did not block the earlier B insert.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFinancialIdentity(OtherPeriodNo, OtherCompany.Name);
        Assert.IsTrue(FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'Another company must not reserve this financial number.');
        OtherCompany.Delete(true);
        DeleteIdentityPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinancialReconciliationPreservesHistoricalConflicts()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Annual reconciliation reports historical conflicts without deleting or repurposing either record.
        Initialize();

        // [GIVEN] An owned period has a historical conflict created without insert triggers.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Description := 'Historical financial meaning';
        FinancialFormBox."Minimum Reportable Amount" := 777;
        FinancialFormBox.Insert();

        // [WHEN] Annual reconciliation is repeated.
        LibraryIRSReportingPeriod.ReconcileAnnualSetup(PeriodNo, CompanyName());
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup(PeriodNo, CompanyName());

        // [THEN] Both identities and their meaning are preserved with an explicit scoped conflict.
        FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01B');
        Definition.Get(PeriodNo, 'NEC', 'NEC-01B');
        VerifyHistoricalFinancialConflict(FinancialFormBox, Definition, Details);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinancialReconciliationReportsParentIdentityCollision()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reconciliation cannot recreate a financial parent over an existing custom supplemental identity.
        Initialize();

        // [GIVEN] Custom supplemental NEC-01 uses an existing alternative financial parent.
        PeriodNo := CreateIdentityPeriod(CompanyName());
        FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FinancialFormBox.Delete(true);
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'CUSTOM');
        FinancialFormBox.Insert(true);
        CreateIdentityDefinition(PeriodNo, 'NEC', 'NEC-01', 'CUSTOM', '', CompanyName());

        // [WHEN] Standard annual financial reconciliation attempts to supply NEC-01.
        Details := LibraryIRSReportingPeriod.ReconcileAnnualSetup(PeriodNo, CompanyName());

        // [THEN] The custom definition is preserved and the financial parent is explicitly reported, not inserted.
        Assert.IsFalse(FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01'), 'Reconciliation must not create a financial/supplemental collision.');
        Definition.Get(PeriodNo, 'NEC', 'NEC-01');
        Assert.AreEqual('CUSTOM', Definition."Parent Form Box No.", 'Custom supplemental meaning must survive.');
        VerifyFinancialConflictDetails(Details, PeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyOmitsUnsupportedSupplementalSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        TargetPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A copy to an earlier year retains financial statements without unsupported supplemental dependencies.
        Initialize();

        // [GIVEN] Source S has complete 2026 setup and target T is in 2025.
        CreateAnnualSetup(2026);
        TargetPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(TargetPeriodNo);
        ReportingPeriod."Starting Date" := 20250101D;
        ReportingPeriod."Ending Date" := 20251231D;
        ReportingPeriod.Modify();

        // [WHEN] Setup is copied twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);

        // [THEN] Financial setup survives, supplemental setup is omitted and its target-year reason is explicit.
        VerifyUnsupportedSetupCopy(TargetPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyPreservesFutureSupplementalSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        TargetPeriodNo: Code[20];
    begin
        // [SCENARIO] Copying to a future year retains valid supplemental definitions and statement selectors.
        Initialize();
        CreateAnnualSetup(2026);
        TargetPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(TargetPeriodNo);
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();

        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);

        Definition.SetRange("Period No.", TargetPeriodNo);
        Assert.RecordCount(Definition, 6);
        VerifyStandardDefinitions(TargetPeriodNo);
        StatementLine.SetRange("Period No.", TargetPeriodNo);
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordCount(StatementLine, 6);
        VerifyYearInstructions(TargetPeriodNo, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyCreatesCustomDependenciesBeforeSelectors()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Custom typed definitions and their selectors precede statement defaults and converge without losing labels.
        Initialize();

        // [GIVEN] S has custom amount and code definitions, a custom parent and selectors at standard default positions.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        PrepareFinancialBox(FinancialFormBox, FromPeriodNo, 'NEC', 'CUSTOM-PARENT');
        FinancialFormBox.Description := 'Source custom financial parent';
        FinancialFormBox.Insert(true);
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'CUSTOM-AMOUNT', 'CUSTOM-PARENT', '', CompanyName());
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'CUSTOM-CODES', 'NEC-01', '', CompanyName());
        Definition.Get(FromPeriodNo, 'NEC', 'CUSTOM-CODES');
        Definition."Value Type" := Definition."Value Type"::"Occupation Codes";
        Definition.Modify(true);
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM-AMOUNT', 12500);
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM-CODES', 15000);

        // [WHEN] Copy is repeated within supported 2026 periods.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Both typed dependencies are valid and source labels and ordering win over unseeded statement defaults.
        VerifyCustomSetupCopy(FromPeriodNo, ToPeriodNo, CompanyName());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyRejectsMissingSourceDefinition()
    var
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A historical dangling source selector is reported rather than introduced into the target.
        Initialize();

        // [GIVEN] S contains an intentionally malformed selector without a definition.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(FromPeriodNo, 'MISSING', 31000);

        // [WHEN] Its setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T contains no new dangling selector and S remains available for explicit repair.
        VerifyRejectedSetupSelector(FromPeriodNo, ToPeriodNo, 'MISSING', 31000, 'does not exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyRejectsUnsupportedSourceMapping()
    var
        Definition: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An unsupported custom source mapping is not accepted by triggerless setup copying.
        Initialize();

        // [GIVEN] S has a custom definition with an unsupported XML mapping and its selector.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'UNSUPPORTED-MAP', 'NEC-01', 'UnsupportedElement', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'UNSUPPORTED-MAP', 31000);

        // [WHEN] Its setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Neither unsupported dependency is introduced and the source mapping remains unchanged.
        VerifyRejectedSetupSelector(FromPeriodNo, ToPeriodNo, 'UNSUPPORTED-MAP', 31000, 'XML element does not meet the reporting requirements');
        Assert.IsFalse(Definition.Get(ToPeriodNo, 'NEC', 'UNSUPPORTED-MAP'), 'Do not copy an unsupported source mapping.');
        Definition.Get(FromPeriodNo, 'NEC', 'UNSUPPORTED-MAP');
        Assert.AreEqual('UnsupportedElement', Definition."XML Element Name", 'Do not repair the source implicitly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyPreservesConflictingTargetDefinitions()
    var
        Definition: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Incompatible typed and malformed target definitions remain unchanged without acquiring source selectors.
        Initialize();

        // [GIVEN] S has valid custom definitions, while T has incompatible typed and historical unsupported mappings.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'MALFORMED', 'NEC-01', '', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM', 31000);
        CreateSetupCopySelector(FromPeriodNo, 'MALFORMED', 32000);
        CreateIdentityDefinition(ToPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        Definition.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        Definition."Value Type" := Definition."Value Type"::"Occupation Codes";
        Definition.Description := 'Target typed customization';
        Definition.Modify(true);
        CreateIdentityDefinition(ToPeriodNo, 'NEC', 'MALFORMED', 'NEC-01', 'HISTORICAL', CompanyName());
        CreateSetupCopySelector(ToPeriodNo, 'MALFORMED', 41000);

        // [WHEN] Setup copy is repeated.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Target choices and malformed historical rows survive, while no incompatible replacement is inserted.
        VerifyConflictingTargetSetupCopy(FromPeriodNo, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyReportsExistingMalformedTargetSelector()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Copy reports an existing dangling target selector without deleting or repairing historical setup.
        Initialize();

        // [GIVEN] T already contains a historical dangling selector unrelated to S's financial setup.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(ToPeriodNo, 'MISSING', 31000);

        // [WHEN] Ordinary financial setup is copied into T.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] The historical row stays unchanged and is explicitly reported for repair.
        StatementLine.Get(ToPeriodNo, 'NEC', 31000);
        Assert.AreEqual('MISSING', StatementLine."Supplemental Box No.", 'Do not delete or silently repair existing malformed target setup.');
        VerifySetupCopySummary(ToPeriodNo, 'MISSING', 'cannot be used for reporting in the target period and was not changed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyPreservesOccupiedStatementIdentity()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A target's customized statement identity is reported and never overwritten by a copied supplemental selector.
        Initialize();

        // [GIVEN] S has a valid supplemental selector at the position of T's customized financial statement.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM', 12500);
        StatementLine."Period No." := ToPeriodNo;
        StatementLine."Form No." := 'NEC';
        StatementLine."Line No." := 12500;
        StatementLine."Row No." := 'TARGET-ROW';
        StatementLine.Description := 'Target customized financial statement';
        StatementLine."Print with" := StatementLine."Print with"::"Opposite Sign";
        StatementLine."Row Totaling" := 'CUSTOM-TOTAL';
        StatementLine.SetFormBoxFilter('NEC-01');
        StatementLine.Insert(true);

        // [WHEN] S is copied into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Target description, selector, sign, total and ordering are unchanged and the conflict is scoped.
        VerifyOccupiedSetupStatement(StatementLine, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopySkipsRejectedFinancialDependents()
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Rejection of a financial identity also rejects its directly dependent vendor setup and adjustment.
        Initialize();

        // [GIVEN] S's form box has vendor setup and adjustment, while T reserves that identity as supplemental.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        PrepareFinancialBox(FinancialFormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FinancialFormBox.Insert(true);
        LibraryPurchase.CreateVendor(Vendor);
        VendorSetup."Period No." := FromPeriodNo;
        VendorSetup."Vendor No." := Vendor."No.";
        VendorSetup."Form No." := 'NEC';
        VendorSetup."Form Box No." := 'NEC-01B';
        VendorSetup.Insert(true);
        Adjustment."Period No." := FromPeriodNo;
        Adjustment."Vendor No." := Vendor."No.";
        Adjustment."Form No." := 'NEC';
        Adjustment."Form Box No." := 'NEC-01B';
        Adjustment.Amount := 1000;
        Adjustment.Insert(true);
        CreateIdentityDefinition(ToPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());

        // [WHEN] The financial parent is rejected during copy.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] No dangling dependent is copied and its reason is reported without changing the source amount.
        VerifyRejectedFinancialDependents(FromPeriodNo, ToPeriodNo, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('IdentityCopyMessageHandler')]
    procedure SetupCopyAcrossCompaniesUsesTargetScope()
    var
        OtherCompany: Record Company;
        TempSelectedCompany: Record Company temporary;
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
        DefinitionCount: Integer;
        StatementCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Cross-company repeated copy validates B's supported target independently of A's unsupported counterpart.
        Initialize();

        // [GIVEN] A has S in 2026 and T in 2025, while owned B has a supported 2026 T with a custom parent minimum.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(ToPeriodNo);
        ReportingPeriod."Starting Date" := 20250101D;
        ReportingPeriod."Ending Date" := 20251231D;
        ReportingPeriod.Modify();
        CreateIdentityDefinition(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM', 12500);
        OtherCompany.Name := CopyStr('IRS-ASTRA-COPY-' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateIdentityPeriodInCompany(ToPeriodNo, OtherCompany.Name);
        SetSetupCopyTargetMinimum(ToPeriodNo, OtherCompany.Name);
        CreateIdentityPeriodInCompany('UNRELATED', OtherCompany.Name);
        SetSetupCopyTargetMinimum('UNRELATED', OtherCompany.Name);
        TempSelectedCompany.Name := OtherCompany.Name;
        TempSelectedCompany.Insert();

        // [WHEN] A's source setup is copied to B twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);

        // [THEN] Only B receives one valid custom dependency and selector; source and session-company T remain unchanged.
        VerifyCrossCompanySetupCopy(FromPeriodNo, ToPeriodNo, OtherCompany.Name);
        Definition.ChangeCompany(OtherCompany.Name);
        Definition.SetRange("Period No.", ToPeriodNo);
        Definition.SetRange("No.", 'CUSTOM');
        DefinitionCount := Definition.Count();
        StatementLine.ChangeCompany(OtherCompany.Name);
        StatementLine.SetRange("Period No.", ToPeriodNo);
        StatementLine.SetRange("Supplemental Box No.", 'CUSTOM');
        StatementCount := StatementLine.Count();
        Commit();
        OtherCompany.Delete(true);
        DeleteIdentityPeriod(FromPeriodNo);
        DeleteIdentityPeriod(ToPeriodNo);
        Commit();
        Assert.AreEqual(1, DefinitionCount, 'Repeated cross-company copying must not duplicate definitions.');
        Assert.AreEqual(1, StatementCount, 'Repeated cross-company copying must not duplicate selectors.');
    end;

    local procedure Initialize()
    begin
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        AnnualFixturePrepared := false;
        Clear(IdentityCopySummary);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS Reporting Period Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");
    end;

    local procedure CreateSetupCopyPeriod() PeriodNo: Code[20]
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        PeriodNo := CreateIdentityPeriod(CompanyName());
        FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FinancialFormBox."Minimum Reportable Amount" := 2000;
        FinancialFormBox.Modify();
        FinancialFormBox.Get(PeriodNo, 'MISC', 'MISC-03');
        FinancialFormBox."Minimum Reportable Amount" := 2000;
        FinancialFormBox.Modify();
    end;

    local procedure CreateSetupCopySelector(PeriodNo: Code[20]; BoxNo: Code[20]; LineNo: Integer)
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        StatementLine."Period No." := PeriodNo;
        StatementLine."Form No." := 'NEC';
        StatementLine."Line No." := LineNo;
        StatementLine."Row No." := BoxNo;
        StatementLine.Description := 'Source customized ' + BoxNo;
        StatementLine."Value Source" := StatementLine."Value Source"::"Supplemental Line";
        StatementLine."Supplemental Box No." := BoxNo;
        StatementLine."Print with" := StatementLine."Print with"::"Opposite Sign";
        // Triggerless fixtures also model historical selectors with malformed dependencies.
        StatementLine.Insert();
    end;

    local procedure VerifyUnsupportedSetupCopy(TargetPeriodNo: Code[20])
    var
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        Definition.SetRange("Period No.", TargetPeriodNo);
        Assert.RecordIsEmpty(Definition);
        StatementLine.SetRange("Period No.", TargetPeriodNo);
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordIsEmpty(StatementLine);
        StatementLine.Reset();
        StatementLine.Get(TargetPeriodNo, 'NEC', 10000);
        Assert.AreEqual(StatementLine."Value Source"::"Document Line", StatementLine."Value Source", 'Ordinary NEC statements must remain financial.');
        StatementLine.Get(TargetPeriodNo, 'MISC', 10000);
        Assert.AreEqual(StatementLine."Value Source"::"Document Line", StatementLine."Value Source", 'Ordinary MISC statements must remain financial.');
        Assert.IsTrue(FinancialFormBox.Get(TargetPeriodNo, 'MISC', 'MISC-03'), 'Ordinary financial setup must still copy.');
        Definition.SetRange("Period No.", '2026');
        Assert.RecordCount(Definition, 6);
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordCount(StatementLine, 6);
        VerifySetupCopySummary(TargetPeriodNo, 'MISC-13A', 'Supplemental boxes are supported for tax years 2026 and later');
        Assert.IsTrue(IdentityCopySummary.Contains('2025'), 'The omission must identify the unsupported target year.');
    end;

    local procedure VerifyCustomSetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; TargetCompany: Text)
    var
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        Definition.ChangeCompany(TargetCompany);
        Definition.Get(ToPeriodNo, 'NEC', 'CUSTOM-AMOUNT');
        Assert.AreEqual('CUSTOM-PARENT', Definition."Parent Form Box No.", 'Copy the custom financial parent before its definition.');
        Assert.AreEqual(Definition."Value Type"::Amount, Definition."Value Type", 'Preserve the amount type.');
        Definition.Get(ToPeriodNo, 'NEC', 'CUSTOM-CODES');
        Assert.AreEqual(Definition."Value Type"::"Occupation Codes", Definition."Value Type", 'Preserve typed occupation-code definitions.');
        Assert.AreEqual('', Definition."XML Element Name", 'A valid custom definition must remain unmapped.');
        StatementLine.ChangeCompany(TargetCompany);
        StatementLine.Get(ToPeriodNo, 'NEC', 12500);
        Assert.AreEqual('Source customized CUSTOM-AMOUNT', StatementLine.Description, 'Default statement seeding must not steal the custom description.');
        Assert.AreEqual('CUSTOM-AMOUNT', StatementLine."Supplemental Box No.", 'Preserve the custom selector at its source identity.');
        Assert.AreEqual(StatementLine."Print with"::"Opposite Sign", StatementLine."Print with", 'Preserve custom formatting.');
        StatementLine.Get(ToPeriodNo, 'NEC', 15000);
        Assert.AreEqual('CUSTOM-CODES', StatementLine."Supplemental Box No.", 'Preserve the code selector.');
        StatementLine.SetRange("Period No.", ToPeriodNo);
        StatementLine.SetFilter("Supplemental Box No.", 'CUSTOM-AMOUNT|CUSTOM-CODES');
        Assert.RecordCount(StatementLine, 2);
        FinancialFormBox.ChangeCompany(TargetCompany);
        FinancialFormBox.Get(ToPeriodNo, 'NEC', 'CUSTOM-PARENT');
        Assert.AreEqual('Source custom financial parent', FinancialFormBox.Description, 'Copy the custom parent without repurposing it.');
        Definition.ChangeCompany(CompanyName());
        Definition.Get(FromPeriodNo, 'NEC', 'CUSTOM-AMOUNT');
        Assert.AreEqual('CUSTOM-PARENT', Definition."Parent Form Box No.", 'Do not retarget source definitions.');
        StatementLine.Reset();
        StatementLine.ChangeCompany(CompanyName());
        StatementLine.Get(FromPeriodNo, 'NEC', 12500);
        Assert.AreEqual('Source customized CUSTOM-AMOUNT', StatementLine.Description, 'Do not edit source statements.');
    end;

    local procedure VerifyRejectedSetupSelector(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; BoxNo: Code[20]; LineNo: Integer; Reason: Text)
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        Assert.IsFalse(StatementLine.Get(ToPeriodNo, 'NEC', LineNo), 'A rejected dependency must not create a target selector.');
        StatementLine.Get(FromPeriodNo, 'NEC', LineNo);
        Assert.AreEqual(BoxNo, StatementLine."Supplemental Box No.", 'The source selector must be preserved.');
        VerifySetupCopySummary(ToPeriodNo, BoxNo, Reason);
    end;

    local procedure VerifyConflictingTargetSetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        Definition.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual(Definition."Value Type"::"Occupation Codes", Definition."Value Type", 'Do not overwrite a target type to force compatibility.');
        Assert.AreEqual('Target typed customization', Definition.Description, 'Preserve target descriptions.');
        Definition.Get(ToPeriodNo, 'NEC', 'MALFORMED');
        Assert.AreEqual('HISTORICAL', Definition."XML Element Name", 'Do not silently repair malformed historical target setup.');
        Assert.IsFalse(StatementLine.Get(ToPeriodNo, 'NEC', 31000), 'An incompatible target definition must not acquire the source selector.');
        Assert.IsFalse(StatementLine.Get(ToPeriodNo, 'NEC', 32000), 'A malformed target definition must not acquire another selector.');
        StatementLine.Get(ToPeriodNo, 'NEC', 41000);
        Assert.AreEqual('MALFORMED', StatementLine."Supplemental Box No.", 'Preserve existing malformed target data for explicit resolution.');
        Definition.Get(FromPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual(Definition."Value Type"::Amount, Definition."Value Type", 'Preserve the source definition type.');
        VerifySetupCopySummary(ToPeriodNo, 'CUSTOM', 'different parent form box, value type, or XML element');
    end;

    local procedure VerifyOccupiedSetupStatement(Original: Record "IRS 1099 Form Statement Line"; ToPeriodNo: Code[20])
    var
        Stored: Record "IRS 1099 Form Statement Line";
    begin
        Stored.Get(ToPeriodNo, 'NEC', Original."Line No.");
        Assert.AreEqual(Original."Row No.", Stored."Row No.", 'Preserve target row identity and ordering.');
        Assert.AreEqual(Original.Description, Stored.Description, 'Preserve target statement text.');
        Assert.AreEqual(Original."Value Source", Stored."Value Source", 'Do not switch the target financial source.');
        Assert.AreEqual(Original."Supplemental Box No.", Stored."Supplemental Box No.", 'Do not install a conflicting supplemental selector.');
        Assert.AreEqual(Original."Print with", Stored."Print with", 'Preserve target signs.');
        Assert.AreEqual(Original."Print Value Type", Stored."Print Value Type", 'Preserve target formatting.');
        Assert.AreEqual(Original."Record View String", Stored."Record View String", 'Preserve target financial selection.');
        Assert.AreEqual(Original."Filter Expression", Stored."Filter Expression", 'Preserve target filter text.');
        Assert.AreEqual(Original."Row Totaling", Stored."Row Totaling", 'Preserve target totaling.');
        VerifySetupCopySummary(ToPeriodNo, '12500', 'statement line in the target period has custom settings');
    end;

    local procedure VerifyRejectedFinancialDependents(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; VendorNo: Code[20])
    var
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
    begin
        VerifyRejectedFinancialIdentity(ToPeriodNo, CompanyName());
        Assert.IsFalse(VendorSetup.Get(ToPeriodNo, VendorNo), 'Do not copy vendor setup whose financial parent was rejected.');
        Assert.IsFalse(Adjustment.Get(ToPeriodNo, VendorNo, 'NEC', 'NEC-01B'), 'Do not copy an adjustment whose financial parent was rejected.');
        VendorSetup.Get(FromPeriodNo, VendorNo);
        Assert.AreEqual('NEC-01B', VendorSetup."Form Box No.", 'Do not alter source vendor setup.');
        Adjustment.Get(FromPeriodNo, VendorNo, 'NEC', 'NEC-01B');
        Assert.AreEqual(1000, Adjustment.Amount, 'Do not reset the source adjustment amount.');
        VerifySetupCopySummary(ToPeriodNo, VendorNo, 'Form box NEC-01B does not exist');
    end;

    local procedure SetSetupCopyTargetMinimum(PeriodNo: Code[20]; TargetCompany: Text)
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        FinancialFormBox.ChangeCompany(TargetCompany);
        FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FinancialFormBox."Minimum Reportable Amount" := 777;
        FinancialFormBox.Modify();
    end;

    local procedure VerifyCrossCompanySetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; TargetCompany: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Definition: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        Definition.ChangeCompany(TargetCompany);
        Definition.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('NEC-01', Definition."Parent Form Box No.", 'The custom definition must use B''s valid parent.');
        StatementLine.ChangeCompany(TargetCompany);
        StatementLine.Get(ToPeriodNo, 'NEC', 12500);
        Assert.AreEqual('CUSTOM', StatementLine."Supplemental Box No.", 'Copy the custom selector only in B.');
        FinancialFormBox.ChangeCompany(TargetCompany);
        FinancialFormBox.Get(ToPeriodNo, 'NEC', 'NEC-01');
        Assert.AreEqual(777, FinancialFormBox."Minimum Reportable Amount", 'Preserve B''s financial customization.');
        FinancialFormBox.Get('UNRELATED', 'NEC', 'NEC-01');
        Assert.AreEqual(777, FinancialFormBox."Minimum Reportable Amount", 'Do not change unrelated B periods.');
        Definition.SetRange("Period No.", 'UNRELATED');
        Assert.RecordIsEmpty(Definition);
        Definition.Reset();
        Definition.ChangeCompany(CompanyName());
        Definition.Get(FromPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('Original supplemental meaning', Definition.Description, 'Preserve A''s source definition.');
        Definition.SetRange("Period No.", ToPeriodNo);
        Assert.RecordIsEmpty(Definition);
        StatementLine.ChangeCompany(CompanyName());
        StatementLine.SetRange("Period No.", ToPeriodNo);
        Assert.RecordIsEmpty(StatementLine);
        ReportingPeriod.Get(ToPeriodNo);
        Assert.AreEqual(20250101D, ReportingPeriod."Starting Date", 'Do not change A''s target-year scope.');
    end;

    local procedure VerifySetupCopySummary(PeriodNo: Code[20]; Identity: Text; Reason: Text)
    begin
        Assert.IsTrue(IdentityCopySummary.Contains(PeriodNo), 'The summary must identify the target period.');
        Assert.IsTrue(IdentityCopySummary.Contains(Identity), 'The summary must identify the omitted or preserved setup identity.');
        Assert.IsTrue(IdentityCopySummary.Contains(Reason), 'The summary must explain the dependency or customization conflict.');
        Assert.IsTrue(IdentityCopySummary.Contains(CompanyName()), 'The summary must identify the target company.');
    end;

    local procedure PrepareReadPermissionFixture(IsSaaS: Boolean; IsSandbox: Boolean)
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        ReportingPeriod.Get('2099');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(IsSaaS);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(IsSandbox);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Read');
    end;

    local procedure RestorePermissionEnvironment()
    begin
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
    end;

    local procedure CreateIdentityPeriod(TargetCompany: Text) PeriodNo: Code[20]
    begin
        PeriodNo := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(PeriodNo));
        CreateIdentityPeriodInCompany(PeriodNo, TargetCompany);
    end;

    local procedure CreateIdentityPeriodInCompany(PeriodNo: Code[20]; TargetCompany: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        ReportingPeriod."No." := PeriodNo;
        ReportingPeriod."Starting Date" := 20260101D;
        ReportingPeriod."Ending Date" := 20261231D;
        ReportingPeriod.Insert(true);
        Form.ChangeCompany(TargetCompany);
        Form."Period No." := PeriodNo;
        Form."No." := 'NEC';
        Form.Insert(true);
        Form."No." := 'MISC';
        Form.Insert(true);
        FinancialFormBox.ChangeCompany(TargetCompany);
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'NEC', 'NEC-01');
        FinancialFormBox.Insert(true);
        PrepareFinancialBox(FinancialFormBox, PeriodNo, 'MISC', 'MISC-03');
        FinancialFormBox.Insert(true);
    end;

    local procedure PrepareFinancialBox(var FinancialFormBox: Record "IRS 1099 Form Box"; PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20])
    begin
        FinancialFormBox.Init();
        FinancialFormBox."Period No." := PeriodNo;
        FinancialFormBox."Form No." := FormNo;
        FinancialFormBox."No." := BoxNo;
    end;

    local procedure CreateIdentityDefinition(PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20]; ParentBoxNo: Code[20]; ElementName: Text[100]; TargetCompany: Text)
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        Definition.ChangeCompany(TargetCompany);
        Definition."Period No." := PeriodNo;
        Definition."Form No." := FormNo;
        Definition."No." := BoxNo;
        Definition.Description := 'Original supplemental meaning';
        Definition."Parent Form Box No." := ParentBoxNo;
        Definition."Value Type" := Definition."Value Type"::Amount;
        Definition."XML Element Name" := ElementName;
        // Isolate financial guards from the separate unfixed changed-company definition-trigger defect.
        Definition.Insert();
    end;

    local procedure DeleteIdentityPeriod(PeriodNo: Code[20])
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.Get(PeriodNo);
        ReportingPeriod.Delete(true);
    end;

    local procedure VerifyRejectedFinancialIdentity(PeriodNo: Code[20]; TargetCompany: Text)
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        FinancialFormBox.ChangeCompany(TargetCompany);
        Definition.ChangeCompany(TargetCompany);
        Assert.IsFalse(FinancialFormBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'A supplemental identity must not become a financial destination.');
        Definition.Get(PeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Original supplemental meaning', Definition.Description, 'The existing definition changed.');
        Assert.AreEqual('NEC-01', Definition."Parent Form Box No.", 'The supplemental parent changed.');
        Assert.AreEqual('CashTipsAmt', Definition."XML Element Name", 'The supplemental mapping changed.');
        Assert.AreEqual(Definition."Value Type"::Amount, Definition."Value Type", 'The supplemental value type changed.');
    end;

    local procedure VerifyRejectedSupplementalIdentity(PeriodNo: Code[20])
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        FinancialFormBox.Get(PeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('Financial meaning', FinancialFormBox.Description, 'The financial meaning changed.');
        Assert.IsFalse(Definition.Get(PeriodNo, 'NEC', 'CUSTOM'), 'A rejected supplemental definition must not be stored.');
    end;

    local procedure VerifyRejectedFinancialRenames(PeriodNo: Code[20]; OtherPeriodNo: Code[20])
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        VerifyRejectedFinancialIdentity(PeriodNo, CompanyName());
        Assert.IsTrue(FinancialFormBox.Get(PeriodNo, 'NEC', 'CUSTOM'), 'Box-number rename lost the original form box.');
        Assert.IsTrue(FinancialFormBox.Get(PeriodNo, 'MISC', 'NEC-01B'), 'Form rename lost the original form box.');
        Assert.IsTrue(FinancialFormBox.Get(OtherPeriodNo, 'NEC', 'NEC-01B'), 'Period rename lost the original form box.');
    end;

    local procedure VerifyFinancialCopyConflict(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        FinancialFormBox: Record "IRS 1099 Form Box";
    begin
        FinancialFormBox.Get(FromPeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Source financial meaning', FinancialFormBox.Description, 'The copy must preserve the source.');
        VerifyFinancialConflictDetails(IdentityCopySummary, ToPeriodNo);
        Assert.IsTrue(IdentityCopySummary.Contains('NEC-01B'), 'Copy summary must identify the skipped box.');
    end;

    local procedure VerifyFinancialConflictDetails(Details: Text; PeriodNo: Code[20])
    begin
        Assert.IsTrue(Details.Contains('already exists as a supplemental box'), 'The identifier conflict must be reported.');
        Assert.IsTrue(Details.Contains(PeriodNo), 'The conflict must identify its period.');
        Assert.IsTrue(Details.Contains(CompanyName()), 'The conflict must identify its company.');
        Assert.IsTrue(Details.Contains('form NEC'), 'The conflict must identify its form.');
    end;

    local procedure VerifyValidFinancialDestinations(VendorSetup: Record "IRS 1099 Vendor Form Box Setup"; JournalLine: Record "Gen. Journal Line")
    begin
        Assert.AreEqual('MISC', VendorSetup."Form No.", 'Vendor setup must keep its valid financial form.');
        Assert.AreEqual('NEC-01B', VendorSetup."Form Box No.", 'Vendor setup must keep its valid financial destination.');
        Assert.AreEqual('NEC-01B', JournalLine."IRS 1099 Form Box No.", 'A different period must remain a valid journal destination.');
    end;

    local procedure VerifyHistoricalFinancialConflict(FinancialFormBox: Record "IRS 1099 Form Box"; Definition: Record "IRS 1099 Suppl. Box"; Details: Text)
    begin
        Assert.AreEqual('Historical financial meaning', FinancialFormBox.Description, 'Do not repurpose historical financial meaning.');
        Assert.AreEqual(777, FinancialFormBox."Minimum Reportable Amount", 'Do not alter historical financial setup.');
        Assert.AreEqual('Original supplemental meaning', Definition.Description, 'Do not repurpose the existing supplemental definition.');
        Assert.AreEqual('NEC-01', Definition."Parent Form Box No.", 'Do not retarget the existing supplemental parent.');
        VerifyFinancialConflictDetails(Details, FinancialFormBox."Period No.");
    end;

    local procedure CreateAnnualSetup(ReportingYear: Integer)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        IRSFormsData: Codeunit "IRS Forms Data";
    begin
        if not AnnualFixturePrepared then begin
            ReportingPeriod.SetFilter("No.", '2025|2026|2027');
            ReportingPeriod.DeleteAll(true);
            AnnualFixturePrepared := true;
        end;
        IRSFormsData.AddReportingPeriodsWithForms(ReportingYear);
    end;

    local procedure VerifyMinimum(PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20]; ExpectedMinimum: Decimal)
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.Get(PeriodNo, FormNo, BoxNo);
        Assert.AreEqual(ExpectedMinimum, FormBox."Minimum Reportable Amount", PeriodNo + '/' + BoxNo);
    end;

    local procedure SetInstruction(PeriodNo: Code[20]; FormNo: Code[20]; LineNo: Integer; Header: Text; Description: Text)
    var
        Instruction: Record "IRS 1099 Form Instruction";
    begin
        Instruction.Get(PeriodNo, FormNo, LineNo);
        Instruction.Header := CopyStr(Header, 1, MaxStrLen(Instruction.Header));
        Instruction.Description := CopyStr(Description, 1, MaxStrLen(Instruction.Description));
        Instruction.Modify();
    end;

    local procedure VerifyYearInstructions(PeriodNo: Code[20]; Is2026: Boolean)
    var
        Instruction: Record "IRS 1099 Form Instruction";
    begin
        Instruction.Get(PeriodNo, 'NEC', 7);
        Assert.IsTrue(Instruction.Description.Contains('excess golden parachute payments'), 'NEC box 3 is not reserved.');
        Instruction.Get(PeriodNo, 'MISC', 18);
        Assert.IsFalse(Instruction.Description.Contains('parachute'), 'MISC box 14 is not parachute compensation.');
        if Is2026 then begin
            Assert.IsTrue(Instruction.Description.Contains('qualified overtime'), '2026 MISC box 14 is overtime.');
            Instruction.Get(PeriodNo, 'MISC', 17);
            Assert.AreEqual('FATCA filing requirement.', Instruction.Header, 'FATCA is unnumbered in 2026.');
            Instruction.Get(PeriodNo, 'MISC', 23);
            Assert.AreEqual('Box 13a.', Instruction.Header, '2026 MISC cash-tip instructions.');
            Instruction.Get(PeriodNo, 'MISC', 24);
            Assert.AreEqual('Box 13b.', Instruction.Header, '2026 MISC occupation-code instructions.');
            Instruction.Get(PeriodNo, 'NEC', 4);
            Assert.AreEqual('Box 1a.', Instruction.Header, '2026 NEC compensation instructions.');
            Instruction.Get(PeriodNo, 'NEC', 12);
            Assert.AreEqual('Box 1b.', Instruction.Header, '2026 NEC cash-tip instructions.');
            Instruction.Get(PeriodNo, 'NEC', 13);
            Assert.AreEqual('Box 1c.', Instruction.Header, '2026 NEC occupation-code instructions.');
            Assert.IsTrue(Instruction.Description.Contains('000'), 'Occupation codes retain their zeros.');
            Instruction.Get(PeriodNo, 'NEC', 14);
            Assert.AreEqual('Box 1d.', Instruction.Header, '2026 NEC overtime instructions.');
        end else begin
            Assert.AreEqual('Reserved for future use.', Instruction.Description, '2025 MISC box 14 is reserved.');
            Instruction.Get(PeriodNo, 'NEC', 4);
            Assert.AreEqual('Box 1.', Instruction.Header, '2025 retains box 1.');
            Assert.IsFalse(Instruction.Get(PeriodNo, 'NEC', 12), 'No 2026 NEC instructions in 2025.');
            Assert.IsFalse(Instruction.Get(PeriodNo, 'MISC', 23), 'No 2026 MISC instructions in 2025.');
        end;
    end;

    local procedure VerifyAnnualThresholds(PeriodNo: Code[20]; IncomeMinimum: Decimal; CropMinimum: Decimal; DeferredMinimum: Decimal)
    begin
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-01', IncomeMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-03', IncomeMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-06', IncomeMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-09', CropMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-12', IncomeMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-15', DeferredMinimum);
        VerifyMinimum(PeriodNo, 'NEC', 'NEC-01', IncomeMinimum);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-02', 10);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-08', 10);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-05', 600);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-11', 600);
        VerifyMinimum(PeriodNo, 'MISC', 'MISC-07', 5000);
        VerifyMinimum(PeriodNo, 'NEC', 'NEC-02', 5000);
        VerifyMinimum(PeriodNo, 'DIV', 'DIV-01-A', 10);
        VerifyMinimum(PeriodNo, 'DIV', 'DIV-09', 600);
        VerifyMinimum(PeriodNo, 'INT', 'INT-01', 10);
        VerifyMinimum(PeriodNo, 'INT', 'INT-11', 0.01);
    end;

    local procedure VerifyStandardDefinitions(PeriodNo: Code[20])
    var
        Definition: Record "IRS 1099 Suppl. Box";
    begin
        Definition.Get(PeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('NEC-01', Definition."Parent Form Box No.", 'Cash tips use compensation.');
        Assert.AreEqual(Definition."Value Type"::Amount, Definition."Value Type", 'Cash tips are amounts.');
        Assert.AreEqual('CashTipsAmt', Definition."XML Element Name", 'Use the shared supported mapping.');
        Definition.Get(PeriodNo, 'NEC', 'NEC-01C');
        Assert.AreEqual(Definition."Value Type"::"Occupation Codes", Definition."Value Type", 'Occupation codes remain typed.');
        Definition.Get(PeriodNo, 'MISC', 'MISC-14');
        Assert.AreEqual('MISC-03', Definition."Parent Form Box No.", '2026 overtime uses other income, not old parachute payments.');
        Assert.AreEqual('OvertimeCompensationAmt', Definition."XML Element Name", '2026 MISC-14 is overtime.');
    end;

    local procedure VerifyOverrides(PeriodNo: Code[20]; TestVersion: Enum "XML Schema Version IRIS"; LiveVersion: Enum "XML Schema Version IRIS")
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.Get(PeriodNo);
        Assert.AreEqual(TestVersion, ReportingPeriod."IRIS XML Schema Version Test", 'Do not inherit or overwrite TEST overrides.');
        Assert.AreEqual(LiveVersion, ReportingPeriod."IRIS XML Schema Version Live", 'Do not inherit or overwrite live overrides.');
    end;

    local procedure CreateStoredDocument(var DocHeader: Record "IRS 1099 Form Doc. Header"; PeriodNo: Code[20]; DocumentStatus: Enum "IRS 1099 Form Doc. Status"; MinimumAmount: Decimal)
    var
        Vendor: Record Vendor;
        DocLine: Record "IRS 1099 Form Doc. Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        DocHeader.Init();
        DocHeader."Period No." := PeriodNo;
        DocHeader."Form No." := 'NEC';
        DocHeader."Vendor No." := Vendor."No.";
        DocHeader.Insert(true);
        DocLine."Document ID" := DocHeader.ID;
        DocLine."Period No." := PeriodNo;
        DocLine."Vendor No." := Vendor."No.";
        DocLine."Form No." := 'NEC';
        DocLine."Line No." := 10000;
        DocLine."Form Box No." := 'NEC-01';
        DocLine."Minimum Reportable Amount" := MinimumAmount;
        DocLine.Validate(Amount, 1500);
        DocLine.Insert();
        DocHeader.Status := DocumentStatus;
        DocHeader.Modify();
    end;

    [MessageHandler]
    procedure IdentityCopyMessageHandler(Message: Text)
    begin
        IdentityCopySummary := Message;
    end;

    [MessageHandler]
    procedure CopySetupMessageHandler(Message: Text[1024])
    begin
        // Handle the setup copied message
    end;

}
