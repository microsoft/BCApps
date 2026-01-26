codeunit 144079 "ERM Payment Terms"
{
    // 1. Test to verify Payment Terms Code in Cust. Ledger Entry after posting Sales Invoice.
    // 2. Test to verify Payment Terms Code in Vendor Ledger Entry after posting Purchase Invoice.
    // 3. Test to verify Payment Term Code to create General Journal Lines using get Standard Journal.
    // 4. Test to verify Vendor Ledger Entry after posting Standard Journal.
    // 5. Test to verify Payment Terms Code on create General Journal Lines and Save them as Standard Journal.
    // 6. Test to verify Payment Discount Amount on report Service - Invoice.
    // 7. Test to verify Payment Discount Amount on report Service - Credit Memo.
    // 
    // Covers Test Cases for WI - 351156.
    // -------------------------------------------------
    // Test Function Name                         TFS ID
    // -------------------------------------------------
    // PaymentTermsCodeOnCustomerLedgerEntry      296095
    // PaymentTermsCodeOnVendorLedgerEntry        296125
    // 
    // Covers Test Cases for WI - 351428.
    // -------------------------------------------------
    // Test Function Name                         TFS ID
    // -------------------------------------------------
    // PaymentTermsCodeOnGenJournalLine           277550
    // VendorLedgerEntryAfterPostStandardJournal  277551
    // PaymentTermsCodeOnStandardJournal          277552
    // PaymentDiscountOnServiceInvoiceReport      280666
    // PaymentDiscountOnServiceCreditMemoReport   280894

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
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountMustMatchMsg: Label 'Amount must match';
        VATAmtLineInvDiscAmtPmtDiscAmtCap: Label 'VATAmtLineInvDiscAmtPmtDiscAmt';
        VATAmtLineInvDiscAmtCap: Label 'VATAmtLineInvDiscAmt';

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTermsCodeOnCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        Item: Record Item;
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Test to verify Payment Terms Code in Cust. Ledger Entry after posting Sales Invoice.

        // Setup.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random for quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // True for ship and invoice

        // Verify.
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Payment Terms Code", SalesHeader."Payment Terms Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTermsCodeOnVendorLedgerEntry()
    var
        Item: Record Item;
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test to verify Payment Terms Code in Vendor Ledger Entry after posting Purchase Invoice.

        // Setup.
        Initialize();
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random for quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Payment Terms Code", PurchaseHeader."Payment Terms Code");
    end;

    [Test]
    [HandlerFunctions('SaveAsStandardGenJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentTermsCodeOnGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test to verify Payment Term Code to create General Journal Lines using get Standard Journal.

        // Setup: Create General Journal Batch, Create General Journal Line and save them as Standard Journal.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalLine(GenJournalLine, Vendor."No.", '');  // Blank for Bal. Account No.
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalLine."Journal Template Name");
        RunSaveAsStandardJournal(StandardGeneralJournal.Code);

        // Exercise.
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalLine."Journal Batch Name");

        // Verify: Verify Payment Terms Code on created General Journal Lines.
        GenJournalLine.TestField("Payment Terms Code", Vendor."Payment Terms Code");
    end;

    [Test]
    [HandlerFunctions('SaveAsStandardGenJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryAfterPostStandardJournal()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test to verify Vendor Ledger Entry after posting Standard Journal.

        // Setup: Create General Journal Batch, create a Vendor and create General Journal Lines.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalLine(GenJournalLine, Vendor."No.", GLAccount."No.");
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalLine."Journal Template Name");
        RunSaveAsStandardJournal(StandardGeneralJournal.Code);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor Ledger Entry with the General Journal Lines.
        VerifyVendorLedgerEntry(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('SaveAsStandardGenJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentTermsCodeOnStandardJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        Vendor: Record Vendor;
    begin
        // Test to verify Payment Terms Code on create General Journal Lines and Save them as Standard Journal.

        // Setup: Create General Journal Batch, General Journal Lines and Standard Journal Code.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalLine(GenJournalLine, Vendor."No.", '');  // Blank for Bal. Account No.
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalLine."Journal Template Name");

        // Exercise.
        RunSaveAsStandardJournal(StandardGeneralJournal.Code);

        // Verify: Verify Payment Terms Code on Standard General Journal Lines created.
        VerifyStandardJournalLines(StandardGeneralJournal.Code, Vendor."Payment Terms Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceInvoiceReport()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test to verify Payment Discount Amount on report Service - Invoice.

        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceInvoice."Calculate Invoice Discount".Invoke();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True for ship and invoice, False for consume.
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for ServiceInvoiceRequestPageHandler.
        Commit();  // commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Service - Invoice");  // Opens ServiceInvoiceRequestPageHandler.

        // Verify: Verify values on Service Invoice report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          VATAmtLineInvDiscAmtPmtDiscAmtCap, Round(ServiceLine."Line Amount" * ServiceHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackDiscountCalculationOnGeneralLedgerSetup();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceCreditMemoReport()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // Test to verify Payment Discount Amount on report Service - Credit Memo.

        // Setup
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", Customer."No.");
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", ServiceHeader."No.");
#if not CLEAN27
        ServiceCreditMemo."Calculate Inv. and Pmt. Disc.".Invoke();
#else
        ServiceCreditMemo."Calculate Invoice Discount".Invoke();
#endif
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // True for ship and invoice, False for consume.
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for ServiceCreditMemoRequestPageHandler.
        Commit();  // commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Service - Credit Memo");  // Opens ServiceCreditMemoRequestPageHandler.

        // Verify: Verify values on Service Credit Memo report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          VATAmtLineInvDiscAmtCap, Round(ServiceLine."Line Amount" * ServiceHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackDiscountCalculationOnGeneralLedgerSetup();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::Vendor, AccountNo, LibraryRandom.RandDec(100, 2));  // Random for Amount.
        GenJournalLine.Validate("Document No.", AccountNo);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure RollBackDiscountCalculationOnGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Discount Calculation", GeneralLedgerSetup."Discount Calculation"::" ");
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure RunSaveAsStandardJournal("Code": Code[10])
    begin
        LibraryVariableStorage.Enqueue(Code);  // Enqueue for SaveAsStandardGenJournalRequestPageHandler.
        Commit();  // Commit requires to run report.
        REPORT.Run(REPORT::"Save as Standard Gen. Journal");  // Opens SaveAsStandardGenJournalRequestPageHandler.
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentDiscountType: Option; DiscountCalculation: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GeneralLedgerSetup.Validate("Discount Calculation", DiscountCalculation);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyStandardJournalLines(StandardJournalCode: Code[10]; PaymentTermsCode: Code[10])
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindFirst();
        StandardGeneralJournalLine.TestField("Payment Terms Code", PaymentTermsCode);
    end;

    local procedure VerifyVendorLedgerEntry(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(GenJournalLine.Amount, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SaveAsStandardGenJournalRequestPageHandler(var SaveAsStandardGenJournal: TestRequestPage "Save as Standard Gen. Journal")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        SaveAsStandardGenJournal.Code.SetValue(Code);
        SaveAsStandardGenJournal.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoRequestPageHandler(var ServiceCreditMemo: TestRequestPage "Service - Credit Memo")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        ServiceCreditMemo."Service Cr.Memo Header".SetFilter("Customer No.", CustomerNo);
        ServiceCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        ServiceInvoice."Service Invoice Header".SetFilter("Customer No.", CustomerNo);
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

