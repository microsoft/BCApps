// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.HumanResources.Employee;

codeunit 148312 "Expense Rule Violation Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        EmployeePostingGroupMandatoryErr: Label '%1 is mandatory on %2 %3.', Comment = '%1 = Field Caption, %2 = Table Caption, %3 = Employee No.';
        EmployeePostingGroupMandatoryOnExpenseReportErr: Label '%1 is mandatory on Expense Report No. %2.', Comment = '%1 = Field Caption, %2 = Expense Report No.';
        ExpenseItemizationCurrencyMismatchErr: Label '%1 on %2 must be the same as %1 on %3 in Expense No.=%4, Line No.=%5.', Comment = '%1 = Currency Code field caption, %2 = Expense Itemization table caption, %3 = Expense table caption, %4 = Expense No., %5 = Line No.';
        ExpenseReportItemizationCurrencyMismatchErr: Label '%1 on %2 must be the same as %3 on %4 in Expense Report No.=%5, Expense Report Line No.=%6, Line No.=%7.', Comment = '%1 = Currency Code field caption, %2 = Expense Report Line Item table caption, %3 = Expense Currency Code field caption, %4 = Expense Report Line table caption, %5 = Expense Report No., %6 = Expense Report Line No., %7 = Line No.';

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

    [Test]
    procedure ExpenseValidationWithMissingEmployeePostingGroupCreatesRuleViolation()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [Expense Agent] [Rule Violation]
        // [SCENARIO 645043] Validating an expense for an expense user whose linked employee has a missing employee posting group creates a rule violation.
        Initialize();

        // [GIVEN] Expense user linked to employee "E1" with blank "Employee Posting Group", and an expense created for "E1".
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        Employee.Validate("Employee Posting Group", '');
        Employee.Modify(true);
        CreateTestExpenseForUser(Expense, ExpenseUser."No.");

        // [WHEN] Validate expense against rules is executed.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] Expense rule violation is created stating "Employee Posting Group" is mandatory on employee "E1".
        VerifyExpenseRuleViolation(
            Expense."No.",
            StrSubstNo(EmployeePostingGroupMandatoryErr, Employee.FieldCaption("Employee Posting Group"), Employee.TableCaption(), Employee."No."));
    end;

    [Test]
    procedure ExpenseValidationWithEmployeePostingGroupCreatesNoRuleViolation()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [Expense Agent] [Rule Violation]
        // [SCENARIO 645043] Validating an expense for an expense user whose linked employee has a valid employee posting group does not create a rule violation.
        Initialize();

        // [GIVEN] Expense user linked to employee "E1" with a non-blank "Employee Posting Group", and an expense created for "E1".
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        Employee.Validate("Employee Posting Group", LibraryHumanResource.FindEmployeePostingGroup());
        Employee.Modify(true);
        CreateTestExpenseForUser(Expense, ExpenseUser."No.");

        // [WHEN] Validate expense against rules is executed.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] No employee posting group rule violation exists for the expense.
        VerifyNoExpenseRuleViolation(Expense."No.");
    end;

    [Test]
    procedure ExpenseReportLineValidationWithMissingEmployeePostingGroupCreatesRuleViolation()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [Expense Agent] [Rule Violation]
        // [SCENARIO 645043] Validating an expense report line when the report header has a missing employee posting group creates a report rule violation.
        Initialize();

        // [GIVEN] Expense report header "H1" with blank "Employee Posting Group" and expense report line "L1".
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        Employee.Validate("Employee Posting Group", '');
        Employee.Modify(true);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        CreateTestExpenseReportLine(ExpenseReportHeader, ExpenseReportLine);

        // [WHEN] Validate expense report line against rules is executed.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] Expense report rule violation is created stating "Employee Posting Group" is mandatory on expense report "H1".
        VerifyExpenseReportRuleViolation(
            ExpenseReportHeader."No.",
            ExpenseReportLine."Line No.",
            StrSubstNo(EmployeePostingGroupMandatoryOnExpenseReportErr, ExpenseReportHeader.FieldCaption("Employee Posting Group"), ExpenseReportHeader."No."));
    end;

    [Test]
    procedure UpdatingEmployeePostingGroupOnExpenseReportHeaderClearsLineRuleViolation()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [Expense Agent] [Rule Violation]
        // [SCENARIO 645043] Updating "Employee Posting Group" on expense report header "H1" automatically re-evaluates line "L1" and clears the rule violation.
        Initialize();

        // [GIVEN] Expense report header "H1" with blank "Employee Posting Group" and line "L1" having a rule violation.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        Employee.Validate("Employee Posting Group", '');
        Employee.Modify(true);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        CreateTestExpenseReportLine(ExpenseReportHeader, ExpenseReportLine);
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
        VerifyExpenseReportRuleViolation(
            ExpenseReportHeader."No.",
            ExpenseReportLine."Line No.",
            StrSubstNo(EmployeePostingGroupMandatoryOnExpenseReportErr, ExpenseReportHeader.FieldCaption("Employee Posting Group"), ExpenseReportHeader."No."));

        // [WHEN] "Employee Posting Group" on header "H1" is updated to a valid value.
        ExpenseReportHeader.Validate("Employee Posting Group", LibraryHumanResource.FindEmployeePostingGroup());
        ExpenseReportHeader.Modify(true);

        // [THEN] Expense report line "L1" rule violation for "Employee Posting Group" is cleared.
        VerifyNoExpenseReportRuleViolation(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");
    end;

    [Test]
    procedure ExpenseValidationWithItemizationCurrencyMismatchCreatesRuleViolation()
    var
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Validating an expense whose itemization has a different currency than the expense creates a rule violation.
        Initialize();

        // [GIVEN] Expense "E1" in currency "FCY" with an itemization whose currency is changed to blank.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateItemizedExpense(Expense, ExpenseItemization, CurrencyCode, 10, 1);
        ExpenseItemization."Currency Code" := '';
        ExpenseItemization.Modify(false);

        // [WHEN] Validate expense against rules is executed.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] A rule violation states that the itemization currency must be the same as the expense currency.
        VerifyExpenseRuleViolationExists(Expense."No.", GetExpenseItemizationCurrencyMismatchMessage(Expense, ExpenseItemization));
    end;

    [Test]
    procedure ExpenseValidationWithMatchingItemizationCurrencyCreatesNoCurrencyRuleViolation()
    var
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Validating an expense whose itemization has the same currency as the expense does not create a currency rule violation.
        Initialize();

        // [GIVEN] Expense "E1" in currency "FCY" with an itemization created in the same currency.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateItemizedExpense(Expense, ExpenseItemization, CurrencyCode, 10, 1);

        // [WHEN] Validate expense against rules is executed.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] No currency mismatch rule violation exists.
        VerifyNoExpenseRuleViolationWithDescription(Expense."No.", GetExpenseItemizationCurrencyMismatchMessage(Expense, ExpenseItemization));
    end;

    [Test]
    procedure ExpenseReportLineValidationWithItemizationCurrencyMismatchCreatesRuleViolation()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Validating an expense report line whose itemization has a different currency than the line creates a report rule violation.
        Initialize();

        // [GIVEN] Expense report line "L1" in currency "FCY" with an itemization whose currency is changed to blank.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateItemizedExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineItem, CurrencyCode, 10, 1);
        ExpenseReportLineItem."Currency Code" := '';
        ExpenseReportLineItem.Modify(false);

        // [WHEN] Validate expense report line against rules is executed.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] A report rule violation states that the itemization currency must be the same as the expense currency.
        VerifyExpenseReportRuleViolationExists(
            ExpenseReportHeader."No.", ExpenseReportLine."Line No.",
            GetExpenseReportItemizationCurrencyMismatchMessage(ExpenseReportLine, ExpenseReportLineItem));
    end;

    [Test]
    procedure ExpenseReportLineValidationWithMatchingItemizationCurrencyCreatesNoCurrencyRuleViolation()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Validating an expense report line whose itemization has the same currency as the line does not create a currency rule violation.
        Initialize();

        // [GIVEN] Expense report line "L1" in currency "FCY" with an itemization created in the same currency.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateItemizedExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineItem, CurrencyCode, 10, 1);

        // [WHEN] Validate expense report line against rules is executed.
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] No currency mismatch report rule violation exists.
        VerifyNoExpenseReportRuleViolationWithDescription(
            ExpenseReportHeader."No.", ExpenseReportLine."Line No.",
            GetExpenseReportItemizationCurrencyMismatchMessage(ExpenseReportLine, ExpenseReportLineItem));
    end;

    [Test]
    procedure ExpenseItemizationInheritsExpenseCurrencyOnInsert()
    var
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] A new expense itemization takes the currency of its expense.
        Initialize();

        // [GIVEN] Expense "E1" in currency "FCY".
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);

        // [WHEN] An itemization is created for expense "E1".
        CreateItemizedExpense(Expense, ExpenseItemization, CurrencyCode, 10, 1);

        // [THEN] The itemization "Currency Code" is "FCY".
        ExpenseItemization.Get(ExpenseItemization."Expense No.", ExpenseItemization."Line No.");
        Assert.AreEqual(CurrencyCode, ExpenseItemization."Currency Code", 'Itemization currency should match the expense currency.');
    end;

    [Test]
    procedure ExpenseReportLineItemizationInheritsLineCurrencyOnInsert()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] A new expense report line itemization takes the expense currency of its line.
        Initialize();

        // [GIVEN] Expense report line "L1" in currency "FCY".
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);

        // [WHEN] An itemization is created for line "L1".
        CreateItemizedExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineItem, CurrencyCode, 10, 1);

        // [THEN] The itemization "Currency Code" is "FCY".
        ExpenseReportLineItem.Get(ExpenseReportLineItem."Expense Report No.", ExpenseReportLineItem."Expense Report Line No.", ExpenseReportLineItem."Line No.");
        Assert.AreEqual(CurrencyCode, ExpenseReportLineItem."Currency Code", 'Itemization currency should match the expense report line currency.');
    end;

    [Test]
    procedure ApplyRuleUpdatesExpenseItemizationCurrencyAndRounding()
    var
        Currency: Record Currency;
        Expense: Record Expense;
        ExpenseItemization: Record "Expense Itemization";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Applying the rule after the expense currency changed updates the itemization currency and rounds amounts with the new currency precision.
        Initialize();

        // [GIVEN] Currency "FCY" with amount rounding precision 1 and expense "E1" in local currency with an itemization of daily rate 10.5 and quantity 2.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Currency.Get(CurrencyCode);
        Currency."Amount Rounding Precision" := 1;
        Currency.Modify();
        CreateItemizedExpense(Expense, ExpenseItemization, '', 10.5, 2);

        // [GIVEN] The expense currency is changed to "FCY".
        Expense."Currency Code" := CurrencyCode;
        Expense.Modify();

        // [WHEN] Rule is applied on expense "E1".
        Expense.ApplyRule();

        // [THEN] The itemization currency is "FCY", the daily rate is rounded to 11 and the amount is 22.
        ExpenseItemization.Get(ExpenseItemization."Expense No.", ExpenseItemization."Line No.");
        Assert.AreEqual(CurrencyCode, ExpenseItemization."Currency Code", 'Itemization currency should be updated to the expense currency.');
        Assert.AreEqual(11, ExpenseItemization."Daily Rate", 'Daily rate should be rounded with the expense currency precision.');
        Assert.AreEqual(22, ExpenseItemization.Amount, 'Amount should be recalculated from the rounded daily rate.');
    end;

    [Test]
    procedure ApplyRuleUpdatesExpenseReportLineItemizationCurrencyAndRounding()
    var
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 656372] Applying the rule after the expense report line currency changed updates the itemization currency and rounds amounts with the new currency precision.
        Initialize();

        // [GIVEN] Currency "FCY" with amount rounding precision 1 and line "L1" in local currency with an itemization of daily rate 10.5 and quantity 2.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        Currency.Get(CurrencyCode);
        Currency."Amount Rounding Precision" := 1;
        Currency.Modify();
        CreateItemizedExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, ExpenseReportLineItem, '', 10.5, 2);

        // [GIVEN] The line expense currency is changed to "FCY".
        ExpenseReportLine."Expense Currency Code" := CurrencyCode;
        ExpenseReportLine.Modify();

        // [WHEN] Rule is applied on line "L1".
        ExpenseReportLine.ApplyRule();

        // [THEN] The itemization currency is "FCY", the daily rate is rounded to 11 and the amount is 22.
        ExpenseReportLineItem.Get(ExpenseReportLineItem."Expense Report No.", ExpenseReportLineItem."Expense Report Line No.", ExpenseReportLineItem."Line No.");
        Assert.AreEqual(CurrencyCode, ExpenseReportLineItem."Currency Code", 'Itemization currency should be updated to the expense report line currency.');
        Assert.AreEqual(11, ExpenseReportLineItem."Daily Rate", 'Daily rate should be rounded with the line currency precision.');
        Assert.AreEqual(22, ExpenseReportLineItem.Amount, 'Amount should be recalculated from the rounded daily rate.');
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

    local procedure CreateTestExpenseForUser(var Expense: Record Expense; ExpenseUserNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
    begin
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        LibraryExpense.CreateExpense(Expense, ExpenseUserNo, ExpenseCategory.Code, '', '', true, '', LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateItemizedExpense(var Expense: Record Expense; var ExpenseItemization: Record "Expense Itemization"; CurrencyCode: Code[10]; DailyRate: Decimal; Quantity: Decimal)
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, CurrencyCode, LibraryRandom.RandIntInRange(100, 200));
        Expense."Expense Detail Required" := Expense."Expense Detail Required"::Itemize;
        Expense.Modify();
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), DailyRate, Quantity);
    end;

    local procedure CreateItemizedExpenseReportLine(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; var ExpenseReportLineItem: Record "Expense Report Line Item"; CurrencyCode: Code[10]; DailyRate: Decimal; Quantity: Decimal)
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, CurrencyCode, LibraryRandom.RandIntInRange(100, 200));
        ExpenseReportLine."Expense Detail Required" := ExpenseReportLine."Expense Detail Required"::Itemize;
        ExpenseReportLine.Modify();
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategory.Code, WorkDate(), DailyRate, Quantity);
    end;

    local procedure GetExpenseItemizationCurrencyMismatchMessage(Expense: Record Expense; ExpenseItemization: Record "Expense Itemization"): Text
    begin
        exit(
            StrSubstNo(
                ExpenseItemizationCurrencyMismatchErr,
                ExpenseItemization.FieldCaption("Currency Code"), ExpenseItemization.TableCaption(), Expense.TableCaption(),
                ExpenseItemization."Expense No.", ExpenseItemization."Line No."));
    end;

    local procedure GetExpenseReportItemizationCurrencyMismatchMessage(ExpenseReportLine: Record "Expense Report Line"; ExpenseReportLineItem: Record "Expense Report Line Item"): Text
    begin
        exit(
            StrSubstNo(
                ExpenseReportItemizationCurrencyMismatchErr,
                ExpenseReportLineItem.FieldCaption("Currency Code"), ExpenseReportLineItem.TableCaption(),
                ExpenseReportLine.FieldCaption("Expense Currency Code"), ExpenseReportLine.TableCaption(),
                ExpenseReportLineItem."Expense Report No.", ExpenseReportLineItem."Expense Report Line No.", ExpenseReportLineItem."Line No."));
    end;

    local procedure VerifyExpenseRuleViolationExists(ExpenseNo: Code[20]; ExpectedDescription: Text)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseNo);
        ExpenseRuleViolation.SetRange(Description, CopyStr(ExpectedDescription, 1, MaxStrLen(ExpenseRuleViolation.Description)));
        Assert.RecordCount(ExpenseRuleViolation, 1);
    end;

    local procedure VerifyNoExpenseRuleViolationWithDescription(ExpenseNo: Code[20]; Description: Text)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseNo);
        ExpenseRuleViolation.SetRange(Description, CopyStr(Description, 1, MaxStrLen(ExpenseRuleViolation.Description)));
        Assert.RecordIsEmpty(ExpenseRuleViolation);
    end;

    local procedure VerifyExpenseReportRuleViolationExists(ReportNo: Code[20]; ReportLineNo: Integer; ExpectedDescription: Text)
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ReportNo);
        ExpenseReportRuleViolation.SetRange("Report Line No.", ReportLineNo);
        ExpenseReportRuleViolation.SetRange(Description, CopyStr(ExpectedDescription, 1, MaxStrLen(ExpenseReportRuleViolation.Description)));
        Assert.RecordCount(ExpenseReportRuleViolation, 1);
    end;

    local procedure VerifyNoExpenseReportRuleViolationWithDescription(ReportNo: Code[20]; ReportLineNo: Integer; Description: Text)
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ReportNo);
        ExpenseReportRuleViolation.SetRange("Report Line No.", ReportLineNo);
        ExpenseReportRuleViolation.SetRange(Description, CopyStr(Description, 1, MaxStrLen(ExpenseReportRuleViolation.Description)));
        Assert.RecordIsEmpty(ExpenseReportRuleViolation);
    end;

    local procedure VerifyExpenseRuleViolation(ExpenseNo: Code[20]; ExpectedDescription: Text)
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseNo);
        Assert.RecordCount(ExpenseRuleViolation, 1);
        ExpenseRuleViolation.FindFirst();
        Assert.AreEqual(ExpectedDescription, ExpenseRuleViolation.Description, 'Rule violation description should match.');
    end;

    local procedure VerifyNoExpenseRuleViolation(ExpenseNo: Code[20])
    var
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseNo);
        Assert.RecordIsEmpty(ExpenseRuleViolation);
    end;

    local procedure VerifyExpenseReportRuleViolation(ReportNo: Code[20]; ReportLineNo: Integer; ExpectedDescription: Text)
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ReportNo);
        ExpenseReportRuleViolation.SetRange("Report Line No.", ReportLineNo);
        Assert.RecordCount(ExpenseReportRuleViolation, 1);
        ExpenseReportRuleViolation.FindFirst();
        Assert.AreEqual(ExpectedDescription, ExpenseReportRuleViolation.Description, 'Report rule violation description should match.');
    end;

    local procedure VerifyNoExpenseReportRuleViolation(ReportNo: Code[20]; ReportLineNo: Integer)
    var
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
    begin
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ReportNo);
        ExpenseReportRuleViolation.SetRange("Report Line No.", ReportLineNo);
        Assert.RecordIsEmpty(ExpenseReportRuleViolation);
    end;
}
