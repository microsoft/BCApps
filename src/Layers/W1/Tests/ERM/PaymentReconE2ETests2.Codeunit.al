codeunit 134266 "Payment Recon. E2E Tests 2"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Reconciliation] [Purchase]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurch: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryCAMTFileMgt: Codeunit "Library - CAMT File Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;
        OpenBankLedgerEntriesErr: Label 'All bank account ledger entries should be closed after posting the payment reconciliation journal.';
        ClosedBankLedgerEntriesErr: Label 'All bank account ledger entries should be open after posting the payment reconciliation journal.';
        ExcessiveAmountErr: Label 'The remaining amount to apply is %1.', Comment = '%1 is the amount that is not applied (there is filed on the page named Remaining Amount To Apply)';
        ListEmptyMsg: Label 'No bank transaction lines exist. Choose the Import Bank Transactions action to fill in the lines from a file, or enter lines manually.';
        SEPA_CAMT_Txt: Label 'SEPA CAMT';
        OpenBankStatementPageQst: Label 'Do you want to open the bank account statement?';

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTransactionsAlreadyImported()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon1: Record "Bank Acc. Reconciliation";
        BankAccRecon2: Record "Bank Acc. Reconciliation";
        BankAcc: Record "Bank Account";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        BankStmtFormat: Code[20];
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        BankStmtFormat := 'SEPA CAMT';
        CreateBankAcc(BankStmtFormat, BankAcc, '');

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables();
        OnePurchOnePmt1(BankAccRecon1, BankAcc, TempBlobUTF8);
        OnePurchOnePmt1(BankAccRecon2, BankAcc, TempBlobUTF8);

        OpenPmtReconJnl(BankAccRecon1, PmtReconJnl);
        PmtReconJnl.Post.Invoke();
        VerifyNoLinesImported(BankAccRecon2);

        OpenPmtReconJnl(BankAccRecon2, PmtReconJnl);
        asserterror PmtReconJnl.Post.Invoke(); // It should not be possible to post
        PmtReconJnl.Close();
        BankAccRecon2.Find();
        BankAccRecon2.Delete(true); // It should be possible to delete the payment reconcilation journal

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
    end;

    local procedure OnePurchOnePmt1(var BankAccRecon: Record "Bank Acc. Reconciliation"; BankAcc: Record "Bank Account"; TempBlobUTF8: Codeunit "Temp Blob")
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

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        LibraryLowerPermissions.AddAccountReceivables();
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPrePostedPmtNoReconciliation()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateTwoPurchTwoPmtOutstream(VendLedgEntry, VendLedgEntry2, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.PostPaymentsOnly.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntryAmount(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
        VerifyBankLedgEntriesOpen(BankAccRecon."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePrePostedPmt()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyVendLedgEntry(VendLedgEntry2."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithPmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchTwoPmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmtWithPmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchTwoPmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchTwoPmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8, VendLedgEntry, VendLedgEntry2);
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmtWithPmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTwoPurchOnePmtWithPmtDisc2()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry2, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry, OutStream, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYPurchOnePmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OneFCYPurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneFCYPurchOneFCYPmtWithLateDueDatePmtDisc()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithLateDueDatePmtDisc(
          VendLedgEntry, OutStream, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, VendLedgEntry."Currency Code");
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscDate(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtWithWrongPmtDiscPct()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmtWithWrongPmtDiscPct(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtDiscAmt(VendLedgEntry, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
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
        TransferAmount := -100;
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        BankTransfer(BankAcc, OutStream, TransferAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostBankTransfer(BankAcc."No.", BankAccRecon."Bank Account No.", TransferAmount);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
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
        TransactionAmount := -100;
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, WorkDate(), TransactionText, TransactionAmount, '');
        WriteCAMTFooter(OutStream);
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := TransactionText;
        TextToAccountMapping."Credit Acc. No." := GLAccount."No.";
        TextToAccountMapping.Insert();

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPaymentToGLAccount(GLAccount."No.", BankAccRecon."Bank Account No.", TransactionAmount, TextToAccountMapping."Mapping Text");
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
        TransactionAmount := -100;
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
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestRecurringInterest()
    var
        GLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Interest2');
        GLAcc.Modify(true);
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, CalcDate('<CM+1D>', WorkDate()), GLAcc."No." + ' Bank Interest2', -200, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        LibraryVariableStorage.Enqueue(GLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke();

        ApplyAutomatically(PmtReconJnl);
        HandleRecurringInterestAmt(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestRecurringRent()
    var
        GLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Rent');
        GLAcc.Modify(true);
        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate()), 'Rent', -10000, '');
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        LibraryVariableStorage.Enqueue(GLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke();

        ApplyAutomatically(PmtReconJnl);
        HandleRecurringRentAmt(PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,TextMapperHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestEndToEnd()
    var
        RentGLAcc: Record "G/L Account";
        InterestGLAcc: Record "G/L Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: array[20] of Record "Vendor Ledger Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        i: Integer;
    begin
        // Setup
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        CreateUnpaidDocs(OutStream, VendLedgEntry, RentGLAcc, InterestGLAcc);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        AddTextMapperRules(PmtReconJnl, InterestGLAcc, RentGLAcc);
        ApplyAutomatically(PmtReconJnl);
        ApplyManually(PmtReconJnl, VendLedgEntry);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        for i := 1 to 14 do
            VerifyVendLedgEntry(VendLedgEntry[i]."Vendor No.");

        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestManyToOne()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        MatchConfidence1: Text;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
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
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
        AccountNo1: Code[20];
        AccountType1: Text;
        AppliedAmount: Decimal;
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchTwoPmt(VendLedgEntry, OutStream);
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
          VendLedgEntry."Remaining Amount", AppliedAmount, 'Entries not applied correctly. Missmatch for total applied amount.');
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestAccountNameWhenApplyingToBankAccountLedgerEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Vendor: Record Vendor;
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        OutStream: OutStream;
    begin
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        Vendor.Get(VendLedgEntry."Vendor No.");
        BankAccReconciliationLine.LinesExist(BankAccRecon);
        repeat
            Assert.AreEqual(Vendor.Name, BankAccReconciliationLine.GetAppliedToName(), '');
        until BankAccReconciliationLine.Next() = 0;

        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PmtApplnHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePmtExcessiveAmount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
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
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        PmtReconJnl.Accept.Invoke();
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntryExcessiveAmount(VendLedgEntry."Vendor No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestOnePurchOnePrePostedPmtExcessiveAmount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
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
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        asserterror PmtReconJnl.Accept.Invoke();
        Assert.ExpectedError(StrSubstNo(ExcessiveAmountErr, Format(-ExcessiveAmount)));
    end;

    [Test]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,TransferDiffToAccountHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestTransferDiffToAccount()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
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
        OnePurchOnePmtExcessiveAmount(VendLedgEntry, OutStream, ExcessiveAmount);
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        LibraryVariableStorage.Enqueue(DummyGenJournalLine."Account Type"::Vendor);
        LibraryVariableStorage.Enqueue(VendLedgEntry."Vendor No.");
        PmtReconJnl.TransferDiffToAccount.Invoke();
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntryExcessiveAmount(VendLedgEntry."Vendor No.", ExcessiveAmount);
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure TestDrilldownTwoPurchTwoPrePostedPmt()
    var
        Vend: Record Vendor;
        Vend2: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendLedgEntry2: Record "Vendor Ledger Entry";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
        TempBlobUTF8: Codeunit "Temp Blob";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendorCard: TestPage "Vendor Card";
        OutStream: OutStream;
    begin
        Initialize();
        SetOnMatchOnClosingDocumentNumber();

        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        LibraryPurch.CreateVendor(Vend);
        LibraryPurch.CreateVendor(Vend2);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend2, VendLedgEntry2, '');

        WriteCAMTHeader(OutStream, '', 'TEST');
        WriteCAMTStmtLine(
          OutStream,
          VendLedgEntry."Posting Date",
          StrSubstNo('%1 %2', VendLedgEntry."Document No.", VendLedgEntry2."Document No."),
          VendLedgEntry."Remaining Amount" + VendLedgEntry2."Remaining Amount",
          VendLedgEntry."Currency Code");
        WriteCAMTFooter(OutStream);

        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        PostPayment(VendLedgEntry, BankAccRecon."Bank Account No.");
        PostPayment(VendLedgEntry2, BankAccRecon."Bank Account No.");
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);

        // verify that you got two applied payment entries
        BankAccReconLine.FilterBankRecLines(BankAccRecon);
        BankAccReconLine.FindFirst();
        AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
        Assert.AreEqual(2, AppliedPmtEntry.Count, '');

        // verify that you can drill down to correct vendor from the first applied entry
        AppliedPmtEntry.Find('-');
        Assert.AreEqual(Vend.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        VendorCard.Trap();
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Vend."No.", VendorCard."No.".Value, '');
        VendorCard.Close();

        // verify that you can drill down to correct vendor from the second applied entry
        AppliedPmtEntry.Next();
        Assert.AreEqual(Vend2.Name, BankAccReconLine.GetAppliedEntryAccountName(AppliedPmtEntry."Applies-to Entry No."), '');
        VendorCard.Trap();
        BankAccReconLine.AppliedEntryAccountDrillDown(AppliedPmtEntry."Applies-to Entry No.");
        Assert.AreEqual(Vend2."No.", VendorCard."No.".Value, '');
        VendorCard.Close();
    end;

    [Test]
    [HandlerFunctions('PmtApplnAllOpenPaymentsHandler,ConfirmHandlerYes,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure TestOneOutstandingPaymentTrxsTotalPost()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        VendLedgerAmount: Decimal;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [Outstanding Bank Transactions]
        // [SCENARIO 166797] Annie can view one outstanding check transactions and Verify that all Vendors | gls | banks go to zero

        // [GIVEN] One purchase and one payment is created and put into xml import bank statment
        // [WHEN] Statement is imported
        // [WHEN] GL Journal is created as a manual check
        // [WHEN] Payment Reconciliation Journal is opened
        OpenPmtReconJrnlOnePayment(PmtReconJnl, VendLedgEntry, BankAccRecon, VendLedgerAmount);

        // [WHEN] Manually match one and post the Payment Reconcilation Journal
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // [THEN] Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    [Test]
    [HandlerFunctions('MsgHandler,PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure SingleVendorAutoMatchAndPostTwoPaymentsTwoInvoicesInViceVersaOrder()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: array[2] of Record "Bank Acc. Reconciliation Line";
        InvVendLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PmtVendLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Match]
        // [SCENARIO 198751] Automatically match and post payment reconciliation journal with two vendor payments applied to two invoices in vice versa order
        Initialize();

        // [GIVEN] Vendor "V" with two posted purchase invoices:
        VendorNo := LibraryPurch.CreateVendorNo();
        // [GIVEN] "PI1" with Amount Including VAT = 1000 (vendor ledger entry no. = "VLE_INV1")
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        InvoiceNo[1] := CreateAndPostPurchaseInvoiceWithAmount(VendorNo, Amount);
        FindVendorLedgerEntry(InvVendLedgerEntry[1], VendorNo, InvVendLedgerEntry[1]."Document Type"::Invoice, InvoiceNo[1]);
        // [GIVEN] "PI2" with Amount Including VAT = 1000 (vendor ledger entry no. = "VLE_INV2")
        InvoiceNo[2] := CreateAndPostPurchaseInvoiceWithAmount(VendorNo, Amount);
        FindVendorLedgerEntry(InvVendLedgerEntry[2], VendorNo, InvVendLedgerEntry[2]."Document Type"::Invoice, InvoiceNo[2]);

        // [GIVEN] Payment Reconciliation Journal ("Statement No." = "X") with two lines:
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo(),
          BankAccReconciliation."Statement Type"::"Payment Application");
        // [GIVEN] Line1: "Statement Line No." = 10000, "Account Type" = "Vendor", "Account No." = "V", "Transaction Text" = "PI2", "Transaction Amount" = -1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[1], BankAccReconciliation, VendorNo, InvoiceNo[2], -Amount);
        // [GIVEN] Line2: "Statement Line No." = 20000, "Account Type" = "Vendor", "Account No." = "V", "Transaction Text" = "PI1", "Transaction Amount" = -1000
        CreateBankAccReconciliationLine(
          BankAccReconciliationLine[2], BankAccReconciliation, VendorNo, InvoiceNo[1], -Amount);

        // [GIVEN] Perform "Apply automatically" action
        MatchBankReconLineAutomatically(BankAccReconciliation);

        // [GIVEN] Vendor ledger entry "VLE_INV1" has "Applies-To ID" = "X-20000"
        InvVendLedgerEntry[1].Find();
        Assert.AreEqual(
          BankAccReconciliationLine[2].GetAppliesToID(),
          InvVendLedgerEntry[1]."Applies-to ID", InvVendLedgerEntry[1].FieldCaption("Applies-to ID"));
        // [GIVEN] Vendor ledger entry "VLE_INV2" has "Applies-To ID" = "X-10000"
        InvVendLedgerEntry[2].Find();
        Assert.AreEqual(
          BankAccReconciliationLine[1].GetAppliesToID(),
          InvVendLedgerEntry[2]."Applies-to ID", InvVendLedgerEntry[2].FieldCaption("Applies-to ID"));

        // [WHEN] Post the journal
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccReconciliation);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] The journal has been posted and two invoices "PI1", "PI2" are closed:
        // [THEN] Vendor ledger entry "VLE_INV2" has "Open" = FALSE, "Closed by Entry No." = "VLE_PMT1", where
        // [THEN] Vendor ledger entry "VLE_PMT1": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        FindVendorLedgerEntry(
          PmtVendLedgerEntry, VendorNo, PmtVendLedgerEntry."Document Type"::Payment, BankAccReconciliationLine[1]."Statement No.");
        InvVendLedgerEntry[2].Find();
        Assert.AreEqual(false, InvVendLedgerEntry[2].Open, InvVendLedgerEntry[2].FieldCaption(Open));
        Assert.AreEqual(
          PmtVendLedgerEntry."Entry No.", InvVendLedgerEntry[2]."Closed by Entry No.",
          InvVendLedgerEntry[2].FieldCaption("Closed by Entry No."));
        // [THEN] Vendor ledger entry "VLE_INV1" has "Open" = FALSE, "Closed by Entry No." = "VLE_PMT2", where
        // [THEN] Vendor ledger entry "VLE_PMT2": "Document Type" = Payment, "Document No." = "X", "Amount" = 1000
        PmtVendLedgerEntry.Next();
        InvVendLedgerEntry[1].Find();
        Assert.AreEqual(false, InvVendLedgerEntry[1].Open, InvVendLedgerEntry[1].FieldCaption(Open));
        Assert.AreEqual(
          PmtVendLedgerEntry."Entry No.", InvVendLedgerEntry[1]."Closed by Entry No.",
          InvVendLedgerEntry[1].FieldCaption("Closed by Entry No."));
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure VATEntryCreatedWhenCopyVATSetupToJnlLineEnabledInBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 212403] VAT Entry is created when post Payment Reconciliation with enabled "Copy VAT Setup to Jnl. Line" in Payment Reconciliation

        Initialize();

        // [GIVEN] Payment Reconciliation with enabled "Copy VAT Setup to Jnl. Line"
        CreateBankAccReconSetCopyVATSetupInJnlLine(BankAccReconciliation, true);

        // [GIVEN] Payment Reconciliation Line
        CreateBankAccReconciliationLineWithVATGLAcc(BankAccReconciliationLine, BankAccReconciliation);

        // [WHEN] Post Payment Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation,
                                         BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry is created for Payment Reconciliation
        FindGLEntry(GLEntry, BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Account No.");
        FilterPmtVATEntry(VATEntry, BankAccReconciliationLine."Statement No.", GLEntry."Transaction No.");
        Assert.RecordCount(VATEntry, 1);
    end;

    [Test]
    [HandlerFunctions('PostAndReconcilePageHandler,PostAndReconcilePageStatementDateHandler')]
    [Scope('OnPrem')]
    procedure NoVATEntryCreatedWhenCopyVATSetupToJnlLineDisabledInBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 212403] VAT Entry is not created when post Payment Reconciliation with disabled  "Copy VAT Setup to Jnl. Line" in Payment Reconciliation

        Initialize();

        // [GIVEN] Payment Reconciliation with disabled "Copy VAT Setup to Jnl. Line"
        CreateBankAccReconSetCopyVATSetupInJnlLine(BankAccReconciliation, false);

        // [GIVEN] Payment Reconciliation Line
        CreateBankAccReconciliationLineWithVATGLAcc(BankAccReconciliationLine, BankAccReconciliation);

        // [WHEN] Post Payment Reconciliation
        UpdateBankAccRecStmEndingBalance(BankAccReconciliation,
                                         BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry is not created for Payment Reconciliation
        FindGLEntry(GLEntry, BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Account No.");
        FilterPmtVATEntry(VATEntry, BankAccReconciliationLine."Statement No.", GLEntry."Transaction No.");
        Assert.RecordCount(VATEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenAndVATPostingGroupsNotCopiesIfCopyVATSetupSetInGenJnlLine()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] General and VAT Posting groups not copies to General Journal Line from G/L Account when "Bank Acc. Recon. Rec. ID" is set in General Journal Line

        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        GenJournalLine.Init();
        GenJournalLine.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccount."No.");

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenAndVATPostingGroupsCopiesIfCopyVATSetupDoesNotSetInGenJnlLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] General and VAT Posting groups copies to General Journal Line from G/L Account when "Bank Acc. Recon. Rec. ID" is not set in General Journal Line

        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        GenJournalLine.Init();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", GLAccount."No.");

        GenJournalLine.TestField("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        GenJournalLine.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GenJournalLine.TestField("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        GenJournalLine.TestField("VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenJournalLine.TestField("Gen. Posting Type", GLAccount."Gen. Posting Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJnlLineHasCopyVATSetupToJnlLineByDefault()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] "Copy VAT Setup to Jnl. Line" is true by default in General Journal Line

        Initialize();

        GenJournalLine.Init();
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Insert();

        GenJournalLine.TestField("Copy VAT Setup to Jnl. Lines", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GenJnlLineInheritsCopyVATSetupToJnlLineFromBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 212403] "Copy VAT Setup to Jnl. Line" inherits from General Journal Batch to General Journal Line

        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.Insert(true);

        GenJournalLine.TestField("Copy VAT Setup to Jnl. Lines", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllFieldsExceptCopyVATSetupToJnlLineNonEditableOnPmtReconJnlsPage()
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 212403] All fields except "Copy VAT Setup to Jnl. Line" are not editable on "Pmt. Reconciliation Journals" page

        Initialize();

        PmtReconciliationJournals.OpenEdit();
        Assert.IsFalse(PmtReconciliationJournals."Bank Account No.".Editable(), 'Bank Account No.');
        Assert.IsFalse(PmtReconciliationJournals."Statement No.".Editable(), 'Statement No.');
        Assert.IsFalse(PmtReconciliationJournals."Total Transaction Amount".Editable(), 'Total Transaction Amount');
        Assert.IsFalse(PmtReconciliationJournals."Total Difference".Editable(), 'Total Difference');
        Assert.IsTrue(PmtReconciliationJournals."Copy VAT Setup to Jnl. Line".Editable(), 'Copy VAT Setup to Jnl. Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATSetupDoesNotCopyToGenJnlLineByBatchValueWhenRecordInsertsAfterGLAccValidation()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255555] VAT Setup does not copy to General Journal Line based on "Copy VAT Setup to Jnl. Lines" value of General Journal Batch when record inserts after G/L Account Validation

        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalLine.Insert(true);

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_VATSetupDoesNotCopyToGenJnlLineByFieldValueWhenRecordInsertsAfterGLAccValidation()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255555] VAT Setup does not copy to General Journal Line based on "Copy VAT Setup to Jnl. Lines" value of record when it inserts after G/L Account Validation

        Initialize();
        GenJournalLine.Init();
        GenJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJournalLine, GenJournalLine.FieldNo("Line No.")));
        GenJournalLine.Validate("Copy VAT Setup to Jnl. Lines", false);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        GenJournalLine.Insert(); // insert without trigger to avoid error on GenJournalBatch.GET

        GenJournalLine.TestField("Gen. Bus. Posting Group", '');
        GenJournalLine.TestField("Gen. Prod. Posting Group", '');
        GenJournalLine.TestField("VAT Bus. Posting Group", '');
        GenJournalLine.TestField("VAT Prod. Posting Group", '');
        GenJournalLine.TestField("Gen. Posting Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportCAMT053_BankAccountID()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [SEPA CAMT] [CAMT 053] [Bank Account ID]
        // [SCENARIO 273063] Import CAMT 053 when only Bank Account Id is specified in Stmt/Acct/Id/Othr/Id
        Initialize();

        // [GIVEN] Bank account with SEPA CAMT 053 setup
        CreateBankAcc(SEPA_CAMT_Txt, BankAccount, '');

        // [GIVEN] XML file with Bank Account Id specified in Stmt/Acct/Id/Othr/Id
        WriteCAMTFile_BankAccID(BankAccount."Bank Account No.");

        // [WHEN] Import bank statement
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliation.ImportBankStatement();

        // [THEN] The file has been imported and a line has been created
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");
        BankAccReconciliationLine.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTableRelationStatementNoInPostedPmtPeconLineToPostedPmtReconHdr()
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
        PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr";
    begin
        // [SCENARIO 346379] Field Statement No. in the table Posted Payment Recon. Line has a relation to table Posted Payment Recon. Hdr.
        Initialize();

        // [GIVEN] Created Posted Payment Recon. Header
        PostedPaymentReconHdr.Init();
        PostedPaymentReconHdr."Bank Account No." := LibraryERM.CreateBankAccountno();
        PostedPaymentReconHdr."Statement No." := LibraryUtility.GenerateGUID();
        PostedPaymentReconHdr.Insert();
        Commit();

        // [WHEN] Validate field "Statement No." in "Posted Payment Recon. Line"
        PostedPaymentReconLine.Init();
        PostedPaymentReconLine.Validate("Bank Account No.", PostedPaymentReconHdr."Bank Account No.");
        PostedPaymentReconLine.Validate("Statement No.", PostedPaymentReconHdr."Statement No.");

        // [THEN] The field validated correctly
        PostedPaymentReconLine.TestField("Statement No.", PostedPaymentReconHdr."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MsgHandler,ReviewRequiredSendNotificationHandler')]
    procedure ShowReviewRequiredNotification()
    var
        SalesHeader: Record "Sales Header";
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary;
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [UI] [Application Rules] [Notification]
        // [SCENARIO 413337] Stan doesn't get "Review Required" notification when system does not have any rule with "Review Required" = true
        BankAccReconciliation.DeleteAll(true);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CopyApplRulesToTemp(TempBankPmtApplRule);
        BankPmtApplRule.ModifyAll("Review Required", false, false);

        LibraryVariableStorage.Enqueue(ListEmptyMsg);
        LibraryVariableStorage.Enqueue(ListEmptyMsg);

        CreatePaymentReconciliationAndMatchAutomatically(PaymentReconciliationJournal, InvoiceNo, SalesHeader."Amount Including VAT");

        PaymentReconciliationJournal."Match Confidence".AssertEquals(BankPmtApplRule."Match Confidence"::Medium);

        RestoreApplRulesReviewRequiredFromTemp(TempBankPmtApplRule);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceAfterPostingConsidersBankAccountLines()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amounts: array[2] of Decimal;
    begin
        // [FEATURE] [UI] [Payment Reconciliation Journal]
        // [SCENARIO 419580] System considers reconsilation lines with Account Type = "Bank Account" when it calculates ending balance after posting.
        Initialize();

        // [GIVEN] Payment Reconciliation Journal for the Bank Acount "B1" with two lines
        // [GIVEN] [1]: "Account Type" = "G/L Account", "Account No." = 2910, "Applied Amount" = 100
        // [GIVEN] [2]: "Account Type" = "Bank Account", "Account No." = "B2", "Applied Amount" = 1000
        Amounts[1] := LibraryRandom.RandIntInRange(100, 200);
        Amounts[2] := LibraryRandom.RandIntInRange(1000, 2000);

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");

        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);

        PaymentReconciliationJournal.Trap();

        BankAccReconciliation.OpenWorksheet(BankAccReconciliation);

        PaymentReconciliationJournal."Transaction Date".SetValue(WorkDate());
        PaymentReconciliationJournal."Statement Amount".SetValue(Amounts[1]);
        PaymentReconciliationJournal."Account Type".SetValue(BankAccReconciliationLine."Account Type"::"G/L Account");
        PaymentReconciliationJournal."Account No.".SetValue(LibraryERM.CreateGLAccountNo());

        PaymentReconciliationJournal.Next();

        PaymentReconciliationJournal."Transaction Date".SetValue(WorkDate());
        PaymentReconciliationJournal."Statement Amount".SetValue(Amounts[2]);
        PaymentReconciliationJournal."Account Type".SetValue(BankAccReconciliationLine."Account Type"::"Bank Account");
        PaymentReconciliationJournal."Account No.".SetValue(LibraryERM.CreateBankAccountNo());

        // [WHEN] When validate amounts on the given lines
        // [THEN] "Balance After Posting" = 100 + 1000 = 1100.
        PaymentReconciliationJournal.BalanceOnBankAccountAfterPostingFixedLayout.AssertEquals(Amounts[1] + Amounts[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentRecJnlStatementEndingBalanceZero()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        TempBlobUTF8: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Payment Reconciliation Journal] [UT]
        // [SCENARIO 421360] Statement Ending Balance field is not visible if it is 0
        Initialize();

        // [GIVEN] Mock Bank reconciliation "BR" with "Statement Ending Balance" = 0
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        BankAccRecon.TestField("Statement Ending Balance", 0);

        // [WHEN] Open Payment Reconcilation Journal for "BR"
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [THEN] Statement Ending Balance field is always visible and a "-" is displayed as the field does not apply.
        Assert.IsTrue(PmtReconJnl.StatementEndingBalanceFixedLayout.Visible(), 'Statement Ending Balance must be always visible to avoid epmty space');
        Assert.AreEqual(PmtReconJnl.StatementEndingBalanceFixedLayout.Value(), '-', 'Statements with ending balance 0 should show -')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentRecJnlStatementEndingBalanceNotZero()
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // [FEATURE] [Payment Reconciliation Journal] [UT]
        // [SCENARIO 421360] Statement Ending Balance field is visible if it is <> 0
        Initialize();

        // [GIVEN] Mock Bank reconciliation "BR" with "Statement Ending Balance" <> 0
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        BankAccRecon.TestField("Statement Ending Balance");

        // [WHEN] Open Payment Reconcilation Journal for "BR"
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);

        // [THEN] Statement Ending Balance field is visible
        Assert.IsTrue(PmtReconJnl.StatementEndingBalanceFixedLayout.Visible(), 'Statement Ending Balance must be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifyTestReportRequestPage')]
    procedure OutstandingPaymentsControlShouldShowOnTestReport()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
        BankAccReconciliationList: TestPage "Bank Acc. Reconciliation List";
        BankAccReconciliationTestPage: TestPage "Bank Acc. Reconciliation";
    begin
        // [SCENARIO] When the test report is printed from the Bank Account Reconciliation page, it should show the "Print Outstanding Payments" option
        BindSubscription(PaymentReconE2ETests2);
        ClearBankAccReconciliations();
        // [GIVEN] A Bank Acc. Reconciliation
        BankAccReconciliation.Init();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        // [WHEN] Invoking TestReport from Bank Acc. Reconciliation
        LibraryVariableStorage.Enqueue(true); // Expected value of PrintOutstdTransac
        BankAccReconciliationList.OpenView();
        BankAccReconciliationList.GoToRecord(BankAccReconciliation);
        BankAccReconciliationTestPage.Trap();
        BankAccReconciliationList.Edit().Invoke();
        BankAccReconciliationTestPage."&Test Report".Invoke();
        // [THEN] The control PrintOutstdTransac should not be visible (in VerifyTestReportRequestPage)
        ClearBankAccReconciliations();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('VerifyTestReportRequestPage')]
    procedure OutstandingPaymentsControlShouldNotShowOnTestReport()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        PaymentReconE2ETests2: Codeunit "Payment Recon. E2E Tests 2";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        // [SCENARIO] When the test report is printed from the Payment Reconciliation Journal page, it should NOT show the "Print Outstanding Payments" option
        BindSubscription(PaymentReconE2ETests2);
        ClearBankAccReconciliations();
        // [GIVEN] A Bank Acc. Reconciliation
        BankAccReconciliation.Init();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        // [WHEN] Invoking TestReport from Payment Reconciliation Journal
        LibraryVariableStorage.Enqueue(false); // Expected value of PrintOutstdTransac
        OpenPmtReconJnl(BankAccReconciliation, PaymentReconciliationJournal);
        PaymentReconciliationJournal.TestReport.Invoke();
        // [THEN] The control PrintOutstdTransac should not be visible (in VerifyTestReportRequestPage)
        ClearBankAccReconciliations();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler,ReversalUndoStatementHandler,ReversalRelatedHandler,ReversalFinalizeHandler')]
    procedure ReversePaymentRecJournal()
    var
        SalesHeader: Record "Sales Header";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr";
        BankAccountStatement: Record "Bank Account Statement";
        ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        StatementEndingBalance: Decimal;
        InvoiceNo: Code[20];
        SalesHeaderNo: Code[20];
        BankAccNo: Code[20];
        StatementNo: Code[20];
    begin
        // [SCENARIO] A user that has posted a Payment Rec Journal with post and reconcile wants to reverse it
        // [GIVEN] A posted and reconciled Paym Rec Journal
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        SalesHeaderNo := SalesHeader."No.";
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreatePaymentReconciliationAndMatchAutomatically(PaymentReconciliationJournal, InvoiceNo, SalesHeader."Amount Including VAT", BankAccReconciliation);
        BankAccNo := BankAccReconciliation."Bank Account No.";
        StatementNo := BankAccReconciliation."Statement No.";
        BankAccReconciliation."Statement Date" := WorkDate();
        Evaluate(StatementEndingBalance, PaymentReconciliationJournal."Statement Amount".Value());
        BankAccReconciliation."Statement Ending Balance" := StatementEndingBalance;
        BankAccReconciliation.Modify();
        PaymentReconciliationJournal.Post.Invoke();

        // [WHEN] Running the Reversal Wizard with default selection
        PostedPaymentReconHdr.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        ReversePaymentRecJournal.RunReversalWizard(PostedPaymentReconHdr);

        Commit();
        // [THEN] the original bank statement shouldn't exist
        asserterror BankAccReconciliation.Get(BankAccNo, StatementNo);
        asserterror BankAccountStatement.Get(BankAccNo, StatementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MsgHandler,ConfirmHandlerYes,PostAndReconcilePageHandler,ReversalUndoStatementCancelYesHandler,ReversalRelatedHandler,ReversalFinalizeHandler')]
    procedure ReversePaymentRecJournalWhenPreviouslyUndone()
    var
        SalesHeader: Record "Sales Header";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountStatement: Record "Bank Account Statement";
        PostedPaymentReconHdr: Record "Posted Payment Recon. Hdr";
        ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
        StatementEndingBalance: Decimal;
        InvoiceNo: Code[20];
        SalesHeaderNo: Code[20];
        BankAccNo: Code[20];
        StatementNo: Code[20];
    begin
        // [SCENARIO] A user that has posted a Payment Rec Journal with post and reconcile, undoes the bank statment, and then wants to reverse it
        // [GIVEN] A posted and reconciled Paym Rec Journal
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        SalesHeaderNo := SalesHeader."No.";
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreatePaymentReconciliationAndMatchAutomatically(PaymentReconciliationJournal, InvoiceNo, SalesHeader."Amount Including VAT", BankAccReconciliation);
        BankAccNo := BankAccReconciliation."Bank Account No.";
        StatementNo := BankAccReconciliation."Statement No.";
        BankAccReconciliation."Statement Date" := WorkDate();
        Evaluate(StatementEndingBalance, PaymentReconciliationJournal."Statement Amount".Value());
        BankAccReconciliation."Statement Ending Balance" := StatementEndingBalance;
        BankAccReconciliation.Modify();
        PaymentReconciliationJournal.Post.Invoke();
        Commit();

        // [GIVEN] The reversal of the payment rec. journal was executed and canceled
        LibraryVariableStorage.Enqueue(true);
        PostedPaymentReconHdr.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        ReversePaymentRecJournal.RunReversalWizard(PostedPaymentReconHdr);

        // [GIVEN] The bank account statement created is undone
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
        UndoBankStatementYesNo.UndoBankAccountStatement(BankAccountStatement, false);
        Commit();

        // [WHEN] Running the Reversal Wizard with default selection
        LibraryVariableStorage.Enqueue(false);
        ReversePaymentRecJournal.RunReversalWizard(PostedPaymentReconHdr);
        // [THEN] there should be no errors
        // [THEN] the original bank statement shouldn't exist
        asserterror BankAccReconciliation.Get(BankAccNo, StatementNo);
        asserterror BankAccountStatement.Get(BankAccNo, StatementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MsgHandler')]
    procedure BankAccountReconciliationDoesNotExistIfImportBankStatement()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccReconciliationListPage: TestPage "Bank Acc. Reconciliation List";
    begin
        // [SCENARIO 477062] Verify Bank Account Reconciliation is created If we import bank statements for only one bank account in the company.
        Initialize();

        // [GIVEN] Delete all the bank accounts.
        BankAccount.DeleteAll();

        // [GIVEN] Create a new bank account.
        CreateBankAcc(SEPA_CAMT_Txt, BankAccount, '');

        // [GIVEN] Creates an XML file with the bank account ID.
        WriteCAMTFile_BankAccID(BankAccount."Bank Account No.");

        // [GIVEN] Create a new bank account reconciliation.
        BankAccReconciliationPage.Trap();
        BankAccReconciliationListPage.OpenNew();

        // [WHEN] Import a bank statement.
        BankAccReconciliationPage.OpenEdit();
        BankAccReconciliationPage.ImportBankStatement.Invoke();

        // [Verify] Verify that a bank account reconciliation line has been created.
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccount."No.");

        Assert.RecordIsNotEmpty(BankAccReconciliationLine);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Recon. E2E Tests 2");
        LibrarySetupStorage.Restore();
        if BankPmtApplSettings.Get() then
            BankPmtApplSettings.Delete();

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 2");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateVendPostingGrp();

        Initialized := true;
        Commit();

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Recon. E2E Tests 2");
    end;

    local procedure ClearBankAccReconciliations()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Reset();
        BankAccount.DeleteAll();
        BankAccReconciliation.Reset();
        BankAccReconciliation.DeleteAll();
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

    local procedure CreateVendor(var Vend: Record Vendor)
    begin
        LibraryPurch.CreateVendor(Vend);
        Vend.Validate(Name, LibraryUtility.GenerateRandomText(10));
        Vend.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateManualCheckAndPostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; BankAccNo: Code[20]; StmtAmt: Decimal)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine,
          GenJnlTemplate.Name,
          GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment,
          GenJnlLine."Account Type"::Vendor,
          VendLedgEntry."Vendor No.",
          GenJnlLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          StmtAmt);

        GenJnlLine.Validate("Bank Payment Type", GenJnlLine."Bank Payment Type"::"Manual Check");
        GenJnlLine.Validate("Applies-to Doc. Type", VendLedgEntry."Document Type");
        GenJnlLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");
        GenJnlLine.Validate("External Document No.", VendLedgEntry."External Document No.");
        GenJnlLine.Modify(true);
        Commit();

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        Commit();
    end;

    local procedure CreatePaymentReconciliationAndMatchAutomatically(var PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal"; InvoiceNo: Code[20]; PaymentAmount: Decimal)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        CreatePaymentReconciliationAndMatchAutomatically(PaymentReconciliationJournal, InvoiceNo, PaymentAmount, BankAccReconciliation);
    end;

    local procedure CreatePaymentReconciliationAndMatchAutomatically(var PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal"; InvoiceNo: Code[20]; PaymentAmount: Decimal; var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        NoSeriesCode: Code[20];
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccount."No.", BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccount."Pmt. Rec. No. Series" := NoSeriesCode;
        BankAccount.Modify();

        PaymentReconciliationJournal.Trap();
        BankAccReconciliation.OpenWorksheet(BankAccReconciliation);
        PaymentReconciliationJournal."Transaction Date".SetValue(WorkDate());
        PaymentReconciliationJournal."Transaction Text".SetValue(InvoiceNo);
        PaymentReconciliationJournal."Statement Amount".SetValue(PaymentAmount);
        PaymentReconciliationJournal."Account Type".SetValue(BankAccReconciliationLine."Account Type"::Customer);
        PaymentReconciliationJournal."Match Confidence".AssertEquals(BankAccReconciliationLine."Match Confidence"::None);

        PaymentReconciliationJournal.ApplyAutomatically.Invoke();
    end;

    local procedure CreateBankAccReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; CurrencyCode: Code[10])
    var
        BankAcc: Record "Bank Account";
    begin
        CreateBankAcc(SEPA_CAMT_Txt, BankAcc, CurrencyCode);
        CreateBankReconAndImportStmt(BankAccRecon, TempBlobUTF8, BankAcc);
    end;

    local procedure CreateBankReconAndImportStmt(var BankAccRecon: Record "Bank Acc. Reconciliation"; var TempBlobUTF8: Codeunit "Temp Blob"; BankAcc: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.", BankAccRecon."Statement Type"::"Payment Application");
        SetupSourceMock(SEPA_CAMT_Txt, TempBlobUTF8);
        BankAccRecon.ImportBankStatement();

        BankAccRecon.CalcFields("Total Transaction Amount");
    end;

    local procedure CreateUnpaidDocs(var OutStream: OutStream; var VendLedgEntry: array[20] of Record "Vendor Ledger Entry"; var RentGLAcc: Record "G/L Account"; var InterestGLAcc: Record "G/L Account")
    begin
        WriteCAMTHeader(OutStream, '', 'TEST');

        OnePurchOnePmt(VendLedgEntry[1], OutStream);
        OnePurchTwoPmt(VendLedgEntry[2], OutStream);
        TwoPurchTwoPmt(VendLedgEntry[3], VendLedgEntry[4], OutStream);
        TwoPurchOnePmt(VendLedgEntry[5], VendLedgEntry[6], OutStream);

        OnePurchOnePmtWithPmtDisc(VendLedgEntry[7], OutStream);
        OnePurchTwoPmtWithPmtDisc(VendLedgEntry[8], OutStream);
        TwoPurchTwoPmtWithPmtDisc(VendLedgEntry[9], VendLedgEntry[10], OutStream);
        TwoPurchOnePmtWithPmtDisc(VendLedgEntry[11], VendLedgEntry[12], OutStream);

        OnePurchOnePmtWithLateDueDatePmtDisc(VendLedgEntry[13], OutStream, '');
        OnePurchOnePmtWithWrongPmtDiscPct(VendLedgEntry[14], OutStream);

        // BankTransfer(BankAcc,OutStream);

        RecurringRent(RentGLAcc, OutStream);
        RecurringInterest(InterestGLAcc, OutStream);

        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithAmount(VendorNo: Code[20]; Amount: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurch.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurch.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        exit(LibraryPurch.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateBankAccReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; VendorNo: Code[20]; InvoiceNo: Code[20]; StatementAmount: Decimal)
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Transaction Text", InvoiceNo);
        BankAccReconciliationLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::Vendor);
        BankAccReconciliationLine.Validate("Account No.", VendorNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateBankAccReconSetCopyVATSetupInJnlLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; CopyVATSetupToJnlLine: Boolean)
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, LibraryERM.CreateBankAccountNo(),
          BankAccReconciliation."Statement Type"::"Payment Application");
        BankAccReconciliation.Validate("Copy VAT Setup to Jnl. Line", CopyVATSetupToJnlLine);
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankAccReconciliationLineWithVATGLAcc(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        BankAccReconciliationLine.Validate(Description, BankAccReconciliationLine."Document No.");
        BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDec(100, 2));
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        BankAccReconciliationLine.Validate("Account No.", GLAccNo);
        BankAccReconciliationLine.Modify(true);
        BankAccReconciliationLine.TransferRemainingAmountToAccount();
    end;

    local procedure CopyApplRulesToTemp(var TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        TempBankPmtApplRule.Reset();
        TempBankPmtApplRule.DeleteAll();

        if BankPmtApplRule.FindSet() then
            repeat
                TempBankPmtApplRule := BankPmtApplRule;
                TempBankPmtApplRule.Insert();
            until BankPmtApplRule.Next() = 0;
    end;

    local procedure RestoreApplRulesReviewRequiredFromTemp(var TempBankPmtApplRule: Record "Bank Pmt. Appl. Rule" temporary)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if TempBankPmtApplRule.FindSet() then
            repeat
                if BankPmtApplRule.Get(TempBankPmtApplRule."Match Confidence", TempBankPmtApplRule.Priority) then begin
                    BankPmtApplRule."Review Required" := TempBankPmtApplRule."Review Required";
                    BankPmtApplRule.Modify();
                end;
            until TempBankPmtApplRule.Next() = 0;
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

    local procedure FilterPmtVATEntry(var VATEntry: Record "VAT Entry"; DocNo: Code[20]; TransactionNo: Integer)
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.SetRange("Transaction No.", TransactionNo);
    end;

    local procedure AddTextMapperRules(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; InterestGLAcc: Record "G/L Account"; RentGLAcc: Record "G/L Account")
    begin
        PmtReconJnl.Last();
        LibraryVariableStorage.Enqueue(InterestGLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke();

        PmtReconJnl.Previous();
        LibraryVariableStorage.Enqueue(RentGLAcc."No.");
        PmtReconJnl.AddMappingRule.Invoke();
    end;

    local procedure ApplyAutomatically(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        PmtReconJnl.ApplyAutomatically.Invoke();
        Commit();
        PmtReconJnl.First();
    end;

    local procedure ApplyManually(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var VendLedgEntry: array[20] of Record "Vendor Ledger Entry")
    begin
        // Without Pmt Disc

        // OnePurchOnePmt
        PmtReconJnl.First();
        HandlePmtEntries(VendLedgEntry[1], PmtReconJnl);
        // OnePurchTwoPmt
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[2], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[2], PmtReconJnl);
        // TwoPurchTwoPmt
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[3], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[4], PmtReconJnl);
        // TwoPurchOnePmt
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[5], PmtReconJnl);
        HandlePmtEntries(VendLedgEntry[6], PmtReconJnl);

        // OnePurchOnePmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[7], PmtReconJnl);
        // OnePurchTwoPmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[8], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[8], PmtReconJnl);
        // TwoPurchTwoPmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[9], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[10], PmtReconJnl);
        // TwoPurchOnePmtWithPmtDisc
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry[11], PmtReconJnl);
        HandlePmtEntries(VendLedgEntry[12], PmtReconJnl);

        PmtReconJnl.Next();
        HandlePmtDiscDate(VendLedgEntry[13], PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtDiscAmt(VendLedgEntry[14], PmtReconJnl);

        // PmtReconJnl.Next();
        // HandleBankTransAmt(BankAcc,PmtReconJnl);
        PmtReconJnl.Next();
        HandleRecurringInterestAmt(PmtReconJnl);

        PmtReconJnl.Next();
        HandleRecurringRentAmt(PmtReconJnl);
    end;

    local procedure MatchBankReconLineAutomatically(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
    end;

    local procedure SetOnMatchOnClosingDocumentNumber()
    var
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
    begin
        BankPmtApplSettings.GetOrInsert();
        BankPmtApplSettings."Bank Ledg Closing Doc No Match" := true;
        BankPmtApplSettings.Modify();
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

    local procedure WriteCAMTFile_BankAccID(BankAccountID: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        LibraryCAMTFileMgt.WriteCAMTHeader(OutStream);
        LibraryCAMTFileMgt.WriteCAMTStmtHeaderWithBankID(
          OutStream, 'TEST', '2018-01-01T12:00:00+00:00', '', BankAccountID, '100', '01-01-2018', '100', '01-01-2018');
        WriteCAMTStmtLine(OutStream, WorkDate(), 'TEST CAMT BANK ID', 1000, '');
        WriteCAMTFooter(OutStream);
        SetupSourceMock(SEPA_CAMT_Txt, TempBlob);
    end;

    local procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryCAMTFileMgt.SetupSourceMock(DataExchDefCode, TempBlob);
    end;

    [Scope('OnPrem')]
    procedure OnePurchOnePmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Posting Date", VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchOnePmtExcessiveAmount(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; Excessiveamount: Decimal)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        WriteCAMTStmtLine(OutStream,
              VendLedgEntry."Posting Date", VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible" - Excessiveamount, VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchTwoPmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        HalfAmt: Decimal;
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        HalfAmt := Round(VendLedgEntry."Remaining Amount" / 2);
        WriteCAMTStmtLine(OutStream, VendLedgEntry."Posting Date", VendLedgEntry."Document No.", HalfAmt, VendLedgEntry."Currency Code");
        WriteCAMTStmtLine(
          OutStream, VendLedgEntry."Posting Date", VendLedgEntry."Document No.",
          VendLedgEntry."Remaining Amount" - HalfAmt - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
    end;

    [Scope('OnPrem')]
    procedure TwoPurchTwoPmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Posting Date", VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
        WriteCAMTStmtLine(
              OutStream, VendLedgEntry2."Posting Date", VendLedgEntry2."Document No.", VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible", VendLedgEntry2."Currency Code");
    end;

    local procedure TwoPurchOnePmt(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Posting Date", StrSubstNo('%1;%2', VendLedgEntry."Document No.", VendLedgEntry2."Document No."),
              VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible" +
              VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible",
              VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchOnePmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchTwoPmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
        HalfAmt: Decimal;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');

        HalfAmt := Round(VendLedgEntry."Remaining Amount" / 2);
        WriteCAMTStmtLine(OutStream, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Document No.", HalfAmt, VendLedgEntry."Currency Code");
        WriteCAMTStmtLine(
          OutStream, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Document No.",
          VendLedgEntry."Remaining Amount" - HalfAmt - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
    end;

    local procedure TwoPurchTwoPmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Pmt. Discount Date", VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
        WriteCAMTStmtLine(
              OutStream, VendLedgEntry2."Pmt. Discount Date", VendLedgEntry2."Document No.", VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible", VendLedgEntry2."Currency Code");
    end;

    local procedure TwoPurchOnePmtWithPmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
    begin
        CreateVendWithPmtDisc(Vend);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, '');
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry2, '');

        WriteCAMTStmtLine(
              OutStream, VendLedgEntry."Pmt. Discount Date", StrSubstNo('%1;%2', VendLedgEntry."Document No.", VendLedgEntry2."Document No."),
              VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible" +
              VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible",
              VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchOnePmtWithLateDueDatePmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; CurrencyCode: Code[10])
    var
        Vend: Record Vendor;
        PmtTerms: Record "Payment Terms";
    begin
        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, CurrencyCode);

        WriteCAMTStmtLine(
              OutStream,
              CalcDate('<+1D>', VendLedgEntry."Pmt. Discount Date"),
              VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible", VendLedgEntry."Currency Code");
    end;

    local procedure OneFCYPurchOnePmtWithLateDueDatePmtDisc(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    var
        Vend: Record Vendor;
        PmtTerms: Record "Payment Terms";
        Curr: Record Currency;
        StmtAmt: Decimal;
    begin
        Curr.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10));

        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);

        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, Curr.Code);

        StmtAmt :=
  VendLedgEntry."Remaining Amt. (LCY)" -
  Round(VendLedgEntry."Remaining Pmt. Disc. Possible" * (VendLedgEntry."Remaining Amt. (LCY)" / VendLedgEntry."Remaining Amount"));

        WriteCAMTStmtLine(
          OutStream,
          CalcDate('<+1D>', VendLedgEntry."Pmt. Discount Date"),
          VendLedgEntry."Document No.", StmtAmt, VendLedgEntry."Currency Code");
    end;

    local procedure OnePurchOnePmtWithWrongPmtDiscPct(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream)
    begin
        CreateVendAndPostPurchInvoice(VendLedgEntry, '');

        WriteCAMTStmtLine(
              OutStream,
              VendLedgEntry."Pmt. Discount Date",
              VendLedgEntry."Document No.", VendLedgEntry."Remaining Amount" + Round(VendLedgEntry."Remaining Pmt. Disc. Possible" - 5 / 100 * VendLedgEntry."Remaining Amount"),
              VendLedgEntry."Currency Code");
    end;

    local procedure RecurringInterest(var GLAcc: Record "G/L Account"; var OutStream: OutStream)
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Interest');
        GLAcc.Modify(true);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM+1D>', WorkDate()), GLAcc."No." + ' Bank Interest', -200, '');
    end;

    local procedure BankTransfer(var BankAcc: Record "Bank Account"; var OutStream: OutStream; TransferAmount: Decimal)
    begin
        LibraryERM.CreateBankAccount(BankAcc);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate()), BankAcc."No." + ' Bank Transfer', TransferAmount, '');
    end;

    local procedure RecurringRent(var GLAcc: Record "G/L Account"; var OutStream: OutStream)
    begin
        LibraryERM.CreateGLAccount(GLAcc);
        GLAcc.Validate(Name, 'Rent');
        GLAcc.Modify(true);
        WriteCAMTStmtLine(OutStream, CalcDate('<CM>', WorkDate()), 'Rent', -10000, '');
    end;

    [Scope('OnPrem')]
    procedure HandlePmtEntries(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, false, false, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandlePmtDiscDate(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, true, false, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandlePmtDiscAmt(VendLedgEntry: Record "Vendor Ledger Entry"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          VendLedgEntry."Vendor No.", VendLedgEntry."Entry No.", VendLedgEntry."Remaining Amt. (LCY)",
          PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), true, false, false, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandleRecurringInterestAmt(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          '', 0, 0, PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, false, true, false);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure HandleRecurringRentAmt(var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    begin
        EnqueueValuesForPmtApplnHandler(
          '', 0, 0, PmtReconJnl."Transaction Date".AsDate(), PmtReconJnl."Statement Amount".AsDecimal(), false, false, false, true);
        PmtReconJnl.ApplyEntries.Invoke();
    end;

    local procedure EnqueueValuesForPmtApplnHandler(VendorNo: Code[20]; VLEEntryNo: Integer; VLERemAmtLCY: Decimal; TransactionDate: Date; StatementAmount: Decimal; AdjustDiscountAmount: Boolean; AdjustDiscountDate: Boolean; IsRecurringInterest: Boolean; IsRecurringRent: Boolean)
    begin
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(VLEEntryNo);
        LibraryVariableStorage.Enqueue(VLERemAmtLCY);
        LibraryVariableStorage.Enqueue(TransactionDate);
        LibraryVariableStorage.Enqueue(StatementAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountAmount);
        LibraryVariableStorage.Enqueue(AdjustDiscountDate);
        LibraryVariableStorage.Enqueue(IsRecurringInterest);
        LibraryVariableStorage.Enqueue(IsRecurringRent);
    end;

    local procedure CreateVendWithPmtDisc(var Vend: Record Vendor)
    var
        PmtTerms: Record "Payment Terms";
    begin
        CreateVendor(Vend);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vend.Validate("Payment Terms Code", PmtTerms.Code);
        Vend.Modify(true);
    end;

    local procedure CreateVendAndPostPurchInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        Vend: Record Vendor;
    begin
        CreateVendor(Vend);
        CreatePurchInvoiceAndPost(Vend, VendLedgEntry, CurrencyCode);
    end;

    local procedure CreatePurchInvoiceAndPost(var Vend: Record Vendor; var VendLedgEntry: Record "Vendor Ledger Entry"; CurrencyCode: Code[10])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.");
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomText(10));
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurch.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.", 1);
        PurchLine.Validate("Direct Unit Cost", 100);
        PurchLine.Modify(true);

        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange("Document No.", LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
        VendLedgEntry.FindFirst();

        VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
    end;

    local procedure PostPayment(var VendLedgerEntry: Record "Vendor Ledger Entry"; BankAccNo: Code[20])
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
          GenJournalLine."Account Type"::Vendor,
          VendLedgerEntry."Vendor No.",
          GenJournalLine."Bal. Account Type"::"Bank Account",
          BankAccNo,
          -VendLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", VendLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJournalLine.Validate("External Document No.", VendLedgerEntry."External Document No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentToGLAccount(GLAccountNo: Code[20]; BankAccNo: Code[20]; Amount: Decimal; LineDescription: Text)
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

        GenJournalLine.Description := CopyStr(LineDescription, 1, MaxStrLen(GenJournalLine.Description));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostBankTransfer(BankAccNo: Code[20]; BalBankAccNo: Code[20]; TransferAmount: Decimal)
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
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyPrePost(BankAccRecon: Record "Bank Acc. Reconciliation"; var PmtReconJnl: TestPage "Payment Reconciliation Journal")
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        PmtReconJnl.First();
        repeat
            PmtReconJnl.Difference.AssertEquals(0);
            PmtReconJnl."Applied Amount".AssertEquals(PmtReconJnl."Statement Amount".AsDecimal());
        until not PmtReconJnl.Next();

        BankAccReconLine.LinesExist(BankAccRecon);
        repeat
            AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconLine);
            Assert.AreEqual(AppliedPmtEntry.Count, BankAccReconLine."Applied Entries", 'Checking the Applied Entries field on Tab273');
        until BankAccReconLine.Next() = 0;
    end;

    local procedure VerifyVendLedgEntry(VendNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange(Open, true);
        Assert.IsTrue(VendLedgEntry.IsEmpty, 'All entries are closed')
    end;

    local procedure VerifyVendLedgEntryExcessiveAmount(VendNo: Code[20]; ExcessiveAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetAutoCalcFields("Remaining Amount");
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetRange("Remaining Amount", ExcessiveAmount);
        Assert.AreEqual(1, VendLedgEntry.Count, 'There should be one open ledger entry for the excessive amount.')
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
        VendorNo: Code[20];
        VLEEntryNo: Integer;
        VLERemAmtLCY: Decimal;
        PmtReconJnlTransactionDate: Date;
        PmtReconJnlStatementAmount: Decimal;
        AdjustDiscountAmount: Boolean;
        AdjustDiscountDate: Boolean;
        IsRecurringInterest: Boolean;
        IsRecurringRent: Boolean;
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VendorNo));
        VLEEntryNo := LibraryVariableStorage.DequeueInteger();
        VLERemAmtLCY := LibraryVariableStorage.DequeueDecimal();
        PmtReconJnlTransactionDate := LibraryVariableStorage.DequeueDate();
        PmtReconJnlStatementAmount := LibraryVariableStorage.DequeueDecimal();
        AdjustDiscountAmount := LibraryVariableStorage.DequeueBoolean();
        AdjustDiscountDate := LibraryVariableStorage.DequeueBoolean();
        IsRecurringInterest := LibraryVariableStorage.DequeueBoolean();
        IsRecurringRent := LibraryVariableStorage.DequeueBoolean();

        if IsRecurringRent or IsRecurringInterest then begin
            PmtAppln.RemainingAmountAfterPosting.AssertEquals(0);
            exit;
        end;
        // Remove Entry is not the same Vendor
        if PmtAppln.AppliedAmount.AsDecimal() <> 0 then
            if PmtAppln."Account No.".Value <> VendorNo then begin
                PmtAppln.Applied.SetValue(false);
                PmtAppln.Next();
            end;
        // Go to the first and check that it is the Vendor and scroll down to find the entry
        if PmtAppln.Applied.AsBoolean() then begin
            PmtAppln.RelatedPartyOpenEntries.Invoke();
            while PmtAppln."Applies-to Entry No.".AsInteger() <> VLEEntryNo do begin
                PmtAppln."Account No.".AssertEquals(VendorNo);
                PmtAppln.Next();
            end;
        end;
        // check that it is the Vendor ledger entry and apply
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
                  VLERemAmtLCY - PmtReconJnlStatementAmount);
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
    procedure TextMapperHandler(var TextToAccMapping: TestPage "Text-to-Account Mapping")
    var
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(GLAccountNo));
        TextToAccMapping."Debit Acc. No.".SetValue(GLAccountNo);
        TextToAccMapping."Credit Acc. No.".SetValue(GLAccountNo);
        TextToAccMapping.OK().Invoke();
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
    procedure PmtApplnAllOpenPaymentsHandler(var PmtAppln: TestPage "Payment Application")
    var
        VendorNo: Code[20];
    begin
        VendorNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(VendorNo));
        // dummy dequeues
        LibraryVariableStorage.DequeueInteger();
        LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.DequeueDate();
        LibraryVariableStorage.DequeueDecimal();
        LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.DequeueBoolean();
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

    [Scope('OnPrem')]
    procedure CreateOnePurchOnePmtOutstream(var VendLedgEntry: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        OnePurchOnePmt(VendLedgEntry, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    [Scope('OnPrem')]
    procedure CreateTwoPurchTwoPmtOutstream(var VendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry2: Record "Vendor Ledger Entry"; var OutStream: OutStream; var TempBlobUTF8: Codeunit "Temp Blob")
    begin
        Initialize();
        TempBlobUTF8.CreateOutStream(OutStream, TEXTENCODING::UTF8);

        WriteCAMTHeader(OutStream, '', 'TEST');
        TwoPurchTwoPmt(VendLedgEntry, VendLedgEntry2, OutStream);
        WriteCAMTFooter(OutStream);
    end;

    local procedure CreateApplyHandleAndPostPmtReconJnl(TempBlobUTF8: Codeunit "Temp Blob"; VendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry2: Record "Vendor Ledger Entry")
    var
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PmtReconJnl: TestPage "Payment Reconciliation Journal";
    begin
        // Exercise
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
        ApplyAutomatically(PmtReconJnl);
        HandlePmtEntries(VendLedgEntry, PmtReconJnl);
        PmtReconJnl.Next();
        HandlePmtEntries(VendLedgEntry2, PmtReconJnl);
        VerifyPrePost(BankAccRecon, PmtReconJnl);
        PmtReconJnl.Post.Invoke();

        // Verify that all Vendors | gls | banks go to zero
        VerifyVendLedgEntry(VendLedgEntry."Vendor No.");
        VerifyBankLedgEntry(BankAccRecon."Bank Account No.", BankAccRecon."Total Transaction Amount");
    end;

    local procedure OpenPmtReconJrnlOnePayment(var PmtReconJnl: TestPage "Payment Reconciliation Journal"; var VendLedgEntry: Record "Vendor Ledger Entry"; var BankAccRecon: Record "Bank Acc. Reconciliation"; var VendLedgerAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        TempBlobUTF8: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // One purchase and one payment is created and put into xml import bank statment
        CreateOnePurchOnePmtOutstream(VendLedgEntry, OutStream, TempBlobUTF8);

        VendLedgerAmount := VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible";

        // Statement is imported
        CreateBankAccReconAndImportStmt(BankAccRecon, TempBlobUTF8, '');
        if (not BankAccRecon."Post Payments Only") then
            GetLinesAndUpdateBankAccRecStmEndingBalance(BankAccRecon);

        // GL Journal is created as a manual check
        CreateManualCheckAndPostGenJnlLine(GenJnlLine, VendLedgEntry, BankAccRecon."Bank Account No.", -VendLedgerAmount);

        // Payment Reconciliation Journal is opened
        OpenPmtReconJnl(BankAccRecon, PmtReconJnl);
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

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforePrintDocument', '', false, false)]
    procedure OnBeforePrintDocument(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
        Commit();
    end;

    [ModalPageHandler]
    procedure ReversalUndoStatementHandler(var PmtRecUndoStatement: TestPage "Pmt. Rec. Undo Statement")
    begin
        PmtRecUndoStatement.ActionNext.Invoke();
    end;

    [ModalPageHandler]
    procedure ReversalUndoStatementCancelYesHandler(var PmtRecUndoStatement: TestPage "Pmt. Rec. Undo Statement")
    begin
        if LibraryVariableStorage.DequeueBoolean() then
            exit
        else
            PmtRecUndoStatement.ActionNext.Invoke();
    end;

    [ModalPageHandler]
    procedure ReversalRelatedHandler(var PaymentRecRelatedEntries: TestPage "Payment Rec. Related Entries")
    begin
        PaymentRecRelatedEntries.ActionNext.Invoke();
    end;

    [ModalPageHandler]
    procedure ReversalFinalizeHandler(var PmtRecReversalFinalize: TestPage "Pmt. Rec. Reversal Finalize")
    begin
        PmtRecReversalFinalize.CreatePaymentRecJournal.Value(Format(false));
        PmtRecReversalFinalize.ActionFinalize.Invoke();
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

    [SendNotificationHandler]
    procedure ReviewRequiredSendNotificationHandler(var SentNotification: Notification): Boolean
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), SentNotification.Message);
    end;

    [RequestPageHandler]
    procedure VerifyTestReportRequestPage(var RequestPage: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        if (LibraryVariableStorage.DequeueBoolean()) <> (RequestPage.PrintOutstdTransac.Visible()) then
            Error('PrintOutstdTransac does not have the expected visibility');
    end;

}
