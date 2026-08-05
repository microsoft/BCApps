// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System;
using System.Automation;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 148302 "Expense Report Posting Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        AddExpenseTo: Option "New Expense Report","Existing Expense Report";
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        SalesDocNoMustNotBeSameErr: Label 'Sales Document No. must not be same.';
        DocumentCanOnlyBePostedWhenApprovalProcessIsCompleteErr: Label 'This document can only be posted when the approval process is complete.';
        JPEGLbl: Label '.jpeg';
        DocumentAttachmentDoesNotExistErr: Label 'Document Attachment does not exist on %1.', Comment = '%1 - Table Caption';
        DocumentAttachmentExistErr: Label 'Document Attachment exist on %1.', Comment = '%1 - Table Caption';
        CannotUpdateAndDeleteAttachmentIfOpenStatusErr: Label 'You can only import and delete attachments on %1 %2 when the %3 is Open.', Comment = '%1 = Expense No., %2 = EXP100001, %3 = Status';
        CannotImportAndDeleteAttachmentOnPostedExpenseReportErr: Label 'You cannot import and delete attachments on %1 %2, %3 %4.', Comment = '%1 = Posted Expense Report No., %2 = P-ER000001, %3 = Line No., %4 = 10000';
        CannotUpdateAndDeleteAttachmentOnExpenseErr: Label 'You cannot update and delete attachment on an %1 %2 that is part of an %3 %4.', Comment = '%1 = Expense No., %2 = EXP100001, %3 = Expense Report No., %4 = ER100001';
        CannotUpdateAndDeleteAttachmentOnExpenseReportErr: Label 'You cannot update and delete attachment on an %1 %2, %3 %4 that is part of an %5 %6.', Comment = '%1 = Expense Report No., %2 = ER100001, %3 = Line No., %4 = 10000, %5 = Expense No., %6 = EXP100001';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportMustBePostedForOnlyReleasedExpense()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
    begin
        // [SCENARIO 580546] Verify that the Expense Report must be posted for "Expense" with Status "Released".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted. 
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);

        PostedExpenseReportLine.SetRange("Expense User No.", Expense."Expense User No.");
        Assert.RecordCount(PostedExpenseReportLine, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportMustBePostedForMultipleReleasedExpense()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 580546] Verify that the Expense Report must be posted for multiple "Expense" with Status "Released".
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted. 
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense[1]."Expense User No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);

        PostedExpenseReportLine.SetRange("Expense User No.", Expense[1]."Expense User No.");
        Assert.RecordCount(PostedExpenseReportLine, 2);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,GLPostingPreviewHandler')]
    procedure GLEntryMustBeShownWhenPreviewPostingOfExpenseReport()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 580546] Verify that the "G/L Entry" must be shown When Preview Posting of Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', Amount);

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save transaction.
        Commit();

        // [WHEN] Preview Post Expense Report.
        LibraryVariableStorage.Enqueue(2);
        asserterror ExpenseReportHeader.Preview(ExpenseReportHeader);

        // [THEN] Verify that the "G/L Entry" must be shown When Preview Posting of Expense Report through Handler.
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure GLEntryMustBeCreatedWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "G/L Entry" is created When Expense Report is posted.
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

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that "G/L Entry", "Employee Ledger Entry" and "Detailed Employee Ledger Entry" are created When Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntry(PostedExpenseReportHeader."No.", EmployeePostingGroup.GetExpenseReportPayablesAccount(), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", ExpensePostingGroup."Refundable Debit Account", ExpectedAmountLCY);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportPayableAccountMustExistInEmployeePostingGroupWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Expense Payable Cash Account" must exist When Expense Report is posted.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        EmployeePostingGroup.Get(Employee."Employee Posting Group");
        EmployeePostingGroup.Validate("Expense Report Payable Account", '');
        EmployeePostingGroup.Modify();

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Expense Payable Cash Account" must exist.
        Assert.ExpectedTestFieldError(EmployeePostingGroup.FieldCaption("Expense Report Payable Account"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure RefundableDebitAccountMustExistInExpensePostingGroupWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that system must throw an error of "Refundable Debit Account" must exist When Expense Report is posted.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Update "Refundable Debit Account" in Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", '');
        ExpensePostingGroup.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Refundable Debit Account" must exist.
        Assert.ExpectedTestFieldError(ExpensePostingGroup.FieldCaption("Refundable Debit Account"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportNoIsUpdatedInExpenseWhenExpenseIsUsedInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Text;
    begin
        // [SCENARIO 580546] Verify that "Expense Report No." in updated in Expense when GetExpenseLine is invoked in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get and Update Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that "Expense Report No." in updated in Expense.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            ExpenseReportNo,
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), ExpenseReportNo, Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseLedgerEntryIsCreatedWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
        ExpenseReportNo: Text;
    begin
        // [SCENARIO 580546] Verify that an Expense Ledger Entry is created when an Expense Report is posted.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get and Update Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save Expense Report No.
        ExpenseReportNo := ExpenseReportHeader."No.";

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that an Expense Ledger Entry is created when the Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 1);

        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, Employee."No.", Expense.Amount, Expense."Amount (LCY)");

        // [THEN] Verify that an Employee Ledger Entry is created when the Expense Report is posted.
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -PostedExpenseReportLine."Amount (LCY)");
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -PostedExpenseReportLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleExpenseLedgerEntryIsCreatedWhenExpenseReportIsPostedForMultipleExpenses()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: array[2] of Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 580546] Verify that an Expense Ledger Entry is created for both Expenses when an Expense Report is posted for multiple Expenses.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that an Expense Ledger Entry is created when the Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 2);

        // [THEN] Verify that multiple Expense Ledger Entry is created for both Expenses.
        FindPostedExpenseReportLine(PostedExpenseReportLine[1], Expense[1]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[1], Expense[1], Employee."No.", Expense[1].Amount, Expense[1]."Amount (LCY)");

        FindPostedExpenseReportLine(PostedExpenseReportLine[2], Expense[2]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[2], Expense[2], Employee."No.", Expense[2].Amount, Expense[2]."Amount (LCY)");

        // [THEN] Verify that an Employee Ledger Entry is created when the Expense Report is posted.
        EmployeeLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(EmployeeLedgerEntry, 1);

        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -PostedExpenseReportLine[1]."Amount (LCY)" - PostedExpenseReportLine[2]."Amount (LCY)");
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -PostedExpenseReportLine[1]."Amount (LCY)" - PostedExpenseReportLine[2]."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ExpenseReportGLPostingPreviewHandler')]
    procedure ExpenseLedgerEntryAndEmployeeLedgerEntryMustBeShownWhenPreviewPostingOfExpenseReport()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        // [SCENARIO 580546] Verify that the Expense Ledger Entry and Employee Ledger Entry must be shown When Preview Posting of Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save transaction.
        Commit();

        // [WHEN] Preview Post Expense Report.
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(1);
        asserterror ExpenseReportHeader.Preview(ExpenseReportHeader);

        // [THEN] Verify that the Expense Ledger Entry and Employee Ledger Entry must be shown When Preview Posting of Expense Report through Handler.
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,NavigateFindEntriesHandler,ConfirmHandler')]
    procedure VerifyExpenseLedgerEntryAndEmployeeLedgerEntryShouldBeShownWhenNavigatingPostedExpenseReport()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Navigate: Page Navigate;
    begin
        // [SCENARIO 580546] Verify that the Expense Ledger Entry and Employee Ledger Entry should be shown when navigating Posted Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory, ExpenseUser);
        Expense[1]."Reimbursement Type" := Expense[1]."Reimbursement Type"::"Employee Paid";
        Expense[1]."Payment Method Code" := '';
        Expense[1].Modify();

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory, ExpenseUser);
        Expense[2]."Reimbursement Type" := Expense[2]."Reimbursement Type"::"Employee Paid";
        Expense[2]."Payment Method Code" := '';
        Expense[2].Modify();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save transaction.
        Commit();

        // [GIVEN] Enqueue Count of Expense Ledger Entry and Employee Ledger Entry.
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(1);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Ledger Entry and Employee Ledger Entry should be shown when navigating Posted Expense Report through NavigateFindEntriesHandler handler.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        Navigate.SetDoc(ExpenseReportHeader."Posting Date", PostedExpenseReportHeader."No.");
        Navigate.Run();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure BillableToCustomerMustHaveValueWhenBillableIsTrueInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Billable to Customer" must have a value when "Billable" is true in Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Set Billable to true in Expense Report Line.
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Billable to Customer" must have a value when "Billable" is true in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Billable to Customer"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure AccountTypeMustBeEqualToGLAccountWhenBillableIsTrueInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Account Type" must be equal to "G/L Account" when "Billable" is true in Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update Billable and "Billable to Customer" in Expense Report Line.
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", LibrarySales.CreateCustomerNo());
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Account Type" must be equal to "G/L Account" when "Billable" is true in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Account Type"), Format(ExpenseReportLine."Account Type"::"G/L Account"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure AccountNoMustHaveValueWhenBillableIsTrueInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that Account No. must have a value when "Billable" is true in Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update Billable and "Billable to Customer" in Expense Report Line.
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", LibrarySales.CreateCustomerNo());
        ExpenseReportLine.Validate("Account Type", ExpenseReportLine."Account Type"::"G/L Account");
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Account No." must have a value when "Billable" is true in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Account No."), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure SalesDocumentIsCreatedWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        Customer: Record Customer;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        SalesHeader: Record "Sales Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that a sales document is created when an expense report is posted.
        Initialize();

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT");

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update Billable and "Billable to Customer" in Expense Report Line.
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", Customer."No.");
        ExpenseReportLine.Validate("Account Type", ExpenseReportLine."Account Type"::"G/L Account");
        ExpenseReportLine.Validate("Account No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale));
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that a sales document is created when the expense report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader, PostedExpenseReportHeader, PostedExpenseReportLine);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure OneSalesDocumentIsCreatedWhenMultipleExpenseIsPosted()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        PostCode: Record "Post Code";
        Expense: array[2] of Record Expense;
        ExpenseUser: Record "Expense User";
        SalesHeader: array[2] of Record "Sales Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        PostedExpenseReportHeader: array[2] of Record "Posted Expense Report Header";
        PostedExpenseReportLine: array[2] of Record "Posted Expense Report Line";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that a single sales document is created when multiple expense reports are posted for the same customer.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateAndReleaseExpense(Expense[1], ExpenseUser, true, CurrencyCode, Amount);

        // [GIVEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader[1], ExpenseReportLine[1], Expense[1], Customer, ExpenseUser, Currency);

        // [GIVEN] Create another Expense.
        CreateAndReleaseExpense(Expense[2], ExpenseUser, true, CurrencyCode, Amount);

        // [GIVEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader[2], ExpenseReportLine[2], Expense[2], Customer, ExpenseUser, Currency);

        // [THEN] Verify that a sales document is created when the expense report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader[1], Expense[1]);
        FindPostedExpenseReportLine(PostedExpenseReportLine[1], Expense[1]);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader[1], PostedExpenseReportHeader[1], PostedExpenseReportLine[1]);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine[1]);

        FindPostedExpenseReport(PostedExpenseReportHeader[2], Expense[2]);
        FindPostedExpenseReportLine(PostedExpenseReportLine[2], Expense[2]);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader[2], PostedExpenseReportHeader[2], PostedExpenseReportLine[2]);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine[2]);
        SalesHeader[1].TestField("No.", SalesHeader[2]."No.");
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure DifferentSalesDocumentIsCreatedWhenMultipleExpenseIsPosted()
    var
        Currency: Record Currency;
        PostCode: Record "Post Code";
        Expense: array[2] of Record Expense;
        Customer: array[2] of Record Customer;
        ExpenseUser: Record "Expense User";
        SalesHeader: array[2] of Record "Sales Header";
        ExpenseReportLine: array[2] of Record "Expense Report Line";
        ExpenseReportHeader: array[2] of Record "Expense Report Header";
        PostedExpenseReportHeader: array[2] of Record "Posted Expense Report Header";
        PostedExpenseReportLine: array[2] of Record "Posted Expense Report Line";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that a different sales document is created when multiple expense reports are posted for different customers.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer[1]);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateAndReleaseExpense(Expense[1], ExpenseUser, true, CurrencyCode, Amount);

        // [GIVEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader[1], ExpenseReportLine[1], Expense[1], Customer[1], ExpenseUser, Currency);

        // [GIVEN] Create another Expense.
        CreateAndReleaseExpense(Expense[2], ExpenseUser, true, CurrencyCode, Amount);

        // [GIVEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader[2], ExpenseReportLine[2], Expense[2], Customer[2], ExpenseUser, Currency);

        // [THEN] Verify that a different sales document is created when the expense report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader[1], Expense[1]);
        FindPostedExpenseReportLine(PostedExpenseReportLine[1], Expense[1]);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader[1], PostedExpenseReportHeader[1], PostedExpenseReportLine[1]);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine[1]);

        FindPostedExpenseReport(PostedExpenseReportHeader[2], Expense[2]);
        FindPostedExpenseReportLine(PostedExpenseReportLine[2], Expense[2]);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader[2], PostedExpenseReportHeader[2], PostedExpenseReportLine[2]);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine[2]);

        Assert.AreNotEqual(SalesHeader[1]."No.", SalesHeader[2]."No.", SalesDocNoMustNotBeSameErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesDocumentIsCreatedForExpenseReportWithoutExpense()
    var
        Employee: Record Employee;
        PostCode: Record "Post Code";
        Customer: Record Customer;
        ExpensePaymentMethod: Record "Expense Payment Method";
        SalesHeader: Record "Sales Header";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 580546] Verify that a sales document is created when an expense report is posted without any expenses.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT");

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create "Expense Location".
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, true, Customer."No.",
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale));

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        ExpenseReportLine.Validate(Refundable, true);
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine.Validate(Amount, LibraryRandom.RandInt(100));
        ExpenseReportLine.Modify();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that a sales document is created when the expense report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseUser);
        FindSalesHeaderFromPostedExpenseReportLine(SalesHeader, PostedExpenseReportHeader, PostedExpenseReportLine);
        VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure VendorNoMustHaveValueWhenPurchaseInvoiceIsTrueInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Vendor No." must have a value when "Purchase Invoice" is true in Expense Report Line.
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
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update "Purchase Invoice" in Expense Report Line.
        ExpenseReportLine.Validate("Purchase Invoice", true);
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Vendor No." must have a value when "Purchase Invoice" is true in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Vendor No."), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostedPurchaseInvoiceNoMustHaveValueWhenPurchaseInvoiceIsTrueInExpenseReportLine()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Posted Purchase Invoice No." must have a value when "Purchase Invoice" is true in Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update "Purchase Invoice" and "Vendor No." in Expense Report Line.
        ExpenseReportLine.Validate("Purchase Invoice", true);
        ExpenseReportLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Posted Purchase Invoice No." must have a value when "Purchase Invoice" is true in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Posted Purch. Invoice No."), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseCategoryMustBeRequiredWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Expense Category" must be required when Expense Report is posting.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update "Expense Category" in Expense Report Line.
        ExpenseReportLine."Expense Category" := '';
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Expense Category" must have a value when Expense Report is posting.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Expense Category"), '');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure DescriptionMustBeRequiredWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Description" must be required when Expense Report is posting.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Find Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update "Description" in Expense Report Line.
        ExpenseReportLine.Validate(Description, '');
        ExpenseReportLine.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Description" must have a value when Expense Report is posting.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption(Description), '');
    end;

    [Test]
    procedure ExpenseUserNoMustBeRequiredWhenExpenseIsInsertedInExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Expense User No." must be required when Expense is inserted in Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        ExpenseReportHeader.Init();
        ExpenseReportHeader.Insert(true);

        // [WHEN] Insert Expense.
        asserterror CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that system must throw an error of "Expense User No." must have a value when Expense is inserted in Expense Report.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption("Expense User No."), '');
    end;

    [Test]
    [HandlerFunctions('CancelExpensesModalPageHandler')]
    procedure ExpenseReportNoMustBeBlankAfterCancellingIntoExpenseReport()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580546] Verify that "Expense Report No." must be blank in Expense after Cancelling into Expense Report.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [WHEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [THEN] Verify that "Expense Report No." must be blank in Expense after Cancelling into Expense Report."
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            '',
            Expense."Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Expense Report No."), '', Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RefundableMustBeFlowFromExpenseReportLineToPostedExpenseReportLine()
    var
        Employee: Record Employee;
        PostCode: Record "Post Code";
        Customer: Record Customer;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 613262] Verify that "Refundable" must be flow from Expense Report Line to Posted Expense Report Line.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create "Expense Location".
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, true, Customer."No.",
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        ExpenseReportLine.Validate(Refundable, true);
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine.Validate(Amount, LibraryRandom.RandInt(100));
        ExpenseReportLine.Modify();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that "Refundable" must be flow from Expense Report Line to Posted Expense Report Line.
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseUser);
        Assert.AreEqual(
            true,
            PostedExpenseReportLine.Refundable,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption(Refundable), true, PostedExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleExpenseLedgerEntryIsCreatedWhenExpenseReportIsPostedForMultipleExpensesWithDifferentPaymentMethods()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        GLEntry: Record "G/L Entry";
        ExpensePaymentMethod: array[2] of Record "Expense Payment Method";
        ExpenseCategory: array[2] of Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: array[2] of Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 613294] Verify that an Expense Ledger Entry is created for both Expenses when an Expense Report is posted for multiple Expenses with Different Payment Methods.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[1], ExpenseCategory[1]."Reimbursement Type"::"Company Paid", ExpenseCategory[1]."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseCategory(ExpenseCategory[2], ExpenseCategory[2]."Reimbursement Type"::"Credit Card", ExpenseCategory[2]."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get and Update Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory[1]."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory[1], ExpenseUser);

        // [GIVEN] Get Payment Method.
        ExpensePaymentMethod[1].Get(Expense[1]."Payment Method Code");

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory[2], ExpenseUser);

        // [GIVEN] Get Payment Method.
        ExpensePaymentMethod[2].Get(Expense[2]."Payment Method Code");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that an Expense Ledger Entry is created when the Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 2);

        // [THEN] Verify that multiple Expense Ledger Entry is created for both Expenses.
        FindPostedExpenseReportLine(PostedExpenseReportLine[1], Expense[1]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[1], Expense[1], Employee."No.", Expense[1].Amount, Expense[1]."Amount (LCY)");

        FindPostedExpenseReportLine(PostedExpenseReportLine[2], Expense[2]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[2], Expense[2], Employee."No.", Expense[2].Amount, Expense[2]."Amount (LCY)");

        // [THEN] Verify that an Employee Ledger Entry is not created when the Expense Report is posted.
        EmployeeLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(EmployeeLedgerEntry, 0);

        // [THEN] Verify G/L Entries are created correctly when the Expense Report is posted.
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(GLEntry, 4);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(Employee."No."), -Expense[1].Amount);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCardPaidAccountFromEmployeePostingGroup(Employee."No."), -Expense[2].Amount);
        VerifyGLEntry(PostedExpenseReportHeader."No.", ExpensePostingGroup."Refundable Debit Account", Expense[1].Amount + Expense[2].Amount);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultipleExpenseLedgerEntryIsCreatedWhenExpenseReportIsPostedForMultipleExpensesWithSamePaymentMethod()
    var
        Expense: array[2] of Record Expense;
        Employee: Record Employee;
        GLEntry: Record "G/L Entry";
        ExpensePaymentMethod: array[2] of Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: array[2] of Record "Posted Expense Report Line";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 613294] Verify that an Expense Ledger Entry is created for both Expenses when an Expense Report is posted for multiple Expenses with Same Payment Method.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get and Update Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        // [GIVEN] Create "Expense".
        CreateAndReleaseExpense(Expense[1], ExpenseCategory, ExpenseUser);

        // [GIVEN] Get Payment Method.
        ExpensePaymentMethod[1].Get(Expense[1]."Payment Method Code");

        // [GIVEN] Create another "Expense".
        CreateAndReleaseExpense(Expense[2], ExpenseCategory, ExpenseUser);

        // [GIVEN] Set same Payment Method as first Expense.
        Expense[2]."Payment Method Code" := Expense[1]."Payment Method Code";
        Expense[2].Modify();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Insert another Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that an Expense Ledger Entry is created when the Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 2);

        // [THEN] Verify that multiple Expense Ledger Entry is created for both Expenses.
        FindPostedExpenseReportLine(PostedExpenseReportLine[1], Expense[1]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[1], Expense[1], Employee."No.", Expense[1].Amount, Expense[1]."Amount (LCY)");

        FindPostedExpenseReportLine(PostedExpenseReportLine[2], Expense[2]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine[2], Expense[2], Employee."No.", Expense[2].Amount, Expense[2]."Amount (LCY)");

        // [THEN] Verify that an Employee Ledger Entry is not created when the Expense Report is posted.
        EmployeeLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(EmployeeLedgerEntry, 0);

        // [THEN] Verify G/L Entries are created correctly when the Expense Report is posted.
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(GLEntry, 4);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(Employee."No."), -Expense[1].Amount - Expense[2].Amount);
        VerifyGLEntry(PostedExpenseReportHeader."No.", ExpensePostingGroup."Refundable Debit Account", Expense[1].Amount + Expense[2].Amount);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure GLEntryWithSourceCurrencyCodeMustBeCreatedWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613707] Verify that Source Currency Code is not blank in "G/L Entry" When Expense Report is posted.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Source code is not blank in "G/L Entry"When Expense Report is posted.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntryWithSourceCurrencyCode(PostedExpenseReportHeader);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportCannotBePostedIfStatusIsNotApprovedWhenExpenseApprovalWorkflowIsEnabledInAgentSetup()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        UserSetup: Record "User Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report cannot be posted if Status is not Approved when Expense Approval Workflow is enabled in Agent Setup.
        Initialize();

        // [GIVEN] Enable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Create or Find User Setup.
        LibraryDocumentApprovals.CreateOrFindUserSetup(UserSetup, CopyStr(UserId, 1, 50));

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        // [GIVEN] Get "Expense Category".
        ExpenseCategory.Get(Expense."Expense Category");

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");
        ExpenseUser.Validate("User Id For Approvals", UserSetup."User ID");
        ExpenseUser.Modify();

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Get Employee Posting Group.
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be posted if Status is not Approved when Expense Approval Workflow is enabled in Agent Setup.
        Assert.ExpectedError(DocumentCanOnlyBePostedWhenApprovalProcessIsCompleteErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportCannotBePostedIfStatusIsNotOpenWhenExpenseApprovalWorkflowIsDisabledInAgentSetup()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report cannot be posted if Status is not Open when Expense Approval Workflow is disabled in Agent Setup.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Change Status in Expense Report.
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Pending Approval";
        ExpenseReportHeader.Modify();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be posted if Status is not Open when Expense Approval Workflow is disabled in Agent Setup.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCannotBeReleasedIfStatusIsNotOpenWhenExpenseApprovalWorkflowIsDisabledInAgentSetup()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report cannot be released if Status is not Open when Expense Approval Workflow is disabled in Agent Setup.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Change Status in Expense Report.
        ExpenseReportHeader.Status := ExpenseReportHeader.Status::"Pending Approval";
        ExpenseReportHeader.Modify();

        // [WHEN] Release Expense Report.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that Expense Report cannot be released if Status is not Open when Expense Approval Workflow is disabled in Agent Setup.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCanBePendingApprovalIfStatusIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report can be Pending Approval if Status is Released.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that Expense Report is Released.
        Assert.AreEqual(
            ExpenseReportHeader.Status::Released,
            ExpenseReportHeader.Status,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption(Status), ExpenseReportHeader.Status::Released, ExpenseReportHeader.TableCaption()));

        // [WHEN] Set Expense Report to Pending Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [THEN] Verify that Expense Report is Pending Approval.
        Assert.AreEqual(
            ExpenseReportHeader.Status::"Pending Approval",
            ExpenseReportHeader.Status,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption(Status), ExpenseReportHeader.Status::"Pending Approval", ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCanBePendingApprovalOnlyIfStatusIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report can be Pending Approval only if Status is Released.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [WHEN] Set Expense Report to Pending Approval.
        asserterror ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [THEN] Verify that Expense Report cannot be set to Pending Approval if Status is not Released.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::Released));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCannotBeApprovedAndRejectedIfStatusIsNotPendingApproval()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report cannot be Approved and Rejected if Status is not Pending Approval.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Save Expense Report.
        Commit();

        // [WHEN] Set Expense Report to Approved.
        asserterror ExpenseReportHeader.PerformManualApproved(ExpenseUser."No.");

        // [THEN] Verify that Expense Report cannot be set to Approved if Status is not Pending Approval.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));

        // [WHEN] Set Expense Report to Rejected.
        asserterror ExpenseReportHeader.PerformManualRejected(ExpenseUser."No.", '');

        // [THEN] Verify that Expense Report cannot be set to Rejected if Status is not Pending Approval.
        Assert.ExpectedTestFieldError(ExpenseReportHeader.FieldCaption(Status), Format(ExpenseReportHeader.Status::"Pending Approval"));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCanBeApprovedIfStatusIsPendingApproval()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report can be Approved if Status is Pending Approval.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense Report to Pending Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Set Expense Report to Approved.
        ExpenseReportHeader.PerformManualApproved(ExpenseUser."No.");

        // [THEN] Verify that Expense Report is Approved.
        Assert.AreEqual(
            ExpenseReportHeader.Status::"Approved",
            ExpenseReportHeader.Status,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption(Status), ExpenseReportHeader.Status::"Approved", ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCanBeRejectedIfStatusIsPendingApproval()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report can be Rejected if Status is Pending Approval.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense Report to Pending Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Set Expense Report to Rejected.
        ExpenseReportHeader.PerformManualRejected(ExpenseUser."No.", '');

        // [THEN] Verify that Expense Report is Rejected.
        Assert.AreEqual(
            ExpenseReportHeader.Status::"Rejected",
            ExpenseReportHeader.Status,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportHeader.FieldCaption(Status), ExpenseReportHeader.Status::"Rejected", ExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportCanBePostedIfStatusIsApprovedWhenExpenseApprovalWorkflowIsEnabledInAgentSetup()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        Currency: Record Currency;
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        EmployeePostingGroup: Record "Employee Posting Group";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 580816] Verify that Expense Report can be posted if Status is Approved when Expense Approval Workflow is enabled in Agent Setup.
        Initialize();

        // [GIVEN] Enable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(true);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, CurrencyCode, Amount);

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

        // [GIVEN] Get Expense Posting Group.
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Set User Id For Approvals on Expense User.
        ExpenseUser.Get(Expense."Expense User No.");
        ExpenseUser.Validate("User Id For Approvals", CurrentUserSetup."User ID");
        ExpenseUser.Modify();

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense Report to Pending Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Set Expense Report to Approved.
        ExpenseReportHeader.PerformManualApproved(ExpenseUser."No.");

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted. 
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsEmployeePaidWithAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Employee Paid with Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, AmountReduction, Amount);

        // [GIVEN] Create Expense Report and Attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [WHEN] Release and Post Expense Report.
        ReleaseAndPostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Employee Paid with Amount Reduction.
        VerifyPostedExpenseReport(Expense, ExpenseUser, Amount, AmountReduction, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsCompanyPaidWithZeroAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Company Paid with Zero Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Company Paid with Zero Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntryForPostedExpenseReport(PostedExpenseReportHeader, Expense, 2, -ExpectedAmountLCY, ExpectedAmountLCY, 0, 0, -Amount, Amount, 0, 0);

        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", Amount, ExpectedAmountLCY);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 0, 1);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsCompanyPaidWithAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: Decimal;
        ExpectedAmountReductionLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Company Paid with Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected "Amount (LCY)", "Amount Reduction (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");
        ExpectedAmountReductionLCY := Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, AmountReduction, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Company Paid with Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntryForPostedExpenseReport(
            PostedExpenseReportHeader, Expense, 4, -ExpectedAmountLCY, ExpectedAmountLCY, ExpectedAmountReductionLCY,
            -ExpectedAmountReductionLCY, -(Amount - AmountReduction), Amount - AmountReduction, AmountReduction, -AmountReduction);

        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense, Amount - AmountReduction, ExpectedAmountLCY, ExpectedAmountReductionLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsCreditCardWithZeroAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Credit Card with Zero Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Credit Card", true, CurrencyCode, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Credit Card with Zero Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetExpensePayableCardPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), -ExpectedAmountLCY, -Amount);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY, Amount);

        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", Amount, ExpectedAmountLCY);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 0);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 0, 1);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsCreditCardWithAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: Decimal;
        ExpectedAmountReductionLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Credit Card with Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected "Amount (LCY)", "Amount Reduction (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");
        ExpectedAmountReductionLCY := Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Credit Card", true, CurrencyCode, AmountReduction, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Credit Card with Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetExpensePayableCardPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), -ExpectedAmountLCY, -(Amount - AmountReduction));
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY, Amount - AmountReduction);

        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense, Amount - AmountReduction, ExpectedAmountLCY, ExpectedAmountReductionLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsFalseAndTypeIsCreditCardWithoutAmountReduction()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        ExpenseUser: Record "Expense User";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616218] Verify that Expense Report is posted when Refundable is false and "Reimbursement Type" is Credit Card without Amount Reduction.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Payment Method.
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is false and "Reimbursement Type" is Credit Card without Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntryForPostedExpenseReport(PostedExpenseReportHeader, Expense, 2, 0, 0, ExpectedAmountLCY, -ExpectedAmountLCY, 0, 0, Amount, -Amount);
        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense, -Amount, -ExpectedAmountLCY, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportCannotBePostedWithoutJobTaskNoInExpenseReportLine()
    var
        Expense: Record Expense;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613723] Verify that Expense Report cannot be posted without "Job Task No." in Expense Report Line.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode, 0, Amount);

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [GIVEN] Get Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);

        // [GIVEN] Update "Job Task No." in Expense Report Line.
        ExpenseReportLine."Job Task No." := '';
        ExpenseReportLine.Modify();

        // [WHEN] Release Expense Report.
        asserterror ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify that Expense Report cannot be posted without "Job Task No." in Expense Report Line.
        Assert.ExpectedTestFieldError(ExpenseReportLine.FieldCaption("Job Task No."), '');
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeIsEmployeePaidWithAmountReductionForJob()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613723] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Employee Paid with Amount Reduction for Job and Job Task.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, AmountReduction, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is Employee Paid with Amount Reduction for Job.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyJobLedgerEntry(
            PostedExpenseReportHeader,
            PostedExpenseReportLine,
            GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"),
            Amount - AmountReduction,
            ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeNotIsEmployeePaidWithZeroAmountReductionForJob()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        ExpectedAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 613723] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is not Employee Paid with Zero Amount Reduction for Job and Job Task.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Generate Expected "Amount (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Job Ledger Entry is created when Refundable is true and "Reimbursement Type" is not Employee Paid with Zero Amount Reduction.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntryForPostedExpenseReport(PostedExpenseReportHeader, Expense, 2, -ExpectedAmountLCY, ExpectedAmountLCY, 0, 0, -Amount, Amount, 0, 0);

        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", Amount, ExpectedAmountLCY);
        VerifyJobLedgerEntry(
            PostedExpenseReportHeader,
            PostedExpenseReportLine,
            GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"),
            Amount,
            ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsTrueAndTypeNotIsEmployeePaidWithAmountReductionForJob()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: Decimal;
        ExpectedAmountReductionLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 613723] Verify that Expense Report is posted when Refundable is true and "Reimbursement Type" is not Employee Paid with Amount Reduction for Job and Job Task.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected "Amount (LCY)", "Amount Reduction (LCY)".
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");
        ExpectedAmountReductionLCY := Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, AmountReduction, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Job Ledger Entry is created when Refundable is true and "Reimbursement Type" is not Employee Paid with Amount Reduction for Job and Job Task.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyGLEntryForPostedExpenseReport(
            PostedExpenseReportHeader, Expense, 4, -ExpectedAmountLCY, ExpectedAmountLCY, ExpectedAmountReductionLCY,
            -ExpectedAmountReductionLCY, -(Amount - AmountReduction), Amount - AmountReduction, AmountReduction, -AmountReduction);

        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense, Amount - AmountReduction, ExpectedAmountLCY, ExpectedAmountReductionLCY);
        VerifyJobLedgerEntry(
            PostedExpenseReportHeader,
            PostedExpenseReportLine,
            GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"),
            Amount - AmountReduction,
            ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportIsPostedWhenRefundableIsFalseAndTypeNotIsEmployeePaidWithoutAmountReductionForJob()
    var
        Expense: Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 613723] Verify that Expense Report is posted when Refundable is false and "Reimbursement Type" is not Employee Paid without Amount Reduction for Job and Job Task.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Job Ledger Entry is not created when Refundable is false and "Reimbursement Type" is not Employee Paid without Amount Reduction for Job and Job Task.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyRecordCountOfJobLedgerEntry(PostedExpenseReportHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CommentsCopiedFromExpenseReportToPostedExpenseReport()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CommentText: Text[80];
    begin
        // [SCENARIO 614678] Verify that comments are copied from Expense Report to Posted Expense Report when Expense Report is posted.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Create comment for expense report header.
        CommentText := CreateCommentForExpenseReportHeader(ExpenseReportHeader."No.");

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Posted Expense Report is created.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);

        // [THEN] Verify comments are copied to Posted Expense Report.
        PostedExpenseReportCommentLine.SetRange("Document Type", PostedExpenseReportCommentLine."Document Type"::"Posted Expense Report");
        PostedExpenseReportCommentLine.SetRange("No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportCommentLine.SetRange("Document Line No.", 0);
        PostedExpenseReportCommentLine.FindFirst();
        Assert.AreEqual(
            CommentText,
            PostedExpenseReportCommentLine.Comment,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportCommentLine.FieldCaption(Comment), CommentText, PostedExpenseReportCommentLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure MultipleCommentsCopiedFromExpenseReportToPostedExpenseReport()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportCommentLine: Record "Expense Report Comment Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CommentText: array[4] of Text[80];
    begin
        // [SCENARIO 614678] Verify that multiple comments are copied from Expense Report to Posted Expense Report when Expense Report is posted.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Create multiple comment for expense report header.
        CommentText[1] := CreateCommentForExpenseReportHeader(ExpenseReportHeader."No.");
        CommentText[2] := CreateCommentForExpenseReportHeader(ExpenseReportHeader."No.");

        // [GIVEN] Create comment for expense report line.
        CommentText[3] := CreateRandomExpenseReportLineComment(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");
        CommentText[4] := CreateRandomExpenseReportLineComment(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Posted Expense Report is created.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);

        // [THEN] Verify comments are copied to Posted Expense Report.
        PostedExpenseReportCommentLine.SetRange("Document Type", PostedExpenseReportCommentLine."Document Type"::"Posted Expense Report");
        PostedExpenseReportCommentLine.SetRange("No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportCommentLine.SetRange("Document Line No.", 0);
        Assert.RecordCount(PostedExpenseReportCommentLine, 2);

        PostedExpenseReportCommentLine.FindFirst();
        Assert.AreEqual(
            CommentText[1],
            PostedExpenseReportCommentLine.Comment,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportCommentLine.FieldCaption(Comment), CommentText[1], PostedExpenseReportCommentLine.TableCaption()));

        PostedExpenseReportCommentLine.Next();
        Assert.AreEqual(
            CommentText[2],
            PostedExpenseReportCommentLine.Comment,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportCommentLine.FieldCaption(Comment), CommentText[2], PostedExpenseReportCommentLine.TableCaption()));

        // [THEN] Verify comments are copied to Posted Expense Report Line.
        PostedExpenseReportCommentLine.SetRange("Document Type", PostedExpenseReportCommentLine."Document Type"::"Posted Expense Report");
        PostedExpenseReportCommentLine.SetRange("No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportCommentLine.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(PostedExpenseReportCommentLine, 2);

        PostedExpenseReportCommentLine.FindFirst();
        Assert.AreEqual(
            CommentText[3],
            PostedExpenseReportCommentLine.Comment,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportCommentLine.FieldCaption(Comment), CommentText[3], PostedExpenseReportCommentLine.TableCaption()));

        PostedExpenseReportCommentLine.Next();
        Assert.AreEqual(
            CommentText[4],
            PostedExpenseReportCommentLine.Comment,
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportCommentLine.FieldCaption(Comment), CommentText[4], PostedExpenseReportCommentLine.TableCaption()));

        // [THEN] Verify comments are deleted from Expense Report.
        PostedExpenseReportCommentLine.Reset();
        PostedExpenseReportCommentLine.SetRange("No.", ExpenseReportHeader."No.");
        Assert.RecordCount(PostedExpenseReportCommentLine, 0);

        // [THEN] Verify comments are copied from Expense Report to Posted Expense Report.
        PostedExpenseReportCommentLine.Reset();
        PostedExpenseReportCommentLine.SetRange("No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(PostedExpenseReportCommentLine, 4);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseUpdatedWithPostedExpenseReportNoWhenExpenseReportIsPosted()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 614678] Verify that "Posted Expense Report No." is updated in Expense when Expense Report is posted.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create Expense.
        CreateAndReleaseExpense(Expense, ExpenseCategory, ExpenseUser);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Verify Expense has no Posted Expense Report No.
        Assert.AreEqual(
            '',
            Expense."Posted Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Posted Expense Report No."), '', Expense.TableCaption()));

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense into Report.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Posted Expense Report is created.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);

        // [THEN] Verify Expense is updated with Posted Expense Report No.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            PostedExpenseReportHeader."No.",
            Expense."Posted Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Posted Expense Report No."), PostedExpenseReportHeader."No.", Expense.TableCaption()));
    end;

    [Test]
    procedure CommentsDeletedWhenExpenseReportLineIsDeleted()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        CommentText: Text[80];
    begin
        // [SCENARIO 614678] Verify that comments are deleted when Expense Report Line is deleted.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Create comment for expense report line.
        CommentText := CreateRandomExpenseReportLineComment(ExpenseReportHeader."No.", ExpenseReportLine."Line No.");

        // [THEN] Verify comment exists.
        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Expense Report");
        ExpenseReportCommentLine.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportCommentLine, 1);

        // [WHEN] Delete Expense Report Line.
        ExpenseReportLine.Delete(true);

        // [THEN] Verify comments are deleted.
        ExpenseReportCommentLine.SetRange("Document Type", ExpenseReportCommentLine."Document Type"::"Expense Report");
        ExpenseReportCommentLine.SetRange("No.", ExpenseReportHeader."No.");
        ExpenseReportCommentLine.SetRange("Document Line No.", ExpenseReportLine."Line No.");
        Assert.RecordCount(ExpenseReportCommentLine, 0);
    end;

    [Test]
    procedure CommentsDeletedWhenExpenseReportHeaderIsDeleted()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        CommentText: Text[80];
    begin
        // [SCENARIO 614678] Verify that comments are deleted when Expense Report Header is deleted.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Create comment for expense report header.
        CommentText := CreateCommentForExpenseReportHeader(ExpenseReportHeader."No.");

        // [THEN] Verify comment exists.
        ExpenseReportCommentLine.SetRange("No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportCommentLine, 1);

        // [WHEN] Delete Expense Report Header.
        ExpenseReportHeader.Delete(true);

        // [THEN] Verify comments are deleted.
        ExpenseReportCommentLine.SetRange("No.", ExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseReportCommentLine, 0);
    end;

    [Test]
    procedure AmountReductionLCYCalculatedCorrectlyInExpenseReportLine()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        Currency: Record Currency;
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpensePaymentMethod: Record "Expense Payment Method";
        CurrencyCode: Code[10];
        OriginalAmount: Decimal;
        ReductionAmount: Decimal;
        ExpectedReductionLCY: Decimal;
    begin
        // [SCENARIO 614678] Verify that "Amount Reduction (LCY)" is calculated correctly when currency is used in Expense Report Line.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        Currency.Get(CurrencyCode);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Company Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, "Expense Reimbursement Type"::"Company Paid");

        // [GIVEN] Create Expense Report with currency.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, '');

        // [GIVEN] Create Expense Report Line with Amount Reduction.
        OriginalAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        ReductionAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [WHEN] Update line with amounts and payment method.
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine.Validate(Amount, OriginalAmount);
        ExpenseReportLine.Validate("Non-Refundable Amount", ReductionAmount);
        ExpenseReportLine.Modify();

        // [THEN] Verify Amount Reduction (LCY) is calculated correctly.
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        ExpectedReductionLCY := CurrencyExchangeRate.ExchangeAmtFCYToLCY(WorkDate(), CurrencyCode, ReductionAmount, ExpenseReportLine."Expense Currency Factor");
        Assert.AreNearlyEqual(
            ExpectedReductionLCY,
            ExpenseReportLine."Non-Refundable Amount (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Non-Refundable Amount (LCY)"), ExpectedReductionLCY, ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure GetTotalRefundableAmountLCYCalculatedCorrectlyInPostedExpenseReportHeader()
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: array[3] of Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RefundableAmount1, RefundableAmount2, ReductionAmount1, ExpectedTotal : Decimal;
    begin
        // [SCENARIO 614678] Verify that GetTotalRefundableAmountLCY calculates correctly for Posted Expense Report Header.
        Initialize();

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        ExpenseCategory.Validate(Refundable, true);
        ExpenseCategory.Modify();

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create first refundable Expense Report Line.
        RefundableAmount1 := LibraryRandom.RandDecInRange(100, 200, 2);
        ReductionAmount1 := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine[1], ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine[1]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        ExpenseReportLine[1].Validate(Refundable, true);
        ExpenseReportLine[1].Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine[1].Validate(Amount, RefundableAmount1);
        ExpenseReportLine[1].Validate("Non-Refundable Amount", ReductionAmount1);
        ExpenseReportLine[1].Modify();

        // [GIVEN] Create second refundable Expense Report Line.
        RefundableAmount2 := LibraryRandom.RandDecInRange(150, 250, 2);
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine[2], ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine[2]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        ExpenseReportLine[2].Validate(Refundable, true);
        ExpenseReportLine[2].Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine[2].Validate(Amount, RefundableAmount2);
        ExpenseReportLine[2].Modify();

        // [GIVEN] Create non-refundable Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine[3], ExpenseReportHeader, ExpenseCategory.Code, false, '',
            ExpenseReportLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        ExpenseReportLine[3].Validate(Refundable, false);
        ExpenseReportLine[3].Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine[3].Validate("Reimbursement Type", ExpenseCategory."Reimbursement Type"::"Company Paid");
        ExpenseReportLine[3].Validate(Amount, LibraryRandom.RandDecInRange(50, 100, 2));
        ExpenseReportLine[3].Modify();

        // [GIVEN] Calculate expected total refundable amount (LCY).
        ExpectedTotal := (RefundableAmount1 - ReductionAmount1) + RefundableAmount2;

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Posted Expense Report is created.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);
        PostedExpenseReportHeader.CalcFields("Refundable Amount (LCY)");
        Assert.AreEqual(
            ExpectedTotal,
            PostedExpenseReportHeader."Refundable Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, 'GetTotalRefundableAmountLCY', ExpectedTotal, PostedExpenseReportHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportAttachmentMustFlowToPostedExpenseReport()
    var
        Expense: Record Expense;
        DocumentAttachment: array[2] of Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Expense Report Attachment must flow to Posted Expense Report.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment[1], CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense with Attachment.
        CreateAndAttachExpenseToExpenseReportWithAttachment(ExpenseReportHeader, DocumentAttachment[2], ExpenseReportLine, Expense);

        // [THEN] Verify Document Attachment exists in Expense and Expense Report Line.
        VerifyAttachmentExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Expense Report Page.
        VerifyAttachmentInExpenseReportPage(ExpenseReportHeader, ExpenseReportLine, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Document Attachment exists in Expense and Posted Expense Report Line.
        Expense.Get(Expense."No.");
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyAttachmentPostedExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Posted Expense Report Page.
        VerifyAttachmentInPostedExpenseReport(PostedExpenseReportHeader, ExpenseReportLine, Expense);

        // [THEN] Verify Document Attachment exists for Expense and not exist for Expense Report Line.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportAttachmentMustFlowToPostedExpenseReportWithMultiLines()
    var
        Expense: Record Expense;
        DocumentAttachment: array[2] of Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Expense Report Attachment must flow to Posted Expense Report with Multiple Lines.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment[1], CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense with Attachment in new Expense Report Line.
        CreateAndAttachExpenseToExpenseReportWithAttachmentInNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, DocumentAttachment[2], Expense);

        // [THEN] Verify Document Attachment exists in Expense and Expense Report Line.
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        VerifyAttachmentExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment[2].ID);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Expense Report Page.
        VerifyAttachmentInExpenseReportPageWithNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Document Attachment exists in Expense and Posted Expense Report Line.
        Expense.Get(Expense."No.");
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLine.SetRange("Expense No.", '');
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment[2].ID);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Posted Expense Report Page.
        VerifyAttachmentInPostedExpenseReportPageWithNewExpenseReportLine(PostedExpenseReportHeader, ExpenseReportLine, Expense);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportAttachmentIsDeletedWhenExpenseReportIsDeleted()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Expense Report Attachment is deleted when Expense Report is deleted.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment, CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense with Attachment in new Expense Report Line.
        CreateAndAttachExpenseToExpenseReportWithAttachmentInNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, DocumentAttachment, Expense);

        // [THEN] Verify Document Attachment exists for Expense and Expense Report Line.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 3);

        // [WHEN] Delete Expense Report.
        ExpenseReportHeader.Delete(true);

        // [THEN] Verify Document Attachment exists for Expense and not exist for Expense Report Line.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportAttachmentIsDeletedWhenExpenseReportLinesAreDeleted()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Expense Report Attachment is deleted when Expense Report Lines are deleted.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment, CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense with Attachment in new Expense Report Line.
        CreateAndAttachExpenseToExpenseReportWithAttachmentInNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, DocumentAttachment, Expense);

        // [THEN] Verify Document Attachment exists for Expense and Expense Report Line.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 3);

        // [WHEN] Delete Expense Report.
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.DeleteAll(true);

        // [THEN] Verify Document Attachment exists for Expense.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 1);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure ExpenseReportAttachmentCannotBeDeletedIfItIsPartOfExpense()
    var
        Expense: Record Expense;
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Expense Report Attachment cannot be deleted if it is part of an Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment, CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify Document Attachment exists for Expense and Expense Report Line.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 2);

        // [GIVEN] Save a transaction.
        Commit();

        // [WHEN] Delete Expense Attachment.
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetRange("Table ID", Database::Expense);
        DocumentAttachment.SetRange("No.", Expense."No.");
        DocumentAttachment.FindFirst();
        asserterror DocumentAttachment.Delete(true);

        // [THEN] Verify Document Attachment cannot be deleted error.
        Assert.ExpectedError(
            StrSubstNo(
                CannotUpdateAndDeleteAttachmentOnExpenseErr,
                ExpenseReportLine.FieldCaption("Expense No."),
                Expense."No.",
                Expense.FieldCaption("Expense Report No."),
                ExpenseReportHeader."No."));

        // [WHEN] Delete Expense Report Attachment.
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetRange("Table ID", Database::"Expense Report Line");
        DocumentAttachment.SetRange("No.", ExpenseReportHeader."No.");
        DocumentAttachment.FindFirst();
        asserterror DocumentAttachment.Delete(true);

        // [THEN] Verify Document Attachment cannot be deleted error on expense report line.
        Assert.ExpectedError(
            StrSubstNo(
                CannotUpdateAndDeleteAttachmentOnExpenseReportErr,
                Expense.FieldCaption("Expense Report No."), ExpenseReportLine."Document No.", ExpenseReportLine.FieldCaption("Line No."), ExpenseReportLine."Line No.",
                ExpenseReportLine.FieldCaption("Expense No."), ExpenseReportLine."Expense No."));
    end;

    [Test]
    procedure ExpenseAttachmentCannotBeDeletedIfItExpenseIsReleased()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        DocumentAttachment: Record "Document Attachment";
        ExpenseReportLine: Record "Expense Report Line";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 618102] Verify that Expense Attachment cannot be deleted if Expense is Released.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [WHEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment, CurrencyCode, LibraryRandom.RandInt(100));

        // [THEN] Verify Document Attachment exists for Expense and Expense Report Line.
        VerifyRecordCountOfDocumentAttachment(Expense, ExpenseReportLine, 1);

        // [WHEN] Delete Expense Attachment.
        asserterror DocumentAttachment.Delete(true);

        // [THEN] Verify Document Attachment cannot be deleted error.
        Assert.ExpectedError(
            StrSubstNo(
                CannotUpdateAndDeleteAttachmentIfOpenStatusErr,
                ExpenseReportLine.FieldCaption("Expense No."), Expense."No.", Expense.FieldCaption(Status)));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure ExpenseReportAttachmentMustFlowToPostedExpenseReportWithMultipleLinesWhenAttachmentIsUpdatedFromExpReportForExpense()
    var
        Expense: Record Expense;
        DocumentAttachment: array[2] of Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 617011] Verify that Expense Report Attachment must flow to Posted Expense Report with Multiple Lines when Attachment is Updated from Expense Report for Expense.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment[1], CurrencyCode, LibraryRandom.RandInt(100));

        // [WHEN] Create Expense Report and attach Expense with Attachment in new Expense Report Line.
        CreateAndAttachExpenseToExpenseReportWithAttachmentInNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, DocumentAttachment[2], Expense);

        // [THEN] Verify Document Attachment exists in Expense and Expense Report Line.
        Expense.Get(Expense."No.");
        ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");
        Assert.AreEqual(
            true,
            Expense."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Receipt Attached"), true, Expense.TableCaption()));
        Assert.AreEqual(
            DocumentAttachment[1].ID,
            Expense."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), DocumentAttachment[1].ID, ExpenseReportLine.TableCaption()));
        VerifyAttachmentExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);
        VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine, true, DocumentAttachment[2].ID);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Expense Report Page.
        VerifyAttachmentInExpenseReportPageWithNewExpenseReportLine(ExpenseReportHeader, ExpenseReportLine, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Document Attachment exists in Expense and Posted Expense Report Line.
        Expense.Get(Expense."No.");
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        PostedExpenseReportLine.SetRange("Expense No.", '');
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense."Expense User No.");
        VerifyAttachmentPostedExpenseReportLineFromExpense(Expense, DocumentAttachment[1], true);
        VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine, true, DocumentAttachment[2].ID);

        // [THEN] Verify Document Attachment is linked in Attached Documents List on Posted Expense Report Page.
        VerifyAttachmentInPostedExpenseReportPageWithNewExpenseReportLine(PostedExpenseReportHeader, ExpenseReportLine, Expense);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure AttachmentCannotBeDeletedFromPostedExpenseReport()
    var
        Expense: Record Expense;
        DocumentAttachment: array[2] of Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Attachment cannot be deleted from Posted Expense Report.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment[1], CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Create Expense Report and attach Expense with Attachment.
        CreateAndAttachExpenseToExpenseReportWithAttachment(ExpenseReportHeader, DocumentAttachment[2], ExpenseReportLine, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [WHEN] Delete Posted Expense Report Attachment.
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense."Expense User No.");
        DocumentAttachment[1].SetRange("Document Type", DocumentAttachment[1]."Document Type"::Expense);
        DocumentAttachment[1].SetRange("Table ID", Database::"Posted Expense Report Line");
        DocumentAttachment[1].SetRange("No.", PostedExpenseReportLine."Document No.");
        DocumentAttachment[1].FindFirst();
        asserterror DocumentAttachment[1].Delete(true);

        // [THEN] Verify Document Attachment cannot be deleted from Posted Expense Report.
        Assert.ExpectedError(
            StrSubstNo(
                CannotImportAndDeleteAttachmentOnPostedExpenseReportErr,
                Expense.FieldCaption("Posted Expense Report No."),
                PostedExpenseReportLine."Document No.",
                PostedExpenseReportLine.FieldCaption("Line No."),
                PostedExpenseReportLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure AttachmentCannotBeInsertedFromPostedExpenseReport()
    var
        Expense: Record Expense;
        DocumentAttachment: array[3] of Record "Document Attachment";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        RecRef: RecordRef;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 613390] Verify that Attachment cannot be inserted from Posted Expense Report.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Release Expense with Attachment.
        CreateAndReleaseExpenseWithAttachment(Expense, DocumentAttachment[1], CurrencyCode, LibraryRandom.RandInt(100));

        // [GIVEN] Create Expense Report and attach Expense with Attachment.
        CreateAndAttachExpenseToExpenseReportWithAttachment(ExpenseReportHeader, DocumentAttachment[2], ExpenseReportLine, Expense);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [WHEN] Insert Attachment to Posted Expense Report.
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense."Expense User No.");
        RecRef.GetTable(PostedExpenseReportLine);
        asserterror CreateDocumentAttachment(DocumentAttachment[3], RecRef, PostedExpenseReportLine."Document No." + JPEGLbl);

        // [THEN] Verify Document Attachment cannot be inserted from Posted Expense Report.
        Assert.ExpectedError(
            StrSubstNo(
                CannotImportAndDeleteAttachmentOnPostedExpenseReportErr,
                Expense.FieldCaption("Posted Expense Report No."),
                PostedExpenseReportLine."Document No.",
                PostedExpenseReportLine.FieldCaption("Line No."),
                PostedExpenseReportLine."Line No."));
    end;

    // This test is currently disabled via DisabledTests/Expense_Agent_Tests/Expense_Agent_Tests.DisabledTest.json because the foreign-currency Source Currency Amount rounding on the balancing G/L entry differs under non-W1 localizations (AT/DE/DK/ES/FR).
    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithCurrencyOnHeaderAndExchangeRateForExpensesIsExpenseDate()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580546] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Expense Date.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        CalculateExpectedValuesForFCYOnHeader(
            Amount, AmountReduction, CurrencyCode, WorkDate() + 2,
            ExpectedAmount, ExpectedAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, Amount, AmountReduction);

        // [WHEN] Create and Release Expense Report.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, Expense[1]."VAT Bus. Posting Group");
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Refundable Amount in Expense Report Line.
        VerifyRefundableAmountInExpenseReportLine(Expense, ExpectedAmount, ExpectedAmountLCY);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntryForFCYPostedExpenseReport(
            PostedExpenseReportHeader, Expense, 8, Amount, AmountReduction, ExpectedAmount, ExpectedAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [THEN] Verify Refundable Amount in Posted Expense Report Line.
        VerifyRefundableAmountInPostedExpenseReportLine(Expense, ExpectedAmount, ExpectedAmountLCY);
    end;

    // This test is currently disabled via DisabledTests/Expense_Agent_Tests/Expense_Agent_Tests.DisabledTest.json because the foreign-currency Source Currency Amount rounding on the balancing G/L entry differs under non-W1 localizations (AT/DE/DK/ES/FR).
    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithCurrencyOnHeaderAndExchangeRateForExpensesIsPostingDate()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580546] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Posting Date.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Posting Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        CalculateExpectedValuesForFCYOnHeader(
            Amount, AmountReduction, CurrencyCode, WorkDate() + 2,
            ExpectedAmount, ExpectedAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, Amount, AmountReduction);

        // [WHEN] Create and Release Expense Report.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, Expense[1]."VAT Bus. Posting Group");
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Refundable Amount in Expense Report Line.
        VerifyRefundableAmountInExpenseReportLine(Expense, ExpectedAmount, ExpectedAmountLCY);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntryForFCYPostedExpenseReport(
            PostedExpenseReportHeader, Expense, 8, Amount, AmountReduction, ExpectedAmount, ExpectedAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [THEN] Verify Refundable Amount in Posted Expense Report Line.
        VerifyRefundableAmountInPostedExpenseReportLine(Expense, ExpectedAmount, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDate()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: array[4] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        RoundingDebitAccountAmountLCY: Decimal;
        RoundingCreditAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580546] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        CalculateExpectedValuesForLCYOnHeaderForExpenseDateOnSetup(
            Amount, AmountReduction, CurrencyCode, WorkDate(),
            ExpectedAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        RoundingDebitAccountAmountLCY :=
            Abs(ExpectedAmountLCY[1] - Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision")) +
            Abs(ExpectedAmountLCY[3] - Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision"));

        RoundingCreditAccountAmountLCY +=
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2)) -
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision") +
            -ExpectedAmountLCY[4] - Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, JobTask, ExpensePaymentMethod, ExpenseUser, CurrencyCode, '', AmountReduction, Amount);

        // [WHEN] Create and Release Expense Report.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Refundable Amount in Expense Report Line.
        VerifyRefundableAmountInExpenseReportLine(Expense, ExpectedAmountLCY, ExpectedAmountLCY);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntryForLCYPostedExpenseReport(
            PostedExpenseReportHeader, Expense, ExpectedAmountLCY, ExpectedAmountLCY, 12, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetCreditRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingCreditAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetDebitRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingDebitAccountAmountLCY);

        // [THEN] Verify Refundable Amount in Posted Expense Report Line.
        VerifyRefundableAmountInPostedExpenseReportLine(Expense, ExpectedAmountLCY, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDate()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: array[4] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580546] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Posting Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        CalculateExpectedValuesForLCYOnHeader(
            Amount, AmountReduction, CurrencyCode, WorkDate() + 2,
            ExpectedAmountLCY, PaymentMethodAccAmtLCY, RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, JobTask, ExpensePaymentMethod, ExpenseUser, CurrencyCode, '', AmountReduction, Amount);

        // [WHEN] Create and Release Expense Report.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");
        ExpenseReportHeader.PerformManualRelease();

        // [THEN] Verify Refundable Amount in Expense Report Line.
        VerifyRefundableAmountInExpenseReportLine(Expense, ExpectedAmountLCY, ExpectedAmountLCY);

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntryForLCYPostedExpenseReport(
            PostedExpenseReportHeader, Expense, ExpectedAmountLCY, ExpectedAmountLCY, 8, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        // [THEN] Verify Refundable Amount in Posted Expense Report Line.
        VerifyRefundableAmountInPostedExpenseReportLine(Expense, ExpectedAmountLCY, ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler')]
    procedure DifferentCurrencyCanBeSelectedInExpenseReportLineIfCurrencyIsFCYOnHeader()
    var
        Expense: Record Expense;
        PostCode: Record "Post Code";
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 580546] Verify that Expense Report is allow to select different Currency in Expense Line if Currency is FCY on Header.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", CurrencyCode, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that different Currency can be selected in Expense Report Line if Currency is FCY on Header.
        FindExpenseReportLine(ExpenseReportLine, Expense);
        Assert.AreEqual(
            '',
            ExpenseReportLine."Expense Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Currency Code"), '', ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure DifferentCurrencyCanBeSelectedInExpenseReportLineIfCurrencyIsLCYOnHeader()
    var
        Expense: array[3] of Record Expense;
        PostCode: Record "Post Code";
        JobTask: array[3] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        Amount: Decimal;
        CurrencyCode: array[2] of Code[10];
    begin
        // [SCENARIO 580546] Verify that Expense Report is allowed to select different Currency in Expense Line if Currency is LCY on Header.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[2], 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');

        // [WHEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that different Currency can be selected in Expense Report Line if Currency is LCY on Header.
        FindExpenseReportLine(ExpenseReportLine, Expense[3]);
        Assert.AreEqual(
            CurrencyCode[2],
            ExpenseReportLine."Expense Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Expense Currency Code"), CurrencyCode[2], ExpenseReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithCurrencyOnHeaderAndExchangeRateForExpensesIsExpenseDateWithVAT()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        VATBaseAmount: array[4] of Decimal;
        VATBaseAmountLCY: array[4] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[2] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Expense Date with VAT.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmount[1] := Amount;
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[2] := Amount;
        ExpectedAmountLCY[2] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[3] := Amount - AmountReduction;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[4] := -Amount;
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[2] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[2], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];

        PaymentMethodAccAmtLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[1] +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
           -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup, CurrencyCode, AmountReduction, Amount);

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Expense Date with VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 10, 2, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader, ExpectedAmount[1] - VATAmount[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[1] - VATAmountLCY[1], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader, ExpectedAmount[2] - VATAmount[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[2] - VATAmountLCY[2], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[3], PostedExpenseReportHeader, ExpectedAmount[3], ExpectedAmountLCY[3],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[3], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmount[4], ExpectedAmountLCY[4]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithCurrencyOnHeaderAndExchangeRateForExpensesIsPostingDateWithVAT()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        VATBaseAmount: array[4] of Decimal;
        VATBaseAmountLCY: array[4] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[2] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Posting Date with VAT.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Posting Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmount[1] := Amount;
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[2] := Amount;
        ExpectedAmountLCY[2] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[3] := Amount - AmountReduction;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmount[4] := -Amount;
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[2] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[2], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];

        PaymentMethodAccAmtLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[1] +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
           -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup, CurrencyCode, AmountReduction, Amount);

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, VATPostingSetup[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with Currency on Header and Exchange Rate for Expenses is Posting Date with VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 10, 2, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader, ExpectedAmount[1] - VATAmount[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[1] - VATAmountLCY[1], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader, ExpectedAmount[2] - VATAmount[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[2] - VATAmountLCY[2], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[3], PostedExpenseReportHeader, ExpectedAmount[3], ExpectedAmountLCY[3],
            Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[3], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision"),
            ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmount[4], ExpectedAmountLCY[4]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithVAT()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: array[4] of Record "Job Task";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        VATBaseAmount: array[4] of Decimal;
        VATBaseAmountLCY: array[4] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[2] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date with VAT.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Posting Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[2] := VATBaseAmount[2];

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[1] +
            Amount - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], VATPostingSetup[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, true, CurrencyCode, 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date with VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 10, 2, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader,
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader,
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);

        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 4);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithVAT()
    var
        Expense: array[4] of Record Expense;
        Currency: Record Currency;
        JobTask: array[4] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        VATBaseAmount: array[4] of Decimal;
        VATBaseAmountLCY: array[4] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[2] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        RoundingDebitAccountAmountLCY: Decimal;
        RoundingCreditAccountAmountLCY: Decimal;
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date with VAT.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        VATBaseAmountLCY[2] := VATBaseAmount[2];

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") - VATAmountLCY[1] +
            Amount - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");

        RoundingDebitAccountAmountLCY :=
            Abs(ExpectedAmountLCY[1] - Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision")) +
            Abs(Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 2))) -
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision") +
            -ExpectedAmountLCY[4] - Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision");

        RoundingCreditAccountAmountLCY :=
            -(ExpectedAmountLCY[3] - Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision"));

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], VATPostingSetup[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, true, CurrencyCode, 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date With VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetCreditRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingCreditAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetDebitRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingDebitAccountAmountLCY);

        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 14, 2, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader,
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader,
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithVATAndDifferentCurrency()
    var
        Expense: array[5] of Record Expense;
        Currency: array[2] of Record Currency;
        JobTask: array[5] of Record "Job Task";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[5] of Decimal;
        VATBaseAmount: array[5] of Decimal;
        VATBaseAmountLCY: array[5] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[5] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: array[2] of Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date with VAT and Different Currency.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Posting Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create another Currency with different Exchange Rate.
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency[1].Get(CurrencyCode[1]);
        Currency[2].Get(CurrencyCode[2]);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[5] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency[1]."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency[1]."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        VATBaseAmountLCY[2] := VATBaseAmount[2];
        VATBaseAmount[5] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency[2]."Amount Rounding Precision");
        VATBaseAmountLCY[5] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[5], CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];
        VATAmountLCY[5] := ExpectedAmountLCY[5] - VATBaseAmountLCY[5];

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") - VATAmountLCY[1] +
            Amount - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") - VATAmountLCY[5];
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], VATPostingSetup[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, true, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[5], ExpenseUser, ExpensePaymentMethod, JobTask[5], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode[2], 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[5]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[5], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date with VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 12, 3, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader,
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader,
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[5], PostedExpenseReportHeader,
            ExpectedAmountLCY[5] - VATAmountLCY[5], ExpectedAmountLCY[5] - VATAmountLCY[5],
            ExpectedAmountLCY[5] - VATAmountLCY[5], ExpectedAmountLCY[5] - VATAmountLCY[5]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithVATAndDifferentCurrency()
    var
        Expense: array[5] of Record Expense;
        Currency: array[2] of Record Currency;
        JobTask: array[5] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[5] of Decimal;
        VATBaseAmount: array[5] of Decimal;
        VATBaseAmountLCY: array[5] of Decimal;
        VATAmountLCY: array[5] of Decimal;
        VATAmount: array[5] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        RoundingDebitAccountAmountLCY: Decimal;
        RoundingCreditAccountAmountLCY: Decimal;
        CalculateAmount: Decimal;
        CurrencyCode: array[2] of Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date with VAT.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Find VAT Posting Setup.
        CreateTwoVATPostingSetups(VATPostingSetup);

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 1, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 2, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDecInRange(10, 50, 2));

        // [GIVEN] Create another Currency with different Exchange Rate.
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency[1].Get(CurrencyCode[1]);
        Currency[2].Get(CurrencyCode[2]);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[5] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        VATBaseAmount[1] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency[1]."Amount Rounding Precision");
        VATBaseAmount[2] := Round((Amount) / (1 + VATPostingSetup[2]."VAT %" / 100), Currency[1]."Amount Rounding Precision");
        VATBaseAmount[5] := Round((Amount) / (1 + VATPostingSetup[1]."VAT %" / 100), Currency[2]."Amount Rounding Precision");
        VATBaseAmountLCY[1] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[1], CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        VATBaseAmountLCY[2] := VATBaseAmount[2];
        VATBaseAmountLCY[5] := Round(LibraryERM.ConvertCurrency(VATBaseAmount[5], CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        VATAmount[1] := Amount - VATBaseAmount[1];
        VATAmount[2] := Amount - VATBaseAmount[2];
        VATAmount[5] := Amount - VATBaseAmount[5];
        VATAmountLCY[1] := ExpectedAmountLCY[1] - VATBaseAmountLCY[1];
        VATAmountLCY[2] := ExpectedAmountLCY[2] - VATBaseAmountLCY[2];
        VATAmountLCY[5] := ExpectedAmountLCY[5] - VATBaseAmountLCY[5];

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") - VATAmountLCY[1] +
            Amount - VATAmountLCY[2] +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") - VATAmountLCY[5];
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate()), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate()), Currency[2]."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate()), Currency[1]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += Abs(ExpectedAmountLCY[1] - CalculateAmount);

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(ExpectedAmountLCY[3] - CalculateAmount);

        CalculateAmount := -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += Abs(Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2))) + CalculateAmount;

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += -ExpectedAmountLCY[4] - CalculateAmount;

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate()), Currency[2]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(ExpectedAmountLCY[5] - CalculateAmount);

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], VATPostingSetup[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, true, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[5], ExpenseUser, ExpensePaymentMethod, JobTask[5], VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode[2], 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[5]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Update VAT Liable in Expense Report Line from Expense.
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[1], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[2], true, LibraryPurchase.CreateVendorNo());
        UpdateVATLiableInExpenseReportLineFromExpense(Expense[5], true, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date With VAT.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);

        VerifyLedgerEntriesForPostedExpenseReportWithVAT(
            PostedExpenseReportHeader, Expense[1], 17, 3, VATAmountLCY, PaymentMethodAccAmtLCY,
            RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetCreditRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingCreditAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetDebitRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingDebitAccountAmountLCY);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader,
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1],
            ExpectedAmountLCY[1] - VATAmountLCY[1], ExpectedAmountLCY[1] - VATAmountLCY[1]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader,
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2],
            ExpectedAmountLCY[2] - VATAmountLCY[2], ExpectedAmountLCY[2] - VATAmountLCY[2]);

        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);

        VerifyExpenseAndJobLedgerEntry(
            Expense[5], PostedExpenseReportHeader,
            ExpectedAmountLCY[5] - VATAmountLCY[5], ExpectedAmountLCY[5] - VATAmountLCY[5],
            ExpectedAmountLCY[5] - VATAmountLCY[5], ExpectedAmountLCY[5] - VATAmountLCY[5]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithDifferentCurrency()
    var
        Expense: array[8] of Record Expense;
        GLEntry: Record "G/L Entry";
        Currency: array[2] of Record Currency;
        JobTask: array[8] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[8] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        RoundingDebitAccountAmountLCY: Decimal;
        RoundingCreditAccountAmountLCY: Decimal;
        CalculateAmount: Decimal;
        CurrencyCode: array[2] of Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date with different Currency.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, "Expense Exchange Rate"::"Expense Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create another Currency with different Exchange Rate.
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency[1].Get(CurrencyCode[1]);
        Currency[2].Get(CurrencyCode[2]);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[5] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[6] := Amount;
        ExpectedAmountLCY[7] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[8] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision") +
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate()), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate()), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate()), Currency[1]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += Abs(ExpectedAmountLCY[1] - CalculateAmount);

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += Abs(ExpectedAmountLCY[3] - CalculateAmount);

        CalculateAmount := -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(-Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 2)) + Abs(CalculateAmount));

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 1), Currency[1]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(CalculateAmount + ExpectedAmountLCY[4]);

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate()), Currency[2]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(ExpectedAmountLCY[5] - CalculateAmount);

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RoundingCreditAccountAmountLCY += -(ExpectedAmountLCY[7] - CalculateAmount);

        CalculateAmount := Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += Abs(Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2))) - CalculateAmount;

        CalculateAmount := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 1), Currency[2]."Amount Rounding Precision");
        RoundingDebitAccountAmountLCY += -ExpectedAmountLCY[8] - CalculateAmount;

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode[1], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[1], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[5], ExpenseUser, ExpensePaymentMethod, JobTask[5], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[6], ExpenseUser, ExpensePaymentMethod, JobTask[6], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[7], ExpenseUser, ExpensePaymentMethod, JobTask[7], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[8], ExpenseUser, ExpensePaymentMethod, JobTask[8], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode[2], 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[5]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[6]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[7]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[8]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[1]);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), PaymentMethodAccAmtLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RefundableDebitAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), EmployeePayableAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetNonRefundableDebitAccountFromExpensePostingGroup(Expense[1]."Expense Category"), NonRefundableDebitAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetCreditRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingCreditAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetDebitRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RoundingDebitAccountAmountLCY);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, 23);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[1], ExpenseUser."Employee No.", ExpectedAmountLCY[1], ExpectedAmountLCY[1]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[1], ExpectedAmountLCY[1]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[2]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[2], ExpenseUser."Employee No.", ExpectedAmountLCY[2], ExpectedAmountLCY[2]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[2], ExpectedAmountLCY[2]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[3]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[3], ExpenseUser."Employee No.", ExpectedAmountLCY[3], ExpectedAmountLCY[3]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[3], ExpectedAmountLCY[3]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[5]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[5], ExpenseUser."Employee No.", ExpectedAmountLCY[5], ExpectedAmountLCY[5]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[5], ExpectedAmountLCY[5]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[6]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[6], ExpenseUser."Employee No.", ExpectedAmountLCY[6], ExpectedAmountLCY[6]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[6], ExpectedAmountLCY[6]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[7]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[7], ExpenseUser."Employee No.", ExpectedAmountLCY[7], ExpectedAmountLCY[7]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[7], ExpectedAmountLCY[7]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[8]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[8], ExpenseUser."Employee No.", ExpectedAmountLCY[8], ExpectedAmountLCY[8]);

        VerifyRecordCountOfJobLedgerEntry(PostedExpenseReportHeader."No.", 6);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 1);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 8);

        GLEntry.SetFilter("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetFilter("Source Currency Code", '<>%1', '');
        Assert.RecordCount(GLEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithDifferentCurrency()
    var
        Expense: array[8] of Record Expense;
        GLEntry: Record "G/L Entry";
        PostCode: Record "Post Code";
        Currency: array[2] of Record Currency;
        JobTask: array[8] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmountLCY: array[8] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal;
        CurrencyCode: array[2] of Code[10];
    begin
        // [FEATURE] [AI TEST]
        // [SCENARIO 616963] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date with Different Currency.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Update Exchange Rate for Expenses to Posting Date in Expense Agent Setup.
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup."Exchange Rate for Expenses" := ExpenseAgentSetup."Exchange Rate for Expenses"::"Posting Date";
        ExpenseAgentSetup.Modify();

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode[1] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[1], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create another Currency with different Exchange Rate.
        CurrencyCode[2] := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode[2], WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency[1].Get(CurrencyCode[1]);
        Currency[2].Get(CurrencyCode[2]);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);
        AmountReduction := Amount - LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Generate Expected Amount as per Account.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision");
        ExpectedAmountLCY[5] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[6] := Amount;
        ExpectedAmountLCY[7] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        ExpectedAmountLCY[8] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[1], '', WorkDate() + 2), Currency[1]."Amount Rounding Precision") +
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode[2], '', WorkDate() + 2), Currency[2]."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode[1], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[1], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode[1], 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[5], ExpenseUser, ExpensePaymentMethod, JobTask[5], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[6], ExpenseUser, ExpensePaymentMethod, JobTask[6], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[7], ExpenseUser, ExpensePaymentMethod, JobTask[7], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode[2], AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[8], ExpenseUser, ExpensePaymentMethod, JobTask[8], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode[2], 0, Amount);

        // [GIVEN] Remove Currency Code from Job.
        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[5]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[6]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[7]."Job No.", '');
        UpdateCurrencyCodeInJob(JobTask[8]."Job No.", '');

        // [GIVEN] Create Expense Report and attach Expense.
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[1]);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), PaymentMethodAccAmtLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense[1]."Expense Category"), RefundableDebitAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), EmployeePayableAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetNonRefundableDebitAccountFromExpensePostingGroup(Expense[1]."Expense Category"), NonRefundableDebitAccountAmountLCY);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, 15);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[1], ExpenseUser."Employee No.", ExpectedAmountLCY[1], ExpectedAmountLCY[1]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[1], ExpectedAmountLCY[1]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[2]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[2], ExpenseUser."Employee No.", ExpectedAmountLCY[2], ExpectedAmountLCY[2]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[2], ExpectedAmountLCY[2]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[3]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[3], ExpenseUser."Employee No.", ExpectedAmountLCY[3], ExpectedAmountLCY[3]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[3], ExpectedAmountLCY[3]);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[4]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[4], ExpenseUser."Employee No.", ExpectedAmountLCY[4], ExpectedAmountLCY[4]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[5]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[5], ExpenseUser."Employee No.", ExpectedAmountLCY[5], ExpectedAmountLCY[5]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[5], ExpectedAmountLCY[5]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[6]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[6], ExpenseUser."Employee No.", ExpectedAmountLCY[6], ExpectedAmountLCY[6]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[6], ExpectedAmountLCY[6]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[7]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[7], ExpenseUser."Employee No.", ExpectedAmountLCY[7], ExpectedAmountLCY[7]);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedAmountLCY[7], ExpectedAmountLCY[7]);

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense[8]);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense[8], ExpenseUser."Employee No.", ExpectedAmountLCY[8], ExpectedAmountLCY[8]);

        VerifyRecordCountOfJobLedgerEntry(PostedExpenseReportHeader."No.", 6);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 1);

        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(ExpenseLedgerEntry, 8);

        GLEntry.SetFilter("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetFilter("Source Currency Code", '<>%1', '');
        Assert.RecordCount(GLEntry, 0);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,GLPostingPreviewHandler')]
    procedure PreviewPostingOfExpenseReportWhenDemoDataIsExecuted()
    var
        Expense: Record Expense;
        Employee: Record Employee;
        PostCode: Record "Post Code";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpensePostingGroup: Record "Expense Posting Group";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        Amount: Decimal;
    begin
        // [SCENARIO 616959] Verify that the Preview posting of expense report when Demo Data is executed.

        // [GIVEN] Delete Expense Payment Method.
        ExpensePaymentMethod.DeleteAll();

        // [GIVEN] Delete Expense User.
        ExpenseUser.DeleteAll();

        // [GIVEN] This test deliberately skips Initialize(), so set up employee no. series explicitly
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();

        // [GIVEN] Create Demo Data for Expense Management.
        ExpenseAgentSetup.CreateDefaultSettings();

        // [GIVEN] Create Expense Posting Group.
        LibraryExpense.CreateExpensePostingGroup(ExpensePostingGroup);

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense.
        CreateExpense(Expense, true, '', Amount);

        // [GIVEN] Update Expense Category with Expense Posting Group.
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseCategory.Validate("Posting Group", ExpensePostingGroup.Code);
        ExpenseCategory.Modify();

        // [GIVEN] Get "Expense User".
        ExpenseUser.Get(Expense."Expense User No.");

        // [GIVEN] Get "Employee".
        Employee.Get(ExpenseUser."Employee No.");

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Release Expense.
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");

        // [GIVEN] Insert Expense.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Save transaction.
        Commit();

        // [WHEN] Preview Post Expense Report.
        LibraryVariableStorage.Enqueue(2);
        asserterror ExpenseReportHeader.Preview(ExpenseReportHeader);

        // [THEN] Verify that the "G/L Entry" must be shown When Preview Posting of Expense Report through Handler.
        Assert.ExpectedError('');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CannotPostExpenseReportIfExpenseCategoryIsInactive()
    var
        Employee: Record Employee;
        PostCode: Record "Post Code";
        Customer: Record Customer;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be posted if Expense Category is inactive.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");

        // [GIVEN] Create "Expense Location".
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, true, Customer."No.",
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        ExpenseReportLine.Validate(Refundable, true);
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine.Modify();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense Category as Inactive.
        ExpenseCategory.Validate(Inactive, true);
        ExpenseCategory.Modify(true);

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that error is shown that Expense Category is inactive.
        Assert.ExpectedTestFieldError(ExpenseCategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CannotPostExpenseReportIfExpenseSubCategoryIsInactive()
    var
        Employee: Record Employee;
        PostCode: Record "Post Code";
        Customer: Record Customer;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseCategory: Record "Expense Category";
        ExpenseLocation: Record "Expense Location";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // [SCENARIO 617001] Verify that Expense Report cannot be posted if Expense SubCategory is inactive.
        Initialize();

        // [GIVEN] Find "Post Code".
        LibraryERM.FindPostCode(PostCode);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create "Expense User".
        LibraryExpense.CreateExpenseUser(ExpenseUser);

        // [GIVEN] Create "Expense Category".
        LibraryExpense.CreateExpenseCategoryWithSubCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", true);

        // [GIVEN] Get the created Expense SubCategory.
        ExpenseSubCategory.SetRange("Expense Category Code", ExpenseCategory.Code);
        ExpenseSubCategory.FindFirst();

        // [GIVEN] Create "Expense Location".
        LibraryExpense.CreateExpenseLocation(ExpenseLocation, PostCode."Country/Region Code", PostCode.City);

        // [GIVEN] Update Expense Account in "Employee Posting Group".
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');

        // [GIVEN] Create Expense Report Line.
        LibraryExpense.CreateExpenseReportLine(
            ExpenseReportLine, ExpenseReportHeader, ExpenseCategory.Code, true, Customer."No.",
            ExpenseReportLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        // [GIVEN] Find Expense Payment Method.
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        // [GIVEN] Update Payment Method in Expense.
        ExpenseReportLine.Validate("Expense Subcategory Code", ExpenseSubCategory.Code);
        ExpenseReportLine.Validate(Refundable, true);
        ExpenseReportLine.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        ExpenseReportLine.Modify();

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense SubCategory as Inactive.
        ExpenseSubCategory.Validate(Inactive, true);
        ExpenseSubCategory.Modify(true);

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that error is shown that Expense SubCategory is inactive.
        Assert.ExpectedTestFieldError(ExpenseSubCategory.FieldCaption(Inactive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithMultipleFCYLinesAndEmployeePaid()
    var
        Expense: array[3] of Record Expense;
        Currency: Record Currency;
        ExpensePostingGroup: Record "Expense Posting Group";
        JobTask: array[3] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedAmountLCY: array[3] of Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date.
        // Reimbursement type is Employee Paid with two FCY expense lines and one LCY expense line.
        Initialize();

        // [GIVEN] Delete Expense Posting Group.
        ExpensePostingGroup.DeleteAll();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Posting Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY := ExpectedAmountLCY[1] + ExpectedAmountLCY[2] + ExpectedAmountLCY[3];

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, '', Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with LCY on Header and "Exchange Rate for Expenses" is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -RefundableDebitAccountAmountLCY, 4, RefundableDebitAccountAmountLCY, -RefundableDebitAccountAmountLCY);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -RefundableDebitAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 3);

        VerifyExpenseAndJobLedgerEntry(Expense[1], PostedExpenseReportHeader, ExpectedAmountLCY[1], ExpectedAmountLCY[1], ExpectedAmountLCY[1], ExpectedAmountLCY[1]);
        VerifyExpenseAndJobLedgerEntry(Expense[2], PostedExpenseReportHeader, ExpectedAmountLCY[2], ExpectedAmountLCY[2], ExpectedAmountLCY[2], ExpectedAmountLCY[2]);
        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithMultipleLCYLinesAndEmployeePaid()
    var
        Expense: array[3] of Record Expense;
        JobTask: array[3] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        RefundableDebitAccountAmountLCY: Decimal;
        Amount: Decimal;
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Posting Date.
        // Reimbursement type is Employee Paid with three LCY expense lines.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Posting Date");

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        RefundableDebitAccountAmountLCY := Amount * 3;

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, '', '', Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with LCY on Header and "Exchange Rate for Expenses" is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -RefundableDebitAccountAmountLCY, 4, RefundableDebitAccountAmountLCY, -RefundableDebitAccountAmountLCY);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -RefundableDebitAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 3);

        VerifyExpenseAndJobLedgerEntry(Expense[1], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
        VerifyExpenseAndJobLedgerEntry(Expense[2], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
    end;

    // This test is currently disabled via DisabledTests/Expense_Agent_Tests/Expense_Agent_Tests.DisabledTest.json because the foreign-currency Source Currency Amount rounding on the balancing G/L entry differs under non-W1 localizations (AT/DE/DK/ES/FR).
    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithFCYOnHeaderAndExchangeRateForExpensesIsPostingDateWithMultipleFCYLinesAndEmployeePaid()
    var
        Expense: array[2] of Record Expense;
        Currency: Record Currency;
        JobTask: array[2] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedAmountLCY: array[2] of Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with FCY on Header and Exchange Rate for Expenses is Posting Date.
        // Reimbursement type is Employee Paid with two FCY expense lines.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Posting Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Posting Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY := ExpectedAmountLCY[1] + ExpectedAmountLCY[2];

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithTwoFCYLines(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, CurrencyCode, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with FCY on Header and "Exchange Rate for Expenses" is Posting Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -RefundableDebitAccountAmountLCY, 3, Amount * 2, -Amount * 2);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -RefundableDebitAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 2, 2);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader, Amount, ExpectedAmountLCY[1],
            LibraryERM.ConvertCurrency(ExpectedAmountLCY[1], '', CurrencyCode, WorkDate() + 2), ExpectedAmountLCY[1]);
        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader, Amount, ExpectedAmountLCY[2],
            LibraryERM.ConvertCurrency(ExpectedAmountLCY[2], '', CurrencyCode, WorkDate() + 2), ExpectedAmountLCY[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithMultipleFCYLinesAndEmployeePaid()
    var
        Currency: Record Currency;
        Expense: array[3] of Record Expense;
        JobTask: array[3] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedAmountLCY: array[3] of Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date.
        // Reimbursement type is Employee Paid with two FCY expense lines and one LCY expense line.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Expense Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY := ExpectedAmountLCY[1] + ExpectedAmountLCY[2] + ExpectedAmountLCY[3];
        EmployeePayableAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()), Currency."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 1), Currency."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, '', Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with LCY on Header and "Exchange Rate for Expenses" is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -EmployeePayableAccountAmountLCY, 6, RefundableDebitAccountAmountLCY, -EmployeePayableAccountAmountLCY);

        VerifyGLEntryWithSourceCurrencyAmount(
            PostedExpenseReportHeader."No.",
            GetDebitRoundingAccountFromExpensePostingGroup(Expense[1]."Expense Category"),
            EmployeePayableAccountAmountLCY - RefundableDebitAccountAmountLCY,
            EmployeePayableAccountAmountLCY - RefundableDebitAccountAmountLCY);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -EmployeePayableAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 3);

        VerifyExpenseAndJobLedgerEntry(Expense[1], PostedExpenseReportHeader, ExpectedAmountLCY[1], ExpectedAmountLCY[1], ExpectedAmountLCY[1], ExpectedAmountLCY[1]);
        VerifyExpenseAndJobLedgerEntry(Expense[2], PostedExpenseReportHeader, ExpectedAmountLCY[2], ExpectedAmountLCY[2], ExpectedAmountLCY[2], ExpectedAmountLCY[2]);
        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3], ExpectedAmountLCY[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithLCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithMultipleLCYLinesAndEmployeePaid()
    var
        Expense: array[3] of Record Expense;
        JobTask: array[3] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        RefundableDebitAccountAmountLCY: Decimal;
        Amount: Decimal;
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with LCY on Header and Exchange Rate for Expenses is Expense Date.
        // Reimbursement type is Employee Paid with three LCY expense lines.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Expense Date");

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        RefundableDebitAccountAmountLCY := Amount * 3;

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, '', '', Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, '', Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with LCY on Header and "Exchange Rate for Expenses" is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -RefundableDebitAccountAmountLCY, 4, RefundableDebitAccountAmountLCY, -RefundableDebitAccountAmountLCY);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -RefundableDebitAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 3);

        VerifyExpenseAndJobLedgerEntry(Expense[1], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
        VerifyExpenseAndJobLedgerEntry(Expense[2], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
        VerifyExpenseAndJobLedgerEntry(Expense[3], PostedExpenseReportHeader, Amount, Amount, Amount, Amount);
    end;

    // This test is currently disabled via DisabledTests/Expense_Agent_Tests/Expense_Agent_Tests.DisabledTest.json because the foreign-currency Source Currency Amount rounding on the balancing G/L entry differs under non-W1 localizations (AT/DE/DK/ES/FR).
    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithFCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithMultipleFCYLinesAndEmployeePaid()
    var
        Expense: array[2] of Record Expense;
        Currency: Record Currency;
        JobTask: array[2] of Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedAmountLCY: array[2] of Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with FCY on Header and Exchange Rate for Expenses is Expense Date.
        // Reimbursement type is Employee Paid with two FCY expense lines.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Expense Date");

        // [GIVEN] Create Currency with different Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 1, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + 2, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate() + 2), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY := ExpectedAmountLCY[1] + ExpectedAmountLCY[2];

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithTwoFCYLines(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, CurrencyCode, CurrencyCode, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode, Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with FCY on Header and "Exchange Rate for Expenses" is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense[1]);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense[1]."Expense Category", RefundableDebitAccountAmountLCY,
            -RefundableDebitAccountAmountLCY, 3, Amount * 2, -Amount * 2);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -RefundableDebitAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 2, 2);

        VerifyExpenseAndJobLedgerEntry(
            Expense[1], PostedExpenseReportHeader, Amount, ExpectedAmountLCY[1],
            LibraryERM.ConvertCurrency(ExpectedAmountLCY[1], '', CurrencyCode, WorkDate() + 2), ExpectedAmountLCY[1]);
        VerifyExpenseAndJobLedgerEntry(
            Expense[2], PostedExpenseReportHeader, Amount, ExpectedAmountLCY[2],
            LibraryERM.ConvertCurrency(ExpectedAmountLCY[2], '', CurrencyCode, WorkDate() + 2), ExpectedAmountLCY[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler')]
    procedure ExpenseReportIsPostedWithFCYOnHeaderAndExchangeRateForExpensesIsExpenseDateWithDifferentFCYLineAndEmployeePaid()
    var
        Expense: Record Expense;
        Currency1: Record Currency;
        Currency2: Record Currency;
        JobTask: Record "Job Task";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseAgentSetup: Record "Expense Agent Setup";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedAmount: Decimal;
        ExpectedAmountLCY: Decimal;
        Amount: Decimal;
        CurrencyCode1: Code[10];
        CurrencyCode2: Code[10];
    begin
        // [SCENARIO 621644] Verify that Expense Report is posted with FCY on Header and Exchange Rate for Expenses is Expense Date.
        // Reimbursement type is Employee Paid with different FCY expense.
        Initialize();

        // [GIVEN] Disable Expense Approval Workflow and Set Exchange Rate for Expenses to Expense Date in Agent Setup.
        UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(false, ExpenseAgentSetup."Exchange Rate for Expenses"::"Expense Date");

        // [GIVEN] Create Currency.
        CurrencyCode1 := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CurrencyCode2 := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency1.Get(CurrencyCode1);
        Currency2.Get(CurrencyCode2);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandIntInRange(300, 400);

        // [GIVEN] Generate Expected Amount.
        ExpectedAmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode1, '', WorkDate()), Currency1."Amount Rounding Precision");
        ExpectedAmount := Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY, '', CurrencyCode2, WorkDate()), Currency2."Amount Rounding Precision");

        // [GIVEN] Create and Release Expense with Job Task.
        CreateAndReleaseExpenseWithJobTask(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode1, 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate() + 2, CurrencyCode2, Expense."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted with FCY on Header and "Exchange Rate for Expenses" is Expense Date.
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        VerifyGLEntriesForPostedExpenseReport(
            PostedExpenseReportHeader."No.", Expense."Expense Category", ExpectedAmountLCY,
            -ExpectedAmountLCY, 2, ExpectedAmount, -ExpectedAmount);

        VerifyEmpAndDetailedEmpLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 1, 1);

        VerifyExpenseAndJobLedgerEntry(
            Expense, PostedExpenseReportHeader, CurrencyCode1, ExpectedAmount, ExpectedAmountLCY,
            LibraryERM.ConvertCurrency(ExpectedAmountLCY, '', CurrencyCode1, WorkDate()), ExpectedAmountLCY);
    end;

    [Test]
    [HandlerFunctions('AddExpensesToExpenseReportModalPageHandler,ExpenseReportPageHandler,ConfirmHandler')]
    procedure ExpenseReportCanBePostedIfExpenseIsCreatedWithCurrencyAndOtherExpenseWithoutCurrency()
    var
        Currency: Record Currency;
        Expense: array[2] of Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        Amount: Decimal;
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 625536] Verify that Expense Report can be posted if one expense line is created with currency and another expense line is created without currency.
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate.
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Get Currency.
        Currency.Get(CurrencyCode);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create Expense with Currency.
        CreateAndReleaseExpense(Expense[1], ExpenseUser, true, CurrencyCode, Amount);

        // [GIVEN] Create another Expense without currency.
        CreateAndReleaseExpenseWithExpenseUser(Expense[2], ExpenseUser, "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);

        // [WHEN] Create and Post Expense Report.
        CreateAndPostExpenseReport(ExpenseReportHeader, ExpenseUser."No.", WorkDate(), CurrencyCode, Expense[1]."VAT Bus. Posting Group");

        // [THEN] Verify that Expense Report is posted successfully.
        FindPostedExpenseReport(PostedExpenseReportHeader, ExpenseUser);
        FindPostedExpenseReportLine(PostedExpenseReportLine, ExpenseUser);
        Assert.RecordCount(PostedExpenseReportLine, 2);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingExpRepFailsWhenEnableAgentAndNotApproved()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629986] Posting expense report fails when Enable Agent is true and status is not Approved.
        Initialize();

        // [GIVEN] Enable Agent in Agent Setup.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create and release Expense.
        CreateAndReleaseExpense(Expense, ExpenseUser, true, '', Amount);

        // [GIVEN] Create Expense Report with status Released.
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        ExpenseReportHeader.PerformManualRelease();

        // [WHEN] Post Expense Report.
        asserterror ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify that Expense Report cannot be posted because approval process is not complete.
        Assert.ExpectedError(DocumentCanOnlyBePostedWhenApprovalProcessIsCompleteErr);
        Assert.ExpectedErrorCode('Dialog');

        // Cleanup
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingExpRepSucceedsWhenEnableAgentAndApproved()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        CurrentUserSetup: Record "User Setup";
        FinalApproverUserSetup: Record "User Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629986] Posting expense report succeeds when Enable Agent is true and status is Approved.
        Initialize();

        // [GIVEN] Enable Agent in Agent Setup.
        LibraryExpense.UpdateEnableAgentInAgentSetup(true);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create and release Expense.
        CreateAndReleaseExpense(Expense, ExpenseUser, true, '', Amount);

        // [GIVEN] Create User Setups and chain of approvers.
        CreateUserSetupsAndChainOfApprovers(CurrentUserSetup, FinalApproverUserSetup, ExpenseUser);

        // [GIVEN] Create Expense Report.
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [GIVEN] Add Expense to Expense Report.
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        // [GIVEN] Release Expense Report.
        ExpenseReportHeader.PerformManualRelease();

        // [GIVEN] Set Expense Report to Pending Approval.
        ExpenseReportHeader.PerformManualPendingApproval(ExpenseUser."No.");

        // [GIVEN] Set Expense Report to Approved.
        ExpenseReportHeader.PerformManualApproved(ExpenseUser."No.");

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted.
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);

        // Cleanup
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingExpRepAutoReleasesWhenBothAgentAndWorkflowDisabled()
    var
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseReportHeader: Record "Expense Report Header";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 629986] Posting expense report auto-releases when both Enable Agent and Enable Approval Workflow are disabled.
        Initialize();

        // [GIVEN] Disable Enable Agent in Agent Setup.
        LibraryExpense.UpdateEnableAgentInAgentSetup(false);

        // [GIVEN] Disable Expense Approval Workflow in Agent Setup.
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        // [GIVEN] Generate Random Amount.
        Amount := LibraryRandom.RandInt(100);

        // [GIVEN] Create and release Expense.
        CreateAndReleaseExpense(Expense, ExpenseUser, true, '', Amount);

        // [GIVEN] Create Expense Report with Open status (not released).
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");

        // [WHEN] Post Expense Report.
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        // [THEN] Verify Expense Report is posted (auto-released during posting).
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        Assert.RecordCount(PostedExpenseReportHeader, 1);
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        ExpensePostingGroup: Record "Expense Posting Group";
        UserSetup: Record "User Setup";
        User: Record User;
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Report Posting Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        UserSetup.DeleteAll();

        // Remove test-created users to stay within the CI license user cap; keep the current session user.
        User.SetFilter("User Security ID", '<>%1', UserSecurityId());
        User.DeleteAll();

        // Turn off Additional Reporting Currency to avoid extra "Residual caused by rounding" G/L entries
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Report Posting Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        ExpensePostingGroup.DeleteAll();
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Report Posting Test");
    end;

    local procedure CreateExpense(var Expense: Record Expense; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
    end;

    local procedure CreateAndReleaseExpense(var Expense: Record Expense; ExpenseCategory: Record "Expense Category"; ExpenseUser: Record "Expense User")
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseSubCategory: Record "Expense Subcategory";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', LibraryRandom.RandInt(100));
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpenseCategory."Reimbursement Type");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure UpdateExpenseAccountInEmployeePostingGroup(var ExpenseUser: Record "Expense User"; Expense: Record "Expense")
    var
        ExpenseCategory: Record "Expense Category";
        Employee: Record Employee;
    begin
        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure GetExpensePayableCashAccountFromEmployeePostingGroup(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        Employee.Get(EmployeeNo);
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        exit(EmployeePostingGroup.GetExpenseReportPayablesAccount());
    end;

    local procedure GetExpensePayableBankPaidAccountFromEmployeePostingGroup(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        Employee.Get(EmployeeNo);
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        exit(EmployeePostingGroup.GetExpensePayableBankPaidAccount());
    end;

    local procedure GetExpensePayableCardPaidAccountFromEmployeePostingGroup(EmployeeNo: Code[20]): Code[20]
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        Employee.Get(EmployeeNo);
        EmployeePostingGroup.Get(Employee."Employee Posting Group");

        exit(EmployeePostingGroup.GetExpensePayableCardPaidAccount());
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

    local procedure GetNonRefundableDebitAccountFromExpensePostingGroup(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        exit(ExpensePostingGroup."Non-Refundable Debit Account");
    end;

    local procedure GetDebitRoundingAccountFromExpensePostingGroup(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        exit(ExpensePostingGroup."Debit Rounding Account");
    end;

    local procedure GetCreditRoundingAccountFromExpensePostingGroup(ExpenseCategoryCode: Code[20]): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        ExpenseCategory.Get(ExpenseCategoryCode);
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");

        exit(ExpensePostingGroup."Credit Rounding Account");
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; Expense: Record Expense)
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure FindPostedExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseUser: Record "Expense User")
    begin
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; Expense: Record Expense)
    begin
        PostedExpenseReportLine.SetRange("Expense No.", Expense."No.");
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; ExpenseUserNo: Code[20])
    begin
        PostedExpenseReportLine.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure FindPostedExpenseReportLine(var PostedExpenseReportLine: Record "Posted Expense Report Line"; ExpenseUser: Record "Expense User")
    begin
        PostedExpenseReportLine.SetRange("Expense User No.", ExpenseUser."No.");
        PostedExpenseReportLine.FindFirst();
    end;

    local procedure FindExpenseReportLine(var ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    begin
        ExpenseReportLine.SetRange("Expense No.", Expense."No.");
        ExpenseReportLine.FindFirst();
    end;

    local procedure FindSalesLineFromPostedExpenseReportLine(var SalesLine: Record "Sales Line"; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        SalesLine.SetRange("Posted Exp. Report No.", PostedExpenseReportLine."Document No.");
        SalesLine.SetRange("Posted Exp. Report Line No.", PostedExpenseReportLine."Line No.");
        SalesLine.FindFirst();
    end;

    local procedure FindSalesHeaderFromPostedExpenseReportLine(var SalesHeader: Record "Sales Header"; PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line")
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", PostedExpenseReportLine."Billable to Customer");
        SalesHeader.SetRange("Currency Code", PostedExpenseReportLine."Expense Currency Code");
        SalesHeader.SetRange("Posting Date", PostedExpenseReportHeader."Posting Date");
        SalesHeader.SetRange(Status, SalesHeader.Status::Open);
        SalesHeader.FindFirst();
    end;

    local procedure CreateAndPostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense; Customer: Record Customer; ExpenseUser: Record "Expense User"; Currency: Record Currency)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, "Tax Calculation Type"::"Normal VAT");

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", Currency.Code, Expense."VAT Bus. Posting Group");

        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);

        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.Validate(Billable, true);
        ExpenseReportLine.Validate("Billable to Customer", Customer."No.");
        ExpenseReportLine.Validate("Account Type", ExpenseReportLine."Account Type"::"G/L Account");
        ExpenseReportLine.Validate("Account No.", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale));
        ExpenseReportLine.Modify();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure CreateAndReleaseExpense(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; Refundable: Boolean; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        CreateAndReleaseExpenseWithPaymentMethod(Expense, ExpenseUser, ExpensePaymentMethod, Expense."Reimbursement Type"::"Employee Paid", Refundable, CurrencyCode, 0, Amount);
    end;

    local procedure CreateAndReleaseExpenseWithPaymentMethod(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; var ExpensePaymentMethod: Record "Expense Payment Method"; ReimbursementType: Enum "Expense Reimbursement Type"; Refundable: Boolean; CurrencyCode: Code[10]; AmountReduction: Decimal; Amount: Decimal)
    var
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ReimbursementType);

        CreateExpense(Expense, Refundable, CurrencyCode, Amount);
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Non-Refundable Amount", AmountReduction);
        Expense.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateAndReleaseExpenseWithJobTask(var Expense: Record Expense; var ExpenseUser: Record "Expense User"; var ExpensePaymentMethod: Record "Expense Payment Method"; var JobTask: Record "Job Task"; ExpenseDate: Date; ReimbursementType: Enum "Expense Reimbursement Type"; Refundable: Boolean; CurrencyCode: Code[10]; AmountReduction: Decimal; Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense, ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup, ExpenseDate, ReimbursementType, Refundable, false, CurrencyCode, AmountReduction, Amount);
    end;

    local procedure CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(
        var Expense: Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var JobTask: Record "Job Task";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpenseDate: Date;
        ReimbursementType: Enum "Expense Reimbursement Type";
        Refundable: Boolean;
        UpdateVAT: Boolean;
        CurrencyCode: Code[10];
        AmountReduction: Decimal;
        Amount: Decimal)
    var
        Job: Record Job;
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ReimbursementType);

        CreateJobWithJobTask(JobTask);
        Job.Get(JobTask."Job No.");
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify();

        if ExpenseUser."No." = '' then
            LibraryExpense.CreateExpenseUser(ExpenseUser);

        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
        if UpdateVAT then begin
            Expense.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Expense.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        end;
        Expense.Validate("Expense Date", ExpenseDate);
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Non-Refundable Amount", AmountReduction);
        Expense.Validate("Job No.", JobTask."Job No.");
        Expense.Validate("Job Task No.", JobTask."Job Task No.");
        Expense.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateExpenseReportComment(ExpenseReportNo: Code[20]; DocumentLineNo: Integer; CommentText: Text[80])
    var
        ExpenseReportCommentLine: Record "Expense Report Comment Line";
        RecordRef: RecordRef;
    begin
        ExpenseReportCommentLine.Init();
        ExpenseReportCommentLine."Document Type" := ExpenseReportCommentLine."Document Type"::"Expense Report";
        ExpenseReportCommentLine."No." := ExpenseReportNo;
        ExpenseReportCommentLine."Document Line No." := DocumentLineNo;
        RecordRef.GetTable(ExpenseReportCommentLine);
        ExpenseReportCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecordRef, ExpenseReportCommentLine.FieldNo("Line No.")));
        ExpenseReportCommentLine.Date := WorkDate();
        ExpenseReportCommentLine.Comment := CommentText;
        ExpenseReportCommentLine.Insert();
    end;

    local procedure CreateRandomExpenseReportComment(ExpenseReportNo: Code[20]; DocumentLineNo: Integer): Text[80]
    var
        CommentText: Text[80];
    begin
        CommentText := CopyStr(LibraryRandom.RandText(80), 1, 80);
        CreateExpenseReportComment(ExpenseReportNo, DocumentLineNo, CommentText);
        exit(CommentText);
    end;

    local procedure CreateCommentForExpenseReportHeader(ExpenseReportNo: Code[20]): Text[80]
    begin
        exit(CreateRandomExpenseReportComment(ExpenseReportNo, 0));
    end;

    local procedure CreateRandomExpenseReportLineComment(ExpenseReportNo: Code[20]; LineNo: Integer): Text[80]
    begin
        exit(CreateRandomExpenseReportComment(ExpenseReportNo, LineNo));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);

        Assert.AreNearlyEqual(
            ExpectedAmount,
            GLEntry.Amount,
            0.01,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount);

        Assert.AreNearlyEqual(
            ExpectedAmount,
            VATEntry.Amount,
            0.01,
            StrSubstNo(ValueMustBeEqualErr, VATEntry.FieldCaption(Amount), ExpectedAmount, VATEntry.TableCaption()));
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

        Assert.AreNearlyEqual(
            ExpectedAmount,
            EmployeeLedgerEntry."Amount (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, EmployeeLedgerEntry.FieldCaption("Amount (LCY)"), ExpectedAmount, EmployeeLedgerEntry.TableCaption()));
    end;

    local procedure VerifyDetailedEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        DetailedEmployeeLedgerEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgerEntry.SetRange("Document Type", DetailedEmployeeLedgerEntry."Document Type"::Invoice);
        DetailedEmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgerEntry.CalcSums("Amount (LCY)");

        Assert.AreNearlyEqual(
            ExpectedAmount,
            DetailedEmployeeLedgerEntry."Amount (LCY)",
            0.01,
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
            PostedExpenseReportLine."Expense Currency Code",
            ExpenseLedgerEntry."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Currency Code"), PostedExpenseReportLine."Expense Currency Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Payment Method Code",
            ExpenseLedgerEntry."Payment Method Code",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Payment Method Code"), PostedExpenseReportLine."Payment Method Code", ExpenseLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            Amount,
            ExpenseLedgerEntry."Amount",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            AmountLCY,
            ExpenseLedgerEntry."Amount (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            PostedExpenseReportLine.Amount,
            ExpenseLedgerEntry."Original Amount",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amount"), PostedExpenseReportLine.Amount, ExpenseLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Amount (LCY)",
            ExpenseLedgerEntry."Original Amt. (LCY)",
            StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Original Amt. (LCY)"), PostedExpenseReportLine."Amount (LCY)", ExpenseLedgerEntry.TableCaption()));
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
        if PostedExpenseReportLine.Refundable then begin
            Assert.AreNearlyEqual(
                Amount,
                ExpenseLedgerEntry."Refundable Amount",
                0.01,
                StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Refundable Amount"), Amount, ExpenseLedgerEntry.TableCaption()));
            Assert.AreNearlyEqual(
                AmountLCY,
                ExpenseLedgerEntry."Refundable Amount (LCY)",
                0.01,
                StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Refundable Amount (LCY)"), AmountLCY, ExpenseLedgerEntry.TableCaption()));
        end else begin
            Assert.AreEqual(
                0,
                ExpenseLedgerEntry."Refundable Amount",
                StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Refundable Amount"), 0, ExpenseLedgerEntry.TableCaption()));
            Assert.AreEqual(
                0,
                ExpenseLedgerEntry."Refundable Amount (LCY)",
                StrSubstNo(ValueMustBeEqualErr, ExpenseLedgerEntry.FieldCaption("Refundable Amount (LCY)"), 0, ExpenseLedgerEntry.TableCaption()));
        end;
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

    local procedure VerifySalesLineFromPostedExpenseReportLine(PostedExpenseReportLine: Record "Posted Expense Report Line")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLineFromPostedExpenseReportLine(SalesLine, PostedExpenseReportLine);

        Assert.AreEqual(
            PostedExpenseReportLine."Account Type"::"G/L Account",
            SalesLine.Type,
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption(Type), PostedExpenseReportLine."Account Type"::"G/L Account", SalesLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Account No.",
            SalesLine."No.",
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("No."), PostedExpenseReportLine."Account No.", SalesLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine.Description,
            SalesLine.Description,
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Description"), PostedExpenseReportLine.Description, SalesLine.TableCaption()));
        Assert.AreEqual(
            1,
            SalesLine.Quantity,
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Quantity"), 1, SalesLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine.Amount,
            SalesLine."Unit Price",
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Amount"), PostedExpenseReportLine.Amount, SalesLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Amount (LCY)",
            SalesLine."Outstanding Amount (LCY)",
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Outstanding Amount (LCY)"), PostedExpenseReportLine."Amount (LCY)", SalesLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Expense Currency Code",
            SalesLine."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, SalesLine.FieldCaption("Currency Code"), PostedExpenseReportLine."Expense Currency Code", SalesLine.TableCaption()));
    end;

    local procedure VerifyGLEntryWithSourceCurrencyCode(PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.SetRange("Source Currency Code", PostedExpenseReportHeader."Reimbursement Currency Code");
        Assert.RecordCount(GLEntry, 2);
    end;

    local procedure VerifyRecordCountOfGLEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpectedRecordCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.RecordCount(GLEntry, ExpectedRecordCount);
    end;

    local procedure CreateAndAttachExpenseToExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20])
    var
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, VATBusPostingGroup);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure CreateAndAttachExpenseToExpenseReportWithPostingDate(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]; VATBusPostingGroup: Code[20])
    var
        ExpenseFilter: Record Expense;
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUserNo, CurrencyCode, VATBusPostingGroup);
        ExpenseReportHeader.Validate("Posting Date", PostingDate);
        ExpenseReportHeader.Modify();

        // Enqueue Existing Expense Report No. and mark to skip creating a new one.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ExpenseReportHeader."No.");

        ExpenseFilter.SetRange("Expense User No.", ExpenseUserNo);
        CreateExpenseReport.AddExpensesToReport(ExpenseFilter);
    end;

    local procedure UpdateVATLiableInExpenseReportLineFromExpense(Expense: Record Expense; VATLiable: Boolean; VendorNo: Code[20])
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        FindExpenseReportLine(ExpenseReportLine, Expense);
        ExpenseReportLine.Validate("Vendor No.", VendorNo);
        ExpenseReportLine.Validate("VAT Liable", VATLiable);
        ExpenseReportLine.Modify();
    end;

    local procedure UpdateCurrencyCodeInJob(JobNo: Code[20]; CurrencyCode: Code[10])
    var
        Job: Record Job;
    begin
        Job.Get(JobNo);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify();
    end;

    local procedure VerifyRecordCountOfEmployeeLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(EmployeeLedgerEntry, ExpectedRecordCount);
    end;

    local procedure VerifyRecordCountOfVATEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, ExpectedRecordCount);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure VerifyJobLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; AccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    begin
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, AccountNo, PostedExpenseReportHeader."Reimbursement Currency Code", ExpectedAmount, ExpectedAmountLCY);
    end;

    local procedure VerifyJobLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; PostedExpenseReportLine: Record "Posted Expense Report Line"; AccountNo: Code[20]; JobCurrencyCode: Code[10]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
