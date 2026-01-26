codeunit 144133 "ERM Dishonor"
{
    // // [FEATURE] [ERM Dishonor]
    // 1.  Test to verify values on the Cust. Ledger Entries after Posting Cust. Ledger Application with Set Applies to Id.
    // 2.  Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored Entry Totally.
    // 3.  Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored Entry Partially.
    // 4.  Test to verify values on the Payment Cust. Ledger Entry after applying Dishonored to Payment Entry.
    // 5.  Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored to Payment Entry Totally.
    // 6.  Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored to Payment Entry Partially.
    // 7.  Test to verify values on the Report - Closing Bank Receipts.
    // 8.  Test to verify Avg. Collection Period Days on Customer Entry Statistics Page after applying Posted Entries with Application Date.
    // 9.  Test to verify values on the Report - Customer Bills List.
    // 10. Test to verify error message on Report - Customer Bills List when Ending Date is blank.
    // 11. Test to verify error message on Report - Customer Bills List when Bank Receipts Risk Period on Sales & Receivable Setup is blank.
    // 12. Test to verify values on the Cust. Ledger Entry after applying Cust Bill to Dishonored Entry.
    // 13. Test to verify values on the Payment Cust. Ledger Entry after applying Cust Bill to Payment Entry.
    // 14. Test to verify Customer Ledger Entry when Sales Invoice applied with multiple Document Types.
    // 15. Test to verify Vendor Ledger Entry when Purchase Invoice applied with multiple Document Types.
    // 
    // Covers Test Cases for WI - 345867
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------
    // ApplyPaymentToDishonoredEntry, ApplyAndUnapplyPaymenToDishonoredEntry                          268475
    // ApplyAndUnapplyPaymenToDishonoredEntryPartially                                                268476
    // ApplyDishonoredToPaymentEntry, ApplyAndUnapplyDishnoredToPaymentEntry                          268477
    // ApplyAndUnapplyDishnoredToPaymentEntryPartially                                                268478
    // AvgCollectionPeriodDaysWhenBillIssuedPayment                                                   154879
    // AvgCollectionPeriodDaysWhenPaymentType                                                  154880,154881
    // CustomerBillListAfterApplyingDishonored, CustomerBillListWithBlankEndingDateError              238896
    // CustomerBillListWithBlankBankReceiptsRiskPeriodError                                           268117
    // PostingBillsAsDishonored                                                                       151825
    // UnapplyAndApplyDishonoredDocument                                                              189005
    // 
    // Covers Test Cases for WI - 346512
    // -------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                             TFS ID
    // -------------------------------------------------------------------------------------------------------
    // ApplySalesInvoiceWithMultipleDocumentTypes                                                     203471
    // ApplyAndUnapplyPurchInvWithMultipleDocumentTypes                                               205937

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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Caption,%2 = Field Value,%3 = Table Caption';
        BankReceiptsRiskPeriodErr: Label 'Bank Receipts Risk Period must have a value';
        EndingDateErr: Label 'Specify the Ending Date';
        WrongValueInCustLedgerEntryErr: Label 'Wrong value in Cust. Ledger Entry.';
        WrongValueInDtldCustLedgerEntryErr: Label 'Wrong value in Detailed Cust. Ledger Entry.';

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentToDishonoredEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Test to verify values on the Cust. Ledger Entries after Posting Cust. Ledger Application with Set Applies to Id.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);

        // Exercise: Post Cust. Ledger Entry after Set Applies to Id.
        PostCustLedgerApplicationAfterSetAppliesToId(TempSalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify values on Payment and Dishonered Cust. Ledger Entries.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment, false,
          CustLedgerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using False for Open.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Dishonored, false,
          CustLedgerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using False for Open.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyPaymenToDishonoredEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored Entry Totally.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored, Apply Dishonered Entry Post Application after Set Applies to Id.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);
        DocumentNo2 := ApplyAndPostGeneralJournalLine(
            TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);
        PostCustLedgerApplicationAfterSetAppliesToId(TempSalesLine."Sell-to Customer No.", DocumentNo);

        // Exercise: Unapply Dishonored Entry.
        UnapplyCustomerLedgerEntry(DocumentNo2);

        // Verify: Verify values on Invoice, Payment and Dishonered Cust. Ledger Entries.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment, true,
          CustLedgerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using True for Open.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Dishonored, true,
          CustLedgerEntry."Document Type to Close"::" ", '');  // Using False for Open, blank for Document type Close and Document No.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Invoice, true,
          CustLedgerEntry."Document Type to Close"::" ", '');  // Using False for Open, blank for Document type Close and Document No.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyPaymenToDishonoredEntryPartially()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored Entry Partially.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored, Apply Dishonered Entries partially and Post Application after Set Applies to Id.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);
        DocumentNo2 := ApplyAndPostGeneralJournalLine(
            TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount" / 2, GenJournalLine."Document Type"::Dishonored);  // Apply Partial Amount to Dishonred Entry.
        DocumentNo3 := ApplyAndPostGeneralJournalLine(
            TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount" / 2, GenJournalLine."Document Type"::Dishonored);  // Apply Partial Amount to Dishonred Entry.
        PostCustLedgerApplicationAfterSetAppliesToId(TempSalesLine."Sell-to Customer No.", DocumentNo);

        // Exercise: Unapply Cust. Ledger Entry of Document Type Dishonored.
        UnapplyCustomerLedgerEntry(DocumentNo2);

        // Verify: Verify Open field on Dishonered Cust. Ledger Entries
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Dishonored, DocumentNo2);
        CustLedgerEntry.TestField(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Dishonored, DocumentNo3);
        CustLedgerEntry.TestField(Open, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyDishonoredToPaymentEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after applying Dishonored to Payment Entry.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);

        // Exercise: Post Cust. Ledger Entry After Set Appples to Id.
        PostCustLedgerApplicationAfterSetAppliesToId(TempSalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify values on Payment Cust. Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedgerEntry."Document Type"::Payment, false,
          CustLedgerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using False for Open.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyDishnoredToPaymentEntry()
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored to Payment Entry Totally.
        ApplyAndUnapplyDishnoredToPayment(1);  // Divide by 1 to apply Total amount to Dishonred Entry.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyDishnoredToPaymentEntryPartially()
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after Unapplying Dishonored to Payment Entry Partially.
        ApplyAndUnapplyDishnoredToPayment(2);  // Divide by 2 to apply Partial amount to Dishonred Entry.
    end;

    local procedure ApplyAndUnapplyDishnoredToPayment(PartPayment: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup: Create and Post Sales Invoice. Run Issue Bank Receipt Report, Create and Post Customer Bill.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);

        // Exercise: Unapply Cust. Ledger Entry of Document Type Dishonored.
        UnapplyCustomerLedgerEntry(
          ApplyAndPostGeneralJournalLine(TempSalesLine."Sell-to Customer No.",
            TempSalesLine."Line Amount" / PartPayment, GenJournalLine."Document Type"::Dishonored));

        // Verify: Verify values on Invoice, Payment and Dishonered Cust. Ledger Entries.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.",
          CustLedgerEntry."Document Type"::Payment, true, CustLedgerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using True for Open.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.",
          CustLedgerEntry."Document Type"::Dishonored, true, CustLedgerEntry."Document Type to Close"::" ", '');  // Using True for Open, blank for Document type Close and Document No.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.",
          CustLedgerEntry."Document Type"::Invoice, true, CustLedgerEntry."Document Type to Close"::" ", '');  // Using True for Open, blank for Document type Close and Document No.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ClosingBankReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AvgCollectionPeriodDaysWhenBillIssuedPayment()
    var
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify values on the Report - Closing Bank Receipts.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Create and Post Customer Bill.
        Initialize();
        CreateAndPostCustomerBill(TempSalesLine);
        LibraryVariableStorage.Enqueue(TempSalesLine."Sell-to Customer No.");  // Enqueue CustomerNo. on ClosingBankReceiptRequestPageHandler.

        // Exercise: Run Closing Bank Receipts Report.
        REPORT.Run(REPORT::"Closing Bank Receipts");

        // Verify: Verify values on Report - Closing Bank Receipts.
        VerifyAvgCollectionPeriodDays(TempSalesLine."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgCollectionPeriodDaysWhenPaymentType()
    var
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Test to verify Avg. Collection Period Days on Customer Entry Statistics Page after applying Posted Entries with Application Date.

        // Setup: Create and Post Sales Invoice.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(TempSalesLine, '');  // Payment Terms Code as blank.

        // Exercise: Apply Posted Entries with Application Date.
        ApplyPostedEntries(TempSalesLine."Sell-to Customer No.", DocumentNo);

        // Verify: Verify Avg. Collection Period Days Customer Entry Statistics Page.
        VerifyAvgCollectionPeriodDays(TempSalesLine."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,MessageHandler,CustomerBillListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillListAfterapplyingDishonored()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify values on the Report - Customer Bills List.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored and Payment Entries.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, '');  // Payment Terms Code as blank.
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", -TempSalesLine."Line Amount", GenJournalLine."Document Type"::Payment);
        EnqueueValuesInCustomerBillListRequestPageHandler(TempSalesLine."Sell-to Customer No.", CalcDate('<CM>', WorkDate()));  // Enqueue values CustomerBillListRequestPageHandler.

        // Exercise: Run Customer Bills List Report.
        REPORT.Run(REPORT::"Customer Bills List");

        // Verify: Verify values on Report - Customer Bills List.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalCustLedgrEntries_', TempSalesLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists('ClosedByAmountLCY', TempSalesLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists('TotalClosedByAmntLCY', TempSalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,MessageHandler,CustomerBillListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillListWithBlankEndingDateError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
    begin
        // Test to verify error message on Report - Customer Bills List when Ending Date is blank.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored and Payment Entries.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, '');  // Payment Terms Code as blank.
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);
        EnqueueValuesInCustomerBillListRequestPageHandler(TempSalesLine."Sell-to Customer No.", 0D);  // Enqueue blank Ending Date in CustomerBillListRequestPageHandler.

        // Exercise: Run Customer Bills List Report.
        asserterror REPORT.Run(REPORT::"Customer Bills List");

        // Verify: Verify error on Report - Customer Bills List.
        Assert.ExpectedError(EndingDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,MessageHandler,CustomerBillListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerBillListWithBlankBankReceiptsRiskPeriodError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Test to verify error message on Report - Customer Bills List when Bank Receipts Risk Period on Sales & Receivable Setup is blank.

        // Setup: Update Bank Receipts Risk Period on Sales & Receivable Setup, Create and Post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored Entry.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesAndReceivableSetup('');
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, '');  // Payment Terms Code as blank.
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);
        EnqueueValuesInCustomerBillListRequestPageHandler(TempSalesLine."Sell-to Customer No.", WorkDate());  // Enqueue values CustomerBillListRequestPageHandler.

        // Exercise: Run Customer Bills List Report.
        asserterror REPORT.Run(REPORT::"Customer Bills List");

        // Verify: Verify error on Report - Customer Bills List.
        Assert.ExpectedError(BankReceiptsRiskPeriodErr);

        // Tear down.
        UpdateSalesAndReceivableSetup(Format(SalesReceivablesSetup."Bank Receipts Risk Period"));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingBillsAsDishonored()
    var
        TempSalesLine: Record "Sales Line" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedegerEntry: Record "Cust. Ledger Entry";
    begin
        // Test to verify values on the Cust. Ledger Entry after applying Cust Bill to Dishonored Entry.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Create and Post Customer Bill.
        Initialize();
        CreateAndPostCustomerBill(TempSalesLine);

        // Exercise: Apply Cust Bill to Dishonored Entry.
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);

        // Verify: Verify values on Cust. Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.",
          CustLedegerEntry."Document Type"::Invoice, true, CustLedegerEntry."Document Type to Close"::" ", '');  // Using True for Open, blank for Document type Close and Document No.
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyAndApplyDishonoredDocument()
    var
        CustLedegerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Test to verify values on the Payment Cust. Ledger Entry after applying Cust Bill to Payment Entry.

        // Setup: Create and Post Sales Invoice, Run Issue Bank Receipt Report, Create and Post Customer Bill and Apply Customer Bill to Dishonored.
        Initialize();
        DocumentNo := CreateAndPostCustomerBill(TempSalesLine);
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);

        // Exercise: Apply Customer Bill to Payment.
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", -TempSalesLine."Line Amount", GenJournalLine."Document Type"::Payment);

        // Verify: Verify values on Payment Cust. Ledger Entry.
        VerifyCustomerLedgerEntry(
          TempSalesLine."Sell-to Customer No.", CustLedegerEntry."Document Type"::Payment, true,
          CustLedegerEntry."Document Type to Close"::Invoice, DocumentNo);  // Using True for Open.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplySalesInvoiceWithMultipleDocumentTypes()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Test to verify Customer Ledger Entry when Sales Invoice applied with multiple Document Types.

        // Setup: Create and post Sales Invoice, Run Issue Bank Receipt Report, Apply Customer Bill to Dishonored Entry.
        Initialize();
        IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, FindPaymentTermsCode());
        ApplyAndPostGeneralJournalLine(
          TempSalesLine."Sell-to Customer No.", TempSalesLine."Line Amount", GenJournalLine."Document Type"::Dishonored);

        // Exercise: Apply Invoice to Payment.
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(
            TempSalesLine."Sell-to Customer No.", -TempSalesLine."Line Amount", GenJournalLine."Document Type"::Payment);

        // Verify: Verify Amount on Customer Ledger Entry.
        VerifyAmountOnCustomerLedgerEntry(DocumentNo, -TempSalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyPurchInvWithMultipleDocumentTypes()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
    begin
        // Test to verify Vendor Ledger Entry when Purchase Invoice applied with multiple Document Types.

        // Setup: Post Purchase Invoice after posting Vendor Bill, Unapply and Apply Vendor Bill to Dishonored Entry.
        Initialize();
        DocumentNo := PostVendorBillAfterPostingPurchaseInvoice(TempPurchaseLine);
        DocumentNo2 := UnApplyVendorLedgerEntry(TempPurchaseLine."Buy-from Vendor No.");
        CreateAndPostCashReceiptJournal(
          TempPurchaseLine."Buy-from Vendor No.", DocumentNo2, -TempPurchaseLine.Amount,
          GenJournalLine."Document Type"::Dishonored, GenJournalLine."Applies-to Doc. Type"::Payment);

        // Exercise: Apply Payment to Invoice.
        DocumentNo3 :=
          CreateAndPostCashReceiptJournal(
            TempPurchaseLine."Buy-from Vendor No.", DocumentNo, TempPurchaseLine.Amount,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify: Verify Amount on VendorLedger Entry.
        VerifyAmountOnVendorLedgerEntry(DocumentNo3, TempPurchaseLine.Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTCheckHandleBillApplyDishonoredDocument()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplyingCustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [Apply]
        // [SCENARIO 124025] HandleBill function in "Gen. Jnl.-Post Line" for application
        Initialize();

        // [GIVEN] Customer Payment and Invoice entries
        MockCustLedgerEntryAndDtldCustLedgEntry(ApplyingCustLedgEntry, false);
        MockCustLedgerEntry(CustLedgerEntry);
        SetupForApplyingCustLedgerEntry(CustLedgerEntry, ApplyingCustLedgEntry);

        // [WHEN] Execute COD12."HandleBill" for application
        GenJnlPostLine.HandleBill(CustLedgerEntry, false);

        // [THEN] Bank Receipt data is copied from Invoice to Payment
        // [THEN] Bank Receipt data is cleared in Invoice
        VerifyCustLedgerEntriesAfterApplying(CustLedgerEntry, ApplyingCustLedgEntry);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UTCheckHandleBillUnApplyDishonoredDocument()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        OldCustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [FEATURE] [UnApply]
        // [SCENARIO 124025] HandleBill function in "Gen. Jnl.-Post Line" for unapplication
        Initialize();

        // [GIVEN] Customer Payment and Invoice entries
        MockCustLedgerEntryAndDtldCustLedgEntry(AppliedCustLedgEntry, true);
        MockCustLedgerEntry(CustLedgerEntry);
        SetupForUnApplyingCustLedgerEntry(CustLedgerEntry, AppliedCustLedgEntry);
        OldCustLedgerEntry := CustLedgerEntry;

        // [WHEN] Execute COD12."HandleBill" for unapplication
        GenJnlPostLine.HandleBill(CustLedgerEntry, true);

        // [THEN] Bank Receipt data is copied from Payment to Invoice
        // [THEN] Bank Receipt data is cleared in Payment
        VerifyCustLedgerEntriesAfterUnApplying(OldCustLedgerEntry, AppliedCustLedgEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyNonBankRcptPaymentWithDishonored()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
    begin
        // [SCENARIO 438607] To check if system is allowing user to apply a dishonored journal line with a payment entry even if "Bank Receipt" is false on customer ledger

        // [GIVEN] Create a sales invoice and apply it with a payment entry
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(TempSalesLine, '');
        DocumentNo2 := CreateAndPostCashReceiptJournalForCustomer(
          TempSalesLine."Sell-to Customer No.", DocumentNo, -TempSalesLine.Amount,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] upapply payment entry
        UnapplyCustomerLedgerEntryPayment(DocumentNo2);

        // [WHEN] Post a cash receipt with document type as Dishonored and apply it with payment document no.
        DocumentNo3 := CreateAndPostCashReceiptJournalForCustomer(
          TempSalesLine."Sell-to Customer No.", DocumentNo2, TempSalesLine.Amount,
          GenJournalLine."Document Type"::Dishonored, GenJournalLine."Applies-to Doc. Type"::Payment);

        // [THEN] it should allow user to apply payment entry and post the journal line withour any error.
        VerifyAmountOnCustomerLedgerEntryForDishonorPayment(DocumentNo2, -TempSalesLine.Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure ApplyAndPostGeneralJournalLine(CustomerNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, CustomerNo, Amount, GenJournalLine."Account Type"::Customer, DocumentType);
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
        CashReceiptJournal."Applies-to Doc. No.".Lookup();  // Invoke ApplyCustomerEntriesModalPageHandler.
        CashReceiptJournal.OK().Invoke();
    end;

    local procedure ApplyPostedEntries(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, CreateAndPostGeneralJournalLine(CustomerNo));
        PostCustomerApplicationEntry(CustLedgerEntry, DocumentNo, CalcDate('<1M>', WorkDate()));
    end;

    local procedure CopySalesLineToTempSalesLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        TempSalesLine.Init();
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();
    end;

    local procedure CopyPurchaseLineToTempPurchaseLine(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine.Init();
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    local procedure CreateAndPostCashReceiptJournal(AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountNo, Amount, GenJournalLine."Account Type"::Vendor, DocumentType);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostCustomerBill(var TempSalesLine: Record "Sales Line" temporary) DocumentNo: Code[20]
    var
        BillPostingGroup: Record "Bill Posting Group";
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        // Find Bank Account No for the Payment Method and Create Customer Bill.
        DocumentNo := IssueBankReceiptAfterPostingSalesInvoice(TempSalesLine, '');  // Payment Terms Code as blank.
        BillPostingGroup.SetRange("Payment Method", FindPaymentMethod());
        BillPostingGroup.FindFirst();
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
        RunSuggestCustomerBill(CustomerBillHeader, TempSalesLine."Sell-to Customer No.");
        PostCustomerBill(CustomerBillHeader);
    end;

    local procedure CreateAndPostSalesInvoice(var TempSalesLine: Record "Sales Line" temporary; PaymentTermsCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(PaymentTermsCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        CopySalesLineToTempSalesLine(TempSalesLine, SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostGeneralJournalLine(CustomerNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(
          GenJournalLine, CustomerNo, -LibraryRandom.RandDec(10, 2),
          GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Payment);  // Use Random value for Amount.
        GenJournalLine.Validate("Posting Date", CalcDate('<1D>', WorkDate()));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseInvoice(var TempPurchaseLine: Record "Purchase Line" temporary; VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item),
          LibraryRandom.RandDec(10, 2));  // Using random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use random Unit Price.
        PurchaseLine.Modify(true);
        CopyPurchaseLineToTempPurchaseLine(TempPurchaseLine, PurchaseLine);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateBillPostingGroup(PaymentMethod: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", PaymentMethod);
        exit(BillPostingGroup."No.");
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

    local procedure CreateCashReceiptsJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; DocumentType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateCashReceiptsJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", FindBillCode());
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
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
        BillPostingGroup.SetRange("No.", No);
        BillPostingGroup.FindFirst();
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BillPostingGroup."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        RunSuggestVendorBills(VendorBillHeader, VendorNo);
    end;

    local procedure EnqueueValuesInCustomerBillListRequestPageHandler(CustomerNo: Code[20]; EndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(EndingDate);
    end;

    local procedure FindBillCode(): Code[20]
    var
        Bill: Record Bill;
    begin
        Bill.SetRange("Allow Issue", true);
        Bill.SetRange("Bank Receipt", true);
        Bill.FindFirst();
        Bill.Validate("List No.", LibraryERM.CreateNoSeriesSalesCode());
        Bill.Validate("Vendor Bill List", Bill."List No.");
        Bill.Validate("Vendor Bill No.", Bill."List No.");
        Bill.Modify(true);
        exit(Bill.Code);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Bill Code", FindBillCode());
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindPaymentTermsCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Payment Nos.", '>%1', 1);  // Payment Term Code with multiple Payments is required.
        PaymentTerms.FindFirst();
        exit(PaymentTerms.Code);
    end;

    local procedure IssueBankReceiptAfterPostingSalesInvoice(var TempSalesLine: Record "Sales Line" temporary; PaymentTermsCode: Code[10]) DocumentNo: Code[20]
    begin
        DocumentNo := CreateAndPostSalesInvoice(TempSalesLine, PaymentTermsCode);
        RunIssueBankReceipt(TempSalesLine."Sell-to Customer No.");
    end;

    local procedure IssueVendorBill(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard."&Create List".Invoke();
    end;

    local procedure RunIssueBankReceipt(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuingCustomerBill: Report "Issuing Customer Bill";
    begin
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
        SuggestCustomerBills.InitValues(CustomerBillHeader, true);
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

    local procedure PostCustomerBill(CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillPost: Codeunit "Customer Bill - Post + Print";
    begin
        CustomerBillPost.SetHidePrintDialog(true);
        CustomerBillPost.Code(CustomerBillHeader);
    end;

    local procedure PostCustomerApplicationEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; ApplicationDate: Date)
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry2.FindFirst();
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

        ApplyUnapplyParameters."Document No." := DocumentNo;
        ApplyUnapplyParameters."Posting Date" := ApplicationDate;
        CustEntryApplyPostedEntries.Apply(CustLedgerEntry, ApplyUnapplyParameters);
    end;

    local procedure PostCustLedgerApplicationAfterSetAppliesToId(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Payment);
        PostCustomerApplicationEntry(CustLedgerEntry, DocumentNo, WorkDate());
    end;

    local procedure PostVendorBillAfterPostingPurchaseInvoice(var TempPurchaseLine: Record "Purchase Line" temporary) DocumentNo: Code[20]
    var
        VendorBillHeader: Record "Vendor Bill Header";
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        DocumentNo := CreateAndPostPurchaseInvoice(TempPurchaseLine, Vendor."No.");
        CreateVendorBill(VendorBillHeader, Vendor."No.", CreateBillPostingGroup(Vendor."Payment Method Code"));
        IssueVendorBill(VendorBillHeader."No.");
        PostVendorBill(VendorBillHeader."Payment Method Code");
    end;

    local procedure PostVendorBill(PaymentMethodCode: Code[10])
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("Payment Method Code", PaymentMethodCode);
        VendorBillListSentCard.Post.Invoke();
    end;

    local procedure UnapplyCustomerLedgerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Dishonored, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnApplyVendorLedgerEntry(VendorNo: Code[20]) DocumentNo: Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        DocumentNo := VendorLedgerEntry."Document No.";
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UpdateSalesAndReceivableSetup(BankReceiptsRiskPeriod: Text)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        BankReceiptsRiskPeriod2: DateFormula;
    begin
        SalesReceivablesSetup.Get();
        Evaluate(BankReceiptsRiskPeriod2, BankReceiptsRiskPeriod);
        SalesReceivablesSetup.Validate("Bank Receipts Risk Period", BankReceiptsRiskPeriod2);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        RecRef: RecordRef;
    begin
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Dishonored;
        CustLedgerEntry."Document No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Document Occurrence" := LibraryRandom.RandInt(10);
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
    end;

    local procedure MockDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntryNo: Integer; BankReceiptIssued: Boolean)
    begin
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DtldCustLedgEntry."Entry Type" := DtldCustLedgEntry."Entry Type"::"Initial Entry";
        DtldCustLedgEntry."Bank Receipt Issued" := BankReceiptIssued;
        DtldCustLedgEntry.Insert();
    end;

    local procedure MockCustLedgerEntryAndDtldCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; BankReceiptIssued: Boolean)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        MockCustLedgerEntry(CustLedgerEntry);
        MockDtldCustLedgEntry(DtldCustLedgEntry, CustLedgerEntry."Entry No.", BankReceiptIssued);
    end;

    local procedure SetupForApplyingCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        SetupBlankBankReceiptValueCustLedgerEntry(CustLedgerEntry);
        SetupCloseDocumentCustLedgerEntry(CustLedgerEntry, ApplyingCustLedgerEntry);
        CustLedgerEntry.Modify();
        SetupRandomBankReceiptValueCustLedgerEntry(ApplyingCustLedgerEntry);
        ApplyingCustLedgerEntry."Allow Issue" := true;
        ApplyingCustLedgerEntry.Modify();
    end;

    local procedure SetupForUnApplyingCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        SetupBlankBankReceiptValueCustLedgerEntry(AppliedCustLedgerEntry);
        AppliedCustLedgerEntry."Allow Issue" := false;
        AppliedCustLedgerEntry.Modify();
        SetupRandomBankReceiptValueCustLedgerEntry(CustLedgerEntry);
        SetupCloseDocumentCustLedgerEntry(CustLedgerEntry, AppliedCustLedgerEntry);
        CustLedgerEntry.Modify();
    end;

    local procedure SetupBlankBankReceiptValueCustLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry."Bank Receipt Issued" := false;
        CustLedgEntry."Bank Receipt Temp. No." := '';
        CustLedgEntry."Bank Receipts List No." := '';
        CustLedgEntry."Customer Bill No." := '';
    end;

    local procedure SetupCloseDocumentCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; ApplyCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry."Document Type to Close" := ApplyCustLedgerEntry."Document Type";
        CustLedgerEntry."Document No. to Close" := ApplyCustLedgerEntry."Document No.";
        CustLedgerEntry."Document Occurrence to Close" := ApplyCustLedgerEntry."Document Occurrence";
        CustLedgerEntry."Customer No." := ApplyCustLedgerEntry."Customer No.";
    end;

    local procedure SetupRandomBankReceiptValueCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry."Bank Receipt Issued" := true;
        CustLedgerEntry."Bank Receipt Temp. No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Bank Receipt Temp. No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Bank Receipts List No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Bank Receipt Temp. No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Customer Bill No." :=
          LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Customer Bill No."), DATABASE::"Cust. Ledger Entry");
    end;

    local procedure VerifyAmountOnCustomerLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
        CustLedgerEntry.TestField(Open, true);
    end;

    local procedure VerifyAmountOnVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption(Amount), Amount, VendorLedgerEntry.TableCaption()));
        VendorLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyAvgCollectionPeriodDays(No: Code[20])
    var
        CustomerEntryStatistics: TestPage "Customer Entry Statistics";
    begin
        CustomerEntryStatistics.OpenView();
        CustomerEntryStatistics.FILTER.SetFilter("No.", No);
        CustomerEntryStatistics.AvgCollectionPeriodDays_ThisYear.AssertEquals(0);
        CustomerEntryStatistics.AvgCollectionPeriodDays_ThisPeriod.AssertEquals(0);
        CustomerEntryStatistics.AvgCollectionPeriodDays_LastYear.AssertEquals(0);
        CustomerEntryStatistics.Close();
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Open: Boolean; DocumentTypeToClose: Enum "Gen. Journal Document Type"; DocumentNoToClose: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, DocumentType);
        CustLedgerEntry.TestField(Open, Open);
        CustLedgerEntry.TestField("Document Type to Close", DocumentTypeToClose);
        CustLedgerEntry.TestField("Document No. to Close", DocumentNoToClose);
    end;

    local procedure VerifyCustLedgerEntriesAfterApplying(var CustLedgerEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        VerifyFillingOfFieldsCustLedgEntry(CustLedgerEntry, AppliedCustLedgerEntry);
        AppliedCustLedgerEntry.Get(AppliedCustLedgerEntry."Entry No.");
        VerifyBlankedFieldsCustLedgEntry(AppliedCustLedgerEntry);
        Assert.IsFalse(AppliedCustLedgerEntry."Allow Issue", WrongValueInCustLedgerEntryErr);
        VerifyDtldCustLedgerEntry(AppliedCustLedgerEntry."Entry No.", false);
    end;

    local procedure VerifyCustLedgerEntriesAfterUnApplying(var CustLedgerEntry: Record "Cust. Ledger Entry"; UnAppliedCustLedgerEntryNo: Integer)
    var
        UnAppliedCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        UnAppliedCustLedgerEntry.Get(UnAppliedCustLedgerEntryNo);
        VerifyFillingOfFieldsCustLedgEntry(UnAppliedCustLedgerEntry, CustLedgerEntry);
        Assert.IsTrue(UnAppliedCustLedgerEntry."Allow Issue", WrongValueInCustLedgerEntryErr);
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        VerifyBlankedFieldsCustLedgEntry(CustLedgerEntry);
        VerifyDtldCustLedgerEntry(UnAppliedCustLedgerEntry."Entry No.", true);
    end;

    local procedure VerifyDtldCustLedgerEntry(EntryNo: Integer; BankReceiptIssued: Boolean)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::"Initial Entry");
        DtldCustLedgEntry.FindFirst();
        Assert.AreEqual(BankReceiptIssued, DtldCustLedgEntry."Bank Receipt Issued", WrongValueInDtldCustLedgerEntryErr);
    end;

    local procedure VerifyFillingOfFieldsCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; OldCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        Assert.AreEqual(OldCustLedgerEntry."Bank Receipt Issued", CustLedgerEntry."Bank Receipt Issued", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual(OldCustLedgerEntry."Bank Receipt Temp. No.", CustLedgerEntry."Bank Receipt Temp. No.", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual(OldCustLedgerEntry."Bank Receipts List No.", CustLedgerEntry."Bank Receipts List No.", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual(OldCustLedgerEntry."Customer Bill No.", CustLedgerEntry."Customer Bill No.", WrongValueInCustLedgerEntryErr);
    end;

    local procedure VerifyBlankedFieldsCustLedgEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        Assert.AreEqual(false, CustLedgerEntry."Bank Receipt Issued", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual('', CustLedgerEntry."Bank Receipt Temp. No.", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual('', CustLedgerEntry."Bank Receipts List No.", WrongValueInCustLedgerEntryErr);
        Assert.AreEqual('', CustLedgerEntry."Customer Bill No.", WrongValueInCustLedgerEntryErr);
    end;

    local procedure CreateAndPostCashReceiptJournalForCustomer(AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountNo, Amount, GenJournalLine."Account Type"::Customer, DocumentType);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
    end;

    local procedure VerifyAmountOnCustomerLedgerEntryForDishonorPayment(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
        CustLedgerEntry.TestField(Open, false);
    end;

    local procedure UnapplyCustomerLedgerEntryPayment(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ClosingBankReceiptRequestPageHandler(var ClosingBankReceipts: TestRequestPage "Closing Bank Receipts")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        ClosingBankReceipts.ConfirmPerApplication.SetValue(true);
        ClosingBankReceipts.CustEntry1.SetFilter("Customer No.", CustomerNo);
        ClosingBankReceipts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillListRequestPageHandler(var CustomerBillsListReport: TestRequestPage "Customer Bills List")
    var
        No: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(EndingDate);
        CustomerBillsListReport.Customer.SetFilter("No.", No);
        CustomerBillsListReport."Ending Date".SetValue(EndingDate);
        CustomerBillsListReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
}

