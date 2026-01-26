codeunit 147563 "SII Negative Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/';

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 394230] Negative line exports to the SII file for the sales invoice when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the sales credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForSalesReplacementCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the replacement sales credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(
          CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 394230] Negative line exports to the SII file for the purchase invoice when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive and negative
        PostPurchDocWithPositiveAndNegativeLine(VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the purchase credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive and negative
        PostPurchDocWithPositiveAndNegativeLine(VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNegativeLineForPurchReplacementCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the replacement purchase credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (VAT Amount = 16) and negative (VAT Amount = -10)
        PostPurchDocWithPositiveAndNegativeLine(
          VendorLedgerEntry, PositivePurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // TFS ID 400899: CuotaDeducible xml of purchase replacement credit memo with positive and negative lines has correct value
        VATEntry.SetRange("Document Type", VendorLedgerEntry."Document Type");
        VATEntry.SetRange("Document No.", VendorLedgerEntry."Document No.");
        VATEntry.FindSet();
        Assert.RecordCount(VATEntry, 2);
        repeat
            TotalVATAmount += VATEntry.Amount;
        until VATEntry.Next() = 0;

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);

        // [THEN] "CuotaDeducible" is 6
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(-TotalVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNoReportNegativeLineForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 394230] Negative line does not export to the SII file for the sales invoice when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has positive amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PositiveSalesLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNegativeLineForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the sales credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has negative amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PositiveSalesLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNegativeLineForSalesReplacementCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the sales credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostSalesDocWithPositiveAndNegativeLine(
          CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has positive amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PositiveSalesLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNoReportNegativeLineForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 394230] Negative line does not export to the SII file for the purchase invoice when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostPurchDocWithPositiveAndNegativeLine(VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has positive amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PositivePurchaseLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNegativeLineForPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the purchase credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostPurchDocWithPositiveAndNegativeLine(VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has negative amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PositivePurchaseLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNegativeLineForPurchReplacementCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the purchase credit memo when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive and negative
        PostPurchDocWithPositiveAndNegativeLine(
          VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] "BaseImponible" xml node has positive amount
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PositivePurchaseLine.Amount), 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNonTaxableNegativeLineForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 394230] Negative line exports to the SII file for the sales invoice with no taxable VAT when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] One "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNonTaxableNegativeLineForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the sales credit memo with no taxable VAT when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] One "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNonTaxableNegativeLineForSalesReplacementCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the replacement sales credit memo with no taxable VAT when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(
          CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] One "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNonTaxableNegativeLineForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 394230] Negative line does not export to the SII file for the sales invoice with no taxable VAT when "Do Not Report Negative Lines" option enabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] No "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNonTaxableNegativeLineForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the sales credit memo with no taxable VAT when "Do Not Report Negative Lines" option enabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] No "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNonTaxableNegativeLineForSalesReplacementCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PositiveSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the replacement sales credit memo with no taxable VAT when "Do Not Report Negative Lines" option enabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostSalesDocWithPositiveAndNegativeNoTaxableLine(
          CustLedgerEntry, PositiveSalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);

        // [THEN] No "ImportePorArticulos7_14_Otros" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNonTaxableNegativeLineForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 394230] Negative line exports to the SII file for the purchase invoice with no taxable VAT when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostPurchDocWithPositiveAndNegativeNoTaxableLine(
          VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportNonTaxableNegativeLineForPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line exports to the SII file for the purchase credit memo with no taxable VAT when "Do Not Report Negative Lines" option disabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is disabled in the SII setup
        SetDoNotReportNegativeLines(false);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostPurchDocWithPositiveAndNegativeNoTaxableLine(
          VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" xml nodes exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNonTaxableNegativeLineForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 394230] Negative line does not export to the SII file for the purchase invoice with no taxable VAT when "Do Not Report Negative Lines" option enabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostPurchDocWithPositiveAndNegativeNoTaxableLine(
          VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotReportNonTaxableNegativeLineForPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PositivePurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 394230] Negative line does not export to the SII file for the purchase credit memo with no taxable VAT when "Do Not Report Negative Lines" option enabled in the SII Setup

        Initialize();

        // [GIVEN] "Do Not Report Negative Lines" is enabled in the SII setup
        SetDoNotReportNegativeLines(true);

        // [GIVEN] Document with two lines - positive (normal VAT) and negative (no taxable VAT)
        PostPurchDocWithPositiveAndNegativeNoTaxableLine(
          VendorLedgerEntry, PositivePurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "BaseImponible" xml node exported
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SII Negative Lines");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SII Negative Lines");
        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"SII Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SII Negative Lines");
    end;

    local procedure SetDoNotReportNegativeLines(DoNotReportNegativeLines: Boolean)
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("Do Not Export Negative Lines", DoNotReportNegativeLines);
        SIISetup.Modify(true);
    end;

    local procedure PostSalesDocWithPositiveAndNegativeLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; var PositiveSalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, PositiveSalesLine, DocType, CorrType);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostSalesDocWithPositiveAndNegativeNoTaxableLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; var PositiveSalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocWithNegativeNoTaxableLine(SalesHeader, PositiveSalesLine, DocType, CorrType);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithPositiveAndNegativeLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PositivePurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDoc(PurchaseHeader, PositivePurchaseLine, DocType, CorrType);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPurchDocWithPositiveAndNegativeNoTaxableLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var PositivePurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDocWithNegativeNoTaxableLine(PurchaseHeader, PositivePurchaseLine, DocType, CorrType);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var PositiveSalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, LibraryInventory.CreateItemNo());
        LibrarySales.FindFirstSalesLine(PositiveSalesLine, SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithNewVATProdPostGroup(SalesHeader."VAT Bus. Posting Group", PositiveSalesLine."VAT %"), -1);
        LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesDocWithNegativeNoTaxableLine(var SalesHeader: Record "Sales Header"; var PositiveSalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, LibraryInventory.CreateItemNo());
        LibrarySales.FindFirstSalesLine(PositiveSalesLine, SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithNewVATProdPostGroup(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT %"), -1);
        SalesLine.Validate(
          "VAT Prod. Posting Group", LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", false, 0));
        SalesLine.Modify(true);
        LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; var PositivePurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, LibraryInventory.CreateItemNo());
        LibraryPurchase.FindFirstPurchLine(PositivePurchaseLine, PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithNewVATProdPostGroup(PurchaseHeader."VAT Bus. Posting Group", PositivePurchaseLine."VAT %"), -1);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchDocWithNegativeNoTaxableLine(var PurchaseHeader: Record "Purchase Header"; var PositivePurchaseLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, LibraryInventory.CreateItemNo());
        LibraryPurchase.FindFirstPurchLine(PositivePurchaseLine, PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithNewVATProdPostGroup(PurchaseHeader."VAT Bus. Posting Group", PositivePurchaseLine."VAT %"), -1);
        PurchaseLine.Validate(
          "VAT Prod. Posting Group", LibrarySII.CreateSpecificNoTaxableVATSetup(PurchaseHeader."VAT Bus. Posting Group", false, 0));
        PurchaseLine.Modify(true);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateItemWithNewVATProdPostGroup(VATBusPostGroupCode: Code[20]; VATRate: Decimal): Code[20]
    var
        Item: Record Item;
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("VAT %", VATRate + 1);
        VATPostingSetup.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;
}

