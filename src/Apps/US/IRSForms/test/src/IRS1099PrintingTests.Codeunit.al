// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Vendor;

codeunit 148017 "IRS 1099 Printing Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryIRS1099Document: Codeunit "Library IRS 1099 Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        IRS1099FormStatementLineEmptyErr: Label 'There are no form statement lines for the selected form and period.';

    trigger OnRun()
    begin
        // [FEATURE] [1099] [UT]
    end;

    [Test]
    procedure UT_IRS1099Print_NoStatementLinesErr()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
begin
        // [SCENARIO 495389] User gets error when trying to run report with empty statement lines
        Initialize();

// [GIVEN] IRS 1099 Document exists for Vendor in period
        CreateIRS1099Document(IRS1099FormDocHeader);

        // [GIVEN] Form Box No exists in period
        Commit();

        // [GIVEN] IRS 1099 Document Line exists for Vendor in period
        CreateIRS1099DocLine(IRS1099FormDocHeader, IRS1099FormDocLine, LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No."), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Run Print report
        asserterror Report.Run(Report::"IRS 1099 Print", false, false, IRS1099FormDocHeader);

        // [THEN] Error is shown that no statement lines exist
        Assert.ExpectedError(IRS1099FormStatementLineEmptyErr);

        // Tear down
        IRS1099FormDocHeader.Delete(true);
end;

    [Test]
    procedure UT_IRS1099Print_SavingReportWorks()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        TempIRS1099PrintParams: Record "IRS 1099 Print Params";
        IRSFormsFacade: Codeunit "IRS Forms Facade";
FormBoxNo: Code[20];
    begin
        // [SCENARIO 495389] SaveContentForDocument works for document
        Initialize();
// [GIVEN] IRS 1099 Document exists for Vendor in period
        CreateIRS1099Document(IRS1099FormDocHeader);

        // [GIVEN] Form Box No exists in period
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No.");

        // [GIVEN] IRS 1099 Document Line exists for Vendor in period
        CreateIRS1099DocLine(IRS1099FormDocHeader, IRS1099FormDocLine, FormBoxNo, LibraryRandom.RandDec(1000, 2));

        // [GIVEN] No Statement Line exists for Vendor in period
        CreateStatementLine(IRS1099FormDocHeader, FormBoxNo);

        Commit();

        // [WHEN] Use Save content for document
        TempIRS1099PrintParams := CreatePrintParams();
        IRSFormsFacade.SaveContentForDocument(IRS1099FormDocHeader, TempIRS1099PrintParams, false);

        // [THEN] Content has beed saved
        VerifyFileContentExists(IRS1099FormDocHeader, TempIRS1099PrintParams."Report Type");

        // Tear down
        IRS1099FormDocHeader.Delete(true);
end;

    [Test]
    procedure UT_IRS1099Print_BankAccountNo()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        VendorBankAccount: Record "Vendor Bank Account";
FormBoxNo: Code[20];
    begin
        // [SCENARIO 495389] Bank Account No for Vendor is shown correctly in report
        Initialize();
// [GIVEN] IRS 1099 Document exists for Vendor in period
        CreateIRS1099Document(IRS1099FormDocHeader);

        // [GIVEN] Vendor Bank Account exists for this vendor with Bank Account No = "XXX"
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, IRS1099FormDocHeader."Vendor No.");
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount.Modify(true);

        // [GIVEN] Update Preffered Bank Account for Vendor
        SetPreferredBankAccount(IRS1099FormDocHeader."Vendor No.", VendorBankAccount.Code);

        // [GIVEN] Form Box No exists in period
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), IRS1099FormDocHeader."Form No.");

        // [GIVEN] IRS 1099 Document Line exists for Vendor in period
        CreateIRS1099DocLine(IRS1099FormDocHeader, IRS1099FormDocLine, FormBoxNo, LibraryRandom.RandDec(1000, 2));

        // [GIVEN] No Statement Line exists for Vendor in period
        CreateStatementLine(IRS1099FormDocHeader, FormBoxNo);

        Commit();

        // [WHEN] Run report
        LibraryReportDataset.RunReportAndLoad(Report::"IRS 1099 Print", IRS1099FormDocHeader, '');

        // [THEN] Vendor Bank Account No in report is "XXX"
        LibraryReportDataset.AssertElementWithValueExists('Vendor_BankAccountNo', VendorBankAccount."Bank Account No.");

        // Tear down
        IRS1099FormDocHeader.Delete(true);
