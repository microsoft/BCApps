codeunit 147550 "SII AEAT"
{
    // // [FEATURE] [SII] [Sales]
    // All tests related to field "No in AEAT" in table Customer. AEAT - Spanish Tax Agency

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesContraparteTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/';
        XPathSalesIDOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/sii:IDOtro/';
        XPathSalesRemovalContraparteTok: Label '//soapenv:Body/siiRL:BajaLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/';
        XPathSalesRemovalIDOtroTok: Label '//soapenv:Body/siiRL:BajaLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/sii:IDOtro/';
        UploadType: Option Regular,Intracommunity,RetryAccepted;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithLocalCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 221621] XML has value "Customer No." in node "NIF" when post Sales Invoice with local customer registered in AEAT

        Initialize();

        // [GIVEN] Posted Sales Invoice local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(CustLedgerEntry, '', SalesHeader."Document Type"::Invoice, 0, false);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', CustLedgerEntry."Sell-to Customer No.");

        // Bug 283608: XML does not have node IDType when post Sales Invoice with local customer registered in AEAT
        LibrarySII.VerifyCountOfElements(XMLDoc, 'xii:IDType', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithLocalCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Invoice with local customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Invoice local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(CustLedgerEntry, '', SalesHeader."Document Type"::Invoice, 0, true);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithForeignCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 221621] XML has value "06" in node "IDType" when post Sales Invoice with foreign customer registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Invoice local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::Invoice, 0, false);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '06');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithForeignCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Invoice with foreign customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Invoice local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::Invoice, 0, true);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRemovalCrMemoWithLocalCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "Customer No." in node "NIF" when post Sales Credit Memo with type "Removal" with local customer registered in AEAT

        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Removal, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesRemovalContraparteTok, 'sii:NIF', CustLedgerEntry."Sell-to Customer No.");

        // Bug 283608: XML does not have node IDType when post Sales Credit Memo with type "Removal" with local customer registered in AEAT
        LibrarySII.VerifyCountOfElements(XMLDoc, 'xii:IDType', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRemovalCrMemoWithLocalCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Removal" with local customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Removal, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesRemovalIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRemovalCrMemoWithForeignCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "06" in node "IDType" when post Sales Credit Memo with type "Removal" with foreign customer registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Removal, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesRemovalIDOtroTok, 'sii:IDType', '06');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRemovalCrMemoWithForeignCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Removal" with foreign customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Removal, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, true), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesRemovalIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithLocalCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "Customer No." in node "NIF" when post Sales Credit Memo with type "Replacement" with local customer registered in AEAT

        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', CustLedgerEntry."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithLocalCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Replacement" with local customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithForeignCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "06" in node "IDType" when post Sales Credit Memo with type "Replacement" with foreign customer registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Replacement, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '06');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithForeignCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Replacement" with foreign customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Replacement, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithLocalCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "Customer No." in node "NIF" when post Sales Credit Memo with type "Difference" with local customer registered in AEAT

        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesContraparteTok, 'sii:NIF', CustLedgerEntry."Sell-to Customer No.");

        // Bug 283608: XML does not have node IDType when post Sales Credit Memo with type "Difference" with local customer registered in AEAT
        LibrarySII.VerifyCountOfElements(XMLDoc, 'xii:IDType', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithLocalCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Difference" with local customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, '', SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Difference, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithForeignCustomerInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "06" in node "IDType" when post Sales Credit Memo with type "Difference" with foreign customer registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Difference, false);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "NIF" with value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '06');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDiffCrMemoWithForeignCustomerNoInAEAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 221621] XML has value "07" in node "IDType" when post Sales Credit Memo with type "Difference" with foreign customer not registered in AEAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo local customer "X" not registered in AEAT
        PostSalesDocWithCustAEAT(
          CustLedgerEntry, CreateCountryRegionCode(), SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Difference, true);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node "IDType" with value "07"
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDOtroTok, 'sii:IDType', '07');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();

        IsInitialized := true;
    end;

    local procedure PostSalesDocWithCustAEAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; CountryCode: Code[10]; DocType: Enum "Sales Document Type"; CorrType: Option; NoInAEAT: Boolean)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryCode);
        Customer.Validate("Not in AEAT", NoInAEAT);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Validate("Corrected Invoice No.", '');
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        exit(CountryRegion.Code);
    end;
}

