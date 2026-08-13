// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.UOM;
using System.Automation;
using System.TestLibraries.Utilities;

codeunit 148311 "Expense No Rule Test"
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
        ItemizationRequiredErr: Label 'Itemization is required for this expense based on your organization''s rule.';
        ItemizationTotalMismatchErr: Label 'Itemization total %1 must be equal to expense amount %2.', Comment = '%1 = Itemization total amount, %2 = Expense amount';
        MileageRequiredErr: Label 'Mileage details are required for this expense based on your organization''s rule.';
        ParticipantsRequiredErr: Label 'Participants are required for this expense based on your organization''s rule.';

    [Test]
    [HandlerFunctions('CreateExpenseItemizationsWithSubCategoryHandler')]
    procedure AmountReductionIsUpdatedInExpenseFromExpenseItemizationPageWithoutRule()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618902] Verify that the Amount Reduction is updated in Expense from Expense Itemization Page.
        // when Expense Itemization is created with Refundable and Non-Refundable Expense Sub Category Without Rule.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(10, 50);

        // [GIVEN] Create Expense with No Rule for "Itemize".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::Itemize, "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], Expense."Expense Category", true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], Expense."Expense Category", false);

        // [GIVEN] Enqueue Expense Sub Category Code, Quantity and Amount for Expense Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory[1].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Amount - AmountReduction);

        LibraryVariableStorage.Enqueue(ExpenseSubCategory[2].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(AmountReduction);

        // [GIVEN] Apply Rule.
        Expense.ApplyRule();

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violations are shown in Expense Page.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(ItemizationRequiredErr);
        ExpensePage.RuleViolations.Next();
        ExpensePage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalMismatchErr, 0, Expense.Amount));

        // [WHEN] Invoke Itemizations Action.
        ExpensePage.Itemizations.Invoke();

        // [THEN] Verify that the Amount Reduction is updated in Expense from Expense Itemization Page.
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage."Non-Refundable Amount".AssertEquals(AmountReduction);
    end;

    [Test]
    [HandlerFunctions('AddExpenseItemizationsWithSubCategoryHandler')]
    procedure AmountReductionIsUpdatedInExpenseReportLineFromExpenseReportItemizationPage()
    var
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: array[2] of Record "Expense Subcategory";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        AmountReduction: Decimal;
    begin
        // [SCENARIO 618902] Verify that the Amount Reduction is updated in Expense Report Line from Expense Report Itemization Page.
        // when Expense Report Line Itemization is created with Refundable and Non-Refundable Expense Sub Category.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := LibraryRandom.RandIntInRange(50, 90);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Itemize, ExpensePaymentMethod.Code);

        // [GIVEN] Create Expense Sub Category.
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[1], ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory[2], ExpenseCategory.Code, false);

        // [GIVEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Refundable.SetValue(true);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [WHEN] Enqueue Expense Sub Category Code, Quantity and Amount for Expense Itemization.
        LibraryVariableStorage.Enqueue(ExpenseSubCategory[1].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(Amount - AmountReduction);

        LibraryVariableStorage.Enqueue(ExpenseSubCategory[2].Code);
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(AmountReduction);

        // [THEN] Verify that Rule Violations are shown in Expense Report Page.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(ItemizationRequiredErr);
        ExpenseReportPage.RuleViolations.Next();
        ExpenseReportPage.RuleViolations.Description.AssertEquals(StrSubstNo(ItemizationTotalMismatchErr, 0, ExpenseReportPage."Expense Report Subform".Amount));

        // [GIVEN] Add Itemization from Expense Itemizations Page.
        ExpenseReportPage."Expense Report Subform".Itemizations.Invoke();

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Verify that the Amount Reduction is updated in Expense Report Line from Expense Report Itemization Page.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage."Expense Report Subform"."Non-Refundable Amount".AssertEquals(AmountReduction);
        ExpenseReportPage.Status.AssertEquals(Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    procedure AmountIsUpdatedInExpenseWhenMileageIsUpdated()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618902] Verify that the Amount is updated in Expense from Expense Page.
        Initialize();

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Modify(true);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with No Rule for "Mileage".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::Mileage, "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violations are shown in Expense Page.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(MileageRequiredErr);
        ExpensePage.Amount.AssertEquals(0);
        ExpensePage."Amount (LCY)".AssertEquals(0);
        ExpensePage."Unit of Measure Code".AssertEquals(ExpenseAgentSetup."Default Mileage UOM");

        // [WHEN] Set Mileage in Expense Page.
        ExpensePage.Mileage.SetValue(Amount);

        // [THEN] Verify that the Amount is updated in Expense from Expense Page.
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
        ExpensePage.Amount.AssertEquals(Amount * Round(LibraryERM.ConvertCurrency(ExpenseAgentSetup."Standard Rate of Mileage", '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision"));
        ExpensePage."Amount (LCY)".AssertEquals(Amount);
    end;

    [Test]
    procedure AmountIsUpdatedInExpenseReportWhenMileageIsUpdated()
    var
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UnitOfMeasure: Record "Unit of Measure";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618902] Verify that the Amount is updated in Expense Report when Mileage is updated in Expense Report Line.
        Initialize();

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Update Standard Rate of Mileage in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Standard Rate of Mileage", LibraryRandom.RandIntInRange(1, 1));
        ExpenseAgentSetup.Validate("Default Mileage UOM", UnitOfMeasure.Code);
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Mileage, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform"."Expense Currency Code".SetValue(CurrencyCode);

        // [THEN] Verify that Rule Violations are shown in Expense Report Page.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(MileageRequiredErr);
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(0);

        // [WHEN] Set Mileage in Expense Report Line.
        ExpenseReportPage."Expense Report Subform".Mileage.SetValue(Amount);

        // [THEN] Verify that the Amount is updated in Expense Report.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage."Expense Report Subform".Amount.AssertEquals(Amount * Round(LibraryERM.ConvertCurrency(ExpenseAgentSetup."Standard Rate of Mileage", '', CurrencyCode, WorkDate()), Currency."Amount Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('AddExpenseParticipantsModalPageHandler')]
    procedure RuleViolationIsRemovedWWhenParticipantsIsUpdatedInExpense()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpensePage: TestPage Expense;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618902] Verify that the Rule Violation is removed when Participants is updated in Expense from Expense Page.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create Expense with No Rule for "Participants".
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::Participants, "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [WHEN] Open Expense Page.
        ExpensePage.OpenEdit();
        ExpensePage.GoToRecord(Expense);

        // [THEN] Verify that Rule Violations are shown in Expense Page.
        ExpensePage."Rule Violations".AssertEquals(true);
        ExpensePage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);

        // [GIVEN] Enqueue "Employee No." for Participant.
        ExpenseUser.Get(Expense."Expense User No.");
        LibraryVariableStorage.Enqueue(ExpenseUser."Employee No.");

        // [WHEN] Invoke Participants Action.
        ExpensePage.Participants.Invoke();

        // [THEN] Verify that the Participants is updated in Expense from Expense Page.
        ExpensePage."Rule Violations".AssertEquals(false);
        ExpensePage.RuleViolations.Description.AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('AddExpenseReportParticipantsModalPageHandler')]
    procedure RuleViolationIsRemovedWWhenParticipantsIsUpdatedInExpenseReport()
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportPage: TestPage "Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 618902] Verify that the Rule Violation is removed when Participants is updated in Expense Report from Expense Report Page.
        Initialize();

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense User.
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create Expense Category.
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::Participants, ExpensePaymentMethod.Code);

        // [WHEN] Create Expense Report.
        ExpenseReportPage.OpenNew();
        ExpenseReportPage."Expense User No.".SetValue(ExpenseUser."No.");
        ExpenseReportPage."Expense Report Subform"."Expense Category".SetValue(ExpenseCategory.Code);
        ExpenseReportPage."Expense Report Subform".Amount.SetValue(Amount);

        // [THEN] Verify that expense Rule Violation is true before adding Participant.
        ExpenseReportPage.RuleViolations.Description.AssertEquals(ParticipantsRequiredErr);

        // [GIVEN] Enqueue "Employee No." for Participant.
        LibraryVariableStorage.Enqueue(ExpenseUser."Employee No.");

        // [GIVEN] Add Participant from Expense Report Participants Page.
        ExpenseReportPage."Expense Report Subform".Participants.Invoke();

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, CopyStr(ExpenseReportPage."No.".Value(), 1, 20));

        // [GIVEN] Update "Merchant Name" in Expense Report Line.
        ExpenseReportLine.Validate("Merchant Name", LibraryRandom.RandText(20));
        ExpenseReportLine.Modify();

        // [WHEN] Release Expense Report.
        ExpenseReportPage.Release.Invoke();

        // [THEN] Verify that Expense Report is released successfully.
        ExpenseReportPage.RuleViolations.Description.AssertEquals('');
        ExpenseReportPage.Status.AssertEquals(Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure CannotSelectDifferentExpenseUserInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser1: Record "Expense User";
        ExpenseUser2: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618902] Verify that different Expense User cannot be selected in Expense Report Line
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(2000);

        // [GIVEN] Create Expense User
        LibraryExpense.CreateExpenseUser(ExpenseUser2);

        // [GIVEN] Create Expense.
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::Itemize, "Expense Attachment Enforcement"::" ", true, CurrencyCode, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report and attach Expense.
        ExpenseUser1.Get(Expense."Expense User No.");
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser1."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [WHEN] Create another Expense Report Line.
        asserterror LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, ExpenseUser2."No.", Expense."Expense Category", ExpensePaymentMethod.Code, true, Currency.Code, Amount);

        // [THEN] Verify that different Expense User cannot be selected in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Expense User No."), ExpenseUser1."No.");
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense No Rule Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense No Rule Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateDefaultUnitOfMeasureInAgentSetup();
        LibraryExpense.UpdateUseRulesInAgentSetup(false);
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense No Rule Test");
    end;

    local procedure CreateExpenseWithNoRule(var Expense: Record Expense; ExpenseDetailRequired: Enum "Expense Detail Needed"; AttachmentEnforcement: Enum "Expense Attachment Enforcement"; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        PostCode: Record "Post Code";
        ExpenseLocation: Record "Expense Location";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseDetailRequired);
        UpdateAttachmentEnforcementInExpenseCategory(ExpenseCategory.Code, AttachmentEnforcement);

        if ExpenseDetailRequired = ExpenseDetailRequired::"Per Diem" then begin
            LibraryERM.CreatePostCode(PostCode);
            LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);
        end;

        LibraryExpense.CreateExpense(Expense, ExpenseUser."No.", ExpenseCategory.Code, '', ExpenseLocation."No.", Refundable, CurrencyCode, Amount);
    end;

    local procedure UpdateAttachmentEnforcementInExpenseCategory(CategoryCode: Code[20]; AttachmentEnforcement: Enum "Expense Attachment Enforcement")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.Get(CategoryCode);
        ExpenseCategory.Validate("Attachment Enforcement", AttachmentEnforcement);
        ExpenseCategory.Modify(true);
    end;

    local procedure CreateAndAttachExpenseToExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20])
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, VATBusPostingGroup);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; ExpenseReportNo: Code[20])
    begin
        ExpenseReportLine.SetRange("Document No.", ExpenseReportNo);
        ExpenseReportLine.FindFirst();
    end;

    [ModalPageHandler]
    procedure CreateExpenseItemizationsWithSubCategoryHandler(var ExpenseItemizationsPage: TestPage "Expense Itemizations")
    begin
        ExpenseItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());

        ExpenseItemizationsPage.New();
        ExpenseItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());
        ExpenseItemizationsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseParticipantsModalPageHandler(var ExpenseParticipants: TestPage "Expense Participants")
    begin
        ExpenseParticipants."Participant Employee No.".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseParticipants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseItemizationsWithSubCategoryHandler(var ExpenseReportLineItemizationsPage: TestPage "Expense Report Line Items")
    begin
        ExpenseReportLineItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseReportLineItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());

        ExpenseReportLineItemizationsPage.New();
        ExpenseReportLineItemizationsPage."Expense Subcategory Code".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineItemizationsPage.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        ExpenseReportLineItemizationsPage."Daily Rate".SetValue(LibraryVariableStorage.DequeueDecimal());
        ExpenseReportLineItemizationsPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AddExpenseReportParticipantsModalPageHandler(var ExpenseReportLineParticipants: TestPage "Expense Report Line Particips")
    begin
        ExpenseReportLineParticipants."Participant Employee No.".SetValue(LibraryVariableStorage.DequeueText());
        ExpenseReportLineParticipants.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;
}