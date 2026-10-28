// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.UOM;
using System.Automation;
using System.TestLibraries.Utilities;
using System.Utilities;

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
        ExpenseReportLine.Validate("Merchant Name", CopyStr(LibraryRandom.RandText(20), 1, 100));
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

    [Test]
    procedure NoReceiptThresholdIsStrictAndUsesLCY()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        CurrencyCode: Code[10];
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 2, 1);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::Error, true, CurrencyCode, 100);
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := Expense."Amount (LCY)" + 1;
        ExpenseCategory.Modify();

        Expense.UpdateAmount();
        Assert.AreEqual(Expense."No Receipt Type"::"Receipt not needed", Expense."No Receipt Type",
            'The exemption must use LCY, including when LCY has not changed.');
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'An automatic exemption must not attest or generate a declaration.');

        ExpenseCategory."Amount Limit for No Receipt" := Expense."Amount (LCY)";
        ExpenseCategory.Modify();
        Expense.ApplyRule(false, true);
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Equality requires proof of receipt.');

        ExpenseCategory."Amount Limit for No Receipt" := Expense."Amount (LCY)" - 1;
        ExpenseCategory.Modify();
        Expense.UpdateAmount();
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Amounts above the limit require proof.');
    end;

    [Test]
    procedure NoReceiptExemptionClearsWhenDisabledOrCategoryRemoved()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseNo: Code[20];
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 200;
        ExpenseCategory.Modify();
        Expense.UpdateAmount();
        Assert.AreEqual(Expense."No Receipt Type"::"Receipt not needed", Expense."No Receipt Type", 'Below the limit must be exempt.');
        ExpenseNo := Expense."No.";

        SetAllowNoReceipt(false);
        Clear(Expense);
        Expense.Get(ExpenseNo);
        Expense.UpdateAmount();
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Disabling no receipt must clear automatic exemptions.');

        SetAllowNoReceipt(true);
        Clear(Expense);
        Expense.Get(ExpenseNo);
        Expense.UpdateAmount();
        Expense.Validate("Expense Category", '');
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Removing the category must clear the exemption.');
    end;

    [Test]
    procedure NoReceiptCategoryChangeRecomputesSameAmount()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        ExpenseCategory."Amount Limit for No Receipt" := 100;
        ExpenseCategory.Modify();

        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Expense.Validate(Amount, 100);
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type",
            'Restoring the same LCY amount after category validation must not retain an exemption from the temporary zero amount.');
    end;

    [Test]
    procedure NoReceiptDeclarationBecomesStaleOnEditing()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        CurrencyCode: Code[10];
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", "Expense Detail Needed"::" ");
        ExpenseCategory."Posting Description" := Expense.Description;
        ExpenseCategory.Modify();

        MarkDeclarationCurrentForTest(Expense);
        Expense.Validate("Expense Category", ExpenseCategory.Code);
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'A category change must invalidate the declaration even if its description is unchanged.');
        Assert.AreEqual(Expense."No Receipt Type"::"Lost Receipt", Expense."No Receipt Type", 'Edits must preserve explicit declarations until cancelled.');

        MarkDeclarationCurrentForTest(Expense);
        Expense.Validate("Currency Code", CurrencyCode);
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'A currency change must invalidate the declaration even at a 1:1 rate.');

        MarkDeclarationCurrentForTest(Expense);
        Expense.Validate("Expense Date", CalcDate('<1D>', Expense."Expense Date"));
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'A date change must invalidate the declaration.');

        MarkDeclarationCurrentForTest(Expense);
        Expense.Validate(Amount, Expense.Amount + 1);
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'An amount change must invalidate the declaration.');

        MarkDeclarationCurrentForTest(Expense);
        Expense.Validate(Description, 'Changed declaration description');
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'A description change must invalidate the declaration.');
    end;

    [Test]
    procedure NoReceiptAPIActionsRequireReasonAndAttestation()
    var
        Expense: Record Expense;
        ExpensesAPI: Page "Expenses API";
        ActionContext: WebServiceActionContext;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        Expense.Validate(Description, 'Taxi without a receipt');
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);

        asserterror ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, '   ', true);
        Assert.ExpectedError('Enter the reason the original receipt is unavailable.');
        asserterror ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt was lost', false);
        Assert.ExpectedError('Confirm the declaration before creating the no receipt document.');
        Expense.Get(Expense."No.");
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'Rejected requests must not create a declaration.');
    end;

    [Test]
    procedure NoReceiptAPIActionsGenerateRegenerateAndCancel()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        NoReceiptDeclarationMgt: Codeunit "No Receipt Declaration Mgt.";
        ExpensesAPI: Page "Expenses API";
        ActionContext: WebServiceActionContext;
        FirstDeclarationId: Guid;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        Expense.Validate(Description, 'Taxi without a receipt');
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);

        ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, ' Receipt was lost ', true);
        Expense.Get(Expense."No.");
        Assert.IsTrue(NoReceiptDeclarationMgt.HasCurrentDeclaration(Expense), 'The action must generate a current PDF attachment.');
        Assert.AreEqual('Receipt was lost', Expense."No Receipt Reason", 'The stored reason must be trimmed.');
        FirstDeclarationId := Expense."No Receipt Declaration ID";

        Expense.Validate(Description, 'Updated taxi journey');
        Expense.Modify();
        Assert.IsFalse(NoReceiptDeclarationMgt.HasCurrentDeclaration(Expense), 'Editing must make the existing PDF stale.');
        ExpensesAPI.SetRecord(Expense);
        ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt still unavailable', true);
        Expense.Get(Expense."No.");
        Assert.IsTrue(NoReceiptDeclarationMgt.HasCurrentDeclaration(Expense), 'Regeneration must create current proof.');
        Assert.IsFalse(DocumentAttachment.GetBySystemId(FirstDeclarationId), 'Regeneration must remove the old declaration.');

        FirstDeclarationId := Expense."No Receipt Declaration ID";
        ExpensesAPI.SetRecord(Expense);
        ExpensesAPI.CancelNoReceiptDeclaration(ActionContext);
        Expense.Get(Expense."No.");
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'Cancellation must clear the attachment reference.');
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'Cancellation must clear the current flag.');
        Assert.IsFalse(DocumentAttachment.GetBySystemId(FirstDeclarationId), 'Cancellation must remove the generated declaration.');
    end;

    [Test]
    procedure NoReceiptDeclarationRejectsOriginalReceipt()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        NoReceiptDeclarationMgt: Codeunit "No Receipt Declaration Mgt.";
        ExpenseRecordRef: RecordRef;
        ReceiptInStream: InStream;
        ReceiptOutStream: OutStream;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        Expense.Validate(Description, 'Taxi with original receipt');
        Expense.Modify();
        TempBlob.CreateOutStream(ReceiptOutStream);
        ReceiptOutStream.WriteText('Original receipt');
        TempBlob.CreateInStream(ReceiptInStream);
        ExpenseRecordRef.GetTable(Expense);
        DocumentAttachment.InitFieldsFromRecRef(ExpenseRecordRef);
        DocumentAttachment.SaveAttachmentFromStream(ReceiptInStream, ExpenseRecordRef, 'receipt.txt');

        asserterror NoReceiptDeclarationMgt.CreateDeclaration(Expense, 'Receipt was lost', true);
        Assert.ExpectedError('already has an original receipt');
        Assert.IsTrue(NoReceiptDeclarationMgt.HasOriginalReceipt(Expense), 'Rejected declarations must preserve the original receipt.');
    end;

    [Test]
    procedure NoReceiptActionsRejectReleasedExpense()
    var
        Expense: Record Expense;
        ExpensesAPI: Page "Expenses API";
        ActionContext: WebServiceActionContext;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        Expense.Status := Expense.Status::Released;
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);

        asserterror ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt was lost', true);
        Assert.ExpectedError(Expense.FieldCaption(Status));
        asserterror ExpensesAPI.CancelNoReceiptDeclaration(ActionContext);
        Assert.ExpectedError(Expense.FieldCaption(Status));
    end;

    [Test]
    procedure NoReceiptLostDeclarationBecomesAutomaticExemption()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        DocumentAttachment: Record "Document Attachment";
        ExpensesAPI: Page "Expenses API";
        ActionContext: WebServiceActionContext;
        DeclarationId: Guid;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::"Not needed under limit", true, '', 100);
        Expense.Validate(Description, 'Taxi without a receipt');
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);
        ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt was lost', true);
        Expense.Get(Expense."No.");
        DeclarationId := Expense."No Receipt Declaration ID";
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 100;
        ExpenseCategory.Modify();

        Expense.Validate(Amount, 99);
        Expense.Modify();
        Assert.AreEqual(Expense."No Receipt Type"::"Receipt not needed", Expense."No Receipt Type", 'A lost receipt must become exempt below the limit.');
        Assert.IsTrue(IsNullGuid(Expense."No Receipt Declaration ID"), 'An automatic exemption must clear the obsolete declaration reference.');
        Assert.IsFalse(Expense."No Receipt Decl. Current", 'An automatic exemption must not retain an attestation.');
        Assert.IsFalse(DocumentAttachment.GetBySystemId(DeclarationId), 'An automatic exemption must remove the obsolete generated PDF.');

        Expense.Validate(Amount, 100);
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Increasing to the limit requires new proof, not a restored old declaration.');
    end;

    [Test]
    procedure NoReceiptUnderLimitEnforcementRequiresProofAtEquality()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ExpenseRuleViolation: Record "Expense Rule Violation";
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::"Not needed under limit", true, '', 100);
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 100;
        ExpenseCategory.Modify();
        Expense.ApplyRule(false, true);
        ExpenseRuleViolation.SetRange("Expense No.", Expense."No.");
        ExpenseRuleViolation.SetFilter(Description, '*Document Attachment is mandatory*');
        Assert.IsFalse(ExpenseRuleViolation.IsEmpty(), 'The under-limit policy must require proof at equality.');

        Expense.Validate(Amount, 99);
        Assert.IsTrue(ExpenseRuleViolation.IsEmpty(), 'The under-limit policy must not flag an exempt expense.');
    end;

    [Test]
    procedure NoReceiptReleaseRechecksThresholdBeforeDeclaration()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::"Not needed under limit", true, '', 100);
        MarkDeclarationCurrentForTest(Expense);

        asserterror ReleaseExpenseDocument.PerformManualRelease(Expense);
        Assert.ExpectedError('is missing or no longer current');

        Expense.Get(Expense."No.");
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 200;
        ExpenseCategory.Modify();
        ReleaseExpenseDocument.PerformManualRelease(Expense);
        Expense.Get(Expense."No.");
        Assert.AreEqual(Expense.Status::Released, Expense.Status, 'A newly exempt expense must not require regeneration of an obsolete declaration.');
        Assert.AreEqual(Expense."No Receipt Type"::"Receipt not needed", Expense."No Receipt Type", 'Release must persist the current category exemption.');
    end;

    [Test]
    procedure NoReceiptActionsRejectDisabledPolicyAndReportedExpense()
    var
        Expense: Record Expense;
        ExpensesAPI: Page "Expenses API";
        ActionContext: WebServiceActionContext;
    begin
        Initialize();
        SetAllowNoReceipt(false);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, '', 100);
        Expense.Validate(Description, 'Taxi without a receipt');
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);
        asserterror ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt was lost', true);
        Assert.ExpectedError('No receipt declarations are not allowed');

        SetAllowNoReceipt(true);
        Expense."Expense Report No." := 'REPORT';
        Expense.Modify();
        ExpensesAPI.SetRecord(Expense);
        asserterror ExpensesAPI.CreateNoReceiptDeclaration(ActionContext, 'Receipt was lost', true);
        Assert.ExpectedError(Expense.FieldCaption("Expense Report No."));
        asserterror ExpensesAPI.CancelNoReceiptDeclaration(ActionContext);
        Assert.ExpectedError(Expense.FieldCaption("Expense Report No."));
    end;

    [Test]
    procedure NoReceiptDateChangeRecalculatesLCYAndThreshold()
    var
        Expense: Record Expense;
        ExpenseCategory: Record "Expense Category";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        NewDate: Date;
    begin
        Initialize();
        SetAllowNoReceipt(true);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1);
        CreateExpenseWithNoRule(Expense, "Expense Detail Needed"::" ", "Expense Attachment Enforcement"::" ", true, CurrencyCode, 100);
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory."Amount Limit for No Receipt" := 200;
        ExpenseCategory.Modify();
        Expense.UpdateAmount();
        Assert.AreEqual(Expense."No Receipt Type"::"Receipt not needed", Expense."No Receipt Type", 'The original exchange rate must be below the threshold.');

        NewDate := CalcDate('<1D>', WorkDate());
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := NewDate;
        CurrencyExchangeRate."Exchange Rate Amount" := 1;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 4;
        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := 1;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := 4;
        CurrencyExchangeRate.Insert();

        Expense.Validate("Expense Date", NewDate);
        Assert.AreEqual(400, Expense."Amount (LCY)", 'Date validation must apply the new exchange rate.');
        Assert.AreEqual(Expense."No Receipt Type"::" ", Expense."No Receipt Type", 'Date-driven LCY changes must re-evaluate the threshold.');
    end;

    local procedure SetAllowNoReceipt(AllowNoReceipt: Boolean)
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Allow No Receipt" := AllowNoReceipt;
        ExpenseAgentSetup.Modify();
    end;

    local procedure MarkDeclarationCurrentForTest(var Expense: Record Expense)
    begin
        Expense."No Receipt Type" := Expense."No Receipt Type"::"Lost Receipt";
        Expense."No Receipt Declaration ID" := CreateGuid();
        Expense."No Receipt Decl. Current" := true;
        Expense.Modify();
        Expense.Get(Expense."No.");
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