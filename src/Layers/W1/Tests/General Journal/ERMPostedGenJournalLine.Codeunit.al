codeunit 134935 "ERM Posted Gen. Journal Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        CopyEnabledErr: Label 'Copy to Posted Gen. Journal Lines should be enabled.';
        CopyDisabledErr: Label 'Copy to Posted Gen. Journal Lines should not be enabled.';
        PostedGenJournalLineErr: Label 'Posted Gen. Journal Line contains wrong data.';
        GenJournalLineErr: Label 'Gen. Journal Line contains wrong data.';
        CanBeCopiedErr: Label 'You cannot copy the posted general journal lines with G/L register number %1 because they contain customer, vendor, or employee ledger entries that were posted and applied in the same G/L register.';
        ReverseDateCalcRecurringTypeErr: Label 'Recurring must have a value in Gen. Journal Template';
        ReverseDateCalcRecurringMethodErr: Label 'Recurring Method must not be';
        PostedGenJournalLineLinkErr: Label ' Links are not equal.';

    [Test]
    [Scope('OnPrem')]
    procedure EnableGenJnlTemplateCopyToPostedGenJnlLinesUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        // [SCENARIO 277244] Enable "Copy to Posted Jnl. Lines" on the Gen. Journal Template
        Initialize();

        // [GIVEN] Gen. Journal Template with batches
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        for i := 1 to 5 do
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [WHEN] Enable "Copy to Posted Jnl. Lines"
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalTemplate.Modify(true);

        // [THEN] "Copy to Posted Jnl. Lines" is enabled on the Gen. Journal Template
        Assert.IsTrue(GenJournalTemplate."Copy to Posted Jnl. Lines", CopyEnabledErr);

        // [THEN] "Copy to Posted Jnl. Lines" is enabled on the Gen. Journal Batches
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindSet();
        repeat
            Assert.IsTrue(GenJournalBatch."Copy to Posted Jnl. Lines", CopyEnabledErr);
        until GenJournalBatch.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableGenJnlTemplateCopyToPostedGenJnlLinesUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        i: Integer;
    begin
        // [SCENARIO 277244] Disable "Copy to Posted Jnl. Lines" on the Gen. Journal Template
        Initialize();

        // [GIVEN] Gen. Journal Template with batches and enabled "Copy to Posted Jnl. Lines"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        for i := 1 to 5 do
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJournalTemplate.Modify(true);

        // [WHEN] Disable "Copy to Posted Jnl. Lines"
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", false);
        GenJournalTemplate.Modify(true);

        // [THEN] "Copy to Posted Jnl. Lines" is disabled on the Gen. Journal Template
        Assert.IsFalse(GenJournalTemplate."Copy to Posted Jnl. Lines", CopyDisabledErr);

        // [THEN] "Copy to Posted Jnl. Lines" is disabled on the Gen. Journal Batches
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindSet();
        repeat
            Assert.IsFalse(GenJournalBatch."Copy to Posted Jnl. Lines", CopyDisabledErr);
        until GenJournalBatch.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableGenJnlBatchCopyToPostedGenJnlLinesWithDisabledTemplateUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 277244] Enable "Copy to Posted Jnl. Lines" on the Gen. Journal Batch when "Copy to Posted Jnl. Lines" is disabled on the Gen. Journal Template
        Initialize();

        // [GIVEN] Gen. Journal Template with disabled "Copy to Posted Jnl. Lines"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", false);
        GenJournalTemplate.Modify(true);

        // [GIVEN] Gen. Journal Batch
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [WHEN] Enable "Copy to Posted Jnl. Lines" on the Gen. Journal Batch
        asserterror GenJournalBatch.Validate("Copy to Posted Jnl. Lines", true);

        // [THEN] Error message that Gen. Journal Template "Copy to Posted Jnl. Lines"
        Assert.ExpectedTestFieldError(GenJournalBatch.FieldCaption("Copy to Posted Jnl. Lines"), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableGenJnlTemplateCopyToPostedGenJnlLinesForRecurringUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 277244] Enable "Copy to Posted Jnl. Lines" for recurring general journal template leads to error
        Initialize();

        // [GIVEN] Recurring Gen. Journal Template
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);

        // [WHEN] Enable "Copy to Posted Jnl. Lines" on the recurring Gen. Journal Template
        asserterror GenJournalTemplate.Validate("Copy to Posted Jnl. Lines", true);

        // [THEN] Error message that recurring must not be enabled
        Assert.ExpectedTestFieldError(GenJournalTemplate.FieldCaption(Recurring), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlBatchWithDisabledCopyToPostedJnlLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
    begin
        // [SCENARIO 277244] Post Gen. Journal Batch with disabled "Copy to Posted Jnl. Lines"
        Initialize();

        // [GIVEN] Gen. Journal Batch with disabled "Copy to Posted Jnl. Lines"
        CreateGenJnlBatch(GenJournalBatch, false);

        // [GIVEN] Gen. Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        // [WHEN] Post Gen. Journal Batch
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There are no Posted Gen. Journal Line
        PostedGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordIsEmpty(PostedGenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGenJnlBatchWithEnabledCopyToPostedJnlLines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        i: Integer;
    begin
        // [SCENARIO 277244] Post Gen. Journal Batch with enabled "Copy to Posted Jnl. Lines"
        Initialize();

        // [GIVEN] Gen. Journal Batch with enabled "Copy to Posted Jnl. Lines"
        CreateGenJnlBatch(GenJournalBatch, true);

        // [GIVEN] Five Gen. Journal Line
        for i := 1 to 5 do
            LibraryERM.CreateGeneralJnlLineWithBalAcc(
                GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
                GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
                GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        // [WHEN] Post Gen. Journal Batch
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] There are five Posted Gen. Journal Line
        PostedGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordCount(PostedGenJournalLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLineCopiedToPostGenJnlLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Gen. Journal copied to Posted Gen. Journal Line
        Initialize();

        // [GIVEN] Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        AddGenJournalLineDimension(GenJournalLine);

        // [WHEN] Post Gen. Journal Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted Gen. Journal Line is a copy of Gen. Journal Line
        VerifyPostedGenJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedGenJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Navigate: TestPage Navigate;
        i: Integer;
    begin
        // [SCENARIO 277244] Navigate discovers Posted Gen. Journal Lines
        Initialize();

        // [GIVEN] Posted Gen. Journal Line "PGJL1" with "PD1"
        CreateGenJnlBatch(GenJournalBatch, true);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, WorkDate() + 1);

        // [GIVEN] Two Posted Gen. Journal Line "PGJL2" with "PD2"
        for i := 1 to 2 do
            CreateGenJnlLine(GenJournalLine, GenJournalBatch, WorkDate() + 2);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run Navigate page and search for "PD1"
        Navigate.OpenEdit();
        Navigate.PostingDateFilter.SetValue(WorkDate() + 1);
        Navigate.Find.Invoke();

        // [THEN] Number of "PGJL1" records = 1
        Navigate.Filter.SetFilter("Table Id", Format(Database::"Posted Gen. Journal Line"));
        Navigate."No. of Records".AssertEquals(1);
        Navigate.Close();

        // [WHEN] Run Navigate page and search for "PD2"
        Navigate.OpenEdit();
        Navigate.PostingDateFilter.SetValue(WorkDate() + 2);
        Navigate.Find.Invoke();

        // [THEN] Number of "PGJL2" records = 2
        Navigate.Filter.SetFilter("Table Id", Format(Database::"Posted Gen. Journal Line"));
        Navigate."No. of Records".AssertEquals(2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NavigatePostedGenJournalLineDrillDownRecords()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Navigate: TestPage Navigate;
        PostedGeneralJournal: TestPage "Posted General Journal";
    begin
        // [SCENARIO 277244] Drill down to posted general journal from "Find Entries" page
        Initialize();

        // [GIVEN] Posted Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, WorkDate() + 3);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Navigate page with found posted general journal line
        Navigate.OpenEdit();
        Navigate.PostingDateFilter.SetValue(WorkDate() + 3);
        Navigate.Find.Invoke();
        Navigate.Filter.SetFilter("Table Id", Format(Database::"Posted Gen. Journal Line"));

        // [WHEN] Drill down to posted entries
        Navigate."No. of Records".AssertEquals(1);
        PostedGeneralJournal.Trap();
        Navigate."No. of Records".Drilldown();

        // [THEN] "Posted General Journal" page opened with posted entry
        PostedGeneralJournal.First();
        PostedGeneralJournal."Account No.".AssertEquals(GenJournalLine."Account No.");
        Assert.IsFalse(PostedGeneralJournal.Next(), 'Wrong number of entries');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandler,ConfirmHandler')]
    procedure CopyPostedGenJnlLineToGenJnlLineWithoutReverseSign()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        ReverseSign: Boolean;
    begin
        // [SCENARIO 277244] Copy Posted Gen. Journal to Gen. Journal Line without reverse sign
        Initialize();

        // [GIVEN] "Reverse Sign" = false
        ReverseSign := false;

        // [GIVEN] Posted Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        AddGenJournalLineDimension(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy Posted Gen. Journal Line to Gen. Journal Line without "Reverse Sign"
        QueueCopyParameters(GenJournalBatch, ReverseSign);
        FindPostedGenJournalLine(PostedGenJournalLine, GenJournalBatch, false);
        CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] New Gen. Journal Line is a copy of original Gen. Journal Line
        VerifyCopiedGenJnlLine(GenJournalLine, GenJournalBatch, false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandler,ConfirmHandler')]
    procedure CopyPostedGenJnlLineToGenJnlLineReverseSign()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        ReverseSign: Boolean;
    begin
        // [SCENARIO 277244] Copy Posted Gen. Journal to Gen. Journal Line with "Reverse Sign"
        Initialize();

        // [GIVEN] "Reverse Sign" = true
        ReverseSign := true;

        // [GIVEN] Posted Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        AddGenJournalLineDimension(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy Posted Gen. Journal Line to Gen. Journal Line with "Reverse Sign"
        QueueCopyParameters(GenJournalBatch, ReverseSign);
        FindPostedGenJournalLine(PostedGenJournalLine, GenJournalBatch, false);
        CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] New Gen. Journal Line is a copy of original Gen. Journal Line
        VerifyCopiedGenJnlLine(GenJournalLine, GenJournalBatch, true);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandler,ConfirmHandler')]
    procedure CopyRegisterToGenJnlLineOneRegister()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TargetGenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        i: Integer;
    begin
        // [SCENARIO 277244] Register is copied when copy first posted general journal line and invoke "Copy G/L Register..." action
        Initialize();

        // [GIVEN] Two Posted Gen. Journal Lines in one register
        CreateGenJnlBatch(GenJournalBatch, true);
        for i := 1 to 2 do
            CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy first posted general journal line
        CreateGenJnlBatch(TargetGenJournalBatch, false);
        QueueCopyParameters(TargetGenJournalBatch, false);
        FilterFirstPostedGenJnlLine(PostedGenJournalLine, GenJournalBatch);
        CopyGenJournalMgt.CopyGLRegister(PostedGenJournalLine);

        // [THEN] The whole register copied to general journal (2 entries copied)
        VerifyCopiedGenJnlLines(GenJournalBatch, TargetGenJournalBatch, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandler,ConfirmHandler')]
    procedure CopyRegisterToGenJnlLineTowRegisters()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TargetGenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        i: Integer;
    begin
        // [SCENARIO 277244] Two registers are copied when copy first posted general journal lines and invoke "Copy G/L Register..." action
        Initialize();

        // [GIVEN] Two Posted Gen. Journal Lines, register "R1"
        CreateGenJnlBatch(GenJournalBatch, true);
        for i := 1 to 2 do
            CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Two Posted Gen. Journal Lines, register "R2"
        for i := 1 to 2 do
            CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy first posted general journal line from registers "R1" and "R2"
        CreateGenJnlBatch(TargetGenJournalBatch, false);
        QueueCopyParameters(TargetGenJournalBatch, false);
        FilterFirstPostedGenJnlLine(PostedGenJournalLine, GenJournalBatch);
        CopyGenJournalMgt.CopyGLRegister(PostedGenJournalLine);

        // [THEN] Two entries should be copied
        VerifyCopiedGenJnlLines(GenJournalBatch, TargetGenJournalBatch, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBalancedRecurringGenJournalLineWithReversePostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Post balanced recurring journal with "Reverse Date Calculation"
        Initialize();

        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "RF Reversing Fixed", "Reverse Date Calculation" = +5D
        CreateBalancedRecurringGenJnlLine(GenJournalLine);

        // [WHEN] Post recurring Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Reversal entries posted with "Posting Date" = Workdate + 5D
        VerifyPostedRecurringGenJournalLine(GenJournalLine, 5);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostAllocatedRecurringGenJournalLineWithReversePostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Post allocated recurring journal with "Reverse Date Calculation"
        Initialize();

        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "RB Reversing Balance", "Reverse Date Calculation" = +5D
        CreateAllocatedRecurringGenJnlLine(GenJournalLine);

        // [WHEN] Post recurring Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Reversal entries posted with "Posting Date" = Workdate + 5D
        VerifyPostedRecurringGenJournalLine(GenJournalLine, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringGenJournalLineFixedWithAmountZeroLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        // [SCENARIO] Post recurring journal with method Fixed and an amount zero line
        Initialize();

        // [GIVEN] Create recurring Gen. Journal Batch
        CreateRecurringGenJnlBatch(GenJournalBatch);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", "Reverse Date Calculation" = +5D, Amount = zero
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", 0);
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", "Reverse Date Calculation" = +5D, Amount = 500
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", 500);
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Modify(true);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", "Reverse Date Calculation" = +5D, Amount = -500
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", -500);
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Modify(true);

        // [WHEN] Post recurring Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only two entries posted
        VerifyPostedRecurringGenJournalLine(GenJournalLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostRecurringGenJournalLineVariableWithAmountZeroLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        // [SCENARIO] Post recurring journal with method Variable and an amount zero line
        Initialize();

        // [GIVEN] Create recurring Gen. Journal Batch
        CreateRecurringGenJnlBatch(GenJournalBatch);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", Amount = zero
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", 0);
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", Amount = 500
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", 500);
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Modify(true);
        // [GIVEN] Recurring Gen. Journal Line, "Recurring Method" = "F Fixed", Amount = -500
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", -500);
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Modify(true);

        // [WHEN] Post recurring Gen. Journal Lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Only two entries posted
        VerifyPostedRecurringGenJournalLine(GenJournalLine, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedAndAppliedGenJnlLineToGenJnlLineCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        CustomerNo: Code[20];

        DocumentNo: Code[20];
    begin
        // [SCENARIO 277244] Copy Posted and Applied Gen. Journal to Gen. Journal Line
        Initialize();

        // [GIVEN] Posted Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        CustomerNo := GenJournalLine."Account No.";
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted applied Gen. Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), -123.45);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy Posted Gen. Journal Line to Gen. Journal Line
        FindPostedGenJournalLine(PostedGenJournalLine, GenJournalBatch, false);
        asserterror CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] Posted Gen. Journal Line is not copied to Gen. Journal Line
        Assert.ExpectedError(StrSubstNo(CanBeCopiedErr, PostedGenJournalLine."G/L Register No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedAndAppliedGenJnlLineToGenJnlLineVendor()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 277244] Copy Posted and Applied Gen. Journal to Gen. Journal Line
        Initialize();

        // [GIVEN] Posted Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), -123.45);
        VendorNo := GenJournalLine."Account No.";
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted applied Gen. Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
        GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy Posted Gen. Journal Line to Gen. Journal Line
        FindPostedGenJournalLine(PostedGenJournalLine, GenJournalBatch, false);
        asserterror CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] Posted Gen. Journal Line is not copied to Gen. Journal Line
        Assert.ExpectedError(StrSubstNo(CanBeCopiedErr, PostedGenJournalLine."G/L Register No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReversePostingDateNonRecurring()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Validate "Reverse Date Calculation" for non recurring journal line leads to the error
        Initialize();

        // [GIVEN] Normal Gen. Journal Line
        CreateGenJnlBatch(GenJournalBatch, false);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, WorkDate());

        // [WHEN] Validate "Reverse Date Calculation"
        Evaluate(GenJournalLine."Reverse Date Calculation", '<2D>');
        asserterror GenJournalLine.Validate("Reverse Date Calculation");

        // [THEN] Error that general journal template should be recurring is shown
        Assert.ExpectedError(ReverseDateCalcRecurringTypeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReversePostingDateFFixedRecurringMethod()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Validate "Reverse Date Calculation" for recurring journal with "F  Fixed" recurring method line leads to the error
        Initialize();

        // [GIVEN] Recurring Gen. Journal Line, recurring method = "F  Fixed"
        CreateRecurringGenJnlBatch(GenJournalBatch);
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"F  Fixed", 456.78);

        // [WHEN] Validate "Reverse Date Calculation" for "F  Fixed" recurring method
        Evaluate(GenJournalLine."Reverse Date Calculation", '<2D>');
        asserterror GenJournalLine.Validate("Reverse Date Calculation");

        // [THEN] Error that recurring method cannot be "F  Fixed" is shown
        Assert.ExpectedError(ReverseDateCalcRecurringMethodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReversePostingDateBBalanceRecurringMethod()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Validate "Reverse Date Calculation" for recurring journal with "B  Balance" recurring method line leads to the error
        Initialize();

        // [GIVEN] Recurring Gen. Journal Line, recurring method = "B  Balance"
        CreateRecurringGenJnlBatch(GenJournalBatch);
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"B  Balance", 456.78);

        // [WHEN] Validate "Reverse Date Calculation" for "B  Balance" recurring method
        Evaluate(GenJournalLine."Reverse Date Calculation", '<2D>');
        asserterror GenJournalLine.Validate("Reverse Date Calculation");

        // [THEN] Error that recurring method cannot be "B  Balance" is shown
        Assert.ExpectedError(ReverseDateCalcRecurringMethodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReversePostingDateVVariableRecurringMethod()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 277244] Validate "Reverse Date Calculation" for recurring journal with "V  Variable" recurring method line leads to the error
        Initialize();

        // [GIVEN] Recurring Gen. Journal Line, recurring method = "V  Variable"
        CreateRecurringGenJnlBatch(GenJournalBatch);
        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"V  Variable", 456.78);

        // [WHEN] Validate "Reverse Date Calculation" for "V  Variable" recurring method
        Evaluate(GenJournalLine."Reverse Date Calculation", '<2D>');
        asserterror GenJournalLine.Validate("Reverse Date Calculation");

        // [THEN] Error that recurring method cannot be "V  Variable" is shown
        Assert.ExpectedError(ReverseDateCalcRecurringMethodErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandlerDefaults')]
    procedure CopyGenJnlParametersOneBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
    begin
        // [SCENARIO 277244] Source/target template and batch should be filled from posted gen jnl. lines if there is the same template/batch
        Initialize();

        // [GIVEN] Two posted gen. jnl. lines "PGJL" from one batch
        CreateGenJnlBatch(GenJournalBatch, true);
        CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Copy posted general journal lines
        FilterFirstPostedGenJnlLine(PostedGenJournalLine, GenJournalBatch);
        LibraryVariableStorage.Enqueue(PostedGenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(PostedGenJournalLine."Journal Batch Name");
        CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] Page controls filled with defaults (verified in CopyGenJournalParametersHandlerDefaults)
        // [THEN] Page "Source Journal Template Name" = "PGJL"."Journal Template Name"
        // [THEN] Page "Source Journal Batch Name" = "PGJL"."Journal Batch Name"
        // [THEN] Page "Target Journal Template" = "PGJL"."Journal Template Name"
        // [THEN] Page "Target Journal Batch" = "PGJL"."Journal Batch Name"
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CopyGenJournalParametersHandlerEmpty')]
    procedure CopyGenJnlParametersTwoBatches()
    var
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        CopyGenJournalMgt: Codeunit "Copy Gen. Journal Mgt.";
        i: Integer;
    begin
        // [SCENARIO 277244] Sourcet template and batch should be filled '(multiple)', targets are empty
        Initialize();

        // [GIVEN] Two posted gen. jnl. lines from two batches
        for i := 1 to 2 do begin
            CreateGenJnlBatch(GenJournalBatch[i], true);
            CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch[i]);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [WHEN] Copy posted general journal lines
        PostedGenJournalLine.SetFilter("Journal Template Name", '%1|%2', GenJournalBatch[1]."Journal Template Name", GenJournalBatch[2]."Journal Template Name");
        PostedGenJournalLine.SetFilter("Journal Batch Name", '%1|%2', GenJournalBatch[1].Name, GenJournalBatch[2].Name);
        PostedGenJournalLine.FindSet();
        CopyGenJournalMgt.CopyToGenJournal(PostedGenJournalLine);

        // [THEN] Page controls filled with following values (verified in CopyGenJournalParametersHandlerEmpty)
        // [THEN] Page "Source Journal Template Name" = '(multiple)'
        // [THEN] Page "Source Journal Batch Name" = '(multiple)'
        // [THEN] Page "Target Journal Template" = empty
        // [THEN] Page "Target Journal Batch" = empty
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('PostedGeneralJournalBatch')]
    procedure PostedGenJournalPageSelectBatchName()
    var
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        PostedGeneralJournal: TestPage "Posted General Journal";
        i: Integer;
    begin
        // [SCENARIO 277244] Select batch name on the posted gen. journal page, records should be filtered accordingly
        Initialize();

        // [GIVEN] Two posted gen. jnl. lines from two batches: "B1" and "B2"
        for i := 1 to 2 do begin
            CreateGenJnlBatch(GenJournalBatch[i], true);
            CreateGenJnlLineWithDim(GenJournalLine, GenJournalBatch[i]);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [WHEN] Select second batch name on the page
        LibraryVariableStorage.Enqueue(GenJournalBatch[2]."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch[2].Name);
        PostedGeneralJournal.OpenView();
        PostedGeneralJournal.CurrentJnlBatchName.AssistEdit();

        // [THEN] Page "Template Name" = "B2"."Journal Template Name"
        // [THEN] Page "Batch Name" = "B2".Name
        PostedGeneralJournal.CurrentJnlTemplateName.AssertEquals(GenJournalBatch[2]."Journal Template Name");
        PostedGeneralJournal.CurrentJnlBatchName.AssertEquals(GenJournalBatch[2].Name);

        // [THEN] Number of records on the page = 1
        PostedGenJournalLine.SetFilter("Journal Template Name", PostedGeneralJournal.Filter.GetFilter("Journal Template Name"));
        PostedGenJournalLine.SetFilter("Journal Batch Name", PostedGeneralJournal.Filter.GetFilter("Journal Batch Name"));
        Assert.RecordCount(PostedGenJournalLine, 1);
        PostedGenJournalLine.FindFirst();
        PostedGeneralJournal.First();
        PostedGeneralJournal."Account No.".AssertEquals(PostedGenJournalLine."Account No.");
        Assert.IsFalse(PostedGeneralJournal.Next(), 'Wrong number of filtered entries.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchCopyToPostedGenJnlLineTrue_UT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 400398] "Copy to Posted Jnl. Lines" = true in gen. journal batch when create new batch from template with "Copy to Posted Jnl. Lines" = true
        Initialize();

        // [GIVEN] Gen. journal template "Copy to Posted Jnl. Lines" = true
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate."Copy to Posted Jnl. Lines" := true;
        GenJournalTemplate.Modify();

        // [WHEN] Create new gen. journal batch (SetupNewBatch procedure called from OnNewRecord of "General Journal Batches" page)
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.SetupNewBatch();

        // [THEN] Gen. journal batch "Copy to Posted Jnl. Lines" = true
        GenJournalBatch.TestField("Copy to Posted Jnl. Lines");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlBatchCopyToPostedGenJnlLineFalse_UT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [SCENARIO 400398] "Copy to Posted Jnl. Lines" = false in gen. journal batch when create new batch from template with "Copy to Posted Jnl. Lines" = false
        Initialize();

        // [GIVEN] Gen. journal template "Copy to Posted Jnl. Lines" = false
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [WHEN] Create new gen. journal batch (SetupNewBatch procedure called from OnNewRecord of "General Journal Batches" page)
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.SetupNewBatch();

        // [THEN] Gen. journal batch "Copy to Posted Jnl. Lines" = false
        GenJournalBatch.TestField("Copy to Posted Jnl. Lines", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLinkPostedOnPostedGenJournalLine()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        Link: Text;
    begin
        // [SCENARIO 452729] After posting General Journal Lines a link from a line that just got posted is automatically attached to new lines
        Initialize();

        // [GIVEN] Gen. Journal Batch with enabled "Copy to Posted Jnl. Lines"
        CreateGenJnlBatch(GenJournalBatch, true);

        // [GIVEN]  Gen. Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        // [GIVEN] Record Link for Sales Order with value = "SalesLink"
        Link := CreateRecordLink(GenJournalLine);

        // [WHEN] Post Gen. Journal Batch
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Link on Posted Gen. Journal Line 
        PostedGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PostedGenJournalLine.FindFirst();
        VerifyPostedGenJournalLineLink(PostedGenJournalLine.RecordId, Link)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLinkDeletedOnGenJournalLineAfterPosting()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Link: Text;
    begin
        // [SCENARIO 452729] After posting General Journal Lines a link from a line that just got posted is automatically attached to new lines
        Initialize();

        // [GIVEN] Gen. Journal Batch with enabled "Copy to Posted Jnl. Lines"
        CreateGenJnlBatch(GenJournalBatch, true);

        // [GIVEN]  Gen. Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        // [GIVEN] Record Link for Sales Order with value = "SalesLink"
        Link := CreateRecordLink(GenJournalLine);

        // [WHEN] Post Gen. Journal Batch
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [VERIFY] Verify Link on will be deleted after posting gen. journal line
        VerifyGenJournalLineLinkNotFound(GenJournalLine.RecordId)
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch"; CopyToPostedJnlLines: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Copy to Posted Jnl. Lines" := CopyToPostedJnlLines;
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        GenJournalLine."Posting Date" := PostingDate;
        GenJournalLine.Modify(false);
    end;

    local procedure FindPostedGenJournalLine(var PostedGenJournalLine: Record "Posted Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; FirstLine: Boolean)
    begin
        PostedGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        if FirstLine then
            PostedGenJournalLine.FindFirst()
        else
            PostedGenJournalLine.FindLast();
    end;

    local procedure AddGenJournalLineDimension(var GenJournalLine: Record "Gen. Journal Line")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        GenJournalLine.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(GenJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateRecurringGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateRecurringJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; RecurringMethod: Enum "Gen. Journal Recurring Method"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        GenJournalLine.Validate("Recurring Method", RecurringMethod);
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);
    end;

    local procedure FindGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.FindSet();
    end;

    local procedure CreateBalancedRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        CreateRecurringGenJnlBatch(GenJournalBatch);

        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RF Reversing Fixed", 456.78);
        Evaluate(GenJournalLine."Reverse Date Calculation", '<+5D>');
        GenJournalLine.Modify(true);
        DocNo := GenJournalLine."Document No.";

        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RF Reversing Fixed", -456.78);
        GenJournalLine.Validate("Document No.", DocNo);
        Evaluate(GenJournalLine."Reverse Date Calculation", '<+5D>');
        GenJournalLine.Modify(true);

        FindGenJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    local procedure CreateAllocatedRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        CreateRecurringGenJnlBatch(GenJournalBatch);

        CreateRecurringJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Recurring Method"::"RB Reversing Balance", 0);
        Evaluate(GenJournalLine."Reverse Date Calculation", '<+5D>');
        GenJournalLine.Modify(true);
        CreateGLAccountNoBalance(GenJournalLine."Account No.");

        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJnlAllocation.Validate("Allocation %", 100);
        GenJnlAllocation.Modify(true);

        FindGenJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
    end;

    local procedure CreateGLAccountNoBalance(GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlBatch(GenJournalBatch, false);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJnlLineWithDim(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 123.45);
        AddGenJournalLineDimension(GenJournalLine);
    end;

    local procedure FilterFirstPostedGenJnlLine(var PostedGenJournalLine: Record "Posted Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        PostedGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PostedGenJournalLine.SetRange(Indentation, 0);
        PostedGenJournalLine.FindSet();
    end;

    local procedure QueueCopyParameters(GenJournalBatch: Record "Gen. Journal Batch"; ReverseSign: Boolean)
    begin
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(ReverseSign);
    end;

    local procedure VerifyPostedGenJnlLine(GenJournalLine: Record "Gen. Journal Line")
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        FindPostedGenJournalLine(PostedGenJournalLine, GenJournalBatch, false);

        PostedGenJournalLine.TestField("G/L Register No.");
        PostedGenJournalLine.TestField("Dimension Set ID");

        Assert.AreEqual(GenJournalLine."Document Type", PostedGenJournalLine."Document Type", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Document No.", PostedGenJournalLine."Document No.", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Document Date", PostedGenJournalLine."Document Date", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Posting Date", PostedGenJournalLine."Posting Date", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Account Type", PostedGenJournalLine."Account Type", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Account No.", PostedGenJournalLine."Account No.", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Bal. Account Type", PostedGenJournalLine."Bal. Account Type", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Bal. Account No.", PostedGenJournalLine."Bal. Account No.", PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine.Amount, PostedGenJournalLine.Amount, PostedGenJournalLineErr);
        Assert.AreEqual(GenJournalLine."Dimension Set ID", PostedGenJournalLine."Dimension Set ID", PostedGenJournalLineErr);
    end;

    local procedure VerifyCopiedGenJnlLine(SrcGenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; ReverseSign: Boolean)
    var
        DstGenJournalLine: Record "Gen. Journal Line";
    begin
        DstGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        DstGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        DstGenJournalLine.SetFilter("Account No.", '<>''''');
        DstGenJournalLine.FindFirst();

        DstGenJournalLine.TestField("Dimension Set ID");

        Assert.AreEqual(SrcGenJournalLine."Document No.", DstGenJournalLine."Document No.", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Document Date", DstGenJournalLine."Document Date", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Posting Date", DstGenJournalLine."Posting Date", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Account Type", DstGenJournalLine."Account Type", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Account No.", DstGenJournalLine."Account No.", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Bal. Account Type", DstGenJournalLine."Bal. Account Type", GenJournalLineErr);
        Assert.AreEqual(SrcGenJournalLine."Bal. Account No.", DstGenJournalLine."Bal. Account No.", GenJournalLineErr);
        if ReverseSign then begin
            Assert.AreEqual(DstGenJournalLine."Document Type", DstGenJournalLine."Document Type"::" ", GenJournalLineErr);
            Assert.AreEqual(-SrcGenJournalLine.Amount, DstGenJournalLine.Amount, GenJournalLineErr)
        end else begin
            Assert.AreEqual(DstGenJournalLine."Document Type", SrcGenJournalLine."Document Type", GenJournalLineErr);
            Assert.AreEqual(SrcGenJournalLine.Amount, DstGenJournalLine.Amount, GenJournalLineErr);
        end;
        Assert.AreEqual(SrcGenJournalLine."Dimension Set ID", DstGenJournalLine."Dimension Set ID", GenJournalLineErr);
    end;

    local procedure VerifyPostedRecurringGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; Days: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GLEntry.SetRange("Posting Date", WorkDate() + Days);
        Assert.RecordCount(GLEntry, 2);
    end;

    local procedure VerifyCopiedGenJnlLines(SrcGenJournalBatch: Record "Gen. Journal Batch"; TargetGenJournalBatch: Record "Gen. Journal Batch"; RecordCount: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", TargetGenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", TargetGenJournalBatch.Name);
        Assert.RecordCount(GenJournalLine, RecordCount);

        PostedGenJournalLine.SetRange("Journal Template Name", SrcGenJournalBatch."Journal Template Name");
        PostedGenJournalLine.SetRange("Journal Batch Name", SrcGenJournalBatch.Name);
        if PostedGenJournalLine.FindSet() then
            repeat
                GenJournalLine.SetRange("Account No.", PostedGenJournalLine."Account No.");
                Assert.RecordCount(GenJournalLine, 1);
            until PostedGenJournalLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyGenJournalParametersHandler(var CopyGenJournalParameters: TestPage "Copy Gen. Journal Parameters")
    begin
        CopyGenJournalParameters."Journal Template Name".SetValue(LibraryVariableStorage.DequeueText());
        CopyGenJournalParameters."Journal Batch Name".SetValue(LibraryVariableStorage.DequeueText());
        CopyGenJournalParameters."Reverse Sign".SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyGenJournalParameters.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyGenJournalParametersHandlerDefaults(var CopyGenJournalParameters: TestPage "Copy Gen. Journal Parameters")
    var
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
    begin
        JournalTemplateName := LibraryVariableStorage.DequeueText();
        JournalBatchName := LibraryVariableStorage.DequeueText();

        CopyGenJournalParameters.SourceJnlTemplateName.AssertEquals(JournalTemplateName);
        CopyGenJournalParameters.SourceJnlBatchName.AssertEquals(JournalBatchName);
        CopyGenJournalParameters."Journal Template Name".AssertEquals(JournalTemplateName);
        CopyGenJournalParameters."Journal Batch Name".AssertEquals(JournalBatchName);
        CopyGenJournalParameters.Cancel().Invoke();
    end;

    local procedure CreateRecordLink(SourceRecord: Variant): Text[250]
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceRecord);
        RecRef.AddLink(LibraryUtility.GenerateGUID());
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst();
        exit(RecordLink.URL1);
    end;

    local procedure VerifyPostedGenJournalLineLink(RecordId: RecordId; Link: Text)
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.SetRange("Record ID", RecordId);
        RecordLink.FindFirst();
        Assert.AreEqual(Link, RecordLink.URL1, PostedGenJournalLineLinkErr);
    end;

    local procedure VerifyGenJournalLineLinkNotFound(RecordId: RecordId)
    var
        RecordLink: Record "Record Link";
    begin
        RecordLink.SetRange("Record ID", RecordId);
        asserterror RecordLink.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyGenJournalParametersHandlerEmpty(var CopyGenJournalParameters: TestPage "Copy Gen. Journal Parameters")
    begin
        CopyGenJournalParameters.SourceJnlTemplateName.AssertEquals('(multiple)');
        CopyGenJournalParameters.SourceJnlBatchName.AssertEquals('(multiple)');
        CopyGenJournalParameters."Journal Template Name".AssertEquals('');
        CopyGenJournalParameters."Journal Batch Name".AssertEquals('');
        CopyGenJournalParameters.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedGeneralJournalBatch(var PostedGeneralJournalBatch: TestPage "Posted General Journal Batch")
    var
        PostedGenJournalBatch: Record "Posted Gen. Journal Batch";
    begin
        PostedGenJournalBatch.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());
        PostedGeneralJournalBatch.GoToRecord(PostedGenJournalBatch);
        PostedGeneralJournalBatch.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}