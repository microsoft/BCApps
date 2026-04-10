codeunit 134342 "ERM Posting Outside Date"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Posting After Working Date]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        InstructionMgt: Codeunit "Instruction Mgt.";
        IsInitialized: Boolean;
        ConfirmPostingAfterWorkingDateQst: Label 'The posting date of one or more journal lines is after the working date. Do you want to continue?';
        UnexpectedConfirmTextErr: Label 'Unexpected confirmation text.';
        NotAllowedToPostAfterWorkingDateErr: Label 'Cannot post because one or more transactions have dates after the working date.';

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineCurrentDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 169269] General Journal Line with "Posting Date" equals current work date should be posted without asking for confirmation

        Initialize();

        // [GIVEN] "Posting After Working Date" confirmation is enabled
        EnablePostingAfterWorkignDate();

        // [GIVEN] Current work date is 05.01.2017
        // [GIVEN] General Journal Line with "Posting Date" = 05.01.2017
        CreateGenJnlLine(GenJnlLine, WorkDate());

        // [WHEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] General Journal Line is posted
        VerifyGLEntryExists(GenJnlLine."Posting Date", GenJnlLine."Document No.");

        // Tear Down
        DisablePostingAfterWorkingDate();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlLineBeforeCurrentDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 169269] General Journal Line with "Posting Date" before current work date should be posted without asking for confirmation

        Initialize();

        // [GIVEN] "Posting After Working Date" confirmation is enabled
        EnablePostingAfterWorkignDate();

        // [GIVEN] Current work date is 06.01.2017
        // [GIVEN] General Journal Line with "Posting Date" = 05.01.2017
        CreateGenJnlLine(GenJnlLine, WorkDate() - LibraryRandom.RandInt(100));

        // [WHEN] Post General Journal Line
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] General Journal Line is posted
        VerifyGLEntryExists(GenJnlLine."Posting Date", GenJnlLine."Document No.");

        // Tear Down
        DisablePostingAfterWorkingDate();
    end;

    [Test]
    [HandlerFunctions('ConfirmByQuestionHandler')]
    [Scope('OnPrem')]
    procedure PostGenJnlLineConfirmPostingAfterCurrentDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 169269] General Journal Line after current date should be posted if confirmed

        Initialize();

        // [GIVEN] "Posting After Working Date" confirmation is enabled
        EnablePostingAfterWorkignDate();

        // [GIVEN] Current work date is 06.01.2017
        // [GIVEN] General Journal Line with "Posting Date" = 07.01.2017
        CreateGenJnlLine(GenJnlLine, WorkDate() + 1);
        LibraryVariableStorage.Enqueue(ConfirmPostingAfterWorkingDateQst);

        // [WHEN] Confirm dialog "The posting date of one or more General Journal Line is after the current date. Do you want to continue?" while posting Gen. Journal Line
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] General Journal Line is posted
        VerifyGLEntryExists(GenJnlLine."Posting Date", GenJnlLine."Document No.");

        // Tear Down
        DisablePostingAfterWorkingDate();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PostGenJnlLineDoNotConfirmPostingAfterWorkingDate()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 169269] Error message should be thrown if posting of General Journal Line after working date is not confirmed

        Initialize();

        // [GIVEN] "Posting After Working Date" confirmation is enabled
        EnablePostingAfterWorkignDate();

        // [GIVEN] Current work date is 06.01.2017
        // [GIVEN] General Journal Line with "Posting Date" = 07.01.2017
        CreateGenJnlLine(GenJnlLine, WorkDate() + 1);
        Commit();

        // [WHEN] Do not confirm dialog "The posting date of one or more General Journal Line is after the working date. Do you want to continue?" while posting Gen. Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] General Journal Line is not posted and error message "You cannot post when one or more dates is After the working date" is thrown
        Assert.ExpectedError(NotAllowedToPostAfterWorkingDateErr);
        GenJnlLine.Find();
        VerfifyGLEntryDoesNotExist(GenJnlLine."Posting Date", GenJnlLine."Document No.");

        // Tear Down
        DisablePostingAfterWorkingDate();
    end;

    [Test]
    [HandlerFunctions('ConfirmWithCheckHandler')]
    [Scope('OnPrem')]
    procedure PostMultipleGenJnlLineWithOneConfirmAfterWorkingDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlLine: array[2] of Record "Gen. Journal Line";
        i: Integer;
    begin
        // [SCENARIO 169269] Multiple General Journal Lines after current date should be posted with only one confirmation of "Posting After Working Date"

        Initialize();

        // [GIVEN] "Posting After Working Date" confirmation is enabled
        EnablePostingAfterWorkignDate();

        // [GIVEN] Current work date is 06.01.2017
        // [GIVEN] Two General Journal Lines with "Posting Date" = 07.01.2017
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        for i := 1 to ArrayLen(GenJnlLine) do
            CreateGenJnlLineWithBatch(GenJnlLine[i], GenJournalBatch, WorkDate() + 1);

        // [WHEN] Confirm dialog "The posting date of one or more General Journal Line is after working date. Do you want to continue?" while posting Gen. Journal Line one time for two entries
        // Single confirmation handled by ConfirmWithCheckHandler
        LibraryVariableStorage.Enqueue(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine[1]); // will post two entries with the same batch

        // [THEN] General Journal Lines are posted
        for i := 1 to ArrayLen(GenJnlLine) do
            VerifyGLEntryExists(GenJnlLine[i]."Posting Date", GenJnlLine[i]."Document No.");

        // Tear Down
        DisablePostingAfterWorkingDate();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Posting Outside Date");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Posting Outside Date");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Posting Outside Date");
    end;

    local procedure EnablePostingAfterWorkignDate()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(
          InstructionMgt.GetPostingAfterWorkingDateNotificationId(),
          InstructionMgt.PostingAfterWorkingDateNotAllowedCode(),
          '', true);
    end;

    local procedure DisablePostingAfterWorkingDate()
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.Get(UserId, InstructionMgt.GetPostingAfterWorkingDateNotificationId()) then
            MyNotifications.Delete();
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Modify(true);
    end;

    local procedure CreateGenJnlLineWithBatch(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; PostingDate: Date)
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine."Document Type"::Invoice, GenJnlLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          GenJnlLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Modify(true);
    end;

    local procedure VerifyGLEntryExists(PostingDate: Date; DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Document No.", DocNo);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerfifyGLEntryDoesNotExist(PostingDate: Date; DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("Document No.", DocNo);
        Assert.RecordIsEmpty(GLEntry);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmWithCheckHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmByQuestionHandler(Question: Text; var Reply: Boolean)
    begin
        // There should be no additonal confirm except one passed from LibraryVariableStorage
        Assert.AreNotEqual(0, StrPos(Question, LibraryVariableStorage.DequeueText()), UnexpectedConfirmTextErr);
        Reply := true;
    end;
}

