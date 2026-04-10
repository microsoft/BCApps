codeunit 134077 "ERM Currency Factor"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Currency Factor] [General Journal]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        AmountLCYError: Label 'Amount LCY must be %1.';
        CurrencyFactorError: Label 'Currency Factor must be %1.';
        OutOfBalanceError: Label '%1 %2 is out of balance by %3. Please check that %4, %5, %6 and %7 are correct for each line.';
        UnknownError: Label 'Unknown Error.';

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithAmount()
    begin
        // Covers documents TC_ID=8891,8871,8892,8872,8893,8873,8894 and 8874.

        // Check that Currency Factor and Amount LCY field are posted correct on General Journal Line after Post Sales Invoice.
        // Random Amount required for General Journal Line.
        CreateDocAndVerifyAmountLCY(LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalWithApplyEntry()
    begin
        // Covers documents TC_ID=8891,8871,8892,8872,8893,8873,8895 and 8875.

        // Check that Currency Factor and Amount LCY field are posted correct on General Journal Line after Apply Customer Ledger Entry
        // and Post Sales Invoice.
        CreateDocAndVerifyAmountLCY(0);
    end;

    local procedure CreateDocAndVerifyAmountLCY(Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        // Setup: Create Currency, Customer and Create Sales Invoice and Post.
        Initialize();
        CreateSalesDocument(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Create General Journal for Random Amount.
        CreateGeneralJournals(TempGenJournalLine, SalesHeader."Sell-to Customer No.", -Amount);

        if Amount = 0 then
            ApplyCustomerLedgerEntry(TempGenJournalLine, SalesHeader);

        // Verify: Verify for Amount LCY and Currency Factor field on General Journal.
        VerifyCurrencyFactorAmountLCY(TempGenJournalLine, SalesHeader."Currency Factor");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutOfBalanceErrorWithCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        AmountLCY: Decimal;
    begin
        // Verify Out Of Balance Error with Customer.

        // Setup: Create Currency, Customer, General Journal Batch and General Journal Lines with Random Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        CustomerNo := CreateCustomer(CurrencyCode);
        AmountLCY :=
          CreateGeneralJournalLines(
            GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CurrencyCode, LibraryRandom.RandInt(1000));

        // Exercise: Post General Journal Lines.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: System Generates Out Of Balance Error.
        Assert.AreEqual(
          StrSubstNo(OutOfBalanceError, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.",
            AmountLCY + GenJournalLine."Amount (LCY)", GenJournalLine.FieldCaption("Posting Date"),
            GenJournalLine.FieldCaption("Document Type"), GenJournalLine.FieldCaption("Document No."),
            GenJournalLine.FieldCaption(Amount)), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutOfBalanceErrorWithVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        AmountLCY: Decimal;
    begin
        // Verify Out Of Balance Error with Vendor.

        // Setup: Create Currency, Vendor, General Journal Batch and General Journal Lines with Random Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        VendorNo := CreateVendor(CurrencyCode);
        AmountLCY :=
          CreateGeneralJournalLines(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, CurrencyCode, -LibraryRandom.RandInt(1000));

        // Exercise: Post General Journal Lines.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: System Generates Out Of Balance Error.
        Assert.AreEqual(
          StrSubstNo(OutOfBalanceError, GenJournalLine.FieldCaption("Document No."), GenJournalLine."Document No.",
            AmountLCY + GenJournalLine."Amount (LCY)", GenJournalLine.FieldCaption("Posting Date"),
            GenJournalLine.FieldCaption("Document Type"), GenJournalLine.FieldCaption("Document No."),
            GenJournalLine.FieldCaption(Amount)), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringGeneralJournalCurrencyFactor()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        // Verify Currency Factor and Amount(LCY) on Recurring General Journal.

        // Setup: Find Recurring Template,Create a Recurring Batch and create a Payment in Recurring General Journal taking Random value for Amount.
        Initialize();
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, CreateCustomer(CreateCurrency()), LibraryRandom.RandDec(100, 2));

        // Exercise: Calculate the Currency Factor for validation.
        GetOrCreateCurrencyExchangeRate(GenJournalLine."Currency Code", CurrencyExchangeRate);
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";

        // Verify: Validate 'Currency factor' and 'Amount(LCY)' on Recurring General Journal.
        VerifyCurrencyFactorAmountLCY(GenJournalLine, CurrencyFactor);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntryPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntryCurrencyFactor()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
        CurrencyFactor: Decimal;
        CurrencyCode: Code[10];
    begin
        // Verify Currency Factor and Amount(LCY) on General Journal after applying Customer entries.

        // Setup: Create a Currency,post an Invoice for new Customer and create a payment in General Journal taking Random values for Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        GetOrCreateCurrencyExchangeRate(CurrencyCode, CurrencyExchangeRate);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify();
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CreateCustomer(CurrencyCode), LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, GenJournalLine."Account No.",
          LibraryRandom.RandDec(100, 2));

        // Exercise: Open Apply Customer Entries page from General Journal and Set Applies to ID through page handler.
        GeneralJournal.OpenEdit();
        GeneralJournal.CurrentJnlBatchName.Value(GenJournalLine."Journal Batch Name");
        GeneralJournal.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        GeneralJournal."Apply Entries".Invoke();

        // Verify: Validate 'Currency factor' and 'Amount(LCY)' on General Journal.
        VerifyCurrencyFactorAmountLCY(GenJournalLine, CurrencyFactor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchaseDocumentWithoutFCYExchangeRate()
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        LibraryERM.CreateCurrency(Currency);

        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Insert(true);
        Commit();

        asserterror LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);

        Assert.ExpectedTestFieldError(PurchaseHeader.FieldCaption("Currency Factor"), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesDocumentWithoutFCYExchangeRate()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        LibraryERM.CreateCurrency(Currency);

        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);
        Commit();

        asserterror LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);

        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Currency Factor"), '');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Currency Factor");
        LibraryApplicationArea.EnableFoundationSetup();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Currency Factor");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Currency Factor");
    end;

    local procedure ApplyCustomerLedgerEntry(var TempGenJournalLine: Record "Gen. Journal Line" temporary; SalesHeader: Record "Sales Header")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyCustomerEntries: Page "Apply Customer Entries";
    begin
        CustLedgerEntry.SetRange("Document Type", SalesHeader."Document Type".AsInteger());
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgerEntry.FindFirst();
        ApplyCustomerEntries.SetCustLedgEntry(CustLedgerEntry);
        ApplyCustomerEntries.SetCustApplId(false);

        CustLedgerEntry.SetFilter("Applies-to ID", '<>''''');
        CustLedgerEntry.FindFirst();
        TempGenJournalLine.Validate(Amount, -CustLedgerEntry."Amount to Apply");
        TempGenJournalLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(CreateCurrency()));

        // Create multiple Sales Lines. Make sure that No. of Lines always greater than 1 to better Testability.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            // Required Random Value for Quantity and "Unit Price" field value is not important.
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);

        // Use Journal Batch Name as Document No. value is not important.
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal) AmountLCY: Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, AccountType, AccountNo, CurrencyCode, Amount);

        AmountLCY := GenJournalLine."Amount (LCY)";

        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), CurrencyCode,
          LibraryUtility.GenerateRandomFraction() - GenJournalLine.Amount);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournals(var TempGenJournalLine: Record "Gen. Journal Line" temporary; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          TempGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TempGenJournalLine."Document Type"::Payment,
          TempGenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure VerifyCurrencyFactorAmountLCY(GenJournalLine: Record "Gen. Journal Line"; CurrencyFactor: Decimal)
    var
        Currency: Record Currency;
        AmountLCY: Decimal;
    begin
        Assert.AreEqual(CurrencyFactor, GenJournalLine."Currency Factor", StrSubstNo(CurrencyFactorError, CurrencyFactor));
        Currency.Get(GenJournalLine."Currency Code");
        Currency.InitRoundingPrecision();
        AmountLCY := GenJournalLine.Amount / GenJournalLine."Currency Factor";
        Assert.AreNearlyEqual(
          AmountLCY, GenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision", StrSubstNo(AmountLCYError, AmountLCY));
    end;

    local procedure GetOrCreateCurrencyExchangeRate(CurrencyCode: Code[10]; var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        if CurrencyExchangeRate.Get(CurrencyCode, LibraryERM.FindEarliestDateForExhRate()) then
            exit;
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := LibraryERM.FindEarliestDateForExhRate();
        CurrencyExchangeRate.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcAmountSrcCurrRoundingPrecisionInitialization()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[10];
        GLAccountNo: Code[20];
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 610864] Verify that CalcAmountSrcCurr properly initializes LocalAmountRoundingPrecision to avoid "value of ROUND parameter 2 is outside of the permitted range" error

        // [GIVEN] A currency with proper rounding precision
        Initialize();
        CurrencyCode := CreateCurrency();
        GLAccountNo := CreateGLAccountWithVATSetup(VATPostingSetup, GeneralPostingSetup);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] A General Journal Line with Source Currency Code and VAT to trigger CalcAmountSrcCurr
        CreateGeneralJournalBatch(GenJournalBatch);

        // Set up the journal batch to use a balancing account
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Modify(true);

        // Create journal line with VAT and source currency - the balancing account will handle the balance automatically
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::"G/L Account",
            GLAccountNo,
            Amount);
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Validate("Source Currency Code", CurrencyCode);
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GenJournalLine.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);

        // [WHEN] Posting the journal line which will trigger CalcAmountSrcCurr during VAT posting
        // [THEN] No error should occur during CalcAmountSrcCurr rounding operations (LocalAmountRoundingPrecision should be initialized from GetSourceCurrency)
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccountWithVATSetup(var VATPostingSetup: Record "VAT Posting Setup"; var GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", false);
        GenJournalTemplate.Modify(true);

        // Create General Posting Groups
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        // Create VAT Posting Groups
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 25));

        // Set up required VAT accounts
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        exit(GLAccount."No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntryPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
    end;
}

