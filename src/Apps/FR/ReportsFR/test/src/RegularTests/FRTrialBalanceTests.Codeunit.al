// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using System.IO;
using System.Utilities;

codeunit 148012 "FR Trial Balance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodAndCumulativeMovementsStaySeparate()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Period 100/40 plus earlier 20/10 produces cumulative 120/50, never net-only movements.
        Initialize();

        // [GIVEN] A has current 100/40, earlier 20/10 and signed prior-period net 30.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20250115D, 30, 0);
        CreateEntry(GLAccount."No.", 20251215D, -10, 10);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20260101D, 20260131D);

        // [WHEN] Report 7 exports the extended dataset.
        LibraryReportDataset.RunReportAndLoad(Report::"Trial Balance/Previous Year", GLAccount, '');

        // [THEN] Movement columns retain debit/credit detail while prior-year output remains signed.
        VerifyMovements(100, 40, 120, 50);
        LibraryReportDataset.AssertElementWithValueExists('LastYearNetChange', 30);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeIncreasePct', 200);
        LibraryReportDataset.AssertElementWithValueExists('FiscalYearNetChange', 60);
        LibraryReportDataset.AssertElementWithValueExists('NegFiscalYearNetChange', -60);
        LibraryReportDataset.AssertElementWithValueExists('FiscalYearBalance', 70);
        LibraryReportDataset.AssertElementWithValueExists('NegFiscalYearBalance', -70);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClosingDateIncludesClosingMovements()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Closing-date boundaries and negative corrections remain supported by the extension.
        Initialize();

        // [GIVEN] A has a normal debit and a closing credit at year end.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20261231D, 100, 0);
        CreateEntry(GLAccount."No.", ClosingDate(20261231D), 0, 40);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20260101D, ClosingDate(20261231D));

        // [WHEN] The closing date is included.
        LibraryReportDataset.RunReportAndLoad(Report::"Trial Balance/Previous Year", GLAccount, '');

        // [THEN] Both the normal and closing movements contribute.
        VerifyMovements(100, 40, 100, 40);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeIncreasePct', 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FrenchLayoutRendersSeparateMovements()
    var
        GLAccount: Record "G/L Account";
        TempCells: Record "Excel Buffer" temporary;
        TrialBalance: Report "Trial Balance/Previous Year";
        Data: Codeunit "Temp Blob";
        Rendered: Codeunit "FR Financial Integration Tests";
        Output: OutStream;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The selected French layout renders gross movements instead of W1 net-only values.
        Initialize();

        // [GIVEN] A has earlier 20/10 and current 100/40.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20251215D, 20, 10);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20260101D, 20260131D);
        TrialBalance.SetTableView(GLAccount);
        Data.CreateOutStream(Output);

        // [WHEN] The installed report layout is rendered to Excel.
        TrialBalance.SaveAs('', ReportFormat::Excel, Output);
        Rendered.ReadRenderedExcel(Data, TempCells);

        // [THEN] All four movement amounts occur in the rendered output.
        Rendered.VerifyRenderedNumber(TempCells, 100);
        Rendered.VerifyRenderedNumber(TempCells, 40);
        Rendered.VerifyRenderedNumber(TempCells, 120);
        Rendered.VerifyRenderedNumber(TempCells, 50);
        Rendered.SaveArtifact('653672-TrialBalance.xlsx', Data);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AccountAndDimensionFiltersRestrictAllMovements()
    var
        GLAccount: Record "G/L Account";
        ExcludedAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Dimension: Record Dimension;
        IncludedValue: Record "Dimension Value";
        ExcludedValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Account and dimension selection applies equally to period, cumulative and prior-year values.
        Initialize();

        // [GIVEN] A has selected movements and excluded dimension/account movements of 900.
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(IncludedValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(ExcludedValue, Dimension.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Global Dimension 1 Code" := Dimension.Code;
        GeneralLedgerSetup.Modify(false);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(ExcludedAccount);
        CreateDimensionEntry(GLAccount."No.", 20250115D, 30, 0, IncludedValue.Code);
        CreateDimensionEntry(GLAccount."No.", 20251215D, 20, 10, IncludedValue.Code);
        CreateDimensionEntry(GLAccount."No.", 20260115D, 100, 40, IncludedValue.Code);
        CreateDimensionEntry(GLAccount."No.", 20260115D, 900, 0, ExcludedValue.Code);
        CreateDimensionEntry(ExcludedAccount."No.", 20260115D, 900, 0, IncludedValue.Code);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20260101D, 20260131D);
        GLAccount.SetRange("Global Dimension 1 Filter", IncludedValue.Code);

        // [WHEN] Report 7 calculates each of its current and prior periods.
        LibraryReportDataset.RunReportAndLoad(Report::"Trial Balance/Previous Year", GLAccount, '');

        // [THEN] The selected dimension is retained while dates change and the excluded account is absent.
        VerifyMovements(100, 40, 150, 50);
        LibraryReportDataset.AssertElementWithValueExists('LastYearNetChange', 30);
        LibraryReportDataset.AssertElementWithValueExists('FiscalYearNetChange', 60);
        LibraryReportDataset.AssertElementWithValueNotExist('FRAccountNo', ExcludedAccount."No.");
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        Assert.AreEqual(4, GLEntry.Count(), 'Reporting must not remove excluded ledger movements.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeapPeriodRetainsRoundedSignedRatios()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Leap-day derivation and one-decimal ratios preserve signed net semantics.
        Initialize();

        // [GIVEN] A has prior-year -30 and a leap-day net 60.2, plus an excluded following-day movement.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20270228D, 0, 30);
        CreateEntry(GLAccount."No.", 20280229D, 100.4, 40.2);
        CreateEntry(GLAccount."No.", 20280301D, 900, 0);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20280229D);

        // [WHEN] Report 7 derives the non-leap previous-year period.
        LibraryReportDataset.RunReportAndLoad(Report::"Trial Balance/Previous Year", GLAccount, '');

        // [THEN] Gross movements, signed prior values and rounded ratios retain their independent meanings.
        VerifyMovements(100.4, 40.2, 100.4, 70.2);
        LibraryReportDataset.AssertElementWithValueExists('LastYearNetChange', -30);
        LibraryReportDataset.AssertElementWithValueExists('NetChangeIncreasePct', -200.7);
        LibraryReportDataset.AssertElementWithValueExists('BalanceIncreasePct', -100.7);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IndentationBlankLinesAndPaginationSurvive()
    var
        FirstAccount: Record "G/L Account";
        SecondAccount: Record "G/L Account";
        TempCells: Record "Excel Buffer" temporary;
        TrialBalance: Report "Trial Balance/Previous Year";
        Data: Codeunit "Temp Blob";
        Rendered: Codeunit "FR Financial Integration Tests";
        Output: OutStream;
        SheetCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Account indentation, blank-line repeaters and new-page grouping reach the selected layout.
        Initialize();

        // [GIVEN] A requests two blank lines and a page break before the following account B.
        LibraryERM.CreateGLAccount(FirstAccount);
        LibraryERM.CreateGLAccount(SecondAccount);
        FirstAccount.Name := 'Indented financial account';
        FirstAccount.Indentation := 2;
        FirstAccount."No. of Blank Lines" := 2;
        FirstAccount."New Page" := true;
        FirstAccount.Modify(false);
        CreateEntry(FirstAccount."No.", 20260115D, 100, 0);
        CreateEntry(SecondAccount."No.", 20260115D, 0, 40);
        FirstAccount.SetFilter("No.", '%1|%2', FirstAccount."No.", SecondAccount."No.");
        FirstAccount.SetRange("Date Filter", 20260101D, 20260131D);

        // [WHEN] The dataset and then the selected layout are generated independently.
        LibraryReportDataset.RunReportAndLoad(Report::"Trial Balance/Previous Year", FirstAccount, '');
        TrialBalance.SetTableView(FirstAccount);
        Data.CreateOutStream(Output);
        TrialBalance.SaveAs('', ReportFormat::Excel, Output);
        SheetCount := Rendered.ReadRenderedExcel(Data, TempCells);

        // [THEN] The dataset retains spacing/grouping and the renderer emits distinct page worksheets.
        LibraryReportDataset.AssertElementWithValueExists('FRAccountName', '    Indented financial account');
        LibraryReportDataset.AssertElementWithValueExists('FRBlankLines', 2);
        LibraryReportDataset.AssertElementWithValueExists('BlankLineNo', 2);
        LibraryReportDataset.AssertElementWithValueExists('PageGroupNo', 2);
        Assert.AreEqual(2, SheetCount, 'The new-page group must render on a separate worksheet.');
        Rendered.SaveArtifact('653672-TrialBalance-Pagination.xlsx', Data);
    end;

    local procedure Initialize()
    var
        Migration: Codeunit "Library - Reports FR";
    begin
        Migration.Migrate();
        LibraryReportDataset.Reset();
    end;

    local procedure CreateEntry(AccountNo: Code[20]; PostingDate: Date; Debit: Decimal; Credit: Decimal): Integer
    var
        GLEntry: Record "G/L Entry";
        NextEntryNo: Integer;
    begin
        if GLEntry.FindLast() then
            NextEntryNo := GLEntry."Entry No." + 1
        else
            NextEntryNo := 1;
        GLEntry.Init();
        GLEntry."Entry No." := NextEntryNo;
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Debit Amount" := Debit;
        GLEntry."Credit Amount" := Credit;
        GLEntry.Amount := Debit - Credit;
        GLEntry.Insert(false);
        exit(NextEntryNo);
    end;

    local procedure CreateDimensionEntry(AccountNo: Code[20]; PostingDate: Date; Debit: Decimal; Credit: Decimal; DimensionValueCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Get(CreateEntry(AccountNo, PostingDate, Debit, Credit));
        GLEntry."Global Dimension 1 Code" := DimensionValueCode;
        GLEntry.Modify(false);
    end;

    local procedure VerifyMovements(PeriodDebit: Decimal; PeriodCredit: Decimal; CumulativeDebit: Decimal; CumulativeCredit: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists('FRPeriodDebitAmount', PeriodDebit);
        LibraryReportDataset.AssertElementWithValueExists('FRPeriodCreditAmount', PeriodCredit);
        LibraryReportDataset.AssertElementWithValueExists('FRCumulativeDebitAmount', CumulativeDebit);
        LibraryReportDataset.AssertElementWithValueExists('FRCumulativeCreditAmount', CumulativeCredit);
    end;
}
