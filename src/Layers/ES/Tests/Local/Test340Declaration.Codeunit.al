codeunit 147315 "Test 340 Declaration"
{
    // // [FEATURE] [340 Declaration]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        VATCashRegimeTransferErr: Label 'The VAT Cash Regime flag was not transferred to the VAT Entry table';
        SetupErr: Label 'The Setup value of %1 is incorrect';
        VATCashRegimeErr: Label 'You cannot change %1 because %2 is empty.';
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        Wrong340FileErr: Label 'Export of %1 contains wrong value in 340 file.';
        Wrong340FileHeaderErr: Label 'Wrong 340 file header''s amounts.';
        Wrong340FileLineCountErr: Label 'Wrong 340 file line''s count.';
        CACPrintedOnReportErr: Label 'CAC Message is not printed correctly on the report';
        CannotChangeContentBecauseOfErr: Label 'You cannot change %1 because %2 is selected.';
        NoRecordsWereFoundErr: Label 'No records were found to be included in the declaration.';
        CurrentSaveValuesId: Integer;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesSalesInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Sales Invoice posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] Sales Invoice is posted (with two lines)
        CreateAndPostVATSalesInvoiceWithTwoLines(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesSalesCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Sales Credit Memo
        // [WHEN] Y posted
        CreateAndPostVATSalesCreditMemo(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesServiceInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Service Invoice
        // [WHEN] Y posted
        CreateAndPostVATServiceInvoice(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesServiceCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Service Credit Memo
        CreateAndPostVATServiceCreditMemo(VATEntry, true, true);

        // [WHEN] Y posted
        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesReminder()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Reminder
        CreateAndPostVATReminder(VATEntry, true, true);
        // [WHEN] Y posted
        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Finance Charge
        // [WHEN] Y posted
        CreateAndPostVATFinanceCharge(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesSalesPayment()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Payment
        // [WHEN] Y posted
        CreateAndPostVATSalesPayment(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesSalesRefund()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Refund
        // [WHEN] Y posted
        CreateAndPostVATSalesRefund(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesPurchaseInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = TRUE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Purchase Invoice
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseInvoice(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesPurchaseCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = TRUE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Purchase Credit Memo
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseCreditMemo(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesPurchasePayment()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = TRUE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Payment
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchasePayment(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVATCashRegimeToVATEntriesPurchaseRefund()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = TRUE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Refund
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseRefund(VATEntry, true, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = TRUE
        Assert.IsTrue(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLDeselectVATCashRegime()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Initialize();
        // 3.1. Setup of own VAT Cash Regime Deactivate CAC
        // Own VAT Cash Regime can only be TRUE when Unrealized VAT is TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);
        // [WHEN] General Ledger Setup.Unrealized VAT is set to FALSE
        asserterror GeneralLedgerSetup.Validate("Unrealized VAT", false);
        // [THEN] General Ledger Setup.VAT Cash Regime is set to FALSE as well
        Assert.ExpectedError(StrSubstNo(CannotChangeContentBecauseOfErr, GeneralLedgerSetup.FieldName("Unrealized VAT"), GeneralLedgerSetup.FieldName("VAT Cash Regime")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLSelectVATCashRegime()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // 3.2. Setup of own VAT Cash Regime Activate CAC
        // The attempt to set VAT Cash Regime to TRUE when Unrealized is FALSE sets Unrealized to TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        Initialize();
        // [WHEN] General Ledger Setup.VAT Cash Regime is set to TRUE
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);
        // [THEN] General Ledger Setup.Unrealized VAT is set to TRUE as well
        Assert.IsTrue(GeneralLedgerSetup."Unrealized VAT", StrSubstNo(SetupErr, GeneralLedgerSetup.FieldName("Unrealized VAT")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetupDeselectVATCashRegime()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();
        // 3.3. Setup of the vendor's VAT Cash Regime - positive scenario

        // The peer's Unrealized VAT cannot be unset while VAT Cash Regime is active
        // [GIVEN] The company is set up to use Unrealized VAT
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Modify(true);
        // [GIVEN] VAT Posting Setup Line.Unrealized VAT Type = Percentage
        VATPostingSetup.FindFirst();
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        // [GIVEN] The same line has VAT Cash Regime = TRUE
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Modify(true);
        // [WHEN] VAT Posting Setup Line.Unrealized VAT Type is set to ' '
        asserterror VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        // [THEN] VAT Posting Setup.VAT Cash Regime is set to FALSE as well
        Assert.ExpectedError(
          StrSubstNo(CannotChangeContentBecauseOfErr, VATPostingSetup.FieldName("Unrealized VAT Type"), VATPostingSetup.FieldName("VAT Cash Regime")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetupSelectVATCashRegime()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();
        // 3.4. Setup of the vendor's VAT Cash Regime - Negative Scenario
        // The attempt to set VAT Cash Regime to TRUE when Unrealized is FALSE yields an error
        // [GIVEN] VAT Posting Setup Line.Unrealized VAT Type = ' '
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.FindFirst();
        // [WHEN] General Ledger Setup.VAT Cash Regime is attempted to be set to TRUE
        asserterror VATPostingSetup.Validate("VAT Cash Regime", true);
        // [THEN] An error prompts the user that Unrealized VAT is mandatory if we want VAT Cash Regime to be TRUE
        Assert.ExpectedError(StrSubstNo(VATCashRegimeErr, VATPostingSetup.FieldName("VAT Cash Regime"), VATPostingSetup.FieldName("Unrealized VAT Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesSalesInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Sales Invoice
        // [WHEN] Y posted
        CreateAndPostVATSalesInvoiceWithTwoLines(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesSalesCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Sales Credit Memo
        // [WHEN] Y posted
        CreateAndPostVATSalesCreditMemo(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesServiceInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Service Invoice
        // [WHEN] Y posted
        CreateAndPostVATServiceInvoice(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesServiceCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Service Credit Memo
        // [WHEN] Y posted
        CreateAndPostVATServiceCreditMemo(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesReminder()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Reminder
        // [WHEN] Y posted
        CreateAndPostVATReminder(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Finance Charge
        // [WHEN] Y posted
        CreateAndPostVATFinanceCharge(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesSalesPayment()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Payment
        // [WHEN] Y posted
        CreateAndPostVATSalesPayment(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesSalesRefund()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Our company is not under VAT Cash Regime. Customer document is posted
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Y is Refund
        // [WHEN] Y posted
        CreateAndPostVATSalesRefund(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesPurchaseInvoice()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = FALSE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Purchase Invoice
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseInvoice(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesPurchaseCreditMemo()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = FALSE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Purchase Credit Memo
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseCreditMemo(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesPurchasePayment()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = FALSE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Payment
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchasePayment(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTransferVATCashRegimeToVATEntriesPurchaseRefund()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // [GIVEN] VAT Posting Setup X has VAT Cash Regime = FALSE
        // [GIVEN] X has Unrealized VAT set up
        // [GIVEN] Y is Refund
        // [WHEN] Y is posted using VAT Posting Setup X
        CreateAndPostVATPurchaseRefund(VATEntry, false, true);

        // [THEN] The corresponding "VAT Entry" has VAT Cash Regime = FALSE
        Assert.IsFalse(VATEntry."VAT Cash Regime", VATCashRegimeTransferErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FilePayment()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Payment
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Payment, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileInvoice()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Invoice
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Invoice, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Credit Memo
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::"Credit Memo", true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Finance Charge Memo
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::"Finance Charge Memo", true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileReminder()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Reminder
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Reminder, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileRefund()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Refund
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Refund, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZPropagatedTo340FileBill()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = TRUE
        // [GIVEN] X has Document Type Bill
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Bill, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure InvoiceWithUnrealizedVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Invoices with unrealized VAT but not in VAT Cash Regime are not propagated to 340 file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Invoice
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Invoice, false);

        // [WHEN] User tries to export 340 file.
        // [THEN] No entries are found and the error 'No records were found to be included in the declaration.' is thrown.
        asserterror ExportVATEntryTo340File(VATEntry);

        Assert.ExpectedError(NoRecordsWereFoundErr);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoWithUnrealizedVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Invoices with unrealized VAT but not in VAT Cash Regime are not propagated to 340 file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Invoice
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::"Credit Memo", false);

        // [WHEN] User tries to export 340 file.
        // [THEN] No entries are found and the error 'No records were found to be included in the declaration.' is thrown.
        asserterror ExportVATEntryTo340File(VATEntry);

        Assert.ExpectedError(NoRecordsWereFoundErr);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoWithUnrealizedVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Invoices with unrealized VAT but not in VAT Cash Regime are not propagated to 340 file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Invoice
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::"Finance Charge Memo", false);

        // [WHEN] User tries to export 340 file.
        // [THEN] No entries are found and the error 'No records were found to be included in the declaration.' is thrown.
        asserterror ExportVATEntryTo340File(VATEntry);

        Assert.ExpectedError(NoRecordsWereFoundErr);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithUnrealizedVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();
        // Invoices with unrealized VAT but not in VAT Cash Regime are not propagated to 340 file
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Invoice
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Reminder, false);

        // [WHEN] User tries to export 340 file.
        // [THEN] No entries are found and the error 'No records were found to be included in the declaration.' is thrown.
        asserterror ExportVATEntryTo340File(VATEntry);

        Assert.ExpectedError(NoRecordsWereFoundErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZUnrealizedVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to file, Unrealized is TRUE
        // [GIVEN] VAT Entry Line X with an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Payment
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Payment, false);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a char different that 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure OperationCodeZNormalVATNotPropagatedTo340File()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to file, Unrealized is FALSE
        // [GIVEN] VAT Entry Line X withOUT an Unrealized VAT Entry
        // [GIVEN] X has VAT Cash Regime = FALSE
        // [GIVEN] X has Document Type Invoice
        CreateVATEntry(VATEntry, VATEntry."Document Type"::Invoice);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a char different from 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340Declaration_SeveralVATEntries_RPH,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimePaymentWithoutAmountsIn340File()
    var
        InvVATEntry: Record "VAT Entry";
        PmtVATEntry: Record "VAT Entry";
        Filename: Text;
        DummyZeroAmounts: array[3] of Decimal;
    begin
        // [FEATURE] [VAT Cash Regime] [UT]
        // [SCENARIO 377818] VAT Cash payments are exported with zero amounts in 340 file
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Cash Regime" = TRUE
        // [GIVEN] Payment (february) applied to Invoice (january). Total Amount Including VAT = "X".
        CreateUnrealizedVATEntry(InvVATEntry, InvVATEntry."Document Type"::Invoice, true);
        CreateRealizedVATEntry(
          PmtVATEntry, InvVATEntry, CalcDate('<1M>', InvVATEntry."Posting Date"), PmtVATEntry."Document Type"::Payment);

        // [WHEN] Make 340 Declaration for february
        Filename := ExportSeveralVATEntriesTo340File(
            PmtVATEntry."Posting Date", StrSubstNo('%1|%2', InvVATEntry."Entry No.", PmtVATEntry."Entry No."));

        // [THEN] Generated 340 file has one payment line
        Verify340FileLinesCount(Filename, 2);
        // [THEN] Header line has all zero amounts: VAT Base = 0, VAT Amount = 0, Invoice Amount = 0
        Verify340FileHeaderAmounts(Filename, DummyZeroAmounts);
        // [THEN] Payment line has VAT % = 0, VAT Base = 0, VAT Amount = 0, Invoice Amount = 0, Collection Amount = "X"
        Verify340FileLineAmounts(Filename, 2, PmtVATEntry, 0, DummyZeroAmounts, PmtVATEntry.Base + PmtVATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeInvoiceWithAmountsIn340File()
    var
        VATEntry: Record "VAT Entry";
        DocumentType: Enum "Gen. Journal Document Type";
        Filename: Text;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [VAT Cash Regime] [UT]
        // [SCENARIO 377818] VAT Cash invoices are exported with actual amounts in 340 file
        Initialize();

        for DocumentType := VATEntry."Document Type"::Invoice to VATEntry."Document Type"::Reminder do begin
            // [GIVEN] VAT Posting Setup with "VAT Cash Regime" = TRUE
            // [GIVEN] Invoice: VAT % = "Z", VAT Base = "X", VAT Amount = "Y".
            CreateUnrealizedVATEntry(VATEntry, DocumentType, true);
            CalcVATEntryAmounts(VATEntry, Amounts);

            // [WHEN] Make 340 Declaration
            Filename := ExportVATEntryTo340File(VATEntry);

            // [THEN] Generated 340 file has one invoice line
            Verify340FileLinesCount(Filename, 2);
            // [THEN] Header line has VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y"
            Verify340FileHeaderAmounts(Filename, Amounts);
            // [THEN] Invoice line has VAT % = "Z", VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y", Collection Amount = 0
            Verify340FileLineAmounts(Filename, 2, VATEntry, VATEntry."VAT %", Amounts, 0);

            DeleteObjectOptionsIfNeeded();
        end
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340Declaration_SeveralVATEntries_RPH,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimePaymentWithInvoiceIn340File()
    var
        InvVATEntry: Record "VAT Entry";
        PmtVATEntry: Record "VAT Entry";
        Filename: Text;
        Amounts: array[3] of Decimal;
        DummyZeroAmounts: array[3] of Decimal;
    begin
        // [FEATURE] [VAT Cash Regime] [UT]
        // [SCENARIO 377818] VAT Cash payment is exported with zero amounts and invoice with amounts in 340 file
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Cash Regime" = TRUE
        // [GIVEN] Payment applied to Invoice in the same period. VAT % = "Z", VAT Base = "X", VAT Amount = "Y".
        CreateUnrealizedVATEntry(InvVATEntry, InvVATEntry."Document Type"::Invoice, true);
        CreateRealizedVATEntry(
          PmtVATEntry, InvVATEntry, InvVATEntry."Posting Date", PmtVATEntry."Document Type"::Payment);
        CalcVATEntryAmounts(InvVATEntry, Amounts);

        // [WHEN] Make 340 Declaration
        Filename := ExportSeveralVATEntriesTo340File(
            PmtVATEntry."Posting Date", StrSubstNo('%1|%2', InvVATEntry."Entry No.", PmtVATEntry."Entry No."));

        // [THEN] Generated 340 file has two lines: payment and invoice
        Verify340FileLinesCount(Filename, 3);
        // [THEN] Header line has VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y"
        Verify340FileHeaderAmounts(Filename, Amounts);
        // [THEN] Payment line has VAT % = 0, VAT Base = 0, VAT Amount = 0, Invoice Amount = 0, Collection Amount = "X" + "Y"
        Verify340FileLineAmounts(Filename, 2, PmtVATEntry, 0, DummyZeroAmounts, -Amounts[3]);
        // [THEN] Invoice line has VAT % = "Z", VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y", Collection Amount = 0
        Verify340FileLineAmounts(Filename, 3, InvVATEntry, InvVATEntry."VAT %", Amounts, 0);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340Declaration_SeveralVATEntries_RPH,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure UnrealVATPaymentWithInvoiceIn340File()
    var
        InvVATEntry: Record "VAT Entry";
        PmtVATEntry: Record "VAT Entry";
        Filename: Text;
        Amounts: array[3] of Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [UT]
        // [SCENARIO 377818] Unrealized VAT payment applied to invoice is exported with amounts in 340 file
        Initialize();

        // [GIVEN] Unrealized VAT Posting Setup with "VAT Cash Regime" = FALSE
        // [GIVEN] Payment applied to Invoice in the same period. VAT % = "Z", VAT Base = "X", VAT Amount = "Y".
        CreateUnrealizedVATEntry(InvVATEntry, InvVATEntry."Document Type"::Invoice, false);
        CreateRealizedVATEntry(
          PmtVATEntry, InvVATEntry, InvVATEntry."Posting Date", PmtVATEntry."Document Type"::Payment);
        CalcVATEntryAmounts(InvVATEntry, Amounts);

        // [WHEN] Make 340 Declaration
        Filename := ExportSeveralVATEntriesTo340File(
            PmtVATEntry."Posting Date", StrSubstNo('%1|%2', InvVATEntry."Entry No.", PmtVATEntry."Entry No."));

        // [THEN] Generated 340 file has one payment line
        Verify340FileLinesCount(Filename, 2);
        // [THEN] Header line has VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y"
        Verify340FileHeaderAmounts(Filename, Amounts);
        // [THEN] Payment line has VAT % = "Z", VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y", Collection Amount = 0
        Verify340FileLineAmounts(Filename, 2, PmtVATEntry, PmtVATEntry."VAT %", Amounts, 0);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340Declaration_SeveralVATEntries_RPH,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure CombinedDocumentsIn340File()
    var
        NormalInvVATEntry: Record "VAT Entry";
        UnrealInvVATEntry: Record "VAT Entry";
        UnrealPmtVATEntry: Record "VAT Entry";
        VATCashInvVATEntry: Record "VAT Entry";
        VATCashPmtVATEntry: Record "VAT Entry";
        Filename: Text;
        NormalVATAmounts: array[3] of Decimal;
        UnrealVATAmounts: array[3] of Decimal;
        VATCashAmounts: array[3] of Decimal;
        DummyZeroAmounts: array[3] of Decimal;
        HeaderAmounts: array[3] of Decimal;
    begin
        // [FEATURE] [VAT Cash Regime] [Unrealized VAT] [UT]
        // [SCENARIO 377818] Normal VAT, Unrealized VAT and VAT Cash payment with invoices are correctly exported to 340 file
        Initialize();

        // [GIVEN] Normal VAT Invoice "I1": VAT % = "Z1", VAT Base = "X1", VAT Amount = "Y1".
        CreateVATEntry(NormalInvVATEntry, NormalInvVATEntry."Document Type"::Invoice);
        CalcVATEntryAmounts(NormalInvVATEntry, NormalVATAmounts);
        UpdateAmounts(HeaderAmounts, NormalVATAmounts);

        // [GIVEN] Unrealized VAT Payment "P2" applied to Invoice in the same period. VAT % = "Z2", VAT Base = "X2", VAT Amount = "Y2".
        CreateUnrealizedVATEntry(UnrealInvVATEntry, UnrealInvVATEntry."Document Type"::Invoice, false);
        CreateRealizedVATEntry(
          UnrealPmtVATEntry, UnrealInvVATEntry, UnrealInvVATEntry."Posting Date", UnrealPmtVATEntry."Document Type"::Payment);
        CalcVATEntryAmounts(UnrealInvVATEntry, UnrealVATAmounts);
        UpdateAmounts(HeaderAmounts, UnrealVATAmounts);

        // [GIVEN] VAT Cash Payment "P3" applied to Invoice "I3" in the same period. VAT % = "Z3", VAT Base = "X3", VAT Amount = "Y3".
        CreateUnrealizedVATEntry(VATCashInvVATEntry, VATCashInvVATEntry."Document Type"::Invoice, true);
        CreateRealizedVATEntry(
          VATCashPmtVATEntry, VATCashInvVATEntry, VATCashInvVATEntry."Posting Date", VATCashPmtVATEntry."Document Type"::Payment);
        CalcVATEntryAmounts(VATCashInvVATEntry, VATCashAmounts);
        UpdateAmounts(HeaderAmounts, VATCashAmounts);

        // [WHEN] Make 340 Declaration
        Filename := ExportSeveralVATEntriesTo340File(
            UnrealInvVATEntry."Posting Date", StrSubstNo('%1..%2', NormalInvVATEntry."Entry No.", VATCashPmtVATEntry."Entry No."));

        // [THEN] Generated 340 file has four lines: Normal VAT Invoice, Unrealized VAT Payment, VAT Cash Invoice and VAT Cash Payment
        Verify340FileLinesCount(Filename, 5);
        // [THEN] Header line has VAT Base = "X", VAT Amount = "Y", Invoice Amount = "X" + "Y"
        Verify340FileHeaderAmounts(Filename, HeaderAmounts);
        // [THEN] Unrealized Payment line has VAT % = "Z2", VAT Base = "X2", VAT Amount = "Y2", Invoice Amount = "X2" + "Y2", Collection Amount = 0
        Verify340FileLineAmounts(Filename, 2, UnrealPmtVATEntry, UnrealPmtVATEntry."VAT %", UnrealVATAmounts, 0);
        // [THEN] Cash Payment line has VAT % = 0, VAT Base = 0, VAT Amount = 0, Invoice Amount = 0, Collection Amount = "X3" + "Y3"
        Verify340FileLineAmounts(Filename, 3, VATCashPmtVATEntry, 0, DummyZeroAmounts, -VATCashAmounts[3]);
        // [THEN] Normal VAT Invoice line has VAT % = "Z1", VAT Base = "X1", VAT Amount = "Y1", Invoice Amount = "X1" + "Y1", Collection Amount = 0
        Verify340FileLineAmounts(Filename, 4, NormalInvVATEntry, NormalInvVATEntry."VAT %", NormalVATAmounts, 0);
        // [THEN] VAT Cash Invoice line has VAT % = "Z3", VAT Base = "X3", VAT Amount = "Y3", Invoice Amount = "X3" + "Y3", Collection Amount = 0
        Verify340FileLineAmounts(Filename, 5, VATCashInvVATEntry, VATCashInvVATEntry."VAT %", VATCashAmounts, 0);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure FullScenarioExport340FileFromInvoiceWithVATCashRegime()
    var
        VATEntry: Record "VAT Entry";
        Filename: Text[1024];
    begin
        Initialize();
        // Full scenario type Z is propagated to 340 file
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [GIVEN] Sales Invoice is posted with Unrealized VAT, Creating VAT Entry X
        CreateAndPostVATSalesInvoiceWithTwoLines(VATEntry, true, true);

        // [GIVEN] 340 Declaration Lines has been generated from X
        // [WHEN] User creates exports a 340 file from the generated 340 Declaration Lines
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] In the 340 file: On the line related to X, a 'Z' is written in column 100
        Verify340FileVATCashRegimeFlag(VATEntry, Filename);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnPurchaseInvoice()
    var
        VATEntry: Record "VAT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseInvoice(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        PurchInvHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseInvoice.ShowCashAccountingCriteria(PurchInvHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnPurchaseCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseCreditMemo(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        PurchCrMemoHdr.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseCreditMemo.ShowCashAccountingCriteria(PurchCrMemoHdr) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Service Order
        CreateVATServiceHeader(ServiceHeader, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        Assert.IsTrue(ServiceOrder.ShowCashAccountingCriteria(ServiceHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnServiceInvoice()
    var
        VATEntry: Record "VAT Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: Report "Service - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceInvoice(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        ServiceInvoiceHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceInvoice.ShowCashAccountingCriteria(ServiceInvoiceHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnServiceCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: Report "Service - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceCreditMemo(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        ServiceCrMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceCreditMemo.ShowCashAccountingCriteria(ServiceCrMemoHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        "Order": Report "Order";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Purchase Order
        CreateVATPurchaseHeader(PurchaseHeader, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        Assert.IsTrue(Order.ShowCashAccountingCriteria(PurchaseHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnReminder()
    var
        VATEntry: Record "VAT Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Reminder
        CreateAndPostVATReminder(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        IssuedReminderHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(Reminder.ShowCashAccountingCriteria(IssuedReminderHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextPrintedOnFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FinanceChargeMemo: Report "Finance Charge Memo";
    begin
        Initialize();
        // VAT Cash Regime text is printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = TRUE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Finance Charge
        CreateAndPostVATFinanceCharge(VATEntry, true, true);

        // [THEN] The text stating that we use CAC is printed on the invoice
        IssuedFinChargeMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(FinanceChargeMemo.ShowCashAccountingCriteria(IssuedFinChargeMemoHeader) <> '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnPurchaseInvoice()
    var
        VATEntry: Record "VAT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseInvoice(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        PurchInvHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseInvoice.ShowCashAccountingCriteria(PurchInvHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnPurchaseCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseCreditMemo(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        PurchCrMemoHdr.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseCreditMemo.ShowCashAccountingCriteria(PurchCrMemoHdr) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Service Order
        CreateVATServiceHeader(ServiceHeader, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        Assert.IsTrue(ServiceOrder.ShowCashAccountingCriteria(ServiceHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnServiceInvoice()
    var
        VATEntry: Record "VAT Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: Report "Service - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceInvoice(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        ServiceInvoiceHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceInvoice.ShowCashAccountingCriteria(ServiceInvoiceHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnServiceCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: Report "Service - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceCreditMemo(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        ServiceCrMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceCreditMemo.ShowCashAccountingCriteria(ServiceCrMemoHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        "Order": Report "Order";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Purchase Order
        CreateVATPurchaseHeader(PurchaseHeader, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        Assert.IsTrue(Order.ShowCashAccountingCriteria(PurchaseHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnReminder()
    var
        VATEntry: Record "VAT Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Reminder
        CreateAndPostVATReminder(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        IssuedReminderHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(Reminder.ShowCashAccountingCriteria(IssuedReminderHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithVATNotPrintedOnFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FinanceChargeMemo: Report "Finance Charge Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = TRUE
        // [WHEN] X is posted where X is Finance Charge
        CreateAndPostVATFinanceCharge(VATEntry, false, true);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        IssuedFinChargeMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(FinanceChargeMemo.ShowCashAccountingCriteria(IssuedFinChargeMemoHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnPurchaseInvoice()
    var
        VATEntry: Record "VAT Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseInvoice(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        PurchInvHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseInvoice.ShowCashAccountingCriteria(PurchInvHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnPurchaseCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATPurchaseCreditMemo(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        PurchCrMemoHdr.Get(VATEntry."Document No.");
        Assert.IsTrue(PurchaseCreditMemo.ShowCashAccountingCriteria(PurchCrMemoHdr) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: Report "Service Order";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Service Order
        CreateVATServiceHeader(ServiceHeader, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        Assert.IsTrue(ServiceOrder.ShowCashAccountingCriteria(ServiceHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnServiceInvoice()
    var
        VATEntry: Record "VAT Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: Report "Service - Invoice";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceInvoice(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        ServiceInvoiceHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceInvoice.ShowCashAccountingCriteria(ServiceInvoiceHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnServiceCreditMemo()
    var
        VATEntry: Record "VAT Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: Report "Service - Credit Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Sales Invoice
        CreateAndPostVATServiceCreditMemo(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        ServiceCrMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(ServiceCreditMemo.ShowCashAccountingCriteria(ServiceCrMemoHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        "Order": Report "Order";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Purchase Order
        CreateVATPurchaseHeader(PurchaseHeader, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        Assert.IsTrue(Order.ShowCashAccountingCriteria(PurchaseHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnReminder()
    var
        VATEntry: Record "VAT Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Reminder
        CreateAndPostVATReminder(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        IssuedReminderHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(Reminder.ShowCashAccountingCriteria(IssuedReminderHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATCashRegimeTextWithoutVATNotPrintedOnFinanceChargeMemo()
    var
        VATEntry: Record "VAT Entry";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        FinanceChargeMemo: Report "Finance Charge Memo";
    begin
        Initialize();
        // VAT Cash Regime text is not printed
        // [GIVEN] General Ledger Setup.VAT Cash Regime = FALSE
        // [GIVEN] General Ledger Setup.Unrealized VAT = FALSE
        // [WHEN] X is posted where X is Finance Charge
        CreateAndPostVATFinanceCharge(VATEntry, false, false);

        // [THEN] The text stating that we use CAC is not printed on the invoice
        IssuedFinChargeMemoHeader.Get(VATEntry."Document No.");
        Assert.IsTrue(FinanceChargeMemo.ShowCashAccountingCriteria(IssuedFinChargeMemoHeader) = '', CACPrintedOnReportErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationOnCustomerWithLongName()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        FileName: Text[1024];
    begin
        // [SCENARIO 328188] Run "Make 340 Declaration" report on Customer with long Name.
        Initialize();

        // [GIVEN] VAT Entry Line for Customer with Name, that has length 100.
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Invoice, true);

        Customer.Get(VATEntry."Bill-to/Pay-to No.");
        Customer.Name :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 0), 1, MaxStrLen(Customer.Name));
        Customer.Modify();

        // [WHEN] Run "Make 340 Declaration" report.
        FileName := ExportVATEntryTo340File(VATEntry);

        // [THEN] Report runs without errors.
        Assert.IsTrue(FILE.Exists(FileName), '');
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationOnCompanyWithLongName()
    var
        VATEntry: Record "VAT Entry";
        CompanyInfo: Record "Company Information";
        Filename: Text[1024];
    begin
        // [SCENARIO 328188] Run "Make 340 Declaration" report on Customer with long Name.
        Initialize();

        // [GIVEN] VAT Entry Line.
        // [GIVEN] Current Company has Name with length 100.
        CreateUnrealizedVATEntry(VATEntry, VATEntry."Document Type"::Invoice, true);

        CompanyInfo.Get();
        CompanyInfo.Name :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CompanyInfo.Name), 0), 1, MaxStrLen(CompanyInfo.Name));
        CompanyInfo.Modify();

        // [WHEN] Run "Make 340 Declaration" report.
        Filename := ExportVATEntryTo340File(VATEntry);

        // [THEN] Report runs without errors.
        Assert.IsTrue(FILE.Exists(Filename), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        Library340347Declaration.SetupVATType(false, false);
        DeleteObjectOptionsIfNeeded();
    end;

    local procedure CreateGLAccountWithVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup."Def. VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GenProductPostingGroup.Modify(true);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostVATSalesInvoiceWithTwoLines(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice);
    end;

    local procedure CreateAndPostVATSalesCreditMemo(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, Customer."No.", WorkDate(), Amount, '');
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo");
    end;

    local procedure CreateAndPostVATServiceInvoice(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostServiceInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice);
    end;

    local procedure CreateAndPostVATServiceCreditMemo(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostServiceCrMemo(VATPostingSetup, Customer."No.", WorkDate(), Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo");
    end;

    local procedure CreateAndPostVATPurchaseInvoice(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice);
    end;

    local procedure CreateAndPostVATPurchaseCreditMemo(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo :=
          Library340347Declaration.CreateAndPostPurchaseCrMemo(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo, '');
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo");
    end;

    local procedure CreateAndPostVATReminder(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");

        // Create Header
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Additional Fee", true);
        ReminderTerms.Modify(true);

        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Validate("Reminder Terms Code", ReminderTerms.Code);
        ReminderHeader.Modify(true);

        // Create Line
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");
        ReminderLine.Validate("No.", CreateGLAccountWithVATPostingSetup(VATPostingSetup));
        ReminderLine.Validate(Amount, LibraryRandom.RandDecInRange(100, 200, 2));
        ReminderLine.Modify(true);

        // Issue reminder
        ReminderHeader.SetRange("No.", ReminderHeader."No.");
        REPORT.Run(REPORT::"Issue Reminders", false, true, ReminderHeader);
        IssuedReminderHeader.SetFilter("Pre-Assigned No.", ReminderHeader."No.");
        IssuedReminderHeader.FindFirst();

        FindVATEntry(VATEntry, IssuedReminderHeader."No.", VATEntry."Document Type"::Reminder);
    end;

    local procedure CreateAndPostVATFinanceCharge(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");

        // Create Header
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        FinanceChargeMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeMemoHeader.Modify(true);

        // Create Line
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", CreateGLAccountWithVATPostingSetup(VATPostingSetup));
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandDecInRange(100, 200, 2));
        FinanceChargeMemoLine.Modify(true);

        // Issue Finance Charge
        REPORT.Run(REPORT::"Issue Finance Charge Memos", false, true, FinanceChargeMemoHeader);
        IssuedFinChargeMemoHeader.SetFilter("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.FindFirst();

        FindVATEntry(VATEntry, IssuedFinChargeMemoHeader."No.", VATEntry."Document Type"::"Finance Charge Memo");
    end;

    local procedure CreateAndPostVATSalesPayment(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Payment);
    end;

    local procedure CreateAndPostVATSalesRefund(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, Customer."No.", WorkDate(), Amount, '');
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::"Credit Memo", DocumentNo, WorkDate(), -Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Refund);
    end;

    local procedure CreateAndPostVATPurchasePayment(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Payment);
    end;

    local procedure CreateAndPostVATPurchaseRefund(var VATEntry: Record "VAT Entry"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        DocumentNo: Code[20];
        ExtDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        DocumentNo :=
          Library340347Declaration.CreateAndPostPurchaseCrMemo(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo, '');
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::"Credit Memo", DocumentNo, WorkDate(), -Amount);
        FindVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Refund);
    end;

    local procedure CreateVATServiceHeader(var ServiceHeader: Record "Service Header"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        Library340347Declaration.CreateServiceLine(ServiceHeader, VATPostingSetup);
    end;

    local procedure CreateVATPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; UseVATCashRegime: Boolean; UseUnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        Amount: Decimal;
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        Library340347Declaration.CreatePurchaseLine(VATPostingSetup, PurchaseHeader, Amount);
    end;

    local procedure CreateUnrealizedVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; UseVATCashRegime: Boolean)
    begin
        MockVATEntry(VATEntry, WorkDate(), DocumentType, UseVATCashRegime);
        VATEntry."Unrealized Base" := LibraryRandom.RandDecInRange(1000, 100, 2);
        VATEntry."Unrealized Amount" := Round(VATEntry."Unrealized Base" * (VATEntry."VAT %" + VATEntry."EC %") / 100);
        VATEntry."Remaining Unrealized Base" := VATEntry."Unrealized Base";
        VATEntry."Remaining Unrealized Amount" := VATEntry."Unrealized Amount";
        VATEntry.Modify();
    end;

    local procedure CreateRealizedVATEntry(var VATEntry: Record "VAT Entry"; var UnrealizedVATEntry: Record "VAT Entry"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type")
    begin
        MockVATEntry(VATEntry, PostingDate, DocumentType, UnrealizedVATEntry."VAT Cash Regime");
        VATEntry."VAT %" := UnrealizedVATEntry."VAT %";
        VATEntry."EC %" := UnrealizedVATEntry."EC %";
        VATEntry.Base := UnrealizedVATEntry."Unrealized Base";
        VATEntry.Amount := UnrealizedVATEntry."Unrealized Amount";
        VATEntry."Unrealized VAT Entry No." := UnrealizedVATEntry."Entry No.";
        VATEntry.Modify();

        UnrealizedVATEntry."Remaining Unrealized Base" := 0;
        UnrealizedVATEntry."Remaining Unrealized Amount" := 0;
        UnrealizedVATEntry.Modify();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type")
    begin
        MockVATEntry(VATEntry, WorkDate(), DocumentType, false);
        VATEntry.Base := LibraryRandom.RandDecInRange(1000, 100, 2);
        VATEntry.Amount := Round(VATEntry.Base * (VATEntry."VAT %" + VATEntry."EC %") / 100);
        VATEntry.Modify();
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; UseVATCashRegime: Boolean)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := PostingDate;
        VATEntry."Document Type" := DocumentType;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Bill-to/Pay-to No." := LibrarySales.CreateCustomerNo();
        VATEntry."Document No." := LibraryUtility.GenerateGUID();
        VATEntry."VAT %" := LibraryRandom.RandIntInRange(15, 20);
        VATEntry."EC %" := LibraryRandom.RandIntInRange(5, 10);
        VATEntry."VAT Cash Regime" := UseVATCashRegime;
        VATEntry."Transaction No." := VATEntry."Entry No.";
        VATEntry.Insert();
    end;

    local procedure CalcVATEntryAmounts(VATEntry: Record "VAT Entry"; var Amounts: array[3] of Decimal)
    begin
        if VATEntry.Base <> 0 then begin
            Amounts[1] := -VATEntry.Base;
            Amounts[2] := -(VATEntry.Amount - Round(VATEntry.Base * VATEntry."EC %" / 100));
            Amounts[3] := -(VATEntry.Amount + VATEntry.Base);
        end else begin
            Amounts[1] := -VATEntry."Unrealized Base";
            Amounts[2] := -(VATEntry."Unrealized Amount" - Round(VATEntry."Unrealized Base" * VATEntry."EC %" / 100));
            Amounts[3] := -(VATEntry."Unrealized Amount" + VATEntry."Unrealized Base");
        end;
    end;

    local procedure UpdateAmounts(var Target: array[3] of Decimal; Source: array[3] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Target) do
            Target[i] += Source[i];
    end;

    local procedure ExportVATEntryTo340File(VATEntryToExport: Record "VAT Entry"): Text[1024]
    begin
        Commit();
        LibraryVariableStorage.Enqueue(VATEntryToExport."Entry No.");
        exit(Library340347Declaration.RunMake340DeclarationReport(VATEntryToExport."Posting Date"));
    end;

    local procedure ExportSeveralVATEntriesTo340File(PostingDate: Date; VATEntryNoFilter: Text): Text
    begin
        Commit();
        LibraryVariableStorage.Enqueue(VATEntryNoFilter);
        exit(Library340347Declaration.RunMake340DeclarationReport(PostingDate));
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VATEntry.SetCurrentKey("Document Type", "Posting Date", "Document No.");
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure Find340FileLineAmounts(Filename: Text; LineNo: Integer; var DocumentNo: Code[20]; var VATPercentage: Decimal; var Amounts: array[3] of Decimal; var CollectionAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        Test340DeclarationLineBuf: Record "Test 340 Declaration Line Buf.";
        Line: Text;
    begin
        Line := LibraryTextFileValidation.ReadLine(Filename, LineNo);
        Test340DeclarationLineBuf.Init();
        Test340DeclarationLineBuf.Type := VATEntry.Type::Sale.AsInteger();
        Evaluate(DocumentNo,
          LibraryTextFileValidation.ReadValue(Line, Test340DeclarationLineBuf.GetFieldPos(Test340DeclarationLineBuf.FieldNo("Document No.")), Test340DeclarationLineBuf.GetFieldLen(Test340DeclarationLineBuf.FieldNo("Document No."))));
        Evaluate(VATPercentage,
          LibraryTextFileValidation.ReadValue(Line, Test340DeclarationLineBuf.GetFieldPos(Test340DeclarationLineBuf.FieldNo("Tax %")), Test340DeclarationLineBuf.GetFieldLen(Test340DeclarationLineBuf.FieldNo("Tax %"))));
        VATPercentage /= 100;
        CollectionAmount := Library340347Declaration.GetLine340Amount(Line, Test340DeclarationLineBuf.GetFieldPos(Test340DeclarationLineBuf.FieldNo("Collection Amount")) - 1, false);
        Amounts[1] := Library340347Declaration.GetLine340Amount(Line, 122, false);
        Amounts[2] := Library340347Declaration.GetLine340Amount(Line, 136, false);
        Amounts[3] := Library340347Declaration.GetLine340Amount(Line, 150, false);
    end;

    local procedure Verify340FileVATCashRegimeFlag(VATEntry: Record "VAT Entry"; Filename: Text[1024])
    var
        Test340DeclarationLineBuf: Record "Test 340 Declaration Line Buf.";
        Line: Text[1024];
        OperationCode: Text[1024];
    begin
        Test340DeclarationLineBuf.Init();
        Test340DeclarationLineBuf.Type := VATEntry.Type.AsInteger();
        Line := LibraryTextFileValidation.FindLineWithValue(Filename,
            Test340DeclarationLineBuf.GetFieldPos(Test340DeclarationLineBuf.FieldNo("Document No.")), StrLen(VATEntry."Document No."), VATEntry."Document No.");
        OperationCode := LibraryTextFileValidation.ReadValue(Line, Test340DeclarationLineBuf.GetFieldPos(Test340DeclarationLineBuf.FieldNo("Operation Code")), 1);

        if VATEntry."VAT Cash Regime" then begin
            if VATEntry."Document Type" in [VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type"::Refund] then
                Assert.AreEqual('3', OperationCode, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"))
            else
                Assert.AreEqual('Z', OperationCode, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        end else
            Assert.AreNotEqual('Z', OperationCode, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
    end;

    local procedure Verify340FileLineAmounts(Filename: Text; LineNo: Integer; VATEntry: Record "VAT Entry"; ExpectedVATPercentage: Decimal; ExpectedAmounts: array[3] of Decimal; ExpectedCollectionAmount: Decimal)
    var
        DocumentNo: Code[20];
        VATPercentage: Decimal;
        Amounts: array[3] of Decimal;
        CollectionAmount: Decimal;
    begin
        Find340FileLineAmounts(Filename, LineNo, DocumentNo, VATPercentage, Amounts, CollectionAmount);
        Assert.AreEqual(VATEntry."Document No.", DocumentNo, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        Assert.AreEqual(ExpectedVATPercentage, VATPercentage, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        Assert.AreEqual(ExpectedAmounts[1], Amounts[1], StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        Assert.AreEqual(ExpectedAmounts[2], Amounts[2], StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        Assert.AreEqual(ExpectedAmounts[3], Amounts[3], StrSubstNo(Wrong340FileErr, VATEntry."Document Type"));
        Assert.AreEqual(ExpectedCollectionAmount, CollectionAmount, StrSubstNo(Wrong340FileErr, VATEntry."Document Type"))
    end;

    local procedure Verify340FileHeaderAmounts(Filename: Text; ExpectedAmounts: array[3] of Decimal)
    var
        Line: Text;
        TotalBaseAmt: Decimal;
        TotalVATAmt: Decimal;
        TotalInvAmt: Decimal;
    begin
        Line := LibraryTextFileValidation.ReadLine(Filename, 1);
        TotalBaseAmt := Library340347Declaration.GetLine340Amount(Line, 147, true);
        TotalVATAmt := Library340347Declaration.GetLine340Amount(Line, 165, true);
        TotalInvAmt := Library340347Declaration.GetLine340Amount(Line, 183, true);
        Assert.AreEqual(ExpectedAmounts[1], TotalBaseAmt, Wrong340FileHeaderErr);
        Assert.AreEqual(ExpectedAmounts[2], TotalVATAmt, Wrong340FileHeaderErr);
        Assert.AreEqual(ExpectedAmounts[3], TotalInvAmt, Wrong340FileHeaderErr);
    end;

    local procedure Verify340FileLinesCount(FileName: Text; ExpectedCnt: Integer)
    begin
        Assert.AreEqual(ExpectedCnt, LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, '', 1, 0), Wrong340FileLineCountErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesPageHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340DeclarationHandler(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    var
        VATEntry: Record "VAT Entry";
    begin
        CurrentSaveValuesId := REPORT::"Make 340 Declaration";
        VATEntry.Get(LibraryVariableStorage.DequeueInteger());
        Make340Declaration.VATEntry.SetFilter("Entry No.", Format(VATEntry."Entry No."));
        Make340Declaration.VATEntry.SetFilter("Document Type", Format(VATEntry."Document Type"));
        Make340Declaration.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340Declaration_SeveralVATEntries_RPH(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    begin
        CurrentSaveValuesId := REPORT::"Make 340 Declaration";
        Make340Declaration.VATEntry.SetFilter("Entry No.", LibraryVariableStorage.DequeueText());
        Make340Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportedSuccessfullyMessageHandler(Message: Text[1024])
    begin
    end;

    local procedure DeleteObjectOptionsIfNeeded()
    var
        LibraryReportValidation: Codeunit "Library - Report Validation";
    begin
        LibraryReportValidation.DeleteObjectOptions(CurrentSaveValuesId);
    end;
}
