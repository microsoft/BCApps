codeunit 144184 "ERM Registration No."
{
    // 1. Verify report Customer Bill List after posting Sales Invoice.
    // 2. Verify report Vendor Account Bills List after posting Purchase Invoice.
    // 
    // Covers Test Cases for WI - 346322
    // --------------------------------------------------------------------------------------
    // Test Function Name                                                              TFS ID
    // --------------------------------------------------------------------------------------
    // CustomerBillListAfterSalesInvoicePost,VendorBillListAfterPurchaseInvoicePost    157299

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        VendorLedgerEntryLCYCap: Label 'VendLedgEntry1__Amount__LCY__';
        TotalForVendorCap: Label 'TotalForVendor';
        CustomerLedgerEntryLCYCap: Label 'CustLedgEntry1__Amount__LCY__';
        TotalForCustomerCap: Label 'TotalForCustomer';
        BalanceDueCap: Label 'BalanceDue';

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillListAfterSalesInvoicePost()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Verify report Customer Bill List after posting Sales Invoice.

        // Setup: Create and post Sales Invoice and General Journal Line.
        Initialize();
        CreateSalesInvoice(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Using true for Ship and Invoice.
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", -SalesHeader."Amount Including VAT", DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Customer Bills List");

        // Verify: Verify values on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CustomerLedgerEntryLCYCap, SalesHeader."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists(TotalForCustomerCap, 0);  // 0 for TotalForCustomer.
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillListAfterPurchaseInvoicePost()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Verify report Vendor Account Bills List after posting Purchase Invoice.

        // Setup: Create and post Purchase Invoice and General Journal Line.
        Initialize();
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Using true for Receive and Invoice.
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");
        CreateAndPostGenJournalLine(
          GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Amount Including VAT", DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // Verify: Verify values on report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VendorLedgerEntryLCYCap, -PurchaseHeader."Amount Including VAT");
        LibraryReportDataset.AssertElementWithValueExists(TotalForVendorCap, 0);  // 0 for TotalForVendor.
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyBalanceOnVendorBillListWhenPaymentAppliedAndPostWithLaterDate()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 469728] The report Vendor Account Bills List shows wrongly applied documents depending on the Ending Date entered, in the Italian version
        Initialize();

        // [GIVEN] Setup: Create and post Purchase Invoice and General Journal Line.
        CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Using true for Receive and Invoice.
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Applied Invoice and Post Payment for Vendor
        CreateAndPostGenJournalLineWithDifferentDate(
            GenJournalLine."Account Type"::Vendor,
            PurchaseHeader."Buy-from Vendor No.",
            PurchaseHeader."Amount Including VAT",
            DocumentNo);

        // [WHEN] Exercise: Run "Vendor Account Bills List" report
        REPORT.Run(REPORT::"Vendor Account Bills List");

        // [VERIFY] Verify: Verify Balance value on Vendor Account Bills List report before payment posting.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(BalanceDueCap, -PurchaseHeader."Amount Including VAT");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateBill(): Code[20]
    var
        Bill: Record Bill;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Allow Issue", true);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", GLAccount."No.");
        Bill.Validate("List No.", LibraryERM.CreateNoSeriesCode());
        Bill.Validate("Temporary Bill No.", Bill."List No.");
        Bill.Validate("Final Bill No.", Bill."List No.");
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", CreatePaymentMethod());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", CreateBill());
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", CreatePaymentMethod());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostGenJournalLineWithDifferentDate(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);

        GenJournalLine.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerBillsList."Ending Date".SetValue(WorkDate());
        CustomerBillsList.Customer.SetFilter("No.", No);
        CustomerBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRequestPageHandler(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorAccountBillsList.Vendor.SetFilter("No.", No);
        VendorAccountBillsList.EndingDate.SetValue(WorkDate());
        VendorAccountBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

