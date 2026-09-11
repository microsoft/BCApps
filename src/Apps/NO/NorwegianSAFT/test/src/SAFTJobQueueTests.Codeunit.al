codeunit 148105 "SAF-T Job Queue Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SAF-T] [Job Queue]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        SAFTTestHelper: Codeunit "SAF-T Test Helper";
        Assert: Codeunit Assert;
        SAFTMappingType: Enum "SAF-T Mapping Type";
        IsInitialized: Boolean;
        ExpectedExportID: Integer;
        ExpectedTransactionCount: Integer;
        VerifiedScheduledTasks: Integer;
        SetStartDateTimeAsCurrentQst: Label 'The Earliest Start Date/Time field is not filled in. Do you want to proceed and start the export immediately?';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure BackgroundTasksCreatesAccordingToMaxNoOfJobsOfExportSetup()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTJobQueueTests: Codeunit "SAF-T Job Queue Tests";
        CurrDate: Date;
        NullGuid: Guid;
        MaxNoOfJobs: Integer;
    begin
        // [SCENARIO 309923] The background tasks creates according to "Max No. Of Jobs" and "Split Month" when run SAF-T Export with "Parallel Processing" option enabled

        Initialize();
        BindSubscription(SAFTJobQueueTests);

        // [GIVEN] SAF-T Mapping Range in year 2022 fully setup
        SetupSAFT(SAFTMappingRange, SAFTMappingType::"Four Digit Standard Account");
        MaxNoOfJobs := LibraryRandom.RandIntInRange(3, 5);
        MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] SAF-T Export with "Parallel Processing" and "Split Month" option enabled and "Max. No Of Jobs" = 8
        CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, MaxNoOfJobs);

        // [GIVEN] Posted G/L Entries in each month of year 2022, in total 12 months
        CurrDate := SAFTExportHeader."Starting Date";
        while CurrDate <= SAFTExportHeader."Ending Date" do begin
            SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(CurrDate, 1);
            CurrDate := CalcDate('<1M>', CurrDate);
        end;

        // [WHEN] Run SAF-T Export
        LibraryVariableStorage.Enqueue(SetStartDateTimeAsCurrentQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] 8 background tasks were started at the same moment
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.SetFilter("Task ID", '<>%1', NullGuid);
        Assert.RecordCount(SAFTExportLine, MaxNoOfJobs);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TransactionCountPersistedBeforeParallelTasks()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        GLEntry: Record "G/L Entry";
        SAFTJobQueueTests: Codeunit "SAF-T Job Queue Tests";
        TransactionNo: Integer;
        NullGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] The complete 1.30 document/date count is persisted before any parallel task is accepted.
        Initialize();

        // [GIVEN] Three groups sharing one transaction number, spread over two monthly parts
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Four Digit Standard Account", 1);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTExportHeader.Validate("Ending Date", CalcDate('<1M+CM>', SAFTExportHeader."Starting Date"));
        SAFTExportHeader.Validate("Parallel Processing", true);
        SAFTExportHeader.Validate("Split By Month", true);
        SAFTExportHeader.Validate("Max No. Of Jobs", 3);
        SAFTExportHeader.Modify(true);
        GLAccount.FindFirst();
        SourceCode.FindFirst();
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.FindLast();
        TransactionNo := GLEntry."Transaction No." + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode.Code, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-B', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode.Code, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode.Code, 100, 0);
        SAFTJobQueueTests.SetExpectedTransactionCount(SAFTExportHeader.ID, 3);
        BindSubscription(SAFTJobQueueTests);

        // [WHEN] Start export with the existing fake scheduler
        LibraryVariableStorage.Enqueue(SetStartDateTimeAsCurrentQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Every accepted task observed the persisted total before it was assigned a task ID
        Assert.AreEqual(3, SAFTJobQueueTests.GetVerifiedScheduledTasks(), 'Expected master data and two monthly tasks.');
        SAFTExportLine.SetRange(ID, SAFTExportHeader.ID);
        SAFTExportLine.SetFilter("Task ID", '<>%1', NullGuid);
        Assert.RecordCount(SAFTExportLine, 3);
        SAFTExportHeader.Get(SAFTExportHeader.ID);
        Assert.AreEqual(3, SAFTExportHeader."Number of G/L Entries", 'Incorrect persisted selection-wide transaction count.');
        UnbindSubscription(SAFTJobQueueTests);
        LibraryVariableStorage.AssertEmpty();
    end;

    procedure SetExpectedTransactionCount(ExportID: Integer; TransactionCount: Integer)
    begin
        ExpectedExportID := ExportID;
        ExpectedTransactionCount := TransactionCount;
        VerifiedScheduledTasks := 0;
    end;

    procedure GetVerifiedScheduledTasks(): Integer
    begin
        exit(VerifiedScheduledTasks);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SAF-T Job Queue Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SAF-T Job Queue Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SAF-T Job Queue Tests");
    end;

    local procedure SetupSAFT(var SAFTMappingRange: Record "SAF-T Mapping Range"; MappingType: Enum "SAF-T Mapping Type"): Code[20]
    var
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
    begin
        SAFTTestHelper.SetupMasterData(LibraryRandom.RandInt(5));
        SAFTMappingHelper.MapRestSourceCodesToAssortedJournals();
        SAFTTestHelper.InsertSAFTMappingRangeFullySetup(
            SAFTMappingRange, MappingType,
            CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        exit(SAFTMappingRange.Code);
    end;

    local procedure MatchGLAccountsFourDigit(MappingRangeCode: Code[20])
    var
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
    begin
        SAFTGLAccountMapping.SetRange("Mapping Range Code", MappingRangeCode);
        SAFTGLAccountMapping.FindSet();
        SAFTMapping.FindSet();
        repeat
            SAFTGLAccountMapping.Validate("Category No.", SAFTMapping."Category No.");
            SAFTGLAccountMapping.Validate("No.", SAFTMapping."No.");
            SAFTGLAccountMapping.Modify(true);
            SAFTMapping.Next();
        until SAFTGLAccountMapping.Next() = 0;
    end;

    local procedure CreateSAFTExportHeader(var SAFTExportHeader: Record "SAF-T Export Header"; MappingRangeCode: Code[20]; MaxNoOfJobs: Integer)
    begin
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, MappingRangeCode);
        SAFTExportHeader."Parallel Processing" := true;
        SAFTExportHeader."Max No. Of Jobs" := MaxNoOfJobs;
        SAFTExportHeader."Parallel Processing" := true;
        SAFTExportHeader.Modify();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SAF-T Export Mgt.", 'OnBeforeScheduleTask', '', false, false)]
    local procedure OnBeforeScheduleTask(var DoNotScheduleTask: Boolean; var TaskID: Guid)
    var
        SAFTExportHeader: Record "SAF-T Export Header";
    begin
        if ExpectedExportID <> 0 then begin
            SAFTExportHeader.Get(ExpectedExportID);
            Assert.AreEqual(
                ExpectedTransactionCount, SAFTExportHeader."Number of G/L Entries",
                'The selection-wide count must be persisted before scheduling any task.');
            VerifiedScheduledTasks += 1;
        end;
        DoNotScheduleTask := true;
        TaskID := CreateGuid();
    end;

}
