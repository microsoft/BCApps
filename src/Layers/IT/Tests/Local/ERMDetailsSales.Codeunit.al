codeunit 144178 "ERM Details Sales"
{
    // 1. Test to validate different Sales Invoice created after Combine Shipment with different Sales Order.
    // 2. Test to validate values on Report Customer Bills List after post Sales Invoice and General Journal Line.
    // 3. Test to validate Customer Ledger Entry after Closing Bank Receipts.
    // 4. Test to validate values on Report Customer Bills List after Closing Bank Receipts.
    // 5. Test to validate Vendor Ledger Entry after Post Vendor Bill.
    // 6. Test to validate values on Report Vendor Account Bills List after Post Vendor Bill.
    // 7. Test to validate values on Report Customer Sheet - Print after Post Sales Invoice and General Journal Line with Currency.
    // 8. Test to validate Due Date in "Detailed Cust. Ledg. Entry" after posting Sales Invoice.
    // 
    // Covers Test Cases for WI - 346279
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // CombineShipmentsAfterPostSalesInvoice                                                  267124
    // CustomerBillsListAfterPostGenJnlLine                                                   242418
    // CustomerLedgerEntryAfterClosingBankReceipts                                            308182
    // CustomerBillsListAfterClosingBankReceipts
    // VendorLedgerEntryAfterPostVendorBill, VendorAccountBillsListAfterPostVendorBill        294119
    // CustomerSheetPrintAfterPostGenJnlLineWithCurrency                                      264098
    // 
    // ---------------------------------------------------------------------------------------------
    // Test Function Name
    // ---------------------------------------------------------------------------------------------
    // CheckDueDateDetailedCustLedgEntryAfterPostingSalesInvoice                              359853

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmntLCYCap: Label 'AmountLCY2';
        AmountCap: Label 'CustLedgEntry2__Amount__LCY__';
        AmountLCYCap: Label 'CustLedgEntry1__Amount__LCY__';
        CustLedgEntryDocNoCap: Label 'CustLedgEntry2__Document_No__';
        CustLedgEntryNoCap: Label 'CustLedgEntry1__Document_No__';
        DecreasesAmntCap: Label 'DecreasesAmnt';
        DetailedVendDocNo: Label 'Detailed_Vendor_Ledg__Entry__Document_No__';
        DocNoCap: Label 'DocNo_CustLedgEntry';
        OriginalAmtCap: Label 'VendLedgEntry3__Original_Amt___LCY__';
        PostingBeforeDocumentDateErr: Label 'Document Date must be less than Posting Date.';
        VendAmountCap: Label 'VendLedgEntry1__Amount__LCY___Control1130017';
        ValueEqualErr: Label 'Value must be equal.';
        ValueNotEqualErr: Label 'Value must not be equal.';
        VendLedgEntryNoCap: Label 'VendLedgEntry1__Document_No__';
        WrongDueDateDetailedCustLedgEntryErr: Label 'Wrong Initial Entry Due Date in Detailed Cust. Ledg. Entry.';

    [Test]
    [HandlerFunctions('MessageHandler,CombineShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsAfterPostSalesInvoice()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        OperationType: Code[20];
    begin
        // Test to validate different Sales Invoice created after Combine Shipment with different Sales Order.

        // Setup: Create and post Sales Order.
        Initialize();
        OperationType := LibraryERM.CreateNoSeriesSalesCode();
        DocumentNo := CreateAndPostSalesOrder(SalesLine, CreateCustomer(), '', OperationType, false);  // Currency Code as blank and Invoice as False.
        DocumentNo2 := CreateAndPostSalesOrder(SalesLine, SalesLine."Sell-to Customer No.", '', OperationType, false);  // Currency Code as blank and Invoice as False.

        // Run Combine Shipments Report
        RunCombineShipmentsReport(SalesLine."Sell-to Customer No.", OperationType, WorkDate(), WorkDate());

        // Verify: Verify different Sales Invoice created after Combine Shipment.
        Assert.AreNotEqual(FindSalesLine(DocumentNo), FindSalesLine(DocumentNo2), ValueNotEqualErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler,MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListAfterPostGenJnlLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to validate values on Report Customer Bills List after post Sales Invoice and General Journal Line.

        // Setup: Issue Customer Bill after post Sales Invoice. Create and post General Journal Line.
        Initialize();
        DocumentNo := IssuingCustomerBillAfterPostSalesInvoice(SalesLine);
        DocumentNo2 :=
          ApplyAndPostGeneralJournalLine(
            SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Dishonored, SalesLine."Line Amount");
        ApplyAndPostGeneralJournalLine(
          SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, -SalesLine."Line Amount");
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for CustomerBillsListRequestPageHandler.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Customer Bills List");  // Opens CustomerBillsListRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          CustLedgEntryNoCap, AmountLCYCap, CustLedgEntryDocNoCap, AmountCap, DocumentNo, SalesLine."Amount Including VAT", DocumentNo2,
          -SalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('ClosingBankReceiptsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryAfterClosingBankReceipts()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesLine: Record "Sales Line";
    begin
        // Test to validate Customer Ledger Entry after Closing Bank Receipts.

        // Setup: Create and post Customer Bill after post Sales Invoice.
        Initialize();
        CreateAndPostCustomerBillAfterPostSalesInvoice(SalesLine);
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for ClosingBankReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Closing Bank Receipts");  // Opens ClosingBankReceiptsRequestPageHandler.

        // Verify.
        VerifyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Invoice, SalesLine."Sell-to Customer No.", SalesLine."Amount Including VAT", 0);  // Remaining Amount must be 0.
        VerifyCustomerLedgerEntry(
          CustLedgerEntry."Document Type"::Payment, SalesLine."Sell-to Customer No.", -SalesLine."Amount Including VAT", 0);  // Remaining Amount must be 0.
    end;

    [Test]
    [HandlerFunctions('CustomerBillsListRequestPageHandler,ClosingBankReceiptsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillsListAfterClosingBankReceipts()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Test to validate values on Report Customer Bills List after Closing Bank Receipts.

        // Setup: Create and post Customer Bill after post Sales Invoice. Run report Closing Bank Receipts.
        Initialize();
        DocumentNo := CreateAndPostCustomerBillAfterPostSalesInvoice(SalesLine);
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for ClosingBankReceiptsRequestPageHandler.
        REPORT.Run(REPORT::"Closing Bank Receipts");  // Opens ClosingBankReceiptsRequestPageHandler.
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, SalesLine."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for CustomerBillsListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Customer Bills List");  // Opens CustomerBillsListRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          CustLedgEntryNoCap, AmountLCYCap, CustLedgEntryDocNoCap, AmountCap, DocumentNo, SalesLine."Amount Including VAT",
          CustLedgerEntry."Document No.", -SalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryAfterPostVendorBill()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Test to validate Vendor Ledger Entry after Post Vendor Bill.

        // Setup: Issue Vendor Bill after post Purchase Invoice.
        Initialize();
        DocumentNo := IssueVendorBillAfterPostPurchaseInvoice(VendorBillHeader);
        FindPostedPurchaseInvoice(PurchInvLine, DocumentNo);

        // Exercise: Post Vendor Bill.
        PostVendorBill(VendorBillHeader."Payment Method Code");

        // Verify.
        VerifyVendorLedgerEntry(
          VendorLedgerEntry."Document Type"::Payment, PurchInvLine."Buy-from Vendor No.", PurchInvLine."Amount Including VAT", 0);  // Remaining Amount must be 0.
        VerifyVendorLedgerEntry(
          VendorLedgerEntry."Document Type"::Invoice, PurchInvLine."Buy-from Vendor No.", -PurchInvLine."Amount Including VAT", 0);  // Remaining Amount must be 0.
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillsListRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListAfterPostVendorBill()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VendorBillHeader: Record "Vendor Bill Header";
        DocumentNo: Code[20];
    begin
        // Test to validate values on Report Vendor Account Bills List after Post Vendor Bill.

        // Setup: Issue Vendor Bill after post Purchase Invoice, post Vendor Bill.
        Initialize();
        DocumentNo := IssueVendorBillAfterPostPurchaseInvoice(VendorBillHeader);
        FindPostedPurchaseInvoice(PurchInvLine, DocumentNo);
        PostVendorBill(VendorBillHeader."Payment Method Code");
        LibraryVariableStorage.Enqueue(PurchInvLine."Buy-from Vendor No.");  // Enqueue for VendorAccountBillsListRequestPageHandler.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Vendor Account Bills List");  // Opens VendorAccountBillsListRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          VendLedgEntryNoCap, VendAmountCap, DetailedVendDocNo, OriginalAmtCap, PurchInvLine."Document No.",
          -PurchInvLine."Amount Including VAT", FindPostedVendorBillHeader(VendorBillHeader."Bank Account No."),
          PurchInvLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,CustomerSheetPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintAfterPostGenJnlLineWithCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to validate values on Report Customer Sheet - Print after Post Sales Invoice and General Journal Line with Currency.

        // Setup: Create and post Sales Order and General Journal Line with Currency.
        Initialize();
        DocumentNo :=
          CreateAndPostSalesOrder(SalesLine, CreateCustomer(), CreateCurrencyWithExchangeRate(), LibraryERM.CreateNoSeriesSalesCode(), true);  // Invoice as True.
        DocumentNo2 :=
          ApplyAndPostGeneralJournalLine(SalesLine."Sell-to Customer No.", GenJournalLine."Document Type"::Payment, -SalesLine.Amount);
        LibraryVariableStorage.Enqueue(SalesLine."Sell-to Customer No.");  // Enqueue for CustomerSheetPrintRequestPageHandler.
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(REPORT::"Customer Sheet - Print");  // Opens CustomerSheetPrintRequestPageHandler.

        // Verify.
        VerifyXMLValuesOnReport(
          DocNoCap, DecreasesAmntCap, DocNoCap, AmntLCYCap, DocumentNo, FindDebitAmountGLEntry(SalesLine."Sell-to Customer No."), DocumentNo2,
          -FindDebitAmountGLEntry(SalesLine."Sell-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDueDateDetailedCustLedgEntryAfterPostingSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // SETUP
        Initialize();
        CreateSalesHeaderWithPaymentTerms(SalesHeader);
        // EXERCISE
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // VERIFY
        VerifyDetailedCustLedgEntryDueDate(SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryOpeningBillListFromInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvLine: Record "Purch. Inv. Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntriesPage: TestPage "Vendor Ledger Entries";
        PostedVendBillListPage: TestPage "List of Posted Vend. Bill List";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 380451] Openning "List of Posted Bill List" page for the Invoice record of the Vendor Ledger Entry

        Initialize();

        // [GIVEN] Issue Vendor Bill = "X" after posting of Purchase Invoice.
        DocumentNo := IssueVendorBillAfterPostPurchaseInvoice(VendorBillHeader);
        FindPostedPurchaseInvoice(PurchInvLine, DocumentNo);
        PostVendorBill(VendorBillHeader."Payment Method Code");

        // [WHEN] Open "Vendor Ledger Entry" page for Invoice record and press "Bill List" button
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvLine."Buy-from Vendor No.");
        OpenVendorLedgerEntryAndPressBillList(VendorLedgerEntry, VendorLedgerEntriesPage, PostedVendBillListPage);

        // [THEN] "Vendor Bill List" with "No." = "X" must be shown
        VendorLedgerEntry.TestField("Vendor Bill List");
        PostedVendBillListPage."No.".AssertEquals(VendorLedgerEntry."Vendor Bill List");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryOpeningBillListFromPayment()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntriesPage: TestPage "Vendor Ledger Entries";
        PostedVendBillListPage: TestPage "List of Posted Vend. Bill List";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 380451] Openning "List of Posted Bill List" page for the Payment record of the Vendor Ledger Entry

        Initialize();

        // [GIVEN] Issue Vendor Bill = "X" after posting of Purchase Invoice.
        DocumentNo := IssueVendorBillAfterPostPurchaseInvoice(VendorBillHeader);
        FindPostedPurchaseInvoice(PurchInvLine, DocumentNo);
        PostVendorBill(VendorBillHeader."Payment Method Code");

        // [WHEN] Open "Vendor Ledger Entry" page for Payment record and press "Bill List" button
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PurchInvLine."Buy-from Vendor No.");
        OpenVendorLedgerEntryAndPressBillList(VendorLedgerEntry, VendorLedgerEntriesPage, PostedVendBillListPage);

        // [THEN] "Vendor Bill List" with "No." = "X" must be shown
        PostedVendBillListPage."No.".AssertEquals(VendorLedgerEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillWithPaymentTerms()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Discount: Decimal;
        BillAmount: Decimal;
        DiscountAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 380800] Check Payment Discount when Post Vendor Bill.

        Initialize();

        // [GIVEN] Payment Terms with discount "D"
        Discount := LibraryRandom.RandDecInDecimalRange(1, 20, 1);
        CreateVendorWithPaymentTerms(Vendor, Discount);

        // [GIVEN] Issue Vendor Bill after post Purchase Invoice with Amount = "B".
        CreateAndPostPurchaseInvoice(PurchaseLine, Vendor."No.");
        CreateVendorBill(VendorBillHeader, Vendor."No.", CreateBillPostingGroup(Vendor."Payment Method Code"));
        IssueVendorBill(VendorBillHeader."No.");

        // [GIVEN] Discount Amount "A" = "B" * "D" / 100
        BillAmount := PurchaseLine."Amount Including VAT";
        DiscountAmount := BillAmount * Discount / 100;

        // [WHEN] Post Vendor Bill.
        PostVendorBill(VendorBillHeader."Payment Method Code");

        // [THEN] Vendor Legder Entry has "Original Amount" =  "B" - "A".
        // [THEN] Vendor Legder Entry has "Remaining Amount" to be zero.
        VerifyVendorLedgerEntryOriginalAmount(
          VendorLedgerEntry."Document Type"::Payment, Vendor."No.",
          BillAmount - DiscountAmount, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VendorBillNoAfterPostedBillList()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        PostedInvoiceNo: Code[20];
        PostedVendorBillNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Bill]
        // [SCENARIO 381093] "Vendor Bill No." is present in posted vendor bill and invoice ledger entry
        Initialize();

        // [GIVEN] Posted Purchase Invoice "PI"
        // [GIVEN] Issued Vendor Bill List:
        // [GIVEN] Vendor Bill Header: "No." = "A", "Vendor Bill List No." = "BList"
        // [GIVEN] Vendor Bill Line: "Vendor Bill List No." = "A", "Document No." = "PI", "Vendor Bill No." = "BNo"
        IssueVendorBillAfterPostPurchaseInvoice(VendorBillHeader);
        FindVendorBillLine(VendorBillLine, VendorBillHeader."No.");
        PostedInvoiceNo := FindPostedPurchaseInvoiceNo(VendorBillLine."Vendor No.");
        VendorBillHeader.Find();

        // [WHEN] Post Vendor Bill List
        PostVendorBill(VendorBillHeader."Payment Method Code");
        PostedVendorBillNo := FindPostedVendorBillHeader(VendorBillHeader."Bank Account No.");

        // [THEN] Posted Vendor Bill Header: "No." = "BList"
        Assert.AreEqual(VendorBillHeader."Vendor Bill List No.", PostedVendorBillNo, '');
        // [THEN] Posted Vendor Bill Line: "Vendor Bill No." = "BList", "Vendor Bill List No." = "BNo"
        VerifyPostedVendorBillLineDetails(PostedVendorBillNo, VendorBillLine."Vendor Bill No.");
        // [THEN] Vendor Invoice Ledger Entry: "Document No." = "PI", "Vendor Bill List" = "BList", "Vendor Bill No." = "BNo"
        VerifyVendorLedgerEntryDetails(VendorBillLine."Vendor No.", PostedInvoiceNo, PostedVendorBillNo, VendorBillLine."Vendor Bill No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CombineShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithPostingDateAfterDocumentDate()
    var
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        OperationType: Code[20];
    begin
        // [FEATURE] [Combine Shipment] [Posting Date]
        // [SCENARIO 348826] Combine Shipment with Posting Date > Document Date has been run on two Sales Orders, resulting in two Sales Invoice lines created
        Initialize();

        // [GIVEN] Created and posted two Sales Orders without invoicing
        OperationType := LibraryERM.CreateNoSeriesSalesCode();
        DocumentNo := CreateAndPostSalesOrder(SalesLine, CreateCustomer(), '', OperationType, false);
        DocumentNo2 := CreateAndPostSalesOrder(SalesLine, SalesLine."Sell-to Customer No.", '', OperationType, false);

        // [WHEN] Run Combine Shipments report with Posting Date > Document Date
        RunCombineShipmentsReport(SalesLine."Sell-to Customer No.", OperationType, WorkDate() + 1, WorkDate());

        // [THEN] Two different Sales Invoice lines created successfully
        Assert.AreNotEqual(FindSalesLine(DocumentNo), FindSalesLine(DocumentNo2), ValueNotEqualErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CombineShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithPostingDateBeforeDocumentDate()
    var
        SalesLine: Record "Sales Line";
        OperationType: Code[20];
    begin
        // [FEATURE] [Combine Shipment] [Posting Date]
        // [SCENARIO 348826] Cannot run Combine Shipments report with Posting Date < Document Date
        Initialize();

        // [GIVEN] Created and posted two Sales Orders without invoicing
        OperationType := LibraryERM.CreateNoSeriesSalesCode();
        CreateAndPostSalesOrder(SalesLine, CreateCustomer(), '', OperationType, false);
        CreateAndPostSalesOrder(SalesLine, SalesLine."Sell-to Customer No.", '', OperationType, false);

        // [WHEN] Run Combine Shipments report with Posting Date < Document Date
        asserterror RunCombineShipmentsReport(SalesLine."Sell-to Customer No.", OperationType, WorkDate(), WorkDate() + 1);

        // [THEN] The error is thrown: "Document Date must be less than Posting Date."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(PostingBeforeDocumentDateErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure RunCombineShipmentsReport(CustomerNo: Code[20]; OperationType: Code[20]; PostingDate: Date; DocumentDate: Date)
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(OperationType);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DocumentDate);
        REPORT.Run(REPORT::"Combine Shipments");
    end;

    local procedure ApplyAndPostGeneralJournalLine(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal) DocumentNo: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        ApplyGenJournalLine(GenJournalLine."Journal Batch Name");
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyGenJournalLine(CurrentJnlBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        CashReceiptJournal."Applies-to Doc. No.".Lookup();  // Invoke ApplyCustomerEntriesModalPageHandler.
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure CreateAndPostCustomerBillAfterPostSalesInvoice(var SalesLine: Record "Sales Line") DocumentNo: Code[20]
    var
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        DocumentNo := IssuingCustomerBillAfterPostSalesInvoice(SalesLine);
        Customer.Get(SalesLine."Sell-to Customer No.");
        CreateCustomerBill(CustomerBillHeader, Customer."No.", CreateBillPostingGroup(Customer."Payment Method Code"));
        PostCustomerBill(CustomerBillHeader);
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Using random Unit Price.
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as receive and invoice.
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; CurrencyCode: Code[10]; OperationType: Code[20]; Invoice: Boolean): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, OperationType, CurrencyCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random Unit Price.
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));  // Post as ship and invoice.
    end;

    local procedure CreateBill(): Code[20]
    var
        Bill: Record Bill;
    begin
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Allow Issue", true);
        Bill.Validate("Bills for Coll. Temp. Acc. No.", CreateGLAccount());
        Bill.Validate("List No.", LibraryERM.CreateNoSeriesSalesCode());
        Bill.Validate("Temporary Bill No.", Bill."List No.");
        Bill.Validate("Final Bill No.", Bill."List No.");
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    local procedure CreateBillPostingGroup(PaymentMethod: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", PaymentMethod);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", CreateGLAccount());
        BillPostingGroup.Validate("Bills For Discount Acc. No.", BillPostingGroup."Bills For Collection Acc. No.");
        BillPostingGroup.Modify(true);
        exit(BillPostingGroup."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Losses Acc.", CreateGLAccount());
        Currency.Validate("Realized Gains Acc.", CreateGLAccount());
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", CreatePaymentMethod());
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCustomerBill(var CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20]; No: Code[20])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        FindBillPostingGroup(BillPostingGroup, No);
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
        RunSuggestCustomerBill(CustomerBillHeader, CustomerNo);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindBankAccount(BankAccount);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
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

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; OperationType: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Operation Type", OperationType);
        SalesHeader.Validate("Bank Account", CreateCustomerBankAccount(CustomerNo));
        SalesHeader.Validate("Posting Date", WorkDate());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", CreatePaymentMethod());
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBill(var VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20]; No: Code[20])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        FindBillPostingGroup(BillPostingGroup, No);
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        RunSuggestVendorBills(VendorBillHeader, VendorNo);
    end;

    local procedure CreatePaymentTermsWithDiscount(Discount: Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        LibraryERM.CreatePaymentLines(PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
        Evaluate(PaymentLines."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(30)) + 'D>');
        PaymentLines.Validate("Due Date Calculation", PaymentLines."Due Date Calculation");
        PaymentLines.Validate("Discount %", Discount);
        PaymentLines.Modify(true);
        exit(PaymentLines.Code);
    end;

    local procedure CreateVendorWithPaymentTerms(var Vendor: Record Vendor; Discount: Decimal)
    begin
        CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount(Discount));
        Vendor.Modify(true);
    end;

    local procedure IssuingCustomerBillAfterPostSalesInvoice(var SalesLine: Record "Sales Line") DocumentNo: Code[20]
    begin
        DocumentNo := CreateAndPostSalesOrder(SalesLine, CreateCustomer(), '', LibraryERM.CreateNoSeriesSalesCode(), true);  // Currency Code as blank and Invoice as True.
        RunIssuingCustomerBill(SalesLine."Sell-to Customer No.");
    end;

    local procedure IssueVendorBill(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard."&Create List".Invoke();
    end;

    local procedure IssueVendorBillAfterPostPurchaseInvoice(var VendorBillHeader: Record "Vendor Bill Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        CreateAndPostPurchaseInvoice(PurchaseLine, Vendor."No.");
        CreateVendorBill(VendorBillHeader, Vendor."No.", CreateBillPostingGroup(Vendor."Payment Method Code"));
        IssueVendorBill(VendorBillHeader."No.");
        exit(PurchaseLine."Document No.");
    end;

    local procedure FindBillPostingGroup(var BillPostingGroup: Record "Bill Posting Group"; No: Code[20])
    begin
        BillPostingGroup.SetRange("No.", No);
        BillPostingGroup.FindFirst();
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindDebitAmountGLEntry(BalAccountNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.FindFirst();
        exit(GLEntry."Debit Amount");
    end;

    local procedure FindPostedPurchaseInvoice(var PurchInvLine: Record "Purch. Inv. Line"; PreAssignedNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
    end;

    local procedure FindPostedPurchaseInvoiceNo(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPostedVendorBillHeader(BankAccountNo: Code[20]): Code[20]
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
    begin
        PostedVendorBillHeader.SetRange("Bank Account No.", BankAccountNo);
        PostedVendorBillHeader.FindFirst();
        exit(PostedVendorBillHeader."No.");
    end;

    local procedure FindVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorBillListNo: Code[20])
    begin
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillListNo);
        VendorBillLine.FindFirst();
    end;

    local procedure FindSalesLine(ShipmentNo: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Shipment No.", ShipmentNo);
        SalesLine.FindFirst();
        exit(SalesLine."Document No.");
    end;

    local procedure OpenVendorLedgerEntryAndPressBillList(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendorLedgerEntriesPage: TestPage "Vendor Ledger Entries"; var PostedVendBillListPage: TestPage "List of Posted Vend. Bill List")
    begin
        VendorLedgerEntriesPage.OpenView();
        VendorLedgerEntriesPage.GotoKey(VendorLedgerEntry."Entry No.");
        PostedVendBillListPage.Trap();
        VendorLedgerEntriesPage.BillList.Invoke();
    end;

    local procedure PostCustomerBill(CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillPost: Codeunit "Customer Bill - Post + Print";
    begin
        CustomerBillPost.SetHidePrintDialog(true);
        CustomerBillPost.Code(CustomerBillHeader);
    end;

    local procedure PostVendorBill(PaymentMethodCode: Code[10])
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("Payment Method Code", PaymentMethodCode);
        VendorBillListSentCard.Post.Invoke();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure RunIssuingCustomerBill(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuingCustomerBill: Report "Issuing Customer Bill";
    begin
        Clear(IssuingCustomerBill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        IssuingCustomerBill.SetTableView(CustLedgerEntry);
        IssuingCustomerBill.SetPostingDescription(CustomerNo);
        IssuingCustomerBill.UseRequestPage(false);
        IssuingCustomerBill.Run();
    end;

    local procedure RunSuggestCustomerBill(CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        Clear(SuggestCustomerBills);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        SuggestCustomerBills.InitValues(CustomerBillHeader, true);  // OKIssue as True.
        SuggestCustomerBills.SetTableView(CustLedgerEntry);
        SuggestCustomerBills.UseRequestPage(false);
        SuggestCustomerBills.Run();
    end;

    local procedure RunSuggestVendorBills(VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        Clear(SuggestVendorBills);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        SuggestVendorBills.InitValues(VendorBillHeader);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.Run();
    end;

    local procedure CreateSalesHeaderWithPaymentTerms(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        LibraryERM.CreatePaymentLines(PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
        Evaluate(PaymentLines."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(30)) + 'D>');
        PaymentLines.Validate("Due Date Calculation", PaymentLines."Due Date Calculation");
        PaymentLines.Modify(true);
        exit(PaymentLines.Code);
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; Amount: Decimal; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, CustomerNo);
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
        Assert.AreNearlyEqual(RemainingAmount, CustLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
    end;

    local procedure VerifyVendorLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, VendorNo);
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(Amount, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
        Assert.AreNearlyEqual(RemainingAmount, VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
    end;

    local procedure VerifyXMLValuesOnReport(Caption: Text; Caption2: Text; Caption3: Text; Caption4: Text; Value: Code[20]; Value2: Decimal; Value3: Code[20]; Value4: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, Value3);
        LibraryReportDataset.AssertElementWithValueExists(Caption4, Value4);
    end;

    local procedure VerifyDetailedCustLedgEntryDueDate(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindLast();
        Assert.AreEqual(CustLedgerEntry."Due Date", DetailedCustLedgEntry."Initial Entry Due Date", WrongDueDateDetailedCustLedgEntryErr);
    end;

    local procedure VerifyVendorLedgerEntryOriginalAmount(DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal; RemainingAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, VendorNo);
        VendorLedgerEntry.CalcFields(Amount, "Original Amount");
        Assert.AreNearlyEqual(Amount, VendorLedgerEntry."Original Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
        Assert.AreNearlyEqual(RemainingAmount, VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), ValueEqualErr);
    end;

    local procedure VerifyPostedVendorBillLineDetails(PostedVendorBillNo: Code[20]; ExpectedVendorBillNo: Code[20])
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        PostedVendorBillLine.SetRange("Vendor Bill No.", PostedVendorBillNo);
        PostedVendorBillLine.FindFirst();
        Assert.AreEqual(ExpectedVendorBillNo, PostedVendorBillLine."Vendor Bill List No.", PostedVendorBillLine.FieldCaption("Vendor Bill List No."));
    end;

    local procedure VerifyVendorLedgerEntryDetails(VendorNo: Code[20]; ExpectedDocumentNo: Code[20]; ExpectedPostedVendorBillNo: Code[20]; ExpectedVendorBillNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        Assert.AreEqual(ExpectedDocumentNo, VendorLedgerEntry."Document No.", VendorLedgerEntry.FieldCaption("Document No."));
        Assert.AreEqual(ExpectedPostedVendorBillNo, VendorLedgerEntry."Vendor Bill List", VendorLedgerEntry.FieldCaption("Vendor Bill List"));
        Assert.AreEqual(ExpectedVendorBillNo, VendorLedgerEntry."Vendor Bill No.", VendorLedgerEntry.FieldCaption("Vendor Bill No."));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CombineShipmentRequestPageHandler(var CombineShipments: TestRequestPage "Combine Shipments")
    begin
        CombineShipments.SalesOrderHeader.SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText());
        CombineShipments.OperationType.SetValue(LibraryVariableStorage.DequeueText());
        CombineShipments.CombineFromDate.SetValue(WorkDate());
        CombineShipments.CombineToDate.SetValue(WorkDate());
        CombineShipments.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CombineShipments.DocDateReq.SetValue(LibraryVariableStorage.DequeueDate());
        CombineShipments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsRequestPageHandler(var ClosingBankReceipts: TestRequestPage "Closing Bank Receipts")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        ClosingBankReceipts.CustEntry1.SetFilter("Customer No.", CustomerNo);
        ClosingBankReceipts.ClosingDateForBankReceipts.SetValue(
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate())); // Using random Date.
        ClosingBankReceipts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerBillsList.Customer.SetFilter("No.", No);
        CustomerBillsList."Ending Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Using random Date.
        CustomerBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerSheetPrintRequestPageHandler(var CustomerSheetPrint: TestRequestPage "Customer Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CustomerSheetPrint.Customer.SetFilter("No.", No);
        CustomerSheetPrint.Customer.SetFilter("Date Filter", Format(WorkDate()));
        CustomerSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountBillsListRequestPageHandler(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        VendorAccountBillsList.Vendor.SetFilter("No.", No);
        VendorAccountBillsList.EndingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Using random Date.
        VendorAccountBillsList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

