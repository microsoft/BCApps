// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using System.Automation;
using System.TestLibraries.Utilities;

codeunit 148301 "Expense Rule Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        JustificationRequiredErr: Label 'Justification is required for this expense based on your organization''s rule.';
        ItemizationRequiredErr: Label 'Itemization is required for this expense based on your organization''s rule.';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        FixAmountErr: Label 'Amount must equal %1 as defined by rule.', Comment = '%1 = Required fixed amount';
        MaxAmountErr: Label 'Amount must not exceed %1 as defined by rule.', Comment = '%1 = Maximum allowed amount';
        MinAmountErr: Label 'Amount must be at least %1 as defined by rule.', Comment = '%1 = Minimum required amount';
        ParticipantsRequiredErr: Label 'Participants are required for this expense based on your organization''s rule.';
        DailyRateConditionMissingForRangeErr: Label 'You can''t set %1 to %2 for the %3 %4. Because this expense category requires Per Diem details, %1 must be %5.', Comment = '%1 = Condition Type field caption, %2 = Condition Type value entered, %3 = Expense Category Code field caption, %4 = Expense Category Code value, %5 = Daily Rate condition type';
        RuleValidationSuccessMsg: Label 'Expense has been successfully validated against your organization''s rules.';
        CannotAddItemizationErr: Label 'Cannot add Itemizations to Expense No. %1 as there is no applicable Expense Rule that requires itemizations.', Comment = '%1 - Expense No.';
        FieldShouldBeEditableErr: Label '%1 should be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        RuleRestrictOnlyItemizationErr: Label 'Your organization''s rule requires only Itemization details for this expense. Please remove the extra %1 and try again.', Comment = '%1 = Extra detail types found (e.g., Participants, Per Diem, Mileage)';
        ParticipantsItemizationLbl: Label 'Participants/Itemization';
        PerDiemLbl: Label 'Per Diem';
        MileageLbl: Label 'Mileage';
        AndLbl: Label ' and ';
        AdditionalDetailsLbl: Label 'additional details';
        PerDiemForLbl: Label 'Per Diem for: %1', Comment = '%1 = Date';
        MissingExpenseSubCategoryErr: Label 'Expense Subcategories is required in order to add Itemization detail(s) for expense category code %1.', Comment = '%1 = Expense Category Code';

    [Test]
    procedure AmountLCYIsConvertedBasedOnCurrencyInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Amount (LCY)" is converted based on currency When Amount is updated in expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense.
        CreateExpense(Expense, CurrencyCode, Amount);

        // [THEN] Verify that the "Amount (LCY)" is converted based on currency in expense.
        Assert.AreEqual(
            ExpectedAmountLCY,
            Expense."Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Amount (LCY)"), ExpectedAmountLCY, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseItemizationMustFlowToExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "Expense Itemization" must flow to Expense Report When GetExpenseLine is invoked in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that the "Expense Itemization" must flow to Expense Report.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLineItem, 1);
        Assert.AreEqual(
            ExpenseItemization."Expense No.",
            ExpenseReportLineItem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Expense No."), ExpenseItemization."Expense No.", ExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseItemization.Description,
            ExpenseReportLineItem.Description,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Description"), ExpenseItemization.Description, ExpenseReportLineItem.TableCaption()));

        // [THEN] Verify that the "Expense Itemization Line" must flow to Expense Report Itemization Line.
        FindExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLineItem, 1);
        Assert.AreEqual(
            ExpenseItemization."Expense No.",
            ExpenseReportLineItem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Expense No."), ExpenseItemization."Expense No.", ExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseItemization."Start Date",
            ExpenseReportLineItem."Start Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Start Date"), ExpenseItemization."Start Date", ExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseItemization."Daily Rate",
            ExpenseReportLineItem."Daily Rate",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Daily Rate"), ExpenseItemization."Daily Rate", ExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseItemization.Quantity,
            ExpenseReportLineItem.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Quantity"), ExpenseItemization.Quantity, ExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseItemization."Amount",
            ExpenseReportLineItem."Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineItem.FieldCaption("Amount"), ExpenseItemization."Amount", ExpenseReportLineItem.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportItemizationMustFlowToPostedExpenseReportItemization()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLineItem: Record "Posted Exp. Rep. Line Item";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "Expense Report Itemization" must flow to Posted Expense Report Itemization.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line, Expense Report Line Itemization and Expense Report Itemization Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportNo, ExpenseReportLine);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that the "Expense Report Itemization" must flow to Posted Expense Report Itemization.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLineItem(PostedExpenseReportLineItem, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLineItem, 1);
        Assert.AreEqual(
            ExpenseReportLineItem."Expense No.",
            PostedExpenseReportLineItem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Expense No."), ExpenseReportLineItem."Expense No.", PostedExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineItem.Description,
            PostedExpenseReportLineItem.Description,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Description"), ExpenseReportLineItem.Description, PostedExpenseReportLineItem.TableCaption()));

        // [THEN] Verify that the "Expense Report Itemization Line" must flow to Posted Expense Report Itemization Line.
        FindPostedExpenseReportLineItem(PostedExpenseReportLineItem, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLineItem, 1);
        Assert.AreEqual(
            ExpenseReportLineItem."Expense No.",
            PostedExpenseReportLineItem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Expense No."), ExpenseReportLineItem."Expense No.", PostedExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineItem."Start Date",
            PostedExpenseReportLineItem."Start Date",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Start Date"), ExpenseReportLineItem."Start Date", PostedExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineItem."Daily Rate",
            PostedExpenseReportLineItem."Daily Rate",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Daily Rate"), ExpenseReportLineItem."Daily Rate", PostedExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineItem.Quantity,
            PostedExpenseReportLineItem.Quantity,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Quantity"), ExpenseReportLineItem.Quantity, PostedExpenseReportLineItem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineItem."Amount",
            PostedExpenseReportLineItem."Amount",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineItem.FieldCaption("Amount"), ExpenseReportLineItem."Amount", PostedExpenseReportLineItem.TableCaption()));
    end;

    [Test]
    procedure JustificationRequiredWhenExpenseIsReleasedForItemization()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Justification Required" When Expense is released with rule "Justification Required" as "Always".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::"Always", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [WHEN] Apply rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    procedure ItemizationRequiredWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Itemization Required" When Expense is released.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Delete Expense Itemization.
        ExpenseItemization.Delete(true);

        // [WHEN] Apply rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Itemization Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(ItemizationRequiredErr);
    end;

    [Test]
    procedure ItemizationTotalMismatchWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Itemization Total Mismatch" When Expense is released.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount - 1, LibraryRandom.RandInt(1));

        // [WHEN] Apply rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Itemization Total Mismatch".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalMismatchErr, Amount - 1, Expense.Amount));
    end;

    [Test]
    procedure ExpenseItemizationIsOnlyRequiredWhenExpenseIsItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Itemization" is only required when Expense is "Itemized" in Expense rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Release Expense.
        Expense.ApplyRule(false, true);

        // [THEN] Verify that the "Expense Itemization" is only required when Expense is "Itemized".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(
            StrSubstNo(
                RuleRestrictOnlyItemizationErr,
                BuildExtraDetailsMessage(true, false, false)));
    end;

    [Test]
    procedure CurrencyIsNotUpdatedInExpenseBasedOnRuleItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Currency Code" is not updated in Expense based on Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that Currency is updated in Expense.
        Assert.AreEqual(
            CurrencyCode,
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), CurrencyCode, Expense.TableCaption()));

        // [GIVEN] Remove Currency Code from Expense.
        Expense.Validate("Currency Code", '');
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that the "Currency Code" is not updated in Expense based on Rule Per Diem.
        Assert.AreEqual(
            '',
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure FixAmountIsRequiredInExpenseBasedOnRuleItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Fix Amount" is required in Expense based on Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount - 1, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Fix Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount - 1, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Fix Amount" is required in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(FixAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    procedure MaxAmountIsNotExceededInExpenseBasedOnRuleItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Max Amount" is not exceeded in Expense based on Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount + 1, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount + 1, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Max Amount" is not exceeded in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    procedure MinAmountIsNotExceededInExpenseBasedOnRuleItemized()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Min Amount" is not exceeded in Expense based on Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount - 1, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Min Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount - 1, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Min Amount" is not exceeded in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MinAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseParticipantMustFlowToExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that Expense Participant flows to the Expense Report when GetExpenseLine is invoked.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Release Expense.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that the Expense Participant flowed to the Expense Report participant.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLineParticipant, 1);
        Assert.AreEqual(
            Expense."No.",
            ExpenseReportLineParticipant."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Expense No."), Expense."No.", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            ExpenseParticipant."Participant Employee No.",
            ExpenseReportLineParticipant."Participant Employee No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), ExpenseParticipant."Participant Employee No.", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            ExpenseParticipant."Participant Name",
            ExpenseReportLineParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Name"), ExpenseParticipant."Participant Name", ExpenseReportLineParticipant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportParticipantMustFlowToPostedExpenseReportParticipant()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLineParticipant: Record "Posted Exp. Rep. Line Particip";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "Expense Report Participant" must flow to Posted Expense Report Participant.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line & Participant.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that the "Expense Report Participant" must flow to Posted Expense Report Participant.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLineParticipant(PostedExpenseReportLineParticipant, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLineParticipant, 1);
        Assert.AreEqual(
            ExpenseReportLineParticipant."Expense No.",
            PostedExpenseReportLineParticipant."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineParticipant.FieldCaption("Expense No."), ExpenseReportLineParticipant."Expense No.", PostedExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineParticipant."Participant Employee No.",
            PostedExpenseReportLineParticipant."Participant Employee No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineParticipant.FieldCaption("Participant Employee No."), ExpenseReportLineParticipant."Participant Employee No.", PostedExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLineParticipant."Participant Name",
            PostedExpenseReportLineParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLineParticipant.FieldCaption("Participant Name"), ExpenseReportLineParticipant."Participant Name", PostedExpenseReportLineParticipant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleExpenseReportParticipantMustFlowToPostedExpenseReportParticipant()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLineParticipant: Record "Posted Exp. Rep. Line Particip";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the multiple "Expense Report Participant" must flow to Posted Expense Report Participant.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Create another Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line & Participant.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that the multiple "Expense Report Participant" must flow to Posted Expense Report Participant.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLineParticipant(PostedExpenseReportLineParticipant, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLineParticipant, 2);
    end;

    [Test]
    procedure JustificationRequiredWhenExpenseIsReleasedForParticipant()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Justification Required" When Expense is released with Rule "Justification Required" as "Always".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::"Always", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    procedure ParticipantRequiredWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Participant Required" When Expense is released.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Delete Expense Participant.
        ExpenseParticipant.Delete(true);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Participant Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);
    end;

    [Test]
    procedure ExpenseParticipantIsOnlyRequiredWhenExpenseIsParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Participant" is only required when Expense is "Participants" in Expense Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [WHEN] Create Expense Itemization.
        asserterror LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [THEN] Verify that system must throw an error of "Expense Participant" is only required when Expense is "Participants".
        Assert.ExpectedError(StrSubstNo(CannotAddItemizationErr, Expense."No."));
    end;

    [Test]
    procedure CurrencyIsNotUpdatedInExpenseBasedOnRuleParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Currency Code" is not updated in Expense based on Rule Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that Currency is updated in Expense.
        Assert.AreEqual(
            CurrencyCode,
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), CurrencyCode, Expense.TableCaption()));

        // [GIVEN] Remove Currency Code from Expense.
        Expense.Validate("Currency Code", '');
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Release Expense with violations.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [THEN] Verify that system must not throw an error while releasing Expense.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Status"), Expense.Status::Released, Expense.TableCaption()));

        // [GIVEN] Reopen Expense.
        Expense.SetRange("No.", Expense."No.");
        Expense.PerformManualReopen(Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.Get(Expense."No.");
        Expense.ApplyRule();

        // [THEN] Verify that Currency is not updated in Expense based on Rule Per Diem.
        Assert.AreEqual(
            '',
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure FixAmountIsRequiredInExpenseBasedOnRuleParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Fix Amount" is required in Expense based on Rule Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount - 1, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Fix Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Fix Amount" is required in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(FixAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    procedure MaxAmountIsNotExceededInExpenseBasedOnRuleParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Max Amount" is not exceeded in Expense based on Rule Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount + 1, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Max Amount" is not exceeded in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    procedure MinAmountIsNotExceededInExpenseBasedOnRuleParticipants()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Min Amount" is not exceeded in Expense based on Rule Participants.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participant".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount - 1, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Min Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Min Amount" is not exceeded in Expense based on Rule.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MinAmountErr, ExpenseRuleCondition.Value));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpensePerDiemMustFlowToExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that Expense Per Diem flows to the Expense Report when GetExpenseLine is invoked.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that the Expense Per Diem flowed to the Expense Report Per Diem.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);
        Assert.AreEqual(
            Expense."No.",
            ExpenseReportLinePerDiem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense No."), Expense."No.", ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            Expense."Expense Category",
            ExpenseReportLinePerDiem."Expense Category Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense Category Code"), Expense."Expense Category", ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            Expense."Expense Subcategory",
            ExpenseReportLinePerDiem."Expense Subcategory Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense Subcategory Code"), Expense."Expense Subcategory", ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            Expense."Expense Location",
            ExpenseReportLinePerDiem."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Expense Location"), Expense."Expense Location", ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            DT2Date(Expense."Starting Date and Time"),
            ExpenseReportLinePerDiem.Date,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Date"), DT2Date(Expense."Starting Date and Time"), ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            Expense.Amount,
            ExpenseReportLinePerDiem."Per Diem Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Per Diem Amount"), Expense.Amount, ExpenseReportLinePerDiem.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportPerDiemMustFlowToPostedExpenseReportPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the "Expense Report Per Diem" must flow to Posted Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line & Per Diem.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportNo, ExpenseReportLine);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that the "Expense Report Per Diem" must flow to Posted Expense Report Per Diem.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLinePerDiem(PostedExpenseReportLinePerDiem, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLinePerDiem, 1);
        Assert.AreEqual(
            ExpenseReportLinePerDiem."Expense No.",
            PostedExpenseReportLinePerDiem."Expense No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Expense No."), ExpenseReportLinePerDiem."Expense No.", PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLinePerDiem."Expense Category Code",
            PostedExpenseReportLinePerDiem."Expense Category Code",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Expense Category Code"), ExpenseReportLinePerDiem."Expense Category Code", PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLinePerDiem."Expense Subcategory Code",
            PostedExpenseReportLinePerDiem."Expense Subcategory Code",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Expense Subcategory Code"), ExpenseReportLinePerDiem."Expense Subcategory Code", PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLinePerDiem."Expense Location",
            PostedExpenseReportLinePerDiem."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Expense Location"), ExpenseReportLinePerDiem."Expense Location", PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLinePerDiem.Date,
            PostedExpenseReportLinePerDiem.Date,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Date"), ExpenseReportLinePerDiem.Date, PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLinePerDiem."Per Diem Amount",
            PostedExpenseReportLinePerDiem."Per Diem Amount",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Per Diem Amount"), ExpenseReportLinePerDiem."Per Diem Amount", PostedExpenseReportLinePerDiem.TableCaption()));
    end;

    [Test]
    procedure JustificationRequiredWhenExpenseIsReleasedForPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Justification Required" When Expense is released with Rule "Justification Required" as "Always".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::"Always", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    procedure ExpensePerDiemIsCreatedWhenExpenseRuleIsApplied()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePerDiem: Record "Expense Per Diem";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Per Diem" is created when Expense Rule is applied.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [THEN] Verify that the "Expense Per Diem" is created when Expense Rule is applied.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 1);
    end;

    [Test]
    procedure ExpensePerDiemIsOnlyRequiredWhenExpenseIsPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Expense Per Diem" is only required when Expense is "Per Diem" in Expense Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [WHEN] Create Expense Itemization.
        asserterror LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [THEN] Verify that system must throw an error of Cannot add Itemization when Expense is Per Diem.
        Assert.ExpectedError(StrSubstNo(CannotAddItemizationErr, Expense."No."));
    end;

    [Test]
    procedure CurrencyIsUpdatedInExpenseBasedOnRulePerDiemWhenApplyRuleIsExecuted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Currency" is updated in Expense based on Rule "Per Diem" when ApplyRule is executed.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Remove Currency Code from Expense.
        Expense.Validate("Currency Code", '');
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that the "Currency" is updated in Expense based on Rule "Per Diem".
        Assert.AreEqual(
            CurrencyCode,
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), CurrencyCode, Expense.TableCaption()));
    end;

    [Test]
    procedure DailyRateIsRequiredInExpenseBasedOnRulePerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the "Daily Rate" is required in Expense based on Rule "Per Diem".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Per Diem".
        asserterror CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount - 1, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Fix Amount", true, Amount);

        // [THEN] Verify that system must throw an error of "Daily Rate" is required in Expense based on Rule.
        Assert.ExpectedError(
            StrSubstNo(
                DailyRateConditionMissingForRangeErr,
                ExpenseRuleCondition.FieldCaption("Condition Type"),
                ExpenseRuleCondition."Condition Type"::"Fix Amount",
                ExpenseRuleCondition.FieldCaption("Expense Category Code"),
                ExpenseRuleCondition."Expense Category Code",
                ExpenseRuleCondition."Condition Type"::"Daily Rate"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleExpenseReportPerDiemMustFlowToPostedExpenseReportPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 580546] Verify that the multiple "Expense Report Per Diem" must flow to Posted Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount * 2, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);

        // [GIVEN] Update Ending Date and Time to next day.
        Expense.Validate("Ending Date and Time", CreateDateTime(WorkDate() + 1, Time));
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line & Per Diem.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportNo, ExpenseReportLine);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that the multiple "Expense Report Per Diem" must flow to Posted Expense Report Per Diem.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLinePerDiem(PostedExpenseReportLinePerDiem, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.RecordCount(PostedExpenseReportLinePerDiem, 2);
    end;

    [Test]
    procedure ExpenseIsNotAppliedWithAnyRule()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that the Expense is not applied with any Rule.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount * 2, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Delete all Expense rules.
        ExpenseRuleHeader.DeleteAll();
        ExpenseRuleCondition.DeleteAll();

        // [GIVEN] Update "Currency Code" and "Ending Date and Time" to next day.
        Expense.Validate("Currency Code", '');
        Expense.Validate("Ending Date and Time", CreateDateTime(WorkDate() + 1, Time));
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Enqueue Consent Question with Yes.
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(RuleValidationSuccessMsg);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that Expense is not applied with any Rule.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            '',
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseMustBeCalculatedInExpenseAsPerDiemRule()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseLocation: Record "Expense Location";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613264] Verify that Per Diem Expense is calculated in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::"Per Diem");

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule with Condition "Per Diem".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense.
        Expense.Init();
        Expense.Validate("Expense User No.", ExpenseUser."No.");
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Validate("Expense Date", WorkDate());
        Expense.Insert(true);

        // [WHEN] Update "Expense Category", "Expense Location" in Expense.
        Expense.Validate("Expense Location", ExpenseLocation."No.");
        Expense.Modify(true);

        // [THEN] Verify that Per Diem Expense is calculated in Expense.
        Assert.AreEqual(
            Amount,
            Expense.Amount,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Amount), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            CurrencyCode,
            Expense."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Currency Code"), CurrencyCode, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseMustBeCalculatedInExpenseAsPerMileageRule()
    var
        Expense: Record Expense;
        UnitOfMeasure: Record "Unit of Measure";
        DefaultUnitOfMeasure: Record "Unit of Measure";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO 613267] Verify that Mileage Expense is calculated in Expense.
        Initialize();

        // [GIVEN] Create Default Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(DefaultUnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(20, 100));
        ExpenseAgentSetup.Validate("Default Mileage UOM", DefaultUnitOfMeasure.Code);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Mileage);

        // [GIVEN] Create Expense Rule with Condition "Per Diem".
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', UnitOfMeasure.Code, ExpenseRuleCondition."Condition Type"::" ", 0);

        // [GIVEN] Create Expense.
        Expense.Init();
        Expense.Validate("Expense User No.", ExpenseUser."No.");
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Insert(true);

        // [WHEN] Update "Mileage" in Expense.
        Expense.Validate(Mileage, LibraryRandom.RandInt(10));
        Expense.Modify(true);

        // [THEN] Verify that Mileage Expense is calculated in Expense.
        Assert.AreEqual(
            Expense.Mileage * ExpenseAgentSetup."Standard Rate of Mileage",
            Expense.Amount,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Amount), Expense.Mileage * ExpenseAgentSetup."Standard Rate of Mileage", Expense.TableCaption()));
        Assert.AreEqual(
            DefaultUnitOfMeasure.Code,
            Expense."Unit of Measure Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Unit of Measure Code"), DefaultUnitOfMeasure.Code, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseRuleViolationFieldNonEditable()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePage: TestPage Expense;
    begin
        // [SCENARIO 614681] Verify that the Rule Violation field as non editable in the expense page
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [WHEN] Create Expense 
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', false, '', 0);

        // [THEN] Verify Rule Violation Field as not editable in the Expense Page
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        Assert.IsFalse(ExpensePage."Rule Violations".Editable(), '');
    end;

    [Test]
    procedure VerifyRuleViolationIsTrueAndRuleCondiftionsAreSpecified()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614681] Verify that Rule violation we have independent line with description why this is against Rule. 
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::"Always", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that Rule Violation is true and description is updated with Rule Violation
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    procedure JustificationRequiredWhenExpenseIsReleasedForItemizationWithRuleTypeAtLeastJustificationNeeded()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613693] Verify that system must throw an error of "Justification Required" When Expense is released with Rule "Justification Required" as "Always Conditions" with "Rule Type" "At Least Justification Needed".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::"Against Conditions", '', ExpenseRuleCondition."Condition Type"::"At Least Justification Needed", true, Amount - 1);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    procedure JustificationRequiredWhenExpenseIsReleasedForParticipantWithRuleTypeAtLeastJustificationNeeded()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613693] Verify that system must throw an error of "Justification Required" When Expense is released with Rule "Justification Required" as "Always Conditions" with "Rule Type" "At Least Justification Needed".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::"Against Conditions", '', ExpenseRuleCondition."Condition Type"::"At Least Justification Needed", true, Amount - 1);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
    end;

    [Test]
    [HandlerFunctions('AddExpenseParticipantsModalPageHandler')]
    procedure AddParticipantFromExpenseParticipantsPage()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountInFCY: Decimal;
        CurrencyFactor: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613726] Verify that the "Expense Report Participant" can be added from "Expense Participants" page and Expense can be released successfully.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);
        Currency."Amount Rounding Precision" := LibraryRandom.RandInt(1);
        Currency.Modify();

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Calculate Amount in FCY.
        CurrencyFactor := CurrencyExchangeRate.ExchangeRate(WorkDate(), CurrencyCode);
        AmountInFCY := Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), CurrencyCode, Amount, CurrencyFactor), Currency."Amount Rounding Precision");

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Participants, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [WHEN] Create Expense.
        ExpensePage.OpenNew();
        ExpensePage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpensePage."Expense Category".SetValue(ExpenseCategory.Code);
        ExpensePage."Merchant Name".SetValue(LibraryRandom.RandText(20));
        ExpensePage.Amount.SetValue(Amount);

        // [THEN] Verify that expense Rule Violation is true before adding Participant.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);
        ExpensePage.RuleViolations.Next();
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpensePage.Amount.Value));

        // [GIVEN] Enqueue "Employee No." for Participant.
        LibraryVariableStorage.Enqueue(ExpenseUser."Employee No.");

        // [WHEN] Add Participant from Expense Participants Page.
        ExpensePage.Amount.SetValue(AmountInFCY);
        ExpensePage.Participants.Invoke();

        // [THEN] Verify that expense Rule Violation is false.
        ExpensePage."Rule Violations".AssertEquals(false);

        // [WHEN] Release Expense.
        ExpensePage.Release.Invoke();

        // [THEN] Verify that Expense is released successfully.
        ExpensePage.Status.AssertEquals(Format(Expense.Status::Released));
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesModalPageHandler')]
    procedure AmountMustBeEqualToExpenseAmountInExpensePerDiem()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Expense: Record Expense;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613726] Verify that the Amount must be equal to Expense Amount in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [WHEN] Create Expense.
        ExpensePage.OpenNew();
        ExpensePage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpensePage."Expense Category".SetValue(ExpenseCategory.Code);
        ExpensePage."Expense Location".SetValue(ExpenseLocation."No.");
        ExpensePage."Expense Ext. Doc. No.".SetValue(LibraryRandom.RandText(30));
        ExpensePage."Merchant Name".SetValue(LibraryRandom.RandText(30));

        // [GIVEN] Enqueue Amount for Per Diem.
        LibraryVariableStorage.Enqueue(Amount);

        // [WHEN] Open Per Diem Page.
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that expense Rule Violation is false.
        ExpensePage."Rule Violations".AssertEquals(false);

        // [WHEN] Release Expense.
        ExpensePage.Release.Invoke();

        // [THEN] Verify that Expense is released successfully.
        ExpensePage.Status.AssertEquals(Format(Expense.Status::Released));
    end;

    [Test]
    [HandlerFunctions('AddExpenseReportParticipantsModalPageHandler')]
    procedure AddParticipantFromExpenseReportParticipantsPage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 613726] Verify that the "Expense Report Participant" can be added from "Expense Report Participants" page.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Participants, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that expense Rule Violation is true before adding Participant.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);

        // [GIVEN] Enqueue "Employee No." for Participant.
        LibraryVariableStorage.Enqueue(ExpenseUser."Employee No.");

        // [WHEN] Add Participant from Expense Participants Page.
        ExpenseReportPage."Expense Report Subform".Participants.Invoke();

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Verify that Expense Report is released successfully.
        ExpenseReportPage.Status.AssertEquals(Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    [HandlerFunctions('AddExpenseReportItemizationModalPageHandler')]
    procedure AddItemizationFromExpenseReportItemizationPage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 613726] Verify that the "Expense Report Itemization" can be added from "Expense Report Itemization" page.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        ExpenseReportHeader.Get(ExpenseReportPage."No.".Value);
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportPage.Close();

        // [WHEN] Update "Expense Ext. Doc. No.", "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", LibraryRandom.RandText(30));
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", LibraryRandom.RandText(30));
        ExpenseReportLine.Modify();

        // [THEN] Verify that expense Rule Violation is true before adding Itemization.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(ItemizationRequiredErr);

        // [GIVEN] Enqueue SubCategory and Amount for Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory.Code);
        LibraryVariableStorage.Enqueue(Amount);

        // [WHEN] Add Itemization from Expense Itemizations Page.
        ExpenseReportPage."Expense Report Subform".Itemizations.Invoke();

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Verify that Expense Report is released successfully.
        ExpenseReportPage.Status.AssertEquals(Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportLinePerDiemModalPageHandler')]
    procedure ExpenseReportLinePerDiemAmountReductionBasedOnBreakfastLunchDinner()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Breakfast, Lunch, Dinner selection in Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        FindExpenseReportLine(ExpenseReportLine, Format(ExpenseReportPage."No.".Value));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", true, false, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", true, true, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", true, true, true));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportLinePerDiemModalPageHandler')]
    procedure ExpenseReportLinePerDiemAmountReductionBasedOnLunchDinner()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Lunch, Dinner selection in Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        FindExpenseReportLine(ExpenseReportLine, Format(ExpenseReportPage."No.".Value));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, false, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, true, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, true, true));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportLinePerDiemModalPageHandler')]
    procedure ExpenseReportLinePerDiemAmountReductionBasedOnDinner()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Dinner selection in Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        FindExpenseReportLine(ExpenseReportLine, Format(ExpenseReportPage."No.".Value));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, false, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, false, true));
    end;

    [Test]
    [HandlerFunctions('ExpenseReportLinePerDiemModalPageHandler')]
    procedure ExpenseReportLinePerDiemAmountReductionBasedOnBreakfastDinner()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense amount must be updated based on Breakfast and Dinner selection in Expense Report Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::"Per Diem", ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", CurrencyCode, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Location".SetValue(ExpenseLocation."No.");

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        FindExpenseReportLine(ExpenseReportLine, Format(ExpenseReportPage."No.".Value));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", false, false, false));

        // [GIVEN] Enqueue Breakfast,Lunch and Dinner for Per Diem.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Document No.");
        LibraryVariableStorage.Enqueue(ExpenseReportLine."Line No.");

        // [WHEN] Open Per Diem Page.
        ExpenseReportPage."Expense Report Subform".PerDiem.Invoke();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(CalculateAmountReduction(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", true, false, true));
    end;


    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,VerifyAmountInExpenseReportLinePerDiemModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportPerDiemAmountReductionBasedOnBreakfastLunchDinner()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpensePerDiem: Record "Expense Per Diem";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 614319] Verify that the expense report line per diem amount must be updated based on Breakfast, Lunch, Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Expense Per Diem Record. 
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        ExpensePerDiem.FindFirst();

        // [GIVEN] Validate Breakfast in Expense Per Diem.
        ExpensePerDiem.Validate(Breakfast, true);
        ExpensePerDiem.Validate(Lunch, true);
        ExpensePerDiem.Validate(Dinner, true);
        ExpensePerDiem.Modify(true);

        // [GIVEN] Release Expense.
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Enqueue Expense No.
        LibraryVariableStorage.Enqueue(Expense."No.");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Find Expense Report Line and Open Per Diem Page.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.ShowPerDiem();

        // [THEN] Verify that the Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner through Handler.

        // [WHEN] Post Expense Report.
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::Released;
        ExpenseReportHeader.Modify();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Posted Expense Report Line Per Diem Amount is calculated based on Breakfast, Lunch, Dinner.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        FindPostedExpenseReportLinePerDiem(PostedExpenseReportLinePerDiem, PostedExpenseReportHeader."No.", PostedExpenseReportLine);
        Assert.AreEqual(
            true,
            PostedExpenseReportLinePerDiem.Breakfast,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption(Breakfast), true, PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            true,
            PostedExpenseReportLinePerDiem.Lunch,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption(Lunch), true, PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            true,
            PostedExpenseReportLinePerDiem.Dinner,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption(Dinner), true, PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
            CalculateAmountReduction(Expense."No."),
            PostedExpenseReportLinePerDiem."Per Diem Amount",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Per Diem Amount"), CalculateAmountReduction(Expense."No."), PostedExpenseReportLinePerDiem.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportParticipantIsUpdatedWhenExpenseParticipantIsChangedFromEmployeeToExternal()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        CompanyInformation: Record "Company Information";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 613397] Verify that the Expense Report Participant is updated when Expense Participant is changed from Employee to External.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Find Expense Report Line & Participant.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);

        // [THEN] Verify that the Expense Participant is created.
        Employee.Get(ExpenseReportLineParticipant."Participant Employee No.");
        CompanyInformation.Get();
        Assert.AreEqual(
            Employee."First Name" + ' ' + Employee."Last Name",
            ExpenseReportLineParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Name"), Employee."First Name" + ' ' + Employee."Last Name", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Country/Region Code",
            ExpenseReportLineParticipant."Participant Country/Region",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Country/Region"), Employee."Country/Region Code", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Job Title",
            ExpenseReportLineParticipant."Participant Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Title"), Employee."Job Title", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            Employee."Company E-Mail",
            ExpenseReportLineParticipant."Participant Email",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Email"), Employee."Company E-Mail", ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            CompanyInformation.Name,
            ExpenseReportLineParticipant."Participant Organization",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Organization"), CompanyInformation.Name, ExpenseReportLineParticipant.TableCaption()));

        // [WHEN] Validate Participant Type to External.
        ExpenseReportLineParticipant.Validate("Participant Type", ExpenseReportLineParticipant."Participant Type"::External);

        // [THEN] Verify that the Expense Participant fields is updated accordingly.
        Assert.AreEqual(
            '',
            ExpenseReportLineParticipant."Participant Name",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Name"), '', ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportLineParticipant."Participant Country/Region",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Country/Region"), '', ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportLineParticipant."Participant Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Title"), '', ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportLineParticipant."Participant Email",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Email"), '', ExpenseReportLineParticipant.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseReportLineParticipant."Participant Organization",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLineParticipant.FieldCaption("Participant Organization"), '', ExpenseReportLineParticipant.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportParticipantEmployeeNoIsRequiredWhenSomeFieldsAreUpdating()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 613397] Verify that the Expense Report "Participant Employee No." is required when some fields are updating.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Participants, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [GIVEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line & Participant.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);

        // [GIVEN] Validate "Participant Employee No." to blank.
        ExpenseReportLineParticipant.Validate("Participant Employee No.", '');
        ExpenseReportLineParticipant.Modify();

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Update Participant Name.
        asserterror ExpenseReportLineParticipant.validate("Participant Name", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Organization.
        asserterror ExpenseReportLineParticipant.validate("Participant Organization", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Country/Region.
        asserterror ExpenseReportLineParticipant.validate("Participant Country/Region", PostCode."Country/Region Code");

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Title.
        asserterror ExpenseReportLineParticipant.validate("Participant Title", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), '');

        // [WHEN] Update Participant Email.
        asserterror ExpenseReportLineParticipant.validate("Participant Email", LibraryRandom.RandText(10));

        // [THEN] Verify that Expense "Participant Employee No." is required when some fields are updating.
        Assert.ExpectedTestFieldError(ExpenseReportLineParticipant.FieldCaption("Participant Employee No."), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithFullCompleteDays()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Full Complete Days.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue * 3;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 235900T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [WHEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Full Complete Days.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithFullCompleteDaysWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Full Complete Days Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue * 3;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 235900T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Full Complete Days without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithPartialDays()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + (ConditionValue * 0.5) + (ConditionValue * 0.5);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Partial Days.
        StartingDateTime := CreateDateTime(WorkDate(), 143000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 101500T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.5);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.5);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.5);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithPartialDaysWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + (ConditionValue * 0.5) + (ConditionValue * 0.5);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Partial Days.
        StartingDateTime := CreateDateTime(WorkDate(), 143000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 101500T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.5);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.5);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithSinglePartialDay()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := (ConditionValue * 0.5);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Single Partial Day.
        StartingDateTime := CreateDateTime(WorkDate(), 090000T);
        EndingDateTime := CreateDateTime(WorkDate(), 170000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithSinglePartialDayWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := (ConditionValue * 0.5);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Single Partial Day.
        StartingDateTime := CreateDateTime(WorkDate(), 090000T);
        EndingDateTime := CreateDateTime(WorkDate(), 170000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Partial Days without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue * 0.5);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithSinglePartialDayBelowMinimum()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day below Minimum hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 4);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 090000T);
        EndingDateTime := CreateDateTime(WorkDate(), 120000T);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created with Zero Amount.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day below Minimum hours.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithSinglePartialDayBelowMinimumWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day below Minimum hours without expense.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 4);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 090000T);
        EndingDateTime := CreateDateTime(WorkDate(), 120000T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Single Partial Day below Minimum hours Without Expense with Zero Amount.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithFull24Hour()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Full 24 Hour.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full 24 Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 100000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 140000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithFull24HourWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Full 24 Hour Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full 24 Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 100000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 140000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithBelowMinimumHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Below Minimum Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 150000T);
        EndingDateTime := CreateDateTime(WorkDate(), 210000T);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created with Zero Amount.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Below Minimum Hours with Zero Amount.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithBelowMinimumHoursWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Below Minimum Hours Without Expense.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 150000T);
        EndingDateTime := CreateDateTime(WorkDate(), 210000T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Below Minimum Hours with Zero Amount.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithFullShortTrip()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Full Short Trip.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for above Minimum Hours Short Trip.
        StartingDateTime := CreateDateTime(WorkDate(), 020000T);
        EndingDateTime := CreateDateTime(WorkDate(), 230000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full Short Trip.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithFullShortTripWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Full Short Trip Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for above Minimum Hours Short Trip.
        StartingDateTime := CreateDateTime(WorkDate(), 020000T);
        EndingDateTime := CreateDateTime(WorkDate(), 230000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full Short Trip without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithPartialShortTrip()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Partial Short Trip.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue * 0.6;

        // [GIVEN] Create Starting DateTime and Ending DateTime for above Minimum Hours Short Trip.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(WorkDate(), 160000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full Short Trip.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithPartialShortTripWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Partial Short Trip Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue * 0.6;

        // [GIVEN] Create Starting DateTime and Ending DateTime for above Minimum Hours Short Trip.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(WorkDate(), 160000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Partial Short Trip without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDays()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Multiple Days.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 080000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDaysWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Multiple Days Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 080000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDaysAbovePartialAndBelowMinimumHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Multiple Days Above Partial And Below Minimum Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + (ConditionValue * 0.6);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days Above Partial And Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 190000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.6);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.6);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.6);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDaysAbovePartialAndBelowMinHrsWithoutExp()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Multiple Days Above Partial And Below Minimum Hours Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + (ConditionValue * 0.6);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days Above Partial And Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 060000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 190000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.6);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue * 0.6);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDaysAbovePartialAndMinimumHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24-hour Rolling Period with Multiple Days Above Partial and Minimum Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days Above Partial and Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 030000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 233000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIs24HourRollingPeriodWithMultipleDaysAbovePartialAndMinHrsWithoutExp()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is 24 Hour Rolling Period with Multiple Days Above Partial and Minimum Hours Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"24-hour Rolling Period", "Expense Partial Day Rules"::"Based On Eligible Hours", 60, 20, 8);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days Above Partial and Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 030000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 233000T);
        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full 24 Hour Rolling Period with Full 24 Hour without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ConditionValue);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithMultiNightTrip()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Multi Night Trip.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days.
        StartingDateTime := CreateDateTime(WorkDate(), 160000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 110000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Multi Night Trip.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithMultiNightTripWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Multi Night Trip Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Multiple Days.
        StartingDateTime := CreateDateTime(WorkDate(), 160000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 110000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Multi Night Trip.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithSameDayTripWithNoOverNight()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Same Day Trip with No Over Night.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Same Day Trip with No Over Night.
        StartingDateTime := CreateDateTime(WorkDate(), 080000T);
        EndingDateTime := CreateDateTime(WorkDate(), 200000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Same Day Trip With No Over Night.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithSameDayTripWithNoOverNightWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Same Day Trip With No Over Night Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime for Same Day Trip with No Over Night.
        StartingDateTime := CreateDateTime(WorkDate(), 080000T);
        EndingDateTime := CreateDateTime(WorkDate(), 200000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with Same Day Trip With No Over Night Without Expense.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStay()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 180000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 100000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStayWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue;

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 180000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 100000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStayAndAboveMinimumPartialHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Above Minimum Partial Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + (ConditionValue * 0.4);

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 080000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 160000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue * 0.4);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue * 0.4);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Above Minimum Partial Hours.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue * 0.4);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStayAndAboveMinimumPartialHoursWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay Without Expense and Above Minimum Partial Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := ConditionValue + (ConditionValue * 0.4);

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 080000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 160000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue * 0.4);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Above Minimum Partial Hours.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ConditionValue);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ConditionValue * 0.4);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStayAndBelowMinimumPartialHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Below Minimum Partial Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 230000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 040000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Below Minimum Partial Hours.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsOvernightStayWithOneNightStayAndBelowMinimumPartialHoursWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay Without Expense and Below Minimum Partial Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Overnight Stay", "Expense Partial Day Rules"::"Based On Eligible Hours", 40, 12, 6);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);
        ExpectedAmount := 0;

        // [GIVEN] Create Starting DateTime and Ending DateTime.
        StartingDateTime := CreateDateTime(WorkDate(), 230000T);
        EndingDateTime := CreateDateTime(CalcDate('<1D>', WorkDate()), 040000T);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Overnight Stay with One Night Stay and Above Minimum Partial Hours.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", ExpectedAmount, ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 2);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsNoneWithBelowMinimumHours()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is None with Below Minimum Hours.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::None, "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 0, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 150000T);
        EndingDateTime := CreateDateTime(WorkDate(), 210000T);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Per Diem is created with Zero Amount.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is None with Below Minimum Hours with Zero Amount.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsNoneWithBelowMinimumHoursWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is None with Below Minimum Hours Without Expense.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::None, "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 0, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Below Minimum Hours.
        StartingDateTime := CreateDateTime(WorkDate(), 150000T);
        EndingDateTime := CreateDateTime(WorkDate(), 210000T);

        // [WHEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [THEN] Verify Expense Report Line Per Diem is created with Zero Amount.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is None with Below Minimum Hours Without Expense with Zero Amount.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyRecordCountOfGeneralLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", 0, 0);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), 0);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithMealReduction()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpectedAmount: array[3] of Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Meal Reduction.
        Initialize();

        // [GIVEN] Setup Number Series in Expense Management.s
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 235900T);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateAndReleaseExpenseWithPerDiemRule(
            Expense, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            Expense."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [GIVEN] Reopen Expense to update Expense Per Diem with Meal Reductions.
        ReleaseExpenseDocument.Reopen(Expense);

        // [GIVEN] Update Expense Per Diem with Meal Reductions.
        UpdateExpensePerDiemWithMealReduction(Expense."No.", WorkDate(), true, true, false);
        UpdateExpensePerDiemWithMealReduction(Expense."No.", CalcDate('<1D>', WorkDate()), true, true, true);
        UpdateExpensePerDiemWithMealReduction(Expense."No.", CalcDate('<2D>', WorkDate()), false, false, true);
        ExpectedAmount[1] := CalculateAmountReduction(Expense."No.", WorkDate());
        ExpectedAmount[2] := CalculateAmountReduction(Expense."No.", CalcDate('<1D>', WorkDate()));
        ExpectedAmount[3] := CalculateAmountReduction(Expense."No.", CalcDate('<2D>', WorkDate()));
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount[1] + ExpectedAmount[2] + ExpectedAmount[3], CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Release Expense after updating Meal Reductions.
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [THEN] Verify Expense Per Diem is created.
        VerifyExpensePerDiem(Expense."No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount[1]);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ExpectedAmount[2]);
        VerifyExpensePerDiem(Expense."No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ExpectedAmount[3]);

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode);

        // [WHEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount[1]);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ExpectedAmount[2]);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ExpectedAmount[3]);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Meal Reduction.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, Expense."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", Round(ExpectedAmount[1] + ExpectedAmount[2] + ExpectedAmount[3], Currency."Amount Rounding Precision"), ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount[1]);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ExpectedAmount[2]);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ExpectedAmount[3]);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenFullPerDiemCalculationIsFullCalendarDayWithMealReductionWithoutExpense()
    var
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ReleaseExpenseReportDocument: Codeunit "Release Exp. Report Document";
        ExpectedAmount: array[3] of Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
        ConditionValue: Decimal;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
    begin
        // [SCENARIO 613486] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Meal Reduction Without Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        ConditionValue := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Starting DateTime and Ending DateTime for Full Complete Days.
        StartingDateTime := CreateDateTime(WorkDate(), 000000T);
        EndingDateTime := CreateDateTime(CalcDate('<2D>', WorkDate()), 235900T);

        // [GIVEN] Create Expense Report with Rule "Per Diem".
        CreateAndReleaseExpenseReportWithPerDiemRule(
            ExpenseReportHeader, ExpenseReportLine, ExpenseUser, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code",
            PostCode.City, CurrencyCode, 0, WorkDate(), StartingDateTime, EndingDateTime,
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ",
            ExpenseReportLine."Reimbursement Type"::"Employee Paid", '', ExpenseRuleCondition."Condition Type"::"Daily Rate",
            true, ConditionValue);

        // [GIVEN] Reopen Expense to update Expense Per Diem with Meal Reductions.
        ReleaseExpenseReportDocument.Reopen(ExpenseReportHeader);

        // [GIVEN] Update Expense Report Line Per Diem with Meal Reductions.
        UpdateExpenseReportLinePerDiemWithMealReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", WorkDate(), true, true, false);
        UpdateExpenseReportLinePerDiemWithMealReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), true, true, true);
        UpdateExpenseReportLinePerDiemWithMealReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), false, false, true);
        ExpectedAmount[1] := CalculateAmountReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", WorkDate());
        ExpectedAmount[2] := CalculateAmountReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()));
        ExpectedAmount[3] := CalculateAmountReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()));
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(ExpectedAmount[1] + ExpectedAmount[2] + ExpectedAmount[3], CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [WHEN] Release Expense Report after updating Meal Reductions.
        ExpenseReportHeader.Get(ExpenseReportHeader."No.");
        ReleaseExpenseReportDocument.PerformManualCheckAndRelease(ExpenseReportHeader);

        // [THEN] Verify Expense Report Line Per Diem is created.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount[1]);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ExpectedAmount[2]);
        VerifyExpenseReportLinePerDiem(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ExpectedAmount[3]);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Full Per Diem Calculation is Full Calendar Day with Meal Reduction.
        FindPostedExpenseReportHeader(PostedExpenseReportHeader, ExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, PostedExpenseReportHeader."No.");
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseReportLine."Expense Category"), ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, ExpenseReportLine, ExpenseUser."Employee No.", Round(ExpectedAmount[1] + ExpectedAmount[2] + ExpectedAmount[3], Currency."Amount Rounding Precision"), ExpectedAmountLCY);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", WorkDate(), StrSubstNo(PerDiemForLbl, Format(WorkDate())), ExpectedAmount[1]);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<1D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<1D>', WorkDate()))), ExpectedAmount[2]);
        VerifyPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.", CalcDate('<2D>', WorkDate()), StrSubstNo(PerDiemForLbl, Format(CalcDate('<2D>', WorkDate()))), ExpectedAmount[3]);
        VerifyRecordCountOfPostedExpenseReportLinePerDiem(PostedExpenseReportLine."Document No.", 0, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportPerDiemAmountReductionBasedOnBreakfastLunchDinnerCanBeUpdatedCreatedFromExpenseAndHasRuleViolation()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617013] Verify that the expense report line per diem amount must be updated based on Breakfast, Lunch, Dinner selection in Expense Per Diem.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 100, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Update Reduction for Breakfast, Lunch, Dinner in Expense Agent Setup.
        UpdateReductionForMealPerDiem(LibraryRandom.RandInt(5), LibraryRandom.RandInt(10), LibraryRandom.RandInt(12));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::Always, '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, Expense."Expense User No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Enqueue Expense No.
        LibraryVariableStorage.Enqueue(Expense."No.");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        UpdateExpenseReportLinePerDiemWithMealReduction(ExpenseReportHeader."No.", ExpenseReportLine."Line No.", WorkDate(), true, true, true);

        // [THEN] Verify Expense Report Line Per Diem must be not equal to Expense Amount.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreNotEqual(
            Expense.Amount,
            ExpenseReportLine.Amount,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption(Amount), Expense.Amount, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('AddExpenseReportParticipantsModalPageHandler')]
    procedure ExpenseReportLineCanBeDeletedWhenExpenseParticipantsExist()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportLineParticipants: Record "Expense Report Line Particip.";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Participants exist.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Participants, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", Amount);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [GIVEN] Find Expense Report Line.
        ExpenseReportHeader.Get(ExpenseReportPage."No.".Value());
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportPage.Close();

        // [WHEN] Update "Expense Ext. Doc. No.", "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", LibraryRandom.RandText(30));
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", LibraryRandom.RandText(30));
        ExpenseReportLine.Modify();

        // [THEN] Verify that expense Rule Violation is true before adding Participant.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);

        // [GIVEN] Enqueue "Employee No." for Participant.
        LibraryVariableStorage.Enqueue(ExpenseUser."Employee No.");

        // [WHEN] Add Participant from Expense Participants Page.
        ExpenseReportPage."Expense Report Subform".Participants.Invoke();
        ExpenseReportPage.Close();

        // [THEN] Verify that the new Participants are created in Expense Report Line Participants Page.
        ExpenseReportLineParticipants.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineParticipants, 1);

        // [WHEN] Delete Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Participants exist.
        ExpenseReportLineParticipants.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineParticipants, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLine, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportLineCanBeDeletedWhenExpenseItemizationExistFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Itemizations exist and Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Itemize".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Subcategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);

        // [GIVEN] Create Expense Itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [WHEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that the Expense Report Line Itemizations are created from Expense Itemization.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLineItem, 1);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            ExpenseReportNo,
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), ExpenseReportNo, Expense.TableCaption()));

        // [WHEN] Delete Expense Report Line.
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Itemizations exist.
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineItem, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        Assert.RecordCount(ExpenseReportLine, 0);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            '',
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), '', Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportLineCanBeDeletedWhenExpenseParticipantExistsFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseParticipant: Record "Expense Participant";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineParticipant: Record "Expense Report Line Particip.";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Participants exist and Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Participants".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Participants", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Participant.
        LibraryExpense.CreateExpenseParticipant(ExpenseParticipant, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [WHEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that the Expense Report Line Participants are created from Expense Participants.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLineParticipant(ExpenseReportLineParticipant, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLineParticipant, 1);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            ExpenseReportNo,
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), ExpenseReportNo, Expense.TableCaption()));

        // [WHEN] Delete Expense Report Line.
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Participants exist.
        ExpenseReportLineParticipant.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLineParticipant, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        Assert.RecordCount(ExpenseReportLine, 0);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            '',
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), '', Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportLineCanBeDeletedWhenExpensePerDiemExistsFromExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Code[20];
    begin
        // [SCENARIO 616956] Verify that Expense Report Line can be deleted when Expense Per Diem exists and Expense Report is created from Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Reduction in Expense Agent Setup.
        LibraryExpense.UpdateReductionInAgentSetup(LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), LibraryRandom.RandInt(20));

        // [GIVEN] Update Full Per Diem Calculation and Partial Day Rules in Expense Agent Setup.
        LibraryExpense.UpdatePerDiemInAgentSetup("Exp. Full Per Diem Calculation"::"Full Calendar Day", "Expense Partial Day Rules"::"Flat Percentage Of Full Rate", 50, 0, 0);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [WHEN] Insert Expense Line.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that the Expense Report Line Per Diem are created from Expense Per Diem.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportNo);
        FindExpenseReportLinePerDiem(ExpenseReportLinePerDiem, ExpenseReportNo, ExpenseReportLine);
        Assert.RecordCount(ExpenseReportLinePerDiem, 1);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            ExpenseReportNo,
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), ExpenseReportNo, Expense.TableCaption()));

        // [WHEN] Delete Expense Report Line.
        ExpenseReportLine.Delete(true);

        // [THEN] Verify that the Expense Report Line can be deleted when Expense Per Diem exist.
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportLinePerDiem, 0);

        // [THEN] Verify that the Expense Report Line is deleted.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        Assert.RecordCount(ExpenseReportLine, 0);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            '',
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), '', Expense.TableCaption()));
    end;

    [Test]
    procedure JustificationRequiredForExpenseWithRuleTypeAtLeastJustificationNeededWithLCYAndFCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense has rule type "At Least Justification Needed" with LCY and FCY in Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, CurrencyCode, '', Amount, Amount, ExpectedAmountLCY);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpensePage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount LCY.
        ExpenseRuleCondition1.Validate(Value, ExpectedAmountLCY + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure JustificationRequiredForExpenseReportWithRuleTypeAtLeastJustificationNeededWithLCYAndFCYInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense Report has rule type "At Least Justification Needed" with LCY and FCY in Expense Report.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, CurrencyCode, '', Amount, Amount, ExpectedAmountLCY);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Create and Attach Expense Report.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpenseReportPage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount LCY.
        ExpenseRuleCondition1.Validate(Value, ExpectedAmountLCY + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure JustificationRequiredForExpenseWithRuleTypeAtLeastJustificationNeededWithLCYAndLCYInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense has rule type "At Least Justification Needed" with LCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', '', Amount, Amount, Amount);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpensePage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount.
        ExpenseRuleCondition1.Validate(Value, Amount + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure JustificationRequiredForExpenseReportWithRuleTypeAtLeastJustificationNeededWithLCYAndLCYInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense Report has rule type "At Least Justification Needed" with LCY and LCY in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', '', Amount, Amount, Amount);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Create and Attach Expense Report.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpenseReportPage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount.
        ExpenseRuleCondition1.Validate(Value, Amount + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure JustificationRequiredForExpenseWithRuleTypeAtLeastJustificationNeededWithFCYAndLCYInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense has rule type "At Least Justification Needed" with FCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY, ExpectedAmountFCY);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpensePage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount LCY.
        ExpenseRuleCondition1.Validate(Value, ExpectedAmountFCY + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure JustificationRequiredForExpenseReportWithRuleTypeAtLeastJustificationNeededWithFCYAndLCYInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 620126] Verify that Justification is required when Expense Report has rule type "At Least Justification Needed" with FCY and LCY in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY, ExpectedAmountFCY);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [WHEN] Create and Attach Expense Report.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [THEN] Verify that system must throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpenseReportPage.Close();

        // [GIVEN] Update Expense Rule Condition Value to be less than Expected Amount LCY.
        ExpenseRuleCondition1.Validate(Value, ExpectedAmountFCY + 1);
        ExpenseRuleCondition1.Modify();

        // [WHEN] Apply Rule on Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.ApplyRule();

        // [THEN] Verify that system must not throw an error of "Justification Required".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure ValidateItemizationWithValidSubcategories()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify itemization validation passes when expense category has valid subcategories.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with itemization.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create subcategory for the expense category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create expense with itemization.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create expense itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Expense.Amount, LibraryRandom.RandInt(1));

        // [WHEN] Apply rule validation.
        Expense.ApplyRule();

        // [THEN] Verify no rule violations exist for missing subcategories.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        Assert.RecordIsEmpty(ExpenseRuleViolation);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ValidateExpenseReportLineItemizationWithValidSubcategories()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify expense report line itemization validation passes when expense category has valid subcategories.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with itemization.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create subcategory for the expense category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create expense with itemization.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandDec(100, 2));

        // [GIVEN] Create expense itemization.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Expense.Amount, LibraryRandom.RandInt(1));

        // [GIVEN] Release expense and create expense report.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Apply rule validation on expense report line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseReportLine.ApplyRule();

        // [THEN] Verify no rule violations exist for missing subcategories.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportRuleViolation.SetRange("Line No.", ExpenseReportLine."Line No.");
        Assert.RecordIsEmpty(ExpenseReportRuleViolation);
    end;

    [Test]
    procedure ValidateMissingSubcategoriesErrorForExpense()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify error is raised when expense requires itemization but category has no subcategories.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with itemization.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create expense with itemization.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Apply rule validation.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] Verify rule violation exists for missing subcategories.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.SetRange(Description, StrSubstNo(MissingExpenseSubCategoryErr, ExpenseCategory.Code));
        Assert.RecordIsNotEmpty(ExpenseRuleViolation);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ValidateMissingSubcategoriesErrorForExpenseReportLine()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportRuleViolation: Record "Expense Report Rule Violation";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify error is raised when expense report line requires itemization but category has no subcategories.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with itemization.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create expense with itemization.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', LibraryRandom.RandDec(100, 2));

        // [GIVEN] Release expense and create expense report.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Apply rule validation on expense report line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");
        ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);

        // [THEN] Verify rule violation exists for missing subcategories.
        ExpenseReportRuleViolation.SetRange("Expense Report No.", ExpenseReportHeader."No.");
        ExpenseReportRuleViolation.SetRange("Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportRuleViolation.SetRange(Description, StrSubstNo(MissingExpenseSubCategoryErr, ExpenseCategory.Code));
        Assert.RecordIsNotEmpty(ExpenseReportRuleViolation);
    end;

    [Test]
    procedure ValidateMissingItemizationAfterSubcategoryValidationPasses()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify itemization required error is raised when subcategories exist but no itemization.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with itemization.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create subcategory for the expense category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create expense without expense itemization.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Apply rule validation.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);

        // [THEN] Verify no subcategory error.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.SetRange(Description, StrSubstNo(MissingExpenseSubCategoryErr, ExpenseCategory.Code));
        Assert.RecordIsEmpty(ExpenseRuleViolation);

        // [THEN] Verify itemization required error exists.
        ExpenseRuleViolation.Reset();
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.SetRange(Description, ItemizationRequiredErr);
        Assert.RecordIsNotEmpty(ExpenseRuleViolation);
    end;

    [Test]
    procedure ValidateMultipleCategoriesMixedSubcategoryScenario()
    var
        ExpenseWithSubcategory: Record Expense;
        ExpenseWithoutSubcategory: Record Expense;
        ExpenseCategoryWithSubcategory: Record "Expense Category";
        ExpenseCategoryWithoutSubcategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseUser: Record "Expense User";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621105] Verify validation is category-specific - some categories with subcategories, some without Subcategories should only raise errors for the ones without subcategories.
        Initialize();

        // [GIVEN] Create expense user.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create expense category with subcategories.
        LibraryExpense.CreateExpenseCategory(ExpenseCategoryWithSubcategory, ExpenseCategoryWithSubcategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategoryWithSubcategory.Code, true);

        // [GIVEN] Create expense category without subcategories.
        LibraryExpense.CreateExpenseCategory(ExpenseCategoryWithoutSubcategory, ExpenseCategoryWithoutSubcategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::Itemize);

        // [GIVEN] Create expenses for both categories.
        LibraryExpense.CreateExpense(ExpenseWithSubcategory, ExpenseUser."No.", ExpenseCategoryWithSubcategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandDec(100, 2));
        LibraryExpense.CreateExpense(ExpenseWithoutSubcategory, ExpenseUser."No.", ExpenseCategoryWithoutSubcategory.Code, '', '', true, '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Apply rule validation to both expenses.
        ExpenseRuleValidation.ValidateExpenseAgainstRule(ExpenseWithSubcategory);
        ExpenseRuleValidation.ValidateExpenseAgainstRule(ExpenseWithoutSubcategory);

        // [THEN] Verify expense with subcategories has no subcategory error.
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseWithSubcategory."No.");
        ExpenseRuleViolation.SetRange(Description, StrSubstNo(MissingExpenseSubCategoryErr, ExpenseCategoryWithSubcategory.Code));
        Assert.RecordIsEmpty(ExpenseRuleViolation);

        // [THEN] Verify expense without subcategories has subcategory error.
        ExpenseRuleViolation.Reset();
        ExpenseRuleViolation.SetRange("Expense No.", ExpenseWithoutSubcategory."No.");
        ExpenseRuleViolation.SetRange(Description, StrSubstNo(MissingExpenseSubCategoryErr, ExpenseCategoryWithoutSubcategory.Code));
        Assert.RecordIsNotEmpty(ExpenseRuleViolation);
    end;

    [Test]
    procedure RuleViolationShownWhenExpenseExceedsMaximumAmount()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620073] Verify that system shows rule violation when expense exceeds maximum amount defined in rule condition with FCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);
        AmountReduction := LibraryRandom.RandInt(10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY - 1, ExpectedAmountFCY - 1);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of rule violation for exceeding maximum amount.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpensePage.RuleViolations.Next();
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpectedAmountFCY - 1));
        ExpensePage.Close();

        // [GIVEN] Create Refundable and Non-Refundable Itemizations for the Expense.
        UpdateRefundableItemizationForExpense(Expense, Amount - AmountReduction);
        CreateNonRefundableItemizationForExpense(Expense, AmountReduction);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must still throw an error of rule violation for exceeding maximum amount as refundable amount still exceeds the maximum amount.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage.Close();
    end;

    [Test]
    procedure RuleViolationShownWhenExpenseExceedsMaximumAmountWithAmountReduction()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620073] Verify that system shows rule violation when expense exceeds maximum amount with amount reduction defined in rule condition with FCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);
        AmountReduction := LibraryRandom.RandInt(10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY - 1, ExpectedAmountFCY);

        // [GIVEN] Create Refundable and Non-Refundable Itemizations for the Expense.
        UpdateRefundableItemizationForExpense(Expense, Amount - AmountReduction);
        CreateNonRefundableItemizationForExpense(Expense, AmountReduction);

        // [WHEN] Apply Rule on Expense.
        Expense.ApplyRule();

        // [THEN] Verify that system must throw an error of rule violation for exceeding maximum amount.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpensePage.RuleViolations.Next();
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpectedAmountFCY - 1));
        ExpensePage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure RuleViolationShownWhenExpenseReportLineExceedsMaximumAmount()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620073] Verify that system shows rule violation when expense report line exceeds maximum amount defined in rule condition with FCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);
        AmountReduction := LibraryRandom.RandInt(10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY - 1, ExpectedAmountFCY - 1);

        // [WHEN] Release expense and create expense report.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [THEN] Verify that system must throw an error of rule violation for exceeding maximum amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpenseReportPage.RuleViolations.Next();
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpectedAmountFCY - 1));
        ExpenseReportPage.Close();

        // [GIVEN] Find expense report line.
        FindExpenseReportLine(ExpenseReportLine, ExpenseReportHeader."No.");

        // [GIVEN] Create Refundable and Non-Refundable Itemizations for the Expense Report Line.
        UpdateRefundableItemizationForExpenseReportLine(ExpenseReportLine, Amount - AmountReduction);
        CreateNonRefundableItemizationForExpenseReportLine(ExpenseReportLine, AmountReduction);

        // [WHEN] Apply Rule on Expense Report Line.
        ExpenseReportLine.ApplyRule();

        // [THEN] Verify that system must still throw an error of rule violation for exceeding maximum amount as refundable amount still exceeds the maximum amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure RuleViolationShownWhenExpenseReportLineExceedsMaximumAmountWithAmountReduction()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseRuleCondition1: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountFCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620073] Verify that system shows rule violation when expense report line exceeds maximum amount with amount reduction defined in rule condition with FCY and LCY in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);
        AmountReduction := LibraryRandom.RandInt(10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountFCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create Expense with rule "Itemize".
        CreateExpenseWithItemization(Expense, ExpenseRuleCondition1, '', CurrencyCode, Amount, ExpectedAmountFCY - 1, ExpectedAmountFCY);

        // [GIVEN] Create Refundable and Non-Refundable Itemizations for the Expense.
        UpdateRefundableItemizationForExpense(Expense, Amount - AmountReduction);
        CreateNonRefundableItemizationForExpense(Expense, AmountReduction);
        Expense.ApplyRule();

        // [WHEN] Release expense and create expense report.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", '', Expense."VAT Bus. Posting Group");

        // [THEN] Verify that system must throw an error of rule violation for exceeding maximum amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(JustificationRequiredErr);
        ExpenseReportPage.RuleViolations.Next();
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(MaxAmountErr, ExpectedAmountFCY - 1));
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure NonRefundableAmountIsRecalculatedWhenItemizationSubcategoryChanges()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseSubCategoryRefundable: Record "Expense Subcategory";
        ExpenseSubCategoryNonRefundable: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        Amount: Decimal;
    begin
        // [SCENARIO 640848] Verify that the Expense "Non-Refundable Amount" is recalculated when an itemization line's subcategory changes across the refundable/non-refundable boundary.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with Rule "Itemize" in LCY.
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Create a refundable and a non-refundable Expense Subcategory under the Expense Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategoryRefundable, Expense."Expense Category", true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategoryNonRefundable, Expense."Expense Category", false);

        // [WHEN] Create an itemization line for the full amount using the refundable subcategory.
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, Expense."Expense Category", ExpenseSubCategoryRefundable.Code, WorkDate(), Amount, 1);

        // [THEN] Verify that the "Non-Refundable Amount" is zero.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            0,
            Expense."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Non-Refundable Amount"), 0, Expense.TableCaption()));

        // [WHEN] Change the itemization subcategory to a non-refundable one.
        ExpenseItemization.Validate("Expense Subcategory Code", ExpenseSubCategoryNonRefundable.Code);
        ExpenseItemization.Modify(true);

        // [THEN] Verify that the "Non-Refundable Amount" is recalculated to the itemization amount.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            Amount,
            Expense."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Non-Refundable Amount"), Amount, Expense.TableCaption()));

        // [WHEN] Change the itemization subcategory back to a refundable one.
        ExpenseItemization.Validate("Expense Subcategory Code", ExpenseSubCategoryRefundable.Code);
        ExpenseItemization.Modify(true);

        // [THEN] Verify that the "Non-Refundable Amount" is recalculated back to zero.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            0,
            Expense."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Non-Refundable Amount"), 0, Expense.TableCaption()));
    end;

    [Test]
    procedure NonRefundableAmountIsRecalcWhenReportItemizationSubcategoryChanges()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseSubCategoryRefundable: Record "Expense Subcategory";
        ExpenseSubCategoryNonRefundable: Record "Expense Subcategory";
        ExpenseReportLineItem: Record "Expense Report Line Item";
        Amount: Decimal;
    begin
        // [SCENARIO 640848] Verify that the Expense Report Line "Non-Refundable Amount" is recalculated when a report itemization line's subcategory changes across the refundable/non-refundable boundary.
        Initialize();

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Itemize requirement.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense Report with a refundable line for the full amount in LCY.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);

        // [GIVEN] Create a refundable and a non-refundable Expense Subcategory under the Expense Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategoryRefundable, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategoryNonRefundable, ExpenseCategory.Code, false);

        // [WHEN] Create a report itemization line for the full amount using the refundable subcategory.
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItem, ExpenseReportLine, ExpenseCategory.Code, ExpenseSubCategoryRefundable.Code, WorkDate(), Amount, 1);

        // [THEN] Verify that the "Non-Refundable Amount" is zero.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            0,
            ExpenseReportLine."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Non-Refundable Amount"), 0, ExpenseReportLine.TableCaption()));

        // [WHEN] Change the report itemization subcategory to a non-refundable one.
        ExpenseReportLineItem.Validate("Expense Subcategory Code", ExpenseSubCategoryNonRefundable.Code);
        ExpenseReportLineItem.Modify(true);

        // [THEN] Verify that the "Non-Refundable Amount" is recalculated to the itemization amount.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            Amount,
            ExpenseReportLine."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Non-Refundable Amount"), Amount, ExpenseReportLine.TableCaption()));

        // [WHEN] Change the report itemization subcategory back to a refundable one.
        ExpenseReportLineItem.Validate("Expense Subcategory Code", ExpenseSubCategoryRefundable.Code);
        ExpenseReportLineItem.Modify(true);

        // [THEN] Verify that the "Non-Refundable Amount" is recalculated back to zero.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            0,
            ExpenseReportLine."Non-Refundable Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Non-Refundable Amount"), 0, ExpenseReportLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Rule Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Rule Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Rule Test");
    end;

    local procedure CreateExpense(var Expense: Record Expense; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, CurrencyCode, Amount);
    end;

    local procedure CreateExpenseWithRule(
        var Expense: Record Expense;
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseDetailRequired);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        if ExpenseDetailRequired = "Expense Detail Needed"::"Per Diem" then begin
            LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);
            LibraryExpense.CreateExpenseRuleWithCondition(
                ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", EffectiveDate,
                JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);
            LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
            Expense.Validate("Starting Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Validate("Ending Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Modify();
        end else begin
            LibraryExpense.CreateExpenseRuleWithCondition(
                ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', EffectiveDate,
                JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);
            LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
        end;
    end;

    local procedure CreateAndReleaseExpenseWithPerDiemRule(
        var Expense: Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        ReimbursementType: Enum "Expense Reimbursement Type";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired);
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", EffectiveDate,
            JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
        Expense.Validate("Starting Date and Time", StartingDateTime);
        Expense.Validate("Ending Date and Time", EndingDateTime);
        Expense.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense."Expense Category", ExpenseUser."No.");
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateAndReleaseExpenseReportWithPerDiemRule(
        var ExpenseReportHeader: Record "Expense Report Header";
        var ExpenseReportLine: Record "Expense Report Line";
        var ExpenseUser: Record "Expense User";
        var ExpenseRuleHeader: Record "Expense Rule Header";
        var ExpenseRuleCondition: Record "Expense Rule Condition";
        CountryRegionCode: Code[10];
        City: Text[30];
        CurrencyCode: Code[10];
        Amount: Decimal;
        EffectiveDate: Date;
        StartingDateTime: DateTime;
        EndingDateTime: DateTime;
        ExpenseDetailRequired: Enum "Expense Detail Needed";
        JustificationRequired: Enum "Expense Justification";
        ReimbursementType: Enum "Expense Reimbursement Type";
        UnitOfMeasureCode: Code[10];
        ConditionType: Enum "Expense Rule Condition Type";
        Refundable: Boolean;
        Value: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ReimbursementType, ExpenseDetailRequired);
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, CountryRegionCode, City);
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, ExpenseLocation."No.", EffectiveDate,
            JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, CurrencyCode, Amount);
        ExpenseReportLine.Validate("Expense Location", ExpenseLocation."No.");
        ExpenseReportLine.Validate(Refundable, Refundable);
        ExpenseReportLine.Validate("Starting Date and Time", StartingDateTime);
        ExpenseReportLine.Validate("Ending Date and Time", EndingDateTime);
        ExpenseReportLine.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, ExpenseCategory.Code, ExpenseUser."No.");
        ExpenseReportHeader.PerformManualRelease();
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(var ExpenseUser: Record "Expense User"; CategoryCode: Code[20]; ExpenseUserNo: Code[20])
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseUser.Get(ExpenseUserNo);
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure CreateAndAttachExpenseToExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10])
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, '');
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);

        Assert.AreEqual(
            ExpectedAmount,
            GLEntry.Amount,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::Invoice);
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
#pragma warning restore AA0210
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields("Amount (LCY)");

        Assert.AreEqual(
            ExpectedAmount,
            EmployeeLedgerEntry."Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, EmployeeLedgerEntry.FieldCaption("Amount (LCY)"), ExpectedAmount, EmployeeLedgerEntry.TableCaption()));
    end;

    local procedure VerifyDetailedEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.SetRange("Document Type", DetailedEmployeeLedgerEntry."Document Type"::Invoice);
        DetailedEmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgerEntry.CalcSums("Amount (LCY)");

        Assert.AreEqual(
            ExpectedAmount,
            DetailedEmployeeLedgerEntry."Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, DetailedEmployeeLedgerEntry.FieldCaption("Amount (LCY)"), ExpectedAmount, DetailedEmployeeLedgerEntry.TableCaption()));
    end;

    local procedure VerifyExpenseLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; Expense: Record Expense; EmployeeNo: Code[20]; Amount: Decimal; AmountLCY: Decimal)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
#pragma warning disable AA0210
        ExpenseLedgerEntry.SetRange("Document Type", ExpenseLedgerEntry."Document Type"::Invoice);
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        ExpenseLedgerEntry.FindFirst();
        Assert.RecordCount(ExpenseLedgerEntry, 1);
        SourceCodeSetup.Get();

        ExpenseCategory.Get(PostedExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        Assert.AreEqual(
            Expense."Expense User No.",
            ExpenseLedgerEntry."Expense User No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense User No."), Expense."Expense User No.", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine.Description,
            ExpenseLedgerEntry."Description",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Description"), PostedExpenseReportLine.Description, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmployeeNo,
            ExpenseLedgerEntry."Employee No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Employee No."), EmployeeNo, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."Posting Date",
            ExpenseLedgerEntry."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Posting Date"), PostedExpenseReportHeader."Posting Date", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Currency Code",
            ExpenseLedgerEntry."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Currency Code"), Expense."Currency Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Payment Method Code",
            ExpenseLedgerEntry."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Payment Method Code"), PostedExpenseReportLine."Payment Method Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Amount,
            ExpenseLedgerEntry."Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AmountLCY,
            ExpenseLedgerEntry."Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Amount,
            ExpenseLedgerEntry."Original Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AmountLCY,
            ExpenseLedgerEntry."Original Amt. (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amt. (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Non-Refundable Amount",
           ExpenseLedgerEntry."Non-Refundable Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Non-Refundable Amount"), PostedExpenseReportLine."Non-Refundable Amount", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Non-Refundable Amount (LCY)",
           ExpenseLedgerEntry."Non-Refundable Amount (LCY)",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Non-Refundable Amount (LCY)"), PostedExpenseReportLine."Non-Refundable Amount (LCY)", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Reimbursable Amount",
           ExpenseLedgerEntry."Reimbursable Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Reimbursable Amount"), PostedExpenseReportLine."Reimbursable Amount", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Reimbursable Amount (LCY)",
           ExpenseLedgerEntry."Reimbursable Amount (LCY)",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Reimbursable Amount (LCY)"), PostedExpenseReportLine."Reimbursable Amount (LCY)", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Expense Category",
            ExpenseLedgerEntry."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense Category"), Expense."Expense Category", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Expense Subcategory",
            ExpenseLedgerEntry."Expense Subcategory Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense Subcategory Code"), Expense."Expense Subcategory", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."Employee Posting Group",
            ExpenseLedgerEntry."Employee Posting Group",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Employee Posting Group"), PostedExpenseReportHeader."Employee Posting Group", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Dimension Set ID",
           ExpenseLedgerEntry."Dimension Set ID",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Dimension Set ID"), PostedExpenseReportLine."Dimension Set ID", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Shortcut Dimension 1 Code",
           ExpenseLedgerEntry."Global Dimension 1 Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Global Dimension 1 Code"), PostedExpenseReportLine."Shortcut Dimension 1 Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Shortcut Dimension 2 Code",
           ExpenseLedgerEntry."Global Dimension 2 Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Global Dimension 2 Code"), PostedExpenseReportLine."Shortcut Dimension 2 Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           UserId,
           ExpenseLedgerEntry."User ID",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("User ID"), UserId, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           SourceCodeSetup.Expense,
           ExpenseLedgerEntry."Source Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Source Code"), SourceCodeSetup.Expense, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           false,
           ExpenseLedgerEntry.Reversed,
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption(Reversed), false, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Job No.",
            ExpenseLedgerEntry."Job No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job No."), Expense."Job No.", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Expense."Job Task No.",
            ExpenseLedgerEntry."Job Task No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job Task No."), Expense."Job Task No.", ExpenseLedgerEntry.TableCaption()));
    end;

    local procedure VerifyExpenseLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; ExpenseReportLine: Record "Expense Report Line"; EmployeeNo: Code[20]; Amount: Decimal; AmountLCY: Decimal)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
