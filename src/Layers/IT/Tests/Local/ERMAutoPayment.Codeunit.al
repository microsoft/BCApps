codeunit 144050 "ERM Auto Payment"
{
    // // [FEATURE] [Payment]
    // 1. Test to verify values on the Report - Bank Sheet - Print.
    // 2. Test to verify values on Customer Ledger Entry when Closing Bank Receipts Report run with Confirm Per Application.
    // 3. Test to verify values on Customer Ledger Entry when Closing Bank Receipts Report run without Confirm Per Application.
    // 4. Test to verify values on the Report - Issued Customer Bills Report.
    // 5. Test to verify values on Customer Ledger Entry after recall Customer Bill.
    // 6. Test to verify values on Customer Ledger Entry after recall Issued Customer Bill.
    // 7. Test to verify error message on Report - Closing Bank Receipts for blocked Customer.
    // 8. Test to verify error message while posting Customer Bill when Customer Bill Header Bank Account Payment Method is different from Customer Payment Method.
    // 9. Test to verify error message while posting Vendor Bill List Sent when Invoice applied to Payment.
    // 10. Test to verify error message while posting Vendor Bill List Sent when Invoice applied to Credit Memo.
    // 11. Test to verify error message while posting Vendor Bill List Sent when multiple Invoices applied to Payment.
    // 12. Test to verify error message while posting Vendor Bill List Sent when multiple Invoices applied to Credit Memo.
    // 13. Test to verify Customer Ledger Entry for Customer with dimension when unapplied payment entry reversed.
    // 14. Test to verify Customer Ledger Entry for Customer without dimension when unapplied payment entry reversed.
    // 15. Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to All.
    // 16. Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to All.
    // 17. Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to Payment.
    // 18. Test to verify Vendor Bill can be reissued after deleting Issued Vendor Bill.
    // 19. Test to verify Vendor Bill Lines can be resuggested after deleting Issued Vendor Bill Line.
    // 20. Test to verify Vendor Bill Lines can be resuggested after deleting Vendor Bill Line.
    // 21. Test to verify Vendor Bill Lines can be re-inserted manually after deleting Vendor Bill Line without Withholding Tax Code.
    // 22. Test to verify Vendor Bill Lines can be re-inserted manually after deleting Vendor Bill Line with Withholding Tax Code.
    // 23. Test to verify Shipment method code on Posted Sales Invoice Header after validating Intra Shipping Code of Shipping Method.
    // 24. Verify Vendor Bill is successfully posted after the payment is Unapplied.
    // 25. Test to verify initialization of Purchase Header field Prepmt. Payment Terms Code
    // 26. Test to verify that it is impossible to use payment terms with multilply payment lines for vendor's Prepmt. Payment Terms Code
    // 27. Test to verify that it is not possible to add new payments line to payment term
    //     if it is already defined for vendors with "Prepmt. Payment Terms Code"
    // 28. Test to verify that it is not possible to delete payments line from payment term
    //     if it is already defined for vendors with "Prepmt. Payment Terms Code"
    // 30. Test to verify that it is not possible to add new payments line to payment term
    //     if it is already defined for purchase document with "Prepmt. Payment Terms Code"
    // 31. Test to verify that it is not possible to delete payments line from payment term
    //     if it is already defined for purchase document with "Prepmt. Payment Terms Code"
    // 32. Test to verify no extra lines generated in G/L Entry and G/L Book Entry for Vendor.
    // 33. Test to verify no extra lines generated in G/L Entry and G/L Book Entry for Customer.
    // 
    // Covers Test Cases for WI - 347430
    // --------------------------------------------------------------------------
    // Test Function Name                                           TFS ID
    // --------------------------------------------------------------------------
    // BankSheetPrintWithCurrency                                   205313
    // ClosingBankReceiptsWithConfirmPerApplication                 160252
    // ClosingBankReceiptsWithoutConfirmPerApplication              160523
    // IssuedCustomerBillWithCumulative                             174224
    // RecallCustomerBillAfterIssueCustomerBill                     206420
    // RecallIssuedCustomerBillAfterPostingCustomerBill             206421
    // 
    // Covers Test Cases for WI - 347485
    // ----------------------------------------------------------------------------
    // Test Function Name                                           TFS ID
    // ----------------------------------------------------------------------------
    // ClosingBankReceiptsWithBlockedCustomerError                  155746
    // PostCustBillWithDifferentBankAccountError                    177638
    // PostVendorBillListWithApplyToPmtError                        154721
    // PostVendorBillListWithApplyToCrMemoError                     154722
    // PostVendorBillListWithApplyToMutiplePmtsError                154730
    // PostVendorBillListWithApplyToMutipleCrMemosError             154731
    // ReverseCustomerLedgerEntryWithDimension                      155764
    // ReverseCustomerLedgerEntryWithoutDimension                   155765
    // 
    // Covers Test Cases for WI - 347998
    // ----------------------------------------------------------------------------
    // Test Function Name                                           TFS ID
    // ----------------------------------------------------------------------------
    // SuggestCustomerBillLineForCustomerBlockedAll                156357
    // SuggestVendorBillLineForVendorBlockedAll                    156359
    // SuggestVendorBillLineForVendorBlockedPayment                156360
    // ReissueVendorBillAfterDeletingIssuedVendorBill               151706
    // SuggestVendorBillLineAfterDeletingIssuedVendorBillLine       151707
    // ResuggestVendorBillLineAfterDeletingVendorBillLine           243162
    // ReinsertVendorBillLineManuallyWithoutWithholdingTax          243160
    // ReinsertVendorBillLineManuallyWithWithholdingTax             243161
    // ShipmentMethodOnPostedSalesInvoice                           188668
    // 
    // Covers Test Cases for WI - 349771
    // ----------------------------------------------------------------------------
    // Test Function Name                                           TFS ID
    // ----------------------------------------------------------------------------
    // PostVendorBillListAfterUnapplyPayment                        154724
    // 
    // Covers Test Cases for WI - 91768
    // ----------------------------------------------------------------------------
    // Test Function Name                                           TFS ID
    // ----------------------------------------------------------------------------
    // ReverseVendorLedgerEntryAfterUnApply                         91767
    // ReverseCustomerLedgerEntryAfterUnApply                       91767
    // BankRcptTempNoOnPmtEntryAfterRecallIssuedCustomerBill        360401
    // ReverseVendorLedgerEntryAfterUnApply                         91768
    // ReverseCustomerLedgerEntryAfterUnApply                       91768

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmtCapLbl: Label 'Amt';
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Caption,%2 = Field Value,%3 = Table Caption';
        AmountIssuedCustBillLineCapLbl: Label 'Amount_IssuedCustBillLine';
        CustomerNoTxt: Label '%1|%2', Comment = '%1=Field Value,%2=Field Value';
        CustomerBlockedErr: Label 'You cannot post this type of document when Customer %1 is blocked with type All';
        LineMustNotExistsErr: Label '%1 Bill Line must not exists.';
        ListDateIssuedCustBillHdrCap: Label 'ListDate_IssuedCustBillHdr';
        NoBankAccountCap: Label 'No_BankAccount';
        VendorBillListErr: Label 'Meanwhile Remaining Amount has been modified for Document No. %1 Document Occurrence 1. New amount is %2. Please recreate the bill list.';
        IncorrectPrepmtPaymentTermsCodeErr: Label 'Incorrect value of Prepmt. Payment Terms Code.';
        PrepmtPaymtTermCodeValidationErr: Label 'The field Prepmt. Payment Terms Code of table Vendor contains a value';
        OnlyOnePayLineAllowedErr: Label 'Only one payment line is allowed for payment terms';
        GLEntryErr: Label 'The lines of G/L Entry is not correct after Reverse.';
        GLBookEntryErr: Label 'The lines of G/L Book Entry is not correct after Reverse.';
        IncorrectBankRcptTempNoErr: Label 'Incorrect Bank Receipt Temp. No.';
        DimensionCodeMissingErr: Label 'Select a Dimension Value Code for the Dimension Code %1 for Customer %2.', Comment = '%1 = Dimension Code, %2 = Customer no.';
        ContactNoSeriesErr: Label 'No. Series should be assigned from selected Series from Assist Edit.';
        AnalysisViewErr: Label 'Last Entry No. must be %1 in %2.', Comment = '%1= Field Value ,%2= Table Name.';
        DocumentOccurrenceErr: Label 'The %1 field value is not equal to the expected value %2 in the %3 table.';
        CustomerLedgerEntryErr: Label '%1 must be %2 in %3.', Comment = '%1=Field Caption,%2=Field Value,%3=Table Caption';

    [Test]
    [HandlerFunctions('BankSheetPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankSheetPrintWithCurrency()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Amount: Decimal;
    begin
        // Test to verify values on the Report - Bank Sheet - Print.

        // Setup: Create and Post multiple Cash Receipt Journals.
        Initialize();
        CreateCashReceiptsJournalBatch(GenJournalBatch, CreateCurrencyCode());
        Amount := CreateAndPostMultipleCashReceiptGenJournalLines(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");  // Enqueue Bal. Account No. in BankSheetPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Bank Sheet - Print");

        // Verify: Verify values on Report - Bank Sheet - Print.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmtCapLbl, -Amount);
        LibraryReportDataset.AssertElementWithValueExists(NoBankAccountCap, GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,IssuingCustomerBillRequestPageHandler,ClosingBankReceiptsRequestPageHandler,ConfirmHandler,PostApplicationModalPageHandler')]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsWithConfirmPerApplication()
    begin
        // [FEATURE] [Closing Bank Receipts]
        // [SCENARIO 375223] "Bank Receipts Risk Period" should be taken into account by "Closing Bank Receipts" report  while closing payments with "Confirm Per Application"
        // [GIVEN] Issued Bank Receipt with Posting Date = 15.01
        // [GIVEN] Customer Bill with Posting Date = 01.01
        // [GIVEN] "Bank Receipts Risk Period" = 4 days
        // [WHEN] Run Closing Bank Receipts batch job with application confirm
        // [THEN] Customer Bill applied to Bank Receipt with Posting Date = 05.01
        ApplySalesInvoiceToBillUsingClosingCustomerBill(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,IssuingCustomerBillRequestPageHandler,ClosingBankReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsWithoutConfirmPerApplication()
    begin
        // [FEATURE] [Closing Bank Receipts]
        // [SCENARIO 375223] "Bank Receipts Risk Period" should be taken into account by "Closing Bank Receipts" report  while closing payments without "Confirm Per Application"
        // [GIVEN] Issued Bank Receipt with Posting Date = 15.01
        // [GIVEN] Customer Bill with Posting Date = 01.01
        // [GIVEN] "Bank Receipts Risk Period" = 4 days
        // [WHEN] Run Closing Bank Receipts batch job without application confirm
        // [THEN] Customer Bill applied to Bank Receipt with Posting Date = 05.01
        ApplySalesInvoiceToBillUsingClosingCustomerBill(false);
    end;

    local procedure ApplySalesInvoiceToBillUsingClosingCustomerBill(ConfirmPerApplication: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempSalesLine: Record "Sales Line" temporary;
        OldWorkDate: Date;
        PostingDate: Date;
    begin
        // Setup: Create and post Customer Bill.Change WorkDate.
        Initialize();
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Using greater date than WORKDATE as Bill must be issued later than the posted invoice.
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsCode(), PostingDate);
        CreateAndPostCustomerBill(TempSalesLine."Sell-to Customer No.");
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<CY>', PostingDate);
        PostingDate := GetClosingBankRcptDate();
        EnqueueValuesForRequestPageHandler(ConfirmPerApplication, TempSalesLine."Sell-to Customer No.");  // Enqueue values in ClosingBankReceiptsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Closing Bank Receipts");

        // Verify: Verify Amount on Customer Ledger Entry and Posting Date on Detailed Customer Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Amount Including VAT", TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Invoice);
        VerifyDetailedCustomerLedgerEntry(TempSalesLine."Sell-to Customer No.", PostingDate);

        // Tear Down.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler,IssuedCustBillsReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssuedCustomerBillWithCumulative()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        TempSalesLine: Record "Sales Line" temporary;
        TempSalesLine2: Record "Sales Line" temporary;
        PaymentTermsCode: Code[10];
    begin
        // Test to verify values on the Report - Issued Customer Bills Report.

        // Setup: Issue Bank Receipts after posting Sales Invoices. Run Suggest Customer Bills for created Customers.
        Initialize();
        PaymentTermsCode := CreatePaymentTermsCode();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, PaymentTermsCode, WorkDate());
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine2, PaymentTermsCode, WorkDate());
        CreateCustomerBillHeader(CustomerBillHeader);
        RunSuggestCustomerBill(
          CustomerBillHeader, StrSubstNo(CustomerNoTxt, TempSalesLine."Sell-to Customer No.", TempSalesLine2."Sell-to Customer No."));
        DeleteCustomerBillLine(CustomerBillHeader."No.", TempSalesLine2."Sell-to Customer No.");
        UpdateCustomerBillLine(CustomerBillHeader."No.", TempSalesLine."Sell-to Customer No.");
        PostCustomerBill(CustomerBillHeader);
        LibraryVariableStorage.Enqueue(GetIssuedCustomerBillHeaderNo(TempSalesLine."Sell-to Customer No."));  // Enqueue value in IssuedCustBillsReportRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Issued Cust Bills Report");

        // Verify: Verify values on Report - Issued Customer Bills Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ListDateIssuedCustBillHdrCap, Format(WorkDate()));
        LibraryReportDataset.AssertElementWithValueExists(AmountIssuedCustBillLineCapLbl, TempSalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecallCustomerBillAfterIssueCustomerBill()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify values on Customer Ledger Entry after recall Customer Bill.

        // Setup: Create customer bill after Issue Bank Receipt for posted Sales Invoice . Run Suggest Customer Bill.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsWithMultiplePaymentLines(), WorkDate());
        CreateCustomerBillHeader(CustomerBillHeader);
        RunSuggestCustomerBill(CustomerBillHeader, TempSalesLine."Sell-to Customer No.");

        // Exercise: Recall Customer Bill.
        RecallUnpostedCustomerBill(CustomerBillHeader."No.");

        // Verify: Verify values on Customer Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Amount Including VAT", TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecallIssuedCustomerBillAfterPostingCustomerBill()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify values on Customer Ledger Entry after recall Issued Customer Bill.

        // Setup: Create and Post Customer Bill after Issue Bank Receipt for Posted Sales Invoice.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsWithMultiplePaymentLines(), WorkDate());
        CreateAndPostCustomerBill(TempSalesLine."Sell-to Customer No.");

        // Exercise: Recall Issued Customer Bill.
        RecallIssuedCustomerBill(TempSalesLine."Sell-to Customer No.");

        // Verify: Verify values on Customer Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Amount Including VAT", TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::" ");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,IssuingCustomerBillRequestPageHandler,ClosingBankReceiptsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsWithBlockedCustomerError()
    var
        TempSalesLine: Record "Sales Line" temporary;
        OldWorkDate: Date;
    begin
        // Test to verify error message on Report - Closing Bank Receipts for blocked Customer.

        // Setup: Create and post Customer Bill. Update Customer. Change WorkDate.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsCode(), WorkDate());
        CreateAndPostCustomerBill(TempSalesLine."Sell-to Customer No.");
        UpdateBlockedCustomerToAll(TempSalesLine."Sell-to Customer No.");
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<1Y>', WorkDate());
        EnqueueValuesForRequestPageHandler(false, TempSalesLine."Sell-to Customer No.");  // Enqueue False for Confirm Per Application and Customer No. in ClosingBankReceiptsRequestPageHandler.
        Commit();  // Commit required to run the report.

        // Exercise.
        asserterror REPORT.Run(REPORT::"Closing Bank Receipts");

        // Verify: Verify error on Report - Closing Bank Receipts.
        Assert.ExpectedError(StrSubstNo(CustomerBlockedErr, TempSalesLine."Sell-to Customer No."));

        // Tear Down.
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCustBillWithDifferentBankAccountError()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify error message while posting Customer Bill when Customer Bill Header Bank Account Payment Method is different from Customer Payment Method.

        // Setup: Issue Bank Receipt for Posted Sales Invoice. Create Customer Bill Header with new Bank Account No and Bills to subject to collection.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsCode(), WorkDate());
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, CreateBankAccount(''), FindPaymentMethod(), CustomerBillHeader.Type::"Bills Subject To Collection");  // Blank value for Currency Code,
        RunSuggestCustomerBill(CustomerBillHeader, TempSalesLine."Sell-to Customer No.");

        // Exercise.
        asserterror PostCustomerBill(CustomerBillHeader);

        // Verify: Verify error on while posting Customer Bill.
        Assert.ExpectedErrorCannotFind(Database::"Bill Posting Group");
    end;


    [Test]
    [HandlerFunctions('MessageHandler,IssuingCustomerBillRequestPageHandler,ClosingBankReceiptsCheckDimensionsRequestPageHandler')]
    procedure ClosingBankReceiptsWithoutCheckDimensions()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        BillPostingGroup: Record "Bill Posting Group";
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        OldWorkDate: Date;
    begin
        // [FEATURE] [Closing Bank Receipts]
        // [SCENARIO 538465] Do not check dimensions if "Do Not Check Dimensions" is enabled on "Closing Bank Receipts" report
        Initialize();

        // [GIVEN] Customer X, Payment method code X with 'Bill Code', payment term code Y
        CustomerNo := CreateCustomer(CreatePaymentTermsCode());

        // [GIVEN] Create and post sales invoice, customer X, Payment method code X, payment term code Y
        CreateSalesInvoice(SalesLine, CustomerNo);
        SalesInvoiceNo := PostSalesInvoice(SalesLine);
        SalesInvoiceHeader.Get(SalesInvoiceNo);

        // [GIVEN] Issued Bank Receipt for Customer X
        EnqueueValuesForRequestPageHandler(WorkDate(), CustomerNo);  // Enqueue values in IssuingCustomerBillRequestPageHandler.
        REPORT.Run(REPORT::"Issuing Customer Bill");

        // [GIVEN] Create Customer Bill Card
        // [GIVEN] Suggest lines on Customer Bill Card for Customer X
        // [GIVEN] Post Customer Bill Card
        CreateBillPostingGroup(BillPostingGroup, SalesInvoiceHeader."Payment Method Code");
        CreateCustomerBill(CustomerBillHeader, CustomerNo, BillPostingGroup);
        PostCustomerBill(CustomerBillHeader);

        // [GIVEN] Add new dimension with code mandatory for customer X
        CreateDefaultDimension(CustomerNo);

        // [GIVEN] Change WorkDate
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<+1D>', SalesInvoiceHeader."Due Date");

        // [WHEN] Run Closing Bank Receipts for Customer X without check dimensions
        Commit();
        EnqueueValuesForRequestPageHandler(true, CustomerNo);  // Enqueue values in ClosingBankReceiptsCheckDimensionsRequestPageHandler
        REPORT.Run(REPORT::"Closing Bank Receipts");

        // [THEN] The error for missing dimension hasn't been occured
        // [THEN] The report is executed and entries are correct
        VerifyCustomerLedgerEntry(
            SalesLine."Amount Including VAT", CustomerNo, "Gen. Journal Document Type"::Invoice);

        // Tear Down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,IssuingCustomerBillRequestPageHandler,ClosingBankReceiptsCheckDimensionsRequestPageHandler')]
    procedure ClosingBankReceiptsWithCheckDimensions()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        BillPostingGroup: Record "Bill Posting Group";
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
        DimensionCode: Code[20];
        OldWorkDate: Date;
    begin
        // [FEATURE] [Closing Bank Receipts]
        // [SCENARIO 538465] Check dimensions if "Do Not Check Dimensions" is  not enabled on "Closing Bank Receipts" report
        Initialize();

        // [GIVEN] Customer X, Payment method code X with 'Bill Code', payment term code Y
        CustomerNo := CreateCustomer(CreatePaymentTermsCode());

        // [GIVEN] Create and post sales invoice, customer X, Payment method code X, payment term code Y
        CreateSalesInvoice(SalesLine, CustomerNo);
        SalesInvoiceNo := PostSalesInvoice(SalesLine);
        SalesInvoiceHeader.Get(SalesInvoiceNo);

        // [GIVEN] Issued Bank Receipt for Customer X
        EnqueueValuesForRequestPageHandler(WorkDate(), CustomerNo);  // Enqueue values in IssuingCustomerBillRequestPageHandler.
        REPORT.Run(REPORT::"Issuing Customer Bill");

        // [GIVEN] Create Customer Bill Card for Customer X
        // [GIVEN] Suggest lines on Customer Bill Card for Customer X
        // [GIVEN] Post Customer Bill Card
        CreateBillPostingGroup(BillPostingGroup, SalesInvoiceHeader."Payment Method Code");
        CreateCustomerBill(CustomerBillHeader, CustomerNo, BillPostingGroup);
        PostCustomerBill(CustomerBillHeader);

        // [GIVEN] Add new dimension with code mandatory for customer X
        DimensionCode := CreateDefaultDimension(CustomerNo);

        // [GIVEN] Change WorkDate
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<+1D>', SalesInvoiceHeader."Due Date");

        // [WHEN] Run Closing Bank Receipts, with checking dimensions
        Commit();
        EnqueueValuesForRequestPageHandler(false, CustomerNo);  // Enqueue values in ClosingBankReceiptsCheckDimensionsRequestPageHandler
        asserterror REPORT.Run(REPORT::"Closing Bank Receipts");

        // [THEN] The error popup
        Assert.ExpectedError(StrSubstNo(DimensionCodeMissingErr, DimensionCode, SalesLine."Sell-to Customer No."));
        // Tear Down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillListWithApplyToPmtError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify error message while posting Vendor Bill List Sent when Invoice applied to Payment.
        PostVendorBillListForSingleInvoice(GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillListWithApplyToCrMemoError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify error message while posting Vendor Bill List Sent when Invoice applied to Credit Memo.
        PostVendorBillListForSingleInvoice(GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure PostVendorBillListForSingleInvoice(DocumentType: Enum "Gen. Journal Document Type")
    var
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        DocumentNo := ApplyToDocumentAfterIssueVendorBill(CreateVendor(), DocumentType);

        // Exercise and Verify.
        PostVendorBillListFromVendorBillListSentCard(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillListWithApplyToMutiplePmtsError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify error message while posting Vendor Bill List Sent when multiple Invoices applied to Payment.
        PostVendorBillListForMultipleInvoices(GenJournalLine."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillListWithApplyToMutipleCrMemosError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify error message while posting Vendor Bill List Sent when multiple Invoices applied to Credit Memo.
        PostVendorBillListForMultipleInvoices(GenJournalLine."Document Type"::"Credit Memo");
    end;

    local procedure PostVendorBillListForMultipleInvoices(DocumentType: Enum "Gen. Journal Document Type")
    var
        DocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // Setup.
        Initialize();
        VendorNo := CreateVendor();
        DocumentNo := ApplyToDocumentAfterIssueVendorBill(VendorNo, DocumentType);
        ApplyToDocumentAfterIssueVendorBill(VendorNo, DocumentType);

        // Exercise and Verify.
        PostVendorBillListFromVendorBillListSentCard(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustomerLedgerEntryWithDimension()
    begin
        // Test to verify Customer Ledger Entry for Customer with dimension when unapplied payment entry reversed.
        ReverseCustLedgerEntryAfterUnApply(CreateCustomerWithDimension());
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustomerLedgerEntryWithoutDimension()
    begin
        // Test to verify Customer Ledger Entry for Customer without dimension when unapplied payment entry reversed.
        ReverseCustLedgerEntryAfterUnApply(CreateCustomer(''));  // Blank value for PaymentTermsCode.
    end;

    local procedure ReverseCustLedgerEntryAfterUnApply(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Sales Invoice. Unapply payment Customer Ledger Entry.
        Initialize();
        CreateSalesInvoice(SalesLine, CustomerNo);
        TempSalesLine := SalesLine;
        PostSalesInvoice(SalesLine);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(
            TempSalesLine."Sell-to Customer No.",
            -TempSalesLine."Line Amount", GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        ReversalEntry.SetHideDialog(true);

        // Exercise: Reverse Posted Payment Entry from Customer Ledger Entry.
        ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Verify: Verify Amount on Customer Ledger Entry.
        VerifyCustomerLedgerEntry(-TempSalesLine.Amount, TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SuggestCustomerBillLineForCustomerBlockedAll()
    var
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to All.

        // Setup: Issue bank Receipt, Create Customer Bill Header, Update Customer Blocked to All.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsCode(), WorkDate());
        CreateCustomerBillHeader(CustomerBillHeader);
        UpdateBlockedCustomerToAll(TempSalesLine."Sell-to Customer No.");

        // Exercise.
        RunSuggestCustomerBill(CustomerBillHeader, TempSalesLine."Sell-to Customer No.");

        // Verify: Verify no Customer Bill Lines are suggested.
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        Assert.IsFalse(CustomerBillLine.FindFirst(), StrSubstNo(LineMustNotExistsErr, Customer.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineForVendorBlockedAll()
    var
        Vendor: Record Vendor;
    begin
        // Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to All.
        SuggestVendorBillLineForBlockedVendor(Vendor.Blocked::All);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineForVendorBlockedPayment()
    var
        Vendor: Record Vendor;
    begin
        // Test to verify no Customer Bill Lines are suggested after the Customer Blocked is set to Payment.
        SuggestVendorBillLineForBlockedVendor(Vendor.Blocked::Payment);
    end;

    local procedure SuggestVendorBillLineForBlockedVendor(Blocked: Enum "Vendor Blocked")
    var
        Vendor: Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
    begin
        // Setup: Post Purchase Invoice, Create Vendor Bill Header, Update Vendor Blocked to All.
        Initialize();
        VendorNo := CreateVendor();
        CreateAndPostPurchaseInvoice(VendorNo, LibraryRandom.RandDec(10, 2));  // Using Random for Direct Unit Cost.
        CreateVendorBillHeader(VendorBillHeader);
        UpdateBlockedVendorToAll(VendorNo, Blocked);

        // Exercise.
        RunSuggestVendorBills(VendorBillHeader, VendorNo);

        // Verify: Verify no Vendor Bill Lines are suggested.
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        Assert.IsFalse(VendorBillLine.FindFirst(), StrSubstNo(LineMustNotExistsErr, Vendor.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReissueVendorBillAfterDeletingIssuedVendorBill()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
    begin
        // Test to verify Vendor Bill can be reissued after deleting Issued Vendor Bill.

        // Setup: Create vendor, post Purchase Invoice, Issue vendor Bill and delete Issued Vendor Bill.
        Initialize();
        VendorNo := CreateVendor();
        IssueVendorBillAfterPostingPurchaseInvoice(VendorBillLine, VendorNo);
        FindVendorBillHeader(VendorBillHeader, VendorBillLine."Vendor Bill List No.", VendorBillHeader."List Status"::Sent);
        VendorBillHeader.Delete(true);

        // Exercise: Reissue Vendor Bill.
        IssueVendorBill(CreateVendorBill(VendorNo));

        // Verify: Verify Vendor Bill can be reissued.
        FindVendorBillLine(VendorBillLine, VendorNo);
        FindVendorBillHeader(VendorBillHeader, VendorBillLine."Vendor Bill List No.", VendorBillHeader."List Status"::Sent);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineAfterDeletingIssuedVendorBillLine()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillHeader2: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
    begin
        // Test to verify Vendor Bill Lines can be resuggested after deleting Issued Vendor Bill Line.

        // Setup: Create vendor, post Purchase Invoice, Issue Vendor Bill and delete Issued Vendor Bill Line, Create new Vendor Bill Header.
        Initialize();
        VendorNo := CreateVendor();
        IssueVendorBillAfterPostingPurchaseInvoice(VendorBillLine, VendorNo);
        FindVendorBillHeader(VendorBillHeader, VendorBillLine."Vendor Bill List No.", VendorBillHeader."List Status"::Sent);
        VendorBillLine.Delete(true);
        CreateVendorBillHeader(VendorBillHeader2);

        // Exercise.
        RunSuggestVendorBills(VendorBillHeader2, VendorNo);

        // Verify:  Verify Vendor Bill Lines can be resuggested.
        FindAndVerifyVendorBillLines(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResuggestVendorBillLineAfterDeletingVendorBillLine()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
    begin
        // Test to verify Vendor Bill Lines can be resuggested after deleting Vendor Bill Line.

        // Setup: Create vendor, post Purchase Invoice, Create Vendor Bill and delete Vendor Bill Line.
        Initialize();
        VendorNo := CreateVendor();
        CreateAndPostPurchaseInvoice(VendorNo, LibraryRandom.RandDec(10, 2));  // Using Random for Direct Unit Cost.
        CreateVendorBill(VendorNo);
        FindVendorBillLine(VendorBillLine, VendorNo);
        VendorBillLine.Delete(true);
        FindVendorBillHeader(VendorBillHeader, VendorBillLine."Vendor Bill List No.", VendorBillHeader."List Status"::Open);

        // Exercise.
        RunSuggestVendorBills(VendorBillHeader, VendorNo);

        // Verify: Verify vendor Bill LInes are resuggested.
        FindAndVerifyVendorBillLines(VendorNo);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure ReinsertVendorBillLineManuallyWithoutWithholdingTax()
    begin
        // Test to verify Vendor Bill Lines can be re-inserted manually after deleting Vendor Bill Line without Withholding Tax Code.
        Initialize();
        ReinsertVendorBillLineManually('');  // Blank for Withhold code.
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure ReinsertVendorBillLineManuallyWithWithholdingTax()
    begin
        // Test to verify Vendor Bill Lines can be re-inserted manually after deleting Vendor Bill Line with Withholding Tax Code.
        Initialize();
        ReinsertVendorBillLineManually(CreateWithholdCodeWithLine());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentMethodOnPostedSalesInvoice()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
    begin
        // Test to verify Shipment method code on Posted Sales Invoice Header after validating Intra Shipping Code of Shipping Method.

        // Setup: Create Customer and update Shipment method on Customer.
        Initialize();
        CreateCustomerWithShipmentMethod(Customer);
        CreateSalesInvoice(SalesLine, Customer."No.");

        // Exercise.
        PostSalesInvoice(SalesLine);

        // Verify: Verify Shipment method code on Posted Sales Invoice Header
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ApplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillListAfterUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // Verify Vendor Bill is successfully posted after the payment is Unapplied.

        // Setup: Create Vendor, create and post Purchase Invoice, create and issue Vendor Bill, Apply and Unapply Vendor Ledger Entry.
        Initialize();
        VendorNo := CreateVendor();
        DocumentNo := ApplyToDocumentAfterIssueVendorBill(VendorNo, GenJournalLine."Document Type"::Payment);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        FindVendorLedgerEntry(VendorLedgerEntry2, VendorNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry2);
        VendorLedgerEntry.CalcFields(Amount);

        // Exercise.
        PostVendorBillList(VendorLedgerEntry."Vendor Bill List");

        // Verify: Verify vendor bill is successfully posted.
        PostedVendorBillLine.SetRange("Vendor No.", VendorNo);
        PostedVendorBillLine.FindFirst();
        PostedVendorBillLine.TestField("Amount to Pay", -VendorLedgerEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchHeaderPrepPaymentTermCode()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test to verify initialization of Purchase Header field Prepmt. Payment Terms Code

        // Setup.
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithMultiplePaymentLines());
        Vendor.Validate("Prepmt. Payment Terms Code", CreatePaymentTermsCode());
        Vendor.Modify(true);

        // Exercise.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // Verify.
        Assert.AreEqual(
          PurchaseHeader."Prepmt. Payment Terms Code",
          Vendor."Prepmt. Payment Terms Code",
          IncorrectPrepmtPaymentTermsCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPrepPaymentTermCode()
    var
        Vendor: Record Vendor;
    begin
        // Test to verify that it is impossible to use payment terms
        // with multilply payment lines for vendor's Prepmt. Payment Terms Code

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        asserterror Vendor.Validate("Prepmt. Payment Terms Code", CreatePaymentTermsWithMultiplePaymentLines());

        // Verify.
        Assert.ExpectedError(PrepmtPaymtTermCodeValidationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddPaymentLineToPrepPaymentTerm_Vendor()
    var
        PaymentLines: Record "Payment Lines";
        PrepmtPaymentTermsCode: Code[10];
    begin
        // Test to verify that it is not possible to add new payments line to payment term
        // if it is already defined for vendors with "Prepmt. Payment Terms Code"

        // Setup.
        PrepmtPaymentTermsCode := SetPrepmtPmtTermsCodeOnVendor();

        // Exercise.
        asserterror LibraryERM.CreatePaymentLinesDiscount(PaymentLines, PrepmtPaymentTermsCode);

        // Verify.
        Assert.ExpectedError(OnlyOnePayLineAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePaymentLineFromPrepPaymentTerm_Vendor()
    var
        PrepmtPaymentTermsCode: Code[10];
    begin
        // Test to verify that it is not possible to delete payments line from payment term
        // if it is already defined for vendors with "Prepmt. Payment Terms Code"

        // Setup.
        PrepmtPaymentTermsCode := SetPrepmtPmtTermsCodeOnVendor();

        // Exercise.
        asserterror DeletePaymentLine(PrepmtPaymentTermsCode);

        // Verify.
        Assert.ExpectedError(OnlyOnePayLineAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddPaymentLineToPrepPaymentTerm_PurchHeader()
    var
        PaymentLines: Record "Payment Lines";
        PrepmtPaymentTermsCode: Code[10];
    begin
        // Test to verify that it is not possible to add new payments line to payment term
        // if it is already defined for purchase document with "Prepmt. Payment Terms Code"

        // Setup.
        PrepmtPaymentTermsCode := SetPrepmtPmtTermsCodeOnInvoice();

        // Exercise.
        asserterror LibraryERM.CreatePaymentLinesDiscount(PaymentLines, PrepmtPaymentTermsCode);

        // Verify.
        Assert.ExpectedError(OnlyOnePayLineAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePaymentLineFromPrepPaymentTerm_PurchHeader()
    var
        PrepmtPaymentTermsCode: Code[10];
    begin
        // Test to verify that it is not possible to delete payments line from payment term
        // if it is already defined for purchase document with "Prepmt. Payment Terms Code"

        // Setup.
        PrepmtPaymentTermsCode := SetPrepmtPmtTermsCodeOnInvoice();

        // Exercise.
        asserterror DeletePaymentLine(PrepmtPaymentTermsCode);

        // Verify.
        Assert.ExpectedError(OnlyOnePayLineAllowedErr);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseVendorLedgerEntryAfterUnApply()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        VendorNo: Code[20];
    begin
        // Test to verify no extra lines generated in G/L Entry and G/L Book Entry for Vendor.

        // Setup: Create and post Purchase Invoice. Unapply payment Vendor Ledger Entry.
        Initialize();
        VendorNo := CreateVendor();
        CreateAndPostPurchaseInvoice(VendorNo, LibraryRandom.RandDec(10, 2));
        ApplyAndPostGeneralJournalLine(
          VendorNo, 0, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Payment);
        FindVendorLedgerEntry(VendLedgerEntry, VendorNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgerEntry);
        ReversalEntry.SetHideDialog(true);

        // Exercise: Reverse Posted Payment Entry from Vendor Ledger Entry.
        ReversalEntry.ReverseTransaction(VendLedgerEntry."Transaction No.");

        // Verify no extra lines generated in G/L Entry and G/L Book Entry for Vendor.
        FindLastVendorLedgerEntry(VendLedgerEntry, VendorNo);
        VerifyGLEntry(VendLedgerEntry."Transaction No.");
        VerifyGLBookEntry(VendLedgerEntry."Transaction No.");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCustomerLedgerEntryAfterUnApply()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        CustomerNo: Code[20];
    begin
        // Test to verify no extra lines generated in G/L Entry and G/L Book Entry for Customer.

        // Setup: Create and post Sales Invoice. Unapply payment Customer Ledger Entry.
        Initialize();
        CustomerNo := CreateCustomer(''); // Blank value for PaymentTermsCode.
        CreateAndPostSalesInvoice(CustomerNo);
        ApplyAndPostGeneralJournalLine(
          CustomerNo, 0, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment);
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Payment);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        ReversalEntry.SetHideDialog(true);

        // Exercise: Reverse Posted Payment Entry from Customer Ledger Entry.
        ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Verify no extra lines generated in G/L Entry and G/L Book Entry for Customer.
        FindLastCustomerLedgerEntry(CustLedgerEntry, CustomerNo);
        VerifyGLEntry(CustLedgerEntry."Transaction No.");
        VerifyGLBookEntry(CustLedgerEntry."Transaction No.");
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankRcptTempNoOnPmtEntryAfterRecallIssuedCustomerBill()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // [SCENARIO 360400] Test to verify "Bank Receipt Temp No." on Customer Ledger Entry after recall Issued Customer Bill.

        // [GIVEN] Posted Customer Bill after Issue Bank Receipt for Posted Sales Invoice.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, CreatePaymentTermsWithMultiplePaymentLines(), WorkDate());
        CreateAndPostCustomerBill(TempSalesLine."Sell-to Customer No.");

        // [WHEN] Recall Issued Customer Bill.
        RecallIssuedCustomerBill(TempSalesLine."Sell-to Customer No.");

        // [THEN] "Bank Receipt Temp No." of Payment Entry is equal to "Document No." of Invoice Entry.
        VerifyBankRcptTempNoOnCustLedgEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillLineWHTAmountAfterManualInsertWithoutWithholdingTax()
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
        VendorBillHeaderNo: Code[20];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Payables] [WHT]
        // [SCENARIO 374728] WHT Amount = 0 in Vendor Bill Line after manual insert with empty Wihholding Tax Code
        Initialize();

        // [GIVEN] Vendor with "Withholding Tax Code" = ''
        // [GIVEN] Create Vendor Bill Card. Invoke "Insert Vend. Bill Line Manual".
        // [GIVEN] Set "Withhold Tax Code" = ''.
        // [WHEN] Invoke "Insert Line".
        InsertVendorBillLineManually(VendorNo, VendorBillHeaderNo, TotalAmount, '');

        // [THEN] "Vendor Bill Line"."Withholding Tax Amount" = 0
        FindVendorBillLine(VendorBillLine, VendorNo);
        Assert.AreEqual(0, VendorBillLine."Withholding Tax Amount", VendorBillLine.FieldCaption("Withholding Tax Amount"));
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillLineWHTAmountAfterManualInsertWithWithholdingTax()
    var
        VendorBillLine: Record "Vendor Bill Line";
        WithholdCodeLine: Record "Withhold Code Line";
        VendorNo: Code[20];
        VendorBillHeaderNo: Code[20];
        TotalAmount: Decimal;
        ExpectedWHTAmount: Decimal;
    begin
        // [FEATURE] [Payables] [WHT]
        // [SCENARIO 374728] WHT Amount <> 0 in Vendor Bill Line after Manual insert with Wihholding Tax Code
        Initialize();

        // [GIVEN] Vendor with "Withholding Tax Code" = ''
        // [GIVEN] Create Vendor Bill Card. Invoke "Insert Vend. Bill Line Manual".
        // [GIVEN] Set "Withhold Tax Code" = 'WHTCode', where "Taxable Base %" = X,  "Withholding Tax %" = Y.
        // [WHEN] Invoke "Insert Line".
        WithholdCodeLine.Get(CreateWithholdCodeWithLine(), WorkDate());
        InsertVendorBillLineManually(VendorNo, VendorBillHeaderNo, TotalAmount, WithholdCodeLine."Withhold Code");

        // [THEN] "Vendor Bill Line"."Withholding Tax Amount" = Amount * X * Y
        FindVendorBillLine(VendorBillLine, VendorNo);
        ExpectedWHTAmount := Round(TotalAmount * WithholdCodeLine."Taxable Base %" * WithholdCodeLine."Withholding Tax %" / 10000);
        Assert.AreEqual(ExpectedWHTAmount, VendorBillLine."Withholding Tax Amount", VendorBillLine.FieldCaption("Withholding Tax Amount"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillWithBankExpenseGLAccVAT()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Expense] [Activity Code]
        // [SCENARIO 372284] Post Issued Vendor Bill with Bank Expense and Expense Bill Account No. with VAT setup
        Initialize();
        // [GIVEN] Posted Purchase Invoice with Activity Code = "A"
        VendorNo := CreateVendor();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        DocumentNo := CreateAndPostPurchaseInvoice(VendorNo, InvoiceAmount);
        // [GIVEN] Bill Posting Group with "Expense Bill Account No." = G/L Account with Gen. Posting Type = Purchase
        // [GIVEN] Vendor Bill with Bank Expense = 10 and suggested Invoice line
        CreateVendorBillWithBankExpense(
          VendorBillHeader, VendorNo, CreateGLAccount(),
          LibraryRandom.RandDecInDecimalRange(1, InvoiceAmount, 2));
        // [GIVEN] Issued Vendor Bill
        IssueVendorBill(VendorBillHeader."No.");
        // [WHEN] Issued Vendor Bill posted
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        PostVendorBillList(VendorLedgerEntry."Vendor Bill List");
        // [THEN] VAT Entry generated for Payment has Activity Code = "A".
        FindVATEntry(
          VATEntry, VendorBillHeader."Bank Expense", VATEntry."Document Type"::Payment,
          VendorLedgerEntry."Vendor Bill List");
        Assert.RecordIsNotEmpty(VATEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillWithBankExpenseGLAccNoVAT()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bank Expense] [Activity Code]
        // [SCENARIO 372284] Post Issued Vendor Bill with Bank Expense and Expense Bill Account No. with no VAT setup
        Initialize();
        // [GIVEN] Posted Purchase Invoice with Activity Code = "A"
        VendorNo := CreateVendor();
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        DocumentNo := CreateAndPostPurchaseInvoice(VendorNo, InvoiceAmount);
        // [GIVEN] Bill Posting Group with "Expense Bill Account No." = G/L Account with Gen. Posting Type = ""
        // [GIVEN] Vendor Bill with Bank Expense = 10 and suggested Invoice line
        CreateVendorBillWithBankExpense(
          VendorBillHeader, VendorNo, LibraryERM.CreateGLAccountNo(),
          LibraryRandom.RandDecInDecimalRange(1, InvoiceAmount, 2));
        // [GIVEN] Issued Vendor Bill
        IssueVendorBill(VendorBillHeader."No.");
        // [WHEN] Issued Vendor Bill posted
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        PostVendorBillList(VendorLedgerEntry."Vendor Bill List");
        // [THEN] No VAT Entry Generated with Activity Code = "A"
        FindVATEntry(
          VATEntry, VendorBillHeader."Bank Expense", VATEntry."Document Type"::Payment,
          VendorLedgerEntry."Vendor Bill List");
        Assert.RecordIsEmpty(VATEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDateAndMonthWHTEntryAndContributions()
    var
        IssuedVendorBillHeader: Record "Vendor Bill Header";
        VendorNo: Code[20];
        DocumentDate: Date;
    begin
        // [FEATURE] [WHT][Contributions]
        // [SCENARIO 379276] "Payment Date" of Withholding Tax and Contributions should contain value of "Posting Date" from "Posting Date" of Issued Vendor Bill List
        Initialize();

        // [GIVEN] Vendor with Withholding Tax and Contributions
        VendorNo := CreateVendorWithWithholdingTax();

        // [GIVEN] Issued vendor bill list
        CreateAndIssueVendorBillList(IssuedVendorBillHeader, DocumentDate, VendorNo);

        // [WHEN] Post issued vendor bill list with Posting date "15-01-2016" and Payment Date "20-01-2016"
        LibraryITLocalization.PostIssuedVendorBill(IssuedVendorBillHeader);

        // [THEN] Withholding tax entry contains
        // [THEN] Payment Date = "15-01-2016"
        // [THEN] Month = 1
        // [THEN] Year = 2016
        VerifyPmtDateWithholdingTaxEntry(
          VendorNo, DocumentDate, IssuedVendorBillHeader."Vendor Bill List No.", IssuedVendorBillHeader."Posting Date");

        // [THEN] Contributions entry contains
        // [THEN] Payment Date = "15-01-2016"
        // [THEN] Month = 1
        // [THEN] Year = 2016
        VerifyPmtDateContribution(
          VendorNo, DocumentDate, IssuedVendorBillHeader."Vendor Bill List No.", IssuedVendorBillHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RecallSecondCustomerBillAfterIssueTwoCustomerBill()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        BillPostingGroup: Record "Bill Posting Group";
        RecallEntryNo: Integer;
        DocumentNo: Code[20];
        PaymentEntryNo: Integer;
    begin
        // [FEATURE] [Sales] [UI] [Bill]
        // [SCENARIO 380843] Recall more than one customer bill if the "Allow Issue" field of the Bill Code is set to false

        Initialize();

        CreateCustomerWithPaymentMethod(Customer, false); // No "Allow Issue"

        // [GIVEN] Post 2 Sales Invoices
        CreateSalesInvoice(SalesLine, Customer."No.");
        PostSalesInvoice(SalesLine);
        CreateSalesInvoice(SalesLine, Customer."No.");
        DocumentNo := PostSalesInvoice(SalesLine);

        // [GIVEN] Posted Customer Bill for both invoices
        CreateBillPostingGroup(BillPostingGroup, Customer."Payment Method Code");
        CreateCustomerBill(CustomerBillHeader, Customer."No.", BillPostingGroup);
        PostCustomerBill(CustomerBillHeader);

        // [WHEN] Recall second posted invoice
        RecallLastInvoice(DocumentNo);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        PaymentEntryNo :=
            FindCLEDocumentToClose(Customer."No.", CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type", CustLedgerEntry."Document No.", CustLedgerEntry."Document Occurrence");
        RecallEntryNo :=
            FindCLEDocumentToClose(Customer."No.", CustLedgerEntry."Document Type"::" ", CustLedgerEntry."Document Type", CustLedgerEntry."Document No.", CustLedgerEntry."Document Occurrence");

        // [THEN] Recall Customer Ledger Entry is applied to the second customer bill issued
        FindAppliedCustLedgerEntry(DetailedCustLedgEntry, RecallEntryNo);
        DetailedCustLedgEntry.TestField("Cust. Ledger Entry No.", PaymentEntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineAndVerifyWithWithholdingTaxAmount()
    var
        VendorBillHeader2: Record "Vendor Bill Header";
        Vendor: Record Vendor;
        WithholdCode: Code[20];
    begin
        // [SCENARIO 454727]: Witholding tax amount is wrongly calculate when you have multiple payment installments in the Italian localization

        // [GIVEN] Setup: Create vendor, post Purchase Invoice, Issue Vendor Bill and delete Issued Vendor Bill Line, Create new Vendor Bill Header.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        WithholdCode := CreateWithholdCodeWithLine();
        Vendor.Validate("Withholding Tax Code", WithholdCode);
        Vendor.Validate("Payment Method Code", FindPaymentMethodAndBill());
        Vendor.Modify(true);

        // [GIVEN] Create and post Purchase Invoice and create vendor bill header
        CreateAndPostPurchaseInvoiceWithGL(Vendor, LibraryRandom.RandDec(10, 2));
        CreateAndModifyVendorBillHeaderWithPaymentMethod(VendorBillHeader2, Vendor."Payment Method Code");

        // [THEN] Exercise: Run Suggest Vendor Bills line
        RunSuggestVendorBills(VendorBillHeader2, Vendor."No.");

        // [VERIFY] Verify: Vendor Bill Line Amount
        FindAndVerifyVendorBillLinesAmount(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineVerifyWithholdingTaxAmount()
    var
        VendorBillHeader2: Record "Vendor Bill Header";
        Vendor: Record Vendor;
        WithholdCode: Code[20];
    begin
        // [SCENARIO 464755]: WWithholding tax amount not update correctly in Vendor bill in the Italian Localization

        // [GIVEN] Setup: Create vendor, post Purchase Invoice, Issue Vendor Bill and delete Issued Vendor Bill Line, Create new Vendor Bill Header.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        WithholdCode := CreateWithholdCodeWithLine();
        Vendor.Validate("Withholding Tax Code", WithholdCode);
        Vendor.Validate("Payment Method Code", FindPaymentMethodAndBill());
        Vendor.Modify(true);

        // [GIVEN] Create and post Purchase Invoice and create vendor bill header
        CreateAndPostPurchaseInvoiceWithGLByUpdatingWithHoldingTotalAmount(Vendor, LibraryRandom.RandDec(10, 2));
        CreateAndModifyVendorBillHeaderWithPaymentMethod(VendorBillHeader2, Vendor."Payment Method Code");

        // [THEN] Exercise: Run Suggest Vendor Bills line
        RunSuggestVendorBills(VendorBillHeader2, Vendor."No.");

        // [VERIFY] Verify: Vendor Bill Line Amount
        FindAndVerifyVendorBillLinesAmount(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorBillLineVerifyWithholdingTaxByUpdatingBaseExcludedAmount()
    var
        VendorBillHeader2: Record "Vendor Bill Header";
        Vendor: Record Vendor;
        WithholdCode: Code[20];
    begin
        // [SCENARIO 467725]: Withholding tax amount  when base excluded amount is used is  not update correctly in Vendor bill in the Italian Localization

        // [GIVEN] Setup: Create vendor, post Purchase Invoice, Issue Vendor Bill and delete Issued Vendor Bill Line, Create new Vendor Bill Header.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        WithholdCode := CreateWithholdCodeWithLine();
        Vendor.Validate("Withholding Tax Code", WithholdCode);
        Vendor.Validate("Payment Method Code", FindPaymentMethodAndBill());
        Vendor.Modify(true);

        // [GIVEN] Create and post Purchase Invoice and create vendor bill header
        CreateAndPostPurchaseInvoiceWithGLByUpdatingWithHoldingBaseExcludedAmount(Vendor, LibraryRandom.RandDec(10, 2));
        CreateAndModifyVendorBillHeaderWithPaymentMethod(VendorBillHeader2, Vendor."Payment Method Code");

        // [THEN] Exercise: Run Suggest Vendor Bills line
        RunSuggestVendorBills(VendorBillHeader2, Vendor."No.");

        // [VERIFY] Verify: Vendor Bill Line Amount
        FindAndVerifyVendorBillLinesAmount(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('SelectNoSeriesModalPageHandler')]
    procedure ContactAssistEditShouldUseSelectedNoSeries()
    var
        MarketingSetup: Record "Marketing Setup";
        NoSeriesLine: Record "No. Series line";
        ContactCard: TestPage "Contact Card";
        NoSeriesPage: TestPage "No. Series";
        SeriesCode: Code[20];
    begin
        // [SCENARIO 541942]: Contact Card should use selected No. Series in from assist edit.
        Initialize();

        // [GIVEN] Create No. Series Line.
        LibraryUtility.CreateNoSeriesLine(
            NoSeriesLine,
            LibraryERM.CreateNoSeriesCode(),
            LibraryUtility.GenerateGUID(),
            '');

        // [GIVEN] Store Series Code.
        SeriesCode := NoSeriesLine."Series Code";
        LibraryVariableStorage.Enqueue(SeriesCode);

        // [GIVEN] Get Marketing Setup and Create Relationship with Contact Nos. and Newly created No. Series.
        MarketingSetup.Get();
        LibraryUtility.CreateNoSeriesRelationship(MarketingSetup."Contact Nos.", NoSeriesLine."Series Code");

        // [WHEN] Open Contact Card and Assist Edit.
        NoSeriesPage.Trap();
        ContactCard.OpenNew();
        ContactCard."No.".AssistEdit();

        // [THEN] Contact No. should be assigned from newly created No. Series.
        NoSeriesLine.SetRange("Series Code", SeriesCode);
        NoSeriesLine.FindFirst();
        Assert.AreEqual(ContactCard."No.".Value(), NoSeriesLine."Last No. Used", ContactNoSeriesErr);
    end;

    [Test]
    procedure PostingSalesInvoiceUpdatesAnalysisView()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 560063] Posting Sales Invoice updates in Analysis View.
        Initialize();

        // [GIVEN] Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);

        // [GIVEN] Create VAT Business Posting Group.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);

        // [GIVEN] Create VAT Product Posting Group.
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);

        // [GIVEN] Create GL Account with VAT Product Posting Setup.
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Validate Update On Posting and Account Source in Analysis View.
        AnalysisView.Validate("Update on Posting", true);
        AnalysisView.Validate("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.Modify(true);

        // [GIVEN] Create Sales Header with Document Type Invoice.
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Invoice,
            LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Line with Type GL Account.
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::"G/L Account",
            GLAccount."No.",
            LibraryRandom.RandInt(2));

        // [GIVEN] Validate Unit Price in Sales Line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify();

        // [WHEN] Post Sales Document.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Last Entry No. on Analysis View is updated with GL Entry created by Sales Invoice.
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.FindLast();
        AnalysisView.Get(AnalysisView.Code);
        Assert.AreEqual(
            GLEntry."Entry No.",
            AnalysisView."Last Entry No.",
            StrSubstNo(
                AnalysisViewErr,
                GLEntry."Entry No.",
                AnalysisView.TableCaption()));
    end;

    [Test]
    procedure PostingPurchaseInvoiceUpdatesAnalysisView()
    var
        AnalysisView: Record "Analysis View";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 560063] Posting Purchase Invoice updates in Analysis View.
        Initialize();

        // [GIVEN] Create Analysis View.
        LibraryERM.CreateAnalysisView(AnalysisView);

        // [GIVEN] Create VAT Business Posting Group.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);

        // [GIVEN] Create VAT Product Posting Group.
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);

        // [GIVEN] Create VAT Posting Setup.
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);

        // [GIVEN] Create GL Account with VAT Product Posting Setup.
        LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);

        // [GIVEN] Validate Update On Posting and Account Source in Analysis View.
        AnalysisView.Validate("Update on Posting", true);
        AnalysisView.Validate("Account Source", AnalysisView."Account Source"::"G/L Account");
        AnalysisView.Modify(true);

        // [GIVEN] Create Purchase Header with Document Type Invoice.
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [GIVEN] Create Purchase Line with Type GL Account.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"G/L Account",
            GLAccount."No.",
            LibraryRandom.RandInt(2));

        // [GIVEN] Validate Unit Price in Purchase Line.
        PurchaseLine.Validate("Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify();

        // [WHEN] Post Purchase Document.
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Last Entry No. on Analysis View is updated with GL Entry created by Purchase Invoice.
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.FindLast();
        AnalysisView.Get(AnalysisView.Code);
        Assert.AreEqual(
            GLEntry."Entry No.",
            AnalysisView."Last Entry No.",
            StrSubstNo(
                AnalysisViewErr,
                GLEntry."Entry No.",
                AnalysisView.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandlerForInvoice,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DocumentOccurrenceUpdatedForManual()
    var
        BillPostingGroup: Record "Bill Posting Group";
        Vendor: Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
        ManualDocumentNo: Code[20];
        TotalAmount: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO 580570] Document Occurrence is updated for manual vendor bill line
        Initialize();

        // [GIVEN] Create Bill Posting Group with Payment Method and Bank Account No.
        CreateBillPostingGroupWithPmtMethodAndBill(BillPostingGroup);

        // [GIVEN] Create Vendor 
        VendorNo := CreateVendor(BillPostingGroup."Payment Method");
        Vendor.Get(VendorNo);

        // [GIVEN] Total Amount for Vendor Bill Line
        TotalAmount := LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Create Vendor Bill Header with Bill Posting Group and update Bank Account No. and Payment Method Code.
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);

        // [GIVEN] Create Manual Document No. for Vendor Bill Line
        ManualDocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Insert two Vendor Bill Lines manually with same details.
        LibraryVariableStorage.Enqueue(ManualDocumentNo);
        InsertVendorBillLineManual(VendorNo, '', TotalAmount, VendorBillHeader."No.");
        LibraryVariableStorage.Enqueue(ManualDocumentNo);
        InsertVendorBillLineManual(VendorNo, '', TotalAmount, VendorBillHeader."No.");

        // [WHEN] Issue Vendor Bill
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);

        // [WHEN] Post Vendor Bill List
        PostVendorBillList(VendorBillHeader."Vendor Bill List No.");

        // [THEN] Verify Document Occurrence for Vendor Ledger Entry
        VerifyDocumentOccurrenceVendorLedgerEntry(VendorNo, VendorBillHeader."Vendor Bill List No.");
    end;

    [Test]
    procedure TheBankReceiptAndAllowIssueUpdatedPaymentMethodCodeInCustomerLedgerEntries()
    var
        Bill: Record Bill;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Item: Record Item;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 597830] The 'Bank Receipt' and 'Allow Issue' are updated when changing the Payment Method Code from the Customer Ledger Entries.
        Initialize();

        // [GIVEN] Create Payment Method with Bill Code.
        PaymentMethod.Get(FindPaymentMethodAndBill());

        // [GIVEN] Update Bill with "Allow Issue" = true and "Bank Receipt" = true.
        Bill.Get(PaymentMethod."Bill Code");
        Bill.Validate("Allow Issue", true);
        Bill.Validate("Bank Receipt", true);
        Bill.Modify(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Header for the Customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Creare Sales Line with Item.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        // [GIVEN] Post Sales Document.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);


        // [GIVEN] Customer Ledger Entry created for the Customer.
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] Update Payment Method Code in Customer Ledger Entry.
        CustLedgerEntry.Validate("Payment Method Code", PaymentMethod.Code);
        CustLedgerEntry.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Cust. Entry-Edit", CustLedgerEntry);

        // [THEN] The "Allow Issue" and "Bank Receipt" fields are true in the Customer Ledger Entry.
        Assert.IsTrue(
            CustLedgerEntry."Allow Issue",
            StrSubstNo(
                CustomerLedgerEntryErr,
                CustLedgerEntry."Allow Issue",
                true,
                CustLedgerEntry.TableName()));
        Assert.IsTrue(
            CustLedgerEntry."Bank Receipt",
            StrSubstNo(
                CustomerLedgerEntryErr,
                CustLedgerEntry."Bank Receipt",
                true,
                CustLedgerEntry.TableName()));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure ReinsertVendorBillLineManually(WithholdCode: Code[20])
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
        VendorBillHeaderNo: Code[20];
        TotalAmount: Decimal;
    begin
        // Setup: Create vendor, post Purchase Invoice, Create Vendor Bill Header and Insert Vendor BIll Lines manually, delete Vendor Bill Lines.
        InsertVendorBillLineManually(VendorNo, VendorBillHeaderNo, TotalAmount, WithholdCode);
        FindVendorBillLine(VendorBillLine, VendorNo);
        VendorBillLine.Delete(true);

        // Exercise.
        InsertVendorBillLineManual(VendorNo, WithholdCode, TotalAmount, VendorBillHeaderNo);

        // Verify: Verify Vendor Bill Lines can be reinserted.
        FindAndVerifyVendorBillLines(VendorNo);
    end;

    local procedure InsertVendorBillLineManually(var VendorNo: Code[20]; var VendorBillHeaderNo: Code[20]; var TotalAmount: Decimal; WithholdCode: Code[20])
    var
        Vendor: Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        VendorNo := CreateVendor();
        CreateAndPostPurchaseInvoice(VendorNo, LibraryRandom.RandDecInRange(100, 200, 2));
        CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeaderNo := VendorBillHeader."No.";
        Vendor.Get(VendorNo);
        Vendor.CalcFields(Balance);
        TotalAmount := Vendor.Balance;
        InsertVendorBillLineManual(VendorNo, WithholdCode, TotalAmount, VendorBillHeader."No.");
    end;

    local procedure ApplyAndPostGeneralJournalLine(CustomerNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, CustomerNo, Amount, AccountType, DocumentType);
        ApplyGenJournalLine(GenJournalLine."Journal Batch Name");
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyGenJournalLine(GenJournalBatchName: Code[10])
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        Commit();  // COMMIT is required for Write Transaction Error.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.CurrentJnlBatchName.SetValue(GenJournalBatchName);
        CashReceiptJournal."Applies-to Doc. No.".Lookup();  // Invoke ApplyCustomerEntriesModalPageHandler, ApplyVendorEntriesModalPageHandler.
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure ApplyToDocumentAfterIssueVendorBill(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo := CreateAndPostPurchaseInvoice(VendorNo, Amount);
        IssueVendorBill(CreateVendorBill(VendorNo));
        ApplyAndPostGeneralJournalLine(VendorNo, Amount, GenJournalLine."Account Type"::Vendor, DocumentType);
    end;

    local procedure CreateCustomerWithShipmentMethod(var Customer: Record Customer)
    begin
        Customer.Get(CreateCustomer(''));  // Blank for Payment Terms code.
        Customer.Validate("Shipment Method Code", FindAndUpdateShipmentMethod());
        Customer.Modify(true);
    end;

    local procedure CreateAndPostCustomerBill(CustomerNo: Code[20])
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        CreateCustomerBillHeader(CustomerBillHeader);
        RunSuggestCustomerBill(CustomerBillHeader, CustomerNo);
        UpdateBillsForCollAccNoOnBillPostingGroup(
          CustomerBillHeader."Bank Account No.", CustomerBillHeader."Payment Method Code");
        PostCustomerBill(CustomerBillHeader);
    end;

    local procedure CreateAndPostMultipleCashReceiptGenJournalLines(GenJournalBatch: Record "Gen. Journal Batch") Amount: Decimal
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(100, 2));  // Use random value for Amount.
        Amount := GenJournalLine.Amount;
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(100, 2));  // Use random Value for Amount.
        GenJournalLine.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Using random date to post General Journal Lines with different dates.
        Amount += GenJournalLine.Amount;
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateSalesInvoice(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; DirectUnitCost: Decimal): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(10, 20, 2));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoice(SalesLine, CustomerNo);
        PostSalesInvoice(SalesLine);
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", FindPaymentMethod());
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBillHeader(var CustomerBillHeader: Record "Customer Bill Header")
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        BillPostingGroup.SetRange("Payment Method", FindPaymentMethod());
        BillPostingGroup.FindFirst();
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
    end;

    local procedure CreateCustomerWithDimension() CustomerNo: Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        CustomerNo := CreateCustomer(CreatePaymentTermsCode());
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateCashReceiptsJournalBatch(GenJournalBatch, '');  // Blank value for Currency code.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
    end;

    local procedure CreatePaymentTermsCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        LibraryERM.CreatePaymentLinesDiscount(PaymentLines, PaymentTerms.Code);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePaymentTermsWithMultiplePaymentLines(): Code[10]
    var
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentLinesDiscount(PaymentLines, CreatePaymentTermsCode());
        exit(PaymentLines.Code);
    end;

    local procedure CreateCashReceiptsJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; CurrencyCode: Code[10])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", CreateBankAccount(CurrencyCode));
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", FindPaymentMethod());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithWithholdingTax(): Code[20]
    var
        Vendor: Record Vendor;
        ContributionCode: Record "Contribution Code";
        ContributionCode2: Record "Contribution Code";
    begin
        CreateContributionCodeWithLine(ContributionCode, ContributionCode."Contribution Type"::INAIL);
        CreateContributionCodeWithLine(ContributionCode2, ContributionCode2."Contribution Type"::INPS);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Withholding Tax Code", CreateWithholdCodeWithLine());
        Vendor.Validate("Social Security Code", ContributionCode2.Code);
        Vendor.Validate("INAIL Code", ContributionCode.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBill(VendorNo: Code[20]): Code[20]
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        CreateVendorBillHeader(VendorBillHeader);
        RunSuggestVendorBills(VendorBillHeader, VendorNo);
        exit(VendorBillHeader."No.");
    end;

    local procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header")
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, CreateBankAccount(''), FindPaymentMethod());  // Blank value for Currency Code.
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
    end;

    local procedure CreateVendorBillWithBankExpense(var VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20]; GLAccountNo: Code[20]; BankExpenseAmount: Decimal)
    begin
        VendorBillHeader.Get(CreateVendorBill(VendorNo));
        UpdateBillPostingGroupExpenseBillAccount(
          VendorBillHeader."Bank Account No.", VendorBillHeader."Payment Method Code", GLAccountNo);
        VendorBillHeader.Validate("Bank Expense", BankExpenseAmount);
        VendorBillHeader.Modify(true);
    end;

    local procedure CreateWithholdCodeWithLine(): Code[20]
    var
        GLAccount: Record "G/L Account";
        WithholdCode: Record "Withhold Code";
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryITLocalization.CreateWithholdCode(WithholdCode);
        WithholdCode.Validate("Withholding Taxes Payable Acc.", GLAccount."No.");
        WithholdCode.Validate("Tax Code", Format(LibraryRandom.RandIntInRange(1000, 9999)));
        WithholdCode.Modify(true);
        LibraryITLocalization.CreateWithholdCodeLine(WithholdCodeLine, WithholdCode.Code, WorkDate());
        WithholdCodeLine.Validate("Withholding Tax %", LibraryRandom.RandDecInRange(10, 20, 2));
        WithholdCodeLine.Validate("Taxable Base %", LibraryRandom.RandDecInRange(10, 20, 2));
        WithholdCodeLine.Modify(true);
        exit(WithholdCode.Code);
    end;

    local procedure CreateAndIssueVendorBillList(var VendorBillHeader: Record "Vendor Bill Header"; var DocumentDate: Date; VendorNo: Code[20])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        CreateBillPostingGroupWithPmtMethodAndBill(BillPostingGroup);
        DocumentDate := CreatePostPurchaseInvoice(VendorNo, BillPostingGroup."Payment Method");
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        RunSuggestVendorBills(VendorBillHeader, VendorNo);
        LibraryITLocalization.IssueVendorBill(VendorBillHeader);
        VendorBillHeader.Validate(
          "Posting Date", CalcDate(StrSubstNo('<+%1M>', LibraryRandom.RandIntInRange(1, 11)), VendorBillHeader."Posting Date"));
        VendorBillHeader.Modify(true);
    end;

    local procedure CreateBillPostingGroupWithPmtMethodAndBill(var BillPostingGroup: Record "Bill Posting Group")
    var
        PaymentMethod: Record "Payment Method";
        Bill: Record Bill;
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateBill(Bill);
        Bill.Validate("Vendor Bill List", LibraryUtility.GetGlobalNoSeriesCode());
        Bill.Validate("Vendor Bill No.", LibraryUtility.GetGlobalNoSeriesCode());
        Bill.Modify(true);
        PaymentMethod.Validate("Bill Code", Bill.Code);
        PaymentMethod.Modify(true);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, LibraryERM.CreateBankAccountNo(), PaymentMethod.Code);
    end;

    local procedure CreatePostPurchaseInvoice(VendorNo: Code[20]; PaymentMethod: Code[10]): Date
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod);
        PurchaseHeader.Modify(true);
        WithholdingContribution.CalculateWithholdingTax(PurchaseHeader, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."Document Date");
    end;

    local procedure CreateContributionCode(var ContributionCode: Record "Contribution Code"; ContributionType: Option)
    begin
        LibraryITLocalization.CreateContributionCode(ContributionCode, ContributionType);
        ContributionCode.Validate("Social Security Payable Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Validate("Social Security Charges Acc.", LibraryERM.CreateGLAccountNo());
        ContributionCode.Modify(true);
    end;

    local procedure CreateContributionCodeWithLine(var ContributionCode: Record "Contribution Code"; ContributionType: Option)
    var
        ContributionCodeLine: Record "Contribution Code Line";
    begin
        CreateContributionCode(ContributionCode, ContributionType);
        LibraryITLocalization.CreateContributionCodeLine(
          ContributionCodeLine, ContributionCode.Code, WorkDate(), ContributionCode."Contribution Type");
        ContributionCodeLine.Validate("Social Security %", LibraryRandom.RandIntInRange(5, 10));
        ContributionCodeLine.Validate("Free-Lance Amount %", LibraryRandom.RandIntInRange(10, 20));
        ContributionCodeLine.Validate(
          "Social Security Bracket Code", CreateContributionBracketWithLine(ContributionType));
        ContributionCodeLine.Modify(true)
    end;

    local procedure CreateContributionBracketWithLine(ContributionType: Option): Code[10]
    var
        ContributionBracket: Record "Contribution Bracket";
        ContributionBracketLine: Record "Contribution Bracket Line";
    begin
        LibraryITLocalization.CreateContributionBracket(ContributionBracket, ContributionType);
        LibraryITLocalization.CreateContributionBracketLine(
          ContributionBracketLine, ContributionBracket.Code, LibraryRandom.RandIntInRange(10000, 99999),
          ContributionBracket."Contribution Type");
        ContributionBracketLine.Validate("Taxable Base %", LibraryRandom.RandIntInRange(10, 20));
        ContributionBracketLine.Modify(true);
        exit(ContributionBracket.Code);
    end;

    local procedure CreateCustomerWithPaymentMethod(var Customer: Record Customer; AllowIssue: Boolean)
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        Customer.Get(CreateCustomer(''));
        PaymentMethod.Get(Customer."Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");
        Bill.Validate("Allow Issue", AllowIssue);
        Bill.Modify(true);
    end;

    local procedure CreateBillPostingGroup(var BillPostingGroup: Record "Bill Posting Group"; PaymentMethod: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", PaymentMethod);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Modify(true);
        exit(BillPostingGroup."No.");
    end;

    local procedure CreateCustomerBill(var CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20]; BillPostingGroup: Record "Bill Posting Group")
    begin
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
        RunSuggestCustomerBill(CustomerBillHeader, CustomerNo);
    end;

    local procedure DeleteCustomerBillLine(CustomerBillNo: Code[20]; CustomerNo: Code[20])
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        FindCustomerBillLine(CustomerBillLine, CustomerBillNo, CustomerNo);
        CustomerBillLine.Delete(true);
    end;

    local procedure EnqueueValuesForRequestPageHandler(Value: Variant; Value2: Variant)
    begin
        LibraryVariableStorage.Enqueue(Value);
        LibraryVariableStorage.Enqueue(Value2);
    end;

    local procedure FindBillCode(): Code[20]
    var
        Bill: Record Bill;
    begin
        Bill.SetRange("Allow Issue", true);
        Bill.SetRange("Bank Receipt", true);
        Bill.FindFirst();
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    local procedure FindCustomerBillLine(var CustomerBillLine: Record "Customer Bill Line"; CustomerBillNo: Code[20]; CustomerNo: Code[20])
    begin
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillNo);
        CustomerBillLine.SetRange("Customer No.", CustomerNo);
        CustomerBillLine.FindFirst();
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindLastCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();
    end;

    local procedure FindVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorNo: Code[20])
    begin
        VendorBillLine.SetRange("Vendor No.", VendorNo);
        VendorBillLine.FindFirst();
    end;

    local procedure FindVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header"; No: Code[20]; ListStatus: Option)
    begin
        VendorBillHeader.SetRange("No.", No);
        VendorBillHeader.SetRange("List Status", ListStatus);
        VendorBillHeader.FindFirst();
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindLastVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindLast();
    end;

    local procedure FindIssuedCustomerBillLine(var IssuedCustomerBillLine: Record "Issued Customer Bill Line"; CustomerNo: Code[20])
    begin
        IssuedCustomerBillLine.SetRange("Customer No.", CustomerNo);
        IssuedCustomerBillLine.FindFirst();
    end;

    local procedure FindAndUpdateShipmentMethod(): Code[10]
    var
        EntryExitPoint: Record "Entry/Exit Point";
        ShipmentMethod: Record "Shipment Method";
    begin
        EntryExitPoint.FindFirst();
        ShipmentMethod.FindFirst();
        ShipmentMethod.Validate("Intra Shipping Code", EntryExitPoint.Code);
        ShipmentMethod.Modify(true);
        exit(ShipmentMethod.Code);
    end;

    local procedure FindAndVerifyVendorBillLines(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorBillLine: Record "Vendor Bill Line";
    begin
        Vendor.Get(VendorNo);
        Vendor.CalcFields(Balance);
        FindVendorBillLine(VendorBillLine, Vendor."No.");
        Assert.AreEqual(
          Vendor.Balance,
          VendorBillLine."Amount to Pay" + VendorBillLine."Withholding Tax Amount",
          StrSubstNo(AmountErr, VendorBillLine.FieldCaption("Amount to Pay"), Vendor.Balance, VendorBillLine.TableCaption()));
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Bill Code", FindBillCode());
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; BaseAmount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange(Base, BaseAmount);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure FindAppliedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryNo: Integer)
    begin
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntry.SetFilter("Cust. Ledger Entry No.", '<>%1', EntryNo);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure FindCLEDocumentToClose(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentTypeToClose: Enum "Gen. Journal Document Type"; DocumentNoToClose: Code[20]; DocumentOccurrenceToClose: Integer): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document Type to Close", DocumentTypeToClose);
        CustLedgerEntry.SetRange("Document No. to Close", DocumentNoToClose);
        CustLedgerEntry.SetRange("Document Occurrence to Close", DocumentOccurrenceToClose);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure GetIssuedCustomerBillHeaderNo(CustomerNo: Code[20]): Code[20]
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        FindIssuedCustomerBillLine(IssuedCustomerBillLine, CustomerNo);
        IssuedCustomerBillHeader.SetRange("No.", IssuedCustomerBillLine."Customer Bill No.");
        IssuedCustomerBillHeader.FindFirst();
        exit(IssuedCustomerBillHeader."No.");
    end;

    local procedure GetClosingBankRcptDate(): Date
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        RiskPeriod: DateFormula;
    begin
        SalesReceivablesSetup.Get();
        Evaluate(RiskPeriod, '<-' + Format(SalesReceivablesSetup."Bank Receipts Risk Period") + '>');
        exit(CalcDate(RiskPeriod, WorkDate()));
    end;

    local procedure IssueBankReceiptAfterPostingSalesInvoice(var TempSalesLine: Record "Sales Line" temporary; PaymentTermsCode: Code[10]; StartingDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoice(SalesLine, CreateCustomer(PaymentTermsCode));
        TempSalesLine := SalesLine;
        PostSalesInvoice(SalesLine);
        EnqueueValuesForRequestPageHandler(StartingDate, TempSalesLine."Sell-to Customer No.");  // Enqueue values in IssuingCustomerBillRequestPageHandler.
        REPORT.Run(REPORT::"Issuing Customer Bill");
    end;

    local procedure IssueVendorBillAfterPostingPurchaseInvoice(var VendorBillLine: Record "Vendor Bill Line"; VendorNo: Code[20])
    begin
        CreateAndPostPurchaseInvoice(VendorNo, LibraryRandom.RandDec(10, 2));  // Using Random for Direct Unit Cost.
        IssueVendorBill(CreateVendorBill(VendorNo));
        FindVendorBillLine(VendorBillLine, VendorNo);
    end;

    local procedure InsertVendorBillLineManual(VendorNo: Code[20]; WithholdCode: Code[20]; TotalAmount: Decimal; No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        // Enqueue for ManualVendorPaymentLinePageHandler.
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(WithholdCode);
        LibraryVariableStorage.Enqueue(TotalAmount);
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard.InsertVendBillLineManual.Invoke();  // Opens ManualVendorPaymentLinePageHandler.
        VendorBillCard.Close();
    end;

    local procedure IssueVendorBill(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard."&Create List".Invoke();
    end;

    local procedure PostCustomerBill(CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillPost: Codeunit "Customer Bill - Post + Print";
    begin
        CustomerBillPost.SetHidePrintDialog(true);
        CustomerBillPost.Code(CustomerBillHeader);
    end;

    local procedure PostSalesInvoice(SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Ship and Invoice Sales Document.
    end;

    local procedure PostVendorBillList(VendorBillListNo: Code[20])
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("Vendor Bill List No.", VendorBillListNo);
        VendorBillListSentCard.Post.Invoke();
    end;

    local procedure PostVendorBillListFromVendorBillListSentCard(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Exercise.
        asserterror PostVendorBillList(VendorLedgerEntry."Vendor Bill List");

        // Verify: Verify error on while posting Vendor Bill List.
        VendorLedgerEntry.CalcFields("Remaining Amount");
        Assert.ExpectedError(StrSubstNo(VendorBillListErr, DocumentNo, -VendorLedgerEntry."Remaining Amount"));
    end;

    local procedure RecallIssuedCustomerBill(CustomerNo: Code[20])
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
        RecallCustomerBill: Codeunit "Recall Customer Bill";
        IssuedCustomerBillCard: TestPage "Issued Customer Bill Card";
    begin
        FindIssuedCustomerBillLine(IssuedCustomerBillLine, CustomerNo);
        IssuedCustomerBillCard.OpenEdit();
        IssuedCustomerBillCard.FILTER.SetFilter("No.", IssuedCustomerBillLine."Customer Bill No.");
        IssuedCustomerBillCard.BankReceiptsLines.SelectBillToRecall.Invoke();
        IssuedCustomerBillCard.OK().Invoke();
        RecallCustomerBill.RecallIssuedBill(IssuedCustomerBillLine);
    end;

    local procedure RecallUnpostedCustomerBill(No: Code[20])
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        CustomerBillCard.OpenEdit();
        CustomerBillCard.FILTER.SetFilter("No.", No);
        CustomerBillCard.CustomerBillLine.SelectBillToRecall.Invoke();
        CustomerBillCard."Recall Customer Bill".Invoke();
        CustomerBillCard.OK().Invoke();
    end;

    local procedure RecallLastInvoice(DocumentNo: Code[20])
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
        RecallCustomerBill: Codeunit "Recall Customer Bill";
    begin
        IssuedCustomerBillLine.SetRange("Document No.", DocumentNo);
        IssuedCustomerBillLine.FindLast();
        IssuedCustomerBillLine.Validate("Recalled by", UserId);
        IssuedCustomerBillLine.Modify(true);
        RecallCustomerBill.RecallIssuedBill(IssuedCustomerBillLine);
    end;

    local procedure RunSuggestCustomerBill(CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Text)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentMethod: Record "Payment Method";
        Bill: Record Bill;
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        Clear(SuggestCustomerBills);
        CustLedgerEntry.SetFilter("Customer No.", CustomerNo);
        PaymentMethod.Get(CustomerBillHeader."Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");
        SuggestCustomerBills.InitValues(CustomerBillHeader, Bill."Allow Issue");
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

    local procedure UpdateBlockedCustomerToAll(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate(Blocked, Customer.Blocked::All);
        Customer.Modify(true);
    end;

    local procedure UpdateBlockedVendorToAll(VendorNo: Code[20]; Blocked: Enum "Vendor Blocked")
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate(Blocked, Blocked);
        Vendor.Modify(true);
    end;

    local procedure UpdateCustomerBillLine(CustomerBillNo: Code[20]; CustomerNo: Code[20])
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        FindCustomerBillLine(CustomerBillLine, CustomerBillNo, CustomerNo);
        CustomerBillLine.Validate("Cumulative Bank Receipts", true);
        CustomerBillLine.Modify(true);
    end;

    local procedure UpdateBillsForCollAccNoOnBillPostingGroup(BankAccNo: Code[20]; PaymentMethodCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        BillPostingGroup.Get(BankAccNo, PaymentMethodCode);
        LibraryERM.CreateGLAccount(GLAccount);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", GLAccount."No.");
        BillPostingGroup.Modify(true);
    end;

    local procedure UpdateBillPostingGroupExpenseBillAccount(No: Code[20]; PaymentMethodCode: Code[10]; GLAccountNo: Code[20])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        BillPostingGroup.Get(No, PaymentMethodCode);
        BillPostingGroup.Validate("Expense Bill Account No.", GLAccountNo);
        BillPostingGroup.Modify(true);
    end;

    local procedure VerifyCustomerLedgerEntry(Amount: Decimal; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType);
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyBankRcptTempNoOnCustLedgEntry(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType);
        Assert.AreEqual(
          CustLedgerEntry."Document No.", CustLedgerEntry."Bank Receipt Temp. No.", IncorrectBankRcptTempNoErr);
    end;

    local procedure VerifyDetailedCustomerLedgerEntry(CustomerNo: Code[20]; PostingDate: Date)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyGLEntry(TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.FindSet();
        Assert.AreEqual(2, GLEntry.Count, GLEntryErr); // 2 is important since there must be two lines with balance.
    end;

    local procedure VerifyGLBookEntry(TransactionNo: Integer)
    var
        GLBookEntry: Record "GL Book Entry";
    begin
        GLBookEntry.SetRange("Transaction No.", TransactionNo);
        GLBookEntry.FindSet();
        Assert.AreEqual(2, GLBookEntry.Count, GLBookEntryErr); // 2 is important since there must be two lines with balance.
    end;

    local procedure VerifyPmtDateWithholdingTaxEntry(VendorNo: Code[20]; DocumentDate: Date; DocumentNo: Code[20]; PostingDate: Date)
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.SetRange("Vendor No.", VendorNo);
        WithholdingTax.SetRange("Document Date", DocumentDate);
        WithholdingTax.SetRange("Document No.", DocumentNo);
        WithholdingTax.FindFirst();
        WithholdingTax.TestField("Payment Date", PostingDate);
        WithholdingTax.TestField(Month, Date2DMY(PostingDate, 2));
        WithholdingTax.TestField(Year, Date2DMY(PostingDate, 3));
    end;

    local procedure VerifyPmtDateContribution(VendorNo: Code[20]; DocumentDate: Date; DocumentNo: Code[20]; PostingDate: Date)
    var
        Contributions: Record Contributions;
    begin
        Contributions.SetRange("Vendor No.", VendorNo);
        Contributions.SetRange("Document Date", DocumentDate);
        Contributions.SetRange("Document No.", DocumentNo);
        Contributions.FindFirst();
        Contributions.TestField("Payment Date", PostingDate);
        Contributions.TestField(Month, Date2DMY(PostingDate, 2));
        Contributions.TestField(Year, Date2DMY(PostingDate, 3));
    end;

    local procedure SetPrepmtPmtTermsCodeOnVendor() PrepmtPaymentTermsCode: Code[10]
    var
        Vendor: Record Vendor;
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        PrepmtPaymentTermsCode := CreatePaymentTermsCode();
        Vendor.Validate("Prepmt. Payment Terms Code", PrepmtPaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure SetPrepmtPmtTermsCodeOnInvoice() PrepmtPaymentTermsCode: Code[10]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        PrepmtPaymentTermsCode := CreatePaymentTermsCode();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Prepmt. Payment Terms Code", PrepmtPaymentTermsCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure DeletePaymentLine(PaymentTermsCode: Code[10])
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetRange(Code, PaymentTermsCode);
        PaymentLines.FindFirst();
        PaymentLines.Delete(true);
    end;

    local procedure CreateAndPostPurchaseInvoiceWithGL(Vendor: Record Vendor; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Check Total" := DirectUnitCost + DirectUnitCost * WithholdCodeLine."Withholding Tax %" / 100;
        PurchaseHeader.Validate("Payment Method Code", Vendor."Payment Method Code");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(1));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        WithholdingContribution.CalculateWithholdingTax(PurchaseHeader, true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure FindPaymentMethodAndBill(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Bill Code", FindPaymentMethodBillCode());
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindPaymentMethodBillCode(): Code[20]
    var
        Bill: Record Bill;
    begin
        Bill.FindFirst();
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    local procedure CreateAndModifyVendorBillHeaderWithPaymentMethod(var VendorBillHeader: Record "Vendor Bill Header"; PaymentMethodCode: Code[10])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, CreateBankAccount(''), PaymentMethodCode);  // Blank value for Currency Code.
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
    end;

    local procedure FindAndVerifyVendorBillLinesAmount(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorBillLine: Record "Vendor Bill Line";
    begin
        Vendor.Get(VendorNo);
        Vendor.CalcFields(Balance);
        FindVendorBillLine(VendorBillLine, Vendor."No.");
        Assert.AreEqual(
          VendorBillLine."Remaining Amount",
          VendorBillLine."Amount to Pay" + VendorBillLine."Withholding Tax Amount",
          StrSubstNo(AmountErr, VendorBillLine.FieldCaption("Amount to Pay"), VendorBillLine."Remaining Amount", VendorBillLine.TableCaption()));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithGLByUpdatingWithHoldingTotalAmount(Vendor: Record Vendor; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Check Total" := DirectUnitCost + DirectUnitCost * WithholdCodeLine."Withholding Tax %" / 100;
        PurchaseHeader.Validate("Payment Method Code", Vendor."Payment Method Code");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(1));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        WithholdingContribution.CalculateWithholdingTax(PurchaseHeader, true);
        UpdateWithHoldingTotalAmount(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateWithHoldingTotalAmount(PurchHeader: Record "Purchase Header")
    var
        PurchWithSoc: Record "Purch. Withh. Contribution";
    begin
        if PurchWithSoc.Get(PurchHeader."Document Type", PurchHeader."No.") then begin
            PurchWithSoc.Validate("Total Amount", PurchWithSoc."Total Amount" / 2);
            PurchWithSoc.Modify();
        end;
    end;

    local procedure CreateAndPostPurchaseInvoiceWithGLByUpdatingWithHoldingBaseExcludedAmount(Vendor: Record Vendor; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WithholdCodeLine: Record "Withhold Code Line";
        WithholdingContribution: Codeunit "Withholding - Contribution";
    begin
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader."Check Total" := DirectUnitCost + DirectUnitCost * WithholdCodeLine."Withholding Tax %" / 100;
        PurchaseHeader.Validate("Payment Method Code", Vendor."Payment Method Code");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(1));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        WithholdingContribution.CalculateWithholdingTax(PurchaseHeader, true);
        UpdateWithHoldingBaseExcludedAmount(PurchaseHeader);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateWithHoldingBaseExcludedAmount(PurchHeader: Record "Purchase Header")
    var
        PurchWithSoc: Record "Purch. Withh. Contribution";
    begin
        if PurchWithSoc.Get(PurchHeader."Document Type", PurchHeader."No.") then begin
            PurchWithSoc.Validate("Base - Excluded Amount", PurchWithSoc."Total Amount" / 2);
            PurchWithSoc.Modify();
        end;
    end;

    local procedure CreateDefaultDimension(CustomerNo: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify();
        exit(Dimension.Code);
    end;

    local procedure CreateVendor(PaymentMethodCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure VerifyDocumentOccurrenceVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Iteration: Integer;
    begin
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Document No.", "Document Type", "Document Occurrence");
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindSet();
        repeat
            Iteration := Iteration + 1;
            Assert.AreEqual(
              Iteration, VendorLedgerEntry."Document Occurrence",
              StrSubstNo(DocumentOccurrenceErr, VendorLedgerEntry.FieldCaption("Document Occurrence"), Iteration, VendorLedgerEntry.TableCaption()));
        until VendorLedgerEntry.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankSheetPrintRequestPageHandler(var BankSheetPrint: TestRequestPage "Bank Sheet - Print")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        BankSheetPrint."Bank Account".SetFilter("No.", No);
        BankSheetPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsRequestPageHandler(var ClosingBankReceipts: TestRequestPage "Closing Bank Receipts")
    var
        ConfirmPerApplication: Variant;
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ConfirmPerApplication);
        LibraryVariableStorage.Dequeue(CustomerNo);
        ClosingBankReceipts.ConfirmPerApplication.SetValue(ConfirmPerApplication);
        ClosingBankReceipts.CustEntry1.SetFilter("Customer No.", CustomerNo);
        ClosingBankReceipts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptsCheckDimensionsRequestPageHandler(var ClosingBankReceipts: TestRequestPage "Closing Bank Receipts")
    var
        CheckDimensions: Variant;
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CheckDimensions);
        LibraryVariableStorage.Dequeue(CustomerNo);
        ClosingBankReceipts.RiskPeriod.SetValue('1D');
        ClosingBankReceipts.CheckDim.SetValue(CheckDimensions);
        ClosingBankReceipts.CustEntry1.SetFilter("Customer No.", CustomerNo);
        ClosingBankReceipts.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuingCustomerBillRequestPageHandler(var IssuingCustomerBill: TestRequestPage "Issuing Customer Bill")
    var
        CustomerNo: Variant;
        PostingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(CustomerNo);
        IssuingCustomerBill."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        IssuingCustomerBill.PostingDescription.SetValue(Format(PostingDate));
        IssuingCustomerBill.DoNotCheckDimensions.SetValue(false);
        IssuingCustomerBill.PostingDate.SetValue(PostingDate);
        IssuingCustomerBill.DocumentDate.SetValue(PostingDate);
        IssuingCustomerBill.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuedCustBillsReportRequestPageHandler(var IssuedCustBillsReport: TestRequestPage "Issued Cust Bills Report")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        IssuedCustBillsReport."Issued Customer Bill Header".SetFilter("No.", No);
        IssuedCustBillsReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ManualVendorPaymentLinePageHandler(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
        TotalAmount: Variant;
        WithholdingTaxCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(WithholdingTaxCode);
        LibraryVariableStorage.Dequeue(TotalAmount);
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.WithholdingTaxCode.SetValue(WithholdingTaxCode);
        ManualVendorPaymentLine.DocumentType.SetValue(VendorLedgerEntry."Document Type"::Payment);
        ManualVendorPaymentLine.DocumentNo.SetValue(LibraryUtility.GenerateGUID());
        ManualVendorPaymentLine.DocumentDate.SetValue(WorkDate());
        ManualVendorPaymentLine.TotalAmount.SetValue(TotalAmount);
        ManualVendorPaymentLine.InsertLine.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ManualVendorPaymentLinePageHandlerForInvoice(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
        TotalAmount: Variant;
        WithholdingTaxCode: Variant;
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(WithholdingTaxCode);
        LibraryVariableStorage.Dequeue(TotalAmount);
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.WithholdingTaxCode.SetValue(WithholdingTaxCode);
        ManualVendorPaymentLine.DocumentType.SetValue(VendorLedgerEntry."Document Type"::Invoice);
        ManualVendorPaymentLine.DocumentNo.SetValue(DocumentNo);
        ManualVendorPaymentLine.DocumentDate.SetValue(WorkDate());
        ManualVendorPaymentLine.TotalAmount.SetValue(TotalAmount);
        ManualVendorPaymentLine.InsertLine.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectNoSeriesModalPageHandler(var NoSeriesPage: TestPage "No. Series")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(LibraryVariableStorage.DequeueText());
        NoSeriesPage.GoToRecord(NoSeries);
        NoSeriesPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

