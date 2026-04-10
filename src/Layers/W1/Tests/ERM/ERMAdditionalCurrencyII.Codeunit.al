codeunit 134091 "ERM Additional Currency II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ACY]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongAmountErr: Label '%1 must be %2 in %3.';
        WrongBankAccLedgEntryAmtErr: Label 'Wrong %1 in Bank Account Ledger Entry.';

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalFCY()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Additional Currency Amount in GL Entry and Amount on Cust. Ledger Entry after Posting General Journal Line
        // with Customer and GL Account.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Customer.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
        Customer.Get(CreateCustomer(CurrencyCode));

        // Exercise: Create General Invoices with GL Account and Customer.
        DocumentNo :=
          CreateAndPostGenLines(
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", AmountLCY, -Amount);

        // Verify: Verify Additional Currency on GL Entry and Amount on Customer Ledger Entry.

        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", AmountLCY);
        VerifyCustomerLedgerEntry(DocumentNo, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentGeneralJournalFCY()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Additional Currency Amount in GL Entry after Posting General Journal Line with Customer and GL Account
        // with Payment Posted Invoices.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Customer.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
        Customer.Get(CreateCustomer(CurrencyCode));
        CreateAndPostGenLines(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", AmountLCY, -Amount);

        // Exercise: Create General Invoices with GL Account and Customer.
        DocumentNo :=
          CreateAndPostGenLines(
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", -AmountLCY, Amount);

        // Verify: Verify Additional Currency in GL Entry and Remaining Amount LCY on Customer Ledger Entry.
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", -AmountLCY);
        VerifyZeroCustRemainingAmountLCY(CustLedgerEntry."Document Type"::Payment, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        CurrencyCode: Code[10];
        AmountLCY: Decimal;
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting Sales Invoice.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Customer.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        AmountLCY := Round(LibraryERM.ConvertCurrency(LibraryRandom.RandDec(100, 2), '', CurrencyCode, WorkDate()));

        // Exercise.
        LineAmount := CreateAndPostSalesInvoice(SalesHeader, AmountLCY, CurrencyCode);
        AmountLCY := Round(LibraryERM.ConvertCurrency(LineAmount, CurrencyCode, '', WorkDate()));

        // Verify: Verify GL Entry for Additional Currency Amount after Posting Sales Invoice.
        GeneralLedgerSetup.Get();
        DocumentNo := FindSalesInvoiceHeader(SalesHeader."Sell-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)", "Original Amt. (LCY)");

        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", LineAmount);
        Assert.AreNearlyEqual(
          AmountLCY, CustLedgerEntry."Original Amt. (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Original Amt. (LCY)"), AmountLCY, CustLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          AmountLCY, CustLedgerEntry."Remaining Amt. (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), AmountLCY, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPaymentGeneral()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustomerPostingGroup: Record "Customer Posting Group";
        CurrencyCode: Code[10];
        Amount: Decimal;
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting Sales Invoice with Payment General Line.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Customer and Random Values.
        // Create and Post Sales Invoice.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        LineAmount := CreateAndPostSalesInvoice(SalesHeader, Amount, CurrencyCode);

        // Exercise: Post Payment General Line with Posted Invoice.
        CreateAndPostGenLines(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -LineAmount, Amount);

        // Verify: Verify GL Entry for Additional Currency Amount after Posting Sales Invoice and Remaining Amount on Customer
        // Ledger Entry.
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        DocumentNo := FindSalesInvoiceHeader(SalesHeader."Sell-to Customer No.");
        VerifyGLEntry(DocumentNo, CustomerPostingGroup."Receivables Account", LineAmount);
        VerifyZeroCustRemainingAmountLCY(CustLedgerEntry."Document Type"::Invoice, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPaymentGeneralAndRealizedLoss()
    begin
        // Verify Additional Currency Amount of Realized Loss G/L Entry
        // after Posting Sales Invoice with Payment General Line
        // in case of increasing Exchange Rate Amount
        SalesInvoiceWithPaymentGeneralAndModifiedExchRate(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPaymentGeneralAndRealizedGain()
    begin
        // Verify Additional Currency Amount of Realized Gain G/L Entry
        // after Posting Sales Invoice with Payment General Line
        // in case of decreasing Exchange Rate Amount
        SalesInvoiceWithPaymentGeneralAndModifiedExchRate(false, false);
    end;

    local procedure SalesInvoiceWithPaymentGeneralAndModifiedExchRate(IsLossEntry: Boolean; IsAdjustExchRate: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        InvoiceDocNo: Code[20];
        PaymentDocNo: Code[20];
        CurrencyGainsLossesAccNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);

        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostSalesInvoice(SalesHeader, Amount, CurrencyCode);
        ModifyExchangeRateAmount(CurrencyCode, IsLossEntry);

        if IsAdjustExchRate then
            LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());

        InvoiceDocNo := FindSalesInvoiceHeader(SalesHeader."Sell-to Customer No.");
        CreatePostGenJnlLineAndApplyToDoc(
          GenJournalLine."Account Type"::Customer, SalesHeader."Sell-to Customer No.",
          Amount, InvoiceDocNo);
        PaymentDocNo := FindCustPaymentDocNo(SalesHeader."Sell-to Customer No.");

        CurrencyGainsLossesAccNo :=
          GetCurrencyGainsLossesAccNo(CurrencyCode, IsLossEntry, IsAdjustExchRate);
        VerifyZeroAddCurrAmountInGLEntry(PaymentDocNo, CurrencyGainsLossesAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPostGeneralJournalFCY()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Additional Currency Amount in GL Entry and Amount on Vendor Ledger Entry after Posting General Journal Line
        // with Vendor and GL Account.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Vendor.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
        Vendor.Get(CreateVendor(CurrencyCode));

        // Exercise: Create General Invoices with GL Account.
        DocumentNo :=
          CreateAndPostGenLines(
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -AmountLCY, Amount);

        // Verify: Verify Additional Currency on GL Entry and Amount on Vendor Ledger Entry.
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -AmountLCY);
        VerifyVendorLedgerEntry(DocumentNo, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPaymentGeneralJournalFCY()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        Amount: Decimal;
        AmountLCY: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Additional Currency Amount in GL Entry and Amount after Posting Invoice and payment General Journal Line

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Vendor.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := Round(LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate()));
        Vendor.Get(CreateVendor(CurrencyCode));

        // Exercise: Create and Post Invoice and Payment General.
        CreateAndPostGenLines(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, Vendor."No.", -AmountLCY, Amount);
        DocumentNo :=
          CreateAndPostGenLines(
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, Vendor."No.", AmountLCY, Amount);

        // Verify: Verify Additional Currency on GL Entry and Amount on Vendor Ledger Entry.
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", AmountLCY);
        VerifyZeroVendRemainingAmountLCY(VendorLedgerEntry."Document Type"::Payment, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithFCY()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        VendorPostingGroup: Record "Vendor Posting Group";
        CurrencyCode: Code[10];
        AmountLCY: Decimal;
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting Purchase Invoice.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Customer and Random Values.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        AmountLCY := Round(LibraryERM.ConvertCurrency(LibraryRandom.RandDec(100, 2), '', CurrencyCode, WorkDate()));

        // Exercise.
        LineAmount := CreateAndPostPurchaseInvoice(PurchaseHeader, DocumentNo, AmountLCY, CurrencyCode);

        // Verify: Verify GL Entry for Additional Currency Amount after Posting Purchase Invoice.
        AmountLCY := Round(LibraryERM.ConvertCurrency(LineAmount, CurrencyCode, '', WorkDate()));
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -LineAmount);

        GeneralLedgerSetup.Get();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)", "Original Amt. (LCY)");
        Assert.AreNearlyEqual(
          -AmountLCY, VendorLedgerEntry."Original Amt. (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Original Amt. (LCY)"), -AmountLCY, VendorLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          -AmountLCY, VendorLedgerEntry."Remaining Amt. (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), -AmountLCY, VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPaymentGeneral()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        VendorPostingGroup: Record "Vendor Posting Group";
        CurrencyCode: Code[10];
        Amount: Decimal;
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify Additional Currency Amount in GL Entry after Posting Purchase Invoice with Payment General Line.

        // Setup: Update Additional Currency in General Ledger Setup and Create Currency with Vendor and Random Values.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        Amount := LibraryRandom.RandDec(100, 2);
        LineAmount := CreateAndPostPurchaseInvoice(PurchaseHeader, DocumentNo, Amount, CurrencyCode);

        // Exercise.
        CreateAndPostGenLines(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", LineAmount, -Amount);

        // Verify: Verify GL Entry for Additional Currency Amount after Posting Purchase Invoice and Payment General Line.
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(DocumentNo, VendorPostingGroup."Payables Account", -LineAmount);
        VerifyZeroVendRemainingAmountLCY(VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPaymentGeneralAndRealizedLoss()
    begin
        // Verify Additional Currency Amount of Realized Loss G/L Entry
        // after Posting Purchase Invoice with Payment General Line
        // in case of increasing Exchange Rate Amount
        PurchInvoiceWithPaymentGeneralAndModifiedExchRate(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPaymentGeneralAndRealizedGain()
    begin
        // Verify Additional Currency Amount of Realized Gain G/L Entry
        // after Posting Purchase Invoice with Payment General Line
        // in case of decreasing Exchange Rate Amount
        PurchInvoiceWithPaymentGeneralAndModifiedExchRate(false, false);
    end;

    local procedure PurchInvoiceWithPaymentGeneralAndModifiedExchRate(IsLossEntry: Boolean; IsAdjustExchRate: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        InvoiceDocNo: Code[20];
        PaymentDocNo: Code[20];
        CurrencyGainsLossesAccNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);

        Amount := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseInvoice(PurchHeader, InvoiceDocNo, Amount, CurrencyCode);
        ModifyExchangeRateAmount(CurrencyCode, not IsLossEntry);

        if IsAdjustExchRate then
            LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, WorkDate(), WorkDate());
        CreatePostGenJnlLineAndApplyToDoc(
          GenJournalLine."Account Type"::Vendor, PurchHeader."Buy-from Vendor No.",
          -Amount, InvoiceDocNo);
        PaymentDocNo := FindVendPaymentDocNo(PurchHeader."Buy-from Vendor No.");

        CurrencyGainsLossesAccNo :=
          GetCurrencyGainsLossesAccNo(CurrencyCode, IsLossEntry, IsAdjustExchRate);
        VerifyZeroAddCurrAmountInGLEntry(PaymentDocNo, CurrencyGainsLossesAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnapplyWithDiffExchRates()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyCode: Code[10];
        CustNo: Code[20];
        DocNo: array[3] of Code[20];
        Dates: array[2] of Date;
        Amounts: array[3] of Decimal;
    begin
        Initialize();
        CreateInitDataTFS351444(CurrencyCode, Dates, Amounts, true);
        CustNo := CreateSimpleCustomer(CurrencyCode);

        CreatePostPaymentAnd2Invoices(DocNo, Dates[1], false, CustNo, CurrencyCode, Amounts);
        ApplyPostCustPayment2Invoices(DocNo[1], DocNo[2], DocNo[3]);
        UnapplyAndPostCustEntry(CustNo, DocNo[1], Dates[2]);

        VerifyCustRemainingAmount(CustLedgerEntry."Document Type"::Payment, DocNo[1], -Amounts[1]);
        VerifyCustRemainingAmount(CustLedgerEntry."Document Type"::Invoice, DocNo[2], -Amounts[2]);
        VerifyCustRemainingAmount(CustLedgerEntry."Document Type"::Invoice, DocNo[3], -Amounts[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnapplyWithDiffExchRates()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CurrencyCode: Code[10];
        VendNo: Code[20];
        DocNo: array[3] of Code[20];
        Dates: array[2] of Date;
        Amounts: array[3] of Decimal;
    begin
        Initialize();
        CreateInitDataTFS351444(CurrencyCode, Dates, Amounts, false);
        VendNo := CreateSimpleVendor(CurrencyCode);

        CreatePostPaymentAnd2Invoices(DocNo, Dates[1], true, VendNo, CurrencyCode, Amounts);
        ApplyPostVendPayment2Invoices(DocNo[1], DocNo[2], DocNo[3]);
        UnapplyAndPostVendEntry(VendNo, DocNo[1], Dates[2]);

        VerifyVendRemainingAmount(VendLedgerEntry."Document Type"::Payment, DocNo[1], -Amounts[1]);
        VerifyVendRemainingAmount(VendLedgerEntry."Document Type"::Invoice, DocNo[2], -Amounts[2]);
        VerifyVendRemainingAmount(VendLedgerEntry."Document Type"::Invoice, DocNo[3], -Amounts[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithPmtBalAccountNo()
    var
        PaymentMethod: Record "Payment Method";
        ServiceHeader: Record "Service Header";
        CurrencyCode: Code[10];
        ServiceInvNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Service] [Payment Method]
        // [SCENARIO 362623] Service Invoice with Additional Currency and Payment Method with "Bal. Account No."

        Initialize();
        // [GIVEN] "Additional Currency Code" = "X"
        CurrencyCode := CreateCurrencyAndExchangeRate();
        UpdateAddnlReportingCurrency(CurrencyCode);
        // [GIVEN] Payment Method with Bal. Account No. = "Y"
        CreatePaymentMethodWithBalAccount(PaymentMethod);
        // [GIVEN] Service Order with Currency Code = "X", Payment Method with Bal. Account No. = "Y" and Amount = 100
        TotalAmount :=
          CreateServiceOrderWithCurrencyCodeAndPmtMethod(ServiceHeader, CurrencyCode, PaymentMethod.Code);

        // [WHEN] Post Service Order
        ServiceInvNo := PostServiceOrder(ServiceHeader);

        // [THEN] G/L Entry with Account No. = "Y" is created and Additional Currency Amount = 100
        VerifyACYOnServiceOrderGLEntry(ServiceInvNo, PaymentMethod."Bal. Account No.", TotalAmount);
    end;

    local procedure CreatePaymentMethodWithBalAccount(var PaymentMethod: Record "Payment Method")
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        PaymentMethod.Modify(true);
    end;

    local procedure CreateInitDataTFS351444(var CurrencyCode: Code[10]; var Dates: array[2] of Date; var Amounts: array[3] of Decimal; IsCust: Boolean)
    var
        i: Integer;
    begin
        Dates[1] := WorkDate();
        Dates[2] := CalcDate('<1M>', Dates[1]);
        Amounts[1] := -9858.77;
        Amounts[2] := 5338.86;
        Amounts[3] := 4519.91;
        if IsCust then
            for i := 1 to ArrayLen(Amounts) do
                Amounts[i] := -Amounts[i];
        CurrencyCode := CreateCurrency();
        CreateAddExchRate(CurrencyCode, Dates[1], 0.857);
        CreateAddExchRate(CurrencyCode, Dates[2], 0.85365);
        UpdateAddnlReportingCurrency(CurrencyCode);
    end;

    local procedure CreatePostPaymentAnd2Invoices(var DocNo: array[3] of Code[20]; PostingDate: Date; IsVend: Boolean; CVNo: Code[20]; CurrencyCode: Code[10]; Amounts: array[3] of Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        DocNo[1] := CreatePostGenJnlLine(
            PostingDate, GenJnlLine."Document Type"::Payment, IsVend, CVNo, CurrencyCode, Amounts[1]);
        for i := 2 to 3 do
            DocNo[i] := CreatePostGenJnlLine(
                PostingDate, GenJnlLine."Document Type"::Invoice, IsVend, CVNo, CurrencyCode, Amounts[i]);
    end;

    local procedure CreatePostGenJnlLine(PostingDate: Date; DocType: Enum "Gen. Journal Document Type"; IsVend: Boolean; CVNo: Code[20]; CurrencyCode: Code[10]; PayAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        BalAccountType: Enum "Gen. Journal Account Type";
    begin
        if IsVend then
            BalAccountType := GenJnlLine."Bal. Account Type"::Vendor
        else
            BalAccountType := GenJnlLine."Bal. Account Type"::Customer;
        exit(
          CreatePostGenJnlLineWithBalanceAcc(
            PostingDate, DocType, GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
            BalAccountType, CVNo, CurrencyCode, PayAmount));
    end;

    local procedure CreatePostGenJnlLineWithBalanceAcc(PostingDate: Date; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; CurrencyCode: Code[10]; LineAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        SelectClearGenJournalBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
            DocType, AccountType, AccountNo, LineAmount);
        GenJnlLine.Validate("External Document No.", GenJnlLine."Document No.");
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Bal. Account Type", BalAccountType);
        GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Amount, LineAmount);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreatePostGenJnlLineAndApplyToDoc(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PayAmount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, -PayAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenLines(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; Amount2: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Bal. Account No.", Amount2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; UnitPrice: Decimal; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        SalesLine: Record "Sales Line";
    begin
        Currency.Get(CurrencyCode);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(CurrencyCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          ModifyGLAccount(LibraryERM.CreateGLAccountNoWithDirectPosting()), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(Round(SalesLine."Amount Including VAT", Currency."Invoice Rounding Precision"));
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var DocumentNo: Code[20]; DirectUnitCost: Decimal; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
    begin
        Currency.Get(CurrencyCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(CurrencyCode));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::"G/L Account",
          ModifyGLAccount(LibraryERM.CreateGLAccountNoWithDirectPosting()), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(Round(PurchaseLine."Amount Including VAT", Currency."Invoice Rounding Precision"));
    end;

    local procedure CreateServiceOrderWithCurrencyCodeAndPmtMethod(var ServiceHeader: Record "Service Header"; CurrencyCode: Code[10]; PamentMethodCode: Code[10]): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryERM.FindVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 0); // zero VAT to pass on IN
        VATPostingSetup.Modify(true);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Validate("Payment Method Code", PamentMethodCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        exit(ServiceLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGeneralJournalBankFCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        BankAccountNo: Code[20];
        Amount: Decimal;
        AmountLCY: Decimal;
    begin
        // Verify Amount and Amount (LCY) in GL Entry after Posting General Journal Line with Bank having Currency code and
        // balancing Bank having no Currency code.

        // Setup.
        Initialize();
        CurrencyCode := CreateCurrencyAndExchangeRate();

        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := Round(LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', WorkDate()));

        BankAccountNo := CreateBankAccount('');

        // Exercise.
        DocumentNo :=
          CreatePostGenJnlLineWithBalanceAcc(
            WorkDate(), GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(CurrencyCode),
            GenJournalLine."Account Type"::"Bank Account", BankAccountNo, CurrencyCode, Amount);

        // Verify.
        VerifyBankAccountLedgerEntry(DocumentNo, BankAccountNo, -AmountLCY);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Additional Currency II");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Additional Currency II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Additional Currency II");
    end;

    local procedure CreateCurrencyAndExchangeRate() CurrencyCode: Code[10]
    begin
        CurrencyCode := CreateCurrency();
        LibraryERM.CreateRandomExchangeRate(CurrencyCode);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        Currency.Validate("Residual Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Residual Losses Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized G/L Gains Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized G/L Losses Account", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateAddExchRate(CurrencyCode: Code[10]; StartingDate: Date; ExhRateAmt: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.Init();
        CurrExchRate."Starting Date" := StartingDate;
        CurrExchRate."Currency Code" := CurrencyCode;
        CurrExchRate."Exchange Rate Amount" := ExhRateAmt;
        CurrExchRate."Adjustment Exch. Rate Amount" := 1;
        CurrExchRate."Relational Exch. Rate Amount" := 1;
        CurrExchRate."Relational Adjmt Exch Rate Amt" := 1;
        CurrExchRate.Insert();
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateSimpleCustomer(CurrencyCode));
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSimpleCustomer(CurrencyCode: Code[10]): Code[20]
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
    begin
        Vendor.Get(CreateSimpleVendor(CurrencyCode));
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSimpleVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
        GLAccountSourceCurrency: Record "G/L Account Source Currency";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        GLAccount.Get(BankAccountPostingGroup."G/L Account No.");
        if GLAccount."Source Currency Posting" = GLAccount."Source Currency Posting"::"Multiple Currencies" then
            if not GLAccountSourceCurrency.Get(GLAccount."No.", CurrencyCode) then begin
                GLAccountSourceCurrency.Init();
                GLAccountSourceCurrency."G/L Account No." := GLAccount."No.";
                GLAccountSourceCurrency."Currency Code" := CurrencyCode;
                GLAccountSourceCurrency.Insert();
            end;
        exit(BankAccount."No.");
    end;

    local procedure FindSalesInvoiceHeader(SelltoCustomerNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SelltoCustomerNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindCustPaymentDocNo(CustNo: Code[20]): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Sell-to Customer No.", CustNo);
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Payment);
        CustLedgEntry.FindFirst();
        exit(CustLedgEntry."Document No.");
    end;

    local procedure FindVendPaymentDocNo(VendNo: Code[20]): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Buy-from Vendor No.", VendNo);
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Payment);
        VendLedgEntry.FindFirst();
        exit(VendLedgEntry."Document No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
    end;

    local procedure ModifyExchangeRateAmount(CurrencyCode: Code[10]; IsRaise: Boolean)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        RaiseValue: Decimal;
    begin
        if IsRaise then
            RaiseValue := 1 / 3
        else
            RaiseValue := 3;
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" * RaiseValue);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount" * RaiseValue);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyGLAccount(GLAccountNo: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccountNo);
    end;

    local procedure PostServiceOrder(var ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure GetCurrencyGainsLossesAccNo(CurrencyCode: Code[10]; IsLossEntry: Boolean; IsUnrealizedEntry: Boolean): Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        if IsLossEntry then begin
            if IsUnrealizedEntry then
                exit(Currency."Unrealized Losses Acc.");
            exit(Currency."Realized Losses Acc.");
        end;
        if IsUnrealizedEntry then
            exit(Currency."Unrealized Gains Acc.");
        exit(Currency."Realized Gains Acc.");
    end;

    local procedure SelectClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exits before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    [Normal]
    local procedure UpdateAddnlReportingCurrency(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ApplyPostVendPayment2Invoices(PayDocNo: Code[20]; InvDocNo1: Code[20]; InvDocNo2: Code[20])
    var
        VendLedgerEntryFrom: Record "Vendor Ledger Entry";
        VendLedgerEntryTo: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgerEntryFrom, VendLedgerEntryFrom."Document Type"::Payment, PayDocNo);
        VendLedgerEntryFrom.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendLedgerEntryFrom, VendLedgerEntryFrom."Remaining Amount");

        LibraryERM.FindVendorLedgerEntry(VendLedgerEntryTo, VendLedgerEntryTo."Document Type"::Invoice, InvDocNo1);
        LibraryERM.SetAppliestoIdVendor(VendLedgerEntryTo);

        LibraryERM.FindVendorLedgerEntry(VendLedgerEntryTo, VendLedgerEntryTo."Document Type"::Invoice, InvDocNo2);
        LibraryERM.SetAppliestoIdVendor(VendLedgerEntryTo);

        LibraryERM.PostVendLedgerApplication(VendLedgerEntryFrom);
    end;

    local procedure ApplyPostCustPayment2Invoices(PayDocNo: Code[20]; InvDocNo1: Code[20]; InvDocNo2: Code[20])
    var
        CustLedgerEntryFrom: Record "Cust. Ledger Entry";
        CustLedgerEntryTo: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryFrom, CustLedgerEntryFrom."Document Type"::Payment, PayDocNo);
        CustLedgerEntryFrom.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryFrom, CustLedgerEntryFrom."Remaining Amount");

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryTo, CustLedgerEntryTo."Document Type"::Invoice, InvDocNo1);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryTo);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryTo, CustLedgerEntryTo."Document Type"::Invoice, InvDocNo2);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryTo);

        LibraryERM.PostCustLedgerApplication(CustLedgerEntryFrom);
    end;

    local procedure UnapplyAndPostVendEntry(VendNo: Code[20]; DocNo: Code[20]; PostingDate: Date)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendNo);
        VendorLedgerEntry.SetRange("Document No.", DocNo);
        VendorLedgerEntry.SetRange(Open, false);
        VendorLedgerEntry.FindLast();
        LibraryERMUnapply.UnapplyVendorLedgerEntryBase(VendorLedgerEntry, PostingDate);
    end;

    local procedure UnapplyAndPostCustEntry(CustNo: Code[20]; DocNo: Code[20]; PostingDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.SetRange(Open, false);
        CustLedgerEntry.FindLast();
        LibraryERMUnapply.UnapplyCustomerLedgerEntryBase(CustLedgerEntry, PostingDate);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields("Original Amount", Amount, "Remaining Amount");
        Assert.AreEqual(
          Amount, CustLedgerEntry."Original Amount",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Original Amount"), Amount, CustLedgerEntry.TableCaption()));
        Assert.AreEqual(
          Amount, CustLedgerEntry.Amount,
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
        Assert.AreEqual(
          Amount, CustLedgerEntry."Remaining Amount",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Remaining Amount"), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyBankAccountLedgerEntry(DocumentNo: Code[20]; BankAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, BankAccountLedgerEntry.Amount,
          StrSubstNo(WrongBankAccLedgEntryAmtErr, BankAccountLedgerEntry.FieldCaption(Amount)));
        Assert.AreEqual(ExpectedAmount, BankAccountLedgerEntry."Remaining Amount",
          StrSubstNo(WrongBankAccLedgEntryAmtErr, BankAccountLedgerEntry.FieldCaption(Amount)));
        Assert.AreEqual(ExpectedAmount, BankAccountLedgerEntry."Amount (LCY)",
          StrSubstNo(WrongBankAccLedgEntryAmtErr, BankAccountLedgerEntry.FieldCaption("Amount (LCY)")));
    end;

    local procedure VerifyZeroCustRemainingAmountLCY(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreEqual(
          0, CustLedgerEntry."Remaining Amt. (LCY)",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), 0, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyCustRemainingAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedAmt: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(
          ExpectedAmt, CustLedgerEntry."Remaining Amount",
          StrSubstNo(WrongAmountErr, CustLedgerEntry.FieldCaption("Remaining Amount"), ExpectedAmt, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Original Amount", Amount, "Remaining Amount");
        Assert.AreEqual(
          -Amount, VendorLedgerEntry."Original Amount",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Original Amount"), -Amount, VendorLedgerEntry.TableCaption()));
        Assert.AreEqual(
          -Amount, VendorLedgerEntry.Amount,
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption(Amount), -Amount, VendorLedgerEntry.TableCaption()));
        Assert.AreEqual(
          -Amount, VendorLedgerEntry."Remaining Amount",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Remaining Amount"), -Amount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyZeroVendRemainingAmountLCY(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        Assert.AreEqual(
          0, VendorLedgerEntry."Remaining Amt. (LCY)",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Remaining Amt. (LCY)"), 0, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyVendRemainingAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ExpectedAmt: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(
          ExpectedAmt, VendorLedgerEntry."Remaining Amount",
          StrSubstNo(WrongAmountErr, VendorLedgerEntry.FieldCaption("Remaining Amount"), ExpectedAmt, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreEqual(
          Amount, GLEntry."Additional-Currency Amount",
          StrSubstNo(WrongAmountErr, GLEntry.FieldCaption("Additional-Currency Amount"), Amount, GLEntry.TableCaption()));
        Assert.AreEqual(
          Amount, GLEntry."Source Currency Amount",
          StrSubstNo(WrongAmountErr, GLEntry.FieldCaption("Source Currency Amount"), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyZeroAddCurrAmountInGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.TestField("Additional-Currency Amount", 0);
    end;

    local procedure VerifyACYOnServiceOrderGLEntry(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        FindGLEntry(GLEntry, DocNo, GLAccNo);
        Assert.AreEqual(
          ExpectedAmount, GLEntry."Additional-Currency Amount", GLEntry.FieldCaption("Additional-Currency Amount"));
    end;
}

