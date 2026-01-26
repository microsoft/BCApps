codeunit 144125 "ERM Payment VAT EC Calculate"
{
    // 1. Test to verify VAT and G/L entries after posting Payment for Vendor with Currency and Unrealized VAT TRUE.
    // 2. Test to verify VAT and G/L entries after posting Payment for Vendor with Reverse Charge VAT and Unrealized VAT TRUE.
    // 3. Test to verify VAT and G/L entries after posting Payment for Vendor with Reverse Charge VAT, Currency and Unrealized VAT TRUE.
    // 4. Test to verify VAT Amount after posting Purchase Order with Payment Discount, Invoice Discount and Line Discount.
    // 5. Test to verify VAT Amount after posting Sales Order with Payment Discount, Invoice Discount and Line Discount.
    // 6. Test to verify VAT and G/L entries after posting Payment for Customer with Currency and Unrealized VAT TRUE.
    // 7. Test to verify VAT and G/L entries after posting Payment for Customer without Currency and Unrealized VAT TRUE.
    // 
    // Covers Test Cases for WI - 352299
    // -----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------
    // PaymentForVendorWithCurrencyAndUnrealizedVAT                                                         283139
    // PmtForVendorWithReverseChargeVATAndWithoutCurr                                                       283156
    // PaymentForVendorWithReverseChargeVATAndCurrency                                                      283148
    // PurchaseOrderWithPaymentInvoiceAndLineDiscount                                                       229964
    // SalesOrderWithPaymentInvoiceAndLineDiscount                                                          229965
    // PaymentForCustomerWithCurrencyUnrealizedVAT                                                          283144
    // 
    // Covers Test Cases for WI - 352327
    // -----------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -----------------------------------------------------------------------------------------------------------
    // PaymentForCustomerWithoutCurrUnrealizedVAT                                                           283286

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustBeEqualMsg: Label 'Amount must be equal.';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForVendorWithCurrencyAndUnrealizedVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        BaseAmount: Decimal;
    begin
        // Test to verify VAT and G/L entries after posting Payment for Vendor with Currency and Unrealized VAT TRUE.

        // Setup: Create and Post Purchase Invoice from General Journal line. Create Payment on General Journal line.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");  // True for Unrealized VAT.
        CreateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."Unrealized VAT Type"::Percentage);
        CreateAndPostInvoiceFromGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), CreateGLAccount(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", GLAccount."Gen. Posting Type"::Purchase),
          CreateCurrencyWithExchangeRate(), -LibraryRandom.RandDec(100, 2));  // Random value used for Amount.
        CreatePaymentFromGeneralJournalLine(GenJournalLine2, GenJournalLine);
        BaseAmount :=
          LibraryERM.ConvertCurrency(
            GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate()) * 100 / (100 + VATPostingSetup."VAT+EC %");  // Blank value used for ToCurrency.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Verify.
        VerifyVATAndGLEntries(
          GenJournalLine2."Document No.", GenJournalLine."Bal. Account No.", VATPostingSetup."Purch. VAT Unreal. Account",
          VATPostingSetup."Purchase VAT Account", BaseAmount, Round(BaseAmount * VATPostingSetup."VAT+EC %" / 100));

        // Tear Down.
        VATPostingSetup.Delete();  // Deleting new created VAT Posting Setup.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtForVendorWithReverseChargeVATAndWithoutCurr()
    begin
        // Test to verify VAT and G/L entries after posting Payment for Vendor with Reverse Charge VAT and Unrealized VAT TRUE.
        PmtForVendWithReverseChargeVATAndUnrealizedVAT('');  // Blank used for Currency Code.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForVendorWithReverseChargeVATAndCurrency()
    begin
        // Test to verify VAT and G/L entries after posting Payment for Vendor with Reverse Charge VAT, Currency and Unrealized VAT TRUE.
        PmtForVendWithReverseChargeVATAndUnrealizedVAT(CreateCurrencyWithExchangeRate());
    end;

    local procedure PmtForVendWithReverseChargeVATAndUnrealizedVAT(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        BaseAmount: Decimal;
    begin
        // Setup: Create and Post Purchase Invoice from General Journal line. Create Payment on General Journal line.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");  // True for Unrealized VAT.
        CreateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT",
          VATPostingSetup."Unrealized VAT Type"::Percentage);
        CreateAndPostInvoiceFromGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CreateGLAccount(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", GLAccount."Gen. Posting Type"::Purchase),
          CurrencyCode, -LibraryRandom.RandDec(100, 2));  // Random value used for Amount.
        CreatePaymentFromGeneralJournalLine(GenJournalLine2, GenJournalLine);
        BaseAmount := LibraryERM.ConvertCurrency(GenJournalLine.Amount, CurrencyCode, '', WorkDate());  // Blank value used for ToCurrency.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Verify.
        VerifyVATAndGLEntries(
          GenJournalLine2."Document No.", GenJournalLine."Bal. Account No.", VATPostingSetup."Purch. VAT Unreal. Account",
          VATPostingSetup."Purchase VAT Account", BaseAmount, Round(BaseAmount * VATPostingSetup."VAT+EC %" / 100));

        // Tear Down.
        VATPostingSetup.Delete();  // Deleting new created VAT Posting Setup.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPaymentInvoiceAndLineDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountExclVAT: Decimal;
        TotalExclVAT: Decimal;
    begin
        // Test to verify VAT Amount after posting Purchase Order with Payment Discount, Invoice Discount and Line Discount.

        // Setup: Create Purchase Order. Calculate Invoice and Payment Discount on Purchase Order.
        CreateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."Unrealized VAT Type"::" ");
        CreatePurchaseOrder(PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          false, GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");  // False for Unrealized VAT.
        CalculateInvAndPmtDiscountOnPurchaseOrder(PurchaseHeader."No.");
        PurchaseHeader.CalcFields("Invoice Discount Amount");
        AmountExclVAT := Round(PurchaseLine.Amount - PurchaseHeader."Invoice Discount Amount");
        TotalExclVAT := Round(AmountExclVAT - AmountExclVAT * PurchaseHeader."Payment Discount %" / 100);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyTotalVATAmountOnVATEntry(DocumentNo, TotalExclVAT * VATPostingSetup."VAT+EC %" / 100);

        // Tear Down.
        UpdateDiscountCalculationAsBlankGeneralLedgerSetup();  // To update Payment Discount Type on General Ledger Setup, we need to update Discount Calculation as Blank.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithPaymentInvoiceAndLineDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        AmountExclVAT: Decimal;
        TotalExclVAT: Decimal;
    begin
        // Test to verify VAT Amount after posting Sales Order with Payment Discount, Invoice Discount and Line Discount.

        // Setup: Create Sales Order. Calculate Invoice and Payment Discount on Sales Order.
        CreateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."Unrealized VAT Type"::" ");
        CreateSalesOrder(SalesLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          false, GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");  // False for Unrealized VAT.
        CalculateInvAndPmtDiscountOnSalesOrder(SalesHeader."No.");
        SalesHeader.CalcFields("Invoice Discount Amount");
        AmountExclVAT := Round(SalesLine.Amount - SalesHeader."Invoice Discount Amount");
        TotalExclVAT := Round(AmountExclVAT - AmountExclVAT * SalesHeader."Payment Discount %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyTotalVATAmountOnVATEntry(DocumentNo, -TotalExclVAT * VATPostingSetup."VAT+EC %" / 100);

        // Tear Down.
        UpdateDiscountCalculationAsBlankGeneralLedgerSetup();  // To update Payment Discount Type on General Ledger Setup, we need to update Discount Calculation as Blank.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForCustomerWithCurrencyUnrealizedVAT()
    begin
        // Test to verify VAT and G/L entries after posting Payment for Customer with Currency and Unrealized VAT TRUE.
        PaymentForCustomerUnrealizedVAT(CreateCurrencyWithExchangeRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentForCustomerWithoutCurrUnrealizedVAT()
    begin
        // Test to verify VAT and G/L entries after posting Payment for Customer without Currency and Unrealized VAT TRUE.
        PaymentForCustomerUnrealizedVAT('');  // Blank for Currency Code.
    end;

    local procedure PaymentForCustomerUnrealizedVAT(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        BaseAmount: Decimal;
    begin
        // Setup: Create and Post Sales Invoice from General Journal line. Create Payment on General Journal line.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(true, GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");  // True for Unrealized VAT.
        CreateVATPostingSetup(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPostingSetup."Unrealized VAT Type"::Percentage);
        CreateAndPostInvoiceFromGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
          CreateGLAccount(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", GLAccount."Gen. Posting Type"::Sale),
          CurrencyCode, LibraryRandom.RandDec(100, 2));  // Random value used for Amount.
        CreatePaymentFromGeneralJournalLine(GenJournalLine2, GenJournalLine);
        BaseAmount :=
          LibraryERM.ConvertCurrency(
            GenJournalLine.Amount, GenJournalLine."Currency Code", '', WorkDate()) * 100 / (100 + VATPostingSetup."VAT+EC %");  // Blank value used for ToCurrency.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);

        // Verify.
        VerifyVATAndGLEntries(
          GenJournalLine2."Document No.", GenJournalLine."Bal. Account No.", VATPostingSetup."Sales VAT Unreal. Account",
          VATPostingSetup."Sales VAT Account", BaseAmount, Round(BaseAmount * VATPostingSetup."VAT+EC %" / 100));

        // Tear Down.
        VATPostingSetup.Delete();  // Deleting new created VAT Posting Setup.
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    local procedure CalculateInvAndPmtDiscountOnPurchaseOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure CalculateInvAndPmtDiscountOnSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        SalesOrder.Close();
    end;

    local procedure CreateAndPostInvoiceFromGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", CreateGLAccount('', '', GLAccount."Gen. Posting Type"::" "));  // Blank used for VATBusPostingGroup and VATProdPostingGroup.
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
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

    local procedure CreateCustomerWithInvoiceDiscount(VATBusPostingGroup: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(VATBusPostingGroup), '', 0);  // Blank used for Currency Code. 0 used for Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(50, 2));
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateGLAccount(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentFromGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine2."Journal Template Name", GenJournalLine2."Journal Batch Name",
          GenJournalLine."Document Type"::Payment, GenJournalLine2."Account Type", GenJournalLine2."Account No.", -GenJournalLine2.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", GenJournalLine2."Document No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GenJournalLine2."Bal. Account No.");
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine2."Bal. Gen. Posting Type");
        GenJournalLine.Validate("Currency Code", GenJournalLine2."Currency Code");
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithInvoiceDiscount(VATBusPostingGroup));
        PurchaseHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithInvoiceDiscount(VATBusPostingGroup));
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate(
          "Purch. VAT Unreal. Account",
          CreateGLAccount(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", GLAccount."Gen. Posting Type"::" "));
        VATPostingSetup.Validate("Sales VAT Unreal. Account", VATPostingSetup."Purch. VAT Unreal. Account");
        VATPostingSetup.Validate(
          "Purchase VAT Account", CreateGLAccount(
            VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", GLAccount."Gen. Posting Type"::" "));
        VATPostingSetup.Validate("Sales VAT Account", VATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", VATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", VATPostingSetup."Purch. VAT Unreal. Account");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithInvoiceDiscount(VATBusPostingGroup: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(VATBusPostingGroup), '', 0);  // Blank used for Currency Code. 0 used for Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(50, 2));
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure UpdateDiscountCalculationAsBlankGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Discount Calculation", GeneralLedgerSetup."Discount Calculation"::" ");
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; PaymentDiscountType: Option; DiscountCalculation: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GeneralLedgerSetup.Validate("Discount Calculation", DiscountCalculation);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyTotalVATAmountOnVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Amount);
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    local procedure VerifyVATAndGLEntries(DocumentNo: Code[20]; BalAccountNo: Code[20]; VATUnrealAccount: Code[20]; VATAccount: Code[20]; BaseAmount: Decimal; VATAmount: Decimal)
    begin
        VerifyVATEntry(DocumentNo, VATAmount);
        VerifyGLEntry(DocumentNo, BalAccountNo, BaseAmount);
        VerifyGLEntry(DocumentNo, VATUnrealAccount, VATAmount);
        VerifyGLEntry(DocumentNo, VATAccount, VATAmount);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustBeEqualMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

