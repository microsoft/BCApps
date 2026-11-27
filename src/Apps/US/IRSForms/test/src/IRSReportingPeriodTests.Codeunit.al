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
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        IsInitialized: Boolean;
        AnnualTestSetupPrepared: Boolean;
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
        IRSReportingPeriod: Record "IRS Reporting Period";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        FromStartDate: Date;
        FromEndDate: Date;
    begin
        // [SCENARIO 623874] When copying reporting period setup with vendor form box adjustments, the Amount field is reset to 0 in the target period
        Initialize();

        // [GIVEN] Source annual reporting period with vendor form box adjustment "V" for form "MISC" box "01" with Amount = 1000
        FromPeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(Date2DMY(WorkDate(), 3));
        IRSReportingPeriod.Get(FromPeriodNo);
        FromStartDate := IRSReportingPeriod."Starting Date";
        FromEndDate := IRSReportingPeriod."Ending Date";
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(FromStartDate, FromEndDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(FromStartDate, FromEndDate, FormNo);
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBoxForNonPosting(FromStartDate, FromEndDate, FormNo, FormBoxNo);
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryIRS1099FormBox.AddAdjustmentAmountForVendor(FromStartDate, FromEndDate, VendorNo, FormNo, FormBoxNo, Amount);

        // [GIVEN] A later annual reporting period exists
        ToPeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(Date2DMY(FromStartDate, 3) + 1);

        // [WHEN] Copy setup from the source period to the target period
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Vendor form box adjustment is copied to the target period with Amount = 0
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
        // [SCENARIO 653992] Standard 2026 setup raises the selected reporting minimums and adds six supplemental boxes without changing 2025 setup.
        Initialize();

        // [GIVEN] Neither 2025 nor 2026 has annual setup.
        SupplementalLineCount := SupplementalLine.Count();
        CreateAnnualSetup(2025);
        CreateAnnualSetup(2026);

        // [WHEN] Create setup for both years and read their reporting minimums, supplemental boxes and instructions.

        // [THEN] 2025 keeps its old minimums and instructions; 2026 uses new minimums and six supplemental boxes, without creating document values.
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
        // [SCENARIO 653992] Standard setup for 2027 includes the new reporting minimums, supplemental boxes and recipient instructions.
        Initialize();

        // [GIVEN] Tax year 2027 has no annual setup.

        // [WHEN] Create standard annual setup for 2027.
        CreateAnnualSetup(2027);

        SupplementalBox.SetRange("Period No.", '2027');

        // [THEN] Six supplemental boxes are created, new reporting minimums are used, and recipient instructions include supplemental boxes.
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
        // [SCENARIO 653992] Copying 2025 setup into 2026 applies 2026 defaults while preserving target customizations on a repeat copy.
        Initialize();

        // [GIVEN] 2025 setup has explicit Test and Live schema versions; empty 2026 period has no overrides.
        CreateAnnualSetup(2025);
        ReportingPeriod.Get('2025');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"5.0.7";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"2.0.3";
        ReportingPeriod.Modify();
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2026', 20260101D, 20261231D);

        // [WHEN] Copy setup from 2025 into 2026.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] 2025 stays unchanged; 2026 receives its own minimums, labels and supplemental rows, but not source's schema overrides.
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

        // [GIVEN] Set explicit Test and Live schema overrides and custom compensation minimum of 2500 on 2026.
        ReportingPeriod.Get('2026');
        ReportingPeriod."IRIS XML Schema Version Test" := ReportingPeriod."IRIS XML Schema Version Test"::"2.0.3";
        ReportingPeriod."IRIS XML Schema Version Live" := ReportingPeriod."IRIS XML Schema Version Live"::"5.0.7";
        ReportingPeriod.Modify();
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 2500;
        FormBox.Modify();

        // [WHEN] Copy 2025 setup into 2026 again.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2025', '2026');

        // [THEN] 2026 keeps its schema overrides and minimum 2500, and still has exactly six supplemental boxes.
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
        // [SCENARIO 653992] Updating annual setup restores missing defaults and old standard minimums but keeps custom values and reports conflicts.
        Initialize();

        // [GIVEN] 2026 setup has missing rent box, old direct-sales minimum, custom compensation minimum 2500, custom labels and unsupported overtime XML element.
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

        // [WHEN] Run annual setup update twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Missing and old defaults are updated; custom minimums and labels stay unchanged, and result identifies custom minimum and unsupported overtime mapping.
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
        // [SCENARIO 653992] Updating 2025 setup into 2026 does not change an old MISC-14 income box into supplemental overtime.
        Initialize();

        // [GIVEN] 2026 contains old MISC-14 income box labelled Historical parachute payments instead of new overtime box.
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

        // [WHEN] Run consecutive-year update and then update annual setup.
        LibraryIRSReportingPeriod.UpdateDataForNewTaxYear('2025', '2026');
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Old MISC-14 box keeps its meaning; no supplemental MISC-14 is created, and conflicting box number is reported.
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
        // [SCENARIO 653992] An income form box cannot be deleted while supplemental boxes refer to it.
        Initialize();

        // [GIVEN] 2026 setup has cash-tip box NEC-01B linked to compensation box NEC-01.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'NEC', 'NEC-01');

        // [WHEN] Try to delete NEC-01.
        asserterror FormBox.Delete(true);

        // [THEN] Error identifies dependent cash-tip box NEC-01B.
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
        // [SCENARIO 653992] An income form box cannot be renamed while supplemental boxes refer to it.
        Initialize();

        // [GIVEN] 2026 MISC cash-tip box MISC-13A refers to Other Income box MISC-03.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'MISC', 'MISC-03');

        // [WHEN] Try to rename MISC-03 to RENAMED.
        asserterror FormBox.Rename('2026', 'MISC', 'RENAMED');

        // [THEN] Error identifies dependent cash-tip box MISC-13A.
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
        // [SCENARIO 653992] Deleting a form or unused period also deletes its contained statement rows and supplemental setup.
        Initialize();

        // [GIVEN] 2026 period has NEC and MISC income boxes, supplemental boxes and statement rows, but no documents.
        CreateAnnualSetup(2026);

        // [WHEN] Delete NEC form.
        Form.Get('2026', 'NEC');
        Form.Delete(true);

        // [THEN] All NEC boxes and statement rows are deleted, while three MISC supplemental boxes remain.
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

        // [WHEN] Delete remaining 2026 reporting period.
        ReportingPeriod.Get('2026');
        ReportingPeriod.Delete(true);

        // [THEN] Remaining MISC supplemental boxes, statement rows and income boxes are also deleted.
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
        // [SCENARIO 653992] Annual setup updates report only Open documents with old minimums and do not rewrite saved document or transmission data.
        Initialize();

        // [GIVEN] 2026 has Open and Submitted documents with minimum 600 and another Open document with minimum 2000; 2025 has its own document.
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

        // [WHEN] Run 2026 annual setup update twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Only Open 2026 document with minimum 600 is listed; saved minimums, inclusion, tips, submission data and historical XML remain unchanged.
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
        // [SCENARIO 653992] Annual setup updates report a changed supplemental parent without changing the saved income-box link.
        Initialize();

        // [GIVEN] Saved cash-tip line refers to NEC-01, but imported setup for its box now refers to NEC-03.
        CreateAnnualSetup(2026);
        CreateStoredDocument(IRS1099FormDocHeader, '2026', IRS1099FormDocHeader.Status::Open, 600);
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", 'NEC-01B');
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Insert(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        SupplementalBox."Parent Form Box No." := 'NEC-03';
        SupplementalBox.Modify();

        // [WHEN] Update annual setup.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Conflict is reported; setup still refers to NEC-03, while saved line retains NEC-01 and tips 100.
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
        // [SCENARIO 653992] Deleting a reporting period with a Submitted document fails before any setup is removed.
        Initialize();

        // [GIVEN] Reporting period contains Submitted document and annual setup.
        CreateAnnualSetup(2026);
        CreateStoredDocument(IRS1099FormDocHeader, '2026', IRS1099FormDocHeader.Status::Submitted, 600);
        ReportingPeriod.Get('2026');

        // [WHEN] Try to delete period.
        asserterror ReportingPeriod.Delete(true);

        // [THEN] Error reports document use, and period's setup remains intact.
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
        // [SCENARIO 653992] Updating another company's annual setup uses that company's period and boxes, not the current company's setup.
        Initialize();

        // [GIVEN] Company C1 has custom 2026 minimum 777; test company C2 has empty 2027 period that does not exist in C1.
        CreateAnnualSetup(2026);
        FormBox.Get('2026', 'NEC', 'NEC-01');
        FormBox."Minimum Reportable Amount" := 777;
        FormBox.Modify();
        OtherCompany.Name := CopyStr('IRS Annual ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        ReportingPeriod.ChangeCompany(OtherCompany.Name);
        ReportingPeriod."No." := '2027';
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Insert();

        // [WHEN] Update C2's 2027 annual setup twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2027', OtherCompany.Name);
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2027', OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        FormBox.Get('2027', 'NEC', 'NEC-01');
        OtherMinimum := FormBox."Minimum Reportable Amount";
        SupplementalBox.ChangeCompany(OtherCompany.Name);
        SupplementalBox.SetRange("Period No.", '2027');
        SupplBoxCount := SupplementalBox.Count();
        StatementLine.ChangeCompany(OtherCompany.Name);
        StatementLine.SetRange("Period No.", '2027');
        StatementLine.SetRange("Value Source", StatementLine."Value Source"::"Supplemental Line");
        StatementCount := StatementLine.Count();
        Commit();
        OtherCompany.Delete(true);

        // [THEN] Only C2 receives minimum 2000 and six unique supplemental boxes and statement rows; C1 keeps minimum 777.
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
        // [SCENARIO 653992] A supplemental box used by a statement row cannot be deleted, even without document values.
        Initialize();

        // [GIVEN] Standard statement row selects cash-tip box NEC-01B.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] Try to delete NEC-01B from setup.
        asserterror SupplementalBox.Delete(true);

        // [THEN] Error identifies statement row that uses NEC-01B.
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
        // [SCENARIO 653992] A supplemental box used by a statement row cannot be renamed.
        Initialize();

        // [GIVEN] Standard statement row selects occupation-code box NEC-01C.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01C');

        // [WHEN] Try to rename NEC-01C to RENAMED.
        asserterror SupplementalBox.Rename('2026', 'NEC', 'RENAMED');

        // [THEN] Error identifies statement row that uses NEC-01C.
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
        // [SCENARIO 653992] A supplemental box used by a statement row cannot be changed to an incompatible income box.
        Initialize();

        // [GIVEN] Standard statement row selects overtime box NEC-01D.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01D');
        SupplementalBox."Parent Form Box No." := 'NEC-03';

        // [WHEN] Try to save NEC-03 as overtime box's Parent Form Box No.
        asserterror SupplementalBox.Modify(true);

        // [THEN] Error identifies statement row that would be broken by change.
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
        // [SCENARIO 653992] A statement row using income-line filters does not prevent deletion of its unused supplemental box selection.
        Initialize();

        // [GIVEN] Statement row retains supplemental box NEC-01B but its Value Source is Document Line and its filter selects NEC-01.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine.Validate("Value Source", StatementLine."Value Source"::"Document Line");
        StatementLine.SetFormBoxFilter('NEC-01');
        StatementLine.Modify(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');

        // [WHEN] Delete otherwise unused NEC-01B supplemental box.
        SupplementalBox.Delete(true);

        // [THEN] Deletion succeeds, and statement row keeps its saved supplemental-box number without treating it as active reference.
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
        // [SCENARIO 653992] Repeated annual updates preserve customized statement rows and create missing standard rows only once.
        Initialize();

        // [GIVEN] 2026 statement rows have changed boxes, sources, labels and positions, and one standard MISC row is missing.
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

        // [WHEN] Run annual setup update twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Custom row settings and order remain, missing defaults are added once, and result lists customized rows.
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
        // [SCENARIO 653992] An annual update does not overwrite a custom statement row at a standard line number.
        Initialize();

        // [GIVEN] Standard cash-tip statement position contains row named CUSTOM with description My row.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);
        StatementLine."Row No." := 'CUSTOM';
        StatementLine.Description := 'My row';
        StatementLine.Modify(true);

        // [WHEN] Update annual setup.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Custom row is unchanged, and result reports that standard cash-tip row could not be inserted.
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
        // [SCENARIO 653992] A NEC statement row cannot select a MISC supplemental box.
        Initialize();

        // [GIVEN] Statement row belongs to 2026 NEC form.
        CreateAnnualSetup(2026);
        StatementLine.Get('2026', 'NEC', 12500);

        // [WHEN] Try to select supplemental box MISC-13A.
        asserterror StatementLine.Validate("Supplemental Box No.", 'MISC-13A');

        // [THEN] Lookup rejects box because it does not belong to row's period and form.
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
        PeriodNo: Code[20];
        InstructionCount: Integer;
        Details: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] The first annual update creates forms and instructions together, and a repeat update creates no duplicates.
        Initialize();

        // [GIVEN] Unused annual reporting period has no forms or recipient instructions.
        PeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(2026);
        ReportingPeriod.Get(PeriodNo);

        // [WHEN] Run annual setup update, then repeat it.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(ReportingPeriod."No.", CompanyName());

        // [THEN] First update creates correct instructions without conflicts, and second leaves their count unchanged.
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
        // [SCENARIO 653992] Annual updates correct old standard 2025 instructions without changing historical 2024 instructions.
        Initialize();

        // [GIVEN] 2025 has old NEC Box 3 and MISC Box 14 instructions; historical 2024 period has copy of old NEC text.
        CreateAnnualSetup(2025);
        SetInstruction('2025', 'NEC', 7, 'Box 3.', 'Reserved for future use.');
        SetInstruction('2025', 'MISC', 18, 'Box 14.', 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.');
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('HISTORY2024', 20240101D, 20241231D);
        LibraryIRS1099FormBox.CreateSpecificFormInReportingPeriod(20240101D, 20241231D, 'NEC');
        Instruction.Get('2025', 'NEC', 7);
        Instruction."Period No." := 'HISTORY2024';
        Instruction.Insert();

        // [WHEN] Update both periods, repeating 2025 update.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2025', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2025', CompanyName());
        LibraryIRSReportingPeriod.UpdateAnnualSetup('HISTORY2024', CompanyName());

        // [THEN] 2025 receives corrected instructions without conflicts or duplicates, while historical 2024 text stays unchanged.
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
        // [SCENARIO 653992] Annual updates preserve custom and moved instructions while restoring missing standard instructions.
        Initialize();

        // [GIVEN] 2026 has custom NEC and FATCA guidance, moved NEC instruction and missing MISC cash-tip instruction.
        CreateAnnualSetup(2026);
        SetInstruction('2026', 'NEC', 7, 'Box 3.', 'Custom parachute guidance');
        SetInstruction('2026', 'MISC', 17, 'My FATCA guidance', 'Custom account reporting');
        Instruction.Get('2026', 'NEC', 12);
        Instruction.Delete();
        Instruction."Line No." := 1200;
        Instruction.Insert();
        Instruction.Get('2026', 'MISC', 23);
        Instruction.Delete();

        // [WHEN] Run annual setup update twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Custom text and positions stay unchanged, missing instruction is restored, and customized or moved lines are listed for review.
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
        // [SCENARIO 653992] Annual updates replace old standard supplemental summaries with official recipient instructions.
        Initialize();

        // [GIVEN] 2026 setup contains previous standard tips, occupation-code and overtime summaries for NEC and MISC.
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

        // [WHEN] Run annual setup update, then repeat it.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());

        // [THEN] Summaries become official box-specific instructions without conflicts, and repeated update needs no further changes.
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
        // [SCENARIO 653992] The hidden schema-version field is unavailable through TestPage in both sandbox and production.
        Initialize();

        // [GIVEN] Environment is set to sandbox.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);

        // [WHEN] Open IRS Reporting Periods without personalizing page.
        ReportingPeriods.OpenEdit();

        // [THEN] Editing schema-version control fails because hidden control is not exposed to TestPage.
        asserterror ReportingPeriods.IRISXmlSchemaVersion.SetValue("XML Schema Version IRIS"::"5.0.7");
        Assert.ExpectedError('is not found on the page');
        ReportingPeriods.Close();

        // [WHEN] Open same page with environment set to production.
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        ReportingPeriods.OpenEdit();

        // [THEN] Hidden production schema-version control is also unavailable.
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
        // [SCENARIO 653992] IRS Forms - Read permissions allow viewing a reporting period in a sandbox.
        Initialize();

        // [GIVEN] Period 2099 has schema override, and simulated sandbox user has only IRS Forms - Read permissions.
        PrepareReadPermissionTestData(true, true);

        // [WHEN] Open IRS Reporting Periods in view mode and navigate to 2099.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] Period 2099 is displayed without execute-permission error.
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
        // [SCENARIO 653992] IRS Forms - Read permissions allow viewing a reporting period in production.
        Initialize();

        // [GIVEN] Period 2099 has schema override, and simulated production user has only IRS Forms - Read permissions.
        PrepareReadPermissionTestData(true, false);

        // [WHEN] Open IRS Reporting Periods in view mode and navigate to 2099.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] Period 2099 is displayed without granting extra execute permissions.
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
        // [SCENARIO 653992] IRS Forms - Read permissions allow viewing a reporting period in an on-premises environment.
        Initialize();

        // [GIVEN] Period 2099 has schema override, and on-premises user has only IRS Forms - Read permissions.
        PrepareReadPermissionTestData(false, false);

        // [WHEN] Open IRS Reporting Periods in view mode and navigate to 2099.
        ReportingPeriods.OpenView();
        ReportingPeriods.GoToKey('2099');

        // [THEN] Period 2099 is displayed without simulating SaaS or granting extra execute permissions.
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
        // [SCENARIO 653992] IRS Forms - Edit permissions allow saving independent Test and Live schema overrides for an unverified year.
        Initialize();

        // [GIVEN] Period 2099 is accessed with only IRS Forms - Edit permissions.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Edit');
        ReportingPeriod.Get('2099');
        CanWrite := ReportingPeriod.WritePermission();

        // [WHEN] Validate and save Test schema 5.0.7 and Live schema 2.0.3.
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");
        ReportingPeriod.Validate("IRIS XML Schema Version Live", "XML Schema Version IRIS"::"2.0.3");
        ReportingPeriod.Modify(true);
        ReportingPeriod.Get('2099');
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);

        // [THEN] Both values are saved independently without requiring 2099 to be verified filing year.
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
        // [SCENARIO 653992] IRS Forms - Read permissions block direct schema-override writes, not just page edits.
        Initialize();

        // [GIVEN] New uncommitted period 2099 is accessed with only IRS Forms - Read permissions.
        LibraryIRSReportingPeriod.CreateSpecificReportingPeriod('2099', 20990101D, 20991231D);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(true);
        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('IRS Forms - Read');
        ReportingPeriod.Get('2099');
        CanWrite := ReportingPeriod.WritePermission();
        ReportingPeriod.Validate("IRIS XML Schema Version Test", "XML Schema Version IRIS"::"5.0.7");

        // [WHEN] Try to save Test schema override directly through table.
        asserterror ReportingPeriod.Modify(true);

        // [THEN] Permission error blocks write, and neither override nor uncommitted period is saved.
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        Assert.ExpectedError('permission');
        Assert.ExpectedErrorCode('DB:ClientModifyDenied');
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        Assert.IsFalse(CanWrite, 'The normal read permission set must not grant setup writes.');
        Assert.IsFalse(ReportingPeriod.Get('2099'), 'The rejected operation must not save the override or the uncommitted reporting period.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FormBoxInsertRejectsSupplBoxNumber()
    var
        FormBox: Record "IRS 1099 Form Box";
        PeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An income form box cannot use a number already assigned to a supplemental box in the same period and form.
        Initialize();

        // [GIVEN] Period P has supplemental cash-tip box NEC-01B.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        Commit();
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');

        // [WHEN] Try to insert income form box with number NEC-01B in P's NEC form.
        asserterror FormBox.Insert(true);

        // [THEN] Error blocks duplicate number, leaving supplemental box unchanged.
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
        // [SCENARIO 653992] A supplemental box cannot use a number already assigned to an income form box.
        Initialize();

        // [GIVEN] Period P has income form box named CUSTOM.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'CUSTOM');
        FormBox.Description := 'Financial meaning';
        FormBox.Insert(true);
        Commit();
        SupplementalBox."Period No." := PeriodNo;
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."Parent Form Box No." := 'NEC-01';

        // [WHEN] Try to insert supplemental box named CUSTOM in same period and form.
        asserterror SupplementalBox.Insert(true);

        // [THEN] Insertion fails, and CUSTOM remains only income form box.
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
        // [SCENARIO 653992] Renaming an income box checks for supplemental-box conflicts when the number, form or period changes.
        Initialize();

        // [GIVEN] Three income boxes have different keys, and supplemental NEC-01B exists in period P's NEC form.
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

        // [WHEN] Rename only first box's number to match supplemental NEC-01B.
        FormBox.Get(PeriodNo, 'NEC', 'CUSTOM');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Number change is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Change only second box's form so its full key matches supplemental NEC-01B.
        FormBox.Get(PeriodNo, 'MISC', 'NEC-01B');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Form change is rejected.
        Assert.ExpectedError('already exists as a supplemental box');
        Assert.ExpectedErrorCode('Dialog');

        // [WHEN] Change only third box's period so its full key matches supplemental NEC-01B.
        FormBox.Get(OtherPeriodNo, 'NEC', 'NEC-01B');
        asserterror FormBox.Rename(PeriodNo, 'NEC', 'NEC-01B');

        // [THEN] Period change is rejected, and all original boxes and supplemental setup remain unchanged.
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
        // [SCENARIO 653992] Copying setup skips an income box whose target number is already used by a supplemental box.
        Initialize();

        // [GIVEN] Source period S has income box NEC-01B; target period T uses NEC-01B as supplemental box.
        FromPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        ToPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        PrepareFormBox(FormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Description := 'Source financial meaning';
        FormBox.Insert(true);
        CreateSupplBox(ToPeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());

        // [WHEN] Copy S's setup into T through Copy Period Setup.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] No conflicting income box is inserted, S stays unchanged, and copy summary identifies rejected target box.
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
        // [SCENARIO 653992] A supplemental-box number can still be used by income boxes in a different period or form.
        Initialize();

        // [GIVEN] Period P has supplemental NEC-01B; income boxes with that number exist in P's MISC form and another period's NEC form.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        OtherPeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'MISC', 'NEC-01B');
        FormBox.Insert(true);
        PrepareFormBox(FormBox, OtherPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
        LibraryIRS1099FormBox.CreateVendorForNonPosting(Vendor);

        // [WHEN] Select those income boxes in vendor setup and journal line.
        VendorSetup.Validate("Period No.", PeriodNo);
        VendorSetup.Validate("Vendor No.", Vendor."No.");
        VendorSetup.Validate("Form No.", 'MISC');
        VendorSetup.Validate("Form Box No.", 'NEC-01B');
        VendorSetup.Insert(true);
        JournalLine.Validate("IRS 1099 Reporting Period", OtherPeriodNo);
        JournalLine.Validate("IRS 1099 Form No.", 'NEC');
        JournalLine.Validate("IRS 1099 Form Box No.", 'NEC-01B');

        // [THEN] Both selections succeed because period and form distinguish them from supplemental box.
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
        // [SCENARIO 653992] Inserting an income box in another company checks that company's supplemental-box numbers.
        Initialize();

        // [GIVEN] Company C1 has supplemental number that is free in C2; C2 also has separate period where that number is used by supplemental box.
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

        // [WHEN] Insert income box at C2's conflicting number after successfully inserting it at C2's free number.
        asserterror FormBox.Insert(true);

        // [THEN] Only C2's actual conflict is rejected; C1's setup does not block C2's free number.
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
        // [SCENARIO 653992] Supplemental-box validation uses the target company's periods, income boxes and number conflicts.
        Initialize();

        // [GIVEN] Company C2 has period and income box absent from C1, plus separate period with income-box number conflict.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        OtherCompany.Name := CopyStr('IRS Supplemental ' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(OtherCompany.Name));
        Commit();
        OtherCompany.Insert(true);
        CreateBoxSetupTestPeriodInCompany(PeriodNo, OtherCompany.Name);
        TargetOnlyPeriodNo := CreateBoxSetupTestPeriod(OtherCompany.Name);
        FormBox.ChangeCompany(OtherCompany.Name);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);

        // [WHEN] Insert supplemental box in C2's target-only period, then try conflicting number in C2's other period.
        SupplementalBox.ChangeCompany(OtherCompany.Name);
        SupplementalBox."Period No." := TargetOnlyPeriodNo;
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'NEC-01B';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox."Value Type" := SupplementalBox."Value Type"::Amount;
        SupplementalBox."XML Element Name" := 'CashTipsAmt';
        SupplementalBox.Insert(true);

        // [THEN] First insertion succeeds, conflicting insertion fails, and C2's income box is unchanged.
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
        // [SCENARIO 653992] Annual updates report existing income/supplemental number conflicts without deleting either box.
        Initialize();

        // [GIVEN] Period P has income box and supplemental box both named NEC-01B, created by bypassing insert validation.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01B', 'NEC-01', 'CashTipsAmt', CompanyName());
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'NEC-01B');
        FormBox.Description := 'Historical financial meaning';
        FormBox."Minimum Reportable Amount" := 777;
        FormBox.Insert();

        // [WHEN] Run annual setup update twice.
        LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());

        // [THEN] Both boxes keep their values, and result identifies conflicting period, form and box number.
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
        // [SCENARIO 653992] Annual setup does not create a standard income box over a custom supplemental box with the same number.
        Initialize();

        // [GIVEN] Custom supplemental NEC-01 already exists and refers to income box CUSTOM.
        PeriodNo := CreateBoxSetupTestPeriod(CompanyName());
        FormBox.Get(PeriodNo, 'NEC', 'NEC-01');
        FormBox.Delete(true);
        PrepareFormBox(FormBox, PeriodNo, 'NEC', 'CUSTOM');
        FormBox.Insert(true);
        CreateSupplBox(PeriodNo, 'NEC', 'NEC-01', 'CUSTOM', '', CompanyName());

        // [WHEN] Update annual setup, which normally creates compensation box NEC-01.
        Details := LibraryIRSReportingPeriod.UpdateAnnualSetup(PeriodNo, CompanyName());

        // [THEN] Supplemental box keeps its CUSTOM parent, no income NEC-01 is inserted, and conflict is reported.
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
        // [SCENARIO 653992] Copying setup into a period with 2025 dates skips supplemental boxes but keeps income statement rows.
        Initialize();

        // [GIVEN] Source S has complete 2026 setup; target T has dates in 2025.
        CreateAnnualSetup(2026);
        TargetPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(TargetPeriodNo);
        ReportingPeriod."Starting Date" := 20250101D;
        ReportingPeriod."Ending Date" := 20251231D;
        ReportingPeriod.Modify();

        // [WHEN] Copy S's setup into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);

        // [THEN] Income setup is copied, supplemental setup is skipped, and summary explains that T's year does not support it.
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
        // [SCENARIO 653992] Copying setup into a period with 2027 dates keeps supplemental rows and preserves custom source and target labels.
        Initialize();

        // [GIVEN] Source S has custom cash-tip label; target T has dates in 2027.
        CreateAnnualSetup(2026);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01B');
        SupplementalBox.Description := 'Source customized cash tips';
        SupplementalBox.Modify(true);
        TargetPeriodNo := CreateSetupCopyPeriod();
        ReportingPeriod.Get(TargetPeriodNo);
        ReportingPeriod."Starting Date" := 20270101D;
        ReportingPeriod."Ending Date" := 20271231D;
        ReportingPeriod.Modify();

        // [WHEN] Copy S into T, customize T's cash-tip label, and repeat copy.
        LibraryIRSReportingPeriod.CopyPeriodSetup('2026', TargetPeriodNo);
        SupplementalBox.Get(TargetPeriodNo, 'NEC', 'NEC-01B');

        // [THEN] T first receives S's label, then keeps its own label; six supplemental boxes and rows and correct instructions remain, with S unchanged.
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
        // [SCENARIO 653992] Setup copy uses source descriptions for new boxes and preserves descriptions on existing target boxes.
        Initialize();

        // [GIVEN] Source S has custom tips and occupation-code descriptions; target T already has its own occupation-code description.

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

        // [WHEN] Copy S's setup into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        SupplementalBox.Get(ToPeriodNo, 'NEC', 'NEC-01B');

        // [THEN] T receives S's tips description but keeps its own occupation-code description; source descriptions are unchanged and no boxes are duplicated.
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
        // [SCENARIO 653992] Setup copy creates custom income and supplemental boxes before statement rows that use them.
        Initialize();

        // [GIVEN] Source S has custom amount and code boxes, custom income box and statement rows at standard line numbers.
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

        // [WHEN] Copy S's setup into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T receives valid custom boxes and their statement rows, keeping source labels and order without duplicate defaults.
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
        // [SCENARIO 653992] Setup copy skips a statement row whose supplemental box is missing.
        Initialize();

        // [GIVEN] Source S has statement row selecting nonexistent supplemental box MISSING.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(FromPeriodNo, 'MISSING', 31000);

        // [WHEN] Copy S's setup into target T.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T does not receive broken row, and summary identifies missing source box without modifying S.
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
        // [SCENARIO 653992] Setup copy skips a supplemental box with an unsupported XML element and the statement row that uses it.
        Initialize();

        // [GIVEN] Source S has custom box mapped to UnsupportedElement and statement row selecting that box.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSupplBox(FromPeriodNo, 'NEC', 'UNSUPPORTED-MAP', 'NEC-01', 'UnsupportedElement', CompanyName());
        CreateSetupCopySelector(FromPeriodNo, 'UNSUPPORTED-MAP', 31000);

        // [WHEN] Copy S's setup into T.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Neither unsupported box nor its row is copied, and source's XML element remains unchanged.
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
        // [SCENARIO 653992] Setup copy does not overwrite target boxes with different value types or unsupported historical mappings.
        Initialize();

        // [GIVEN] Source S has valid custom amount boxes; matching target boxes use occupation codes or unsupported historical XML element.
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

        // [WHEN] Copy S's setup into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T keeps its existing boxes and historical rows, and no incompatible source statement rows are added.
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
        // [SCENARIO 653992] Setup copy reports a target statement row with a missing supplemental box without changing that row.
        Initialize();

        // [GIVEN] Target T already has statement row selecting nonexistent box MISSING.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        CreateSetupCopySelector(ToPeriodNo, 'MISSING', 31000);

        // [WHEN] Copy ordinary income setup from S into T.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T's broken row remains unchanged, and copy summary identifies it for repair.
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
        // [SCENARIO 653992] Setup copy does not overwrite a custom target statement row at the source row's line number.
        Initialize();

        // [GIVEN] Source S has supplemental statement row where T already has custom income statement row.
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

        // [WHEN] Copy S's setup into T twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] T keeps its description, selected box, sign, totaling and position, and copy summary reports conflict.
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
        // [SCENARIO 653992] Skipping a conflicting income box also skips vendor setup and adjustments that depend on it.
        Initialize();

        // [GIVEN] S has income box NEC-01B with vendor setup and adjustment 1000; T reserves NEC-01B as supplemental box.
        FromPeriodNo := CreateSetupCopyPeriod();
        ToPeriodNo := CreateSetupCopyPeriod();
        PrepareFormBox(FormBox, FromPeriodNo, 'NEC', 'NEC-01B');
        FormBox.Insert(true);
        LibraryIRS1099FormBox.CreateVendorForNonPosting(Vendor);
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

        // [WHEN] Copy S's setup into T.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Income box, vendor setup and adjustment are all skipped; summary explains why and S's adjustment remains 1000.
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
        // [SCENARIO 653992] Cross-company setup copy uses the target company's period dates and preserves its custom income minimum.
        Initialize();

        // [GIVEN] C1's source has 2026 dates and its target has 2025 dates; C2's same target number has 2026 dates and custom income minimum.
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

        // [WHEN] Copy C1's source setup into C2's target twice.
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo, TempSelectedCompany);

        // [THEN] Only C2 receives custom supplemental box and statement row once; its minimum is preserved, and C1's source and target remain unchanged.
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

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualSetupRejectsNonYearPeriodNumber()
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Annual supplemental setup requires a four-digit period number, even when the dates are valid.
        Initialize();

        // [GIVEN] Period OTHER2026 has January through December 2026 dates.
        ReportingPeriod."No." := 'OTHER2026';
        ReportingPeriod."Starting Date" := 20260101D;
        ReportingPeriod."Ending Date" := 20261231D;
        ReportingPeriod.Insert();

        // [WHEN] Try to update annual supplemental setup for OTHER2026.
        asserterror LibraryIRSReportingPeriod.UpdateAnnualSetup(ReportingPeriod."No.", CompanyName());

        // [THEN] Tax-year validation rejects period number because it is not four digits.
        Assert.ExpectedError('The IRIS tax year OTHER2026 must contain four digits');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AnnualTestSetupSkipsYearUsedByDocument()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        OccupiedPeriodNo: Code[20];
        SelectedPeriodNo: Code[20];
        ReportingYear: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Creating annual test setup skips a year still used by a document whose reporting period is missing.
        Initialize();

        // [GIVEN] Document D uses year whose reporting-period record has been deleted.
        OccupiedPeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(2026);
        ReportingPeriod.Get(OccupiedPeriodNo);
        ReportingPeriod.Delete(true);
        DocHeader.ID := LibraryUtility.GetNewRecNo(DocHeader, DocHeader.FieldNo(ID));
        DocHeader."Period No." := OccupiedPeriodNo;
        DocHeader.Insert();
        Evaluate(ReportingYear, OccupiedPeriodNo);

        // [WHEN] Request available annual reporting period starting from that year.
        SelectedPeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(ReportingYear);

        // [THEN] Different year is selected, and document D and its saved period number are unchanged.
        Assert.AreNotEqual(OccupiedPeriodNo, SelectedPeriodNo, 'Years used by existing documents must not be selected for test setup.');
        DocHeader.Get(DocHeader.ID);
        Assert.AreEqual(OccupiedPeriodNo, DocHeader."Period No.", 'Selecting a test reporting period must not delete an existing document.');
        ReportingPeriod.Get(SelectedPeriodNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetupCopyValidatesYearBeforeAnyWrites()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        FromPeriodNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Setup copy rejects a nonnumeric target period before saving any forms or supplemental boxes.
        Initialize();

        // [GIVEN] Source S is annual period; target COPY2026 has valid 2026 dates but nonnumeric number.
        FromPeriodNo := LibraryIRSReportingPeriod.CreateAvailableAnnualReportingPeriod(2025);
        ReportingPeriod.Init();
        ReportingPeriod."No." := 'COPY2026';
        ReportingPeriod."Starting Date" := 20260101D;
        ReportingPeriod."Ending Date" := 20261231D;
        ReportingPeriod.Insert();

        // [WHEN] Try to copy S into COPY2026 using error-catching copy method.
        Assert.IsFalse(LibraryIRSReportingPeriod.TryCopyPeriodSetup(FromPeriodNo, ReportingPeriod."No."), 'Nonnumeric annual targets must be rejected.');

        // [THEN] Error explains that period number must contain four digits, and no target forms or supplemental boxes are inserted.
        Assert.ExpectedError('Annual IRIS setup for period COPY2026');
        Assert.ExpectedError('must contain four digits');
        Assert.ExpectedErrorCode('Dialog');
        Form.SetRange("Period No.", ReportingPeriod."No.");
        Assert.RecordIsEmpty(Form);
        SupplementalBox.SetRange("Period No.", ReportingPeriod."No.");
        Assert.RecordIsEmpty(SupplementalBox);
    end;

    local procedure Initialize()
    begin
        LibraryLowerPermissions.StopLoggingNAVPermissions();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnvironmentInfoTestLibrary.SetTestabilitySandbox(false);
        LibraryIRSReportingPeriod.RemoveAllReportingPeriodsWithRelatedData();
        AnnualTestSetupPrepared := false;
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
        IRSFormsData: Codeunit "IRS Forms Data";
    begin
        if not AnnualTestSetupPrepared then begin
            DeleteAnnualTestSetup();
            AnnualTestSetupPrepared := true;
        end;
        IRSFormsData.AddReportingPeriodsWithForms(ReportingYear);
    end;

    local procedure CreateBoxSetupTestPeriod(TargetCompany: Text) PeriodNo: Code[20]
    var
        ReportingPeriod: Record "IRS Reporting Period";
    begin
        ReportingPeriod.ChangeCompany(TargetCompany);
        PeriodNo := '2100';
        while ReportingPeriod.Get(PeriodNo) do
            PeriodNo := IncStr(PeriodNo);
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
        // Bypass validation to represent old statement rows with missing or invalid supplemental boxes.
        StatementLine.Insert();
    end;

    local procedure CreateStoredDocument(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; PeriodNo: Code[20]; DocumentStatus: Enum "IRS 1099 Form Doc. Status"; MinimumAmount: Decimal)
    var
        Vendor: Record Vendor;
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        LibraryIRS1099FormBox.CreateVendorForNonPosting(Vendor);
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

    local procedure DeleteAnnualTestSetup()
    var
        ReportingPeriod: Record "IRS Reporting Period";
        Form: Record "IRS 1099 Form";
        FormBox: Record "IRS 1099 Form Box";
        FormInstruction: Record "IRS 1099 Form Instruction";
        StatementLine: Record "IRS 1099 Form Statement Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        DocLine: Record "IRS 1099 Form Doc. Line";
        VendorSetup: Record "IRS 1099 Vendor Form Box Setup";
        VendorAdjustment: Record "IRS 1099 Vendor Form Box Adj.";
        Transmission: Record "Transmission IRIS";
        PeriodFilter: Text;
        AnnualTestSetupInUseErr: Label 'Cannot reset annual test setup for period %1 while transmission %2 exists.', Comment = '%1 = reporting period, %2 = transmission ID';
    begin
        PeriodFilter := '2025|2026|2027';
        Transmission.SetFilter("Period No.", PeriodFilter);
        if Transmission.FindFirst() then
            Error(AnnualTestSetupInUseErr, Transmission."Period No.", Transmission."Document ID");

        DocHeader.SetFilter("Period No.", PeriodFilter);
        DocHeader.ModifyAll(Status, DocHeader.Status::Open);
        DocHeader.DeleteAll(true);
        DocLine.SetFilter("Period No.", PeriodFilter);
        DocLine.DeleteAll(true);
        ReportingPeriod.SetFilter("No.", PeriodFilter);
        ReportingPeriod.DeleteAll(true);

        // Triggerless period deletion can leave setup without its parent period or form.
        Form.SetFilter("Period No.", PeriodFilter);
        Form.DeleteAll(true);
        StatementLine.SetFilter("Period No.", PeriodFilter);
        StatementLine.DeleteAll(true);
        SupplementalBox.SetFilter("Period No.", PeriodFilter);
        SupplementalBox.DeleteAll(true);
        FormBox.SetFilter("Period No.", PeriodFilter);
        FormBox.DeleteAll(true);
        FormInstruction.SetFilter("Period No.", PeriodFilter);
        FormInstruction.DeleteAll(true);
        VendorSetup.SetFilter("Period No.", PeriodFilter);
        VendorSetup.DeleteAll(true);
        VendorAdjustment.SetFilter("Period No.", PeriodFilter);
        VendorAdjustment.DeleteAll(true);
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

    local procedure PrepareReadPermissionTestData(IsSaaS: Boolean; IsSandbox: Boolean)
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
