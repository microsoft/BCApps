codeunit 134227 "ERM PostRecurringJournal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Recurring Journal]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OneDocSameNoErr: Label 'There must be one   invoice, credit memo, or finance charge memo with the same Document No.';
        GenJnlDocType: Enum "Gen. Journal Document Type";
        GenJnlAccountType: Enum "Gen. Journal Account Type";
        GenJnlRecurringMethod: Enum "Gen. Journal Recurring Method";
        IsInitialized: Boolean;
        IncorrectPostingPreviewErr: Label 'Incorrect number of entries in posting preview.';
        NoOfLinesErr: Label 'Incorrect number of lines found in GL Entry.';
        DocumentDateErr: Label '%1 must be equal to %2 in %3.', Comment = '%1 = Document Date Field Caption,%2 = Posting Date Field Caption,%3 = GL Entry Table Caption';
        SuccessPostingMsg: Label 'The journal lines were successfully posted.';
        SkippedLineMsg: Label 'One or more lines has not been posted because the amount is zero.';
        DocumentOutOfBalanceErr: Label 'Document No. %1 is out of balance', Locked = true;
        AllocAccountImportWrongAccTypeErr: Label 'Import from Allocation Account is only allowed for G/L Account Destination account type.', Locked = true;
        AllocationDimensionErr: Label 'Allocation dimension is not correct';
        PostingDateErr: Label '%1 is not within your range of allowed posting dates in Gen. Journal Line Journal Template Name=''%2'',Journal Batch Name=''%3'',Line No.=''%4''.', Comment = '%1= Field Name, %2= Field Value, %3= Field Value, %4= Field Value.';

    [Test]
    [Scope('OnPrem')]
    procedure TestPostRecurringJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringFrequency: array[6] of DateFormula;
        NoOfLines: Integer;
    begin
        // Check No. of lines in G/L Entry after posting Recurring Journal with allocation.

        // Setup: Create Recurring Journal Lines.
        NoOfLines := CreateRecurringJournalLine(GenJournalLine, RecurringFrequency);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify the number of lines generated in GL Entry table after posting.
        VerifyNoOfLineInGLEntry(GenJournalLine."Journal Batch Name", 2 * NoOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnRecurringJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringFrequency: array[6] of DateFormula;
        PostingDate: array[6] of Date;
        NoOfLines: Integer;
        Counter: Integer;
        Loop: Integer;
    begin
        // Check posting Date on Recurring Journal Lines after posting.

        // Setup: Create Recurring Journal Lines.
        NoOfLines := CreateRecurringJournalLine(GenJournalLine, RecurringFrequency);
        for Counter := 1 to NoOfLines do
            PostingDate[Counter] := CalcDate(RecurringFrequency[Counter], GenJournalLine."Posting Date");

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Posting Date on Recurring Journal Lines.
        FindGeneralJournalLine(GenJournalLine);
        repeat
            Loop += 1;
            GenJournalLine.TestField("Posting Date", PostingDate[Loop]);
        until (GenJournalLine.Next() = 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringJournalWithExpirDateLessPostDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Expiration Date]
        // [SCENARIO 363410] Recurring journal line with "Expiration Date" less than Posting Date should be posted on "Posting Date"

        // [GIVEN] Recurring Journal Line
        CreateRecurringGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed",
          LibraryRandom.RandDec(100, 2), GLAccount."No.");

        // [GIVEN] "Posting Date" = "X", "X" < "Expiration Date"
        GenJournalLine.Validate("Expiration Date", LibraryRandom.RandDate(-10));
        GenJournalLine.Validate(
          "Posting Date", GenJournalLine."Expiration Date" - LibraryRandom.RandInt(10));
        GenJournalLine.Modify(true);
        // [GIVEN] Allocation Line for Recurring Journal Line
        CreateAllocationLine(GenJournalLine);

        // [WHEN] Post recurring journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] 2 G/L Entries are created
        VerifyNoOfLineInGLEntry(GenJournalLine."Journal Batch Name", 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringJournalWithExpirDateMorePostDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Expiration Date]
        // [SCENARIO 363410] Recurring journal line with "Expiration Date" more than Posting Date should not be posted to G/L

        // [GIVEN] Recurring Journal Line
        CreateRecurringGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed",
          LibraryRandom.RandDec(100, 2), GLAccount."No.");

        // [GIVEN] "Posting Date" = "X", "X" > "Expiration Date"
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(10));
        GenJournalLine.Validate(
          "Expiration Date", GenJournalLine."Posting Date" - LibraryRandom.RandInt(10));
        GenJournalLine.Modify(true);
        // [GIVEN] Allocation Line for Recurring Journal Line
        CreateAllocationLine(GenJournalLine);

        // [WHEN] Post recurring journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] No G/L Entries are created
        VerifyNoOfLineInGLEntry(GenJournalLine."Journal Batch Name", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleRecurringJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check the posting of Recurring General Journal with Multiple line with same Document No. is possible and also check No. of lines in G/L Entry after posting.

        // Exercise: Create multiple Recurring Journal Lines with same Document No. and with random values.
        CreateAndPostGeneralJournalLineWithRecurringMethod(GenJournalLine, GenJournalLine."Recurring Method"::"F  Fixed");

        // Verify: Verify the number of lines generated in GL Entry table after posting.
        VerifyNoOfLineInGLEntry(GenJournalLine."Journal Batch Name", GenJournalLine.Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateAfterPostingRecurringJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check the Document Date on G/L Entry after Posting Recurring General Journal with Recurring Method "RF Reversing Fixed" and Multiple lines.

        // Exercise: Create multiple Recurring Journal Lines with same Document No. and with random values.
        CreateAndPostGeneralJournalLineWithRecurringMethod(GenJournalLine, GenJournalLine."Recurring Method"::"RF Reversing Fixed");

        // Verify: Verify Document Date on number of lines generated in GL Entry table after posting.
        VerifyDocumentDateOnGLEntry(GenJournalLine."Journal Batch Name", GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleRecurringJournalExpiredLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[3] of Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Expiration Date]
        // [SCENARIO 375144] Recurring Journal skip lines while posting if they are expired.

        // [GIVEN] General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Recurring Journal with 3 lines: "Posting Date" is more, less and equal to "Expiration Date"
        PostingDate := LibraryRandom.RandDate(-10);
        DocumentNo[1] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, PostingDate, PostingDate);
        DocumentNo[2] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, PostingDate, PostingDate - 1);
        DocumentNo[3] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, PostingDate - 1, PostingDate + 1);

        // [WHEN] Post recurring journal.
        CreateAllocationLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only G/L Entries for line 1 and line 3 are created.
        VerifyGLEntriesWithExpiredDate(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure PostRecurringJnlWithFiltering()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 377115] If not all lines of Recurring General Journal's Batch are shown after applying a filter, then in case of posting, only shown entries must be posted

        DocumentNo := LibraryUtility.GenerateGUID();
        FindGLAccount(GLAccount);
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();

        // Remove existing lines
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine.Delete(true);
            until GenJournalLine.Next() = 0;
        GenJournalLine.Reset();

        // [GIVEN] The 1st Line of Batch having "Amount" = 100 and G/L Account
        Amount := LibraryRandom.RandDec(100, 2);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", Amount, GLAccount."No.", DocumentNo);

        // [GIVEN] The 2nd Line of Batch having "Amount" = -100 and G/L Account
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", -Amount, GLAccount."No.", DocumentNo);

        // [GIVEN] The 3rd Line of Batch having "Amount" = 0 and G/L Account
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", 0, GLAccount."No.", DocumentNo);

        // [GIVEN] "Amount <> 0" filter applied to Journal
        Commit();
        RecurringGeneralJournal.OpenEdit();
        RecurringGeneralJournal.FILTER.SetFilter(Amount, '<>0');

        // [WHEN] Posting Batch
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] The 1st and the 2nd lines were successfully posted
        // Checked in Message Handler
        RecurringGeneralJournal.Close();

        // [THEN] Posting Date is changed in posted entries only
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();

        repeat
            if GenJournalLine.Amount = 0 then
                Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", '')
            else
                Assert.AreEqual(
                  CalcDate(GenJournalLine."Recurring Frequency", WorkDate()),
                  GenJournalLine."Posting Date", '');
        until GenJournalLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewRecurringJnlWithFiltering()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
        GLPostingPreview: TestPage "G/L Posting Preview";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Preview Posting]
        // [SCENARIO 377115] If not all lines of Recurring General Journal's Batch are shown after applying a filter, then in case of posting, only shown entries must be posted

        DocumentNo := LibraryUtility.GenerateGUID();
        FindGLAccount(GLAccount);
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();

        // Remove existing lines
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if GenJournalLine.FindSet() then
            repeat
                GenJournalLine.Delete(true);
            until GenJournalLine.Next() = 0;
        GenJournalLine.Reset();

        // [GIVEN] The 1st Line of Batch having "Amount" = 100 and G/L Account
        Amount := LibraryRandom.RandDec(100, 2);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", Amount, GLAccount."No.", DocumentNo);

        // [GIVEN] The 2nd Line of Batch having "Amount" = -100 and G/L Account
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", -Amount, GLAccount."No.", DocumentNo);

        // [GIVEN] The 3rd Line of Batch having "Amount" = 0 and G/L Account
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", 0, GLAccount."No.", DocumentNo);

        // [GIVEN] "Amount <> 0" filter applied to Journal
        RecurringGeneralJournal.OpenEdit();
        RecurringGeneralJournal.FILTER.SetFilter(Amount, '<>0');

        // [WHEN] Preview Posting Batch
        Commit();
        GLPostingPreview.Trap();
        RecurringGeneralJournal.Preview.Invoke();

        // [THEN] Posting Preview is shown
        Assert.AreEqual(2, GLPostingPreview."No. of Records".AsInteger(), IncorrectPostingPreviewErr);

        asserterror Error(''); // Rollback previewing inconsistencies
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostRecurringJournalFromMultipleBatches()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        // [SCENARIO 377795] Recurring journal Lines should be posted from multiple Recurring General Journal Batches

        // [GIVEN] Recurring General Journal Template
        // [GIVEN] Recurring General Journal Line with "Posting Date" = "X"
        CreateRecurringTemplateWithoutForceDocBalance(GenJnlTemplate);
        for i := 1 to 2 do begin
            LibraryERM.CreateRecurringBatchName(GenJnlBatch, GenJnlTemplate.Name);
            GenJnlBatch.SetRecFilter();
            CreateBalancedRecurringJnlLines(GenJnlLine, GenJnlBatch);
        end;
        Commit();
        GenJnlBatch.SetRange(Name);

        // [WHEN] Pos Recurring General Journal Line from Recurring General Journal Batch
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-B.Post", GenJnlBatch);

        // [THEN] G/L Entry is created with "Posting Date" = "X"
        GenJnlBatch.FindSet();
        for i := 1 to 2 do begin
            VerifyGLEntryExists(GenJnlBatch.Name, WorkDate());
            GenJnlBatch.Next();
        end;
    end;

    [Test]
    [HandlerFunctions('GenJnlTemplateModalPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostRecurringJournalFromBlankLine()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 379482] Recurring journal line is posted if focus is set on blank line in the same batch

        // [GIVEN] Recurring General Journal Line
        CreateRecurringTemplateWithoutForceDocBalance(GenJnlTemplate);
        LibraryERM.CreateRecurringBatchName(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.SetRecFilter();
        CreateBalancedRecurringJnlLines(GenJnlLine, GenJnlBatch);
        Commit();
        LibraryVariableStorage.Enqueue(GenJnlBatch."Journal Template Name");

        // [GIVEN] Recurring Journal is opened and focus set on blank line
        RecurringGeneralJournal.OpenEdit();
        RecurringGeneralJournal.CurrentJnlBatchName.SetValue(GenJnlBatch.Name);
        RecurringGeneralJournal.Last();
        RecurringGeneralJournal.Next();

        // [WHEN] Press "Post" on Recurring Journal page
        RecurringGeneralJournal.Post.Invoke();

        // [THEN] G/L Entry is created
        VerifyGLEntryExists(GenJnlBatch.Name, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ZeroAmountLinePostingSkipMessageHandler')]
    [Scope('OnPrem')]
    procedure PostRecurringJournalWithZeroAmountLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccountA: Record "G/L Account";
        GLAccountB: Record "G/L Account";
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO 381263] It is possible to post recurring journal having zero amounts in lines, but lines with zero amounts are skipped
        // [GIVEN] "G/L Account" "GL-A" with balance 100
        // [GIVEN] "G/L Account" "GL-B" with balance 0
        // [GIVEN] Recurring Journal Line[1] where "Account No." = "GL-A", Amount = 0, "Reccuring Method" = "B  Balance", "Recurring Frequency" = 1M, "Posting Date" = 01/01/2017
        // [GIVEN] Recurring Journal Line[2] where "Account No." = "GL-B", Amount = 0, "Reccuring Method" = "B  Balance", "Recurring Frequency" = 1M, "Posting Date" = 01/01/2017
        LibraryERM.CreateGLAccount(GLAccountA);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccountA."No.", LibraryRandom.RandIntInRange(100, 200));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Clear(GenJournalLine);
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"B  Balance", 0, GLAccountA."No.");
        GLAccountB.Copy(GLAccountA);
        GLAccountB."No." := LibraryUtility.GenerateGUID();
        GLAccountB.Insert();
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"B  Balance", 0, GLAccountB."No.");

        // [GIVEN] Allocations set for both lines
        CreateAllocationLine(GenJournalLine);

        // [WHEN] Post recurring journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Recurring Journal Line[1] has been posted
        // [THEN] Recurring Journal Line[2] has not been posted
        // [THEN] Message "At least one line has not been posted because of zero amount" has been shown
        // message verified in ZeroAmountLinePostingSkipMessageHandler
        GLEntry.SetRange("G/L Account No.", GLAccountA."No.");
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetRange("G/L Account No.", GLAccountB."No.");
        Assert.RecordIsEmpty(GLEntry);

        // [THEN] Recurring Journal Line[1]."Posting Date" = 01/02/2017 (1st February 2017)
        // [THEN] Recurring Journal Line[2]."Posting Date" = 01/02/2017 (1st February 2017)
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", CalcDate(GenJournalLine."Recurring Frequency", WorkDate()));
        GenJournalLine.Next();
        GenJournalLine.TestField("Posting Date", CalcDate(GenJournalLine."Recurring Frequency", WorkDate()));
        Assert.RecordCount(GenJournalLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountPositiveCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns TRUE when "Account No" <> <blank>, "Account Type" = Customer, "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::Customer);
        Assert.IsTrue(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountPositiveVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns TRUE when "Account No" <> <blank>, "Account Type" = Vendor, "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::Vendor);
        Assert.IsTrue(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountPositiveBankAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns TRUE when "Account No" <> <blank>, "Account Type" = "Bank Account", "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::"Bank Account");
        Assert.IsTrue(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountPositiveICPartner()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns TRUE when "Account No" <> <blank>, "Account Type" = "IC Partner", "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::"IC Partner");
        Assert.IsTrue(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountPositiveGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns TRUE when "Account No" <> <blank>, "Account Type" = "G/L Account", "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::"G/L Account");
        Assert.IsTrue(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountNegativeBlankAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns FALSE when "Account No" = <blank>, "Account Type" = Customer, "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, '', false, false, GenJournalLine."Account Type"::Customer);
        Assert.IsFalse(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountNegativeSystemEnrty()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns FALSE when "Account No" <> <blank>, "Account Type" = Customer, "Is System Created Entry" = TRUE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), true, false, GenJournalLine."Account Type"::Customer);
        Assert.IsFalse(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountNegativeAllowZeroPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns FALSE when "Account No" <> <blank>, "Account Type" = Customer, "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = TRUE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, true, GenJournalLine."Account Type"::Customer);
        Assert.IsFalse(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineNeedCheckZeroAmountNegativeFixedAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] NeedCheckZeroAmount function returns FALSE when "Account No" <> <blank>, "Account Type" = "Fixed Asset", "Is System Created Entry" = FALSE and "Allow Zero-Amount Posting" = FALSE
        GenJournalLine.Init();
        UpdateGenJournalLine(GenJournalLine, LibraryUtility.GenerateGUID(), false, false, GenJournalLine."Account Type"::"Fixed Asset");
        Assert.IsFalse(GenJournalLine.NeedCheckZeroAmount(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineIsRecurringPostive()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] IsReccuring function returns TRUE when Reccuring = TRUE in template of general journal line
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        Assert.IsTrue(GenJournalLine.IsRecurring(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineIsRecurringNegativeIsReccuringField()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] IsReccuring function returns FALSE when Reccuring = FALSE in template of general journal line
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.TestField(Recurring, false);
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
        Assert.IsFalse(GenJournalLine.IsRecurring(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJournalLineIsRecurringNegativeBlankTemplateField()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381263] IsReccuring function returns TRUE when template is not set in general journal line
        GenJournalLine.Init();
        Assert.IsFalse(GenJournalLine.IsRecurring(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleRecurringJournalLineUserSetupNotAllowedPostingPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        UserSetup: Record "User Setup";
        DocumentNo: array[3] of Code[20];
        AllowedDate: Date;
    begin
        // [FEATURE] [Posting Date] [Allowed Posting Period]
        // [SCENARIO 221154] Lines with posting date outside User Setup allowed posting period are not posted in Recurring Journal
        Initialize();

        // [GIVEN] General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Date when posting is allowed "D"
        AllowedDate := LibraryRandom.RandDate(-10);

        // [GIVEN] Admin User with "D" as allowed posting period
        CreateUserSetupWithAllowedPostingPeriod(UserSetup, AllowedDate, AllowedDate, true);

        // [GIVEN] Recurring Journal with 3 lines: "Posting Date" is more, less and equal to "DPA", "Expiration Date" is always more than "Posting Date"
        DocumentNo[1] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate + 1, AllowedDate + 2);
        DocumentNo[2] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate, AllowedDate + 2);
        DocumentNo[3] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate - 1, AllowedDate + 2);

        // [WHEN] Post Recurring Journal
        CreateAllocationLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only G/L Entry for line 2 is created
        VerifyGLEntriesWithNotAllowedPostingDate(DocumentNo);

        // Tear down
        UserSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostMultipleRecurringJournalLineGLSetupNotAllowedPostingPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[3] of Code[20];
        AllowedDate: Date;
    begin
        // [FEATURE] [Posting Date] [Allowed Posting Period]
        // [SCENARIO 221154] Lines with posting date outside GL Setup allowed posting period are not posted in Recurring Journal
        Initialize();

        // [GIVEN] General Journal Batch
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Date when posting is allowed "D"
        AllowedDate := LibraryRandom.RandDate(-10);

        // [GIVEN] Admin User with "D" as allowed posting period
        CreateGLSetupWithAllowedPostingPeriod(AllowedDate, AllowedDate);

        // [GIVEN] Recurring Journal with 3 lines: "Posting Date" is more, less and equal to "DPA", "Expiration Date" is always more than "Posting Date"
        DocumentNo[1] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate + 1, AllowedDate + 2);
        DocumentNo[2] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate, AllowedDate + 2);
        DocumentNo[3] := CreateRecurringJnlLine(
            GenJournalLine, GenJournalBatch, AllowedDate - 1, AllowedDate + 2);

        // [WHEN] Post Recurring Journal
        CreateAllocationLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only G/L Entry for line 2 is created
        VerifyGLEntriesWithNotAllowedPostingDate(DocumentNo);

        // Tear down
        LibrarySetupStorage.Restore();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SuccessMessageHandler,GLRegisterReportHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintRecurringJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // [FEATURE] [Print]
        // [SCENARIO 221154] Stan can post and print recurring journal
        CreateRecurringGenJournalBatch(GenJournalBatch);
        NameValueBuffer.DeleteAll();

        // [GIVEN] Balanced recurring journal
        CreateBalancedRecurringJnlLines(GenJournalLine, GenJournalBatch);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        // [WHEN] Call codeunit "Gen. Jnl.-Post+Print"
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", GenJournalLine);

        // [THEN] Report G/L Register printed after successful posting
        Assert.RecordCount(NameValueBuffer, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryPurchaseLCYAfterPostingPurchaseInvoiceJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 264513] Vendor Ledger Entry "Purchase (LCY)" has value after posting recurring journal for purchase invoice

        // [GIVEN] Recurring journal line for purchase Invoice with Amount = 100. The line is allocated by 100%.
        // [WHEN] Post the recurring journal
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] Vendor Ledger Entry "Purchase (LCY)" = 100
        VerifyVendorLedgerEntryPruchaseLCY(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryPurchaseLCYAfterPostingPurchaseCrMemoJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 264513] Vendor Ledger Entry "Purchase (LCY)" has value after posting recurring journal for purchase credit memo

        // [GIVEN] Recurring journal line for purchase Invoice with Amount = 100. The line is allocated by 100%.
        // [WHEN] Post the recurring journal
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] Vendor Ledger Entry "Purchase (LCY)" = 100
        VerifyVendorLedgerEntryPruchaseLCY(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntrySalesLCYAfterPostingSalesInvoiceJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 264513] Customer Ledger Entry "Sales (LCY)" has value after posting recurring journal for sales invoice

        // [GIVEN] Recurring journal line for sales Invoice with Amount = 100. The line is allocated by 100%.
        // [WHEN] Post the recurring journal
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] Customer Ledger Entry "Sales (LCY)" = 100
        VerifyCustomerLedgerEntrySalesLCY(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntrySalesLCYAfterPostingSalesCrMemoJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 264513] Customer Ledger Entry "Sales (LCY)" has value after posting recurring journal for sales credit memo

        // [GIVEN] Recurring journal line for sales Invoice with Amount = 100. The line is allocated by 100%.
        // [WHEN] Post the recurring journal
        CreatePostGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [THEN] Customer Ledger Entry "Sales (LCY)" = 100
        VerifyCustomerLedgerEntrySalesLCY(GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllocAmtWhenPostRecurringGenJnlLineWithRecurringMethodBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        RecurringMethod: array[2] of Enum "Gen. Journal Recurring Method";
        AllocLineNo: array[2] of Integer;
        AllocAmt: array[2] of Decimal;
        Index: Integer;
    begin
        // [FEATURE] [Gen. Jnl. Allocation] [Allocated Amt. (LCY)]
        // [SCENARIO 281606] When Balancing Recurring Gen. Journal Lines are posted with Allocations, then Amounts are populated in Allocations
        RecurringMethod[1] := GenJournalLine[1]."Recurring Method"::"B  Balance";
        RecurringMethod[2] := GenJournalLine[1]."Recurring Method"::"RB Reversing Balance";

        // [GIVEN] Two Recurring Gen. Journal Lines "L1" and "L2" in same Batch with same Posting Date:
        // [GIVEN] Line "L1" with Recurring Method = B Balance and G/L Account, which had Balance 1000.0 at Posting Date
        // [GIVEN] Line "L2" with Recurring Method = RB Reversing Balance and G/L Account, which had Balance 800.0 at Posting Date
        // [GIVEN] Gen. Jnl. Allocations "A1" and "A2" for Lines "L1" and "L2" respectfully, each had Allocation % = 100.0
        CreateRecurringGenJournalBatch(GenJournalBatch);
        for Index := 1 to ArrayLen(GenJournalLine) do begin
            AllocAmt[Index] := LibraryRandom.RandDecInRange(1000, 2000, 2);
            CreateGeneralJournalLine(
              GenJournalLine[Index], GenJournalBatch, RecurringMethod[Index], 0, CreateGLAccountWithBalanceAtDate(WorkDate(), AllocAmt[Index]));
            AllocLineNo[Index] := CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine[Index], LibraryERM.CreateGLAccountNo(), 100.0);
        end;

        // [WHEN] Post Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        // [THEN] Gen. Jnl. Allocations "A1" and "A2" have Amounts 1000.0 and 800.0 respectfully
        for Index := 1 to ArrayLen(GenJournalLine) do
            VerifyGenJnlAllocationAmount(GenJournalLine[Index], AllocLineNo[Index], AllocAmt[Index]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATInfoCopiedOnAllocationLine()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Sales] [Gen. Jnl. Allocation]
        // [SCENARIO 320952] "Country Code","VAT Registration No." are copied to VAT Entry from Customer when Recurring Journal Line is posted with Allocations

        // [GIVEN] Customer with "VAT Registration No." = "12345678910" and "Country/Region Code" = "FR"
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] Recurring journal line for sales Invoice with Amount = 100. The line is allocated by 100%.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        CreateGenJnlAllocationWithAccountAndAllocPct(
          GenJournalLine,
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), 100);

        // [WHEN] Post the recurring journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VAT Entry for the Invoice with "Country/Region Code" = "FR" and "VAT Registration No." = "12345678910" is created
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, Customer."No.");
        VATEntry.TestField("VAT Registration No.", Customer."VAT Registration No.");
        VATEntry.TestField("Country/Region Code", Customer."Country/Region Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineWithAllocationLine_CopyVATSetup_FALSE()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATEntryCount: Integer;
    begin
        // [FEATURE] [Gen. Jnl. Allocation]
        // [SCENARIO 332089] Posting gen. allocation lines must rely on negative "Copy VAT Setup on Jnl. Lines" of general journal batch
        CreateRecurringGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        VATEntryCount := VATEntry.Count();
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccount."No.", 100);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.RecordCount(VATEntry, VATEntryCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineWithAllocationLine_CopyVATSetup_TRUE()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Gen. Jnl. Allocation]
        // [SCENARIO 332089] Posting gen. allocation lines must rely on positive "Copy VAT Setup on Jnl. Lines" of general journal batch
        CreateRecurringGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccount."No.", 100);

        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error "There must be one invoice, credit memo, or finance charge memo with the same Document No." is thrown.
        Assert.ExpectedError(OneDocSameNoErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineCustomerWithAllocationLine_CopyVATSetup_TRUE()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATEntryCount: Integer;
    begin
        // [FEATURE] [Gen. Jnl. Allocation] [Customer]
        // [SCENARIO 332089] Posting gen. allocation lines must rely on positive "Copy VAT Setup on Jnl. Lines" of general journal batch
        CreateRecurringGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        VATEntryCount := VATEntry.Count;
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccount."No.", 100);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.RecordCount(VATEntry, VATEntryCount + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJournalLineVendorWithAllocationLine_CopyVATSetup_TRUE()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATEntryCount: Integer;
    begin
        // [FEATURE] [Gen. Jnl. Allocation] [Vendor]
        // [SCENARIO 332089] Posting gen. allocation lines must rely on positive "Copy VAT Setup on Jnl. Lines" of general journal batch
        CreateRecurringGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());

        VATEntryCount := VATEntry.Count;
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDecInRange(1000, 2000, 2));
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccount."No.", 100);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.RecordCount(VATEntry, VATEntryCount + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringGenJnlLinesNotSortedByDocNoWithForceDocBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // [FEATURE] [Force Doc. Balance]
        // [SCENARIO 345070] Post recurring Gen. Journal Lines, that are balanced by Document No, but not sorted in Document No order in case "Force Doc. Balance" and "Posting No. Series" are set.

        // [GIVEN] Gen. Journal Template with "Force Doc. Balance" = true; Gen. Journal Batch with non-empty "Posting No. Series".
        CreateRecurringGenJournalBatch(GenJournalBatch);
        UpdatePostingNoSeriesOnGenJnlBatch(GenJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", true);

        // [GIVEN] Four recurring Gen. Journal lines, balanced by Document No., but created with Document No. in order TEST1, TEST2, TEST1, TEST2.
        DocumentNo[1] := LibraryUtility.GenerateGUID();
        DocumentNo[2] := LibraryUtility.GenerateGUID();
        Amount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        Amount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          Amount[1], LibraryERM.CreateGLAccountNo(), DocumentNo[1]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          Amount[2], LibraryERM.CreateGLAccountNo(), DocumentNo[2]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          -Amount[1], LibraryERM.CreateGLAccountNo(), DocumentNo[1]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          -Amount[2], LibraryERM.CreateGLAccountNo(), DocumentNo[2]);

        // [WHEN] Post recurring Gen. Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Gen. Journal Lines were posted.
        VerifyGLEntryExists(GenJournalBatch.Name, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringGenJnlLinesUnbalancedAndNotSortedByDocNoWithForceDocBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // [FEATURE] [Force Doc. Balance]
        // [SCENARIO 345070] Post recurring Gen. Journal Lines, that are not balanced by Document No and not sorted in Document No order in case "Force Doc. Balance" and "Posting No. Series" are set.

        // [GIVEN] Gen. Journal Template with "Force Doc. Balance" = true; Gen. Journal Batch with non-empty "Posting No. Series".
        CreateRecurringGenJournalBatch(GenJournalBatch);
        UpdatePostingNoSeriesOnGenJnlBatch(GenJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        UpdateForceDocBalanceOnGenJnlTemplate(GenJournalBatch."Journal Template Name", true);

        // [GIVEN] Four recurring Gen. Journal lines, unbalanced by Document No. and created with Document No. in order TEST1, TEST2, TEST1, TEST2.
        DocumentNo[1] := LibraryUtility.GenerateGUID();
        DocumentNo[2] := LibraryUtility.GenerateGUID();
        Amount[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        Amount[2] := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          Amount[1], LibraryERM.CreateGLAccountNo(), DocumentNo[1]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          Amount[2], LibraryERM.CreateGLAccountNo(), DocumentNo[2]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          -Amount[1] * 2, LibraryERM.CreateGLAccountNo(), DocumentNo[1]);
        CreateJournalLineWithDocumentNo(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RV Reversing Variable",
          -Amount[2] * 2, LibraryERM.CreateGLAccountNo(), DocumentNo[2]);

        // [WHEN] Post recurring Gen. Journal Lines.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error "Document No. is out of balance" was thrown. General Journal Lines were not posted.
        Assert.ExpectedError(StrSubstNo(DocumentOutOfBalanceErr, DocumentNo[1]));
        Assert.ExpectedErrorCode('Dialog');
        VerifyGLEntryNotExists(GenJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringJnlWithExtDocNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLAccNo: array[2] of Code[20];
    begin
        // [SCENARIO 395652] "External Document No." transferred to G/L entry of the allocation line

        // [GIVEN] Recurring journal line with "External Document No." = "EXT1" and allocation = "ALLOC1" and "ALLOC2"
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 100);
        GenJournalLine."External Document No." := LibraryUtility.GenerateRandomText(MaxStrLen(GenJournalLine."External Document No."));
        GenJournalLine.Modify(true);

        GLAccNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccNo[2] := LibraryERM.CreateGLAccountNo();
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccNo[1], 60);
        CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine, GLAccNo[2], 40);

        // [WHEN] Post recurring journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "ALLOC1" GLEntry."External Document No." = "EXT1"
        GLEntry.SetRange("G/L Account No.", GLAccNo[1]);
        GLEntry.FindFirst();
        Assert.AreEqual(GenJournalLine."External Document No.", GLEntry."External Document No.", 'Wrong External Document No. in allocation G/L entry');
        // [THEN] "ALLOC2" GLEntry."External Document No." = "EXT1"
        GLEntry.SetRange("G/L Account No.", GLAccNo[2]);
        GLEntry.FindFirst();
        Assert.AreEqual(GenJournalLine."External Document No.", GLEntry."External Document No.", 'Wrong External Document No. in allocation G/L entry');
    end;

    [Test]
    procedure DueDateWhenPostRecurringJnlRVMethodForCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostingDate: Date;
    begin
        // [SCENARIO 407413] Due Date of Customer Ledger Entries when post recurring journal line with Reversing Variable method.
        Initialize();

        // [GIVEN] Recurring Journal Line with Posting Date "D" for Customer.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithType(
            GenJournalLine, GenJournalBatch, GenJnlRecurringMethod::"RV Reversing Variable", GenJnlDocType::" ",
            GenJnlAccountType::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDecInRange(100, 200, 2));

        PostingDate := LibraryRandom.RandDate(-20);
        UpdatePostingDateOnGenJournalLine(GenJournalLine, PostingDate);
        CreateAllocationLine(GenJournalLine);

        // [WHEN] Post recurring journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Two Customer Ledger Entries are created. First entry has Due Date = "D", second entry has Due Date = "D" + 1.
        VerifyCustomerLedgerEntryDueDateForRVMethod(GenJournalLine."Account No.", GenJournalLine."Document Type", PostingDate);
    end;

    [Test]
    procedure DueDateWhenPostRecurringJnlRVMethodForVendor()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostingDate: Date;
    begin
        // [SCENARIO 407413] Due Date of Vendor Ledger Entries when post recurring journal line with Reversing Variable method.
        Initialize();

        // [GIVEN] Recurring Journal Line with Posting Date "D" for Vendor.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithType(
            GenJournalLine, GenJournalBatch, GenJnlRecurringMethod::"RV Reversing Variable", GenJnlDocType::" ",
            GenJnlAccountType::Vendor, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDecInRange(100, 200, 2));

        PostingDate := LibraryRandom.RandDate(-20);
        UpdatePostingDateOnGenJournalLine(GenJournalLine, PostingDate);
        CreateAllocationLine(GenJournalLine);

        // [WHEN] Post recurring journal.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Two Vendor Ledger Entries are created. First entry has Due Date = "D", second entry has Due Date = "D" + 1.
        VerifyVendorLedgerEntryDueDateForRVMethod(GenJournalLine."Account No.", GenJournalLine."Document Type", PostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S462932_PostMultipleRecurringJournalLine_GLSetupNotAllowedPostingPeriod_OverExpirationDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: array[3] of Code[20];
    begin
        // [FEATURE] [Recurring General Journal] [Posting Date] [Allowed Posting Period] [Expiration Date]
        // [SCENARIO 462932] Lines with posting date outside General Ledger Setup allowed posting period are not posted in Recurring Journal and Posting Date is not updated.
        // [SCENARIO 462932] Expired lines are not posted in Recurring Journal and Posting Date is not updated.
        Initialize();

        // [GIVEN] Create Recurring General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Defined General Ledger Setup allowed posting period from 30 days before WorkDate up to 1 day before WorkDate.
        CreateGLSetupWithAllowedPostingPeriod(WorkDate() - 30, WorkDate() - 1);

        // [GIVEN] Create Recurring Journal with 3 lines:
        // [GIVEN] Line 1: "Posting Date" is WorkDate (out of allowed period). "Expiration Date" is blank. "Recurring Frequency" is defined.
        DocumentNo[1] := CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate(), 0D, LibraryRandom.RandInt(10));
        // [GIVEN] Line 2: "Posting Date" is the day before WorkDate (in allowed period). "Expiration Date" is blank. "Recurring Frequency" is defined.
        DocumentNo[2] := CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate() - 1, 0D, LibraryRandom.RandInt(10));
        // [GIVEN] Line 3: "Posting Date" is the day before WorkDate (in allowed period). But, "Expiration Date" is before (Expired). "Recurring Frequency" is defined.
        DocumentNo[3] := CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate() - 1, WorkDate() - 15, LibraryRandom.RandInt(10));

        // [WHEN] Post Recurring Journal.
        CreateAllocationLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only G/L Entry for Line 2 is posted.
        VerifyGLEntriesWithNotAllowedPostingDate(DocumentNo);

        // [THEN] Verify that Posting Date only for Line 2 is updated.
        FindGeneralJournalLine(GenJournalLine);
        GenJournalLine.FindSet();
        repeat
            case GenJournalLine."Document No." of
                DocumentNo[1]:
                    GenJournalLine.TestField("Posting Date", WorkDate());
                DocumentNo[2]:
                    GenJournalLine.TestField("Posting Date", CalcDate(GenJournalLine."Recurring Frequency", WorkDate() - 1));
                DocumentNo[3]:
                    GenJournalLine.TestField("Posting Date", WorkDate() - 1);
            end;
        until GenJournalLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AllocationAccountListPageHandler,ConfirmHandlerYes')]
    procedure RecurringJournal_ImportAllocationFromAllocationAccount_Successful()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        AllocationAccount: Record "Allocation Account";
        GLAccounts: array[3] of Record "G/L Account";
        AllocationShares: array[3] of Decimal;
        SharesSum: Decimal;

    begin
        // [FEATURE] [Recurring General Journal] [Allocation Account] [Allocations]
        // [SCENARIO 501438] User can import Allocation Account definition to Allocations in Recurring Gen Journal
        Initialize();

        // [GIVEN] Create Recurring General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create Recurring Journal with a line
        CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate(), 0D, LibraryRandom.RandInt(10));

        // [GIVEN] Create allocation for general journal line
        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // [GIVEN] Allocation Account "XXX" with 3 lines exists for different G/L Accounts and different Allocation Shares
        CreateAllocationAccountWithThreeGLAccLines(AllocationAccount, GLAccounts, AllocationShares);

        // [WHEN] Invoke Import from Allocation Account. Handler chooses Allocation Account "XXX" in lookup
        LibraryVariableStorage.Enqueue(AllocationAccount."No.");
        GenJnlAllocation.ChooseAndImportFromAllocationAccount();
        // UI Handled by handler

        // [THEN] There are 3 Gen Journal Allocations with the same amount and account as in Allocation Account
        SharesSum := AllocationShares[1] + AllocationShares[2] + AllocationShares[3];
        VerifyGenJnlAllocationExists(GenJnlAllocation, GenJournalLine, GLAccounts[1], AllocationShares[1] / SharesSum * 100);
        VerifyGenJnlAllocationExists(GenJnlAllocation, GenJournalLine, GLAccounts[2], AllocationShares[2] / SharesSum * 100);
        VerifyGenJnlAllocationExists(GenJnlAllocation, GenJournalLine, GLAccounts[3], AllocationShares[3] / SharesSum * 100);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AllocationAccountListPageHandler,ConfirmHandlerYes')]
    procedure RecurringJournal_ImportAllocationFromAllocationAccount_BankAccountNotSupported()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        AllocationAccount: Record "Allocation Account";
        BankAccount: Record "Bank Account";

    begin
        // [FEATURE] [Recurring General Journal] [Allocation Account] [Allocations]
        // [SCENARIO 501438] User cannot import Allocation Account definition to Allocations in Recurring Gen Journal if a line on Allocation Account is of type = Bank Account
        Initialize();

        // [GIVEN] Create Recurring General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create Recurring Journal with a line
        CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate(), 0D, LibraryRandom.RandInt(10));

        // [GIVEN] Create allocation for general journal line
        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // [GIVEN] Allocation Account "XXX" with a line exists for a Bank Account
        CreateAllocationAccountWithBankLine(AllocationAccount, BankAccount);

        // [WHEN] Invoke Import from Allocation Account. Handler chooses Allocation Account "XXX" in lookup
        LibraryVariableStorage.Enqueue(AllocationAccount."No.");
        asserterror GenJnlAllocation.ChooseAndImportFromAllocationAccount();
        // UI Handled by handler

        // [THEN] Error message is shown that Bank Account is not supported
        Assert.ExpectedError(AllocAccountImportWrongAccTypeErr);

    end;

    [Test]
    [HandlerFunctions('HandleEditDimensionSetEntriesPage,AllocationAccountListPageHandler,ConfirmHandlerYes')]
    procedure CheckDimensionOfRecurringJournalImportAllocationFromAllocationAccount()
    var
        AllocationAccount: Record "Allocation Account";
        FirstDimensionValue: Record "Dimension Value";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SecondDimensionValue: Record "Dimension Value";
        GLAccounts: array[2] of Record "G/L Account";
        AllocationShares: array[2] of Decimal;
        DimensionSetID: array[2] of Integer;
    begin
        // [SCENARIO 579186] In Recurring General Journals Import from Allocation Accounts does not import dimensions.
        Initialize();

        // [GIVEN] Create Recurring General Journal Batch.
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Create Recurring Journal with a line.
        CreateRecurringJnlLine(GenJournalLine, GenJournalBatch, WorkDate(), 0D, LibraryRandom.RandInt(10));

        // [GIVEN] Create allocation for general journal line.
        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");

        // [GIVEN] Dimension With Value.
        CreateDimensionsWithValues(FirstDimensionValue, SecondDimensionValue);

        // [GIVEN] Allocation Account "XXX" with 2 lines exists for different G/L Accounts and different Allocation Shares with Dimension.
        CreateAllocationAccountWithTwoGLAccLines(AllocationAccount, GLAccounts, AllocationShares, FirstDimensionValue, SecondDimensionValue, DimensionSetID);

        // [WHEN] Invoke Import from Allocation Account. Handler chooses Allocation Account "XXX" in lookup
        LibraryVariableStorage.Enqueue(AllocationAccount."No.");
        GenJnlAllocation.ChooseAndImportFromAllocationAccount();
        // UI Handled by handler

        // [THEN] There are 2 Gen Journal Allocations with the same Dimension as in Allocation Account
        VerifyGenJnlAllocationDimension(GenJnlAllocation, GenJournalLine, GLAccounts[1], DimensionSetID[1]);
        VerifyGenJnlAllocationDimension(GenJnlAllocation, GenJournalLine, GLAccounts[2], DimensionSetID[2]);
    end;

    [Test]
    procedure RecurringJournalLineGLSetupNotAllowedPostingPeriod()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecurringFrequency: DateFormula;
        Amount: Decimal;
        AllowedDate: Date;
    begin
        // [SCENARIO 221154] Lines with posting date outside GL Setup allowed posting period are not posted in Recurring Journal
        Initialize();

        // [GIVEN] General Journal Batch
        CreateRecurringGenJournalBatch(GenJournalBatch);

        // [GIVEN] Date when posting is allowed "D"
        AllowedDate := LibraryRandom.RandDate(-10);

        // [GIVEN] Admin User with "D" as allowed posting period
        CreateGLSetupWithAllowedPostingPeriod(AllowedDate - 10, AllowedDate + 10);

        LibraryERM.CreateGLAccount(GLAccount);

        Amount := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Recurring Journal with 3 lines: "Posting Date" is more, less and equal to "DPA", "Expiration Date" is always more than "Posting Date"
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[1],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::" ",
            GenJournalLine[1]."Account Type"::"G/L Account",
            GLAccount."No.",
            Amount);
        GenJournalLine[1].Validate("Posting Date", AllowedDate - 11);
        GenJournalLine[1].Validate("Recurring Method", GenJournalLine[1]."Recurring Method"::"RV Reversing Variable");
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandIntInRange(1, 1)) + 'M >');
        GenJournalLine[1].Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine[1].Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine[2],
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::" ",
            GenJournalLine[2]."Account Type"::"G/L Account",
            GLAccount."No.",
            -Amount);
        GenJournalLine[2].Validate("Posting Date", AllowedDate - 11);
        GenJournalLine[2].Validate("Document No.", GenJournalLine[1]."Document No.");
        GenJournalLine[2].Validate("Recurring Method", GenJournalLine[2]."Recurring Method"::"RV Reversing Variable");
        GenJournalLine[2].Validate("Recurring Frequency", GenJournalLine[1]."Recurring Frequency");
        GenJournalLine[2].Modify(true);

        // [WHEN] Post Recurring Journal
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        Assert.ExpectedError(
            StrSubstNo(
                PostingDateErr,
                GenJournalLine[1].FieldCaption("Posting Date"),
                GenJournalLine[1]."Journal Template Name",
                GenJournalLine[1]."Journal Batch Name",
                GenJournalLine[1]."Line No."));
    end;

    [Test]
    procedure RecurringJournalSuccessfullyPostedWhenUnlinkIncomingDocumentOnPostingOptionIsActivated()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringFrequency: array[6] of DateFormula;
    begin
        // [SCENARIO 602441] The changes to the Gen. Journal Line record cannot be saved because some information is not up-to-date" error when posting Recurring General Journal and the Unlink Incoming Document on Posting option is activated.
        Initialize();

        // [GIVEN] Create Recurring Journal Lines.
        CreateRecurringJournalLineWithVariable(GenJournalLine, RecurringFrequency);

        // [THEN] Post Recurring Journal Lines Successfully
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM PostRecurringJournal");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM PostRecurringJournal");
    end;

    local procedure CreateGLAccountWithBalanceAtDate(PostingDate: Date; Balance: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), Balance);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Account No.");
    end;

    local procedure CreateAndPostGeneralJournalLineWithRecurringMethod(var GenJournalLine: Record "Gen. Journal Line"; RecurringMethod: Enum "Gen. Journal Recurring Method")
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
        Counter: Integer;
    begin
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateRecurringGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount);
        for Counter := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            CreateJournalLineWithDocumentNo(
              GenJournalLine, GenJournalBatch, RecurringMethod, LibraryRandom.RandDec(100, 2), GLAccount."No.", DocumentNo);
            CreateJournalLineWithDocumentNo(
              GenJournalLine, GenJournalBatch, RecurringMethod, -GenJournalLine.Amount, GLAccount."No.", DocumentNo);
        end;
        FindGeneralJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateRecurringTemplateWithoutForceDocBalance(var GenJnlTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateRecurringTemplateName(GenJnlTemplate);
        GenJnlTemplate.Validate("Force Doc. Balance", false);
        GenJnlTemplate.Modify(true);
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var RecurringFrequency: array[6] of DateFormula): Integer
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
        NoOfLines: Integer;
    begin
        // Use Random Number Generator to generate the No. of lines.
        NoOfLines := 2 * LibraryRandom.RandInt(3);

        // Find G/L Account without VAT.
        FindGLAccount(GLAccount);

        // Create Recurring Journal Lines with Allocation and with random values.
        CreateRecurringGenJournalBatch(GenJournalBatch);
        for Counter := 1 to NoOfLines do begin
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", LibraryRandom.RandDec(100, 2),
              GLAccount."No.");
            GLAccount.Next();
            RecurringFrequency[Counter] := GenJournalLine."Recurring Frequency";
        end;
        CreateAllocationLine(GenJournalLine);
        exit(NoOfLines);
    end;

    local procedure CreateRecurringJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; ExpirationDate: Date): Code[20]
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed",
          LibraryRandom.RandDec(100, 2), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Expiration Date", ExpirationDate);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateRecurringJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; ExpirationDate: Date; RecurringFrequencyMonths: Integer): Code[20]
    var
        RecurringFrequency: DateFormula;
    begin
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed",
          LibraryRandom.RandDec(100, 2), LibraryERM.CreateGLAccountNo());
        Evaluate(RecurringFrequency, '<' + Format(RecurringFrequencyMonths) + 'M >');
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Expiration Date", ExpirationDate);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateBalancedRecurringJnlLines(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch")
    var
        InitialAmount: Decimal;
    begin
        CreateRecurringJnlLine(GenJnlLine, GenJnlBatch, WorkDate(), WorkDate());
        InitialAmount := GenJnlLine.Amount;
        GenJnlLine."Line No." := LibraryUtility.GetNewRecNo(GenJnlLine, GenJnlLine.FieldNo("Line No."));
        GenJnlLine.Validate(Amount, -InitialAmount);
        GenJnlLine.Insert(true);
    end;

    local procedure CreateGenJnlAllocationWithAccountAndAllocPct(GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; AllocPercent: Decimal): Integer
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", GLAccountNo);
        GenJnlAllocation.Validate("Allocation %", AllocPercent);
        GenJnlAllocation.Modify(true);
        exit(GenJnlAllocation."Line No.");
    end;

    local procedure CreateAllocationLine(GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLAccount: Record "G/L Account";
    begin
        // Create GL Account to use in General Journal Allocation Lines.
        LibraryERM.CreateGLAccount(GLAccount);
        FindGeneralJournalLine(GenJournalLine);

        // Create Allocation Line for each Recurring Journal Line.
        repeat
            LibraryERM.CreateGenJnlAllocation(
              GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
            GenJnlAllocation.Validate("Account No.", GLAccount."No.");
            GenJnlAllocation.Validate("Allocation %", 100);  // Using complete allocation for the Allocation Line.
            GenJnlAllocation.Modify(true);
        until GenJournalLine.Next() = 0;
    end;

    local procedure CreateAllocationAccountWithThreeGLAccLines(var AllocationAccount: Record "Allocation Account"; var GLAccounts: array[3] of Record "G/L Account"; var AllocationShares: array[3] of Decimal)
    var
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, GLAccounts[1]);
        AllocationShares[1] := LibraryRandom.RandDecInRange(1, 100, 2);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(AllocationShares[1]);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, GLAccounts[2]);
        AllocationShares[2] := LibraryRandom.RandDecInRange(1, 100, 2);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(AllocationShares[2]);

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistribution(AllocationAccountPage, GLAccounts[3]);
        AllocationShares[3] := LibraryRandom.RandDecInRange(1, 100, 2);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(AllocationShares[3]);

        AllocationAccountPage.Close();

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure CreateAllocationAccountWithBankLine(var AllocationAccount: Record "Allocation Account"; var BankAccount: Record "Bank Account")
    var
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AddBankDestinationAccountForFixedDistribution(AllocationAccountPage, BankAccount);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(LibraryRandom.RandDecInRange(1, 100, 2));

        AllocationAccountPage.Close();

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure AddGLDestinationAccountForFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure AddBankDestinationAccountForFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"; var BankAccount: Record "Bank Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if BankAccount."No." = '' then
            BankAccount.Get(LibraryERM.CreateBankAccountNo());

        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"Bank Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(BankAccount."No.");
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(var AllocationAccountPage: TestPage "Allocation Account"): Code[20]
    var
        DummyAllocationAccount: Record "Allocation Account";
        AllocationAccountNo: Code[20];
    begin
        AllocationAccountPage.OpenNew();

        AllocationAccountNo := LibraryUtility.GenerateGUID();

        AllocationAccountPage."No.".SetValue(AllocationAccountNo);
        AllocationAccountPage."Account Type".SetValue(DummyAllocationAccount."Account Type"::Fixed);
        AllocationAccountPage.Name.SetValue(LibraryUtility.GenerateGUID());
        exit(AllocationAccountNo);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; Amount: Decimal; AccountNo: Code[20])
    begin
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, RecurringMethod, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
    end;

    local procedure CreateGeneralJournalLineWithType(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        RecurringFrequency: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        Evaluate(RecurringFrequency, '<' + Format(LibraryRandom.RandInt(10)) + 'M >');
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineWithDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; Amount: Decimal; AccountNo: Code[20]; DocumentNo: Code[20])
    begin
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, RecurringMethod, Amount, AccountNo);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateRecurringGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateUserSetupWithAllowedPostingPeriod(var UserSetup: Record "User Setup"; AllowedPostingFrom: Date; AllowedPostingTo: Date; IsAdministrator: Boolean)
    begin
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, CopyStr(UserId, 1, 50), '');
        UserSetup.Validate("Allow Posting From", AllowedPostingFrom);
        UserSetup.Validate("Allow Posting To", AllowedPostingTo);
        UserSetup.Validate("Approval Administrator", IsAdministrator);
        UserSetup.Modify(true)
    end;

    local procedure CreateGLSetupWithAllowedPostingPeriod(AllowedPostingFrom: Date; AllowedPostingTo: Date)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.FindFirst();
        GLSetup.Validate("Allow Posting From", AllowedPostingFrom);
        GLSetup.Validate("Allow Posting To", AllowedPostingTo);
        GLSetup.Modify(true)
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateRecurringGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", DocumentType, AccountType, AccountNo, Amount);
        CreateAllocationLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; IsSystemEntry: Boolean; AllowZeroPosting: Boolean; AccountType: Enum "Gen. Journal Account Type")
    begin
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."System-Created Entry" := IsSystemEntry;
        GenJournalLine."Allow Zero-Amount Posting" := AllowZeroPosting;
        GenJournalLine."Account Type" := AccountType;
    end;

    local procedure UpdateForceDocBalanceOnGenJnlTemplate(GenJnlTemplateName: Code[20]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(GenJnlTemplateName);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure UpdatePostingNoSeriesOnGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch"; PostingNoSeries: Code[20])
    begin
        GenJournalBatch.Validate("Posting No. Series", PostingNoSeries);
        GenJournalBatch.Modify(true);
    end;

    local procedure UpdatePostingDateOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("VAT Prod. Posting Group", '');
        LibraryERM.FindDirectPostingGLAccount(GLAccount);
    end;

    local procedure FindGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
        VATEntry.FindFirst();
    end;

    local procedure VerifyGenJnlAllocationExists(GenJnlAllocation: Record "Gen. Jnl. Allocation"; GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; AllocationPct: Decimal)
    begin
        GenJnlAllocation.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlAllocation.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlAllocation.SetRange("Journal Line No.", GenJournalLine."Line No.");
        GenJnlAllocation.SetRange("Account No.", GLAccount."No.");
        GenJnlAllocation.FindFirst();
        Assert.AreNearlyEqual(GenJnlAllocation."Allocation %", AllocationPct, 0.01, 'Allocation % is not correct');
    end;

    local procedure VerifyGenJnlAllocationAmount(GenJournalLine: Record "Gen. Journal Line"; AllocationLineNo: Integer; ExpectedAmount: Decimal)
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        GenJnlAllocation.Get(
          GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.", AllocationLineNo);
        GenJnlAllocation.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyNoOfLineInGLEntry(JournalBatchName: Code[10]; NoOfLines: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", JournalBatchName);
        Assert.AreEqual(GLEntry.Count, NoOfLines, NoOfLinesErr);
    end;

    local procedure VerifyDocumentDateOnGLEntry(JournalBatchName: Code[10]; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", JournalBatchName);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("Document Date", '<>%1', GLEntry."Posting Date");
        if not GLEntry.IsEmpty() then
            Error(DocumentDateErr, GLEntry.FieldCaption("Document Date"), GLEntry.FieldCaption("Posting Date"), GLEntry.TableCaption());
    end;

    local procedure VerifyGLEntryExists(JournalBatchName: Code[10]; PostingDate: Date)
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("Journal Batch Name", JournalBatchName);
        DummyGLEntry.SetRange("Posting Date", PostingDate);
        Assert.RecordIsNotEmpty(DummyGLEntry);
    end;

    local procedure VerifyGLEntryNotExists(JournalBatchName: Code[10])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", JournalBatchName);
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure VerifyGLEntriesWithExpiredDate(DocumentNo: array[3] of Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry.SetRange("External Document No.", DocumentNo[1]);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetRange("External Document No.", DocumentNo[2]);
        Assert.RecordIsEmpty(GLEntry);
        GLEntry.SetRange("External Document No.", DocumentNo[3]);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    local procedure VerifyGLEntriesWithNotAllowedPostingDate(DocumentNo: array[3] of Code[20])
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("External Document No.", DocumentNo[1]);
        Assert.RecordIsEmpty(DummyGLEntry);
        DummyGLEntry.SetRange("External Document No.", DocumentNo[2]);
        Assert.RecordIsNotEmpty(DummyGLEntry);
        DummyGLEntry.SetRange("External Document No.", DocumentNo[3]);
        Assert.RecordIsEmpty(DummyGLEntry);
    end;

    local procedure VerifyVendorLedgerEntryPruchaseLCY(VendorNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Purchase (LCY)", ExpectedAmount);
    end;

    local procedure VerifyCustomerLedgerEntrySalesLCY(CustomerNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Sales (LCY)", ExpectedAmount);
    end;

    local procedure VerifyCustomerLedgerEntryDueDateForRVMethod(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.SetRange(Positive, true);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Due Date", PostingDate);

        CustLedgerEntry.SetRange("Posting Date", PostingDate + 1);
        CustLedgerEntry.SetRange(Positive, false);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Due Date", PostingDate + 1);
    end;

    local procedure VerifyVendorLedgerEntryDueDateForRVMethod(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Posting Date", PostingDate);
        VendorLedgerEntry.SetRange(Positive, true);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Due Date", PostingDate);

        VendorLedgerEntry.SetRange("Posting Date", PostingDate + 1);
        VendorLedgerEntry.SetRange(Positive, false);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Due Date", PostingDate + 1);
    end;

    local procedure CreateDimensionsWithValues(var FirstDimensionValue: Record "Dimension Value"; var SecondDimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(FirstDimensionValue, Dimension.Code);
        LibraryDimension.CreateDimensionValue(SecondDimensionValue, Dimension.Code);
    end;

    local procedure CreateAllocationAccountWithTwoGLAccLines(var AllocationAccount: Record "Allocation Account"; var GLAccounts: array[2] of Record "G/L Account"; var AllocationShares: array[2] of Decimal; FirstDimensionValue: Record "Dimension Value"; SecondDimensionValue: Record "Dimension Value"; var DimensionSetID: array[2] of Integer)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        AllocationAccountPage: TestPage "Allocation Account";
        FixedAllocationAccountCode: Code[20];
    begin
        FixedAllocationAccountCode := CreateAllocationAccountWithFixedDistribution(AllocationAccountPage);
        AddGLDestinationAccountForFixedDistributionWithDimension(AllocationAccountPage, GLAccounts[1]);
        AllocationShares[1] := LibraryRandom.RandDecInRange(1, 100, 2);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(AllocationShares[1]);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, FirstDimensionValue);

        AllocAccountDistribution.SetRange("Allocation Account No.", FixedAllocationAccountCode);
        AllocAccountDistribution.SetRange("Account Type", AllocAccountDistribution."Account Type"::Fixed);
        AllocAccountDistribution.SetRange("Destination Account Number", GLAccounts[1]."No.");
        AllocAccountDistribution.FindFirst();
        DimensionSetID[1] := AllocAccountDistribution."Dimension Set ID";

        AllocationAccountPage.FixedAccountDistribution.New();
        AddGLDestinationAccountForFixedDistributionWithDimension(AllocationAccountPage, GLAccounts[2]);
        AllocationShares[2] := LibraryRandom.RandDecInRange(1, 100, 2);
        AllocationAccountPage.FixedAccountDistribution.Share.SetValue(AllocationShares[2]);
        SetDimensionToCurrentVariableLine(AllocationAccountPage, SecondDimensionValue);

        AllocAccountDistribution.Reset();
        AllocAccountDistribution.SetRange("Allocation Account No.", FixedAllocationAccountCode);
        AllocAccountDistribution.SetRange("Account Type", AllocAccountDistribution."Account Type"::Fixed);
        AllocAccountDistribution.SetRange("Destination Account Number", GLAccounts[2]."No.");
        AllocAccountDistribution.FindFirst();
        AllocationAccountPage.FixedAccountDistribution.GoToRecord(AllocAccountDistribution);
        DimensionSetID[2] := AllocAccountDistribution."Dimension Set ID";

        AllocationAccountPage.Close();

        AllocationAccount.Get(FixedAllocationAccountCode);
    end;

    local procedure SetDimensionToCurrentVariableLine(var AllocationAcccount: TestPage "Allocation Account"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryVariableStorage.Enqueue(DimensionValue.SystemId);
        AllocationAcccount.FixedAccountDistribution.Dimensions.Invoke();
    end;

    local procedure AddGLDestinationAccountForFixedDistributionWithDimension(var AllocationAccountPage: TestPage "Allocation Account"; var GLAccount: Record "G/L Account")
    var
        DummyAllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountNoWithDirectPosting());

        AllocationAccountPage.FixedAccountDistribution."Destination Account Type".SetValue(DummyAllocAccountDistribution."Destination Account Type"::"G/L Account");
        AllocationAccountPage.FixedAccountDistribution."Destination Account Number".SetValue(GLAccount."No.");
    end;

    local procedure VerifyGenJnlAllocationDimension(GenJnlAllocation: Record "Gen. Jnl. Allocation"; GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account"; DimensionSetID: Integer)
    begin
        GenJnlAllocation.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlAllocation.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlAllocation.SetRange("Journal Line No.", GenJournalLine."Line No.");
        GenJnlAllocation.SetRange("Account No.", GLAccount."No.");
        GenJnlAllocation.FindFirst();
        Assert.AreEqual(GenJnlAllocation."Dimension Set ID", DimensionSetID, AllocationDimensionErr);
    end;

    local procedure CreateRecurringJournalLineWithVariable(var GenJournalLine: Record "Gen. Journal Line"; var RecurringFrequency: array[6] of DateFormula)
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        Counter: Integer;
        NoOfLines: Integer;
    begin
        // Use Random Number Generator to generate the No. of lines.
        NoOfLines := 2 * LibraryRandom.RandInt(3);

        //[GIVEN] Find G/L Account
        FindGLAccount(GLAccount);

        //[GIVEN] Create Vendor
        LibraryPurchase.CreateVendor(Vendor);

        //[WHEN] Create Recurring Journal Lines with Allocation and with random values.
        CreateRecurringGenJournalTemplateAndBatch(GenJournalBatch);
        for Counter := 1 to NoOfLines do begin
            if Counter = 1 then begin
                CreateGeneralJournalLineWithAccountType(
                  GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", -1000,
                  Vendor."No.");
                RecurringFrequency[Counter] := GenJournalLine."Recurring Frequency";
                GenJournalLine."Document No." := '123';
                GenJournalLine.Modify();
            end else
                CreateGeneralJournalLineDocType(
                  GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", 1000,
                  GLAccount."No.");
            GenJournalLine."Document No." := '123';
            GenJournalLine.Modify();
            GLAccount.Next();
            RecurringFrequency[Counter] := GenJournalLine."Recurring Frequency";
        end;
    end;

    local procedure CreateGeneralJournalLineWithAccountType(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; Amount: Decimal; AccountNo: Code[20])
    begin
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, RecurringMethod, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
    end;

    local procedure CreateGeneralJournalLineDocType(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; Amount: Decimal; AccountNo: Code[20])
    begin
        CreateGeneralJournalLineWithType(
          GenJournalLine, GenJournalBatch, RecurringMethod, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
    end;

    local procedure CreateRecurringGenJournalTemplateAndBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindRecurringTemplateName(GenJnlTemplate);
        GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::General);
        GenJnlTemplate.Validate(Recurring, true);
        GenJnlTemplate.Validate("Bal. Account Type", GenJnlTemplate."Bal. Account Type"::"G/L Account");
        GenJnlTemplate.Validate("Force Doc. Balance", true);
        GenJnlTemplate.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJnlTemplate.Validate("Unlink Inc. Doc On Posting", true);
        GenJnlTemplate.Modify(true);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJnlTemplate.Name);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessMessageHandler(Msg: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessPostingMsg, Msg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ZeroAmountLinePostingSkipMessageHandler(MessageText: Text)
    begin
        Assert.ExpectedMessage(SkippedLineMsg, MessageText);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJnlTemplateModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AllocationAccountListPageHandler(var AllocationAccountList: TestPage "Allocation Account List")
    begin
        AllocationAccountList.GoToKey(LibraryVariableStorage.DequeueText());
        AllocationAccountList.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure GLRegisterReportHandler(var GLRegister: Report "G/L Register")
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.ID := LibraryUtility.GetNewRecNo(NameValueBuffer, NameValueBuffer.FieldNo(ID));
        NameValueBuffer.Insert();
    end;

    [ModalPageHandler]
    procedure HandleEditDimensionSetEntriesPage(var EditDimensionSetEntriesPage: TestPage "Edit Dimension Set Entries")
    var
        DimensionValue: Record "Dimension Value";
        DimensionValueSystemId: Text;
    begin
        DimensionValueSystemId := LibraryVariableStorage.DequeueText();
        DimensionValue.GetBySystemId(DimensionValueSystemId);
        EditDimensionSetEntriesPage.New();
        EditDimensionSetEntriesPage."Dimension Code".SetValue(DimensionValue."Dimension Code");
        EditDimensionSetEntriesPage.DimensionValueCode.SetValue(DimensionValue.Code);
        EditDimensionSetEntriesPage.OK().Invoke();
    end;
}

