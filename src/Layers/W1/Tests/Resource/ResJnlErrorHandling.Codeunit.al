codeunit 136613 "Res. Jnl. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Error Handling]
    end;

    var
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        TestFieldMustHaveValueErr: Label '%1 must have a value', Comment = '%1 - field caption';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalSunshine()
    var
        ResJournalLine: Record "Res. Journal Line";
        ResourceJournal: TestPage "Resource Journal";
    begin
        // [FEATURE] [Resource Journal]
        // [SCENARIO 411162] Journal errors factbox works for Resource journal
        Initialize();

        // [GIVEN] Create journal line with empty "Gen. Prod. Posting Group"
        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine);

        // [WHEN] Open res journal for batch "XXX"
        ResourceJournal.Trap();
        Page.Run(Page::"Resource Journal", ResJournalLine);

        // [THEN] Journal Errors factbox shows message "Gen. Prod. Posting Group must have a value."
        VerifyErrorMessageText(
            ResourceJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, ResJournalLine.FieldCaption("Gen. Prod. Posting Group")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalNumberOfBatchErrors()
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJournalBatch: Record "Res. Journal Batch";
        ResourceJournal: TestPage "Resource Journal";
        i: Integer;
        NumbefOfLines: Integer;
    begin
        // [FEATURE] [Res Journal]
        // [SCENARIO 411162] Journal errors factbox shows the number of batch errors
        Initialize();

        // [GIVEN] Create 5 journal lines with empty "Gen. Prod. Posting Group"
        FindResourceJournalBatch(ResJournalBatch);
        NumbefOfLines := LibraryRandom.RandIntInRange(5, 10);
        for i := 1 to NumbefOfLines do
            CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine, ResJournalBatch);

        // [WHEN] Open res journal for batch "XXX"
        ResourceJournal.Trap();
        Page.Run(Page::"Resource Journal", ResJournalLine);

        // [THEN] Journal Errors factbox shows Lines with Issues = 5
        ResourceJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(NumbefOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLineWithErrors()
    var
        ResJournalLine: array[2] of Record "Res. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ResJournalBatch: Record "Res. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        TemJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] [Res Journal]
        // [SCENARIO 411162] Errors for deleted journal lines removed from error messages
        Initialize();

        // [GIVEN] journal lines with empty "Gen. Prod. Posting Group" ress: Line1 and Line2
        FindResourceJournalBatch(ResJournalBatch);
        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine[1], ResJournalBatch);

        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine[2], ResJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            ResJournalLine[1]."Journal Template Name",
            ResJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [GIVEN] Mock Line2 deleted
        TemJournalErrorsMgt.InsertDeletedResJnlLine(ResJournalLine[2]);
        ResJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args); // Mock call from "Journal Errors Factbox".CheckErrorsInBackground
        SetErrorHandlingParameters(ErrorHandlingParameters, ResJournalLine[1], 0);
        BackgroundErrorHandlingMgt.CleanResJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", ResJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalShowAllLinesActionsEnabledState()
    var
        ResJournalLine: Record "Res. Journal Line";
        ResourceJournal: TestPage "Resource Journal";
        LinesWithIssuesCounter: Integer;
    begin
        // [SCENARIO 411162] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine);

        // [GIVEN] Open res journal for batch "XXX"
        ResourceJournal.Trap();
        Page.Run(Page::"Resource Journal", ResJournalLine);
        // [WHEN] Action "Show Lines with Errors" is selected
        ResourceJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Check that there is one line shown in the journal
        if ResourceJournal.First() then
            repeat
                LinesWithIssuesCounter += 1;
            until not ResourceJournal.Next();
        Assert.AreEqual(1, LinesWithIssuesCounter - 1, 'There must be exactly one line shown in the journal');

        // [WHEN] Action "Show All Lines" is being selected
        ResourceJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        Assert.IsTrue(ResourceJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        Assert.IsFalse(ResourceJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalCheckUpdatedLineWithError()
    var
        ResJournalLine: array[2] of Record "Res. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ResJournalBatch: Record "Res. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        ResJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and fixed error deleted
        Initialize();

        // [GIVEN] journal lines with empty "Gen. Prod. Posting Group": Line1 and Line2
        FindResourceJournalBatch(ResJournalBatch);
        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine[1], ResJournalBatch);

        CreateResJournalLineWithEmptyGenProdPostGroup(ResJournalLine[2], ResJournalBatch);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            ResJournalLine[1]."Journal Template Name",
            ResJournalLine[1]."Journal Batch Name",
            TempErrorMessage);
        TempErrorMessage.Reset();
        Assert.AreEqual(2, TempErrorMessage.Count, 'Invalid number of error messages');

        // [GIVEN] Set Gen. Prod. Posting Group = 'XXX' for Line 2 and mock it is modified
        ResJournalLine[2]."Gen. Prod. Posting Group" := ResJournalLine[1]."Gen. Prod. Posting Group";
        ResJournalLine[2].Modify();
        ResJournalErrorsMgt.SetResJnlLineOnModify(ResJournalLine[2]);

        // [WHEN] Run CleanTempErrorMessages
        SetErrorHandlingParameters(ErrorHandlingParameters, ResJournalLine[1], ResJournalLine[2]."Line No.");
        BackgroundErrorHandlingMgt.CleanResJnlTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", ResJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceJournalCheckUpdatedLineNewError()
    var
        ResJournalLine: array[2] of Record "Res. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ResJournalBatch: Record "Res. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        TemJournalErrorsMgt: Codeunit "Res. Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411162] Updated line checked after moving focus to another line and new error found
        Initialize();

        // [GIVEN] journal lines with not empty Gen. Prod. Posting Group: Line1 and Line2
        FindResourceJournalBatch(ResJournalBatch);
        CreateResJournalLine(ResJournalLine[1], ResJournalBatch);
        CreateResJournalLine(ResJournalLine[2], ResJournalBatch);

        // [GIVEN] Set Gen. Prod. Posting Group = '' for Line 2 and mock it is modified
        ResJournalLine[2]."Gen. Prod. Posting Group" := '';
        ResJournalLine[2].Modify();
        TemJournalErrorsMgt.SetResJnlLineOnModify(ResJournalLine[2]);

        // [WHEN] Run background check
        SetErrorHandlingParameters(ErrorHandlingParameters, ResJournalLine[1], ResJournalLine[2]."Line No.");
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);

        // [THEN] Empty Gen. Prod. Posting Group error message about Line2 created
        TempErrorMessage.Reset();
        TempErrorMessage.FindFirst();

        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldMustHaveValueErr, ResJournalLine[2].FieldCaption("Gen. Prod. Posting Group")));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Res. Jnl. Error Handling");
        LibrarySetupStorage.Restore();
        Commit(); // need to notify background sessions about data restore
        if IsInitialized then
            exit;

        SetEnableDataCheck(true);
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Res. Jnl. Error Handling");

        Commit();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Res. Jnl. Error Handling");
    end;

    local procedure SetEnableDataCheck(Enabled: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Data Check", Enabled);
        GLSetup.Modify();
    end;

    local procedure CreateResJournalLine(var ResJournalLine: Record "Res. Journal Line"; ResJournalBatch: Record "Res. Journal Batch")
    begin
        LibraryResource.CreateResJournalLine(ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Resource No.", LibraryResource.CreateResourceNo());
        ResJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ResJournalLine.Validate("Document No.", ResJournalLine."Resource No.");
        ResJournalLine.Modify();
    end;

    local procedure CreateResJournalLineWithEmptyGenProdPostGroup(var ResJournalLine: Record "Res. Journal Line"; ResJournalBatch: Record "Res. Journal Batch")
    begin
        LibraryResource.CreateResJournalLine(
            ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Resource No.", LibraryResource.CreateResourceNo());
        ResJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(2, 10));
        ResJournalLine.Validate("Document No.", ResJournalLine."Resource No.");
        ResJournalLine."Gen. Prod. Posting Group" := '';
        ResJournalLine.Modify();
    end;

    local procedure CreateResJournalLineWithEmptyGenProdPostGroup(var ResJournalLine: Record "Res. Journal Line")
    var
        ResJournalBatch: Record "Res. Journal Batch";
    begin
        FindResourceJournalBatch(ResJournalBatch);
        LibraryResource.CreateResJournalLine(
            ResJournalLine, ResJournalBatch."Journal Template Name", ResJournalBatch.Name);
        ResJournalLine.Validate("Posting Date", WorkDate());
        ResJournalLine.Validate("Resource No.", LibraryResource.CreateResourceNo());
        ResJournalLine.Validate(Quantity, LibraryRandom.RandIntInRange(2, 10));
        ResJournalLine.Validate("Document No.", ResJournalLine."Resource No.");
        ResJournalLine."Gen. Prod. Posting Group" := '';
        ResJournalLine.Modify();
    end;

    local procedure FindResourceJournalBatch(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalTemplate: Record "Res. Journal Template";
    begin
        ResJournalTemplate.SetRange(Recurring, false);
        if not ResJournalTemplate.FindFirst() then
            LibraryResource.CreateResourceJournalTemplate(ResJournalTemplate);
        ResJournalBatch.SetRange("Journal Template Name", ResJournalTemplate.Name);
        if not ResJournalBatch.FindFirst() then
            LibraryResource.CreateResourceJournalBatch(ResJournalBatch, ResJournalTemplate.Name);
        ClearResourceJournalLines(ResJournalBatch);
    end;

    local procedure ClearResourceJournalLines(var ResJournalBatch: Record "Res. Journal Batch")
    var
        ResJournalLine: Record "Res. Journal Line";
    begin
        ResJournalLine.SetRange("Journal Template Name", ResJournalBatch."Journal Template Name");
        ResJournalLine.SetRange("Journal Batch Name", ResJournalBatch.Name);
        ResJournalLine.DeleteAll(true);
    end;

    local procedure ClearTempErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
    end;

    local procedure MockFullBatchCheck(TemplateName: Code[10]; BatchName: Code[10]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
    begin
        ClearTempErrorMessage(TempErrorMessage);

        SetErrorHandlingParameters(ErrorHandlingParameters, TemplateName, BatchName, true);
        RunBackgroundCheck(ErrorHandlingParameters, TempErrorMessage);
    end;

    local procedure RunBackgroundCheck(ErrorHandlingParameters: Record "Error Handling Parameters"; var TempErrorMessage: Record "Error Message" temporary)
    var
        Params: Dictionary of [Text, Text];
        CheckResJnlLineBackgr: Codeunit "Check Res. Jnl. Line. Backgr.";
    begin
        ErrorHandlingParameters.ToArgs(Params);
        Commit();
        CheckResJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; TemplateName: Code[10]; BatchName: Code[10]; FullBatchCheck: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := TemplateName;
        ErrorHandlingParameters."Journal Batch Name" := BatchName;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; ResJournalLine: Record "Res. Journal Line"; PreviosLineNo: Integer)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := ResJournalLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := ResJournalLine."Journal Batch Name";
        ErrorHandlingParameters."Line No." := ResJournalLine."Line No.";
        ErrorHandlingParameters."Previous Line No." := PreviosLineNo;
    end;

    local procedure VerifyErrorMessageText(ActualText: Text; ExpectedText: Text)
    begin
        Assert.IsSubstring(ActualText, ExpectedText);
    end;
}