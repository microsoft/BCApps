codeunit 144014 "G/L Acc. Provisional Balance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceGLToGL()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::"G/L Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceGLToGLWithCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::"G/L Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);
        AddCurrencyToGLAccount(GenJournalLine);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceCustomerToGL()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Bal. Account Type"::"G/L Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceGLToBank()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::"Bank Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceBankToGL()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"Bank Account",
          GenJournalLine."Bal. Account Type"::"G/L Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"Bank Account", AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceCustomerToBank()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Bal. Account Type"::"Bank Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceVendorToBank()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Bal. Account Type"::"Bank Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceVendorToGL()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Bal. Account Type"::"G/L Account");
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::Vendor, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceGLToCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::Customer);
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::Customer, BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    [Test]
    [HandlerFunctions('GLAccProvisionalBalancePageHandler')]
    [Scope('OnPrem')]
    procedure ProvBalanceGLToVendor()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        Initialize();

        // Setup.
        CreateAccountsWithBalance(AccountNo, BalAccountNo, GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account Type"::Vendor);
        CreateUnpostedBatch(GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", AccountNo,
          GenJournalLine."Bal. Account Type"::Vendor, BalAccountNo);
        FindGenJnlLine(GenJournalLine, GenJournalBatch);

        // Exercise.
        LibraryVariableStorage.Enqueue(GenJournalLine);
        PAGE.Run(PAGE::"G/L Acc. Provisional Balance", GenJournalLine);

        // Verify: In the page handler.
    end;

    local procedure CreateAccountsWithBalance(var AccountNo: Code[20]; var BalAccountNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; BalAccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        AccountNo := CreateAccount(AccountType);
        BalAccountNo := CreateAccount(BalAccountType);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", AccountType, AccountNo, BalAccountType, BalAccountNo,
          LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAccount(AccountType: Enum "Gen. Journal Account Type"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
    begin
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                begin
                    LibraryERM.CreateGLAccount(GLAccount);
                    exit(GLAccount."No.");
                end;
            GenJournalLine."Account Type"::"Bank Account":
                begin
                    LibraryERM.CreateBankAccount(BankAccount);
                    exit(BankAccount."No.");
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    LibrarySales.CreateCustomer(Customer);
                    exit(Customer."No.");
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    LibraryPurchase.CreateVendor(Vendor);
                    exit(Vendor."No.");
                end;
        end;
    end;

    local procedure FindGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
    end;

    local procedure AddCurrencyToGLAccount(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        GLAccount.SetFilter("No.", '%1|%2', GenJournalLine."Account No.", GenJournalLine."Bal. Account No.");
        GLAccount.ModifyAll("Source Currency Code", Currency.Code);
        GenJournalLine.Validate("Currency Code", Currency.Code);
        GenJournalLine.Modify(true);
    end;

    local procedure GetExpectedValues(var AccountName: Text; var BalanceLCY: Decimal; var BalanceFCY: Decimal; var CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                begin
                    GLAccount.Get(AccountNo);
                    GLAccount.CalcFields(Balance);
                    GLAccountSourceCurrency."G/L Account No." := GLAccount."No.";
                    GLAccountSourceCurrency."Currency Code" := GLAccount."Source Currency Code";
                    GLAccountSourceCurrency.CalcFields("Source Curr. Balance at Date");
                    AccountName := GLAccount.Name;
                    BalanceLCY := GLAccount.Balance;
                    BalanceFCY := GLAccountSourceCurrency."Source Curr. Balance at Date";
                    CurrencyCode := GLAccount."Source Currency Code";
                end;
            GenJournalLine."Account Type"::"Bank Account":
                begin
                    BankAccount.Get(AccountNo);
                    BankAccount.CalcFields(Balance, "Balance (LCY)");
                    AccountName := BankAccount.Name;
                    BalanceLCY := BankAccount."Balance (LCY)";
                    BalanceFCY := BankAccount.Balance;
                    CurrencyCode := BankAccount."Currency Code";
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    Customer.Get(AccountNo);
                    Customer.CalcFields(Balance, "Balance (LCY)");
                    AccountName := Customer.Name;
                    BalanceLCY := Customer."Balance (LCY)";
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    Vendor.Get(AccountNo);
                    Vendor.CalcFields(Balance, "Balance (LCY)");
                    AccountName := Vendor.Name;
                    BalanceLCY := -Vendor."Balance (LCY)";
                end;
        end;
    end;

    local procedure CreateUnpostedBatch(var GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", AccountType, AccountNo,
          BalAccountType, BalAccountNo,
          LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine2, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine2."Document Type"::" ", AccountType, AccountNo,
          BalAccountType, BalAccountNo,
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure GetUnpostedBalance(var NotPostedBalanceLCY: Decimal; var NotPostedBalanceFCY: Decimal; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account Type", AccountType);
        GenJournalLine.SetRange("Account No.", AccountNo);
        GenJournalLine.CalcSums("Amount (LCY)");
        NotPostedBalanceLCY := GenJournalLine."Amount (LCY)";

        GenJournalLine.SetRange("Currency Code", CurrencyCode);
        GenJournalLine.CalcSums(Amount);
        if CurrencyCode <> '' then
            NotPostedBalanceFCY := GenJournalLine.Amount;

        GenJournalLine.Reset();
        GenJournalLine.SetRange("Bal. Account Type", AccountType);
        GenJournalLine.SetRange("Bal. Account No.", AccountNo);
        GenJournalLine.CalcSums("Amount (LCY)");
        NotPostedBalanceLCY -= GenJournalLine."Amount (LCY)";

        GenJournalLine.SetRange("Currency Code", CurrencyCode);
        GenJournalLine.CalcSums(Amount);

        if CurrencyCode <> '' then
            NotPostedBalanceFCY -= GenJournalLine.Amount;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLAccProvisionalBalancePageHandler(var GLAccProvisionalBalance: TestPage "G/L Acc. Provisional Balance")
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineVar: Variant;
        CurrencyCode: Code[10];
        BalCurrencyCode: Code[10];
        ExpAccName: Text;
        ExpAccBalanceLCY: Decimal;
        ExpAccBalanceFCY: Decimal;
        ExpBalAccName: Text;
        ExpBalAccBalanceLCY: Decimal;
        ExpBalAccBalanceFCY: Decimal;
        ExpUnpostedAccLCY: Decimal;
        ExpUnpostedAccFCY: Decimal;
        ExpUnpostedBalAccLCY: Decimal;
        ExpUnpostedBalAccFCY: Decimal;
    begin
        LibraryVariableStorage.Dequeue(GenJournalLineVar);
        GenJournalLine := GenJournalLineVar;

        GetExpectedValues(ExpAccName, ExpAccBalanceLCY, ExpAccBalanceFCY, CurrencyCode,
          GenJournalLine."Account Type", GenJournalLine."Account No.");
        GetExpectedValues(ExpBalAccName, ExpBalAccBalanceLCY, ExpBalAccBalanceFCY, BalCurrencyCode,
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.");
        GetUnpostedBalance(ExpUnpostedAccLCY, ExpUnpostedAccFCY,
          GenJournalLine."Account Type", GenJournalLine."Account No.", CurrencyCode);
        GetUnpostedBalance(ExpUnpostedBalAccLCY, ExpUnpostedBalAccFCY,
          GenJournalLine."Account Type", GenJournalLine."Account No.", BalCurrencyCode);

        // Show current journal.
        GLAccProvisionalBalance."A&ctual Journal".Invoke();

        GLAccProvisionalBalance.AccNumber.AssertEquals(GenJournalLine."Account No.");
        GLAccProvisionalBalance.AccName.AssertEquals(ExpAccName);
        GLAccProvisionalBalance.AccBalance.AssertEquals(ExpAccBalanceLCY);
        GLAccProvisionalBalance.AccCurrency.AssertEquals(CurrencyCode);
        GLAccProvisionalBalance.AccBalanceFC.AssertEquals(ExpAccBalanceFCY);

        GLAccProvisionalBalance.BalAccNo.AssertEquals(GenJournalLine."Bal. Account No.");
        GLAccProvisionalBalance.BalAccName.AssertEquals(ExpBalAccName);
        GLAccProvisionalBalance.BalAccBalance.AssertEquals(ExpBalAccBalanceLCY);
        GLAccProvisionalBalance.BalAccCurrency.AssertEquals(BalCurrencyCode);
        GLAccProvisionalBalance.BalAccBalanceFC.AssertEquals(ExpBalAccBalanceFCY);

        GLAccProvisionalBalance.AccNotPosted.AssertEquals(GenJournalLine."Amount (LCY)");
        GLAccProvisionalBalance.AccNotPostedFC.AssertEquals(ExpUnpostedAccFCY);
        GLAccProvisionalBalance.BalAccNotPosted.AssertEquals(-GenJournalLine."Amount (LCY)");
        GLAccProvisionalBalance.BalAccNotPostedFC.AssertEquals(-ExpUnpostedBalAccFCY);

        // Show all journals.
        GLAccProvisionalBalance."&All Journals".Invoke();
        GLAccProvisionalBalance.AccNotPosted.AssertEquals(ExpUnpostedAccLCY);
        GLAccProvisionalBalance.AccNotPostedFC.AssertEquals(ExpUnpostedAccFCY);
        GLAccProvisionalBalance.BalAccNotPosted.AssertEquals(-ExpUnpostedBalAccLCY);
        GLAccProvisionalBalance.BalAccNotPostedFC.AssertEquals(-ExpUnpostedBalAccFCY);
    end;
}
