codeunit 134140 "ERM Bank Acc Ledger Reversal"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Bank Ledger Entry]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankLedgerEntryWithCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Create and post General Journal Line using Random Values with Document Type Payment and Refund for Customer.

        // Setup: Create Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // Create and post General Journal Line and Reverse Bank Ledger Entry for Customer.
        CreateAndReverseBankLedgerEntry(
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankLedgerEntryWithVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post General Journal Line using Random Values with Document Type Payment and Refund for Vendor.

        // Setup: Create Vendor.
        Initialize();

        // Create and post General Journal Line and Reverse Bank Ledger Entry for Vendor.
        CreateAndReverseBankLedgerEntry(
          GenJournalLine."Account Type"::Vendor, CreateVendor(), GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Refund, LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankLedgerEntryWithGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post General Journal Line using Random Values with Document Type Blank for GL Account.

        // Setup : Create GL Account.
        Initialize();

        // Create and post General Journal Line and Reverse Bank Ledger Entry for GL Account.
        CreateAndReverseBankLedgerEntry(
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Document Type"::" ",
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransferAndReverseBankAccounts()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and post General Journal Line using Random Values with Document Type Blank for Bank Account.

        // Setup.
        Initialize();

        // Create and post General Journal Line and Reverse Bank Ledger Entry for Bank Account.
        CreateAndReverseBankLedgerEntry(
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), GenJournalLine."Document Type"::" ",
          GenJournalLine."Document Type"::" ", LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [HandlerFunctions('BankAccountListReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountListReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify No. and Balance on Bank Account List Report.

        // Setup: Create Bank Account and post Gen. Jnl. Line with Bank Account No. as Bal. Account.
        Initialize();
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, '', false);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");  // Enqueue values for BankAccountListReqPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Bank Account - List");

        // Verify: Verify No. and Balance on Bank Account List Report.
        VerifyBankAccountListReport(GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccountListReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountListReportWithCurrency()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Verify No. and Balance on Bank Account List Report with Currency.

        // Setup: Create Bank Account with Currency and post Gen. Jnl. Line with Bank Account No. as Bal. Account.
        Initialize();
        Currency.Get(CreateCurrency());
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, Currency.Code, true);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");  // Enqueue values for BankAccountListReqPageHandler.
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, Currency.Code, '', WorkDate());

        // Exercise.
        REPORT.Run(REPORT::"Bank Account - List");

        // Verify: Verify No. and Balance on Bank Account List Report.
        VerifyBankAccountListReport(GenJournalLine."Bal. Account No.", -Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccountRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountRegisterReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Bank Account No. and Amount on Bank Account Register Report.

        // Setup: Create Bank Account, create and post Gen. Jnl. Line with Bank Account No. as Bal. Account.
        Initialize();
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, '', false);

        // Exercise.
        REPORT.Run(REPORT::"Bank Account Register");

        // Verify: Verify Bank Account No. and Amount on Bank Account Register Report.
        VerifyBankAccountRegisterReport(GenJournalLine."Bal. Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccountRegisterReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountRegisterReportWithCurrency()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Verify Bank Account No. and Amount on Bank Account Register Report with Currency.

        // Setup: Create Bank Account with Currency and post Gen. Jnl. Line with Bank Account No. as Bal. Account.
        Initialize();
        Currency.Get(CreateCurrency());
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, Currency.Code, true);
        Amount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, Currency.Code, '', WorkDate());

        // Exercise.
        REPORT.Run(REPORT::"Bank Account Register");

        // Verify: Verify Bank Account No. and Amount on Bank Account Register Report.
        VerifyBankAccountRegisterReport(GenJournalLine."Bal. Account No.", Amount);
    end;

    [Test]
    [HandlerFunctions('BankAccDetailTrialBalReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccDetailTrialBalReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Bank Account No., Amount, Document No. and Document Type on Bank Acc. Detail Trial Bal Report.

        // Setup: Create Bank Account and post Gen. Jnl. Line with Bank Account No. as Bal. Account.
        Initialize();
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, '', false);

        // Exercise.
        REPORT.Run(REPORT::"Bank Acc. - Detail Trial Bal.");

        // Verify: Verify Bank Account No., Amount, Document No. and Document Type on Bank Acc. Detail Trial Bal Report.
        VerifyBankAccDetailTrialBalReport(GenJournalLine, -1);  // -1 for SignFactor.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,BankAccDetailTrialBalReqPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccDetailTrialBalReportWithReverseEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Bank Account No., Amount, Document No. and Document Type on Bank Acc. Detail Trial Bal Report with reversed entries.

        // Setup: Create Bank Account and post Gen. Jnl. Line with Bank Account No. as Bal. Account. Reverse Bank Account Ledger Entries.
        Initialize();
        CreateBankAccountAndPostGenJnlLine(GenJournalLine, '', true);
        ReverseBankLedgerEntry();
        Commit();  // Required to run the report.

        // Exercise.
        REPORT.Run(REPORT::"Bank Acc. - Detail Trial Bal.");

        // Verify: Verify Bank Account No., Amount, Document No. and Document Type on Bank Acc. Detail Trial Bal Report.
        VerifyBankAccDetailTrialBalReport(GenJournalLine, 1);  // 1 for SignFactor.
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Bank Acc Ledger Reversal");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Bank Acc Ledger Reversal");
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Bank Acc Ledger Reversal");
    end;

    local procedure CalculateBankLedgerEntryAmount(DocumentNo: Code[20]): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankAccountLedgerEntryAmt: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        BankAccountLedgerEntry.FindSet();
        repeat
            BankAccountLedgerEntryAmt += BankAccountLedgerEntry.Amount;
        until BankAccountLedgerEntry.Next() = 0;
        exit(BankAccountLedgerEntryAmt);
    end;

    local procedure CreateBankAccountAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; ReportBooleanOption: Boolean)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, CreateVendor(),
          LibraryRandom.RandInt(100), BankAccount."No.");  // Using Random value for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(ReportBooleanOption);  // Enqueue value for various Request Page Handlers.
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndReverseBankLedgerEntry(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        Assert: Codeunit Assert;
        Amount2: Decimal;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, DocumentType, AccountType, AccountNo, Amount, FindBankAccount());
        Amount2 := GenJournalLine.Amount;
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, DocumentType2, AccountType, GenJournalLine."Account No.", -Amount, FindBankAccount());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        Amount2 += GenJournalLine.Amount;

        // Exercise: Reverse Bank Ledger Entry from GL Register.
        ReverseBankLedgerEntry();

        // Verify: Verify Bank Ledger Entries Amount.
        Assert.AreEqual(Amount2, CalculateBankLedgerEntryAmount(GenJournalLine."Document No."), 'Amount must be equal');
    end;

    local procedure ReverseBankLedgerEntry()
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating General Journal Lines.
        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure VerifyBankAccountListReport(BankAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account__No__', BankAccountNo);
        LibraryReportDataset.AssertElementWithValueExists('BankAccBalance', Amount);
    end;

    local procedure VerifyBankAccountRegisterReport(BankAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account_Ledger_Entry__Bank_Account_No__', BankAccountNo);
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account_Ledger_Entry___Credit_Amount__LCY__', Amount);
    end;

    local procedure VerifyBankAccDetailTrialBalReport(GenJournalLine: Record "Gen. Journal Line"; SignFactor: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_BankAccount', GenJournalLine."Bal. Account No.");
        LibraryReportDataset.AssertElementWithValueExists('DocNo_BankAccLedg', GenJournalLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('DocType_BankAccLedg', Format(GenJournalLine."Document Type"::Payment));
        LibraryReportDataset.AssertElementWithValueExists('Amount_BankAccLedg', SignFactor * GenJournalLine.Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountListReqPageHandler(var BankAccountList: TestRequestPage "Bank Account - List")
    var
        No: Variant;
        ShowBalanceInLCY: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(ShowBalanceInLCY);
        LibraryVariableStorage.Dequeue(No);
        BankAccountList."Bank Account".SetFilter("No.", No);
        BankAccountList.PrintAmountsInLCY.SetValue(ShowBalanceInLCY);  // Setting Show Balance In LCY.
        BankAccountList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountLabelReqPageHandler(var BankAccountLabels: TestRequestPage "Bank Account - Labels")
    var
        LabelFormat: Variant;
    begin
        LibraryVariableStorage.Dequeue(LabelFormat);  // Dequeue variable.
        BankAccountLabels.LabelFormat.SetValue(LabelFormat);  // Setting Label Format.
        BankAccountLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountRegisterReqPageHandler(var BankAccountRegister: TestRequestPage "Bank Account Register")
    var
        ShowBalanceInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowBalanceInLCY);  // Dequeue variable
        BankAccountRegister.PrintAmountsInLCY.SetValue(ShowBalanceInLCY);  // Setting Show Balance In LCY.
        BankAccountRegister.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccDetailTrialBalReqPageHandler(var BankAccDetailTrialBal: TestRequestPage "Bank Acc. - Detail Trial Bal.")
    var
        IncludeReversedEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(IncludeReversedEntries);  // Dequeue variable
        BankAccDetailTrialBal.PrintReversedEntries.SetValue(IncludeReversedEntries);  // Setting Include Reversed Entries.
        BankAccDetailTrialBal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

