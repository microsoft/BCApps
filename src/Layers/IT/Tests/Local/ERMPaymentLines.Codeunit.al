codeunit 144164 "ERM Payment Lines"
{
    // // [FEATURE] [Payment Lines]
    // 
    //  1. Test to verify Amount on Payment Date Lines page invoked from Purchase Journal without Currency.
    //  2. Test to verify Amount on Payment Date Lines page invoked from Purchase Journal with Currency.
    //  3. Test to verify Amount on Posted Payments page invoked from Posted Sales Invoice without Currency.
    //  4. Test to verify Amount on Payment Date Lines page invoked from Sales Credit Memo with Currency.
    //  5. Test to verify Amount on Posted Payments page invoked from Posted Purchase Invoice without Currency.
    //  6. Test to verify Amount on Payments Date Lines page invoked from Purchase Credit Memo with Currency.
    //  7. Test to verify Amount on Posted Payments page invoked from Posted Service Invoice without Currency.
    //  8. Test to verify Amount on Payment Date Lines page invoked from Service Invoice with Currency.
    //  9. Test to verify Amount on Posted Payments page invoked from Posted Service Credit Memo without Currency.
    // 10. Test to verify Amount on Payment Date Lines page invoked from Service Credit Memo with Currency.
    // 11. Test to verify Amount on Payment Date Lines page invoked from Service Order with Currency.
    // 12. Test to verify Amount on Payment Date Lines page invoked from Service Order after Shipment.
    // 13. Test to verify Amount on Payment Date Lines page invoked from Service Invoice with multiple Lines.
    // 14. Test to verify Amount on Payment Date Lines page invoked from Service Credit Memo with multiple Lines.
    // 15. Test to verify Amount on Payment Date Lines page invoked from Service Invoice after deleting Service line.
    // 16. Test to verify Amount on Payment Date Lines page invoked from Purchase Invoice.
    // 17. Test to verify Amount on Payment Date Lines page invoked from Sales Invoice.
    // 18. Test to verify Amount on Vendor Ledger Entry after posting Purchase Invoice.
    // 19. Test to verify Amount on Customer Ledger Entry after posting Sales Invoice.
    // 20. Test to verify Original Amount on Customer Ledger Entry after posting Sales Invoice with Discount on Payment Terms.
    // 21. Test to verify Original Amount on Vendor Ledger Entry after posting Sales Invoice with Discount on Payment Terms.
    // 22. Test to verify no error message appears when deleting Vendor Bill Line.
    // 23. Test to verify no error message appears when Cancel List from Vendor Bill List Issued Card.
    // 
    // Covers Test Cases for WI - 345414
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // RecalculatePmtAmtOnPurchJournalWithoutCurr,RecalculatePmtAmtOnPurchJournalWithCurr
    // RecalculatePmtAmtOnPstdSalesInvoiceWithoutCurr                                       202320,155710
    // RecalculatePmtAmtOnSalesCrMemoWithCurr,RecalculatePmtAmtOnPostedPurchInvoiceWithoutCurr
    // RecalculatePmtAmtOnPurchCreditMemoWithCurr,RecalculatePmtAmtOnPostedServiceInvoice
    // RecalculatePmtAmtOnServiceInvoiceWithCurr                                                   202316
    // RecalculatePmtAmtOnPostedServiceCrMemo
    // RecalculatePmtAmtOnServiceCrMemoWithCurr                                                    202317
    // RecalculatePmtAmtOnServiceOrderWithCurr                                                     202318
    // RecalculatePmtAmtOnServiceOrderAndPostShipment                                              202319
    // RecalculatePmtAmtOnServiceInvoiceWithMultipleLines                                          202861
    // RecalculatePmtAmtOnServiceCrMemoWithMultipleLines                                           202862
    // RecalculatePmtAmtOnServiceInvoiceAfterDeleteLine                                            202863
    // 
    // Covers Test Cases for WI - 345793
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // RecalculatePmtAmtOnPurchaseInvoice                                                   155712,153176
    // RecalculatePmtAmtOnSalesInvoice                                                             155711
    // InvoiceAmountOnVendorLedgerEntry                                                            156975
    // InvoiceAmountOnCustomerLedgerEntry                                                          156972
    // OriginalAmtOnCustomerLedgerEntryWithDiscOnPmtTerms                                          156973
    // OriginalAmtOnVendorLedgerEntryWithDiscOnPmtTerms                                            156977
    // DeleteVendorBillLineOnVendorBillCard, CancelListOnVendorBillIssuedCard                      233972

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Caption,%2 =  Field Value, %3 = Table Caption.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        WrongBalanceErr: Label 'Wrong balance on page.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        VendorBalanceErr: Label 'Vendor Ledger Entries are not applied.';
        RemainingAmountErr: Label 'Remaining Amount must be %1.', Comment = 'Field Value.';

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPurchJournalWithoutCurr()
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Purchase Journal without Currency.
        RecalculatePmtAmtOnPurchJournal('');  // Use Blank for Currency
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPurchJournalWithCurr()
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Purchase Journal with Currency.
        RecalculatePmtAmtOnPurchJournal(CreateCurrencyWithExchangeRate());
    end;

    local procedure RecalculatePmtAmtOnPurchJournal(CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
        PaymentDateLines: TestPage "Payment Date Lines";
    begin
        // Setup: Create Purchase Journal line and open Payment Date Lines page from Purchase Journal.
        LibrarySales.CreateCustomer(Customer);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalTemplate.Type::Purchases, GenJournalLine."Account Type"::Customer,
          Customer."No.", FindPaymentTermsCode(), LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Amount
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        Commit();  // COMMIT required for test case
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");
        PaymentDateLines.Trap();
        PurchaseJournal."&Payments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, GenJournalLine."Debit Amount" / 2);  // Use 2 for partial payment
        PurchaseJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPstdSalesInvoiceWithoutCurr()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        PostedPayments: TestPage "Posted Payments";
        No: Code[20];
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Posted Payments page invoked from Posted Sales Invoice without Currency.

        // Setup: Create and post Sales Invoice.
        AmountIncludingVAT := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', FindPaymentTermsCode());  // Use Blank for Currency
        No := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedPayments.Trap();
        PostedSalesInvoice.Payments.Invoke();

        // Exercise: Recalculate Amount on Posted Payments page.
        PostedPayments.RecalcAmount.Invoke();

        // Verify: Amounts on Posted Payments page.
        VerifyAmountsOnPostedPaymentsPage(PostedPayments, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PostedSalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnSalesCrMemoWithCurr()
    var
        SalesHeader: Record "Sales Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Sales Credit Memo with Currency.

        // Setup: Create Sales Credit Memo.
        AmountIncludingVAT :=
          CreateSalesDocument(
            SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCurrencyWithExchangeRate(), FindPaymentTermsCode());
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PaymentDateLines.Trap();
        SalesCreditMemo."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPostedPurchInvoiceWithoutCurr()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPayments: TestPage "Posted Payments";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        No: Code[20];
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Posted Payments page invoked from Posted Purchase Invoice without Currency.

        // Setup: Create and post Purchase Invoice.
        AmountIncludingVAT := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), '');  // Use Blank for Currency and Payment Method Code.
        No := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Invoice
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", No);
        PostedPayments.Trap();
        PostedPurchaseInvoice."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Posted Payments page.
        PostedPayments.RecalcAmount.Invoke();

        // Verify: Amounts on Posted Payments page.
        VerifyAmountsOnPostedPaymentsPage(PostedPayments, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPurchCreditMemoWithCurr()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payments Date Lines page invoked from Purchase Credit Memo with Currency.

        // Setup: Create Purchase Credit Memo
        AmountIncludingVAT :=
          CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
            CreateCurrencyWithExchangeRate(), FindPaymentTermsCode(), '');  // Blank for Payment Method.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PaymentDateLines.Trap();
        PurchaseCreditMemo."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PurchaseCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPostedServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
        PostedPayments: TestPage "Posted Payments";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Posted Payments page invoked from Posted Service Invoice without Currency.

        // Setup: Create and Post Service Invoice.
        AmountIncludingVAT := CreateAndPostServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, true);  // True for Invoice
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("Pre-Assigned No.", ServiceHeader."No.");
        PostedPayments.Trap();
        PostedServiceInvoice."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Posted Payments page.
        PostedPayments.RecalcAmount.Invoke();

        // Verify: Amounts on Posted Payments Page.
        VerifyAmountsOnPostedPaymentsPage(PostedPayments, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PostedServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceInvoiceWithCurr()
    var
        ServiceHeader: Record "Service Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        ServiceInvoice: TestPage "Service Invoice";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Invoice with Currency.

        // Setup: Create Service Invoice.
        AmountIncludingVAT := CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCurrencyWithExchangeRate());
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceInvoice(ServiceInvoice, ServiceHeader."No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        ServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPostedServiceCrMemo()
    var
        ServiceHeader: Record "Service Header";
        PostedPayments: TestPage "Posted Payments";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Posted Payments page invoked from Posted Service Credit Memo without Currency.

        // Setup: Create and Post Service Credit Memo.
        AmountIncludingVAT :=
          CreateAndPostServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", true);  // True for Invoice
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.FILTER.SetFilter("Pre-Assigned No.", ServiceHeader."No.");
        PostedPayments.Trap();
        PostedServiceCreditMemo."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Posted Payments page.
        PostedPayments.RecalcAmount.Invoke();

        // Verify: Amounts on Posted Payments Page.
        VerifyAmountsOnPostedPaymentsPage(PostedPayments, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PostedServiceCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceCrMemoWithCurr()
    var
        ServiceHeader: Record "Service Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Credit Memo with Currency.

        // Setup: Create Service Credit Memo.
        AmountIncludingVAT :=
          CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", CreateCurrencyWithExchangeRate());
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceCreditMemo(ServiceHeader."No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceOrderWithCurr()
    var
        ServiceHeader: Record "Service Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Order with Currency.

        // Setup: Create Service Order.
        AmountIncludingVAT := CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCurrencyWithExchangeRate());
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceOrder(ServiceHeader."No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceOrderAndPostShipment()
    var
        ServiceHeader: Record "Service Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Order after Shipment.

        // Setup: Create Service Order and Post Shipment.
        AmountIncludingVAT := CreateAndPostServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Order, false);  // False for Invoice
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceOrder(ServiceHeader."No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceInvoiceWithMultipleLines()
    var
        ServiceLine: Record "Service Line";
        PaymentDateLines: TestPage "Payment Date Lines";
        ServiceInvoice: TestPage "Service Invoice";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Invoice with multiple Lines.

        // Setup: Create Service Invoice with multiple Lines.
        AmountIncludingVAT := CreateServiceDocumentWithMultipleLines(ServiceLine, ServiceLine."Document Type"::Invoice);
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceInvoice(ServiceInvoice, ServiceLine."Document No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        ServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceCrMemoWithMultipleLines()
    var
        ServiceLine: Record "Service Line";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Credit Memo with multiple Lines.

        // Setup: Create Service Credit Memo with multiple Lines.
        AmountIncludingVAT := CreateServiceDocumentWithMultipleLines(ServiceLine, ServiceLine."Document Type"::"Credit Memo");
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceCreditMemo(ServiceLine."Document No.");

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Verify Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnServiceInvoiceAfterDeleteLine()
    var
        ServiceHeader: Record "Service Header";
        PaymentDateLines: TestPage "Payment Date Lines";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Service Invoice after deleting Service line.

        // Setup: Create Service Invoice, recalculate Payment and delete the Service line.
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');  // Use Blank for Currency and Payment Method Code.
        PaymentDateLines.Trap();
        InvokePaymentDateLinesPageFromServiceInvoice(ServiceInvoice, ServiceHeader."No.");
        PaymentDateLines.RecalcAmount.Invoke();
        DeleteServiceLine(ServiceHeader);
        ServiceInvoice."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Verify Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, 0);
        ServiceInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Purchase Invoice.

        // Setup: Create and release Purchase Invoice, Open Payment Date Lines page.
        AmountIncludingVAT := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), '');  // Use Blank for Currency and Payment Method.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PaymentDateLines.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Verify Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        PurchaseInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculatePmtAmtOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        PaymentDateLines: TestPage "Payment Date Lines";
        AmountIncludingVAT: Decimal;
    begin
        // Test to verify Amount on Payment Date Lines page invoked from Sales Invoice.

        // Setup: Create and release Sales Invoice and open Payment Date Lines page.
        AmountIncludingVAT := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', FindPaymentTermsCode());  // Use Blank for Currency
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        PaymentDateLines.Trap();
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice."Pa&yments".Invoke();

        // Exercise: Recalculate Amount on Payment Date Lines page.
        PaymentDateLines.RecalcAmount.Invoke();

        // Verify: Verify Amounts on Payment Date Lines Page.
        VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines, AmountIncludingVAT / 2);  // Use 2 for partial payment
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAmountOnVendorLedgerEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        AmountIncludingVAT: Decimal;
        SecondDueDateCalculation: DateFormula;
        DueDateCalculation: DateFormula;
        DocumentNo: Code[20];
    begin
        // Test to verify Amount on Vendor Ledger Entry after posting Purchase Invoice.

        // Setup: Create Purchase Invoice.
        AmountIncludingVAT := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), '');  // Use Blank for Currency and Payment Method Code.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Amount on Vendor Ledger Entry.
        Evaluate(SecondDueDateCalculation, GetDueDateCalculationFromPaymentTerms(DueDateCalculation, FindPaymentTermsCode()));
        VerifyAmountOnVendorLedgerEntry(DocumentNo, -AmountIncludingVAT / 2, DueDateCalculation);
        VerifyAmountOnVendorLedgerEntry(DocumentNo, -AmountIncludingVAT / 2, SecondDueDateCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAmountOnCustomerLedgerEntry()
    var
        SalesHeader: Record "Sales Header";
        AmountIncludingVAT: Decimal;
        SecondDueDateCalculation: DateFormula;
        DueDateCalculation: DateFormula;
        DocumentNo: Code[20];
    begin
        // Test to verify Amount on Customer Ledger Entry after posting Sales Invoice.

        // Setup: Create Sales Invoice.
        AmountIncludingVAT := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', FindPaymentTermsCode());  // Use Blank for Currency

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount on Customer Ledger Entry.
        Evaluate(SecondDueDateCalculation, GetDueDateCalculationFromPaymentTerms(DueDateCalculation, FindPaymentTermsCode()));
        VerifyAmountOnCustomerLedgerEntry(DocumentNo, AmountIncludingVAT / 2, DueDateCalculation);
        VerifyAmountOnCustomerLedgerEntry(DocumentNo, AmountIncludingVAT / 2, SecondDueDateCalculation);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure OriginalAmtOnCustomerLedgerEntryWithDiscOnPmtTerms()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        Amount: Decimal;
        PaymentTermsCode: Code[10];
    begin
        // Test to verify Original Amount on Customer Ledger Entry after posting Sales Invoice with Discount on Payment Terms.

        // Setup: Create Payment Terms, create and post Sales Invoice.
        PaymentTermsCode := CreatePaymentTerms();
        Amount := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', PaymentTermsCode);  // Use Blank for Currency
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalTemplate.Type::Sales, GenJournalLine."Account Type"::Customer,
          SalesHeader."Sell-to Customer No.", PaymentTermsCode, 0);  // 0 for Amount.

        // Exercise: Post Customer Application.
        ApplyCustLedgerEntryAndPostApplication(GenJournalLine."Journal Batch Name");

        // Verify: verify Original Amount on Customer Ledger Entry.
        Amount := FindPaymentLineAndCalculateOriginalAmount(PaymentTermsCode, Amount);
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          -Amount, CustLedgerEntry."Original Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption("Original Amount"), Amount, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure OriginalAmtOnVendorLedgerEntryWithDiscOnPmtTerms()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        Amount: Decimal;
        PaymentTermsCode: Code[10];
    begin
        // Test to verify Original Amount on Vendor Ledger Entry after posting Purchase Invoice with Discount on Payment Terms.

        // Setup: Create Payment Terms, create and post Purchase Invoice.
        PaymentTermsCode := CreatePaymentTerms();
        Amount := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', PaymentTermsCode, '');  // Use Blank for Currency and Payment Method.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalTemplate.Type::Purchases, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", PaymentTermsCode, 0);  // 0 for Amount.

        // Exercise: Post Vendor Application.
        ApplyVendorLedgerEntryAndPostApplication(GenJournalLine."Journal Batch Name");

        // Verify:  verify Original Amount on Vendor Ledger Entry.
        Amount := FindPaymentLineAndCalculateOriginalAmount(PaymentTermsCode, Amount);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry."Original Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption("Original Amount"), Amount, VendorLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendorBillLineOnVendorBillCard()
    var
        VendorBillHeader: Record "Vendor Bill Header";
        No: Code[20];
    begin
        // Test to verify no error message appears when deleting Vendor Bill Line.

        // Setup: Create and post Puchase Invoice, Create vendor Bill Header and Suggest Vendor Bills.
        No := PostPurchaseInvoiceAndSuggestVendorBills();

        // Exercise.
        DeleteVendorBillLine(No);

        // Verify: Verify Vendor Bill Header exists after Vendor Bill Line has been deleted.
        VendorBillHeader.Get(No);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CancelListOnVendorBillIssuedCard()
    var
        VendorBillCard: TestPage "Vendor Bill Card";
        No: Code[20];
    begin
        // Test to verify no error message appears when Cancel List from Vendor Bill List Issued Card.

        // Setup: Create and post Puchase Invoice, Create vendor Bill Header, Suggest Vendor Bills and Delete Vendor Bill Line.
        No := PostPurchaseInvoiceAndSuggestVendorBills();
        DeleteVendorBillLine(No);

        // Issue Vendor Bill.
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard."&Create List".Invoke();

        // Exercise.
        CancelListOnVendorBillListSentCard(No);

        // Verify: Verify Vendor Bill Header exists after Cancel List from Vendor Bill List Issued Card.
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard."No.".AssertEquals(No);
        VendorBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplateListHandler')]
    [Scope('OnPrem')]
    procedure UpdateBalanceAndTotalBalanceOnPurchaseJournalPage()
    var
        PurchaseJournal: TestPage "Purchase Journal";
        DebitAmount: Decimal;
    begin
        // [FEATURE] [Purchase Journal]
        // [SCENARIO 363437] Balance should be correct after cursor was moved to next row
        // [GIVEN] Gen. Journal Line in Purchase journal with "Debit Amount" = "X"
        DebitAmount := CreateGenJournalLineWithDebitAmount();
        Commit();
        PurchaseJournal.OpenEdit();
        // [WHEN] Cursor move to next row
        PurchaseJournal.Next();
        // [THEN] Balance = "X"
        Assert.AreEqual(DebitAmount, PurchaseJournal.TotalBalance.AsDecimal(), WrongBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentLineNotRemovedAfterMakeOrderFromPurchBlanketOtder()
    var
        PaymentLines: Record "Payment Lines";
        PurchHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Blanket Order] [Purchase]
        // [SCENARIO 376665] Payment Line should not be removed after make order from Purchase Blanket Order

        Initialize();

        // [GIVEN] Purchase Blanket Order with Payment Line, Quantity = 100, "Qty to Receive" = 1
        CreatePurchaseDocument(PurchHeader, PurchHeader."Document Type"::"Blanket Order", '', FindPaymentTermsCode(), '');
        UpdateQtyToReceiveInPurchLine(PurchHeader."Document Type", PurchHeader."No.", 1);

        // [WHEN] Make Order from Blanket Order
        DocumentNo := LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchHeader);

        // [THEN] Payment Line still exist for Blanket Order
        VerifyPaymentLinesExist(
          PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::"Blanket Order", PurchHeader."No.");
        VerifyPaymentLinesExist(
          PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Order, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentLineNotRemovedAfterMakeOrderFromSalesBlanketOtder()
    var
        PaymentLines: Record "Payment Lines";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Blanket Order] [Sales]
        // [SCENARIO 376665] Payment Line should not be removed after make order from Sales Blanket Order

        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Purchase Sales Order with Payment Line, Quantity = 100, "Qty to Receive" = 1
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', FindPaymentTermsCode());
        UpdateQtyToShipInSalesLine(SalesHeader."Document Type", SalesHeader."No.", 1);

        // [WHEN] Make Order from Blanket Order
        DocumentNo := LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // [THEN] Payment Line still exists for Blanket Order
        VerifyPaymentLinesExist(
          PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::"Blanket Order", SalesHeader."No.");
        VerifyPaymentLinesExist(
          PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Order, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_NotPossibleToInsertPaymentLineWithNonExistentPmtTermCode()
    var
        PaymentLines: Record "Payment Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378071] It is not possible to insert Payment Line with type "Payment Terms" and "Code" with non-existent Payment Terms Code

        PaymentLines.Init();
        PaymentLines.Type := PaymentLines.Type::"Payment Terms";
        PaymentLines.Code := LibraryUtility.GenerateGUID();
        PaymentLines.SetRecFilter();

        asserterror PaymentLines.Insert(true);
        Assert.ExpectedErrorCannotFind(Database::"Payment Terms");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertPaymentLineWithTypeInvoice()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378071] It is possible to insert Payment Line with type "Invoice" and calling OnInsert trigger

        Initialize();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Insert(true);

        PaymentLines.Init();
        PaymentLines.Type := PaymentLines.Type::Invoice;
        PaymentLines.Code := SalesHeader."No.";
        PaymentLines.SetRecFilter();

        PaymentLines.Insert(true);

        PaymentLines.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDoNotCreatePaymentLinesWithBlankCode()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] New Invoice where "No." = <blank>, "Posting Date" = '01/01/2017' and "Document Date" = '01/01/2017'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Posting Date" := WorkDate();
        SalesHeader."Document Date" := WorkDate();

        // [WHEN] Validate "Bill-to Customer No." with "C"
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Payment Lines are not created with blank "Code"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreatePaymentLinesWhenValidateCustomerWithPaymentTerms()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = <blank> and "Bill-to Customer No." = "C"

        // [WHEN] Insert record with assigned "No." = "1000"
        InitializeSalesInvoice(SalesHeader, Customer."No.");

        // [THEN] Payment Lines with "Code" = "1000" haven been created
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesDeletePaymentLinesWhenValidateCustomerWithoutPaymentTerms()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C1"
        InitializeSalesInvoice(SalesHeader, Customer."No.");
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");

        // [GIVEN] Customer "C2" without Payment Perms Code
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", '');
        Customer.Modify(true);

        // [WHEN] Validate "Bill-to Customer No." with "C2"
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Payment lines have been deleted with Code = "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDeletePaymentLinesWhenCleanUpDocumentDate()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C"
        InitializeSalesInvoice(SalesHeader, Customer."No.");

        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");

        // [WHEN] Clean up "Document Date" on invoice
        SalesHeader.Validate("Document Date", 0D);

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreatePaymentLinesWhenValidateDocumentDate()
    var
        SalesHeader: Record "Sales Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = 1000 and "Bill-to Customer No." = "C1" and blank "Document Date"
        InitializeSalesInvoice(SalesHeader, Customer."No.");

        SalesHeader.Validate("Document Date", 0D);
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");

        // [WHEN] Validate "Document Date" with "01/01/2017"
        SalesHeader.Validate("Document Date", WorkDate());

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Sales, PaymentLines.Type::Invoice, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDoNotCreatePaymentLinesWithBlankCode()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] New Invoice where "No." = <blank>, "Posting Date" = '01/01/2017' and "Document Date" = '01/01/2017'
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."Posting Date" := WorkDate();
        PurchaseHeader."Document Date" := WorkDate();

        // [WHEN] Validate "Bill-to Customer No." with "C"
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor."No.");

        // [THEN] Payment Lines are not created with blank "Code"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreatePaymentLinesWhenValidateCustomerWithPaymentTerms()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Invoice where "No." = <blank> and "Bill-to Customer No." = "C"

        // [WHEN] Insert record with assigned "No." = "1000"
        InitializePurchaseInvoice(PurchaseHeader, Vendor."No.");

        // [THEN] Payment Lines with "Code" = "1000" haven been created
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDeletePaymentLinesWhenValidateCustomerWithoutPaymentTerms()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C1"
        InitializePurchaseInvoice(PurchaseHeader, Vendor."No.");
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");

        // [GIVEN] Customer "C2" without Payment Perms Code
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", '');
        Vendor.Modify(true);

        // [WHEN] Validate "Bill-to Customer No." with "C2"
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor."No.");

        // [THEN] Payment lines have been deleted with Code = "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDeletePaymentLinesWhenCleanUpDocumentDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C"
        InitializePurchaseInvoice(PurchaseHeader, Vendor."No.");

        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");

        // [WHEN] Clean up "Document Date" on invoice
        PurchaseHeader.Validate("Document Date", 0D);

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreatePaymentLinesWhenValidateDocumentDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Purchase]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Invoice where "No." = 1000 and "Bill-to Customer No." = "C1" and blank "Document Date"
        InitializePurchaseInvoice(PurchaseHeader, Vendor."No.");

        PurchaseHeader.Validate("Document Date", 0D);
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");

        // [WHEN] Validate "Document Date" with "01/01/2017"
        PurchaseHeader.Validate("Document Date", WorkDate());

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Purchase, PaymentLines.Type::Invoice, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServicesDoNotCreatePaymentLinesWithBlankCode()
    var
        ServiceHeader: Record "Service Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Service]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] New Invoice where "No." = <blank>, "Posting Date" = '01/01/2017' and "Document Date" = '01/01/2017'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader."Posting Date" := WorkDate();
        ServiceHeader."Document Date" := WorkDate();

        // [WHEN] Validate "Bill-to Customer No." with "C"
        ServiceHeader.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Payment Lines are not created with blank "Code"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServicesCreatePaymentLinesWhenValidateCustomerWithPaymentTerms()
    var
        ServiceHeader: Record "Service Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Service]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = <blank> and "Bill-to Customer No." = "C"

        // [WHEN] Insert record with assigned "No." = "1000"
        InitializeServiceInvoice(ServiceHeader, Customer."No.");

        // [THEN] Payment Lines with "Code" = "1000" haven been created
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ServicesDeletePaymentLinesWhenValidateCustomerWithoutPaymentTerms()
    var
        ServiceHeader: Record "Service Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Service]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C1"
        InitializeServiceInvoice(ServiceHeader, Customer."No.");
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");

        // [GIVEN] Customer "C2" without Payment Perms Code
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", '');
        Customer.Modify(true);

        // [WHEN] Validate "Bill-to Customer No." with "C2"
        ServiceHeader.Validate("Bill-to Customer No.", Customer."No.");

        // [THEN] Payment lines have been deleted with Code = "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServicesDeletePaymentLinesWhenCleanUpDocumentDate()
    var
        ServiceHeader: Record "Service Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Service]
        Initialize();

        // [GIVEN] Customer "C" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = "1000" and "Bill-to Customer No." = "C"
        InitializeServiceInvoice(ServiceHeader, Customer."No.");

        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");

        // [WHEN] Clean up "Document Date" on invoice
        ServiceHeader.Validate("Document Date", 0D);

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServicesCreatePaymentLinesWhenValidateDocumentDate()
    var
        ServiceHeader: Record "Service Header";
        PaymentLines: Record "Payment Lines";
        Customer: Record Customer;
    begin
        // [FEATURE] [Service]
        Initialize();

        // [GIVEN] Customer "C1" with Payment Terms Code
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice where "No." = 1000 and "Bill-to Customer No." = "C1" and blank "Document Date"
        InitializeServiceInvoice(ServiceHeader, Customer."No.");

        ServiceHeader.Validate("Document Date", 0D);
        VerifyPaymentLinesDoNotExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");

        // [WHEN] Validate "Document Date" with "01/01/2017"
        ServiceHeader.Validate("Document Date", WorkDate());

        // [THEN] Payment lines have deleted for code "1000"
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Service, PaymentLines.Type::Invoice, ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreatePaymentLinesOnNewDocEnteringVendorNo()
    var
        PurchHeader: Record "Purchase Header";
        PaymentLines: Record "Payment Lines";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 279058] Payment lines are created when Purchase Header.InitInsert is run
        Initialize();

        // [GIVEN] A new purchase header
        PurchHeader.Init();

        // [GIVEN] Header is populated with Vendor data, including payment terms code
        PurchHeader.Validate("Buy-from Vendor No.", LibraryPurchase.CreateVendorNo());

        // [WHEN] Running InitInsert
        PurchHeader.InitInsert();

        // [THEN] Payment lines for this document type, document no are created.
        VerifyPaymentLinesExist(PaymentLines."Sales/Purchase"::Purchase, PurchHeader."Document Type", PurchHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnPurchInvoiceWithMultipleVLE();
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment Terms] [UI]
        // [SCENARIO 314721] Posted Purchase Invoice has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos.
        Initialize();

        // [GIVEN] Purchase Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), '');

        // [WHEN] Purchase Header was posted
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [THEN] Posted Purchase Invoice header has Remaining Amount = "100" on Posted Purchase Invoices page
        VerifyRemainingAmountOnPurchaseInvoice(PurchInvHeader."No.", DocumentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnPurchCrMemoWithMultipleVLE();
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Payment Terms] [UI]
        // [SCENARIO 314721] Posted Purchase Credit Memo has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos.
        Initialize();

        // [GIVEN] Purchase Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreatePurchaseDocument(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', FindPaymentTermsCode(), '');

        // [WHEN] Purchase Header was posted
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [THEN] Posted Purchase Credit Memo header has Remaining Amount = "100" on Posted Purchase Credit Memos page
        VerifyRemainingAmountOnPurchaseCrMemo(PurchCrMemoHdr."No.", -DocumentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnSalesInvoiceWithMultipleCLE();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Terms] [UI]
        // [SCENARIO 314721] Posted Sales Invoice has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos.
        Initialize();

        // [GIVEN] Sales Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', FindPaymentTermsCode());

        // [WHEN] Sales Header was posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [THEN] Posted Sales Invoice header has Remaining Amount = "100" on Posted Sales Invoices page
        VerifyRemainingAmountOnSalesInvoice(SalesInvoiceHeader."No.", DocumentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnSalesCrMemoWithMultipleCLE();
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Payment Terms] [UI]
        // [SCENARIO 314721] Posted Sales Credit Memo has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos.
        Initialize();

        // [GIVEN] Sales Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', FindPaymentTermsCode());

        // [WHEN] Sales Header was posted
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [THEN] Posted Sales Credit Memo header has Remaining Amount = "100" on Posted Sales Credit Memos page
        VerifyRemainingAmountOnSalesCrMemo(SalesCrMemoHeader."No.", -DocumentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnPurchInvoiceWithMultipleVLEAfterApplyPayment();
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Payment Terms] [Apply] [UI]
        // [SCENARIO 314721] Posted Purchase Invoice has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos. and Payment is applied after
        Initialize();

        // [GIVEN] Purchase Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), '');

        // [GIVEN] Purchase Header was posted
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [WHEN] Payment for "33" is applied
        PaymentAmount := Round(DocumentAmount / 3);
        CreateApplyAndPostVendorPayment(
          PurchInvHeader."Pay-to Vendor No.", PurchInvHeader."No.", PurchaseHeader."Document Type"::Invoice, PaymentAmount);

        // [THEN] Posted Purchase Invoice header has Remaining Amount = "67" on Posted Purchase Invoices page
        VerifyRemainingAmountOnPurchaseInvoice(PurchInvHeader."No.", DocumentAmount - PaymentAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmountIsCorrectOnSalesInvoiceWithMultipleCLEAfterApplyPayment();
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [Payment Terms] [Apply] [UI]
        // [SCENARIO 314721] Posted Sales Invoice has correct Remaining Amount when posted with Payment Terms with 2 Payment Nos.
        Initialize();

        // [GIVEN] Sales Header with Payment Terms with 2 payment nos. and Amount = "100"
        DocumentAmount := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', FindPaymentTermsCode());

        // [GIVEN] Sales Header was posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Payment for "-33" is applied
        PaymentAmount := -Round(DocumentAmount / 3);
        CreateApplyAndPostCustomerPayment(
          SalesInvoiceHeader."Bill-to Customer No.", SalesInvoiceHeader."No.",
          SalesHeader."Document Type"::Invoice, PaymentAmount);

        // [THEN] Posted Sales Invoice header has Remaining Amount = "67" on Posted Sales Invoices page
        VerifyRemainingAmountOnSalesInvoice(SalesInvoiceHeader."No.", DocumentAmount + PaymentAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorBillsRPH,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SuggestVendorBillsRespectsUseSameCode()
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        Vendor: array[2] of Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        SuggestVendorBills: Report "Suggest Vendor Bills";
        ABICodes: array[2] of Code[5];
        BankAccountNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Invoice] [Bill]
        // [SCENARIO 352490] When "Use same ABI code" option is selected on Suggest Vendor Bills it only works for vendors with same ABI code
        Initialize();

        // [GIVEN] Two ABI Codes "C1" and "C2"
        ABICodes[1] := CreateABICodeInRange(10000, 20000);
        ABICodes[2] := CreateABICodeInRange(30000, 40000);

        // [GIVEN] Bank "B1" with ABI Code "C1"
        BankAccountNo := CreateBankAccountWithABICode(ABICodes[1]);

        // [GIVEN] Payment Method with Bill code was created
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateBill(Bill);
        PaymentMethod.Validate("Bill Code", Bill.Code);
        PaymentMethod.Modify(true);

        // [GIVEN] Vendor "V1" with Bank "B2" with ABI Code "C1"
        CreateVendorWithABICodeAndPaymentMethod(Vendor[1], ABICodes[1], PaymentMethod.Code);

        // [GIVEN] Vendor "V2" with Bank "B3" with ABI Code "C2"
        CreateVendorWithABICodeAndPaymentMethod(Vendor[2], ABICodes[2], PaymentMethod.Code);

        // [GIVEN] Purchase invoices posted for both vendors
        for i := 1 to ArrayLen(Vendor) do begin
            LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor[i]."No.");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;

        // [GIVEN] Vendor bill header with payment code for Bank "B1" was created
        CreateVendorBillHeader(VendorBillHeader, PaymentMethod.Code);
        VendorBillHeader.Validate("Bank Account No.", BankAccountNo);
        VendorBillHeader.Modify(true);

        // [WHEN] Suggest Vendor Bills report is ran for Vendor bill header with "Use same ABI code" = TRUE
        SuggestVendorBills.InitValues(VendorBillHeader);
        LibraryVariableStorage.Enqueue(true);
        Commit();
        SuggestVendorBills.Run();
        // UI handled by SuggestVendorBillsUIHandler

        // [THEN] Vendor bill line for "V1" exists
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.SetRange("Vendor No.", Vendor[1]."No.");
        Assert.RecordIsNotEmpty(VendorBillLine);

        // [THEN] Vendor bill line for "V2" does not exist
        VendorBillLine.SetRange("Vendor No.", Vendor[2]."No.");
        Assert.RecordIsEmpty(VendorBillLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('UIConfirmHandler,PurchaseInvoiceHandler')]
    procedure CreateCorrectPostedPurchInvoiceWithMultiplePaymentLines();
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PaymentTermsCode: Code[10];
        PostedPurchaseDoc: Code[20];
        PostedPurchInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [SCENARIO 459520] Unable to correct a posted purchase invoice when with multiple payment installment in the Italian localization
        Initialize();

        // [GIVEN] Create Vendor and Payment Term Code of 2 payment lines.
        LibraryPurchase.CreateVendor(Vendor);
        PaymentTermsCode := CreatePaymentTerms();

        // [GIVEN] Update Payment Term Code in Vendor .
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify();

        // [GIVEN] Create Purchase document and post the document.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', PaymentTermsCode, '');
        PostedPurchaseDoc := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Open Posted Purchase Invoice page and click on "Correct" Invoice action button.
        PurchInvHeader.Get(PostedPurchaseDoc);
        PostedPurchInvoice.OpenEdit();
        PostedPurchInvoice.GoToRecord(PurchInvHeader);
        PostedPurchInvoice.CorrectInvoice.Invoke();

        // [VERIFY] Verify credit memo posted and applied successfully with the posted invoice and balance of vendor will be 0.
        Vendor.CalcFields(Balance);
        Assert.AreEqual(0, Vendor.Balance, VendorBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToDocNoShouldBringCorrectDueDateAsPerSelectedLineOfPostedPurchaseInvoiceWithSplitPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentAmount: Decimal;
        PaymentTermsCode: Code[10];
    begin
        // [SCENARIO 560381] Applies-to-Doc No. brings the first Due Date even if you select the second line of an Purchase Invoice with split payments in the Italian version.
        Initialize();

        // [GIVEN] Purchase Header with Payment Terms with 2 payment nos. and Amount = "100"
        PaymentTermsCode := CreatePaymentTerms();
        DocumentAmount := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', PaymentTermsCode, '');

        // [GIVEN] Post Purchase Invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [WHEN] Create Payment Journal Line with Applies-To Doc. No. with specific Applies-to Occurrence No.
        CreateGenJournalLineWithAppliesToOccurrence(
            GenJournalLine, GenJournalLine."Account Type"::Vendor, PurchInvHeader."Pay-to Vendor No.", Round(DocumentAmount / 3),
            GenJournalLine."Document Type"::Payment, PurchaseHeader."Document Type"::Invoice, PurchInvHeader."No.", 2);

        // [THEN] Verify Applies-to Doc. Due Date is correct on Payment Journal Line as per selected line
        GetVendorLedgerEntry(VendorLedgerEntry, PurchInvHeader."No.", 2);
        VerifyGetAppliesToDocDueDate(GenJournalLine."Journal Batch Name", VendorLedgerEntry."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToDocNoShouldBringCorrectDueDateAsPerSelectedLineOfPostedSalesInvoiceWithSplitPayment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentAmount: Decimal;
        PaymentTermsCode: Code[10];
    begin
        // [SCENARIO 560381] Applies-to-Doc No. brings the first Due Date even if you select the second line of an Sales Invoice with split payments in the Italian version.
        Initialize();

        // [GIVEN] Sales Header with Payment Terms with 2 payment nos. and Amount = "100"
        PaymentTermsCode := CreatePaymentTerms();
        DocumentAmount := CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, '', PaymentTermsCode);

        // [GIVEN] Post Sales Invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Create Payment Journal Line with Applies-To Doc. No. with specific Applies-to Occurrence No.
        CreateGenJournalLineWithAppliesToOccurrence(
            GenJournalLine, GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Bill-to Customer No.", Round(DocumentAmount / 3),
            GenJournalLine."Document Type"::Payment, SalesHeader."Document Type"::Invoice, SalesInvoiceHeader."No.", 2);

        // [THEN] Verify Applies-to Doc. Due Date is correct on Payment Journal Line as per selected line
        GetCustLedgerEntry(CustLedgerEntry, SalesInvoiceHeader."No.", 2);
        VerifyGetAppliesToDocDueDate(GenJournalLine."Journal Batch Name", CustLedgerEntry."Due Date");
    end;

    [Test]
    procedure AppliesToDocNoAppliesPaymentSecondOccurrenceInvoiceWhenSecondOccurrence()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        PaymentTermsCode: Code[10];
    begin
        // [SCENARIO 563980] Applies-to-Doc No. Applies Payment to the second Occurrence in an Invoice when selecting the second line.
        Initialize();

        // [GIVEN] Create a Payment Terms.
        PaymentTermsCode := CreatePaymentTerms();

        // [GIVEN] Create a Purchase Document.
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', PaymentTermsCode, '');

        // [GIVEN] Post Purchase Invoice.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry[1].SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry[1].SetRange("Document Occurrence", 2);
        VendorLedgerEntry[1].FindFirst();

        // [GIVEN] Find Detailed Vendor Ledger Entry.
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry[1]."Entry No.");
        DetailedVendorLedgEntry.FindFirst();

        // [GIVEN] Create Payment Journal To Applies To Occurrence.
        CreateGenJournalLineWithAppliesToOccurrence(
            GenJournalLine,
            GenJournalLine."Account Type"::Vendor,
            PurchInvHeader."Pay-to Vendor No.",
            -DetailedVendorLedgEntry.Amount,
            GenJournalLine."Document Type"::Payment,
            PurchaseHeader."Document Type"::Invoice,
            PurchInvHeader."No.",
            2);

        // [GIVEN] Validate "Bal. Account No.", "Bal. Gen. Posting Type "and "External Document No.".
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::Purchase);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        // [GIVEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Vendor Ledger should be applied as per Occurrence selected.
        VendorLedgerEntry[2].CalcFields("Remaining Amount");
        VendorLedgerEntry[2].SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry[2].SetRange("Document Occurrence", 2);
        VendorLedgerEntry[2].FindFirst();
        Assert.AreEqual(
            VendorLedgerEntry[2]."Remaining Amount",
            0,
            StrSubstNo(
                RemainingAmountErr,
                VendorLedgerEntry[2]."Remaining Amount"));
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure InitializeSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Insert(true);
    end;

    local procedure InitializePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader.Validate("Pay-to Vendor No.", VendorNo);
        PurchaseHeader.Insert(true);
    end;

    local procedure InitializeServiceInvoice(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    begin
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader.Validate("Bill-to Customer No.", CustomerNo);
        ServiceHeader.Insert(true);
    end;

    local procedure ApplyCustLedgerEntryAndPostApplication(CurrentJnlBatchName: Code[10])
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        Commit();
        SalesJournal.OpenEdit();
        SalesJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        SalesJournal."Apply Entries".Invoke();
        SalesJournal.Post.Invoke();
    end;

    local procedure ApplyVendorLedgerEntryAndPostApplication(CurrentJnlBatchName: Code[10])
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        Commit();
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(CurrentJnlBatchName);
        PurchaseJournal."Apply Entries".Invoke();
        PurchaseJournal.Post.Invoke();
    end;

    local procedure CancelListOnVendorBillListSentCard(No: Code[20])
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("No.", No);
        VendorBillListSentCard.CancelList.Invoke();
    end;

    local procedure CreateAndPostServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; Invoice: Boolean) AmountIncludingVAT: Decimal
    begin
        AmountIncludingVAT := CreateServiceDocument(ServiceHeader, DocumentType, '');  // Use Blank for Currency.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, Invoice);  // True for Ship
    end;

    local procedure CreateApplyAndPostCustomerPayment(CustomerNo: Code[20]; AppliesToDocumentNo: Code[20]; AppliesToDocumentType: Enum "Sales Document Type"; PmtAmount: Decimal): Code[20];
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        EXIT(
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Customer, CustomerNo, PmtAmount,
            GenJournalLine."Document Type"::Payment, AppliesToDocumentType, AppliesToDocumentNo));
    end;

    local procedure CreateApplyAndPostVendorPayment(VendorNo: Code[20]; AppliesToDocumentNo: Code[20]; AppliesToDocumentType: Enum "Purchase Document Type"; PmtAmount: Decimal): Code[20];
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        EXIT(
          CreateAndPostGenJournalLine(
            GenJournalLine."Account Type"::Vendor, VendorNo, PmtAmount,
            GenJournalLine."Document Type"::Payment, AppliesToDocumentType, AppliesToDocumentNo));
    end;

    local procedure CreateAndPostGenJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]): Code[20];
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLineWithAppliesTo(GenJournalLine, DocumentType, AccountType, AccountNo, Amount, AppliesToDocType, AppliesToDocNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        EXIT(GenJournalLine."Document No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));  // Use Random value for Exchange Rate Amount
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", LibraryRandom.RandDec(100, 2));  // Use Random value for Relational Exchange Rate Amount
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        GenJournalTemplate.FindFirst();
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; Type: Enum "Gen. Journal Template Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PaymentTermsCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", CreateBankAccount());
        GenJournalLine.Validate("Payment Terms Code", PaymentTermsCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLineWithAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]);
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateABICodeInRange("Min": Integer; "Max": Integer): Code[5]
    var
        ABICodes: Record "ABI/CAB Codes";
        ABICode: Code[5];
    begin
        ABICode := Format(LibraryRandom.RandIntInRange(Min, Max));
        ABICodes.Init();
        ABICodes.ABI := ABICode;
        ABICodes.CAB := ABICode;
        if ABICodes.Insert() then;
        exit(ABICode);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountWithABICode(ABICode: Code[5]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate(ABI, ABICode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentPct: Integer;
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        PaymentPct := LibraryRandom.RandIntInRange(1, 50);
        CreatePaymentLines(PaymentTerms.Code, PaymentPct);
        CreatePaymentLines(PaymentTerms.Code, 100 - PaymentPct);  // Subtracted from 100 to make two installment for Payment.
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePaymentLines(PaymentTermsCode: Code[10]; PaymentPct: Integer)
    var
        PaymentLines: Record "Payment Lines";
    begin
        LibraryERM.CreatePaymentLinesDiscount(PaymentLines, PaymentTermsCode);
        PaymentLines.Validate("Payment %", PaymentPct);
        PaymentLines.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; PaymentTermsCode: Code[10]; PaymentMethodCode: Code[10]): Decimal
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendorWithPaymentMethod(PaymentMethodCode));
        PurchaseHeader.Validate("Payment Terms Code", PaymentTermsCode);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Quantity
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Use Random value for Direct Unit Cost
        PurchaseLine.Validate("Unit Cost (LCY)", LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Unit Cost
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; PaymentTermsCode: Code[10]): Decimal
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Quantity
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Unit Price
        SalesLine.Modify(true);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CurrencyCode: Code[10]): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, CurrencyCode);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccount());
        exit(ServiceLine."Amount Including VAT");
    end;

    local procedure CreateServiceDocumentWithMultipleLines(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type") AmountIncludingVAT: Decimal
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        AmountIncludingVAT := CreateServiceDocument(ServiceHeader, DocumentType, '');  // Use Blank for Currency
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        AmountIncludingVAT += ServiceLine."Amount Including VAT";
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Validate("Payment Terms Code", FindPaymentTermsCode());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Quantity
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));  // Use Random value for Unit Price
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendorWithABICodeAndPaymentMethod(var Vendor: Record Vendor; ABICode: Code[5]; PaymentMethodCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate(ABI, ABICode);
        VendorBankAccount.Modify(true);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header"; PaymentMethodCode: Code[10])
    begin
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", CreateBankAccount());
        VendorBillHeader.Validate("Payment Method Code", PaymentMethodCode);
        VendorBillHeader.Modify(true);
    end;

    local procedure DeleteServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.Delete(true);
    end;

    local procedure CreateVendorWithPaymentMethod(PaymentMethodCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGenJournalLineWithDebitAmount(): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlTmplAndGenJnlBatch(GenJournalBatch, GenJournalTemplate.Type::Purchases);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type", GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandDec(1000, 2));
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        exit(GenJournalLine."Debit Amount");
    end;

    local procedure CreateGenJnlTmplAndGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure DeleteVendorBillLine(VendorBillListNo: Code[20])
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillListNo);
        VendorBillLine.SetFilter("Vendor No.", '<>%1', '');
        VendorBillLine.FindFirst();
        VendorBillLine.Delete(true);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Original Amount");
    end;

    local procedure FindPaymentTermsCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Payment Nos.", '>1');  // Payment Term Code with multiple Payments is required
        PaymentTerms.FindFirst();
        exit(PaymentTerms.Code);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount, "Original Amount");
    end;

    local procedure FindPaymentLineAndCalculateOriginalAmount("Code": Code[10]; Amount: Decimal): Decimal
    var
        PaymentLines: Record "Payment Lines";
        DiscountAmount: Decimal;
    begin
        PaymentLines.SetRange(Code, Code);
        PaymentLines.FindSet();
        repeat
            DiscountAmount += Amount * (PaymentLines."Payment %" / 100) * (PaymentLines."Discount %" / 100);
        until PaymentLines.Next() = 0;
        exit(Amount - DiscountAmount);
    end;

    local procedure FilterPaymentLines(var PaymentLines: Record "Payment Lines"; EntryType: Option; DocType: Enum "Payment Lines Document Type"; DocNo: Code[20])
    begin
        PaymentLines.SetRange("Sales/Purchase", EntryType);
        PaymentLines.SetRange(Type, DocType);
        PaymentLines.SetRange(Code, DocNo);
    end;

    local procedure UpdateQtyToReceiveInPurchLine(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; QtyToReceive: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", DocType);
        PurchLine.SetRange("Document No.", DocNo);
        PurchLine.FindFirst();
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Modify(true);
    end;

    local procedure UpdateQtyToShipInSalesLine(DocType: Enum "Sales Document Type"; DocNo: Code[20]; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure GetDueDateCalculationFromPaymentTerms(var FirstDueDateCalculation: DateFormula; "Code": Code[10]): Text
    var
        PaymentLines: Record "Payment Lines";
    begin
        PaymentLines.SetRange(Code, Code);
        PaymentLines.FindSet();
        FirstDueDateCalculation := PaymentLines."Due Date Calculation";
        PaymentLines.Next();
        exit(Format(PaymentLines."Due Date Calculation"));
    end;

    local procedure InvokePaymentDateLinesPageFromServiceCreditMemo(No: Code[20])
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo."Pa&yments".Invoke();
        ServiceCreditMemo.Close();
    end;

    local procedure InvokePaymentDateLinesPageFromServiceInvoice(var ServiceInvoice: TestPage "Service Invoice"; No: Code[20])
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice."Pa&yments".Invoke();
    end;

    local procedure InvokePaymentDateLinesPageFromServiceOrder(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder."Pa&yments".Invoke();
        ServiceOrder.Close();
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

    local procedure PostPurchaseInvoiceAndSuggestVendorBills(): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        PurchaseHeader: Record "Purchase Header";
        VendorBillHeader: Record "Vendor Bill Header";
        Bill: Record Bill;
    begin
        // Create and post Purchase Invoice.
        Bill.SetFilter("Vendor Bill List", '<>%1', '');
        Bill.SetFilter("Vend. Bill Source Code", '<>%1', '');
        Bill.FindFirst();
        PaymentMethod.SetRange("Bill Code", Bill.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);

        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', FindPaymentTermsCode(), PaymentMethod.Code);  // Use Blank for Currency
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create Vendor Bill Header and Suggest Vendor Bills.
        CreateVendorBillHeader(VendorBillHeader, PaymentMethod.Code);
        RunSuggestVendorBills(VendorBillHeader, PurchaseHeader."Buy-from Vendor No.");
        exit(VendorBillHeader."No.");
    end;

    local procedure VerifyAmountOnPaymentDateLinesPage(PaymentDateLines: TestPage "Payment Date Lines"; DueDateCalculation: DateFormula; ExpectedAmount: Decimal)
    begin
        PaymentDateLines.FILTER.SetFilter("Due Date Calculation", Format(DueDateCalculation));
        Assert.AreNearlyEqual(
          ExpectedAmount, PaymentDateLines.Amount.AsDecimal(), LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, PaymentDateLines.Amount.Caption, ExpectedAmount, PaymentDateLines.Caption));
    end;

    local procedure VerifyAmountsOnPaymentDateLinesPage(PaymentDateLines: TestPage "Payment Date Lines"; Amount: Decimal)
    var
        DueDateCalculation: DateFormula;
        SecondDueDateCalculation: DateFormula;
    begin
        Evaluate(SecondDueDateCalculation, GetDueDateCalculationFromPaymentTerms(DueDateCalculation, FindPaymentTermsCode()));
        VerifyAmountOnPaymentDateLinesPage(PaymentDateLines, DueDateCalculation, Amount);
        VerifyAmountOnPaymentDateLinesPage(PaymentDateLines, SecondDueDateCalculation, Amount);
        PaymentDateLines.Close();
    end;

    local procedure VerifyAmountOnPostedPaymentsPage(PostedPayments: TestPage "Posted Payments"; DueDateCalculation: DateFormula; ExpectedAmount: Decimal)
    begin
        PostedPayments.FILTER.SetFilter("Due Date Calculation", Format(DueDateCalculation));
        Assert.AreNearlyEqual(
          ExpectedAmount, PostedPayments.Amount.AsDecimal(), LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, PostedPayments.Amount.Caption, ExpectedAmount, PostedPayments.Caption));
    end;

    local procedure VerifyAmountsOnPostedPaymentsPage(PostedPayments: TestPage "Posted Payments"; Amount: Decimal)
    var
        DueDateCalculation: DateFormula;
        SecondDueDateCalculation: DateFormula;
    begin
        Evaluate(SecondDueDateCalculation, GetDueDateCalculationFromPaymentTerms(DueDateCalculation, FindPaymentTermsCode()));
        VerifyAmountOnPostedPaymentsPage(PostedPayments, DueDateCalculation, Amount);
        VerifyAmountOnPostedPaymentsPage(PostedPayments, SecondDueDateCalculation, Amount);
        PostedPayments.Close();
    end;

    local procedure VerifyAmountOnVendorLedgerEntry(DocumentNo: Code[20]; Amount: Decimal; DueDateCalculation: DateFormula)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DueDate: Date;
    begin
        DueDate := CalcDate('<' + Format(DueDateCalculation) + '>', WorkDate());
        VendorLedgerEntry.SetRange("Due Date", DueDate);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, VendorLedgerEntry.FieldCaption(Amount), Amount, VendorLedgerEntry.TableCaption()));
    end;

    local procedure VerifyAmountOnCustomerLedgerEntry(DocumentNo: Code[20]; Amount: Decimal; DueDateCalculation: DateFormula)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DueDate: Date;
    begin
        DueDate := CalcDate('<' + Format(DueDateCalculation) + '>', WorkDate());
        CustLedgerEntry.SetRange("Due Date", DueDate);
        FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyPaymentLinesExist(EntryType: Option; DocType: Enum "Payment Lines Document Type"; DocNo: Code[20])
    var
        PaymentLines: Record "Payment Lines";
    begin
        FilterPaymentLines(PaymentLines, EntryType, DocType, DocNo);
        Assert.RecordIsNotEmpty(PaymentLines);
    end;

    local procedure VerifyPaymentLinesDoNotExist(EntryType: Option; DocType: Enum "Payment Lines Document Type"; DocNo: Code[20])
    var
        PaymentLines: Record "Payment Lines";
    begin
        FilterPaymentLines(PaymentLines, EntryType, DocType, DocNo);
        Assert.RecordIsEmpty(PaymentLines);
    end;

    local procedure VerifyRemainingAmountOnSalesInvoice(DocumentNo: Code[20]; Amount: Decimal);
    var
        PostedSalesInvoicesPage: TestPage "Posted Sales Invoices";
    begin
        PostedSalesInvoicesPage.OpenView();
        PostedSalesInvoicesPage.FILTER.SETFILTER("No.", DocumentNo);
        PostedSalesInvoicesPage."Remaining Amount".ASSERTEQUALS(Amount);
        PostedSalesInvoicesPage.Close();
    end;

    local procedure VerifyRemainingAmountOnSalesCrMemo(DocumentNo: Code[20]; Amount: Decimal);
    var
        PostedSalesCreditMemosPage: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemosPage.OpenView();
        PostedSalesCreditMemosPage.FILTER.SETFILTER("No.", DocumentNo);
        PostedSalesCreditMemosPage."Remaining Amount".ASSERTEQUALS(Amount);
        PostedSalesCreditMemosPage.Close();
    end;

    local procedure VerifyRemainingAmountOnPurchaseInvoice(DocumentNo: Code[20]; Amount: Decimal);
    var
        PostedPurchaseInvoicesPage: TestPage "Posted Purchase Invoices";
    begin
        PostedPurchaseInvoicesPage.OpenView();
        PostedPurchaseInvoicesPage.FILTER.SETFILTER("No.", DocumentNo);
        PostedPurchaseInvoicesPage."Remaining Amount".ASSERTEQUALS(Amount);
        PostedPurchaseInvoicesPage.Close();
    end;

    local procedure VerifyRemainingAmountOnPurchaseCrMemo(DocumentNo: Code[20]; Amount: Decimal);
    var
        PostedPurchaseCreditMemosPage: TestPage "Posted Purchase Credit Memos";
    begin
        PostedPurchaseCreditMemosPage.OpenView();
        PostedPurchaseCreditMemosPage.FILTER.SETFILTER("No.", DocumentNo);
        PostedPurchaseCreditMemosPage."Remaining Amount".ASSERTEQUALS(Amount);
        PostedPurchaseCreditMemosPage.Close();
    end;

    local procedure CreateGenJournalLineWithAppliesToOccurrence(
        var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal;
        DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; AppliesToOccurrenceNo: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentGeneralBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Applies-to Occurrence No.", AppliesToOccurrenceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePaymentGeneralBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure GetVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; DocumentOccurrence: Integer)
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Document Occurrence", DocumentOccurrence);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure GetCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; DocumentOccurrence: Integer)
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Occurrence", DocumentOccurrence);
        CustLedgerEntry.FindFirst();
    end;

    local procedure VerifyGetAppliesToDocDueDate(JournalBatchName: Code[10]; DueDate: Date)
    var

        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        PaymentJournal.GetAppliesToDocDueDate.AssertEquals(DueDate);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.Next();
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalTemplateListHandler(var GenJournalTemplateList: TestPage "General Journal Template List")
    var
        GenJournalTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplateName);
        GenJournalTemplateList.FILTER.SetFilter(Name, GenJournalTemplateName);
        GenJournalTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var TheNotification: Notification): Boolean
    begin
        exit(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorBillsRPH(var SuggestVendorBills: TestRequestPage "Suggest Vendor Bills")
    begin
        SuggestVendorBills.UseSameABICode.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestVendorBills.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UIConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    begin
        PurchaseInvoice.Close();
    end;
}

