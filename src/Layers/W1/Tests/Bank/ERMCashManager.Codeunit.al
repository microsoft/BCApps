codeunit 134500 "ERM Cash Manager"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        AmountErrorErr: Label 'Amount must be same.';
        EmailIDTxt: Label 'abc@microsoft.com', Locked = true;
        HomePageTxt: Label 'http://microsoft.com', Locked = true;
        PhoneAndFaxNoTxt: Label '4600600';
        CurrencyErrorErr: Label '%1 must be equal to 0 in %2.', Comment = '%1 Balance field; %2 Bank Account table.';
        ValueErrorErr: Label '%1 must have a value.', Comment = '%1 field name.';
        BankAccountBlockedErrorErr: Label '%1 must be equal to No in %2.', Comment = '%1 Blocked field; %2 Bank Account table';
        VATAmountErrorErr: Label 'VAT Amount must be equal.';
        NoOfVATEntryErrorErr: Label 'No. of  %1 must be %2. ', Comment = '%1 VAT Entry table; %2 count';
        StatementEndingBalanceErrorErr: Label '%1 must be equal to Total Balance.', Comment = 'Statement Ending Balance';
        UnknownErrorErr: Label 'Unknown Error.';
        SameCurrencyErrorMsg: Label 'The Bank Account and the General Journal Line must have the same currency';

    [Test]
    [Scope('OnPrem')]
    procedure UpdateBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test if Application allows to creating New Bank Account.

        // 1.Setup:
        Initialize();

        // 2.Exercise: Create and Update Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);
        InputValuesInBankAccount(BankAccount);

        // 3.Verification: Verify New Bank Account Created.
        VerifyBankAccountCreated(BankAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnBankAccount()
    var
        BankAccount: Record "Bank Account";
        GeneralLederSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Currency2: Record Currency;
    begin
        // Test if Application allows changing the Currency Code in the Bank Account Card
        // if balance in the Bank Account is not equal to zero.

        // 1.Setup: Create Bank Account with Currency. Create and Post General Journal.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateBankAccountWithCurrency(BankAccount, Currency.Code);
        CreatePostCustomerGenJnlLine(BankAccount."No.");
        GeneralLederSetup.get();
        // 2.Exercise: Change Currency on Bank Account.
        Currency2.SetFilter(Code, '<>%1&<>%2', Currency.Code, GeneralLederSetup."LCY Code");
        asserterror BankAccount.Validate("Currency Code", FindCurrency(Currency2));

        // 3.Verification: Error occurs while changing Currency Code on Bank Account.
        Assert.AreNotEqual(
          0, StrPos(GetLastErrorText, BankAccount."No."),
          StrSubstNo(CurrencyErrorErr, BankAccount.FieldCaption(Balance), BankAccount.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnBankAccountFromBlankToLCY()
    var
        BankAccount: Record "Bank Account";
        GeneralLederSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        // Test if Application allows changing the Currency Code in the Bank Account Card
        // if balance in the Bank Account is not equal to zero.

        // 1.Setup: Create Bank Account with Currency. Create and Post General Journal.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        GeneralLederSetup.get();
        GeneralLederSetup."LCY Code" := '';       // to avoid error on updating LCY Code
        GeneralLederSetup.Validate("LCY Code", Currency.Code);
        GeneralLederSetup.Modify();
        CreateBankAccountWithCurrency(BankAccount, '');
        CreatePostCustomerGenJnlLine(BankAccount."No.");

        // 2.Exercise: Change Currency on Bank Account To LCY.
        BankAccount.Validate("Currency Code", GeneralLederSetup."LCY Code");

        // 3.Verification: Error occurs while changing Currency Code on Bank Account.
        Assert.AreEqual(GeneralLederSetup."LCY Code", BankAccount."Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountPostingGroup()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test if Application allows posting any transactions without specifying
        // the "Bank Acc. Posting Group" in the Bank Account Card.

        // 1.Setup: Create Bank Account and Find Customer.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Acc. Posting Group", '');
        BankAccount.Modify(true);

        // 2.Exercise: Create General Journal and Post without Bank Acc. Posting Group.
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verification: Error occurs while post General Journal without Bank Acc. Posting Group.
        Assert.AreNotEqual(
          0, StrPos(GetLastErrorText, BankAccount."No."),
          StrSubstNo(ValueErrorErr, BankAccount.FieldCaption("Bank Acc. Posting Group")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintCheckWithoutLastCheckNo()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Check: Report Check;
    begin
        // Test if Application allows printing a check without providing the Last Check No. on the Posting tab of Bank Account Card.

        // 1.Setup: Create Bank Account. Find Vendor. Create and Post Gen. Journal Line. Create and apply General Journal Line.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePostInvoiceGenJnlLine(GenJournalLine, Vendor."No.");
        CreateAndApplyGenJnlLine(GenJournalLine, GenJournalLine."Document No.", BankAccount."No.", Vendor."No.");

        // 2.Exercise: Print Check Report.
        Clear(Check);
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, false, false);
        asserterror Check.InputBankAccount();

        // 3.Verification: Error occurs while Print check report without last check No.
        Assert.AreNotEqual(
          0, StrPos(GetLastErrorText, BankAccount."No."),
          StrSubstNo(ValueErrorErr, BankAccount.FieldCaption("Last Check No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BalanceAndBalanceLCYInAccount()
    var
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        CurrencyCode: Code[10];
    begin
        // Test if Application updates the "Balance" and "Balance (LCY)" fields in the Bank Account Card with correct values after posting
        // Cash Receipt/Payment transactions in bank's currency.

        // 1.Setup: Create Currency with Exchange Rate. Create Bank Account with currency.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            DMY2Date(1, 1, 2000), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateBankAccountWithCurrency(BankAccount, CurrencyCode);

        // 2.Exercise: Create and Post General Journal.
        CreatePostCustomerGenJnlLine(BankAccount."No.");

        // 3.Verification: Verify Bank Account Balance and Balance (LCY).
        Currency.Get(CurrencyCode);
        BankAccount.CalcFields(Balance, "Balance (LCY)");
        BankAccount.TestField(
          "Balance (LCY)",
          Round(
            LibraryERM.ConvertCurrency(
              BankAccount.Balance, CurrencyCode, '',
              LibraryERM.FindEarliestDateForExhRate()), Currency."Amount Rounding Precision"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccountWithVAT()
    var
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CurrencyCode: Code[10];
    begin
        // Test if the tax components value (e.g. - VAT) is correctly calculated in LCY for the transaction/s posted in FCY.

        // 1.Setup: Create Currency with Exchange Rate, Create Bank account with currency.
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            DMY2Date(1, 1, 2000), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        CreateBankAccountWithCurrency(BankAccount, CurrencyCode);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // 2.Exercise: Create and Post General Journal.
        UpdateGenJnlLineForVAT(GenJournalLine, VATPostingSetup, BankAccount."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verification: Verify Posted Vat Amount.
        Currency.Get(CurrencyCode);
        FindVATEntry(VATEntry, GenJournalLine."Document No.");
        Assert.AreEqual(1, VATEntry.Count, StrSubstNo(NoOfVATEntryErrorErr, VATEntry.TableCaption(), 1));
        Assert.AreNearlyEqual(
          VATEntry.Amount,
          LibraryERM.ConvertCurrency(GenJournalLine.Amount, CurrencyCode, '', LibraryERM.FindEarliestDateForExhRate()) *
          VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"), Currency."Amount Rounding Precision", VATAmountErrorErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountWithBlockedOption()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test if Application allows using any Bank Account in journals, when the "Blocked" field in that
        // Bank Account Card contains a check mark.

        // 1.Setup: Find Bank Account and Find Customer.
        Initialize();
        BlockedBankAccount(BankAccount);

        // 2.Exercise: Create General Journal.
        asserterror CreateGenJnlLine(
            GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.

        // 3.Verification: Error occurs while using Blocked Bank Account in General Journal.
        Assert.AreNotEqual(
          0, StrPos(GetLastErrorText, BankAccount."No."),
          StrSubstNo(BankAccountBlockedErrorErr, BankAccount.FieldCaption(Blocked), BankAccount.TableCaption()));

        // 4.TearDown: Roll back the Previous Bank Account.
        UnBlockedBankAccount(BankAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountOnGenJournalBatch()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test if Application correctly updates the "Balancing Account No." in the Cash Receipt/Payment journals.
        // when the "Balance Account Type" and "Balance Account No." fields in the General Journal Batches are filled in.

        // 1.Setup: Create Bank Account and Find Customer.
        Initialize();
        LibraryERM.FindBankAccount(BankAccount);

        // 2.Exercise: Update Bank Account on General Journal Batch and Create General Journal.
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.

        // 3.Verification: Verify "Bal. Account No." must be same as Bank Account "No.".
        GenJournalLine.TestField("Bal. Account No.", BankAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountReconcile()
    var
        BankAccount: Record "Bank Account";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        TempGLAccountNetChange: Record "G/L Account Net Change" temporary;
        Reconciliation: Page Reconciliation;
    begin
        // Test if Application correctly updates the values in the Bank - Reconciliation window before a payment journal is posted.

        // 1.Setup: Create Bank Account, G/L Account and General Journal.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGLAccount(GLAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDec(1000, 2));  // Using RANDOM for Amount.

        // 2.Exercise: Reconcile.
        Reconciliation.SetGenJnlLine(GenJournalLine);
        Reconciliation.ReturnGLAccountNetChange(TempGLAccountNetChange);

        // 3.Verification: Verify Amount must be same as "Net Change in Jnl.".
        TempGLAccountNetChange.Get(GLAccount."No.");
        GenJournalLine.TestField(Amount, TempGLAccountNetChange."Net Change in Jnl.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccountComputerCheck()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test whether the Application allows posting a payment transaction using the Computer Check option before the check is printed.

        // 1.Setup: Create Bank Account, find Vendor. Create and Post General Journal Line. Create and apply General Journal Line.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);
        CreatePostInvoiceGenJnlLine(GenJournalLine, Vendor."No.");
        CreateAndApplyGenJnlLine(GenJournalLine, GenJournalLine."Document No.", BankAccount."No.", Vendor."No.");

        // 2.Exercise: Posting General Journal with Computer Check option before Check is printed.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verification: Error occurs while Posting General Journal with Computer Check option before Check is printed.
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Check Printed"), Format(true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccountWithManualCheck()
    var
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        LastCheckNo: Code[20];
    begin
        // Test that the Application does not update the Last Check No. field in the Bank Account Card
        // after posting a Payment Journal with Bank Payment Type as Manual check.

        // 1.Setup: Create Bank Account, Find Vendor, Create General Journal Line with Bank Payment Type as Manual check.
        Initialize();
        CreateBankAccountLastCheckNo(BankAccount);
        LastCheckNo := BankAccount."Last Check No.";
        Vendor.SetRange("Currency Code", '');
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJnlLineWithBankPaymentType(
          GenJournalLine, BankAccount."No.", Vendor."No.", GenJournalLine."Bank Payment Type"::"Manual Check");

        // 2.Exercise: Posting General Journal with Manual Check option.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3.Verification: Verify Bank Account Last Check No. does not update.
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField("Last Check No.", LastCheckNo);
    end;

    [Test]
    [HandlerFunctions('CountCheckLedgerEntries,TestPrintCheckRequestPageHandler')]
    procedure OutstandingChecksDrilldownOnlyShowsRecordsFromItsBank()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        CheckLedgerEntryNo1: Integer;
        CheckLedgerEntryNo2: Integer;
    begin
        // [GIVEN] Two reconciliations with check entries for different banks
        CheckLedgerEntryNo1 := SetupBankWithOutstandingCheckPayment(BankAccount);
        CheckLedgerEntryNo2 := SetupBankWithOutstandingCheckPayment(BankAccount);
        LibraryVariableStorage.Enqueue(CheckLedgerEntryNo1);
        LibraryVariableStorage.Enqueue(CheckLedgerEntryNo2);

        // [WHEN] Visiting Drilldown of Balance on Outstanding Checks for one of them
        BankAccReconciliationPage.OpenEdit();
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        BankAccReconciliationPage.GoToRecord(BankAccReconciliation);
        BankAccReconciliationPage.ApplyBankLedgerEntries.CheckBalance.Drilldown();

        // [THEN] We should see the entry of one bank but not from the other.
        // On PageHandler CountCheckLedgerEntries
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatementNoBankReconciliation()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Test whether the program automatically updates the value in "Balance Last Statement" and "Statement No." fields
        // in the Bank Reconciliation window, except when it is the first Reconciliation Statement.

        // 1.Setup: Create Bank Account with "Statement No." and "Balance Last Statement" fields Value.
        Initialize();
        CreateBankAccountStatementNo(BankAccount);

        // 2.Exercise: Create "Bank Acc. Reconciliation" using Bank Account.
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");

        // 3.Verification: Verify "Balance Last Statement" and "Statement No." fields value.
        BankAccReconciliation.TestField("Statement No.", IncStr(BankAccount."Last Statement No."));
        BankAccReconciliation.TestField("Balance Last Statement", BankAccount."Balance Last Statement");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankReconciliationError()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Test whether the Application allows posting the Bank Reconciliation when the value in Statement Ending Balance field
        // is different from the Total Balance.

        // 1.Setup: Create Bank Account with "Statement No." and "Balance Last Statement" fields Value, Find Customer,
        // Create and Post General Journal Line, and Create "Bank Acc. Reconciliation" using Bank Account.
        Initialize();
        CreateBankAccountStatementNo(BankAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        SuggestLines(BankAccReconciliation, BankAccount);

        // 2.Exercise: Post "Bank Acc. Reconciliation".
        asserterror LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // 3.Verification: Verify Error Occurs when Value in Statement Ending Balance field is different from the Total Balance.
        Assert.AreEqual(
          StrSubstNo(
            StatementEndingBalanceErrorErr, BankAccReconciliation.FieldCaption("Statement Ending Balance")),
          GetLastErrorText, UnknownErrorErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankReconciliationTotal()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // Test that the Application doesn't allow posting the Bank Reconciliation when there is unapplied difference (line type Difference is deprecated)
        // 1.Setup: Create Bank Account with "Statement No." and "Balance Last Statement" fields Value, Find Customer,
        // Create and Post General Journal Line, and Create "Bank Acc. Reconciliation" using Bank Account.
        Initialize();
        CreateBankAccountStatementNo(BankAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");
        SuggestLines(BankAccReconciliation, BankAccount);
        CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        UpdateBalanceLastStatement(BankAccReconciliation);

        // 2.Exercise: Post "Bank Acc. Reconciliation".
        // 3.Verification: Verify Error Occurs
        AssertError LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankReconciliationSuggestLine()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Test whether any entry is unapplied in the Reconciliation window it gets again available in next reconciliation
        // window on doing suggest lines.

        // 1.Setup: Create Bank Account with "Statement No." and "Balance Last Statement" fields Value, Find Customer,
        // Create and Post General Journal Line, and Create "Bank Acc. Reconciliation" using Bank Account.
        Initialize();
        CreateBankAccountStatementNo(BankAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");

        // 2.Exercise: Create Suggest lines for "Bank Acc. Reconciliation".
        SuggestLines(BankAccReconciliation, BankAccount);

        // 3.Verification: Verify Bank Entry available in Reconciliation
        BankAccount.Get(BankAccount."No.");
        BankAccount.CalcFields(Balance);
        BankAccount.TestField(
          Balance,
          CalculateStatementAmount(
            BankAccReconciliation."Statement No.", BankAccReconciliation."Bank Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutBalAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify GL Entry after posting Purchase Order without Balancing Account.

        // Setup.
        Initialize();

        // Exercise: Create and Post Purchase order Without Balancing Account.
        CreatePurchaseOrder(PurchaseHeader, FindVendor(''));

        // Verify: Verify GL Entry Without Balancing Account.
        VerifyGLEntry(PurchaseHeader."No.", '', GLEntry."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithBalAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify GL Entry and Vendor Ledger Entry after posting Purchase Order with Balancing Account.

        // Setup.
        Initialize();

        // Exercise: Create and Post Purchase order With Balancing Account.
        CreatePurchaseOrder(PurchaseHeader, FindVendor('<>'''''));

        // Verify: Verify GL Entry and Vendor Ledger Entry With Balancing Account.
        VerifyGLEntry(PurchaseHeader."No.", '<>''''', GLEntry."Document Type"::Payment);
        VerifyVendorLedgerEntry(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReconciliationStatementAmount()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Test the Suggest Bank Account Reconciliation Lines.

        // 1.Setup: Create Bank Account with "Statement No." and "Balance Last Statement" fields Value, Find Customer,
        // Create and Post General Journal Line, and Create "Bank Acc. Reconciliation" using Bank Account.
        Initialize();
        CreateBankAccountStatementNo(BankAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.");

        // 2.Exercise: Create Suggest lines for "Bank Acc. Reconciliation".
        SuggestLines(BankAccReconciliation, BankAccount);

        // 3.Verification: Verify Amount in Bank Account Ledger Entry and in Bank Account Reconciliation.
        Assert.AreEqual(
          CalculateStatementAmount(BankAccReconciliation."Statement No.", BankAccReconciliation."Bank Account No."),
          AmountInBankAccountLedgerEntry(BankAccount."No.", BankAccReconciliation."Statement No."),
          AmountErrorErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralLineWithCorrection()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test the Application works properly when the Correction field in the Journals contains a check mark.

        // 1. Setup: Create Bank Account, create Customer and create General Journal line.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        CreateGenJnlLine(
          GenJournalLine, BankAccount."No.", GenJournalLine."Account Type"::Customer, Customer."No.",
          -LibraryRandom.RandDec(500, 2)); // Using RANDOM for Amount.

        // 2. Exercise: Post General Journal Line with Correction check mark.
        CorrectionGeneralJournalLine(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Debit amount for Correction in Customer Ledger Entry.
        VerifyLedgerEntryForCorrection(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmYes')]
    [Scope('OnPrem')]
    procedure ChangeBalanceLastStatement_ConfirmYes()
    var
        BankAccount: Record "Bank Account";
        BalanceLastStatement: Decimal;
    begin
        // 1.Setup:
        InitBalanceLastStatementScenario(BankAccount, BalanceLastStatement);

        // 2.Exercise: Update Balance Last Statement
        UpdateOnPageBalanceLastStatement(BankAccount."No.", BalanceLastStatement);

        // 3. Verify: Balance Last Statement is updated
        BankAccount.Find();
        BankAccount.TestField("Balance Last Statement", BalanceLastStatement);
    end;

    [Test]
    [HandlerFunctions('ConfirmNo')]
    [Scope('OnPrem')]
    procedure ChangeBalanceLastStatement_ConfirmNo()
    var
        BankAccount: Record "Bank Account";
        BalanceLastStatement: Decimal;
    begin
        // 1.Setup:
        InitBalanceLastStatementScenario(BankAccount, BalanceLastStatement);

        // 2.Exercise: Update Balance Last Statement, but decline confirmation
        asserterror UpdateOnPageBalanceLastStatement(BankAccount."No.", BalanceLastStatement);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBankTestTransmitted()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 478188 Setting on Bank Acount should enfore the check for Test Transmitted]

        // [GIVEN] General Journal Line with "Bal. Account Type" = Bank Account, And bank account with Test Transmitted set
        LibraryERM.CreateBankAccount(BankAccount);

        BankAccount."Check Transmitted" := true;
        BankAccount.modify();
        CreateGenJnlLineWithBankPaymentTypeWithExpToPaymentFileSet(
            GenJournalLine, BankAccount."No.", LibraryPurchase.CreateVendorNo(), GenJournalLine."Bank Payment Type"::"Electronic Payment");

        // [WHEN] Post General Journal Line. should giv an error
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);


        // [GIVEN] General Journal Line with "Bal. Account Type" = Bank Account, And bank account with Test Transmitted set
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJnlLineWithBankPaymentTypeWithExpToPaymentFileSet(
            GenJournalLine, BankAccount."No.", LibraryPurchase.CreateVendorNo(), GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine."Exported to Payment File" := true;
        GenJournalLine.Modify();

        // [WHEN] Post General Journal Line. should succed
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLedgerEntryWithManualCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        // [FEATURE] [General Journal] [Bank Payment] [Manual Check]
        // [SCENARIO 374790] post a payment journal with Bank Payment Type = Manual Check the Check Ledger Entry has Bank Payment Type = Manual Check.
        Initialize();

        // [GIVEN] General Journal Line with "Bal. Account Type" = Bank Account, "Bank Payment Type" = "Manual Check"
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJnlLineWithBankPaymentType(
          GenJournalLine, BankAccount."No.", LibraryPurchase.CreateVendorNo(), GenJournalLine."Bank Payment Type"::"Manual Check");

        // [WHEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "Check Ledger Entry" Field "Bank Payment Type" is set to "Manual Check".
        VerifyCheckLedgerEntry(GenJournalLine."Document No.", BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('CheckRequstPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCheckForPaymentsInMultipleCurrencies()
    var
        CustomerPaymentGenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BatchName: Code[10];
        TemplateName: Code[10];
        CurrencyCode: Code[10];
    begin
        Initialize();

        // 1. Create lines in different currencies and same document no.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Check No." := '1';
        BankAccount.Modify(true);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            DMY2Date(1, 1, 2000), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        LibrarySales.CreateCustomer(Customer);
        CreateGenJnlLinesWithDifferentCurrencies(CustomerPaymentGenJnlLine, BankAccount."No.",
          CustomerPaymentGenJnlLine."Account Type"::Customer, Customer."No.", CurrencyCode, BatchName, TemplateName);
        Commit();

        // 2. Print check - there should be an error since the currency of the bank and the gen. jnl line are not the same. (TFS 319808)
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        CustomerPaymentGenJnlLine.SetRange("Journal Template Name", CustomerPaymentGenJnlLine."Journal Template Name");
        CustomerPaymentGenJnlLine.SetRange("Journal Batch Name", CustomerPaymentGenJnlLine."Journal Batch Name");
        CustomerPaymentGenJnlLine.SetRange("Posting Date", CustomerPaymentGenJnlLine."Posting Date");
        asserterror REPORT.Run(REPORT::Check, true, false, CustomerPaymentGenJnlLine);

        Assert.ExpectedError(SameCurrencyErrorMsg);

        CustomerPaymentGenJnlLine.Delete(true);
    end;

    [Test]
    [HandlerFunctions('CheckRequstPageHandler')]
    [Scope('OnPrem')]
    procedure DisablePrintCheckForExportedPayment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Payment][Check]

        // [SCENARIO 375650] "Check" should not be printed for a Gen. Journal Line, where "Exported to Payment File" is Yes
        Initialize();

        // [GIVEN] Gen. Journal Line, where "Bank Payment Type" is "Computer Check", "Exported to Payment File" is Yes
        CreateBankAccountLastCheckNo(BankAccount);
        CreateGenJnlLineWithBankPaymentType(
          GenJournalLine, BankAccount."No.", LibraryPurchase.CreateVendorNo(), GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine."Exported to Payment File" := true;
        GenJournalLine.Modify();
        CreateGenJnlBatchForBank(GenJournalBatch, BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        Commit();

        // [WHEN] Run report "Check"
        asserterror REPORT.Run(REPORT::Check, true, false, GenJournalLine);

        // [THEN] Error "Exported to Payment File must be equal to 'No' in Gen. Journal Line" should be show
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Exported to Payment File"), Format(false));
    end;

    [Test]
    [HandlerFunctions('TestPrintCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestPrintCheckDoesNotIncrementLastCheckNo()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        LastCheckNo: Code[20];
    begin
        // [FEATURE] [Report] [Check] [UT]
        // [SCENARIO 338023] Check report with TestPrint do not increment bank account "Last Check No."
        Initialize();

        // [GIVEN] Bank Account with Last Check No = 10
        LastCheckNo := CreateBankAccountLastCheckNo(BankAccount);

        // [GIVEN] Gen. Journal Line with Bank Account for print Check
        PrepareGenJnlLineForCheckPrinting(GenJournalLine, BankAccount."No.");

        // [WHEN] Run report "Check" with TestPrint option enabled
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        LibraryVariableStorage.Enqueue(true);
        Commit();
        REPORT.Run(REPORT::Check, true, false, GenJournalLine);

        // [THEN] Bank Account "Last Check No." was not changed
        BankAccount.Find();
        BankAccount.TestField("Last Check No.", LastCheckNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('TestPrintCheckRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LastCheckNoIncrementedWhenCheckPrintedWithTestPrintDisabled()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        LastCheckNo: Code[20];
    begin
        // [FEATURE] [Report] [Check] [UT]
        // [SCENARIO 338023] "Check" report without TestPrint option increment bank account "Last Check No."
        Initialize();

        // [GIVEN] Bank Account with Last Check No = 10
        LastCheckNo := CreateBankAccountLastCheckNo(BankAccount);

        // [GIVEN] Gen. Journal Line with Bank Account for print Check
        PrepareGenJnlLineForCheckPrinting(GenJournalLine, BankAccount."No.");

        // [WHEN] Run report "Check" with TestPrint option disabled
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        LibraryVariableStorage.Enqueue(false);
        Commit();
        REPORT.Run(REPORT::Check, true, false, GenJournalLine);

        // [THEN] Bank Account "Last Check No." was updated to the next value
        BankAccount.Find();
        Assert.AreNotEqual(BankAccount."Last Check No.", LastCheckNo, 'Last Check No. must be updated');
        BankAccount.TestField("Last Check No.", IncStr(LastCheckNo));

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Manager");
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Manager");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Manager");
    end;

    local procedure SetupBankWithOutstandingCheckPayment(var BankAccount: Record "Bank Account"): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        LastCheckNo: Code[20];
        NextCheckEntryNo: Integer;
    begin
        Initialize();
        LastCheckNo := CreateBankAccountLastCheckNo(BankAccount);

        PrepareGenJnlLineForCheckPrinting(GenJournalLine, BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        LibraryVariableStorage.Enqueue(BankAccount."Last Check No.");
        LibraryVariableStorage.Enqueue(false);

        if CheckLedgerEntry.FindLast() then
            NextCheckEntryNo := CheckLedgerEntry."Entry No." + 1
        else
            NextCheckEntryNo := 1;

        CheckLedgerEntry.Init();
        CheckLedgerEntry."Entry No." := NextCheckEntryNo;
        CheckLedgerEntry."Bank Account No." := BankAccount."No.";
        CheckLedgerEntry."Document Type" := CheckLedgerEntry."Document Type"::Payment;
        CheckLedgerEntry.Amount := LibraryRandom.RandDec(500, 2);
        CheckLedgerEntry."Check No." := GenJournalLine."Document No.";
        CheckLedgerEntry."Bank Payment Type" := CheckLedgerEntry."Bank Payment Type"::"Computer Check";
        CheckLedgerEntry."Entry Status" := CheckLedgerEntry."Entry Status"::Posted;
        CheckLedgerEntry.Insert(true);
        Commit();

        Report.Run(Report::Check, true, false, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(CheckLedgerEntry."Entry No.");
    end;

    local procedure AmountInBankAccountLedgerEntry(BankAccountNo: Code[20]; StatementNo: Code[20]): Decimal
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Statement No.", StatementNo);
        BankAccountLedgerEntry.FindFirst();
        exit(BankAccountLedgerEntry.Amount);
    end;

    local procedure BlockedBankAccount(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.FindBankAccount(BankAccount);
        BankAccount.Validate(Blocked, true);
        BankAccount.Validate(IBAN, FindIBAN());
        BankAccount.Modify(true);
    end;

    local procedure CalculateStatementAmount(StatementNo: Code[20]; BankAccountNo: Code[20]): Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type"::"Bank Reconciliation");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.SetRange("Statement No.", StatementNo);
        BankAccReconciliationLine.CalcSums("Statement Amount");
        exit(BankAccReconciliationLine."Statement Amount");
    end;

    local procedure CorrectionGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Validate(Correction, true);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo,
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate());
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankAccountWithCurrency(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateAndApplyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20]; BankAccountNo: Code[20]; AccountNo: Code[20])
    begin
        CreateGenJnlLine(
          GenJournalLine, BankAccountNo, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateBankAccountLastCheckNo(var BankAccount: Record "Bank Account"): Code[20]
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate(
          "Last Check No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Check No."), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo("Last Check No."))));
        BankAccount.Modify(true);
        exit(BankAccount."Last Check No.");
    end;

    local procedure CreateBankAccountStatementNo(var BankAccount: Record "Bank Account")
    begin
        // Using RANDOM value for Balance Last Statement.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Balance Last Statement", LibraryRandom.RandDec(50000, 2));
        BankAccount.Validate(
          "Last Statement No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Statement No."), DATABASE::"Bank Account"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo("Last Statement No."))));
        BankAccount.Modify(true);
    end;

    local procedure CreateGenJnlLineWithBankPaymentTypeWithExpToPaymentFileSet(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type")
    begin
        CreateGenJnlLineWithBankPaymentType(
           GenJournalLine, BankAccountNo, AccountNo, BankPaymentType);
        GenJournalLine."Exported to Payment File" := true;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJnlLineWithBankPaymentType(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; AccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type")
    begin
        CreateGenJnlLine(GenJournalLine, BankAccountNo, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatchForBank(GenJournalBatch, BankAccountNo);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
    end;

    local procedure CreatePostCustomerGenJnlLine(BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(
          GenJournalLine, BankAccountNo, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          -LibraryRandom.RandDec(500, 2));  // Using RANDOM for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor,
          AccountNo, -LibraryRandom.RandDec(2000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Reconciliation Account", true);
        GLAccount.Modify(true);
    end;

    local procedure CreateGenJnlBatchForBank(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BalAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateBankAccReconciliationLn(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate(Difference, LibraryRandom.RandDec(50, 2));  // Using RANDOM for Amount.
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // Using Random value for Modify Last Direct cost of Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Using Random value for creating purchase line.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure FindVendor(BalAccountNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", BalAccountNo);
        PaymentMethod.FindFirst();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.FindFirst();
    end;

    local procedure FindCurrency(var Currency: Record Currency): Code[10]
    begin
        LibraryERM.FindCurrency(Currency);
        exit(Currency.Code);
    end;

    local procedure FindIBAN(): Code[50]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation.IBAN);
    end;

    local procedure FindPostCode(): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        exit(PostCode.Code);
    end;

    local procedure FindCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure FindSalespersonPurchaserCode(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        exit(SalespersonPurchaser.Code);
    end;

    local procedure InputValuesInBankAccount(var BankAccount: Record "Bank Account")
    var
        Currency: Record Currency;
    begin
        BankAccount.Validate(
          Address,
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(Address), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo(Address))));
        BankAccount.Validate("Address 2", CopyStr(BankAccount.Address, 1, MaxStrLen(BankAccount."Address 2")));
        BankAccount.Validate("Country/Region Code", FindCountryRegionCode());
        BankAccount.Validate("Post Code", FindPostCode());
        BankAccount.Validate("Phone No.", PhoneAndFaxNoTxt);  // Using text.
        BankAccount.Validate(
          Contact,
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(Contact), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo(Contact))));
        BankAccount.Validate(
          "Bank Branch No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Bank Branch No."), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo("Bank Branch No."))));
        BankAccount.Validate("Bank Account No.", BankAccount."Bank Branch No.");
        BankAccount.Validate("Min. Balance", LibraryRandom.RandDec(50000, 2));  // Using RANDOM for Minimum Balance.
        BankAccount.Validate("Our Contact Code", FindSalespersonPurchaserCode());
        BankAccount.Validate("Fax No.", PhoneAndFaxNoTxt);  // Using text.
        BankAccount.Validate("E-Mail", EmailIDTxt);  // Using text.
        BankAccount.Validate("Home Page", HomePageTxt);  // Using text.
        BankAccount.Validate(
          "Last Check No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("Last Check No."), DATABASE::"Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Bank Account", BankAccount.FieldNo("Last Check No."))));
        BankAccount.Validate("Transit No.", BankAccount."Last Check No.");
        BankAccount.Validate("Last Statement No.", BankAccount."Last Check No.");
        BankAccount.Validate("Balance Last Statement", LibraryRandom.RandDec(50000, 2));
        BankAccount.Validate(IBAN, FindIBAN());
        BankAccount.Validate("SWIFT Code", LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account"));
        BankAccount.Validate("Currency Code", FindCurrency(Currency));
        BankAccount.Modify(true);
    end;

    local procedure PrepareGenJnlLineForCheckPrinting(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    begin
        CreateGenJnlLineWithBankPaymentType(
          GenJournalLine, BankAccountNo, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
    end;

    local procedure SuggestLines(BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccount: Record "Bank Account")
    var
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        Clear(SuggestBankAccReconLines);
        BankAccount.SetRange("No.", BankAccount."No.");
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate(), WorkDate(), false);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.Run();
    end;

    local procedure UnBlockedBankAccount(BankAccount: Record "Bank Account")
    begin
        BankAccount.Validate(Blocked, false);
        BankAccount.Modify(true);
    end;

    local procedure UpdateGenJnlLineForVAT(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; BankAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CreateGenJnlLine(
          GenJournalLine, BankAccountNo, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          LibraryRandom.RandDec(1000, 2));  // Using RANDOM for Amount.
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateBalanceLastStatement(var BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        BankAccReconciliation.Validate(
          "Statement Ending Balance",
          CalculateStatementAmount(
            BankAccReconciliation."Statement No.", BankAccReconciliation."Bank Account No.") +
          BankAccReconciliation."Balance Last Statement");
        BankAccReconciliation.Modify(true);
    end;

    local procedure VerifyBankAccountCreated(BankAccount: Record "Bank Account")
    var
        NewBankAccount: Record "Bank Account";
    begin
        NewBankAccount.Get(BankAccount."No.");
        NewBankAccount.TestField(Name, BankAccount.Name);
        NewBankAccount.TestField(Address, BankAccount.Address);
        NewBankAccount.TestField("Address 2", BankAccount."Address 2");
        NewBankAccount.TestField("Post Code", BankAccount."Post Code");
        NewBankAccount.TestField("Country/Region Code", BankAccount."Country/Region Code");
        NewBankAccount.TestField("Phone No.", BankAccount."Phone No.");
        NewBankAccount.TestField(Contact, BankAccount.Contact);
        NewBankAccount.TestField("Bank Branch No.", BankAccount."Bank Branch No.");
        NewBankAccount.TestField("Bank Account No.", BankAccount."Bank Account No.");
        NewBankAccount.TestField("Min. Balance", BankAccount."Min. Balance");
        NewBankAccount.TestField("Our Contact Code", BankAccount."Our Contact Code");
        NewBankAccount.TestField("Fax No.", BankAccount."Fax No.");
        NewBankAccount.TestField("E-Mail", BankAccount."E-Mail");
        NewBankAccount.TestField("Home Page", BankAccount."Home Page");
        NewBankAccount.TestField("Last Check No.", BankAccount."Last Check No.");
        NewBankAccount.TestField("Transit No.", BankAccount."Transit No.");
        NewBankAccount.TestField("Last Statement No.", BankAccount."Last Statement No.");
        NewBankAccount.TestField("Balance Last Statement", BankAccount."Balance Last Statement");
        NewBankAccount.TestField("SWIFT Code", BankAccount."SWIFT Code");
        NewBankAccount.TestField("Currency Code", BankAccount."Currency Code");
        NewBankAccount.TestField("Bank Acc. Posting Group", BankAccount."Bank Acc. Posting Group");
    end;

    local procedure VerifyLedgerEntryForCorrection(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Debit Amount");
        CustLedgerEntry.TestField("Debit Amount", GenJournalLine.Amount);
    end;

    local procedure VerifyGLEntry(OrderNo: Code[20]; BalAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();

        GLEntry.SetRange("Document No.", PurchInvHeader."No.");
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetFilter("Bal. Account No.", BalAccountNo);
        Commit();
        GLEntry.FindLast();
    end;

    local procedure VerifyVendorLedgerEntry(OrderNo: Code[20]; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();

        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetFilter("Bal. Account No.", '<>''''');
        VendorLedgerEntry.FindFirst();
    end;

    local procedure VerifyCheckLedgerEntry(DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Document No.", DocumentNo);
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField("Bank Payment Type", CheckLedgerEntry."Bank Payment Type"::"Manual Check");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure UpdateOnPageBalanceLastStatement(BankAccountNo: Code[20]; NewBalanceLastStatement: Decimal)
    var
        BankAccountCard: TestPage "Bank Account Card";
    begin
        BankAccountCard.OpenEdit();
        BankAccountCard.FILTER.SetFilter("No.", BankAccountNo);
        BankAccountCard."Balance Last Statement".SetValue(NewBalanceLastStatement);
        BankAccountCard.OK().Invoke();
    end;

    local procedure InitBalanceLastStatementScenario(var BankAccount: Record "Bank Account"; var BalanceLastStatement: Decimal)
    begin
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        BalanceLastStatement := LibraryRandom.RandDec(100, 2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CheckRequstPageHandler(var CheckRequestPage: TestRequestPage Check)
    var
        LastCheckNo: Variant;
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(LastCheckNo);
        CheckRequestPage.BankAccount.SetValue(Format(BankAccountNo));
        CheckRequestPage.LastCheckNo.SetValue(Format(LastCheckNo));
        CheckRequestPage.OneCheckPerVendorPerDocumentNo.SetValue(true);
        CheckRequestPage.ReprintChecks.SetValue(true);
        CheckRequestPage.SaveAsPdf(Format(CreateGuid()));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TestPrintCheckRequestPageHandler(var CheckRequestPage: TestRequestPage Check)
    var
        LastCheckNo: Variant;
        BankAccountNo: Variant;
        TestPrint: Boolean;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(LastCheckNo);
        TestPrint := LibraryVariableStorage.DequeueBoolean();
        CheckRequestPage.BankAccount.SetValue(Format(BankAccountNo));
        CheckRequestPage.LastCheckNo.SetValue(Format(LastCheckNo));
        CheckRequestPage.TestPrinting.SetValue(TestPrint);
        CheckRequestPage.SaveAsPdf(Format(CreateGuid()));
    end;

    local procedure CreateGenJnlLinesWithDifferentCurrencies(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; var BatchName: Code[10]; var TemplateName: Code[10]) Amount: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DocNo: Code[20];
    begin
        CreateGenJnlBatchForBank(GenJournalBatch, BankAccountNo);
        BatchName := GenJournalBatch.Name;
        TemplateName := GenJournalBatch."Journal Template Name";

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, TemplateName, BatchName, GenJournalLine."Document Type"::Refund, AccountType, AccountNo,
          LibraryRandom.RandDec(500, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        DocNo := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);

        Amount += GenJournalLine."Amount (LCY)";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, TemplateName, BatchName, GenJournalLine."Document Type"::Refund, AccountType, AccountNo,
          LibraryRandom.RandDec(500, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);
        Amount += GenJournalLine."Amount (LCY)";
    end;

    [PageHandler]
    procedure CountCheckLedgerEntries(var CheckLedgerEntriesPage: TestPage "Check Ledger Entries")
    var
        FirstEntry: Integer;
        SecondEntry: Integer;
        HasFirstEntry: Boolean;
        HasSecondEntry: Boolean;
    begin
        FirstEntry := LibraryVariableStorage.DequeueInteger();
        SecondEntry := LibraryVariableStorage.DequeueInteger();
        // [THEN] We should see the entry of one bank but not from the other.
        if CheckLedgerEntriesPage.First() then
            repeat
                if CheckLedgerEntriesPage."Entry No.".AsInteger() = FirstEntry then
                    HasFirstEntry := true;
                if CheckLedgerEntriesPage."Entry No.".AsInteger() = SecondEntry then
                    HasSecondEntry := true;
            until not CheckLedgerEntriesPage.Next();
        Assert.IsFalse(HasFirstEntry, 'Entry for another account found in the check drilldown');
        Assert.IsTrue(HasSecondEntry, 'Entry for account not found in the check drilldown');
    end;
}
