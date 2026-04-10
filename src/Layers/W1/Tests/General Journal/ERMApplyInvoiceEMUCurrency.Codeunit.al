codeunit 134082 "ERM Apply Invoice EMU Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [General Ledger] [EMU Currency]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in \\%3 %4=%5.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceWithEMUCurrency()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        ApplnbetweenCurrencies: Option "None",EMU,All;
        Amount: Decimal;
    begin
        // Check that G/L Entry has correct amount after apply EMU currency.

        // Setup: Modify Sales & Receivables Setup for EMU Currency, Create Currency, Modify Exchange Rate, Create Sales Invoice and Post
        // it.
        Initialize();
        ModifySalesAndReceivablesSetup(ApplnbetweenCurrencies, SalesReceivablesSetup."Appln. between Currencies"::EMU);

        CurrencyCode := CreateCurrency();
        ModifyExchangeRate(CurrencyCode);
        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader, CurrencyCode);
        FindSalesInvoiceHeaderAmt(SalesInvoiceHeader, PostedDocumentNo);
        Amount := LibraryERM.ConvertCurrency(SalesInvoiceHeader."Amount Including VAT", SalesHeader."Currency Code", '', WorkDate());
        Amount := LibraryERM.ConvertCurrency(Amount, SalesHeader."Currency Code", '', WorkDate());

        // Exercise: Create General Lines and Apply Posted Invoice and Post with New Currency with Modification of Exchange Rate.
        CreateGeneralJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocumentNo, -SalesInvoiceHeader."Amount Including VAT");
        ModifyExchangeRate(GenJournalLine."Currency Code");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify G/L Entry for EMU Currency amount.
        VerifyGLEntry(GenJournalLine."Document No.", CurrencyCode, Amount);

        // Cleanup: Set Default value in Sales & Receivables Setup.
        ModifySalesAndReceivablesSetup(ApplnbetweenCurrencies, ApplnbetweenCurrencies);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceEMUCurrAdjExchRate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
        ApplnbetweenCurrencies: Option "None",EMU,All;
        Amount: Decimal;
    begin
        // Check that G/L Entry has correct amount after apply EMU currency with Adjust Exchange Rate Batch Job.

        // Setup: Modify Sales & Receivables Setup for EMU Currency, Create Currency, Modify Exchange Rate, Create Sales Invoice and Post
        // it and Run Adjust Exchange Rate Batch Job.
        Initialize();
        ModifySalesAndReceivablesSetup(ApplnbetweenCurrencies, SalesReceivablesSetup."Appln. between Currencies"::EMU);

        PostedDocumentNo := CreateAndPostSalesInvoice(SalesHeader, CreateCurrency());
        ModifyExchangeRate(SalesHeader."Currency Code");
        LibraryERM.RunExchRateAdjustment(SalesHeader."Currency Code", 0D, WorkDate(), 'Test', WorkDate(), PostedDocumentNo, false);
        FindSalesInvoiceHeaderAmt(SalesInvoiceHeader, PostedDocumentNo);
        Amount := LibraryERM.ConvertCurrency(SalesInvoiceHeader."Amount Including VAT", SalesHeader."Currency Code", '', WorkDate());

        // Exercise: Create General Lines, Apply Posted Invoice and Post with New Currency.
        CreateGeneralJournalLine(
          GenJournalLine, SalesHeader."Sell-to Customer No.", PostedDocumentNo, -SalesInvoiceHeader."Amount Including VAT");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify G/L Entry for EMU Currency amount.
        VerifyGLEntry(SalesInvoiceHeader."No.", SalesHeader."Currency Code", Amount);

        // Cleanup: Set Default value in Sales & Receivables Setup.
        ModifySalesAndReceivablesSetup(ApplnbetweenCurrencies, ApplnbetweenCurrencies);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]) PostedDocumentNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(CurrencyCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(50));
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("EMU Currency", true);
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AppliedToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliedToDocNo);
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Modify(true);
    end;

    local procedure FindSalesInvoiceHeaderAmt(var SalesInvoiceHeader: Record "Sales Invoice Header"; No: Code[20])
    begin
        SalesInvoiceHeader.SetRange("No.", No);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
    end;

    local procedure ModifySalesAndReceivablesSetup(var OldApplnbetweenCurrencies: Option; ApplnbetweenCurrencies: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldApplnbetweenCurrencies := SalesReceivablesSetup."Appln. between Currencies";
        SalesReceivablesSetup.Validate("Appln. between Currencies", ApplnbetweenCurrencies);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Currency Code", CreateCurrency());
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"G/L Account");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindFirst();
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(),
            GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;
}

