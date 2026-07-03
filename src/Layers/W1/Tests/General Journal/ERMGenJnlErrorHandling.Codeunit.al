codeunit 134932 "ERM Gen. Jnl. Error Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [UI] [Journal Error Handling]
    end;

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        DummyErr: Label 'Dummy error';
        TestFieldMustHaveValueErr: Label '%1 must have a value', Comment = '%1 - field caption';
        TestFieldValueErr: Label '%1 must be equal to %2', Comment = '%1 - field caption, %2 - field value';
        TestFieldOptionValueErr: Label '%1 must be equal to ''%2''', Comment = '%1 - field caption, %2 - field value';
        DocumentOutOfBalanceErr: Label 'Document No. %1 is out of balance by %2', Comment = '%1 - document number, %2 = amount';
        FieldMustNotBeErr: Label '%1 must not be %2', Comment = '%1 - field name, %2 - field value';
        OutOfBalanceFilterTxt: Label '*is out of balance by*';
        RecurringDocIsOutOfBalanceFilterTxt: Label 'Document No. %1 is out of balance.', Comment = '%1 - document number';
        ExtendingGenJnlCheckLineTxt: Label 'ExtendingGenJnlCheckLine', Locked = true;
        ExtendingGenJnlCheckLineNewTxt: Label 'ExtendingGenJnlCheckLineWithCollectError', Locked = true;
        LogTestFieldOptionTxt: Label 'LogTestFieldOption', Locked = true;
        LogTestFieldOptionNewTxt: Label 'LogTestFieldOptionWithCollectError', Locked = true;
        DimErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for G/L Account %2.', Comment = '%1 - dimension code, %2 - account number';
        OnBeforeRunCheckTxt: Label 'OnBeforeRunCheck', Locked = true;
        ExpectedErrorTxt: Label 'Expected should be : %1', Comment = '%1 - Expected error message';
        NotAllowedPostingDateErr: Label 'is not within your range of allowed posting dates';
        RecurringLineIsExpiredErr: Label 'The posting date %1 must be less or equal the expiration date %2 in the document %3.', Comment = '%1 - posting date, %2 - expiration date, %3 - document number';
        RecurringLineIsOutOfWorkdateErr: Label 'The posting date %1 must be less or equal the working date %2 in the document %3.', Comment = '%1 - posting date, %2 - working date, %3 - document number';

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfBatchErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Batch Errors field shows correct number of errors for all lines in batch
        Initialize();

        // [GIVEN] Create 5 single line documents with zero amount for new batch "XXX"
        CreateZeroAmountJournalLines(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Number for batch errors = 5
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(GetNumberOfLines(GenJournalLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfDocumentOutOfBalanceErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        TotalBalance: Decimal;
    begin
        // [SCENARIO 355641] Multiline out of balance document gives one common batch error
        Initialize();

        // [GIVEN] Create 5 line document for new batch "XXX" with balance 100
        CreateMultiLineGenJnlDocOutOfBalance(GenJournalLine, TotalBalance);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Number for batch errors = 1
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfLinesChecked()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Lines Checked field shows correct number of lines in batch
        Initialize();

        // [GIVEN] Create 6 line document 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Lines Checked = 6
        GeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(GetNumberOfLines(GenJournalLine));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NumberOfLinesWithErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] "Lines with Issues" field shows correct number of lines with errors
        Initialize();

        // [GIVEN] Create 5 single document lines 
        CreateGenJournalLines(GenJournalLine, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Clear amount and document number for first and last lines
        SetBatchFilter(GenJournalLine);
        GenJournalLine.FindFirst();
        ClearAmountAndDocumentNo(GenJournalLine);

        GenJournalLine.FindLast();
        ClearAmountAndDocumentNo(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] "Lines with Issues" = 2
        GeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentLineTwoErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Current line group shows 2 errors
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with 2 errors: empty document number and amount 
        CreateGenJournalLine(GenJournalLine);
        ClearAmountAndDocumentNo(GenJournalLine);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] First error line is "Document No. must not be empty" 
        VerifyErrorMessageText(GeneralJournal.JournalErrorsFactBox.Error1.Value, StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
        VerifyErrorMessageText(GeneralJournal.JournalErrorsFactBox.Error2.Value, StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrentLineThreeErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Second row shows message "(+2 other issues)" in case of 3 errors
        Initialize();

        // [GIVEN] Set allwow posign to = 31.12.2020
        LibraryERM.SetAllowPostingFromTo(0D, WorkDate() - 1);

        // [GIVEN] Create journal line for new batch "XXX" with 3 errors: empty document number, amount and posting date = 01.01.2021
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine."Document No." := '';
        GenJournalLine.TestField("Posting Date", WorkDate());
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        Commit();
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BatchErrorsDrillDown()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ErrorMessages: TestPage "Error Messages";
        TotalBalance: Decimal;
        GLSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 355641] DrillDown from Batch Errors field opens list of errors
        Initialize();
        GLSetup.Get();

        // [GIVEN] Create 5 line document "DOC" for new batch "XXX" with balance 100
        CreateMultiLineGenJnlDocOutOfBalance(GenJournalLine, TotalBalance);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [WHEN] DrillDown from Batch Erros fields
        ErrorMessages.Trap();
        GeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.Drilldown();

        // [THEN] Error Messages page opened with Description = "Document DOC is out of balance by 100"
        ErrorMessages.Description.AssertEquals(StrSubstNo(DocumentOutOfBalanceErr, GenJournalLine."Document No.", TotalBalance));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendingGenJnlCheckLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Journal errors log shows errors from extension of codeunit "Gen. Jnl.-Check Line" 
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise "Dummy error"
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'ExtendingGenJnlCheckLine' for the subscriber 
        GenJournalLine.Description := ExtendingGenJnlCheckLineTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRun(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "Dummy error"
        TempErrorMessage.TestField("Message", DummyErr);
        TempErrorMessage.TestField("Context Record ID", GenJournalLine.RecordId());

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldOption()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Journal errors log shows TestField error for option type field with option caption 
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise option field error
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'LogTestFieldOption' for the subscriber 
        GenJournalLine.Description := LogTestFieldOptionTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRun(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "IC Direction must be Outgoing"
        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldValueErr, GenJournalLine.FieldCaption("IC Direction"), GenJournalLine."IC Direction"::Outgoing));

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendingGenJnlCheckLineWithErrorBehaviorCollectError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411163] Journal errors log shows errors from extension of codeunit "Gen. Jnl.-Check Line" with Error(ErrorInfo.Create())
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise "Dummy error"
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'ExtendingGenJnlCheckLineWithCollectError' for the subscriber 
        GenJournalLine.Description := ExtendingGenJnlCheckLineNewTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with ErrorBehavior::Collect
        MockGenJnlCheckLineRunWithErrorBehaviorCollect(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "Dummy error"
        TempErrorMessage.TestField("Message", DummyErr);
        TempErrorMessage.TestField("Context Record ID", GenJournalLine.RecordId());

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogTestFieldOptionWithErrorBehaviorCollectError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 411163] Journal errors log shows TestField error for option type field with option caption with TestField(Field, ErrorInfo.Create)
        Initialize();

        // [GIVEN] Subscribe to OnAfterCheckGenJnlLine event to raise option field error
        BindSubscription(ERMGenJnlErrorHandling);

        // [GIVEN] Create journal line
        CreateGenJournalLine(GenJournalLine);
        // [GIVEN] Set Description = 'LogTestFieldOptionWithCollectError' for the subscriber 
        GenJournalLine.Description := LogTestFieldOptionNewTxt;
        GenJournalLine.Modify();

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with with ErrorBehavior::Collect
        MockGenJnlCheckLineRunWithErrorBehaviorCollect(GenJournalLine, TempErrorMessage);

        // [THEN] Error message has Description = "IC Direction must be 'Outgoing'"
        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldOptionValueErr, GenJournalLine.FieldCaption("IC Direction"), GenJournalLine."IC Direction"::Outgoing));

        UnbindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxTestFieldNotEmpty()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by test field against empty value is "FieldXXX must not be empty"
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(GeneralJournal.JournalErrorsFactBox.Error1.Value, StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxTestFieldValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by test field against some value is "FieldXXX must be equal to YYY."
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with "Pmt. Discount Date" = 25.01.2020 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Pmt. Discount Date" := WorkDate();
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Pmt. Discount Date must be equal to ''."
        VerifyErrorMessageText(GeneralJournal.JournalErrorsFactBox.Error1.Value, StrSubstNo(TestFieldValueErr, GenJournalLine.FieldCaption("Pmt. Discount Date"), ''''''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxFieldError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by FieldError with error message parameters is "FieldXXX ErrorMessageYYY"
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with Amount = 100, "Amount (LCY)" = -100
        CreateGenJournalLine(GenJournalLine);
        LibraryERM.CreateICPartner(ICPartner);
        GenJournalLine.Amount := LibraryRandom.RandDec(100, 2);
        GenJournalLine."Amount (LCY)" := -LibraryRandom.RandDec(100, 2);
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Amount (LCY) must have the same sign as Amount"
        // skip check due to platform bug 415131
        // VerifyErrorMessageText(
        //     GeneralJournal.JournalErrorsFactBox.Error1.Value,
        //     StrSubstNo(
        //         SameSignErr, GenJournalLine.FieldCaption("Amount (LCY)"), GenJournalLine.FieldCaption(Amount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalLineErrorsFactBoxFieldErrorNoErrorMessage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICPartner: Record "IC Partner";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Message for error caused by FieldError without parameters is "FieldXXX must not be YYY."
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with Account Type = "IC Partner""
        CreateGenJournalLine(GenJournalLine);
        LibraryERM.CreateICPartner(ICPartner);
        GenJournalLine."Account Type" := "Gen. Journal Account Type"::"IC Partner";
        GenJournalLine."Account No." := ICPartner.Code;
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Account Type must not be IC Partner."
        VerifyErrorMessageText(
            GeneralJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(
                FieldMustNotBeErr, GenJournalLine.FieldCaption("Account Type"), "Gen. Journal Account Type"::"IC Partner"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JournalBatchBackgroundErrorCheckYes()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Background check related controls are visible on the general journal page for batch with "Background Error "Check = Yes
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with "Pmt. Discount Date" = 25.01.2020 
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine."Pmt. Discount Date" := WorkDate();
        GenJournalLine.Modify();

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [THEN] Action items are visible
        Assert.IsTrue(GeneralJournal.ShowLinesWithErrors.Visible(), 'ShowLinesWithErrors must be visible');
        Assert.IsTrue(GeneralJournal.ShowAllLines.Visible(), 'ShowAllLines must be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when make multiline document out of balance
        Initialize();

        // [GIVEN] Create 6 line document with zero balance 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Increase first line amount by 100 to make document out of balance 
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate(Amount, GenJournalLine.Amount + LibraryRandom.RandDec(100, 2));
        GenJournalLine.Modify();

        // [WHEN] Mock line modified
        Commit();
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter("Message", OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalanceByClearDocumentNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when make one of multiline document line empty document number
        Initialize();

        // [GIVEN] Create 6 line document with zero balance 
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Set first line document number empty
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Modify();

        // [WHEN] RunCheck to mock move from first line to second line 
        Commit();
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter("Message", OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeMultilineDocumentOutOfBalanceByUpdatePostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;

    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when change the Posting Date for one of multiline document line 
        Initialize();

        // [GIVEN] Create 6 line document with zero balance and "Posting Date" = 22.01.2020
        CreateMultiLineGenJnlDocZeroBalance(GenJournalLine);

        // [GIVEN] Set first line "Posting Date" = 23.01.2020
        GenJournalLine.FindFirst();
        xGenJournalLine := GenJournalLine;
        GenJournalLine.Validate("Posting Date", CalcDate('<+1D>', WorkDate()));
        GenJournalLine.Modify();

        // [WHEN] RunCheck to mock move from first line to second line 
        MockLineModified(xGenJournalLine, GenJournalLine, TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 6
        TempErrorMessage.SetFilter("Message", OutOfBalanceFilterTxt);
        Assert.AreEqual(GenJournalLine.Count(), TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeTwoMultilineDocumentsOutOfBalanceByMovingToThirdDocument()
    var
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempErrorMessage: Record "Error Message" temporary;
        xDocumentNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Unit test to check errors when change the document number from DOC1 to DOC2 and move to DOC3
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Create 6 line zero balance document DOC1  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[1]);

        // [GIVEN] Create 6 line zero balance document DOC2  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[2]);
        // [GIVEN] Create 6 line zero balance document DOC3  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[3]);

        // [GIVEN] For first line of DOC2 set "Document No." = DOC1
        GenJournalLine[2].FindFirst();
        xDocumentNo := GenJournalLine[2]."Document No.";
        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[2].Modify();

        // [GIVEN] RunCheck to mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 12
        Assert.AreEqual(GenJournalLine[1].Count() + GenJournalLine[2].Count(), TempErrorMessage.Count(), 'Invalid number of errors');

        // [GIVEN] Mock first line of DOC2 as xRec before update "Document No."
        GenJournalLine[2].Find();
        xGenJournalLine := GenJournalLine[2];

        // [GIVEN] For first line of DOC2 set back "Document No." = DOC2
        GenJournalLine[2]."Document No." := xDocumentNo;
        GenJournalLine[2].Modify();

        // [WHEN] RunCheck to mock move from first line of DOC2 to line of DOC3 
        MockLineModified(xGenJournalLine, GenJournalLine[2], TempErrorMessage);

        // [THEN] Number of errors became 0
        Assert.AreEqual(0, TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for cash receipt journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::"Cash Receipts", Page::"Cash Receipt Journal");

        // [WHEN] Open cash receipt journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            CashReceiptJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for sales journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Sales, Page::"Sales Journal");

        // [WHEN] Open sales journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            SalesJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for purchase journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Purchases, Page::"Purchase Journal");

        // [WHEN] Open purchase journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            PurchaseJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for payment journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Payments, Page::"Payment Journal");

        // [WHEN] Open payment journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            PaymentJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for fixed assets G/L journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Assets, Page::"Fixed Asset G/L Journal");

        // [WHEN] Open fixed assets G/L journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            FixedAssetGLJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for fixed assets IC General Journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Intercompany, Page::"IC General Journal");

        // [WHEN] Open IC general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(ICGeneralJournal.JournalErrorsFactBox.Error1.Value, StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalSunshine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Journal errors factbox works for Jobs G/L journal
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" with empty document 
        CreateEmptyDocGenJournalLineForTemplate(GenJournalLine, "Gen. Journal Template Type"::Jobs, Page::"Job G/L Journal");

        // [WHEN] Open Jobs G/L journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);

        // [THEN] Journal Errors factbox shows message "Document No. must not be empty."
        VerifyErrorMessageText(
            JobGLJournal.JournalErrorsFactBox.Error1.Value,
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption("Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLineWithErrors()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Errors for deleted journal lines removed from error messages
        Initialize();

        // [GIVEN] journal lines with empty amount: Line1 and Line2
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        // [GIVEN] Mock 2 error messages for Line1 and Line2
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [GIVEN] Mock Line2 deleted
        JournalErrorsMgt.InsertDeletedLine(GenJournalLine[2]);
        GenJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args); // Mock call from "Journal Errors Factbox".CheckErrorsInBackground
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Error message about Line2 deleted
        TempErrorMessage.Reset();
        TempErrorMessage.SetRange("Context Record ID", GenJournalLine[2].RecordId);
        Assert.IsTrue(TempErrorMessage.IsEmpty, 'Error message for line 2 has to be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteJnlLinesWithErrorsToMakeZeroDocsBalance()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        ExtraGenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Args: Dictionary of [Text, Text];
    begin
        // [FEATURE] 
        // [SCENARIO 355641] Balance checked for deleted lines 
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Create 6 line zero balance document DOC1  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[1]);

        // [GIVEN] Create 6 line zero balance document DOC2  
        CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch, GenJournalLine[2]);

        // [GIVEN] Create one more line for document DOC1
        CreateGenJournalLineWithDocumentNo(ExtraGenJournalLine[1], GenJournalBatch, GenJournalLine[1]."Document No.");
        // [GIVEN] Create one more line for document DOC2
        CreateGenJournalLineWithDocumentNo(ExtraGenJournalLine[2], GenJournalBatch, GenJournalLine[2]."Document No.");

        // [GIVEN] RunCheck to mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);

        // [THEN] Number of "out of balance" errors = 14
        Assert.AreEqual(GenJournalLine[1].Count() + GenJournalLine[2].Count(), TempErrorMessage.Count(), 'Invalid number of errors');

        // [GIVEN] Mock 2 extra lines deleted
        JournalErrorsMgt.InsertDeletedLine(ExtraGenJournalLine[1]);
        ExtraGenJournalLine[1].Delete();
        JournalErrorsMgt.InsertDeletedLine(ExtraGenJournalLine[2]);
        ExtraGenJournalLine[2].Delete();

        // [WHEN] Run CleanTempErrorMessages 
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args); // Mock call from "Journal Errors Factbox".CheckErrorsInBackground
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Removed not only errors related to deleted lines but for documents DOC1 and DOC2 lines as well 
        Assert.AreEqual(0, TempErrorMessage.Count(), 'Invalid number of errors');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MoveToAnotherJournalLineWithoutModify()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ErrorHandlingParameters: Record "Error Handling Parameters";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        ErrorsCount: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 355641] Errors are not deleted when user move from one line to another without modifying data
        Initialize();

        // [GIVEN] journal lines with empty amount: Line1 and Line2
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        // [GIVEN] Mock full batch check
        MockFullBatchCheck(
            GenJournalLine[1]."Journal Template Name",
            GenJournalLine[1]."Journal Batch Name",
            TempErrorMessage);
        TempErrorMessage.Reset();
        ErrorsCount := TempErrorMessage.Count();

        // [WHEN] Run CleanTempErrorMessages 
        SetErrorHandlingParameters(ErrorHandlingParameters, GenJournalLine[1], GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date",
            GenJournalLine[1]."Document No.", GenJournalLine[1]."Posting Date", false, false);
        BackgroundErrorHandlingMgt.CleanTempErrorMessages(TempErrorMessage, ErrorHandlingParameters);

        // [THEN] Errors count left the same
        TempErrorMessage.Reset();
        Assert.AreEqual(ErrorsCount, TempErrorMessage.Count(), 'Errors count must be the same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissedDefaultDimensionErrors()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Dimension: array[2] of Record Dimension;
        TempErrorMessage: Record "Error Message" temporary;
        i: Integer;
    begin
        // [SCENARIO 364840] Several missed default dimensions found in background check
        Initialize();

        // [GIVEN] Create journal line with 2 mandatory default dimensions "DIM1" and "DIM2"
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account",
            CreateGLAccountWithTwoMandatoryDefaultDim(Dimension), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Mock full batch check
        MockFullBatchCheck(
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            TempErrorMessage);

        // [THEN] Errors created for DIM1 and DIM2: "Select a Dimension Value Code for the Dimension Code ..."
        for i := 1 to 2 do begin
            TempErrorMessage.SetFilter("Message", StrSubstNo(DimErr, Dimension[1].Code, GenJournalLine."Account No."));
            Assert.IsTrue(TempErrorMessage.FindFirst(), 'Expected error not found');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        GeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(GeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(GeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        GeneralJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        GeneralJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(GeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(GeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        CashReceiptJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(CashReceiptJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(CashReceiptJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashReceiptJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        CashReceiptJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        CashReceiptJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(CashReceiptJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(CashReceiptJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        FixedAssetGLJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(FixedAssetGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(FixedAssetGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        FixedAssetGLJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        FixedAssetGLJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(FixedAssetGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(FixedAssetGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        ICGeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(ICGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(ICGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ICGeneralJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        ICGeneralJournal.Trap();
        Page.Run(Page::"IC General Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        ICGeneralJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        ICGeneralJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(ICGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(ICGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        JobGLJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(JobGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(JobGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobGLJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        JobGLJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        JobGLJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(JobGLJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(JobGLJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        PaymentJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(PaymentJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(PaymentJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        PaymentJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        PaymentJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(PaymentJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(PaymentJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        PurchaseJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(PurchaseJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(PurchaseJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        PurchaseJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        PurchaseJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(PurchaseJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(PurchaseJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalShowLinesWithErrorsActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Action "Show Lines with Errors" makes action "Show All Lines" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        SalesJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Action "Show Lines with Errors" disabled
        assert.IsFalse(SalesJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        assert.IsTrue(SalesJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesJournalShowAllLinesActionsEnabledState()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO 355641] Action "Show All Lines" makes action "Show Lines with Errors" enabled
        Initialize();

        // [GIVEN] Create journal line for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Open general journal for batch "XXX"
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);
        // [GIVEN] Action "Show Lines with Errors" is selected
        SalesJournal.ShowLinesWithErrors.Invoke();

        // [WHEN] Action "Show All Lines" is being selected
        SalesJournal.ShowAllLines.Invoke();

        // [THEN] Action "Show Lines with Errors" enabled
        assert.IsTrue(SalesJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        assert.IsFalse(SalesJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlCheckLineOnBeforeRunCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempErrorMessage: Record "Error Message" temporary;
        ERMGenJnlErrorHandling: Codeunit "ERM Gen. Jnl. Error Handling";
    begin
        // [SCENARIO 367332] Changes made by event OnBeforeRunCheck has effect on error handling
        Initialize();

        // [GIVEN] Create journal line 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Mark journal line for OnBeforeRunCheck event
        GenJournalLine.Description := OnBeforeRunCheckTxt;
        GenJournalLine.Modify();
        // [GIVEN] Subscribe on OnBeforeRunCheck and set Amount = 0 (see OnBeforeRunCheck sibscriber)
        BindSubscription(ERMGenJnlErrorHandling);

        // [WHEN] Mock run codeunit "Gen. Jnl.-Check Line" with LogErrorMode=True
        MockGenJnlCheckLineRunWithErrorBehaviorCollect(GenJournalLine, TempErrorMessage);

        // [THEN] Error message "Amount must have a value"
        TempErrorMessage.TestField("Context Record ID", GenJournalLine.RecordId());
        VerifyErrorMessageText(
            TempErrorMessage."Message",
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine.FieldCaption(Amount)));

        UnBindSubscription(ERMGenJnlErrorHandling);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetDeletedDocumentsFromArgsUT()
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        TempResultGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        Args: Dictionary of [Text, Text];
        i: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 367332] Unit test for function GetDeletedDocumentsFromArgs
        Initialize();

        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        // [GIVEN] Mock 3 jounrnal document lines with different "Document No." and "Posing Date" deleted
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do
            MockDummyJournalDocumentLineDeleted(GenJournalBatch, TempGenJnlLine);

        // [GIVEN] Pack buffer to Args
        BackgroundErrorHandlingMgt.PackDeletedDocumentsToArgs(Args);

        // [WHEN] Function GetDeletedDocumentsFromArgs is being run
        BackgroundErrorHandlingMgt.GetDeletedDocumentsFromArgs(Args, TempResultGenJnlLine);

        // [THEN] Buffer contains all 3 documents
        Assert.AreEqual(TempGenJnlLine.Count, TempResultGenJnlLine.Count, 'Number of buffer records must be the same');
        TempGenJnlLine.FindSet();
        TempResultGenJnlLine.FindSet();
        repeat
            TempResultGenJnlLine.TestField("Document No.", TempGenJnlLine."Document No.");
            TempResultGenJnlLine.TestField("Posting Date", TempGenJnlLine."Posting Date");

            TempResultGenJnlLine.Next();
        until TempGenJnlLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetRecXRecOnModifyRunTwice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 385781] No error in case of subsequent call of SetRecXRecOnModify for same general journal record
        Initialize();

        // [GIVEN] Prepare Rec and xRec parameters for SetRecXRecOnModify
        CreateGenJournalLine(xGenJournalLine);
        GenJournalLine := xGenJournalLine;
        GenJournalLine.Description := OnBeforeRunCheckTxt;
        GenJournalLine.Modify();

        // [GIVEN] Run SetRecXRecOnModify
        JournalErrorsMgt.SetRecXRecOnModify(GenJournalLine, xGenJournalLine);
        // [WHEN] Run SetRecXRecOnModify with same parameters second time
        JournalErrorsMgt.SetRecXRecOnModify(GenJournalLine, xGenJournalLine);

        // [THEN] No error "Gen. Journal Line already exists"
        Assert.IsTrue(JournalErrorsMgt.GetRecXRecOnModify(GenJournalLine, xGenJournalLine), 'GetRecXRecOnModify failed');
    end;

    [Test]
    procedure ForceDocBalance_False()
    var
        GeneralJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 389104] No error should appear when "Force Doc. Balance" = false and lines are balanced only by Date
        Initialize();

        // [GIVEN] General Journal Template, where "Force Doc. Balance" is false
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", false);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GeneralJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] General Journal Line GJL1: Document Type = "", Document No. := 01, Posting Date = WorkDate(), Amount = 10
        // [GIVEN] General Journal Line GJL2: Document Type = "", Document No. := 02, Posting Date = WorkDate(), Amount = -10
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1], GeneralJournalBatch."Journal Template Name", GeneralJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandInt(10));
        LibraryERM.CreateGeneralJnlLine(
           GenJournalLine[2], GeneralJournalBatch."Journal Template Name", GeneralJournalBatch.Name,
           "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), -GenJournalLine[1].Amount);

        // [WHEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine[2]);

        // [THEN] "Lines with Issues" = 0
        GeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowLinesWithErrorsDimError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 397303] Action "Show Lines with Errors" shows lines with dimension related errors
        Initialize();

        // [GIVEN] Create journal line with G/L Account "A" for new batch "XXX" 
        CreateGenJournalLine(GenJournalLine);

        // [GIVEN] Create mandatory dimension value for account "A"
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GenJournalLine."Account No.", DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension."Value Posting" := "Default Dimension Value Posting Type"::"Code Mandatory";
        DefaultDimension.Modify();

        // [GIVEN] Open general journal for batch "XXX"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);

        // [WHEN] Action "Show Lines with Errors" is being selected
        GeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] Journal line with Account "A" is shown on the page
        GeneralJournal."Account No.".AssertEquals(GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure GeneralJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on General Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open General Journal page
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        GeneralJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure GeneralJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on General Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open General Journal page
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        GeneralJournal.PostAndPrint.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure CashReceiptJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Cash Receipt Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Cash Receipt Journal page
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        CashReceiptJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure CashReceiptJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Cash Receipt Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Cash Receipt Journal page
        CashReceiptJournal.Trap();
        Page.Run(Page::"Cash Receipt Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        CashReceiptJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure FixedAssetGLJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Fixed Asset G/L Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Fixed Asset G/L Journal page
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        FixedAssetGLJournal."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure FixedAssetGLJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Fixed Asset G/L Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Fixed Asset G/L Journal page
        FixedAssetGLJournal.Trap();
        Page.Run(Page::"Fixed Asset G/L Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        FixedAssetGLJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure JobGLJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Job G/L Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Job G/L Journal page
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        JobGLJournal."P&ost".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure JobGLJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Job G/L Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Job G/L Journal page
        JobGLJournal.Trap();
        Page.Run(Page::"Job G/L Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        JobGLJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PaymentJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Payment Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Payment Journal page
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        PaymentJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PaymentJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Payment Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Payment Journal page
        PaymentJournal.Trap();
        Page.Run(Page::"Payment Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        PaymentJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PurchaseJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Purchase Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Purchase Journal page
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        PurchaseJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PurchaseJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Purchase Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Purchase Journal page
        PurchaseJournal.Trap();
        Page.Run(Page::"Purchase Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        PurchaseJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure SalesJournalCatchErrorPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on Sales Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Sales Journal page
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        SalesJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure SalesJournalCatchErrorPostPrint()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post and Print on Sales Journal page for customer with empty Receivable Account of customer posting group opens Error Messages page
        Initialize();

        // [GIVEN] Gen. journal line for Customer with empty Receivables Account of customer posting group
        CreateCustomerEmptyRecAccGenJournalLine(GenJournalLine);

        // [GIVEN] Open Sales Journal page
        SalesJournal.Trap();
        Page.Run(Page::"Sales Journal", GenJournalLine);
        ErrorMessages.Trap();

        // [WHEN] Action Post and Print is being selected
        SalesJournal."Post and &Print".Invoke();

        // [THEN] Error Messages page opened with error "Receivables Account is missing ..."
        VerifyRecievablesAccountError(ErrorMessages.Description.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure GeneralJournalCatchCheckPostError()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UI] [Post] [Order]
        // [SCENARIO 395037] Action Post on General Journal page opens Error Messages page for errors from "Gen. Jnl. Check Line" codeunit
        Initialize();

        // [GIVEN] Create general journal template "T" and batch "B"
        CreateGenJournalTemplateBatch(GenJournalBatch, "Gen. Journal Template Type"::General, Page::"General Journal");
        // [GIVEN] Create journal line 1 with no errors
        CrateJournalLineWithBalanceAccount(GenJournalBatch, GenJournalLine[1]);

        // [GIVEN] Create journal line 2 with empty "Document No."
        CrateJournalLineWithBalanceAccount(GenJournalBatch, GenJournalLine[2]);
        GenJournalLine[2]."Document No." := '';
        GenJournalLine[2].Modify();

        // [GIVEN] Create journal line 3 with no errors
        CrateJournalLineWithBalanceAccount(GenJournalBatch, GenJournalLine[3]);

        // [GIVEN] Open General Journal for template "T" and batch "B"
        GeneralJournal.Trap();
        Page.Run(Page::"General Journal", GenJournalLine[1]);
        ErrorMessages.Trap();

        // [WHEN] Action Post is being selected
        GeneralJournal.Post.Invoke();

        // [THEN] Error Messages page opened with error "Document No. must have a value" and context of gen. journal line 2
        Assert.ExpectedMessage(
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine[2].FieldCaption("Document No.")),
            ErrorMessages.Description.Value);
        Assert.AreEqual(Format(GenJournalLine[2].RecordId), ErrorMessages.Context.Value, 'Invalid context');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGeneralJournalErrorUpdateOnAmount()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DummyGeneralJournal: TestPage "General Journal";
        Error1: Text;
        Error2: Text;
    begin
        // [SCENARIO 443559] General Journal page should not show message for blank amount if amount is populated.
        Initialize();

        //[GIVEN] Create Customer,Journal batch and General Journal Line without Bal.Account No.
        LibrarySales.CreateCustomer(Customer);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        Commit();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable Data Check", true);
        GeneralLedgerSetup.Modify(true);

        //[WHEN] Creating General Journal and amount is non blank
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account",
            '',
            LibraryRandom.RandDecInRange(1000, 2000, 0));

        DummyGeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        Error1 := DummyGeneralJournal.JournalErrorsFactBox.Error1.Value();
        Error2 := StrSubstNo(
            DocumentOutOfBalanceErr,
            GenJournalLine."Document No.",
            GenJournalLine.GetDocumentBalance(GenJournalLine));

        //[THEN] Error for Amount blank should be gone.
        Assert.AreEqual(Error2, Error1, StrSubstNo(ExpectedErrorTxt, Error2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlNumberOfErrorsSunshine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Journal Check factbox shows correct number of lines checked, zero lines with issues and total issues 
        Initialize();

        // [GIVEN] Recurring Gen. Journal has 2 balanced lines for document A1 with "F Fixed" recurring method with no errors
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Lines Checked = 2, Lines with issues = 0, Issues total = 0
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(2);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(0);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlNumberOfErrorsWithErrors()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Journal Check factbox shows correct number of lines checked, lines with issues and total issues 
        Initialize();

        // [GIVEN] Recurring Gen. Journal has 2 balanced lines where second line does not have Account No. filled in.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", '', -GenJournalLine.Amount);

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Lines Checked = 2, Lines with issues = 1, Issues total = 1
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(2);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(1);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(1);
        // [THEN] Error message is "Account No. must have a value" in the factbox
        RecurringGeneralJournal.Last();
        Assert.ExpectedMessage(
            StrSubstNo(TestFieldMustHaveValueErr, GenJournalLine."Account No."), RecurringGeneralJournal.JournalErrorsFactBox.Error1.Value());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlNumberOfDocumentOutOfBalanceErrors()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Recurring multiple lines give one common error for out of balance document 
        Initialize();

        // [GIVEN] Recurring Gen. Journal has 1st document out of balance and 2nd document balanced.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", DocumentNo, LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", DocumentNo, LibraryERM.CreateGLAccountNo(), GenJournalLine.Amount);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Lines Checked = 4, Lines with issues = 2, Issues total = 1 (one common error for out of balance document)
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(4);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(2);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(1);
        // [THEN] Error message is about first document is out of balance is shown for first and second line        
        RecurringGeneralJournal.First();
        RecurringGeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(RecurringDocIsOutOfBalanceFilterTxt, DocumentNo));
        RecurringGeneralJournal.Next();
        RecurringGeneralJournal.JournalErrorsFactBox.Error1.AssertEquals(StrSubstNo(RecurringDocIsOutOfBalanceFilterTxt, DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlCurrentLineTwoErrors()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] One recurring line out of allowed posting dates generates 2 errors
        Initialize();

        // [GIVEN] Set allowed posting dates in General Ledger Setup
        LibraryERM.SetAllowPostingFromTo(CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [GIVEN] Recurring Gen. Journal has one line with Posting date less that Allowed Posting From date
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        UpdateRecGenJnlLineWithPostingDateAndExpirationDate(GenJournalLine, CalcDate('<-1M>', WorkDate()), CalcDate('<-1M>', WorkDate()));
        Commit();

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Lines Checked = 1, Lines with issues = 1, Issues total = 2        
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesChecked.AssertEquals(1);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfLinesWithErrors.AssertEquals(1);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(2);

        // [THEN] Error messages are about not allowed posting date and out of balance document 
        RecurringGeneralJournal.First();
        Assert.ExpectedMessage(NotAllowedPostingDateErr, RecurringGeneralJournal.JournalErrorsFactBox.Error1.Value);
        RecurringGeneralJournal.JournalErrorsFactBox.Error2.AssertEquals(StrSubstNo(RecurringDocIsOutOfBalanceFilterTxt, GenJournalLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlWorkingDateCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Recurring lines ignored during posting with posting date more than working date generate error messages on Error Message page
        Initialize();

        // [GIVEN] Balanced document with the posting date more than working date   
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        UpdateRecGenJnlLineWithPostingDateAndExpirationDate(GenJournalLine, WorkDate() + 1, WorkDate() + 1);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);
        UpdateRecGenJnlLineWithPostingDateAndExpirationDate(GenJournalLine, WorkDate() + 1, WorkDate() + 1);

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Issues total = 2
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(2);
        // [THEN] Error messages are shown respectively for each line about posting date more than working date
        ErrorMessages.Trap();
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.Drilldown();
        ErrorMessages.First();
        ErrorMessages.Description.AssertEquals(StrSubstNo(RecurringLineIsOutOfWorkdateErr, GenJournalLine."Posting Date", WorkDate(), GenJournalLine."Document No."));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(StrSubstNo(RecurringLineIsOutOfWorkdateErr, GenJournalLine."Posting Date", WorkDate(), GenJournalLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlExpirationDateCheck()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Recurring lines ignored during posting with posting date more than expiration date generate error messages on Error Message page
        Initialize();

        // [GIVEN] Balanced document with expired posting date
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        UpdateRecGenJnlLineWithPostingDateAndExpirationDate(GenJournalLine, WorkDate(), WorkDate() - 1);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);
        UpdateRecGenJnlLineWithPostingDateAndExpirationDate(GenJournalLine, WorkDate(), WorkDate() - 1);

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] Issues total = 2
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(2);
        // [THEN] Error messages are shown respectively for each line about expired posting date
        ErrorMessages.Trap();
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.Drilldown();
        ErrorMessages.First();
        ErrorMessages.Description.AssertEquals(StrSubstNo(RecurringLineIsExpiredErr, GenJournalLine."Posting Date", GenJournalLine."Expiration Date", GenJournalLine."Document No."));
        ErrorMessages.Next();
        ErrorMessages.Description.AssertEquals(StrSubstNo(RecurringLineIsExpiredErr, GenJournalLine."Posting Date", GenJournalLine."Expiration Date", GenJournalLine."Document No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlShowLinesActions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Background check related actions are visible on the recurring general journal page
        Initialize();

        // [GIVEN] Recurring Journal with one line
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] 'Show lines' action items are visible
        Assert.IsTrue(RecurringGeneralJournal.ShowLinesWithErrors.Visible(), 'ShowLinesWithErrors must be visible');
        Assert.IsTrue(RecurringGeneralJournal.ShowAllLines.Visible(), 'ShowAllLines must be visible');
        // [THEN] Action "Show Lines with Errors" enabled
        Assert.IsTrue(RecurringGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be enabled');
        // [THEN] Action "Show All Lines" disabled
        Assert.IsFalse(RecurringGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be disabled');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGenJnlShowLinesWithErrorsAction()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Recurring General Journal]
        // [SCENARIO 490333] Background check related contols are visible on the recurring general journal page
        Initialize();

        // [GIVEN] Recurring Journal with one balanced document and one more line 
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document No.", LibraryERM.CreateGLAccountNo(), -GenJournalLine.Amount);
        CreateRecurringGenJnlLineWithDocumentNo(
            GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(), LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Open recurring general journal for the batch
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", GenJournalLine);
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        RecurringGeneralJournal.JournalErrorsFactBox.NumberOfBatchErrors.AssertEquals(1);
        // [WHEN] Action "Show Lines with Errors" is selected
        RecurringGeneralJournal.ShowLinesWithErrors.Invoke();

        // [THEN] One line with error is shown in the journal
        RecurringGeneralJournal.Last();
        Assert.IsFalse(RecurringGeneralJournal.Previous(), 'There must be only one line with error shown in the journal'); // Next() generates new line after the last one

        // [THEN] 'Show lines' action items are visible
        Assert.IsTrue(RecurringGeneralJournal.ShowLinesWithErrors.Visible(), 'ShowLinesWithErrors must be visible');
        Assert.IsTrue(RecurringGeneralJournal.ShowAllLines.Visible(), 'ShowAllLines must be visible');
        // [THEN] Action "Show Lines with Errors" disabled
        Assert.IsFalse(RecurringGeneralJournal.ShowLinesWithErrors.Enabled(), 'Action ShowLinesWithErrors must be disabled');
        // [THEN] Action "Show All Lines" enabled
        Assert.IsTrue(RecurringGeneralJournal.ShowAllLines.Enabled(), 'Action ShowAllLines must be enabled');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        Commit(); // need to notify background sessions about data restore
        if IsInitialized then
            exit;

        SetEnableDataCheck(true);
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
    end;

    local procedure SetEnableDataCheck(Enabled: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable Data Check", Enabled);
        GLSetup.Modify();
    end;

    local procedure ClearAmountAndDocumentNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate(Amount, 0);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    local procedure MockDummyJournalDocumentLineDeleted(GenJournalBatch: Record "Gen. Journal Batch"; var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
    begin
        if TempGenJnlLine.FindLast() then;
        TempGenJnlLine."Line No." := TempGenJnlLine."Line No." + 1;
        TempGenJnlLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        TempGenJnlLine."Journal Batch Name" := GenJournalBatch.Name;
        TempGenJnlLine."Posting Date" := LibraryRandom.RandDate(100);
        TempGenJnlLine."Document No." := LibraryRandom.RandText(MaxStrLen(TempGenJnlLine."Document No."));
        TempGenJnlLine.Insert();

        JournalErrorsMgt.InsertDeletedLine(TempGenJnlLine);
    end;

    local procedure CreateGLAccountWithTwoMandatoryDefaultDim(var Dimension: array[2] of Record Dimension) GLAccountNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        for i := 1 to 2 do begin
            LibraryDimension.CreateDimension(Dimension[i]);
            LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, Dimension[i].Code, '');
            DefaultDimension."Value Posting" := DefaultDimension."Value Posting"::"Code Mandatory";
            DefaultDimension.Modify();
        end;
    end;

    local procedure CreateMultiLineGenJnlDocOutOfBalance(var GenJournalLine: Record "Gen. Journal Line"; var TotalBalance: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
    end;

    local procedure CreateMultiLineGenJnlDocZeroBalance(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        TotalBalance: Decimal;
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', -TotalBalance);
    end;

    local procedure CreateMultiLineGenJnlDocZeroBalance(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    var
        TotalBalance: Decimal;
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do begin
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            TotalBalance += GenJournalLine.Amount;
        end;
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', -TotalBalance);

        GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
    end;

    local procedure CreateZeroAmountJournalLines(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);

        for i := 1 to LibraryRandom.RandIntInRange(5, 10) do
            LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
              GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
              LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', 0);
    end;

    local procedure CrateJournalLineWithBalanceAccount(GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateEmptyDocGenJournalLineForTemplate(var GenJournalLine: Record "Gen. Journal Line"; TemplateType: Enum "Gen. Journal Template Type"; PageId: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalBatch, TemplateType, PageId);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        CreateGenJournalLines(GenJournalLine, 1);
    end;

    local procedure CreateGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; NumbefOfLines: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify();

        for i := 1 to NumbefOfLines do
            LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
                "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateGenJournalLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        GenJournalLine."Document No." := DocumentNo;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type"; PageID: Integer)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, TemplateType);
        GenJournalTemplate.Get(GenJournalBatch."Journal Template Name");
        GenJournalTemplate.Validate("Page ID", PageID);
        GenJournalTemplate.Modify();
    end;

    local procedure CreateCustomerWithEmptyReceivableAccount(var Customer: Record Customer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Receivables Account" := '';
        CustomerPostingGroup.Modify();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);
        Commit();
    end;

    local procedure CreateCustomerEmptyRecAccGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
    begin
        CreateCustomerWithEmptyReceivableAccount(Customer);
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Modify();

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            "Gen. Journal Document Type"::" ", "Gen. Journal Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2));
        Commit();
    end;

    local procedure CreateRecurringGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        GenJournalTemplate."Force Doc. Balance" := true;
        GenJournalTemplate.Modify();
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateRecurringGenJnlLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        RecurringFrequency: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate(Description, LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(10)) + 'M >');
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateRecGenJnlLineWithPostingDateAndExpirationDate(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; ExpirationDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Expiration Date", ExpirationDate);
        GenJournalLine.Modify(true);
    end;

    local procedure GetNumberOfLines(var GenJournalLine: Record "Gen. Journal Line"): Integer
    begin
        SetBatchFilter(GenJournalLine);
        exit(GenJournalLine.Count());
    end;

    local procedure MockLineModified(xGenJournalLine: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        Params: Dictionary of [Text, Text];
    begin
        ClearTempErrorMessage(TempErrorMessage);
        SetErrorHandlingParameters(ErrorHandlingParameters,
            GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
            GenJournalLine."Document No.", GenJournalLine."Posting Date",
            xGenJournalLine."Document No.", xGenJournalLine."Posting Date", false, true);
        ErrorHandlingParameters.ToArgs(Params);

        JournalErrorsMgt.SetRecXRecOnModify(xGenJournalLine, GenJournalLine);
        Commit();
        CheckGenJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure MockFullBatchCheck(TemplateName: Code[10]; BatchName: Code[10]; var TempErrorMessage: Record "Error Message" temporary)
    var
        ErrorHandlingParameters: Record "Error Handling Parameters";
        CheckGenJnlLineBackgr: Codeunit "Check Gen. Jnl. Line. Backgr.";
        Params: Dictionary of [Text, Text];
    begin
        ClearTempErrorMessage(TempErrorMessage);

        SetErrorHandlingParameters(ErrorHandlingParameters, TemplateName, BatchName, '', 0D, '', 0D, true, false);
        ErrorHandlingParameters.ToArgs(Params);
        Commit();
        CheckGenJnlLineBackgr.RunCheck(Params, TempErrorMessage);
    end;

    local procedure MockGenJnlCheckLineRun(var GenJournalLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        GenJnlCheckLine.SetLogErrorMode(true);
        GenJnlCheckLine.Run(GenJournalLine);
        GenJnlCheckLine.GetErrors(TempErrorMessage);
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure MockGenJnlCheckLineRunWithErrorBehaviorCollect(var GenJournalLine: Record "Gen. Journal Line"; var TempErrorMessage: Record "Error Message" temporary)
    var
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        GenJnlCheckLine.Run(GenJournalLine);
        ErrorMessageMgt.CollectErrors(TempErrorMessage);
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; TemplateName: Code[10]; BatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date; xDocumentNo: Code[20]; xPostingDate: Date; FullBatchCheck: Boolean; LineModified: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := TemplateName;
        ErrorHandlingParameters."Journal Batch Name" := BatchName;
        ErrorHandlingParameters."Document No." := DocumentNo;
        ErrorHandlingParameters."Posting Date" := PostingDate;
        ErrorHandlingParameters."Previous Document No." := xDocumentNo;
        ErrorHandlingParameters."Previous Posting Date" := xPostingDate;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Line Modified" := LineModified;
    end;

    local procedure ClearTempErrorMessage(var TempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Reset();
        TempErrorMessage.DeleteAll();
    end;

    local procedure SetBatchFilter(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
    end;

    local procedure SetErrorHandlingParameters(var ErrorHandlingParameters: Record "Error Handling Parameters"; GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PostingDate: Date; xDocumentNo: Code[20]; xPostingDate: Date; FullBatchCheck: Boolean; LineModified: Boolean)
    begin
        ErrorHandlingParameters.Init();
        ErrorHandlingParameters."Journal Template Name" := GenJournalLine."Journal Template Name";
        ErrorHandlingParameters."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        ErrorHandlingParameters."Document No." := DocumentNo;
        ErrorHandlingParameters."Posting Date" := PostingDate;
        ErrorHandlingParameters."Previous Document No." := xDocumentNo;
        ErrorHandlingParameters."Previous Posting Date" := xPostingDate;
        ErrorHandlingParameters."Full Batch Check" := FullBatchCheck;
        ErrorHandlingParameters."Line Modified" := LineModified;
    end;

    local procedure VerifyRecievablesAccountError(Description: Text)
    var
        DummyCustomerPostingGroup: Record "Customer Posting Group";
    begin
        Assert.ExpectedMessage(DummyCustomerPostingGroup.FieldCaption("Receivables Account"), Description);
    end;

    local procedure VerifyErrorMessageText(ActualText: Text; ExpectedText: Text)
    begin
        Assert.IsSubstring(ActualText, ExpectedText);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLineExtendingGenJnlCheckLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        if GenJournalLine.Description = ExtendingGenJnlCheckLineTxt then
            ErrorMessageMgt.LogError(GenJournalLine, DummyErr, '');
        if GenJournalLine.Description = ExtendingGenJnlCheckLineNewTxt then
            Error(ErrorInfo.Create(DummyErr, true, GenJournalLine));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLineLogTestFieldOption(var GenJournalLine: Record "Gen. Journal Line")
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        RecRef: RecordRef;
    begin
        if GenJournalLine.Description = LogTestFieldOptionTxt then begin
            GenJournalLine."IC Direction" := GenJournalLine."IC Direction"::Incoming;
            RecRef.GetTable(GenJournalLine);
            ErrorMessageMgt.LogTestField(RecRef, GenJournalLine.FieldNo("IC Direction"), GenJournalLine."IC Direction"::Outgoing);
        end;
        if GenJournalLine.Description = LogTestFieldOptionNewTxt then begin
            GenJournalLine."IC Direction" := GenJournalLine."IC Direction"::Incoming;
            GenJournalLine.TestField("IC Direction", GenJournalLine."IC Direction"::Outgoing, ErrorInfo.Create());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnBeforeRunCheck', '', false, false)]
    local procedure OnBeforeRunCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine.Description = OnBeforeRunCheckTxt then
            GenJournalLine.Validate(Amount, 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
