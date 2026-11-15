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
using System.Security.AccessControl;

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
        CancelConfirmPrefixTxt: Label 'Do you want to cancel posted expense report', Locked = true;

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

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelFromPostedReportPageLogsCanceledActivity()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        TempPriorExpenseActivityLogEntry: Record "Expense Activity Log Entry" temporary;
        PostedExpenseReport: TestPage "Posted Expense Report";
        OriginalSubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] Cancelling a posted expense report from the posted report page adds a Canceled entry to its history.
        Initialize();

        // [GIVEN] A posted expense report whose activity history started with a submission before posting.
        PostExpenseReportWithHistory(Expense, PostedExpenseReportHeader, OriginalSubjectSystemID);
        CopyPostedReportHistory(PostedExpenseReportHeader, TempPriorExpenseActivityLogEntry);
        Assert.RecordCount(TempPriorExpenseActivityLogEntry, 2);

        // [WHEN] The user cancels the report from the Posted Expense Report page and confirms.
        PostedExpenseReport.OpenView();
        PostedExpenseReport.GoToRecord(PostedExpenseReportHeader);
        PostedExpenseReport.CancelPostedExpenseReport.Invoke();
        PostedExpenseReport.Close();

        // [THEN] Exactly one Canceled entry is owned by the posted report and continues the original report subject.
        FindSingleCanceledEntry(PostedExpenseReportHeader, ExpenseActivityLogEntry);
        Assert.AreEqual(Database::"Expense Report Header", ExpenseActivityLogEntry."Subject Table ID", 'The Canceled entry must keep the original report subject table.');
        Assert.AreEqual(OriginalSubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'The Canceled entry must keep the original report subject.');
        TempPriorExpenseActivityLogEntry.FindFirst();
        Assert.AreEqual(TempPriorExpenseActivityLogEntry."Document No.", ExpenseActivityLogEntry."Document No.", 'The Canceled entry must keep the report document number of its history.');

        // [THEN] The current Business Central user is the actor, identified by the User SystemId.
        VerifyCurrentBCUserActor(ExpenseActivityLogEntry);

        // [THEN] Earlier history is unchanged and the Canceled entry is the latest one.
        VerifyPriorHistoryUnchanged(TempPriorExpenseActivityLogEntry, ExpenseActivityLogEntry);

        // [THEN] The posted report page history shows the Canceled entry first.
        PostedExpenseReport.OpenView();
        PostedExpenseReport.GoToRecord(PostedExpenseReportHeader);
        PostedExpenseReport.Activity.First();
        Assert.AreEqual(
            Format(Enum::"Expense Activity Event Type"::Canceled), PostedExpenseReport.Activity."Event Type".Value(),
            'The posted report history must show the Canceled entry first.');
        PostedExpenseReport.Close();
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler')]
    procedure CancelOnRunLogsCanceledActivity()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        TempPriorExpenseActivityLogEntry: Record "Expense Activity Log Entry" temporary;
        OriginalSubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] Running the Cancel Posted Expense Report codeunit adds one Canceled entry to the posted report history.
        Initialize();

        // [GIVEN] A posted expense report with activity history.
        PostExpenseReportWithHistory(Expense, PostedExpenseReportHeader, OriginalSubjectSystemID);
        CopyPostedReportHistory(PostedExpenseReportHeader, TempPriorExpenseActivityLogEntry);

        // [WHEN] The report is canceled through the codeunit OnRun trigger.
        Codeunit.Run(Codeunit::"Cancel Posted Expense Report", PostedExpenseReportHeader);

        // [THEN] One Canceled entry continues the original subject, performed by the current user, after unchanged earlier history.
        PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No.");
        Assert.IsTrue(PostedExpenseReportHeader.Canceled, 'The posted expense report must be canceled.');
        FindSingleCanceledEntry(PostedExpenseReportHeader, ExpenseActivityLogEntry);
        Assert.AreEqual(OriginalSubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'The Canceled entry must keep the original report subject.');
        VerifyCurrentBCUserActor(ExpenseActivityLogEntry);
        VerifyPriorHistoryUnchanged(TempPriorExpenseActivityLogEntry, ExpenseActivityLogEntry);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelWithoutActivityHistoryLogsNoActivity()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
    begin
        // [SCENARIO 656401] Like posting, cancellation does not start activity history for a report without it.
        Initialize();

        // [GIVEN] A posted expense report without activity history.
        PostExpenseReport(Expense, PostedExpenseReportHeader);
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);

        // [WHEN] The report is canceled.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] The report is canceled and no activity entry is logged.
        PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No.");
        Assert.IsTrue(PostedExpenseReportHeader.Canceled, 'The posted expense report must be canceled.');
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelIgnoresOtherSourceHistoryWithSameSystemId()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        OriginalSubjectSystemID: Guid;
        DecoySubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] The Canceled entry takes its subject only from history owned by the posted report.
        Initialize();

        // [GIVEN] A posted expense report with activity history.
        PostExpenseReportWithHistory(Expense, PostedExpenseReportHeader, OriginalSubjectSystemID);

        // [GIVEN] A later entry of an expense report source that has the same SystemId as the posted report.
        DecoySubjectSystemID := InsertSourcePairDecoy(PostedExpenseReportHeader);

        // [WHEN] The report is canceled.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] The Canceled entry keeps the posted report's own subject, not the decoy subject.
        FindSingleCanceledEntry(PostedExpenseReportHeader, ExpenseActivityLogEntry);
        Assert.AreEqual(OriginalSubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'The Canceled entry must keep the posted report subject.');
        Assert.AreNotEqual(DecoySubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'The Canceled entry must not use the subject of another source.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure CancelWithoutOwnHistoryIgnoresOtherSourceWithSameSystemId()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        DecoySubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] History of another source with the same SystemId does not make cancellation log activity.
        Initialize();

        // [GIVEN] A posted expense report without activity history and an expense report source entry with its SystemId.
        PostExpenseReport(Expense, PostedExpenseReportHeader);
        DecoySubjectSystemID := InsertSourcePairDecoy(PostedExpenseReportHeader);

        // [WHEN] The report is canceled.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] No Canceled entry is logged and only the decoy entry remains.
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::Canceled);
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
        ExpenseActivityLogEntry.Reset();
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        ExpenseActivityLogEntry.FindFirst();
        Assert.AreEqual(DecoySubjectSystemID, ExpenseActivityLogEntry."Subject System ID", 'The decoy entry must be unchanged.');
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure RepeatCancelDoesNotLogSecondCanceledActivity()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        PostedExpenseReport: TestPage "Posted Expense Report";
        OriginalSubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] A canceled report has one Canceled entry and a repeat cancellation is rejected before it logs.
        Initialize();

        // [GIVEN] A posted expense report with activity history, canceled once.
        PostExpenseReportWithHistory(Expense, PostedExpenseReportHeader, OriginalSubjectSystemID);
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] The history has exactly one Canceled entry after Submitted and Posted.
        FindSingleCanceledEntry(PostedExpenseReportHeader, ExpenseActivityLogEntry);
        ExpenseActivityLogEntry.Reset();
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        Assert.RecordCount(ExpenseActivityLogEntry, 3);

        // [THEN] The posted report page no longer offers Cancel.
        PostedExpenseReport.OpenView();
        PostedExpenseReport.GoToRecord(PostedExpenseReportHeader);
        Assert.IsFalse(PostedExpenseReport.CancelPostedExpenseReport.Enabled(), 'Cancel must be disabled for a canceled report.');
        PostedExpenseReport.Close();

        // [WHEN] The report is canceled again through OnRun.
        asserterror Codeunit.Run(Codeunit::"Cancel Posted Expense Report", PostedExpenseReportHeader);

        // [THEN] The repeat cancellation is rejected.
        Assert.ExpectedError(AlreadyCanceledErr);
    end;

    [Test]
    [HandlerFunctions('ExpensesModalPageHandler,DeclineCancelConfirmHandler')]
    procedure DeclinedCancelConfirmationLogsNoActivity()
    var
        Expense: Record Expense;
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
        TempPriorExpenseActivityLogEntry: Record "Expense Activity Log Entry" temporary;
        CancelPostedExpReport: Codeunit "Cancel Posted Expense Report";
        OriginalSubjectSystemID: Guid;
    begin
        // [SCENARIO 656401] Declining the cancel confirmation neither cancels the report nor logs a Canceled entry.
        Initialize();

        // [GIVEN] A posted expense report with activity history.
        PostExpenseReportWithHistory(Expense, PostedExpenseReportHeader, OriginalSubjectSystemID);
        CopyPostedReportHistory(PostedExpenseReportHeader, TempPriorExpenseActivityLogEntry);

        // [WHEN] The user declines the cancel confirmation.
        CancelPostedExpReport.CancelPostedExpenseReport(PostedExpenseReportHeader);

        // [THEN] The report is not canceled and its history is unchanged.
        PostedExpenseReportHeader.Get(PostedExpenseReportHeader."No.");
        Assert.IsFalse(PostedExpenseReportHeader.Canceled, 'The posted expense report must not be canceled.');
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::Canceled);
        Assert.RecordIsEmpty(ExpenseActivityLogEntry);
        ExpenseActivityLogEntry.Reset();
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        Assert.RecordCount(ExpenseActivityLogEntry, TempPriorExpenseActivityLogEntry.Count());
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

    local procedure PostExpenseReportWithHistory(var Expense: Record Expense; var PostedExpenseReportHeader: Record "Posted Expense Report Header"; var OriginalSubjectSystemID: Guid)
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseActivityLogMgt: Codeunit "Expense Activity Log Mgt.";
    begin
        PostExpenseReportUpToRelease(Expense, ExpenseReportHeader);
        ExpenseReportHeader.PerformManualRelease();
        OriginalSubjectSystemID := ExpenseReportHeader.SystemId;
        ExpenseActivityLogMgt.LogExpenseReportEvent(
            ExpenseReportHeader,
            Enum::"Expense Activity Event Type"::Submitted,
            Enum::"Expense Activity Initiator"::User,
            Enum::"Expense Activity Actor Role"::Submitter,
            ExpenseReportHeader."Expense User No.",
            '');

        PostExpenseReportFromHeader(ExpenseReportHeader, PostedExpenseReportHeader, Expense."Expense User No.");
    end;

    local procedure CopyPostedReportHistory(PostedExpenseReportHeader: Record "Posted Expense Report Header"; var TempExpenseActivityLogEntry: Record "Expense Activity Log Entry" temporary)
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", PostedExpenseReportHeader.SystemId);
        if ExpenseActivityLogEntry.FindSet() then
            repeat
                TempExpenseActivityLogEntry := ExpenseActivityLogEntry;
                TempExpenseActivityLogEntry.Insert();
            until ExpenseActivityLogEntry.Next() = 0;
    end;

    local procedure FindSingleCanceledEntry(PostedExpenseReportHeader: Record "Posted Expense Report Header"; var ExpenseActivityLogEntry: Record "Expense Activity Log Entry")
    begin
        ExpenseActivityLogEntry.SetRange("Event Type", Enum::"Expense Activity Event Type"::Canceled);
        Assert.RecordCount(ExpenseActivityLogEntry, 1);
        ExpenseActivityLogEntry.FindFirst();
        Assert.AreEqual(Database::"Posted Expense Report Header", ExpenseActivityLogEntry."Source Table ID", 'The Canceled entry must be owned by the posted report table.');
        Assert.AreEqual(PostedExpenseReportHeader.SystemId, ExpenseActivityLogEntry."Source Record System ID", 'The Canceled entry must be owned by the posted report.');
    end;

    local procedure VerifyCurrentBCUserActor(ExpenseActivityLogEntry: Record "Expense Activity Log Entry")
    var
        User: Record User;
    begin
        User.Get(UserSecurityId());
        Assert.AreEqual(Enum::"Expense Activity Initiator"::User, ExpenseActivityLogEntry."Initiated By", 'Cancellation must be initiated by a user.');
        Assert.AreEqual(Database::User, ExpenseActivityLogEntry."Actor Table ID", 'Cancellation must identify the current BC User actor.');
        Assert.AreEqual(User.SystemId, ExpenseActivityLogEntry."Actor Record System ID", 'Cancellation must store the User SystemId.');
        Assert.AreNotEqual(User."User Security ID", ExpenseActivityLogEntry."Actor Record System ID", 'Cancellation must not store the user security ID.');
    end;

    local procedure VerifyPriorHistoryUnchanged(var TempPriorExpenseActivityLogEntry: Record "Expense Activity Log Entry" temporary; CanceledExpenseActivityLogEntry: Record "Expense Activity Log Entry")
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        ExpenseActivityLogEntry.SetRange("Source Table ID", Database::"Posted Expense Report Header");
        ExpenseActivityLogEntry.SetRange("Source Record System ID", CanceledExpenseActivityLogEntry."Source Record System ID");
        Assert.RecordCount(ExpenseActivityLogEntry, TempPriorExpenseActivityLogEntry.Count() + 1);

        TempPriorExpenseActivityLogEntry.FindSet();
        repeat
            ExpenseActivityLogEntry.Get(TempPriorExpenseActivityLogEntry."Entry No.");
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Event Type", ExpenseActivityLogEntry."Event Type", 'Earlier event types must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Occurred At", ExpenseActivityLogEntry."Occurred At", 'Earlier event times must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Subject System ID", ExpenseActivityLogEntry."Subject System ID", 'Earlier subjects must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Actor Record System ID", ExpenseActivityLogEntry."Actor Record System ID", 'Earlier actors must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Amount (LCY)", ExpenseActivityLogEntry."Amount (LCY)", 'Earlier amount snapshots must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry."Expense Count", ExpenseActivityLogEntry."Expense Count", 'Earlier contents snapshots must be unchanged.');
            Assert.AreEqual(TempPriorExpenseActivityLogEntry.Categories, ExpenseActivityLogEntry.Categories, 'Earlier category snapshots must be unchanged.');
            Assert.IsTrue(CanceledExpenseActivityLogEntry."Entry No." > ExpenseActivityLogEntry."Entry No.", 'The Canceled entry must follow earlier entries.');
            Assert.IsTrue(CanceledExpenseActivityLogEntry."Occurred At" >= ExpenseActivityLogEntry."Occurred At", 'The Canceled entry must not precede earlier entries.');
        until TempPriorExpenseActivityLogEntry.Next() = 0;

        Assert.AreEqual(0, CanceledExpenseActivityLogEntry."Amount (LCY)", 'The Canceled entry has no amount snapshot.');
        Assert.AreEqual(0, CanceledExpenseActivityLogEntry."Expense Count", 'The Canceled entry has no contents snapshot.');
    end;

    local procedure InsertSourcePairDecoy(PostedExpenseReportHeader: Record "Posted Expense Report Header") DecoySubjectSystemID: Guid
    var
        ExpenseActivityLogEntry: Record "Expense Activity Log Entry";
    begin
        // Same SystemId as the posted report, but owned by an expense report source and logged later than its own history.
        DecoySubjectSystemID := CreateGuid();
        ExpenseActivityLogEntry.Init();
        ExpenseActivityLogEntry."Source Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Source Record System ID" := PostedExpenseReportHeader.SystemId;
        ExpenseActivityLogEntry."Subject Table ID" := Database::"Expense Report Header";
        ExpenseActivityLogEntry."Subject System ID" := DecoySubjectSystemID;
        ExpenseActivityLogEntry."Event Type" := Enum::"Expense Activity Event Type"::Submitted;
        ExpenseActivityLogEntry."Occurred At" := CurrentDateTime() + 60 * 60 * 1000;
        ExpenseActivityLogEntry.Insert();
    end;

    [ModalPageHandler]
    procedure ExpensesModalPageHandler(var Expenses: TestPage Expenses)
    begin
        Expenses.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DeclineCancelConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not Question.StartsWith(CancelConfirmPrefixTxt);
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
