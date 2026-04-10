codeunit 134031 "ERM VAT With Payment Discount"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in \\%3 %4=%5.';

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATForSalesInvLCY()
    begin
        // Test Discount Amount with Pmt Disc Excl VAT field TRUE and no Currency Code.
        Initialize();
        PmtDiscExclVATForSalesInvoice('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATForSalesInvFCY()
    begin
        // Test Discount Amount with Pmt Disc Excl VAT field TRUE and with Currency Code.
        Initialize();
        PmtDiscExclVATForSalesInvoice(CreateCurrency());
    end;

    local procedure PmtDiscExclVATForSalesInvoice(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        PostedInvoiceNo: Code[20];
        PaymentAmount: Decimal;
        AmountLCY: Decimal;
    begin
        // Setup: Create and Post Sales Invoice and calculate Payment Amount.
        PostedInvoiceNo := CreateAndPostSalesDocument(SalesHeader, true, CurrencyCode, SalesHeader."Document Type"::Invoice);
        PaymentAmount := CalculatePmtAmtExclVATSales(AmountLCY, SalesHeader, PostedInvoiceNo, SalesHeader."Currency Code");

        // Make Payment for the Sales Document, Calculate Discount Amount and verify Discount Amount.
        MakePmtAndVerifyDiscAmtSales(
          SalesHeader."No.", SalesHeader."Bill-to Customer No.", SalesHeader."Currency Code", -PaymentAmount, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscInclVATForSalesInvLCY()
    var
        SalesHeader: Record "Sales Header";
        PaymentAmount: Decimal;
        DiscountAmountLCY: Decimal;
    begin
        // Test Discount Amount with Pmt Disc Excl VAT field FALSE and no Currency Code.

        // Setup: Create and Post Sales Invoice and calculate Payment Amount.
        Initialize();
        CreateAndPostSalesDocument(SalesHeader, false, '', SalesHeader."Document Type"::Invoice);
        PaymentAmount :=
          SalesHeader."Amount Including VAT" - (SalesHeader."Amount Including VAT" * SalesHeader."Payment Discount %" / 100);
        DiscountAmountLCY := SalesHeader."Amount Including VAT" * SalesHeader."Payment Discount %" / 100;

        // Make Payment for the Sales Document, Calculate Discount Amount and verify Discount Amount.
        MakePmtAndVerifyDiscAmtSales(
          SalesHeader."No.", SalesHeader."Bill-to Customer No.", SalesHeader."Currency Code", -PaymentAmount, DiscountAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATForPurchInvLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentAmount: Decimal;
        AmountLCY: Decimal;
    begin
        // Test Discount Amount with Pmt Disc Excl VAT field TRUE.

        // Setup: Create and Post Purchase Invoice and calculate Payment Amount.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, true, '', PurchaseHeader."Document Type"::Invoice);
        PaymentAmount := CalculatePmtAmtExclVATPurch(PurchaseHeader, AmountLCY, PurchaseHeader."Currency Code");

        // Make Payment for the Purchase Document, Calculate Discount Amount and verify Discount Amount.
        MakePmtAndVerifyDiscAmtPurch(
          PurchaseHeader."No.", PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Currency Code", PaymentAmount, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscInclVATForPurchInvLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentAmount: Decimal;
        AmountLCY: Decimal;
    begin
        // Test Discount Amount with Pmt Disc Excl VAT field FALSE.

        // Setup: Create and Post Purchase Invoice and calculate Payment Amount.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, false, '', PurchaseHeader."Document Type"::Invoice);
        PaymentAmount :=
          PurchaseHeader."Amount Including VAT" - (PurchaseHeader."Amount Including VAT" * PurchaseHeader."Payment Discount %" / 100);
        AmountLCY := PurchaseHeader."Amount Including VAT" * PurchaseHeader."Payment Discount %" / 100;

        // Make Payment for the Purchase Document, Calculate Discount Amount and verify Discount Amount.
        MakePmtAndVerifyDiscAmtPurch(
          PurchaseHeader."No.", PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."Currency Code", PaymentAmount, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYSalesInvLCY()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Sales Invoice without Currency.
        Initialize();
        PaymentDiscountOnSalesDocument(SalesHeader."Document Type"::Invoice, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYSalesInvFCY()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Sales Invoice with Currency.
        Initialize();
        PaymentDiscountOnSalesDocument(SalesHeader."Document Type"::Invoice, CreateCurrency(), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYSalesCrMemoLCY()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Sales Credit Memo without Currency.
        Initialize();
        PaymentDiscountOnSalesDocument(SalesHeader."Document Type"::"Credit Memo", '', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYSalesCrMemoFCY()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Sales Credit Memo with Currency.
        Initialize();
        PaymentDiscountOnSalesDocument(SalesHeader."Document Type"::"Credit Memo", CreateCurrency(), -1);
    end;

    local procedure PaymentDiscountOnSalesDocument(DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; AmountSign: Integer)
    var
        SalesHeader: Record "Sales Header";
        OriginalPmtDiscPossible: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Document.
        DocumentNo := CreateAndPostSalesDocument(SalesHeader, true, CurrencyCode, DocumentType);

        // Exercise : Calculate Original Pmt.Disc.Possible on Sales Document.
        OriginalPmtDiscPossible := Round(SalesHeader.Amount * SalesHeader."Payment Discount %" / 100);

        // Verify: Verify Pmt.Disc.Given(LCY) and Original Pmt.Disc.Possible in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(DocumentNo, DocumentType, AmountSign * OriginalPmtDiscPossible);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYPurchInvLCY()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Purchase Invoice without Currency.
        Initialize();
        PaymentDiscountOnPurchDocument(PurchaseHeader."Document Type"::Invoice, '', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYPurchInvFCY()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Purchase Invoice with Currency.
        Initialize();
        PaymentDiscountOnPurchDocument(PurchaseHeader."Document Type"::Invoice, CreateCurrency(), -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYPurchCrMemoLCY()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Purchase Credit Memo without Currency.
        Initialize();
        PaymentDiscountOnPurchDocument(PurchaseHeader."Document Type"::"Credit Memo", '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscGivenLCYPurchCrMemoFCY()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Pmt. Disc. Given(LCY) is not updated when Payment is not made against the Purchase Credit Memo with Currency.
        Initialize();
        PaymentDiscountOnPurchDocument(PurchaseHeader."Document Type"::"Credit Memo", CreateCurrency(), 1);
    end;

    local procedure PaymentDiscountOnPurchDocument(DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; AmountSign: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        OriginalPmtDiscPossible: Decimal;
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Purchase Document.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseHeader, true, CurrencyCode, DocumentType);

        // Exercise : Calculate Original Pmt.Disc. Possible on Purchase Document.
        OriginalPmtDiscPossible := Round(PurchaseHeader.Amount * PurchaseHeader."Payment Discount %" / 100);

        // Verify: Verify Pmt.Disc.Given(LCY) and Original Pmt.Disc. Possible in Vendor Ledger Entry.
        VerifyVendorLedgerEntry(DocumentNo, DocumentType, AmountSign * OriginalPmtDiscPossible);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATTrueForCustomer()
    begin
        // Check Original Payment Discount Possible and Remaining Payment Discount Possible for Customer when Payment Discount Excluding VAT is TRUE.
        Initialize();
        PmtDiscExclVATForCustomer(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATFalseForCustomer()
    begin
        // Check Original Payment Discount Possible and Remaining Payment Discount Possible for Customer when Payment Discount Excluding VAT is FALSE.
        Initialize();
        PmtDiscExclVATForCustomer(false);
    end;

    local procedure PmtDiscExclVATForCustomer(PmtDiscExclVAT: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DiscountAmount: Decimal;
    begin
        // Setup and Exercise: Performed inside SetupPmtDiscAndPostGenJournalLine Function, taking Random Amount.
        DiscountAmount :=
          SetupPmtDiscAndPostGenJournalLine(
            GenJournalLine, PmtDiscExclVAT, GenJournalLine."Account Type"::Customer, CreateCustomer(), LibraryRandom.RandDec(100, 2));

        // Verify: Verify Original Payment Discount Possible and Remaining Payment Discount Possible for Customer in Customer Ledger Entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          DiscountAmount, CustLedgerEntry."Original Pmt. Disc. Possible", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, CustLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), DiscountAmount,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        Assert.AreNearlyEqual(
          DiscountAmount, CustLedgerEntry."Remaining Pmt. Disc. Possible", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, CustLedgerEntry.FieldCaption("Remaining Pmt. Disc. Possible"), DiscountAmount,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATTrueForVendor()
    begin
        // Check Original Payment Discount Possible and Remaining Payment Discount Possible for Vendor when Payment Discount Excluding VAT is TRUE.
        Initialize();
        PmtDiscExclVATForVendor(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscExclVATFalseForVendor()
    begin
        // Check Original Payment Discount Possible and Remaining Payment Discount Possible for Vendor when Payment Discount Excluding VAT is FALSE.
        Initialize();
        PmtDiscExclVATForVendor(false);
    end;

    local procedure PmtDiscExclVATForVendor(PmtDiscExclVAT: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DiscountAmount: Decimal;
    begin
        // Setup and Exercise: Performed inside SetupPmtDiscAndPostGenJournalLine Function, taking Random negative Amount for Vendor.
        DiscountAmount :=
          SetupPmtDiscAndPostGenJournalLine(
            GenJournalLine, PmtDiscExclVAT, GenJournalLine."Account Type"::Vendor, CreateVendor(), -LibraryRandom.RandDec(100, 2));

        // Verify: Verify Original Payment Discount Possible and Remaining Payment Discount Possible for Vendor in Vendor Ledger Entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          DiscountAmount, VendorLedgerEntry."Original Pmt. Disc. Possible", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, VendorLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), DiscountAmount,
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
        Assert.AreNearlyEqual(
          DiscountAmount, VendorLedgerEntry."Remaining Pmt. Disc. Possible", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErrorMessage, VendorLedgerEntry.FieldCaption("Remaining Pmt. Disc. Possible"), DiscountAmount,
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM VAT With Payment Discount");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM VAT With Payment Discount");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM VAT With Payment Discount");
    end;

    local procedure ApplyAndPostCustomerEntry(SalesInvDocNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesInvDocNo);
        SalesInvoiceHeader.FindFirst();
        CustLedgerEntry2.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyAndPostVendorEntry(PurchInvDocNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Apply Payment Entry on Posted Invoice.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");

        // Set Applies-to ID.
        PurchInvHeader.SetRange("Pre-Assigned No.", PurchInvDocNo);
        PurchInvHeader.FindFirst();
        VendorLedgerEntry2.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry2.FindFirst();
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);

        // Post Application Entries.
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CalculatePmtAmtExclVATPurch(PurchaseHeader: Record "Purchase Header"; var DiscountAmountLCY: Decimal; CurrencyCode: Code[10]) PaymentAmount: Decimal
    begin
        PaymentAmount := PurchaseHeader."Amount Including VAT" - (PurchaseHeader.Amount * PurchaseHeader."Payment Discount %" / 100);
        DiscountAmountLCY := PurchaseHeader.Amount * PurchaseHeader."Payment Discount %" / 100;
        PaymentAmount := LibraryERM.ConvertCurrency(PaymentAmount, CurrencyCode, '', WorkDate());
        DiscountAmountLCY := LibraryERM.ConvertCurrency(DiscountAmountLCY, CurrencyCode, '', WorkDate());
    end;

    local procedure CalculatePmtAmtExclVATSales(var AmountLCY: Decimal; SalesHeader: Record "Sales Header"; No: Code[20]; CurrencyCode: Code[10]) PaymentAmount: Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(No);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        PaymentAmount := SalesHeader."Amount Including VAT" - Round(SalesHeader.Amount * SalesHeader."Payment Discount %" / 100);
        AmountLCY := Round(SalesInvoiceHeader.Amount * SalesHeader."Payment Discount %" / 100);
        PaymentAmount := Round(LibraryERM.ConvertCurrency(PaymentAmount, CurrencyCode, '', WorkDate()));
        AmountLCY := Round(LibraryERM.ConvertCurrency(AmountLCY, CurrencyCode, '', WorkDate()));
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        CreateGeneralJnlLine(GenJournalLine, AccountType, DocumentType, AccountNo, Amount, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PmtDiscExclVAT: Boolean; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"): Code[20]
    begin
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(PmtDiscExclVAT);
        CreatePurchaseDocument(PurchaseHeader, CreateVendor(), CurrencyCode, DocumentType);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT", Amount);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; PmtDiscExclVAT: Boolean; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type") PostedInvoiceNo: Code[20]
    begin
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(PmtDiscExclVAT);
        CreateSalesDocument(SalesHeader, CreateCustomer(), CurrencyCode, DocumentType);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT", Amount);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Using RANDOM for Quantity, value is not important for Quantity.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        // Using RANDOM for Quantity, value is not important for Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateVendor(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure MakePmtAndVerifyDiscAmtPurch(No: Code[20]; AccountNo: Code[20]; CurrencyCode: Code[10]; PaymentAmount: Decimal; AmountLCY: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Exercise: Create and Post General Journal Line and Apply and Post Vendor Ledger Entry.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo, CurrencyCode,
          PaymentAmount);
        ApplyAndPostVendorEntry(No, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount in Vendor Detailed Ledger and G/L Entry.
        VendorPostingGroup.Get(GenJournalLine."Posting Group");
        VerifyGLEntry(GenJournalLine."Document No.", VendorPostingGroup."Payment Disc. Credit Acc.", -AmountLCY);
        VerifyDetailedVendorEntry(GenJournalLine."Document No.", AmountLCY);
    end;

    local procedure MakePmtAndVerifyDiscAmtSales(No: Code[20]; AccountNo: Code[20]; CurrencyCode: Code[10]; PaymentAmount: Decimal; AmountLCY: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Exercise: Create and Post General Journal Line and Apply and Post Customer Ledger Entry.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo, CurrencyCode,
          PaymentAmount);
        ApplyAndPostCustomerEntry(No, GenJournalLine."Document No.");

        // Verify: Verify Discount Amount in Detailed Customer Ledger Entry and in GL Entry.
        CustomerPostingGroup.Get(GenJournalLine."Posting Group");
        VerifyDetailedCustomerEntry(GenJournalLine."Document No.", AmountLCY);
        VerifyGLEntry(GenJournalLine."Document No.", CustomerPostingGroup."Payment Disc. Debit Acc.", AmountLCY);
    end;

    local procedure SetupPmtDiscAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PmtDiscExclVAT: Boolean; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal) DiscountAmount: Decimal
    begin
        // Setup: Set value for Payment Discount Exclusive VAT on General Ledger Setup, Create General Journal Line.
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(PmtDiscExclVAT);
        CreateGeneralJnlLine(GenJournalLine, AccountType, GenJournalLine."Document Type"::Invoice, AccountNo, Amount, '');  // Passing Blank for Currency Code.
        DiscountAmount := GenJournalLine.Amount * GenJournalLine."Payment Discount %" / 100;

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; OriginalPmtDiscPossible: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        Assert.AreNearlyEqual(
          OriginalPmtDiscPossible, CustLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, CustLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), OriginalPmtDiscPossible,
            CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        Assert.AreEqual(
          0, CustLedgerEntry."Pmt. Disc. Given (LCY)",
          StrSubstNo(
            AmountErrorMessage, CustLedgerEntry.FieldCaption("Pmt. Disc. Given (LCY)"), 0, CustLedgerEntry.TableCaption(),
            CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyDetailedCustomerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        Currency: Record Currency;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        Currency.InitRoundingPrecision();
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          -Amount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedCustLedgEntry.TableCaption(),
            DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyDetailedVendorEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        Currency: Record Currency;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Currency.InitRoundingPrecision();
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Payment Discount");
        DetailedVendorLedgEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, DetailedVendorLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"), Amount, DetailedVendorLedgEntry.TableCaption(),
            DetailedVendorLedgEntry.FieldCaption("Entry No."), DetailedVendorLedgEntry."Entry No."));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        Currency.InitRoundingPrecision();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; OriginalPmtDiscPossible: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Currency: Record Currency;
    begin
        Currency.InitRoundingPrecision();
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        Assert.AreNearlyEqual(
          OriginalPmtDiscPossible, VendorLedgerEntry."Original Pmt. Disc. Possible", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountErrorMessage, VendorLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), OriginalPmtDiscPossible,
            VendorLedgerEntry.TableCaption(), VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
        Assert.AreEqual(
          0, VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)",
          StrSubstNo(
            AmountErrorMessage, VendorLedgerEntry.FieldCaption("Pmt. Disc. Rcd.(LCY)"), 0, VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;
}

