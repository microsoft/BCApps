// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 148010 "FR Financial Schedule Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ScheduleReport: Report "FR Financial Schedule";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
#if not CLEAN30
        FeatureState: Codeunit "Library - Reports FR";
#endif
        TestScheduleName: Code[10];
        CurrentDateFilter: Text;
        ComparisonDateFilter: Text;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DebtorsUseAccountNetSign()
    var
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Debtor selection uses each account's filtered net, not its debit movements.
        Initialize();

        // [GIVEN] A is +60, B is -30 and C is zero.
        CreateNetSignFixture(ScheduleLine);
        ScheduleLine."Totaling Creditor" := '';

        // [WHEN] Debtor accounts are totaled.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] Only A contributes its net +60.
        Assert.AreEqual(60, Total, 'Debtor selection must sum positive account net changes.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CreditorsUseAccountNetSign()
    var
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Creditor selection preserves the negative net, not credit movements.
        Initialize();

        // [GIVEN] A is +60, B is -30 and C is zero.
        CreateNetSignFixture(ScheduleLine);
        ScheduleLine."Totaling Debtor" := '';

        // [WHEN] Creditor accounts are totaled.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] Only B contributes -30.
        Assert.AreEqual(-30, Total, 'Creditor selection must sum negative account net changes.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverlappingSelectionsStillAccumulate()
    var
        GLAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Overlap is accumulated as before and is not silently deduplicated.
        Initialize();

        // [GIVEN] A has net +60 and appears in both primary and debtor selections.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        ScheduleLine.Totaling := GLAccount."No.";
        ScheduleLine."Totaling Debtor" := GLAccount."No.";

        // [WHEN] Both selections are calculated.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] The two contributions are retained.
        Assert.AreEqual(120, Total, 'Legacy overlapping selections accumulate.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SecondaryOnlyRetainsLegacyEligibility()
    var
        GLAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Blank primary totaling retains the characterized legacy eligibility rule.
        Initialize();

        // [GIVEN] Only the secondary selection refers to A.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        ScheduleLine."Totaling 2" := GLAccount."No.";

        // [WHEN] The schedule row is calculated.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] Neither component is eligible without primary totaling.
        Assert.AreEqual(0, Total, 'The primary component must remain zero.');
        Assert.AreEqual(0, SecondTotal, 'Extraction must not expand secondary-only eligibility.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PeriodFilterCanReverseAccountSign()
    var
        GLAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Sign selection is performed after applying the reporting period.
        Initialize();

        // [GIVEN] A has prior net -90 and current net +60.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20251215D, 0, 90);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        ScheduleLine.Totaling := 'NO-PRIMARY';
        ScheduleLine."Totaling Debtor" := GLAccount."No.";
        ScheduleLine.SetRange("Date Filter", 20260101D, 20261231D);
        GLAccount.SetRange("Date Filter", 20260101D, 20261231D);
        GLAccount.CalcFields("Net Change");
        Assert.AreEqual(60, GLAccount."Net Change", 'The native filtered account net is the independent calculation oracle.');

        // [WHEN] Debtor selection is evaluated for the current period only.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] A contributes +60 despite its negative all-time net.
        Assert.AreEqual(60, Total, 'Period filtering must precede the sign test.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CyclicRowsFailWithDiagnostic()
    var
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Cyclic row references fail with a bounded actionable error.
        Initialize();

        // [GIVEN] R1 totals itself.
        ScheduleLine."Schedule Name" := TestScheduleName;
        ScheduleLine."Line No." := 10000;
        ScheduleLine."Row No." := 'R1';
        ScheduleLine."Totaling Type" := ScheduleLine."Totaling Type"::Rows;
        ScheduleLine.Totaling := 'R1';
        ScheduleLine.Insert(false);

        // [WHEN] The cycle is evaluated.
        asserterror ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondTotal);

        // [THEN] Recursion cannot hang or return a partial plausible amount.
        Assert.ExpectedError('maximum nesting depth of six');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DatasetPreservesRatioAndBlankCaptions()
    var
        GLAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Current 60 and prior 30 produce 200 percent without changing component signs.
        Initialize();

        // [GIVEN] S selects A with current 60 and prior 30.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", 20250115D, 30, 0);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        ScheduleLine."Schedule Name" := TestScheduleName;
        ScheduleLine."Line No." := 10000;
        ScheduleLine.Totaling := GLAccount."No.";
        ScheduleLine.Insert(false);

        // [WHEN] The new report exports its dataset.
        Report.Run(Report::"FR Financial Schedule");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Ratio, components and prior-year totals retain their distinct meanings.
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalNetChange', 60);
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalNetChange2', 0);
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalCurrentYear', 60);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control20', 30);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control23', 200);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeleteHeaderDeletesOnlyItsLines()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Deleting a maintained header removes its associated rows.
        Initialize();

        // [GIVEN] S owns L.
        ScheduleName.Get(TestScheduleName);
        ScheduleLine."Schedule Name" := ScheduleName.Name;
        ScheduleLine."Line No." := 10000;
        ScheduleLine.Insert(true);

        // [WHEN] S is deleted through its maintenance trigger.
        ScheduleName.Delete(true);

        // [THEN] Its child row no longer exists.
        Assert.IsFalse(ScheduleLine.Get(TestScheduleName, 10000), 'Deleting a schedule must delete its rows.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DimensionsAndBusinessUnitChangeNetSign()
    var
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        DimensionValue: Record "Dimension Value";
        BusinessUnit: Record "Business Unit";
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondaryTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Dimension and business-unit filters change sign eligibility before accumulation.
        Initialize();

        // [GIVEN] A has unfiltered net -30 but selected dimension and business unit net +60.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        BusinessUnit.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(BusinessUnit.Code));
        BusinessUnit.Insert(false);
        CreateEntry(GLAccount."No.", 20260115D, 100, 40);
        GLEntry.FindLast();
        GLEntry."Global Dimension 1 Code" := DimensionValue.Code;
        GLEntry."Business Unit Code" := BusinessUnit.Code;
        GLEntry.Modify(false);
        CreateEntry(GLAccount."No.", 20260115D, 0, 90);
        ScheduleLine.Totaling := 'NO-PRIMARY';
        ScheduleLine."Totaling Debtor" := GLAccount."No.";
        ScheduleLine.SetRange("Dimension 1 Filter", DimensionValue.Code);
        ScheduleLine.SetRange("Business Unit Filter", BusinessUnit.Code);

        // [WHEN] The selected slice is evaluated.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondaryTotal);

        // [THEN] Its positive net qualifies despite the negative all-time account balance.
        Assert.AreEqual(60, Total, 'Dimension and business-unit restrictions must precede sign selection.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NestedRowsAndTotalAccountsKeepPeriodContext()
    var
        PostingAccount: Record "G/L Account";
        TotalAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
        Total: Decimal;
        SecondaryTotal: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Nested row references and total accounts retain the leaf's filtered accounting result.
        Initialize();

        // [GIVEN] R3 totals R2 which totals R1; R1 selects a total account over posting account A.
        LibraryERM.CreateGLAccount(PostingAccount);
        CreateEntry(PostingAccount."No.", 20250115D, 900, 0);
        CreateEntry(PostingAccount."No.", 20260115D, 100, 40);
        LibraryERM.CreateGLAccount(TotalAccount);
        TotalAccount."Account Type" := TotalAccount."Account Type"::Total;
        TotalAccount.Totaling := PostingAccount."No.";
        TotalAccount.Modify(false);
        InsertScheduleLine(ScheduleLine, 10000, 'R1', TotalAccount."No.", ScheduleLine."Totaling Type"::"Total Accounts");
        InsertScheduleLine(ScheduleLine, 20000, 'R2', 'R1', ScheduleLine."Totaling Type"::Rows);
        InsertScheduleLine(ScheduleLine, 30000, 'R3', 'R2', ScheduleLine."Totaling Type"::Rows);
        ScheduleLine.SetRange("Date Filter", 20260101D, 20261231D);

        // [WHEN] The outer row is calculated.
        ScheduleReport.CalcSchedLineTotal(ScheduleLine, 0, Total, SecondaryTotal);

        // [THEN] Prior-year movements cannot leak into the nested calculation.
        Assert.AreEqual(60, Total, 'Nested total-account references must preserve execution filters.');
    end;

    [Test]
    [HandlerFunctions('ScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExplicitComparisonSignsBlankCaptionsAndPageBreaks()
    var
        PrimaryAccount: Record "G/L Account";
        SecondaryAccount: Record "G/L Account";
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Explicit comparison, opposite signs, hidden components and page breaks remain independent.
        Initialize();

        // [GIVEN] R1 has primary 100, secondary -40, explicit comparison 30 and a break after the row.
        LibraryERM.CreateGLAccount(PrimaryAccount);
        LibraryERM.CreateGLAccount(SecondaryAccount);
        CreateEntry(PrimaryAccount."No.", 20240115D, 30, 0);
        CreateEntry(PrimaryAccount."No.", 20260115D, 100, 0);
        CreateEntry(SecondaryAccount."No.", 20260115D, 0, 40);
        ScheduleName.Get(TestScheduleName);
        ScheduleName."Caption Column 1" := '';
        ScheduleName."Caption Column 2" := 'Second';
        ScheduleName.Modify(false);
        InsertScheduleLine(ScheduleLine, 10000, 'R1', PrimaryAccount."No.", ScheduleLine."Totaling Type"::"Posting Accounts");
        ScheduleLine."Totaling 2" := SecondaryAccount."No.";
        ScheduleLine."Calculate with" := ScheduleLine."Calculate with"::"Opposite Sign";
        ScheduleLine."New Page" := true;
        ScheduleLine.Modify(false);
        InsertScheduleLine(ScheduleLine, 20000, 'R2', PrimaryAccount."No.", ScheduleLine."Totaling Type"::"Posting Accounts");
        ComparisonDateFilter := StrSubstNo('%1..%2', 20240101D, 20241231D);

        // [WHEN] The report exports its dataset.
        Report.Run(Report::"FR Financial Schedule");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Hiding the primary component does not change combined totals or ratio.
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalNetChange', 0);
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalNetChange2', -40);
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalCurrentYear', -60);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control20', -30);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control23', 200);
        LibraryReportDataset.AssertElementWithValueExists('PageGroupNo', 2);
    end;

    [Test]
    [HandlerFunctions('ScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LeapClosingDateDerivesComparisonBoundary()
    var
        GLAccount: Record "G/L Account";
        ScheduleLine: Record "FR Financial Schedule Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Leap-year closing dates derive the preceding year's normal and closing boundaries.
        Initialize();

        // [GIVEN] A has closing movements on leap day and on the preceding year's last February day.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateEntry(GLAccount."No.", ClosingDate(20240229D), 60, 0);
        CreateEntry(GLAccount."No.", ClosingDate(20230228D), 30, 0);
        InsertScheduleLine(ScheduleLine, 10000, 'R1', GLAccount."No.", ScheduleLine."Totaling Type"::"Posting Accounts");
        CurrentDateFilter := StrSubstNo('%1..%2', 20240201D, ClosingDate(20240229D));

        // [WHEN] No explicit comparison period is supplied.
        Report.Run(Report::"FR Financial Schedule");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] The derived comparison includes its corresponding closing entry.
        LibraryReportDataset.AssertElementWithValueExists('Sign_TotalCurrentYear', 60);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control20', 30);
        LibraryReportDataset.AssertElementWithValueExists('Previous_Period_Control23', 200);
    end;

    local procedure Initialize()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        Migration: Codeunit "Library - Reports FR";
    begin
        Clear(ScheduleReport);
        CurrentDateFilter := StrSubstNo('%1..%2', 20260101D, 20261231D);
        Clear(ComparisonDateFilter);
#if not CLEAN30
        Clear(FeatureState);
        FeatureState.SetFeatureEnabled(true);
        BindSubscription(FeatureState);
#endif
        Migration.Migrate();
        TestScheduleName := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 10);
        ScheduleName.Name := TestScheduleName;
        ScheduleName."Caption Column 1" := 'Current';
        ScheduleName."Caption Column 3" := 'Combined';
        ScheduleName."Caption Column Previous Year" := 'Previous';
        ScheduleName.Insert(true);
    end;

    local procedure InsertScheduleLine(var ScheduleLine: Record "FR Financial Schedule Line"; LineNo: Integer; RowNo: Code[10]; Totaling: Text[250]; TotalingType: Option)
    begin
        ScheduleLine.Init();
        ScheduleLine."Schedule Name" := TestScheduleName;
        ScheduleLine."Line No." := LineNo;
        ScheduleLine."Row No." := RowNo;
        ScheduleLine.Totaling := Totaling;
        ScheduleLine."Totaling Type" := TotalingType;
        ScheduleLine.Insert(false);
    end;

    local procedure CreateNetSignFixture(var ScheduleLine: Record "FR Financial Schedule Line")
    var
        PositiveAccount: Record "G/L Account";
        NegativeAccount: Record "G/L Account";
        ZeroAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(PositiveAccount);
        LibraryERM.CreateGLAccount(NegativeAccount);
        LibraryERM.CreateGLAccount(ZeroAccount);
        CreateEntry(PositiveAccount."No.", 20260115D, 100, 40);
        CreateEntry(NegativeAccount."No.", 20260115D, 20, 50);
        CreateEntry(ZeroAccount."No.", 20260115D, 10, 10);
        ScheduleLine.Totaling := ZeroAccount."No.";
        ScheduleLine."Totaling Debtor" := PositiveAccount."No." + '|' + NegativeAccount."No." + '|' + ZeroAccount."No.";
        ScheduleLine."Totaling Creditor" := ScheduleLine."Totaling Debtor";
        ScheduleLine.SetRange("Date Filter", 20260101D, 20261231D);
    end;

    local procedure CreateEntry(AccountNo: Code[20]; PostingDate: Date; Debit: Decimal; Credit: Decimal)
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
    end;

    [RequestPageHandler]
    procedure ScheduleRequestPageHandler(var RequestPage: TestRequestPage "FR Financial Schedule")
    begin
        RequestPage."FR Acc. Schedule Name".SetFilter(Name, TestScheduleName);
        RequestPage."FR Acc. Schedule Line".SetFilter("Date Filter", CurrentDateFilter);
        RequestPage."FR Acc. Schedule Line".SetFilter("Date Filter 2", ComparisonDateFilter);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