#pragma warning disable AA0210
        ExpenseLedgerEntry.SetRange("Document Type", ExpenseLedgerEntry."Document Type"::Invoice);
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange("Document Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        ExpenseLedgerEntry.FindFirst();
        Assert.RecordCount(ExpenseLedgerEntry, 1);
        SourceCodeSetup.Get();

        ExpenseCategory.Get(PostedExpenseReportLine."Expense Category");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        Assert.AreEqual(
            ExpenseReportLine."Expense User No.",
            ExpenseLedgerEntry."Expense User No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense User No."), ExpenseReportLine."Expense User No.", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine.Description,
            ExpenseLedgerEntry."Description",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Description"), PostedExpenseReportLine.Description, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            EmployeeNo,
            ExpenseLedgerEntry."Employee No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Employee No."), EmployeeNo, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."Posting Date",
            ExpenseLedgerEntry."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Posting Date"), PostedExpenseReportHeader."Posting Date", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Expense Currency Code",
            ExpenseLedgerEntry."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Currency Code"), ExpenseReportLine."Expense Currency Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Payment Method Code",
            ExpenseLedgerEntry."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Payment Method Code"), PostedExpenseReportLine."Payment Method Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Amount,
            ExpenseLedgerEntry."Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AmountLCY,
            ExpenseLedgerEntry."Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            Amount,
            ExpenseLedgerEntry."Original Amount",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AmountLCY,
            ExpenseLedgerEntry."Original Amt. (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amt. (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Non-Refundable Amount",
           ExpenseLedgerEntry."Non-Refundable Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Non-Refundable Amount"), PostedExpenseReportLine."Non-Refundable Amount", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Non-Refundable Amount (LCY)",
           ExpenseLedgerEntry."Non-Refundable Amount (LCY)",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Non-Refundable Amount (LCY)"), PostedExpenseReportLine."Non-Refundable Amount (LCY)", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Reimbursable Amount",
           ExpenseLedgerEntry."Reimbursable Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Reimbursable Amount"), PostedExpenseReportLine."Reimbursable Amount", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Reimbursable Amount (LCY)",
           ExpenseLedgerEntry."Reimbursable Amount (LCY)",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Reimbursable Amount (LCY)"), PostedExpenseReportLine."Reimbursable Amount (LCY)", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Expense Category",
            ExpenseLedgerEntry."Expense Category",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense Category"), ExpenseReportLine."Expense Category", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            '',
            ExpenseLedgerEntry."Expense Subcategory Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Expense Subcategory Code"), '', ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."Employee Posting Group",
            ExpenseLedgerEntry."Employee Posting Group",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Employee Posting Group"), PostedExpenseReportHeader."Employee Posting Group", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Dimension Set ID",
           ExpenseLedgerEntry."Dimension Set ID",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Dimension Set ID"), PostedExpenseReportLine."Dimension Set ID", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Shortcut Dimension 1 Code",
           ExpenseLedgerEntry."Global Dimension 1 Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Global Dimension 1 Code"), PostedExpenseReportLine."Shortcut Dimension 1 Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           PostedExpenseReportLine."Shortcut Dimension 2 Code",
           ExpenseLedgerEntry."Global Dimension 2 Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Global Dimension 2 Code"), PostedExpenseReportLine."Shortcut Dimension 2 Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           UserId,
           ExpenseLedgerEntry."User ID",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("User ID"), UserId, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           SourceCodeSetup.Expense,
           ExpenseLedgerEntry."Source Code",
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Source Code"), SourceCodeSetup.Expense, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
           false,
           ExpenseLedgerEntry.Reversed,
           StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption(Reversed), false, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Job No.",
            ExpenseLedgerEntry."Job No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job No."), ExpenseReportLine."Job No.", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            ExpenseReportLine."Job Task No.",
            ExpenseLedgerEntry."Job Task No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Job Task No."), ExpenseReportLine."Job Task No.", ExpenseLedgerEntry.TableCaption()));
    end;

    local procedure GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser: Record "Expense User"): Code[20]
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        Employee.Get(ExpenseUser."Employee No.");
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        exit(EmployeePostingGroup.GetExpenseReportPayablesAccount());
    end;

    local procedure GetRefundableDebitAccountFromExpensePostingGroup(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        exit(ExpensePostingGroup."Refundable Debit Account");
    end;

    local procedure VerifyExpensePerDiem(ExpenseNo: Code[20]; Date: Date; Description: Text; ExpectedAmount: Decimal)
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
#pragma warning disable AA0210
        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        ExpensePerDiem.SetRange(Date, Date);
#pragma warning restore AA0210
        ExpensePerDiem.FindFirst();

        Assert.AreEqual(
           Description,
           ExpensePerDiem.Description,
           StrSubstNo(ValueMustBeEqualErr, ExpensePerDiem.FieldCaption(Description), Description, ExpensePerDiem.TableCaption()));
        Assert.AreEqual(
           ExpectedAmount,
           ExpensePerDiem."Per Diem Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpensePerDiem.FieldCaption("Per Diem Amount"), ExpectedAmount, ExpensePerDiem.TableCaption()));
    end;

    local procedure VerifyExpenseReportLinePerDiem(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; Date: Date; Description: Text; ExpectedAmount: Decimal)
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
#pragma warning disable AA0210
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        ExpenseReportLinePerDiem.SetRange(Date, Date);
#pragma warning restore AA0210
        ExpenseReportLinePerDiem.FindFirst();

        Assert.AreEqual(
           Description,
           ExpenseReportLinePerDiem.Description,
           StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption(Description), Description, ExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
           ExpectedAmount,
           ExpenseReportLinePerDiem."Per Diem Amount",
           StrSubstNo(ValueMustBeEqualErr, ExpenseReportLinePerDiem.FieldCaption("Per Diem Amount"), ExpectedAmount, ExpenseReportLinePerDiem.TableCaption()));
    end;

    local procedure VerifyPostedExpenseReportLinePerDiem(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; Date: Date; Description: Text; ExpectedAmount: Decimal)
    var
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
    begin
#pragma warning disable AA0210
        PostedExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        PostedExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        PostedExpenseReportLinePerDiem.SetRange(Date, Date);
#pragma warning restore AA0210
        PostedExpenseReportLinePerDiem.FindFirst();

        Assert.AreEqual(
           Description,
           PostedExpenseReportLinePerDiem.Description,
           StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption(Description), Description, PostedExpenseReportLinePerDiem.TableCaption()));
        Assert.AreEqual(
           ExpectedAmount,
           PostedExpenseReportLinePerDiem."Per Diem Amount",
           StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLinePerDiem.FieldCaption("Per Diem Amount"), ExpectedAmount, PostedExpenseReportLinePerDiem.TableCaption()));
    end;

    local procedure VerifyRecordCountOfPostedExpenseReportLinePerDiem(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; ExpectedRecordCount: Integer)
    var
        PostedExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem";
    begin
