codeunit 134252 "Match Bank Reconciliation - UT"
{
    Permissions = TableData "Bank Account Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [Match] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        isInitialized: Boolean;
        MatchSummaryMsg: Label '%1 reconciliation lines out of %2 are matched.', Comment = '%1 = Matched lines count, %2 = Total lines count';
        WrongValueOfFieldErr: Label 'Wrong value of field.';
        MatchedManuallyTxt: Label 'This statement line was matched manually.';

    [Test]
    [HandlerFunctions('MatchSummaryMsgHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesFullMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(4);
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchSummaryMsgHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesMatchDetails()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PaymentMatchingDetails: Record "Payment Matching Details";
        DummyBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(4);
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", ExpectedMatchedLineNo);
        Assert.IsTrue(PaymentMatchingDetails.FindFirst(), '');
        Assert.IsTrue(PaymentMatchingDetails.Message.IndexOf(DummyBankAccountLedgerEntry.FieldCaption("Remaining Amount")) > 0, '');
        Assert.IsTrue(PaymentMatchingDetails.Message.IndexOf(DummyBankAccountLedgerEntry.FieldCaption("Posting Date")) > 0, '');
        Assert.IsTrue(PaymentMatchingDetails.Message.IndexOf(DummyBankAccountLedgerEntry.FieldCaption(Description)) > 0, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDesc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDocNoVsDesc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), DocumentNo, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesNoDate()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, 0D, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', -Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDateRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankEntries: Report "Match Bank Entries";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        DateRange: Integer;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        DateRange := LibraryRandom.RandIntInRange(2, 10);

        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation,
            PostingDate - LibraryRandom.RandInt(DateRange), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate + DateRange + LibraryRandom.RandInt(10), Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(DateRange);
        Commit();
        MatchBankEntries.UseRequestPage(true);
        MatchBankEntries.SetTableView(BankAccReconciliation);
        REPORT.Run(REPORT::"Match Bank Entries", true, false, BankAccReconciliation);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDateVsRange()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankEntries: Report "Match Bank Entries";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        DateRange: Integer;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        DateRange := LibraryRandom.RandIntInRange(2, 10);

        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation,
          PostingDate + LibraryRandom.RandInt(DateRange), Description, '', Amount);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, WorkDate(), '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        LibraryVariableStorage.Enqueue(DateRange);
        Commit();
        MatchBankEntries.UseRequestPage(true);
        MatchBankEntries.SetTableView(BankAccReconciliation);
        REPORT.Run(REPORT::"Match Bank Entries", true, false, BankAccReconciliation);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDescDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesAmtVsDocNoDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDocNoVsDescDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OneBankEntryMoreRecLinesDescVsDesc2()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', DocumentNo, Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineFullMatch()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, WorkDate(), DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, WorkDate(), 'WRONG DOC NO', '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineAmtVsDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineAmtVsDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - LibraryRandom.RandDec(100, 2), '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineDocNoVsDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure MoreBankEntriesOneRecLineDocNoVsExtDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, 'WRONG DOC NO', DocumentNo, Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, DocumentNo, '', Amount);

        // Exercise.
        BankAccReconciliation.MatchSingle(0);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultipleBankRec()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliation1: Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
        AdditionalLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation,
            PostingDate, Description, '', Amount);
        CreateBankAccRec(BankAccReconciliation1, BankAccountNo,
          LibraryUtility.GenerateRandomCode(BankAccReconciliation1.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation"));
        AdditionalLineNo := CreateBankAccRecLine(BankAccReconciliation1, PostingDate, Description, '', Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(0);
        Commit();
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.MatchAutomatically.Invoke();

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
        asserterror VerifyOneToOneMatch(BankAccReconciliation1, AdditionalLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManyToOneIsSupported()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', 2 * Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        BankAccountLedgerEntry.Get(TempBankAccountLedgerEntry."Entry No.");
        VerifyManyToOneMatch(BankAccountLedgerEntry, 2, 2 * Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchManuallyMatchDetailsOneToOne()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedEntryNo: Integer;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", ExpectedMatchedLineNo);
        Assert.IsTrue(PaymentMatchingDetails.FindFirst(), '');
        Assert.IsTrue(PaymentMatchingDetails.Message.IndexOf(MatchedManuallyTxt) = 1, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchManuallyMatchDetailsManyToOne()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedEntryNo: Integer;
        PaymentMatchDetailsCount: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', 2 * Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        BankAccountLedgerEntry.Get(TempBankAccountLedgerEntry."Entry No.");
        VerifyManyToOneMatch(BankAccountLedgerEntry, 2, 2 * Amount);

        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");

        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", ExpectedMatchedEntryNo);
        if BankAccRecMatchBuffer.FindSet() then
            repeat
                PaymentMatchingDetails.SetRange("Statement Line No.", BankAccRecMatchBuffer."Statement Line No.");
                Assert.IsTrue(PaymentMatchingDetails.FindFirst(), '');
                Assert.IsTrue(PaymentMatchingDetails.Message.IndexOf(MatchedManuallyTxt) = 1, '');
                PaymentMatchDetailsCount += 1;
            until BankAccRecMatchBuffer.Next() = 0;

        Assert.AreEqual(PaymentMatchDetailsCount, 2, 'Wrong number of payment matching details');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneToManyPartialBRL()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '',
            2 * Amount - LibraryRandom.RandDec(100, 2));

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 2, 2 * Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneToManyPartialBLE()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        Delta: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        Delta := LibraryRandom.RandDec(100, 2);
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount - Delta, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);

        // Exercise.
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 2, 2 * Amount - Delta);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchOneToMany()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Exercise.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 0, 0);
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", TempBankAccReconciliationLine."Statement Line No.");
        Assert.IsTrue(PaymentMatchingDetails.IsEmpty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchOneToManyStatementLineDeleted()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Delete matched statement line
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Line No.", ExpectedMatchedLineNo);
        if not BankAccReconciliationLine.FindFirst() then
            BankAccReconciliationLine.Delete();

        // Exercise.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 0, 0);
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        PaymentMatchingDetails.SetRange("Statement Line No.", TempBankAccReconciliationLine."Statement Line No.");
        Assert.IsTrue(PaymentMatchingDetails.IsEmpty(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchFromBLE()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', 2 * Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Exercise.
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        TempBankAccountLedgerEntry.FindLast();
        TempBankAccountLedgerEntry.Delete();
        TempBankAccReconciliationLine.DeleteAll();
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        VerifyOneToManyMatch(BankAccReconciliation, ExpectedMatchedLineNo, 1, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveMatchManyToOne()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        PaymentMatchingDetails: Record "Payment Matching Details";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', 2 * Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
        BankAccountLedgerEntry.Get(ExpectedMatchedEntryNo);
        VerifyManyToOneMatch(BankAccountLedgerEntry, 2, 2 * Amount);

        // Exercise.
        MatchBankRecLines.RemoveMatch(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);

        // Verify.
        BankAccountLedgerEntry.Get(ExpectedMatchedEntryNo);
        Assert.AreEqual(0, BankAccountLedgerEntry."Statement Line No.", 'Wrong Statement Line No.');
        PaymentMatchingDetails.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        PaymentMatchingDetails.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        PaymentMatchingDetails.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        repeat
            BankAccReconciliationLine.GetBySystemId(TempBankAccReconciliationLine.SystemId);
            Assert.AreEqual(0, BankAccReconciliationLine."Applied Entries", 'Applied entries should be 0');
            Assert.AreEqual(0, BankAccReconciliationLine."Applied Amount", 'Applied amount should be  0');
            PaymentMatchingDetails.SetRange("Statement Line No.", TempBankAccReconciliationLine."Statement Line No.");
            Assert.IsTrue(PaymentMatchingDetails.IsEmpty(), '');
        until TempBankAccReconciliationLine.Next() = 0;

        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", ExpectedMatchedEntryNo);
        Assert.IsTrue(BankAccRecMatchBuffer.IsEmpty(), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,BankStatementPagePostHandler')]
    [Scope('OnPrem')]
    procedure PostMatchManyToOne()
    var
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
        TempBankAccountLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        ExpectedMatchedEntryNo: Integer;
    begin
        Initialize();

        // Setup.
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', 2 * Amount, Description);
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        AddBankRecLinesToTemp(TempBankAccReconciliationLine, BankAccReconciliation);
        AddBankEntriesToTemp(TempBankAccountLedgerEntry, BankAccountNo);
        MatchBankRecLines.MatchManually(TempBankAccReconciliationLine, TempBankAccountLedgerEntry);
        BankAccountLedgerEntry.Get(ExpectedMatchedEntryNo);
        VerifyManyToOneMatch(BankAccountLedgerEntry, 2, 2 * Amount);

        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);
        BankAccReconciliationPage.StatementEndingBalance.SetValue(BankAccReconciliationPage.StmtLine.TotalBalance.AsDecimal());
        BankAccReconciliationPage.Post.Invoke();
        VerifyPosting(BankAccReconciliation, 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTFieldsBankAccReconciliationLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        FirstValue: Text[250];
        SecondValue: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375536] Fields "Related-Party Name" and "Related-Party Bank Acc. No." of "Bank Acc. Reconciliation Line" should have length of 250 and 100 respectively
        Initialize();

        // [GIVEN] Record of "Bank Acc. Reconciliation Line" - "BACL"
        BankAccReconciliationLine.Init();
        // [GIVEN] Length of string "X" = 250
        FirstValue := PadStr('', 250, '0');
        // [GIVEN] Length of string "Y" = 100
        SecondValue := PadStr('', 100, '0');

        // [WHEN] Validate "BACL"."Related-Party Name" with string "X", "BACL"."Related-Party Bank Acc. No." with string "Y"
        BankAccReconciliationLine.Validate("Related-Party Name", FirstValue);
        BankAccReconciliationLine.Validate("Related-Party Bank Acc. No.", SecondValue);

        // [THEN] Value of "BACL"."Related-Party Name" = "X"
        Assert.AreEqual(FirstValue, BankAccReconciliationLine."Related-Party Name", WrongValueOfFieldErr);
        // [THEN] Value of "BACL"."Related-Party Bank Acc. No." = "Y"
        Assert.AreEqual(SecondValue, BankAccReconciliationLine."Related-Party Bank Acc. No.", WrongValueOfFieldErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTFieldsPostedPaymentReconLine()
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        StringValue: Text[250];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 375536] Field "Related-Party Name" of "Posted Payment Recon. Line" should has length of 250
        Initialize();

        // [GIVEN] Record of "Posted Payment Recon. Line" - "PPRL"
        PostedPaymentReconLine.Init();
        // [GIVEN] Length of string "X" = 250
        StringValue := PadStr('', 250, '0');

        // [WHEN] Validate "PPRL"."Related-Party Name" with string "X"
        PostedPaymentReconLine.Validate("Related-Party Name", StringValue);

        // [THEN] Value of "PPRL"."Related-Party Name" = "X"
        Assert.AreEqual(StringValue, PostedPaymentReconLine."Related-Party Name", WrongValueOfFieldErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateAppliesToID()
    var
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [SCENARIO 198751] "Applies-to ID" must be unique for each Bank Account Reconciliation Line
        DummyBankAccReconciliationLine."Bank Account No." := 'BANK';
        DummyBankAccReconciliationLine."Statement No." := 'STATEMENT_0000012345';
        DummyBankAccReconciliationLine."Statement Line No." := 1234567890;
        Assert.AreEqual(
          'BANK-STATEMENT_0000012345-1234567890',
          DummyBankAccReconciliationLine.GetAppliesToID(),
          'Wrong BankAccReconciliationLine.GenerateAppliesToID() return result');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountWithSpecialChar()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        ResultDate: Date;
    begin
        // [FEATURE] [Special Character]
        // [SCENARIO 398533] Stan call bank account reconciliation when bank account's number contains special character like '('
        Initialize();

        BankAccount.Init();
        BankAccount.Validate("No.", StrSubstNo('%1()', LibraryUtility.GenerateGUID()));
        BankAccount.Insert(true);

        CreateBankAccRec(BankAccReconciliation, BankAccount."No.", LibraryUtility.GenerateGUID());

        ResultDate := BankAccReconciliation.MatchCandidateFilterDate();

        Assert.AreEqual(BankAccReconciliation."Statement Date", ResultDate, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DontAcceptRandomDigitsOrderAsMatchDocNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        GibberishText: Text[50];
        DocumentNoAsInt: Integer;
        Amount: Decimal;
        BankAccReconciliationLineNo: Integer;
    begin
        //[SCENARIO 458926] Bank Acc Reconciliation Auto-match doesn't consider partial substrings of lower length in random orders as matching DocNo -> Desc
        Initialize();

        // [GIVEN] Prepare data for Amount, Description and DocumentNo
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        GenerateNonMatchingNumberAndText(DocumentNoAsInt, GibberishText);

        // [GIVEN] Bank Acc Ledger Enrty exists with DocumentNo = "123456"
        DocumentNo := Format(DocumentNoAsInt);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, '');

        // [GIVEN] Bank Account Reconcilition for this bank is created
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);

        // [GIVEN] Create a Bank Acc Reconciliation Line with Description = "xx56yy34zz12", Amount not matching
        BankAccReconciliationLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, GibberishText, '', 2 * Amount);

        // [WHEN] Executing automatch for Bank Acc Reconciliation
        BankAccReconciliation.MatchSingle(0);

        // [THEN] No match is produced
        VerifyNoMatch(BankAccReconciliation, BankAccReconciliationLineNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DontAcceptRandomDigitsOrderAsMatchDesc()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        GibberishText: Text[50];
        DocumentNoAsInt: Integer;
        Amount: Decimal;
        BankAccReconciliationLineNo: Integer;
    begin
        //[SCENARIO 458926] Bank Acc Reconciliation Auto-match doesn't consider partial substrings of lower length in random orders as matching Desc -> Desc
        Initialize();

        // [GIVEN] Prepare data for Amount, Description and DocumentNo
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        GenerateNonMatchingNumberAndText(DocumentNoAsInt, GibberishText);

        // [GIVEN] Bank Acc Ledger Enrty exists with Desc = "123456"
        DocumentNo := Format(DocumentNoAsInt);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, DocumentNo);

        // [GIVEN] Bank Account Reconcilition for this bank is created
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);

        // [GIVEN] Create a Bank Acc Reconciliation Line with Description = "xx56yy34zz12", Amount not matching
        BankAccReconciliationLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, GibberishText, '', 2 * Amount);

        // [WHEN] Executing automatch for Bank Acc Reconciliation
        BankAccReconciliation.MatchSingle(0);

        // [THEN] No match is produced
        VerifyNoMatch(BankAccReconciliation, BankAccReconciliationLineNo);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBankEntryMatchToExactBankAccReconciliationLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        MatchBankEntries: Report "Match Bank Entries";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        RandomDescText: Text;
        Amount: Decimal;
        DateRange: Integer;
        ExpectedMatchedLineNo: Integer;
        ExpectedMatchedEntryNo: Integer;
    begin
        // [SCENARIO 460336] Amount is matched incorrectly when using Bank reconciliation auto-matching 
        // [GIVEN] Prepare data for Posting Date, Amount, DocumentNo, and Description
        Initialize();
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        DateRange := LibraryRandom.RandIntInRange(2, 10);
        RandomDescText := LibraryUtility.GenerateRandomAlphabeticText(2, 0);
        // [GIVEN] Bank Acc Ledger Enrty exists with Desc = "123456"
        Description := RandomDescText + ' ' + Description;
        // [GIVEN] Bank Account Reconcilition for this bank is created
        ExpectedMatchedEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, Description);
        // [GIVEN] Create a Bank Acc Reconciliation Line with differen Descriptions, with matching amount
        CreateBankAccRec(BankAccReconciliation, BankAccountNo, StatementNo);
        CreateBankAccRecLine(BankAccReconciliation, PostingDate, RandomDescText, '', Amount);
        // [GIVEN] Exercise, run Match Bank Entries report for Bank Account Reconciliation
        ExpectedMatchedLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, Description, '', Amount);
        LibraryVariableStorage.Enqueue(DateRange);
        Commit();
        MatchBankEntries.UseRequestPage(true);
        MatchBankEntries.SetTableView(BankAccReconciliation);
        // [VERIFY] Verify: Bank Acc Ledger Entry with expected Bank Reconciliation Line
        REPORT.Run(REPORT::"Match Bank Entries", true, false, BankAccReconciliation);
        VerifyOneToOneMatch(BankAccReconciliation, ExpectedMatchedLineNo, ExpectedMatchedEntryNo, Amount);
    end;

    [Test]
    [HandlerFunctions('MatchRecLinesReqPageHandler,MessageHandler')]
    procedure MatchToSimilarLinesShouldBeKept()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
        PostingDate: Date;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Description: Text[50];
        Amount: Decimal;
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
        FirstLineNo: Integer;
        SecondLineNo: Integer;
    begin
        // [SCENARIO]
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);
        BankAccountNo := BankAccount."No.";
        StatementNo := BankAccReconciliation."Statement No.";
        FirstEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, 'ABCDE');
        SecondEntryNo := CreateBankAccLedgerEntry(BankAccountNo, PostingDate, DocumentNo, '', Amount, 'ZYXWV');
        FirstLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, '', '', Amount);
        SecondLineNo := CreateBankAccRecLine(BankAccReconciliation, PostingDate, 'ABCDE', '', Amount);
        LibraryVariableStorage.Enqueue(0);
        Commit();
        Report.Run(Report::"Match Bank Entries", true, false, BankAccReconciliation);
        BankAccountLedgerEntry.Get(FirstEntryNo);
        Assert.AreEqual(SecondLineNo, BankAccountLedgerEntry."Statement Line No.", 'First BLE should be matched with the second bank rec. line since it''s a high confidence match, they match in description, date, and amount');
        BankAccountLedgerEntry.Get(SecondEntryNo);
        Assert.AreEqual(FirstLineNo, BankAccountLedgerEntry."Statement Line No.", 'Second BLE should be matched with the first bank rec. line since the match is acceptable (same amount although not same description) ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterNotUpdatingWhenMovingFromOneBankAccReconRecordToAnother()
    var
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        FilteredPostingDate: array[2] of Text;
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        PostingDate: Date;
        Description: Text[50];
    begin
        // [SCENARIO 474655] The filter for the Bank Account Ledger Entries of the Bank Acc. Reconciliation page is not updated when going from one Bank Acc. Rec to the next one using the arrows
        Initialize();

        // [GIVEN] Setup: Create input data e.g. Posting Date, Bank account No., Statement No., Doc no., Description, and Amount
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);

        // [GIVEN] Create different Bank Account Ledger Entries
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate + 1, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate + 10, DocumentNo, '', Amount, Description);

        // [GIVEN] Create a Bank Acc Reconciliation with Different Statement Date
        CreateBankAccRecWithStatementDate(BankAccReconciliation[1], BankAccountNo, StatementNo, PostingDate);
        CreateBankAccRecWithStatementDate(BankAccReconciliation[1], BankAccountNo, StatementNo + '1', PostingDate + 10);

        // [THEN] Open Bank Account Reconcialiation Page and move to next record.
        BankAccReconciliationPage.OpenView();
        BankAccReconciliation[2].SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliation[2].FindSet();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation[2]);
        FilteredPostingDate[1] := BankAccReconciliationPage.ApplyBankLedgerEntries.Filter.GetFilter("Posting Date");
        BankAccReconciliationPage.Next();
        FilteredPostingDate[2] := BankAccReconciliationPage.ApplyBankLedgerEntries.Filter.GetFilter("Posting Date");

        // [VERIFY] Verify: Both filters are different
        Assert.IsTrue(FilteredPostingDate[1] <> FilteredPostingDate[2], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFilterWorkingOnApplyBankLedgerEntriesSubFormOnBankAccReconciliationPage()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
        PostingDate: Date;
        Description: Text[50];
    begin
        // [SCENARIO 480247] Filter is not working on the date field of the Bank account ledger Entries in the Bank account reconciliation page.
        Initialize();

        // [GIVEN] Setup: Create input data e.g. Posting Date, Bank account No., Statement No., Doc no., Description, and Amount
        CreateInputData(PostingDate, BankAccountNo, StatementNo, DocumentNo, Description, Amount);

        // [GIVEN] Create 2 Bank Account Ledger Entries with different Posting Date
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate + 1, DocumentNo, '', Amount, Description);
        CreateBankAccLedgerEntry(BankAccountNo, PostingDate + 10, DocumentNo, '', Amount, Description);

        // [GIVEN] Create a Bank Acc Reconciliation with Statement Date
        CreateBankAccRecWithStatementDate(BankAccReconciliation, BankAccountNo, StatementNo, PostingDate + 10);

        // [THEN] Open Bank Account Reconcialiation Page
        BankAccReconciliationPage.OpenView();
        BankAccReconciliation.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliation.FindSet();
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);

        // [VERIFY] Last Bank Account Ledger Entry Posting Date is Equals to the Second Bank Account Ledger Entry Posting Date
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.ApplyBankLedgerEntries."Posting Date".AssertEquals(PostingDate + 10);

        // [WHEN] Set Different Posting Date Filter to Get the First Bank Account Ledger Entry
        BankAccountLedgerEntry.SetRange("Posting Date", 0D, PostingDate + 1);
        BankAccReconciliationPage.ApplyBankLedgerEntries.Filter.SetFilter("Posting Date", Format(BankAccountLedgerEntry.GetFilter("Posting Date")));

        // [VERIFY] Last Bank Account Ledger Entry Posting Date is Equals to the First Bank Account Ledger Entry Posting Date
        BankAccReconciliationPage.ApplyBankLedgerEntries.Last();
        BankAccReconciliationPage.ApplyBankLedgerEntries."Posting Date".AssertEquals(PostingDate + 1);
    end;

    local procedure Initialize()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Match Bank Reconciliation - UT");
        LibraryApplicationArea.EnableFoundationSetup();
        BankAccReconciliationLine.DeleteAll();
        BankAccReconciliation.DeleteAll();
        BankAccountLedgerEntry.DeleteAll();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Match Bank Reconciliation - UT");

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryVariableStorage.Clear();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Match Bank Reconciliation - UT");
    end;

    local procedure CreateBankAccountWithNo(var BankAccount: Record "Bank Account"; BankAccountNo: Code[20])
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankContUpdate: Codeunit "BankCont-Update";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccount.Init();
        BankAccount.Validate("No.", BankAccountNo);
        BankAccount.Validate(Name, BankAccount."No.");  // Validating No. as Name because value is not important.
        BankAccount.IBAN := LibraryUtility.GenerateGUID();
        BankAccount.Insert(true);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        BankContUpdate.OnModify(BankAccount);
    end;

    local procedure AddBankRecLinesToTemp(var TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        TempBankAccReconciliationLine.Reset();
        TempBankAccReconciliationLine.DeleteAll();
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindSet() then
            repeat
                TempBankAccReconciliationLine := BankAccReconciliationLine;
                TempBankAccReconciliationLine.Insert();
            until BankAccReconciliationLine.Next() = 0;
    end;

    local procedure AddBankEntriesToTemp(var TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary; BankAccountNo: Code[20])
    var
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        TempBankAccLedgerEntry.Reset();
        TempBankAccLedgerEntry.DeleteAll();
        BankAccLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        if BankAccLedgerEntry.FindSet() then
            repeat
                TempBankAccLedgerEntry := BankAccLedgerEntry;
                TempBankAccLedgerEntry.Insert();
            until BankAccLedgerEntry.Next() = 0;
    end;

    local procedure CreateInputData(var PostingDate: Date; var BankAccountNo: Code[20]; var StatementNo: Code[20]; var DocumentNo: Code[20]; var Description: Text[50]; var Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        Amount := -LibraryRandom.RandDec(1000, 2);
        PostingDate := WorkDate() - LibraryRandom.RandInt(10);
        BankAccountNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Bank Account No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        StatementNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Statement No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        DocumentNo := LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."),
            DATABASE::"Bank Acc. Reconciliation Line");
        Description := CopyStr(CreateGuid(), 1, 50);
        if not BankAccount.Get(BankAccountNo) then
            CreateBankAccountWithNo(BankAccount, BankAccountNo);
    end;

    local procedure CreateBankAccRec(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Bank Account No." := BankAccountNo;
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccReconciliation."Statement Date" := WorkDate();
        BankAccReconciliation.Insert();
    end;

    local procedure CreateBankAccRecLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; TransactionDate: Date; Description: Text[50]; PayerInfo: Text[50]; Amount: Decimal): Integer
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        if BankAccReconciliationLine.FindLast() then;

        BankAccReconciliationLine.Init();
        BankAccReconciliationLine."Bank Account No." := BankAccReconciliation."Bank Account No.";
        BankAccReconciliationLine."Statement Type" := BankAccReconciliation."Statement Type";
        BankAccReconciliationLine."Statement No." := BankAccReconciliation."Statement No.";
        BankAccReconciliationLine."Statement Line No." += 10000;
        BankAccReconciliationLine."Transaction Date" := TransactionDate;
        BankAccReconciliationLine.Description := Description;
        BankAccReconciliationLine."Related-Party Name" := PayerInfo;
        BankAccReconciliationLine."Statement Amount" := Amount;
        BankAccReconciliationLine.Difference := Amount;
        BankAccReconciliationLine.Insert();

        exit(BankAccReconciliationLine."Statement Line No.");
    end;

    local procedure CreateBankAccLedgerEntry(BankAccountNo: Code[20]; PostingDate: Date; DocumentNo: Code[20]; ExtDocNo: Code[35]; Amount: Decimal; Description: Text[50]): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankAccountLedgerEntry.FindLast() then;

        BankAccountLedgerEntry.Init();
        BankAccountLedgerEntry."Entry No." += 1;
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Posting Date" := PostingDate;
        BankAccountLedgerEntry."Document No." := DocumentNo;
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry."Remaining Amount" := Amount;
        BankAccountLedgerEntry.Description := Description;
        BankAccountLedgerEntry."External Document No." := ExtDocNo;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Open;
        BankAccountLedgerEntry.Insert();

        exit(BankAccountLedgerEntry."Entry No.");
    end;

    local procedure GenerateNonMatchingNumberAndText(var Number: Integer; var GeneratedText: Text[50])
    var
        SmallNumber: Integer;
        i: Integer;
        Multiplier: Integer;
    begin
        // This will generate a random number that looks like 12345678 and 'matching' text that looks like 'bb78cc56dd34ee12'
        Multiplier := 1;
        for i := 1 to 4 do begin
            SmallNumber := LibraryRandom.RandIntInRange(10, 99);
            Number := Number + Multiplier * SmallNumber;
            GeneratedText := GeneratedText + LibraryUtility.GenerateRandomAlphabeticText(2, 0) + Format(SmallNumber);
            Multiplier := Multiplier * 100;
        end;
    end;

    local procedure VerifyNoMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);

        BankAccReconciliationLine.TestField("Applied Entries", 0);
    end;

    local procedure VerifyOneToOneMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryNo: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        BankAccountLedgerEntry.Get(ExpBankEntryNo);

        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(1, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');
        Assert.AreEqual(ExpAmount, BankAccountLedgerEntry."Remaining Amount", 'Wrong remaining amt.');
        Assert.AreEqual(BankAccReconciliation."Statement No.", BankAccountLedgerEntry."Statement No.", 'Wrong statement no.');
        Assert.AreEqual(ExpRecLineNo, BankAccountLedgerEntry."Statement Line No.",
          'Wrong statement line no.');

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetFilter("Applied Amount", '<>%1', 0);
        Assert.AreEqual(1, BankAccReconciliationLine.Count, 'Too many matches.');

        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        Assert.AreEqual(1, BankAccountLedgerEntry.Count, 'Too many matches.');
    end;

    local procedure VerifyOneToManyMatch(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpRecLineNo: Integer; ExpBankEntryMatches: Integer; ExpAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliation."Statement Type",
          BankAccReconciliation."Bank Account No.",
          BankAccReconciliation."Statement No.",
          ExpRecLineNo);
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Statement Line No.", ExpRecLineNo);
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(ExpBankEntryMatches, BankAccountLedgerEntry.Count, 'Wrong no of applied entries.');
        Assert.AreEqual(ExpAmount, BankAccReconciliationLine."Applied Amount", 'Wrong applied amt.');
        Assert.AreEqual(ExpBankEntryMatches, BankAccReconciliationLine."Applied Entries", 'Wrong no. of applied entries.');
    end;

    local procedure VerifyManyToOneMatch(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; ExpBankEntryMatches: Integer; ExpAmount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        TotalRecLineAppliedAmount: Decimal;
    begin
        Assert.AreEqual(-1, BankAccountLedgerEntry."Statement Line No.", 'Statement Line No should be set to -1 in a Many-1 matching.');

        BankAccRecMatchBuffer.SetRange("Statement No.", BankAccountLedgerEntry."Statement No.");
        BankAccRecMatchBuffer.SetRange("Bank Account No.", BankAccountLedgerEntry."Bank Account No.");
        BankAccRecMatchBuffer.SetRange("Ledger Entry No.", BankAccountLedgerEntry."Entry No.");
        Assert.AreEqual(ExpBankEntryMatches, BankAccRecMatchBuffer.Count(), 'Wrong no of applied rec lines.');

        if BankAccRecMatchBuffer.FindSet() then
            repeat
                BankAccReconciliationLine.SetRange("Bank Account No.", BankAccRecMatchBuffer."Bank Account No.");
                BankAccReconciliationLine.SetRange("Statement No.", BankAccRecMatchBuffer."Statement No.");
                BankAccReconciliationLine.SetRange("Statement Line No.", BankAccRecMatchBuffer."Statement Line No.");
                if BankAccReconciliationLine.FindFirst() then
                    TotalRecLineAppliedAmount += BankAccReconciliationLine."Applied Amount";
                Assert.AreEqual(1, BankAccReconciliationLine."Applied Entries", 'Wrong Applied Entries amount.');
            until BankAccRecMatchBuffer.Next() = 0;

        Assert.AreEqual(ExpAmount, TotalRecLineAppliedAmount, 'Wrong applied amt.');
    end;

    local procedure VerifyPosting(BankAccReconciliation: Record "Bank Acc. Reconciliation"; ExpEntriesNo: Integer)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccountLedgerEntry.SetRange("Statement Status", BankAccountLedgerEntry."Statement Status"::Closed);
        BankAccountLedgerEntry.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange("Remaining Amount", 0);
        BankAccountLedgerEntry.SetRange(Open, false);
        Assert.AreEqual(ExpEntriesNo, BankAccountLedgerEntry.Count, 'Wrong no of bank entries.');

        BankAccountLedgerEntry.Reset();
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccReconciliation."Statement No.");
        BankAccountLedgerEntry.SetRange(Open, true);
        Assert.IsTrue(BankAccountLedgerEntry.IsEmpty, 'There should be no entries left.');

        asserterror BankAccReconciliation.FindFirst();
    end;

    local procedure CreateBankAccRecWithStatementDate(
        var BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
        StatementNo: Code[20];
        StatementDate: Date)
    begin
        BankAccReconciliation.Init();
        BankAccReconciliation."Bank Account No." := BankAccountNo;
        BankAccReconciliation."Statement No." := StatementNo;
        BankAccReconciliation."Statement Date" := StatementDate;
        BankAccReconciliation.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MatchRecLinesReqPageHandler(var MatchBankAccReconciliation: TestRequestPage "Match Bank Entries")
    var
        DateRange: Variant;
    begin
        LibraryVariableStorage.Dequeue(DateRange);
        MatchBankAccReconciliation.DateRange.SetValue(DateRange);
        MatchBankAccReconciliation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MatchSummaryMsgHandler(Message: Text[1024])
    var
        MatchedLinesCount: Variant;
        TotalLinesCount: Variant;
    begin
        LibraryVariableStorage.Dequeue(MatchedLinesCount);
        LibraryVariableStorage.Dequeue(TotalLinesCount);
        Assert.IsTrue(StrPos(Message, StrSubstNo(MatchSummaryMsg, MatchedLinesCount, TotalLinesCount)) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmOverwriteAutoMatchHandlerDefault(Question: Text; var Reply: Boolean)
    begin
        if Question = 'There are lines in this statement that are already matched with ledger entries.\\ Do you want to overwrite the existing matches?' then
            Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankStatementPagePostHandler(var BankStatement: TestPage "Bank Account Statement")
    begin
        BankStatement.Close();
    end;

}

