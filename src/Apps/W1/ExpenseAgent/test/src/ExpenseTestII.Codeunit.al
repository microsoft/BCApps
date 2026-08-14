// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;
using System.Automation;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 148309 "Expense Test II"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryJob: Codeunit "Library - Job";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTemplates: Codeunit "Library - Templates";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        AddExpenseTo: Option "New Expense Report","Existing Expense Report";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        ExpenseDetailRequiredCannotBeChangedWhenRuleExistErr: Label '%1 cannot be changed because there are existing Expense Rules for this Expense Category %2.', Comment = '%1 = Field Caption, %2 = Expense Category Code';
        ExpenseDetailRequiredMustBePerDiemErr: Label '%1 must be set to %2 in %3 %4 to create an Expense Rule for %5 %6.',
                                                     Comment = '%1 = Field Caption, %2 = Field Value, %3 = Table Caption, %4 = Expense Category Code, %5 = Field Caption, %6 = Expense Location';
        NonRefundableAmountCannotBeNegativeErr: Label '%1 cannot be in negative on Expense No. %2.', Comment = '%1 = Field Caption, %2 = Expense No.';
        UnitOfMeasureErr: Label 'Unit of Measure Code must be %1 as defined by rule.', Comment = '%1 = Required unit of measure code';
        ExpenseUserMustBeLinkedToAnEmployeeErr: Label 'Expense User %1 must be linked to an Employee No.', Comment = '%1 = Expense User No.';
        BillableCustomerAndProjectErr: Label 'You cannot use both %1 and %2 at the same time.', Comment = '%1 = Billable to Customer field caption, %2 = Project No. field caption';
        ExpenseAlreadyExistErr: Label 'An expense already exists with the same Receipt No. %1, Expense Date %2, Merchant Name %3 and Amount %4.', Comment = '%1 = Receipt No., %2 = Expense Date, %3 = Merchant Name, %4 = Amount';
        SameExpensePaymentMethodForReimbursementExistErr: Label '%1 %2 with the same %3 "%4" already exists. %3 must be unique for expense report payment methods.', Comment = '%1 = Table Caption, %2 = Expense Payment Method Code, %3 = Reimbursement Type, %4 = Reimbursement Type Value';
        FieldShouldNotBeEditableErr: Label '%1 should not be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldShouldBeEditableErr: Label '%1 should be editable in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        DuplicateEmailErr: Label '%1 %2 is already used by another %3. %1 must be unique.', Comment = '%1 = Email Caption, %2 = Email address, %3 = Expense User Table Caption';
        DuplicateEmployeeNoErr: Label '%1 %2 is already linked to another %3. Each employee can only be linked to one %3.', Comment = '%1 = Employee No. Caption, %2 = Employee No., %3 = Expense User Table Caption';
        ExpenseLocationMissingMsg: Label '%1 is missing in Expense No. %2.', Comment = '%1 = Expense Location Caption, %2 = Expense No.';
        ExpenseReportAlreadyExistErr: Label 'An expense report already exists with the same Receipt No. %1, Expense Date %2, Merchant Name %3 and Amount %4.', Comment = '%1 = Receipt No., %2 = Expense Date, %3 = Merchant Name, %4 = Amount';
        CannotDeleteEmployeeWithPostedExpenseReportErr: Label 'You cannot delete Employee %1 because they have posted expense report.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithExpenseReportErr: Label 'You cannot delete Employee %1 because they have active expense report.', Comment = '%1 = Employee No.';
        CannotDeleteEmployeeWithExpenseErr: Label 'You cannot delete Employee %1 because they have active expense.', Comment = '%1 = Employee No.';
        CannotDeletePaymentMethodInUseErr: Label 'You cannot delete %1 %2 because it is used as the %3 for %4 %5.', Comment = '%1 = Table Caption, %2 = Payment Method Code, %3 = Default Payment Method Field Caption, %4 = Expense Category Table Caption, %5 = Expense Category Code';

    [Test]
    procedure ExpenseDetailRequiredMustFlowToExpenseFromExpenseCategory()
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: array[5] of Record "Expense Category";
        Expense: array[5] of Record Expense;
    begin
        // [SCENARIO 613726] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Expense Category with "Expense Detail Required" Blank.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[1], ExpenseCategory[1]."Reimbursement Type"::"Employee Paid", ExpenseCategory[1]."Expense Detail Required"::" ");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense with Expense Category.
        Expense[1].Init();
        Expense[1].Validate(Description, LibraryUtility.GenerateRandomCode(Expense[1].FieldNo(Description), Database::"Expense"));
        Expense[1].Validate("Expense User No.", ExpenseUser."No.");
        Expense[1].Validate("Expense Category", ExpenseCategory[1].Code);
        Expense[1].Insert(true);

        // [THEN] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Assert.AreEqual(
            ExpenseCategory[1]."Expense Detail Required",
            Expense[1]."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, Expense[1].FieldCaption("Expense Detail Required"), ExpenseCategory[1]."Expense Detail Required", Expense[1].TableCaption()));

        // [GIVEN] Create Expense Category with "Expense Detail Required" Itemize.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[2], ExpenseCategory[2]."Reimbursement Type"::"Employee Paid", ExpenseCategory[2]."Expense Detail Required"::Itemize);

        // [WHEN] Create Expense with Expense Category.
        Expense[2].Init();
        Expense[2].Validate(Description, LibraryUtility.GenerateRandomCode(Expense[2].FieldNo(Description), Database::"Expense"));
        Expense[2].Validate("Expense User No.", ExpenseUser."No.");
        Expense[2].Validate("Expense Category", ExpenseCategory[2].Code);
        Expense[2].Insert(true);

        // [THEN] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Assert.AreEqual(
            ExpenseCategory[2]."Expense Detail Required",
            Expense[2]."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, Expense[2].FieldCaption("Expense Detail Required"), ExpenseCategory[2]."Expense Detail Required", Expense[2].TableCaption()));

        // [GIVEN] Create Expense Category with "Expense Detail Required" Mileage.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[3], ExpenseCategory[3]."Reimbursement Type"::"Employee Paid", ExpenseCategory[3]."Expense Detail Required"::Mileage);

        // [WHEN] Create Expense with Expense Category.
        Expense[3].Init();
        Expense[3].Validate(Description, LibraryUtility.GenerateRandomCode(Expense[3].FieldNo(Description), Database::"Expense"));
        Expense[3].Validate("Expense User No.", ExpenseUser."No.");
        Expense[3].Validate("Expense Category", ExpenseCategory[3].Code);
        Expense[3].Insert(true);

        // [THEN] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Assert.AreEqual(
            ExpenseCategory[3]."Expense Detail Required",
            Expense[3]."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, Expense[3].FieldCaption("Expense Detail Required"), ExpenseCategory[3]."Expense Detail Required", Expense[3].TableCaption()));

        // [GIVEN] Create Expense Category with "Expense Detail Required" Participants.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[4], ExpenseCategory[4]."Reimbursement Type"::"Employee Paid", ExpenseCategory[4]."Expense Detail Required"::Participants);

        // [WHEN] Create Expense with Expense Category.
        Expense[4].Init();
        Expense[4].Validate(Description, LibraryUtility.GenerateRandomCode(Expense[4].FieldNo(Description), Database::"Expense"));
        Expense[4].Validate("Expense User No.", ExpenseUser."No.");
        Expense[4].Validate("Expense Category", ExpenseCategory[4].Code);
        Expense[4].Insert(true);

        // [THEN] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Assert.AreEqual(
            ExpenseCategory[4]."Expense Detail Required",
            Expense[4]."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, Expense[4].FieldCaption("Expense Detail Required"), ExpenseCategory[4]."Expense Detail Required", Expense[4].TableCaption()));

        // [GIVEN] Create Expense Category with "Expense Detail Required" Per Diem.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[5], ExpenseCategory[5]."Reimbursement Type"::"Employee Paid", ExpenseCategory[5]."Expense Detail Required"::"Per Diem");

        // [WHEN] Create Expense with Expense Category.
        Expense[5].Init();
        Expense[5].Validate(Description, LibraryUtility.GenerateRandomCode(Expense[5].FieldNo(Description), Database::"Expense"));
        Expense[5].Validate("Expense User No.", ExpenseUser."No.");
        Expense[5].Validate("Expense Category", ExpenseCategory[5].Code);
        Expense[5].Insert(true);

        // [THEN] Verify that the Expense Detail Required must flow to Expense from Expense Category.
        Assert.AreEqual(
            ExpenseCategory[5]."Expense Detail Required",
            Expense[5]."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, Expense[5].FieldCaption("Expense Detail Required"), ExpenseCategory[5]."Expense Detail Required", Expense[5].TableCaption()));
    end;

    [Test]
    procedure RuleIdIsClearedWhenExpenseDateIsChanged()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
        EmptyGuid: Guid;
        NewExpenseDate: Date;
    begin
        // [SCENARIO 613726] Verify that Rule Id is cleared when Expense Date is changed.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule that has an Applied Rule Id.
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Itemize, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that the Rule Id in expense.
        Assert.AreEqual(
            ExpenseRuleHeader.SystemId,
            Expense."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Applied Rule Id"), ExpenseRuleHeader.SystemId, Expense.TableCaption()));

        // [WHEN] Change Expense Date.
        NewExpenseDate := CalcDate('<-1D>', Expense."Expense Date");
        LibraryERM.CreateExchangeRate(CurrencyCode, NewExpenseDate, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Expense.Validate("Expense Date", NewExpenseDate);
        Expense.Modify();

        // [THEN] Verify Rule Id is cleared.
        Assert.AreEqual(
            EmptyGuid,
            Expense."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Applied Rule Id"), EmptyGuid, Expense.TableCaption()));
    end;

    [Test]
    procedure ExpenseDetailRequiredCannotBeChangedWhenRuleExists()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
    begin
        // [SCENARIO 613726] Verify that the Expense Detail Required cannot be changed when expense rules exist for Expense Category.
        Initialize();

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Participants);

        // [GIVEN] Create Expense Rule.
        LibraryExpense.CreateExpenseRuleWithCondition(
            ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', WorkDate(),
            ExpenseRuleHeader."Justification Required"::" ", '', '', ExpenseRuleCondition."Condition Type"::"Max Amount", 100);

        // [WHEN] Update "Expense Detail Required" in Expense Category.
        asserterror ExpenseCategory.Validate("Expense Detail Required", ExpenseCategory."Expense Detail Required"::Mileage);

        // [THEN] Verify that the Expense Detail Required cannot be changed when expense rules exist for Expense Category.
        Assert.ExpectedError(StrSubstNo(ExpenseDetailRequiredCannotBeChangedWhenRuleExistErr, ExpenseCategory.FieldCaption("Expense Detail Required"), ExpenseCategory.Code));
    end;

    [Test]
    procedure ExpenseLocationOnlyAllowedForPerDiemRules()
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseRuleHeader: Record "Expense Rule Header";
        PostCode: Record "Post Code";
    begin
        // [SCENARIO 613726] Verify that Expense Location can only be set for Per Diem expense categories in rules.
        Initialize();

        // [GIVEN] Find Post Code.
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense Location.
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Create Expense Rule for Itemize category.
        ExpenseRuleHeader.Init();
        ExpenseRuleHeader.Validate("Expense Category Code", ExpenseCategory.Code);
        ExpenseRuleHeader.Validate("Effective Date", WorkDate());
        ExpenseRuleHeader.Insert(true);

        // [WHEN] Update "Expense Location" in Expense Rule.
        asserterror ExpenseRuleHeader.Validate("Expense Location", ExpenseLocation."No.");

        // [THEN] Verify that Expense Location can only be set for Per Diem expense categories in rules.
        Assert.ExpectedError(
            StrSubstNo(
                ExpenseDetailRequiredMustBePerDiemErr,
                ExpenseCategory.FieldCaption("Expense Detail Required"),
                ExpenseCategory."Expense Detail Required"::"Per Diem",
                ExpenseCategory.TableCaption(),
                ExpenseRuleHeader."Expense Category Code",
                ExpenseRuleHeader.FieldCaption("Expense Location"),
                ExpenseLocation."No."));
    end;

    [Test]
    procedure ExpenseDetailRequiredFlowsToExpenseReportLine()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 613726] Verify that Expense Detail Required flows to Expense Report Line from Expense Category.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Mileage);

        // [GIVEN] Create Expense Report Header.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [WHEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '', ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [THEN] Verify that Expense Detail Required flows to Expense Report Line.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            ExpenseCategory."Expense Detail Required",
            ExpenseReportLine."Expense Detail Required",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), ExpenseCategory."Expense Detail Required", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,AddExpensesToExpenseReportModalPageHandler')]
    procedure CreateExpenseReportHandlesExpenseDetailRequired()
    var
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 613726] Verify that Insert Expense Lines handles Expense Detail Required correctly.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category with Itemize requirement.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Perform Manual Release on Expense.
        Expense.PerformManualRelease();

        // [GIVEN] Create Expense Report Header.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // Enqueue Existing Expense Report No. and mark to skip creating a new one.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportHeader."No.");

        // [WHEN] Insert expense into expense report.
        Expense.SetRange("No.", Expense."No.");
        CreateExpenseReport.AddExpensesToReport(Expense);

        // [THEN] Verify that Expense Detail Required flows to expense report line.
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        if ExpenseReportLine.FindFirst() then
            Assert.AreEqual(
                ExpenseCategory."Expense Detail Required",
                ExpenseReportLine."Expense Detail Required",
                StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Detail Required"), ExpenseCategory."Expense Detail Required", ExpenseReportLine.TableCaption()));
    end;

    [Test]
    procedure ReimbursementTypeMustBeUpdatedFromPaymentMethodCodeInExpense()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 616218] Verify that the "Reimbursement Type" is updated from Payment Method in Expense.
        Initialize();

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Validate("Default Payment Method", ExpensePaymentMethod.Code);
        ExpenseCategory.Validate("Reimbursement Type", ExpenseCategory."Reimbursement Type"::"Company Paid");
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);

        // [THEN] Verify that the "Expense Payment Method" is updated from Expense Category in Expense.
        Assert.AreEqual(
            ExpenseCategory."Default Payment Method",
            Expense."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Payment Method Code"), ExpenseCategory."Default Payment Method", Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory.Refundable,
            Expense.Refundable,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable"), ExpenseCategory.Refundable, Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Description"), ExpenseCategory."Posting Description", Expense.TableCaption()));
        Assert.AreEqual(
            ExpensePaymentMethod."Reimbursement Type",
            Expense."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursement Type"), ExpensePaymentMethod."Reimbursement Type", Expense.TableCaption()));
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), Amount, Expense.TableCaption()));

        // [WHEN] Clear Payment Method Code in Expense.
        Expense.Validate("Payment Method Code", '');

        // [THEN] Verify that the Reimbursement Type is updated.
        Assert.AreEqual(
            '',
            Expense."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Payment Method Code"), '', Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory.Refundable,
            Expense.Refundable,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable"), ExpenseCategory.Refundable, Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Description"), ExpenseCategory."Posting Description", Expense.TableCaption()));
        Assert.AreEqual(
            ExpensePaymentMethod."Reimbursement Type"::" ",
            Expense."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursement Type"), ExpensePaymentMethod."Reimbursement Type"::" ", Expense.TableCaption()));
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), 0, Expense.TableCaption()));
        Assert.AreEqual(
            0,
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), 0, Expense.TableCaption()));

        // [WHEN] Set Payment Method Code in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);

        // [THEN] Verify that the Reimbursement Type is updated.
        Assert.AreEqual(
            ExpensePaymentMethod.Code,
            Expense."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Payment Method Code"), ExpensePaymentMethod.Code, Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory.Refundable,
            Expense.Refundable,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Refundable"), ExpenseCategory.Refundable, Expense.TableCaption()));
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Description"), ExpenseCategory."Posting Description", Expense.TableCaption()));
        Assert.AreEqual(
            ExpensePaymentMethod."Reimbursement Type",
            Expense."Reimbursement Type",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursement Type"), ExpensePaymentMethod."Reimbursement Type", Expense.TableCaption()));
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount"), Amount, Expense.TableCaption()));
        Assert.AreEqual(
            Amount,
            Expense."Reimbursable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Reimbursable Amount (LCY)"), Amount, Expense.TableCaption()));
    end;

    [Test]
    procedure WhenToCreateExpenseReportValidationClearsDayOfWeekAndDayInMonthForDaily()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that changing "When to Create Expense Reports" to Daily clears Day of Week and Day In A Month.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Update Day of Week, Day In A Month and Custom Formula.
        ExpenseAgentSetup."Day of Week" := ExpenseAgentSetup."Day of Week"::Monday;
        ExpenseAgentSetup."Day In A Month" := LibraryRandom.RandInt(10);
        Evaluate(ExpenseAgentSetup."Custom Report Creation Formula", '1W');
        ExpenseAgentSetup.Modify();

        // [WHEN] Set "When to Create Expense Reports" to Daily.
        ExpenseAgentSetup.Validate("When to Create Expense Reports", ExpenseAgentSetup."When to Create Expense Reports"::Daily);

        // [THEN] Verify that Day of Week is cleared to Sunday, Day In A Month is cleared to 0, and Custom Formula is cleared.
        Assert.AreEqual(
            ExpenseAgentSetup."Day of Week"::Sunday,
            ExpenseAgentSetup."Day of Week",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day of Week"), ExpenseAgentSetup."Day of Week"::Sunday, ExpenseAgentSetup.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseAgentSetup."Day In A Month",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day In A Month"), 0, ExpenseAgentSetup.TableCaption()));
        Assert.AreEqual(
            '',
            Format(ExpenseAgentSetup."Custom Report Creation Formula"),
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Custom Report Creation Formula"), '', ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure WhenToCreateExpenseReportValidationClearsDayInMonthAndCustomFormulaForWeekly()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that changing "When to Create Expense Reports" to Weekly clears Day In A Month and Custom Formula.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Update Day In A Month and Custom Formula.
        ExpenseAgentSetup."Day In A Month" := LibraryRandom.RandInt(10);
        Evaluate(ExpenseAgentSetup."Custom Report Creation Formula", '<+1M>');
        ExpenseAgentSetup.Modify();

        // [WHEN] Set "When to Create Expense Reports" to Weekly.
        ExpenseAgentSetup.Validate("When to Create Expense Reports", ExpenseAgentSetup."When to Create Expense Reports"::Weekly);

        // [THEN] Verify that Day In A Month is cleared to 0 and Custom Formula is cleared.
        Assert.AreEqual(
            0,
            ExpenseAgentSetup."Day In A Month",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day In A Month"), 0, ExpenseAgentSetup.TableCaption()));
        Assert.AreEqual(
            '',
            Format(ExpenseAgentSetup."Custom Report Creation Formula"),
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Custom Report Creation Formula"), '', ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure WhenToCreateExpenseReportValidationClearsDayOfWeekAndCustomFormulaForMonthly()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that changing "When to Create Expense Reports" to Monthly clears Day of Week and Custom Formula.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Update "Day of Week" and Custom Formula.
        ExpenseAgentSetup."Day of Week" := ExpenseAgentSetup."Day of Week"::Friday;
        Evaluate(ExpenseAgentSetup."Custom Report Creation Formula", '1W');
        ExpenseAgentSetup.Modify();

        // [WHEN] Set "When to Create Expense Reports" to Monthly.
        ExpenseAgentSetup.Validate("When to Create Expense Reports", ExpenseAgentSetup."When to Create Expense Reports"::Monthly);

        // [THEN] Verify that "Day of Week" is cleared to Sunday and Custom Formula is cleared.
        Assert.AreEqual(
            ExpenseAgentSetup."Day of Week"::Sunday,
            ExpenseAgentSetup."Day of Week",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day of Week"), ExpenseAgentSetup."Day of Week"::Sunday, ExpenseAgentSetup.TableCaption()));
        Assert.AreEqual(
            '',
            Format(ExpenseAgentSetup."Custom Report Creation Formula"),
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Custom Report Creation Formula"), '', ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure WhenToCreateExpenseReportValidationClearsDayOfWeekAndDayInMonthForCustom()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that changing "When to Create Expense Reports" to Custom clears Day of Week and Day In A Month.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Update Day of Week and Day In A Month.
        ExpenseAgentSetup."Day of Week" := ExpenseAgentSetup."Day of Week"::Wednesday;
        ExpenseAgentSetup."Day In A Month" := 20;
        ExpenseAgentSetup.Modify();

        // [WHEN] Set "When to Create Expense Reports" to Custom.
        ExpenseAgentSetup.Validate("When to Create Expense Reports", ExpenseAgentSetup."When to Create Expense Reports"::Custom);

        // [THEN] Verify that Day of Week is cleared to Sunday and Day In A Month is cleared to 0.
        Assert.AreEqual(
            ExpenseAgentSetup."Day of Week"::Sunday,
            ExpenseAgentSetup."Day of Week",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day of Week"), ExpenseAgentSetup."Day of Week"::Sunday, ExpenseAgentSetup.TableCaption()));
        Assert.AreEqual(
            0,
            ExpenseAgentSetup."Day In A Month",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day In A Month"), 0, ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure CustomReportCreationFormulaValidationRequiresCustomFrequency()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CustomReportDateFormula: DateFormula;
    begin
        // [SCENARIO 613723] Verify that Custom Report Creation Formula can only be set when frequency is Custom.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Weekly;
        ExpenseAgentSetup.Modify();

        // [WHEN] Try to set Custom Report Creation Formula with non-Custom frequency.
        Evaluate(CustomReportDateFormula, '1D');
        asserterror ExpenseAgentSetup.Validate("Custom Report Creation Formula", CustomReportDateFormula);

        // [THEN] Verify that error is thrown requiring Custom frequency.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("When to Create Expense Reports"), Format(ExpenseAgentSetup."When to Create Expense Reports"::Custom));
    end;

    [Test]
    procedure CustomReportCreationFormulaCanBeSetWhenFrequencyIsCustom()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CustomReportDateFormula: DateFormula;
    begin
        // [SCENARIO 613723] Verify that Custom Report Creation Formula can be set when frequency is Custom.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Set frequency to Custom.
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Custom;
        ExpenseAgentSetup.Modify();

        // [WHEN] Set Custom Report Creation Formula with Custom frequency.
        Evaluate(CustomReportDateFormula, '1W');
        ExpenseAgentSetup.Validate("Custom Report Creation Formula", CustomReportDateFormula);
        ExpenseAgentSetup.Modify();

        // [THEN] Verify that Custom Report Creation Formula is set correctly.
        Assert.AreEqual(
            '1W',
            Format(ExpenseAgentSetup."Custom Report Creation Formula"),
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Custom Report Creation Formula"), '1W', ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure DayOfWeekValidationRequiresWeeklyFrequency()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that Day of Week can only be changed when frequency is Weekly.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Set frequency to Daily.
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Daily;
        ExpenseAgentSetup.Modify();

        // [WHEN] Try to change Day of Week with non-Weekly frequency.
        asserterror ExpenseAgentSetup.Validate("Day of Week", ExpenseAgentSetup."Day of Week"::Monday);

        // [THEN] Verify that error is thrown requiring Weekly frequency.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("When to Create Expense Reports"), Format(ExpenseAgentSetup."When to Create Expense Reports"::Weekly));
    end;

    [Test]
    procedure DayOfWeekCanBeSetWhenFrequencyIsWeekly()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that Day of Week can be set when frequency is Weekly.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Set to Weekly frequency.
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Weekly;
        ExpenseAgentSetup.Modify();

        // [WHEN] Set Day of Week with Weekly frequency.
        ExpenseAgentSetup.Validate("Day of Week", ExpenseAgentSetup."Day of Week"::Friday);
        ExpenseAgentSetup.Modify();

        // [THEN] Verify that Day of Week is set correctly.
        Assert.AreEqual(
            ExpenseAgentSetup."Day of Week"::Friday,
            ExpenseAgentSetup."Day of Week",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day of Week"), Format(ExpenseAgentSetup."Day of Week"::Friday), ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure DayInMonthValidationRequiresMonthlyFrequency()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that Day In A Month can only be changed when frequency is Monthly.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Set frequency to Weekly.
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Weekly;
        ExpenseAgentSetup.Modify();

        // [WHEN] Try to change Day In A Month with non-Monthly frequency.
        asserterror ExpenseAgentSetup.Validate("Day In A Month", 15);

        // [THEN] Verify that error is thrown requiring Monthly frequency.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("When to Create Expense Reports"), Format(ExpenseAgentSetup."When to Create Expense Reports"::Monthly));
    end;

    [Test]
    procedure DayInMonthCanBeSetWhenFrequencyIsMonthly()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 613723] Verify that Day In A Month can be set when frequency is Monthly.
        Initialize();

        // [GIVEN] Get Expense Agent Setup.
        ExpenseAgentSetup.Get();

        // [GIVEN] Set to Monthly frequency.
        ExpenseAgentSetup."When to Create Expense Reports" := ExpenseAgentSetup."When to Create Expense Reports"::Monthly;
        ExpenseAgentSetup.Modify();

        // [WHEN] Set Day In A Month with Monthly frequency.
        ExpenseAgentSetup.Validate("Day In A Month", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [THEN] Verify that Day In A Month is set correctly.
        Assert.AreEqual(
            1,
            ExpenseAgentSetup."Day In A Month",
            StrSubstNo(ValueMustBeEqualErr, ExpenseAgentSetup.FieldCaption("Day In A Month"), Format(1), ExpenseAgentSetup.TableCaption()));
    end;

    [Test]
    procedure JobTaskNoMustBeRequiredWhenExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Job: Record Job;
        JobTask: Record "Job Task";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613723] Verify that Job Task No is required when Expense is released.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create a Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Get Job.
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify();

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update Mileage in Expense.
        Expense.Validate(Mileage, LibraryRandom.RandDec(100, 2));
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Modify();

        // [WHEN] Release Expense.
        asserterror ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that error is thrown requiring Job Task No.
        Assert.ExpectedTestFieldError(Expense.FieldCaption("Job Task No."), '');
    end;

    [Test]
    procedure ExpenseMustBeReleasedWithJobAndJobTask()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Job: Record Job;
        JobTask: Record "Job Task";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613723] Verify that Expense must be released with Job and Job Task.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create a Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Get Job.
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify();

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update Mileage in Expense.
        Expense.Validate(Mileage, LibraryRandom.RandDec(10, 2));
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        // [WHEN] Release Expense.
        ReleaseExpenseDocument.PerformManualRelease(Expense);

        // [THEN] Verify that Expense is released successfully.
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status), Expense.Status::Released, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ExpenseLocationMustBeUpdatedWhenExpenseCategoryIsChangedInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePerDiem: Record "Expense Per Diem";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616941] Verify that the Expense Location is updated when Expense Category is changed in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [THEN] Verify that Per Diem records exist for the Expense.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 1);

        // [WHEN] Update Expense Category in Expense .
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that "Expense Location" is updated in Expense.
        Assert.AreEqual(
            '',
            Expense."Expense Location",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Location"), '', Expense.TableCaption()));

        // [THEN] Verify that no Per Diem records exist for the Expense.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 0);
    end;

    [Test]
    procedure ExpensePerDiemIsDeletedWhenExpenseLocationIsChangedForPerDiem()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePerDiem: Record "Expense Per Diem";
        EmptyGuid: Guid;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616941] Verify that the Expense Per Diem is deleted when Expense Location is changed for Per Diem Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [THEN] Verify that Rule Id is cleared in Expense.
        Assert.AreEqual(
            ExpenseRuleHeader.SystemId,
            Expense."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Applied Rule Id"), ExpenseRuleHeader.SystemId, Expense.TableCaption()));

        // [THEN] Verify that Per Diem records exist for the Expense.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 1);

        // [WHEN] Update Expense Location in Expense.
        Expense.Validate("Expense Location", '');

        // [THEN] Verify that no Per Diem records exist for the Expense.
        ExpensePerDiem.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpensePerDiem, 0);

        // [THEN] Verify that Rule Id is cleared in Expense.
        Assert.AreEqual(
            EmptyGuid,
            Expense."Applied Rule Id",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Applied Rule Id"), EmptyGuid, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DescriptionMustBeBlankWhenExpenseCategoryIsRemoved()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616949] Verify that the Description is blank when Expense Category is removed.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [WHEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [THEN] Verify that Description is set from Expense Category in Expense.
        ExpenseCategory.Get(Expense."Expense Category");
        Assert.AreEqual(
            ExpenseCategory."Posting Description",
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Description), ExpenseCategory."Posting Description", Expense.TableCaption()));

        // [WHEN] Update Expense Category in Expense.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that Description is blank in Expense.
        Assert.AreEqual(
            '',
            Expense.Description,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Description), '', Expense.TableCaption()));
    end;

    [Test]
    procedure AmountReductionCannotBeNegativeInExpense()
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Expense: Record Expense;
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 616953] Verify that the Amount Reduction cannot be negative in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := -LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', Amount);
        Expense.Validate("Merchant Name", LibraryRandom.RandText(10));
        Expense.Modify();

        // [WHEN] Update Amount Reduction in Expense to negative value.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        asserterror ExpensePage."Non-Refundable Amount".SetValue(AmountReduction);

        // [THEN] Verify that the error is thrown for negative Amount Reduction.
        Assert.ExpectedError(StrSubstNo(NonRefundableAmountCannotBeNegativeErr, ExpensePage."Non-Refundable Amount".Caption, Expense."No."));
    end;

    [Test]
    procedure DefaultMileageUOMIsRequiredWhenExpenseIsCreatedForMileage()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Job: Record Job;
        JobTask: Record "Job Task";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify that Default Mileage UOM is required when Expense is created for Mileage.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Default Mileage UOM", '');
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create a Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Get Job.
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify();

        // [WHEN] Create Expense with Rule "Mileage".
        asserterror CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that Default Mileage UOM is required when Expense is created for Mileage.
        Assert.ExpectedTestFieldError(ExpenseAgentSetup.FieldCaption("Default Mileage UOM"), '');
    end;

    [Test]
    procedure UnitOfMeasureMustBeClearedWhenExpenseCategoryIsCleared()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Job: Record Job;
        JobTask: Record "Job Task";
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify that Unit of Measure must be cleared when Expense Category is cleared.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Default Mileage UOM", UnitOfMeasure.Code);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Enqueue false to create a New Expense Report.
        LibraryVariableStorage.Enqueue(false);

        // [GIVEN] Create a Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Get Job.
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", Currency.Code);
        Job.Modify();

        // [WHEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [THEN] Verify that Expense is created successfully with Default Mileage UOM.
        Assert.AreEqual(
            UnitOfMeasure.Code,
            Expense."Unit of Measure Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Unit of Measure Code"), UnitOfMeasure.Code, Expense.TableCaption()));

        // [WHEN] Clear Expense Category in Expense.
        Expense.Validate("Expense Category", '');

        // [THEN] Verify that Unit of Measure Code is cleared in Expense.
        Assert.AreEqual(
            '',
            Expense."Unit of Measure Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Unit of Measure Code"), '', Expense.TableCaption()));
    end;

    [Test]
    procedure ReceiptNoAndMerchantNameIsRequiredWhenEnableInExpenseAgentSetup()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpenseRuleViolation: Record "Expense Rule Violation";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify that Receipt No and Merchant Name is required when enabled in Expense Agent Setup.
        // [SCENARIO 641894] Verify Receipt No is not mandatory When Expense Category is Mileage and "Receipt No. Mandatory" is enabled in Expense Agent Setup.
        // [SCENARIO 641894] Verify Merchant Name is not mandatory When Expense Category is Mileage and "Merchant Name Mandatory" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Enable Receipt No and Merchant Name requirement in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", true);
        ExpenseAgentSetup.Validate("Receipt No. Mandatory", true);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Update Receipt No, Mileage and Merchant Name in Expense.
        Expense.Validate("Merchant Name", '');
        Expense.Validate("Expense Ext. Doc. No.", '');
        Expense.Validate("Mileage", LibraryRandom.RandDec(100, 2));
        Expense.Modify();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violation is not created in Expense for Merchant Name and Receipt No.
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        Assert.RecordCount(ExpenseRuleViolation, 0);

        // [WHEN] Update Receipt No and Merchant Name in Expense Page.
        ExpensePage."Expense Ext. Doc. No.".SetValue(LibraryRandom.RandText(20));
        ExpensePage."Merchant Name".SetValue(LibraryRandom.RandText(20));
        ExpensePage.Close();

        // [THEN] Verify that Merchant Name requirements are cleared in Expense Page.
        Expense.Get(Expense."No.");
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage."Rule Violations".AssertEquals(false);
    end;

    [Test]
    procedure RuleViolationExistWhenUnitOfMeasureIsDifferentFromDefaultInExpense()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616955] Verify that Rule Violation exists when Unit of Measure is different from Default in Expense.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Enable Receipt No and Merchant Name requirement in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Merchant Name Mandatory", false);
        ExpenseAgentSetup.Validate("Receipt No. Mandatory", false);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Find "Post Code".
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(400, 500);

        // [GIVEN] Create Expense with Rule "Mileage".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, CurrencyCode, Amount, WorkDate(),
            "Expense Detail Needed"::Mileage, ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Max Amount", true, Amount);

        // [GIVEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [WHEN] Update Mileage and Unit of Measure in Expense Page.
        ExpensePage.Mileage.SetValue(LibraryRandom.RandInt(10));
        ExpensePage."Unit of Measure Code".SetValue(UnitOfMeasure.Code);

        // [THEN] Verify that Rule Violation exists in Expense Page.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(UnitOfMeasureErr, ExpenseAgentSetup."Default Mileage UOM"));

        // [WHEN] Update Unit of Measure to Default Mileage UOM in Expense Page.
        ExpensePage."Unit of Measure Code".SetValue(ExpenseAgentSetup."Default Mileage UOM");

        // [THEN] Verify that Rule Violation is cleared in Expense Page.
        ExpensePage."Rule Violations".AssertEquals(false);
    end;

    [Test]
    procedure EmployeeMustBeLinkedToAnExpenseUserToCreateAnExpense()
    var
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Expense: Record Expense;
        Amount: Decimal;
    begin
        // [SCENARIO 617988] Verify that Employee must be linked to an Expense User to create an Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("Employee No.", '');
        ExpenseUser.Modify();

        // [WHEN] Create Expense with Expense Category.
        asserterror LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', Amount);

        // [THEN] Verify that the error is thrown for Expense User not linked to an Employee.
        Assert.ExpectedError(StrSubstNo(ExpenseUserMustBeLinkedToAnEmployeeErr, ExpenseUser."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DimensionMustBeCopyFromCustomerAndJobInExpense()
    var
        DefaultDimension: array[3] of Record "Default Dimension";
        DimensionValue: array[4] of Record "Dimension Value";
        Expense: Record Expense;
        Customer: Record Customer;
        PostCode: Record "Post Code";
        JobTask: Record "Job Task";
        ExpenseRuleHeader: Record "Expense Rule Header";
        ExpenseRuleCondition: Record "Expense Rule Condition";
        ExpectedDimSetID: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO 617034] Verify that the Dimension is copied from Customer and Job in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [GIVEN] Create Dimension Value 3 and 4.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Delete Default Dimension for Customer.
        DefaultDimension[3].SetRange("Table Id", Database::Customer);
        DefaultDimension[3].SetRange("No.", Customer."No.");
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 3 as Default Dimension for Customer.
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[1], Customer."No.", DimensionValue[3]."Dimension Code", DimensionValue[3].Code);

        // [GIVEN] Create Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Delete Default Dimension for Job.
        DefaultDimension[3].SetRange("Table Id", Database::Job);
        DefaultDimension[3].SetFilter("No.", '%1|%2', JobTask."Job No.", '');
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 4 as Default Dimension for Job.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[2], Database::Job, JobTask."Job No.", DimensionValue[4]."Dimension Code", DimensionValue[4].Code);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Rule "Per Diem".
        CreateExpenseWithRule(
            Expense, ExpenseRuleHeader, ExpenseRuleCondition, PostCode."Country/Region Code", PostCode.City, '', Amount, WorkDate(),
            "Expense Detail Needed"::"Per Diem", ExpenseRuleHeader."Justification Required"::" ", '', ExpenseRuleCondition."Condition Type"::"Daily Rate", true, Amount);

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimensionValue[1]);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimensionValue[2]);

        // [WHEN] Update Shortcut Dimension 1 and 2 in Expense.
        Expense.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        Expense.Validate("Shortcut Dimension 2 Code", DimensionValue[2].Code);

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        Assert.AreEqual(
            ExpectedDimSetID,
            Expense."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Dimension Set ID"), ExpectedDimSetID, Expense.TableCaption()));
        Assert.AreEqual(
            DimensionValue[1].Code,
            Expense."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 1 Code"), DimensionValue[1].Code, Expense.TableCaption()));
        Assert.AreEqual(
            DimensionValue[2].Code,
            Expense."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 2 Code"), DimensionValue[2].Code, Expense.TableCaption()));
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 2, DimensionValue[2]);

        // [WHEN] Update Job No. in Expense.
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 1, DimensionValue[4]);

        // [WHEN] Update Customer No. in Expense.
        Expense.Validate("Job No.", '');
        Expense.Validate(Billable, true);
        Expense.Validate("Billable to Customer", Customer."No.");

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 1, DimensionValue[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DimensionMustBeCopyFromEmployeeCustomerAndJobInExpense()
    var
        DefaultDimension: array[5] of Record "Default Dimension";
        DimensionValue: array[4] of Record "Dimension Value";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense SubCategory";
        Expense: Record Expense;
        Customer: Record Customer;
        PostCode: Record "Post Code";
        JobTask: Record "Job Task";
        ExpectedDimSetID: Integer;
    begin
        // [SCENARIO 617034] Verify that the Dimension is copied from Employee, Customer and Job in Expense.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Global Dimension Value 1 and 2.
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);

        // [GIVEN] Create Dimension Value 3 and 4.
        LibraryDimension.CreateDimWithDimValue(DimensionValue[3]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Delete Default Dimension for Customer.
        DefaultDimension[3].SetRange("Table Id", Database::Customer);
        DefaultDimension[3].SetRange("No.", Customer."No.");
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 3 as Default Dimension for Customer.
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension[1], Customer."No.", DimensionValue[3]."Dimension Code", DimensionValue[3].Code);

        // [GIVEN] Create Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Delete Default Dimension for Job.
        DefaultDimension[3].SetRange("Table Id", Database::Job);
        DefaultDimension[3].SetFilter("No.", '%1|%2', JobTask."Job No.", '');
        DefaultDimension[3].DeleteAll();

        // [GIVEN] Set Dimension Value 4 as Default Dimension for Job.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[2], Database::Job, JobTask."Job No.", DimensionValue[4]."Dimension Code", DimensionValue[4].Code);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Set Dimension Value 1 and 2 as Default Dimension for Expense User.
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension[4], Database::Employee, ExpenseUser."Employee No.", DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Create Expense Category with Itemize requirement.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::Itemize);

        // [GIVEN] Create Expense SubCategory.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);

        // [GIVEN] Get Expected Dimension Set ID after adding Dimension Value 1 and 2.
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimensionValue[1]);
        CreateDimSetIDFromDimValue(ExpectedDimSetID, DimensionValue[2]);

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        Assert.AreEqual(
            ExpectedDimSetID,
            Expense."Dimension Set ID",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Dimension Set ID"), ExpectedDimSetID, Expense.TableCaption()));
        Assert.AreEqual(
            DimensionValue[1].Code,
            Expense."Shortcut Dimension 1 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 1 Code"), DimensionValue[1].Code, Expense.TableCaption()));
        Assert.AreEqual(
            DimensionValue[2].Code,
            Expense."Shortcut Dimension 2 Code",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Shortcut Dimension 2 Code"), DimensionValue[2].Code, Expense.TableCaption()));
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 2, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 2, DimensionValue[2]);

        // [WHEN] Update Job No. in Expense.
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[4]);

        // [WHEN] Update Customer No. in Expense.
        // A billable customer and a project are mutually exclusive, so the project is cleared first.
        Expense.Validate("Job No.", '');
        Expense.Validate(Billable, true);
        Expense.Validate("Billable to Customer", Customer."No.");

        // [THEN] Verify that the "Dimension Set ID" is updated in Expense.
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[1]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[2]);
        VerifyDimensionFromDimensionSetID(Expense."Dimension Set ID", 3, DimensionValue[3]);
    end;

    [Test]
    procedure ShowErrorWhenDuplicateExpenseExistWithSameExpenseDateReceiptNoMerchantNameAndAmount()
    var
        ExpenseUser: Record "Expense User";
        Expense: array[2] of Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpensePage: TestPage Expense;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621787] Verify that the duplicate Expense cannot be released with the same Expense Date, Receipt No., Merchant Name and Amount.
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense with same Expense Date, Receipt No., Merchant Name and Amount.
        Initialize();

        // [GIVEN] Create Expense Category with Refundable set to true.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense[1], ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Perform Manual Release on Expense.
        Expense[1].PerformManualRelease();

        // [GIVEN] Create another Expense with Expense Category.
        LibraryExpense.CreateExpense(Expense[2], ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', Expense[1].Amount);
        Expense[2].Validate("Merchant Name", Expense[1]."Merchant Name");
        Expense[2].Validate("Expense Ext. Doc. No.", Expense[1]."Expense Ext. Doc. No.");
        Expense[2].Modify();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense[2]);

        // [THEN] Verify that the error is shown for duplicate Expense with same Expense Date, Receipt No., Merchant Name and Amount.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseAlreadyExistErr, Expense[2]."Expense Ext. Doc. No.", Expense[2]."Expense Date", Expense[2]."Merchant Name", Expense[2].Amount));
    end;

    [Test]
    procedure CannotCreateExpensePaymentMethodWithSameReimbursementType()
    var
        ExpensePaymentMethod: array[2] of Record "Expense Payment Method";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616998] Verify that the Expense Payment Method cannot be created with the same Reimbursement Type.
        Initialize();

        // [GIVEN] Delete all Expense Payment Method.
        ExpensePaymentMethod[1].DeleteAll();

        // [GIVEN] Create Expense Payment Method.
        LibraryExpense.CreateExpensePaymentMethod(ExpensePaymentMethod[1], ExpensePaymentMethod[1]."Reimbursement Type"::"Employee Paid");

        // [WHEN] Create another Expense Payment Method.
        asserterror LibraryExpense.CreateExpensePaymentMethod(ExpensePaymentMethod[2], ExpensePaymentMethod[2]."Reimbursement Type"::"Employee Paid");

        // [THEN] Verify that the error is thrown for Expense Payment Method with same Reimbursement Type.
        Assert.ExpectedError(
            StrSubstNo(SameExpensePaymentMethodForReimbursementExistErr,
                ExpensePaymentMethod[1].TableCaption(),
                ExpensePaymentMethod[1].Code,
                ExpensePaymentMethod[1].FieldCaption("Reimbursement Type"),
                ExpensePaymentMethod[1]."Reimbursement Type"));
    end;

    [Test]
    procedure EmployeeFieldsMustNotBeEditableInExpenseUserWhenEmployeeNoExists()
    var
        ExpenseUser: Record "Expense User";
        ExpenseUserPage: TestPage "Expense User";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620924] Verify that the Employee fields are not editable in Expense User page When "Employee No." is exist in Expense User.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [WHEN] Open Expense User Page.
        ExpenseUserPage.OpenEdit();
        ExpenseUserPage.GoToRecord(ExpenseUser);

        // [THEN] Verify that the Employee fields are not editable in Expense User page.
        Assert.AreEqual(
            false,
            ExpenseUserPage.Name.Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseUserPage.Name.Caption(), ExpenseUserPage.Caption()));
        Assert.AreEqual(
            false,
            ExpenseUserPage."Job Title".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseUserPage."Job Title".Caption(), ExpenseUserPage.Caption()));
        Assert.AreEqual(
            false,
            ExpenseUserPage."E-mail".Editable(),
            StrSubstNo(FieldShouldNotBeEditableErr, ExpenseUserPage."E-mail".Caption(), ExpenseUserPage.Caption()));
    end;

    [Test]
    procedure EmployeeFieldsMustBeEditableInExpenseUserWhenEmployeeNoDoesNotExist()
    var
        ExpenseUser: Record "Expense User";
        ExpenseUserPage: TestPage "Expense User";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620924] Verify that the Employee fields are editable in Expense User page When "Employee No." does not exist in Expense User.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseUser.Validate("Employee No.", '');
        ExpenseUser.Modify();

        // [WHEN] Open Expense User Page.
        ExpenseUserPage.OpenEdit();
        ExpenseUserPage.GoToRecord(ExpenseUser);

        // [THEN] Verify that the Employee fields are editable in Expense User page.
        Assert.AreEqual(
            true,
            ExpenseUserPage.Name.Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseUserPage.Name.Caption(), ExpenseUserPage.Caption()));
        Assert.AreEqual(
            true,
            ExpenseUserPage."Job Title".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseUserPage."Job Title".Caption(), ExpenseUserPage.Caption()));
        Assert.AreEqual(
            true,
            ExpenseUserPage."E-mail".Editable(),
            StrSubstNo(FieldShouldBeEditableErr, ExpenseUserPage."E-mail".Caption(), ExpenseUserPage.Caption()));
    end;

    [Test]
    procedure EmailIdMustBeUniqueInExpenseUser()
    var
        ExpenseUser: array[2] of Record "Expense User";
        EmailId: Text;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 619587] Verify that the Expense User must have unique Email ID.
        Initialize();

        // [GIVEN] Generate Random Email ID.
        EmailId := '1@1.com';

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);
        ExpenseUser[1].Validate("E-mail", EmailId);
        ExpenseUser[1].Modify();

        // [GIVEN] Create another Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);

        // [WHEN] Update the same Email ID in another Expense User.
        asserterror ExpenseUser[2].Validate("E-mail", EmailId);

        // [THEN] Verify that the error is thrown for duplicate Email ID in Expense User.
        Assert.ExpectedError(StrSubstNo(DuplicateEmailErr, ExpenseUser[2].FieldCaption("E-mail"), EmailId, ExpenseUser[2].TableCaption()));
    end;

    [Test]
    procedure EmployeeMustBeUniqueInExpenseUser()
    var
        ExpenseUser: array[2] of Record "Expense User";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620920] Verify that the Expense User must have unique Employee No.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser[1]);

        // [GIVEN] Create another Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser[2]);

        // [WHEN] Update the same Employee No. in another Expense User.
        asserterror ExpenseUser[2].Validate("Employee No.", ExpenseUser[1]."Employee No.");

        // [THEN] Verify that the error is thrown for duplicate Employee No. in Expense User.
        Assert.ExpectedError(StrSubstNo(DuplicateEmployeeNoErr, ExpenseUser[2].FieldCaption("Employee No."), ExpenseUser[1]."Employee No.", ExpenseUser[2].TableCaption()));
    end;

    [Test]
    procedure ExpenseUserMustBeUpdatedWhenEmployeeIsUpdated()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 620922] Verify that the Expense User is updated when Employee is updated.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Get Employee.
        Employee.Get(ExpenseUser."Employee No.");

        // [WHEN] Update E-Mail in Employee.
        Employee.Validate("Company E-Mail", '1@1.com');

        // [THEN] Verify that the E-Mail is updated in Expense User.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(
            Employee."Company E-Mail",
            ExpenseUser."E-mail",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("E-mail"), Employee."Company E-Mail", ExpenseUser.TableCaption()));

        // [WHEN] Update Job Title in Employee.
        Employee.Validate("Job Title", LibraryRandom.RandText(20));

        // [THEN] Verify that the Job Title is updated in Expense User.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(
            Employee."Job Title",
            ExpenseUser."Job Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("Job Title"), Employee."Job Title", ExpenseUser.TableCaption()));

        // [WHEN] Update First Name in Employee.
        Employee.Validate("First Name", LibraryRandom.RandText(20));

        // [THEN] Verify that the Name is updated in Expense User.
        ExpenseUser.Get(ExpenseUser."No.");
        Assert.AreEqual(
            Employee.FullName(),
            ExpenseUser.Name,
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("Name"), Employee.FullName(), ExpenseUser.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('PerDiemExpensesWithRuleModalPageErrorHandler,SentNotificationHandler')]
    procedure MissingExpenseLocationNotificationOnExpensePerDiem()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePage: TestPage Expense;
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 621716] Verify that Missing Expense Location Notification is triggered on Expense Per Diem.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::"Per Diem");

        // [GIVEN] Create Expense.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', '', true, '', 0);

        // [WHEN] Open Expense Page and invoke Per Diem action.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);
        ExpensePage.PerDiem.Invoke();

        // [THEN] Verify that Missing Expense Location Notification is triggered.
        VerifyMissingExpenseLocationNotification(Expense."No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure ShowErrorWhenDuplicateExpenseReportLineExistsInAnotherOpenReport()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Notification is shown when expense report line "L1" in "ER1" matches Receipt No., Date, Merchant Name, and Amount of line "L2" in "ER2".
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        Initialize();

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with line carrying the matching fields.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[1], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader[1], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[1].Modify();

        // [WHEN] Create another Expense Report line carrying the same Receipt No., Date, Merchant Name, and Amount.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[2], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader[2], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader[2]);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine[2]."Expense Ext. Doc. No.", ExpenseReportLine[2]."Expense Date", ExpenseReportLine[2]."Merchant Name", ExpenseReportLine[2].Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure NoNotificationWhenExpenseReportLineHasNoDuplicateInAnyReport()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] No notification is shown when an expense report line has unique Receipt No., Date, Merchant Name, and Amount.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [WHEN] Create an Expense Report line with unique fields.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', LibraryRandom.RandIntInRange(100, 200));

        // [THEN] No notification is shown; LibraryVariableStorage is empty.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SameLineIsNotConsideredDuplicateForExpenseReportLine()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        OriginalReceiptNo: Code[30];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] A line is not treated as a duplicate of itself; no notification is shown when it is the only matching line.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with exactly one line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', LibraryRandom.RandIntInRange(100, 200));
        OriginalReceiptNo := ExpenseReportLine."Expense Ext. Doc. No.";

        // [WHEN] Validate duplicate-checking field.
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", OriginalReceiptNo);
        ExpenseReportLine.Modify();

        // [THEN] No notification is shown; the line is not treated as its own duplicate.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ShowErrorWhenDuplicateExpenseReportLineExistsInPostedExpenseReport()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Notification is shown when an open expense report line matches a posted expense report line.
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        Initialize();

        // [GIVEN] "Do Not Allow Exp. Older Than" is blank in setup (exact date match).
        LibraryExpense.UpdateDoNotAllowExpenseOlderThanInAgentSetup('');

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Posted expense report line with matching fields.
        CreateAndPostExpenseReport(ReceiptNo, WorkDate(), MerchantName, Amount);

        // [WHEN] Create an open Expense Report line carrying the same fields as the posted line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine.Validate("Merchant Name", MerchantName);
        ExpenseReportLine.Validate("Expense Date", WorkDate());
        ExpenseReportLine.Modify();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine."Expense Ext. Doc. No.", ExpenseReportLine."Expense Date", ExpenseReportLine."Merchant Name", ExpenseReportLine.Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ShowErrorWhenDuplicatePostedLineWithinDoNotAllowExpOlderThanRange()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DoNotAllowExpOlderThan: DateFormula;
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Notification is shown when a posted line date falls within the "Do Not Allow Exp. Older Than" date range.
        Initialize();

        // [GIVEN] "Do Not Allow Exp. Older Than" is set to 1 month in setup.
        Evaluate(DoNotAllowExpOlderThan, '1M');
        LibraryExpense.UpdateDoNotAllowExpenseOlderThanInAgentSetup(DoNotAllowExpOlderThan);

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Posted expense report line with Expense Date = today (within the 1-month range).
        CreateAndPostExpenseReport(ReceiptNo, Today(), MerchantName, Amount);

        // [WHEN] Create an open Expense Report line carrying the same fields as the posted line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine.Validate("Merchant Name", MerchantName);
        ExpenseReportLine.Validate("Expense Date", Today());
        ExpenseReportLine.Modify();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine."Expense Ext. Doc. No.", ExpenseReportLine."Expense Date", ExpenseReportLine."Merchant Name", ExpenseReportLine.Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure NoNotificationWhenDuplicatePostedLineIsOutsideDoNotAllowExpOlderThanRange()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        DoNotAllowExpOlderThan: DateFormula;
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] No notification is shown when the matching posted line date is outside the "Do Not Allow Exp. Older Than" range.
        Initialize();

        // [GIVEN] "Do Not Allow Exp. Older Than" is set to 1 month in setup.
        Evaluate(DoNotAllowExpOlderThan, '1M');
        LibraryExpense.UpdateDoNotAllowExpenseOlderThanInAgentSetup(DoNotAllowExpOlderThan);

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Posted expense report line with Expense Date = 2 months ago (outside the 1-month range).
        CreateAndPostExpenseReport(ReceiptNo, CalcDate('<-2M>', Today()), MerchantName, Amount);

        // [WHEN] Create an open Expense Report line carrying the same fields as the posted line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine.Validate("Merchant Name", MerchantName);
        ExpenseReportLine.Validate("Expense Date", Today());
        ExpenseReportLine.Modify();

        // [THEN] No notification is shown because the posted line is older than the allowed range.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ShowErrorWhenDuplicateLineExistsInSameExpenseReport()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Notification is shown when two lines in the same report share Receipt No., Date, Merchant Name, and Amount.
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        Initialize();

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[1].Modify();

        // [WHEN] Create a second line in the same report with same Receipt No., Date, Merchant Name, and Amount.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".Next();
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine[2]."Expense Ext. Doc. No.", ExpenseReportLine[2]."Expense Date", ExpenseReportLine[2]."Merchant Name", ExpenseReportLine[2].Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure NoNotificationWhenPostedLineDateDiffersAndDoNotAllowExpOlderThanIsBlank()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] No notification when posted line has different Expense Date and "Do Not Allow Exp. Older Than" is blank exact date match required.
        Initialize();

        // [GIVEN] "Do Not Allow Exp. Older Than" is blank in setup.
        LibraryExpense.UpdateDoNotAllowExpenseOlderThanInAgentSetup('');

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create posted expense report line with Expense Date = 1 month ago.
        CreateAndPostExpenseReport(ReceiptNo, CalcDate('<-1M>', Today()), MerchantName, Amount);

        // [WHEN] Create an open expense report line with Expense Date = today (different from posted line).
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine.Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine.Validate("Merchant Name", MerchantName);
        ExpenseReportLine.Validate("Expense Date", Today());
        ExpenseReportLine.Modify();

        // [THEN] No notification is shown because exact date match is required and dates differ.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ExpenseBillingInformationModalPageHandler')]
    procedure ShowErrorWhenShowBillableInformationActionInvokedOnDuplicateExpenseReportLine()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Duplicate notification is shown via the "Show Billable Information" page action when the line duplicates another open report line.
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        Initialize();

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Expense Report with line carrying the matching fields.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[1], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader[1], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[1].Modify();

        // [GIVEN] Expense Report with line carrying the same Receipt No., Date, Merchant Name, and Amount.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[2], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader[2], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [WHEN] Open the Expense Report page and invoke "Show Billable Information" action on line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader[2]);
        ExpenseReportPage."Expense Report Subform"."Show Billable Information".Invoke();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine[2]."Expense Ext. Doc. No.", ExpenseReportLine[2]."Expense Date", ExpenseReportLine[2]."Merchant Name", ExpenseReportLine[2].Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('ExpenseBillingInfoUpdateMerchantModalPageHandler')]
    procedure ShowErrorWhenMerchantNameUpdatedViaBillingInfoPage()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] Duplicate notification is shown when Merchant Name is updated via "Expense Billing Information" page to match another open report line.
        // [SCENARIO 634618] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        Initialize();

        // [GIVEN] Generate matching Receipt No., Merchant Name, and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with line carrying Receipt No., Merchant Name, and Amount.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[1], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader[1], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[1].Modify();

        // [GIVEN] Create another Expense Report with line carrying the same Receipt No., Date, and Amount but different Merchant Name.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader[2], ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader[2], ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", LibraryUtility.GenerateGUID());
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [GIVEN] Enqueue the matching Merchant Name for the modal page handler to update.
        LibraryVariableStorage.Enqueue(MerchantName);

        // [WHEN] Open Expense Report page and invoke "Show Billable Information" on line "ER2".
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader[2]);
        ExpenseReportPage."Expense Report Subform"."Show Billable Information".Invoke();

        // [THEN] Verify that the error is shown for duplicate Expense Report Line with same Receipt No., Date, Merchant Name and Amount.
        ExpenseReportLine[2].Find();
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ExpenseReportAlreadyExistErr, ExpenseReportLine[2]."Expense Ext. Doc. No.", ExpenseReportLine[2]."Expense Date", ExpenseReportLine[2]."Merchant Name", ExpenseReportLine[2].Amount));
        ExpenseReportPage.Close();
    end;

    [Test]
    procedure NoNotificationWhenUserEntersDifferentAmountOnExpenseReportPage()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        MerchantName: Text[100];
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] No notification is shown when user creates two lines with same Receipt No., Date, Merchant Name but different Amounts on Expense Report page.
        Initialize();

        // [GIVEN] Generate matching Receipt No. and Merchant Name.
        ReceiptNo := LibraryUtility.GenerateGUID();
        MerchantName := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with first line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[1].Modify();

        // [GIVEN] Create second line with same Receipt No. and Merchant Name but different Amount.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount + LibraryRandom.RandIntInRange(50, 100));
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", MerchantName);
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [WHEN] User opens Expense Report page and navigates to the second line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".Last();
        ExpenseReportPage.Close();

        // [THEN] No notification is shown because amounts differ.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure NoNotificationWhenUserEntersDifferentMerchantNameOnExpenseReportPage()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportPage: TestPage "Expense Report";
        ReceiptNo: Code[30];
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 621787] No notification is shown when user creates two lines with same Receipt No., Date, Amount but different Merchant Names on Expense Report page.
        Initialize();

        // [GIVEN] Generate matching Receipt No. and Amount.
        ReceiptNo := LibraryUtility.GenerateGUID();
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense Report with first line.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[1], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[1].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[1].Validate("Merchant Name", LibraryUtility.GenerateGUID());
        ExpenseReportLine[1].Modify();

        // [GIVEN] Create second line with same Receipt No. and Amount but different Merchant Name.
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine[2], ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory.Code, '', true, '', Amount);
        ExpenseReportLine[2].Validate("Expense Ext. Doc. No.", ReceiptNo);
        ExpenseReportLine[2].Validate("Merchant Name", LibraryUtility.GenerateGUID());
        ExpenseReportLine[2].Validate("Expense Date", ExpenseReportLine[1]."Expense Date");
        ExpenseReportLine[2].Modify();

        // [WHEN] User opens Expense Report page and navigates to the second line.
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Expense Report Subform".Last();
        ExpenseReportPage.Close();

        // [THEN] No notification is shown because Merchant Names differ.
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('EmployeeTemplateHandler')]
    procedure EmployeeIsCreatedFromExpenseUserWhenCreateEmpForExpenseUsersIsEnabled()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        EmployeeTempl: array[2] of Record "Employee Templ.";
        FirstName: Text[30];
        MiddleName: Text[30];
        LastName: Text[30];
        Email: Text[80];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify Employee is created when "Create Emp. for Expense Users" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Enable templates feature.
        LibraryTemplates.EnableTemplatesFeature();

        // [GIVEN] Create Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[1]);

        // [GIVEN] Create another Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[2]);

        // [GIVEN] Enqueue Employee Template.
        LibraryVariableStorage.Enqueue(EmployeeTempl[2].Code);

        // [GIVEN] Generate random First Name, Middle Name and Last Name.
        FirstName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        MiddleName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        LastName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        Email := LibraryUtility.GenerateRandomEmail();

        // [GIVEN] Create Expense User with Name and E-mail.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Insert();
        ExpenseUser.Validate("Name", FirstName + ' ' + MiddleName + ' ' + LastName);
        ExpenseUser.Validate("E-mail", Email);
        ExpenseUser.Modify();

        // [WHEN] Invoke Create Employee action on Expense User.
        CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that Employee is created and linked to Expense User.
        ExpenseUser.TestField("Employee No.");
        Employee.Get(ExpenseUser."Employee No.");
        Assert.AreEqual(
            FirstName,
            Employee."First Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("First Name"), FirstName, Employee.TableCaption()));
        Assert.AreEqual(
            MiddleName,
            Employee."Middle Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Middle Name"), MiddleName, Employee.TableCaption()));
        Assert.AreEqual(
            LastName,
            Employee."Last Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Last Name"), LastName, Employee.TableCaption()));
        Assert.AreEqual(
            Email,
            Employee."Company E-Mail",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Company E-Mail"), Email, Employee.TableCaption()));
        Assert.AreEqual(
            EmployeeTempl[2]."Employee Posting Group",
            Employee."Employee Posting Group",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Employee Posting Group"), EmployeeTempl[2]."Employee Posting Group", Employee.TableCaption()));
    end;

    [Test]
    procedure CheckAndCreateEmployeeFromExpenseUserWhenEmployeeAlreadyExists()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        EmailAddress: Text[80];
        EmployeeNo: Code[20];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify existing Employee is linked to Expense User when "Create Emp. for Expense Users" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Generate random Email Address and Employee No.
        EmailAddress := LibraryUtility.GenerateRandomEmail();
        EmployeeNo := LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), Database::Employee);

        // [GIVEN] Create Employee with E-mail.
        Employee.Get(LibraryExpense.CreateEmployee(EmployeeNo));
        Employee.Validate("Company E-Mail", EmailAddress);
        Employee.Modify();

        // [GIVEN] Create Expense User with same Name and E-mail.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate(Name, Employee.FullName());
        ExpenseUser.Validate("E-mail", EmailAddress);
        ExpenseUser.Insert();

        // [WHEN] Invoke Create Employee action on Expense User.
        CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that existing Employee is linked to Expense User.
        Assert.AreEqual(
            Employee."No.",
            ExpenseUser."Employee No.",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("Employee No."), Employee."No.", ExpenseUser.TableCaption()));
        Assert.AreEqual(
            Employee.FullName(),
            ExpenseUser.Name,
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("Name"), Employee.FullName(), ExpenseUser.TableCaption()));
        Assert.AreEqual(
            Employee."Company E-Mail",
            ExpenseUser."E-mail",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("E-mail"), Employee."Company E-Mail", ExpenseUser.TableCaption()));
        Assert.AreEqual(
            Employee."Job Title",
            ExpenseUser."Job Title",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("Job Title"), Employee."Job Title", ExpenseUser.TableCaption()));
    end;

    [Test]
    procedure EmployeeIsNotCreatedFromExpenseUserWhenNameIsEmpty()
    var
        ExpenseUser: Record "Expense User";
        EmailAddress: Text[80];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify Employee is not created when Name is empty in Expense User and "Create Emp. for Expense Users" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Generate random Email Address.
        EmailAddress := LibraryUtility.GenerateRandomEmail();

        // [GIVEN] Create Expense User with E-mail.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("E-mail", EmailAddress);
        ExpenseUser.Insert();

        // [WHEN] Invoke Check and Create Employee action on Expense User when Name is empty.
        asserterror CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that error is thrown because Name is mandatory.
        Assert.ExpectedTestFieldError(ExpenseUser.FieldCaption("Name"), '');
    end;

    [Test]
    procedure EmployeeIsNotCreatedFromExpenseUserWhenEmailIsEmpty()
    var
        ExpenseUser: Record "Expense User";
        Name: Text[100];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify Employee is not created when E-mail is empty in Expense User and "Create Emp. for Expense Users" is enabled in Expense Agent Setup.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Generate random Name.
        Name := CopyStr(LibraryUtility.GenerateRandomText(100), 1, 100);

        // [GIVEN] Create Expense User with Name.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Name", Name);
        ExpenseUser.Insert();

        // [WHEN] Invoke Create Employee action on Expense User when E-mail is empty.
        asserterror CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that error is thrown because E-mail is mandatory.
        Assert.ExpectedTestFieldError(ExpenseUser.FieldCaption("E-mail"), '');
    end;

    [Test]
    [HandlerFunctions('EmployeeTemplateHandler')]
    procedure EmployeeIsCreatedFromExpenseUserWithFirstName()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        EmployeeTempl: array[2] of Record "Employee Templ.";
        FirstName: Text[30];
        Email: Text[80];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify Employee is created with First Name.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Enable templates feature.
        LibraryTemplates.EnableTemplatesFeature();

        // [GIVEN] Create Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[1]);

        // [GIVEN] Create another Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[2]);

        // [GIVEN] Enqueue Employee Template.
        LibraryVariableStorage.Enqueue(EmployeeTempl[2].Code);

        // [GIVEN] Generate random First Name.
        FirstName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        Email := LibraryUtility.GenerateRandomEmail();

        // [GIVEN] Create Expense User with Name and E-mail.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Insert();
        ExpenseUser.Validate("Name", FirstName);
        ExpenseUser.Validate("E-mail", Email);
        ExpenseUser.Modify();

        // [WHEN] Invoke Create Employee action on Expense User.
        CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that Employee is created and linked to Expense User.
        ExpenseUser.TestField("Employee No.");
        Employee.Get(ExpenseUser."Employee No.");
        Assert.AreEqual(
            FirstName,
            Employee."First Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("First Name"), FirstName, Employee.TableCaption()));
        Assert.AreEqual(
            '',
            Employee."Middle Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Middle Name"), '', Employee.TableCaption()));
        Assert.AreEqual(
            '',
            Employee."Last Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Last Name"), '', Employee.TableCaption()));
        Assert.AreEqual(
            Email,
            Employee."Company E-Mail",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Company E-Mail"), Email, Employee.TableCaption()));
        Assert.AreEqual(
            EmployeeTempl[2]."Employee Posting Group",
            Employee."Employee Posting Group",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Employee Posting Group"), EmployeeTempl[2]."Employee Posting Group", Employee.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('EmployeeTemplateHandler')]
    procedure EmployeeIsCreatedFromExpenseUserWithFirstAndLastName()
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        EmployeeTempl: array[2] of Record "Employee Templ.";
        FirstName: Text[30];
        LastName: Text[30];
        Email: Text[80];
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 624708] Verify Employee is created with First Name and Last Name.
        Initialize();

        // [GIVEN] Enable "Create Emp. for Expense Users" in Expense Agent Setup.
        LibraryExpense.UpdateCreateEmpForExpenseUsersInAgentSetup(true);

        // [GIVEN] Enable templates feature.
        LibraryTemplates.EnableTemplatesFeature();

        // [GIVEN] Create Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[1]);

        // [GIVEN] Create another Employee Template.
        LibraryTemplates.CreateEmployeeTemplateWithData(EmployeeTempl[2]);

        // [GIVEN] Enqueue Employee Template.
        LibraryVariableStorage.Enqueue(EmployeeTempl[2].Code);

        // [GIVEN] Generate random First Name and Last Name.
        FirstName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        LastName := CopyStr(LibraryUtility.GenerateRandomText(30), 1, 30);
        Email := LibraryUtility.GenerateRandomEmail();

        // [GIVEN] Create Expense User with Name and E-mail.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Insert();
        ExpenseUser.Validate("Name", FirstName + ' ' + LastName);
        ExpenseUser.Validate("E-mail", Email);
        ExpenseUser.Modify();

        // [WHEN] Invoke Create Employee action on Expense User.
        CheckAndCreateExpenseUser(ExpenseUser);

        // [THEN] Verify that Employee is created and linked to Expense User.
        ExpenseUser.TestField("Employee No.");
        Employee.Get(ExpenseUser."Employee No.");
        Assert.AreEqual(
            FirstName,
            Employee."First Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("First Name"), FirstName, Employee.TableCaption()));
        Assert.AreEqual(
            '',
            Employee."Middle Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Middle Name"), '', Employee.TableCaption()));
        Assert.AreEqual(
            LastName,
            Employee."Last Name",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Last Name"), LastName, Employee.TableCaption()));
        Assert.AreEqual(
            Email,
            Employee."Company E-Mail",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Company E-Mail"), Email, Employee.TableCaption()));
        Assert.AreEqual(
            EmployeeTempl[2]."Employee Posting Group",
            Employee."Employee Posting Group",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Employee Posting Group"), EmployeeTempl[2]."Employee Posting Group", Employee.TableCaption()));
    end;

    [Test]
    procedure PersonalEmailFlowsInExpenseUserWhenCompanyEmailIsEmpty()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        PersonalEmail: Text[80];
    begin
        // [SCENARIO 605142] When the Employee has no "Company E-Mail" the personal "E-Mail" flows in to the Expense User.
        Initialize();

        // [GIVEN] An Employee with personal E-Mail and no Company E-Mail.
        LibraryExpense.CreateEmployee(LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), Database::Employee));
        Employee.FindLast();
        PersonalEmail := CopyStr(LibraryUtility.GenerateRandomEmail(), 1, MaxStrLen(Employee."E-Mail"));
        Employee.Validate("E-Mail", PersonalEmail);
        Employee."Company E-Mail" := '';
        Employee.Modify();

        // [WHEN] Creating an Expense User linked to that Employee.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Insert(true);

        // [THEN] The Expense User "E-mail" is the personal E-Mail.
        Assert.AreEqual(
            PersonalEmail,
            ExpenseUser."E-mail",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("E-mail"), PersonalEmail, ExpenseUser.TableCaption()));
    end;

    [Test]
    procedure CompanyEmailIsPreferredOverPersonalEmailInExpenseUser()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        CompanyEmail: Text[80];
    begin
        // [SCENARIO 605142] When the Employee has a "Company E-Mail" it is preferred over the personal "E-Mail".
        Initialize();

        // [GIVEN] An Employee with both personal and company E-Mail.
        LibraryExpense.CreateEmployee(LibraryUtility.GenerateRandomCode(Employee.FieldNo("No."), Database::Employee));
        Employee.FindLast();
        Employee."E-Mail" := CopyStr(LibraryUtility.GenerateRandomEmail(), 1, MaxStrLen(Employee."E-Mail"));
        CompanyEmail := CopyStr(LibraryUtility.GenerateRandomEmail(), 1, MaxStrLen(Employee."Company E-Mail"));
        Employee."Company E-Mail" := CompanyEmail;
        Employee.Modify();

        // [WHEN] Creating an Expense User linked to that Employee.
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", LibraryUtility.GenerateRandomCode(ExpenseUser.FieldNo("No."), Database::"Expense User"));
        ExpenseUser.Validate("Employee No.", Employee."No.");
        ExpenseUser.Insert(true);

        // [THEN] The Expense User "E-mail" is the Company E-Mail.
        Assert.AreEqual(
            CompanyEmail,
            ExpenseUser."E-mail",
            StrSubstNo(ValueMustBeEqualErr, ExpenseUser.FieldCaption("E-mail"), CompanyEmail, ExpenseUser.TableCaption()));
    end;

    [Test]
    procedure CannotDeleteExpenseUserSetAsDefaultApprover()
    var
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 605142] Deleting an Expense User that is set as Default Approver in Expense Agent Setup is blocked.
        Initialize();

        // [GIVEN] An Expense User configured as Default Approver in Expense Agent Setup.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Default Approver No." := ExpenseUser."No.";
        ExpenseAgentSetup.Modify();

        // [WHEN] Deleting the Expense User.
        asserterror ExpenseUser.Delete(true);

        // [THEN] An error is raised referencing the Expense Agent Setup.
        Assert.ExpectedError(ExpenseAgentSetup.TableCaption());
    end;

    [Test]
    procedure DeleteExpenseUserSucceedsWhenNotDefaultApprover()
    var
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 605142] An Expense User can be deleted when it is not set as Default Approver and has no approval setup rows.
        Initialize();

        // [GIVEN] An Expense User and Expense Agent Setup with a different (empty) Default Approver.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        ExpenseAgentSetup.GetRecordOnce();
        ExpenseAgentSetup."Default Approver No." := '';
        ExpenseAgentSetup.Modify();

        // [WHEN] Deleting the Expense User.
        // [THEN] The delete succeeds.
        ExpenseUser.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DeleteEmployeeWithPostedExpenseReportMustFail()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 633232] Verify that an Employee with posted expense reports cannot be deleted.
        Initialize();

        // [GIVEN] Create and post an expense report for an Expense User.
        CreateAndReleaseExpenseForPosting(Expense, ExpenseUser, LibraryUtility.GenerateGUID(), WorkDate(), LibraryUtility.GenerateGUID(), LibraryRandom.RandInt(100));
        CreateAndPostExpenseReportFromExpense(ExpenseReportHeader, Expense, ExpenseUser);

        // [GIVEN] Get Employee linked to the Expense User.
        Employee.Get(ExpenseUser."Employee No.");

        // [WHEN] Delete Employee.
        // [THEN] Error is thrown because employee has posted expense reports.
        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithPostedExpenseReportErr, Employee."No."));
    end;

    [Test]
    procedure DeleteEmployeeWithActiveExpenseReportMustFail()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        // [SCENARIO 633232] Verify that an Employee with active expense reports cannot be deleted.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create an Expense Report for the Expense User.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Get Employee linked to the Expense User.
        Employee.Get(ExpenseUser."Employee No.");

        // [WHEN] Delete Employee.
        // [THEN] Error is thrown because employee has active expense reports.
        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithExpenseReportErr, Employee."No."));
    end;

    [Test]
    procedure DeleteEmployeeWithActiveExpenseMustFail()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
    begin
        // [SCENARIO 633231] Verify that an Employee with active expenses cannot be deleted.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category and Subcategory.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense for the Expense User.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Get Employee linked to the Expense User.
        Employee.Get(ExpenseUser."Employee No.");

        // [WHEN] Delete Employee.
        // [THEN] Error is thrown because employee has active expenses.
        asserterror Employee.Delete(true);
        Assert.ExpectedError(StrSubstNo(CannotDeleteEmployeeWithExpenseErr, Employee."No."));
    end;

    [Test]
    procedure DeleteEmployeeWithNoExpensesMustDeleteLinkedExpenseUser()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
    begin
        // [SCENARIO 633232] Verify that deleting an Employee with no expenses also deletes the linked Expense User.
        Initialize();

        // [GIVEN] Create Expense User with a linked Employee.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Get Employee linked to Expense User.
        Employee.Get(ExpenseUser."Employee No.");

        // [WHEN] Delete Employee.
        Employee.Delete(true);

        // [THEN] The linked Expense User is also deleted.
        Assert.IsFalse(ExpenseUser.Get(ExpenseUser."No."), 'Expense User should have been deleted when Employee was deleted.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ChangeEmailOnEmployeeWithExpensesAndConfirmUpdatesEmail()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        NewEmail: Text[80];
    begin
        // [SCENARIO 633232] Verify that changing the email on an Employee with expenses shows a warning, and the email is updated when confirmed.
        Initialize();

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category and Subcategory.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense for the Expense User.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));

        // [GIVEN] Get Employee linked to Expense User.
        Employee.Get(ExpenseUser."Employee No.");
        NewEmail := CopyStr(LibraryRandom.RandText(10) + '@test.com', 1, 80);

        // [WHEN] Change the Company E-Mail on the Employee. ConfirmHandlerYes confirms the warning.
        Employee.Validate("Company E-Mail", NewEmail);
        Employee.Modify(true);

        // [THEN] The Company E-Mail is updated to the new value.
        Employee.Get(Employee."No.");
        Assert.AreEqual(
            NewEmail,
            Employee."Company E-Mail",
            StrSubstNo(ValueMustBeEqualErr, Employee.FieldCaption("Company E-Mail"), NewEmail, Employee.TableCaption()));
    end;

    [Test]
    procedure ExpensePaymentMethodCannotBeDeletedWhenAttachedToExpenseCategory()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO 637028] Verify that an expense payment method that is referenced by an expense category cannot be deleted.
        Initialize();

        // [GIVEN] Create expense payment method.
        LibraryExpense.CreateExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::" ");

        // [GIVEN] Create expense category referencing the payment method.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::" ", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);

        // [WHEN] Delete the payment method.
        asserterror ExpensePaymentMethod.Delete(true);

        // [THEN] Verify that error is thrown because the payment method is in use by the expense category.
        Assert.ExpectedError(StrSubstNo(CannotDeletePaymentMethodInUseErr, ExpensePaymentMethod.TableCaption(), ExpensePaymentMethod.Code, ExpenseCategory.FieldCaption("Default Payment Method"), ExpenseCategory.TableCaption(), ExpenseCategory.Code));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ExpensePaymentMethodCanBeDeletedWhenNotAttachedToExpenseCategory()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        // [SCENARIO 637028] Verify that an expense payment method that is not referenced by any expense category can be deleted.
        Initialize();

        // [GIVEN] Create an expense payment method with no referencing category.
        LibraryExpense.CreateExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::" ");

        // [WHEN] Delete the payment method.
        ExpensePaymentMethod.Delete(true);

        // [THEN] Verify that the payment method is deleted successfully.
        Assert.IsFalse(ExpensePaymentMethod.Get(ExpensePaymentMethod.Code), 'Payment method should not exist after deletion.');
    end;

    [Test]
    procedure ExpensePaymentMethodCanBeDeletedAfterClearingCategoryReference()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
    begin
        // [SCENARIO 637028] Verify that an expense payment method that is referenced by an expense category can be deleted after clearing the category reference.
        Initialize();

        // [GIVEN] Create an expense payment method.
        LibraryExpense.CreateExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::" ");

        // [GIVEN] Create an expense category referencing the payment method.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::" ", ExpenseCategory."Expense Detail Required"::" ", ExpensePaymentMethod.Code);

        // [GIVEN] Update "Default Payment Method" in expense category.
        ExpenseCategory.Validate("Default Payment Method", '');
        ExpenseCategory.Modify(true);

        // [WHEN] Delete the payment method.
        ExpensePaymentMethod.Delete(true);

        // [THEN] Verify that the payment method is deleted successfully.
        Assert.IsFalse(ExpensePaymentMethod.Get(ExpensePaymentMethod.Code), 'Payment method should not exist after deletion.');
    end;

    [Test]
    procedure CannotSetProjectWhenBillableCustomerIsSetInExpense()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        Customer: Record Customer;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 642523] Verify that a Project cannot be set on an Expense that already has a Billable to Customer.
        Initialize();

        // [GIVEN] Create Customer and Job with Job Task.
        LibrarySales.CreateCustomer(Customer);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create Expense User, Category and SubCategory.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense with Billable to Customer.
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.Validate(Billable, true);
        Expense.Validate("Billable to Customer", Customer."No.");
        Expense.Modify();

        // [WHEN] Set Project (Job No.) on the same Expense.
        asserterror Expense.Validate("Job No.", JobTask."Job No.");

        // [THEN] Verify that an error is thrown because a billable customer and a project are mutually exclusive.
        Assert.ExpectedError(StrSubstNo(BillableCustomerAndProjectErr, Expense.FieldCaption("Billable to Customer"), Expense.FieldCaption("Job No.")));
    end;

    [Test]
    procedure CannotSetBillableCustomerWhenProjectIsSetInExpense()
    var
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        Expense: Record Expense;
        Customer: Record Customer;
        JobTask: Record "Job Task";
    begin
        // [SCENARIO 642523] Verify that a Billable to Customer cannot be set on an Expense that already has a Project.
        Initialize();

        // [GIVEN] Create Customer and Job with Job Task.
        LibrarySales.CreateCustomer(Customer);
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create Expense User, Category and SubCategory.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);

        // [GIVEN] Create Expense with Project (Job No.).
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', 100);
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Modify();

        // [WHEN] Set Billable to Customer on the same Expense.
        Expense.Validate(Billable, true);
        asserterror Expense.Validate("Billable to Customer", Customer."No.");

        // [THEN] Verify that an error is thrown because a billable customer and a project are mutually exclusive.
        Assert.ExpectedError(StrSubstNo(BillableCustomerAndProjectErr, Expense.FieldCaption("Billable to Customer"), Expense.FieldCaption("Job No.")));
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Test");
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

            LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
            Expense.Validate("Starting Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Validate("Ending Date and Time", CreateDateTime(EffectiveDate, Time));
            Expense.Modify();
        end else begin
            LibraryExpense.CreateExpenseRuleWithCondition(
                ExpenseRuleHeader, ExpenseRuleCondition, ExpenseCategory.Code, '', EffectiveDate,
                JustificationRequired, CurrencyCode, UnitOfMeasureCode, ConditionType, Value);

            LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
        end;
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateDimSetIDFromDimValue(var DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        if DimSetID <> 0 then
            DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);

        TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        if not TempDimSetEntry.Insert() then
            TempDimSetEntry.Modify();

        DimSetID := DimensionMgt.GetDimensionSetID(TempDimSetEntry);
    end;

    local procedure VerifyDimensionFromDimensionSetID(DimSetID: Integer; ExpectedCount: Integer; ExpectedDimensionValue: Record "Dimension Value")
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionMgt: Codeunit DimensionManagement;
    begin
        DimensionMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        Assert.RecordCount(TempDimSetEntry, ExpectedCount);

        TempDimSetEntry.SetRange("Dimension Code", ExpectedDimensionValue."Dimension Code");
        TempDimSetEntry.FindFirst();

        Assert.AreEqual(
            ExpectedDimensionValue.Code,
            TempDimSetEntry."Dimension Value Code",
            StrSubstNo(ValueMustBeEqualErr, TempDimSetEntry.FieldCaption("Dimension Value Code"), ExpectedDimensionValue.Code, TempDimSetEntry.TableCaption()));
    end;

    local procedure VerifyMissingExpenseLocationNotification(ExpenseNo: Code[20])
    var
        Expense: Record Expense;
    begin
        Expense.Get(ExpenseNo);

        Assert.ExpectedMessage(
            StrSubstNo(ExpenseLocationMissingMsg, Expense.FieldCaption("Expense Location"), Expense."No."),
            LibraryVariableStorage.DequeueText()); // from SentNotificationHandler

        LibraryVariableStorage.AssertEmpty();
        Clear(Expense);
        LibraryNotificationMgt.RecallNotificationsForRecord(Expense);
    end;

    local procedure CreateAndPostExpenseReport(ReceiptNo: Code[30]; ExpenseDate: Date; MerchantName: Text[100]; Amount: Decimal)
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        CreateAndReleaseExpenseForPosting(Expense, ExpenseUser, ReceiptNo, ExpenseDate, MerchantName, Amount);
        CreateAndPostExpenseReportFromExpense(ExpenseReportHeader, Expense, ExpenseUser);
    end;

    local procedure CreateAndReleaseExpenseForPosting(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; ReceiptNo: Code[30]; ExpenseDate: Date; MerchantName: Text[100]; Amount: Decimal)
    var
        Employee: Record Employee;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);

        Expense.Validate("Expense Ext. Doc. No.", ReceiptNo);
        Expense.Validate("Merchant Name", MerchantName);
        Expense.Validate("Expense Date", ExpenseDate);
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateAndPostExpenseReportFromExpense(var ExpenseReportHeader: Record "Expense Report Header"; var Expense: Record Expense; ExpenseUser: Record "Expense User")
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure CheckAndCreateExpenseUser(var ExpenseUser: Record "Expense User")
    var
        ExpenseUserPage: TestPage "Expense User";
    begin
        ExpenseUserPage.OpenEdit();
        ExpenseUserPage.GoToRecord(ExpenseUser);
        ExpenseUserPage.CreateEmployee.Invoke();
        ExpenseUserPage.Close();

        ExpenseUser.Get(ExpenseUser."No.");
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    procedure AddExpensesToExpenseReportModalPageHandler(var AddExpensesToExpenseReport: TestPage "Add Expenses To Expense Report")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            AddExpensesToExpenseReport.AddExpenseTo.SetValue(AddExpenseTo::"Existing Expense Report");
            AddExpensesToExpenseReport.ExpenseReportNo.SetValue(LibraryVariableStorage.DequeueText());
        end else
            AddExpensesToExpenseReport.AddExpenseTo.SetValue(AddExpenseTo::"New Expense Report");

        AddExpensesToExpenseReport.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PerDiemExpensesWithRuleModalPageErrorHandler(var ExpensePerDiem: TestPage "Per Diem Expenses")
    begin
        ExpensePerDiem.Ok().Invoke();
    end;

    [SendNotificationHandler]
    procedure SentNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;

    [ModalPageHandler]
    procedure ExpenseBillingInformationModalPageHandler(var ExpenseBillingInformation: TestPage "Expense Billing Information")
    begin
        ExpenseBillingInformation.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpenseBillingInfoUpdateMerchantModalPageHandler(var ExpenseBillingInformation: TestPage "Expense Billing Information")
    begin
        ExpenseBillingInformation."Merchant Name".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseBillingInformation.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmployeeTemplateHandler(var EmployeeTemplateList: Page "Select Employee Templ. List"; var Reply: Action)
    var
        EmployeeTemplate: Record "Employee Templ.";
    begin
        EmployeeTemplate.Get(LibraryVariableStorage.DequeueText());
        EmployeeTemplateList.SetRecord(EmployeeTemplate);
        Reply := Action::LookupOK;
    end;
}