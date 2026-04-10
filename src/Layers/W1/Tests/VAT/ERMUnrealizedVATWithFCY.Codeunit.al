codeunit 134021 "ERM Unrealized VAT With FCY"
{
    // Appllies first doc. posted to second doc. posted and verifies realized VAT amounts in G/L and VAT entries.
    // Exchange rates are different on the dates of posting first and second document.
    // 
    // no.        1. doc. posted        2. doc. Posted           currency    amount applied  rate change
    // 1          Sales Invoice         Payment                  same        full            increase
    // 2          ''                    ''                       ''          1/3             ''
    // 3          Sales Credit Memo     Refund                   ''          full            ''
    // 4          ''                    ''                       ''          1/3             ''
    // 5          Sales Invoice         Payment                  different   full            ''
    // 6          ''                    ''                       ''          1/3             ''
    // 7          Sales Credit Memo     Refund                   ''          full            ''
    // 8          ''                    ''                       ''          1/3             ''
    // 9          Sales Invoice         Payment                  1.FCY 2.LCY full            ''
    // 10         ''                    ''                       ''          1/3             ''
    // 11         Sales Credit Memo     Refund                   ''          full            ''
    // 12         ''                    ''                       ''          1/3             ''
    // 13         Payment               Sales Invoice            same        full            ''
    // 14         ''                    ''                       ''          1/3             ''
    // 15         Sales Invoice         Payment                  same        remaining 2/3   ''
    // 16         Sales Credit Memo     Refund                   ''          '               ''
    // 17         Sales Invoice         Payment                  different   remaining 2/3   ''
    // 18         Sales Credit Memo     Refund                   ''          ''              ''
    // 19         Sales Invoice         Payment                  same        full            decrease
    // 20         ''                    ''                       ''          1/3             ''
    // 21         Sales Credit Memo     Refund                   ''          full            ''
    // 22         ''                    ''                       ''          1/3             ''
    // 
    // 23-44 same for Puchase side

    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Application] [Unrealized VAT] [FCY]
        IsInitialized := false;
    end;

    var
        PurchHeader2: Record "Purchase Header";
        SalesHeader2: Record "Sales Header";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        OptionTypeError: Label 'Option type is not supported by test helper function.';
        AmountError: Label 'Amount in the %1 No. %2 is incorrect.';
        PaidOption: Option Full,OneThird;
        RateChangeOption: Option Increase,Decrease;
        SecondCurrencyOption: Option Same,Different,LCY;
        DocumentOption: Option Sales,Purchase;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Unrealized VAT With FCY");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT With FCY");
        SetUnrealizedVATTypeToBlank();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Unrealized VAT With FCY");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFullPaymentSameFCY()
    begin
        SalesDocGenJournal(SalesHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentSameFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoFullRefundSameFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialRefundSameFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFullPaymentDiffFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentDiffFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoFullRefundDiffFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialRefundDiffFCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFullPaymentFCYLCY()
    begin
        SalesDocGenJournal(SalesHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentFCYLCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoFullRefundFCYLCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialRefundFCYLCY()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFullPaymentInvoiceSameFCY()
    begin
        SalesGenJournalDocSameFCY(SalesHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPartialPaymentInvoiceSameFCY()
    begin
        SalesGenJournalDocSameFCY(SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentSameFCYRemaining()
    begin
        SalesDocGenJournalRemaining(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialPaymentSameFCYRemaining()
    begin
        SalesDocGenJournalRemaining(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentDiffFCYRemaining()
    begin
        SalesDocGenJournalRemaining(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialPaymentDiffFCYRemaining()
    begin
        SalesDocGenJournalRemaining(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFullPaymentSameFCYDecrease()
    begin
        SalesDocGenJournal(SalesHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePartialPaymentSameFCYDecrease()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoFullRefundSameFCYDecrease()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoPartialRefundSameFCYDecrease()
    begin
        SalesDocGenJournal(
          SalesHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    local procedure SalesDocGenJournal(DocumentType: Enum "Sales Document Type"; Paid: Option; RateChange: Option; SecondCurrency: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        CurrencyCode2: Code[10];
        AmountToPost: Decimal;
        PaymentDate: Date;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CreateCurrencies(CurrencyCode, CurrencyCode2, ExchangeRateSign, SecondCurrency);
        SetupUnrealizedVAT(VATPostingSetup);
        FCYAmount := CreateSalesDoc(SalesHeader, DocumentType, CurrencyCode, VATPostingSetup, WorkDate());
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CalculateValuesForPayment(AmountToPost, PaymentDate, FCYAmount, CurrencyCode, CurrencyCode2, SecondCurrency);

        // Exercise
        CreateAndPostGenJournalLine(
          GenJournalLine, SalesHeader."Document Type", GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CurrencyCode2, AmountToPost / PartialPaymentFactor, PaymentDate, DocumentOption::Sales);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostCustomerEntry(
          PostedDocumentNo, SalesHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, WorkDate(), PartialPaymentFactor, SalesHeader."Document Type".AsInteger(),
            DocumentOption::Sales);
        VerifyEntriesSales(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    local procedure SalesGenJournalDocSameFCY(DocumentType: Enum "Sales Document Type"; Paid: Option; RateChange: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        DocDate: Date;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CurrencyCode := CreateCurrencyWithExchangeRates(ExchangeRateSign);
        SetupUnrealizedVAT(VATPostingSetup);
        DocDate := RandomFutureDate(WorkDate());
        FCYAmount := CreateSalesDoc(SalesHeader, DocumentType, CurrencyCode, VATPostingSetup, DocDate);
        CreateAndPostGenJournalLine(
          GenJournalLine, SalesHeader."Document Type", GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CurrencyCode, FCYAmount / PartialPaymentFactor, WorkDate(), DocumentOption::Sales);
        // Exercise
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostCustomerEntry(
          PostedDocumentNo, SalesHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, DocDate, PartialPaymentFactor, SalesHeader."Document Type".AsInteger(),
            DocumentOption::Sales);
        VerifyEntriesSales(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    local procedure SalesDocGenJournalRemaining(DocumentType: Enum "Sales Document Type"; Paid: Option; RateChange: Option; SecondCurrency: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        CurrencyCode2: Code[10];
        AmountToPost: Decimal;
        PaymentDate: Date;
        PartialPaymentAmount: Decimal;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CreateCurrencies(CurrencyCode, CurrencyCode2, ExchangeRateSign, SecondCurrency);
        SetupUnrealizedVAT(VATPostingSetup);
        FCYAmount := CreateSalesDoc(SalesHeader, DocumentType, CurrencyCode, VATPostingSetup, WorkDate());
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CalculateValuesForPayment(AmountToPost, PaymentDate, FCYAmount, CurrencyCode, CurrencyCode2, SecondCurrency);

        // Exercise
        PartialPaymentAmount := AmountToPost / PartialPaymentFactor;
        CreateAndPostGenJournalLine(
          GenJournalLine, SalesHeader."Document Type", GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CurrencyCode2, PartialPaymentAmount, PaymentDate, DocumentOption::Sales);
        ApplyAndPostCustomerEntry(
          PostedDocumentNo, SalesHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");
        CreateAndPostGenJournalLine(
          GenJournalLine, SalesHeader."Document Type", GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          CurrencyCode2, AmountToPost - PartialPaymentAmount, PaymentDate, DocumentOption::Sales);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostCustomerEntry(
          PostedDocumentNo, SalesHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedRemainingVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, WorkDate(), PartialPaymentFactor, SalesHeader."Document Type".AsInteger(),
            DocumentOption::Sales);
        VerifyEntriesSales(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceFullPaymentSameFCY()
    begin
        PurchDocGenJournal(PurchHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentSameFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoFullRefundSameFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialRefundSameFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceFullPaymentDiffFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentDiffFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoFullRefundDiffFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialRefundDiffFCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceFullPaymentFCYLCY()
    begin
        PurchDocGenJournal(PurchHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentFCYLCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoFullRefundFCYLCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialRefundFCYLCY()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::LCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFullPaymentInvoiceSameFCY()
    begin
        PurchGenJournalDocSameFCY(PurchHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Increase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPartialPaymentInvoiceSameFCY()
    begin
        PurchGenJournalDocSameFCY(PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentSameFCYRemaining()
    begin
        PurchDocGenJournalRemaining(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialPaymentSameFCYRemaining()
    begin
        PurchDocGenJournalRemaining(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentDiffFCYRemaining()
    begin
        PurchDocGenJournalRemaining(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialPaymentDiffFCYRemaining()
    begin
        PurchDocGenJournalRemaining(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Increase, SecondCurrencyOption::Different);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceFullPaymentSameFCYDecrease()
    begin
        PurchDocGenJournal(PurchHeader2."Document Type"::Invoice, PaidOption::Full, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoicePartialPaymentSameFCYDecrease()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::Invoice, PaidOption::OneThird, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoFullRefundSameFCYDecrease()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::Full, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoPartialRefundSameFCYDecrease()
    begin
        PurchDocGenJournal(
          PurchHeader2."Document Type"::"Credit Memo", PaidOption::OneThird, RateChangeOption::Decrease, SecondCurrencyOption::Same);
    end;

    local procedure PurchDocGenJournal(DocumentType: Enum "Purchase Document Type"; Paid: Option; RateChange: Option; SecondCurrency: Option)
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        CurrencyCode2: Code[10];
        AmountToPost: Decimal;
        PaymentDate: Date;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CreateCurrencies(CurrencyCode, CurrencyCode2, ExchangeRateSign, SecondCurrency);
        SetupUnrealizedVAT(VATPostingSetup);
        FCYAmount := CreatePurchDoc(PurchHeader, DocumentType, CurrencyCode, VATPostingSetup, WorkDate());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        CalculateValuesForPayment(AmountToPost, PaymentDate, FCYAmount, CurrencyCode, CurrencyCode2, SecondCurrency);

        // Exercise
        CreateAndPostGenJournalLine(
          GenJournalLine, PurchHeader."Document Type", GenJournalLine."Account Type"::Vendor, PurchHeader."Buy-from Vendor No.",
          CurrencyCode2, AmountToPost / PartialPaymentFactor, PaymentDate, DocumentOption::Purchase);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostVendorEntry(
          PostedDocumentNo, PurchHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, WorkDate(), PartialPaymentFactor, PurchHeader."Document Type".AsInteger(),
            DocumentOption::Purchase);
        VerifyEntriesPurch(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    local procedure PurchGenJournalDocSameFCY(DocumentType: Enum "Purchase Document Type"; Paid: Option; RateChange: Option)
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        DocDate: Date;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CurrencyCode := CreateCurrencyWithExchangeRates(ExchangeRateSign);
        SetupUnrealizedVAT(VATPostingSetup);
        DocDate := RandomFutureDate(WorkDate());
        FCYAmount := CreatePurchDoc(PurchHeader, DocumentType, CurrencyCode, VATPostingSetup, DocDate);
        CreateAndPostGenJournalLine(
          GenJournalLine, PurchHeader."Document Type", GenJournalLine."Account Type"::Vendor, PurchHeader."Buy-from Vendor No.",
          CurrencyCode, FCYAmount / PartialPaymentFactor, WorkDate(), DocumentOption::Purchase);

        // Exercise
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostVendorEntry(
          PostedDocumentNo, PurchHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, DocDate, PartialPaymentFactor, PurchHeader."Document Type".AsInteger(),
            DocumentOption::Purchase);
        VerifyEntriesPurch(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    local procedure PurchDocGenJournalRemaining(DocumentType: Enum "Purchase Document Type"; Paid: Option; RateChange: Option; SecondCurrency: Option)
    var
        PurchHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        PostedDocumentNo: Code[20];
        FCYAmount: Decimal;
        ExpectedAmount: Decimal;
        CurrencyCode2: Code[10];
        AmountToPost: Decimal;
        PaymentDate: Date;
        PartialPaymentAmount: Decimal;
        PartialPaymentFactor: Integer;
        ExchangeRateSign: Integer;
        TransactionNo: Integer;
    begin
        Initialize();

        // Setup
        ExchangeRateSign := ConvertRateChangeOption(RateChange);
        PartialPaymentFactor := ConvertPaidOption(Paid);

        CreateCurrencies(CurrencyCode, CurrencyCode2, ExchangeRateSign, SecondCurrency);
        SetupUnrealizedVAT(VATPostingSetup);
        FCYAmount := CreatePurchDoc(PurchHeader, DocumentType, CurrencyCode, VATPostingSetup, WorkDate());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        CalculateValuesForPayment(AmountToPost, PaymentDate, FCYAmount, CurrencyCode, CurrencyCode2, SecondCurrency);

        // Exercise
        PartialPaymentAmount := AmountToPost / PartialPaymentFactor;
        CreateAndPostGenJournalLine(
          GenJournalLine, PurchHeader."Document Type", GenJournalLine."Account Type"::Vendor, PurchHeader."Buy-from Vendor No.",
          CurrencyCode2, PartialPaymentAmount, PaymentDate, DocumentOption::Purchase);
        ApplyAndPostVendorEntry(
          PostedDocumentNo, PurchHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");
        CreateAndPostGenJournalLine(
          GenJournalLine, PurchHeader."Document Type", GenJournalLine."Account Type"::Vendor, PurchHeader."Buy-from Vendor No.",
          CurrencyCode2, AmountToPost - PartialPaymentAmount, PaymentDate, DocumentOption::Purchase);
        TransactionNo := GetNextTransactionNo();
        ApplyAndPostVendorEntry(
          PostedDocumentNo, PurchHeader."Document Type", GenJournalLine."Document No.", GenJournalLine."Document Type");

        // Verify
        ExpectedAmount :=
          CalculateRealizedRemainingVATEntryAmount(
            VATPostingSetup."VAT %", FCYAmount, CurrencyCode, WorkDate(), PartialPaymentFactor, PurchHeader."Document Type".AsInteger(),
            DocumentOption::Purchase);
        VerifyEntriesPurch(ExpectedAmount, VATPostingSetup, TransactionNo);

        // Tear Down
        TearDownUnrealizedVAT(VATPostingSetup);
    end;

    local procedure ApplyAndPostCustomerEntry(PostedDocumentNo: Code[20]; PostedDocumentType: Enum "Gen. Journal Document Type"; PostedDocumentNo2: Code[20]; PostedDocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, PostedDocumentType2, PostedDocumentNo2);
        CustLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, PostedDocumentType, PostedDocumentNo);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(PostedDocumentNo: Code[20]; PostedDocumentType: Enum "Gen. Journal Document Type"; PostedDocumentNo2: Code[20]; PostedDocumentType2: Enum "Gen. Journal Document Type")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, PostedDocumentType2, PostedDocumentNo2);
        VendorLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry.Amount);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry2, PostedDocumentType, PostedDocumentNo);
        VendorLedgerEntry2.CalcFields("Remaining Amount");
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CalculateFCYAmountExclVAT(FCYAmountInclVAT: Decimal; VATPercentage: Decimal): Decimal
    begin
        exit(Round(FCYAmountInclVAT * 100 / (100 + VATPercentage), LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CalculateRealizedRemainingVATEntryAmount(VATPercentage: Decimal; FCYAmount: Decimal; CurrencyCode: Code[10]; Date: Date; PartialPaymentFactor: Decimal; ApplyToDocumentType: Option; Document: Option) ExpectedAmount: Decimal
    var
        LCYAmountExclVAT: Decimal;
        FCYAmountExclVAT: Decimal;
        LCYAmount: Decimal;
        FirstPaymentAmount: Decimal;
    begin
        FCYAmountExclVAT := CalculateFCYAmountExclVAT(FCYAmount, VATPercentage);
        LCYAmountExclVAT := ConvertCurrencyWithRounding(FCYAmountExclVAT, CurrencyCode, '', Date);
        LCYAmount := ConvertCurrencyWithRounding(FCYAmount, CurrencyCode, '', Date);
        FirstPaymentAmount := Round((LCYAmount - LCYAmountExclVAT) / PartialPaymentFactor, LibraryERM.GetAmountRoundingPrecision());
        ExpectedAmount := LCYAmount - LCYAmountExclVAT - FirstPaymentAmount;
        ExpectedAmount := -1 * ModifySign(ApplyToDocumentType, ExpectedAmount, Document);
    end;

    local procedure CalculateRealizedVATEntryAmount(VATPercentage: Decimal; FCYAmount: Decimal; CurrencyCode: Code[10]; Date: Date; PartialPaymentFactor: Decimal; ApplyToDocumentType: Option; Document: Option) ExpectedAmount: Decimal
    var
        LCYAmountExclVAT: Decimal;
        FCYAmountExclVAT: Decimal;
        LCYAmount: Decimal;
    begin
        FCYAmountExclVAT := CalculateFCYAmountExclVAT(FCYAmount, VATPercentage);
        LCYAmountExclVAT := ConvertCurrencyWithRounding(FCYAmountExclVAT, CurrencyCode, '', Date);
        LCYAmount := ConvertCurrencyWithRounding(FCYAmount, CurrencyCode, '', Date);
        ExpectedAmount := Round((LCYAmount - LCYAmountExclVAT) / PartialPaymentFactor, LibraryERM.GetAmountRoundingPrecision());
        ExpectedAmount := -1 * ModifySign(ApplyToDocumentType, ExpectedAmount, Document);
    end;

    local procedure CalculateValuesForPayment(var AmountToPost: Decimal; var PaymentDate: Date; FCYAmount: Decimal; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; SecondCurrency: Option)
    begin
        PaymentDate := RandomFutureDate(WorkDate());
        AmountToPost := ConvertAmount(FCYAmount, CurrencyCode, CurrencyCode2, PaymentDate, SecondCurrency);
    end;

    local procedure ConvertAmount(FCYAmount: Decimal; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; Date: Date; SecondCurrency: Option): Decimal
    begin
        case SecondCurrency of
            SecondCurrencyOption::Same:
                exit(FCYAmount);
            SecondCurrencyOption::LCY, SecondCurrencyOption::Different:
                exit(ConvertCurrencyWithRounding(FCYAmount, CurrencyCode, CurrencyCode2, Date));
            else
                Error(OptionTypeError);
        end;
    end;

    local procedure ConvertCurrencyWithRounding(FCYAmount: Decimal; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; Date: Date) NewAmount: Decimal
    var
        Currency: Record Currency;
    begin
        NewAmount := LibraryERM.ConvertCurrency(FCYAmount, CurrencyCode, CurrencyCode2, Date);
        if CurrencyCode2 = '' then
            NewAmount := Round(NewAmount, LibraryERM.GetAmountRoundingPrecision())
        else begin
            Currency.Get(CurrencyCode2);
            NewAmount := Round(NewAmount, Currency."Amount Rounding Precision");
        end;
    end;

    local procedure ConvertPaidOption(Paid: Option): Integer
    begin
        case Paid of
            PaidOption::Full:
                exit(1);
            PaidOption::OneThird:
                exit(3);
            else
                Error(OptionTypeError);
        end;
    end;

    local procedure ConvertRateChangeOption(RateChange: Option): Integer
    begin
        case RateChange of
            RateChangeOption::Increase:
                exit(1);
            RateChangeOption::Decrease:
                exit(-1);
            else
                Error(OptionTypeError);
        end;
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; ApplyToDocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; PostingDate: Date; Document: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GetApplyingDocumentType(ApplyToDocumentType),
          AccountType, AccountNo, ModifySign(ApplyToDocumentType.AsInteger(), Amount, Document));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencies(var CurrencyCode: Code[10]; var CurrencyCode2: Code[10]; ExchangeRateSign: Integer; SecondCurrency: Option)
    begin
        CurrencyCode := CreateCurrencyWithExchangeRates(ExchangeRateSign);
        CurrencyCode2 := CreateSecondCurrency(CurrencyCode, ExchangeRateSign, SecondCurrency);
    end;

    local procedure CreateCurrencyWithExchangeRates(ExchangeRateSign: Integer): Code[10]
    var
        Currency: Record Currency;
        Amount: Decimal;
        RelationalAmount: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        SetInvoiceRoundingPrecision(Currency);

        Amount := 100;
        RelationalAmount := 100 + LibraryRandom.RandDec(100, 2); // make sure that the RelationalAmount will be a positive number after later changes in exchange rate

        CreateCurrencyExchangeRate(Currency.Code, WorkDate(), Amount, RelationalAmount);
        CreateCurrencyExchangeRate(
          Currency.Code, CalcDate('<1D>', WorkDate()), Amount, RelationalAmount + ExchangeRateSign * LibraryRandom.RandDec(10, 2)); // make sure that exchange rate is different on any future date

        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(VATBusPostGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(1000, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date) FCYAmount: Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchHeaderWithCurrency(
          PurchHeader, DocumentType, CurrencyCode, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), PostingDate);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        FCYAmount := GetFCYAmountPurch(PurchHeader);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date) FCYAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithCurrency(
          SalesHeader, DocumentType, CurrencyCode, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), PostingDate);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        FCYAmount := GetFCYAmountSales(SalesHeader);
    end;

    local procedure CreatePurchHeaderWithCurrency(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; CustomerNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSecondCurrency(CurrencyCode: Code[10]; ExchangeRateSign: Integer; SecondCurrency: Option): Code[10]
    begin
        case SecondCurrency of
            SecondCurrencyOption::Same:
                exit(CurrencyCode);
            SecondCurrencyOption::LCY:
                exit('');
            SecondCurrencyOption::Different:
                exit(CreateCurrencyWithExchangeRates(ExchangeRateSign));
            else
                Error(OptionTypeError);
        end;
    end;

    local procedure GetApplyingDocumentType(DocumentType: Enum "Gen. Journal Document Type") ApplyingDocumentType: Enum "Gen. Journal Document Type"
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case DocumentType of
            SalesHeader2."Document Type"::Invoice, SalesHeader2."Document Type"::Order:
                ApplyingDocumentType := GenJournalLine."Document Type"::Payment;
            SalesHeader2."Document Type"::"Credit Memo":
                ApplyingDocumentType := GenJournalLine."Document Type"::Refund;
            else
                Error(OptionTypeError);
        end;
    end;

    local procedure GetFCYAmountPurch(PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        GetPurchLines(PurchLine, PurchHeader);
        exit(PurchLine."Amount Including VAT");
    end;

    local procedure GetFCYAmountSales(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        GetSalesLines(SalesLine, SalesHeader);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No." + 1);
    end;

    local procedure GetPurchLines(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetFilter("Document No.", PurchHeader."No.");
        PurchLine.FindSet();
    end;

    local procedure GetSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetFilter("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure ModifySign(ApplyToDocumentType: Option; Amount: Decimal; Document: Option) AmountWithSign: Decimal
    begin
        if Document = DocumentOption::Sales then
            case ApplyToDocumentType of
                SalesHeader2."Document Type"::Invoice.AsInteger(), SalesHeader2."Document Type"::Order.AsInteger():
                    AmountWithSign := -Amount;
                SalesHeader2."Document Type"::"Credit Memo".AsInteger():
                    AmountWithSign := Amount;
                else
                    Error(OptionTypeError);
            end
        else
            case ApplyToDocumentType of
                PurchHeader2."Document Type"::Invoice.AsInteger(), PurchHeader2."Document Type"::Order.AsInteger():
                    AmountWithSign := Amount;
                PurchHeader2."Document Type"::"Credit Memo".AsInteger():
                    AmountWithSign := -Amount;
                else
                    Error(OptionTypeError);
            end
    end;

    local procedure RandomFutureDate(Date: Date): Date
    begin
        exit(CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), Date));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure SetInvoiceRoundingPrecision(var Currency: Record Currency)
    begin
        Currency.Get(Currency.Code);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Modify(true);
    end;

    local procedure SetUnrealizedVATTypeToBlank()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Need to set Unrealized VAT Type to blank to match demo data according to W1. Require for country enabling.
        VATPostingSetup.SetFilter("Unrealized VAT Type", '<>%1', VATPostingSetup."Unrealized VAT Type"::" ");
        if VATPostingSetup.FindSet() then
            repeat
                VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
                VATPostingSetup.Modify(true);
            until VATPostingSetup.Next() = 0;
    end;

    local procedure SetupUnrealizedVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.SetUnrealizedVAT(true);
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure TearDownUnrealizedVAT(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Modify(true);
        LibraryERM.SetUnrealizedVAT(false);
    end;

    local procedure VerifyEntriesPurch(ExpectedAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; TransactionNo: Integer)
    begin
        VerifyGLEntry(VATPostingSetup."Purch. VAT Unreal. Account", TransactionNo, ExpectedAmount);
        VerifyGLEntry(VATPostingSetup."Purchase VAT Account", TransactionNo, -ExpectedAmount);
        VerifyVATEntry(TransactionNo, -ExpectedAmount);
    end;

    local procedure VerifyEntriesSales(ExpectedAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"; TransactionNo: Integer)
    begin
        VerifyGLEntry(VATPostingSetup."Sales VAT Unreal. Account", TransactionNo, ExpectedAmount);
        VerifyGLEntry(VATPostingSetup."Sales VAT Account", TransactionNo, -ExpectedAmount);
        VerifyVATEntry(TransactionNo, -ExpectedAmount);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; TransactionNo: Integer; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindLast();

        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, StrSubstNo(AmountError, GLEntry.TableCaption(), GLEntry."Entry No."));
    end;

    local procedure VerifyVATEntry(TransactionNo: Integer; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.FindLast();

        Assert.AreEqual(ExpectedAmount, VATEntry.Amount, StrSubstNo(AmountError, VATEntry.TableCaption(), VATEntry."Entry No."));
    end;
}