#pragma warning disable AA0210
        PostedExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        if ExpenseReportLineNo <> 0 then
            PostedExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
#pragma warning restore AA0210
        Assert.RecordCount(PostedExpenseReportLinePerDiem, ExpectedRecordCount);
    end;

    local procedure UpdateExpensePerDiemWithMealReduction(ExpenseNo: Code[20]; Date: Date; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean)
    var
        ExpensePerDiem: Record "Expense Per Diem";
    begin
#pragma warning disable AA0210
        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        ExpensePerDiem.SetRange(Date, Date);
#pragma warning restore AA0210
        ExpensePerDiem.FindFirst();

        ExpensePerDiem.Validate(Breakfast, Breakfast);
        ExpensePerDiem.Validate(Lunch, Lunch);
        ExpensePerDiem.Validate(Dinner, Dinner);
        ExpensePerDiem.Modify();
    end;

    local procedure UpdateExpenseReportLinePerDiemWithMealReduction(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; Date: Date; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean)
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
#pragma warning disable AA0210
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        ExpenseReportLinePerDiem.SetRange(Date, Date);
#pragma warning restore AA0210
        ExpenseReportLinePerDiem.FindFirst();

        ExpenseReportLinePerDiem.Validate(Breakfast, Breakfast);
        ExpenseReportLinePerDiem.Validate(Lunch, Lunch);
        ExpenseReportLinePerDiem.Validate(Dinner, Dinner);
        ExpenseReportLinePerDiem.Modify();
    end;

    local procedure CalculateAmountReduction(ExpenseNo: Code[20]; Date: Date): Decimal
    var
        Expense: Record Expense;
        ExpenseCurrency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        Expense.Get(ExpenseNo);
        if Expense."Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(Expense."Currency Code");

