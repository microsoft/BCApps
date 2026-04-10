codeunit 134816 "ERM CA Reporting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Accounting]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCostAccounting: Codeunit "Library - Cost Accounting";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ClosedEntryError: Label 'A closed register cannot be reactivated.';
        DeleteClosedEntryError: Label 'Register %1 can no longer be deleted because it is marked as closed.';
        EndingDateNotAtYearEnd: Label '%1 is not at year''s end.';
        EndingDateNotOlderThanOneYar: Label 'The selected year ending date %1 must be older than last year.';
        ExpectedValueIsDifferentError: Label 'Expected value of %1 field is different than the actual one.';
        FromRegNoHigherThanToRegNo: Label 'From Register No. must not be higher than To Register No..';
        IncorrectAllocEntriesCount: Label 'Incorrect number of cost allocation entries.';
        IncorrectBudgetRegEntriesCount: Label 'Incorrect number of cost budget register entries.';
        IncorrectCostRegEntriesCount: Label 'The number of cost entries should be %1.';
        GlobalCostBudget: Code[10];
        UnexpectedErrorMessage: Label 'Unexpected error message:\%1';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerAllocBudgetCosts,MessageHandler')]
    [Scope('OnPrem')]
    procedure CloseCostBudgetRegisterEntry()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        NoOfCostBudgetRegEntries: Integer;
        NoOfRegisterEntriesBefore: Integer;
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        NoOfRegisterEntriesBefore := CostBudgetRegister.Count();

        Commit();
        GlobalCostBudget := CostBudgetName.Name;
        REPORT.Run(REPORT::"Cost Allocation");
        NoOfCostBudgetRegEntries := CostBudgetRegister.Count - NoOfRegisterEntriesBefore;

        CloseCostBudgetRegEntries(NoOfCostBudgetRegEntries);

        // Verify:
        VerifyClosedBudgetEntries(NoOfCostBudgetRegEntries);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CloseCostRegisterEntry()
    var
        NoOfCostRegisterEntries: Integer;
    begin
        Initialize();

        NoOfCostRegisterEntries := 2;
        CloseCostRegisterEntries(NoOfCostRegisterEntries);

        // Verify:
        VerifyClosedEntries(NoOfCostRegisterEntries);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerAllocCosts,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteAllocEntries()
    var
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
        ReversedCostAllocEntriesCount: Integer;
        LastAllocatedJnlNo: Integer;
        TotalAllocatedEntriesCountOld: Integer;
    begin
        Initialize();

        // Setup:
        Commit();
        REPORT.Run(REPORT::"Cost Allocation");

        CostRegister.SetRange(Source, CostRegister.Source::Allocation);
        CostRegister.FindLast();
        LastAllocatedJnlNo := CostRegister."No.";
        ReversedCostAllocEntriesCount := AllocatedWithJnlNo(LastAllocatedJnlNo) + AllocatedInJnlNo(LastAllocatedJnlNo);
        TotalAllocatedEntriesCountOld := TotalAllocatedCostEntries();

        // Exercise:
        LibraryCostAccounting.DeleteCostRegisterEntriesFrom(LastAllocatedJnlNo);

        // Verify:
        Assert.AreEqual(0, AllocatedWithJnlNo(LastAllocatedJnlNo), IncorrectAllocEntriesCount);
        Assert.AreEqual(
          TotalAllocatedEntriesCountOld - ReversedCostAllocEntriesCount, TotalAllocatedCostEntries(), IncorrectAllocEntriesCount);

        // Verify Last Alloc Doc No. field from Cost Accounting Setup
        CostEntry.SetRange(Allocated, true);
        CostEntry.FindLast();
        VerifyLastAllocationDocNo(CostEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerAllocBudgetCosts,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteClosedBudgetEntry()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        NoOfCostBudgetRegEntries: Integer;
        NoOfRegisterEntriesBefore: Integer;
        LastClosedEntryNo: Integer;
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        NoOfRegisterEntriesBefore := CostBudgetRegister.Count();

        Commit();
        GlobalCostBudget := CostBudgetName.Name;
        REPORT.Run(REPORT::"Cost Allocation");

        NoOfCostBudgetRegEntries := CostBudgetRegister.Count - NoOfRegisterEntriesBefore;
        LastClosedEntryNo := CloseCostBudgetRegEntries(NoOfCostBudgetRegEntries);

        // Exercise and Verify:
        asserterror LibraryCostAccounting.DeleteCostBudgetRegEntriesFrom(LastClosedEntryNo);
        Assert.AreEqual(
          StrSubstNo(DeleteClosedEntryError, LastClosedEntryNo), GetLastErrorText, StrSubstNo(UnexpectedErrorMessage, GetLastErrorText));
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteClosedEntry()
    var
        NoOfCostRegisterEntries: Integer;
        LastClosedEntryNo: Integer;
    begin
        Initialize();

        // Setup:
        NoOfCostRegisterEntries := 1;
        LastClosedEntryNo := CloseCostRegisterEntries(NoOfCostRegisterEntries);

        // Exercise and Verify:
        asserterror LibraryCostAccounting.DeleteCostRegisterEntriesFrom(LastClosedEntryNo);
        Assert.AreEqual(
          StrSubstNo(DeleteClosedEntryError, LastClosedEntryNo), GetLastErrorText, StrSubstNo(UnexpectedErrorMessage, GetLastErrorText));
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerAllocBudgetCosts,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetEntries()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        NoOfBudgetRegEntriesToDelete: Integer;
        TotalNoOfBudgetRegEntries: Integer;
        NoOfRegisterEntriesBefore: Integer;
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        NoOfRegisterEntriesBefore := CostBudgetRegister.Count();

        Commit();
        GlobalCostBudget := CostBudgetName.Name;
        REPORT.Run(REPORT::"Cost Allocation");

        TotalNoOfBudgetRegEntries := CostBudgetRegister.Count();
        NoOfBudgetRegEntriesToDelete := LibraryRandom.RandInt(TotalNoOfBudgetRegEntries - NoOfRegisterEntriesBefore);

        // Exercise:
        LibraryCostAccounting.DeleteCostBudgetRegEntriesFrom(TotalNoOfBudgetRegEntries - NoOfBudgetRegEntriesToDelete + 1);

        // Verify:
        Assert.AreEqual(
          TotalNoOfBudgetRegEntries - NoOfBudgetRegEntriesToDelete, CostBudgetRegister.Count, IncorrectBudgetRegEntriesCount);

        // Verify Last Alloc Doc No. field from Cost Accounting Setup

        CostBudgetRegister.SetRange(Source, CostBudgetRegister.Source::Allocation);
        CostBudgetRegister.FindLast();
        CostBudgetEntry.Get(CostBudgetRegister."To Cost Budget Entry No.");
        VerifyLastAllocationDocNo(CostBudgetEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteCostBudgetEntriesCanceled')]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetEntriesCanceled()
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetEntryCount: Integer;
    begin
        Initialize();

        // Setup
        CostBudgetEntryCount := CostBudgetEntry.Count();

        // Exercise
        REPORT.Run(REPORT::"Delete Cost Budget Entries");

        // Verify
        Clear(CostBudgetEntry);
        Assert.AreEqual(CostBudgetEntryCount, CostBudgetEntry.Count, StrSubstNo(IncorrectCostRegEntriesCount, CostBudgetEntryCount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetEntriesFromGreaterThanTo()
    var
        CostBudgetRegister: Record "Cost Budget Register";
        DeleteCostBudgetEntries: Report "Delete Cost Budget Entries";
    begin
        Initialize();

        // Pre-Setup
        CostBudgetRegister.FindLast();

        // Setup
        Clear(DeleteCostBudgetEntries);
        DeleteCostBudgetEntries.InitializeRequest(CostBudgetRegister."No.", CostBudgetRegister."No." - 1);

        // Exercise
        DeleteCostBudgetEntries.UseRequestPage := false;
        asserterror DeleteCostBudgetEntries.RunModal();

        // Verify
        Assert.ExpectedError(FromRegNoHigherThanToRegNo);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteCostBudgetEntriesSetNonExistingFromValue')]
    [Scope('OnPrem')]
    procedure DeleteCostBudgetEntriesFromValueNotExisting()
    begin
        // Setup
        Initialize();

        // Exercise
        REPORT.Run(REPORT::"Delete Cost Budget Entries");

        // Verify
        Assert.ExpectedErrorCannotFind(Database::"Cost Budget Register");
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteCostEntriesCanceled')]
    [Scope('OnPrem')]
    procedure DeleteCostEntriesCanceled()
    var
        CostEntry: Record "Cost Entry";
        CostEntryCount: Integer;
    begin
        Initialize();

        // Setup
        CostEntryCount := CostEntry.Count();

        // Exercise
        REPORT.Run(REPORT::"Delete Cost Entries");

        // Verify
        Clear(CostEntry);
        Assert.AreEqual(CostEntryCount, CostEntry.Count, StrSubstNo(IncorrectCostRegEntriesCount, CostEntryCount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCostEntriesFromGreaterThanTo()
    var
        CostRegister: Record "Cost Register";
        DeleteCostEntries: Report "Delete Cost Entries";
    begin
        Initialize();

        // Pre-Setup
        CostRegister.FindLast();

        // Setup
        Clear(DeleteCostEntries);
        DeleteCostEntries.InitializeRequest(CostRegister."No.", CostRegister."No." - 1);

        // Exercise
        DeleteCostEntries.UseRequestPage := false;
        asserterror DeleteCostEntries.RunModal();

        // Verify
        Assert.ExpectedError(FromRegNoHigherThanToRegNo);
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteCostEntriesSetNonExistingFromValue')]
    [Scope('OnPrem')]
    procedure DeleteCostEntriesFromValueNotExisting()
    begin
        // Setup
        Initialize();

        // Exercise
        REPORT.Run(REPORT::"Delete Cost Entries");

        // Verify
        Assert.ExpectedErrorCannotFind(Database::"Cost Register");
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteOldCostEntries,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOldCostEntries()
    var
        CostEntry: Record "Cost Entry";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
        YearEndDate: Date;
    begin
        // Setup:
        Initialize();
        YearEndDate := CalcDate('<CY - 2Y>', WorkDate());
        LibraryVariableStorage.Enqueue(YearEndDate);

        // Create a cost entry in the specified date
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        CostJournalLine.Validate("Posting Date", YearEndDate);
        CostJournalLine.Modify(true);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);

        // Exercise:
        Commit();
        REPORT.Run(REPORT::"Delete Old Cost Entries");

        // Validate
        CostEntry.SetFilter("Posting Date", '<=%1', YearEndDate);
        Assert.IsTrue(CostEntry.IsEmpty, StrSubstNo(IncorrectCostRegEntriesCount, 0));
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteOldCostEntriesCanceled')]
    [Scope('OnPrem')]
    procedure DeleteOldCostEntriesCanceled()
    var
        CostEntry: Record "Cost Entry";
        CostEntryCount: Integer;
    begin
        Initialize();

        // Setup
        CostEntryCount := CostEntry.Count();

        // Exercise
        REPORT.Run(REPORT::"Delete Old Cost Entries");

        // Verify
        Clear(CostEntry);
        Assert.AreEqual(CostEntryCount, CostEntry.Count, StrSubstNo(IncorrectCostRegEntriesCount, CostEntryCount));
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteOldCostEntriesError')]
    [Scope('OnPrem')]
    procedure DeleteOldCostEntriesNotYearEnd()
    var
        YearEndingDate: Date;
    begin
        Initialize();

        // Setup
        YearEndingDate := LibraryUtility.GenerateRandomDate(CalcDate('<-CY>', WorkDate()), CalcDate('<CY-1D>', WorkDate()));

        // Post-Setup
        LibraryVariableStorage.Enqueue(YearEndingDate);

        // Exercise
        REPORT.Run(REPORT::"Delete Old Cost Entries");

        // Verify
        Assert.ExpectedError(StrSubstNo(EndingDateNotAtYearEnd, YearEndingDate));
    end;

    [Test]
    [HandlerFunctions('RPHandlerDeleteOldCostEntriesError')]
    [Scope('OnPrem')]
    procedure DeleteOldCostEntriesRecentDate()
    var
        OldWorkDate: Date;
        YearEndingDate: Date;
    begin
        Initialize();

        // Setup
        YearEndingDate := CalcDate('<CY>', Today);
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1M>', YearEndingDate);

        // Post-Setup
        LibraryVariableStorage.Enqueue(YearEndingDate);

        // Exercise
        REPORT.Run(REPORT::"Delete Old Cost Entries");

        // Verify
        Assert.ExpectedError(StrSubstNo(EndingDateNotOlderThanOneYar, YearEndingDate));

        // Tear-Down
        WorkDate(OldWorkDate);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RPHandlerAllocBudgetCosts,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReopenClosedBudgetEntry()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        NoOfCostBudgetRegEntries: Integer;
        NoOfRegisterEntriesBefore: Integer;
        LastClosedEntryNo: Integer;
    begin
        Initialize();

        // Setup:
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        NoOfRegisterEntriesBefore := CostBudgetRegister.Count();

        Commit();
        GlobalCostBudget := CostBudgetName.Name;
        REPORT.Run(REPORT::"Cost Allocation");

        NoOfCostBudgetRegEntries := CostBudgetRegister.Count - NoOfRegisterEntriesBefore;
        LastClosedEntryNo := CloseCostBudgetRegEntries(NoOfCostBudgetRegEntries);

        // Exercise and Verify:
        CostBudgetRegister.Get(LastClosedEntryNo);
        asserterror CostBudgetRegister.Validate(Closed, false);
        Assert.IsTrue(StrPos(ClosedEntryError, GetLastErrorText) > 0, StrSubstNo(UnexpectedErrorMessage, GetLastErrorText));
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReopenClosedEntry()
    var
        CostRegister: Record "Cost Register";
        NoOfCostRegisterEntries: Integer;
        LastClosedEntryNo: Integer;
    begin
        Initialize();

        // Setup:
        NoOfCostRegisterEntries := 1;
        LastClosedEntryNo := CloseCostRegisterEntries(NoOfCostRegisterEntries);

        // Exercise and Verify:
        CostRegister.Get(LastClosedEntryNo);
        asserterror CostRegister.Validate(Closed, false);
        Assert.IsTrue(StrPos(ClosedEntryError, GetLastErrorText) > 0, StrSubstNo(UnexpectedErrorMessage, GetLastErrorText));
        ClearLastError();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TransferBudgetToActual()
    var
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostRegister: Record "Cost Register";
    begin
        LibraryCostAccounting.CreateCostBudgetName(CostBudgetName);
        LibraryCostAccounting.CreateCostBudgetEntry(CostBudgetEntry, CostBudgetName.Name);

        CostBudgetEntry.SetRange("Budget Name", CostBudgetName.Name);
        CostBudgetEntry.SetRange(Date, WorkDate());

        REPORT.Run(REPORT::"Transfer Budget to Actual", false, false, CostBudgetEntry);

        CostRegister.FindLast();
        CostRegister.TestField(Source, CostRegister.Source::"Transfer from Budget");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM CA Reporting");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM CA Reporting");

        LibraryCostAccounting.InitializeCASetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM CA Reporting");
    end;

    local procedure AllocatedInJnlNo(JournalNo: Integer): Integer
    var
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
    begin
        CostRegister.Get(JournalNo);
        CostEntry.SetRange("Entry No.", CostRegister."From Cost Entry No.", CostRegister."To Cost Entry No.");
        CostEntry.SetRange(Allocated, true);
        exit(CostEntry.Count);
    end;

    local procedure AllocatedWithJnlNo(JournalNo: Integer): Integer
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetRange("Allocated with Journal No.", JournalNo);
        exit(CostEntry.Count);
    end;

    local procedure CloseCostBudgetRegEntries(NoOfCostBudgetRegEntries: Integer): Integer
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        CostBudgetRegister.SetRange(Closed, false);
        CostBudgetRegister.Next(NoOfCostBudgetRegEntries);

        CostBudgetRegister.Validate(Closed, true);
        CostBudgetRegister.Modify(true);

        exit(CostBudgetRegister."No.");
    end;

    local procedure CloseCostRegisterEntries(NoOfCostRegisterEntries: Integer): Integer
    var
        CostRegister: Record "Cost Register";
        "Count": Integer;
    begin
        for Count := 1 to NoOfCostRegisterEntries do
            CreateCostRegisterEntry();

        CostRegister.SetRange(Closed, false);
        CostRegister.Next(NoOfCostRegisterEntries);

        CostRegister.Validate(Closed, true);
        CostRegister.Modify(true);

        exit(CostRegister."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateCostRegisterEntry()
    var
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalLine: Record "Cost Journal Line";
    begin
        FindCostJnlBatchAndTemplate(CostJournalBatch);
        LibraryCostAccounting.CreateCostJournalLine(CostJournalLine, CostJournalBatch."Journal Template Name", CostJournalBatch.Name);
        LibraryCostAccounting.PostCostJournalLine(CostJournalLine);
    end;

    local procedure FindCostJnlBatchAndTemplate(var CostJournalBatch: Record "Cost Journal Batch")
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        LibraryCostAccounting.FindCostJournalTemplate(CostJournalTemplate);
        LibraryCostAccounting.FindCostJournalBatch(CostJournalBatch, CostJournalTemplate.Name);
        LibraryCostAccounting.ClearCostJournalLines(CostJournalBatch);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler
    end;

    local procedure TotalAllocatedCostEntries(): Integer
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetRange(Allocated, true);
        exit(CostEntry.Count);
    end;

    local procedure VerifyClosedBudgetEntries(UpToEntry: Integer)
    var
        CostBudgetRegister: Record "Cost Budget Register";
    begin
        CostBudgetRegister.FindSet();
        repeat
            CostBudgetRegister.TestField(Closed, true);
            UpToEntry := UpToEntry - 1;
            CostBudgetRegister.Next();
        until UpToEntry = 0;
    end;

    local procedure VerifyClosedEntries(UpToEntry: Integer)
    var
        CostRegister: Record "Cost Register";
    begin
        CostRegister.FindSet();
        repeat
            CostRegister.TestField(Closed, true);
            UpToEntry := UpToEntry - 1;
            CostRegister.Next();
        until UpToEntry = 0;
    end;

    local procedure VerifyLastAllocationDocNo(ExpectedLastAllocDocNo: Code[20])
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
    begin
        CostAccountingSetup.Get();
        Assert.IsTrue(
          CostAccountingSetup."Last Allocation Doc. No." = ExpectedLastAllocDocNo,
          StrSubstNo(ExpectedValueIsDifferentError, CostAccountingSetup.FieldName("Last Allocation Doc. No.")));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerAllocBudgetCosts(var AllocCostsReqPage: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(AllocCostsReqPage, 1, 99, WorkDate(), '', GlobalCostBudget);
        AllocCostsReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerAllocCosts(var AllocCostsReqPage: TestRequestPage "Cost Allocation")
    begin
        LibraryCostAccounting.AllocateCostsFromTo(AllocCostsReqPage, 1, 99, WorkDate(), '', '');
        AllocCostsReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteCostBudgetEntriesCanceled(var DeleteCostBudgetEntries: TestRequestPage "Delete Cost Budget Entries")
    begin
        DeleteCostBudgetEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteCostBudgetEntriesSetNonExistingFromValue(var DeleteCostBudgetEntries: TestRequestPage "Delete Cost Budget Entries")
    begin
        asserterror DeleteCostBudgetEntries.FromRegisterNo.SetValue(DeleteCostBudgetEntries.ToRegisterNo.AsInteger() + 1);
        DeleteCostBudgetEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteCostEntriesCanceled(var DeleteCostEntries: TestRequestPage "Delete Cost Entries")
    begin
        DeleteCostEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteCostEntriesSetNonExistingFromValue(var DeleteCostEntries: TestRequestPage "Delete Cost Entries")
    begin
        asserterror DeleteCostEntries.FromRegisterNo.SetValue(DeleteCostEntries.ToRegisterNo.AsInteger() + 1);
        DeleteCostEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteOldCostEntries(var DeleteOldCostEntriesRP: TestRequestPage "Delete Old Cost Entries")
    var
        YearEndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(YearEndDate);
        DeleteOldCostEntriesRP.YearEndingDate.SetValue(YearEndDate);
        DeleteOldCostEntriesRP.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteOldCostEntriesCanceled(var DeleteOldCostEntries: TestRequestPage "Delete Old Cost Entries")
    begin
        DeleteOldCostEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHandlerDeleteOldCostEntriesError(var DeleteOldCostEntriesRP: TestRequestPage "Delete Old Cost Entries")
    var
        YearEndDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(YearEndDate);
        asserterror DeleteOldCostEntriesRP.YearEndingDate.SetValue(YearEndDate);
        DeleteOldCostEntriesRP.Cancel().Invoke();
    end;
}

