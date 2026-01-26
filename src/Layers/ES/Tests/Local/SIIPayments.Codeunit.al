codeunit 147529 "SII Payments"
{
    // // [FEATURE] [SII] [Unrealized VAT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        SIIXMLCreator: Codeunit "SII XML Creator";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySII: Codeunit "Library - SII";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        XmlType: Option Invoice,"Intra Community",Payment;
        IsInitialized: Boolean;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesCobroTok: Label '//soapenv:Body/siiLR:SuministroLRCobrosEmitidas/siiLR:RegistroLRCobros/siiLR:Cobros/sii:Cobro/';
        XPathPurchasePagoTok: Label '//soapenv:Body/siiLR:SuministroLRPagosRecibidas/siiLR:RegistroLRPagos/siiLR:Pagos/sii:Pago/';
        UploadType: Option Regular,Intracommunity,RetryAccepted;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedSalesPayment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232943] Sales Invoice Details has non-zero amounts for Unrealized VAT and Cash Regime
        // 265023: SII Doc. Upload State of Cash Based Sales Payment has "Inv. Entry No." and "Document No." of invoice applied to payment

        Initialize();

        CreateCustomer(Customer, VATPostingSetup, 0);

        // [GIVEN] Creation of a Sales Invoice for a local customer, cash based, "Entry No." = 123, "Document No." = "X"
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindCustLedgEntry(CustLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, true, false);

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local customer, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry, DocumentNo);

        // [THEN] Assert that the values in the xml are valid
        // Non-zero values verified in LibrarySII.VerifyXml
        LibrarySII.VerifyXml(XMLDoc, DetailedCustLedgEntry, XmlType::Payment, true, false);

        // [THEN] SII Doc. Upload State of Cash Based Payment has "Inv. Entry No." = 123, "Document No." = "X"
        VerifyDocUploadStateCustomerPmt(DetailedCustLedgEntry."Entry No.", SIIDocUploadState."Document Type"::Payment);

        // [THEN] Two job queue entries have been initiated, one for invoice and one for payment
        VerifyUploadPendingDocsJobQueueEntryCount(2);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedPurchasePayment()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExtDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232943] Purchase Invoice Details has non-zero amounts for Unrealized VAT and Cash Regime
        // 265023: SII Doc. Upload State of Cash Based Sales Payment has "Inv. Entry No." and "External Document No." of invoice applied to payment

        Initialize();

        CreateVendor(Vendor, VATPostingSetup, 0);

        // [GIVEN] Creation of an Purchase Invoice for a local vendor, cash based, "Entry No." = 123, "Document No." = "X", "External Document No." = "Y"
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindVendLedgEntry(VendorLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, true, false);
        LibrarySII.AssertLibraryVariableStorage();

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry, DocumentNo);

        // [THEN] Assert that the values in the xml are valid
        // Non-zero values verified in LibrarySII.VerifyXml
        LibrarySII.VerifyXml(XMLDoc, DetailedVendorLedgEntry, XmlType::Payment, true, false);

        // [THEN] SII Doc. Upload State of Cash Based Payment has "Inv. Entry No." = 123, "Document No." = "Y"
        VerifyDocUploadStateVendorPmt(DetailedVendorLedgEntry."Entry No.", SIIDocUploadState."Document Type"::Payment);

        // [THEN] Two job queue entries have been initiated, one for invoice and one for payment
        VerifyUploadPendingDocsJobQueueEntryCount(2);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedSalesPaymentWithNonDefaultSIIPmtCode()
    var
        PaymentMethod: Record "Payment Method";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232943] Medio node has value of SII Payment Method Code of Customer Ledger Entry

        Initialize();

        CreateCustomer(Customer, VATPostingSetup, PaymentMethod."SII Payment Method Code"::"01");

        // [GIVEN] Creation of a Sales Invoice for a local customer, cash based and "SII Payment Method Code" = "01"
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindCustLedgEntry(CustLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, true, false);

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local customer, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry, DocumentNo);

        // [THEN] Medio node has value "01" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesCobroTok, 'sii:Medio', Format(PaymentMethod."SII Payment Method Code"::"01"));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedPurchasePaymentWithNonDefaultPmtCode()
    var
        PaymentMethod: Record "Payment Method";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExtDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232943] Medio node has value of SII Payment Method Code of Vendor Ledger Entry

        Initialize();

        CreateVendor(Vendor, VATPostingSetup, PaymentMethod."SII Payment Method Code"::"01");

        // [GIVEN] Creation of an Purchase Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindVendLedgEntry(VendorLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, true, false);
        LibrarySII.AssertLibraryVariableStorage();

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry, DocumentNo);

        // [THEN] Medio node has value "01" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchasePagoTok, 'sii:Medio', Format(PaymentMethod."SII Payment Method Code"::"01"));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIEntryCreatesOnSalesPayment()
    var
        VATEntry: Record "VAT Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        EntryNo: Integer;
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 267931] SII Doc. Upload State and SII History entries creates for Detailed Customer Ledger Entry with Payment and Unrealized VAT

        Initialize();

        MockVATEntry(VATEntry);
        EntryNo := MockInvoiceCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        FindSIIDocUploadState(SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Customer Ledger", EntryNo);
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIEntryCreatesOnPurchPayment()
    var
        VATEntry: Record "VAT Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        EntryNo: Integer;
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 267931] SII Doc. Upload State and SII History entries creates for Detailed Vendor Ledger Entry with Payment and Unrealized VAT

        Initialize();

        MockVATEntry(VATEntry);
        EntryNo := MockInvoiceVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        FindSIIDocUploadState(SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Vendor Ledger", EntryNo);
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNewSalesSIIHistoryWhenThereIsExistingInStatePending()
    var
        VATEntry: Record "VAT Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 267931] No new sales SII History creates when send new request and there is an existing SII History entry

        Initialize();

        MockVATEntry(VATEntry);
        DetailedCustLedgEntry.Get(MockInvoiceCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldCustLedgEntry(DetailedCustLedgEntry."Cust. Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");
        MockInvoiceCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Customer Ledger", DetailedCustLedgEntry."Entry No.");
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNewPurchSIIHistoryWhenThereIsExistingInStatePending()
    var
        VATEntry: Record "VAT Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 267931] No new purchase SII History creates when send new request and there is an existing SII History entry

        Initialize();

        MockVATEntry(VATEntry);
        DetailedVendorLedgEntry.Get(MockInvoiceVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldVendLedgEntry(DetailedVendorLedgEntry."Vendor Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");
        MockInvoiceVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Vendor Ledger", DetailedVendorLedgEntry."Entry No.");
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNewSalesSIIHistoryWhenSeveralBillsWithSevPmt()
    var
        VATEntry: Record "VAT Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales] [UT] [Bill] [Partial Payment]
        // [SCENARIO 274784] No new sales SII History creates on several Bills with several payments
        Initialize();

        // [GIVEN] Invoice
        MockVATEntry(VATEntry);
        MockInvoiceCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        // [GIVEN] Bill 1 with two partial paymets
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldCustLedgEntry(DetailedCustLedgEntry."Cust. Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");

        // [WHEN] Bill 2 with two partial paymets
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldCustLedgEntry(DetailedCustLedgEntry."Cust. Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");

        // [THEN] There is one Doc Upload State and pending History entry for the invocie payment
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(VATEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoNewPurchSIIHistoryWhenSeveralBillsWithSevPmt()
    var
        VATEntry: Record "VAT Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase] [UT] [Bill] [Partial Payment]
        // [SCENARIO 274784] No new purchase SII History creates on several Bills with several payments
        Initialize();

        // [GIVEN] Invoice
        MockVATEntry(VATEntry);
        MockInvoiceVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No.");

        // [GIVEN] Bill 1 with two partial paymets
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldVendLedgEntry(DetailedVendorLedgEntry."Vendor Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");

        // [WHEN] Bill 2 with two partial paymets
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        MockDtldVendLedgEntry(DetailedVendorLedgEntry."Vendor Ledger Entry No.", VATEntry."Document No.", VATEntry."Transaction No.");

        // [THEN] There is one Doc Upload State and pending History entry for the invocie payment
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(VATEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedSalesPaymentWithPmtCode05()
    var
        PaymentMethod: Record "Payment Method";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Medio node has value "05" of SII Payment Method Code of Customer Ledger Entry

        Initialize();

        CreateCustomer(Customer, VATPostingSetup, PaymentMethod."SII Payment Method Code"::"05");

        // [GIVEN] Creation of a Sales Invoice for a local customer, cash based and "SII Payment Method Code" = "05"
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindCustLedgEntry(CustLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, true, false);

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local customer, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry, DocumentNo);

        // [THEN] Medio node has value "01" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesCobroTok, 'sii:Medio', Format(PaymentMethod."SII Payment Method Code"::"05"));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedPurchasePaymentWithPmtCode05()
    var
        PaymentMethod: Record "Payment Method";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExtDocumentNo: Code[20];
    begin
        // [FEATURE] [Payment]
        // [SCENARIO 263060] Medio node has value "05" of SII Payment Method Code of Vendor Ledger Entry

        Initialize();

        CreateVendor(Vendor, VATPostingSetup, PaymentMethod."SII Payment Method Code"::"05");

        // [GIVEN] Creation of an Purchase Invoice for a local vendor, cash based and "SII Payment Method Code" is "05"
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        FindVendLedgEntry(VendorLedgerEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, true, false);
        LibrarySII.AssertLibraryVariableStorage();

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry, DocumentNo);

        // [THEN] Medio node has value "05" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchasePagoTok, 'sii:Medio', Format(PaymentMethod."SII Payment Method Code"::"05"));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPaymentAppliesToBill()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Cartera] [Bill]
        // [SCENARIO 272857] Stan can generate SII xml file for sales payment applied to bill

        Initialize();

        // [GIVEN] Unrealized VAT Setup
        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 1);

        // [GIVEN] Posted invoice with associated Bill of amount 100
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);
        Amount := GetSalesBillAmount(InvoiceNo, '1');

        // [GIVEN] Posted payment applied to Bill
        PaymentNo := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Amount);

        // [WHEN] Generate xml file for detailed customer ledger Entry of payment
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry, PaymentNo);

        // [THEN] Importe node has value 100 in exported XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesCobroTok, 'sii:Importe', SIIXMLCreator.FormatNumber(-Amount));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPaymentAppliesToBill()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ExternalDocumentNo: Code[35];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Cartera] [Bill]
        // [SCENARIO 272857] Stan can generate SII xml file for purchase payment applied to bill

        Initialize();

        // [GIVEN] Unrealized VAT Setup
        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled
        VendorNo := CreateCarteraVendor(VATPostingSetup, 1);

        // [GIVEN] Posted invoice with associated Bill of amount 100
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);
        Amount := GetPurchBillAmount(InvoiceNo, '1');

        // [GIVEN] Posted payment applied to Bill
        PaymentNo := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Amount);

        // [WHEN] Generate xml file for detailed vendor ledger Entry of payment
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry, PaymentNo);

        // [THEN] Importe node has value 100 in exported XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchasePagoTok, 'sii:Importe', SIIXMLCreator.FormatNumber(Amount));

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesOnePositive()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of one sales invoice CASH Flow VAT Entry
        MockVATEntry(VATEntry);
        VerifyLedgerCashFlowBasedSalesInvoiceTrue(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesSevPositive()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of two sales invoice CASH Flow VAT Entries
        MockVATEntry(VATEntry);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", LibraryRandom.RandDec(100, 2));
        VerifyLedgerCashFlowBasedSalesInvoiceTrue(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesOneNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of one sales invoice not CASH Flow VAT Entry
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedSalesInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesSevNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two sales invoice not CASH Flow VAT Entries
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedSalesInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesNoVATNegative()
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of one sales invoice without VAT Entry
        VerifyLedgerCashFlowBasedSalesInvoiceFalse(LibraryUtility.GenerateGUID(), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesMixNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two sales invoice VAT Entries (CASH Flow and not CASH Flow)
        MockVATEntry(VATEntry);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedSalesInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesMixReverseOrderNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two sales invoice VAT Entries (not CASH Flow and CASH Flow)
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", LibraryRandom.RandDec(100, 2));
        VerifyLedgerCashFlowBasedSalesInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesBillPositive()
    var
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [UT] [Sales] [Bill]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of sales Bill CASH Flow VAT
        MockVATEntry(VATEntry);

        // Invoice
        DetailedCustLedgEntry.Get(MockInvoiceCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");

        // Bill
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");

        VerifyLedgerCashFlowBasedSalesTrue(CustLedgerEntry, DetailedCustLedgEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedSalesBillWithoutInvoiceNegative()
    var
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [UT] [Sales] [Bill]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of sales Bill without linked invoice
        MockVATEntry(VATEntry);

        // Bill
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");

        VerifyLedgerCashFlowBasedSalesFalse(CustLedgerEntry, DetailedCustLedgEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseOnePositive()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of one purchase invoice CASH Flow VAT Entry
        MockVATEntry(VATEntry);
        VerifyLedgerCashFlowBasedPurchaseInvoiceTrue(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseSevPositive()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of two purchase invoice CASH Flow VAT Entries
        MockVATEntry(VATEntry);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", LibraryRandom.RandDec(100, 2));
        VerifyLedgerCashFlowBasedPurchaseInvoiceTrue(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseOneNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of one purchase invoice not CASH Flow VAT Entry
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseSevNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two purchase invoice not CASH Flow VAT Entries
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseNoVATNegative()
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of one purchase invoice without VAT Entry
        VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(LibraryUtility.GenerateGUID(), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseMixNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two purchase invoice VAT Entries (CASH Flow and not CASH Flow)
        MockVATEntry(VATEntry);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseMixReverseOrderNegative()
    var
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of two purchase invoice VAT Entries (not CASH Flow and CASH Flow)
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", 0);
        MockCustomVATEntry(VATEntry, VATEntry."Document No.", VATEntry."Transaction No.", LibraryRandom.RandDec(100, 2));
        VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(VATEntry."Document No.", VATEntry."Transaction No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseBillPositive()
    var
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [UT] [Purchase] [Bill]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns TRUE in case of purchase Bill CASH Flow VAT
        MockVATEntry(VATEntry);

        // Invoice
        DetailedVendorLedgEntry.Get(MockInvoiceVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");

        // Bill
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");

        VerifyLedgerCashFlowBasedPurchaseTrue(VendorLedgerEntry, DetailedVendorLedgEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtIsLedgerCashFlowBasedPurchaseBillWithoutInvoiceNegative()
    var
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [UT] [Purchase] [Bill]
        // [SCENARIO 274784] SIIManagement.IsLedgerCashFlowBased() and SIIManagement.IsDetailedLedgerCashFlowBased() returns FALSE in case of purchase Bill without linked invoice
        MockVATEntry(VATEntry);

        // Bill
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");

        VerifyLedgerCashFlowBasedPurchaseFalse(VendorLedgerEntry, DetailedVendorLedgEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtFindPaymentDetailedCustomerLedgerEntries()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FoundDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIManagement.FindPaymentDetailedCustomerLedgerEntries() returns TRUE in case of Payment detailed entries related to the parent ledger entry
        MockVATEntry(VATEntry);
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");

        Assert.IsTrue(SIIManagement.FindPaymentDetailedCustomerLedgerEntries(FoundDetailedCustLedgEntry, CustLedgerEntry), '');
        Assert.AreEqual(Format(CustLedgerEntry."Entry No."), FoundDetailedCustLedgEntry.GetFilter("Cust. Ledger Entry No."), '');
        // TFS ID 398897: VAT Cash refunds
        Assert.AreEqual(
          StrSubstNo('%1|%2', Format(FoundDetailedCustLedgEntry."Document Type"::Payment), Format(FoundDetailedCustLedgEntry."Document Type"::Refund)), FoundDetailedCustLedgEntry.GetFilter("Document Type"), '');
        Assert.AreEqual(Format(false), FoundDetailedCustLedgEntry.GetFilter(Unapplied), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgtFindPaymentDetailedVendorLedgerEntries()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        FoundDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIManagement: Codeunit "SII Management";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIManagement.FindPaymentDetailedVendorLedgerEntries() returns TRUE in case of Payment detailed entries related to the parent ledger entry
        MockVATEntry(VATEntry);
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");

        Assert.IsTrue(SIIManagement.FindPaymentDetailedVendorLedgerEntries(FoundDetailedVendorLedgEntry, VendorLedgerEntry), '');
        Assert.AreEqual(Format(VendorLedgerEntry."Entry No."), FoundDetailedVendorLedgEntry.GetFilter("Vendor Ledger Entry No."), '');
        // TFS ID 398897: VAT Cash refunds
        Assert.AreEqual(
          StrSubstNo('%1|%2', Format(FoundDetailedVendorLedgEntry."Document Type"::Payment), Format(FoundDetailedVendorLedgEntry."Document Type"::Refund)), FoundDetailedVendorLedgEntry.GetFilter("Document Type"), '');
        Assert.AreEqual(Format(false), FoundDetailedVendorLedgEntry.GetFilter(Unapplied), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSIIRequestForDtldCustLedgEntryBillWithoutInvoice()
    var
        VATEntry: Record "VAT Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 274784] SIIJobUploadPendingDocs.CreateSIIRequestForDtldCustLedgEntry() doesn't create a new request in case of Bill without Invoice
        Initialize();

        MockVATEntry(VATEntry);
        DetailedCustLedgEntry.Get(MockBillCustLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));

        SIIJobUploadPendingDocs.CreateSIIRequestForDtldCustLedgEntry(DetailedCustLedgEntry);

        SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Detailed Customer Ledger");
        SIIDocUploadState.SetRange("Document No.", VATEntry."Document No.");
        Assert.RecordIsEmpty(SIIDocUploadState);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSIIRequestForDtldVendLedgEntryBillWithoutInvoice()
    var
        VATEntry: Record "VAT Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIJobUploadPendingDocs: Codeunit "SII Job Upload Pending Docs.";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 274784] SIIJobUploadPendingDocs.CreateSIIRequestForDtldVendLedgEntry() doesn't create a new request in case of Bill without Invoice
        Initialize();

        MockVATEntry(VATEntry);
        DetailedVendorLedgEntry.Get(MockBillVendLedgEntry(VATEntry."Document No.", VATEntry."Transaction No."));

        SIIJobUploadPendingDocs.CreateSIIRequestForDtldVendLedgEntry(DetailedVendorLedgEntry);

        SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Detailed Vendor Ledger");
        SIIDocUploadState.SetRange("Document No.", VATEntry."Document No.");
        Assert.RecordIsEmpty(SIIDocUploadState);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastSalesOneFullPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Last]
        // [SCENARIO 274784] Full payment to sales invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Sales Invoice for a local customer (Unreazlied Type = Last)
        CreateAndPostSalesInvoiceUnrealizedLast(VATPostingSetup, CustomerNo, DocumentNo, Amount);
        // [GIVEN] Post payment applied to the invoice (full amount)
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            CustomerNo, GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry[1], DocumentNo);

        // [THEN] The xml has been created with one "Cobro" (received payment) node
        VerifyXMLSeveralSalesPayments(XMLDoc, DetailedCustLedgEntry, 1);
        VerifyDocUploadStateCustomerPmt(DetailedCustLedgEntry[1]."Entry No.", SIIDocUploadState."Document Type"::Payment);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastPurchOneFullPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        DocumentNo: Code[20];
        ExtDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Last]
        // [SCENARIO 274784] Full payment to purchase invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Purchase Invoice for a local vendor (Unreazlied Type = Last)
        CreateAndPostPurchaseInvoiceUnrealizedLast(VATPostingSetup, VendorNo, DocumentNo, Amount, ExtDocumentNo);
        // [GIVEN] Post payment applied to the invoice (full amount)
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForPI(
            VendorNo, GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry[1], DocumentNo);

        // [THEN] The xml has been created with one "Pago" (emitted payment) node
        VerifyXMLSeveralPurchPayments(XMLDoc, DetailedVendorLedgEntry, 1);
        VerifyDocUploadStateVendorPmt(DetailedVendorLedgEntry[1]."Entry No.", SIIDocUploadState."Document Type"::Payment);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastSalesOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Last] [Partial Payment]
        // [SCENARIO 274784] Partial payment to sales invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Sales Invoice for a local customer (Unreazlied Type = Last)
        CreateAndPostSalesInvoiceUnrealizedLast(VATPostingSetup, CustomerNo, DocumentNo, Amount);
        // [GIVEN] Post partial payment applied to the invoice
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            CustomerNo, GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Round(Amount / 3));

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry[1], DocumentNo);

        // [THEN] The xml has been created with one "Cobro" (received payment) node
        VerifyXMLSeveralSalesPayments(XMLDoc, DetailedCustLedgEntry, 1);
        VerifyDocUploadStateCustomerPmt(DetailedCustLedgEntry[1]."Entry No.", SIIDocUploadState."Document Type"::Payment);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastPurchOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        DocumentNo: Code[20];
        ExtDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Last] [Partial Payment]
        // [SCENARIO 274784] Full payment to purchase invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Purchase Invoice for a local vendor (Unreazlied Type = Last)
        CreateAndPostPurchaseInvoiceUnrealizedLast(VATPostingSetup, VendorNo, DocumentNo, Amount, ExtDocumentNo);
        // [GIVEN] Post partial payment applied to the invoice
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForPI(
            VendorNo, GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Round(Amount / 3));

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry[1], DocumentNo);

        // [THEN] The xml has been created with one "Pago" (emitted payment) node
        VerifyXMLSeveralPurchPayments(XMLDoc, DetailedVendorLedgEntry, 1);
        VerifyDocUploadStateVendorPmt(DetailedVendorLedgEntry[1]."Entry No.", SIIDocUploadState."Document Type"::Payment);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastSalesTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        XMLDoc: array[2] of DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[2] of Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Last] [Partial Payment]
        // [SCENARIO 274784] Two partial payments to sales invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Sales Invoice for a local customer (Unreazlied Type = Last)
        CreateAndPostSalesInvoiceUnrealizedLast(VATPostingSetup, CustomerNo, InvoiceNo, Amount);
        // [GIVEN] Post two partial payments applied to the invoice
        for i := 1 to ArrayLen(PaymentNo) do
            PaymentNo[i] :=
              Library340347Declaration.CreateAndPostPaymentForSI(
                CustomerNo, GenJournalLine."Document Type"::Invoice, InvoiceNo, WorkDate(), Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc[i], DetailedCustLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Cobro" (received payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralSalesPayments(XMLDoc[i], DetailedCustLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedLastPurchTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        XMLDoc: array[2] of DotNet XmlDocument;
        VendorNo: Code[20];
        InvDocumentNo: Code[20];
        PmtDocumentNo: array[2] of Code[20];
        ExtDocumentNo: Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Last] [Partial Payment]
        // [SCENARIO 274784] Two partial payments to purchase invoice in case of Unrealized Type = Last
        Initialize();

        // [GIVEN] Purchase Invoice for a local vendor (Unreazlied Type = Last)
        CreateAndPostPurchaseInvoiceUnrealizedLast(VATPostingSetup, VendorNo, InvDocumentNo, Amount, ExtDocumentNo);
        // [GIVEN] Post two partial payment applied to the invoice
        for i := 1 to ArrayLen(PmtDocumentNo) do
            PmtDocumentNo[i] :=
              Library340347Declaration.CreateAndPostPaymentForPI(
                VendorNo, GenJournalLine."Document Type"::Invoice, InvDocumentNo, WorkDate(), Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PmtDocumentNo) do
            GenerateXmlForDetailedVendorLedgerEntry(XMLDoc[i], DetailedVendorLedgEntry[i], PmtDocumentNo[i]);

        // [THEN] The xml has been created with one "Pago" (emitted payment) node
        for i := 1 to ArrayLen(PmtDocumentNo) do
            VerifyXMLSeveralPurchPayments(XMLDoc[i], DetailedVendorLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExtDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOneBillOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Bill] [Partial Payment]
        // [SCENARIO 274784] Partial payment to sales Bill
        Initialize();

        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled
        // [GIVEN] Posted invoice with associated Bill
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 1);
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);

        // [GIVEN] Posted partial payment applied to Bill
        Amount := GetSalesBillAmount(InvoiceNo, '1');
        PaymentNo := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Round(Amount / 3));

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry[1], PaymentNo);

        // [THEN] The xml has been created with one "Cobro" (received payment) node
        VerifyXMLSeveralSalesPayments(XMLDoc, DetailedCustLedgEntry, 1);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOneBillOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        ExternalDocumentNo: Code[35];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Bill] [Partial Payment]
        // [SCENARIO 274784] Partial payment to purchase Bill
        Initialize();

        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled
        // [GIVEN] Posted invoice with associated Bill
        VendorNo := CreateCarteraVendor(VATPostingSetup, 1);
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);

        // [GIVEN] Posted partial payment applied to Bill
        Amount := GetPurchBillAmount(InvoiceNo, '1');
        PaymentNo := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Round(Amount / 3));

        // [WHEN] Generate XML for the posted payment
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry[1], PaymentNo);

        // [THEN] The xml has been created with one "Pago" (emitted payment) node
        VerifyXMLSeveralPurchPayments(XMLDoc, DetailedVendorLedgEntry, 1);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOneBillTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        XMLDoc: array[2] of DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[2] of Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two partial payments to sales Bill
        Initialize();

        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled
        // [GIVEN] Posted invoice with associated Bill
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 1);
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);

        // [GIVEN] Two posted partial payments applied to Bill
        Amount := GetSalesBillAmount(InvoiceNo, '1');
        for i := 1 to ArrayLen(PaymentNo) do
            PaymentNo[i] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc[i], DetailedCustLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Cobro" (received payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralSalesPayments(XMLDoc[i], DetailedCustLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOneBillTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        XMLDoc: array[2] of DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[2] of Code[20];
        ExternalDocumentNo: Code[35];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Bill] [Partial Payment]
        // [SCENARIO 274784] Partial payment to purchase Bill
        Initialize();

        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled
        // [GIVEN] Posted invoice with associated Bill
        VendorNo := CreateCarteraVendor(VATPostingSetup, 1);
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);

        // [GIVEN] Two posted partial payments applied to Bill
        Amount := GetPurchBillAmount(InvoiceNo, '1');
        for i := 1 to ArrayLen(PaymentNo) do
            PaymentNo[i] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedVendorLedgerEntry(XMLDoc[i], DetailedVendorLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Pago" (emitted payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralPurchPayments(XMLDoc[i], DetailedVendorLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTwoBillsEachWithOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        XMLDoc: array[2] of DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[2] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two sales Bills each with one partial payment
        Initialize();

        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 2);
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);

        // [GIVEN] Posted partial payment applied to Bill 1
        // [GIVEN] Posted partial payment applied to Bill 2
        PaymentNo[1] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Round(GetSalesBillAmount(InvoiceNo, '1') / 3));
        PaymentNo[2] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '2', Round(GetSalesBillAmount(InvoiceNo, '2') / 3));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc[i], DetailedCustLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Cobro" (received payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralSalesPayments(XMLDoc[i], DetailedCustLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTwoBillsEachWithOnePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        XMLDoc: array[2] of DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[2] of Code[20];
        ExternalDocumentNo: Code[35];
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two purchase Bills each with one partial payment
        Initialize();

        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        VendorNo := CreateCarteraVendor(VATPostingSetup, 2);
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);

        // [GIVEN] Posted partial payment applied to Bill 1
        // [GIVEN] Posted partial payment applied to Bill 2
        PaymentNo[1] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Round(GetPurchBillAmount(InvoiceNo, '1') / 3));
        PaymentNo[2] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '2', Round(GetPurchBillAmount(InvoiceNo, '2') / 3));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedVendorLedgerEntry(XMLDoc[i], DetailedVendorLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Pago" (emitted payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralPurchPayments(XMLDoc[i], DetailedVendorLedgEntry, 2);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTwoBillsThreePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        XMLDoc: array[3] of DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two sales Bills with three partial payments (two to Bill 1, one to Bill 2)
        Initialize();

        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 2);
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);

        // [GIVEN] Two posted partial payments applied to Bill 1
        Amount := GetSalesBillAmount(InvoiceNo, '1');
        for i := 1 to 2 do
            PaymentNo[i] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [GIVEN] One posted partial payment applied to Bill 2
        PaymentNo[3] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '2', Round(GetSalesBillAmount(InvoiceNo, '2') / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(XMLDoc) do
            GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc[i], DetailedCustLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with three "Cobro" (received payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralSalesPayments(XMLDoc[i], DetailedCustLedgEntry, 3);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTwoBillsThreePartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        XMLDoc: array[3] of DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[3] of Code[20];
        ExternalDocumentNo: Code[35];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two purchase Bills with three partial payments (two to Bill 1, one to Bill 2)
        Initialize();

        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        VendorNo := CreateCarteraVendor(VATPostingSetup, 2);
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);

        // [GIVEN] Two posted partial payments applied to Bill 1
        Amount := GetPurchBillAmount(InvoiceNo, '1');
        for i := 1 to 2 do
            PaymentNo[i] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [GIVEN] One posted partial payments applied to Bill 2
        PaymentNo[3] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '2', Round(GetPurchBillAmount(InvoiceNo, '2') / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedVendorLedgerEntry(XMLDoc[i], DetailedVendorLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with three "Pago" (emitted payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralPurchPayments(XMLDoc[i], DetailedVendorLedgEntry, 3);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesTwoBillsEachWithTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry";
        XMLDoc: array[4] of DotNet XmlDocument;
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[4] of Code[20];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two sales Bills each with two partial payments
        Initialize();

        // [GIVEN] Cartera Customer with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        CustomerNo := CreateCarteraCustomer(VATPostingSetup, 2);
        InvoiceNo := PostSalesInvoice(CustomerNo, VATPostingSetup);

        // [GIVEN] Two posted partial payments applied to Bill 1
        Amount := GetSalesBillAmount(InvoiceNo, '1');
        for i := 1 to 2 do
            PaymentNo[i] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [GIVEN] Two posted partial payments applied to Bill 2
        Amount := GetSalesBillAmount(InvoiceNo, '2');
        for i := 1 to 2 do
            PaymentNo[2 + i] := CreateApplyPostSalesBillPayment(CustomerNo, InvoiceNo, '2', Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(XMLDoc) do
            GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc[i], DetailedCustLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with four "Cobro" (received payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralSalesPayments(XMLDoc[i], DetailedCustLedgEntry, 4);
        VerifyOnePmtDocUploadStateAndHistoryEntrySales(InvoiceNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTwoBillsEachWithTwoPartialPmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry";
        XMLDoc: array[4] of DotNet XmlDocument;
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: array[4] of Code[20];
        ExternalDocumentNo: Code[35];
        Amount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Bill] [Partial Payment]
        // [SCENARIO 274784] Two purchase Bills each with two partial payments
        Initialize();

        // [GIVEN] Cartera Vendor with Payment Method with option "Create Bills" enabled, 2 payment terms installments
        // [GIVEN] Posted invoice with two associated Bills
        VendorNo := CreateCarteraVendor(VATPostingSetup, 2);
        InvoiceNo := PostPurchInvoice(VendorNo, VATPostingSetup, ExternalDocumentNo);

        // [GIVEN] Two posted partial payments applied to Bill 1
        Amount := GetPurchBillAmount(InvoiceNo, '1');
        for i := 1 to 2 do
            PaymentNo[i] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '1', Round(Amount / (i + 2)));

        // [GIVEN] Two posted partial payments applied to Bill 2
        Amount := GetPurchBillAmount(InvoiceNo, '2');
        for i := 1 to 2 do
            PaymentNo[2 + i] := CreateApplyPostPurchBillPayment(VendorNo, InvoiceNo, '2', Round(Amount / (i + 2)));

        // [WHEN] Generate XML for the posted partial payment
        for i := 1 to ArrayLen(PaymentNo) do
            GenerateXmlForDetailedVendorLedgerEntry(XMLDoc[i], DetailedVendorLedgEntry[i], PaymentNo[i]);

        // [THEN] The xml has been created with two "Pago" (emitted payment) nodes
        for i := 1 to ArrayLen(PaymentNo) do
            VerifyXMLSeveralPurchPayments(XMLDoc[i], DetailedVendorLedgEntry, 4);
        VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTemporaryDetailedVendorLedgerEntry()
    var
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 297338] It is possible to insert temporary Detailed Vendor Ledger Entry when SII is enabled

        Initialize();
        TempDetailedVendorLedgEntry.Init();
        TempDetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(TempDetailedVendorLedgEntry, TempDetailedVendorLedgEntry.FieldNo("Entry No."));
        TempDetailedVendorLedgEntry.Insert();
        TempDetailedVendorLedgEntry.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTemporaryDetailedCustomerLedgerEntry()
    var
        TempDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 297338] It is possible to insert temporary Detailed Customer Ledger Entry when SII is enabled

        Initialize();
        TempDetailedCustLedgEntry.Init();
        TempDetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(TempDetailedCustLedgEntry, TempDetailedCustLedgEntry.FieldNo("Entry No."));
        TempDetailedCustLedgEntry.Insert();
        TempDetailedCustLedgEntry.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedSalesRefund()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 398897] Stan can send the sales VAT cash refund to the SII

        Initialize();

        CreateCustomer(Customer, VATPostingSetup, 0);

        // [GIVEN] Cash based sales credit memo
        DocumentNo :=
          Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, Customer."No.", WorkDate(), Amount, '');

        // [GIVEN] Refund applied to credit memo
        DocumentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::"Credit Memo", DocumentNo, WorkDate(), -Amount);

        // [WHEN] We create the xml to be transmitted for that refund
        GenerateXmlForDetailedCustomerLedgerEntry(XMLDoc, DetailedCustLedgEntry, DocumentNo);

        // [THEN] The structure of the XML file for the refund is correct
        LibrarySII.VerifyXml(XMLDoc, DetailedCustLedgEntry, XmlType::Payment, true, false);

        // [THEN] SII Doc. Upload State of Cash Based refund has been created
        VerifyDocUploadStateCustomerPmt(DetailedCustLedgEntry."Entry No.", SIIDocUploadState."Document Type"::Refund);

        // [THEN] Two job queue entries have been initiated, one for credit memo and one for refund
        VerifyUploadPendingDocsJobQueueEntryCount(2);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashBasedPurchaseRefund()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExtDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 398897] Stan can send the purchase VAT cash refund to the SII

        Initialize();

        CreateVendor(Vendor, VATPostingSetup, 0);

        // [GIVEN] Cash based purchase credit memo
        DocumentNo :=
          Library340347Declaration.CreateAndPostPurchaseCrMemo(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo, '');

        // [GIVEN] Refund applied to credit memo
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::"Credit Memo", DocumentNo, WorkDate(), -Amount);

        // [WHEN] We create the xml to be transmitted for that refund
        GenerateXmlForDetailedVendorLedgerEntry(XMLDoc, DetailedVendorLedgEntry, DocumentNo);

        // [THEN] The structure of the XML file for the refund is correct
        LibrarySII.VerifyXml(XMLDoc, DetailedVendorLedgEntry, XmlType::Payment, true, false);

        // [THEN] SII Doc. Upload State of Cash Based refund has been created
        VerifyDocUploadStateVendorPmt(DetailedVendorLedgEntry."Entry No.", SIIDocUploadState."Document Type"::Refund);

        // [THEN] Two job queue entries have been initiated, one for credit memo and one for refund
        VerifyUploadPendingDocsJobQueueEntryCount(2);

        LibrarySII.DisableCashBased(VATPostingSetup);
    end;

    local procedure Initialize()
    begin
        Clear(SIIXMLCreator);
        Clear(LibraryJobQueue);
        BindSubscription(LibraryJobQueue);
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        UpdatePmtBatchNoSeries();

        IsInitialized := true;
    end;

    local procedure CreateCustomer(var Customer: Record Customer; var VATPostingSetup: Record "VAT Posting Setup"; SIIPmtMethodCode: Option)
    var
        PaymentMethod: Record "Payment Method";
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        Customer."VAT Registration No." := 'B80833593';
        Customer."Country/Region Code" := 'ES';
        CreatePmtMethodWithSIIPmtCode(PaymentMethod, SIIPmtMethodCode);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithUnrealizedTypeLast(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer, VATPostingSetup, 0);
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Last;
        VATPostingSetup.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateCarteraCustomer(var VATPostingSetup: Record "VAT Posting Setup"; NoOfInstallments: Integer): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Payment Terms Code", CreatePaymentTerms(NoOfInstallments));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; var VATPostingSetup: Record "VAT Posting Setup"; SIIPmtMethodCode: Option)
    var
        PaymentMethod: Record "Payment Method";
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        Vendor."VAT Registration No." := 'B80833593';
        Vendor."Country/Region Code" := 'ES';
        CreatePmtMethodWithSIIPmtCode(PaymentMethod, SIIPmtMethodCode);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithUnrealizedTypeLast(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, VATPostingSetup, 0);
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Last;
        VATPostingSetup.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateCarteraVendor(var VATPostingSetup: Record "VAT Posting Setup"; NoOfInstallments: Integer): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms(NoOfInstallments));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePmtMethodWithSIIPmtCode(var PaymentMethod: Record "Payment Method"; SIIPmtMethodCode: Option)
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("SII Payment Method Code", SIIPmtMethodCode);
        PaymentMethod.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoiceUnrealizedLast(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var DocumentNo: Code[20]; var Amount: Decimal; var ExtDocumentNo: Code[20])
    begin
        VendorNo := CreateVendorWithUnrealizedTypeLast(VATPostingSetup);
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtDocumentNo);
    end;

    local procedure CreateAndPostSalesInvoiceUnrealizedLast(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var DocumentNo: Code[20]; var Amount: Decimal)
    begin
        CustomerNo := CreateCustomerWithUnrealizedTypeLast(VATPostingSetup);
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
    end;

    local procedure CreateApplyPostPurchBillPayment(VendorNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyPurchPaymentToBill(GenJournalLine."Document No.", InvoiceNo, BillNo);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateApplyPostSalesBillPayment(CustomerNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplySalesPaymentToBill(GenJournalLine."Document No.", InvoiceNo, BillNo);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreatePaymentTerms(NoOfInstallments: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryCarteraPayables.CreateMultipleInstallments(PaymentTerms.Code, NoOfInstallments);
        exit(PaymentTerms.Code);
    end;

    local procedure FindCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocNo: Code[20])
    begin
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindDtldCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocNo: Code[20])
    begin
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocNo);
        DetailedCustLedgEntry.FindFirst();
    end;

    local procedure FindVendLedgEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindDtldVendLedgEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocNo: Code[20])
    begin
        DetailedVendorLedgEntry.Reset();
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocNo);
        DetailedVendorLedgEntry.FindFirst();
    end;

    local procedure FindSIIDocUploadState(var SIIDocUploadState: Record "SII Doc. Upload State"; DocSource: Enum "SII Doc. Upload State Document Source"; EntryNo: Integer)
    begin
        SIIDocUploadState.SetRange("Document Source", DocSource);
        SIIDocUploadState.SetRange("Entry No", EntryNo);
        SIIDocUploadState.FindFirst();
    end;

    local procedure GetPurchBillAmount(InvoiceNo: Code[20]; BillNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Bill, InvoiceNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        exit(-VendorLedgerEntry."Remaining Amount");
    end;

    local procedure GetSalesBillAmount(InvoiceNo: Code[20]; BillNo: Code[20]): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Bill, InvoiceNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        exit(-CustLedgerEntry."Remaining Amount");
    end;

    local procedure ApplySalesPaymentToBill(PayNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20])
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AmountToApply: Decimal;
    begin
        LibraryERM.FindCustomerLedgerEntry(
          ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Document Type"::Payment, PayNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        AmountToApply := ApplyingCustLedgerEntry."Remaining Amount";
        LibraryERM.SetApplyCustomerEntry(
          ApplyingCustLedgerEntry, AmountToApply);

        CustLedgerEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Bill, InvoiceNo);

        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure ApplyPurchPaymentToBill(PayNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20])
    var
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AmountToApply: Decimal;
    begin
        LibraryERM.FindVendorLedgerEntry(
          ApplyingVendLedgerEntry, ApplyingVendLedgerEntry."Document Type"::Payment, PayNo);
        ApplyingVendLedgerEntry.CalcFields("Remaining Amount");
        AmountToApply := ApplyingVendLedgerEntry."Remaining Amount";
        LibraryERM.SetApplyVendorEntry(
          ApplyingVendLedgerEntry, AmountToApply);

        VendorLedgerEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Bill, InvoiceNo);

        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.Validate("Amount to Apply", VendorLedgerEntry."Remaining Amount");
        VendorLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendLedgerEntry);
    end;

    local procedure MockInvoiceCustLedgEntry(DocNo: Code[20]; TransNo: Integer): Integer
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(MockCustLedgEntry(DocNo, TransNo, DummyCustLedgerEntry."Document Type"::Invoice));
    end;

    local procedure MockBillCustLedgEntry(DocNo: Code[20]; TransNo: Integer): Integer
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(MockCustLedgEntry(DocNo, TransNo, DummyCustLedgerEntry."Document Type"::Bill));
    end;

    local procedure MockCustLedgEntry(DocNo: Code[20]; TransNo: Integer; DocumentType: Enum "Gen. Journal Document Type"): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := DocNo;
        CustLedgerEntry."Transaction No." := TransNo;
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry.Insert();
        exit(MockDtldCustLedgEntry(CustLedgerEntry."Entry No.", DocNo, TransNo));
    end;

    local procedure MockDtldCustLedgEntry(CustLedgEntryNo: Integer; DocNo: Code[20]; TransNo: Integer): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry."Document Type" := DetailedCustLedgEntry."Document Type"::Payment;
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry."Document No." := DocNo;
        DetailedCustLedgEntry."Transaction No." := TransNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure MockInvoiceVendLedgEntry(DocNo: Code[20]; TransNo: Integer): Integer
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(MockVendLedgEntry(DocNo, TransNo, DummyCustLedgerEntry."Document Type"::Invoice));
    end;

    local procedure MockBillVendLedgEntry(DocNo: Code[20]; TransNo: Integer): Integer
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        exit(MockVendLedgEntry(DocNo, TransNo, DummyCustLedgerEntry."Document Type"::Bill));
    end;

    local procedure MockVendLedgEntry(DocNo: Code[20]; TransNo: Integer; DocumentType: Enum "Gen. Journal Document Type"): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := DocNo;
        VendorLedgerEntry."External Document No." := DocNo;
        VendorLedgerEntry."Transaction No." := TransNo;
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry.Insert();
        exit(MockDtldVendLedgEntry(VendorLedgerEntry."Entry No.", DocNo, TransNo));
    end;

    local procedure MockDtldVendLedgEntry(VendLedgEntryNo: Integer; DocNo: Code[20]; TransNo: Integer): Integer
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DetailedVendorLedgEntry."Document Type" := DetailedVendorLedgEntry."Document Type"::Payment;
        DetailedVendorLedgEntry."Posting Date" := WorkDate();
        DetailedVendorLedgEntry."Document No." := DocNo;
        DetailedVendorLedgEntry."Transaction No." := TransNo;
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::Application;
        DetailedVendorLedgEntry."Initial Document Type" := DetailedVendorLedgEntry."Initial Document Type"::Invoice;
        DetailedVendorLedgEntry.Insert();
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry")
    begin
        MockCustomVATEntry(VATEntry, LibraryUtility.GenerateGUID(), LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));
    end;

    local procedure MockCustomVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; TransactionNo: Integer; UnrealizedBase: Decimal)
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."Document No." := DocumentNo;
        VATEntry."Transaction No." := TransactionNo;
        VATEntry."Unrealized Base" := UnrealizedBase;
        VATEntry.Insert();
    end;

    local procedure PostSalesInvoice(CustNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchInvoice(VendNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; var ExternalDocumentNo: Code[35]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        ExternalDocumentNo := PurchaseHeader."Vendor Invoice No.";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure GenerateXmlForDetailedVendorLedgerEntry(var XMLDoc: DotNet XmlDocument; var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DocumentNo: Code[20])
    var
        SIIXMLCreator: Codeunit "SII XML Creator";
    begin
        FindDtldVendLedgEntry(DetailedVendorLedgEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(DetailedVendorLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);
    end;

    local procedure GenerateXmlForDetailedCustomerLedgerEntry(var XMLDoc: DotNet XmlDocument; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20])
    var
        SIIXMLCreator: Codeunit "SII XML Creator";
    begin
        FindDtldCustLedgEntry(DetailedCustLedgEntry, DocumentNo);
        Assert.IsTrue(SIIXMLCreator.GenerateXml(DetailedCustLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);
    end;

    local procedure UpdatePmtBatchNoSeries()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();

        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();
    end;

    local procedure VerifySIIHistoryCount(DocStateID: Integer; ExpectedCount: Integer)
    var
        SIIHistory: Record "SII History";
    begin
        SIIHistory.SetRange("Document State Id", DocStateID);
        Assert.RecordCount(SIIHistory, ExpectedCount);
    end;

    local procedure VerifyOneDocUploadStateAndHistoryEntry(DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentNo: Code[35])
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
    begin
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        SIIDocUploadState.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(SIIDocUploadState, 1);
        SIIDocUploadState.FindFirst();
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    local procedure VerifyOnePmtDocUploadStateAndHistoryEntrySales(DocumentNo: Code[20])
    var
        DummySIIDocUploadState: Record "SII Doc. Upload State";
    begin
        VerifyOneDocUploadStateAndHistoryEntry(DummySIIDocUploadState."Document Source"::"Detailed Customer Ledger", DocumentNo);
    end;

    local procedure VerifyOnePmtDocUploadStateAndHistoryEntryPurchase(ExternalDocumentNo: Code[35])
    var
        DummySIIDocUploadState: Record "SII Doc. Upload State";
    begin
        VerifyOneDocUploadStateAndHistoryEntry(DummySIIDocUploadState."Document Source"::"Detailed Vendor Ledger", ExternalDocumentNo);
    end;

    local procedure VerifyLedgerCashFlowBasedSalesInvoiceTrue(DocumentNo: Code[20]; TransactionNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Get(MockInvoiceCustLedgEntry(DocumentNo, TransactionNo));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        VerifyLedgerCashFlowBasedSalesTrue(CustLedgerEntry, DetailedCustLedgEntry);
    end;

    local procedure VerifyLedgerCashFlowBasedSalesInvoiceFalse(DocumentNo: Code[20]; TransactionNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Get(MockInvoiceCustLedgEntry(DocumentNo, TransactionNo));
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        VerifyLedgerCashFlowBasedSalesFalse(CustLedgerEntry, DetailedCustLedgEntry);
    end;

    local procedure VerifyLedgerCashFlowBasedSalesTrue(CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        SIIManagement: Codeunit "SII Management";
        LedgerEntryRecRef: RecordRef;
    begin
        // "Cust. Ledger Entry"
        LedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry");
        LedgerEntryRecRef.GetTable(CustLedgerEntry);
        Assert.IsTrue(SIIManagement.IsLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();

        // "Detailed Cust. Ledg. Entry"
        LedgerEntryRecRef.Open(DATABASE::"Detailed Cust. Ledg. Entry");
        LedgerEntryRecRef.GetTable(DetailedCustLedgEntry);
        Assert.IsTrue(SIIManagement.IsDetailedLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();
    end;

    local procedure VerifyLedgerCashFlowBasedSalesFalse(CustLedgerEntry: Record "Cust. Ledger Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        SIIManagement: Codeunit "SII Management";
        LedgerEntryRecRef: RecordRef;
    begin
        // "Cust. Ledger Entry"
        LedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry");
        LedgerEntryRecRef.GetTable(CustLedgerEntry);
        Assert.IsFalse(SIIManagement.IsLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();

        // "Detailed Cust. Ledg. Entry"
        LedgerEntryRecRef.Open(DATABASE::"Detailed Cust. Ledg. Entry");
        LedgerEntryRecRef.GetTable(DetailedCustLedgEntry);
        Assert.IsFalse(SIIManagement.IsDetailedLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();
    end;

    local procedure VerifyLedgerCashFlowBasedPurchaseInvoiceTrue(DocumentNo: Code[20]; TransactionNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Get(MockInvoiceVendLedgEntry(DocumentNo, TransactionNo));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
        VerifyLedgerCashFlowBasedPurchaseTrue(VendorLedgerEntry, DetailedVendorLedgEntry);
    end;

    local procedure VerifyLedgerCashFlowBasedPurchaseInvoiceFalse(DocumentNo: Code[20]; TransactionNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Get(MockInvoiceVendLedgEntry(DocumentNo, TransactionNo));
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
        VerifyLedgerCashFlowBasedPurchaseFalse(VendorLedgerEntry, DetailedVendorLedgEntry);
    end;

    local procedure VerifyLedgerCashFlowBasedPurchaseTrue(VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        SIIManagement: Codeunit "SII Management";
        LedgerEntryRecRef: RecordRef;
    begin
        // "Cust. Ledger Entry"
        LedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry");
        LedgerEntryRecRef.GetTable(VendorLedgerEntry);
        Assert.IsTrue(SIIManagement.IsLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();

        // "Detailed Cust. Ledg. Entry"
        LedgerEntryRecRef.Open(DATABASE::"Detailed Cust. Ledg. Entry");
        LedgerEntryRecRef.GetTable(DetailedVendorLedgEntry);
        Assert.IsTrue(SIIManagement.IsDetailedLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();
    end;

    local procedure VerifyLedgerCashFlowBasedPurchaseFalse(VendorLedgerEntry: Record "Vendor Ledger Entry"; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    var
        SIIManagement: Codeunit "SII Management";
        LedgerEntryRecRef: RecordRef;
    begin
        // "Cust. Ledger Entry"
        LedgerEntryRecRef.Open(DATABASE::"Cust. Ledger Entry");
        LedgerEntryRecRef.GetTable(VendorLedgerEntry);
        Assert.IsFalse(SIIManagement.IsLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();

        // "Detailed Cust. Ledg. Entry"
        LedgerEntryRecRef.Open(DATABASE::"Detailed Cust. Ledg. Entry");
        LedgerEntryRecRef.GetTable(DetailedVendorLedgEntry);
        Assert.IsFalse(SIIManagement.IsDetailedLedgerCashFlowBased(LedgerEntryRecRef), '');
        LedgerEntryRecRef.Close();
    end;

    local procedure VerifyDocUploadStateCustomerPmt(PmtDtldEntryNo: Integer; DocumentType: Enum "SII Doc. Upload State Document Type")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Get(PmtDtldEntryNo);
        CustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.");
        FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Customer Ledger", PmtDtldEntryNo);

        SIIDocUploadState.TestField("Inv. Entry No", DetailedCustLedgEntry."Cust. Ledger Entry No.");
        SIIDocUploadState.TestField("Document Type", DocumentType);
        SIIDocUploadState.TestField("Document No.", CustLedgerEntry."Document No.");
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    local procedure VerifyDocUploadStateVendorPmt(PmtDtldEntryNo: Integer; DocumentType: Enum "SII Doc. Upload State Document Type")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Get(PmtDtldEntryNo);
        VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
        FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Detailed Vendor Ledger", PmtDtldEntryNo);

        SIIDocUploadState.TestField("Inv. Entry No", DetailedVendorLedgEntry."Vendor Ledger Entry No.");
        SIIDocUploadState.TestField("Document Type", DocumentType);
        SIIDocUploadState.TestField("Document No.", VendorLedgerEntry."External Document No.");
        VerifySIIHistoryCount(SIIDocUploadState.Id, 1);
    end;

    local procedure VerifyXMLSeveralSalesPayments(XMLDoc: DotNet XmlDocument; DetailedCustLedgEntry: array[4] of Record "Detailed Cust. Ledg. Entry"; ExpectedNodeCount: Integer)
    var
        i: Integer;
    begin
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Cobro', ExpectedNodeCount);
        for i := 1 to ExpectedNodeCount do
            LibrarySII.ValidateElementByNameAt(
              XMLDoc, 'sii:Importe', SIIXMLCreator.FormatNumber(Abs(DetailedCustLedgEntry[i].Amount)), i - 1);
    end;

    local procedure VerifyXMLSeveralPurchPayments(XMLDoc: DotNet XmlDocument; DetailedVendorLedgEntry: array[4] of Record "Detailed Vendor Ledg. Entry"; ExpectedNodeCount: Integer)
    var
        i: Integer;
    begin
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Pago', ExpectedNodeCount);
        for i := 1 to ExpectedNodeCount do
            LibrarySII.ValidateElementByNameAt(
              XMLDoc, 'sii:Importe', SIIXMLCreator.FormatNumber(Abs(DetailedVendorLedgEntry[i].Amount)), i - 1);
    end;

    local procedure VerifyUploadPendingDocsJobQueueEntryCount(ExpectedCount: Integer)
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
    begin
        LibraryJobQueue.GetCollectedJobQueueEntries(TempJobQueueEntry);
        TempJobQueueEntry.SetRange("Object Type to Run", TempJobQueueEntry."Object Type to Run"::Codeunit);
        TempJobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
        Assert.RecordCount(TempJobQueueEntry, ExpectedCount);
    end;
}

