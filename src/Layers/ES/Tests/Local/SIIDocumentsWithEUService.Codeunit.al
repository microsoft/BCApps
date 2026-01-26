codeunit 147523 "SII Documents With EU Service"
{
    // // [FEATURE] [SII] [EU Service]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XmlType: Option Invoice,"Intra Community",Payment;
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesEUServiceTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/%1/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesNoTaxTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/%1/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros', Locked = true;
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathSalesExentaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/%1/sii:Sujeta/sii:Exenta/sii:DetalleExenta/';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvNoTaxableEUServiceXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [No tax] [Invoice]
        // [SCENARIO 229401] XML has node "PrestacionServicios" for non taxable amount if only line with No Taxable VAT exists in Sales Invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with one line where "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, true, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNoTaxableEUServiceXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
    begin
        // [FEATURE] [Sales] [No tax] [Credit Memo]
        // [SCENARIO 229401] XML has node "ImportePorArticulos7_14_Otros" with parent node "PrestacionServicios" for non taxable amount in EU Sales Credit Memo

        Initialize();

        // [GIVEN] Posted Sales Cr Memo withwith one line
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] Sales Line where "VAT Calculation Type" = "No Taxable VAT", "EU Service", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", true, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        SalesHeader.CalcFields(Amount);
        NonTaxableAmount := SalesHeader.Amount;

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has "sii:PrestacionServicios\...\sii:ImportePorArticulos7_14_Otros" xpath for non taxable amount of 500
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesNoTaxTok, 'sii:PrestacionServicios'), '', SIIXMLCreator.FormatNumber(-NonTaxableAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 225611] XML has node for VAT Amount excluding EC Amount given Sales Invoice with EC

        Initialize();

        // [GIVEN] Sales Invoice with Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount := CreateSalesDocWithEC(SalesHeader, SalesHeader."Document Type"::Invoice, 0);
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 (1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithVATAndECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 225611] XML has node for VAT Amount given Sales invoice with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Sales Invoice with both Normal VAT and EC

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreateSalesDocWithNormalAndEC(SalesHeader, SalesHeader."Document Type"::Invoice, 0);

        // [GIVEN] Two VAT Entries with Amount = 210 (by "VAT %") and 262 (by "VAT %" + "EC %")
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = 52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with EC

        Initialize();

        // [GIVEN] Sales Credit Memo with Amount = -1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount := CreateSalesDocWithEC(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 0);
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = -210 (-1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(-ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATAndECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Sales Credit Memo with both Normal VAT and EC

        Initialize();

        // [GIVEN] Sales Credit Memo with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreateSalesDocWithNormalAndEC(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 0);

        // [GIVEN] Two VAT Entries with Amount = -210 (by "VAT %") and -262 (by "VAT %" + "EC %")
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = -420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = -52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoWithECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with "Correction Type" = Replacement and EC

        Initialize();

        // [GIVEN] Sales Credit Memo with with "Correction Type" = Replacement, Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount :=
          CreateSalesDocWithEC(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 (1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoWithVATAndECAmount()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with "Correction Type" = Replacement and with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Sales Credit Memo with "Correction Type" = Replacement with both Normal VAT and EC

        Initialize();

        // [GIVEN] Sales Credit Memo with "Correction Type" = Replacement and two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreateSalesDocWithNormalAndEC(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Replacement);

        // [GIVEN] Two VAT Entries with Amount = 210 (by "VAT %") and 262 (by "VAT %" + "EC %")
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = 52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:CuotaRepercutida', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 225611] XML has node for VAT Amount excluding EC Amount given Sales Invoice with EC

        Initialize();

        // [GIVEN] Sales Invoice with Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount := CreatePurchDocWithEC(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 0);
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = 210 (1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithVATAndECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 225611] XML has node for VAT Amount given Purchase invoice with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Purchase invoice with both Normal VAT and EC

        Initialize();

        // [GIVEN] Purchase Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreatePurchDocWithNormalAndEC(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 0);
        // [GIVEN] Two VAT Entries with Amount = 210 (by "VAT %") and 262 (by "VAT %" + "EC %")
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = 420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = 52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:CuotaSoportada', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithECAmountAndDiffCorrType()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedECAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 222254] EC VAT Amount of Purchase Credit Memo with "Correction Type" equal Difference exports with negative value

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with "Correction Type" = Difference
        // [GIVEN] Amount = 100, "VAT %" = 30, "EC %" = 10
        ExpectedECAmount := CreatePurchCrMemoDifferenceWithEC(PurchaseHeader);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml file for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] The amount in tag 'sii:CuotaSoportada' equals 20 (VAT Amount = Amount * VAT % = 30. EC VAT Amount = VAT Amount  - Amount * "EC %" = 30 - 10 = 20)
        LibrarySII.ValidateElementByNameAt(XMLDoc, 'sii:CuotaSoportada', SIIXMLCreator.FormatNumber(ExpectedECAmount), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Purchase Credit Memo with EC

        Initialize();

        // [GIVEN] Purchase Credit Memo with Amount = -1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount := CreatePurchDocWithEC(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 0);
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = -210 (-1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(-ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithVATAndECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Purchase Credit Memo with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Purchase Credit Memo with both Normal VAT and EC

        Initialize();

        // [GIVEN] Purchase Credit Memo with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreatePurchDocWithNormalAndEC(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [GIVEN] Two VAT Entries with Amount = 210 (by "VAT %") and 262 (by "VAT %" + "EC %")
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = 420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = 52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:CuotaSoportada', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoWithECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ExpectedVATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Purchase Credit Memo with "Correction Type" = Replacement and EC

        Initialize();

        // [GIVEN] Purchase Credit Memo with with "Correction Type" = Replacement, Amount = -1000, "VAT %" = 21, "EC %" = 5.2
        ExpectedVATAmount :=
          CreatePurchDocWithEC(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
            PurchaseHeader."Correction Type"::Replacement);
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = -210 (1000 * 21 / 100)
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:CuotaSoportada', SIIXMLCreator.FormatNumber(-ExpectedVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoWithVATAndECAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225621] XML has node for VAT Amount excluding EC Amount given Purchase Credit Memo with "Correction Type" = Replacement and with both Normal VAT and EC
        // [SCENARIO 229914] CuotaRecargoEquivalencia node contains EC Amount for Purchase Credit Memo with "Correction Type" = Replacement and with both Normal VAT and EC

        Initialize();

        // [GIVEN] Purchase Credit Memo with "Correction Type" = Replacement and two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreatePurchDocWithNormalAndEC(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          PurchaseHeader."Correction Type"::Replacement);

        // [GIVEN] Two VAT Entries with Amount = -210 (by "VAT %") and -262 (by "VAT %" + "EC %")
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaSoportada node for VAT Amount = -420 (from the first line and from the second line excluding EC)
        // [THEN] XML file has sii:CuotaRecargoEquivalencia node for EC Amount = -52 (from the second line)
        VerifyMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:CuotaSoportada', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvNoTaxableEUServiceXml()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [No tax] [Invoice]
        // [SCENARIO 229401] XML has node "PrestacionServicios" for non taxable amount if only line with No Taxable VAT exists in Service Invoice

        Initialize();

        // [GIVEN] Posted Service Invoice with one line where "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.",
          PostServDocWithVAT(ServiceHeader."Document Type"::Invoice, true));
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceInvoiceHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, ServiceInvoiceHeader."No.");

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoNoTaxableEUServiceXml()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [No tax] [Credit Memo]
        // [SCENARIO 229401] XML has node "PrestacionServicios" for non taxable amount if only line with No Taxable VAT exists in Service Credit Memo

        Initialize();

        // [GIVEN] Posted Service Credit Memo with one line where "VAT Calculation Type" = "No Taxable VAT" and "EU Service"
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.",
          PostServDocWithVAT(ServiceHeader."Document Type"::"Credit Memo", true));
        ServiceCrMemoHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceCrMemoHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvMultipleLinesDiffGroupsSameVATPct()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Sales Invoice with multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Sales Invoice with multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostSalesDocWithWithMultipleLinesDiffGroupsSameVATPct(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:BaseImponible', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoMultipleLinesDiffGroupsSameVATPct()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Sales Credit Memo with Type = "Replacement" and multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Type = Replacement and multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostSalesDocWithWithMultipleLinesDiffGroupsSameVATPct(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted Sales Credit Memo with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:BaseImponible', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoMultipleLinesDiffGroupsSameVATPct()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Sales Credit Memo with Type = "Difference" and multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Type = Difference and multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostSalesDocWithWithMultipleLinesDiffGroupsSameVATPct(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference);

        // [WHEN] Create xml for Posted Sales Credit Memo with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:BaseImponible', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvMultipleLinesDiffGroupsSameVATPct()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Purchase Invoice with multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Purchase Invoice with multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostPurchDocWithWithMultipleLinesDiffGroupsSameVATPct(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Purchase Invoice with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:BaseImponible', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReplacementCrMemoMultipleLinesDiffGroupsSameVATPct()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Purchase Credit Memo with Type = "Replacement" and multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Type = Replacement and multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostPurchDocWithWithMultipleLinesDiffGroupsSameVATPct(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted Purchase Credit Memo with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:BaseImponible', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDiffCrMemoMultipleLinesDiffGroupsSameVATPct()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Purchase Credit Memo with Type = "Difference" and multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Type = Difference and multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        PostPurchDocWithWithMultipleLinesDiffGroupsSameVATPct(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Difference);

        // [WHEN] Create xml for Posted Purchase Credit Memo with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Purchase, VendorLedgerEntry."Document No.", XPathPurchBaseImponibleTok, 'sii:BaseImponible', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvMultipleLinesDiffGroupsSameVATPct()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Service Invoice with multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Service Invoice with multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.",
          PostServDocWithWithMultipleLinesDiffGroupsSameVATPct(ServiceHeader."Document Type"::Invoice));
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceInvoiceHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, ServiceInvoiceHeader."No.");

        // [WHEN] Create xml for Posted Service Invoice with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:BaseImponible', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoMultipleLinesDiffGroupsSameVATPct()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        VATEntry: Record "VAT Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 232971] There are two XML nodes for each VAT Entry for Service Credit Memo and multiple lines where lines has different "VAT Identifier" but same "VAT %"

        Initialize();

        // [GIVEN] Posted Purchase Service Memo with multiple lines with multiple lines
        // [GIVEN] First line has "VAT Identifier" = "VAT10", "VAT %" = 10
        // [GIVEN] Second line has "VAT Identifier" = "VAT21", "VAT %" = 21
        // [GIVEN] Third line has "VAT Identifier" = "VAT21EXTRA", "VAT %" = 21
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.",
          PostServDocWithWithMultipleLinesDiffGroupsSameVATPct(ServiceHeader."Document Type"::"Credit Memo"));
        ServiceCrMemoHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceCrMemoHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");

        // [WHEN] Create xml for Posted Service Credit Memo with two VAT Entries generated per each "VAT %"
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Two "BaseImponible" nodes exists in xml file for each VAT Entry
        VerifyVATBaseOfMultipleVATEntiesInXMLDetails(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, 'sii:BaseImponible', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithVATAndEUServiceSamePctDomesticCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294162] XML has node for VAT Amount excluding EC Amount given Sales Invoice with Domestic Customer, both Normal VAT and EU Service and same VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(SalesHeader, SalesHeader."Document Type"::Invoice, '', LibrarySII.GetLocalVATRegNo(), 1);

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 310
        VerifyMultipleVATEntiesInOneXMLNode(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATAndEUServiceSamePctDomesticCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294162] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with Domestic Customer, both Normal VAT and EU Service and same VAT rate

        Initialize();

        // [GIVEN] Sales Credit Memo with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', LibrarySII.GetLocalVATRegNo(), 1);

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 310
        VerifyMultipleVATEntiesInOneXMLNode(
          XMLDoc, VATEntry.Type::Sale, CustLedgerEntry."Document No.", XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithVATAndEUServiceSamePctForeignCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294162] Multiple XML has nodes for VAT Amount given Sales Invoice with Foreign Customer, both Normal VAT and EC and same VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySII.GetForeignCountry(), LibrarySII.GetForeignVATRegNo(), 1);

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 under node sii:Sujeta
        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 100 under node sii:PrestacionServicios
        VerifySalesVATEntiesInDiffVATTypeXMLNodes(XMLDoc, CustLedgerEntry."Document No.", 'sii:Entrega', 'sii:PrestacionServicios');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATAndEUServiceSamePctForeignCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294162] Multiple XML has nodes for VAT Amount given Sales Credit Memo with Foreign Customer, both Normal VAT and EC and same VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySII.GetForeignCountry(), LibrarySII.GetForeignVATRegNo(), 1);

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 under node sii:Sujeta
        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 100 under node sii:PrestacionServicios
        VerifySalesVATEntiesInDiffVATTypeXMLNodes(XMLDoc, CustLedgerEntry."Document No.", 'sii:Entrega', 'sii:PrestacionServicios');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithVATAndEUServiceDiffPctDomesticCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294162] XML has node for VAT Amount excluding EC Amount given Sales Invoice with Domestic Customer, both Normal VAT and EU Service and different VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::Invoice, '', LibrarySII.GetLocalVATRegNo(), LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 310
        VerifySalesVATEntiesInDiffVATRateXMLNodes(XMLDoc, CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATAndEUServiceDiffPctDomesticCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294162] XML has node for VAT Amount excluding EC Amount given Sales Credit Memo with Domestic Customer, both Normal VAT and EU Service and different VAT rate

        Initialize();

        // [GIVEN] Sales Credit Memo with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', LibrarySII.GetLocalVATRegNo(), LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 310
        VerifySalesVATEntiesInDiffVATRateXMLNodes(XMLDoc, CustLedgerEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithVATAndEUServiceDiffPctForeignCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294162] Multiple XML has nodes for VAT Amount given Sales Invoice with Foreign Customer, both Normal VAT and EC and different VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySII.GetForeignCountry(),
          LibrarySII.GetForeignVATRegNo(), LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 under node sii:Sujeta
        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 100 under node sii:PrestacionServicios
        VerifySalesVATEntiesInDiffVATTypeXMLNodes(XMLDoc, CustLedgerEntry."Document No.", 'sii:PrestacionServicios', 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATAndEUServiceDiffPctForeignCustomer()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294162] Multiple XML has nodes for VAT Amount given Sales Credit Memo with Foreign Customer, both Normal VAT and EC and different VAT rate

        Initialize();

        // [GIVEN] Sales Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 10,"EU Service" = FALSE
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EU Service" = TRUE
        CreateSalesDocWithNormalAndEUService(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySII.GetForeignCountry(),
          LibrarySII.GetForeignVATRegNo(), LibraryRandom.RandIntInRange(3, 5));

        // [GIVEN] Two VAT Entries with Amount = 100 and 210
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 210 under node sii:Sujeta
        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 100 under node sii:PrestacionServicios
        VerifySalesVATEntiesInDiffVATTypeXMLNodes(XMLDoc, CustLedgerEntry."Document No.", 'sii:PrestacionServicios', 'sii:Entrega');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithRoundedVATAmountExcludedEC()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        UnitPriceArray: array[3] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 305640] CuotaRepercutida XML node of Sales Invoice has value of rounded total VAT Amount excluding EC amount

        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT %" = 10, "EC %" = 1.4
        // [GIVEN] Sales Invoice with three lines, each has different dimension in order to have a separate VAT Entry
        // [GIVEN] Quantity = 1, Unit Price = 17.90
        // [GIVEN] Quantity = 1, Unit Price = 8.00
        // [GIVEN] Quantity = 1, Unit Price = 0.23
        GetUnitPricesForScenario294162(UnitPriceArray);
        CreateSalesDocWithRoundedAmount(SalesHeader, SalesHeader."Document Type"::Invoice, 1.4, UnitPriceArray);

        // [GIVEN] Three VAT Entries with Total VAT Base = 26.13, VAT (10%) = 2.61, EC (1.4 %) = 0.37
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = 2.61
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(2.61));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithRoundedVATAmountExcludedEC()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        UnitPriceArray: array[3] of Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 305640] CuotaRepercutida XML node of Sales Credit Memo has value of rounded total VAT Amount excluding EC amount

        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT %" = 10, "EC %" = 1.4
        // [GIVEN] Sales Credit Memo with three lines, each has different dimension in order to have a separate VAT Entry
        // [GIVEN] Quantity = 1, Unit Price = 17.90
        // [GIVEN] Quantity = 1, Unit Price = 8.00
        // [GIVEN] Quantity = 1, Unit Price = 0.23
        GetUnitPricesForScenario294162(UnitPriceArray);
        CreateSalesDocWithRoundedAmount(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 1.4, UnitPriceArray);

        // [GIVEN] Three VAT Entries with Total VAT Base = -26.13, VAT (10%) = -2.61, EC (1.4 %) = -0.37
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:CuotaRepercutida node for VAT Amount = -2.61
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(-2.61));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNoTaxableEUServiceAndExemptionXml()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATClause: Record "VAT Clause";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Exemption] [Credit Memo]
        // [SCENARIO 363304] XML has correct structure with parent node "PrestacionServicios" for the Sales Credit Memo with "EU service" and "VAT Exemption"

        Initialize();

        // [GIVEN] Posted Sales Cr Memo wit one line
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] Sales Line where "VAT Calculation Type" = "Normal VAT", "EU Service" is enabled, "VAT Clause" is specified
        VATPostingSetup.Get(
          SalesHeader."VAT Bus. Posting Group",
          LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(Customer."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E1 Exempt on account of Article 20"));
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);

        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has "sii:PrestacionServicios/sii:Sujeta/sii:Exenta/sii:DetalleExenta/sii:BaseImponible" xpath
        CustLedgerEntry.CalcFields(Amount);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesExentaTok, 'sii:PrestacionServicios'),
          'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithVATAndECAmountVersion11bis()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIDocUploadState: Record "SII Doc. Upload State";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 375398] CuotaDeducible is zero in the XML file for Purchase invoice with EC for version 1.1bis

        Initialize();

        // [GIVEN] Purchase Invoice with two lines:
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21
        // [GIVEN] First Line: Amount = 1000, "VAT %" = 21, "EC %" = 5.2
        CreatePurchDocWithNormalAndEC(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 0);
        // [GIVEN] Two VAT Entries with Amount = 210 (by "VAT %") and 262 (by "VAT %" + "EC %")
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [GIVEN] SII version is 1.1bis
        SIIXMLCreator.SetSIIVersionNo(SIIDocUploadState."Version No."::"2.1");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "CuotaDeducible" with value "0"
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));
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

        IsInitialized := true;
    end;

    local procedure CreateCustWithVATBusPostGroup(VATBustPostGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, '', LibrarySII.GetLocalVATRegNo());
        Customer.Validate("VAT Bus. Posting Group", VATBustPostGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustWithVATSetup(VATBustPostGroupCode: Code[20]; CustomerCountryCode: Code[10]; VATRegNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithCountryAndVATReg(Customer, CustomerCountryCode, VATRegNo);
        Customer.Validate("VAT Bus. Posting Group", VATBustPostGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVATPostingSetupEC(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(15, 20));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandIntInRange(5, 15));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetupEUService(var VATPostingSetup: Record "VAT Posting Setup"; EUService: Boolean)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(15, 20));
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesDocWithEC(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CorrType: Option): Decimal
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        CustNo := CreateCustWithVATBusPostGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocType, CustNo, ItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
        exit(SalesLine."Amount Including VAT" - SalesLine.Amount - Round(SalesLine.Amount * SalesLine."EC %" / 100));
    end;

    local procedure CreateSalesDocWithNormalAndEC(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        NormalVATSalesLine: Record "Sales Line";
        ECSalesLine: Record "Sales Line";
        VATPostingSetupEC: Record "VAT Posting Setup";
        CustNo: Code[20];
        NormalVATItemNo: Code[20];
        ECItemNo: Code[20];
        NormalVATProdPostGroupCode: Code[20];
    begin
        CreateVATPostingSetupEC(VATPostingSetupEC);
        NormalVATProdPostGroupCode :=
          LibrarySII.CreateSpecificVATSetup(VATPostingSetupEC."VAT Bus. Posting Group", VATPostingSetupEC."VAT %");
        CustNo := CreateCustWithVATSetup(VATPostingSetupEC."VAT Bus. Posting Group", '', LibrarySII.GetLocalVATRegNo());

        NormalVATItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(NormalVATProdPostGroupCode);
        ECItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetupEC."VAT Prod. Posting Group");

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, NormalVATSalesLine, DocType, CustNo, NormalVATItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        LibrarySales.CreateSalesLine(ECSalesLine, SalesHeader, ECSalesLine.Type::Item, ECItemNo, LibraryRandom.RandDec(100, 2));
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySII.UpdateUnitPriceSalesLine(NormalVATSalesLine, LibraryRandom.RandDec(100, 2));
        LibrarySII.UpdateUnitPriceSalesLine(ECSalesLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesDocWithNormalAndEUService(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerCountryCode: Code[10]; CustomerVATRegNo: Code[20]; VATRateFactor: Integer)
    var
        NormalVATSalesLine: Record "Sales Line";
        EUSalesLine: Record "Sales Line";
        VATPostingSetupEUService: Record "VAT Posting Setup";
        CustNo: Code[20];
        NormalVATItemNo: Code[20];
        EUItemNo: Code[20];
        NormalVATProdPostGroupCode: Code[20];
    begin
        CreateVATPostingSetupEUService(VATPostingSetupEUService, true);
        NormalVATProdPostGroupCode :=
          LibrarySII.CreateSpecificVATSetup(
            VATPostingSetupEUService."VAT Bus. Posting Group", VATPostingSetupEUService."VAT %" * VATRateFactor);
        CustNo := CreateCustWithVATSetup(VATPostingSetupEUService."VAT Bus. Posting Group", CustomerCountryCode, CustomerVATRegNo);

        NormalVATItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(NormalVATProdPostGroupCode);
        EUItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetupEUService."VAT Prod. Posting Group");

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, NormalVATSalesLine, DocType, CustNo, NormalVATItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        LibrarySales.CreateSalesLine(EUSalesLine, SalesHeader, EUSalesLine.Type::Item, EUItemNo, LibraryRandom.RandDec(100, 2));
        LibrarySII.UpdateUnitPriceSalesLine(NormalVATSalesLine, LibraryRandom.RandDec(100, 2));
        LibrarySII.UpdateUnitPriceSalesLine(EUSalesLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateSalesDocWithRoundedAmount(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; ECPct: Decimal; UnitPriceArray: array[3] of Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: array[3] of Record "Dimension Value";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        VATPostingSetup.Validate("EC %", ECPct);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        GeneralLedgerSetup.Get();
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.CreateDimensionValue(DimensionValue[i], GeneralLedgerSetup."Global Dimension 1 Code");
            CreateSalesLineForRoundingScenario(
              SalesHeader, VATPostingSetup."VAT Prod. Posting Group", DimensionValue[i].Code, UnitPriceArray[i]);
        end;
    end;

    local procedure CreateSalesLineForRoundingScenario(SalesHeader: Record "Sales Header"; VATProdPostGroupCode: Code[20]; GlobalDimension1ValueCode: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Shortcut Dimension 1 Code", GlobalDimension1ValueCode);
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocWithWithMultipleLinesDiffGroupsSameVATPct(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustNo: Code[20];
        ItemNo: array[4] of Code[20];
        VATPct: array[2] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        CustNo := CreateCustWithVATBusPostGroup(VATPostingSetup."VAT Bus. Posting Group");
        VATPct[1] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        VATPct[2] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        ItemNo[1] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[2] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[3] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        ItemNo[4] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        for i := 1 to ArrayLen(ItemNo) do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo[i], LibraryRandom.RandInt(100));
            LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithWithMultipleLinesDiffGroupsSameVATPct(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendNo: Code[20];
        ItemNo: array[4] of Code[20];
        VATPct: array[2] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATPostingSetup."VAT Bus. Posting Group");
        VATPct[1] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        VATPct[2] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        ItemNo[1] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[2] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[3] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        ItemNo[4] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        for i := 1 to ArrayLen(ItemNo) do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo[i], LibraryRandom.RandInt(100));
            LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServDocWithWithMultipleLinesDiffGroupsSameVATPct(DocType: Enum "Service Document Type"): Code[20]
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemNo: array[4] of Code[20];
        VATPct: array[2] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        LibrarySII.CreateCustWithVATSetup(Customer);
        VATPct[1] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        VATPct[2] := VATPostingSetup."VAT %" + LibraryRandom.RandIntInRange(3, 5);
        ItemNo[1] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[2] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[1]);
        ItemNo[3] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        ItemNo[4] := LibrarySII.CreateItemWithSpecificVATSetup(VATPostingSetup."VAT Bus. Posting Group", VATPct[2]);
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, Customer."No.");
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Modify(true);
        for i := 1 to ArrayLen(ItemNo) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            LibraryService.CreateServiceLineWithQuantity(
              ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo[i], LibraryRandom.RandInt(100));
            ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            ServiceLine.Modify(true);
        end;
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure GetUnitPricesForScenario294162(var UnitPriceArray: array[3] of Decimal)
    begin
        UnitPriceArray[1] := 17.9;
        UnitPriceArray[2] := 8;
        UnitPriceArray[3] := 0.23;
    end;

    local procedure CreatePurchCrMemoDifferenceWithEC(var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendNo: Code[20];
        ItemNo: Code[20];
        VAT: Decimal;
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo", VendNo,
          ItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        PurchaseHeader.Validate("Correction Type", PurchaseHeader."Correction Type"::Difference);
        PurchaseHeader.Modify(true);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        VAT := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        exit(-(VAT - PurchaseLine.Amount * VATPostingSetup."EC %" / 100));
    end;

    local procedure CreatePurchDocWithEC(var PurchaseHeader: Record "Purchase Header"; DocType: enum "Purchase Document Type"; CorrType: Option): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        CreateVATPostingSetupEC(VATPostingSetup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocType, VendNo, ItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        exit(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount - Round(PurchaseLine.Amount * PurchaseLine."EC %" / 100));
    end;

    local procedure CreatePurchDocWithNormalAndEC(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        NormalVATPurchLine: Record "Purchase Line";
        ECPurchLine: Record "Purchase Line";
        VATPostingSetupEC: Record "VAT Posting Setup";
        VendNo: Code[20];
        NormalVATItemNo: Code[20];
        ECItemNo: Code[20];
        NormalVATProdPostGroupCode: Code[20];
    begin
        CreateVATPostingSetupEC(VATPostingSetupEC);
        NormalVATProdPostGroupCode :=
          LibrarySII.CreateSpecificVATSetup(VATPostingSetupEC."VAT Bus. Posting Group", VATPostingSetupEC."VAT %");
        VendNo := LibrarySII.CreateVendWithVATSetup(VATPostingSetupEC."VAT Bus. Posting Group");
        NormalVATItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(NormalVATProdPostGroupCode);
        ECItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetupEC."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, NormalVATPurchLine, DocType, VendNo, NormalVATItemNo, LibraryRandom.RandDec(100, 2), '', WorkDate());
        LibraryPurchase.CreatePurchaseLine(ECPurchLine, PurchaseHeader, ECPurchLine.Type::Item, ECItemNo, LibraryRandom.RandDec(100, 2));
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibrarySII.UpdateDirectUnitCostPurchaseLine(NormalVATPurchLine, LibraryRandom.RandDec(100, 2));
        LibrarySII.UpdateDirectUnitCostPurchaseLine(ECPurchLine, LibraryRandom.RandDec(100, 2));
    end;

    local procedure FindVATEntries(var VATEntry: Record "VAT Entry"; Type: Enum "General Posting Type"; DocNo: Code[20])
    begin
        VATEntry.SetCurrentKey("VAT %", "EC %");
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindSet();
    end;

    local procedure PostServDocWithVAT(DocType: Enum "Service Document Type"; EUService: Boolean): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, Customer."No.");
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", EUService, 0)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure VerifyMultipleVATEntiesInXMLDetails(var XMLDoc: DotNet XmlDocument; Type: Enum "General Posting Type"; DocNo: Code[20]; BaseNode: Text; NodeName: Text; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
        ExpectedECAmount: Decimal;
    begin
        FindVATEntries(VATEntry, Type, DocNo);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, '[1]/' + NodeName, SIIXMLCreator.FormatNumber(Sign * VATEntry.Amount));
        VATEntry.Next();
        ExpectedECAmount := Round(Sign * VATEntry.Base * VATEntry."EC %" / 100);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, '[2]/' + NodeName, SIIXMLCreator.FormatNumber(Sign * VATEntry.Amount - ExpectedECAmount));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, '/sii:CuotaRecargoEquivalencia', SIIXMLCreator.FormatNumber(ExpectedECAmount));
    end;

    local procedure VerifyMultipleVATEntiesInOneXMLNode(var XMLDoc: DotNet XmlDocument; Type: Enum "General Posting Type"; DocNo: Code[20]; BaseNode: Text; NodeName: Text; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, Type, DocNo);
        VATEntry.CalcSums(Amount);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, NodeName, SIIXMLCreator.FormatNumber(Sign * VATEntry.Amount));
    end;

    local procedure VerifySalesVATEntiesInDiffVATTypeXMLNodes(var XMLDoc: DotNet XmlDocument; DocNo: Code[20]; FirstVATTypeNodeName: Text[50]; SecondVATTypeNodeName: Text[50])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, VATEntry.Type::Sale, DocNo);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesEUServiceTok, FirstVATTypeNodeName), '/sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-VATEntry.Amount));
        VATEntry.Next();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathSalesEUServiceTok, SecondVATTypeNodeName), '/sii:CuotaRepercutida',
          SIIXMLCreator.FormatNumber(-VATEntry.Amount));
    end;

    local procedure VerifySalesVATEntiesInDiffVATRateXMLNodes(var XMLDoc: DotNet XmlDocument; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, VATEntry.Type::Sale, DocNo);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '[1]/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(-VATEntry.Amount));
        VATEntry.Next();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '[2]/sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(-VATEntry.Amount));
    end;

    local procedure VerifyVATBaseOfMultipleVATEntiesInXMLDetails(var XMLDoc: DotNet XmlDocument; Type: Enum "General Posting Type"; DocNo: Code[20]; BaseNode: Text; NodeName: Text; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntries(VATEntry, Type, DocNo);
        VATEntry.SetRange("VAT %", VATEntry."VAT %");
        VATEntry.CalcSums(Base);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, '[1]/' + NodeName, SIIXMLCreator.FormatNumber(Sign * VATEntry.Base));
        VATEntry.FindLast();
        VATEntry.SetRange("VAT %");
        VATEntry.Next();
        VATEntry.SetRange("VAT %", VATEntry."VAT %");
        VATEntry.CalcSums(Base);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, BaseNode, '[2]/' + NodeName, SIIXMLCreator.FormatNumber(Sign * VATEntry.Base));
    end;
}

