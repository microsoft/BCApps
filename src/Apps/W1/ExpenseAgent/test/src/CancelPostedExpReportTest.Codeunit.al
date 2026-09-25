// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;
using System.Automation;

codeunit 148319 "Cancel Posted Exp. Report Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        AlreadyCanceledErr: Label 'has already been canceled';

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelMarksPostedExpenseReportAsCanceled()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
    begin
        // [SCENARIO 636777] Cancelling a posted expense report sets header Status to Canceled and stamps every line Canceled = true.
        Initialize();

        // [GIVEN] Posted expense report.
        PostExpenseReport(Expense, PostedExpenseReportHeader);

        // [WHEN] Cancel the posted expense report.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] Header is flagged Canceled.
        PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No.");
        Assert.IsTrue(PostedExpenseReportHeader.Canceled, 'Posted Expense Report Header should be flagged as Canceled.');

        // [THEN] Every posted line is marked Canceled.
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        Assert.RecordIsEmpty(PostedExpenseReportLine);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelReversesExpenseLedgerEntries()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
        ReversingExpenseLedgerEntry: Record "Expense Ledger Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        OriginalEntryNo: Integer;
        OriginalAmount: Decimal;
    begin
        // [SCENARIO 636777] Cancelling a posted expense report marks the original Expense Ledger Entry as Reversed
        // and creates a mirror entry with negated amount and Reversed = true.
        Initialize();

        // [GIVEN] Posted expense report with an Expense Ledger Entry.
        PostExpenseReport(Expense, PostedExpenseReportHeader);

