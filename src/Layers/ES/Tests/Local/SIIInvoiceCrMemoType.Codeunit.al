codeunit 147551 "SII Invoice/Cr. Memo Type"
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:Entrega/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        UploadType: Option Regular,Intracommunity,RetryAccepted;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvTypeF2HasNoContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 223508] XML has no node "Contraparte" when post Sales Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [SCENARIO 234067] XML has node "ImporteTotal" when post Sales Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [SCENARIO 252872] XML has node "ImporteTotal" with positive value

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [GIVEN] Customer Ledger Entry Created with Amount = 120
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0, SalesHeader."Invoice Type"::"F2 Simplified Invoice",
          "SII Sales Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has no node "Contraparte"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has node "ImporteTotal" with value 120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvTypeF3HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        // [SCENARIO 234067] XML has no node "ImporteTotal" when post Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0,
          SalesHeader."Invoice Type"::"F3 Invoice issued to replace simplified invoices",
          "SII Sales Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "ImporteTotal"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvTypeF4HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Invoice with "Invoice Type" = "F4 Invoice summary entry"
        // [SCENARIO 234067] XML has node "ImporteTotal" when post Sales Invoice with "Invoice Type" = "F4 Invoice summary entry"
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Invoice Type" = "F4 Invoice summary entry"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0,
          SalesHeader."Invoice Type"::"F4 Invoice summary entry", "SII Sales Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has node "ImporteTotal"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'F4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithCrMemoTypeR2HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Difference" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 252872] XML has node "ImporteTotal" with negative value

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Difference" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [GIVEN] Customer Ledger Entry Created with Amount = -120

        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "ImporteTotal" with value -120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithCrMemoTypeR3HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Difference" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Difference" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithCrMemoTypeR4HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Difference" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Difference" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementWithCrMemoTypeR2HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 252872] XML has node "ImporteTotal" with negative value

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Replacement" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [GIVEN] Customer Ledger Entry Created with Amount = -120
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has node "ImporteTotal" with value -120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementWithCrMemoTypeR3HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Replacement" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementWithCrMemoTypeR4HasContraparteBlock()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Sales Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo type "Replacement" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"R4 Corrected Invoice (Other)");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInvTypeF2HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [SCENARIO 234067] XML has node "ImporteTotal" when post Purchase Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [SCENARIO 252872] XML has node "ImporteTotal" with positive value

        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "F2 Simplified Invoice"
        // [GIVEN] Vendor Ledger Entry Created with Amount = 120
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0,
          "SII Purch. Invoice Type"::"F2 Simplified Invoice", "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has node "ImporteTotal" with value 120
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInvTypeF3HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        // [SCENARIO 234067] XML has no node "ImporteTotal" when post Purchase Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "F3 Invoice issued to replace simplified invoices"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0,
          "SII Purch. Invoice Type"::"F3 Invoice issued to replace simplified invoices",
          "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "ImporteTotal"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInvTypeF4HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Invoice with "Invoice Type" = "F4 Invoice summary entry"
        // [SCENARIO 234067] XML has node "ImporteTotal" when post Purchase Invoice with "Invoice Type" = "F4 Invoice summary entry"
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "F4 Invoice summary entry"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0, PurchaseHeader."Invoice Type"::"F4 Invoice summary entry",
          "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has node "ImporteTotal"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:ImporteTotal');

        // [THEN] TipoFactura is "F4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInvTypeF5HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Invoice with "Invoice Type" = "F5 Imports (DUA)"
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "F5 Imports (DUA)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0, PurchaseHeader."Invoice Type"::"F5 Imports (DUA)",
          "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "F4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F5');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithInvTypeF6HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 269099] XML has node "Contraparte" when post Purchase Invoice with "Invoice Type" = "F6 Accounting support material"
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "F5 Imports (DUA)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0,
          PurchaseHeader."Invoice Type"::"F6 Accounting support material", "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "F4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'F6');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDiffCrMemoWithCrMemoTypeR2HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Difference" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 252872] XML has node "ImporteTotal" with negative value

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Difference" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [GIVEN] Vendor Ledger Entry Created with Amount = -120
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Difference,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] XML file has node "ImporteTotal" with value -120
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDiffCrMemoWithCrMemoTypeR3HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Difference" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Difference" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Difference,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDiffCrMemoWithCrMemoTypeR4HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Difference" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Difference" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Difference,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R4 Corrected Invoice (Other)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementWithCrMemoTypeR2HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [SCENARIO 252872] XML has node "ImporteTotal" with negative value
        // [SCENARIO 256251] Sales Credit Memo with type "Replacement" has positive values for VAT

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Replacement" and "Cr. Memo Type" = "R2 Corrected Invoice (Art. 80.3)"
        // [GIVEN] Vendor Ledger Entry Created with Amount = -120
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R2 Corrected Invoice (Art. 80.3)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R2');

        // [THEN] XML file has node "ImporteTotal" with value 120
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementWithCrMemoTypeR3HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Replacement" and "Cr. Memo Type" = "R3 Corrected Invoice (Art. 80.4)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R3 Corrected Invoice (Art. 80.4)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R3" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R3');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementWithCrMemoTypeR4HasContraparteBlock()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223508] XML has node "Contraparte" when post Purchase Credit Memo with Type "Replacement" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo type "Replacement" and "Cr. Memo Type" = "R4 Corrected Invoice (Other)"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement,
          "SII Purch. Invoice Type"::"F1 Invoice", "SII Purch. Credit Memo Type"::"R4 Corrected Invoice (Other)");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] TipoFactura is "R4" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'R4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TipoFacturaLCsForPurchInvoiceWithCustomsComplementaryLiquidationInvType()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 263060] TipoFactura is 'LC' for Purchase invoice with invoice type "Customs - Complementary Liquidation"

        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Invoice Type" = "Customs - Complementary Liquidation"
        PostPurchDocWithInvOrCrMemoType(
          VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0,
          PurchaseHeader."Invoice Type"::"Customs - Complementary Liquidation", "SII Purch. Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] TipoFactura is "F2" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:TipoFactura', 'LC');
    end;

    [Test]
    procedure SalesCrMemoWithF3TypeXML()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 433347] Sales credit memo with "F3" type has correct xml to send to SII

        Initialize();
        // [GIVEN] Posted sales credit memo with "Cr. Memo Type" = "F3 Invoice issued to replace simplified invoices"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"F3 Invoice issued to replace simplified invoices");

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "TipoRectificativa"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
    end;

    [Test]
    procedure ServiceCrMemoWithF3TypeXML()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 433347] Sales credit memo with "F3" type has correct xml to send to SII

        Initialize();
        // [GIVEN] Posted sales credit memo with "Cr. Memo Type" = "F3 Invoice issued to replace simplified invoices"
        PostServiceCrMemoWithInvOrCrMemoType(
          CustLedgerEntry, 0, ServiceHeader."Cr. Memo Type"::"F3 Invoice issued to replace simplified invoices");

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "TipoRectificativa"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementsSalesCrMemoWithF3TypeXML()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 433347] Sales replacement credit memo with "F3" type has correct xml to send to SII

        Initialize();
        // [GIVEN] Posted sales replacement credit memo with "Cr. Memo Type" = "F3 Invoice issued to replace simplified invoices"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, SalesHeader."Correction Type"::Replacement,
          "SII Sales Invoice Type"::"F1 Invoice", SalesHeader."Cr. Memo Type"::"F3 Invoice issued to replace simplified invoices");

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "Contraparte"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementServiceCrMemoWithF3TypeXML()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 433347] Sales replacement credit memo with "F3" type has correct xml to send to SII

        Initialize();
        // [GIVEN] Posted sales replacement credit memo with "Cr. Memo Type" = "F3 Invoice issued to replace simplified invoices"
        PostServiceCrMemoWithInvOrCrMemoType(
          CustLedgerEntry, ServiceHeader."Correction Type"::Replacement,
          ServiceHeader."Cr. Memo Type"::"F3 Invoice issued to replace simplified invoices");

        // [WHEN] Create xml for the document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "Contraparte"
        LibrarySII.ValidateElementWithNameExists(XMLDoc, 'sii:Contraparte');

        // [THEN] XML file has no node "Contraparte"
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoRectificativa');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithForeignCustomerAndInvTypeR4()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 502669] Stan can post the sales invoice with a foreign customer and "Invoice Type" = "R4 Corrected Invoice (Other)"

        Initialize();

        // [GIVEN] Foreign customer "X"
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, LibrarySII.GetForeignCountry(), LibrarySII.GetForeignVATRegNo());
        // [GIVEN] Posted Sales Invoice with a customer "X" and "Invoice Type" = "R4 Corrected Invoice (Other)"
        PostSalesDocWithInvOrCrMemoType(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, Customer."No.", 0,
          SalesHeader."Invoice Type"::"R4 Corrected Invoice (Other)",
          "SII Sales Credit Memo Type"::"R1 Corrected Invoice");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has TipoFactura = "R4"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:TipoFactura', 'R4');

        // [THEN] The structure of the line part of the XML is the following:
        // [THEN] sii:DesgloseTipoOperacion/sii:Entrega/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/
        VATEntry.SetRange("Posting Date", CustLedgerEntry."Posting Date");
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();

        IsInitialized := true;
    end;

    local procedure PostSalesDocWithInvOrCrMemoType(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option; InvoiceType: Enum "SII Sales Invoice Type"; CrMemoType: Enum "SII Sales Credit Memo Type")
    begin
        PostSalesDocWithInvOrCrMemoType(CustLedgerEntry, DocType, LibrarySales.CreateCustomerNo(), CorrType, InvoiceType, CrMemoType);
    end;

    local procedure PostSalesDocWithInvOrCrMemoType(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CorrType: Option; InvoiceType: Enum "SII Sales Invoice Type"; CrMemoType: Enum "SII Sales Credit Memo Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Validate("Invoice Type", InvoiceType);
        SalesHeader.Validate("Cr. Memo Type", CrMemoType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithInvOrCrMemoType(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrType: Option; InvoiceType: Enum "SII Purch. Invoice Type"; CrMemoType: Enum "SII Purch. Credit Memo Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Validate("Invoice Type", InvoiceType);
        PurchaseHeader.Validate("Cr. Memo Type", CrMemoType);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServiceCrMemoWithInvOrCrMemoType(var CustLedgerEntry: Record "Cust. Ledger Entry"; InvoiceType: Option; CrMemoType: Enum "SII Sales Credit Memo Type")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), '');
        ServiceHeader.Validate("Invoice Type", InvoiceType);
        ServiceHeader.Validate("Cr. Memo Type", CrMemoType);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemWithSpecificVATSetup(ServiceHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, ServiceHeader."No.");
    end;
}

