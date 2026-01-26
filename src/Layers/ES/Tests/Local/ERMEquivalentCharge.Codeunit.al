codeunit 144047 "ERM Equivalent Charge"
{
    // Feature covered - EQUIVCHRG
    // 
    // 1. Verify VAT Amount on Purchase - Credit Memo report.
    // 2. Verify Customer No. on Reminder - Test Report.
    // 3. Verify Total EUR Excl. VAT and Total EUR Incl. VAT on Sales Return Order Confirmation Report.
    // 4. Verify GL Entry after post vendor application with FCY Vendor.
    // 5. Verify GL Entry after post customer application with FCY Customer.
    // 
    // Covers Test Cases for WI: 351893
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                          TFS ID
    // ----------------------------------------------------------------------------------
    // PurchaseCreditMemoReportWithVATAmount                                       152689
    // ReminderTestReportWithCustomerNo                                            155487
    // SalesRetOrderConfirmationReport                                             265519
    // ApplicationOnPaymentEntryWithFCYVendor                                      202080
    // ApplicationOnPaymentEntryWithFCYCustomer                                    202081

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
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ReminderHeaderCustomerNoCap: Label 'Reminder_Header___Customer_No__';
        TotaVATAmtCap: Label 'TotalAmountVAT';
        EURAmtExclVATCap: Label 'TotalAmount';
        EURAmtInclVATCap: Label 'TotalAmountInclVAT';
        ValueMustBeMatchMsg: Label 'Value must be match with Expected value.';
        VATAmtCap: Label 'VATAmount';

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportWithVATAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // Verify VAT Amount on Purchase - Credit Memo report.

        // Setup: Create and post Purchase Invoice and Credit Memo.
        Initialize();
        InvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseHeader."Document Type"::Invoice,
            CreateVendor(''), '', LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(10, 2), CreateItem());  // Using blank for Currency Code & Corrected Invoice No., Random for Quantity & Direct Unit Cost.
        CrMemoNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine2, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", InvoiceNo,
            PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost", PurchaseLine."No.");
        LibraryVariableStorage.Enqueue(CrMemoNo);  // Enqueue for PurchaseCreditMemoRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Credit Memo");

        // Verify: Verify VAT Amount on Purchase - Credit Memo report.
        VerifyReportValue(TotaVATAmtCap, PurchaseLine2."Amount Including VAT" - PurchaseLine2."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ReminderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderTestReportWithCustomerNo()
    var
        ReminderHeader: Record "Reminder Header";
    begin
        // Verify Customer No. on Reminder - Test Report.

        // Setup: Create Reminder Header with Customer No.
        Initialize();
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CreateCustomer(''));  // Using blank for Currency Code.
        ReminderHeader.Modify(true);
        LibraryVariableStorage.Enqueue(ReminderHeader."No.");  // Enqueue for ReminderTestRequestPageHandler.
        Commit();  // Commit required for run Reminder - Test Report.

        // Exercise.
        REPORT.Run(REPORT::"Reminder - Test");

        // Verify: Verify Customer No. on Reminder - Test Report.
        VerifyReportValue(ReminderHeaderCustomerNoCap, ReminderHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ReturnOrderConfirmationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrderConfirmationReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify Total EUR Excl. VAT and Total EUR Incl. VAT on Sales Return Order Confirmation Report.

        // Setup: Create Sales Return Order with multiple line.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer(''));  // Using blank for Currency Code.
        CreateSalesLine(SalesLine, SalesHeader);
        CreateSalesLine(SalesLine2, SalesHeader);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");  // Enqueue for ReturnOrderConfirmationRequestPageHandler.
        Commit();  // Commit required for run Return Order Confirmation Report.

        // Exercise.
        REPORT.Run(REPORT::"Return Order Confirmation");

        // Verify: Verify Total EUR Excl. VAT and Total EUR Incl. VAT on Sales Return Order Confirmation Report.
        VerifyReportValue(EURAmtExclVATCap, SalesLine."Line Amount" + SalesLine2."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          VATAmtCap, SalesLine."Amount Including VAT" - SalesLine."Line Amount" +
          SalesLine2."Amount Including VAT" - SalesLine2."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(
          EURAmtInclVATCap, SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplicationOnPaymentEntryWithFCYVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        PostedInvoiceNo: Code[20];
        PostedInvoiceNo2: Code[20];
    begin
        // Verify GL Entry after post vendor application with FCY Vendor.

        // Setup: Create and post Purchsae Invoices, post Payment Journal and application.
        Initialize();
        Vendor.Get(CreateVendor(CreateCurrency()));
        PostedInvoiceNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Invoice, Vendor."No.", '', LibraryRandom.RandDec(100, 2),
            LibraryRandom.RandDec(10, 2), CreateItem());  // Using blank for Corrected Invoice No., Random for Quantity & Direct Unit Cost.
        PostedInvoiceNo2 :=
          CreateAndPostPurchaseDocument(
            PurchaseLine2, PurchaseLine2."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", '', PurchaseLine.Quantity,
            LibraryRandom.RandDec(10, 2), CreateItem());  // Using blank for Corrected Invoice No., Random for Direct Unit Cost.
        CreateAndPostPaymentJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."Amount Including VAT" / 2);  // Partial payment.
        CreateAndPostPaymentJournal(
          GenJournalLine2, GenJournalLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
          PurchaseLine2."Amount Including VAT" / 2);  // Partial payment.
        SetApplyAndPostVendorEntry(GenJournalLine."Document No.", PurchaseLine."Amount Including VAT" / 2);  // Partial payment.

        // Exercise.
        SetApplyAndPostVendorEntry(GenJournalLine2."Document No.", PurchaseLine2."Amount Including VAT" / 2);  // Partial payment.

        // Verify: Verify GL Entry after post vendor application.
        VerifyGLEntry(
          PurchaseLine."Currency Code", PostedInvoiceNo,
          PurchaseLine."Amount Including VAT");
        VerifyGLEntry(
          PurchaseLine2."Currency Code", PostedInvoiceNo2,
          PurchaseLine2."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplicationOnPaymentEntryWithFCYCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PostedInvoiceNo: Code[20];
        PostedInvoiceNo2: Code[20];
    begin
        // Verify GL Entry after post customer application with FCY Customer.

        // Setup: Create and post Sales Invoices, post Payment Journal and application.
        Initialize();
        Customer.Get(CreateCustomer(CreateCurrency()));
        PostedInvoiceNo := CreateAndPostSalesInvoice(SalesLine, Customer."No.");
        PostedInvoiceNo2 := CreateAndPostSalesInvoice(SalesLine2, SalesLine."Sell-to Customer No.");
        CreateAndPostPaymentJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
          -SalesLine."Amount Including VAT" / 2);  // Partial payment.
        CreateAndPostPaymentJournal(
          GenJournalLine2, GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
          -SalesLine2."Amount Including VAT" / 2);  // Partial payment.
        SetApplyAndPostCustomerEntry(GenJournalLine."Document No.", SalesLine."Amount Including VAT" / 2);  // Partial payment.

        // Exercise.
        SetApplyAndPostCustomerEntry(GenJournalLine2."Document No.", SalesLine2."Amount Including VAT" / 2);  // Partial payment.

        // Verify: Verify GL Entry after post customer application.
        VerifyGLEntry(
          SalesLine."Currency Code", PostedInvoiceNo, SalesLine."Amount Including VAT");
        VerifyGLEntry(
          SalesLine2."Currency Code", PostedInvoiceNo2, SalesLine2."Amount Including VAT");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostPaymentJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; CorrectedInvoiceNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // TRUE - Receive & Invoice
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        CreateSalesLine(SalesLine, SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // TRUE - Ship & Invoice
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
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

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Using Random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
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

    local procedure SetApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        ApplyingCustomerLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(ApplyingCustomerLedgerEntry, ApplyingCustomerLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(ApplyingCustomerLedgerEntry, -AmountToApply);

        // Find Posted Invoice Customer Ledger Entry.
        CustomerLedgerEntry.SetRange("Document Type", CustomerLedgerEntry."Document Type"::Invoice);
        CustomerLedgerEntry.SetRange("Customer No.", ApplyingCustomerLedgerEntry."Customer No.");
        CustomerLedgerEntry.SetRange("Applying Entry", false);
        CustomerLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustomerLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustomerLedgerEntry);
    end;

    local procedure SetApplyAndPostVendorEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        ApplyingVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(ApplyingVendorLedgerEntry, ApplyingVendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyVendorEntry(ApplyingVendorLedgerEntry, AmountToApply);

        // Find Posted Invoice Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Vendor No.", ApplyingVendorLedgerEntry."Vendor No.");
        VendorLedgerEntry.SetRange("Applying Entry", false);
        VendorLedgerEntry.FindFirst();

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendorLedgerEntry);
    end;

    local procedure VerifyGLEntry(CurrencyCode: Code[10]; DocumentNo: Code[20]; Amount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        DebitAmount: Decimal;
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            DebitAmount += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          DebitAmount, Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount",
          Currency."Invoice Rounding Precision", ValueMustBeMatchMsg);
    end;

    local procedure VerifyReportValue(Caption: Text; Value: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestRequestPageHandler(var ReminderTest: TestRequestPage "Reminder - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ReminderTest."Reminder Header".SetFilter("No.", No);
        ReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOrderConfirmationRequestPageHandler(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ReturnOrderConfirmation."Sales Header".SetFilter("No.", No);
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

