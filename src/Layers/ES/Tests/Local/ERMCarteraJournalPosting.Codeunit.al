codeunit 144013 "ERM Cartera Journal Posting"
{
    // 1. Verify VAT Entry - Amount, Base and G/L Entry, Post Cartera Journal with multiple Lines and apply Customer Ledger Entry.
    // 2. Verify VAT Entry - Amount, Base and G/L Entry, Post Cartera Journal with multiple Lines and apply Vendor Ledger Entry.
    // 3. Verify VAT Entry - Amount, Base and G/L Entry, Post multiple Cartera Journal with Currency and apply Customer Ledger Entry.
    // 4. Verify VAT Entry - Amount, Base and G/L Entry, Post multiple Cartera Journal with Currency and apply Vendor Ledger Entry.
    // 5. Verify that Cartera Journal can be posted with Add. Reporting Currency and Bill Transformation containing some magic numbers.
    // 
    // Covers Test Cases for WI - 351137.
    // --------------------------------------------------------------------------------------------------
    // Test Function Name                                                                         TFS ID
    // --------------------------------------------------------------------------------------------------
    // ApplyCustLedgerEntryCarteraJournalWithMultipleline                                         325292
    // ApplyVendorLedgEntryCarteraJournalWithMultipleline                                         325290
    // ApplyCustLedgerEntryMultipleCarteraJournalWithCurrency                                     326616
    // ApplyVendorLedgEntryMultipleCarteraJournalWithCurrency                                     326615
    // 
    // Covers Test Cases for WI - 357137.
    // --------------------------------------------------------------------------------------------------
    // Test Function Name                                                                         TFS ID
    // --------------------------------------------------------------------------------------------------
    // TransformBillCustCarteraJournalWithCurrency                                                357137

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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValueMustBeEqualMsg: Label 'Value Must Be Equal.';
        WrongNoOfCustLedgEntryErr: Label 'Wrong number of Customer Ledger Entry.';
        ExportedToPaymentFileError: Label 'Vendor Ledger Entry should not be exported to Payment File.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustLedgerEntryCarteraJournalWithMultipleline()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify VAT Entry - Amount, Base and G/L Entry, Post Cartera Journal with multiple Lines and apply Customer Ledger Entry.

        // Setup: Create and Post Sales Invoice, Cartera Journal with multiple Lines, Cash Receipt.
        CustomerNo := CreateCustomer('');  // Blank - Currency Code.
        DocumentNo := CreateAndPostSalesInvoice(SalesLine, CustomerNo);
        CreateAndPostMultipleCarteraJournalLines(GenJournalLine."Account Type"::Customer, DocumentNo, CustomerNo, SalesLine.Amount);
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(GenJournalLine, '', GenJournalLine."Account Type"::Customer, CustomerNo, SalesLine.Amount);  // Blank - Applies - to - Doc. No.

        // Exercise: Apply Customer Ledger Entry.
        ApplyPaymentToSalesInvoice(DocumentNo2, -SalesLine.Amount);

        // Verify: Verify VAT Entry - Base, Amount, Additional-Currency Base, Additional-Currency Amount and G/L Entry - Amount, Additional-Currency Amount.
        VerifyVATAndGLEntry(DocumentNo, DocumentNo2, SalesLine.Amount, SalesLine."VAT %", 0);  // Additional-Currency Amount should be 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendorLedgEntryCarteraJournalWithMultipleline()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify VAT Entry - Amount, Base and G/L Entry, Post Cartera Journal with multiple Lines and apply Vendor Ledger Entry.

        // Setup: Create and Post Purchase Invoice, Cartera Journal with multiple Lines, Payment Journal.
        VendorNo := CreateVendor('');  // Blank - Currency Code.
        DocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, VendorNo);
        CreateAndPostMultipleCarteraJournalLines(
          GenJournalLine."Account Type"::Vendor, DocumentNo, VendorNo, -PurchaseLine.Amount);
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(GenJournalLine, '', GenJournalLine."Account Type"::Vendor, VendorNo, -PurchaseLine.Amount);  // Blank - Applies - to - Doc. No.

        // Exercise: Apply Vendor Ledger Entry.
        ApplyPaymentToPurchaseInvoice(DocumentNo2, PurchaseLine.Amount);

        // Verify: Verify VAT Entry - Base, Amount, Additional-Currency Base, Additional-Currency Amount and G/L Entry - Amount, Additional-Currency Amount.
        VerifyVATAndGLEntry(DocumentNo, DocumentNo2, -PurchaseLine.Amount, PurchaseLine."VAT %", 0);  // Additional-Currency Amount should be 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCustLedgerEntryMultipleCarteraJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        OldCurrencyCode: Code[10];
    begin
        // Verify VAT Entry - Amount, Base and G/L Entry, Post multiple Cartera Journal with Currency and apply Customer Ledger Entry.

        // Setup: Create and Post Sales Invoice with Currency, multiple Cartera Journal, Cash Receipt.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        Commit();  // Commit Required.
        OldCurrencyCode := UpdateGeneralLedgerSetup(CurrencyCode);
        CustomerNo := CreateCustomer(CurrencyCode);
        DocumentNo := CreateAndPostSalesInvoice(SalesLine, CustomerNo);
        CreateAndPostCarteraJournalLines(
          GenJournalLine."Account Type"::Customer, DocumentNo, CustomerNo, SalesLine.Amount);
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(GenJournalLine, '', GenJournalLine."Account Type"::Customer, CustomerNo, SalesLine.Amount);  // Blank - Applies - to - Doc. No.

        // Exercise: Apply Customer Ledger Entry.
        ApplyPaymentToSalesInvoice(DocumentNo2, -SalesLine.Amount);

        // Verify: Verify VAT Entry - Base, Amount, Additional-Currency Base, Additional-Currency Amount and G/L Entry - Amount, Additional-Currency Amount.
        VerifyVATAndGLEntry(
          DocumentNo, DocumentNo2, SalesLine.Amount / FindCurrencyFactor(CurrencyCode), SalesLine."VAT %", SalesLine.Amount);
        UpdateGeneralLedgerSetup(OldCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyVendorLedgEntryMultipleCarteraJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        OldCurrencyCode: Code[10];
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Verify VAT Entry - Amount, Base and G/L Entry, Post multiple Cartera Journal with Currency and apply Vendor Ledger Entry.

        // Setup: Create and Post Purchase Invoice with Currency, multiple Cartera Journal, Payment Journal.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        Commit();  // Commit Required.
        OldCurrencyCode := UpdateGeneralLedgerSetup(CurrencyCode);
        VendorNo := CreateVendor(CurrencyCode);
        DocumentNo := CreateAndPostPurchaseInvoice(PurchaseLine, VendorNo);
        CreateAndPostCarteraJournalLines(
          GenJournalLine."Account Type"::Vendor, DocumentNo, VendorNo, -PurchaseLine.Amount);
        DocumentNo2 :=
          CreateAndPostGeneralJournalLine(GenJournalLine, '', GenJournalLine."Account Type"::Vendor, VendorNo, -PurchaseLine.Amount);  // Blank - Applies - to - Doc. No.

        // Exercise: Apply Vendor Ledger Entry.
        ApplyPaymentToPurchaseInvoice(DocumentNo2, PurchaseLine.Amount);

        // Verify: Verify VAT Entry - Base, Amount, Additional-Currency Base, Additional-Currency Amount and G/L Entry - Amount, Additional-Currency Amount.
        VerifyVATAndGLEntry(
          DocumentNo, DocumentNo2, -PurchaseLine.Amount / FindCurrencyFactor(CurrencyCode),
          PurchaseLine."VAT %", -PurchaseLine.Amount);
        UpdateGeneralLedgerSetup(OldCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransformBillCustCarteraJournalWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        OldCurrencyCode: Code[10];
    begin
        // Verify that Cartera Journal can be posted with Add. Reporting Currency and Bill Transformation containing some magic numbers.

        // Setup.
        CurrencyCode := CreateCurrencyWithExchangeRate();
        ModifyExchangeRate(CurrencyCode, 1.37856);
        OldCurrencyCode := UpdateGeneralLedgerSetup(CurrencyCode);
        CustomerNo := CreateCustomer(CurrencyCode);

        // Exercise.
        CreateAndPostCarteraJournalBillTransform(
          GenJournalLine."Account Type"::Customer, '', CustomerNo, 37140, 22860);

        // Verify.
        VerifyBillCount(CustomerNo, 2);
        UpdateGeneralLedgerSetup(OldCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheFieldCustVendorBankWasAddedToReceivableCarteraDocs()
    var
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page "Receivables Cartera Docs" and ckeck visibility of "Cust./Vendor Bank Acc. Code" variable

        // [GIVEN] Enabled foundation setup   
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Page "Receivables Cartera Docs" is opened
        ReceivablesCarteraDocs.OpenEdit();

        // [THEN] The variable "Cust./Vendor Bank Acc. Code" is visible
        Assert.IsTrue(ReceivablesCarteraDocs."Cust./Vendor Bank Acc. Code".Visible(), '');
        ReceivablesCarteraDocs.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TheFieldCustVendorBankWasAddedToPayableCarteraDocs()
    var
        PayablesCarteraDocs: TestPage "Payables Cartera Docs";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] Open page "Payables Cartera Docs" and ckeck visibility of "Cust./Vendor Bank Acc. Code" variable

        // [GIVEN] Enabled foundation setup   
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Page "Payables Cartera Docs" is opened
        PayablesCarteraDocs.OpenEdit();

        // [THEN] The variable "Cust./Vendor Bank Acc. Code" is visible
        Assert.IsTrue(PayablesCarteraDocs."Cust./Vendor Bank Acc. Code".Visible(), '');
        PayablesCarteraDocs.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('TemplateSelectHandler')]
    [Scope('OnPrem')]
    procedure ExportOneBillOnPaymentJournalWhenMultipleLinesPostedOnCarteraJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
        VendorNo: Code[20];
        VendorPreferredBankAccountCode: Code[20];
    begin
        // [SCENARIO 575499] Exported to Payment File field is set to True in all Bills with the same document number when only one bill entry is exported in the payment journal

        // [GIVEN] Setup: Create vendor with preferred bank account and random amount
        VendorNo := CreateVendorWithPreferredBankAccount(VendorPreferredBankAccountCode);
        Amount := LibraryRandom.RandDecInDecimalRange(200, 200, 2);

        // [GIVEN] Create and Post Cartera Journal with multiple Lines.
        CreateAndPostMultipleCarteraJournalLines(GenJournalLine."Account Type"::Vendor, VendorNo, Amount);

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();

        // [WHEN] Create General Journal Line with Export Payments to File.
        CreateGenJournalLineWithExportPaymentsToFile(VendorNo, VendorPreferredBankAccountCode, Amount / 2, VendorLedgerEntry);

        // [THEN] Find Vendor Ledger Entry and verify that "Exported to Payment File" is false.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Exported to Payment File", false);
        VendorLedgerEntry.FindFirst();
        Assert.IsTrue(VendorLedgerEntry."Exported to Payment File" = false, ExportedToPaymentFileError);
    end;

    local procedure ApplyPaymentToSalesInvoice(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustomerLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(ApplyingCustomerLedgerEntry, AmountToApply);

        // Find Posted Customer Ledger Entries.
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Customer No.", ApplyingCustomerLedgerEntry."Customer No.");
        CustLedgerEntry.SetRange("Applying Entry", false);
        CustLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustomerLedgerEntry);
    end;

    local procedure ApplyPaymentToPurchaseInvoice(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, AmountToApply);

        // Find Posted Vendor Ledger Entries.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", ApplyingVendorLedgerEntry."Vendor No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendorLedgerEntry);
    end;

    local procedure CreateAndPostCarteraJournalLines(AccountType: Enum "Gen. Journal Account Type"; AppliesToDocNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create Multiple General Journal Line.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Cartera);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, AccountType,
          GenJournalLine."Applies-to Doc. Type"::Invoice, AccountNo, AppliesToDocNo, FindPaymentMethod(false, true), -Amount);  // False - Create Bills, TRUE - Invoices to Cartera.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Bill, AccountType, GenJournalLine."Applies-to Doc. Type"::" ",
          AccountNo, '', FindPaymentMethod(true, false), Amount);  // Blank as Apply - to Doc. No, TRUE - Create Bills, FALSE - Invoices to Cartera.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AppliesToDocNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, AccountType, GenJournalLine."Applies-to Doc. Type"::" ",
          AccountNo, AppliesToDocNo, FindPaymentMethod(true, false), -Amount);  // TRUE - Create Bills, FALSE - Invoices to Cartera.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostMultipleCarteraJournalLines(AccountType: Enum "Gen. Journal Account Type"; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    begin
        CreateAndPostCarteraJournalLines(AccountType, DocumentNo, AccountNo, Amount);
        CreateAndPostCarteraJournalLines(AccountType, DocumentNo, AccountNo, Amount / LibraryRandom.RandInt(10));
    end;

    local procedure CreateAndPostCarteraJournalBillTransform(AccountType: Enum "Gen. Journal Account Type"; AppliesToDocNo: Code[20]; AccountNo: Code[20]; Amount1: Decimal; Amount2: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create Multiple General Journal Line.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Cartera);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, AccountType,
            GenJournalLine."Applies-to Doc. Type"::Invoice, AccountNo, AppliesToDocNo, FindPaymentMethod(false, true), -(Amount1 + Amount2));
        // False - Create Bills, TRUE - Invoices to Cartera.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Bill, AccountType,
          GenJournalLine."Applies-to Doc. Type"::" ", AccountNo, '', FindPaymentMethod(true, false), Amount1);
        // False - Create Bills, TRUE - Invoices to Cartera.
        GenJournalLine.Validate("Bill No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Bill, AccountType,
          GenJournalLine."Applies-to Doc. Type"::" ", AccountNo, '', FindPaymentMethod(true, false), Amount2);
        // Blank as Apply - to Doc. No, TRUE - Create Bills, FALSE - Invoices to Cartera.
        GenJournalLine.Validate("Bill No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Random - Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Random - Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        // Create Currency Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
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

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; PaymentMethodCode: Code[10]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Payment Method Code", PaymentMethodCode);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Bill No.", Format(LibraryRandom.RandInt(1000)));
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure FindCurrencyFactor(CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure ModifyExchangeRate(CurrencyCode: Code[20]; NewRate: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindLast();
        CurrencyExchangeRate.Validate("Exchange Rate Amount", NewRate);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 1);
        CurrencyExchangeRate.Modify();
    end;

    local procedure FindPaymentMethod(CreateBills: Boolean; InvoicesToCartera: Boolean): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", CreateBills);
        PaymentMethod.SetRange("Invoices to Cartera", InvoicesToCartera);
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure UpdateGeneralLedgerSetup(AdditionalReportingCurrency: Code[10]) OldAdditionalReportingCurrency: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAdditionalReportingCurrency := GeneralLedgerSetup."Additional Reporting Currency";
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;  // To Avoid Report Handler - Additional Reporting Currency.
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyBaseAndAmountOnVATEntry(DocumentNo: Code[20]; Base: Decimal; VATPct: Decimal; AdditionalCurrencyBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(-Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(-Base * VATPct / 100, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          -AdditionalCurrencyBase, VATEntry."Additional-Currency Base", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          -AdditionalCurrencyBase * VATPct / 100, VATEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(),
          ValueMustBeEqualMsg);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustBeEqualMsg);
    end;

    local procedure VerifyVATAndGLEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; Amount: Decimal; VATPct: Decimal; AdditionalCurrencyAmount: Decimal)
    begin
        VerifyBaseAndAmountOnVATEntry(DocumentNo, Amount, VATPct, AdditionalCurrencyAmount);
        VerifyAmountOnGLEntry(DocumentNo2, Amount, AdditionalCurrencyAmount);
    end;

    local procedure VerifyBillCount(CustomerNo: Code[20]; ExpectedBillCount: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(ExpectedBillCount, CustLedgerEntry.Count, WrongNoOfCustLedgEntryErr);
    end;

    local procedure CreateVendorWithPreferredBankAccount(var PreferredBankAccountCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PreferredBankAccountCode := CreateVendorBankAccountNo(Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", PreferredBankAccountCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccountNo(VendorNo: Code[20]): Code[20]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(IBAN), Database::"Vendor Bank Account");
        VendorBankAccount.Modify(true);
        exit(VendorBankAccount.Code);
    end;

    local procedure CreateGenJournalLineWithExportPaymentsToFile(VendorNo: Code[20]; VendorPreferredBankAccountCode: Code[20]; Amount: Decimal; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        PaymentJournal: TestPage "Payment Journal";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Recipient Bank Account", VendorPreferredBankAccountCode);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Validate("Applies-to Bill No.", VendorLedgerEntry."Bill No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount(FindSEPACTExportFormat()));
        GenJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");

        PaymentJournal.OpenEdit();
        PaymentJournal.GotoRecord(GenJournalLine);
        PaymentJournal.ExportPaymentsToFile.Invoke();
        PaymentJournal.Close();
    end;

    local procedure FindSEPACTExportFormat(): Code[20]
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"SEPA CT-Export File");
        BankExportImportSetup.FindFirst();
        exit(BankExportImportSetup.Code);
    end;

    local procedure CreateBankAccount(PaymentExportFormat: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, ''); // blank currency code
        BankAccount.IBAN := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(IBAN), DATABASE::"Bank Account");
        BankAccount."SWIFT Code" := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("SWIFT Code"), DATABASE::"Bank Account");
        BankAccount.Validate("Payment Export Format", PaymentExportFormat);
        BankAccount.Validate("Credit Transfer Msg. Nos.", CreateNoSeries());
        BankAccount.Validate("E-Pay Export File Path", '');
        BankAccount.Validate("Last E-Pay Export File Name", 'ABC001.txt');
        BankAccount.Validate("Last Remittance Advice No.", '1');
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', ''); // numbering is not important
        exit(NoSeries.Code);
    end;

    local procedure CreateAndPostMultipleCarteraJournalLines(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // Create Multiple General Journal Line.
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Cartera);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLineWithBalancingAccount(
            GenJournalLine, GenJournalBatch, DocumentNo, GenJournalLine."Document Type"::Invoice, AccountType,
            AccountNo, FindPaymentMethod(false, true), -Amount, '', GLAccount."No.");
        CreateGeneralJournalLineWithBalancingAccount(
            GenJournalLine, GenJournalBatch, DocumentNo, GenJournalLine."Document Type"::Bill, AccountType,
            AccountNo, FindPaymentMethod(true, false), -Amount / 2, '1', GLAccount."No.");
        CreateGeneralJournalLineWithBalancingAccount(
            GenJournalLine, GenJournalBatch, DocumentNo, GenJournalLine."Document Type"::Bill, AccountType,
            AccountNo, FindPaymentMethod(true, false), -Amount / 2, '2', GLAccount."No.");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLineWithBalancingAccount(
        var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; var DocumentNo: Code[20];
        DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20]; PaymentMethodCode: Code[10]; Amount: Decimal; BillNo: Code[20]; BalancingAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, AccountType, AccountNo, Amount);
        if DocumentNo = '' then
            DocumentNo := GenJournalLine."Document No."
        else begin
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.validate("External Document No.", DocumentNo);
        end;
        GenJournalLine.Validate("Payment Method Code", PaymentMethodCode);
        GenJournalLine.Validate("Bill No.", BillNo);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalancingAccountNo);
        GenJournalLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.FILTER.SetFilter(Name, LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;
}

