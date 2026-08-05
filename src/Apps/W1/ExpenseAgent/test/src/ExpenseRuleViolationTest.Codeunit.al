// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148312 "Expense Rule Violation Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure AddRuleViolationInsertsRecordWithDescription()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ViolationText: Text[500];
    begin
        // [SCENARIO] AddRuleViolation inserts a record with the given description and a non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense record.
        CreateTestExpense(Expense);
        ViolationText := 'Expense amount exceeds policy limit.';

        // [WHEN] AddRuleViolation is called.
        ExpenseRuleViolation.AddRuleViolation(Expense."No.", ViolationText);

        // [THEN] One record exists for the expense with the correct Description and a non-zero Line No.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseRuleViolation, 1);
        ExpenseRuleViolation.FindFirst();
        Assert.AreEqual(ViolationText, ExpenseRuleViolation.Description, 'Description should match the supplied violation text.');
        Assert.AreNotEqual(0, ExpenseRuleViolation."Line No.", 'Line No. should be non-zero after insert.');
    end;

    [Test]
    procedure MultipleAddRuleViolationsProduceUniqueLineNos()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        LineNo1: Integer;
        LineNo2: Integer;
    begin
        // [SCENARIO] Each call to AddRuleViolation produces a record with a distinct, non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense record.
        CreateTestExpense(Expense);

        // [WHEN] AddRuleViolation is called twice for the same expense.
        ExpenseRuleViolation.AddRuleViolation(Expense."No.", 'First violation');
        ExpenseRuleViolation.AddRuleViolation(Expense."No.", 'Second violation');

        // [THEN] Two records exist and their Line Nos. are distinct and non-zero.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseRuleViolation, 2);
        ExpenseRuleViolation.FindSet();
        LineNo1 := ExpenseRuleViolation."Line No.";
        ExpenseRuleViolation.Next();
        LineNo2 := ExpenseRuleViolation."Line No.";
        Assert.AreNotEqual(0, LineNo1, 'First Line No. must be non-zero.');
        Assert.AreNotEqual(0, LineNo2, 'Second Line No. must be non-zero.');
        Assert.AreNotEqual(LineNo1, LineNo2, 'Each record must have a unique Line No.');
    end;

    [Test]
    procedure DirectInsertWithZeroLineNoAssignsLineNo()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        // [SCENARIO] OnInsert assigns a non-zero Line No. when a record is inserted with Line No. = 0.
        Initialize();

        // [GIVEN] A valid Expense record.
        CreateTestExpense(Expense);

        // [WHEN] A rule violation is inserted directly with Line No. = 0.
        ExpenseRuleViolation."Expense No." := Expense."No.";
        ExpenseRuleViolation."Line No." := 0;
        ExpenseRuleViolation.Description := 'Direct insert with zero line no.';
        ExpenseRuleViolation.Insert(true);

        // [THEN] The record exists with a non-zero Line No. assigned by OnInsert.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.FindFirst();
        Assert.AreNotEqual(0, ExpenseRuleViolation."Line No.", 'OnInsert must assign a non-zero Line No. when Line No. is 0.');
    end;

    [Test]
    procedure DirectInsertWithNonZeroLineNoPreservesValue()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExplicitLineNo: Integer;
    begin
        // [SCENARIO] OnInsert does not overwrite an explicitly set non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense record and an explicit line number.
        CreateTestExpense(Expense);
        ExplicitLineNo := 10000;

        // [WHEN] A rule violation is inserted with an explicit non-zero Line No.
        ExpenseRuleViolation."Expense No." := Expense."No.";
        ExpenseRuleViolation."Line No." := ExplicitLineNo;
        ExpenseRuleViolation.Description := 'Explicit line no. violation';
        ExpenseRuleViolation.Insert(true);

        // [THEN] The record is retrievable by the explicit key and retains its Line No.
        Assert.IsTrue(
            ExpenseRuleViolation.Get(Expense."No.", ExplicitLineNo),
            'Record must be findable by the explicit Line No.');
        Assert.AreEqual(ExplicitLineNo, ExpenseRuleViolation."Line No.", 'Non-zero Line No. must not be overwritten by OnInsert.');
    end;

    [Test]
    procedure ClearRuleViolationsDeletesAllForExpense()
    var
        Expense1: Record Expense;
        Expense2: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        // [SCENARIO] ClearRuleViolations removes all violations for the target expense only.
        Initialize();

        // [GIVEN] Two Expense records, each with rule violations.
        CreateTestExpense(Expense1);
        CreateTestExpense(Expense2);
        ExpenseRuleViolation.AddRuleViolation(Expense1."No.", 'Violation A');
        ExpenseRuleViolation.AddRuleViolation(Expense1."No.", 'Violation B');
        ExpenseRuleViolation.AddRuleViolation(Expense2."No.", 'Violation C');

        // [WHEN] ClearRuleViolations is called for Expense1.
        ExpenseRuleViolation.ClearRuleViolations(Expense1."No.");

        // [THEN] All violations for Expense1 are deleted.
        ExpenseRuleViolation.SetRange("Expense No.", Expense1."No.");
        Assert.RecordIsEmpty(ExpenseRuleViolation);

        // [THEN] The violation for Expense2 is unaffected.
        ExpenseRuleViolation.SetRange("Expense No.", Expense2."No.");
        Assert.RecordCount(ExpenseRuleViolation, 1);
    end;

    [Test]
    procedure ClearRuleViolationsOnExpenseWithNoViolationsDoesNotError()
    var
        Expense: Record Expense;
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        // [SCENARIO] ClearRuleViolations completes without error when there are no violations for the expense.
        Initialize();

        // [GIVEN] A valid Expense with no existing rule violations.
        CreateTestExpense(Expense);

        // [WHEN] ClearRuleViolations is called.
        ExpenseRuleViolation.ClearRuleViolations(Expense."No.");

        // [THEN] No error is raised and the table remains empty for this expense.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        Assert.RecordIsEmpty(ExpenseRuleViolation);
    end;

    [Test]
    procedure AddReportRuleViolationInsertsRecordWithDescription()
    var
        ExpenseReport: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine: Record "Expense Report Line";
        ViolationText: Text[500];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] AddRuleViolation inserts a record with the given description and a non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense Report record.
        CreateTestExpenseReportHeader(ExpenseReport);
        CreateTestExpenseReportLine(ExpenseReport, ExpenseReportLine);
        ViolationText := 'Report exceeds policy limit.';

        // [WHEN] AddRuleViolation is called.
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport."No.", ExpenseReportLine."Line No.", ViolationText);

        // [THEN] One record exists for the report line with the correct Description and a non-zero Line No.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportRuleViolation, 1);
        ExpenseReportRuleViolation.FindFirst();
        Assert.AreEqual(ViolationText, ExpenseReportRuleViolation.Description, 'Description should match the supplied violation text.');
        Assert.AreNotEqual(0, ExpenseReportRuleViolation."Line No.", 'Line No. should be non-zero after insert.');
    end;

    [Test]
    procedure MultipleAddReportRuleViolationsProduceUniqueLineNos()
    var
        ExpenseReport: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine: Record "Expense Report Line";
        LineNo1: Integer;
        LineNo2: Integer;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] Each call to AddRuleViolation produces a record with a distinct, non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense Report record.
        CreateTestExpenseReportHeader(ExpenseReport);
        CreateTestExpenseReportLine(ExpenseReport, ExpenseReportLine);

        // [WHEN] AddRuleViolation is called twice for the same report line.
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport."No.", ExpenseReportLine."Line No.", 'First violation');
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport."No.", ExpenseReportLine."Line No.", 'Second violation');

        // [THEN] Two records exist and their Line Nos. are distinct and non-zero.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportRuleViolation, 2);
        ExpenseReportRuleViolation.FindSet();
        LineNo1 := ExpenseReportRuleViolation."Line No.";
        ExpenseReportRuleViolation.Next();
        LineNo2 := ExpenseReportRuleViolation."Line No.";
        Assert.AreNotEqual(0, LineNo1, 'First Line No. must be non-zero.');
        Assert.AreNotEqual(0, LineNo2, 'Second Line No. must be non-zero.');
        Assert.AreNotEqual(LineNo1, LineNo2, 'Each record must have a unique Line No.');
    end;

    [Test]
    procedure DirectReportInsertWithZeroLineNoAssignsLineNo()
    var
        ExpenseReport: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] OnInsert assigns a non-zero Line No. when a record is inserted with Line No. = 0.
        Initialize();

        // [GIVEN] A valid Expense Report record.
        CreateTestExpenseReportHeader(ExpenseReport);
        CreateTestExpenseReportLine(ExpenseReport, ExpenseReportLine);

        // [WHEN] A rule violation is inserted directly with Line No. = 0.
        ExpenseReportRuleViolation."Expense Report No." := ExpenseReport."No.";
        ExpenseReportRuleViolation."Report Line No." := ExpenseReportLine."Line No.";
        ExpenseReportRuleViolation."Line No." := 0;
        ExpenseReportRuleViolation.Description := 'Direct insert with zero line no.';
        ExpenseReportRuleViolation.Insert(true);

        // [THEN] The record exists with a non-zero Line No. assigned by OnInsert.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportRuleViolation.FindFirst();
        Assert.AreNotEqual(0, ExpenseReportRuleViolation."Line No.", 'OnInsert must assign a non-zero Line No. when Line No. is 0.');
    end;

    [Test]
    procedure DirectReportInsertWithNonZeroLineNoPreservesValue()
    var
        ExpenseReport: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine: Record "Expense Report Line";
        ExplicitLineNo: Integer;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] OnInsert does not overwrite an explicitly set non-zero Line No.
        Initialize();

        // [GIVEN] A valid Expense Report record and an explicit line number.
        CreateTestExpenseReportHeader(ExpenseReport);
        CreateTestExpenseReportLine(ExpenseReport, ExpenseReportLine);
        ExplicitLineNo := 10000;

        // [WHEN] A rule violation is inserted with an explicit non-zero Line No.
        ExpenseReportRuleViolation."Expense Report No." := ExpenseReport."No.";
        ExpenseReportRuleViolation."Report Line No." := ExpenseReportLine."Line No.";
        ExpenseReportRuleViolation."Line No." := ExplicitLineNo;
        ExpenseReportRuleViolation.Description := 'Explicit line no. violation';
        ExpenseReportRuleViolation.Insert(true);

        // [THEN] The record is retrievable by the explicit key and retains its Line No.
        Assert.IsTrue(
            ExpenseReportRuleViolation.Get(ExpenseReport."No.", ExpenseReportLine."Line No.", ExplicitLineNo),
            'Record must be findable by the explicit Line No.');
        Assert.AreEqual(ExplicitLineNo, ExpenseReportRuleViolation."Line No.", 'Non-zero Line No. must not be overwritten by OnInsert.');
    end;

    [Test]
    procedure ClearReportRuleViolationsDeletesAllForReport()
    var
        ExpenseReport1: Record "Expense Report Header";
        ExpenseReport2: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine1: Record "Expense Report Line";
        ExpenseReportLine2: Record "Expense Report Line";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] ClearRuleViolations removes all violations for the target report only.
        Initialize();

        // [GIVEN] Two Expense Report records, each with rule violations.
        CreateTestExpenseReportHeader(ExpenseReport1);
        CreateTestExpenseReportHeader(ExpenseReport2);
        CreateTestExpenseReportLine(ExpenseReport1, ExpenseReportLine1);
        CreateTestExpenseReportLine(ExpenseReport2, ExpenseReportLine2);
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport1."No.", ExpenseReportLine1."Line No.", 'Violation A');
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport1."No.", ExpenseReportLine1."Line No.", 'Violation B');
        ExpenseReportRuleViolation.AddRuleViolation(ExpenseReport2."No.", ExpenseReportLine2."Line No.", 'Violation C');

        // [WHEN] ClearRuleViolations is called for ExpenseReport1.
        ExpenseReportRuleViolation.ClearRuleViolations(ExpenseReport1."No.", ExpenseReportLine1."Line No.");

        // [THEN] All violations for ExpenseReport1 are deleted.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport1."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine1."Line No.");
        Assert.RecordIsEmpty(ExpenseReportRuleViolation);

        // [THEN] The violation for ExpenseReport2 is unaffected.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport2."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine2."Line No.");
        Assert.RecordCount(ExpenseReportRuleViolation, 1);
    end;

    [Test]
    procedure ClearReportRuleViolationsOnReportWithNoViolationsDoesNotError()
    var
        ExpenseReport: Record "Expense Report Header";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 624852] ClearRuleViolations completes without error when there are no violations for the report.
        Initialize();

        // [GIVEN] A valid Expense Report with no existing rule violations.
        CreateTestExpenseReportHeader(ExpenseReport);
        CreateTestExpenseReportLine(ExpenseReport, ExpenseReportLine);

        // [WHEN] ClearRuleViolations is called.
        ExpenseReportRuleViolation.ClearRuleViolations(ExpenseReport."No.", ExpenseReportLine."Line No.");

        // [THEN] No error is raised and the table remains empty for this report line.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReport."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        Assert.RecordIsEmpty(ExpenseReportRuleViolation);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Rule Violation Test");
        LibraryExpense.CleanUpBeforeTesting();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Rule Violation Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Rule Violation Test");
    end;

    local procedure CreateTestExpense(var Expense: Record Expense)
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateTestExpenseReportHeader(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
    end;

    local procedure CreateTestExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine,
            ExpenseReportHeader,
            ExpenseReportHeader."Expense User No.",
            ExpenseCategory.Code,
            '',
            true,
            '',
            LibraryRandom.RandIntInRange(10, 100));
    end;
}
