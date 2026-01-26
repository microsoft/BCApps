codeunit 147520 SIIDocumentTests
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        Assert: Codeunit Assert;
        SIIXMLCreator: Codeunit "SII XML Creator";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySII: Codeunit "Library - SII";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        XmlType: Option Invoice,"Intra Community",Payment;
        IsInitialized: Boolean;
        GlobalCreditMemoType: Option " ",Replacement,Difference,Removal;
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        XPathPurchCrMemoRemovalIDFacturaTok: Label '//soapenv:Body/siiLR:BajaLRFacturasRecibidas/siiLR:RegistroLRBajaRecibidas/siiLR:IDFactura';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        ESLbl: Label 'ES';
        XILbl: Label 'XI';
        VatRegistrationNoLbl: Label 'B80833593';
        SIICodigoPaisLbl: Label 'sii:CodigoPais';
        DotNetVariableNotInstantiatedErr: Label 'A DotNet variable has not been instantiated. Attempting to call System.Xml.XmlNode.InnerText in CodeUnit Library - SII: ValidateElementByNameAt';
        ErrorTextMustMatchErr: label 'Error text must match.';

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesXml()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        Initialize();
        // [GIVEN] Creation of a Sales Invoice for a local customer
        SalesInvoiceHeader.Get(CreateSalesDocument(true, false, '', GlobalCreditMemoType::" ", true));
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.ValidateElementByName(
          XMLDoc,
          'sii:DescripcionOperacion',
          SalesInvoiceHeader."Operation Description" + SalesInvoiceHeader."Operation Description 2");
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure TestCreateSalesXmlWithDiffBillToCust()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 221468] XML has customer related fields from "Bill-to Customer No." in sales order
        Initialize();
        // [GIVEN] Sales Invoice for a local customer and different Bill-to and Sell-to customers
        LibrarySII.CreateCustWithCountryAndVATReg(SellToCustomer, '', 'B78603495');
        LibrarySII.CreateCustWithCountryAndVATReg(BillToCustomer, '', 'B80833593');
        SalesInvoiceHeader.Get(
          CreateSalesDocumentWithDiffBillToCust(
            true, false, GlobalCreditMemoType::" ", SellToCustomer."No.", BillToCustomer."No.", true));
        CustLedgerEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeader."No.");

        // [WHEN] Create the xml for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Customer related fields must be used from "Bill-to Customer No." in sales order
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCashBasedSalesXml()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        Initialize();

        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        Customer."VAT Registration No." := 'B80833593';
        Customer."Country/Region Code" := 'ES';
        Customer.Modify(true);

        // [GIVEN] Creation of a Sales Invoice for a local customer, cash based
        DocumentNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, true, false);

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local customer, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForSI(
            Customer."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindFirst();
        SIIXMLCreator.Reset();
        Assert.IsTrue(SIIXMLCreator.GenerateXml(DetailedCustLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, DetailedCustLedgEntry, XmlType::Payment, true, false);

        DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateExemptSalesXml()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        Initialize();

        // [GIVEN] Creation of an exempt Sales Invoice for a local customer
        SalesInvoiceHeader.Get(CreateSalesDocument(true, true, '', GlobalCreditMemoType::" ", true));
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseXml()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 255493] FechaRegContable node of XML file has value of "Requested Date" of SII History for Purchase Invoice
        Initialize();

        // [GIVEN] Creation of an Purchase Invoice for a local vendor
        PurchInvHeader.Get(CreatePurchDocument(true, 'ES', GlobalCreditMemoType::" ", true));
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction on 09.01.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.ValidateElementByName(
          XMLDoc,
          'sii:DescripcionOperacion',
          PurchInvHeader."Operation Description" + PurchInvHeader."Operation Description 2");

        // [THEN] "FechaRegContable" node has value "09.01.2017" in XML file
        VerifyFechaRegContableIsRequestDateOfSIIHistory(VendorLedgerEntry, XMLDoc);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseXmlWithDiffPayToVend()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 221468] XML has vendor related fields from "Pay-to Vendor No." in purchase order
        // [SCENARIO 233980]
        Initialize();

        // [GIVEN] Purchase Invoice for a local vendor and different Pay-to and Buy-from vendors
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B78603495');
        LibrarySII.CreateVendWithCountryAndVATReg(PayToVendor, 'ES', 'B80833593');
        PurchInvHeader.Get(
          LibrarySII.CreatePurchDocumentWithDiffPayToVendor(
            true, PayToVendor."No.", Vendor."No.", GlobalCreditMemoType::" ", true));

        VendorLedgerEntry.SetRange("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");

        // [WHEN] Create the xml for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Vendor related fields must be used from "Pay-to Vendor No." in purchase order
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseCrMemoXmlWithDiffPayToVend()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 233980] XML has vendor related fields from "Pay-to Vendor No." in purchase Credit Memo
        // [SCENARIO 267017] "VAT Registration No." is taken from "Pay-To Vendor No." in purchase Credit Memo
        Initialize();

        // [GIVEN] Purchase Credit Memo for a local vendor and different Pay-to and Buy-from vendors
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B78603495');
        LibrarySII.CreateVendWithCountryAndVATReg(PayToVendor, 'ES', 'B80833593');
        PurchCrMemoHdr.Get(
          LibrarySII.CreatePurchDocumentWithDiffPayToVendor(
            false, PayToVendor."No.", Vendor."No.", GlobalCreditMemoType::" ", true));

        VendorLedgerEntry.SetRange("Vendor No.", PurchCrMemoHdr."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        // [WHEN] Create the xml for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Vendor related fields must be used from "Pay-to Vendor No." in purchase credit memo
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseCrMemoReplacementXmlWithDiffPayToVend()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PayToVendor: Record Vendor;
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 233980] XML has vendor related fields from "Pay-to Vendor No." in purchase Credit Memo (Replacement)
        Initialize();

        // [GIVEN] Purchase Credit Memo (Replacement) for a local vendor and different Pay-to and Buy-from vendors
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B78603495');
        LibrarySII.CreateVendWithCountryAndVATReg(PayToVendor, 'ES', 'B80833593');
        PurchCrMemoHdr.Get(
          LibrarySII.CreatePurchDocumentWithDiffPayToVendor(
            false, PayToVendor."No.", Vendor."No.", GlobalCreditMemoType::Replacement, true));
        PurchCrMemoHdr.Validate("Correction Type", PurchCrMemoHdr."Correction Type"::Replacement);
        PurchCrMemoHdr.Modify();

        VendorLedgerEntry.SetRange("Vendor No.", PurchCrMemoHdr."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        // [WHEN] Create the xml for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Vendor related fields must be used from "Pay-to Vendor No." in purchase credit memo
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateCashBasedPurchaseXml()
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        XMLDoc: DotNet XmlDocument;
        DocumentNo: Code[20];
        Amount: Decimal;
        ExtDocumentNo: Code[20];
    begin
        Initialize();

        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        Vendor."VAT Registration No." := 'B80833593';
        Vendor."Country/Region Code" := 'ES';
        Vendor.Modify(true);

        // [GIVEN] Creation of an Purchase Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, true, false);
        LibrarySII.AssertLibraryVariableStorage();

        // [GIVEN] Creation of a Payment for the previous Sales Invoice for a local vendor, cash based
        DocumentNo := Library340347Declaration.CreateAndPostPaymentForPI(
            Vendor."No.", GenJournalLine."Document Type"::Invoice, DocumentNo, WorkDate(), Amount);

        // [WHEN] We create the xml to be transmitted for that transaction
        DetailedVendorLedgEntry.Reset();
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst();
        SIIXMLCreator.Reset();
        Assert.IsTrue(SIIXMLCreator.GenerateXml(DetailedVendorLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, DetailedVendorLedgEntry, XmlType::Payment, true, false);

        DisableCashBased(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesCrMemoXmlDifference()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OriginalCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Sales Credit Memo with "Correction Type" = Difference
        // [SCENARIO 221622] Correct structure of XML nodes exports in XML file for Sales Credit Memo "Correction Type" = Difference
        // [SCENARIO 226498] ImporteTotal node contains negative value for Sales Credit Memo with Type = Difference
        // [SCENARIO 228335] DescripcionOperacion node contains value of "Operation Description" of Sales Credit Memo with Type = Difference
        // [SCENARIO 231749] FacturasRectificadas node exports in XML file with information about corrected document for Sales Credit Memo with "Correction Type" = Difference
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected sales invoice

        Initialize();

        // [GIVEN] Creation of an Sales Cr Memo for a local customer with Amount = 100, "Operation Description" = "X", "Document Date" = "Y" and set to difference correction type
        CustLedgerEntry.SetRange("Document No.", CreateSalesDocument(false, false, 'ES', GlobalCreditMemoType::Difference, true));
        CustLedgerEntry.FindFirst();
        SalesCrMemoHeader.Get(CustLedgerEntry."Document No.");
        SalesCrMemoHeader.Validate("Correction Type", SalesCrMemoHeader."Correction Type"::Difference);
        SalesCrMemoHeader.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);

        // [THEN] There is following nodes structure in XML file: TipoDesglose -> DesgloseTipoOperacion -> Entrega -> Sujeta
        VerifyXMLStructureCorrDoc(XMLDoc);
        LibrarySII.AssertLibraryVariableStorage();

        // [THEN] Node "sii:ImporteTotal" contains value -100
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));

        // [THEN] Node "sii:DescripcionOperacion" contains value "X"
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:DescripcionOperacion', SalesCrMemoHeader."Operation Description" + SalesCrMemoHeader."Operation Description 2");

        // [THEN] FacturasRectificadas node exists in XML file
        LibraryERM.FindCustomerLedgerEntry(
          OriginalCustLedgerEntry, OriginalCustLedgerEntry."Document Type"::Invoice, SalesCrMemoHeader."Corrected Invoice No.");
        VerifyFacturasRectificadasNode(
          XMLDoc, XPathSalesFacturaExpedidaTok, OriginalCustLedgerEntry."Document No.", OriginalCustLedgerEntry."Posting Date");

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Customer Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          CustLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", OriginalCustLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corr. Posting Date", OriginalCustLedgerEntry."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesCrMemoXmlReplacement()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvCustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Sales Credit Memo with "Correction Type" = Replacement
        // [SCENARIO 221622] Correct structure of XML nodes exports in XML file for Sales Credit Memo "Correction Type" = Replacement
        // [SCENARIO 226498] ImporteTotal node contains positive value for Sales Credit Memo with Type = Removal
        // [SCENARIO 228335] DescripcionOperacion node contains value of "Operation Description" of Sales Credit Memo with Type = Replacement
        // [SCENARIO 231749] FacturasRectificadas node exports in XML file with information about corrected document for Sales Credit Memo with "Correction Type" = Replacement

        Initialize();

        // [GIVEN] Creation of an Sales Cr Memo for a local customer with Amount = 100, corrective invoice has amount 150, "Operation Description" = "X" and set to replacement correction type
        CustLedgerEntry.SetRange("Document No.", CreateSalesDocument(false, false, 'ES', GlobalCreditMemoType::Replacement, true));
        CustLedgerEntry.FindFirst();
        SalesCrMemoHeader.Get(CustLedgerEntry."Document No.");
        SalesCrMemoHeader.Validate("Correction Type", SalesCrMemoHeader."Correction Type"::Replacement);
        SalesCrMemoHeader.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);

        // [THEN] There is following nodes structure in XML file: TipoDesglose -> DesgloseTipoOperacion -> Entrega -> Sujeta
        VerifyXMLStructureCorrDoc(XMLDoc);
        LibrarySII.AssertLibraryVariableStorage();

        // [THEN] Node "sii:ImporteTotal" contains value 50 (Credit Memo Amount - Invoice Amount = 150 - 100)
        LibraryERM.FindCustomerLedgerEntry(
          InvCustLedgerEntry, InvCustLedgerEntry."Document Type"::Invoice, SalesCrMemoHeader."Corrected Invoice No.");
        InvCustLedgerEntry.CalcFields("Amount (LCY)");
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(InvCustLedgerEntry."Amount (LCY)" + CustLedgerEntry."Amount (LCY)"));

        // [THEN] Node "sii:DescripcionOperacion" contains value "X"
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:DescripcionOperacion', SalesCrMemoHeader."Operation Description" + SalesCrMemoHeader."Operation Description 2");

        // [THEN] FacturasRectificadas node exists in XML file
        VerifyFacturasRectificadasNode(
          XMLDoc, XPathSalesFacturaExpedidaTok, InvCustLedgerEntry."Document No.", InvCustLedgerEntry."Posting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesCrMemoXmlRemoval()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Sales Credit Memo with "Correction Type" = Removal
        Initialize();

        // [GIVEN] Creation of an Sales Cr Memo for a local customer, set to removal correction type
        CustLedgerEntry.SetRange("Document No.", CreateSalesDocument(false, false, 'ES', GlobalCreditMemoType::Removal, true));
        CustLedgerEntry.FindFirst();
        SalesCrMemoHeader.Get(CustLedgerEntry."Document No.");
        SalesCrMemoHeader.Validate("Correction Type", SalesCrMemoHeader."Correction Type"::Removal);
        SalesCrMemoHeader.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchCrMemoXmlDifference()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        OriginalVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Purchase Credit Memo with "Correction Type" = Difference
        // [SCENARIO 226498] ImporteTotal node contains negative value for Purchase Credit Memo with Type = Difference
        // [SCENARIO 228335] DescripcionOperacion node contains value of "Operation Description" of Purchase Credit Memo with Type = Difference
        // [SCENARIO 231749] FacturasRectificadas node exports in XML file with information about corrected document for Purchase Credit Memo with "Correction Type" = Difference
        // [SCENARIO 255493] FechaRegContable node of XML file has value of "Requested Date" of SII History for Purchase Credit Memo with "Correction Type" = Difference
        // [SCENARIO 259155] NumSerieFacturaEmisor node of FacturasRectificadas parent node has value of "External Document No." of Vendor Ledger Entry
        // [SCENARIO 269110] SII Doc. Upload State has "Corrected Doc. No." and "Corr. Posting Date" of corrected sales invoice

        Initialize();

        // [GIVEN] Creation of an Purchase Cr Memo for a local vendor with Amount = 100, "Operation Description" = "X" and "Document Date" = "Y"
        VendorLedgerEntry.SetRange("Document No.", CreatePurchDocument(false, 'ES', PurchCrMemoHdr."Correction Type"::Difference, true));
        VendorLedgerEntry.FindFirst();
        PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.");
        PurchCrMemoHdr.Validate("Correction Type", PurchCrMemoHdr."Correction Type"::Difference);
        PurchCrMemoHdr.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction on 09.01.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);

        // [THEN] Node "sii:ImporteTotal" contains value -100
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));

        // [THEN] Node "sii:DescripcionOperacion" contains value "X"
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:DescripcionOperacion', PurchCrMemoHdr."Operation Description" + PurchCrMemoHdr."Operation Description 2");

        // [THEN] FacturasRectificadas node exists in XML file
        LibraryERM.FindVendorLedgerEntry(
          OriginalVendorLedgerEntry, OriginalVendorLedgerEntry."Document Type"::Invoice, PurchCrMemoHdr."Corrected Invoice No.");
        VerifyFacturasRectificadasNode(
          XMLDoc, XPathPurchFacturaRecibidaTok, OriginalVendorLedgerEntry."External Document No.",
          OriginalVendorLedgerEntry."Posting Date");

        // [THEN] "FechaRegContable" node has value "09.01.2017" in XML file
        VerifyFechaRegContableIsRequestDateOfSIIHistory(VendorLedgerEntry, XMLDoc);

        // [THEN] SII Doc. Upload State for Credit Memo exists with "Corrected Doc. No." = "X" and "Corr. Posting Date" = "Y"
        LibrarySII.FindSIIDocUploadState(
          SIIDocUploadState, SIIDocUploadState."Document Source"::"Vendor Ledger", SIIDocUploadState."Document Type"::"Credit Memo",
          VendorLedgerEntry."Document No.");
        SIIDocUploadState.TestField("Corrected Doc. No.", OriginalVendorLedgerEntry."External Document No.");
        SIIDocUploadState.TestField("Corr. Posting Date", OriginalVendorLedgerEntry."Document Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchCrMemoXmlReplacement()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InvVendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Purchase Credit Memo with "Correction Type" = Replacement
        // [SCENARIO 226498] ImporteTotal node contains negative value for Purchase Credit Memo with Type = Replacement
        // [SCENARIO 228335] DescripcionOperacion node contains value of "Operation Description" of Purchase Credit Memo with Type = Replacement
        // [SCENARIO 231749] FacturasRectificadas node exports in XML file with information about corrected document for Purchase Credit Memo with "Correction Type" = Replacement
        // [SCENARIO 255493] FechaRegContable node of XML file has value of "Requested Date" of SII History for Purchase Credit Memo with "Correction Type" = Replacement

        Initialize();

        // [GIVEN] Creation of an Purchase Cr Memo for a local vendor with Amount = 100, corrective invoice has amount 150 and "Operation Description" = "X"
        VendorLedgerEntry.SetRange("Document No.", CreatePurchDocument(false, 'ES', PurchCrMemoHdr."Correction Type"::Replacement, true));
        VendorLedgerEntry.FindFirst();
        PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.");
        PurchCrMemoHdr.Validate("Correction Type", PurchCrMemoHdr."Correction Type"::Replacement);
        PurchCrMemoHdr.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction on 09.01.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);

        // [THEN] Node "sii:ImporteTotal" contains value 50 (Credit Memo Amount - Invoice Amount = 150 - 100)
        LibraryERM.FindVendorLedgerEntry(
          InvVendorLedgerEntry, InvVendorLedgerEntry."Document Type"::Invoice, PurchCrMemoHdr."Corrected Invoice No.");
        InvVendorLedgerEntry.CalcFields("Amount (LCY)");
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-InvVendorLedgerEntry."Amount (LCY)" - VendorLedgerEntry."Amount (LCY)"));

        // [THEN] Node "sii:DescripcionOperacion" contains value "X"
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:DescripcionOperacion', PurchCrMemoHdr."Operation Description" + PurchCrMemoHdr."Operation Description 2");

        // [THEN] FacturasRectificadas node exists in XML file
        VerifyFacturasRectificadasNode(
          XMLDoc, XPathPurchFacturaRecibidaTok, InvVendorLedgerEntry."External Document No.", InvVendorLedgerEntry."Posting Date");

        // [THEN] "FechaRegContable" node has value "09.01.2017" in XML file
        VerifyFechaRegContableIsRequestDateOfSIIHistory(VendorLedgerEntry, XMLDoc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchCrMemoXmlRemoval()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO] Generate sii XML file for Purchase Credit Memo with "Correction Type" = Removal
        // [SCENARIO 227852] "Exernal Document No." uses for "NumSerieFacturaEmisor" xml node for Purchase Credit Memo with "Correction Type" = Removal

        Initialize();

        // [GIVEN] Creation of an Purchase Cr Memo for a local vendor
        VendorLedgerEntry.SetRange("Document No.", CreatePurchDocument(false, 'ES', PurchCrMemoHdr."Correction Type"::Removal, true));
        VendorLedgerEntry.FindFirst();
        PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.");
        PurchCrMemoHdr.Validate("Correction Type", PurchCrMemoHdr."Correction Type"::Removal);
        PurchCrMemoHdr.Modify();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesForeignXml()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        Initialize();

        // [GIVEN] Creation of a Sales Invoice for a foreign customer
        SalesInvoiceHeader.Get(CreateSalesDocument(true, false, 'US', GlobalCreditMemoType::" ", true));
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseForeignXml()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        Initialize();

        // [GIVEN] Creation of an Purchase Invoice for a foreign Vendor
        PurchInvHeader.Get(CreatePurchDocument(true, 'US', GlobalCreditMemoType::" ", true));
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithoutInvoiceReportedWithTypeI()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 221490] Sales credit memo without corrective invoice No must be reported with Tipo Rectificativa "I"
        Initialize();

        // [GIVEN] Sales Cr Memo without corrective invoice No.
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          CreateSalesDocument(false, false, 'ES', GlobalCreditMemoType::Difference, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithoutInvoiceReportedWithTypeI()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 228997] Purchase credit memo without corrective invoice No must be reported with Tipo Rectificativa "I" and negative amounts

        Initialize();

        // [GIVEN] Purchase Cr Memo without corrective invoice No. and VAT Amount = 100
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          CreatePurchDocument(false, 'ES', GlobalCreditMemoType::Difference, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid and amounts are negative
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure PurchOrderHasCorrectSpecialSchemeCodeAfterNonIntracommunitaryVendorValidate()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // [FEATURE] [Special Scheme Code]
        // [SCENARIO 220567] Purchase Order has "Special Scheme Code" = "01 General" after updating "Buy-from Vendor No." with non-intracommunitary vendor
        Initialize();

        // [GIVEN] Purchase Invoice without "Buy-from Vendor No."
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [WHEN] Update "Buy-from Vendor No." with non-intracommunitary vendor
        PurchaseHeader.Validate("Buy-from Vendor No.", LibrarySII.CreateVendor('ES'));
        PurchaseHeader.Modify(true);

        // [THEN] "Special Scheme Code" has value "01 General"
        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"01 General");
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure SalesOrderHasCorrectSpecialSchemeCodeAfterDomesticCustomerValidate()
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Special Scheme Code]
        // [SCENARIO 220567] Salles Order has "Special Scheme Code" = "01 General" after updating "Sell-to Customer No." with domestic customer
        Initialize();

        // [GIVEN] Sales Invoice without "Sell-to Customer No."
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Update "Sell-to Customer No." with domestic customer
        SalesHeader.Validate("Sell-to Customer No.", LibrarySII.CreateCustomer('ES'));
        SalesHeader.Modify(true);

        // [THEN] "Special Scheme Code" has value "01 General"
        SalesHeader.TestField("Special Scheme Code", SalesHeader."Special Scheme Code"::"01 General");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithMultipleLinesDiffVATRate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 221594] XML file has nodes with correct VAT Base and Amount according to each VAT Entry posted from Sales Invoice with multiple lines with different VAT rate

        Initialize();

        // [GIVEN] Posted Sales Invoice with multiplines lines, each line have different "VAT %"
        LibrarySII.PostSalesInvWithMultiplesLinesDiffVAT(CustLedgerEntry, false);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has two nodes for each VAT Entry with correct "VAT %"
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithMultipleLinesDiffVATRate()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 221594] XML file has nodes with correct VAT Base and Amount according to each VAT Entry posted from Purchase Invoice with multiple lines with different VAT rate

        Initialize();

        // [GIVEN] Posted Sales Invoice with multiplines lines, each line have different "VAT %"
        PostPurchDocWithMultiplesLinesDiffVAT(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has two nodes for each VAT Entry with correct "VAT %"
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithNormalAndReverseChargeVATXML()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        VATRateReverseCharge: Decimal;
        Amount: Decimal;
        AmountReverseCharge: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 221521] When purchase invoice is posted Reverse Charge VAT entries are split from Normal VAT entries in XML
        Initialize();

        // [GIVEN] Posted Purchase Invoice with two Purchase Lines where
        // [GIVEN] 1st line is calculated as Reverse Charge VAT with Base = 100, Amount = 12
        // [GIVEN] 2nd line is calculated as Normal VAT with Base = 100, Amount = 21
        CreatePurchDocWithNormalAndReverseChargeVAT(
          PurchaseHeader, VATRate, VATRateReverseCharge, Amount, AmountReverseCharge, PurchaseHeader."Document Type"::Invoice);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:DesgloseFactura' has subtrees:
        // [THEN] 'sii:InversionSujetoPasivo' created for Reverse Charge VAT with Amount = 12
        // [THEN] 'sii:DesgloseIVA' created for Normal VAT with Amount = 21
        // [THEN] 'sii:CuotaDeducible' has value = 33
        LibrarySII.VerifyXMLWithNormalAndReverseChargeVAT(XMLDoc, VATRate, VATRateReverseCharge, Amount, AmountReverseCharge);

        // [THEN] 'sii:ImporteTotal' = 221
        // TFS ID: 348379: Only VAT Base amount consideres for ImporteTotal xml node in case of Reverse Charge VAT
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(GetVATTotalAmountExceptRevChargeAmount(VendorLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithNormalAndReverseChargeVATXML()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        VATRateReverseCharge: Decimal;
        Amount: Decimal;
        AmountReverseCharge: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 220690] XML file for purchase credit memo with Reverse Charge VAT generates with both DesgloseIVA and InversionSujetoPasivo nodes

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with lines
        // [GIVEN] 1st line is calculated as Reverse Charge VAT with Amount = "AmntRC"
        // [GIVEN] 2nd line is calculated as Normal VAT with Amount = "Amnt"
        CreatePurchDocWithNormalAndReverseChargeVAT(
          PurchaseHeader, VATRate, VATRateReverseCharge, Amount, AmountReverseCharge, PurchaseHeader."Document Type"::"Credit Memo");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:DesgloseFactura' has subtrees:
        // [THEN] 'sii:InversionSujetoPasivo' created for Reverse Charge VAT with Amount = "AmntRC"
        // [THEN] 'sii:DesgloseIVA' created for Normal VAT with Amount = "Amnt"
        // [THEN] 'sii:CuotaDeducible' has value = "AmntRC" + "Amnt"
        LibrarySII.VerifyXMLWithNormalAndReverseChargeVAT(XMLDoc, VATRate, VATRateReverseCharge, -Amount, -AmountReverseCharge);

        // [THEN] 'sii:ImporteTotal' = 221
        // TFS ID: 348379: Only VAT Base amount consideres for ImporteTotal xml node in case of Reverse Charge VAT
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(GetVATTotalAmountExceptRevChargeAmount(VendorLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithReverseChargeVATXML()
    var
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 221521] When purchase invoice is posted Reverse Charge VAT entries get other tag than normal VAT entries in XML
        Initialize();

        // [GIVEN] Posted Purchase Invoice with one Purchase Line where
        // [GIVEN] line is calculated as Reverse Charge VAT with Amount = "AmntRC"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::Invoice, CountryRegion.Code);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:DesgloseFactura' has subtree 'sii:InversionSujetoPasivo'
        // [THEN] 'sii:CuotaDeducible' has value = "AmntRC"
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:InversionSujetoPasivo', VATRate, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithNormalVATXML()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 221521] When purchase invoice is posted Normal VAT entries get other tag than reverse charge VAT entries
        Initialize();

        // [GIVEN] Posted Purchase Invoice with one Purchase Line where
        // [GIVEN] line is calculated as Normal VAT with Amount = "Amnt"
        CreatePurchInvWithNormalVAT(PurchaseHeader, VATRate, Amount);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:DesgloseFactura' has subtree 'sii:DesgloseIVA'
        // [THEN] 'sii:CuotaDeducible' has value = "Amnt"
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:DesgloseIVA', VATRate, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesXmlWithNLVATRegNo()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 220556] It must be possible to get SII XML files for customers from the Netherlands
        Initialize();
        // [GIVEN] Creation of a Sales Invoice for a NL customer
        SalesInvoiceHeader.Get(CreateSalesDocument(true, false, 'NL', GlobalCreditMemoType::" ", true));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("VAT Registration No.", 'NL123456789B12');
        Customer.Modify(true);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesXmlWithVATRegNoStartingWithN()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 220556] It must be possible to get SII XML files for local customers having "VAT Registration No." starting with "N"
        Initialize();
        // [GIVEN] Creation of a Sales Invoice for a local customer having "VAT Registration No." starting with "N"
        SalesInvoiceHeader.Get(CreateSalesDocument(true, false, '', GlobalCreditMemoType::" ", true));
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        Customer.Validate("VAT Registration No.", 'N12345678');
        Customer.Modify(true);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Assert that the values in the xml are valid
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenShptDateDiffersFromSalesInvPostDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeaderForShip1: Record "Sales Header";
        SalesHeaderForShip2: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        ShipmentDate: Date;
        OldWorkDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 220565] If the latest "Shipment Date" of line is not equeal to "Posting Date" of Sales Invoice, then the latest "Shipment Date" must be included in XML file within FechaOperacion tag
        Initialize();

        // [GIVEN] Posted Sales Shipment on 01.07.2017
        CustomerNo := LibrarySales.CreateCustomerNo();
        OldWorkDate := WorkDate();
        CreateSalesShipmentWithShipDate(SalesHeaderForShip1, CustomerNo, WorkDate());

        // [GIVEN] Posted Sales Shipment on 03.07.2017
        WorkDate := WorkDate() + 1;
        ShipmentDate := WorkDate();
        CreateSalesShipmentWithShipDate(SalesHeaderForShip2, CustomerNo, WorkDate());

        // [GIVEN] "Get Shipment Lines" action is called for Sales Invoice
        WorkDate := WorkDate() + 1;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GetShipmentLines(SalesHeaderForShip1, SalesHeader);
        GetShipmentLines(SalesHeaderForShip2, SalesHeader);

        // [GIVEN] Sales Invoice is posted on 05.07.2017
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains 03.07.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(ShipmentDate), 0);

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenShptDateIsTheSameAsSalesInvPostDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeaderForShip1: Record "Sales Header";
        SalesHeaderForShip2: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        OldWorkDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 220565] If the latest "Shipment Date" of line is equeal to "Posting Date" of Sales Invoice, then FechaOperacion tag must not be included in XML file
        Initialize();

        // [GIVEN] Posted Sales Shipment on 01.07.2017
        CustomerNo := LibrarySales.CreateCustomerNo();
        OldWorkDate := WorkDate();
        CreateSalesShipmentWithShipDate(SalesHeaderForShip1, CustomerNo, WorkDate());

        // [GIVEN] Posted Sales Shipment on 05.07.2017
        WorkDate := WorkDate() + 1;
        CreateSalesShipmentWithShipDate(SalesHeaderForShip2, CustomerNo, WorkDate());

        // [GIVEN] "Get Shipment Lines" action is called for Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GetShipmentLines(SalesHeaderForShip1, SalesHeader);
        GetShipmentLines(SalesHeaderForShip2, SalesHeader);

        // [GIVEN] Sales Invoice is posted on 05.07.2017
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenRcptDateDiffersFromPurchInvPostDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderForRcpt1: Record "Purchase Header";
        PurchaseHeaderForRcpt2: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        PurchInvoiceHeaderNo: Code[20];
        RcptDate: Date;
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 220565] If the latest "Posting Date" of purchase receipt line is not equeal to "Posting Date" of Purchase Invoice, then the latest receipt date must be included in XML file within FechaOperacion tag
        Initialize();

        // [GIVEN] Posted Purchase Receipt on 01.07.2017
        VendorNo := LibraryPurchase.CreateVendorNo();
        RcptDate := CalcDate('<-2D>', WorkDate());
        CreatePurchRcptWithPostingDate(PurchaseHeaderForRcpt1, VendorNo, RcptDate);

        // [GIVEN] Posted Purchase Receipt on 03.07.2017
        CreatePurchRcptWithPostingDate(PurchaseHeaderForRcpt2, VendorNo, CalcDate('<-3D>', WorkDate()));

        // [GIVEN] "Get Receipt Lines" action is called for Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetRcptLines(PurchaseHeaderForRcpt1, PurchaseHeader);
        GetRcptLines(PurchaseHeaderForRcpt2, PurchaseHeader);

        // [GIVEN] Purchase Invoice is posted on 05.07.2017
        PurchInvoiceHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Document No.", PurchInvoiceHeaderNo);
        VendorLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains 03.07.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(RcptDate), 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenRcptDateIsTheSameAsPurchInvPostDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeaderForShip1: Record "Sales Header";
        SalesHeaderForShip2: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        ShipmentDate: Date;
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 220565] If the latest "Shipment Date" of line is equeal to "Posting Date" of Sales Invoice, then FechaOperacion tag must not be included in XML file
        Initialize();

        // [GIVEN] Posted Sales Shipment on 01.07.2017
        CustomerNo := LibrarySales.CreateCustomerNo();
        ShipmentDate := CalcDate('<-2D>', WorkDate());
        CreateSalesShipmentWithShipDate(SalesHeaderForShip1, CustomerNo, ShipmentDate);

        // [GIVEN] Posted Sales Shipment on 05.07.2017
        CreateSalesShipmentWithShipDate(SalesHeaderForShip2, CustomerNo, WorkDate());

        // [GIVEN] "Get Shipment Lines" action is called for Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GetShipmentLines(SalesHeaderForShip1, SalesHeader);
        GetShipmentLines(SalesHeaderForShip2, SalesHeader);

        // [GIVEN] Sales Invoice is posted on 05.07.2017
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOfCorrectiveSalesCrMemoInDiffPeriod()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
        CrMemoDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 223812] Posting Date of corrective Sales Credit Memo to Invoice in different period exports to XML file

        Initialize();
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, 'ES', 'B80833593');

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 05.01.2017
        InvNo := CreateAndPostSalesDocWithDate(SalesHeader."Document Type"::Invoice, Customer."No.", WorkDate(), '');

        // [GIVEN] Posted Sales Credit Memo with "Posting Date" = 05.02.2017
        CrMemoDate := CalcDate('<1M>', WorkDate());
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          CreateAndPostSalesDocWithDate(SalesHeader."Document Type"::"Credit Memo", Customer."No.", CrMemoDate, InvNo));

        // [WHEN] Create xml file for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year equals "2017" and month equals "02"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CrMemoDate, 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CrMemoDate, 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOfCorrectivePurchCrMemoInDiffPeriod()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
        CrMemoDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 223812] Posting Date of corrective Purchase Credit Memo to Invoice in different period exports to XML file

        Initialize();
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');

        // [GIVEN] Posted Purchase Invoice with "Posting Date" = 05.01.2017
        InvNo := CreateAndPostPurchDocWithDate(PurchaseHeader."Document Type"::Invoice, Vendor."No.", WorkDate(), '');

        // [GIVEN] Posted Purchase Credit Memo with "Posting Date" = 05.02.2017
        CrMemoDate := CalcDate('<1M>', WorkDate());
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          CreateAndPostPurchDocWithDate(PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", CrMemoDate, InvNo));

        // [WHEN] Create xml file for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year equals "2017" and month equals "02"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CrMemoDate, 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CrMemoDate, 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithMultipleLinesDiffVATGroupSameRate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 221594] XML file has nodes with correct VAT Base and Amount according to each VAT Entry posted from Sales Invoice with multiple lines with different VAT group but same VAT %

        Initialize();

        // [GIVEN] Posted Sales Invoice with multiplines lines, each line have different "VAT %"
        PostSalesInvWithMultiplesLinesDiffVATGroupSameRate(CustLedgerEntry);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has two nodes for each VAT Entry with correct "VAT %"
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithMultipleLinesDiffVATGroupSameRate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 221594] XML file has nodes with correct VAT Base and Amount according to each VAT Entry posted from Purchase Invoice with multiple lines with different VAT group but same VAT %

        Initialize();

        // [GIVEN] Posted Purchase Invoice with multiplines lines, each line have different "VAT %"
        PostPurchInvWithMultiplesLinesDiffVATGroupSameRate(VendorLedgerEntry);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has two nodes for each VAT Entry with correct "VAT %"
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeSalesCreditMemoXML()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 227852] "Special Scheme Code" of Sales Credit Memo uses for "ClaveRegimenEspecialOTrascendencia" node when export to SII xml file

        Initialize();

        // [GIVEN] Sales Credit Memo with "Special Scheme Code" = "02 Export"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"02 Export");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create xml for Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:ClaveRegimenEspecialOTrascendencia node with value '02' for "Special Scheme Code" = "02 Export"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, '/sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodePurchCreditMemoXML()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 227852] "Special Scheme Code" of Purchase Credit Memo uses for "ClaveRegimenEspecialOTrascendencia" node when export to SII xml file

        Initialize();

        // [GIVEN] Purchase Credit Memo with "Special Scheme Code" = "02 Special System Activities"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"02 Special System Activities");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:ClaveRegimenEspecialOTrascendencia node with value '02' for "Special Scheme Code" = "02 Special System Activities"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:ClaveRegimenEspecialOTrascendencia', '02');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenPartialShipment()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
        ShipmentDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 227875] "Shipment Date" of only posted lines of partial shipment must be considers for FechaOperacion tag in XML file

        Initialize();

        // [GIVEN] Sales Order with "Posting Date" = 01.01.2017 and two lines posted as partial shipment
        // [GIVEN] First line with "Shipment Date" = 03.01.2017 and "Qty. To Ship" = 10
        // [GIVEN] Second line with "Shipment Date" = 05.01.2017 and "Qty. To Ship" = 0
        CreatePartialSalesOrderWithDiffShptDates(SalesHeader, ShipmentDate);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Posted Invoice for partial shipment
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [WHEN] Create xml for Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains 03.01.2017, only for shipped line
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, '/sii:FechaOperacion', SIIXMLCreator.FormatDate(ShipmentDate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoRemovalWhenNoExternalDocNoExpecified()
    var
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 227852] "Document No." uses for "NumSerieFacturaEmisor" xml node for Purchase Credit Memo with "Correction Type" = Removal when "External Document No." is not specified

        Initialize();

        // [GIVEN] "Ext. Doc. No. Mandatory" is turned off in "Purchases & Payables Setup"
        LibraryPurchase.SetExtDocNo(false);

        // [GIVEN] Purchase Invoice "X" with blank "External Document No."
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderInvoice, PurchaseLine,
          PurchaseHeaderInvoice."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100), '', WorkDate());
        PurchaseHeaderInvoice.Validate("Vendor Invoice No.", '');
        PurchaseHeaderInvoice.Modify(true);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));

        // [GIVEN] Purchase Credit Memo Header with Type = "Removal" and "Corrected Invoice No." = "X"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeaderInvoice."Pay-to Vendor No.");
        PurchaseHeader.Validate("Correction Type", PurchaseHeader."Correction Type"::Removal);
        PurchaseHeader.Validate("Corrected Invoice No.", LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", LibraryRandom.RandInt(100));
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));

        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] XML file with node "NumSerieFacturaEmisor" and value "X" generated
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchCrMemoRemovalIDFacturaTok, '/sii:NumSerieFacturaEmisor', PurchaseHeader."Corrected Invoice No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoWithMultipleLines()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 228197] Generate sii XML file for Purchase Credit Memo with "Correction Type" = Replacement and multiple lines
        // [SCENARIO 256251] Sales Credit Memo with type "Replacement" and related corrective invoice has positive values for VAT

        Initialize();

        // [GIVEN] Purchase Credit Memo with "X" lines, Total VAT Amount = "Y", and "Correction Type" = Replacement
        PostPurchDocWithMultiplesLinesDiffVAT(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "X" nodes "CuotaSoportada" by each VAT Entry exists in XML file
        VATEntry.SetCurrentKey("VAT %", "EC %");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VATEntry.FindSet();
        repeat
            LibrarySII.VerifyOneNodeWithValueByXPath(
              XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(VATEntry.Amount));
            TotalVATAmount += Abs(VATEntry.Amount);
        until VATEntry.Next() = 0;

        // [THEN] One node "CuotaDeducible" with value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:CuotaDeducible', SIIXMLCreator.FormatNumber(TotalVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescripcionOperacionOfServCrMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 228335] DescripcionOperacion node exists in XML file of Service Credit Memo

        Initialize();

        // [GIVEN] Service Credit Memo with "Operation Description" = "X"
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.",
          LibrarySII.PostServDocWithCurrency(ServiceHeader."Document Type"::"Credit Memo", ''));
        ServiceCrMemoHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceCrMemoHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");

        // [WHEN] Create xml for Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Node "sii:DescripcionOperacion" contains value "X"
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:DescripcionOperacion', ServiceCrMemoHeader."Operation Description" + ServiceCrMemoHeader."Operation Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenShptDateAfterToday()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        ShipmentDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 257315] If the latest "Shipment Date" of Sales Invoice is after today, then the "Posting Date" must be included in XML file within FechaOperacion tag

        Initialize();

        // [GIVEN] Today is January 29
        // [GIVEN] Posted Sales Invoice with "Posting Date" = January 25, "Shipment Date" = January 30
        CustomerNo := LibrarySales.CreateCustomerNo();
        ShipmentDate := LibraryRandom.RandDateFrom(WorkDate(), 10);
        CreateSalesShipmentWithShipDate(SalesHeader, CustomerNo, ShipmentDate);
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeaderNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains January 25
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(SalesHeader."Posting Date"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionWhenRcptDateAfterToday()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderForRcpt: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        PurchInvoiceHeaderNo: Code[20];
        RcptDate: Date;
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 257315] If the latest "Receipt Date" of Sales Invoice is after today, then the "Posting Date" must be included in XML file within FechaOperacion tag

        Initialize();

        // [GIVEN] Today is January 29
        // [GIVEN] Posted Purchase Invoice with "Posting Date" = January 25, "Receipt Date" = January 30
        VendorNo := LibraryPurchase.CreateVendorNo();
        RcptDate := LibraryRandom.RandDateFrom(WorkDate(), 10);
        CreatePurchRcptWithPostingDate(PurchaseHeaderForRcpt, VendorNo, RcptDate);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetRcptLines(PurchaseHeaderForRcpt, PurchaseHeader);
        PurchInvoiceHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvoiceHeaderNo);

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains January 25
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(PurchaseHeader."Posting Date"), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeValuesForSalesInvWithNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 257338] Negative values exports in SII XML file for Sales Invoice with negative line

        Initialize();

        // [GIVEN] Sales invoice with two lines: first with Amount = 100, second with amount = -150
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        UnitPrice := LibraryRandom.RandDec(100, 2);
        CreateSalesLineWithNewProductGroupAndSpecificSign(SalesLine, SalesHeader, 1, UnitPrice + LibraryRandom.RandIntInRange(3, 5));
        CreateSalesLineWithNewProductGroupAndSpecificSign(SalesLine, SalesHeader, -1, UnitPrice);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] The second BaseImponible XNL node is -150
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '[2]' + '/sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '[2]' + '/sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(SalesLine."Amount Including VAT" - SalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeValuesForPurchInvWithNegativeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 257338] Negative values exports in SII XML file for Purchase Invoice with negative line

        Initialize();

        // [GIVEN] Purchase invoice with two lines: first with Amount = 100, second with amount = -150
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        UnitCost := LibraryRandom.RandDec(100, 2);
        CreatePurchLineWithNewProductGroupAndSpecificSign(PurchaseLine, PurchaseHeader, 1, UnitCost + LibraryRandom.RandIntInRange(3, 5));
        CreatePurchLineWithNewProductGroupAndSpecificSign(PurchaseLine, PurchaseHeader, -1, UnitCost);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] The second BaseImponible XNL node is -150
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[2]' + '/sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[2]' + '/sii:CuotaSoportada',
          SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_PaymentEndpointsInSIISetup()
    var
        SIISetup: Record "SII Setup";
    begin
        // [UT] [SII Setup]
        // [SCENARIO 264306] Default payment endpoints are correct in SII Setup

        Initialize();
        SIISetup.Delete();
        SIISetup.Init();
        SIISetup.Insert();
        SIISetup.TestField(PaymentsIssuedEndpointUrl, 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fr/SiiFactPAGV1SOAP');
        SIISetup.TestField(PaymentsReceivedEndpointUrl, 'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/SiiFactCOBV1SOAP');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SIIMgt_IsDomesticCustomer()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 277358] SIIMgt.IsDomesticCustomer() returns TRUE only in case of Customer with Country/Region = ""/"ES" AND "VAT Registration No." <> "N..."
        Initialize();

        // "VAT Registration No." = ""
        VerifySIIMgtIsDomesticCustomer('', '', true);
        VerifySIIMgtIsDomesticCustomer('ES', '', true);
        VerifySIIMgtIsDomesticCustomer('FR', '', false);

        // "VAT Registration No." = "B1234567890"
        VerifySIIMgtIsDomesticCustomer('', 'B1234567890', true);
        VerifySIIMgtIsDomesticCustomer('ES', 'B1234567890', true);
        VerifySIIMgtIsDomesticCustomer('FR', 'B1234567890', false);

        // "VAT Registration No." = "N1234567890"
        VerifySIIMgtIsDomesticCustomer('', 'N1234567890', false);
        VerifySIIMgtIsDomesticCustomer('ES', 'N1234567890', false);
        VerifySIIMgtIsDomesticCustomer('FR', 'N1234567890', false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomer_VATRegNoB_NoEU()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseFactura/Sujeta" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "", VAT Reg. No. = "B80833593"), non EU Service
        Initialize();

        // [GIVEN] Posted Sales Invoice for domestic customer (Country = "", VAT Reg. No. = "B80833593")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(CreateCustWithCountryAndVATReg('', 'B80833593')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseFactura/Sujeta" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseFactura', 'sii:Sujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomer_VATRegNoB_EU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseFactura/Sujeta" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "", VAT Reg. No. = "B80833593"), EU Service
        Initialize();

        // [GIVEN] Posted EU Sales Invoice for domestic customer (Country = "", VAT Reg. No. = "B80833593")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySII.CreatePostSalesInvoiceEU(VATPostingSetup, CreateCustWithCountryAndVATReg('', 'B80833593')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseFactura/Sujeta" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseFactura', 'sii:Sujeta');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomer_VATRegNoN_NoEU()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/Entrega" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "", VAT Reg. No. = "N1234567890"), non EU Service
        Initialize();

        // [GIVEN] Posted Sales Invoice for domestic customer (Country = "", VAT Reg. No. = "N1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(CreateCustWithCountryAndVATReg('', 'N1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/Entrega" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomer_VATRegNoN_EU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "", VAT Reg. No. = "N1234567890"), EU Service
        Initialize();

        // [GIVEN] Posted EU Sales Invoice for domestic customer (Country = "", VAT Reg. No. = "N1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySII.CreatePostSalesInvoiceEU(VATPostingSetup, CreateCustWithCountryAndVATReg('', 'N1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:PrestacionServicios');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomerES_VATRegNoB_NoEU()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseFactura/Sujeta" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "ES", VAT Reg. No. = "B80833593"), non EU Service
        Initialize();

        // [GIVEN] Posted Sales Invoice for domestic customer (Country = "ES", VAT Reg. No. = "B80833593")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(CreateCustWithCountryAndVATReg('ES', 'B80833593')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseFactura/Sujeta" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseFactura', 'sii:Sujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomerES_VATRegNoB_EU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseFactura/Sujeta" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "ES", VAT Reg. No. = "B80833593"), EU Service
        Initialize();

        // [GIVEN] Posted EU Sales Invoice for domestic customer (Country = "ES", VAT Reg. No. = "B80833593")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySII.CreatePostSalesInvoiceEU(VATPostingSetup, CreateCustWithCountryAndVATReg('ES', 'B80833593')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseFactura/Sujeta" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseFactura', 'sii:Sujeta');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomerES_VATRegNoN_NoEU()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/Entrega" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "ES", VAT Reg. No. = "N1234567890"), non EU Service
        Initialize();

        // [GIVEN] Posted Sales Invoice for domestic customer (Country = "ES", VAT Reg. No. = "N1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(CreateCustWithCountryAndVATReg('ES', 'N1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/Entrega" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_DomesticCustomerES_VATRegNoN_EU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node in case of sales invoice for
        // [SCENARIO 277358] domestic customer (Country = "ES", VAT Reg. No. = "N1234567890"), EU Service
        Initialize();

        // [GIVEN] Posted EU Sales Invoice for domestic customer (Country = "ES", VAT Reg. No. = "N1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySII.CreatePostSalesInvoiceEU(VATPostingSetup, CreateCustWithCountryAndVATReg('ES', 'N1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:PrestacionServicios');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_ForeignCustomer_NoEU()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/Entrega" node in case of sales invoice for
        // [SCENARIO 277358] foreign customer (Country = "FR", VAT Reg. No. = "FR1234567890"), non EU Service
        Initialize();

        // [GIVEN] Posted Sales Invoice for foreign customer (Country = "FR", VAT Reg. No. = "FR1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          CreatePostSalesInvoice(CreateCustWithCountryAndVATReg('FR', 'FR1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/Entrega" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoDesglose_ForeignCustomer_EU()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 277358] XML "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node in case of sales invoice for
        // [SCENARIO 277358] foreign customer (Country = "FR", VAT Reg. No. = "FR1234567890"), EU Service
        Initialize();

        // [GIVEN] Posted EU Sales Invoice for foreign customer (Country = "FR", VAT Reg. No. = "FR1234567890")
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySII.CreatePostSalesInvoiceEU(VATPostingSetup, CreateCustWithCountryAndVATReg('FR', 'FR1234567890')));

        // [WHEN] Generate xml for the posted invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There is a "TipoDesglose/DesgloseTipoOperacion/PrestacionServicios" node
        LibrarySII.VerifyTwoLevelChildNodes(XMLDoc, 'sii:TipoDesglose', 'sii:DesgloseTipoOperacion', 'sii:PrestacionServicios');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImporteTotal_WhenPostSalesInvAndCrMemoWithSameNo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        StartingNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Invoice] [No Series]
        // [SCENARIO 278070] Tag <ImporteTotal> has Total Amount from Posted Sales Credit Memo even if both Invoice and Corrective Credit Memo are posted with same No
        Initialize();
        StartingNo := LibraryUtility.GenerateGUID();

        // [GIVEN] No Series for Posted Invoice and Posted Credit Memo had same Starting No = 100000
        ModifyNoSeriesOnSalesSetupForPostedCrMemoAndInv(
          CreateNoSeriesWithStartingNo(StartingNo), CreateNoSeriesWithStartingNo(StartingNo));

        // [GIVEN] Posted Sales Invoice with No 100000 and Amount 1000.0
        // [GIVEN] Posted Sales Credit Memo for the same Customer with No 100000 and Amount 200.0
        CustLedgerEntry.SetRange("Document No.", CreateSalesDocument(false, false, CreateCountryRegionCode(), GlobalCreditMemoType::" ", true));
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");

        // [WHEN] Generate SII XML for the Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Tag <ImporteTotal> has value -200.0 in XML
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImporteTotal_WhenPostPurchInvAndCrMemoWithSameNo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        StartingNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Invoice] [No Series]
        // [SCENARIO 278070] Tag <ImporteTotal> has Total Amount from Posted Purchase Credit Memo even if both Invoice and Corrective Credit Memo are posted with same No
        Initialize();
        StartingNo := LibraryUtility.GenerateGUID();

        // [GIVEN] No Series for Posted Invoice and Posted Credit Memo had same Starting No = 100000
        ModifyNoSeriesOnSalesSetupForPostedCrMemoAndInv(
          CreateNoSeriesWithStartingNo(StartingNo), CreateNoSeriesWithStartingNo(StartingNo));

        // [GIVEN] Posted Purchase Invoice with No 100000 and Amount 1000.0
        // [GIVEN] Posted Purchase Credit Memo for the same Vendor with No 100000 and Amount 200.0
        VendorLedgerEntry.SetRange("Document No.", CreatePurchDocument(false, CreateCountryRegionCode(), GlobalCreditMemoType::" ", true));
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Amount (LCY)");

        // [WHEN] Generate SII XML for the Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Tag <ImporteTotal> has value -200.0 in XML
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImporteTotal_WhenPostServInvAndCrMemoWithSameNo()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        StartingNo: Code[20];
    begin
        // [FEATURE] [Service] [Credit Memo] [Invoice] [No Series]
        // [SCENARIO 278070] Tag <ImporteTotal> has Total Amount from Posted Service Credit Memo even if both Invoice and Corrective Credit Memo are posted with same No
        Initialize();
        StartingNo := LibraryUtility.GenerateGUID();

        // [GIVEN] No Series for Posted Service Invoice and Posted Service Credit Memo had same Starting No = 100000
        ModifyNoSeriesOnServSetupForPostedCrMemoAndInv(
          CreateNoSeriesWithStartingNo(StartingNo), CreateNoSeriesWithStartingNo(StartingNo));

        // [GIVEN] Posted Service Invoice with No 100000 and Amount 1000.0
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomerNoSII());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindCustLedgerEntryByDocTypeAndCustNo(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, ServiceHeader."Customer No.");

        // [GIVEN] Posted Service Credit Memo for the same Customer with No 100000 and Amount 200.0
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.");
        ModifyServiceHeaderCorrectedInvoiceNo(ServiceHeader, CustLedgerEntry."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindCustLedgerEntryByDocTypeAndCustNo(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceHeader."Customer No.");
        CustLedgerEntry.CalcFields("Amount (LCY)");

        // [WHEN] Generate SII XML for the Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Tag <ImporteTotal> has value -200.0 in XML
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FechaOperacionAfterPostingDateWhenSchemeCode14AndVersion11bis()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 375398] FechaOperacion xml node has value after the posting date in the sales invoice with the "Special Scheme Code" equals 14 and SII version equals 1.1bis

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Special Scheme Code" = "14", "Posting Date" = January 20, "Shipment Date" = January 25

        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesShipmentWithShipDate(SalesHeader, CustomerNo, LibraryRandom.RandDateFrom(WorkDate(), 10));
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true); // confirm change
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"14 Invoice Work Certification");
        SalesHeader.Modify(true);
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeaderNo);

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains January 26 (the day after posting date)
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(SalesHeader."Posting Date" + 1), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionAfterPostingDateDoesNotExistWhenSchemeCode01AndVersion11bis()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        ShipmentDate: Date;
        OldWorkDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 375398] FechaOperacion xml node does not exist when shipment date after the posting date for in the sales invoice with the "Special Scheme Code" equals 14 and SII version equals 1.1bis

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Special Scheme Code" = "01", "Posting Date" = January 20, "Shipment Date" = January 25
        CustomerNo := LibrarySales.CreateCustomerNo();
        ShipmentDate := LibraryRandom.RandDateFrom(WorkDate(), 10);
        OldWorkDate := WorkDate();
        WorkDate := ShipmentDate;
        CreateSalesShipmentWithShipDate(SalesHeader, CustomerNo, ShipmentDate);
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SalesInvoiceHeaderNo);

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag does not contain in the xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NoFechaOperacionWhenShptDateIsInDiffYearThanPostingDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 386538] If "Shipment Date" has different year than "Posting Date" of the Sales Invoice, then FechaOperacion tag is not present in the xml file

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 01.01.2021. " Shipment Date" is 31.12.2020
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), CalcDate('<-1Y>', SalesHeader."Posting Date"), 1);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type", LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag does not contain in the xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFechaOperacionWhenRcptDateIsInDiffYearThanPostingDate()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderForRcpt: Record "Purchase Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VendorNo: Code[20];
        PurchInvoiceHeaderNo: Code[20];
        RcptDate: Date;
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 386538] If "Receipt Date" has different year than "Posting Date" of the Purchase Invoice, then FechaOperacion tag is present in the xml file

        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Posting Date" = 01.01.2021, "Receipt Date" = 31.12.2020
        VendorNo := LibraryPurchase.CreateVendorNo();
        RcptDate := CalcDate('<-1Y>', WorkDate());
        CreatePurchRcptWithPostingDate(PurchaseHeaderForRcpt, VendorNo, RcptDate);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        GetRcptLines(PurchaseHeaderForRcpt, PurchaseHeader);
        PurchInvoiceHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvoiceHeaderNo);

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains 31.12.2020
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(RcptDate), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFeachaOperationWhenShptDateOfSeparateSphtIsInDiffYearThanPostingDate()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeaderForShip: Record "Sales Header";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        SalesInvoiceHeaderNo: Code[20];
        OldWorkDate: Date;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 386538] If "Shipment Date" of the separate shipment has different year than "Posting Date" of the Sales Invoice, then FechaOperacion tag is not present in the xml file

        Initialize();

        // [GIVEN] Posted Sales Shipment on 31.12.2020
        CustomerNo := LibrarySales.CreateCustomerNo();
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<-1Y>', WorkDate());
        CreateSalesShipmentWithShipDate(SalesHeaderForShip, CustomerNo, WorkDate());

        // [GIVEN] "Get Shipment Lines" action is called for Sales Invoice
        WorkDate := OldWorkDate;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        GetShipmentLines(SalesHeaderForShip, SalesHeader);

        // [GIVEN] Sales Invoice is posted on 01.01.2021
        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeaderNo);
        CustLedgerEntry.FindFirst();

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag does not contain in the xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithIDType6AndReverseChargeVATXML()
    var
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 389265] CuotaDeducible has non-zero amount for purchase invoice with "ID Type" equals 06 and Reverse charge VAT
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "ID Type" = 06, one Purchase Line where
        // [GIVEN] line is calculated as Reverse Charge VAT with Amount = "X"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::Invoice, CountryRegion.Code);
        PurchaseHeader.Validate("ID Type", PurchaseHeader."ID Type"::"06-Other Probative Document");
        PurchaseHeader.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [GIVEN] SII version is "2.1"
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:CuotaDeducible' has value = "X"
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:InversionSujetoPasivo', VATRate, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithIDType6AndReverseChargeVATXML()
    var
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 389265] CuotaDeducible has non-zero amount for purchase credit memo with "ID Type" equals 06 and Reverse charge VAT
        Initialize();

        // [GIVEN] Posted Purchase credit memo with "ID Type" = 06, one Purchase Line where
        // [GIVEN] line is calculated as Reverse Charge VAT with Amount = "X"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::"Credit Memo", CountryRegion.Code);
        PurchaseHeader.Validate("ID Type", PurchaseHeader."ID Type"::"06-Other Probative Document");
        PurchaseHeader.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [GIVEN] SII version is "2.1"
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:CuotaDeducible' has value = -"X"
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:InversionSujetoPasivo', VATRate, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithInvTypeF5AndReverseChargeVATXML()
    var
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 390731] Reverse Charge VAT Amount exports under the DesgloseIVA for the purchase invoice with invoice type "F5"
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = F5, one Purchase Line where
        // [GIVEN] line is calculated as Reverse Charge VAT with VAT Amount = "X"
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::Invoice, CountryRegion.Code);
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"F5 Imports (DUA)");
        PurchaseHeader.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));

        // [GIVEN] SII version is "2.1"
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] XML is generated
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:CuotaSoportada' under 'sii:DesgloseIVA" has value = "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(Round(VATRate * Amount / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionNextDateAfterPostingDateSalesCreditMemoWithSchemeCode14AndVersion11bis()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 391434] FechaOperacion xml node has value after the posting date
        // [SCENARIO 391434] in the sales credit memo with the "Special Scheme Code" equals 14 and SII version equals 1.1bis

        Initialize();

        // [GIVEN] Posted Sales Credit memo with "Special Scheme Code" = "14", "Posting Date" = January 20
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"14 Invoice Work Certification");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), WorkDate(), 1);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains January 20 (the day after posting date)
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(SalesHeader."Posting Date" + 1), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FechaOperacionNextDateAfterPostingDateSalesReturnOrderWithSchemeCode14AndVersion11bis()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeaderForReceipt: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
        CustomerNo: Code[20];
        OldWorkDate: Date;
    begin
        // [FEATURE] [Sales] [Receipt]
        // [SCENARIO 391434] FechaOperacion xml node has value after the posting date
        // [SCENARIO 391434] in the sales credit memo with receipt from return order with the "Special Scheme Code" equals 14 and SII version equals 1.1bis

        Initialize();

        // [GIVEN] Posted return order on 01.07.2017
        CustomerNo := LibrarySales.CreateCustomerNo();
        OldWorkDate := WorkDate();
        LibrarySales.CreateSalesHeader(SalesHeaderForReceipt, SalesHeaderForReceipt."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeaderForReceipt, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), WorkDate(), 1);
        LibrarySales.PostSalesDocument(SalesHeaderForReceipt, true, false);

        // [GIVEN] Sales invoice with "Posting Date" = 02.02.2017
        // [GIVEN] "Get Shipment Lines" action is called for Sales Invoice
        WorkDate := WorkDate() + 1;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"14 Invoice Work Certification");
        SalesHeader.Modify(true);
        GetReturnReceiptLines(SalesHeaderForReceipt, SalesHeader);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type", LibrarySales.PostSalesDocument(SalesHeader, false, true));

        // [GIVEN] SII Version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag contains 03.07.2017 (the date after the posting date of credit memo)
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(SalesHeader."Posting Date" + 1), 0);

        // Tear down
        WorkDate := OldWorkDate;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFechaOperacionNodeForSalesPrepaymentInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO 220565] A FechaOperacion xml node does not generate for the sales prepayment invoice

        Initialize();

        // [GIVEN] Sales Order with "Prepayment %"
        CreateSalesPrepaymentOrder(SalesHeader);

        // [GIVEN] Post prepayment invoice
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesPrepaymentInvoice(SalesHeader));

        // [WHEN] Generate xml file for the posted prepayment invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFechaOperacionNodeForSalesPrepaymentCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO 220565] A FechaOperacion xml node does not generate for the sales prepayment credit memo

        Initialize();

        // [GIVEN] Sales Order with "Prepayment %"
        CreateSalesPrepaymentOrder(SalesHeader);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Post prepayment credit memo
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.FindFirst();

        // [WHEN] Generate xml file for the posted prepayment credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFechaOperacionNodeForPurchPrepaymentInvoice()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO 220565] A FechaOperacion xml node does not generate for the purchase prepayment invoice

        Initialize();

        // [GIVEN] Purchase Order with "Prepayment %"
        CreatePurchPrepaymentOrder(PurchaseHeader);

        // [GIVEN] Post prepayment invoice
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader));

        // [WHEN] Generate xml file for the posted prepayment invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoFechaOperacionNodeForPurchPrepaymentCrMemo()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO 220565] A FechaOperacion xml node does not generate for the sales purchase credit memo

        Initialize();

        // [GIVEN] Purchase Order with "Prepayment %"
        CreatePurchPrepaymentOrder(PurchaseHeader);

        // [GIVEN] Post prepayment invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [GIVEN] Post prepayment credit memo
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchaseHeader);
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        VendorLedgerEntry.FindFirst();

        // [WHEN] Generate xml file for the posted prepayment credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    procedure SalesNoFechaOperacionWhenPostingDateEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO 43303] No FechaOperacion xml node generates when the posting date equals the document date in the sales journal and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales invoice journal line
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Posted journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Generate xml file for the posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    procedure PurchNoFechaOperacionWhenPostingDateEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Purchase] [Invoice]
        // [SCENARIO 43303] No FechaOperacion xml node generates when the posting date equals the document date in the purchase journal and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Purchase invoice journal line
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Posted journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Generate xml file for the posted purchase invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    procedure SalesJnlFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO 43303] FechaOperacion xml node generates when the posting date is not equal the document date in the sales journal and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales invoice journal line with "Posting Date" = "X", "Document Date" = "Y"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Document Date", GenJournalLine."Posting Date" + 1);
        GenJournalLine.Modify(true);

        // [GIVEN] Posted journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Generate xml file for the posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(GenJournalLine."Document Date"), 0);
    end;

    [Test]
    procedure SalesJnlFechaOperacionWhenPostingDateNotEqualVATDateWithVATDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Sales] [Invoice]
        // [SCENARIO 448682] FechaOperacion xml node generates when the posting date is not equal the VAT date in the sales journal and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "VAT Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"VAT Reporting Date");

        // [GIVEN] Sales invoice journal line with "Posting Date" = "X", "VAT Date" = "Y"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("VAT Reporting Date", GenJournalLine."Posting Date" + 1);
        GenJournalLine.Modify(true);

        // [GIVEN] Posted journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Generate xml file for the posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(GenJournalLine."VAT Reporting Date"), 0);
    end;

    [Test]
    procedure PurchJnlFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Journal] [Purchase] [Invoice]
        // [SCENARIO 43303] FechaOperacion xml node generates when the posting date is not equal the document date in the purchase journal and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Purchase invoice journal line with "Posting Date" = "X", "Document Date" = "Y"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Document Date", GenJournalLine."Posting Date" + 1);
        GenJournalLine.Modify(true);

        // [GIVEN] Posted journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");

        // [WHEN] Generate xml file for the posted purchase invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(GenJournalLine."Document Date"), 0);
    end;

    [Test]
    procedure SalesInvFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 43303] FechaOperacion xml node generates when the posting date is not equal the document date in the sales invoice and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales invoice with "Posting Date" = "X", "Document Date" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Document Date", SalesHeader."Posting Date" + 1);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(CustLedgerEntry."Document Date"), 0);
    end;

    [Test]
    procedure SalesCrMemoFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 43303] FechaOperacion xml node generates when the posting date is not equal the document date in the sales cr. memo and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales credit memo with "Posting Date" = "X", "Document Date" = "Y"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Document Date", SalesHeader."Posting Date" + 1);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo",
          LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(CustLedgerEntry."Document Date"), 0);
    end;

    [Test]
    procedure PurchInvFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 43303] FechaOperacion xml node generates when the posting date is not equal the document date in the purchase invoice and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales invoice with "Posting Date" = "X", "Document Date" = "Y"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Document Date", PurchaseHeader."Posting Date" + 1);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion xml node contains "Y"
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:FechaOperacion', SIIXMLCreator.FormatDate(VendorLedgerEntry."Document Date"), 0);
    end;

    [Test]
    procedure PurchCrMemoFechaOperacionWhenPostingDateNotEqualDocDateWithDocDateOptionEnabled()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 43303] No FechaOperacion xml node generates when the posting date is not equal the document date in the purchase credit memo and the "Document Date" option enables for the "Operation Date"

        Initialize();

        // [GIVEN] Set "Document Date" option for "Operation Date" in the SII Setup
        SetOperationDateInSIISetup(SIISetup."Operation Date"::"Document Date");

        // [GIVEN] Sales invoice with "Posting Date" = "X", "Document Date" = "Y"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Document Date", PurchaseHeader."Posting Date" + 1);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] FechaOperacion tag is not included in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:FechaOperacion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInSalesInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Sales Invoice

        Initialize();
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, 'ES', 'B80833593');

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo := CreateAndPostSalesDocWithVATReportingDate(SalesHeader."Document Type"::Invoice, Customer."No.", WorkDate(), WorkDate() + 1, 0);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CustLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CustLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInSalesCrMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Sales Credit Memo

        Initialize();
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, 'ES', 'B80833593');

        // [GIVEN] Posted Sales Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo := CreateAndPostSalesDocWithVATReportingDate(SalesHeader."Document Type"::"Credit Memo", Customer."No.", WorkDate(), WorkDate() + 1, 0);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CustLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CustLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInSalesReplacementCrMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Replacement Sales Credit Memo

        Initialize();
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, 'ES', 'B80833593');

        // [GIVEN] Posted Replacement Sales Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo :=
            CreateAndPostSalesDocWithVATReportingDate(
                SalesHeader."Document Type"::"Credit Memo", Customer."No.", WorkDate(), WorkDate() + 1, SalesHeader."Correction Type"::Replacement);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CustLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CustLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInSalesRemovalCrMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Removal Sales Credit Memo

        Initialize();
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, 'ES', 'B80833593');

        // [GIVEN] Posted Removal Sales Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo :=
            CreateAndPostSalesDocWithVATReportingDate(
                SalesHeader."Document Type"::"Credit Memo", Customer."No.", WorkDate(), WorkDate() + 1, SalesHeader."Correction Type"::Removal);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CustLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(CustLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInPurchaseInvoice()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Purchase Invoice

        Initialize();
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');

        // [GIVEN] Posted Purchase Invoice with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo := CreateAndPostPurchaseDocWithVATReportingDate(PurchaseHeader."Document Type"::Invoice, Vendor."No.", WorkDate(), WorkDate() + 1, 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(VendorLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(VendorLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInPurchaseCrMemo()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Purchase Credit Memo

        Initialize();
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');

        // [GIVEN] Posted Purchase Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo := CreateAndPostPurchaseDocWithVATReportingDate(PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", WorkDate(), WorkDate() + 1, 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(VendorLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(VendorLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInPurchaseReplacementCrMemo()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Replacement Purchase Credit Memo

        Initialize();
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');

        // [GIVEN] Posted Replacement Purchase Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo :=
            CreateAndPostPurchaseDocWithVATReportingDate(
                PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", WorkDate(), WorkDate() + 1, PurchaseHeader."Correction Type"::Replacement);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(VendorLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(VendorLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateXMLNodesContainsVATReportingDateInPurchaseRemovalCrMemo()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        InvNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 478371] Ejercicio and Periodo XML nodes contain the VAT Reporting Date in the Removal Purchase Credit Memo

        Initialize();
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, 'ES', 'B80833593');

        // [GIVEN] Posted Removal Purchase Credit Memo with "Posting Date" = 05.01.2017 and "VAT Reporting Date" = 06.01.2017
        InvNo :=
            CreateAndPostPurchaseDocWithVATReportingDate(
                PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", WorkDate(), WorkDate() + 1, PurchaseHeader."Correction Type"::Removal);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Create xml file for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file generated with year and month equals 06.01.2017
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(VendorLedgerEntry."VAT Reporting Date", 3)), 0);
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:Periodo', Format(VendorLedgerEntry."VAT Reporting Date", 0, '<Month,2>'), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleConfirmYes')]
    procedure PostedPurchaseInvoiceExportsXMLWithoutCodigoPaisElementForXICountryRegion()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CountryRegion: Record "Country/Region";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 494864] Posted Purchase Invoice XML file is exported without CodigoPais element for XI Country Region Vendor having blank ISO Code.
        Initialize();

        // [GIVEN] Create Vendor with ES Country Region and Vat Registration No.
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, ESLbl, VatRegistrationNoLbl);

        // [GIVEN] Create Vendor 2 with XI Country Region.
        CreateVendorWithXICountryRegion(Vendor2, CountryRegion);

        // [GIVEN] Create and post Purchase Invoice and find Purchase Invoice Header.
        PurchInvHeader.Get(
            LibrarySII.CreatePurchDocumentWithDiffPayToVendor(
                true,
                Vendor2."No.",
                Vendor."No.",
                GlobalCreditMemoType::" ",
                true));

        // [GIVEN] Find Vendor Ledger Entry.
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();

        // [GIVEN] Create XML file for Posted Purchase Invoice.
        Assert.IsTrue(
            SIIXMLCreator.GenerateXml(
                VendorLedgerEntry,
                XMLDoc,
                UploadType::Regular,
                false),
            IncorrectXMLDocErr);

        // [WHEN] Validate CodigoPais element for XI Country Region Code.
        asserterror LibrarySII.ValidateElementByNameAt(XMLDoc, SIICodigoPaisLbl, XILbl, 0);

        // [VERIFY] Verify XML file is without CodigoPais element.
        Assert.AreEqual(DotNetVariableNotInstantiatedErr, GetLastErrorText(), ErrorTextMustMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleConfirmYes')]
    procedure PostedSalesInvoiceExportsXMLWithoutCodigoPaisElementForXICountryRegion()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        CountryRegion: Record "Country/Region";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 494864] Posted Sales Invoice XML file is exported without CodigoPais element for XI Country Region Vendor having blank ISO Code.
        Initialize();

        // [GIVEN] Create Customer with ES Country Region and Vat Registration No.
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, ESLbl, VatRegistrationNoLbl);

        // [GIVEN] Create Customer 2 with XI Country Region.
        CreateCustomerWithXICountryRegion(Customer2, CountryRegion);

        // [GIVEN] Create and post Sales Invoice and find Sales Invoice Header.
        SalesInvHeader.Get(
            CreateSalesDocumentWithDiffBillToCust(
                true,
                false,
                GlobalCreditMemoType::" ",
                Customer."No.",
                Customer2."No.",
                true));

        // [GIVEN] Find Customer Ledger Entry.
        CustomerLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
        CustomerLedgerEntry.FindFirst();

        // [GIVEN] Create XML file for Posted Sales Invoice.
        Assert.IsTrue(
            SIIXMLCreator.GenerateXml(
                CustomerLedgerEntry,
                XMLDoc,
                UploadType::Regular,
                false),
            IncorrectXMLDocErr);

        // [WHEN] Validate CodigoPais element for XI Country Region Code.
        asserterror LibrarySII.ValidateElementByNameAt(XMLDoc, SIICodigoPaisLbl, XILbl, 0);

        // [VERIFY] Verify XML file is without CodigoPais element.
        Assert.AreEqual(DotNetVariableNotInstantiatedErr, GetLastErrorText(), ErrorTextMustMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesXmlWhenVATCashRegimeEnabledAndInvoiceWithSpecialCash()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        PostedSalesInvoiceNo: Code[20];
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO: 536255] The Special Scheme Code used in the Request XML submitted via SII History is wrong in case you use Unrealized VAT without VAT Cash in the Spanish version.
        Initialize();

        // [GIVEN] Update G/L Setup, Create Customer with VAT Posting Setup
        UpdateVATCashRegimeOnGLSetup(true);
        LibrarySales.CreateCustomer(Customer);
        CreateVATPostingSetupVATCashRegime(VATPostingSetup, Customer."VAT Bus. Posting Group", 21);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Last);
        VATPostingSetup.Modify(true);

        // [WHEN] Create and Post Sales Invoice for a local customer
        PostedSalesInvoiceNo := CreateAndPostSalesInvoiceWithItem(Customer, VATPostingSetup, 1, 1000);
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Verify the Special Scheme Code is 07
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesXmlAndValidateImporteTotalWithSpecialSchemeCode09TravelAgencyServices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        PostedSalesInvoiceNo: Code[20];
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 536602] "Si la ClaveRegimenEspecialOTrascendencia o alguna ClaveRegimenEspecialOTrascendenciaAdicional tienen un valor
        // 03, 05 o 09 el campo ImporteTotal debe estar informado" error if we submit so SII a document with Special Scheme Code 09
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Create and Post Sales Invoice for a local customer
        PostedSalesInvoiceNo := CreateAndPostSalesInvoiceWithItemWithTravelAgencyServices(Customer, 1, 1000);
        SalesInvoiceHeader.Get(PostedSalesInvoiceNo);
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();

        // [WHEN] We create the xml to be transmitted for that transaction
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Verify ImporteTotal is available in XML for 09 Travel Agency Services
        CustLedgerEntry.CalcFields("Original Amt. (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Original Amt. (LCY)"));
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        Clear(SIIXMLCreator);
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"SII Setup");

        IsInitialized := true;
    end;

    local procedure CreateNoSeriesWithStartingNo(StartingNo: Code[20]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, '');
        exit(NoSeries.Code);
    end;

    local procedure ModifyNoSeriesOnSalesSetupForPostedCrMemoAndInv(PostedInvNosCode: Code[20]; PostedCrMemoNosCode: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Posted Invoice Nos.", PostedInvNosCode);
        SalesReceivablesSetup.Validate("Posted Credit Memo Nos.", PostedCrMemoNosCode);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ModifyNoSeriesOnServSetupForPostedCrMemoAndInv(PostedInvNosCode: Code[20]; PostedCrMemoNosCode: Code[20])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", PostedInvNosCode);
        ServiceMgtSetup.Validate("Posted Serv. Credit Memo Nos.", PostedCrMemoNosCode);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure FindCustLedgerEntryByDocTypeAndCustNo(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; CustNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Document Type", DocType);
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure GetVATTotalAmountExceptRevChargeAmount(VendorLedgerEntry: Record "Vendor Ledger Entry") TotalAmount: Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VATEntry.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.CalcSums(Base, Amount);
        TotalAmount += VATEntry.Base + VATEntry.Amount;
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        VATEntry.CalcSums(Base);
        TotalAmount += VATEntry.Base;
        exit(TotalAmount);
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomerNoSII(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, CreateCountryRegionCode(), 'B80833593');
        exit(Customer."No.");
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; CustNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustNo);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure ModifyServiceHeaderCorrectedInvoiceNo(var ServiceHeader: Record "Service Header"; CorrectedInvoiceNo: Code[20])
    begin
        ServiceHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(IsInvoice: Boolean; IsExempt: Boolean; CustomerCountryCode: Code[10]; CreditMemoType: Option " ",Replacement,Difference,Removal; AddCorrectedInvoiceNo: Boolean): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, CustomerCountryCode, 'B80833593');

        exit(CreateSalesDocumentWithDiffBillToCust(
            IsInvoice, IsExempt, CreditMemoType, Customer."No.", Customer."No.", AddCorrectedInvoiceNo));
    end;

    local procedure CreateSalesDocumentWithDiffBillToCust(IsInvoice: Boolean; IsExempt: Boolean; CreditMemoType: Option " ",Replacement,Difference,Removal; SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; AddCorrectedInvoiceNo: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        if IsExempt then begin
            LibraryInventory.CreateItem(Item);
            Item."VAT Prod. Posting Group" := 'NO VAT';
            Item.Modify(true);
            exit(CreateAndPostSalesInvoice(SellToCustomerNo, BillToCustomerNo, Item."No."));
        end;

        if IsInvoice then
            exit(CreateAndPostSalesInvoice(SellToCustomerNo, BillToCustomerNo, LibraryInventory.CreateItemNo()));

        LibraryInventory.CreateItem(Item);
        exit(LibrarySII.CreateAndPostSalesCrMemo(SellToCustomerNo, CreditMemoType, Item."No.", AddCorrectedInvoiceNo));
    end;

    local procedure CreateAndPostSalesInvoice(SellToCustomerNo: Code[20]; BillToCustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(SalesHeaderInvoice, SalesLine,
          SalesHeaderInvoice."Document Type"::Invoice, SellToCustomerNo,
          ItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        SalesHeaderInvoice.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeaderInvoice.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, false));
    end;

    local procedure CreateAndPostSalesDocWithDate(DocType: Enum "Sales Document Type"; CustNo: Code[20]; PostingDate: Date; InvNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Corrected Invoice No.", InvNo);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostSalesDocWithVATReportingDate(DocType: Enum "Sales Document Type"; CustNo: Code[20]; PostingDate: Date; VATReportingDate: Date; CorrectionType: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("VAT Reporting Date", VATReportingDate);
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostPurchaseDocWithVATReportingDate(DocType: Enum "Sales Document Type"; VendNo: Code[20]; PostingDate: Date; VATReportingDate: Date; CorrectionType: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("VAT Reporting Date", VATReportingDate);
        PurchaseHeader.Validate("Correction Type", CorrectionType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        DummySalesHeader: Record "Sales Header";
    begin
        exit(CreateAndPostSalesDocWithDate(DummySalesHeader."Document Type"::Invoice, CustomerNo, WorkDate(), ''));
    end;

    local procedure CreateSalesPrepaymentOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), WorkDate(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDocument(IsInvoice: Boolean; VendorCountryCode: Code[10]; CreditMemoType: Option " ",Replacement,Difference,Removal; AddCorrectedInvoiceNo: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibrarySII.CreateVendWithCountryAndVATReg(Vendor, VendorCountryCode, 'B80833593');
        exit(
          LibrarySII.CreatePurchDocumentWithDiffPayToVendor(IsInvoice, Vendor."No.", Vendor."No.", CreditMemoType, AddCorrectedInvoiceNo));
    end;

    local procedure CreateAndPostPurchDocWithDate(DocType: Enum "Purchase Document Type"; VendNo: Code[20]; PostingDate: Date; InvNo: Code[20]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, VendNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Corrected Invoice No.", InvNo);
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, false, false));
    end;

    local procedure CreateSalesShipmentWithShipDate(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), ShipDate, 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePartialSalesOrderWithDiffShptDates(var SalesHeader: Record "Sales Header"; var ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), WorkDate() - 1, 1);
        ShipmentDate := SalesLine."Shipment Date";
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), WorkDate() - LibraryRandom.RandIntInRange(3, 5), 1);
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchRcptWithPostingDate(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; RcptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Posting Date", RcptDate);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesLineWithNewProductGroupAndSpecificSign(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Sign: Integer; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), Sign);
        SalesLine.Validate("VAT Prod. Posting Group",
          CreateVATProductGroupConsistentWithVATBusPostingGroup(SalesHeader."VAT Bus. Posting Group"));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLineWithNewProductGroupAndSpecificSign(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Sign: Integer; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), Sign);
        PurchaseLine.Validate("VAT Prod. Posting Group",
          CreateVATProductGroupConsistentWithVATBusPostingGroup(PurchaseHeader."VAT Bus. Posting Group"));
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchPrepaymentOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandInt(50));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATProductGroupConsistentWithVATBusPostingGroup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Validate(
          "VAT Identifier", CopyStr('VAT' + Format(VATPostingSetup."VAT %"), 1, MaxStrLen(VATPostingSetup."VAT Identifier")));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateCustWithCountryAndVATReg(Country: Code[10]; VATRegNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, Country, VATRegNo);
        exit(Customer."No.");
    end;

    local procedure DisableCashBased(VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        VATPostingSetup.Delete();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", false);
        GeneralLedgerSetup.Modify(true);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", false);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GetRcptLines(PurchaseHeaderFrom: Record "Purchase Header"; PurchaseHeaderTo: Record "Purchase Header")
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderFrom."No.");
        PurchRcptHeader.FindFirst();
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderTo);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetShipmentLines(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeaderFrom."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShipment.SetSalesHeader(SalesHeaderTo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetReturnReceiptLines(SalesHeaderFrom: Record "Sales Header"; SalesHeaderTo: Record "Sales Header")
    var
        ReturnRcptHeader: Record "Return Receipt Header";
        ReturnRcptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        ReturnRcptHeader.SetRange("Return Order No.", SalesHeaderFrom."No.");
        ReturnRcptHeader.FindFirst();
        ReturnRcptLine.SetRange("Document No.", ReturnRcptHeader."No.");
        SalesGetReturnReceipts.SetSalesHeader(SalesHeaderTo);
        SalesGetReturnReceipts.CreateInvLines(ReturnRcptLine);
    end;

    local procedure SetOperationDateInSIISetup(OperationDate: Enum "SII Operation Date Type")
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("Operation Date", OperationDate);
        SIISetup.Modify(true);
    end;

    local procedure PostPurchDocWithMultiplesLinesDiffVAT(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrectionType: Option)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        i: Integer;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);

        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, VendNo);
        PurchHeader.Validate("Document Date", PurchHeader."Posting Date" - 1);
        PurchHeader.Validate("Correction Type", CorrectionType);
        PurchHeader.Modify(true);
        for i := 1 to 2 do
            LibrarySII.CreatePurchLineWithUnitCost(
              PurchHeader, LibrarySII.CreateItemWithSpecificVATSetup(VATBusinessPostingGroup.Code, LibraryRandom.RandIntInRange(10, 25)));

        VendLedgEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchHeader, false, false));
    end;

    local procedure PostSalesInvWithMultiplesLinesDiffVATGroupSameRate(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATPct: Decimal;
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // Create three lines, all with different VAT Prod. Posting Groups but 1st and 3rd have same "VAT %"
        VATPct := LibraryRandom.RandIntInRange(10, 25);
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", VATPct));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group",
            VATPct + LibraryRandom.RandIntInRange(10, 25)));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", VATPct));

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostPurchInvWithMultiplesLinesDiffVATGroupSameRate(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        VATPct: Decimal;
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        PurchHeader.Validate("Document Date", PurchHeader."Posting Date" - 1);
        PurchHeader.Modify(true);
        // Create three lines, all with different VAT Prod. Posting Groups but 1st and 3rd have same "VAT %"
        VATPct := LibraryRandom.RandIntInRange(10, 25);
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchHeader, LibrarySII.CreateItemWithSpecificVATSetup(VATBusinessPostingGroup.Code, VATPct));
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchHeader, LibrarySII.CreateItemWithSpecificVATSetup(VATBusinessPostingGroup.Code,
            VATPct + LibraryRandom.RandIntInRange(10, 25)));
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchHeader, LibrarySII.CreateItemWithSpecificVATSetup(VATBusinessPostingGroup.Code, VATPct));

        VendLedgEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchHeader, false, false));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandleConfirmYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleRecallNotification(var NotificationToRecall: Notification): Boolean
    begin
    end;

    local procedure CreatePurchDocWithNormalAndReverseChargeVAT(var PurchaseHeader: Record "Purchase Header"; var VATRate: Decimal; var VATRateReverseCharge: Decimal; var Amount: Decimal; var AmountReverse: Decimal; DocType: Enum "Purchase Document Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchHeaderWithSetup(PurchaseHeader, VATBusinessPostingGroup, DocType, CountryRegion.Code);
        PurchaseHeader.Validate("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"03 Special System"); // in order to have ImporteTotal node in the XML doc
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, Amount, PurchaseHeader, VATBusinessPostingGroup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySII.CreatePurchLineWithSetup(
          VATRateReverseCharge, AmountReverse, PurchaseHeader, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    local procedure CreatePurchInvWithNormalVAT(var PurchaseHeader: Record "Purchase Header"; var VATRate: Decimal; var Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchHeaderWithSetup(
          PurchaseHeader, VATBusinessPostingGroup, PurchaseHeader."Document Type"::Invoice, CountryRegion.Code);
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, Amount, PurchaseHeader, VATBusinessPostingGroup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure VerifyXMLStructureCorrDoc(var XMLDoc: DotNet XmlDocument)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('sii:TipoDesglose');
        XMLNode := XMLNodeList.Item(0).ChildNodes.Item(0);
        Assert.AreEqual('sii:DesgloseFactura', XMLNode.Name, 'sii:DesgloseFactura not found');
        XMLNode := XMLNode.ChildNodes.Item(0);
        Assert.AreEqual('sii:Sujeta', XMLNode.Name, 'sii:Sujeta not found');
    end;

    local procedure VerifyFacturasRectificadasNode(XMLDoc: DotNet XmlDocument; BasePath: Text; DocNo: Code[35]; PostingDate: Date)
    begin
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BasePath, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:NumSerieFacturaEmisor', DocNo);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BasePath, 'sii:FacturasRectificadas/sii:IDFacturaRectificada/sii:FechaExpedicionFacturaEmisor',
          SIIXMLCreator.FormatDate(PostingDate));
    end;

    local procedure VerifyFechaRegContableIsRequestDateOfSIIHistory(VendorLedgerEntry: Record "Vendor Ledger Entry"; XMLDoc: DotNet XmlDocument)
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        SIIHistory: Record "SII History";
    begin
        SIIDocUploadState.GetSIIDocUploadStateByVendLedgEntry(VendorLedgerEntry);
        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:FechaRegContable', SIIXMLCreator.FormatDate(DT2Date(SIIHistory."Request Date")));
    end;

    local procedure VerifySIIMgtIsDomesticCustomer(Country: Code[10]; VATRegNo: Code[20]; ExpectedResult: Boolean)
    var
        Customer: Record Customer;
        SIIMgt: Codeunit "SII Management";
    begin
        Customer.Init();
        Customer."Country/Region Code" := Country;
        Customer."VAT Registration No." := VATRegNo;
        Assert.AreEqual(ExpectedResult, SIIMgt.IsDomesticCustomer(Customer), 'SIIMgt.IsDomesticCustomer()');
    end;

    local procedure CreateVendorWithXICountryRegion(var Vendor: Record Vendor; var CountryRegion: Record "Country/Region")
    begin
        if not CountryRegion.Get(XILbl) then begin
            CountryRegion.Init();
            CountryRegion.Validate(Code, XILbl);
            CountryRegion.Insert(true);
        end;

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithXICountryRegion(var Customer: Record Customer; var CountryRegion: Record "Country/Region")
    begin
        if not CountryRegion.Get(XILbl) then begin
            CountryRegion.Init();
            CountryRegion.Validate(Code, XILbl);
            CountryRegion.Insert(true);
        end;

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    local procedure UpdateVATCashRegimeOnGLSetup(VATCashRegime: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", VATCashRegime);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceWithItem(var Customer: Record Customer; var VATPostingSetup: Record "VAT Posting Setup"; LineQuantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"07 Special Cash");
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateVATPostingSetupVATCashRegime(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoiceWithItemWithTravelAgencyServices(var Customer: Record Customer; LineQuantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"09 Travel Agency Services");
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LineQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text)
    begin
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(Question, LibraryVariableStorage.DequeueText());
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}