#pragma warning disable AA0210
        JobLedgerEntry.SetRange("Expense Report No.", PostedExpenseReportLine."Document No.");
        JobLedgerEntry.SetRange("Expense Report Line No.", PostedExpenseReportLine."Line No.");
#pragma warning restore AA0210
        JobLedgerEntry.FindFirst();
        Assert.RecordCount(JobLedgerEntry, 1);

        Assert.AreEqual(
            PostedExpenseReportHeader."Posting Date",
            JobLedgerEntry."Posting Date",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Posting Date"), PostedExpenseReportHeader."Posting Date", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportHeader."No.",
            JobLedgerEntry."Document No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Document No."), PostedExpenseReportHeader."No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Job No.",
            JobLedgerEntry."Job No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Job No."), PostedExpenseReportLine."Job No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Job Task No.",
            JobLedgerEntry."Job Task No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Job Task No."), PostedExpenseReportLine."Job Task No.", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            JobLedgerEntry.Type::"G/L Account",
            JobLedgerEntry.Type,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Type"), JobLedgerEntry.Type::"G/L Account", JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            AccountNo,
            JobLedgerEntry."No.",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("No."), AccountNo, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            1,
            JobLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Quantity"), 1, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            JobCurrencyCode,
            JobLedgerEntry."Currency Code",
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Currency Code"), JobCurrencyCode, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmount,
            JobLedgerEntry."Unit Price",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Price"), ExpectedAmount, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmountLCY,
            JobLedgerEntry."Unit Price (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Price (LCY)"), ExpectedAmountLCY, JobLedgerEntry.TableCaption()));
        Assert.AreEqual(
            JobLedgerEntry."Entry No.",
            PostedExpenseReportLine."Job Ledger Entry No.",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Job Ledger Entry No."), JobLedgerEntry."Entry No.", PostedExpenseReportLine.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmount,
            JobLedgerEntry."Unit Cost",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost"), ExpectedAmount, JobLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedAmountLCY,
            JobLedgerEntry."Unit Cost (LCY)",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, JobLedgerEntry.FieldCaption("Unit Cost (LCY)"), ExpectedAmountLCY, JobLedgerEntry.TableCaption()));
    end;

    local procedure VerifyRecordCountOfJobLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(JobLedgerEntry, ExpectedRecordCount);
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob, 'jpeg');
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob"; ImageType: Text)
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        case ImageType of
            'png':
                Bitmap.Save(InStr, ImageFormat.Png);
            'jpeg':
                Bitmap.Save(InStr, ImageFormat.Jpeg);
            else
                Bitmap.Save(InStr, ImageFormat.Bmp);
        end;
        Bitmap.Dispose();
    end;

    local procedure CheckIfDocAttachExist(TableNo: Integer; DocNo: Code[20]; LineNo: Integer): Boolean;
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("No.", DocNo);
        if LineNo <> 0 then
            DocumentAttachment.SetRange("Line No.", LineNo);

        exit(not DocumentAttachment.IsEmpty())
    end;

    local procedure FindDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; TableNo: Integer; DocNo: Code[20]; LineNo: Integer)
    begin
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("No.", DocNo);
        if LineNo <> 0 then
            DocumentAttachment.SetRange("Line No.", LineNo);
        DocumentAttachment.FindFirst();
    end;

    local procedure VerifyAttachmentExpenseReportLineFromExpense(Expense: Record Expense; DocumentAttachment: Record "Document Attachment"; ReceiptAttached: Boolean)
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportDocumentAttachment: Record "Document Attachment";
    begin
        FindExpenseReportLine(ExpenseReportLine, Expense);
        FindDocumentAttachment(ExpenseReportDocumentAttachment, Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No.");

        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::Expense, Expense."No.", 0),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, Expense.TableCaption()));
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            DocumentAttachment.ID,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), DocumentAttachment.ID, ExpenseReportLine.TableCaption()));
        ExpenseReportDocumentAttachment.TestField("Document Reference ID", DocumentAttachment."Document Reference ID");
    end;

    local procedure VerifyAttachmentPostedExpenseReportLineFromExpense(Expense: Record Expense; DocumentAttachment: Record "Document Attachment"; ReceiptAttached: Boolean)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportDocumentAttachment: Record "Document Attachment";
    begin
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        FindDocumentAttachment(PostedExpenseReportDocumentAttachment, Database::"Posted Expense Report Line", PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No.");

        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::Expense, Expense."No.", 0),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, Expense.TableCaption()));
        Assert.AreEqual(
            false,
            CheckIfDocAttachExist(Database::"Expense Report Line", Expense."Expense Report No.", 0),
            StrSubstNo(DocumentAttachmentExistErr, Expense.TableCaption()));
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Posted Expense Report Line", PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            PostedExpenseReportLine."Document No.",
            Expense."Posted Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Posted Expense Report No."), PostedExpenseReportLine."Document No.", PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            PostedExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            DocumentAttachment.ID,
            PostedExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Entry"), DocumentAttachment.ID, PostedExpenseReportLine.TableCaption()));
        PostedExpenseReportDocumentAttachment.TestField("Document Reference ID", DocumentAttachment."Document Reference ID");
    end;

    local procedure VerifyAttachmentExpenseReportLineFromWithoutExpense(ExpenseReportLine: Record "Expense Report Line"; ReceiptAttached: Boolean; ReceiptId: Integer)
    var
        Expense: Record Expense;
    begin
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Expense Report Line", ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            false,
            CheckIfDocAttachExist(Database::Expense, ExpenseReportLine."Document No.", 0),
            StrSubstNo(DocumentAttachmentExistErr, Expense.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            ExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptId,
            ExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Receipt Entry"), ReceiptId, ExpenseReportLine.TableCaption()));
    end;

    local procedure VerifyAttachmentPostedExpenseReportLineFromWithoutExpense(PostedExpenseReportLine: Record "Posted Expense Report Line"; ReceiptAttached: Boolean; ReceiptId: Integer)
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Assert.AreEqual(
            true,
            CheckIfDocAttachExist(Database::"Posted Expense Report Line", PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No."),
            StrSubstNo(DocumentAttachmentDoesNotExistErr, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            false,
            CheckIfDocAttachExist(Database::"Expense Report Line", PostedExpenseReportLine."Document No.", 0),
            StrSubstNo(DocumentAttachmentExistErr, ExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptAttached,
            PostedExpenseReportLine."Receipt Attached",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Attached"), ReceiptAttached, PostedExpenseReportLine.TableCaption()));
        Assert.AreEqual(
            ReceiptId,
            PostedExpenseReportLine."Receipt Entry",
            StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Receipt Entry"), ReceiptId, PostedExpenseReportLine.TableCaption()));
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup[1]."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup[1]."VAT Prod. Posting Group";

        VATPostingSetup[2].Get(VATPostingSetup[1]."VAT Bus. Posting Group", LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
    end;

    local procedure ReleaseAndPostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header")
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure VerifyPostedExpenseReport(Expense: Record Expense; ExpenseUser: Record "Expense User"; Amount: Decimal; AmountReduction: Decimal; ExpectedAmountLCY: Decimal)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        FindPostedExpenseReport(PostedExpenseReportHeader, Expense);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), -ExpectedAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedAmountLCY);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, 2);
        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", -ExpectedAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", Amount - AmountReduction, ExpectedAmountLCY);
    end;

    local procedure VerifyGLEntriesForPostedExpenseReport(
        PostedDocumentNo: Code[20];
        ExpenseCategory: Code[20];
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        RecordCountOfGLEntry: Integer;
        RefundableTotalAmount: Decimal;
        EmployeePayableTotalAmount: Decimal)
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseUser: Record "Expense User";
    begin
        PostedExpenseReportHeader.Get(PostedDocumentNo);
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");

        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(ExpenseCategory), RefundableDebitAccountAmountLCY, RefundableTotalAmount);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), EmployeePayableAccountAmountLCY, EmployeePayableTotalAmount);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, RecordCountOfGLEntry);
        VerifyRecordCountOfGLEntryWithSourceCurrencyCode(PostedExpenseReportHeader."No.", PostedExpenseReportHeader."Reimbursement Currency Code", RecordCountOfGLEntry);
    end;

    local procedure VerifyEmpAndDetailedEmpLedgerEntry(DocumentNo: Code[20]; EmployeePayableAccountAmountLCY: Decimal)
    begin
        VerifyEmployeeLedgerEntry(DocumentNo, EmployeePayableAccountAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(DocumentNo, EmployeePayableAccountAmountLCY);
        VerifyRecordCountOfEmployeeLedgerEntry(DocumentNo, 1);
    end;

    local procedure VerifyExpenseAndJobLedgerEntry(
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpectedExpenseAmount: Decimal;
        ExpectedExpenseAmountLCY: Decimal;
        ExpectedJobAmount: Decimal;
        ExpectedJobAmountLCY: Decimal)
    begin
        VerifyExpenseAndJobLedgerEntry(
            Expense, PostedExpenseReportHeader, PostedExpenseReportHeader."Reimbursement Currency Code",
            ExpectedExpenseAmount, ExpectedExpenseAmountLCY, ExpectedJobAmount, ExpectedJobAmountLCY);
    end;

    local procedure VerifyExpenseAndJobLedgerEntry(
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        JobCurrencyCode: Code[10];
        ExpectedExpenseAmount: Decimal;
        ExpectedExpenseAmountLCY: Decimal;
        ExpectedJobAmount: Decimal;
        ExpectedJobAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");

        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedExpenseAmount, ExpectedExpenseAmountLCY);

        VerifyJobLedgerEntry(
            PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"),
            JobCurrencyCode, ExpectedJobAmount, ExpectedJobAmountLCY);
    end;

    local procedure VerifyGLEntryWithSourceCurrencyAmount(DocumentNo: Code[20]; AccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedSourceCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount, "Source Currency Amount");

        Assert.AreNearlyEqual(
            ExpectedAmount,
            GLEntry.Amount,
            0.01,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), ExpectedAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
            ExpectedSourceCurrencyAmount,
            GLEntry."Source Currency Amount",
            0.01,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption("Source Currency Amount"), ExpectedSourceCurrencyAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyRecordCountOfGLEntryWithSourceCurrencyCode(DocumentNo: Code[20]; CurrencyCode: Code[10]; ExpectedRecordCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Source Currency Code", CurrencyCode);
        Assert.RecordCount(GLEntry, ExpectedRecordCount);
    end;

    local procedure VerifyRecordCountOfExpenseLedgerEntry(DocumentNo: Code[20]; ExpectedRecordCount: Integer)
    var
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
    begin
        ExpenseLedgerEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(ExpenseLedgerEntry, ExpectedRecordCount);
    end;

    local procedure VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; RecordCountOfJobLedgerEntry: Integer; RecordCountOfExpenseLedgerEntry: Integer)
    begin
        VerifyRecordCountOfJobLedgerEntry(PostedExpenseReportHeader."No.", RecordCountOfJobLedgerEntry);
        VerifyRecordCountOfExpenseLedgerEntry(PostedExpenseReportHeader."No.", RecordCountOfExpenseLedgerEntry);
    end;

    local procedure UpdateApprovalWorkflowAndExchangeRateInExpenseAgentSetup(EnableApprovalWorkflow: Boolean; ExpenseRateForExpenses: Enum "Expense Exchange Rate")
    begin
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(EnableApprovalWorkflow);
        LibraryExpense.UpdateExpenseRateForExpensesInAgentSetup(ExpenseRateForExpenses);
    end;

    local procedure CreateAndReleaseExpenseWithJobTask(
        var Expense: array[3] of Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var JobTask: array[3] of Record "Job Task";
        CurrencyCode: Code[10];
        JobCurrencyCode: Code[10];
        Amount: Decimal)
    begin
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], WorkDate() + 1, "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, 0, Amount);

        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", JobCurrencyCode);
    end;

    local procedure CreateAndReleaseExpenseWithTwoFCYLines(
        var Expense: array[2] of Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var JobTask: array[2] of Record "Job Task";
        CurrencyCode: Code[10];
        JobCurrencyCode: Code[10];
        Amount: Decimal)
    begin
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate() + 1, "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, 0, Amount);

        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", JobCurrencyCode);
    end;

    local procedure CreateAndPostExpenseReport(var ExpenseReportHeader: Record "Expense Report Header"; ExpenseUserNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]; VATBusinessPostingGroup: Code[20])
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        CreateAndAttachExpenseToExpenseReportWithPostingDate(ExpenseReportHeader, ExpenseUserNo, PostingDate, CurrencyCode, VATBusinessPostingGroup);
        ExpenseReportHeader.PerformManualRelease();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
    end;

    local procedure CreateAndReleaseExpenseWithAttachment(var Expense: Record Expense; var DocumentAttachment: Record "Document Attachment"; CurrencyCode: Code[10]; Amount: Decimal)
    var
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        RecRef: RecordRef;
    begin
        CreateExpense(Expense, true, CurrencyCode, Amount);

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, "Expense Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        RecRef.GetTable(Expense);
        CreateDocumentAttachment(DocumentAttachment, RecRef, Expense."No." + JPEGLbl);

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);
        Expense.Get(Expense."No.");
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateAndAttachExpenseToExpenseReportWithAttachment(var ExpenseReportHeader: Record "Expense Report Header"; var DocumentAttachment: Record "Document Attachment"; var ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    var
        RecRef: RecordRef;
    begin
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");

        FindExpenseReportLine(ExpenseReportLine, Expense);
        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);
    end;

    local procedure VerifyAttachmentInExpenseReportPage(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    var
        ExpenseReportPage: TestPage "Expense Report";
    begin
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(Expense."No.");
        ExpenseReportPage."Attached Documents List".Next();
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
    end;

    local procedure VerifyAttachmentInPostedExpenseReport(PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    var
        PostedExpenseReportPage: TestPage "Posted Expense Report";
    begin
        PostedExpenseReportPage.OpenEdit();
        PostedExpenseReportPage.GoToRecord(PostedExpenseReportHeader);
        PostedExpenseReportPage."Attached Documents List".Name.AssertEquals(Expense."No.");
        PostedExpenseReportPage."Attached Documents List".Next();
        PostedExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
    end;

    local procedure VerifyRecordCountOfDocumentAttachment(Expense: Record Expense; ExpenseReportLine: Record "Expense Report Line"; ExpectedCount: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Expense);
        DocumentAttachment.SetFilter("Table ID", '%1|%2', Database::Expense, Database::"Expense Report Line");
        DocumentAttachment.SetFilter("No.", '%1|%2', Expense."No.", ExpenseReportLine."Document No.");
        Assert.RecordCount(DocumentAttachment, ExpectedCount);
    end;

    local procedure CreateAndAttachExpenseToExpenseReportWithAttachmentInNewExpenseReportLine(var ExpenseReportHeader: Record "Expense Report Header"; var ExpenseReportLine: Record "Expense Report Line"; var DocumentAttachment: Record "Document Attachment"; Expense: Record Expense)
    var
        RecRef: RecordRef;
    begin
        CreateAndAttachExpenseToExpenseReport(ExpenseReportHeader, Expense."Expense User No.", Expense."Currency Code", Expense."VAT Bus. Posting Group");
        LibraryExpense.CreateExpenseReportLine(ExpenseReportLine, ExpenseReportHeader, Expense."Expense User No.", Expense."Expense Category", Expense."Payment Method Code", true, Expense."Currency Code", Expense.Amount);

        RecRef.GetTable(ExpenseReportLine);
        CreateDocumentAttachment(DocumentAttachment, RecRef, ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No.") + JPEGLbl);
    end;

    local procedure VerifyAttachmentInExpenseReportPageWithNewExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    var
        ExpenseReportPage: TestPage "Expense Report";
    begin
        ExpenseReportPage.OpenEdit();
        ExpenseReportPage.GoToRecord(ExpenseReportHeader);
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(Expense."No.");

        ExpenseReportPage."Expense Report Subform".Next();
        ExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
    end;

    local procedure VerifyAttachmentInPostedExpenseReportPageWithNewExpenseReportLine(PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; Expense: Record Expense)
    var
        PostedExpenseReportPage: TestPage "Posted Expense Report";
    begin
        PostedExpenseReportPage.OpenEdit();
        PostedExpenseReportPage.GoToRecord(PostedExpenseReportHeader);
        PostedExpenseReportPage."Attached Documents List".Name.AssertEquals(Expense."No.");

        PostedExpenseReportPage."Posted Expense Report Subform".Next();
        PostedExpenseReportPage."Attached Documents List".Name.AssertEquals(ExpenseReportLine."Document No." + Format(ExpenseReportLine."Line No."));
    end;

    local procedure VerifyGLEntryForPostedExpenseReport(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: Record Expense;
        RecordCountOfGLEntry: Integer;
        ExpectedCompanyPaidAmountLCY: Decimal;
        ExpectedRefundableAmountLCY: Decimal;
        ExpectedEmployeePayableAmountLCY: Decimal;
        ExpectedNonRefundableAmountLCY: Decimal;
        ExpectedTotalCompanyPaidAmount: Decimal;
        ExpectedTotalRefundableAmount: Decimal;
        ExpectedTotalEmployeePayableAmountLCY: Decimal;
        ExpectedTotalNonRefundableAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        ExpensePaymentMethod.Get(Expense."Payment Method Code");

        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), ExpectedCompanyPaidAmountLCY, ExpectedTotalCompanyPaidAmount);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedRefundableAmountLCY, ExpectedTotalRefundableAmount);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), ExpectedEmployeePayableAmountLCY, ExpectedTotalEmployeePayableAmountLCY);
        VerifyGLEntryWithSourceCurrencyAmount(PostedExpenseReportHeader."No.", GetNonRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), ExpectedNonRefundableAmountLCY, ExpectedTotalNonRefundableAmountLCY);

        VerifyRecordCountOfGLEntryWithSourceCurrencyCode(PostedExpenseReportHeader."No.", PostedExpenseReportHeader."Reimbursement Currency Code", RecordCountOfGLEntry);
        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, RecordCountOfGLEntry);
    end;

    local procedure VerifyEmployeeAndExpenseLedgerEntry(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: Record Expense;
        ExpectedExpenseLedgerAmount: Decimal;
        ExpectedExpenseLedgerAmountLCY: Decimal;
        ExpectedEmployeeAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);

        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", ExpectedEmployeeAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", ExpectedEmployeeAmountLCY);
        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedExpenseLedgerAmount, ExpectedExpenseLedgerAmountLCY);
    end;

    local procedure VerifyLedgerEntryForExpense(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpectedExpenseLedgerAmount: Decimal;
        ExpectedExpenseLedgerAmountLCY: Decimal;
        ExpectedEmployeeAmountLCY: Decimal;
        ExpectedJobLedgerAmount: Decimal;
        ExpectedJobLedgerAmountLCY: Decimal)
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);

        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", ExpectedEmployeeAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", ExpectedEmployeeAmountLCY);

        VerifyExpenseLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, Expense, ExpenseUser."Employee No.", ExpectedExpenseLedgerAmount, ExpectedExpenseLedgerAmountLCY);
        VerifyJobLedgerEntry(PostedExpenseReportHeader, PostedExpenseReportLine, GetRefundableDebitAccountFromExpensePostingGroup(PostedExpenseReportLine."Expense Category"), ExpectedJobLedgerAmount, ExpectedJobLedgerAmountLCY);
    end;

    local procedure CreateAndReleaseExpenseWithJobTask(
        var Expense: array[4] of Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var JobTask: Record "Job Task";
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountReduction: Decimal)
    begin
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask, WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode, 0, Amount);
    end;

    local procedure CalculateExpectedValuesForFCYOnHeader(
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
        PostingDate: Date;
        var ExpectedAmount: array[4] of Decimal;
        var ExpectedAmountLCY: array[4] of Decimal;
        var PaymentMethodAccAmtLCY: Decimal;
        var RefundableDebitAccountAmountLCY: Decimal;
        var EmployeePayableAccountAmountLCY: Decimal;
        var NonRefundableDebitAccountAmountLCY: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);

        ExpectedAmount[1] := Amount - AmountReduction;
        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        ExpectedAmount[2] := Amount;
        ExpectedAmountLCY[2] := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        ExpectedAmount[3] := Amount - AmountReduction;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        ExpectedAmount[4] := -Amount;
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        PaymentMethodAccAmtLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
           -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
    end;

    local procedure VerifyLedgerEntryForFCYPostedExpenseReport(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: array[4] of Record Expense;
        GLEntryCount: Integer;
        Amount: Decimal;
        AmountReduction: Decimal;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        Currency: Record Currency;
        ExpectedJobAmount: Decimal;
    begin
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        Currency.Get(PostedExpenseReportHeader."Reimbursement Currency Code");

        ExpectedJobAmount := Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[2], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision");

        VerifyGLEntryForPostedExpenseReport(
            PostedExpenseReportHeader, Expense[1],
            GLEntryCount, PaymentMethodAccAmtLCY, RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY,
            -Amount - ExpectedAmount[1], Amount + ExpectedAmount[1] * 2, -ExpectedAmount[1] + AmountReduction + Amount, -AmountReduction - Amount);

        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[1], ExpenseUser, ExpectedAmount[1], ExpectedAmountLCY[1], EmployeePayableAccountAmountLCY, ExpectedAmount[1], ExpectedAmountLCY[1]);
        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[2], ExpenseUser, ExpectedAmount[2], ExpectedAmountLCY[2], EmployeePayableAccountAmountLCY, ExpectedJobAmount, ExpectedAmountLCY[2]);
        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[3], ExpenseUser, ExpectedAmount[3], ExpectedAmountLCY[3], EmployeePayableAccountAmountLCY, ExpectedAmount[3], ExpectedAmountLCY[3]);

        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense[4], ExpectedAmount[4], ExpectedAmountLCY[4], EmployeePayableAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 4);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 1);
    end;

    local procedure VerifyLedgerEntryForLCYPostedExpenseReport(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: array[4] of Record Expense;
        ExpectedAmount: array[4] of Decimal;
        ExpectedAmountLCY: array[4] of Decimal;
        GLEntryCount: Integer;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        Currency: Record Currency;
        ExpectedJobAmount: Decimal;
    begin
        ExpenseUser.Get(PostedExpenseReportHeader."Expense User No.");
        ExpectedJobAmount := Round(LibraryERM.ConvertCurrency(ExpectedAmountLCY[2], '', PostedExpenseReportHeader."Reimbursement Currency Code", WorkDate() + 2), Currency."Amount Rounding Precision");

        VerifyGLEntryForPostedExpenseReport(
            PostedExpenseReportHeader, Expense[1],
            GLEntryCount, PaymentMethodAccAmtLCY, RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY,
            PaymentMethodAccAmtLCY, RefundableDebitAccountAmountLCY, EmployeePayableAccountAmountLCY, NonRefundableDebitAccountAmountLCY);

        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[1], ExpenseUser, ExpectedAmount[1], ExpectedAmountLCY[1], EmployeePayableAccountAmountLCY, ExpectedAmount[1], ExpectedAmountLCY[1]);
        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[2], ExpenseUser, ExpectedAmount[2], ExpectedAmountLCY[2], EmployeePayableAccountAmountLCY, ExpectedJobAmount, ExpectedAmountLCY[2]);
        VerifyLedgerEntryForExpense(PostedExpenseReportHeader, Expense[3], ExpenseUser, ExpectedAmount[3], ExpectedAmountLCY[3], EmployeePayableAccountAmountLCY, ExpectedAmount[3], ExpectedAmountLCY[3]);

        VerifyEmployeeAndExpenseLedgerEntry(PostedExpenseReportHeader, Expense[4], ExpectedAmount[4], ExpectedAmountLCY[4], EmployeePayableAccountAmountLCY);
        VerifyRecordCountOfExpenseAndJobLedgerEntry(PostedExpenseReportHeader, 3, 4);
        VerifyRecordCountOfEmployeeLedgerEntry(PostedExpenseReportHeader."No.", 1);
    end;

    local procedure CreateAndReleaseExpenseWithJobTask(
        var Expense: array[4] of Record Expense;
        var JobTask: array[4] of Record "Job Task";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var ExpenseUser: Record "Expense User";
        CurrencyCode: Code[10];
        JobCurrencyCode: Code[10];
        AmountReduction: Decimal;
        Amount: Decimal)
    begin
        CreateAndReleaseExpenseWithJobTask(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, '', 0, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask[3], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTask(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask[4], WorkDate() + 1, "Expense Reimbursement Type"::"Credit Card", false, CurrencyCode, 0, Amount);

        UpdateCurrencyCodeInJob(JobTask[1]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[2]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[3]."Job No.", JobCurrencyCode);
        UpdateCurrencyCodeInJob(JobTask[4]."Job No.", JobCurrencyCode);
    end;

    local procedure CalculateExpectedValuesForLCYOnHeader(
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
        PostingDate: Date;
        var ExpectedAmountLCY: array[4] of Decimal;
        var PaymentMethodAccAmtLCY: Decimal;
        var RefundableDebitAccountAmountLCY: Decimal;
        var EmployeePayableAccountAmountLCY: Decimal;
        var NonRefundableDebitAccountAmountLCY: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);

        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', PostingDate), Currency."Amount Rounding Precision");
    end;

    local procedure CalculateExpectedValuesForLCYOnHeaderForExpenseDateOnSetup(
        Amount: Decimal;
        AmountReduction: Decimal;
        CurrencyCode: Code[10];
        WorkDate: Date;
        var ExpectedAmountLCY: array[4] of Decimal;
        var PaymentMethodAccAmtLCY: Decimal;
        var RefundableDebitAccountAmountLCY: Decimal;
        var EmployeePayableAccountAmountLCY: Decimal;
        var NonRefundableDebitAccountAmountLCY: Decimal)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);

        ExpectedAmountLCY[1] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[2] := Amount;
        ExpectedAmountLCY[3] := Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision");
        ExpectedAmountLCY[4] := -Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision");
        PaymentMethodAccAmtLCY :=
            -Amount -
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate + 1), Currency."Amount Rounding Precision");
        RefundableDebitAccountAmountLCY :=
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision") +
            Amount +
            Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision");
        EmployeePayableAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(Amount - AmountReduction, CurrencyCode, '', WorkDate), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate + 1), Currency."Amount Rounding Precision") +
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate + 1), Currency."Amount Rounding Precision");
        NonRefundableDebitAccountAmountLCY :=
            -Round(LibraryERM.ConvertCurrency(AmountReduction, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision") -
            Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate + 2), Currency."Amount Rounding Precision");
    end;

    local procedure CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(
        var Expense: array[4] of Record Expense;
        var ExpenseUser: Record "Expense User";
        var ExpensePaymentMethod: Record "Expense Payment Method";
        var JobTask: Record "Job Task";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        CurrencyCode: Code[10];
        AmountReduction: Decimal;
        Amount: Decimal)
    begin
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[1], ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup[1], WorkDate(), "Expense Reimbursement Type"::"Employee Paid", true, true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[2], ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup[2], WorkDate(), "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode, 0, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[3], ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", true, true, CurrencyCode, AmountReduction, Amount);
        CreateAndReleaseExpenseWithJobTaskAndVATPostingSetup(Expense[4], ExpenseUser, ExpensePaymentMethod, JobTask, VATPostingSetup[1], WorkDate() + 1, "Expense Reimbursement Type"::"Company Paid", false, true, CurrencyCode, 0, Amount);
    end;

    local procedure VerifyLedgerEntriesForPostedExpenseReportWithVAT(
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        Expense: Record Expense;
        GLEntryCount: Integer;
        VATEntryCount: Integer;
        VATAmountLCY: array[5] of Decimal;
        PaymentMethodAccAmtLCY: Decimal;
        RefundableDebitAccountAmountLCY: Decimal;
        EmployeePayableAccountAmountLCY: Decimal;
        NonRefundableDebitAccountAmountLCY: Decimal)
    var
        ExpenseUser: Record "Expense User";
        ExpensePaymentMethod: Record "Expense Payment Method";
    begin
        ExpenseUser.Get(Expense."Expense User No.");
        ExpensePaymentMethod.Get(Expense."Payment Method Code");

        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableBankPaidAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), PaymentMethodAccAmtLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), RefundableDebitAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetExpensePayableCashAccountFromEmployeePostingGroup(ExpenseUser."Employee No."), EmployeePayableAccountAmountLCY);
        VerifyGLEntry(PostedExpenseReportHeader."No.", GetNonRefundableDebitAccountFromExpensePostingGroup(Expense."Expense Category"), NonRefundableDebitAccountAmountLCY);

        VerifyRecordCountOfGLEntry(PostedExpenseReportHeader, GLEntryCount);
        VerifyRecordCountOfGLEntryWithSourceCurrencyCode(PostedExpenseReportHeader."No.", PostedExpenseReportHeader."Reimbursement Currency Code", GLEntryCount);

        VerifyVATEntry(PostedExpenseReportHeader."No.", VATAmountLCY[1] + VATAmountLCY[2] + VATAmountLCY[3] + VATAmountLCY[4] + VATAmountLCY[5]);
        VerifyRecordCountOfVATEntry(PostedExpenseReportHeader."No.", VATEntryCount);

        VerifyEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
        VerifyDetailedEmployeeLedgerEntry(PostedExpenseReportHeader."No.", EmployeePayableAccountAmountLCY);
    end;

    local procedure VerifyRefundableAmountInExpenseReportLine(Expense: array[4] of Record Expense; ExpectedAmount: array[4] of Decimal; ExpectedAmountLCY: array[4] of Decimal)
    begin
        VerifyRefundableAmountInExpenseReportLine(Expense[1]."No.", ExpectedAmount[1], ExpectedAmountLCY[1]);
        VerifyRefundableAmountInExpenseReportLine(Expense[2]."No.", ExpectedAmount[2], ExpectedAmountLCY[2]);
        VerifyRefundableAmountInExpenseReportLine(Expense[3]."No.", ExpectedAmount[3], ExpectedAmountLCY[3]);
        VerifyRefundableAmountInExpenseReportLine(Expense[4]."No.", ExpectedAmount[4], ExpectedAmountLCY[4]);
    end;

    local procedure VerifyRefundableAmountInPostedExpenseReportLine(Expense: array[4] of Record Expense; ExpectedAmount: array[4] of Decimal; ExpectedAmountLCY: array[4] of Decimal)
    begin
        VerifyRefundableAmountInPostedExpenseReportLine(Expense[1]."No.", ExpectedAmount[1], ExpectedAmountLCY[1]);
        VerifyRefundableAmountInPostedExpenseReportLine(Expense[2]."No.", ExpectedAmount[2], ExpectedAmountLCY[2]);
        VerifyRefundableAmountInPostedExpenseReportLine(Expense[3]."No.", ExpectedAmount[3], ExpectedAmountLCY[3]);
        VerifyRefundableAmountInPostedExpenseReportLine(Expense[4]."No.", ExpectedAmount[4], ExpectedAmountLCY[4]);
    end;

    local procedure VerifyRefundableAmountInExpenseReportLine(ExpenseNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        Expense: Record Expense;
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Expense.Get(ExpenseNo);
        FindExpenseReportLine(ExpenseReportLine, Expense);

        if ExpenseReportLine.Refundable then begin
            Assert.AreEqual(
                ExpectedAmount,
                ExpenseReportLine."Refundable Amount",
                StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Refundable Amount"), ExpectedAmount, ExpenseReportLine.TableCaption()));
            Assert.AreEqual(
                ExpectedAmountLCY,
                ExpenseReportLine."Refundable Amount (LCY)",
                StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Refundable Amount (LCY)"), ExpectedAmountLCY, ExpenseReportLine.TableCaption()));
        end else begin
            Assert.AreEqual(
                0,
                ExpenseReportLine."Refundable Amount",
                StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Refundable Amount"), 0, ExpenseReportLine.TableCaption()));
            Assert.AreEqual(
                0,
                ExpenseReportLine."Refundable Amount (LCY)",
                StrSubstNo(ValueMustBeEqualErr, ExpenseReportLine.FieldCaption("Refundable Amount (LCY)"), 0, ExpenseReportLine.TableCaption()));
        end;
    end;

    local procedure VerifyRefundableAmountInPostedExpenseReportLine(ExpenseNo: Code[20]; ExpectedAmount: Decimal; ExpectedAmountLCY: Decimal)
    var
        Expense: Record Expense;
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        Expense.Get(ExpenseNo);
        FindPostedExpenseReportLine(PostedExpenseReportLine, Expense);

        if PostedExpenseReportLine.Refundable then begin
            Assert.AreEqual(
                ExpectedAmount,
                PostedExpenseReportLine."Refundable Amount",
                StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Refundable Amount"), ExpectedAmount, PostedExpenseReportLine.TableCaption()));
            Assert.AreEqual(
                ExpectedAmountLCY,
                PostedExpenseReportLine."Refundable Amount (LCY)",
                StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Refundable Amount (LCY)"), ExpectedAmountLCY, PostedExpenseReportLine.TableCaption()));
        end else begin
            Assert.AreEqual(
                0,
                PostedExpenseReportLine."Refundable Amount",
                StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Refundable Amount"), 0, PostedExpenseReportLine.TableCaption()));
            Assert.AreEqual(
                0,
                PostedExpenseReportLine."Refundable Amount (LCY)",
                StrSubstNo(ValueMustBeEqualErr, PostedExpenseReportLine.FieldCaption("Refundable Amount (LCY)"), 0, PostedExpenseReportLine.TableCaption()));
        end;
    end;

    local procedure CreateAndReleaseExpenseWithExpenseUser(var Expense: Record Expense; ExpenseUser: Record "Expense User"; ReimbursementType: Enum "Expense Reimbursement Type"; Refundable: Boolean; CurrencyCode: Code[10]; AmountReduction: Decimal; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseSubCategory: Record "Expense Subcategory";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
    begin
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ReimbursementType);

        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', Refundable, CurrencyCode, Amount);
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Validate("Non-Refundable Amount", AmountReduction);
        Expense.Modify();

        UpdateExpenseAccountInEmployeePostingGroup(ExpenseUser, Expense);
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);
    end;

    local procedure CreateUserSetupsAndChainOfApprovers(var CurrentUserSetup: Record "User Setup"; var FinalApproverUserSetup: Record "User Setup"; SubmitterExpenseUser: Record "Expense User")
    var
        ApproverExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        UserEmail: Text[80];
    begin
        LibraryDocumentApprovals.CreateOrFindUserSetup(CurrentUserSetup, CopyStr(UserId, 1, 50));

        UserEmail := LibraryUtility.GenerateRandomEmail();
        CreateAndUpdateUserWithEmail(CurrentUserSetup."User ID", UserEmail);

        SubmitterExpenseUser.Validate("E-mail", UserEmail);
        SubmitterExpenseUser.Validate("Can Approve", true);
        SubmitterExpenseUser.Validate("Entra Id", CreateGuid());
        SubmitterExpenseUser.Modify();

        LibraryDocumentApprovals.CreateMockupUserSetup(FinalApproverUserSetup);

        UserEmail := FinalApproverUserSetup."User ID" + '@' + 'example.com';
        CreateAndUpdateUserWithEmail(FinalApproverUserSetup."User ID", UserEmail);

        LibraryExpense.CreateExpenseUser(ApproverExpenseUser);
        ApproverExpenseUser.Validate("E-mail", UserEmail);
        ApproverExpenseUser.Validate("Can Approve", true);
        ApproverExpenseUser.Validate("Entra Id", CreateGuid());
        ApproverExpenseUser.Modify();

        LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, SubmitterExpenseUser."No.", ApproverExpenseUser."No.");
    end;

    local procedure CreateAndUpdateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            User."Authentication Email" := UserEmail;
            User.Modify();
        end else
            CreateUserWithEmail(UserName, UserEmail);
    end;

    local procedure CreateUserWithEmail(UserName: Code[50]; UserEmail: Text[80])
    var
        User: Record User;
    begin
        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserName;
        User."Authentication Email" := UserEmail;
        User.Insert(true);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.Cancel().Invoke();
    end;

    [PageHandler]
    procedure ExpenseReportPageHandler(var ExpenseReport: TestPage "Expense Report")
    begin
        ExpenseReport.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [PageHandler]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"G/L Entry"));
        GLPostingPreview."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());
        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    procedure ExpenseReportGLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Expense Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());

        GLPostingPreview.Filter.SetFilter("Table ID", Format(Database::"Employee Ledger Entry"));
        GLPostingPreview."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());

        GLPostingPreview.OK().Invoke();
    end;

    [PageHandler]
    procedure NavigateFindEntriesHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.Filter.SetFilter("Table ID", Format(Database::"Expense Ledger Entry"));
        Navigate."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());

        Navigate.Filter.SetFilter("Table ID", Format(Database::"Employee Ledger Entry"));
        Navigate."No. of Records".AssertEquals(LibraryVariableStorage.DequeueInteger());

        Navigate.OK().Invoke();
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
}