end;

    [Test]
    procedure UT_IRS1099Statement_FilterWithParentheses()
    var
        IRS1099FormStatementLine: Record "IRS 1099 Form Statement Line";
        IRSFormsData: Codeunit "IRS Forms Data";
        PeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A statement filter treats parentheses in a form box number as literal characters.
        Initialize();

        // [GIVEN] Form box "B" contains parentheses and belongs to form "F" in period "P".
        FormBoxNo := 'NEC-01 (A)';
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        LibraryIRS1099FormBox.CreateSpecificFormBoxInReportingPeriod(WorkDate(), WorkDate(), FormNo, FormBoxNo);

        // [WHEN] A statement line is created for form box "B".
        IRSFormsData.AddFormStatementLine(PeriodNo, FormNo, FormBoxNo, 10000, 'Form box with parentheses');

        // [THEN] The stored view filters exclusively on form box "B" and agrees with the display expression.
        IRS1099FormStatementLine.Get(PeriodNo, FormNo, 10000);
        VerifyStatementLineFormBoxFilter(IRS1099FormStatementLine, FormBoxNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementUsesTypedConfigurableRows()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        StatementLine: Record "IRS 1099 Form Statement Line";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Configurable supplemental rows retain text codes, signs, labels and user ordering.
        Initialize();

        // [GIVEN] Document D has separately selected disclosures and custom statement configuration.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'NEC');
        StatementLine.Get('2026', 'NEC', 17500);
        StatementLine.Description := 'My overtime';
        StatementLine."Print with" := StatementLine."Print with"::"Opposite Sign";
        StatementLine.Modify(true);
        StatementLine.Rename('2026', 'NEC', 5000);
        StatementLine.Get('2026', 'NEC', 15000);
        StatementLine."Print Value Type" := StatementLine."Print Value Type"::"Yes/No";
        StatementLine."Record View String" := 'Not a financial view';
        StatementLine."Print with" := StatementLine."Print with"::"Opposite Sign";
        StatementLine.Modify(true);

        // [WHEN] The generic statement dataset is generated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Labels, amount signs, text codes and row ordering are respected.
        Assert.AreEqual(4, Lines.Count(), 'Only the parent and three selected disclosures are printed.');
        VerifyDatasetLine(Lines, 0, 'NEC-01D - My overtime', '-50');
        VerifyDatasetLine(Lines, 1, 'NEC-01 - Nonemployee Compensation (box 1a)', '5000');
        VerifyDatasetLine(Lines, 2, 'NEC-01B - Cash tips (box 1b)', '100');
        VerifyDatasetLine(Lines, 3, 'NEC-01C - Treasury tipped occupation codes (box 1c)', '101, 000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementFollowsOnlyItsParentAndWithholding()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        ParentIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRSFormsData: Codeunit "IRS Forms Data";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Eligible rents do not qualify other-income disclosures; backup withholding does.
        Initialize();

        // [GIVEN] Document D has eligible rents and excluded other income with valid disclosures.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'MISC');
        ParentIRS1099FormDocLine.Get('2026', IRS1099FormDocHeader."Vendor No.", 'MISC', IRS1099FormDocHeader.ID, 0);
        ParentIRS1099FormDocLine."Minimum Reportable Amount" := 2000;
        ParentIRS1099FormDocLine.Validate(Amount, 500);
        ParentIRS1099FormDocLine.Modify(true);
        IRS1099FormDocLine."Line No." := 1;
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocLine, IRS1099FormDocHeader.ID, '2026', IRS1099FormDocHeader."Vendor No.", 'MISC', 'MISC-01');
        IRS1099FormDocLine.Validate(Amount, 2500);
        IRS1099FormDocLine.Modify(true);
        IRSFormsData.AddFormStatementLine('2026', 'MISC', 'MISC-01', 10000, 'Rents');

        // [WHEN] The statement is generated without backup withholding.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Only rents are included.
        Assert.AreEqual(1, Lines.Count(), 'Rent does not qualify excluded other-income disclosures.');
        VerifyDatasetLine(Lines, 0, 'MISC-01 - Rents', '2500');

        // [GIVEN] Document D now has backup withholding.
        IRS1099FormDocLine.Init();
        IRS1099FormDocLine."Line No." := 2;
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocLine, IRS1099FormDocHeader.ID, '2026', IRS1099FormDocHeader."Vendor No.", 'MISC', 'MISC-04');
        IRS1099FormDocLine.Validate(Amount, 25);
        IRS1099FormDocLine.Modify(true);
        LibraryIRS1099Document.RecalculateIncludeIn1099(IRS1099FormDocHeader.ID);

        // [WHEN] The dataset is regenerated with refreshed parent eligibility.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Disclosures follow their own now-reportable parent.
        Assert.AreEqual(5, Lines.Count(), 'Withholding qualifies the saved parent and all three disclosures.');
        VerifyDatasetLine(Lines, 1, 'MISC-03 - Other Income', '500');
        VerifyDatasetLine(Lines, 2, 'MISC-13A - Cash tips (box 13a)', '100');
        VerifyDatasetLine(Lines, 3, 'MISC-13B - Treasury tipped occupation codes (box 13b)', '101, 000');
        VerifyDatasetLine(Lines, 4, 'MISC-14 - Qualified overtime compensation (box 14)', '50');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementRetainsZeroTipCodesAndRestoresThem()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Statement suppression never deletes saved zero-tip codes.
        Initialize();

        // [GIVEN] Document D retains occupation codes after its tips are cleared.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'NEC');
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        TipsSupplementalLine.Validate(Amount, 0);
        TipsSupplementalLine.Modify(true);

        // [WHEN] The statement dataset is generated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Suppressed codes remain stored.
        Assert.AreEqual(2, Lines.Count(), 'Zero tips and retained codes are suppressed, not overtime or parent income.');
        CodesSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        Assert.AreEqual('000', CodesSupplementalLine."Occupation Code 2", 'Leading zeros remain stored.');

        // [WHEN] Positive tips are restored.
        TipsSupplementalLine.Validate(Amount, 125);
        TipsSupplementalLine.Modify(true);

        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] The original text codes are reportable again.
        Assert.AreEqual(4, Lines.Count(), 'Positive reportable tips restore the stored codes.');
        VerifyDatasetLine(Lines, 2, 'NEC-01C - Treasury tipped occupation codes (box 1c)', '101, 000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementRoundsWithoutChangingSource()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        TipsSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        OvertimeSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        CodesSupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        StatementLine: Record "IRS 1099 Form Statement Line";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Statements project cents per document, preserving configured signs and raw stored eligibility.
        Initialize();

        // [GIVEN] D has tips rounding to zero, independent overtime rounding up, and an opposite-sign overtime row.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'NEC');
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        TipsSupplementalLine.Validate(Amount, 0.004);
        TipsSupplementalLine.Modify(true);
        OvertimeSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01D');
        OvertimeSupplementalLine.Validate(Amount, 0.006);
        OvertimeSupplementalLine.Modify(true);
        StatementLine.Get('2026', 'NEC', 17500);
        StatementLine."Print with" := StatementLine."Print with"::"Opposite Sign";
        StatementLine.Modify(true);

        // [WHEN] The generic statement dataset is generated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Rounded zero tips hide codes but retain the raw disclosure and its stored eligibility.
        Assert.AreEqual(3, Lines.Count(), 'Only the parent and two projected amounts are printed.');
        VerifyDatasetLine(Lines, 0, 'NEC-01 - Nonemployee Compensation (box 1a)', '5000');
        VerifyDatasetLine(Lines, 1, 'NEC-01B - Cash tips (box 1b)', '0');
        VerifyDatasetLine(Lines, 2, 'NEC-01D - Qualified overtime compensation (box 1d)', '-0.01');
        TipsSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01B');
        Assert.AreEqual(0.004, TipsSupplementalLine.Amount, 'Rendering does not round saved tips.');
        OvertimeSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01D');
        Assert.AreEqual(0.006, OvertimeSupplementalLine.Amount, 'Rendering does not round saved overtime.');
        CodesSupplementalLine.Get(IRS1099FormDocHeader.ID, 'NEC-01C');
        Assert.IsTrue(LibraryIRS1099Document.IsSupplementalReportable(CodesSupplementalLine), 'Raw parent eligibility must remain separate from outgoing projection.');
        Assert.AreEqual('101', CodesSupplementalLine."Occupation Code 1", 'The first saved code remains unchanged.');
        Assert.AreEqual('000', CodesSupplementalLine."Occupation Code 2", 'Leading zeros remain stored.');

        // [GIVEN] D's tips now round up and overtime rounds down.
        TipsSupplementalLine.Validate(Amount, 0.006);
        TipsSupplementalLine.Modify(true);
        OvertimeSupplementalLine.Validate(Amount, 0.004);
        OvertimeSupplementalLine.Modify(true);

        // [WHEN] The statement is regenerated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] Codes return without changing their text and overtime remains independently projected.
        Assert.AreEqual(4, Lines.Count(), 'A positive outgoing tip restores the saved codes.');
        VerifyDatasetLine(Lines, 1, 'NEC-01B - Cash tips (box 1b)', '0.01');
        VerifyDatasetLine(Lines, 2, 'NEC-01C - Treasury tipped occupation codes (box 1c)', '101, 000');
        VerifyDatasetLine(Lines, 3, 'NEC-01D - Qualified overtime compensation (box 1d)', '0');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementUsesSupplBoxDescriptionAndType()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        StatementLine: Record "IRS 1099 Form Statement Line";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        Lines: JsonArray;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] An empty row description uses the editable definition, not a form box or guessed type.
        Initialize();

        // [GIVEN] Definition B has a custom label and its statement row has no override.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'NEC');
        StatementLine.Get('2026', 'NEC', 15000);
        StatementLine.Description := '';
        StatementLine.Modify(true);
        SupplementalBox.Get('2026', 'NEC', 'NEC-01C');
        SupplementalBox.Description := 'My tipped occupations';
        SupplementalBox.Modify(true);

        // [WHEN] The statement dataset is generated.
        Lines := LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] The definition supplies the label and text value kind.
        VerifyDatasetLine(Lines, 2, 'NEC-01C - My tipped occupations', '101, 000');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SupplementalStatementRejectsPopulatedUnknownMappings()
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
        SupplementalBox: Record "IRS 1099 Suppl. Box";
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Printing uses the shared reporting boundary even when a populated custom box is not selected.
        Initialize();

        // [GIVEN] Document D has a populated unmapped custom supplemental line.
        CreateSupplementalStatement(IRS1099FormDocHeader, 'NEC');
        SupplementalBox."Period No." := '2026';
        SupplementalBox."Form No." := 'NEC';
        SupplementalBox."No." := 'CUSTOM';
        SupplementalBox."Parent Form Box No." := 'NEC-01';
        SupplementalBox.Insert(true);
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", 'CUSTOM');
        SupplementalLine.Validate(Amount, 10);
        SupplementalLine.Insert(true);

        // [WHEN] The statement dataset is generated.
        asserterror LibraryIRS1099Document.GetStatementDataset(IRS1099FormDocHeader);

        // [THEN] The common reporting validator rejects the unsupported values.
        Assert.ExpectedError('contains values that cannot be reported in IRIS XML');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure StatementInstructionsUseDocumentYear()
    var
        DocHeader2025: Record "IRS 1099 Form Doc. Header";
        DocHeader2026: Record "IRS 1099 Form Doc. Header";
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
        IRSFormsData: Codeunit "IRS Forms Data";
        SavedWorkDate: Date;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653992] Report years and recipient instructions follow each document, not the work date.
        Initialize();

        // [GIVEN] Documents D1 and D2 belong to different years and forms.
        IRSFormsData.AddReportingPeriodsWithForms(2025);
        IRSFormsData.AddReportingPeriodsWithForms(2026);
        DocHeader2025.Get(LibraryIRS1099Document.MockFormDocumentForVendor('2025', LibraryPurchase.CreateVendorNo(), 'NEC', Enum::"IRS 1099 Form Doc. Status"::Open));
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocLine, DocHeader2025.ID, '2025', DocHeader2025."Vendor No.", 'NEC', 'NEC-01');
        IRS1099FormDocLine.Validate(Amount, 5000);
        IRS1099FormDocLine.Modify(true);
        DocHeader2026.Get(LibraryIRS1099Document.MockFormDocumentForVendor('2026', LibraryPurchase.CreateVendorNo(), 'MISC', Enum::"IRS 1099 Form Doc. Status"::Open));
        Clear(IRS1099FormDocLine);
        LibraryIRS1099Document.MockFormDocumentLineForVendor(IRS1099FormDocLine, DocHeader2026.ID, '2026', DocHeader2026."Vendor No.", 'MISC', 'MISC-03');
        IRS1099FormDocLine.Validate(Amount, 5000);
        IRS1099FormDocLine.Modify(true);
        Commit();

        // [WHEN] D1 is rendered with an unrelated work date.
        SavedWorkDate := WorkDate();
        WorkDate(20240101D);
        DocHeader2025.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::"IRS 1099 Print", DocHeader2025, '');
        WorkDate(SavedWorkDate);

        // [THEN] Its dataset identifies 2025 and the corrected NEC box 3.
        LibraryReportDataset.AssertElementWithValueExists('Report_Year', 2025);
        LibraryReportDataset.AssertElementWithValueExists('Instruction_Header', 'Box 1.');
        LibraryReportDataset.AssertElementWithValueExists('Instruction_Description', 'Shows your total compensation of excess golden parachute payments subject to a 20% excise tax. See your tax return instructions for where to report.');

        // [WHEN] D2 is rendered under that same unrelated work date.
        WorkDate(20240101D);
        DocHeader2026.SetRecFilter();
        LibraryReportDataset.RunReportAndLoad(Report::"IRS 1099 Print", DocHeader2026, '');
        WorkDate(SavedWorkDate);

        // [THEN] Its dataset identifies 2026, supplemental boxes and unnumbered FATCA.
        LibraryReportDataset.AssertElementWithValueExists('Report_Year', 2026);
        LibraryReportDataset.AssertElementWithValueExists('Instruction_Header', 'Box 13a.');
        LibraryReportDataset.AssertElementWithValueExists('Instruction_Header', 'Box 13b.');
        LibraryReportDataset.AssertElementWithValueExists('Instruction_Header', 'FATCA filing requirement.');

        DocHeader2025.Delete(true);
        DocHeader2026.Delete(true);
    end;

    local procedure Initialize()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod.DeleteAll(true);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS 1099 Document Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS 1099 Document Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS 1099 Document Tests");
    end;

    local procedure CreateIRS1099Document(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header")
    var
        PeriodNo, FormNo, VendNo, FormBoxNo : Code[20];
    begin
        PeriodNo := LibraryIRSReportingPeriod.CreateOneDayReportingPeriod(WorkDate());
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(WorkDate());
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(WorkDate(), FormNo);
        VendNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(WorkDate(), FormNo, FormBoxNo);

        IRS1099FormDocHeader."Period No." := PeriodNo;
        IRS1099FormDocHeader."Vendor No." := VendNo;
        IRS1099FormDocHeader."Form No." := FormNo;
        IRS1099FormDocHeader.Insert();
    end;

    local procedure CreateIRS1099DocLine(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; var IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line"; FormBoxNo: Code[20]; Amount: Decimal)
    var
        NewLineNo: Integer;
    begin
        IRS1099FormDocLine.SetRange("Document ID", IRS1099FormDocHeader.ID);
        if IRS1099FormDocLine.FindLast() then
            NewLineNo := IRS1099FormDocLine."Line No." + 1
        else
            NewLineNo := 1;
        IRS1099FormDocLine.Init();
        IRS1099FormDocLine."Line No." := NewLineNo;
        IRS1099FormDocLine."Document ID" := IRS1099FormDocHeader.ID;
        IRS1099FormDocLine."Form Box No." := FormBoxNo;
        IRS1099FormDocLine.Amount := Amount;
        IRS1099FormDocLine.Insert();
    end;

    local procedure CreatePrintParams() TempIRS1099PrintParams: Record "IRS 1099 Print Params"
    begin
        TempIRS1099PrintParams."Report Type" := TempIRS1099PrintParams."Report Type"::"Copy 2";
        TempIRS1099PrintParams.Insert();
    end;

    local procedure CreateStatementLine(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; FormBoxNo: Code[20])
    var
        IRS1099FormStatementLine: Record "IRS 1099 Form Statement Line";
        NewLineNo: Integer;
    begin
        IRS1099FormStatementLine.SetRange("Period No.", IRS1099FormDocHeader."Period No.");
        IRS1099FormStatementLine.SetRange("Form No.", IRS1099FormDocHeader."Form No.");
        if IRS1099FormStatementLine.FindLast() then
            NewLineNo := IRS1099FormStatementLine."Line No." + 1
        else
            NewLineNo := 1;
        IRS1099FormStatementLine.Init();
        IRS1099FormStatementLine."Period No." := IRS1099FormDocHeader."Period No.";
        IRS1099FormStatementLine."Form No." := IRS1099FormDocHeader."Form No.";
        IRS1099FormStatementLine."Line No." := NewLineNo;
        IRS1099FormStatementLine.Description := LibraryUtility.GenerateGUID();
        IRS1099FormStatementLine."Row No." := LibraryUtility.GenerateGUID();
        IRS1099FormStatementLine.SetFormBoxFilter(FormBoxNo);
        IRS1099FormStatementLine.Insert();
    end;

    local procedure CreateSupplementalStatement(var IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; FormNo: Code[20])
    var
        SupplementalLine: Record "IRS 1099 Doc. Suppl. Line";
        IRSFormsData: Codeunit "IRS Forms Data";
        CashTipsBoxNo: Code[20];
        OccupationCodesBoxNo: Code[20];
        OvertimeBoxNo: Code[20];
    begin
        LibraryIRS1099Document.CreateSupplementalDocument(IRS1099FormDocHeader, FormNo);
        LibraryIRSReportingPeriod.UpdateAnnualSetup('2026', CompanyName());
        if FormNo = 'NEC' then begin
            CashTipsBoxNo := 'NEC-01B';
            OccupationCodesBoxNo := 'NEC-01C';
            OvertimeBoxNo := 'NEC-01D';
        end else begin
            CashTipsBoxNo := 'MISC-13A';
            OccupationCodesBoxNo := 'MISC-13B';
            OvertimeBoxNo := 'MISC-14';
            IRSFormsData.AddFormStatementLine('2026', 'MISC', 'MISC-03', 30000, 'Other Income');
        end;
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", CashTipsBoxNo);
        SupplementalLine.Validate(Amount, 100);
        SupplementalLine.Insert(true);
        SupplementalLine.Init();
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", OccupationCodesBoxNo);
        SupplementalLine.Validate("Occupation Code 1", '101');
        SupplementalLine.Validate("Occupation Code 2", '000');
        SupplementalLine.Insert(true);
        SupplementalLine.Init();
        SupplementalLine."Document ID" := IRS1099FormDocHeader.ID;
        SupplementalLine.Validate("Supplemental Box No.", OvertimeBoxNo);
        SupplementalLine.Validate(Amount, 50);
        SupplementalLine.Insert(true);
    end;

    local procedure SetPreferredBankAccount(VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor."Preferred Bank Account Code" := BankAccountNo;
        Vendor.Modify();
    end;

    local procedure VerifyStatementLineFormBoxFilter(IRS1099FormStatementLine: Record "IRS 1099 Form Statement Line"; FormBoxNo: Code[10])
    var
        TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary;
    begin
        TempIRS1099FormDocLine.SetView(IRS1099FormStatementLine."Record View String");
        Assert.AreEqual(FormBoxNo, TempIRS1099FormDocLine.GetRangeMin("Form Box No."), 'The filter lower bound must equal the literal form box number.');
        Assert.AreEqual(FormBoxNo, TempIRS1099FormDocLine.GetRangeMax("Form Box No."), 'The filter upper bound must equal the literal form box number.');
        Assert.AreEqual(TempIRS1099FormDocLine.GetFilters(), IRS1099FormStatementLine."Filter Expression", 'The display expression must match the stored view.');
    end;

    local procedure VerifyFileContentExists(IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header"; ReportType: Enum "IRS 1099 Form Report Type")
    var
        IRS1099FormReport: Record "IRS 1099 Form Report";
    begin
        IRS1099FormReport.SetRange("Document ID", IRS1099FormDocHeader.ID);
        IRS1099FormReport.SetRange("Report Type", ReportType);
        IRS1099FormReport.FindFirst();
        IRS1099FormReport.CalcFields("File Content");
        Assert.IsTrue(IRS1099FormReport."File Content".HasValue(), 'File content should exist for the document and report type.');
    end;

    local procedure VerifyDatasetLine(Lines: JsonArray; Index: Integer; ExpectedName: Text; ExpectedValue: Text)
    var
        Line: JsonToken;
        Value: JsonToken;
    begin
        Lines.Get(Index, Line);
        Line.AsObject().Get('name', Value);
        Assert.AreEqual(ExpectedName, Value.AsValue().AsText(), 'Statement label and configurable order.');
        Line.AsObject().Get('value', Value);
        Assert.AreEqual(ExpectedValue, Value.AsValue().AsText(), 'Statement amount or text codes.');
    end;

}