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
        SetupCopySummary: Text;
        StartingEndingDateOverlapErr: Label 'The starting date and ending date overlap with an existing reporting period.';
        AmountShouldBeResetErr: Label 'Amount should be reset to 0';
        OpenDocumentTok: Label 'document %1 with status Open ', Locked = true, Comment = '%1 = document ID';

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
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        SupplementalLineCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Fresh tax-year defaults change only the seven selected 2026 categories.
        Initialize();

        // [GIVEN] Fresh 2025 and 2026 setup.
        SupplementalLineCount := SupplementalLine.Count();
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);

        // [WHEN] Standard thresholds and definitions are read.

        // [THEN] Historical exceptions, other categories and typed setup remain distinct.
        VerifyAnnualThresholds('2025', 600, 1, 0);
        VerifyAnnualThresholds('2026', 2000, 2000, 2000);
        VerifyYearInstructions('2025', false);
        VerifyYearInstructions('2026', true);
        SupplementalBox.SetRange("Period No.", '2025');
        Assert.RecordIsEmpty(SupplementalBox);
        SupplementalBox.SetRange("Period No.", '2026');
        Assert.RecordCount(SupplementalBox, 6);
        VerifyStandardSupplBoxSetup('2026');
        Assert.AreEqual(SupplementalLineCount, SupplementalLine.Count(), 'Seeding annual setup must not create saved document disclosures.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualFutureDefaultsIncludeSupplementalSetup()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual setup carries the supplemental definitions and statement instructions into future years.
        Initialize();

        // [GIVEN] Reporting year is TY2027 with no annual setup.

        // [WHEN] Requested operation is executed through its existing entry point.
        CreateAnnualSetup(2027);

        SupplementalBox.SetRange("Period No.", '2027');

        // [THEN] Expected result and preserved data are verified.
        Assert.RecordCount(SupplementalBox, 6);
        VerifyStandardSupplBoxSetup('2027');
        VerifyAnnualThresholds('2027', 2000, 2000, 2000);
        VerifyYearInstructions('2027', true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure AnnualCopyUpdatesSetupAndPreservesOverrides()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copying 2025 to 2026 converges without inheriting schema overrides or duplicating setup.
        Initialize();

        // [GIVEN] Source setup has overrides and target has none.
        CreateAnnualSetup(2025);
        ReportingPeriod.Get('2025');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"5.0.7";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"2.0.3";
        ReportingPeriod.Modify();
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2026', 20260101D, 20261231D);

        // [WHEN] Setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] Only target defaults change and its new overrides remain empty.
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

        // [GIVEN] Target now has explicit overrides and customized threshold.
        ReportingPeriod.Get('2026');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"2.0.3";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"5.0.7";
        ReportingPeriod.Modify();
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2500;
        FormBox.Modify();

        // [WHEN] Copy is repeated into existing setup.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] Existing target choices remain and no definitions are duplicated.
        VerifyOverrides('2026', Enum::"XML Schema Version IRIS"::"2.0.3", Enum::"XML Schema Version IRIS"::"5.0.7");
        VerifyMinimum('2026', 'NEC', 'NEC-01', 2500);
        SupplementalBox.SetRange("Period No.", '2026');
        Assert.RecordCount(SupplementalBox, 6);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualSetupUpdatePreservesCustomizationsAndReportsConflicts()
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Reconciliation inserts absent defaults, recognizes prior standards and preserves custom choices.
        Initialize();

        // [GIVEN] Existing target has absent box, old standard and custom setup.
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
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        SupplementalBox.Description := 'Custom tips label';
        SupplementalBox.Modify(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01D');
        SupplementalBox."XML Element Name" := 'CUSTOM';
        SupplementalBox.Modify();

        // [WHEN] Explicit reconciliation is repeated.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Custom values are preserved and identified for explicit resolution.
        VerifyMinimum('2026', 'MISC', 'MISC-01', 2000);
        VerifyMinimum('2026', 'MISC', 'MISC-09', 2000);
        VerifyMinimum('2026', 'NEC', 'NEC-01', 2500);
        FormBox.Get('2026', 'NEC', 'NEC-01');
        Assert.AreEqual('Custom compensation', FormBox.Description, 'Custom financial descriptions must survive.');
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        Assert.AreEqual('Custom tips label', SupplementalBox.Description, 'Compatible supplemental labels must survive.');
        SupplementalBox.Get('2026', 'NEC', 'NEC-01D');
        Assert.AreEqual('CUSTOM', SupplementalBox."XML Element Name", 'Conflicts must not be silently repaired.');
        Assert.IsTrue(Details.Contains('custom minimum'), 'Identify the custom threshold.');
        Assert.IsTrue(Details.Contains('NEC-01D'), 'Identify the incompatible supplemental definition.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure AnnualUpdateDoesNotRepurposeHistoricalMisc14()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The old financial MISC-14 migration is never applied to a 2025-to-2026 update.
        Initialize();

        // [GIVEN] Target retains historical financial identifier with old meaning.
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'MISC', 130000);
        StatementLine.Delete(true);
        SupplementalBox.Get('2026', 'MISC', 'MISC-14');
        SupplementalBox.Delete(true);
        FormBox."Period No." := '2026';
        FormBox."Form No." := 'MISC';
        FormBox."No." := 'MISC-14';
        FormBox.Description := 'Historical parachute payments';
        FormBox.Insert(true);

        // [WHEN] Real consecutive-year update and reconciliation are repeated.
        LibraryIRSReportingPeriod.UpdateDataForNewTaxYear('2025', '2026');
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Financial history is not reused as supplemental overtime or moved to NEC.
        FormBox.Get('2026', 'MISC', 'MISC-14');
        Assert.AreEqual('Historical parachute payments', FormBox.Description, 'Never reinterpret old financial identifiers.');
        Assert.IsFalse(SupplementalBox.Get('2026', 'MISC', 'MISC-14'), 'An identifier conflict requires explicit resolution.');
        Assert.IsTrue(Details.Contains('is already used by a form box'), 'Identify the conflict instead of failing setup or silently repurposing it.');
        VerifyMinimum('2026', 'NEC', 'NEC-03', 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualParentFormBoxDeletionIsBlocked()
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A financial parent cannot be deleted while supplemental setup references it.
        Initialize();

        // [GIVEN] Six supported definitions reference financial parents.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'NEC', 'NEC-01');

        // [WHEN] Parent is deleted.
        asserterror FormBox.Delete(true);

        // [THEN] Dependent definition is identified.
        Assert.ExpectedError('parent of supplemental box NEC-01B');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualParentFormBoxRenameIsBlocked()
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A financial parent cannot be renamed while supplemental setup references it.
        Initialize();

        // [GIVEN] MISC other income is parent of tips definition.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'MISC', 'MISC-03');

        // [WHEN] Parent is renamed.
        asserterror FormBox.Rename('2026', 'MISC', 'RENAMED');

        // [THEN] Reverse-reference guard identifies dependent setup.
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
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Allowed deletion removes statements before definitions and financial parents without orphans.
        Initialize();

        // [GIVEN] Period contains financial and supplemental setup, but no documents.
        CreateAnnualSetup(2026);

        // [WHEN] NEC setup is deleted.
        Form.Get('2026', 'NEC');
        Form.Delete(true);

        // [THEN] MISC remains and no NEC dependencies remain.
        SupplementalBox.SetRange("Period No.", '2026');
        SupplementalBox.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(SupplementalBox);
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(StatementLine);
        FormBox.SetRange("Period No.", '2026');
        FormBox.SetRange("Form No.", 'NEC');
        Assert.RecordIsEmpty(FormBox);
        SupplementalBox.SetRange("Form No.", 'MISC');
        Assert.RecordCount(SupplementalBox, 3);

        // [WHEN] Remaining period is deleted.
        ReportingPeriod.Get('2026');
        ReportingPeriod.Delete(true);

        // [THEN] Its contained setup is removed too.
        Assert.RecordIsEmpty(SupplementalBox);
        StatementLine.SetRange("Form No.");
        Assert.RecordIsEmpty(StatementLine);
        FormBox.SetRange("Form No.");
        Assert.RecordIsEmpty(FormBox);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualReconciliationOnlyIdentifiesAffectedOpenDocuments()
    var
        OpenIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SubmittedIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        CurrentIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OtherPeriodIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TransmissionLog: Record "Transmission Log IRIS";
        OriginalIRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        OriginalSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        OriginalLog: Record "Transmission Log IRIS";
        ContentOutStream: OutStream;
        ContentInStream: InStream;
        Content: Text;
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Setup identifies only stale Open documents and preserves saved snapshots and payload history.
        Initialize();

        // [GIVEN] Stale Open/submitted documents, current Open document and another period.
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);
        CreateStoredDocument(OpenIRS1099FormDocHeader, '2026', OpenIRS1099FormDocHeader.Status::Open, 600);
        CreateStoredDocument(SubmittedIRS1099FormDocHeader, '2026', SubmittedIRS1099FormDocHeader.Status::Submitted, 600);
        CreateStoredDocument(CurrentIRS1099FormDocHeader, '2026', CurrentIRS1099FormDocHeader.Status::Open, 2000);
        CreateStoredDocument(OtherPeriodIRS1099FormDocHeader, '2025', OtherPeriodIRS1099FormDocHeader.Status::Open, 600);
        SupplementalLine."Document ID" := OpenIRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", 'NEC-01B');
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Insert(true);
        TransmissionLog."Period No." := '2026';
        TransmissionLog."Receipt ID" := 'HISTORICAL';
        TransmissionLog."Transmission Content".CreateOutStream(ContentOutStream);
        ContentOutStream.WriteText('<historical>unchanged</historical>');
        TransmissionLog.Insert();
        OriginalIRS1099FormDocHeader := SubmittedIRS1099FormDocHeader;
        OriginalSupplementalLine := SupplementalLine;
        OriginalLog := TransmissionLog;

        // [WHEN] Annual setup is reconciled twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Only stale Open identity is reported; stored data is not recalculated.
        Assert.IsTrue(Details.Contains(StrSubstNo(OpenDocumentTok, OpenIRS1099FormDocHeader.ID)), 'Identify the affected Open document.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, SubmittedIRS1099FormDocHeader.ID)), 'Submitted documents must not be offered.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, CurrentIRS1099FormDocHeader.ID)), 'Current Open documents need no notice.');
        Assert.IsFalse(Details.Contains(StrSubstNo(OpenDocumentTok, OtherPeriodIRS1099FormDocHeader.ID)), 'Another period must not be offered.');
        IRS1099FormDocLine.SetRange("Document ID", OpenIRS1099FormDocHeader.ID);
        IRS1099FormDocLine.FindFirst();
        Assert.AreEqual(600, IRS1099FormDocLine."Minimum Reportable Amount", 'Setup must not rewrite a financial snapshot.');
        Assert.IsTrue(IRS1099FormDocLine."Include In 1099", 'Stored inclusion changes only after explicit recalculation.');
        SubmittedIRS1099FormDocHeader.Get(SubmittedIRS1099FormDocHeader.ID);
        Assert.AreEqual(OriginalIRS1099FormDocHeader.SystemModifiedAt, SubmittedIRS1099FormDocHeader.SystemModifiedAt, 'Submitted data changed.');
        SupplementalLine.Get(OpenIRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.AreEqual(OriginalSupplementalLine.SystemModifiedAt, SupplementalLine.SystemModifiedAt, 'Saved disclosures changed.');
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'Saved parent snapshots must not be retargeted.');
        TransmissionLog.Get(OriginalLog."Line ID");
        Assert.AreEqual(OriginalLog.SystemModifiedAt, TransmissionLog.SystemModifiedAt, 'Historical transmission changed.');
        TransmissionLog.CalcFields("Transmission Content");
        TransmissionLog."Transmission Content".CreateInStream(ContentInStream);
        ContentInStream.ReadText(Content);
        Assert.AreEqual('<historical>unchanged</historical>', Content, 'Stored XML must remain unchanged.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualSupplBoxInUseConflictPreservesSnapshot()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual setup never repairs a structural conflict by retargeting a saved parent.
        Initialize();

        // [GIVEN] Saved supplemental line and incompatible imported definition.
        CreateAnnualSetup(2026);
        CreateStoredDocument(IRS1099FormDocHeader, '2026', IRS1099FormDocHeader.Status::Open, 600);
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", 'NEC-01B');
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Insert(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        SupplementalBox."Parent Form Box No." := 'NEC-03';
        SupplementalBox.Modify();

        // [WHEN] Setup is reconciled.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Conflict is explicit and neither definition nor snapshot is silently reinterpreted.
        Assert.IsTrue(Details.Contains('NEC-01B'), 'Identify the structural conflict for explicit resolution.');
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        Assert.AreEqual('NEC-03', SupplementalBox."Parent Form Box No.", 'Annual setup must not silently repair in-use structure.');
        SupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.AreEqual('NEC-01', SupplementalLine."Parent Form Box No.", 'Annual setup must preserve the saved parent.');
        Assert.AreEqual(100, SupplementalLine.Amount, 'Annual setup must preserve saved values.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualPeriodDeletionChecksDocumentsBeforeCleanup()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Period deletion checks all document use before removing any setup.
        Initialize();

        // [GIVEN] Period contains submitted document.
        CreateAnnualSetup(2026);
        CreateStoredDocument(IRS1099FormDocHeader, '2026', IRS1099FormDocHeader.Status::Submitted, 600);
        ReportingPeriod.Get('2026');

        // [WHEN] Period deletion is attempted.
        asserterror ReportingPeriod.Delete(true);

        // [THEN] Document-use error precedes dependency cleanup.
        Assert.ExpectedError('used by 1099 form documents');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure AnnualSetupUpdateUsesTargetCompany()
    var
        OtherCompany: Record Company;
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FormBox: Record "IRS 1099 Form Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        OtherMinimum: Decimal;
        SupplBoxCount: Integer;
        StatementCount: Integer;
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Definitions validate against the target company's period and parents, not ambient company data.
        Initialize();

        // [GIVEN] Disposable company contains target period absent from current company.
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
        LibraryIRSReportingPeriod.UpdateAnnualSetup('OTHER2026', OtherCompany.Name);
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('OTHER2026', OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        FormBox.Get('OTHER2026', 'NEC', 'NEC-01');
        OtherMinimum := FormBox."Minimum Reportable Amount";
        SupplementalBox.ChangeCompany(OtherCompany.Name);
        SupplementalBox.SetRange("Period No.", 'OTHER2026');
        SupplBoxCount := SupplementalBox.Count();
        StatementLine.ChangeCompany(OtherCompany.Name);
        StatementLine.SetRange("Period No.", 'OTHER2026');
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        StatementCount := StatementLine.Count();
        Commit();
        OtherCompany.Delete(true);

        // [THEN] Company-scoped setup converges without touching current company.
        Assert.AreEqual(2000, OtherMinimum, 'Target-company defaults must be reconciled.');
        Assert.AreEqual(6, SupplBoxCount, 'Target-company definitions must be complete and unique.');
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
    procedure AnnualStatementSelectorBlocksSupplBoxDeletion()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Active statement selectors protect definitions even without document values.
        Initialize();

        // [GIVEN] Supplemental definition is selected by standard statement row.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] Supplemental definition is deleted.
        asserterror SupplementalBox.Delete(true);

        // [THEN] Dependent row is identified.
        Assert.ExpectedError('used by statement row NEC-01B');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorBlocksSupplBoxRename()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Renaming a definition cannot orphan an active selector.
        Initialize();

        // [GIVEN] Supplemental definition is selected by standard statement row.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01C');

        // [WHEN] Supplemental definition is renamed.
        asserterror SupplementalBox.Rename('2026', 'NEC', 'RENAMED');

        // [THEN] Dependent row is identified.
        Assert.ExpectedError('used by statement row NEC-01C');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualStatementSelectorBlocksSupplBoxSetupEdit()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A structurally incompatible edit identifies the dependent statement before breaking its reference.
        Initialize();

        // [GIVEN] Supplemental definition is selected by standard statement row.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01D');
        SupplementalBox."Parent Form Box No." := 'NEC-03';

        // [WHEN] Its stored parent is changed through direct AL modify.
        asserterror SupplementalBox.Modify(true);

        // [THEN] Reference guard protects dependent statement.
        Assert.ExpectedError('used by statement row NEC-01D');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInactiveStatementSelectorDoesNotUseSupplBox()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A financial row retains its filters and does not activate a stale supplemental selector.
        Initialize();

        // [GIVEN] Statement row uses financial filters rather than its inactive supplemental selector.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine.Validate("Value Source", StatementLine."Value Source"::"Document Line");
        StatementLine.SetFormBoxFilter('NEC-01');
        StatementLine.Modify(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] Otherwise unused supplemental definition is deleted.
        SupplementalBox.Delete(true);

        // [THEN] Financial configuration is retained without active reverse reference.
        Assert.IsFalse(SupplementalBox.Get('2026', 'NEC', 'NEC-01B'), 'Only active supplemental selectors are reverse references.');
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
        // [SCENARIO 653992] Repeat annual updates insert absent rows without retargeting custom sources, boxes, labels or order.
        Initialize();

        // [GIVEN] Statement rows have custom source, selector, description and ordering; one default is absent.
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
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

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
        // [SCENARIO 653992] A customer row at a supplied insertion point is never replaced.
        Initialize();

        // [GIVEN] Statement row occupies standard insertion point with custom content.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine."Row No." := 'CUSTOM';
        StatementLine.Description := 'My row';
        StatementLine.Modify(true);

        // [WHEN] Annual reconciliation is requested.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Customer row is preserved and its conflict reported.
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
        // [SCENARIO 653992] A selector cannot borrow a definition from another form in the same year.
        Initialize();

        // [GIVEN] Statement row belongs to NEC.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);

        // [WHEN] MISC supplemental definition is selected.
        asserterror StatementLine.Validate("Supplemental Box No.", 'MISC-13A');

        // [THEN] Filtered relation rejects cross-form selector.
        Assert.ExpectedError('cannot be found in the related table');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    trigger OnRun()
    begin
        // [FEATURE] [1099]
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualSetupAddsInstructionsToEmptyPeriodOnFirstUpdate()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Instruction: Record "IRS 1099 Form Instruction";
        InstructionCount: Integer;
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual Setup Adds Instructions To Empty Period On First Update.
        Initialize();

        // [GIVEN] 2026 reporting period has no forms or instructions.

        ReportingPeriod."No." := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ReportingPeriod."No."));
        ReportingPeriod."Starting Date" := 20260101D;
        ReportingPeriod."Ending Date" := 20261231D;
        ReportingPeriod.Insert(true);

        // [WHEN] Requested operation is executed through its existing entry point.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(ReportingPeriod."No.", CompanyName());

        // [THEN] Expected result and preserved data are verified.
        VerifyYearInstructions(ReportingPeriod."No.", true);
        Assert.AreEqual('', Details, 'Missing forms and their annual instructions must be created in the same update.');
        Instruction.SetRange("Period No.", ReportingPeriod."No.");
        InstructionCount := Instruction.Count();

        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(ReportingPeriod."No.", CompanyName());

        Assert.RecordCount(Instruction, InstructionCount);
        Assert.AreEqual('', Details, 'Repeating an annual update must not require further setup changes.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInstructionsRepairRecognizedEarlierStandards()
    var
        Instruction: Record "IRS 1099 Form Instruction";
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Explicit updates repair recognized stale 2025 instructions without touching earlier years.
        Initialize();

        // [GIVEN] Current reporting period has released stale instructions, while historical period has same text.
        CreateAnnualSetup(2025);
        SetInstruction('2025', 'NEC', 7, 'Box 3.', 'Reserved for future use.');
        SetInstruction('2025', 'MISC', 18, 'Box 14.', 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.');
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('HISTORY2024', 20240101D, 20241231D);
        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(20240101D, 20241231D, 'NEC');
        Instruction.Get('2025', 'NEC', 7);
        Instruction."Period No." := 'HISTORY2024';
        Instruction.Insert();

        // [WHEN] Both periods are explicitly reconciled, with current one repeated.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2025', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2025', CompanyName());
        LibraryIRSReportingPeriod.UpdateAnnualSetup('HISTORY2024', CompanyName());

        // [THEN] Supported year converges without conflicts or duplicates and historical text remains.
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
        // [SCENARIO 653992] Annual instructions preserve custom text and moved rows while restoring absent defaults.
        Initialize();

        // [GIVEN] Reporting period has customized and moved instructions and missing standard instruction.
        CreateAnnualSetup(2026);
        SetInstruction('2026', 'NEC', 7, 'Box 3.', 'Custom parachute guidance');
        SetInstruction('2026', 'MISC', 17, 'My FATCA guidance', 'Custom account reporting');
        Instruction.Get('2026', 'NEC', 12);
        Instruction.Delete();
        Instruction."Line No." := 1200;
        Instruction.Insert();
        Instruction.Get('2026', 'MISC', 23);
        Instruction.Delete();

        // [WHEN] Annual update is repeated.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

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
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualInstructionsUpgradePreviousSupplementalText()
    var
        Instruction: Record "IRS 1099 Form Instruction";
        Details: Text;
        PreviousCashTips: Text;
        PreviousOccupation: Text;
        PreviousOvertime: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual reconciliation replaces previous default summaries with official recipient instructions.
        Initialize();

        // [GIVEN] Reporting period has previous standard supplemental recipient summaries.
        CreateAnnualSetup(2026);
        PreviousCashTips := 'Shows cash tips already included in the reported income. This is a breakdown, not additional income. Determine any deduction using the instructions for your tax return.';
        PreviousOccupation := 'Shows up to two Treasury tipped occupation codes. Code 000 identifies a nonqualifying occupation and retains its leading zeros.';
        PreviousOvertime := 'Shows qualified overtime compensation already included in the reported income. Report only the qualified overtime premium portion, not all overtime pay. Determine any deduction using the instructions for your tax return.';
        SetInstruction('2026', 'NEC', 12, 'Box 1b.', PreviousCashTips);
        SetInstruction('2026', 'NEC', 13, 'Box 1c.', PreviousOccupation);
        SetInstruction('2026', 'NEC', 14, 'Box 1d.', PreviousOvertime);
        SetInstruction('2026', 'MISC', 23, 'Box 13a.', PreviousCashTips);
        SetInstruction('2026', 'MISC', 24, 'Box 13b.', PreviousOccupation);
        SetInstruction('2026', 'MISC', 18, 'Box 14.', PreviousOvertime);

        // [WHEN] Requested operation is executed through its existing entry point.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Expected result and preserved data are verified.
        Assert.AreEqual('', Details, 'Previous default summaries are not customizations.');
        Instruction.Get('2026', 'NEC', 12);
        Assert.IsTrue(Instruction.Description.Contains('amount reported in box 1a'), 'NEC tips refer to nonemployee compensation.');
        Instruction.Get('2026', 'MISC', 23);
        Assert.IsTrue(Instruction.Description.Contains('amount reported in box 3'), 'MISC tips refer to other income.');
        Instruction.Get('2026', 'NEC', 13);
        Assert.IsTrue(Instruction.Description.Contains('no other code is included in box 1c'), 'NEC uses its occupation-code box.');
        Instruction.Get('2026', 'MISC', 24);
        Assert.IsTrue(Instruction.Description.Contains('no other code is included in box 13b'), 'MISC uses its occupation-code box.');
        Instruction.Get('2026', 'NEC', 14);
        Assert.IsTrue(Instruction.Description.Contains('Part III of Schedule 1-A'), 'NEC overtime uses official deduction instructions.');
        Instruction.Get('2026', 'MISC', 18);
        Assert.IsTrue(Instruction.Description.Contains('amount reported in box 3'), 'MISC overtime refers to other income.');
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Assert.AreEqual('', Details, 'Official recipient instructions are idempotent.');
    end;

    [Test]
    procedure HiddenSchemaOverrideCannotBeEditedThroughTestPage()
    var
        ReportingPeriods: TestPage "IRS Reporting Periods";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] TestPage omits the hidden control and cannot substitute for client personalization.
        Initialize();

        // [GIVEN] Current BC environment is sandbox.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);

        // [WHEN] Actual page is opened without personalization.
        ReportingPeriods.OpenEdit();

        // [THEN] Attempted control edit is rejected because hidden field is not exposed.
        asserterror ReportingPeriods.IRISXmlSchemaVersion.SetValue("XML Schema Version IRIS"::"5.0.7");
        Assert.ExpectedError('is not found on the page');
        ReportingPeriods.Close();

        // [WHEN] Same page is opened in production.
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
        // [SCENARIO 653992] Read opens and evaluates the sandbox page even though its schema control is hidden.
        Initialize();

        // [GIVEN] Sandbox period with hidden schema override.
        PrepareReadPermissionFixture(true, true);

        // [WHEN] Page evaluates its period using only normal Read permissions.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] Period is readable without configuration execute-permission failure.
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
        // [SCENARIO 653992] Read opens the production page without making the schema override visible.
        Initialize();

        // [GIVEN] Production period with hidden schema override.
        PrepareReadPermissionFixture(true, false);

        // [WHEN] Page evaluates its period using only normal Read permissions.
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
        // [SCENARIO 653992] Normal Read page evaluation also works in OnPrem without changing environment guards.
        Initialize();

        // [GIVEN] OnPrem period with hidden schema override.
        PrepareReadPermissionFixture(false, false);

        // [WHEN] Page evaluates its period using only normal Read permissions.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] No SaaS mock is required to authorize configuration codeunit.
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
        // [SCENARIO 653992] Normal IRS setup-edit permissions allow validated override writes for an unverified year.
        Initialize();

        // [GIVEN] Unverified period is edited with only normal IRS edit permission set.
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

        // [THEN] Values are saved without requiring verified filing year.
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
        // [SCENARIO 653992] Hiding the override is not security; the normal read permission set rejects a write.
        Initialize();

        // [GIVEN] Period is read with only normal IRS read permission set.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Read');
        ReportingPeriod.Get('2099');
        CanWrite := ReportingPeriod.WritePermission();
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");

        // [WHEN] Direct write attempts to bypass hidden control.
        asserterror ReportingPeriod.Modify(true);

        // [THEN] Platform authorization rejects write and rolls back uncommitted fixture.
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
    procedure FormBoxInsertRejectsSupplBoxNumber()
    var
        FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Financial insertion cannot turn an existing supplemental definition into a posting destination.
        Initialize();

        // [GIVEN] Committed test reporting period has supplemental box NEC-01B.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        Commit();
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');

        // [WHEN] Form box is inserted at that identity.
        asserterror FormBox.Insert(true);

        // [THEN] Collision is rejected and existing definition remains unchanged.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFormBoxNumber(PeriodNo, CompanyName());
        DeleteBoxSetupTestPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SupplBoxInsertRejectsFormBoxNumber()
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The existing supplemental-to-financial rejection remains effective.
        Initialize();

        // [GIVEN] Committed test reporting period has custom Form Box.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'CUSTOM');
        FormBox.Description := 'Financial meaning';
        FormBox.Insert(true);
        Commit();
        SupplementalBox."Period No." := PeriodNo;
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."Parent Form Box No." := 'NEC-01';

        // [WHEN] Supplemental definition is inserted with same identity.
        asserterror SupplementalBox.Insert(true);

        // [THEN] Original financial meaning survives without supplemental replacement.
        Assert.ExpectedError('does not meet the reporting requirements');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedSupplBoxNumber(PeriodNo);
        DeleteBoxSetupTestPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FormBoxRenameChecksAllDestinationKeys()
    var
        FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Changing any financial key component must validate the complete rename destination.
        Initialize();

        // [GIVEN] Three unused form boxes have distinct keys outside supplemental identity.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        OtherPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'CUSTOM');
        FormBox.Insert(true);
        PrepareFormBox(FormBox, PeriodNo, 'MISC', 'NEC-01B');
        FormBox.Insert(true);
        PrepareFormBox(FormBox, OtherPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
        Commit();

        // [WHEN] Only box number changes into occupied supplemental identity.
        FormBox.Get(PeriodNo, 'NEC', 'CUSTOM');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Box-number destination is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Only form changes into occupied supplemental identity.
        FormBox.Get(PeriodNo, 'MISC', 'NEC-01B');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Form destination is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Only period changes into occupied supplemental identity.
        FormBox.Get(OtherPeriodNo, 'NEC', 'NEC-01B');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] All source keys and supplemental definition remain intact.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFormBoxRenames(PeriodNo, OtherPeriodNo);
        DeleteBoxSetupTestPeriod(PeriodNo);
        DeleteBoxSetupTestPeriod(OtherPeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure FormBoxCopyReportsDuplicateSupplBoxNumber()
    var
        FormBox: Record "IRS 1099 Form Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Triggerless financial setup copy reports and skips a target supplemental collision.
        Initialize();

        // [GIVEN] Source period has Form Box and target period uses that identity for supplemental box.
        FromPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        ToPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        PrepareFormBox(FormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Description := 'Source financial meaning';
        FormBox.Insert(true);
        CreateSupplBox(ToPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());

        // [WHEN] Supported copy path bypasses financial table insert triggers.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] No collision is inserted, source is unchanged, and summary names rejected target.
        VerifyRejectedFormBoxNumber(ToPeriodNo, CompanyName());
        VerifyFormBoxCopyConflict(FromPeriodNo, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FormBoxNumberChecksAllowOtherPeriodsAndForms()
    var
        FormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        JournalLine: Record "Gen. Journal Line";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Identical numbers in another form or period remain valid financial posting destinations.
        Initialize();

        // [GIVEN] First period has supplemental NEC-01B while second period and form MISC do not.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        OtherPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'MISC', 'NEC-01B');
        FormBox.Insert(true);
        PrepareFormBox(FormBox, OtherPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
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
        VerifyValidFormBoxRelations(VendorSetup, JournalLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FormBoxNumberCheckUsesTargetCompany()
    var
        OtherCompany: Record Company;
        FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
        OtherPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Changed-company insertion uses target definitions, never ambient-company definitions.
        Initialize();

        // [GIVEN] Target company has collision absent from current company and free identity occupied only in current company.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        OtherCompany.Name := CopyStr('IRS Identity ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateBoxSetupTestPeriodInCompany(PeriodNo, OtherCompany.Name);
        OtherPeriodNo := CreateBoxSetupTestPeriod(OtherCompany.Name);
        CreateSupplBox(OtherPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
        Commit();
        PrepareFormBox(FormBox, OtherPeriodNo, 'NEC', 'NEC-01B');

        // [WHEN] Triggered insert targets target company's supplemental definition.
        asserterror FormBox.Insert(true);

        // [THEN] Target company's collision is rejected, whereas current company's matching identifier did not block earlier target-company insert.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');
        VerifyRejectedFormBoxNumber(OtherPeriodNo, OtherCompany.Name);
        Assert.IsTrue(FormBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'Another company must not reserve this financial number.');
        OtherCompany.Delete(true);
        DeleteBoxSetupTestPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SupplBoxValidationUsesTargetCompany()
    var
        OtherCompany: Record Company;
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
        TargetOnlyPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Suppl Box Validation Uses Target Company.
        Initialize();

        // [GIVEN] Current and target companies have distinct reporting setup and financial-box collision only in target company.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        OtherCompany.Name := CopyStr('IRS Supplemental ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateBoxSetupTestPeriodInCompany(PeriodNo, OtherCompany.Name);
        TargetOnlyPeriodNo := CreateBoxSetupTestPeriod(OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);

        // [WHEN] Requested operation is executed through its existing entry point.
        SupplementalBox.ChangeCompany(OtherCompany.Name);
        SupplementalBox."Period No." := TargetOnlyPeriodNo;
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'NEC-01B';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::Amount;
        SupplementalBox."XML Element Name" := 'CashTipsAmt';
        SupplementalBox.Insert(true);

        // [THEN] Expected result and preserved data are verified.
        Assert.IsTrue(SupplementalBox.Get(TargetOnlyPeriodNo, 'NEC', 'NEC-01B'), 'A period and parent present only in the target company must validate.');
        Commit();

        SupplementalBox.Init();
        SupplementalBox."Period No." := PeriodNo;
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'NEC-01B';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::Amount;
        SupplementalBox."XML Element Name" := 'CashTipsAmt';
        asserterror SupplementalBox.Insert(true);
        Assert.ExpectedError('The setup for supplemental box NEC-01B does not meet the reporting requirements.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'A financial collision present only in the target company must prevent insertion.');
        Assert.IsTrue(FormBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'Validation must preserve the target financial box.');

        OtherCompany.Delete(true);
        DeleteBoxSetupTestPeriod(PeriodNo);
        Commit();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualBoxSetupPreservesExistingNumberConflicts()
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual reconciliation reports historical conflicts without deleting or repurposing either record.
        Initialize();

        // [GIVEN] Owned period has historical conflict created without insert triggers.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');
        FormBox.Description := 'Historical financial meaning';
        FormBox."Minimum Reportable Amount" := 777;
        FormBox.Insert();

        // [WHEN] Annual reconciliation is repeated.
        LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());

        // [THEN] Both identities and their meaning are preserved with explicit scoped conflict.
        FormBox.Get(PeriodNo, 'NEC', 'NEC-01B');
        SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01B');
        VerifyExistingFormBoxNumberConflict(FormBox, SupplementalBox, Details);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualBoxSetupReportsParentBoxNumberConflict()
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        PeriodNo: Code[20];
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Reconciliation cannot recreate a financial parent over an existing custom supplemental identity.
        Initialize();

        // [GIVEN] Custom supplemental NEC-01 uses existing alternative financial parent.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        FormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FormBox.Delete(true);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'CUSTOM');
        FormBox.Insert(true);
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01', 'CUSTOM', '', CompanyName());

        // [WHEN] Standard annual financial reconciliation attempts to supply NEC-01.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());

        // [THEN] Custom definition is preserved and financial parent is explicitly reported, not inserted.
        Assert.IsFalse(FormBox.Get(PeriodNo, 'NEC', 'NEC-01'), 'Reconciliation must not create a financial/supplemental collision.');
        SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01');
        Assert.AreEqual('CUSTOM', SupplementalBox."Parent Form Box No.", 'Custom supplemental meaning must survive.');
        VerifyFormBoxConflictDetails(Details, PeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyOmitsUnsupportedSupplementalSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        TargetPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A copy to an earlier year retains financial statements without unsupported supplemental dependencies.
        Initialize();

        // [GIVEN] Source period has complete 2026 setup and target period is in 2025.
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
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyPreservesFutureSupplementalSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        TargetPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copying to a future year preserves source labels, existing target labels and valid supplemental selectors.
        Initialize();

        // [GIVEN] Source period has customized labels and target period is in 2027.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        SupplementalBox.Description := 'Source customized cash tips';
        SupplementalBox.Modify(true);
        TargetPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(TargetPeriodNo);
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();

        // [WHEN] Requested operation is executed through its existing entry point.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);
        SupplementalBox.Get(TargetPeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Expected result and preserved data are verified.
        Assert.AreEqual('Source customized cash tips', SupplementalBox.Description, 'Copy source labels before seeding missing defaults.');
        SupplementalBox.Description := 'Target customized cash tips';
        SupplementalBox.Modify(true);
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);

        SupplementalBox.Get(TargetPeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Target customized cash tips', SupplementalBox.Description, 'A repeat copy must preserve existing target labels.');
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        Assert.AreEqual('Source customized cash tips', SupplementalBox.Description, 'Copying must not change source labels.');
        SupplementalBox.SetRange("Period No.", TargetPeriodNo);
        Assert.RecordCount(SupplementalBox, 6);
        VerifyStandardSupplBoxSetup(TargetPeriodNo);
        StatementLine.SetRange("Period No.", TargetPeriodNo);
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordCount(StatementLine, 6);
        VerifyYearInstructions(TargetPeriodNo, true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyPreservesSupplementalDescriptions()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Setup Copy Preserves Supplemental Descriptions.
        Initialize();

        // [GIVEN] Source and target periods have independently customized descriptions.

        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        LibraryIRSReportingPeriod.UpdateAnnualSetup(FromPeriodNo, CompanyName());
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'NEC-01B');
        SupplementalBox.Description := 'Source custom tips';
        SupplementalBox.Modify(true);
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'NEC-01C');
        SupplementalBox.Description := 'Source custom occupations';
        SupplementalBox.Modify(true);
        SupplementalBox."Period No." := ToPeriodNo;
        SupplementalBox.Description := 'Existing target occupations';
        SupplementalBox.Insert(true);

        // [WHEN] Requested operation is executed through its existing entry point.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        SupplementalBox.Get(ToPeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Expected result and preserved data are verified.
        Assert.AreEqual('Source custom tips', SupplementalBox.Description, 'Copy source descriptions before supplying absent defaults.');
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'NEC-01C');
        Assert.AreEqual('Existing target occupations', SupplementalBox.Description, 'Never replace an existing target description.');
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Source custom tips', SupplementalBox.Description, 'Do not change the source tips description.');
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'NEC-01C');
        Assert.AreEqual('Source custom occupations', SupplementalBox.Description, 'Do not change the source occupation description.');
        SupplementalBox.SetRange("Period No.", ToPeriodNo);
        Assert.RecordCount(SupplementalBox, 6);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyCreatesCustomDependenciesBeforeSelectors()
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Custom typed definitions and their selectors precede statement defaults and converge without losing labels.
        Initialize();

        // [GIVEN] Source period has custom amount and code definitions, custom parent and selectors at standard default positions.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        PrepareFormBox(FormBox, FromPeriodNo, 'NEC', 'CUSTOM-PARENT');
        FormBox.Description := 'Source custom financial parent';
        FormBox.Insert(true);
        CreateSupplBox(FromPeriodNo, 'NEC', 'CUSTOM-AMOUNT', 'CUSTOM-PARENT', '', CompanyName());
        CreateSupplBox(FromPeriodNo, 'NEC', 'CUSTOM-CODES', 'NEC-01', '', CompanyName());
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'CUSTOM-CODES');
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::"Occupation Codes";
        SupplementalBox.Modify(true);
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
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyRejectsMissingSourceSupplBox()
    var
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A historical dangling source selector is reported rather than introduced into the target.
        Initialize();

        // [GIVEN] Source period contains intentionally malformed selector without definition.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(FromPeriodNo, 'MISSING', 31000);

        // [WHEN] Its setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Target period contains no new dangling selector and source period remains available for explicit repair.
        VerifyRejectedSetupSelector(FromPeriodNo, ToPeriodNo, 'MISSING', 31000, 'does not exist');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyRejectsUnsupportedSourceMapping()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An unsupported custom source mapping is not accepted by triggerless setup copying.
        Initialize();

        // [GIVEN] Source period has custom definition with unsupported XML mapping and its selector.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSupplBox(FromPeriodNo, 'NEC', 'UNSUPPORTED-MAP', 'NEC-01', 'UnsupportedElement', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'UNSUPPORTED-MAP', 31000);

        // [WHEN] Its setup is copied.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Neither unsupported dependency is introduced and source mapping remains unchanged.
        VerifyRejectedSetupSelector(FromPeriodNo, ToPeriodNo, 'UNSUPPORTED-MAP', 31000, 'XML element does not meet the reporting requirements');
        Assert.IsFalse(SupplementalBox.Get(ToPeriodNo, 'NEC', 'UNSUPPORTED-MAP'), 'Do not copy an unsupported source mapping.');
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'UNSUPPORTED-MAP');
        Assert.AreEqual('UnsupportedElement', SupplementalBox."XML Element Name", 'Do not repair the source implicitly.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyPreservesConflictingTargetSupplBoxes()
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Incompatible typed and malformed target definitions remain unchanged without acquiring source selectors.
        Initialize();

        // [GIVEN] Source period has valid custom definitions, while target period has incompatible typed and historical unsupported mappings.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSupplBox(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        CreateSupplBox(FromPeriodNo, 'NEC', 'MALFORMED', 'NEC-01', '', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM', 31000);
        CreateSetupCopySelector(FromPeriodNo, 'MALFORMED', 32000);
        CreateSupplBox(ToPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::"Occupation Codes";
        SupplementalBox.Description := 'Target typed customization';
        SupplementalBox.Modify(true);
        CreateSupplBox(ToPeriodNo, 'NEC', 'MALFORMED', 'NEC-01', 'HISTORICAL', CompanyName());
        CreateSetupCopySelector(ToPeriodNo, 'MALFORMED', 41000);

        // [WHEN] Setup copy is repeated.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Target choices and malformed historical rows survive, while no incompatible replacement is inserted.
        VerifyConflictingTargetSetupCopy(FromPeriodNo, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyReportsExistingMalformedTargetSelector()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Copy reports an existing dangling target selector without deleting or repairing historical setup.
        Initialize();

        // [GIVEN] Target period already contains historical dangling selector unrelated to source period's financial setup.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(ToPeriodNo, 'MISSING', 31000);

        // [WHEN] Ordinary financial setup is copied into target period.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Historical row stays unchanged and is explicitly reported for repair.
        StatementLine.Get(ToPeriodNo, 'NEC', 31000);
        Assert.AreEqual('MISSING', StatementLine."Supplemental Box No.", 'Do not delete or silently repair existing malformed target setup.');
        VerifySetupCopySummary(ToPeriodNo, 'MISSING', 'cannot be used for reporting in the target period and was not changed');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyPreservesExistingStatementLine()
    var
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] A target's customized statement identity is reported and never overwritten by a copied supplemental selector.
        Initialize();

        // [GIVEN] Source period has valid supplemental selector at position of target period's customized financial statement.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSupplBox(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
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

        // [WHEN] Source period's setup is copied into target period twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Target description, selector, sign, total and ordering are unchanged and conflict is scoped.
        VerifyOccupiedSetupStatement(StatementLine, ToPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopySkipsRejectedFormBoxDependentSetup()
    var
        FormBox: Record "IRS 1099 Form Box";
        Vendor: Record Vendor;
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Rejection of a financial identity also rejects its directly dependent vendor setup and adjustment.
        Initialize();

        // [GIVEN] Source period's Form Box has vendor setup and adjustment, while target period reserves that identity as supplemental.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        PrepareFormBox(FormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
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
        CreateSupplBox(ToPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());

        // [WHEN] Financial parent is rejected during copy.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] No dangling dependent is copied and its reason is reported without changing source amount.
        VerifySkippedFormBoxDependentSetup(FromPeriodNo, ToPeriodNo, Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('SetupCopyMessageHandler')]
    procedure SetupCopyAcrossCompaniesUsesTargetScope()
    var
        OtherCompany: Record Company;
        TempSelectedCompany: Record Company temporary;
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
        SupplBoxCount: Integer;
        StatementCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Cross-company repeated copy validates the target company's supported period independently of the current company's unsupported counterpart.
        Initialize();

        // [GIVEN] Current company has 2026 source period and 2025 target period, while target company has supported 2026 target period with custom parent minimum.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(ToPeriodNo);
        ReportingPeriod."Starting Date" := 20250101D;
        ReportingPeriod."Ending Date" := 20251231D;
        ReportingPeriod.Modify();
        CreateSupplBox(FromPeriodNo, 'NEC', 'CUSTOM', 'NEC-01', '', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'CUSTOM', 12500);
        OtherCompany.Name := CopyStr('IRS-ASTRA-COPY-' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateBoxSetupTestPeriodInCompany(ToPeriodNo, OtherCompany.Name);
        SetSetupCopyTargetMinimum(ToPeriodNo, OtherCompany.Name);
        CreateBoxSetupTestPeriodInCompany('UNRELATED', OtherCompany.Name);
        SetSetupCopyTargetMinimum('UNRELATED', OtherCompany.Name);
        TempSelectedCompany.Name := OtherCompany.Name;
        TempSelectedCompany.Insert();

        // [WHEN] Current company's source setup is copied to target company twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);

        // [THEN] Only target company receives one valid custom dependency and selector; source and current company's target period remain unchanged.
        VerifyCrossCompanySetupCopy(FromPeriodNo, ToPeriodNo, OtherCompany.Name);
        SupplementalBox.ChangeCompany(OtherCompany.Name);
        SupplementalBox.SetRange("Period No.", ToPeriodNo);
        SupplementalBox.SetRange("No.", 'CUSTOM');
        SupplBoxCount := SupplementalBox.Count();
        StatementLine.ChangeCompany(OtherCompany.Name);
        StatementLine.SetRange("Period No.", ToPeriodNo);
        StatementLine.SetRange("Supplemental Box No.", 'CUSTOM');
        StatementCount := StatementLine.Count();
        Commit();
        OtherCompany.Delete(true);
        DeleteBoxSetupTestPeriod(FromPeriodNo);
        DeleteBoxSetupTestPeriod(ToPeriodNo);
        Commit();
        Assert.AreEqual(1, SupplBoxCount, 'Repeated cross-company copying must not duplicate definitions.');
        Assert.AreEqual(1, StatementCount, 'Repeated cross-company copying must not duplicate selectors.');
    end;

    local procedure Initialize()
    begin
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        AnnualFixturePrepared := false;
        Clear(SetupCopySummary);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS Reporting Period Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");
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

    local procedure CreateBoxSetupTestPeriod(TargetCompany: Text) PeriodNo: Code[20]
    begin
        PeriodNo := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(PeriodNo));
        CreateBoxSetupTestPeriodInCompany(PeriodNo, TargetCompany);
    end;

    local procedure CreateBoxSetupTestPeriodInCompany(PeriodNo: Code[20]; TargetCompany: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
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
        FormBox.ChangeCompany(TargetCompany);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01');
        FormBox.Insert(true);
        PrepareFormBox(FormBox, PeriodNo, 'MISC', 'MISC-03');
        FormBox.Insert(true);
    end;

    local procedure CreateSetupCopyPeriod() PeriodNo: Code[20]
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        FormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2000;
        FormBox.Modify();
        FormBox.Get(PeriodNo, 'MISC', 'MISC-03');
        FormBox."Minimum Reportable Amount" := 2000;
        FormBox.Modify();
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

    local procedure CreateStoredDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; PeriodNo: Code[20]; DocumentStatus: Enum "IRS 1099 Form Doc. Status"; MinimumAmount: Decimal)
    var
        Vendor: Record Vendor;
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        IRS1099FormDocHeader.Init();
        IRS1099FormDocHeader."Period No." := PeriodNo;
        IRS1099FormDocHeader."Form No." := 'NEC';
        IRS1099FormDocHeader."Vendor No." := Vendor."No.";
        IRS1099FormDocHeader.Insert(true);
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Period No." := PeriodNo;
        IRS1099FormDocLine."Vendor No." := Vendor."No.";
        IRS1099FormDocLine."Form No." := 'NEC';
        IRS1099FormDocLine."Line No." := 10000;
        IRS1099FormDocLine."Form Box No." := 'NEC-01';
        IRS1099FormDocLine."Minimum Reportable Amount" := MinimumAmount;
        IRS1099FormDocLine.Validate(Amount, 1500);
        IRS1099FormDocLine.Insert();
        IRS1099FormDocHeader.Status := DocumentStatus;
        IRS1099FormDocHeader.Modify();
    end;

    local procedure CreateSupplBox(PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20]; ParentFormBoxNo: Code[20]; ElementName: Text[100]; TargetCompany: Text)
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        SupplementalBox.ChangeCompany(TargetCompany);
        SupplementalBox."Period No." := PeriodNo;
        SupplementalBox."Form No." := FormNo;
        SupplementalBox."No." := BoxNo;
        SupplementalBox.Description := 'Original supplemental meaning';
        SupplementalBox."Parent Form Box No." := ParentFormBoxNo;
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::Amount;
        SupplementalBox."XML Element Name" := ElementName;
        SupplementalBox.Insert();
    end;

    local procedure DeleteBoxSetupTestPeriod(PeriodNo: Code[20])
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.Get(PeriodNo);
        ReportingPeriod.Delete(true);
    end;

    local procedure PrepareFormBox(var FormBox: Record "IRS 1099 Form Box"; PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20])
    begin
        FormBox.Init();
        FormBox."Period No." := PeriodNo;
        FormBox."Form No." := FormNo;
        FormBox."No." := BoxNo;
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

    local procedure SetInstruction(PeriodNo: Code[20]; FormNo: Code[20]; LineNo: Integer; Header: Text; Description: Text)
    var
        Instruction: Record "IRS 1099 Form Instruction";
    begin
        Instruction.Get(PeriodNo, FormNo, LineNo);
        Instruction.Header := CopyStr(Header, 1, MaxStrLen(Instruction.Header));
        Instruction.Description := CopyStr(Description, 1, MaxStrLen(Instruction.Description));
        Instruction.Modify();
    end;

    local procedure SetSetupCopyTargetMinimum(PeriodNo: Code[20]; TargetCompany: Text)
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.ChangeCompany(TargetCompany);
        FormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 777;
        FormBox.Modify();
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

    local procedure VerifyConflictingTargetSetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
    begin
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual(SupplementalBox."Value Type"::"Occupation Codes", SupplementalBox."Value Type", 'Do not overwrite a target type to force compatibility.');
        Assert.AreEqual('Target typed customization', SupplementalBox.Description, 'Preserve target descriptions.');
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'MALFORMED');
        Assert.AreEqual('HISTORICAL', SupplementalBox."XML Element Name", 'Do not silently repair malformed historical target setup.');
        Assert.IsFalse(StatementLine.Get(ToPeriodNo, 'NEC', 31000), 'An incompatible target definition must not acquire the source selector.');
        Assert.IsFalse(StatementLine.Get(ToPeriodNo, 'NEC', 32000), 'A malformed target definition must not acquire another selector.');
        StatementLine.Get(ToPeriodNo, 'NEC', 41000);
        Assert.AreEqual('MALFORMED', StatementLine."Supplemental Box No.", 'Preserve existing malformed target data for explicit resolution.');
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual(SupplementalBox."Value Type"::Amount, SupplementalBox."Value Type", 'Preserve the source definition type.');
        VerifySetupCopySummary(ToPeriodNo, 'CUSTOM', 'different parent form box, value type, or XML element');
    end;

    local procedure VerifyCrossCompanySetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; TargetCompany: Text)
    var
        ReportingPeriod: Record "IRS Reporting Period";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FormBox: Record "IRS 1099 Form Box";
    begin
        SupplementalBox.ChangeCompany(TargetCompany);
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('NEC-01', SupplementalBox."Parent Form Box No.", 'The custom definition must use B''s valid parent.');
        StatementLine.ChangeCompany(TargetCompany);
        StatementLine.Get(ToPeriodNo, 'NEC', 12500);
        Assert.AreEqual('CUSTOM', StatementLine."Supplemental Box No.", 'Copy the custom selector only in B.');
        FormBox.ChangeCompany(TargetCompany);
        FormBox.Get(ToPeriodNo, 'NEC', 'NEC-01');
        Assert.AreEqual(777, FormBox."Minimum Reportable Amount", 'Preserve B''s financial customization.');
        FormBox.Get('UNRELATED', 'NEC', 'NEC-01');
        Assert.AreEqual(777, FormBox."Minimum Reportable Amount", 'Do not change unrelated B periods.');
        SupplementalBox.SetRange("Period No.", 'UNRELATED');
        Assert.RecordIsEmpty(SupplementalBox);
        SupplementalBox.Reset();
        SupplementalBox.ChangeCompany(CompanyName());
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('Original supplemental meaning', SupplementalBox.Description, 'Preserve A''s source definition.');
        SupplementalBox.SetRange("Period No.", ToPeriodNo);
        Assert.RecordIsEmpty(SupplementalBox);
        StatementLine.ChangeCompany(CompanyName());
        StatementLine.SetRange("Period No.", ToPeriodNo);
        Assert.RecordIsEmpty(StatementLine);
        ReportingPeriod.Get(ToPeriodNo);
        Assert.AreEqual(20250101D, ReportingPeriod."Starting Date", 'Do not change A''s target-year scope.');
    end;

    local procedure VerifyCustomSetupCopy(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; TargetCompany: Text)
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FormBox: Record "IRS 1099 Form Box";
    begin
        SupplementalBox.ChangeCompany(TargetCompany);
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'CUSTOM-AMOUNT');
        Assert.AreEqual('CUSTOM-PARENT', SupplementalBox."Parent Form Box No.", 'Copy the custom financial parent before its definition.');
        Assert.AreEqual(SupplementalBox."Value Type"::Amount, SupplementalBox."Value Type", 'Preserve the amount type.');
        SupplementalBox.Get(ToPeriodNo, 'NEC', 'CUSTOM-CODES');
        Assert.AreEqual(SupplementalBox."Value Type"::"Occupation Codes", SupplementalBox."Value Type", 'Preserve typed occupation-code definitions.');
        Assert.AreEqual('', SupplementalBox."XML Element Name", 'A valid custom definition must remain unmapped.');
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
        FormBox.ChangeCompany(TargetCompany);
        FormBox.Get(ToPeriodNo, 'NEC', 'CUSTOM-PARENT');
        Assert.AreEqual('Source custom financial parent', FormBox.Description, 'Copy the custom parent without repurposing it.');
        SupplementalBox.ChangeCompany(CompanyName());
        SupplementalBox.Get(FromPeriodNo, 'NEC', 'CUSTOM-AMOUNT');
        Assert.AreEqual('CUSTOM-PARENT', SupplementalBox."Parent Form Box No.", 'Do not retarget source definitions.');
        StatementLine.Reset();
        StatementLine.ChangeCompany(CompanyName());
        StatementLine.Get(FromPeriodNo, 'NEC', 12500);
        Assert.AreEqual('Source customized CUSTOM-AMOUNT', StatementLine.Description, 'Do not edit source statements.');
    end;

    local procedure VerifyExistingFormBoxNumberConflict(FormBox: Record "IRS 1099 Form Box"; SupplementalBox: Record "IRS 1099 Suppl. Box"; Details: Text)
    begin
        Assert.AreEqual('Historical financial meaning', FormBox.Description, 'Do not repurpose historical financial meaning.');
        Assert.AreEqual(777, FormBox."Minimum Reportable Amount", 'Do not alter historical financial setup.');
        Assert.AreEqual('Original supplemental meaning', SupplementalBox.Description, 'Do not repurpose the existing supplemental definition.');
        Assert.AreEqual('NEC-01', SupplementalBox."Parent Form Box No.", 'Do not retarget the existing supplemental parent.');
        VerifyFormBoxConflictDetails(Details, FormBox."Period No.");
    end;

    local procedure VerifyFormBoxConflictDetails(Details: Text; PeriodNo: Code[20])
    begin
        Assert.IsTrue(Details.Contains('already exists as a supplemental box'), 'The identifier conflict must be reported.');
        Assert.IsTrue(Details.Contains(PeriodNo), 'The conflict must identify its period.');
        Assert.IsTrue(Details.Contains(CompanyName()), 'The conflict must identify its company.');
        Assert.IsTrue(Details.Contains('form NEC'), 'The conflict must identify its form.');
    end;

    local procedure VerifyFormBoxCopyConflict(FromPeriodNo: Code[20]; ToPeriodNo: Code[20])
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.Get(FromPeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Source financial meaning', FormBox.Description, 'The copy must preserve the source.');
        VerifyFormBoxConflictDetails(SetupCopySummary, ToPeriodNo);
        Assert.IsTrue(SetupCopySummary.Contains('NEC-01B'), 'Copy summary must identify the skipped box.');
    end;

    local procedure VerifyMinimum(PeriodNo: Code[20]; FormNo: Code[20]; BoxNo: Code[20]; ExpectedMinimum: Decimal)
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        FormBox.Get(PeriodNo, FormNo, BoxNo);
        Assert.AreEqual(ExpectedMinimum, FormBox."Minimum Reportable Amount", PeriodNo + '/' + BoxNo);
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

    local procedure VerifyOverrides(PeriodNo: Code[20]; TestVersion: Enum "XML Schema Version IRIS"; LiveVersion: Enum "XML Schema Version IRIS")
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.Get(PeriodNo);
        Assert.AreEqual(TestVersion, ReportingPeriod."IRIS XML Schema Version Test", 'Do not inherit or overwrite TEST overrides.');
        Assert.AreEqual(LiveVersion, ReportingPeriod."IRIS XML Schema Version Live", 'Do not inherit or overwrite live overrides.');
    end;

    local procedure VerifyRejectedFormBoxNumber(PeriodNo: Code[20]; TargetCompany: Text)
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        FormBox.ChangeCompany(TargetCompany);
        SupplementalBox.ChangeCompany(TargetCompany);
        Assert.IsFalse(FormBox.Get(PeriodNo, 'NEC', 'NEC-01B'), 'A supplemental identity must not become a financial destination.');
        SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('Original supplemental meaning', SupplementalBox.Description, 'The existing definition changed.');
        Assert.AreEqual('NEC-01', SupplementalBox."Parent Form Box No.", 'The supplemental parent changed.');
        Assert.AreEqual('CashTipsAmt', SupplementalBox."XML Element Name", 'The supplemental mapping changed.');
        Assert.AreEqual(SupplementalBox."Value Type"::Amount, SupplementalBox."Value Type", 'The supplemental value type changed.');
    end;

    local procedure VerifyRejectedFormBoxRenames(PeriodNo: Code[20]; OtherPeriodNo: Code[20])
    var
        FormBox: Record "IRS 1099 Form Box";
    begin
        VerifyRejectedFormBoxNumber(PeriodNo, CompanyName());
        Assert.IsTrue(FormBox.Get(PeriodNo, 'NEC', 'CUSTOM'), 'Box-number rename lost the original form box.');
        Assert.IsTrue(FormBox.Get(PeriodNo, 'MISC', 'NEC-01B'), 'Form rename lost the original form box.');
        Assert.IsTrue(FormBox.Get(OtherPeriodNo, 'NEC', 'NEC-01B'), 'Period rename lost the original form box.');
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

    local procedure VerifyRejectedSupplBoxNumber(PeriodNo: Code[20])
    var
        FormBox: Record "IRS 1099 Form Box";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        FormBox.Get(PeriodNo, 'NEC', 'CUSTOM');
        Assert.AreEqual('Financial meaning', FormBox.Description, 'The financial meaning changed.');
        Assert.IsFalse(SupplementalBox.Get(PeriodNo, 'NEC', 'CUSTOM'), 'A rejected supplemental definition must not be stored.');
    end;

    local procedure VerifySetupCopySummary(PeriodNo: Code[20]; SetupDescription: Text; Reason: Text)
    begin
        Assert.IsTrue(SetupCopySummary.Contains(PeriodNo), 'The summary must identify the target period.');
        Assert.IsTrue(SetupCopySummary.Contains(SetupDescription), 'The summary must identify the omitted or preserved setup identity.');
        Assert.IsTrue(SetupCopySummary.Contains(Reason), 'The summary must explain the dependency or customization conflict.');
        Assert.IsTrue(SetupCopySummary.Contains(CompanyName()), 'The summary must identify the target company.');
    end;

    local procedure VerifySkippedFormBoxDependentSetup(FromPeriodNo: Code[20]; ToPeriodNo: Code[20]; VendorNo: Code[20])
    var
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        Adjustment: Record "IRS 1099 Vendor Form Box Adj.";
    begin
        VerifyRejectedFormBoxNumber(ToPeriodNo, CompanyName());
        Assert.IsFalse(VendorSetup.Get(ToPeriodNo, VendorNo), 'Do not copy vendor setup whose financial parent was rejected.');
        Assert.IsFalse(Adjustment.Get(ToPeriodNo, VendorNo, 'NEC', 'NEC-01B'), 'Do not copy an adjustment whose financial parent was rejected.');
        VendorSetup.Get(FromPeriodNo, VendorNo);
        Assert.AreEqual('NEC-01B', VendorSetup."Form Box No.", 'Do not alter source vendor setup.');
        Adjustment.Get(FromPeriodNo, VendorNo, 'NEC', 'NEC-01B');
        Assert.AreEqual(1000, Adjustment.Amount, 'Do not reset the source adjustment amount.');
        VerifySetupCopySummary(ToPeriodNo, VendorNo, 'Form box NEC-01B does not exist');
    end;

    local procedure VerifyStandardSupplBoxSetup(PeriodNo: Code[20])
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
    begin
        SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01B');
        Assert.AreEqual('NEC-01', SupplementalBox."Parent Form Box No.", 'Cash tips use compensation.');
        Assert.AreEqual(SupplementalBox."Value Type"::Amount, SupplementalBox."Value Type", 'Cash tips are amounts.');
        Assert.AreEqual('CashTipsAmt', SupplementalBox."XML Element Name", 'Use the shared supported mapping.');
        SupplementalBox.Get(PeriodNo, 'NEC', 'NEC-01C');
        Assert.AreEqual(SupplementalBox."Value Type"::"Occupation Codes", SupplementalBox."Value Type", 'Occupation codes remain typed.');
        SupplementalBox.Get(PeriodNo, 'MISC', 'MISC-14');
        Assert.AreEqual('MISC-03', SupplementalBox."Parent Form Box No.", '2026 overtime uses other income, not old parachute payments.');
        Assert.AreEqual('OvertimeCompensationAmt', SupplementalBox."XML Element Name", '2026 MISC-14 is overtime.');
    end;

    local procedure VerifyUnsupportedSetupCopy(TargetPeriodNo: Code[20])
    var
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        StatementLine: Record "IRS 1099 Form Statement Line";
        FormBox: Record "IRS 1099 Form Box";
    begin
        SupplementalBox.SetRange("Period No.", TargetPeriodNo);
        Assert.RecordIsEmpty(SupplementalBox);
        StatementLine.SetRange("Period No.", TargetPeriodNo);
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordIsEmpty(StatementLine);
        StatementLine.Reset();
        StatementLine.Get(TargetPeriodNo, 'NEC', 10000);
        Assert.AreEqual(StatementLine."Value Source"::"Document Line", StatementLine."Value Source", 'Ordinary NEC statements must remain financial.');
        StatementLine.Get(TargetPeriodNo, 'MISC', 10000);
        Assert.AreEqual(StatementLine."Value Source"::"Document Line", StatementLine."Value Source", 'Ordinary MISC statements must remain financial.');
        Assert.IsTrue(FormBox.Get(TargetPeriodNo, 'MISC', 'MISC-03'), 'Ordinary financial setup must still copy.');
        SupplementalBox.SetRange("Period No.", '2026');
        Assert.RecordCount(SupplementalBox, 6);
        StatementLine.SetRange("Period No.", '2026');
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        Assert.RecordCount(StatementLine, 6);
        VerifySetupCopySummary(TargetPeriodNo, 'MISC-13A', 'Supplemental boxes are supported for tax years 2026 and later');
        Assert.IsTrue(SetupCopySummary.Contains('2025'), 'The omission must identify the unsupported target year.');
    end;

    local procedure VerifyValidFormBoxRelations(VendorSetup: Record "IRS 1099 Vendor Form Box Setup"; JournalLine: Record "Gen. Journal Line")
    begin
        Assert.AreEqual('MISC', VendorSetup."Form No.", 'Vendor setup must keep its valid financial form.');
        Assert.AreEqual('NEC-01B', VendorSetup."Form Box No.", 'Vendor setup must keep its valid financial destination.');
        Assert.AreEqual('NEC-01B', JournalLine."IRS 1099 Form Box No.", 'A different period must remain a valid journal destination.');
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

    [MessageHandler]
    procedure SetupCopyMessageHandler(Message: Text)
    begin
        SetupCopySummary := Message;
    end;

    [MessageHandler]
    procedure CopySetupMessageHandler(Message: Text[1024])
    begin
        // Handle the setup copied message
    end;

}
