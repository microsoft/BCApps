codeunit 134916 "ERM Discount On Credit Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [Sales]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';
        DocumentNo: Code[20];

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Discount On Credit Memo");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Discount On Credit Memo");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Discount On Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnCreditMemo()
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        AdjustForPaymentDiscount: Boolean;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // Test G/L Entry after applying Payment on Invoice with Adjust for Payment Discount True on Payment Terms.

        // 1. Setup: Update Adjust for Payment Discount as True on General Ledger Setup and VAT Posting Setup, Create Payment Terms with
        // Discount, Create and Post Sales Invoice, Update General Posting Setup for Sales Discount Account, create and Post Sales Credit
        // Memo with Applies to doc. no.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        AdjustForPaymentDiscount := UpdateAdjustForPaymentDiscount(VATPostingSetup, true);
        CreateAndPostSalesInvoice(SalesLine, VATPostingSetup);
        GetPaymentTermDiscount(PaymentTerms, SalesLine."Sell-to Customer No.");
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateGeneralPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", GLAccount."No.");

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesLine."Document No.");
        SalesInvoiceHeader.FindFirst();
        DocumentNo := SalesInvoiceHeader."No.";  // Assign Global Variable for Page Handler.
        CreateAndPostCreditMemo(SalesLine2, SalesLine, SalesInvoiceHeader."No.");
        Amount :=
          SalesLine."Unit Price" * (SalesLine.Quantity - SalesLine2.Quantity) * (1 + VATPostingSetup."VAT %" / 100) *
          PaymentTerms."Discount %" / 100;
        VATAmount := Amount * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %");

        // 2. Exercise: Create and Post General Journal Line for Payment after applying it on Invoice.
        // 0 is required for test case for applying entry.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, SalesLine."Sell-to Customer No.", '', 0);
        GenJnlApply.Run(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify G/L Entry for different values.
        VerifyGLEntry(GenJournalLine."Document No.", GLAccount."No.", Round(Amount - VATAmount));
        VerifyGLEntry(GenJournalLine."Document No.", VATPostingSetup."Sales VAT Account", Round(VATAmount));
        VerifyGLEntry(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", -GenJournalLine.Amount);

        // 4. Teardown: Rollback Adjust for Payment Discount to default value on VAT Posting Setup and General Ledger Setup.
        UpdateAdjustForPaymentDiscount(VATPostingSetup, AdjustForPaymentDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvToCrMemoEqualAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Invoice on Credit Memo Equal to Invoice Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Invoice applied Fully to Credit Memo and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", '', '', 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvToCrMemoLessAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Invoice on Credit Memo Less Than Invoice Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount / 2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo",
          CurrencyCode, CurrencyCode, Amount, -Amount / 2, 1); // Value used for Sign Factor.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvToCrMemoGreaterAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Invoice on Credit Memo Greater Than Invoice Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Invoice applied Fully to Credit Memo and 1 for Sign Factor..
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo",
          CurrencyCode, CurrencyCode, 0, -Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvToCrMemoMultiCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Invoice in foreign currency on
        // Credit Memo in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Invoice applied Fully to Credit Memo and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo",
          CreateCurrency(), CreateCurrency(), 0, -Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCrMemoEqualAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Credit Memo Equal to Refund Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Credit Memo and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", '', '', 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCrMemoLessAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Credit Memo Less Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Credit Memo and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount / 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo",
          CurrencyCode, CurrencyCode, 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCrMemoGreaterAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Credit Memo Greater Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using -1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo",
          CurrencyCode, CurrencyCode, Amount, Amount, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToCrMemoMultiCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund in foreign currency on
        // Credit Memo in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using -1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo",
          CreateCurrency(), CreateCurrency(), Amount, Amount, -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToInvEqualAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Invoice Equal to Credit Memo Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Credit Memo applied Fully to Invoice and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice, '', '', 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToInvLessAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Invoice Less Than Credit
        // Memo Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount / 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          CurrencyCode, CurrencyCode, -Amount, Amount / 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToInvGreaterAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Invoice Greater Than Credit
        // Memo Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Credit Memo applied Fully to Invoice and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount * 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          CurrencyCode, CurrencyCode, 0, Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToInvMultiCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on foreign currency on
        // Invoice on  in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);  // Random value used is not important for test.

        // Using Zero where Credit Memo applied Fully to Invoice and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount * 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          CreateCurrency(), CreateCurrency(), 0, Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToPmtEqualAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Payment Equal to Refund Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Payment and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment, '', '', 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToPmtLessAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Payment Less Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Payment and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount / 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment, CurrencyCode, CurrencyCode, 0,
          0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToPmtGreaterAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund on Payment Greater Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Payment and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment,
          CurrencyCode, CurrencyCode, 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToPmtMultiCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund in foreign currency on
        // Payment in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Payment and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount * 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment,
          CreateCurrency(), CreateCurrency(), 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyRefundToPmtLessAmtMulCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Refund in foreign currency on
        // Payment Less Than Refund Amount and in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Refund is applied to Payment and 1 for Sign Factor.
        ApplySalesDocuments(
          Amount, -Amount / 2, GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::Payment,
          CreateCurrency(), CreateCurrency(), 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToRefundEqualAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Refund Equal to Refund Amount.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Credit Memo is applied to Refund and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, '', '', 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToRefundLessAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Refund Less Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Credit Memo is applied to Refund and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount / 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          CurrencyCode, CurrencyCode, 0, -Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToRefundGreaterAmt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo on Refund Greater Than Refund Amount.
        Initialize();
        CurrencyCode := CreateCurrency();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Credit Memo is applied to Refund and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount * 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          CurrencyCode, CurrencyCode, 0, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToRefundMultiCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying a Credit Memo in foreign currency on
        // Refund in another foreign currency.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Using Zero where Credit Memo is applied to Refund and 1 for Sign Factor.
        ApplySalesDocuments(
          -Amount, Amount * 2, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          CreateCurrency(), CreateCurrency(), 0, 0, 1);
    end;

    [Normal]
    local procedure ApplySalesDocuments(Amount: Decimal; AmounttoApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; PaymentAmont: Decimal; PaymentAmont2: Decimal; SignFactor: Integer)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Setup:  Update Sales And Receivable Setup.Create Payment Terms with Discount,Create Customer and attach Payment Term to it.
        SalesReceivablesSetup.Get();
        FindAndUpdateSetup(SalesReceivablesSetup, VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");

        // Exercise: Create and Post General Journal Line.
        CreateGeneralJournalLine(GenJournalLine, DocumentType, CustomerNo, CurrencyCode, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(GenJournalLine, DocumentType2, CustomerNo, CurrencyCode2, AmounttoApply);

        UpdateGenJournalLine(GenJournalLine, CustomerNo, DocumentType, WorkDate());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify : Verify Customer Ledger Entry for Remaining Pmt. Disc. Possible.
        VerifyCustomerLedgerEntry(CustomerNo, SignFactor * CalculateRemainingPmtDiscount(CustomerNo, PaymentAmont, PaymentAmont2));

        // Tear Down: Roll back the Changes done in Sales And Receivable Setup.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Appln. between Currencies", SalesReceivablesSetup."Credit Warnings");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCrMemoToRefundAftDiscDate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        Amount: Decimal;
        PaymentDiscountDate: Date;
    begin
        // Test Customer Ledger Entry for Remaining Pmt. Disc. Possible after applying Credit Memo on Refund not within the Discount date
        // Equal to Refund Amount.

        // Setup:  Update Sales And Receivable Setup.Create Payment Terms with Discount,Create Customer and attach Payment Term to it.
        Initialize();
        SalesReceivablesSetup.Get();
        FindAndUpdateSetup(SalesReceivablesSetup, VATPostingSetup);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        GetPaymentTermDiscount(PaymentTerms, CustomerNo);
        PaymentDiscountDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate());
        Amount := LibraryRandom.RandDec(100, 2); // Random value used is not important for test.

        // Exercise: Create Update and Post General Journal Line.
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", CustomerNo, CreateCurrency(), -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Refund, CustomerNo, GenJournalLine."Currency Code", Amount);
        UpdateGenJournalLine(
          GenJournalLine, CustomerNo, GenJournalLine."Document Type"::"Credit Memo",
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', PaymentDiscountDate));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify : Verify Customer Ledger Entry for Remaining Pmt. Disc. Possible.
        VerifyCustomerLedgerEntry(CustomerNo, 0);

        // Tear Down: Roll back the Changes done in Sales And Receivable Setup.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Appln. between Currencies", SalesReceivablesSetup."Credit Warnings");
    end;

    local procedure CalculateRemainingPmtDiscount(CustomerNo: Code[20]; Amount: Decimal; Amount2: Decimal) RemainingPmtDiscPossible: Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        GetPaymentTermDiscount(PaymentTerms, CustomerNo);
        RemainingPmtDiscPossible := Round(Amount * PaymentTerms."Discount %" / 100) + Round(Amount2 * PaymentTerms."Discount %" / 100);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndPostCreditMemo(var SalesLine2: Record "Sales Line"; SalesLine: Record "Sales Line"; AppliesToDocNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");
        UpdateAppliesToDocNoSales(SalesHeader, AppliesToDocNo);
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, SalesLine."No.", SalesLine.Quantity * LibraryUtility.GenerateRandomFraction());
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice,
          CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        CreatePaymentTermsWithDiscount(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 100 + LibraryRandom.RandDec(1000, 2));  // Use 100 to insure higher Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentTermsWithDiscount(var PaymentTerms: Record "Payment Terms")
    begin
        // Input any random Due Date, Discount Date Calculation and Discount %.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
    end;

    [Normal]
    local procedure GetPaymentTermDiscount(var PaymentTerms: Record "Payment Terms"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        PaymentTerms.Get(Customer."Payment Terms Code");
    end;

    local procedure UpdateAdjustForPaymentDiscount(var VATPostingSetup: Record "VAT Posting Setup"; AdjustForPaymentDiscount: Boolean): Boolean
    var
        OldAdjustForPaymentDiscount: Boolean;
    begin
        OldAdjustForPaymentDiscount := VATPostingSetup."Adjust for Payment Discount";
        VATPostingSetup."Adjust for Payment Discount" := AdjustForPaymentDiscount;  // Using assignment to avoid error in ES.
        VATPostingSetup.Modify(true);
        exit(OldAdjustForPaymentDiscount);
    end;

    local procedure UpdateAppliesToDocNoSales(var SalesHeader: Record "Sales Header"; AppliesToDocNo: Code[20])
    begin
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; AppliestoDocType: Enum "Gen. Journal Document Type"; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        GenJournalLine.Validate("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesPmtDiscDebitAcc: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        LibraryERM.FindGLAccount(GLAccount);
        // Using assignment to avoid error in ES.
        GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := SalesPmtDiscDebitAcc;
        GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." := GLAccount."No.";
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(ApplnbetweenCurrencies: Option; CreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Appln. between Currencies", ApplnbetweenCurrencies);
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    [Normal]
    local procedure FindAndUpdateSetup(var SalesReceivablesSetup: Record "Sales & Receivables Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    begin
        UpdateSalesReceivablesSetup(
          SalesReceivablesSetup."Appln. between Currencies"::All, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; RemainingPmtDiscPossible: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ActualRemainingPmtDiscPossible: Decimal;
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            ActualRemainingPmtDiscPossible += CustLedgerEntry."Remaining Pmt. Disc. Possible";
        until CustLedgerEntry.Next() = 0;

        Assert.AreNearlyEqual(
          RemainingPmtDiscPossible, ActualRemainingPmtDiscPossible, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, CustLedgerEntry.FieldCaption("Remaining Pmt. Disc. Possible"),
            RemainingPmtDiscPossible, CustLedgerEntry.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        ApplyCustomerEntries.SetRecord(CustLedgerEntry);
        ApplyCustomerEntries.SetCustApplId(false);
        Response := ACTION::LookupOK;
    end;
}

