codeunit 147556 "SII Succeeded Company"
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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathPurchTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:EntidadSucedida/';
        IsInitialized: Boolean;
        XPathSalesTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:EntidadSucedida/';

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntryHasSuccceededCompanyDataAfterPurchInvPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 263060] Vendor Ledger Entry has data about Succceded Company after posting purchase invoice

        Initialize();

        // [GIVEN] Purchase invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Post purchase invoice
        PostPurchDoc(VendorLedgerEntry, PurchaseHeader);

        // [THEN] "Succeeded Company Name" is "X", "Succeeded VAT Registration No." is "Y" in Vendor Ledger Entry
        VendorLedgerEntry.TestField("Succeeded Company Name", PurchaseHeader."Succeeded Company Name");
        VendorLedgerEntry.TestField("Succeeded VAT Registration No.", PurchaseHeader."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntryHasSuccceededCompanyDataAfterSalesInvPosting()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 263060] Customer Ledger Entry has data about Succceded Company after posting sales invoice

        Initialize();

        // [GIVEN] Sales invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Post sales invoice
        PostSalesDoc(CustLedgerEntry, SalesHeader);

        // [THEN] "Succeeded Company Name" is "X", "Succeeded VAT Registration No." is "Y" in Customer Ledger Entry
        CustLedgerEntry.TestField("Succeeded Company Name", SalesHeader."Succeeded Company Name");
        CustLedgerEntry.TestField("Succeeded VAT Registration No.", SalesHeader."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithSucceededCompany()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [XML]
        // [SCENARIO 263648] Purchase invoice with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted purchase invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreatePostPurchDoc(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Export posted purchase invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NombreRazon', VendorLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NIF', VendorLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithSucceededCompany()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [XML]
        // [SCENARIO 263648] Sales invoice with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted sales invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreatePostSalesDoc(CustLedgerEntry, SalesHeader."Document Type"::Invoice);

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithSucceededCompanyFromJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [XML]
        // [SCENARIO 263648] Purchase invoice with Succeeded Company posted from journal has nodes in XML file

        Initialize();

        // [GIVEN] Purchase invoice posted from journal with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        PostGenJnlLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, GenJournalLine."Document Type"::Invoice,
          LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [WHEN] Export posted purchase invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NombreRazon', VendorLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NIF', VendorLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithSucceededCompanyFromJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [XML]
        // [SCENARIO 263648] Sales invoice with Succeeded Company posted from journal has nodes in XML file

        Initialize();

        // [GIVEN] Sales invoice posted from journal with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        PostGenJnlLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, GenJournalLine."Document Type"::Invoice,
          LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(100, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithSucceededCompany()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [XML]
        // [SCENARIO 263648] Purchase credit memo with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted purchase credit memo with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreatePostPurchDoc(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Export posted purchase credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NombreRazon', VendorLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NIF', VendorLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithSucceededCompany()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [XML]
        // [SCENARIO 263648] Sales credit memo with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted sales credit memo with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        CreatePostSalesDoc(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithSucceededCompanyFromJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [XML]
        // [SCENARIO 263648] Purchase credit memo with Succeeded Company posted from journal has nodes in XML file

        Initialize();

        // [GIVEN] Purchase credit memo posted from journal with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        PostGenJnlLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2));
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Export posted purchase credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NombreRazon', VendorLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchTok, 'sii:NIF', VendorLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithSucceededCompanyFromJnl()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [XML]
        // [SCENARIO 263648] Sales credit memo with Succeeded Company posted from journal has nodes in XML file

        Initialize();

        // [GIVEN] Sales credit memo posted from journal with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        PostGenJnlLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), -LibraryRandom.RandDec(100, 2));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Export posted sales credit memo to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvWithSucceededCompany()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [XML]
        // [SCENARIO 263648] Service invoice with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted service invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry, CreatePostServDoc(ServiceHeader."Document Type"::Invoice));

        // [WHEN] Export posted service invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoWithSucceededCompany()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [XML]
        // [SCENARIO 263648] Sales invoice with Succeeded Company has nodes in XML file

        Initialize();

        // [GIVEN] Posted sales invoice with "Succeeded Company" = "X" and "Succeeded VAT Registration No." = "Y"
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, CreatePostServDoc(ServiceHeader."Document Type"::"Credit Memo"));

        // [WHEN] Export posted sales invoice to SII
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] EntidadSucedida/NombreRazon node has value "X"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NombreRazon', CustLedgerEntry."Succeeded Company Name");

        // [THEN] EntidadSucedida/NIF node has value "Y"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesTok, 'sii:NIF', CustLedgerEntry."Succeeded VAT Registration No.");
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        IsInitialized := true;
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Succeeded Company Name", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Succeeded VAT Registration No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePostPurchDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchDoc(PurchaseHeader, DocType);
        PostPurchDoc(VendorLedgerEntry, PurchaseHeader);
    end;

    local procedure PostPurchDoc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PurchaseHeader: Record "Purchase Header")
    begin
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Succeeded Company Name", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Succeeded VAT Registration No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, DocType);
        PostSalesDoc(CustLedgerEntry, SalesHeader);
    end;

    local procedure CreatePostServDoc(DocType: Enum "Service Document Type"): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, LibrarySales.CreateCustomerNo(), '');
        ServiceHeader.Validate("Succeeded Company Name", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Succeeded VAT Registration No.", LibraryUtility.GenerateGUID());
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
        exit(ServiceHeader."No.");
    end;

    local procedure PostSalesDoc(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header")
    begin
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; DocType: Enum "Gen. Journal Document Type"; AccNo: Code[20]; Amount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocType, AccType, AccNo, Amount);
        GenJournalLine.Validate("Succeeded Company Name", LibraryUtility.GenerateGUID());
        GenJournalLine.Validate("Succeeded VAT Registration No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;
}

