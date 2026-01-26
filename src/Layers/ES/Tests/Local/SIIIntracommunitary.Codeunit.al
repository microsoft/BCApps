codeunit 147527 "SII Intracommunitary"
{
    // // [FEATURE] [SII] [Intracommunitary]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        SIIXMLCreator: Codeunit "SII XML Creator";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathPurchIdFacturaOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:IDFactura/sii:IDEmisorFactura/sii:IDOtro/';
        XPathPurchIdOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:Contraparte/sii:IDOtro/';
        XPathSalesIdOtroTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:Contraparte/sii:IDOtro/';
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        ESLbl: Label 'ES';
        XILbl: Label 'XI';
        SpecialSchemeCodeMustMatchErr: Label 'Special Scheme Code must match.';
        SpecialSchemeCodeMustNotMatchErr: Label 'Special Scheme Code must not match.';

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure PurchOrderHasCorrectSpecialSchemeCodeAfterIntracommunitaryVendorValidate()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Scheme Code]
        // [SCENARIO 220567] Purchase Order has "Special Scheme Code" = "09 Intra-Community Acquisition" after updating "Buy-from Vendor No." with intracommunitary vendor
        Initialize();

        // [GIVEN] Purchase Invoice without "Buy-from Vendor No."
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');

        // [WHEN] Update "Buy-from Vendor No." with intracommunitary vendor
        PurchaseHeader.Validate("Buy-from Vendor No.", LibrarySII.CreateVendor(CreateCountryRegionEU()));
        PurchaseHeader.Modify(true);

        // [THEN] "Special Scheme Code" has value "09 Intra-Community Acquisition"
        PurchaseHeader.TestField("Special Scheme Code", PurchaseHeader."Special Scheme Code"::"09 Intra-Community Acquisition");
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes,HandleRecallNotification')]
    [Scope('OnPrem')]
    procedure SalesOrderHasCorrectSpecialSchemeCodeAfterExportCustomerValidate()
    var
        SalesHeader: Record "Sales Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // [FEATURE] [Special Scheme Code]
        // [SCENARIO 232827] Sales Order has "Special Scheme Code" = "01 General" after updating "Sell-to Customer No." with export intracommunitary customer
        Initialize();

        // [GIVEN] Sales Invoice without "Sell-to Customer No."
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [WHEN] Update "Sell-to Customer No." with export customer
        SalesHeader.Validate("Sell-to Customer No.", LibrarySII.CreateCustomer(CreateCountryRegionEU()));
        SalesHeader.Modify(true);

        // [THEN] "Special Scheme Code" has value "02 Export"
        SalesHeader.TestField("Special Scheme Code", SalesHeader."Special Scheme Code"::"01 General");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithIntracommunitaryAndReverseChargeVATXML()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 221521] Reverse Charge VAT entries of intracommunitary invoices exports with node DesgloseIVA

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Intracommunitary Vendor, Reverse Charge VAT and Amount = 21
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::Invoice, CreateCountryRegionEU());
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PurchInvHeader."No.");

        // [WHEN] Generatel XML for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:DesgloseFactura' has subtree 'sii:DesgloseIVA'
        // [THEN] 'sii:CuotaDeducible' has value = 21
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:DesgloseIVA', VATRate, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithIntracommunitaryAndReverseChargeVATXML()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        VATRate: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [XML] [Reverse Charge] [VAT]
        // [SCENARIO 226465] Reverse Charge VAT entries of intracommunitary credit memos exports with node DesgloseIVA

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Intracommunitary Vendor, Reverse Charge VAT and Amount = 21
        LibrarySII.CreatePurchDocWithReverseChargeVAT(
          PurchaseHeader, VATRate, Amount, PurchaseHeader."Document Type"::"Credit Memo", CreateCountryRegionEU());
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.");

        // [WHEN] Generatel XML for Posted Purchase Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] 'sii:DesgloseFactura' has subtree 'sii:DesgloseIVA'
        // [THEN] 'sii:CuotaDeducible' has value = 21
        LibrarySII.VerifyVATInXMLDoc(XMLDoc, 'sii:DesgloseIVA', VATRate, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnSalesInvWithIntracommunitaryCustomer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Sales Invoice with Intracommunitary customer

        Initialize();

        // [GIVEN] Posted Sales Invoice with Intracommunitary Customer
        PostSalesDocWithIntracommunityCustomer(CustLedgerEntry, SalesHeader."Document Type"::Invoice);

        // [WHEN] Generatel XML for Posted Sales Invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnSalesCrMemoWithIntracommunitaryCustomer()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Sales Credit Memo with Intracommunitary customer

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Intracommunitary Customer
        PostSalesDocWithIntracommunityCustomer(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Generatel XML for Posted Sales Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnPurchInvWithIntracommunitaryCustomer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Purchase Invoice with Intracommunitary vendor

        Initialize();

        // [GIVEN] Posted Purchase Invoice with Intracommunitary Vendor
        PostPurchDocWithIntracommunityVendor(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Generatel XML for Posted Purchase Invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdFacturaOtroTok, 'sii:IDType', '02');
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnPurchCrMemoWithIntracommunitaryCustomer()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Purchase Credit Memo with Intracommunitary vendor

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with Intracommunitary vendor
        PostPurchDocWithIntracommunityVendor(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Generatel XML for Posted Purchase Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdFacturaOtroTok, 'sii:IDType', '02');
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathPurchIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnServInvWithIntracommunitaryCustomer()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Service Invoice with Intracommunitary customer

        Initialize();

        // [GIVEN] Posted Service Invoice with Intracommunitary customer
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry, PostServDocWithIntracommunityCustomer(ServiceHeader."Document Type"::Invoice));

        // [WHEN] Generatel XML for Posted Service Invoice
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IDType2OnServCrMemoWithIntracommunitaryCustomer()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 230978] "ID Type" is "02" in SII xml file for Service Credit Memo with Intracommunitary customer

        Initialize();

        // [GIVEN] Posted Service Credit Memo with Intracommunitary customer
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry, PostServDocWithIntracommunityCustomer(ServiceHeader."Document Type"::"Credit Memo"));

        // [WHEN] Generatel XML for Posted Service Credit Memo
        Assert.IsTrue(
          SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false),
          'Xml Document was not Generated properly');

        // [THEN] "ID Type" is "02" in SII xml file
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIdOtroTok, 'sii:IDType', '02');
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes')]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeChangedWhenVendorIsEUAndPayToVendorIsOfESISOCodeOnPurchInv()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        SpecialSchemeCode: Enum "SII Purch. Special Scheme Code";
    begin
        // [SCENARIO 494864] Special Scheme Code gets changed in Purchase Invoice when stan changes Pay to Vendor from EU Vendor to Vendor of Country Region having ES ISO Code.
        Initialize();

        // [GIVEN] Create EU Vendor.
        Vendor.Get(LibrarySII.CreateVendor(CreateCountryRegionEU()));

        // [GIVEN] Create Country Region and Validate ISO Code as ES.
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("ISO Code", ESLbl);
        CountryRegion.Modify(true);

        // [GIVEN] Create Vendor 2 and Validate Country Region Code.
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor2.Validate("Country/Region Code", CountryRegion.Code);
        Vendor2.Modify(true);

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Save Special Scheme Code in a Variable.
        SpecialSchemeCode := PurchaseHeader."Special Scheme Code";

        // [WHEN] Validate Pay-to Vendor No. in Purchase Header.
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor2."No.");
        PurchaseHeader.Modify(true);

        // [VERIFY] Verify Special Scheme Code in Purchase Header is changed.
        Assert.AreNotEqual(SpecialSchemeCode, PurchaseHeader."Special Scheme Code", SpecialSchemeCodeMustNotMatchErr);
    end;

    [Test]
    [HandlerFunctions('HandleConfirmYes')]
    [Scope('OnPrem')]
    procedure SpecialSchemeCodeIsNotChangeWhenVendorisEUAndPayToVendorIsOfXICountryCodeOnPurchInv()
    var
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        CountryRegion: Record "Country/Region";
        PurchaseHeader: Record "Purchase Header";
        SpecialSchemeCode: Enum "SII Purch. Special Scheme Code";
    begin
        // [SCENARIO 494864] Special Scheme Code does not change in Purchase Invoice when stan changes Pay to Vendor from EU Vendor to Vendor of XI Country Region having blank ISO Code.
        Initialize();

        // [GIVEN] Create EU Vendor.
        Vendor.Get(LibrarySII.CreateVendor(CreateCountryRegionEU()));

        // [GIVEN] Create Country Region XI with blank ISO Code.
        CreateCountryRegionXI(CountryRegion);

        // [GIVEN] Create Vendor 2 and Validate Country Region Code.
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor2.Validate("Country/Region Code", CountryRegion.Code);
        Vendor2.Modify(true);

        // [GIVEN] Create Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] Save Special Scheme Code in a Variable.
        SpecialSchemeCode := PurchaseHeader."Special Scheme Code";

        // [WHEN] Validate Pay-to Vendor No. in Purchase Header.
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor2."No.");
        PurchaseHeader.Modify(true);

        // [VERIFY] Verify Special Scheme Code in Purchase Header is not changed.
        Assert.AreEqual(SpecialSchemeCode, PurchaseHeader."Special Scheme Code", SpecialSchemeCodeMustMatchErr);
    end;

    local procedure Initialize()
    begin
        Clear(SIIXMLCreator);
        if IsInitialized then
            exit;

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();

        IsInitialized := true;
    end;

    local procedure CreateCountryRegionEU(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure PostSalesDocWithIntracommunityCustomer(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Customer.Get(LibrarySII.CreateCustomer(CreateCountryRegionEU()));
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader,
          LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));
        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostPurchDocWithIntracommunityVendor(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        Vendor.Get(LibrarySII.CreateVendor(CreateCountryRegionEU()));
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader, LibrarySII.CreateItemWithSpecificVATSetup(Vendor."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));
        VendorLedgerEntry.SetRange("Buy-from Vendor No.", Vendor."No.");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure PostServDocWithIntracommunityCustomer(DocType: Enum "Service Document Type"): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, LibrarySII.CreateCustomer(CreateCountryRegionEU()), '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateCountryRegionXI(var CountryRegion: Record "Country/Region")
    begin
        CountryRegion.Init();
        CountryRegion.Validate(Code, XILbl);
        CountryRegion.Insert(true);
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
}