#pragma warning disable AA0210
        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        ExpensePerDiem.SetRange("Date", Date);
#pragma warning restore AA0210
        ExpensePerDiem.FindFirst();

        CalculatedPerDiemAmount := ExpensePerDiem."Original Per Diem Amount";

        if (ExpensePerDiem.Breakfast) and (ExpensePerDiem."Breakfast Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Breakfast Reduction Percent";
        if (ExpensePerDiem.Lunch) and (ExpensePerDiem."Lunch Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Lunch Reduction Percent";
        if (ExpensePerDiem.Dinner) and (ExpensePerDiem."Dinner Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Dinner Reduction Percent";

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (ExpensePerDiem."Original Per Diem Amount" * TotalReductionPercent / 100);

        exit(Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision"));
    end;

    local procedure CalculateAmountReduction(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; Date: Date): Decimal
    var
        ExpenseCurrency: Record Currency;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        ExpenseReportLine.Get(ExpenseReportNo, ExpenseReportLineNo);
        if ExpenseReportLine."Expense Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(ExpenseReportLine."Expense Currency Code");

#pragma warning disable AA0210
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        ExpenseReportLinePerDiem.SetRange("Date", Date);
#pragma warning restore AA0210
        ExpenseReportLinePerDiem.FindFirst();

        CalculatedPerDiemAmount := ExpenseReportLinePerDiem."Original Per Diem Amount";

        if (ExpenseReportLinePerDiem.Breakfast) and (ExpenseReportLinePerDiem."Breakfast Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Breakfast Reduction Percent";
        if (ExpenseReportLinePerDiem.Lunch) and (ExpenseReportLinePerDiem."Lunch Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Lunch Reduction Percent";
        if (ExpenseReportLinePerDiem.Dinner) and (ExpenseReportLinePerDiem."Dinner Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Dinner Reduction Percent";

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (ExpenseReportLinePerDiem."Original Per Diem Amount" * TotalReductionPercent / 100);

        exit(Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision"));
    end;

    local procedure VerifyRecordCountOfEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(EmployeeLedgerEntry, ExpectedRecordCount);
    end;

    local procedure VerifyRecordCountOfGeneralLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        GeneralLedgerEntry: Record "G/L Entry";
    begin
        GeneralLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GeneralLedgerEntry, ExpectedRecordCount);
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportNo: Code[20])
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        ExpenseReportLine.FindFirst();
    end;

    local procedure FindExpenseReportLineItemization(var ExpenseReportLineItem: Record "Expense Report Line Item"; ExpenseReportNo: Code[20]; ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLineItem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLineItem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineItem.FindFirst();
    end;

    local procedure FindExpenseReportLineParticipant(var ExpenseReportLineParticipant: Record "Expense Report Line Particip."; ExpenseReportNo: Code[20]; ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLineParticipant.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLineParticipant.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineParticipant.FindFirst();
    end;

    local procedure FindPostedExpenseReportHeader(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseUserNo: Code[20])
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportNo: Code[20])
    begin
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportNo);
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure FindPostedExpenseReportLineItem(var PstdExpenseReportItemizationLine: Record "Posted Exp. Rep. Line Item"; ExpenseReportNo: Code[20]; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        PstdExpenseReportItemizationLine.SetRange("Expense Report No.", ExpenseReportNo);
        PstdExpenseReportItemizationLine.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
        PstdExpenseReportItemizationLine.FindFirst();
    end;

    local procedure FindPostedExpenseReportLineParticipant(var PstdExpenseReportLineParticipant: Record "Posted Exp. Rep. Line Particip"; ExpenseReportNo: Code[20]; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        PstdExpenseReportLineParticipant.SetRange("Expense Report No.", ExpenseReportNo);
        PstdExpenseReportLineParticipant.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
        PstdExpenseReportLineParticipant.FindFirst();
    end;

    local procedure FindExpenseReportLinePerDiem(var ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem"; ExpenseReportNo: Code[20]; ExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLinePerDiem.FindFirst();
    end;

    local procedure FindPostedExpenseReportLinePerDiem(var PstdExpenseReportLinePerDiem: Record "Posted Exp. Rep. Line Per Diem"; ExpenseReportNo: Code[20]; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        PstdExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        PstdExpenseReportLinePerDiem.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
        PstdExpenseReportLinePerDiem.FindFirst();
    end;

    local procedure BuildExtraDetailsMessage(HasFirst: Boolean; HasSecond: Boolean; HasThird: Boolean): Text
    var
        ExtraItems: Text;
    begin
        ExtraItems := '';

        if HasFirst then
            ExtraItems := ParticipantsItemizationLbl;

        if HasSecond then
            if ExtraItems <> '' then
                ExtraItems := ExtraItems + AndLbl + PerDiemLbl
            else
                ExtraItems := PerDiemLbl;

        if HasThird then
            if ExtraItems <> '' then
                ExtraItems := ExtraItems + AndLbl + MileageLbl
            else
                ExtraItems := MileageLbl;

        if ExtraItems = '' then
            ExtraItems := AdditionalDetailsLbl;

        exit(ExtraItems);
    end;

    local procedure UpdateReductionForMealPerDiem(Breakfast: Decimal; Lunch: Decimal; Dinner: Decimal)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Reduction for Breakfast %", Breakfast);
        ExpenseAgentSetup.Validate("Reduction for Lunch %", Lunch);
        ExpenseAgentSetup.Validate("Reduction for Dinner %", Dinner);
        ExpenseAgentSetup.Modify();
    end;

    local procedure CalculateAmountReduction(ExpenseNo: Code[20]): Decimal
    var
        Expense: Record Expense;
        ExpenseCurrency: Record Currency;
        ExpensePerDiem: Record "Expense Per Diem";
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        Expense.Get(ExpenseNo);
        if Expense."Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(Expense."Currency Code");

        ExpensePerDiem.SetRange("Expense No.", ExpenseNo);
        ExpensePerDiem.FindFirst();

        CalculatedPerDiemAmount := ExpensePerDiem."Original Per Diem Amount";

        if (ExpensePerDiem.Breakfast) and (ExpensePerDiem."Breakfast Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Breakfast Reduction Percent";
        if (ExpensePerDiem.Lunch) and (ExpensePerDiem."Lunch Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Lunch Reduction Percent";
        if (ExpensePerDiem.Dinner) and (ExpensePerDiem."Dinner Reduction Percent" <> 0) then
            TotalReductionPercent += ExpensePerDiem."Dinner Reduction Percent";

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (ExpensePerDiem."Original Per Diem Amount" * TotalReductionPercent / 100);

        exit(Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision"));
    end;

    local procedure CalculateAmountReduction(ExpenseReportNo: Code[20]; ExpenseReportLineNo: Integer; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean): Decimal
    var
        ExpenseCurrency: Record Currency;
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
        CalculatedPerDiemAmount: Decimal;
        TotalReductionPercent: Decimal;
    begin
        ExpenseReportLine.Get(ExpenseReportNo, ExpenseReportLineNo);
        if ExpenseReportLine."Expense Currency Code" = '' then
            ExpenseCurrency.InitRoundingPrecision()
        else
            ExpenseCurrency.Get(ExpenseReportLine."Expense Currency Code");

        ExpenseReportLinePerDiem.SetRange("Expense Report No.", ExpenseReportNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", ExpenseReportLineNo);
        ExpenseReportLinePerDiem.FindFirst();

        CalculatedPerDiemAmount := ExpenseReportLinePerDiem."Original Per Diem Amount";

        if (Breakfast) and (ExpenseReportLinePerDiem."Breakfast Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Breakfast Reduction Percent";
        if (Lunch) and (ExpenseReportLinePerDiem."Lunch Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Lunch Reduction Percent";
        if (Dinner) and (ExpenseReportLinePerDiem."Dinner Reduction Percent" <> 0) then
            TotalReductionPercent += ExpenseReportLinePerDiem."Dinner Reduction Percent";

        CalculatedPerDiemAmount := CalculatedPerDiemAmount - (ExpenseReportLinePerDiem."Original Per Diem Amount" * TotalReductionPercent / 100);

        exit(Round(CalculatedPerDiemAmount, ExpenseCurrency."Amount Rounding Precision"));
    end;

    local procedure CreateExpenseWithItemization(var Expense: Record Expense; var ExpenseRuleCondition1: Record "Expense Rule Condition"; CurrencyCode: Code[10]; RuleCurrencyCode: Code[10]; Amount: Decimal; RuleAmount: Decimal; JustificationAmount: Decimal)
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        LibraryERM.FindPostCode(PostCode);
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::"Against Conditions", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, RuleAmount);

        ExpenseRuleHeader.Validate("Currency Code", RuleCurrencyCode);
        ExpenseRuleHeader.Modify();

        ExpenseUser.Get(Expense."Expense User No.");
        LibraryExpense.CreateExpenseRuleCondition(ExpenseRuleCondition1, ExpenseRuleHeader, ExpenseRuleCondition1."Condition Type"::"At Least Justification Needed", JustificationAmount);
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense."Expense Category", ExpenseUser."No.");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", true);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));
    end;

    local procedure CreateAndAttachExpenseToExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; VATBusPostingGroupCode: Code[20])
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, VATBusPostingGroupCode);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure CreateNonRefundableItemizationForExpense(Expense: Record Expense; Amount: Decimal)
    var
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseItemization: Record "Expense Itemization";
    begin
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, Expense."Expense Category", false);
        LibraryExpense.CreateExpenseItemization(ExpenseItemization, Expense, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));
    end;

    local procedure UpdateRefundableItemizationForExpense(Expense: Record Expense; Amount: Decimal)
    var
        ExpenseItemization: Record "Expense Itemization";
    begin
        ExpenseItemization.SetRange("Expense No.", Expense."No.");
        ExpenseItemization.SetRange("Refundable", true);
        if ExpenseItemization.FindFirst() then begin
            ExpenseItemization.Amount := Amount;
            ExpenseItemization.Modify();
        end;
    end;

    local procedure CreateNonRefundableItemizationForExpenseReportLine(ExpenseReportLine: Record "Expense Report Line"; Amount: Decimal)
    var
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseReportLine."Expense Category", false);
        LibraryExpense.CreateExpenseReportLineItemization(ExpenseReportLineItemization, ExpenseReportLine, ExpenseSubCategory."Expense Category Code", ExpenseSubCategory.Code, WorkDate(), Amount, LibraryRandom.RandInt(1));
    end;

    local procedure UpdateRefundableItemizationForExpenseReportLine(ExpenseReportLine: Record "Expense Report Line"; Amount: Decimal)
    var
        ExpenseReportLineItemization: Record "Expense Report Line Item";
    begin
        ExpenseReportLineItemization.SetRange("Expense Report No.", ExpenseReportLine."Document No.");
        ExpenseReportLineItemization.SetRange("Expense Report Line No.", ExpenseReportLine."Line No.");
        ExpenseReportLineItemization.SetRange("Refundable", true);
        if ExpenseReportLineItemization.FindFirst() then begin
            ExpenseReportLineItemization.Amount := Amount;
            ExpenseReportLineItemization.Modify();
        end;
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseParticipantsModalPageHandler(var ExpenseParticipants: TestPage "Expense Participants")
    begin
        ExpenseParticipants."Participant Employee No.".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseParticipants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseReportParticipantsModalPageHandler(var ExpenseReportLineParticipants: TestPage "Expense Report Line Particips")
    begin
        ExpenseReportLineParticipants."Participant Employee No.".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineParticipants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseReportItemizationModalPageHandler(var ExpenseReportLineItemizations: TestPage "Expense Report Line Items")
    begin
        ExpenseReportLineItemizations."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineItemizations."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());
        Assert.AreEqual(
            false,
            ExpenseReportLineItemizations.Amount.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseReportLineItemizations.Amount.Caption(), ExpenseReportLineItemizations.Caption()));
        ExpenseReportLineItemizations.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpensesModalPageHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        ExpensePerDiem."Per Diem Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        ExpensePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyAmountInExpenseReportLinePerDiemModalPageHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    begin
        ExpenseReportLinePerDiem.Breakfast.AssertEquals(true);
        ExpenseReportLinePerDiem.Lunch.AssertEquals(true);
        ExpenseReportLinePerDiem.Dinner.AssertEquals(true);
        ExpenseReportLinePerDiem."Per Diem Amount".AssertEquals(CalculateAmountReduction(CopyStr(LibraryVariableStorage.DequeueText(), 1, 20)));
        ExpenseReportLinePerDiem.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseReportLinePerDiemModalPageHandler(var ExpenseReportLinePerDiem: TestPage "Expense Report Line Per Diems")
    var
        Breakfast: Boolean;
        Lunch: Boolean;
        Dinner: Boolean;
    begin
        Breakfast := LibraryVariableStorage.DequeueBoolean();
        Lunch := LibraryVariableStorage.DequeueBoolean();
        Dinner := LibraryVariableStorage.DequeueBoolean();

        ExpenseReportLinePerDiem.Breakfast.SetValue(Breakfast);
        ExpenseReportLinePerDiem.Lunch.SetValue(Lunch);
        ExpenseReportLinePerDiem.Dinner.SetValue(Dinner);

        ExpenseReportLinePerDiem."Per Diem Amount".AssertEquals(
            CalculateAmountReduction(
                CopyStr(LibraryVariableStorage.DequeueText(), 1, 20),
                LibraryVariableStorage.DequeueInteger(),
                Breakfast,
                Lunch,
                Dinner));
        ExpenseReportLinePerDiem.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}