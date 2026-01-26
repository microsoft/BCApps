codeunit 144108 "ERM Service Invoice ES"
{
    // // [FEATURE] [Service] [Invoice]
    //
    // Test for Feature: SERVINV - Service Invoice.
    //  1. Test to verify Credit Memo with marked Calc. Pmt. Disc. on Cr. Memos posted successfully.
    //  2. Test to verify Credit Memo with unmarked Calc. Pmt. Disc. on Cr. Memos posted successfully.
    //  3. Test to verify Program allows to enter invoice discount manually on Service invoice if Type is G/L Account and also update Allow Invoice Disc as TRUE on Service Line.
    //  4. Test to verify Program populates the due date on posted service invoice which value defined on the Service Order while doing posting the Invoice.
    //  5. Test to verify Service Credit Memo posted successfully with filling Applies-to ID automatically.
    //  6. Test to verify Service Credit Memo posted successfully with filling Applies-to Doc. No manually.
    //  7. Test to verify Service Credit Memo posted successfully with filling Applies-to Doc. No automatically.
    //  8. Test to verify corrective service credit memo of a posted service invoice.
    //  9. Test to verify statistics on posted service invoice when posting service invoice with FCY.
    // 10. Test to verify statistics on posted service invoice when posting service invoice with LCY.
    // 11. Test to verify Due Date calculation with the creating bills in Service Invoice.
    // 12. Test to verify Due Date calculation with the creating bills in Purchase Invoice.
    // 14. Test to verify Due Date calculation with the creating bills in Sales Invoice.
    //
    //   Covers Test Cases for WI -349751.
    //   ------------------------------------------------------------------------------------------
    //   Test Function Name                                                                 TFS ID
    //   ------------------------------------------------------------------------------------------
    //   PostedServiceInvoiceWithCalcPmtDiscOnCrMemosTrue                                    155674
    //   PostedServiceInvoiceWithCalcPmtDiscOnCrMemosFalse                                   155675
    //   ManualInvoiceDiscountAmountAllowInvoiceDiscountTrue                          262703,261339
    //   ManualDueDateUpdatedOnServiceInvoice                                                266484
    //   ServiceCreditMemoApplyEntries                                                       155709
    //   ServiceCreditMemoApplyEntriesManually                                               155707
    //   ServiceCreditMemoApplyEntriesWithLookup                                             155708
    //   PostedServiceInvoiceFindCorrectiveInvoices                                          155382
    //   StatisticsForPostedServiceInvoiceWithCurrency                                       155459
    //   StatisticsForPostedServiceInvoiceWithoutCurrency                                    155458
    //
    //   Covers Test Cases for WI -349942.
    //   ------------------------------------------------------------------------------------------
    //   Test Function Name                                                                 TFS ID
    //   ------------------------------------------------------------------------------------------
    //   CarteraDocForMultipleInstallmentsForServiceInvoice                                  205258
    //   CarteraDocForMultipleInstallmentsForPurchInvoice                                    205257
    //   CarteraDocForMultipleInstallmentsForSalesInvoice                                    205256

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RecordMustExistMsg: Label 'Record must exist';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceWithCalcPmtDiscOnCrMemosTrue()
    begin
        // Test to verify Credit Memo with marked Calc. Pmt. Disc. on Cr. Memos posted successfully.
        PostedServiceInvoiceWithCalcPmtDiscOnCrMemos(true);  // Calculate Payment Discount on Credit Memos - TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceWithCalcPmtDiscOnCrMemosFalse()
    begin
        // Test to verify Credit Memo with unmarked Calc. Pmt. Disc. on Cr. Memos posted successfully.
        PostedServiceInvoiceWithCalcPmtDiscOnCrMemos(false);  // Calculate Payment Discount on Credit Memos - FALSE.
    end;

    local procedure PostedServiceInvoiceWithCalcPmtDiscOnCrMemos(CalcPmtDiscOnCrMemos: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        // Setup: Create Service Invoice. Update Calculate Payment Discount on Credit Memos on Payment Terms. Create Service Credit Memo with Corrective Invoice.
        Initialize();
        UpdateSalesReceivablesSetupCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateCustomer(Customer, '');  // Country/Region - Blank.
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        UpdatePaymentTermsCalcPmtDiscOnCrMemos(Customer."Payment Terms Code", CalcPmtDiscOnCrMemos);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceLine.Type::Item, Customer."No.", ServiceLine."No.");
        UpdateServiceHeaderCorrectedInvoiceNo(ServiceLine."Document No.", FindServiceInvoiceHeader(Customer."No."));

        // Exercise: Post Service Credit Memo.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Service Credit Memo created successfully.
        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(ServiceCrMemoHeader.FindFirst(), RecordMustExistMsg);
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure ManualInvoiceDiscountAmountAllowInvoiceDiscountTrue()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Test to verify Program allows to enter Invoice Discount manually on Service Invoice if Type is G/L Account and also update Allow Invoice Disc as TRUE on Service Line.

        // Setup: Create Service Invoice, update Allow Invoice Discount - TRUE on Service Line. Open Statistics and update Invoice Discount Amount on it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceLine.Type::"G/L Account", Customer."No.", CreateGLAccount());
        UpdateServiceLineAllowInvoiceDisc(ServiceLine);
        InvoiceDiscountAmount := LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);  // Required inside ServiceStatisticsPageHandler.
        InvokeStatisticsOnServiceInvoice(Customer."No.");  // Opens ServiceStatisticsPageHandler.

        // Exercise: Post Service Invoice.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify G/L entry created after considering Invoice Discount Amount.
        VerifyGLEntry(ServiceLine."No.", -(ServiceLine.Amount - InvoiceDiscountAmount));
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure ManualInvoiceDiscountAmountAllowInvoiceDiscountTrueNM()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Test to verify Program allows to enter Invoice Discount manually on Service Invoice if Type is G/L Account and also update Allow Invoice Disc as TRUE on Service Line.

        // Setup: Create Service Invoice, update Allow Invoice Discount - TRUE on Service Line. Open Statistics and update Invoice Discount Amount on it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceLine.Type::"G/L Account", Customer."No.", CreateGLAccount());
        UpdateServiceLineAllowInvoiceDisc(ServiceLine);
        InvoiceDiscountAmount := LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);  // Required inside ServiceStatisticsPageHandler.
        InvokeStatisticsOnServiceInvoiceNM(Customer."No.");  // Opens ServiceStatisticsPageHandler.

        // Exercise: Post Service Invoice.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify G/L entry created after considering Invoice Discount Amount.
        VerifyGLEntry(ServiceLine."No.", -(ServiceLine.Amount - InvoiceDiscountAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDueDateUpdatedOnServiceInvoice()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DueDate: Date;
    begin
        // Test to verify Program populates the due date on Posted Service Invoice which value defined on the Service Order while doing posting the Invoice.

        // Setup: Create Service Invoice with Payment terms. Change Due Date on Service Header.
        Initialize();
        CreateCustomer(Customer, '');  // Country/Region - Blank.
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        DueDate := UpdateServiceHeaderDueDate(ServiceLine."Document No.");

        // Exercise: Post Service Invoice.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Due Date on Posted Service Invoice and Customer Ledger Entry.
        ServiceInvoiceHeader.Get(FindServiceInvoiceHeader(Customer."No."));
        ServiceInvoiceHeader.TestField("Due Date", DueDate);
        VerifyCustLedgerEntryDueDate(Customer."No.", DueDate);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithAppliesToIDPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoApplyEntries()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test to verify Service Credit Memo posted successfully with Applies-to ID filled automatically.

        // Setup: Create and Post Service Invoice. Create Service Credit Memo and Apply Entries of Posted Invoice.
        Initialize();
        CompanyInformation.Get();
        CreateCustomer(Customer, CompanyInformation."Country/Region Code");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::"Credit Memo", ServiceLine.Type::Item, Customer."No.", ServiceLine."No.");
        UpdateServiceHeaderAppliesToDoc(ServiceLine."Document No.", '');  // Blank Applies To Document No.
        OpenServiceCreditMemo(ServiceCreditMemo, Customer."No.");
        ServiceCreditMemo.ApplyEntries.Invoke();  // Opens ApplyCustomerEntriesWithAppliesToIDPageHandler.

        // Exercise: Post Service Credit Memo.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Customer Ledger Entry created with Remaining Amount - 0.
        VerifyCustomerLedgerEntry(Customer."No.");
        ServiceCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoApplyEntriesManually()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // Test to verify Service Credit Memo posted successfully with Applies-to Doc. No. filled manually.

        // Setup: Create and Post Service Invoice. Create Service Credit Memo and Applies to Document No. manually.
        Initialize();
        CompanyInformation.Get();
        CreateCustomer(Customer, CompanyInformation."Country/Region Code");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::"Credit Memo", ServiceLine.Type::Item, Customer."No.", ServiceLine."No.");
        UpdateServiceHeaderAppliesToDoc(ServiceLine."Document No.", FindServiceInvoiceHeader(Customer."No."));

        // Exercise: Post Service Credit Memo.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Customer Ledger Entry created with Remaining Amount - 0.
        VerifyCustomerLedgerEntry(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoApplyEntriesWithLookup()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test to verify Service Credit Memo posted successfully with Applies-to Doc. No. filled automatically.

        // Setup: Create and Post Service Invoice. Create Service Credit Memo and Applies to Document No. automatically through Lookup.
        Initialize();
        CompanyInformation.Get();
        CreateCustomer(Customer, CompanyInformation."Country/Region Code");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::"Credit Memo", ServiceLine.Type::Item, Customer."No.", ServiceLine."No.");
        UpdateServiceHeaderAppliesToDoc(ServiceLine."Document No.", '');  // Blank Applies To Document No.
        OpenServiceCreditMemo(ServiceCreditMemo, Customer."No.");
        ServiceCreditMemo."Applies-to Doc. No.".Lookup();  // Opens ApplyCustomerEntriesPageHandler.
        ServiceCreditMemo.OK().Invoke();

        // Exercise: Post Service Credit Memo.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Customer Ledger Entry created with Remaining Amount - 0.
        VerifyCustomerLedgerEntry(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceFindCorrectiveInvoices()
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
    begin
        // Test to verify corrective Service Credit Memo of a Posted Service Invoice.

        // Setup: Create and Post Service Invoice, create Service Credit Memo, update Posted Service Invoice as Corrective Invoice and Post Service Credit Memo.
        Initialize();
        CompanyInformation.Get();
        CreateCustomer(Customer, CompanyInformation."Country/Region Code");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceLine.Type::Item, Customer."No.", ServiceLine."No.");
        UpdateServiceHeaderCorrectedInvoiceNo(ServiceLine."Document No.", FindServiceInvoiceHeader(Customer."No."));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        PostedServiceCreditMemos.Trap();

        // Exercise: Invoke Find Corrective Invoices on Posted Service Invoice.
        FindCorrectiveInvoicesOnPostedServiceInvoice(Customer."No.");

        // Verify: Verify Posted Service Credit Memo opened from Find Corrective Invoice.
        PostedServiceCreditMemos."No.".AssertEquals(FindServiceCrMemoHeader(Customer."No."));
        PostedServiceCreditMemos."Customer No.".AssertEquals(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatisticsForPostedServiceInvoiceWithCurrency()
    begin
        // Test to verify statistics on Posted Service Invoice when posting Service Invoice with FCY.
        Initialize();
        StatisticsForPostedServiceInvoice(CreateCurrencyExchangeRate());  // Customer with Currency.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatisticsForPostedServiceInvoiceWithoutCurrency()
    begin
        // Test to verify statistics on Posted Service Invoice when posting Service Invoice with LCY.
        Initialize();
        StatisticsForPostedServiceInvoice('');  // Customer with blank Currency.
    end;

    local procedure StatisticsForPostedServiceInvoice(CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup: Create multiline Service Invoice.
        Initialize();
        CreateCustomer(Customer, '');  // Country/Region - Blank.
        UpdateCustomer(VATPostingSetup, CurrencyCode, Customer."No.");
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceLine(
          ServiceLine2, ServiceLine."Document Type", ServiceHeader."No.", ServiceLine2.Type::Item, LibraryInventory.CreateItem(Item));

        // Exercise: Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Verify: Verify VAT Amount Line.
        VerifyVATAmountLine(Customer."No.", VATPostingSetup."VAT %", VATPostingSetup."EC %", ServiceLine.Amount, ServiceLine2.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarteraDocForMultipleInstallmentsForServiceInvoice()
    var
        Item: Record Item;
        PaymentTerms: Record "Payment Terms";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustomerNo: Code[20];
    begin
        // Test to verify Due Date calculation with the creating bills in Service Invoice.

        // Setup: Create Multiple Installments for Payment Terms, create Customer with Payment Day and create Service Invoice.
        Initialize();
        CustomerNo := CreateCustomerPaymentDayWithMultipleInstallmentsSetup(PaymentTerms);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceLine.Type::Item, CustomerNo, LibraryInventory.CreateItem(Item));

        // Exercise: Post Service Invoice.
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Due Date on Cartera Document for Multiple Installments.
        ServiceInvoiceHeader.Get(FindServiceInvoiceHeader(CustomerNo));
        VerifyCarteraDocument(PaymentTerms, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarteraDocForMultipleInstallmentsForPurchInvoice()
    var
        PaymentTerms: Record "Payment Terms";
        PaymentDay: Record "Payment Day";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // Test to verify Due Date calculation with the creating bills in Purchase Invoice.

        // Setup: Create Multiple Installments for Payment Terms. Create Vendor with Payment Day.
        Initialize();
        CreateMultipleInstallmentForPaymentTerms(PaymentTerms);
        LibraryESLocalization.CreatePaymentDay(
          PaymentDay, PaymentDay."Table Name"::Vendor, CreateVendor(PaymentTerms.Code), LibraryRandom.RandIntInRange(10, 20));  // Random Payment Day.

        // Exercise: Create and Post Purchase Invoice.
        DocumentNo := CreateAndPostPurchaseInvoice(PaymentDay.Code);

        // Verify: Verify Due Date on Cartera Document for Multiple Installments.
        PurchInvHeader.Get(DocumentNo);
        VerifyCarteraDocument(PaymentTerms, PurchInvHeader."No.", PurchInvHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarteraDocForMultipleInstallmentsForSalesInvoice()
    var
        PaymentTerms: Record "Payment Terms";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Test to verify Due Date calculation with the creating bills in Sales Invoice.

        // Setup: Create Multiple Installments for Payment Terms. Create Customer with Payment Day.
        Initialize();
        CustomerNo := CreateCustomerPaymentDayWithMultipleInstallmentsSetup(PaymentTerms);

        // Exercise: Create and Post Sales Invoice.
        DocumentNo := CreateAndPostSalesInvoice(CustomerNo);

        // Verify: Verify Due Date on Cartera Document for Multiple Installments.
        SalesInvoiceHeader.Get(DocumentNo);
        VerifyCarteraDocument(PaymentTerms, SalesInvoiceHeader."No.", SalesInvoiceHeader."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceWithShipmentMethodCode()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ShipmentMethodCode: Code[10];
    begin
        // [SCENARIO 212181] Shipment Method Code should be updated on Item Ledger Entry when post Service Invoice
        Initialize();

        // [GIVEN] Service Invoice with Shipment Method Code = "SM"
        UpdateSalesReceivablesSetupCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateCustomer(Customer, '');
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::Invoice, ServiceLine.Type::Item, Customer."No.", LibraryInventory.CreateItem(Item));
        ShipmentMethodCode := UpdateShipmentMethodOnServiceHeader(ServiceLine);

        // [WHEN] Post Service Invoice
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");

        // [THEN] Item Ledger Entry is posted with Shipment Method Code = "SM"
        ItemLedgerEntry.SetRange("Source No.", Customer."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Shpt. Method Code", ShipmentMethodCode);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();

        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CountryRegionCode: Code[10])
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegionCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Validate("Payment Method Code", FindPaymentMethod());
        Customer.Validate("VAT Registration No.", VATRegistrationNoFormat.Format);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms());
        Customer.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; Type: Enum "Service Line Type"; CustomerNo: Code[20]; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        CreateServiceLine(ServiceLine, DocumentType, ServiceHeader."No.", Type, No);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(DocumentType, DocumentNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SelectVATPostingSetup());
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", (Format(LibraryRandom.RandIntInRange(5, 10)) + 'M'));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCurrencyExchangeRate(): Code[10]
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

    local procedure CreateVendor(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Validate("Payment Method Code", FindPaymentMethod());
        Vendor.Validate("Payment Days Code", Vendor."No.");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateInstallment(PaymentTerms: Record "Payment Terms"; PctOfTotal: Decimal)
    var
        Installment: Record Installment;
    begin
        LibraryESLocalization.CreateInstallment(Installment, PaymentTerms.Code);
        Installment.Validate("% of Total", PctOfTotal);
        Installment.Validate("Gap between Installments", Format(PaymentTerms."Due Date Calculation"));
        Installment.Modify(true);
    end;

    local procedure CreateMultipleInstallmentForPaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        PaymentTerms.Get(CreatePaymentTerms());
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Modify(true);

        // Sum of Percentage of Totals for Installments should not be equal to greater than 100.
        CreateInstallment(PaymentTerms, LibraryRandom.RandIntInRange(30, 40));
        CreateInstallment(PaymentTerms, LibraryRandom.RandIntInRange(20, 30));
        CreateInstallment(PaymentTerms, LibraryRandom.RandIntInRange(10, 20));
    end;

    local procedure CreateAndPostPurchaseInvoice(BuyFromVendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(SellToCustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerPaymentDayWithMultipleInstallmentsSetup(var PaymentTerms: Record "Payment Terms"): Code[20]
    var
        Customer: Record Customer;
        PaymentDay: Record "Payment Day";
    begin
        CreateMultipleInstallmentForPaymentTerms(PaymentTerms);
        CreateCustomer(Customer, '');  // Country/Region - Blank.
        UpdateCustomerPaymentCode(Customer, PaymentTerms.Code);
        LibraryESLocalization.CreatePaymentDay(
          PaymentDay, PaymentDay."Table Name"::Customer, Customer."No.", LibraryRandom.RandIntInRange(10, 20));  // Random Payment Day.
        exit(Customer."No.");
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", true);
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindCorrectiveInvoicesOnPostedServiceInvoice(CustomerNo: Code[20])
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("Customer No.", CustomerNo);
        PostedServiceInvoice.FindCorrectiveInvoices.Invoke();
    end;

    local procedure FindServiceInvoiceHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure FindServiceCrMemoHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;
#if not CLEAN27
    local procedure InvokeStatisticsOnServiceInvoice(CustomerNo: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("Customer No.", CustomerNo);
        ServiceInvoice.Statistics.Invoke();
    end;
#endif
    local procedure InvokeStatisticsOnServiceInvoiceNM(CustomerNo: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("Customer No.", CustomerNo);
        ServiceInvoice.ServiceStatistics.Invoke();
    end;

    local procedure OpenServiceCreditMemo(var ServiceCreditMemo: TestPage "Service Credit Memo"; CustomerNo: Code[20])
    begin
        Commit();  // Commit Required.
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("Customer No.", CustomerNo);
    end;

    local procedure PostServiceDocument(DocumentType: Enum "Service Document Type"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(DocumentType, No);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure UpdateSalesReceivablesSetupCreditWarnings(NewCreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateServiceLineAllowInvoiceDisc(ServiceLine: Record "Service Line")
    begin
        ServiceLine.Validate("Allow Invoice Disc.", true);
        ServiceLine.Modify(true);
    end;

    local procedure UpdatePaymentTermsCalcPmtDiscOnCrMemos(PaymentTermsCode: Code[10]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", CalcPmtDiscOnCrMemos);
        PaymentTerms.Modify(true);
    end;

    local procedure UpdateServiceHeaderCorrectedInvoiceNo(No: Code[20]; CorrectedInvoiceNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", No);
        ServiceHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateServiceHeaderAppliesToDoc(No: Code[20]; AppliesToDocNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", No);
        ServiceHeader.Validate("Applies-to Doc. Type", ServiceHeader."Applies-to Doc. Type"::Bill);
        ServiceHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateServiceHeaderDueDate(No: Code[20]): Date
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, No);
        ServiceHeader.Validate("Due Date", CalcDate(Format(LibraryRandom.RandIntInRange(5, 10)) + 'M', WorkDate()));
        ServiceHeader.Modify(true);
        exit(ServiceHeader."Due Date");
    end;

    local procedure UpdateCustomer(var VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; No: Code[20])
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        Customer.Get(No);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("EC %", LibraryRandom.RandInt(10));
        VATPostingSetup.Modify(true);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
    end;

    local procedure UpdateCustomerPaymentCode(Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Payment Days Code", Customer."No.");
        Customer.Modify(true);
    end;

    local procedure UpdateShipmentMethodOnServiceHeader(ServiceLine: Record "Service Line"): Code[10]
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceHeader.Validate("Shipment Method Code", LibraryUtility.CreateCodeRecord(DATABASE::"Shipment Method"));
        ServiceHeader.Modify(true);
        exit(ServiceHeader."Shipment Method Code");
    end;

    local procedure SelectVATPostingSetup(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);
    end;

    local procedure VerifyCustLedgerEntryDueDate(CustomerNo: Code[20]; DueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Due Date", DueDate);
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyVATAmountLine(CustomerNo: Code[20]; VATPct: Decimal; ECPct: Decimal; Amount: Decimal; Amount2: Decimal)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        ServiceInvoiceHeader.Get(FindServiceInvoiceHeader(CustomerNo));
        ServiceInvoiceLine.CalcVATAmountLines(ServiceInvoiceHeader, VATAmountLine);
        VATAmountLine.TestField("VAT %", VATPct);
        VATAmountLine.TestField("EC %", ECPct);
        VATAmountLine.TestField("Line Amount", Amount + Amount2);
        VATAmountLine.TestField("VAT Base", Amount + Amount2);
        VATAmountLine.TestField("VAT Amount", Round(VATPct / 100 * (Amount + Amount2)));
        VATAmountLine.TestField("EC Amount", Round(ECPct / 100 * (Amount + Amount2)));
    end;

    local procedure VerifyCarteraDocument(PaymentTerms: Record "Payment Terms"; DocumentNo: Code[20]; DueDate: Date)
    var
        CarteraDoc: Record "Cartera Doc.";
        Counter: Integer;
    begin
        // Verify Due Date for multiple Installments.
        for Counter := 1 to PaymentTerms."No. of Installments" do begin
            CarteraDoc.SetRange("Document No.", DocumentNo);
            CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Bill);
            CarteraDoc.SetRange("No.", Format(Counter));
            CarteraDoc.FindFirst();
            CarteraDoc.TestField("Due Date", DueDate);
            DueDate := CalcDate(PaymentTerms."Due Date Calculation", DueDate);
        end;
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        InvDiscountAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        ServiceStatistics."Inv. Discount Amount_General".SetValue(InvDiscountAmount);
        ServiceStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandlerNM(var ServiceStatistics: TestPage "Service Statistics")
    var
        InvDiscountAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvDiscountAmount);
        ServiceStatistics."Inv. Discount Amount_General".SetValue(InvDiscountAmount);
        ServiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithAppliesToIDPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;
}
