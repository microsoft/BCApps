codeunit 134883 "ERM Exch. Rate Adjustment"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Exch. Rate Adjustment v.20]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        ExpectNoAdjustmentErr: Label 'Expect no adjustment for entries before %1';
        ExchangeRateAdjmtTxt: Label 'Exchange Rate Adjmt. of %1 %2';

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchangeRates()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test run the Adjust Exchange Rate and check the corresponding ledger entries.

        // 1. Setup: Create a new Currency with Exchange Rate, create another Exchange Rate for the Currency having greater
        // Relational Exch Rate Amount.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");

        // Create two GL Entries for two different GL Accounts having different Exchange Rate Adjustment.
        CreateGLEntryForAccount(
          GLAccount, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Amount", WorkDate());
        CreateGLEntryForAccount(
          GLAccount2, CurrencyExchangeRate."Currency Code", GLAccount2."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          WorkDate());
        CreateNewExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run the report Adjust Exchange Rate.
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunExchRateAdjustment(
          CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate(), ExchangeRateAdjmtTxt, WorkDate(), DocumentNo, true);

        // 3. Verification: Verify that the amount in GL Entry is populated as per the adjustment exchange rate for both GL Accounts.
        VerifyGLEntryAdjustAmount(GLAccount, DocumentNo, CurrencyExchangeRate."Currency Code");
        VerifyGLEntry(DocumentNo, GLAccount2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustExchRateACYStartDate()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Test Start Date Field is Used for  Additional Reporting Currency Adjustment.

        // 1. Setup: Create a new Currency with Exchange Rate.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Setup: Configure Additional Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyExchangeRate."Currency Code");

        // Setup: Create two GL Entries for two different GL Accounts with Different Posting Date.
        CreateGLEntryForAccount(
          GLAccount, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          LibraryRandom.RandDate(-7));  // Random Date in the Past.
        CreateGLEntryForAccount(
          GLAccount2, CurrencyExchangeRate."Currency Code", GLAccount."Exchange Rate Adjustment"::"Adjust Additional-Currency Amount",
          WorkDate());

        // Setup: Create new Exchange Rate for a WORKDATE.
        CreateNewExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run the report Adjust Exchange Rate.
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunExchRateAdjustment(
          CurrencyExchangeRate."Currency Code", WorkDate(), WorkDate(), ExchangeRateAdjmtTxt, WorkDate(), DocumentNo, true);

        // 3. Verification: Verify that Entries with Posting Date Less than WORKDATE Were Not Adjusted.
        Assert.IsFalse(VerifyGLEntryFound(DocumentNo, GLAccount."No."), StrSubstNo(ExpectNoAdjustmentErr, WorkDate()));

        // 4. Verification: Verify that Entries with Posting Date Equal to WORKDATE Were Adjusted.
        VerifyGLEntry(DocumentNo, GLAccount2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoErrorOnCurrenciesPage()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currencies: TestPage Currencies;
    begin
        // Check that there is no error exist on currencies page when exchange rate is defined with starting date only.

        // Setup:Create currency and create Exchange Rate with starting date only.
        Initialize();
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());

        // Exercise: Open Currencies page.
        Currencies.OpenEdit();
        Currencies.FILTER.SetFilter(Code, Currency.Code);

        // Verify: Verifying that Currency Code exist on page and no error exist when open the page.
        Currencies.Code.AssertEquals(Currency.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExchRateAdjmtRegisterSyncWithLedgerEntries()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        PostingDate: Date;
    begin
        // [SCENARIO 612802] Exchange Rate Adjustment Registers and Exch. Rate Adjmt. Ledger Entries are in synchrony after multiple adjustments.

        // [GIVEN] Currency with exchange rate 1-0.5
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        Currency.Get(CurrencyExchangeRate."Currency Code");
        UpdateExchangeRate(CurrencyExchangeRate, 1, 0.5);
        PostingDate := WorkDate();

        // [GIVEN] Posted Sales Invoice for 1000 with exchange rate 1-0.5
        CreateAndPostSalesInvoice(SalesHeader, CurrencyExchangeRate."Currency Code", PostingDate, 1000);

        // [GIVEN] Exchange rate changed to 1-0.6 and adjustment run
        UpdateCurrencyExchangeRate(CurrencyExchangeRate, PostingDate, 1, 0.6);
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunExchRateAdjustment(
          CurrencyExchangeRate."Currency Code", PostingDate, PostingDate, ExchangeRateAdjmtTxt, PostingDate, DocumentNo, false);

        // [GIVEN] Posted Purchase Invoice for 2000 with exchange rate 1-0.6
        CreateAndPostPurchaseInvoice(PurchaseHeader, CurrencyExchangeRate."Currency Code", PostingDate, 2000);

        // [GIVEN] Exchange rate changed to 1-0.4 and adjustment run
        UpdateCurrencyExchangeRate(CurrencyExchangeRate, PostingDate, 1, 0.4);
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunExchRateAdjustment(
          CurrencyExchangeRate."Currency Code", PostingDate, PostingDate, ExchangeRateAdjmtTxt, PostingDate, DocumentNo, false);

        // [GIVEN] Posted Sales Invoice for 1000 with exchange rate 1-0.4
        CreateAndPostSalesInvoice(SalesHeader, CurrencyExchangeRate."Currency Code", PostingDate, 1000);

        // [WHEN] Exchange rate changed to 1-0.8 and adjustment run
        UpdateCurrencyExchangeRate(CurrencyExchangeRate, PostingDate, 1, 0.8);
        DocumentNo := Format(LibraryRandom.RandInt(100));
        LibraryERM.RunExchRateAdjustment(
          CurrencyExchangeRate."Currency Code", PostingDate, PostingDate, ExchangeRateAdjmtTxt, PostingDate, DocumentNo, false);

        // [THEN] Exchange Rate Adjustment Register amounts match sum of Exch. Rate Adjmt. Ledger Entry amounts
        VerifyExchRateAdjmtRegisterSync(CurrencyExchangeRate."Currency Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjustment");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Exch. Rate Adjustment");

        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Exch. Rate Adjustment");
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        SetupAccountOnCurrency(Currency);
        Currency.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, 0D);
        UpdateExchangeRate(CurrencyExchangeRate, 100 * LibraryRandom.RandInt(4), 200 * LibraryRandom.RandInt(4));
    end;

    local procedure CreateGLEntryForAccount(var GLAccount: Record "G/L Account"; CurrencyCode: Code[10]; ExchangeRateAdjustment: Enum "Exch. Rate Adjmt. Account Type"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Exchange Rate Adjustment", ExchangeRateAdjustment);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        CreateGeneralJournalLine(GenJournalLine, GLAccount."No.", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Using Random Number Generator to Generate the Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandInt(200));

        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateNewExchangeRate(CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate2, CurrencyExchangeRate."Currency Code", WorkDate());
        UpdateExchangeRate(
          CurrencyExchangeRate2, CurrencyExchangeRate."Exchange Rate Amount", 2 * CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure SetupAccountOnCurrency(var Currency: Record Currency)
    begin
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Realized G/L Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
    end;

    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyGLEntryAdjustAmount(GLAccount: Record "G/L Account"; DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
    begin
        CurrencyExchangeRate.Get(CurrencyCode, WorkDate());
        GLAccount.CalcFields("Add.-Currency Balance at Date");
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(
          Amount,
          GLAccount."Add.-Currency Balance at Date" * (CurrencyExchangeRate."Relational Exch. Rate Amount" / 2) /
          CurrencyExchangeRate."Exchange Rate Amount");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, 0);  // Entry will be created with zero amount.
        GLEntry.TestField("System-Created Entry", true);
    end;

    local procedure VerifyGLEntryFound(DocumentNo: Code[20]; GLAccountNo: Code[20]): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        exit(GLEntry.FindFirst())
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure UpdateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate2.SetRange("Currency Code", CurrencyExchangeRate."Currency Code");
        CurrencyExchangeRate2.SetRange("Starting Date", StartingDate);
        if CurrencyExchangeRate2.FindFirst() then begin
            CurrencyExchangeRate2.Validate("Exchange Rate Amount", ExchangeRateAmount);
            CurrencyExchangeRate2.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
            CurrencyExchangeRate2.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
            CurrencyExchangeRate2.Validate("Relational Adjmt Exch Rate Amt", RelationalExchRateAmount);
            CurrencyExchangeRate2.Modify(true);
            CurrencyExchangeRate := CurrencyExchangeRate2;
        end;
    end;

    local procedure VerifyExchRateAdjmtRegisterSync(CurrencyCode: Code[10])
    var
        ExchRateAdjmtReg: Record "Exch. Rate Adjmt. Reg.";
        ExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry";
        TotalLedgerAmount: Decimal;
    begin
        ExchRateAdjmtReg.SetRange("Currency Code", CurrencyCode);
        if ExchRateAdjmtReg.FindSet() then
            repeat
                TotalLedgerAmount := 0;
                ExchRateAdjmtLedgEntry.SetRange("Register No.", ExchRateAdjmtReg."No.");
                if ExchRateAdjmtLedgEntry.FindSet() then
                    repeat
                        TotalLedgerAmount += ExchRateAdjmtLedgEntry."Adjustment Amount";
                    until ExchRateAdjmtLedgEntry.Next() = 0;

                Assert.AreEqual(
                    TotalLedgerAmount,
                    ExchRateAdjmtReg."Adjusted Amt. (LCY)",
                    StrSubstNo('Register %1 adjusted amount %2 does not match sum of ledger entries %3',
                        ExchRateAdjmtReg."No.", ExchRateAdjmtReg."Adjusted Amt. (LCY)", TotalLedgerAmount));
            until ExchRateAdjmtReg.Next() = 0;
    end;

}

