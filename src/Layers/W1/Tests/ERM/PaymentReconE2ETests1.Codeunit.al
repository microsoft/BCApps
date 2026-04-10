codeunit 134265 "Payment Recon. E2E Tests 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Reconciliation] [Sales]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;
        OpenBankLedgerEntriesErr: Label 'All bank account ledger entries should be closed after posting the payment reconciliation journal.';
        ClosedBankLedgerEntriesErr: Label 'All bank account ledger entries should be open after posting the payment reconciliation journal.';
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ImportPostedTransactionsQst: Label 'The bank statement contains payments that are already applied, but the related bank account ledger entries are not closed.\\Do you want to include these payments in the import?';
        ValidationErr: Label 'Sum of %1 must be %2 in Report.';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.';
        TableValueWrongErr: Label '%1 must be %2 for %3 %4.', Comment = '%1=field caption;%2=field value;%3=table name caption;%4=field value';
        TableValueMissingErr: Label '%1 %2 does not exist.', Comment = '%1=table name caption;%2=table field name caption';
        AmountWrongErr: Label '%1 must be %2.', Comment = '%1=field name caption;%2=field value';
        ErrorText_Number__Control97CaptionLbl: Label 'Warning!';
        OpenBankStatementPageQst: Label 'Do you want to open the bank account statement?';

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTransactionsAlreadyImported()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        BankAcc: Record "Bank Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        BankStmtFormat: Code[20];
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc, '');

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables();
        OneSaleOnePmt1(BankAccReconciliation[1], BankAcc, TempBlobUTF8);
        OneSaleOnePmt1(BankAccReconciliation[2], BankAcc, TempBlobUTF8);

        OpenPmtReconJnl(BankAccReconciliation[1], PmtReconJnl);
        PmtReconJnl.Post.Invoke();
        VerifyNoLinesImported(BankAccReconciliation[2]);

        OpenPmtReconJnl(BankAccReconciliation[2], PmtReconJnl);
        asserterror PmtReconJnl.Post.Invoke(); // It should not be possible to post
        PmtReconJnl.Close();
        BankAccReconciliation[2].Find();
        BankAccReconciliation[2].Delete(true); // It should be possible to delete the payment reconcilation journal

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
    end;

    [Test]
    [HandlerFunctions('PaymentBankAccountListHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure TestNoTransactionsImported()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        DummyBankAccount, BankAccount : Record "Bank Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        BankStmtFormat: Code[20];
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTFooter(OutStream);

        // Exercise
        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, DummyBankAccount, '');
        CreateBankAcc(BankStmtFormat, BankAccount, '');
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        CreateBankAccReconByImportingStmt(BankAccRecon, TempBlobUTF8, BankAccount);
        Assert.IsFalse(BankAccRecon.Find(), 'No reconciliation should be created because there were no transactions to import');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PaymentBankAccountListHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmtCreateJournalByImportingFile()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        BankStmtFormat: Code[20];
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAccount, '');
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        PmtReconJnl.Trap();
        CreateBankAccReconByImportingStmt(BankAccRecon, TempBlobUTF8, BankAccount);
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtRecJournalsLauncherSingleBankAccRecon()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        BankStmtFormat: Code[20];
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccRecon.SetRange("Statement Type", BankAccRecon."Statement Type"::"Payment Application");
        BankAccRecon.DeleteAll();

        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAccount, '');
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAccount."No.", BankAccRecon."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccRecon);
        PmtReconJnl.Trap();
        CODEUNIT.Run(CODEUNIT::"Pmt. Rec. Journals Launcher");
        PmtReconJnl.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmtRecJournalsLauncherMultipleBankAccRecon()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
        BankStmtFormat: Code[20];
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        BankAccRecon.SetRange("Statement Type", BankAccRecon."Statement Type"::"Payment Application");
        BankAccRecon.DeleteAll();

        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAccount, '');
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAccount."No.", BankAccRecon."Statement Type"::"Payment Application");
        Clear(BankAccRecon);
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAccount."No.", BankAccRecon."Statement Type"::"Payment Application");
        PmtReconciliationJournals.Trap();
        CODEUNIT.Run(CODEUNIT::"Pmt. Rec. Journals Launcher");
        PmtReconciliationJournals.Close();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePrePostedPmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleTwoPmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleTwoPmt(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleTwoPrePostedPmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleTwoPmt(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        LibraryLowerPermissions.SetOutsideO365Scope();
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleTwoPmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry2, PmtReconJnl);
        LibraryLowerPermissions.SetOutsideO365Scope();
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleTwoPrePostedPmt()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyCustLedgEntry(CustLedgEntry2."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoSaleTwoPrePostedPmtNoReconciliation()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.PostPaymentsOnly.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyCustLedgEntry(CustLedgEntry2."Customer No.");
        VerifyBankLedgEntryAmount(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesOpen(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleOnePmt()
    var
        CustLedgEntry: array[2] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleOnePmt(CustLedgEntry, OutStream, 1, 2);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry[1]."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesClosed(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleOnePrePostedPmt()
    var
        CustLedgEntry: array[2] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleOnePmt(CustLedgEntry, OutStream, 1, 2);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry[1], BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry[2], BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry[1]."Customer No.");
        VerifyCustLedgEntry(CustLedgEntry[2]."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesClosed(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmtWithPmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesClosed(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleTwoPmtWithPmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleTwoPmtWithPmtDisc(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleTwoPmtWithPmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry2, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleOnePmtWithPmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleOnePmtWithPmtDisc(CustLedgEntry, CustLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoSaleOnePmtWithPmtDisc2()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleOnePmtWithPmtDisc(CustLedgEntry, CustLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry2, PmtReconJnl);

        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmtWithLateDueDatePmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtDiscDate(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYSaleOnePmtWithLateDueDatePmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneFCYSaleOnePmtWithLateDueDatePmtDisc(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtDiscDate(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYSaleOneFCYPmtWithLateDueDatePmtDisc()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtWithLateDueDatePmtDisc(
          CustLedgEntry, OutStream, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, CustLedgEntry."Currency Code");
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmtWithWrongPmtDiscPct()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtWithWrongPmtDiscPct(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        HandlePmtDiscAmt(CustLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestBankTransfer()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransferAmount: Decimal;
    begin
        Initialize();
        TransferAmount := 100;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        BankTransfer(BankAcc, OutStream, TransferAmount, BankAcc."No." + ' Transfer');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntryAmount(BankAcc."No.", -BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestMultipleBankTransferSameExtDocNo()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransferAmount: Decimal;
        ExtDocNo: Code[35];
    begin
        Initialize();
        TransferAmount := 6 * 100;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        ExtDocNo := LibraryUtility.GenerateGUID();

        WriteCAMTHeader(OutStream, '', 'TEST');
        BankTransfer(BankAcc, OutStream, TransferAmount, ExtDocNo);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 2, ExtDocNo);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 3, ExtDocNo);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 6, ExtDocNo);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntryAmount(BankAcc."No.", -BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestMultipleBankTransferDifferentExtDocNo()
    var
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransferAmount: Decimal;
        ExtDocNo1: Code[35];
        ExtDocNo2: Code[35];
        ExtDocNo3: Code[35];
    begin
        Initialize();
        TransferAmount := -6 * 100;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        ExtDocNo1 := LibraryUtility.GenerateGUID();
        ExtDocNo2 := LibraryUtility.GenerateGUID();
        ExtDocNo3 := LibraryUtility.GenerateGUID();

        WriteCAMTHeader(OutStream, '', 'TEST');
        BankTransfer(BankAcc, OutStream, TransferAmount, StrSubstNo('%1 %2 %3', ExtDocNo1, ExtDocNo2, ExtDocNo3));
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 2, ExtDocNo1);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 3, ExtDocNo2);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount / 6, ExtDocNo3);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntryAmount(BankAcc."No.", -BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestMappedGLAccountPayment()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        GLAccount: Record "G/L Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransactionText: Text[250];
        TransactionAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryERM.CreateGLAccount(GLAccount);
        TransactionText := 'Transfer' + LibraryUtility.GenerateGUID();
        TransactionAmount := 100;
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, WorkDate(), TransactionText, TransactionAmount, '');
        WriteCAMTFooter(OutStream);
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := TransactionText;
        TextToAccountMapping."Debit Acc. No." := GLAccount."No.";
        TextToAccountMapping.Insert();

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPaymentToGLAccount(GLAccount."No.", BankAccRecon."Bank Account No.", TransactionAmount, TransactionText);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestUnMappedGLAccountPayment()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GLAccount: Record "G/L Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TransactionText: Text[250];
        TransactionAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryERM.CreateGLAccount(GLAccount);
        TransactionText := 'Transfer' + LibraryUtility.GenerateGUID();
        TransactionAmount := 100;
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, WorkDate(), TransactionText, TransactionAmount, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPaymentToGLAccount(GLAccount."No.", BankAccRecon."Bank Account No.", TransactionAmount, TransactionText);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestEndToEnd()
    var
        CustLedgEntry: array[20] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        i: Integer;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        CreateUnpaidDocs(OutStream, CustLedgEntry);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        ApplyManually(PmtReconJnl, CustLedgEntry);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        for i := 1 to 14 do
            VerifyCustLedgEntry(CustLedgEntry[i]."Customer No.");

        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestSortingForReview()
    var
        CustLedgEntry: array[20] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        CreateUnpaidDocs(OutStream, CustLedgEntry);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // Add also a "None" line
        PmtReconJnl."Transaction Date".SetValue(CalcDate('<+1Y>', CustLedgEntry[1]."Posting Date"));
        PmtReconJnl."Transaction Text".SetValue('');
        PmtReconJnl."Statement Amount".SetValue(100 * CustLedgEntry[1]."Remaining Amount");

        ApplyAutomatically(PmtReconJnl);

        PmtReconJnl.SortForReviewDescending.Invoke();
        Assert.AreEqual(
          Format(PmtReconJnl."Match Confidence".Value), Format(BankAccReconciliationLine."Match Confidence"::High),
          'Descending was not sorted correctly');

        PmtReconJnl.Last();
        Assert.AreEqual(
          Format(PmtReconJnl."Match Confidence".Value), Format(BankAccReconciliationLine."Match Confidence"::None),
          'Descending was not sorted correctly');

        PmtReconJnl.SortForReviewAscending.Invoke();
        Assert.AreEqual(
          Format(PmtReconJnl."Match Confidence".Value), Format(BankAccReconciliationLine."Match Confidence"::None),
          'Ascending was not sorted correctly');

        PmtReconJnl.Last();
        Assert.AreEqual(
          Format(PmtReconJnl."Match Confidence".Value), Format(BankAccReconciliationLine."Match Confidence"::High),
          'Ascending was not sorted correctly');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestToggleShowNonMatchedLines()
    var
        CustLedgEntry: array[20] of Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        PmtReconJournalOverview: TestPage "Pmt. Recon. Journal Overview";
        OutStream: OutStream;
        MatchedLinesShow: Boolean;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        CreateUnpaidDocs(OutStream, CustLedgEntry);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // Add also a "None" line
        PmtReconJnl."Transaction Date".SetValue(CalcDate('<+1Y>', CustLedgEntry[1]."Posting Date"));
        PmtReconJnl."Transaction Text".SetValue('');
        PmtReconJnl."Statement Amount".SetValue(100 * CustLedgEntry[1]."Remaining Amount");

        ApplyAutomatically(PmtReconJnl);
        PmtReconJnl.Close();

        OpenMiniPmtReconJnl(BankAccRecon, PmtReconJournalOverview);

        // show only unmatched lines
        PmtReconJournalOverview.ShowNonAppliedLines.Invoke();
        PmtReconJournalOverview.First();
        repeat
            Assert.AreNotEqual(PmtReconJournalOverview."Statement Amount".AsDecimal(), PmtReconJournalOverview."Applied Amount".AsDecimal(), '');
        until PmtReconJournalOverview.Next() = false;

        // show all lines
        PmtReconJournalOverview.ShowAllLines.Invoke();
        repeat
            if PmtReconJournalOverview."Statement Amount".AsDecimal() = PmtReconJournalOverview."Applied Amount".AsDecimal() then
                MatchedLinesShow := true;
        until PmtReconJournalOverview.Next() = false;
        Assert.AreEqual(true, MatchedLinesShow, '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestManyToOne()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        MatchConfidence1: Text;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleTwoPmt(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        PmtReconJnl.SortForReviewAscending.Invoke();

        PmtReconJnl.First();
        AccountNo1 := PmtReconJnl."Account No.".Value();
        AccountType1 := PmtReconJnl."Account Type".Value();
        MatchConfidence1 := PmtReconJnl."Match Confidence".Value();

        PmtReconJnl.Next();
        Assert.AreEqual(
          AccountNo1, Format(PmtReconJnl."Account No.".Value), 'Entries not applied correctly. Account No. missmatch.');
        Assert.AreEqual(
          AccountType1, Format(PmtReconJnl."Account Type".Value), 'Entries not applied correctly. Account Type missmatch.');
        Assert.AreEqual(
          MatchConfidence1, Format(PmtReconJnl."Match Confidence".Value), 'Entries not applied correctly. Match confidence missmatch.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestManyToOnePmtAmountBiggerThanRemAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        AppliedAmount: Decimal;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleTwoPmt(CustLedgEntry, OutStream);
        WriteCAMTStmtLine(OutStream, CustLedgEntry."Posting Date", CustLedgEntry."Document No.",
          CustLedgEntry."Remaining Amount" / 3, CustLedgEntry."Currency Code");
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        PmtReconJnl.SortForReviewAscending.Invoke();
        PmtReconJnl.First();
        AccountNo1 := PmtReconJnl."Account No.".Value();
        AccountType1 := PmtReconJnl."Account Type".Value();
        AppliedAmount := PmtReconJnl."Applied Amount".AsDecimal();

        PmtReconJnl.Next();
        if (AccountNo1 = Format(PmtReconJnl."Account No.".Value)) and
           (AccountType1 = Format(PmtReconJnl."Account Type".Value))
        then
            AppliedAmount += PmtReconJnl."Applied Amount".AsDecimal();

        PmtReconJnl.Next();
        if (AccountNo1 = Format(PmtReconJnl."Account No.".Value)) and
           (AccountType1 = Format(PmtReconJnl."Account Type".Value))
        then
            AppliedAmount += PmtReconJnl."Applied Amount".AsDecimal();

        Assert.AreEqual(
          CustLedgEntry."Remaining Amount", AppliedAmount, 'Entries not applied correctly. Missmatch for total applied amount.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestAccountNameWhenApplyingToBankAccountLedgerEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        TotalLinesAmount: Decimal;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Customer.Get(CustLedgEntry."Customer No.");
        BankAccReconciliationLine.LinesExist(BankAccRecon);
        repeat
            Assert.AreEqual(Customer.Name, BankAccReconciliationLine.GetAppliedToName(), '');
            TotalLinesAmount += BankAccReconciliationLine."Statement Amount";
        until BankAccReconciliationLine.Next() = 0;
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + TotalLinesAmount);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePmtExcessiveAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtExcessiveAmount(CustLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        PmtReconJnl.Accept.Invoke();
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntryExcessiveAmount(CustLedgEntry."Customer No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOneSaleOnePrePostedPmtExcessiveAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();

        ExcessiveAmount := 1.23;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtExcessiveAmount(CustLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        asserterror PmtReconJnl.Accept.Invoke();
        Assert.ExpectedError(StrSubstNo(ExcessiveAmountErr, Format(ExcessiveAmount)));
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,TransferDiffToAccountHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferDifferenceToAccount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        DummyGenJournalLine: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtExcessiveAmount(CustLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        PmtReconJnl.First();
        LibraryVariableStorage.Enqueue(DummyGenJournalLine."Account Type"::Customer);
        LibraryVariableStorage.Enqueue(CustLedgEntry."Customer No.");
        PmtReconJnl.TransferDiffToAccount.Invoke();
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PmtReconJnl.Post.Invoke();

        // Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntryExcessiveAmount(CustLedgEntry."Customer No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,TransferDiffToAccountHandler')]
    [Scope('OnPrem')]
    procedure TestDeleteSplitDifferenceLine()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DummyGenJournalLine: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExcessiveAmount: Decimal;
    begin
        Initialize();
        ExcessiveAmount := 1;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmtExcessiveAmount(CustLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        ApplyStatementAutomatically(BankAccRecon, TempBlobUTF8, PmtReconJnl);
        PmtReconJnl.First();
        LibraryVariableStorage.Enqueue(DummyGenJournalLine."Account Type"::Customer);
        LibraryVariableStorage.Enqueue(CustLedgEntry."Customer No.");
        PmtReconJnl.TransferDiffToAccount.Invoke();

        // Verify that the line was split in two
        PmtReconJnl.First();
        Assert.AreEqual(CustLedgEntry."Remaining Amount", PmtReconJnl."Statement Amount".AsDecimal(), '');
        Assert.AreEqual(CustLedgEntry."Customer No.", PmtReconJnl."Account No.".Value, '');
        PmtReconJnl.Next();
        Assert.AreEqual(ExcessiveAmount, PmtReconJnl."Statement Amount".AsDecimal(), '');
        Assert.AreEqual(CustLedgEntry."Customer No.", PmtReconJnl."Account No.".Value, '');
        PmtReconJnl.Close();

        // Find the split line via parent line no
        BankAccReconciliationLine.SetRange("Statement Type", BankAccRecon."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccRecon."Statement No.");
        BankAccReconciliationLine.FindFirst();
        BankAccReconciliationLine.SetRange("Parent Line No.", BankAccReconciliationLine."Statement Line No.");
        Assert.IsTrue(BankAccReconciliationLine.FindFirst(), 'Difference line not found.');

        // Delete the split line
        BankAccReconciliationLine.Delete(true);

        // verify that the parent line was updated
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        PmtReconJnl.First();
        Assert.AreEqual(CustLedgEntry."Remaining Amount" + ExcessiveAmount, PmtReconJnl."Statement Amount".AsDecimal(),
          'Original statement line not updated after the difference line was deleted.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestDrilldownTwoSaleTwoPrePostedPmt()
    var
        Cust: Record Customer;
        Cust2: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        CustomerCard: TestPage "Customer Card";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibrarySales.CreateCustomer(Cust);
        LibrarySales.CreateCustomer(Cust2);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust2, CustLedgEntry2, '');

        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(
          OutStream,
          CustLedgEntry."Posting Date",
          StrSubstNo('%1 %2', CustLedgEntry."Document No.", CustLedgEntry2."Document No."),
          CustLedgEntry."Remaining Amount" + CustLedgEntry2."Remaining Amount",
          CustLedgEntry."Currency Code");
        WriteCAMTFooter(OutStream);

        // Exercise
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // verify that you got two applied payment entries
        BankAccReconLine.FilterBankRecLines(BankAccRecon);
        BankAccReconLine.FindFirst();
        AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        Assert.AreEqual(2, AppliedPmtEntry.Count, '');

        // verify that you can drill down to correct customer from the first applied entry
        AppliedPmtEntry.Find('-');
        Assert.AreEqual(Cust.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        CustomerCard.Trap();
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Cust."No.", CustomerCard."No.".Value, '');
        CustomerCard.Close();

        // verify that you can drill down to correct customer from the second applied entry
        AppliedPmtEntry.Next();
        Assert.AreEqual(Cust2.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        CustomerCard.Trap();
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Cust2."No.", CustomerCard."No.".Value, '');
        CustomerCard.Close();
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestReconciledPaymentsNotImported()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke();
        LibraryLowerPermissions.SetAccountReceivables();
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon2, BankAccRecon."Bank Account No.", BankAccRecon2."Statement Type"::"Payment Application");
        BankAccRecon2.ImportBankStatement();

        // Verify that no lines are imported, because all the transactions in the file are already reconciled
        VerifyNoLinesImported(BankAccRecon2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,PmtApplnHandler,PostedNonReconciledLinesConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestImportPostedNonReconciledPayments()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        BankAccRecon3: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        LibraryLowerPermissions.SetBanking();
        LibraryLowerPermissions.AddAccountReceivables();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Close();
        BankAccRecon.Find();
        BankAccRecon."Post Payments Only" := true;
        BankAccRecon.Modify();
        CODEUNIT.Run(CODEUNIT::"Bank Acc. Reconciliation Post", BankAccRecon);

        // choose not to import posted non-reconciled transactions
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon2, BankAccRecon."Bank Account No.", BankAccRecon2."Statement Type"::"Payment Application");
        LibraryVariableStorage.Enqueue(false);
        BankAccRecon2.ImportBankStatement();

        // Verify that no lines are imported, because all the transactions in the file are already posted and not reconciled
        VerifyNoLinesImported(BankAccRecon2);

        // choose to import posted non-reconciled transactions
        LibraryERM.CreateBankAccReconciliation(
          BankAccRecon3, BankAccRecon."Bank Account No.", BankAccRecon3."Statement Type"::"Payment Application");
        LibraryVariableStorage.Enqueue(true);
        BankAccRecon3.ImportBankStatement();

        // Verify that no lines are imported, because we asked to import posted and not reconciled transactions
        VerifyLinesImported(BankAccRecon3);
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenBankTrxsHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneOutstandingBankTrxsTotalPost()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 167357] Annie can view that when one outstanding check transactions get posted that all sales | gls | banks go to zero

        // [GIVEN] One Sale and one payment is created and put into xml import bank statment
        CreateOneSaleOnePmtOutstream(CustLedgEntry, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");

        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Manually match one and post the Payment Reconcilation Journal
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // [THEN] Verify that all customers | gls | banks go to zero
        VerifyCustLedgEntry(CustLedgEntry."Customer No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenBankTrxsPartialApplyHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankAndCheckTrxsTestReportFromPayRecJnlPatialBankApply()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 166798] Annie will be able to view the Bank Reconciliation Report content from the Payment Reconciliation Journal

        // [GIVEN] One sale and one payment and one purchase and one payment are created and put into xml import bank statment
        CreateOneSaleOnePmtOnePurchOnePmt(CustLedgEntry, VendLedgEntry, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        BankAccRecon.Modify();
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";

        // [WHEN] One GL Journal is created as a manual check
        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        PaymentReconE2ETests2.CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry,
          BankAccRecon."Bank Account No.", -VendLedgerAmount);

        // [WHEN] Payment Reconciliation Journal is opened and report is invoked
        LibraryVariableStorage.Enqueue(CustLedgEntry."Customer No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(true);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Manually match one with an amount 10
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        Commit();

        // [WHEN] Report is invoked
        PmtReconJnl.TestReport.Invoke();

        // [THEN] Verify outstanding transactions are included and report totals correct
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(
           CustLedgerAmount - 10,
           VendLedgerAmount,
           BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
           CustLedgerAmount + VendLedgerAmount,
           BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsPartialApplyHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankAndCheckTrxsTestReportFromPayRecJnlPatialPaymentApply()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 166798] Annie will be able to view the Bank Reconciliation Report content from the Payment Reconciliation Journal

        // [GIVEN] One sale and one payment and one purchase and one payment are created and put into xml import bank statment
        CreateOneSaleOnePmtOnePurchOnePmt(CustLedgEntry, VendLedgEntry, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        BankAccRecon.Modify();
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";

        // [WHEN] One GL Journal is created as a manual check
        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        PaymentReconE2ETests2.CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry,
          BankAccRecon."Bank Account No.", -VendLedgerAmount);

        // [WHEN] Payment Reconciliation Journal is opened and report is invoked
        LibraryVariableStorage.Enqueue(VendLedgEntry."Vendor No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(true);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [WHEN] Manually match one with an amount 10
        HandlePmtVendorEntries(VendLedgEntry, PmtReconJnl);
        Commit();

        // [WHEN] Report is invoked
        PmtReconJnl.TestReport.Invoke();

        // [THEN] Verify outstanding transactions are included and report totals correct
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(
          CustLedgerAmount,
          VendLedgerAmount + 10,
          BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
          CustLedgerAmount + VendLedgerAmount,
          BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankAndCheckTrxsTestReportFromPayRecJnl()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 166798] Annie will be able to view the Bank Reconciliation Report content from the Payment Reconciliation Journal

        // [GIVEN] One sale and one payment and one purchase and one payment are created and put into xml import bank statment
        CreateOneSaleOnePmtOnePurchOnePmt(CustLedgEntry, VendLedgEntry, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        BankAccRecon.Modify();
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";

        // [WHEN] One GL Journal is created as a manual check
        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        PaymentReconE2ETests2.CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry,
          BankAccRecon."Bank Account No.", -VendLedgerAmount);

        // [WHEN] Payment Reconciliation Journal is opened and report is invoked
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(true);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        PmtReconJnl.TestReport.Invoke();

        // [THEN] Verify outstanding transactions are included and report totals correct
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(
          CustLedgerAmount,
          VendLedgerAmount,
          BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
          CustLedgerAmount + VendLedgerAmount,
          BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankAndCheckTrxsTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        CustLedgerAmount2: Decimal;
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 166798] Annie will be able to view the Outstanding transactions on the Bank Reconciliation Report

        // [GIVEN] Two sales with payments and two purchases with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtTwoPurchTwoPmt(CustLedgEntry, CustLedgEntry2, VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        BankAccRecon.Modify();
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");

        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        CustLedgerAmount2 := CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible";

        // [WHEN] Two GL Journals created as manual checks
        CreateTwoManualChecks(VendLedgerAmount, VendLedgerAmount2, GenJnlLine,
          VendLedgEntry, VendLedgEntry2, BankAccRecon."Bank Account No.");

        // [WHEN] Bank Reconciliation Report is run, the outstanding transactions are included
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test");

        // [THEN] Verify outstanding transactions are included and report totals correct for multiple transactions
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(
          CustLedgerAmount + CustLedgerAmount2,
          VendLedgerAmount + VendLedgerAmount2,
          BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
          CustLedgerAmount + CustLedgerAmount2 + VendLedgerAmount + VendLedgerAmount2,
          BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankTrxsAppliedTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        CustLedgerAmount2: Decimal;
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 167357] Annie will not see the outstanding transactions once they are applied

        // [GIVEN] Two sales with payments and two purchases with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtTwoPurchTwoPmt(CustLedgEntry, CustLedgEntry2, VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");

        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        CustLedgerAmount2 := CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible";

        // [WHEN] Two GL Journals created as manual checks and automatically applly is run
        CreateTwoManualChecks(VendLedgerAmount, VendLedgerAmount2, GenJnlLine,
          VendLedgEntry, VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Commit();

        // [WHEN] Report is invoked from Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(false);
        PmtReconJnl.TestReport.Invoke();

        // [THEN] Verify no outstanding transactions included as they are applied, verify totals on report
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(0, 0,
          BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
          CustLedgerAmount + CustLedgerAmount2 + VendLedgerAmount + VendLedgerAmount2,
          BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('BankRecTestReportRequestPageHandler,PmtApplnHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankTrxsPartialApplyTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        CustLedgerAmount: Decimal;
        CustLedgerAmount2: Decimal;
        VendLedgerAmount: Decimal;
        VendLedgerAmount2: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Reconciliation Report]
        // [SCENARIO 167357] Annie will see applied and outstanding transactions on report

        // [GIVEN] Two sales with payments and two purchases with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtTwoPurchTwoPmt(CustLedgEntry, CustLedgEntry2, VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);
        SetOnMatchOnClosingDocumentNumber();

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        BankAccRecon."Statement Date" := CalcDate('+20Y', Today());
        BankAccRecon.Modify();
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");

        CustLedgerAmount := CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible";
        CustLedgerAmount2 := CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible";

        // [WHEN] Two GL Journals created as manual checks and one customer record is applied
        CreateTwoManualChecks(VendLedgerAmount, VendLedgerAmount2, GenJnlLine,
          VendLedgEntry, VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        HandlePmtEntries(CustLedgEntry, PmtReconJnl);
        Commit();

        // [WHEN] Bank Reconciliation Report is run
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(true);
        PmtReconJnl.TestReport.Invoke();

        // [THEN] Verify outstanding transactions that are not applied are included, verify totals on report
        BankAccRecon.CalcFields("Total Difference", "Total Transaction Amount");
        VerifyBankAccReconTestReport(
          CustLedgerAmount2,
          VendLedgerAmount + VendLedgerAmount2,
          BankAccRecon."Balance Last Statement" + BankAccRecon."Total Transaction Amount",
          CustLedgerAmount + CustLedgerAmount2 + VendLedgerAmount + VendLedgerAmount2,
          BankAccRecon."Total Difference");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankTrxsAppliedBankErrTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExpectedError1: Text[1024];
        ExpectedError2: Text[1024];
    begin
        // [FEATURE] [Bank Reconciliation Report]
        // [SCENARIO 167357] Annie will see report errors when the bank acc ledger is closed or missing for applied document

        // [GIVEN] Two sales with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported and customer ledger payment is posted
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");
        PostPayment(CustLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(CustLedgEntry2, BankAccRecon."Bank Account No.");

        // [WHEN] Pmt Reconciliation Journal automatic apply is run
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // [WHEN] Update one Bank Acc Ledger Entry to closed and delete one ledger for reporting errors
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateBankAccLedgerEntry(BankAccRecon."Bank Account No.", CustLedgEntry."Customer No.", ExpectedError1, ExpectedError2);
        Commit();

        // [WHEN] Report is run for Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test");

        // [THEN] Verify expected warnings for account closed and missing record are on report
        VerifyWarningOnReport(ErrorText_Number__Control97CaptionLbl, 'ErrorText_Number__Control97Caption',
          'ErrorText_Number__Control97', ExpectedError1, ExpectedError2, '');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankTrxsAppliedCustErrTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExpectedError1: Text[1024];
        ExpectedError2: Text[1024];
        ExpectedError3: Text[1024];
    begin
        // [FEATURE] [Bank Reconciliation Report]
        // [SCENARIO 167357] Annie will see report errors when the cust ledger entry is closed, missing or amount is wrong

        // [GIVEN] Two sales with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtOutstream(CustLedgEntry, CustLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");

        // [WHEN] Pmt Reconciliation Journal automatic apply is run
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // [WHEN] Update Cust Ledger Entry to closed,change amount on one and delete second ledger for reporting errors
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateCustLedgerEntry(CustLedgEntry."Customer No.", ExpectedError1, ExpectedError2, ExpectedError3);
        Commit();

        // [WHEN] Report is run for Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test");

        // [THEN] Verify warnings on report for closed, wrong amount and missing ledger
        VerifyWarningOnReport(ErrorText_Number__Control97CaptionLbl, 'ErrorText_Number__Control97Caption',
          'ErrorText_Number__Control97', ExpectedError1, ExpectedError2, ExpectedError3);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,BankRecTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestOutstBankTrxsAppliedVendErrTestReport()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        ExpectedError1: Text[1024];
        ExpectedError2: Text[1024];
        ExpectedError3: Text[1024];
    begin
        // [FEATURE] [Purchasing] [Bank Reconciliation Report]
        // [SCENARIO 167357] Annie will see report errors when the vendor ledger entry is closed, missing or amount is wrong

        // [GIVEN] Two sales with payments and two purchases with payments are created and put into xml import bank statment
        CreateTwoSaleTwoPmtTwoPurchTwoPmt(CustLedgEntry, CustLedgEntry2, VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // [WHEN] Statement is imported
        LibraryLowerPermissions.SetBanking();
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.Get(BankAccRecon."Statement Type", BankAccRecon."Bank Account No.", BankAccRecon."Statement No.");

        // [WHEN] Automatic apply is run
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Commit();

        // [WHEN] Update Vendor Ledger Entry to closed,change amount on one and delete second ledger for reporting errors
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateVendLedgerEntry(VendLedgEntry."Vendor No.", ExpectedError1, ExpectedError2, ExpectedError3);
        Commit();

        // [WHEN] Report is run for Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(BankAccRecon."Bank Account No.");
        LibraryVariableStorage.Enqueue(BankAccRecon."Statement No.");
        LibraryVariableStorage.Enqueue(false);
        REPORT.Run(REPORT::"Bank Acc. Recon. - Test");

        // [THEN] Verify warnings on report for closed, wrong amount and missing ledger
        VerifyWarningOnReport(ErrorText_Number__Control97CaptionLbl, 'ErrorText_Number__Control97Caption',
          'ErrorText_Number__Control97', ExpectedError1, ExpectedError2, ExpectedError3);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure SingleCustomerAutoMatchAndPostTwoPaymentsTwoInvoicesInViceVersaOrder()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: array[2] of Record "Bank Acc. Reconciliation Line";
        InvCustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        PmtCustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO 198751] Automatically match and post payment reconciliation journal with two customer payments applied to two invoices in vice versa order
        Initialize();

        // [GIVEN] Customer "C" with two posted sales invoices:
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] "SI1" with Amount Including VAT = 1000 (customer ledger entry no. = "CLE_INV1")
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InvoiceNo[1] := CreateAndPostSalesInvoiceWithAmount(CustomerNo, Amount);
        FindCustomerLedgerEntry(InvCustLedgerEntry[1], CustomerNo, InvCustLedgerEntry[1]."Document Type"::Invoice, InvoiceNo[1]);
        // [GIVEN] "SI2" with Amount Including VAT = 1000 (customer ledger entry no. = "CLE_INV2")
        InvoiceNo[2] := CreateAndPostSalesInvoiceWithAmount(CustomerNo, Amount);
        FindCustomerLedgerEntry(InvCustLedgerEntry[2], CustomerNo, InvCustLedgerEntry[2]."Document Type"::Invoice, InvoiceNo[2]);

        // [GIVEN] Payment Reconciliation Journal ("Statement No." = "X") with two lines:
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo(),
          BankAccReconciliation."Statement Type"::"Payment Application");
        // [GIVEN] Line1: "Statement Line No." = 10000, "Account Type" = "Customer", "Account No." = "C", "Transaction Text" = "SI2", "Transaction Amount" = 1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[1], BankAccReconciliation, CustomerNo, InvoiceNo[2], Amount);
        // [GIVEN] Line2: "Statement Line No." = 20000, "Account Type" = "Customer", "Account No." = "C", "Transaction Text" = "SI1", "Transaction Amount" = 1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[2], BankAccReconciliation, CustomerNo, InvoiceNo[1], Amount);

        // [GIVEN] Perform "Apply automatically" action
        MatchBankReconLineAutomatically(BankAccReconciliation);

        // [GIVEN] Customer ledger entry "CLE_INV1" has "Applies-To ID" = "X-20000"
        InvCustLedgerEntry[1].Find();
        Assert.AreEqual(
          BankAccReconciliationLine[2].GetAppliesToID(),
          InvCustLedgerEntry[1]."Applies-to ID", InvCustLedgerEntry[1].FieldCaption("Applies-to ID"));
        // [GIVEN] Customer ledger entry "CLE_INV2" has "Applies-To ID" = "X-10000"
        InvCustLedgerEntry[2].Find();
        Assert.AreEqual(
          BankAccReconciliationLine[1].GetAppliesToID(),
          InvCustLedgerEntry[2]."Applies-to ID", InvCustLedgerEntry[2].FieldCaption("Applies-to ID"));

        // [WHEN] Post the journal
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] The journal has been posted and two invoices "SI1", "SI2" are closed:
        // [THEN] Customer ledger entry "CLE_INV2" has "Open" = FALSE, "Closed by Entry No." = "CLE_PMT1", where
        // [THEN] Customer ledger entry "CLE_PMT1": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        FindCustomerLedgerEntry(
          PmtCustLedgerEntry, CustomerNo, PmtCustLedgerEntry."Document Type"::Payment, BankAccReconciliationLine[1]."Statement No.");
        InvCustLedgerEntry[2].Find();
        Assert.AreEqual(false, InvCustLedgerEntry[2].Open, InvCustLedgerEntry[2].FieldCaption(Open));
        Assert.AreEqual(
          PmtCustLedgerEntry."Entry No.", InvCustLedgerEntry[2]."Closed by Entry No.",
          InvCustLedgerEntry[2].FieldCaption("Closed by Entry No."));
        // [THEN] Customer ledger entry "CLE_INV1" has "Open" = FALSE, "Closed by Entry No." = "CLE_PMT2", where
        // [THEN] Customer ledger entry "CLE_PMT2": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        PmtCustLedgerEntry.Next();
        InvCustLedgerEntry[1].Find();
        Assert.AreEqual(false, InvCustLedgerEntry[1].Open, InvCustLedgerEntry[1].FieldCaption(Open));
        Assert.AreEqual(
          PmtCustLedgerEntry."Entry No.", InvCustLedgerEntry[1]."Closed by Entry No.",
          InvCustLedgerEntry[1].FieldCaption("Closed by Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PaymentApplicationModalPageHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TwoSaesInvoiceToPaymentReconciliationJournalDifferentDates()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BankAccount: Record "Bank Account";
        BankAccReconciliation: array[2] of Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        PostingDate: array[2] of Date;
        Index: Integer;
        DocAmount: Decimal;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Application] [Applies-to ID]
        // [SCENARIO 407488] System can post Bank Account Reconciliation with it has two Bank Account Reconciliation for the same Customer but with different Transaction Date and Bank Account
        Initialize();

        PostingDate[1] := WorkDate();
        PostingDate[2] := WorkDate() + LibraryRandom.RandIntInRange(40, 60);

        DocAmount := LibraryRandom.RandIntInRange(100, 200);

        LibrarySales.CreateCustomer(Customer);

        for Index := 1 to ArrayLen(PostingDate) do begin
            LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
            SalesHeader.Validate("Posting Date", PostingDate[Index]);
            SalesHeader.Validate("Order Date", PostingDate[Index]);
            SalesHeader.Validate("Due Date", PostingDate[Index]);
            SalesHeader.Modify(true);

            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
            SalesLine.Validate("Unit Price", DocAmount);
            SalesLine.Modify(true);

            InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

            Clear(BankAccount);
            CreateBankAcc('SEPA CAMT', BankAccount, '');

            LibraryERM.CreateBankAccReconciliation(
              BankAccReconciliation[Index], BankAccount."No.", BankAccReconciliation[Index]."Statement Type"::"Payment Application");

            PaymentReconciliationJournal.Trap();
            BankAccReconciliation[Index].OpenWorksheet(BankAccReconciliation[Index]);

            PaymentReconciliationJournal."Transaction Date".SetValue(PostingDate[Index]);
            PaymentReconciliationJournal."Statement Amount".SetValue(DocAmount);

            UpdateBankAccRecStmEndingBalance(BankAccReconciliation[Index], DocAmount);

            LibraryVariableStorage.Enqueue(InvoiceNo);
            PaymentReconciliationJournal.ApplyEntries.Invoke();

            PaymentReconciliationJournal.Close();
        end;

        PaymentReconciliationJournal.Trap();
        BankAccReconciliation[1].OpenWorksheet(BankAccReconciliation[1]);
        PaymentReconciliationJournal.Post.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PostAndReconcilePageHandler,BankAccountStatementRequestPageHandler')]
    procedure GLBalanceOnBankAccountStatementWhenPostedFromPaymentRecJournal()
    var
        BankAccount: Record "Bank Account";
        BankGLAccount: Record "G/L Account";
        OtherGLAccount: Record "G/L Account";
        BankAccountStatement: Record "Bank Account Statement";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        RequestPageXML: Text;
    begin
        // [SCENARIO] The field GL Balance at Posting date in the Bank Statement report should consider the entries posted from the payment reconciliation journal.
        Initialize();
        BankAccountStatement.DeleteAll();
        // [GIVEN] A new bank account with no balance in either the Bank Account or corresponding GL account.
        LibraryERM.CreateGLAccount(BankGLAccount);
        LibraryERM.CreateBankAccount(BankAccount, BankGLAccount);
        // [GIVEN] A posted payment reconciliation journal that posted a new GL Entry to some other GLAccount as one of its lines.
        LibraryERM.CreateGLAccount(OtherGLAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        OpenPmtReconJnl(BankAccReconciliation, PaymentReconciliationJournal);
        PaymentReconciliationJournal."Transaction Text".SetValue('Description');
        PaymentReconciliationJournal."Transaction Date".SetValue(WorkDate());
        PaymentReconciliationJournal."Statement Amount".SetValue(100);
        PaymentReconciliationJournal."Account Type".SetValue(Enum::"Gen. Journal Account Type"::"G/L Account");
        PaymentReconciliationJournal."Account No.".SetValue(OtherGLAccount."No.");
        PaymentReconciliationJournal.Accept.Invoke();
        BankAccReconciliation."Statement Date" := WorkDate();
        BankAccReconciliation.Validate("Statement Ending Balance", 100);
        BankAccReconciliation.Modify();
        PaymentReconciliationJournal.Post.Invoke();
        Commit();
        // [WHEN] The Bank Statement report is run.
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        RequestPageXML := Report.RunRequestPage(Report::"Bank Account Statement", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Bank Account Statement", BankAccountStatement, RequestPageXML);
        // [THEN] The GLBalanceAtPostingDate field includes the newly posted line.
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalBalOnBankAccount', 100.0);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Recon. E2E Tests 1");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryLowerPermissions.SetOutsideO365Scope();
        if BankPmtApplSettings.Get() then
            BankPmtApplSettings.Delete();

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 1");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Warnings" := SalesReceivablesSetup."Credit Warnings"::"No Warning";
        SalesReceivablesSetup.Modify();
        UpdateCustPostingGrp();
        UpdateVendPostingGrp();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        Initialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 1");
    end;

    local procedure CreateBankAccReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; CurrencyCode: Code[10])
    var
        BankAcc: Record "Bank Account";
        BankStmtFormat: Code[20];
    begin
        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc, CurrencyCode);

        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(BankStmtFormat, TempBlobUTF8);
        BankAccRecon.ImportBankStatement();

        BankAccRecon.CalcFields("Total Transaction Amount");
    end;

    local procedure CreateBankAccReconByImportingStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; BankAccount: Record "Bank Account")
    begin
        SetupSourceMock(BankAccount."Bank Statement Import Format", TempBlobUTF8);

        // The handler must pick the bank account
        CODEUNIT.Run(CODEUNIT::"Pmt. Rec. Jnl. Import Trans.");

        BankAccRecon.SetRange("Bank Account No.", BankAccount."No.");
        if BankAccRecon.FindLast() then
            BankAccRecon.CalcFields("Total Transaction Amount");
    end;

    local procedure CreateUnpaidDocs(var OutStream: OutStream; var CustLedgEntry: array[25] of Record "Cust. Ledger Entry")
    begin
        WriteCAMTHeader(OutStream, '', 'TEST');

        OneSaleOnePmt(CustLedgEntry[1], OutStream);
        OneSaleTwoPmt(CustLedgEntry[2], OutStream);
        TwoSaleTwoPmt(CustLedgEntry[3], CustLedgEntry[4], OutStream);
        TwoSaleOnePmt(CustLedgEntry, OutStream, 5, 6);

        OneSaleOnePmtWithPmtDisc(CustLedgEntry[7], OutStream);
        OneSaleTwoPmtWithPmtDisc(CustLedgEntry[8], OutStream);
        TwoSaleTwoPmtWithPmtDisc(CustLedgEntry[9], CustLedgEntry[10], OutStream);
        TwoSaleOnePmtWithPmtDisc(CustLedgEntry[11], CustLedgEntry[12], OutStream);

        OneSaleOnePmtWithLateDueDatePmtDisc(CustLedgEntry[13], OutStream, '');
        OneSaleOnePmtWithWrongPmtDiscPct(CustLedgEntry[14], OutStream);

        // BankTransfer(BankAcc,OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateAndPostSalesInvoiceWithAmount(CustomerNo: Code[20]; Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; CustomerNo: Code[20]; InvoiceNo: Code[20]; StatementAmount: Decimal)
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Transaction Text", InvoiceNo);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::Customer);
        BankAccReconciliationLine.Validate("Account No.", CustomerNo);
        BankAccReconciliationLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure OpenPmtReconJnl(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView();
        PmtReconciliationJournals.GotoRecord(BankAccRecon);
        PmtReconJnl.Trap();
        PmtReconciliationJournals.EditJournal.Invoke();
    end;

    local procedure OpenMiniPmtReconJnl(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJournalOverview: TestPage "Pmt. Recon. Journal Overview")
    var
        PmtReconJournalsOverview: TestPage "Pmt. Rec. Journals Overview";
    begin
        PmtReconJournalsOverview.OpenView();
        PmtReconJournalsOverview.GotoRecord(BankAccRecon);
        PmtReconJournalOverview.Trap();
        PmtReconJournalsOverview.ViewJournal.Invoke();
    end;

    local procedure ApplyAutomatically(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        PmtReconJnl.ApplyAutomatically.Invoke();
        PmtReconJnl.First();
    end;

    local procedure ApplyManually(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var CustLedgEntry: array[25] of Record "Cust. Ledger Entry")
    begin
        // Without Pmt Disc

        // OneSaleOnePmt
        PmtReconJnl.First();
        HandlePmtEntries(CustLedgEntry[1], PmtReconJnl);
        // OneSaleTwoPmt

        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[2], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[2], PmtReconJnl);

        // TwoSaleTwoPmt
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[3], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[4], PmtReconJnl);

        // TwoSaleOnePmt
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[5], PmtReconJnl);
        HandlePmtEntries(CustLedgEntry[6], PmtReconJnl);

        // OneSaleOnePmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[7], PmtReconJnl);

        // OneSaleTwoPmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[8], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[8], PmtReconJnl);

        // TwoSaleTwoPmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[9], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[10], PmtReconJnl);

        // TwoSaleOnePmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(CustLedgEntry[11], PmtReconJnl);
        HandlePmtEntries(CustLedgEntry[12], PmtReconJnl);

        PmtReconJnl.Next();
        HandlePmtDiscDate(CustLedgEntry[13], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtDiscAmt(CustLedgEntry[14], PmtReconJnl);

        // PmtReconJnl.Next();
        // HandleBankTransAmt(BankAcc,PmtReconJnl);
    end;

    local procedure MatchBankReconLineAutomatically(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure WriteCAMTHeader(var OutStream: OutStream; CurrTxt: Code[10]; BankAccNo: Code[20])
    begin
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeader(OutStream, CurrTxt, BankAccNo);
    end;

    local procedure WriteCAMTStmtLine(var OutStream: OutStream; StmtDate: Date; StmtText: Text; StmtAmt: Decimal; StmtCurr: Code[10])
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtLine(OutStream, StmtDate, StmtText, StmtAmt, StmtCurr, '');
    end;

    local procedure WriteCAMTFooter(var OutStream: OutStream)
    begin
        LibraryCAMTFileMgt.WriteCAMTStmtFooter(OutStream);
        LibraryCAMTFileMgt.WriteCAMTFooter(OutStream);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCAMTFileMgt.SetupSourceMock(DataExchDefCode, TempBlob);
    end;

    local procedure OneSaleOnePmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    begin
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream, CustLedgEntry."Posting Date", CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
    end;

    local procedure OneSaleOnePmt1(var BankAccRecon: Record "Bank Acc. Reconciliation"; BankAcc: Record "Bank Account"; TempBlobUTF8: Codeunit "Temp Blob")
    var
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(BankAcc."Bank Statement Import Format", TempBlobUTF8);
        BankAccRecon.ImportBankStatement();
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);

        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        VerifyPrePost(BankAccRecon, PmtReconJnl);
    end;

    local procedure OneSaleOnePmtExcessiveAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream; ExcessiveAmount: Decimal)
    begin
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        WriteCAMTStmtLine(OutStream,
              CustLedgEntry."Posting Date", CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible" + ExcessiveAmount, CustLedgEntry."Currency Code");
    end;

    local procedure OneSaleTwoPmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        HalfAmt: Decimal;
    begin
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        HalfAmt := Round(CustLedgEntry."Remaining Amount" / 2);
        WriteCAMTStmtLine(OutStream, CustLedgEntry."Posting Date", CustLedgEntry."Document No.", HalfAmt, CustLedgEntry."Currency Code");
        WriteCAMTStmtLine(
          OutStream, CustLedgEntry."Posting Date", CustLedgEntry."Document No.",
          CustLedgEntry."Remaining Amount" - HalfAmt - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
    end;

    local procedure TwoSaleTwoPmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, CustLedgEntry."Posting Date", CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
        WriteCAMTStmtLine(
              OutStream, CustLedgEntry2."Posting Date", CustLedgEntry2."Document No.", CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible", CustLedgEntry2."Currency Code");
    end;

    local procedure TwoSaleOnePmt(var CustLedgEntry: array[25] of Record "Cust. Ledger Entry"; var OutStream: OutStream; FromPos: Integer; ToPos: Integer)
    var
        Cust: Record Customer;
        i: Integer;
        Total: Decimal;
        DocNo: Text[250];
    begin
        LibrarySales.CreateCustomer(Cust);

        for i := FromPos to ToPos do begin
            CreateSalesInvoiceAndPost(Cust, CustLedgEntry[i], '');
            Total += CustLedgEntry[i]."Remaining Amount" - CustLedgEntry[i]."Remaining Pmt. Disc. Possible";
            DocNo := StrSubstNo('%1;%2', DocNo, CustLedgEntry[i]."Document No.");
        end;

        WriteCAMTStmtLine(OutStream, CustLedgEntry[FromPos]."Posting Date", DocNo, Total, '');
    end;

    local procedure OneSaleOnePmtWithPmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
    begin
        CreateCustWithPmtDisc(Cust);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
    end;

    local procedure OneSaleTwoPmtWithPmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
        HalfAmt: Decimal;
    begin
        CreateCustWithPmtDisc(Cust);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        HalfAmt := Round(CustLedgEntry."Remaining Amount" / 2);
        WriteCAMTStmtLine(OutStream, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Document No.", HalfAmt, CustLedgEntry."Currency Code");
        WriteCAMTStmtLine(
          OutStream, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Document No."
          , CustLedgEntry."Remaining Amount" - HalfAmt - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
    end;

    local procedure TwoSaleTwoPmtWithPmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
    begin
        CreateCustWithPmtDisc(Cust);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, CustLedgEntry."Pmt. Discount Date", CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
        WriteCAMTStmtLine(
              OutStream, CustLedgEntry2."Pmt. Discount Date", CustLedgEntry2."Document No.", CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible", CustLedgEntry2."Currency Code");
    end;

    local procedure TwoSaleOnePmtWithPmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
    begin
        CreateCustWithPmtDisc(Cust);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, '');
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, CustLedgEntry."Pmt. Discount Date", StrSubstNo('%1;%2', CustLedgEntry."Document No.", CustLedgEntry2."Document No."),
              CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible" +
              CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible",
              CustLedgEntry."Currency Code");
    end;

    local procedure OneSaleOnePmtWithLateDueDatePmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream; CurrCode: Code[10])
    var
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, CurrCode);

        WriteCAMTStmtLine(
              OutStream,
              CalcDate('<+1D>', CustLedgEntry."Pmt. Discount Date"),
              CustLedgEntry."Document No.", CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible", CustLedgEntry."Currency Code");
    end;

    local procedure OneFCYSaleOnePmtWithLateDueDatePmtDisc(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    var
        Cust: Record Customer;
        PmtTerms: Record "Payment Terms";
        Curr: Record Currency;
        StmtAmt: Decimal;
    begin
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);

        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, Curr.Code);

        StmtAmt :=
            CustLedgEntry."Remaining Amt. (LCY)" -
            Round(CustLedgEntry."Remaining Pmt. Disc. Possible" * (CustLedgEntry."Remaining Amt. (LCY)" / CustLedgEntry."Remaining Amount"));

        WriteCAMTStmtLine(OutStream, CalcDate('<+1D>', CustLedgEntry."Pmt. Discount Date"), CustLedgEntry."Document No.", StmtAmt, CustLedgEntry."Currency Code");
    end;

    local procedure OneSaleOnePmtWithWrongPmtDiscPct(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream)
    begin
        CreateCustAndPostSalesInvoice(CustLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream,
              CustLedgEntry."Pmt. Discount Date",
              CustLedgEntry."Document No.", Round(CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible" - 5 / 100 * CustLedgEntry."Remaining Amount"),
              CustLedgEntry."Currency Code");
    end;

    local procedure BankTransfer(var BankAcc: Record "Bank Account"; var OutStream: OutStream; TransferAmount: Decimal; StmtTxt: Text)
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        WriteCAMTStmtLine(OutStream, WorkDate(), StmtTxt,
          TransferAmount,
          '');
    end;

    local procedure HandlePmtEntries(CustLedgEntry: Record "Cust. Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          CustLedgEntry."Customer No.", CustLedgEntry."Entry No.", CustLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    [Scope('OnPrem')]
    procedure HandlePmtVendorEntries(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        LibraryVariableStorage.Enqueue(VendLedgEntry."Vendor No.");
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandlePmtDiscDate(CustLedgEntry: Record "Cust. Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          CustLedgEntry."Customer No.", CustLedgEntry."Entry No.", CustLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, true);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandlePmtDiscAmt(CustLedgEntry: Record "Cust. Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          CustLedgEntry."Customer No.", CustLedgEntry."Entry No.", CustLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), true, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure EnqueueValuesForPmtApplnHandler(CustomerNo: Code[20]; CLEEntryNo: Integer; CLERemAmtLCY: Decimal; TransactionDate: Date; StatementAmount: Decimal; AdjustDiscountAmount: Boolean; AdjustDiscountDate: Boolean)
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CLEEntryNo);
        LibraryVariableStorage.Enqueue(CLERemAmtLCY);
        LibraryVariableStorage.Enqueue(TransactionDate);
        LibraryVariableStorage.Enqueue(StatementAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountDate);
    end;

    local procedure CreateCustWithPmtDisc(var Cust: Record Customer)
    var
        PmtTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);
    end;

    local procedure CreateCustAndPostSalesInvoice(var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        CreateSalesInvoiceAndPost(Cust, CustLedgEntry, CurrencyCode);
    end;

    local procedure CreateSalesInvoiceAndPost(var Cust: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Cust."No.");
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateRandomText(10));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst();

        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure SetOnMatchOnClosingDocumentNumber()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Bank Ledg Closing Doc No Match" := true;
        BankPmtApplSettings.Modify();
    end;

    local procedure PostPayment(var CustLedgEntry: Record "Cust. Ledger Entry"; BankAccNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer,
          CustLedgEntry."Customer No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -CustLedgEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJournalLine.Validate("External Document No.", CustLedgEntry."External Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentToGLAccount(GLAccountNo: Code[20]; BankAccNo: Code[20]; Amount: Decimal; TransactionText: Text)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -Amount);

        GenJournalLine.Description := CopyStr(TransactionText, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostBankTransfer(BankAccNo: Code[20]; BalBankAccNo: Code[20]; TransferAmount: Decimal; ExtDocNo: Code[35])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine,
          GenJournalTemplate.Name,
          GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account",
          BankAccNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BalBankAccNo,
          -TransferAmount);
        if ExtDocNo <> '' then begin
            GenJournalLine."External Document No." := ExtDocNo;
            GenJournalLine.Modify();
        end;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyPrePost(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        PmtReconJnl.First();
        repeat
            PmtReconJnl."Applied Amount".AssertEquals(PmtReconJnl."Statement Amount".AsDecimal());
            PmtReconJnl.Difference.AssertEquals(0);
        until not PmtReconJnl.Next();

        BankAccReconLine.LinesExist(BankAccRecon);
        repeat
            AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
            Assert.AreEqual(AppliedPmtEntry.Count, BankAccReconLine."Applied Entries", 'Checkiing the Applied Entries field on Tab273');
        until BankAccReconLine.Next() = 0;
    end;

    local procedure VerifyCustLedgEntry(CustNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange(Open, true);
        Assert.IsTrue(CustLedgEntry.IsEmpty, 'All entries are closed')
    end;

    local procedure VerifyCustLedgEntryExcessiveAmount(CustNo: Code[20]; ExcessiveAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Remaining Amount", -ExcessiveAmount);
        Assert.AreEqual(1, CustLedgEntry.Count, 'There should be one open ledger entry for the excessive amount.')
    end;

    local procedure VerifyBankLedgEntry(BankAccNo: Code[20]; ExpAmt: Decimal)
    begin
        VerifyBankLedgEntryAmount(BankAccNo, ExpAmt);
        VerifyBankLedgEntriesClosed(BankAccNo);
    end;

    local procedure VerifyBankLedgEntryAmount(BankAccNo: Code[20]; ExpAmt: Decimal)
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        TotalAmt: Decimal;
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.FindSet();
        repeat
            TotalAmt += BankAccLedgEntry.Amount;
        until BankAccLedgEntry.Next() = 0;
        Assert.AreEqual(ExpAmt, TotalAmt, '')
    end;

    local procedure VerifyBankLedgEntriesClosed(BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, true);
        Assert.IsTrue(BankAccLedgEntry.IsEmpty, OpenBankLedgerEntriesErr);
    end;

    local procedure VerifyBankLedgEntriesOpen(BankAccNo: Code[20])
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccLedgEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccLedgEntry.SetRange(Open, false);
        Assert.IsTrue(BankAccLedgEntry.IsEmpty, ClosedBankLedgerEntriesErr);
    end;

    local procedure VerifyNoLinesImported(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        Assert.IsTrue(BankAccReconciliationLine.IsEmpty, 'Processed payments should not have been imported.');
    end;

    local procedure VerifyLinesImported(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        Assert.IsTrue(BankAccReconciliationLine.FindFirst(), 'Processed payments should have been imported.');
    end;

    local procedure UpdateCustPostingGrp()
    var
        CustPostingGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        if CustPostingGroup.FindSet() then
            repeat
                if CustPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Debit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
                if CustPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    CustPostingGroup.Validate("Payment Disc. Credit Acc.", GLAcc."No.");
                    CustPostingGroup.Modify(true);
                end;
            until CustPostingGroup.Next() = 0;
    end;

    local procedure UpdateVendPostingGrp()
    var
        VendPostingGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        if VendPostingGroup.FindSet() then
            repeat
                if VendPostingGroup."Payment Disc. Debit Acc." = '' then begin
                    VendPostingGroup.Validate("Payment Disc. Debit Acc.", GLAcc."No.");
                    VendPostingGroup.Modify(true);
                end;
                if VendPostingGroup."Payment Disc. Credit Acc." = '' then begin
                    VendPostingGroup.Validate("Payment Disc. Credit Acc.", GLAcc."No.");
                    VendPostingGroup.Modify(true);
                end;
            until VendPostingGroup.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgTxt: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostedNonReconciledLinesConfirmHandler(Question: Text; var Reply: Boolean)
    var
        ReplyVar: Variant;
    begin
        Assert.AreEqual(Question, ImportPostedTransactionsQst, '');
        LibraryVariableStorage.Dequeue(ReplyVar);
        Reply := ReplyVar;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        if (Question.Contains(OpenBankStatementPageQst)) then
            Reply := false
        else
            Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnHandler(var PmtAppln: TestPage "Payment Application")
    var
        CustomerNo: Code[20];
        CLEEntryNo: Integer;
        CLERemAmtLCY: Decimal;
        PmtReconJnlTransactionDate: Date;
        PmtReconJnlStatementAmount: Decimal;
        AdjustDiscountAmount: Boolean;
        AdjustDiscountDate: Boolean;
    begin
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(CustomerNo));
        CLEEntryNo := LibraryVariableStorage.DequeueInteger();
        CLERemAmtLCY := LibraryVariableStorage.DequeueDecimal();
        PmtReconJnlTransactionDate := LibraryVariableStorage.DequeueDate();
        PmtReconJnlStatementAmount := LibraryVariableStorage.DequeueDecimal();
        AdjustDiscountAmount := LibraryVariableStorage.DequeueBoolean();
        AdjustDiscountDate := LibraryVariableStorage.DequeueBoolean();
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> CustomerNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;
        // Go to the first and check that it is the customer and scroll down to find the entry
        if PmtAppln.Applied.AsBoolean() then begin
            PmtAppln.RelatedPartyOpenEntries.Invoke();
            while PmtAppln."Applies-to Entry No.".AsInteger() <> CLEEntryNo do begin
                PmtAppln."Account No.".AssertEquals(CustomerNo);
                PmtAppln.Next();
            end;
        end;
        // check that it is the customer ledger entry and apply
        if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then
            if PmtAppln.AppliedAmount.AsDecimal() = 0 then begin
                PmtAppln.Applied.SetValue(true);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;

        if AdjustDiscountAmount then
            // Introduce payment discount
            if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then begin
                PmtAppln."Pmt. Disc. Due Date".SetValue(PmtReconJnlTransactionDate);
                PmtAppln."Remaining Pmt. Disc. Possible".SetValue(
                  CLERemAmtLCY - PmtReconJnlStatementAmount);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;

        if AdjustDiscountDate then
            if PmtReconJnlTransactionDate > PmtAppln."Pmt. Disc. Due Date".AsDate() then begin
                PmtAppln."Pmt. Disc. Due Date".SetValue(PmtReconJnlTransactionDate);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;

        PmtAppln.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    var
        InvoiceNo: Code[20];
    begin
        InvoiceNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, 20);

        PaymentApplication.FILTER.SetFilter("Document No.", InvoiceNo);
        if PaymentApplication.Applied.AsBoolean() then
            PaymentApplication.Applied.SetValue(false);
        PaymentApplication.Applied.SetValue(true);
        PaymentApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransferDiffToAccountHandler(var TransferDifferenceToAccount: TestPage "Transfer Difference to Account")
    var
        AccountTypeVar: Variant;
        AccountNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountTypeVar);
        LibraryVariableStorage.Dequeue(AccountNoVar);
        TransferDifferenceToAccount."Account Type".SetValue(AccountTypeVar);
        TransferDifferenceToAccount."Account No.".SetValue(AccountNoVar);
        TransferDifferenceToAccount.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentBankAccountListHandler(var PaymentBankAccountList: TestPage "Payment Bank Account List")
    var
        BankAccNoVar: Variant;
        BankAccNo: Code[20];
    begin
        LibraryVariableStorage.Dequeue(BankAccNoVar);
        BankAccNo := BankAccNoVar;
        PaymentBankAccountList.FindFirstField("No.", BankAccNo);
        PaymentBankAccountList.OK().Invoke();
    end;

    local procedure ApplyStatementAutomatically(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenBankTrxsHandler(var PmtAppln: TestPage "Payment Application")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(CustomerNo));
        // dummy dequeues
        LibraryVariableStorage.DequeueInteger();
        LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.DequeueDate();
        LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.DequeueBoolean();
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> CustomerNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;

        PmtAppln.AllOpenBankTransactions.Invoke();
        // check that it is the customer ledger entry and apply
        if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then
            if PmtAppln.AppliedAmount.AsDecimal() = 0 then begin
                PmtAppln.Applied.SetValue(true);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;

        PmtAppln.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenBankTrxsPartialApplyHandler(var PmtAppln: TestPage "Payment Application")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(CustomerNo));
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> CustomerNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;

        PmtAppln.AllOpenBankTransactions.Invoke();
        // check that it is the customer ledger entry and apply
        if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then
            if PmtAppln.AppliedAmount.AsDecimal() = 0 then
                PmtAppln.AppliedAmount.SetValue(10);

        PmtAppln.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenPaymentsHandler(var PmtAppln: TestPage "Payment Application")
    var
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VendorNo));
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> VendorNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;

        PmtAppln.AllOpenPayments.Invoke();
        // check that it is the customer ledger entry and apply
        if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then
            if PmtAppln.AppliedAmount.AsDecimal() = 0 then begin
                PmtAppln.Applied.SetValue(true);
                PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            end;

        PmtAppln.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtApplnAllOpenPaymentsPartialApplyHandler(var PmtAppln: TestPage "Payment Application")
    var
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VendorNo));
        // Remove Entry is not the same customer
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> VendorNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;

        PmtAppln.AllOpenPayments.Invoke();
        // check that it is the customer ledger entry and apply
        if PmtAppln.RemainingAmountAfterPosting.AsDecimal() <> 0 then
            if PmtAppln.AppliedAmount.AsDecimal() = 0 then
                PmtAppln.AppliedAmount.SetValue(-10);

        PmtAppln.OK().Invoke();
    end;

    local procedure CreateOneSaleOnePmtOutstream(var CustLedgEntry: Record "Cust. Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmt(CustLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateTwoSaleTwoPmtOutstream(var CustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleTwoPmt(CustLedgEntry, CustLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateOneSaleOnePmtOnePurchOnePmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    var
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneSaleOnePmt(CustLedgEntry, OutStream);
        PaymentReconE2ETests2.OnePurchOnePmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateTwoSaleTwoPmtTwoPurchTwoPmt(var CustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry2: Record "Cust. Ledger Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    var
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoSaleTwoPmt(CustLedgEntry, CustLedgEntry2, OutStream);
        PaymentReconE2ETests2.TwoPurchTwoPmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler')]
    local procedure CreateTwoManualChecks(var VendLedgerAmount: Decimal; var VendLedgerAmount2: Decimal; var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry2: Record "Vendor Ledger Entry"; BankAccNo: Code[20])
    var
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
    begin
        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";
        VendLedgerAmount2 := VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible";
        PaymentReconE2ETests2.CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry, BankAccNo, -VendLedgerAmount);
        PaymentReconE2ETests2.CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry2, BankAccNo, -VendLedgerAmount2);
    end;

    local procedure CreateBankAcc(BankStmtFormat: Code[20]; var BankAcc: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."Bank Account No." := 'TEST';
        BankAcc."Bank Branch No." := '123';
        BankAcc."Bank Statement Import Format" := BankStmtFormat;
        BankAcc.Validate("Currency Code", CurrencyCode);
        BankAcc.Modify(true);
    end;

    local procedure VerifyBankAccReconTestReport(OutstdTransactions: Decimal; OutstdPayments: Decimal; StatementEndingBalance: Decimal; GLBalance: Decimal; SumOfDifferences: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();

        // Verify Header Amounts
        LibraryReportDataset.AssertElementWithValueExists('Ending_GL_Balance', GLBalance);
        LibraryReportDataset.AssertElementWithValueExists('Adjusted_Statement_Ending_Balance',
          StatementEndingBalance + OutstdTransactions + OutstdPayments);
        LibraryReportDataset.AssertElementWithValueExists('Sum_Of_Differences', SumOfDifferences);
        // Warning HeaderError1 does not exist for Payment Reconciliation (TFS 398635)
        LibraryReportDataset.AssertElementWithValueNotExist(
            'HeaderError1', 'Statement Ending Balance must be equal to Total Balance.');
        LibraryReportDataset.AssertElementWithValueExists('Bank_Acc__Reconciliation___TotalOutstdBankTransactions', OutstdTransactions);

        // Verify Totals
        Assert.AreEqual(GLBalance,
          LibraryReportDataset.Sum('Bank_Acc__Reconciliation_Line__Statement_Amount_'),
          StrSubstNo(ValidationErr, 'Bank_Acc__Reconciliation_Line__Statement_Amount_', (OutstdTransactions + OutstdPayments)));
        Assert.AreEqual(OutstdTransactions, LibraryReportDataset.Sum('Outstd_Bank_Transac_Amount'),
          StrSubstNo(ValidationErr, 'Outstd_Bank_Transac_Amount', OutstdTransactions));
        Assert.AreEqual(OutstdPayments, LibraryReportDataset.Sum('Outstd_Payment_Amount'),
          StrSubstNo(ValidationErr, 'Outstd_Payment_Amount', OutstdPayments));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecTestReportRequestPageHandler(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Bank Account No.", LibraryVariableStorage.DequeueText());
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Statement No.", LibraryVariableStorage.DequeueText());
        BankAccReconTest."Bank Acc. Reconciliation".SetFilter("Statement Type", 'Payment Application');
        BankAccReconTest.PrintOutstdTransac.SetValue(LibraryVariableStorage.DequeueBoolean());
        BankAccReconTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Scope('OnPrem')]
    procedure UpdateBankAccLedgerEntry(BankAccNo: Code[20]; BalAccNo: Code[20]; var ErrorText1: Text[1024]; var ErrorText2: Text[1024])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccNo);
        BankAccountLedgerEntry.SetRange("Bal. Account No.", BalAccNo);
        if BankAccountLedgerEntry.Find('-') then begin
            BankAccountLedgerEntry.Open := false;
            BankAccountLedgerEntry.Amount += -40.0;
            BankAccountLedgerEntry.Modify();
            ErrorText1 := StrSubstNo(
                TableValueWrongErr, BankAccountLedgerEntry.FieldCaption(Open), true,
                BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
            if BankAccountLedgerEntry.Next() <> 0 then begin
                ErrorText2 := StrSubstNo(TableValueMissingErr, BankAccountLedgerEntry.TableCaption(), BankAccountLedgerEntry."Entry No.");
                BankAccountLedgerEntry.Delete();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateCustLedgerEntry(CustomerNo: Code[20]; var ErrorText1: Text[1024]; var ErrorText2: Text[1024]; var ErrorText3: Text[1024])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DummyAppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if CustLedgerEntry.Find('-') then begin
            CustLedgerEntry.Open := false;
            CustLedgerEntry.Modify();
            ErrorText1 := StrSubstNo(
                TableValueWrongErr, CustLedgerEntry.FieldCaption(Open), true,
                CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.SetRange("Ledger Entry Amount", true);
            if DetailedCustLedgEntry.FindFirst() then begin
                DetailedCustLedgEntry.Amount += -40.0;
                DetailedCustLedgEntry.Modify();
                ErrorText2 := StrSubstNo(
                    AmountWrongErr, DummyAppliedPaymentEntry.FieldCaption("Applied Amount"), DetailedCustLedgEntry.Amount);
            end;
            if CustLedgerEntry.Next() <> 0 then begin
                ErrorText3 := StrSubstNo(TableValueMissingErr, CustLedgerEntry.TableCaption(), CustLedgerEntry."Entry No.");
                CustLedgerEntry.Delete();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateVendLedgerEntry(VendNo: Code[20]; var ErrorText1: Text[1024]; var ErrorText2: Text[1024]; var ErrorText3: Text[1024])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DummyAppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendNo);
        if VendorLedgerEntry.Find('-') then begin
            VendorLedgerEntry.Open := false;
            VendorLedgerEntry.Modify();
            ErrorText1 := StrSubstNo(
                TableValueWrongErr, VendorLedgerEntry.FieldCaption(Open), true,
                VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No.");
            DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
            DetailedVendorLedgEntry.SetRange("Ledger Entry Amount", true);
            if DetailedVendorLedgEntry.FindFirst() then begin
                DetailedVendorLedgEntry.Amount += 40.0;
                DetailedVendorLedgEntry.Modify();
                ErrorText2 := StrSubstNo(
                    AmountWrongErr, DummyAppliedPaymentEntry.FieldCaption("Applied Amount"), DetailedVendorLedgEntry.Amount);
            end;
            if VendorLedgerEntry.Next() <> 0 then begin
                ErrorText3 := StrSubstNo(TableValueMissingErr, VendorLedgerEntry.TableCaption(), VendorLedgerEntry."Entry No.");
                VendorLedgerEntry.Delete();
            end;
        end;
    end;

    local procedure VerifyWarningOnReport(ElementText: Text[1024]; ElementName: Text[1024]; ElementNameError: Text[1024]; ExpectedWarningMessage1: Text[1024]; ExpectedWarningMessage2: Text[1024]; ExpectedWarningMessage3: Text[1024])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ElementName, ElementText);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, ElementName, ElementText);
        LibraryReportDataset.AssertCurrentRowValueEquals(ElementNameError, ExpectedWarningMessage1);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, ElementName, ElementText);
        LibraryReportDataset.AssertCurrentRowValueEquals(ElementNameError, ExpectedWarningMessage2);
        if ExpectedWarningMessage3 <> '' then begin
            if not LibraryReportDataset.GetNextRow() then
                Error(RowNotFoundErr, ElementName, ElementText);
            LibraryReportDataset.AssertCurrentRowValueEquals(ElementNameError, ExpectedWarningMessage3);
        end;
    end;

    local procedure GetLinesAndUpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation")
    var
        BankAccRecLine: Record "Bank Acc. Reconciliation Line";
        TotalLinesAmount: Decimal;
    begin
        BankAccRecLine.LinesExist(BankAccRecon);
        repeat
            TotalLinesAmount += BankAccRecLine."Statement Amount";
        until BankAccRecLine.Next() = 0;
        UpdateBankAccRecStmEndingBalance(BankAccRecon, BankAccRecon."Balance Last Statement" + TotalLinesAmount);
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageStatementDateHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountStatementRequestPageHandler(var BankAccountStatement: TestRequestPage "Bank Account Statement")
    begin
        BankAccountStatement.PrintOutstandingTransaction.SetValue(true);
        BankAccountStatement.OK().Invoke();
    end;

}
