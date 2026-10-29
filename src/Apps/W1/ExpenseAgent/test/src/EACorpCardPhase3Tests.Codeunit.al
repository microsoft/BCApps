// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.Bank.Ledger;
using Microsoft.ExpenseAgent;
using System.IO;
using System.Threading;
using System.Utilities;

codeunit 148353 EACorpCardPhase3Tests
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        EACorpCardTestLib: Codeunit EACorpCardTestLib;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        PostedTransactionDeletionErr: Label 'cannot be deleted because it has been posted or is referenced by a posted expense report or bank account ledger entry.', Locked = true;
        LinkedTransactionDeletionErr: Label 'cannot be deleted because it is linked to an expense or expense report.', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure XmlImportWithMalformedPayloadFailsStatement()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        Initialize();
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, GetMalformedXmlPayload(), MalformedXmlFileNameTok);

        BindSubscription(EACorpCardTestLib);
        asserterror EACorpCardTestLib.RunFileImport(CorpCardXmlProviderCodeTok);
        UnbindSubscription(EACorpCardTestLib);
        Assert.ExpectedError(MalformedXmlRootElementTok);

        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);

        CorpCardStatement.SetRange("Provider Code", CorpCardXmlProviderCodeTok);
        Assert.IsTrue(CorpCardStatement.FindLast(), 'Failed import must create a statement.');
        EACorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
        Assert.AreEqual(CorpCardStatement.Status::Failed, CorpCardStatement.Status, 'Failed imports must finalize the statement as failed.');
        Assert.IsTrue(CorpCardStatement."Ended DT" <> 0DT, 'Failed imports must record the statement end date and time.');
        Assert.AreEqual(MalformedXmlFileNameTok, CorpCardStatement."Source File Name", 'A rolled-back parse must retain the selected file name.');
        Assert.IsTrue(CorpCardStatement."Source Payload Hash" <> '', 'A rolled-back parse must retain the source hash.');
        Assert.AreEqual(0, CorpCardStatement."Data Exch Entry No.", 'A rolled-back parse must not retain the source data exchange.');
        Assert.AreEqual(CorpCardStatement."Statement Entry No.", CorpCardProvider."Last Statement Entry No.", 'Failed imports must update the provider with the failed statement entry number.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AllRejectedCsvImportRetainsRowDiagnostics()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        SetAllRejectedCsvPayload();

        BindSubscription(EACorpCardTestLib);
        asserterror EACorpCardTestLib.RunFileImport(CorpCardCsvProviderCodeTok);
        UnbindSubscription(EACorpCardTestLib);

        Assert.ExpectedError('All 2 transaction lines');
        AssertRejectedCsvStatement(CorpCardStatement);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AllRejectedCsvReturnsActionableFailureWithoutUpdatingLastImport()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        ImportErrorInfo: ErrorInfo;
        ImportErrorText: Text;
        HasStructuredErrorInfo: Boolean;
        LastSuccessfulImport: DateTime;
    begin
        Initialize();
        SetAllRejectedCsvPayload();
        LastSuccessfulImport := CreateDateTime(DMY2Date(1, 1, 2026), 120000T);
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CorpCardProvider."Last Import DT" := LastSuccessfulImport;
        CorpCardProvider.Modify(true);

        BindSubscription(EACorpCardTestLib);
        Assert.IsFalse(
            CorpCardImportOrch.RunProvider(CorpCardProvider, false, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo),
            'All-rejected CSV input must return a failed import outcome.');
        UnbindSubscription(EACorpCardTestLib);

        AssertRejectedCsvStatement(CorpCardStatement);
        Assert.IsTrue(HasStructuredErrorInfo, 'The validation failure must retain structured error information.');
        Assert.AreEqual(ImportErrorText, ImportErrorInfo.Message, 'The returned error must explain the validation failure.');
        Assert.AreEqual(Page::"EA Corp Card Statement", ImportErrorInfo.PageNo, 'The recovery action must open the statement with the retained exceptions.');
        Assert.AreEqual(CorpCardStatement.RecordId, ImportErrorInfo.RecordId, 'The recovery action must target the failed statement.');
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        Assert.AreEqual(LastSuccessfulImport, CorpCardProvider."Last Import DT", 'A validation failure must not overwrite the last successful import time.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure AllRejectedCsvStagingCommitsDiagnosticsWithoutAcknowledgment()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        CorpCardErrorContext: Codeunit "EA Corp Card Error Context";
    begin
        Initialize();
        SetAllRejectedCsvPayload();
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := CorpCardCsvProviderCodeTok;
        CorpCardStatement.Status := CorpCardStatement.Status::Importing;
        CorpCardStatement.Insert(true);
        CorpCardErrorContext.ClearErrorInfo();
        Commit();

        BindSubscription(EACorpCardTestLib);
        Assert.IsTrue(CorpCardImportOrch.Run(CorpCardStatement), 'Row validation failures must return without rolling back their diagnostics.');
        UnbindSubscription(EACorpCardTestLib);

        CorpCardStatement.Get(CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(CorpCardStatement.Status::Failed, CorpCardStatement.Status, 'The committed staging outcome must indicate validation failure.');
        Assert.AreEqual(2, CorpCardStatement.Rejected, 'The staging transaction must retain the exact rejection count.');
        Assert.AreEqual(2, CorpCardStatement.Exceptions, 'The staging transaction must retain its exception count.');
        Assert.AreEqual('Parse', CorpCardErrorContext.GetImportStage(), 'Failed validation must not advance to provider acknowledgment.');
        CorpCardErrorContext.ClearErrorInfo();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScheduleShowsOnlyCorporateCardImportsIncludingAllProviders()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        JobQueueEntry: Record "Job Queue Entry";
        EmptyRecordId: RecordId;
        SchedulePage: TestPage "EA Corp Card JQ Schedule";
        VisibleCount: Integer;
        AllProvidersVisible: Boolean;
    begin
        Initialize();
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-TEST-CSV', CorpCardProvider.RecordId);
        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-TEST-XML', CorpCardProvider.RecordId);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-TEST-ALL', EmptyRecordId);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-TEST-OTHER', EmptyRecordId);
        JobQueueEntry."Object ID to Run" := Codeunit::Assert;
        JobQueueEntry.Modify(false);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-TEST-REPORT', EmptyRecordId);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry.Modify(false);

        SchedulePage.OpenView();
        SchedulePage.Schedule.Filter.SetFilter(Description, 'CORP-SCHEDULE-TEST-*');
        Assert.IsTrue(SchedulePage.Schedule.First(), 'The schedule must contain the corporate-card import entries.');
        repeat
            Assert.IsTrue(
                SchedulePage.Schedule.Description.Value() in ['CORP-SCHEDULE-TEST-CSV', 'CORP-SCHEDULE-TEST-XML', 'CORP-SCHEDULE-TEST-ALL'],
                'Unrelated codeunits and reports must not appear in the corporate-card schedule.');
            AllProvidersVisible := AllProvidersVisible or (SchedulePage.Schedule.Description.Value() = 'CORP-SCHEDULE-TEST-ALL');
            VisibleCount += 1;
        until not SchedulePage.Schedule.Next();
        Assert.AreEqual(3, VisibleCount, 'The schedule must show both providers and the all-providers import entry.');
        Assert.IsTrue(AllProvidersVisible, 'An empty record ID is valid for an all-providers import and must not close the schedule.');
        SchedulePage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ScheduleWithNoMatchingImportsRemainsOpen()
    var
        JobQueueEntry: Record "Job Queue Entry";
        EmptyRecordId: RecordId;
        SchedulePage: TestPage "EA Corp Card JQ Schedule";
    begin
        Initialize();
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-SCHEDULE-EMPTY-OTHER', EmptyRecordId);
        JobQueueEntry."Object ID to Run" := Codeunit::Assert;
        JobQueueEntry.Modify(false);

        SchedulePage.OpenView();
        SchedulePage.Schedule.Filter.SetFilter(Description, 'CORP-SCHEDULE-EMPTY-*');
        Assert.IsFalse(SchedulePage.Schedule.First(), 'The schedule must be empty when only unrelated entries match the user filter.');
        SchedulePage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ProviderImportPreservesActionableProviderError()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        ImportErrorInfo: ErrorInfo;
        ImportErrorText: Text;
        HasStructuredErrorInfo: Boolean;
    begin
        Initialize();
        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, EmptyXmlPayloadTok, EmptyXmlFileNameTok);

        BindSubscription(EACorpCardTestLib);
        Assert.IsFalse(
            CorpCardImportOrch.RunProvider(CorpCardProvider, false, ImportErrorText, ImportErrorInfo, HasStructuredErrorInfo),
            'XML with no transaction rows must produce a provider setup error.');
        UnbindSubscription(EACorpCardTestLib);
        Assert.IsTrue(HasStructuredErrorInfo, 'The failed import must retain structured error information.');
        Assert.AreEqual(Page::"EA Corp Card Providers", ImportErrorInfo.PageNo, 'The recovery action must open provider setup.');
        Assert.AreEqual(CorpCardProvider.RecordId, ImportErrorInfo.RecordId, 'The recovery action must target the failing provider.');

        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, EmptyXmlPayloadTok, EmptyXmlFileNameTok);
        BindSubscription(EACorpCardTestLib);
        asserterror CorpCardFeedMgt.RunImport(CorpCardXmlProviderCodeTok);
        UnbindSubscription(EACorpCardTestLib);
        Assert.AreEqual(ImportErrorInfo.Message, GetLastErrorText(), 'Provider import must surface the actionable provider error without a plain-text wrapper.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedFileImportPreservesLastSuccessfulProvider()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();
        BindSubscription(EACorpCardTestLib);
        EACorpCardTestLib.RunFileImport(CorpCardXmlProviderCodeTok);
        UnbindSubscription(EACorpCardTestLib);
        SetAllRejectedCsvPayload();

        BindSubscription(EACorpCardTestLib);
        asserterror EACorpCardTestLib.RunFileImport(CorpCardCsvProviderCodeTok);
        UnbindSubscription(EACorpCardTestLib);
        Assert.ExpectedError('All 2 transaction lines');

        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        Assert.AreNotEqual(0DT, CorpCardProvider."Last Import DT", 'The successful provider import must retain its completion time.');
        Assert.IsTrue(CorpCardStatement.Get(CorpCardProvider."Last Statement Entry No."), 'The successful provider statement must survive the later import error.');
        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'The successful provider statement must remain imported.');
        EACorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BatchAndScheduledImportsSkipFileBasedFeeds()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        JobQueueEntry: Record "Job Queue Entry";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
        CorpCardJQRunner: Codeunit "EA Corp Card JQ Runner";
        StatementCount: Integer;
    begin
        Initialize();
        StatementCount := CorpCardStatement.Count();

        BindSubscription(EACorpCardTestLib);
        CorpCardFeedMgt.RunAllEnabledProviders();
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-FILE-CSV', CorpCardProvider.RecordId);
        CorpCardJQRunner.Run(JobQueueEntry);
        CorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-FILE-XML', CorpCardProvider.RecordId);
        CorpCardJQRunner.Run(JobQueueEntry);
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        CorpCardProvider."Feed Type" := CorpCardProvider."Feed Type"::DataExch;
        CorpCardProvider.Modify(true);
        CorpCardFeedMgt.RunAllEnabledProviders();
        CreateScheduleTestEntry(JobQueueEntry, 'CORP-FILE-DATAEXCH', CorpCardProvider.RecordId);
        CorpCardJQRunner.Run(JobQueueEntry);

        UnbindSubscription(EACorpCardTestLib);
        Assert.AreEqual(StatementCount, CorpCardStatement.Count(), 'Batch and existing scheduled jobs must skip all built-in file feeds without creating statements.');
        Assert.IsTrue(EACorpCardTestLib.HasSourcePayload(CorpCardCsvProviderCodeTok), 'Scheduled jobs must not request or consume a CSV source file.');
        Assert.IsTrue(EACorpCardTestLib.HasSourcePayload(CorpCardXmlProviderCodeTok), 'Scheduled jobs must not request or consume an XML source file.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FileBasedProviderCannotBeScheduled()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        JobQueueEntry: Record "Job Queue Entry";
        CorpCardJQMgt: Codeunit "EA Corp Card JQ Mgt";
        ProvidersPage: TestPage "EA Corp Card Providers";
        JobCount: Integer;
    begin
        Initialize();
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        JobCount := JobQueueEntry.Count();

        asserterror CorpCardJQMgt.ScheduleProviderImport(CorpCardProvider.Code, 1440, 080000T, Today());

        Assert.ExpectedError('Only automated feeds can be scheduled.');
        Assert.AreEqual(JobCount, JobQueueEntry.Count(), 'Rejecting a file-based schedule must not create a job.');
        ProvidersPage.OpenView();
        ProvidersPage.GoToRecord(CorpCardProvider);
        Assert.IsFalse(ProvidersPage.ScheduleImport.Enabled(), 'The schedule action must be disabled for file-based feeds.');
        ProvidersPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FileImportDeletesSourceAndRetainsMetadata()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        UnrelatedDataExch: Record "Data Exch.";
    begin
        Initialize();
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        UnrelatedDataExch."Related Record" := CorpCardProvider.RecordId;
        UnrelatedDataExch."File Name" := 'Unrelated.csv';
        UnrelatedDataExch.Insert(true);

        RunImportAndGetLastStatement(CorpCardCsvProviderCodeTok, CorpCardStatement);

        EACorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
        Assert.AreEqual(CorpCardCsvSampleFileNameTok, CorpCardStatement."Source File Name", 'The statement must retain the source file name.');
        Assert.IsTrue(CorpCardStatement."Source Payload Hash" <> '', 'The statement must retain the source payload hash.');
        Assert.AreEqual(0, CorpCardStatement."Data Exch Entry No.", 'Successful imports must remove the temporary data exchange record.');
        Assert.IsTrue(UnrelatedDataExch.Get(UnrelatedDataExch."Entry No."), 'Import finalization must preserve unrelated data exchange records for the same provider.');
        UnrelatedDataExch.Delete(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EmptyStatementFileIsRejectedWithoutAnotherFileSelection()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardStatement: Record "EA Corp Card Statement";
        DataExch: Record "Data Exch.";
        CorpCardImportOrch: Codeunit "EA Corp Card Import Orch";
        TempBlob: Codeunit "Temp Blob";
        SourceInStream: InStream;
        SourceOutStream: OutStream;
        StatementCount: Integer;
        DataExchCount: Integer;
    begin
        Initialize();
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        StatementCount := CorpCardStatement.Count();
        DataExch.SetRange("Related Record", CorpCardProvider.RecordId);
        DataExchCount := DataExch.Count();
        TempBlob.CreateOutStream(SourceOutStream);
        Clear(SourceOutStream);
        TempBlob.CreateInStream(SourceInStream);
        Commit();

        BindSubscription(EACorpCardTestLib);
        asserterror CorpCardImportOrch.RunFileImport(CorpCardProvider, SourceInStream, 'Empty.csv');
        UnbindSubscription(EACorpCardTestLib);

        Assert.ExpectedError('The selected statement file is empty.');
        Assert.AreEqual(StatementCount, CorpCardStatement.Count(), 'An empty file must not leave a statement or reach the import worker.');
        Assert.AreEqual(DataExchCount, DataExch.Count(), 'An empty file must not leave a source data exchange record.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ImportWithoutCardIdCreatesException()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseUser: Record "Expense User";
        ExpenseCountBeforeImport: Integer;
    begin
        Initialize();
        ExpenseUser.FindSet();
        CreateProviderCorpCard(CorpCard, 'XML-CARD-1', CorpCardXmlProviderCodeTok, ExpenseUser."No.");
        ExpenseUser.Next();
        CreateProviderCorpCard(CorpCard, 'XML-CARD-2', CorpCardXmlProviderCodeTok, ExpenseUser."No.");
        ExpenseCountBeforeImport := Expense.Count();
        SetProviderSourcePayload(CorpCardXmlProviderCodeTok, GetXmlPayloadWithoutCardId(), MissingCardIdXmlFileNameTok);

        RunImportAndGetLastStatement(CorpCardXmlProviderCodeTok, CorpCardStatement);

        Assert.AreEqual(0, CorpCardStatement.Imported, 'A transaction without an explicit card identifier must not be imported.');
        Assert.AreEqual(1, CorpCardStatement.Exceptions, 'A transaction without an explicit card identifier must create an exception.');
        Assert.AreEqual(1, CorpCardStatement.Rejected, 'A transaction without an explicit card identifier must be rejected.');
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardTrans.IsEmpty(), 'A rejected transaction must not be staged with an arbitrary provider card.');
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardException.FindFirst(), 'The rejected transaction must create an import exception.');
        Assert.IsTrue(StrPos(CorpCardException.Message, 'No corporate card could be identified') > 0, 'The import exception must identify the unresolved card.');
        Assert.AreEqual(ExpenseCountBeforeImport, Expense.Count(), 'A rejected transaction must not create or match an expense.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResolvingExceptionStampsAuditFields()
    var
        CorpCardException: Record "EA Corp Card Exception";
        ResolvedBy: Code[50];
        ResolvedDT: DateTime;
    begin
        Initialize();

        CorpCardException.Init();
        CorpCardException.Insert(true);
        CorpCardException.Resolved := true;
        CorpCardException.Modify(true);

        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(CorpCardException."Resolved By")), CorpCardException."Resolved By", 'Resolving an exception must record the current user.');
        Assert.IsTrue(CorpCardException."Resolved DT" <> 0DT, 'Resolving an exception must record the resolution date and time.');
        ResolvedBy := CorpCardException."Resolved By";
        ResolvedDT := CorpCardException."Resolved DT";

        CorpCardException."Resolved By" := 'MANUAL';
        Clear(CorpCardException."Resolved DT");
        CorpCardException.Modify(true);

        Assert.AreEqual(ResolvedBy, CorpCardException."Resolved By", 'Resolution user must not be overwritten after the exception is resolved.');
        Assert.AreEqual(ResolvedDT, CorpCardException."Resolved DT", 'Resolution date and time must not be overwritten after the exception is resolved.');

        CorpCardException.Resolved := false;
        CorpCardException.Modify(true);

        Assert.AreEqual('', CorpCardException."Resolved By", 'Reopening an exception must clear the resolution user.');
        Assert.AreEqual(0DT, CorpCardException."Resolved DT", 'Reopening an exception must clear the resolution date and time.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingTransactionDeletesOwnedDetailsAndExceptions()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);

        CorpCardTrans.Delete(true);

        CorpCardTransDetail.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(CorpCardTransDetail.IsEmpty(), 'Deleting a transaction must delete its detail lines.');
        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        Assert.IsTrue(CorpCardException.IsEmpty(), 'Deleting a transaction must delete its exceptions.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingStatementDeletesOwnedTransactionsDetailsAndExceptions()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        TransEntryNo: Integer;
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);
        TransEntryNo := CorpCardTrans."Entry No.";

        CorpCardStatement.Delete(true);

        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardTrans.IsEmpty(), 'Deleting a statement must delete its transactions.');
        CorpCardTransDetail.SetRange("Trans Entry No.", TransEntryNo);
        Assert.IsTrue(CorpCardTransDetail.IsEmpty(), 'Deleting a statement must delete transaction detail lines.');
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardException.IsEmpty(), 'Deleting a statement must delete its exceptions.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingPostedTransactionWithStaleBufferFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        CorpCardTrans.Status := CorpCardTrans.Status::Posted;
        CorpCardTrans.Modify(true);
        CorpCardTrans.Status := CorpCardTrans.Status::Imported;

        AssertTransactionDeletionFails(CorpCardTrans, PostedTransactionDeletionErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingTransactionWithPostedReportNumberFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        CorpCardTrans."Posted Expense Report No." := 'DELETE-POSTED';
        CorpCardTrans.Modify(true);

        AssertTransactionDeletionFails(CorpCardTrans, PostedTransactionDeletionErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingCanceledTransactionWithPostedLineFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        PostedExpenseReportLine: Record "Posted Expense Report Line";
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Modify(true);
        PostedExpenseReportLine.Init();
        PostedExpenseReportLine."Document No." := 'DELETE-POSTED';
        PostedExpenseReportLine."Line No." := 10000;
        PostedExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        PostedExpenseReportLine.Insert(false);

        AssertTransactionDeletionFails(CorpCardTrans, PostedTransactionDeletionErr);
        Assert.IsTrue(
            PostedExpenseReportLine.Get(PostedExpenseReportLine."Document No.", PostedExpenseReportLine."Line No."),
            'Rejecting transaction deletion must preserve the posted expense line.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingTransactionWithReversedBankLedgerEntryFails()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCardTrans: Record "EA Corp Card Trans";
        EntryNo: Integer;
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        CorpCardTrans.Status := CorpCardTrans.Status::Matched;
        CorpCardTrans.Modify(true);
        EntryNo := 1;
        if BankAccountLedgerEntry.FindLast() then
            EntryNo := BankAccountLedgerEntry."Entry No." + 1;
        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry."Entry No." := EntryNo;
        BankAccountLedgerEntry."EA Corp Card Trans Entry No." := CorpCardTrans."Entry No.";
        BankAccountLedgerEntry.Reversed := true;
        BankAccountLedgerEntry.Insert(false);

        AssertTransactionDeletionFails(CorpCardTrans, PostedTransactionDeletionErr);
        Assert.IsTrue(BankAccountLedgerEntry.Get(EntryNo), 'Rejecting transaction deletion must preserve the bank ledger entry.');

        BankAccountLedgerEntry.Delete(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingTransactionWithExpenseNumberFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        CorpCardTrans."Expense No." := 'DELETE-EXPENSE';
        CorpCardTrans.Modify(true);

        AssertTransactionDeletionFails(CorpCardTrans, LinkedTransactionDeletionErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingTransactionReferencedByExpenseFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        Expense.Init();
        Expense."No." := 'DELETE-EXPENSE';
        Expense."Credit Card Feed No." := CorpCardTrans."Entry No.";
        Expense.Insert(false);

        AssertTransactionDeletionFails(CorpCardTrans, LinkedTransactionDeletionErr);
        Assert.IsTrue(Expense.Get(Expense."No."), 'Rejecting transaction deletion must preserve the linked expense.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingTransactionReferencedByReportLineFails()
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseReportLine: Record "Expense Report Line";
    begin
        Initialize();
        CreateTransactionForDeletionTest(CorpCardTrans);
        ExpenseReportLine.Init();
        ExpenseReportLine."Document No." := 'DELETE-REPORT';
        ExpenseReportLine."Line No." := 10000;
        ExpenseReportLine."Credit Card Feed No." := CorpCardTrans."Entry No.";
        ExpenseReportLine.Insert(false);

        AssertTransactionDeletionFails(CorpCardTrans, LinkedTransactionDeletionErr);
        Assert.IsTrue(
            ExpenseReportLine.Get(ExpenseReportLine."Document No.", ExpenseReportLine."Line No."),
            'Rejecting transaction deletion must preserve the expense report line.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingStatementWithPostedTransactionRollsBackCascade()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        PostedCorpCardTrans: Record "EA Corp Card Trans";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);
        PostedCorpCardTrans := CorpCardTrans;
        PostedCorpCardTrans."Entry No." := 0;
        PostedCorpCardTrans."Provider Trans Id" := 'DELETE-POSTED';
        PostedCorpCardTrans.Status := PostedCorpCardTrans.Status::Posted;
        PostedCorpCardTrans.Insert(true);
        Commit();

        asserterror CorpCardStatement.Delete(true);

        Assert.ExpectedError(PostedTransactionDeletionErr);
        AssertTransactionAndOwnedDataExist(CorpCardTrans."Entry No.");
        Assert.IsTrue(PostedCorpCardTrans.Get(PostedCorpCardTrans."Entry No."), 'The posted transaction must survive statement deletion.');
        Assert.IsTrue(CorpCardDedupMgt.IsDuplicate(PostedCorpCardTrans), 'The posted transaction must retain its duplicate-check identity.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingCardWithTransactionsFails()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        Initialize();
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);
        CreateCorpCard(CorpCard, CorpCardTrans."Card Id");
        Commit();

        asserterror CorpCard.Delete(true);

        Assert.ExpectedError('Corporate card ' + CorpCard."Card Id" + ' cannot be deleted because one or more transactions exist.');
        Assert.IsTrue(CorpCard.Get(CorpCard."Card Id"), 'A card with transactions must not be deleted.');
        Assert.IsTrue(CorpCardTrans.Get(CorpCardTrans."Entry No."), 'Rejecting card deletion must preserve its transactions.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingCardWithoutTransactionsSucceeds()
    var
        CorpCard: Record "EA Corp Card";
        CardId: Code[50];
    begin
        Initialize();
        CardId := 'DELETE-CARD-TEST';
        CreateCorpCard(CorpCard, CardId);

        CorpCard.Delete(true);

        Assert.IsFalse(CorpCard.Get(CardId), 'A card without transactions must be deleted.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeletingMCCMapWithTransactionsFails()
    var
        CorpCardMCCMap: Record "EA Corp Card MCC Map";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
    begin
        Initialize();
        CreateCorpCardMCCMap(CorpCardMCCMap, 'TST1');
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);
        CorpCardTrans.MCC := CorpCardMCCMap.MCC;
        CorpCardTrans.Modify(true);
        Commit();

        asserterror CorpCardMCCMap.Delete(true);

        Assert.ExpectedError('MCC mapping ' + CorpCardMCCMap.MCC + ' cannot be deleted because one or more corporate card transactions exist.');
        Assert.IsTrue(CorpCardMCCMap.Get(CorpCardMCCMap.MCC), 'An MCC mapping used by transactions must not be deleted.');
        Assert.IsTrue(CorpCardTrans.Get(CorpCardTrans."Entry No."), 'Rejecting MCC mapping deletion must preserve its transactions.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingMCCMapWithoutTransactionsSucceeds()
    var
        CorpCardMCCMap: Record "EA Corp Card MCC Map";
        MCC: Code[4];
    begin
        Initialize();
        MCC := 'TST2';
        CreateCorpCardMCCMap(CorpCardMCCMap, MCC);

        CorpCardMCCMap.Delete(true);

        Assert.IsFalse(CorpCardMCCMap.Get(MCC), 'An unused MCC mapping must be deleted.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingProviderDoesNotDeleteSharedDataExchangeDefinition()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        SharedCorpCardProvider: Record "EA Corp Card Provider";
        DataExchDef: Record "Data Exch. Def";
        SharedDataExchDefCode: Code[20];
    begin
        Initialize();

        SharedCorpCardProvider.Get(CorpCardXmlProviderCodeTok);
        SharedDataExchDefCode := SharedCorpCardProvider."Data Exch Def Code";
        DataExchDef.Get(SharedDataExchDefCode);

        CorpCardProvider.Init();
        CorpCardProvider.Code := SharedDefinitionTestProviderCodeTok;
        CorpCardProvider.Description := 'Shared definition deletion test';
        CorpCardProvider."Data Exch Def Code" := SharedDataExchDefCode;
        CorpCardProvider.Insert(true);

        CorpCardProvider.Delete(true);

        Assert.IsTrue(DataExchDef.Get(SharedDataExchDefCode), 'Deleting a provider must not delete a shared Data Exchange definition.');
        Assert.IsTrue(SharedCorpCardProvider.Get(CorpCardXmlProviderCodeTok), 'Deleting a provider must not affect another provider that uses the shared definition.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure XmlImportMapsMandatoryFields()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        Initialize();

        RunImportAndGetLastStatement(CorpCardXmlProviderCodeTok, CorpCardStatement);

        Assert.AreEqual(CorpCardStatement.Status::Imported, CorpCardStatement.Status, 'XML statement import must complete successfully.');
        Assert.IsTrue(CorpCardStatement.Imported > 0, 'XML sample payload must import at least one transaction.');
        AssertAnyTransactionHasMandatoryFields(CorpCardStatement."Statement Entry No.", CorpCardXmlProviderCodeTok);
    end;

    local procedure AssertAnyTransactionHasMandatoryFields(StatementEntryNo: Integer; ProviderCode: Code[20])
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        FoundMapped: Boolean;
    begin
        CorpCardTrans.SetRange("Statement Entry No.", StatementEntryNo);
        CorpCardTrans.SetRange("Provider Code", ProviderCode);
        if CorpCardTrans.FindSet() then
            repeat
                if (CorpCardTrans."Provider Trans Id" <> '') and
                   (CorpCardTrans."Card Id" <> '') and
                         (CorpCardTrans."Trans Date" <> 0D)
                then begin
                    FoundMapped := true;
                    break;
                end;
            until CorpCardTrans.Next() = 0;

        Assert.IsTrue(FoundMapped, 'No transaction with mandatory mapped fields found for provider ' + ProviderCode + ' in statement ' + Format(StatementEntryNo) + '.');
    end;

    local procedure GetMalformedXmlPayload(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<CorporateCardTransactions>' +
                '<Transaction>' +
                    '<ProviderTransId>XMLNEG0001</ProviderTransId>' +
                    '<CardLast4>0001</CardLast4>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>19.63</Amount>' +
                    '<CurrencyCode>USD</CurrencyCode>' +
                    '<MerchantRaw>Broken XML Merchant</MerchantRaw>' +
                    '<MCC>4511</MCC>' +
                    '<Country>US</Country>' +
                '</Transaction>');
    end;

    local procedure GetXmlPayloadWithoutCardId(): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<CorporateCardTransactions>' +
                '<Transaction>' +
                    '<ProviderTransId>XML-NO-CARD-1</ProviderTransId>' +
                    '<TransDate>2026-07-01</TransDate>' +
                    '<PostingDate>2026-07-01</PostingDate>' +
                    '<Amount>19.63</Amount>' +
                    '<CurrencyCode>USD</CurrencyCode>' +
                    '<MerchantRaw>Missing Card Merchant</MerchantRaw>' +
                    '<MCC>4511</MCC>' +
                    '<Country>US</Country>' +
                '</Transaction>' +
            '</CorporateCardTransactions>');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::EACorpCardPhase3Tests);
        Clear(EACorpCardTestLib);
        EACorpCardTestLib.InitializeCorpCardData();
        DeleteCorpCardTransactionalData();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::EACorpCardPhase3Tests);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::EACorpCardPhase3Tests);
    end;

    local procedure DeleteCorpCardTransactionalData()
    var
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        CorpCardTransDetail.DeleteAll();
        CorpCardException.DeleteAll();
        CorpCardTrans.DeleteAll();
        CorpCardStatement.DeleteAll();
    end;

    local procedure CreateCleanupTestRecords(var CorpCardStatement: Record "EA Corp Card Statement"; var CorpCardTrans: Record "EA Corp Card Trans"; var CorpCardTransDetail: Record "EA Corp Card Trans Detail"; var CorpCardException: Record "EA Corp Card Exception")
    begin
        CorpCardStatement.Init();
        CorpCardStatement."Provider Code" := CorpCardXmlProviderCodeTok;
        CorpCardStatement.Insert(true);

        CorpCardTrans.Init();
        CorpCardTrans."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardTrans."Provider Code" := CorpCardStatement."Provider Code";
        CorpCardTrans."Provider Trans Id" := 'DELETE-TEST';
        CorpCardTrans."Card Id" := 'DELETE-TEST';
        CorpCardTrans."Trans Date" := Today();
        CorpCardTrans.Insert(true);

        CorpCardTransDetail.Init();
        CorpCardTransDetail."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardTransDetail."Line No." := 10000;
        CorpCardTransDetail.Insert(true);

        CorpCardException.Init();
        CorpCardException."Statement Entry No." := CorpCardStatement."Statement Entry No.";
        CorpCardException."Trans Entry No." := CorpCardTrans."Entry No.";
        CorpCardException.Insert(true);
    end;

    local procedure SetAllRejectedCsvPayload()
    var
        CsvPayload: TextBuilder;
    begin
        CsvPayload.AppendLine('ProviderTransId,CardLast4,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes');
        CsvPayload.AppendLine('REJECT-1,,2026-06-02,2026-06-03,19.63,USD,Rejected merchant,4511,US,Missing card');
        CsvPayload.AppendLine(',0001,2026-06-02,2026-06-03,19.63,USD,Rejected merchant,4511,US,Missing transaction ID');
        SetProviderSourcePayload(CorpCardCsvProviderCodeTok, CsvPayload.ToText(), 'All-rejected.csv');
    end;

    local procedure AssertRejectedCsvStatement(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
    begin
        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        Assert.IsTrue(CorpCardStatement.Get(CorpCardProvider."Last Statement Entry No."), 'The failed statement must remain accessible from its provider.');
        Assert.AreEqual(CorpCardStatement.Status::Failed, CorpCardStatement.Status, 'An all-rejected CSV import must finalize as failed.');
        Assert.AreEqual(0, CorpCardStatement.Imported, 'Invalid rows must not be counted as imported.');
        Assert.AreEqual(2, CorpCardStatement.Rejected, 'The rejection count must reflect rows without an additional synthetic rejection.');
        Assert.AreEqual(2, CorpCardStatement.Exceptions, 'The exception count must survive failure finalization.');
        Assert.IsTrue(CorpCardStatement."Ended DT" <> 0DT, 'The failed statement must retain its completion time.');
        Assert.AreEqual('All-rejected.csv', CorpCardStatement."Source File Name", 'The failed statement must retain the source file name.');
        Assert.IsTrue(CorpCardStatement."Source Payload Hash" <> '', 'The failed statement must retain its source hash.');
        Assert.AreEqual(0, CorpCardStatement."Data Exch Entry No.", 'Failure finalization must remove the temporary data exchange record.');
        EACorpCardTestLib.AssertNoSourceFile(CorpCardStatement);
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.IsTrue(CorpCardTrans.IsEmpty(), 'Rejected rows must not create staged transactions.');
        Assert.IsTrue(Expense.IsEmpty(), 'Failed validation must not run post-import draft creation.');
        CorpCardException.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        Assert.AreEqual(2, CorpCardException.Count(), 'Every rejected row must retain its exception record.');
        CorpCardException.SetFilter(Message, 'No corporate card could be identified*');
        Assert.AreEqual(1, CorpCardException.Count(), 'The missing-card diagnostic must survive the failed import.');
        CorpCardException.SetRange(Message, 'Provider Trans Id is missing.');
        Assert.AreEqual(1, CorpCardException.Count(), 'The missing-transaction-ID diagnostic must survive the failed import.');
    end;

    local procedure CreateScheduleTestEntry(var JobQueueEntry: Record "Job Queue Entry"; Description: Text[100]; ProviderRecordId: RecordId)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Description := Description;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"EA Corp Card JQ Runner";
        JobQueueEntry."Record ID to Process" := ProviderRecordId;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry.Insert(false);
    end;

    local procedure CreateTransactionForDeletionTest(var CorpCardTrans: Record "EA Corp Card Trans")
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CreateCleanupTestRecords(CorpCardStatement, CorpCardTrans, CorpCardTransDetail, CorpCardException);
    end;

    local procedure AssertTransactionDeletionFails(var CorpCardTrans: Record "EA Corp Card Trans"; ExpectedError: Text)
    begin
        Commit();

        asserterror CorpCardTrans.Delete(true);

        Assert.ExpectedError(ExpectedError);
        AssertTransactionAndOwnedDataExist(CorpCardTrans."Entry No.");
    end;

    local procedure AssertTransactionAndOwnedDataExist(TransactionEntryNo: Integer)
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTransDetail: Record "EA Corp Card Trans Detail";
        CorpCardException: Record "EA Corp Card Exception";
        CorpCardDedupMgt: Codeunit "EA Corp Card Dedup Mgt";
    begin
        Assert.IsTrue(CorpCardTrans.Get(TransactionEntryNo), 'Rejecting deletion must preserve the transaction.');
        Assert.IsTrue(CorpCardStatement.Get(CorpCardTrans."Statement Entry No."), 'Rejecting deletion must preserve the statement.');
        Assert.IsTrue(CorpCardDedupMgt.IsDuplicate(CorpCardTrans), 'Rejecting deletion must preserve the duplicate-check identity.');
        CorpCardTransDetail.SetRange("Trans Entry No.", TransactionEntryNo);
        Assert.IsFalse(CorpCardTransDetail.IsEmpty(), 'Rejecting deletion must preserve transaction details.');
        CorpCardException.SetRange("Trans Entry No.", TransactionEntryNo);
        Assert.IsFalse(CorpCardException.IsEmpty(), 'Rejecting deletion must preserve transaction exceptions.');
    end;

    local procedure CreateCorpCard(var CorpCard: Record "EA Corp Card"; CardId: Code[50])
    begin
        CorpCard.Init();
        CorpCard."Card Id" := CardId;
        CorpCard.Insert(true);
    end;

    local procedure CreateProviderCorpCard(var CorpCard: Record "EA Corp Card"; CardId: Code[50]; ProviderCode: Code[20]; ExpenseUserNo: Code[20])
    begin
        CorpCard.Init();
        CorpCard."Card Id" := CardId;
        CorpCard."Provider Code" := ProviderCode;
        CorpCard."Expense User No." := ExpenseUserNo;
        CorpCard.Insert(true);
    end;

    local procedure CreateCorpCardMCCMap(var CorpCardMCCMap: Record "EA Corp Card MCC Map"; MCC: Code[4])
    begin
        CorpCardMCCMap.Init();
        CorpCardMCCMap.MCC := MCC;
        CorpCardMCCMap.Insert(true);
    end;

    local procedure RunImportAndGetLastStatement(ProviderCode: Code[20]; var CorpCardStatement: Record "EA Corp Card Statement")
    begin
        BindSubscription(EACorpCardTestLib);
        EACorpCardTestLib.RunImportAndGetLastStatement(ProviderCode, CorpCardStatement);
        UnbindSubscription(EACorpCardTestLib);
    end;

    local procedure SetProviderSourcePayload(ProviderCode: Code[20]; SourcePayload: Text; SourceFileName: Text[250])
    begin
        EACorpCardTestLib.SetProviderSourcePayload(ProviderCode, SourcePayload, SourceFileName);
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', Locked = true;
        SharedDefinitionTestProviderCodeTok: Label 'SHAREDDEFTEST', Locked = true;
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        MalformedXmlRootElementTok: Label 'CorporateCardTransactions', Locked = true;
        MalformedXmlFileNameTok: Label 'CorpCard-Malformed.xml', Locked = true;
        EmptyXmlPayloadTok: Label '<CorporateCardTransactions />', Locked = true;
        EmptyXmlFileNameTok: Label 'CorpCard-Empty.xml', Locked = true;
        MissingCardIdXmlFileNameTok: Label 'CorpCard-Missing-Card-Id.xml', Locked = true;
}