#pragma warning disable AA0210
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange(Reversed, false);
#pragma warning restore AA0210
        ExpenseLedgerEntry.FindFirst();
        OriginalEntryNo := ExpenseLedgerEntry."Entry No.";
        OriginalAmount := ExpenseLedgerEntry.Amount;

        // [WHEN] Cancel the posted expense report.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] Original Expense Ledger Entry is Reversed.
        ExpenseLedgerEntry.Get(OriginalEntryNo);
        Assert.IsTrue(ExpenseLedgerEntry.Reversed, 'Original Expense Ledger Entry should be marked Reversed.');
        Assert.AreNotEqual(0, ExpenseLedgerEntry."Reversed by Entry No.", 'Reversed by Entry No. should be set.');

        // [THEN] A mirror Expense Ledger Entry exists with negated amount and Reversed = true.
        ReversingExpenseLedgerEntry.Get(ExpenseLedgerEntry."Reversed by Entry No.");
        Assert.AreEqual(
            -OriginalAmount,
            ReversingExpenseLedgerEntry.Amount,
            StrSubstNo(ValueMustBeEqualErr, ReversingExpenseLedgerEntry.FieldCaption(Amount),
                Format(-OriginalAmount), ReversingExpenseLedgerEntry.TableCaption()));
        Assert.IsTrue(ReversingExpenseLedgerEntry.Reversed, 'Reversing Expense Ledger Entry should be marked Reversed.');
        Assert.AreEqual(
            OriginalEntryNo,
            ReversingExpenseLedgerEntry."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, ReversingExpenseLedgerEntry.FieldCaption("Reversed Entry No."),
                OriginalEntryNo, ReversingExpenseLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelReversesGLEntriesAndSumsToZero()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        GLEntry: Record "G/L Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        TotalAmountLCY: Decimal;
    begin
        // [SCENARIO 636777] Cancelling a posted expense report posts a reversal G/L transaction.
        // All G/L Entries carrying the document number must net to zero.
        Initialize();

        // [GIVEN] Posted expense report.
        PostExpenseReport(Expense, PostedExpenseReportHeader);

        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        Assert.IsFalse(GLEntry.IsEmpty(), 'G/L Entries should exist for the posted expense report.');

        // [WHEN] Cancel the posted expense report.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] G/L Entries for the document net to zero (original + reversal).
        GLEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        GLEntry.CalcSums(Amount);
        TotalAmountLCY := GLEntry.Amount;
        Assert.AreEqual(
            0,
            TotalAmountLCY,
            StrSubstNo(ValueMustBeEqualErr, GLEntry.FieldCaption(Amount), 0, GLEntry.TableCaption()));

        // [THEN] Every G/L Entry for the document is marked Reversed.
        GLEntry.SetRange(Reversed, false);
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelReleasesRelatedExpense()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
    begin
        // [SCENARIO 636777] Cancelling a posted expense report releases the originating Expense so it can be reused.
        Initialize();

        // [GIVEN] Posted expense report referencing an Expense.
        PostExpenseReport(Expense, PostedExpenseReportHeader);

        // [WHEN] Cancel the posted expense report.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] The Expense is Released with no posted/open report reference.
        Expense.Get(Expense."No.");
        Assert.AreEqual(
            Expense.Status::Released,
            Expense.Status,
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption(Status),
                Format(Expense.Status::Released), Expense.TableCaption()));
        Assert.AreEqual(
            '',
            Expense."Posted Expense Report No.",
            StrSubstNo(ValueMustBeEqualErr, Expense.FieldCaption("Posted Expense Report No."), '', Expense.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CannotCancelAlreadyCanceledReport()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
    begin
        // [SCENARIO 636777] A second cancel on an already-canceled posted expense report raises an error.
        Initialize();

        // [GIVEN] Posted expense report canceled once.
        PostExpenseReport(Expense, PostedExpenseReportHeader);
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [WHEN] Cancel again.
        asserterror CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] Error is raised stating the report is already canceled.
        Assert.ExpectedError(AlreadyCanceledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure MultiLineExpenseReportSharesSingleTransactionNo()
    var
        GLEntry: Record "G/L Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseLedgerEntry: Record "Expense Ledger Entry";
    begin
        // [SCENARIO 636777] All Expense Ledger Entries of a multi-line posted expense report (employee paid + credit card)
        // share a single, non-zero Transaction No.
        Initialize();

        // [GIVEN] Posted expense report with multiple lines of different reimbursement types.
        PostMultiLineExpenseReport(PostedExpenseReportHeader);

        // [WHEN] Find GL Entry for the posted expense report.
        FindGLEntry(GLEntry, PostedExpenseReportHeader."No.");

        // [THEN] Verify a single Transaction No. is shared across all related Expense Ledger Entries.
        ExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ExpenseLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        VerifyRecordCountOfExpenseLedgerEntry(ExpenseLedgerEntry, 3);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelMultiLineReportGeneratesNewTransactionNoForReversedLines()
    var
        GLEntry: Record "G/L Entry";
        ReversalGLEntry: Record "G/L Entry";
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ReversalExpenseLedgerEntry: Record "Expense Ledger Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
    begin
        // [SCENARIO 636777] Cancelling a multi-line posted expense report generates reversal Expense Ledger Entries
        // that all share a single new Transaction No., distinct from the original document Transaction No.
        Initialize();

        // [GIVEN] Posted multi-line expense report carrying a single original Transaction No.
        PostMultiLineExpenseReport(PostedExpenseReportHeader);

        // [GIVEN] Find GL Entry for the posted expense report.
        FindGLEntry(GLEntry, PostedExpenseReportHeader."No.");

        // [WHEN] Cancel the posted expense report.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] Find Reversal GL Entry linked to the original by Reversed Entry No.
#pragma warning disable AA0210
        ReversalGLEntry.SetRange("Reversed Entry No.", GLEntry."Entry No.");
        ReversalGLEntry.FindFirst();
#pragma warning restore AA0210

        // [THEN] All reversal Expense Ledger Entries share a single new Transaction No. distinct from the original.
        ReversalExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ReversalExpenseLedgerEntry.SetRange("Transaction No.", ReversalGLEntry."Transaction No.");
        ReversalExpenseLedgerEntry.SetRange(Reversed, true);
        VerifyRecordCountOfExpenseLedgerEntry(ReversalExpenseLedgerEntry, 3);

        ReversalExpenseLedgerEntry.SetRange("Document No.", PostedExpenseReportHeader."No.");
        ReversalExpenseLedgerEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        ReversalExpenseLedgerEntry.SetRange(Reversed, true);
        VerifyRecordCountOfExpenseLedgerEntry(ReversalExpenseLedgerEntry, 3);

        ReversalExpenseLedgerEntry.SetRange("Transaction No.");
        VerifyRecordCountOfExpenseLedgerEntry(ReversalExpenseLedgerEntry, 6);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure PostingDoesNotCopyUserConfirmedIntoCanceled()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO 647233] Posting must not copy User Confirmed into the posted line's Canceled field.
        Initialize();

        // [GIVEN] A posted expense report where the source line had User Confirmed = true.
        PostExpenseReportWithUserConfirmed(Expense, PostedExpenseReportHeader);

        // [THEN] The posted line must not be marked as Canceled.
        PostedExpenseReportLine.SetRange("Document No.", PostedExpenseReportHeader."No.");
        PostedExpenseReportLine.FindFirst();
        Assert.IsFalse(PostedExpenseReportLine."Is Canceled", 'Is Canceled must not be set by TransferFields from User Confirmed.');
    end;

    local procedure Initialize()
    var
        Workflow: Record Workflow;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Cancel Posted Exp. Report Test");
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.CleanTransactionalData();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Cancel Posted Exp. Report Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdateLocalData();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);
        LibraryExpense.UpdateUseRulesInAgentSetup(true);
        Workflow.DeleteAll();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Cancel Posted Exp. Report Test");
    end;

    local procedure PostExpenseReport(var Expense: Record Expense; var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        PostCode: Record "Post Code";
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        ExpenseReportHeader: Record "Expense Report Header";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        LibraryERM.FindPostCode(PostCode);
        CreateExpense(Expense, LibraryRandom.RandInt(100));

        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");

        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        PostedExpenseReportHeader.SetRange("Expense User No.", Expense."Expense User No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure CreateExpense(var Expense: Record Expense; Amount: Decimal)
    var
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        ExpenseSubCategory: Record "Expense Subcategory";
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        LibraryExpense.CreateExpenseCategory(ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ");
        LibraryExpense.CreateExpenseSubCategory(ExpenseSubCategory, ExpenseCategory.Code, true);
        LibraryExpense.CreateExpenseWithZeroVATPostingSetup(Expense, ExpenseUser."No.", ExpenseCategory.Code, ExpenseSubCategory.Code, '', true, '', Amount);
    end;

    local procedure PostExpenseReportWithUserConfirmed(var Expense: Record Expense; var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        PostExpenseReportUpToRelease(Expense, ExpenseReportHeader);

        ExpenseReportLine.SetRange("Document No.", ExpenseReportHeader."No.");
        ExpenseReportLine.FindFirst();
        ExpenseReportLine."User Confirmed" := true;
        ExpenseReportLine.Modify();

        ExpenseReportHeader.PerformManualRelease();

        PostExpenseReportFromHeader(ExpenseReportHeader, PostedExpenseReportHeader, Expense."Expense User No.");
    end;

    local procedure PostExpenseReportUpToRelease(var Expense: Record Expense; var ExpenseReportHeader: Record "Expense Report Header")
    var
        Employee: Record Employee;
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        ReleaseExpenseDocument: Codeunit "Release Expense Document";
        CreateExpenseReport: Codeunit "Create Expense Report";
    begin
        CreateExpense(Expense, LibraryRandom.RandInt(100));
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");
        Expense.Validate("Payment Method Code", ExpensePaymentMethod.Code);
        Expense.Modify();

        ExpenseCategory.Get(Expense."Expense Category");
        ExpenseUser.Get(Expense."Expense User No.");
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
        ExpensePostingGroup.Get(ExpenseCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();
        ReleaseExpenseDocument.PerformManualCheckAndRelease(Expense);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
    end;

    local procedure PostExpenseReportFromHeader(var ExpenseReportHeader: Record "Expense Report Header"; var PostedExpenseReportHeader: Record "Posted Expense Report Header"; ExpenseUserNo: Code[20])
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUserNo);
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure PostMultiLineExpenseReport(var PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        Employee: Record Employee;
        ExpenseUser: Record "Expense User";
        EmployeePaidCategory: Record "Expense Category";
        CompanyPaidCategory: Record "Expense Category";
        ExpensePostingGroup: Record "Expense Posting Group";
        Expense: array[3] of Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        // Create one Expense User and post a multi-line report mixing Employee Paid and Credit Card lines.
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");

        LibraryExpense.CreateExpenseCategory(EmployeePaidCategory, EmployeePaidCategory."Reimbursement Type"::"Employee Paid", EmployeePaidCategory."Expense Detail Required"::" ");
        ExpensePostingGroup.Get(EmployeePaidCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        LibraryExpense.CreateExpenseCategory(CompanyPaidCategory, CompanyPaidCategory."Reimbursement Type"::"Company Paid", CompanyPaidCategory."Expense Detail Required"::" ");
        ExpensePostingGroup.Get(CompanyPaidCategory."Posting Group");
        ExpensePostingGroup.Validate("Refundable Debit Account", LibraryERM.CreateGLAccountNo());
        ExpensePostingGroup.Modify();

        // Two Employee Paid lines and one Company Paid (credit card) line for the same Expense User.
        CreateAndReleaseExpenseForUser(Expense[1], EmployeePaidCategory, ExpenseUser);
        CreateAndReleaseExpenseForUser(Expense[2], EmployeePaidCategory, ExpenseUser);
        CreateAndReleaseExpenseForUser(Expense[3], CompanyPaidCategory, ExpenseUser);

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', Expense[1]."VAT Bus. Posting Group");
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        CreateExpenseReport.AddExpensesToReport(ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        PostedExpenseReportHeader.SetRange("Expense User No.", ExpenseUser."No.");
        PostedExpenseReportHeader.FindFirst();
    end;

    local procedure CreateAndReleaseExpenseForUser(var Expense: Record Expense; ExpenseCategory: Record "Expense Category"; ExpenseUser: Record "Expense User")
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

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; PostedDocumentNo: Code[20]): Boolean
    begin
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure VerifyRecordCountOfExpenseLedgerEntry(var ExpenseLedgerEntry: Record "Expense Ledger Entry"; ExpectedCount: Integer)
    begin
        Assert.RecordCount(ExpenseLedgerEntry, ExpectedCount);
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
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
}
