codeunit 147557 "SII Invoice Amount Treshold"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII]
    end;

    var
        LibrarySII: Codeunit "Library - SII";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathPurchTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        IsInitialized: Boolean;
        XPathSalesTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted sales invoice is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales invoice with amount = 90,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, SalesHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted sales invoice is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales invoice with amount = 110,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, SalesHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMacrodatoNodeDoesNotExistIfInvoiceTypeIsF1()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node does not exist for sales invoice with "Invoice Type" = "F1 Invoice"

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales invoice with "Invoice Type" = "F1 Invoice" and amount = 110,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, SalesHeader."Invoice Type"::"F1 Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node does not exist
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Macrodato', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted sales credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales credit memo with amount = 90,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted sales credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales credit memo with amount = 110,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted sales replacement credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales replacement credit memo with amount = 90,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Invoice Type"::"F2 Simplified Invoice",
          SalesHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted sales replacement credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales replacement credit memo with amount = 110,000
        PostSalesDoc(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Invoice Type"::"F2 Simplified Invoice",
          SalesHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted purchase invoice is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted purchase invoice with amount = 90,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted purchase invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted invoice is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales invoice with amount = 110,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceMacrodatoNodeDoesNotExistIfInvoiceTypeIsF1()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node does not exist for invoice with "Invoice Type" = "F1 Invoice"

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales invoice with "Invoice Type" = "F1 Invoice" and amount = 110,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Invoice Type"::"F1 Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node does not exist
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Macrodato', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales credit memo with amount = 90,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales credit memo with amount = 110,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Invoice Type"::"F2 Simplified Invoice", 0,
          SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted replacement credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales replacement credit memo with amount = 90,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice",
          PurchaseHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" / 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted replacement credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted sales replacement credit memo with amount = 110,000
        PostPurchDoc(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Invoice Type"::"F2 Simplified Invoice",
          PurchaseHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" * 3);

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvoiceMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted service invoice is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service invoice with amount = 90,000
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            0, SIISetup."Invoice Amount Threshold" / 3));

        // [WHEN] Export posted service invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvoiceMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted service invoice is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service invoice with amount = 110,000
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            0, SIISetup."Invoice Amount Threshold" * 3));

        // [WHEN] Export posted service invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvoiceMacrodatoNodeDoesNotExistIfInvoiceTypeIsF1()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node does not exist for service invoice with "Invoice Type" = "F1 Invoice"

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service invoice with "Invoice Type" = "F1 Invoice" and amount = 110,000
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::Invoice, ServiceHeader."Invoice Type"::"F1 Invoice",
            0, SIISetup."Invoice Amount Threshold" / 3));

        // [WHEN] Export posted service invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node does not exist
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Macrodato', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted service credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service credit memo with amount = 90,000
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            0, SIISetup."Invoice Amount Threshold" / 3));

        // [WHEN] Export posted service credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted service credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service credit memo with amount = 110,000
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            0, SIISetup."Invoice Amount Threshold" * 3));

        // [WHEN] Export posted service credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementServCrMemoMacrodatoNodeAmountLessThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "N" if amount of posted service replacement credit memo is less than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service replacement credit memo with amount = 90,000
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            ServiceHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" / 3));

        // [WHEN] Export posted service credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "N"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'N');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementServCrMemoMacrodatoNodeAmountGreaterThanTreshold()
    var
        SIISetup: Record "SII Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 263060] Macrodate node has value "y" if amount of posted service replacement credit memo is greater than "Invoice Amount Treshold" of SII Setup

        Initialize();

        // [GIVEN] "Invoice Amount Treshold" is 100,000 in SII Setup
        SIISetup.Get();

        // [GIVEN] Posted service replacement credit memo with amount = 110,000
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDoc(
            ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Invoice Type"::"F2 Simplified Invoice",
            ServiceHeader."Correction Type"::Replacement, SIISetup."Invoice Amount Threshold" * 3));

        // [WHEN] Export posted service credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Macrodato node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesTok, 'sii:Macrodato', 'S');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAmountThresholdIs100MillionInSIISetup()
    var
        SIISetup: Record "SII Setup";
    begin
        // [FEATURE] [DEMO]
        // [SCENARIO 391659] "Invoice Amount Threshold" is 100.000.000 in SII Setup

        Initialize();
        SIISetup.DeleteAll();
        SIISetup.Insert();
        SIISetup.TestField("Invoice Amount Threshold", 100000000);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        IsInitialized := true;
    end;

    local procedure PostSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; InvoiceType: Enum "SII Sales Invoice Type"; CorrectonType: Option; Amount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", InvoiceType);
        SalesHeader.Validate("Correction Type", CorrectonType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType,
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; InvoiceType: Enum "SII Purch. Invoice Type"; CorrectonType: Option; Amount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Invoice Type", InvoiceType);
        PurchaseHeader.Validate("Correction Type", CorrectonType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, DocType,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServDoc(DocType: Enum "Service Document Type"; InvoiceType: Enum "SII Sales Invoice Type"; CorrectonType: Option; Amount: Decimal): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, LibrarySales.CreateCustomerNo(), '');
        ServiceHeader.Validate("Invoice Type", InvoiceType);
        ServiceHeader.Validate("Correction Type", CorrectonType);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemWithSpecificVATSetup(ServiceHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          1);
        ServiceLine.Validate("Unit Price", Amount);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;
}

