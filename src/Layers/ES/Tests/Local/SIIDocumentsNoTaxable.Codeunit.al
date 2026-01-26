codeunit 147524 "SII Documents No Taxable"
{
    // // [FEATURE] [SII] [No Tax]

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
        LibraryJournals: Codeunit "Library - Journals";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XmlType: Option Invoice,"Intra Community",Payment;
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesExemptBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:Entrega/sii:Sujeta/sii:Exenta/';
        XPathSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:Entrega/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        XPathEUServiceSalesBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/sii:PrestacionServicios/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA';
        XPathSalesNoTaxTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros', Locked = true;
        IsInitialized: Boolean;
        XPathSalesNoTaxLocalTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:NoSujeta/sii:ImporteTAIReglasLocalizacion', Locked = true;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathEUSalesNoTaxTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseTipoOperacion/%1/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros', Locked = true;
        NoTaxableSetupErr: Label 'The %1 for VAT Calculation Type = No Taxable VAT must be 0.', Comment = '%1 = VAT or EC percent.';
        AmountShouldBeNegative: Label 'Amount should be in negative.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesWithNoTaxableLineXml()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 221621] XML has node for non taxable amount when multiple lines with Normal VAT and No Taxable VAT exists in Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with multiplines lines, each line has different "VAT %", one has "VAT Calculation Type" ="No Taxable VAT" in VAT Posting Setup
        LibrarySII.PostSalesInvWithMultiplesLinesDiffVAT(CustLedgerEntry, true);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesWithOnlyNoTaxableLineXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 223695] XML has node "Entrega" for non taxable amount if only line with No Taxable VAT exists in Sales Invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with one line where "VAT Calculation Type" = "No Taxable VAT"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, false, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyXml(XMLDoc, CustLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchWithOnlyNoTaxableLineXml()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 223695] XML has node for non taxable amount if only line with No Taxable VAT exists in Purchase Invoice

        Initialize();

        // [GIVEN] Posted Purchase Invoice with one line where "VAT Calculation Type" = "No Taxable VAT"
        PostPurchInvWithNoTaxableVAT(VendorLedgerEntry);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount
        LibrarySII.VerifyXml(XMLDoc, VendorLedgerEntry, XmlType::Invoice, false, false);
        LibrarySII.VerifyXMLPurchNoTaxableAmount(XMLDoc, VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFCYNoTaxableNodeDoesNotExist()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
    begin
        // [FEATURE] [Sales] [FCY] [Invoice]
        // [SCENARIO 223695] XML node for non taxable amount does not exist in XML file for Posted Sales Invoice with FCY

        Initialize();

        // [GIVEN] Posted Sales Invoice with FCY
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        PostSalesInvWithCurrency(CustLedgerEntry, CurrencyCode);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Node sii:ImportePorArticulos7_14_Otros does not exist in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServFCYNoTaxableNodeDoesNotExist()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        CurrencyCode: Code[10];
        ExchangeRateAmount: Decimal;
    begin
        // [FEATURE] [Service] [FCY] [Invoice]
        // [SCENARIO 223695] XML node for non taxable amount does not exist in XML file for Posted Service Invoice with FCY

        Initialize();

        // [GIVEN] Posted Service Invoice with FCY
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount);
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.",
          LibrarySII.PostServDocWithCurrency(ServiceHeader."Document Type"::Invoice, CurrencyCode));
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceInvoiceHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, ServiceInvoiceHeader."No.");

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] Node sii:ImportePorArticulos7_14_Otros does not exist in XML file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithNormalAndNoTaxableLinesXml()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        NormalAmount: Decimal;
        VATRate: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Invoice]
        // [SCENARIO 225228] XML has node for both non taxable and normal amount if both No Taxable VAT and Normal VAT lines exist in Purchase Invoice
        Initialize();

        // [GIVEN] Posted Purchase Invoice with two lines
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice");
        PurchaseHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, NormalAmount, PurchaseHeader, VATBusinessPostingGroup, PurchaseLine."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);

        NonTaxableAmount := GetNonTaxableAmountPurch(PurchaseLine, PurchaseHeader);

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for non taxable amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[1]' + '/sii:BaseImponible',
          SIIXMLCreator.FormatNumber(NonTaxableAmount));

        // [THEN] XML file has sii:BaseImponible node for normal amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[2]' + '/sii:BaseImponible',
          SIIXMLCreator.FormatNumber(NormalAmount));

        // [THEN] XML file has ImporteTotal node with only normal amount
        // TFS ID 338388: The value for Importe Total is incorrect if you create a invoice with the type  difference and have values which are not taxable
        // TFS ID 411251: ImporteTotal includes non taxable amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(GetVATEntryTotalAmount(VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithNormalAndNoTaxableLinesXml()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        NormalAmount: Decimal;
        VATRate: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Invoice]
        // [SCENARIO 225228] XML has node for both non taxable and normal amount if both No Taxable VAT and Normal VAT lines exist in Purchase Credit Memo
        Initialize();

        // [GIVEN] Posted Purchase Cr Memo with two lines
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendNo);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, NormalAmount, PurchaseHeader, VATBusinessPostingGroup, PurchaseLine."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);

        NonTaxableAmount := GetNonTaxableAmountPurch(PurchaseLine, PurchaseHeader);

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for non taxable amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[1]' + '/sii:BaseImponible',
          SIIXMLCreator.FormatNumber(-NonTaxableAmount));

        // [THEN] XML file has sii:BaseImponible node for normal amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '[2]' + '/sii:BaseImponible',
          SIIXMLCreator.FormatNumber(-NormalAmount));

        // [THEN] XML file has ImporteTotal node with only normal amount
        // TFS ID 338388: The value for Importe Total is incorrect if you create a credit memo with the type  difference and have values which are not taxable
        // TFS ID 411251: ImporteTotal includes non taxable amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(GetVATEntryTotalAmount(VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithTwoNoTaxableLineXml()
    var
        PurchaseHeader: Record "Purchase Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225228] XML has node for non taxable amount if two No Taxable VAT lines exist in Purchase Credit Memo
        Initialize();

        // [GIVEN] Posted Purchase Cr Memo with two lines
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendNo);

        // [GIVEN] 2 Purchase lines where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);
        PurchaseHeader.CalcFields(Amount);
        NonTaxableAmount := PurchaseHeader.Amount;

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for non taxable amount of -1000
        // TFS ID 337154: Non Taxable Purchase Credit Memo exports with positive sign
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-NonTaxableAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithOnlyNoTaxableLineXml()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 225228] XML has node with negative non taxable amount if only No Taxable VAT line exists in Purchase Credit Memo
        Initialize();

        // [GIVEN] Posted Purchase Cr Memo with one line
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendNo);

        // [GIVEN] Purchase line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, ItemNo);

        NonTaxableAmount := GetNonTaxableAmountPurch(PurchaseLine, PurchaseHeader);

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for non taxable amount of -500
        // TFS ID 337154: Non Taxable Purchase Credit Memo exports with positive sign
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-NonTaxableAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNormalAndNoTaxableLinesXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        NormalAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 229401] XML has node for both non taxable and normal amount if both No Taxable VAT and Normal VAT lines exist in Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));
        SalesHeader.CalcFields(Amount);
        NormalAmount := SalesHeader.Amount;

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        NonTaxableAmount := GetNonTaxableAmountSales(SalesHeader, SalesLine);

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for normal amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(NormalAmount));

        // [THEN] XML file has sii:ImportePorArticulos7_14_Otros node for non taxable amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:Entrega'), '', SIIXMLCreator.FormatNumber(NonTaxableAmount));

        // [THEN] XML file has ImporteTotal node with only normal amount
        // TFS ID 338388: The value for Importe Total is incorrect if you create a invoice with the type  difference and have values which are not taxable
        // TFS ID 411251: ImporteTotal includes non taxable amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(-GetVATEntryTotalAmount(CustLedgerEntry."Document Type", CustLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDomesticInvoiceWithNormalAndNoTaxableLinesXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 352183] XML has correct sequence of normal and non taxable nodes when export Sales Invoice with domestic customer

        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT"
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT"
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has the following nodes under sii:DesgloseFactura in the following order: sii:Sujeta, sii:NoSujeta
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseFactura', 'sii:Sujeta', 'sii:NoSujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDomesticEUServiceInvoiceWithNormalAndNoTaxableLinesXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 352183] XML has correct sequence of normal and non taxable nodes when export Sales Invoice with domestic customer and EU Service

        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "EU Service" = TRUE
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetupEUService(
            SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25), true));

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "EU Service" = TRUE
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", true, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has the following nodes under sii:DesgloseFactura in the following order: sii:Sujeta, sii:NoSujeta
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseFactura', 'sii:Sujeta', 'sii:NoSujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithNormalAndNoTaxableLinesXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
        NormalAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 229401] XML has node for both non taxable and normal amount if both No Taxable VAT and Normal VAT lines exist in Sales Credit Memo
        Initialize();

        // [GIVEN] Posted Sales Cr Memo with two lines
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));
        SalesHeader.CalcFields(Amount);
        NormalAmount := SalesHeader.Amount;

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        NonTaxableAmount := GetNonTaxableAmountSales(SalesHeader, SalesLine);

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node for normal amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-NormalAmount));

        // [THEN] XML file has sii:ImportePorArticulos7_14_Otros node for non taxable amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:Entrega'), '', SIIXMLCreator.FormatNumber(-NonTaxableAmount));

        // [THEN] XML file has ImporteTotal node with only normal amount
        // TFS ID 338388: The value for Importe Total is incorrect if you create a credit memo with the type  difference and have values which are not taxable
        // TFS ID 411251: ImporteTotal includes non taxable amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(-GetVATEntryTotalAmount(CustLedgerEntry."Document Type", CustLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDomesticCrMemoWithNormalAndNoTaxableLinesXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 352183] XML has correct sequence of normal and non taxable nodes when export Sales Credit Memo with domestic customer

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT"
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT"
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has the following nodes under sii:DesgloseFactura in the following order: sii:Sujeta, sii:NoSujeta
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseFactura', 'sii:Sujeta', 'sii:NoSujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDomesticEUServiceCrMemoWithNormalAndNoTaxableLinesXml()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 352183] XML has correct sequence of normal and non taxable nodes when export Sales Credit Memo with domestic customer and EU Service

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "EU Service" = TRUE
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetupEUService(
            SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25), true));

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "EU Service" = TRUE
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", true, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Bill-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has the following nodes under sii:DesgloseFactura in the following order: sii:Sujeta, sii:NoSujeta
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseFactura', 'sii:Sujeta', 'sii:NoSujeta');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithTwoNoTaxableLineXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 229401] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount if two No Taxable VAT lines exist in Sales Credit Memo
        Initialize();

        // [GIVEN] Posted Sales Cr Memo with two lines
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] 2 Sales Lines where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        SalesHeader.CalcFields(Amount);
        NonTaxableAmount := SalesHeader.Amount;

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:ImportePorArticulos7_14_Otros node for non taxable amount of 1000
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:Entrega'), '', SIIXMLCreator.FormatNumber(-NonTaxableAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithOnlyNoTaxableLineXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NonTaxableAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 229401] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount if only No Taxable VAT line exists in Sales Credit Memo
        Initialize();

        // [GIVEN] Posted Sales Cr Memo with one line
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [GIVEN] Sales Line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        SalesHeader.CalcFields(Amount);
        NonTaxableAmount := SalesHeader.Amount;

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:ImportePorArticulos7_14_Otros node for non taxable amount of 500
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:Entrega'), '', SIIXMLCreator.FormatNumber(-NonTaxableAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeFieldExistsOnVATPostingSetupPage()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 231012] Field "Non Taxable Type" exists on "VAT Posting Setup" page

        Initialize();
        VATPostingSetup.OpenEdit();
        Assert.IsTrue(VATPostingSetup."No Taxable Type".Visible(), 'Field is not visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeFieldExistsOnVATPostingSetupCardPage()
    var
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 231012] Field "Non Taxable Type" exists on "VAT Posting Setup Card" page

        Initialize();
        VATPostingSetupCard.OpenEdit();
        Assert.IsTrue(VATPostingSetupCard."No Taxable Type".Visible(), 'Field is not visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeNoTaxVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [No Taxable VAT]
        // [SCENARIO 231012] Stan can specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is "No Taxable VAT"

        Initialize();
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");
        VATPostingSetup.TestField("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeNormalWhenZeroVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 466990] Stan cannot specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is "Normal VAT" and "VAT %" is <zero>
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT and "VAT %" = <zero>
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", 0);

        // [WHEN] Validate "No Taxable Type" = "Non Taxable Art 7-14 and others"
        asserterror
          VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [THEN] Error when set "No Taxable Type" = "Non Taxable Art 7-14 and others" in VAT Posting Setup
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"No Taxable VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeNormalWhenNonZeroVATRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 466990] Stan cannot specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is "Normal VAT" and "VAT %" is <non-zero>
        Initialize();

        // [GIVEN] VAT Posting Setup with Normal VAT and "VAT %" = 10.0%
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Validate "No Taxable Type" = "Non Taxable Art 7-14 and others"
        asserterror VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [THEN] Error VAT Calculation Type must be equal to 'No Taxable VAT' in VAT Posting Setup.
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"No Taxable VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeFullVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Full VAT]
        // [SCENARIO 466990] Stan cannot specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is Full VAT
        Initialize();

        // [GIVEN] VAT Posting Setup with Full VAT
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");

        // [WHEN] Validate "No Taxable Type" = "Non Taxable Art 7-14 and others"
        asserterror VATPostingSetup.Validate("No Taxable Type",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [THEN] Error VAT Calculation Type must not be Full VAT
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"No Taxable VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeSalesTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Sales Tax]
        // [SCENARIO 466990] Stan cannot specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is Sales Tax
        Initialize();

        // [GIVEN] VAT Posting Setup with Sales Tax
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");

        // [WHEN] Validate "No Taxable Type" = "Non Taxable Art 7-14 and others"
        asserterror VATPostingSetup.Validate("No Taxable Type",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [THEN] Error VAT Calculation Type must not be Sales Tax
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"No Taxable VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeVATCalcTypeReverseCharge()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Reverse Charge VAT]
        // [SCENARIO 466990] Stan cannot specify "Non Taxable Type" in VAT Posting Setup if "VAT Calculation Type" is Reverse Charge VAT
        Initialize();

        // [GIVEN] VAT Posting Setup with Reverse Charge VAT
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Validate "No Taxable Type" = "Non Taxable Art 7-14 and others"
        asserterror VATPostingSetup.Validate("No Taxable Type",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [THEN] Error VAT Calculation Type must not be Reverse Charge VAT
        Assert.ExpectedTestFieldError(VATPostingSetup.FieldCaption("VAT Calculation Type"), Format(VATPostingSetup."VAT Calculation Type"::"No Taxable VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeWhenSwitchToNormalVATWithZeroVATPlusECRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 466990] When change VAT Calculation Type to Normal VAT in VAT Posting Setup with <zero> VAT+EC % then No Taxable Type is reset to ""
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and No Taxable Type "Non Taxable Art 7-14 and others"
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");
        VATPostingSetup.TestField("VAT+EC %", 0);

        // [WHEN] Validate VAT Calculation Type = Normal VAT in VAT Posting Setup
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [THEN] "No Taxable Type" reset to "" in VAT Posting Setup
        VATPostingSetup.TestField("No Taxable Type", VATPostingSetup."No Taxable Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeWhenSwitchToReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Reverse Charge VAT]
        // [SCENARIO 278919] When change VAT Calculation Type to Reverse Charge VAT in VAT Posting Setup then No Taxable Type is cleared
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and No Taxable Type "Non Taxable Art 7-14 and others"
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [WHEN] Validate VAT Calculation Type = Reverse Charge VAT in VAT Posting Setup
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [THEN] "No Taxable Type" is <zero> in VAT Posting Setup
        VATPostingSetup.TestField("No Taxable Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeWhenSwitchToFullVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Full VAT]
        // [SCENARIO 278919] When change VAT Calculation Type to Full VAT in VAT Posting Setup then No Taxable Type is cleared
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and No Taxable Type "Non Taxable Art 7-14 and others"
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [WHEN] Validate VAT Calculation Type = Full VAT in VAT Posting Setup
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");

        // [THEN] "No Taxable Type" is <zero> in VAT Posting Setup
        VATPostingSetup.TestField("No Taxable Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableTypeWhenSwitchToSalesTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable Type] [Sales Tax]
        // [SCENARIO 278919] When change VAT Calculation Type to Sales Tax in VAT Posting Setup then No Taxable Type is cleared
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT and No Taxable Type "Non Taxable Art 7-14 and others"
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [WHEN] Validate VAT Calculation Type = Sales Tax in VAT Posting Setup
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");

        // [THEN] "No Taxable Type" is <zero> in VAT Posting Setup
        VATPostingSetup.TestField("No Taxable Type", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenSwitchToNoTaxableVATWithNonZeroVATPlusECRate()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable VAT] [VAT+EC %]
        // [SCENARIO 466990] When change VAT Calculation Type to No Taxable VAT in VAT Posting Setup with <non-zero> VAT+EC % then error
        Initialize();

        // [GIVEN] VAT Posting Setup with VAT+EC % = 10.0
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT+EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Validate VAT Calculation Type = No Taxable VAT
        asserterror VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");

        // [THEN] Error VAT+EC % must be equal to '0' in VAT Posting Setup
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(NoTaxableSetupErr, VATPostingSetup.FieldCaption("VAT+EC %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenValidateNonZeroVATPlusECRateNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable VAT] [VAT+EC %]
        // [SCENARIO 466990] When validate <non-zero> VAT+EC % in No Taxable VAT Posting Setup then error
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");

        // [WHEN] Validate VAT+EC % = 10.0 in VAT Posting Setup
        asserterror VATPostingSetup.Validate("VAT+EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] Error that VAT + EC % must be 0 for the VAT Calculation Type 
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(NoTaxableSetupErr, VATPostingSetup.FieldCaption("VAT+EC %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenValidateNonZeroVATRateNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable VAT] [VAT %]
        // [SCENARIO 466990] When validate <non-zero> VAT % in No Taxable VAT Posting Setup then error
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");

        // [WHEN] Validate VAT % = 10.0 in VAT Posting Setup
        asserterror VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] Error that VAT % must be 0 for the VAT Calculation Type 
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(NoTaxableSetupErr, VATPostingSetup.FieldCaption("VAT %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenValidateNonZeroECRateNoTaxableVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [No Taxable VAT] [EC %]
        // [SCENARIO 466990] When validate <non-zero> EC % in No Taxable VAT Posting Setup then error
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");

        // [WHEN] Validate EC % = 10.0 in VAT Posting Setup
        asserterror VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] Error that EC % must be 0 for the VAT Calculation Type 
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(NoTaxableSetupErr, VATPostingSetup.FieldCaption("EC %")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPlusECRateWhenNormalVATWithoutNoTaxableType()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VatPlusECRate: Decimal;
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 278919] When validate VAT+EC % = 'X' in VAT Posting Setup with Normal VAT and <zero> No Taxable Type then VAT+EC % = 'X'
        Initialize();
        VatPlusECRate := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] VAT Posting Setup with Normal VAT and <zero> No Taxable Type
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("No Taxable Type", 0);

        // [WHEN] Validate VAT+EC % = 10.0 in VAT Posting Setup
        VATPostingSetup.Validate("VAT+EC %", VatPlusECRate);

        // [THEN] Then VAT+EC % = 10.0 in VAT Posting Setup
        VATPostingSetup.TestField("VAT+EC %", VatPlusECRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATRateWhenNormalVATWithoutNoTaxableType()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VatRate: Decimal;
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 278919] When validate VAT % = 'X' in VAT Posting Setup with Normal VAT and <zero> No Taxable Type then VAT % = 'X'
        Initialize();
        VatRate := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] VAT Posting Setup with Normal VAT and <zero> No Taxable Type
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("No Taxable Type", 0);

        // [WHEN] Validate VAT % = 10.0 in VAT Posting Setup
        VATPostingSetup.Validate("VAT %", VatRate);

        // [THEN] Then VAT % = 10.0 in VAT Posting Setup
        VATPostingSetup.TestField("VAT %", VatRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECRateWhenNormalVATWithoutNoTaxableType()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ECRate: Decimal;
    begin
        // [FEATURE] [UT] [No Taxable Type] [Normal VAT]
        // [SCENARIO 278919] When validate EC % = 'X' in VAT Posting Setup with Normal VAT and <zero> No Taxable Type then EC % = 'X'
        Initialize();
        ECRate := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] VAT Posting Setup with Normal VAT and <zero> No Taxable Type
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("No Taxable Type", 0);

        // [WHEN] Validate EC % = 10.0 in VAT Posting Setup
        VATPostingSetup.Validate("EC %", ECRate);

        // [THEN] Then EC % = 10.0 in VAT Posting Setup
        VATPostingSetup.TestField("EC %", ECRate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPlusECRateWhenReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [VAT %] [EC %] [VAT+EC %] [Reverse Charge VAT]
        // [SCENARIO 278919] When Validate EC % = 'X' in VAT Posting Setup with Reverse Charge VAT with VAT % = 'Y' then VAT+EC % = 'X' + 'Y'
        Initialize();

        // [GIVEN] VAT Posting Setup with Reverse Charge VAT and VAT % = 10.0
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Validate EC % = 5.0 in VAT Posting Setup
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] VAT+EC % = 15.0 in VAT Posting Setup
        VATPostingSetup.TestField("VAT+EC %", VATPostingSetup."VAT %" + VATPostingSetup."EC %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPlusECRateWhenFullVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [VAT %] [EC %] [VAT+EC %] [Full VAT]
        // [SCENARIO 278919] When Validate EC % = 'X' in VAT Posting Setup with Full VAT with VAT % = 'Y' then VAT+EC % = 'X' + 'Y'
        Initialize();

        // [GIVEN] VAT Posting Setup with Full VAT and VAT % = 10.0
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Validate EC % = 5.0 in VAT Posting Setup
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] VAT+EC % = 15.0 in VAT Posting Setup
        VATPostingSetup.TestField("VAT+EC %", VATPostingSetup."VAT %" + VATPostingSetup."EC %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPlusECRateWhenSalesTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT] [VAT %] [EC %] [VAT+EC %] [Full VAT]
        // [SCENARIO 278919] When Validate EC % = 'X' in VAT Posting Setup with Salex Tax with VAT % = 'Y' then VAT+EC % = 'X' + 'Y'
        Initialize();

        // [GIVEN] VAT Posting Setup with Sales Tax and VAT % = 10.0
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [WHEN] Validate EC % = 5.0 in VAT Posting Setup
        VATPostingSetup.Validate("EC %", LibraryRandom.RandDecInRange(10, 20, 2));

        // [THEN] VAT+EC % = 15.0 in VAT Posting Setup
        VATPostingSetup.TestField("VAT+EC %", VATPostingSetup."VAT %" + VATPostingSetup."EC %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvNoTaxableBasic()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 231012] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount when post Sales Invoice with "Non Taxable Type" is "Non Taxable Art 7-14 and others"

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, false,
          VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNoTaxableBasic()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 231012] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount when post Sales Credit Memo with "Non Taxable Type" is "Non Taxable Art 7-14 and others"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", false,
          VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvNoTaxableBasic()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 231012] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount when post Service Invoice with "Non Taxable Type" is "Non Taxable Art 7-14 and others"

        Initialize();

        // [GIVEN] Posted Service Invoice with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::Invoice,
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoNoTaxableBasic()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 231012] XML has node "ImportePorArticulos7_14_Otros" for non taxable amount when post Service Credit Memo with "Non Taxable Type" is "Non Taxable Art 7-14 and others"

        Initialize();

        // [GIVEN] Posted Service Credit Memo with "Non Taxable Type" = "Non Taxable Art 7-14 and others"
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::"Credit Memo",
            VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others"));

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvNoTaxableLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 231012] XML has node "ImporteTAIReglasLocalizacion" for non taxable amount when post Sales Invoice with "Non Taxable Type" is "Non Taxable Due To Localization Rules"

        Initialize();

        // [GIVEN] Posted Sales Invoice with "Non Taxable Type" = "Non Taxable Due To Localization Rules"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, false,
          VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules");

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNoTaxableLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 231012] XML has node "ImporteTAIReglasLocalizacion" for non taxable amount when post Sales Credit Memo with "Non Taxable Type" is "Non Taxable Due To Localization Rules"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Non Taxable Type" = "Non Taxable Due To Localization Rules"
        LibrarySII.PostSalesDocWithNoTaxableVAT(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", false,
          VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvNoTaxableLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 231012] XML has node "ImporteTAIReglasLocalizacion" for non taxable amount when post Service Invoice with "Non Taxable Type" is "Non Taxable Due To Localization Rules"

        Initialize();

        // [GIVEN] Posted Service Invoice with "Non Taxable Type" = "Non Taxable Due To Localization Rules"
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::Invoice,
            VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules"));

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoNoTaxableLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 231012] XML has node "ImporteTAIReglasLocalizacion" for non taxable amount when post Service Credit Memo with "Non Taxable Type" is "Non Taxable Due To Localization Rules"

        Initialize();

        // [GIVEN] Posted Service Credit Memo with "Non Taxable Type" = "Non Taxable Due To Localization Rules"
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          LibrarySII.PostServiceDocWithNonTaxableVAT(ServiceHeader."Document Type"::"Credit Memo",
            VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules"));

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMixedOfEUNonServiceExemptAndNoTaxEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [EU Service] [No Tax] [Exemption]
        // [SCENARIO 310154] XML file structure is correct when export sales invoice with mix of EU Service, Non-EU Service, Normal, VAT Exemption and No Taxable VAT

        Initialize();

        // [GIVEN] Sales Invoice with multiple lines: Normal VAT and not EU Service, VAT Exemption and EU Service, No Taxable VAT and EU Service
        PostSalesDocWithMixedOfEUNonServiceExemptAndNoTaxEntries(
          CustLedgerEntry, NormalVATPostingSetup, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There are two nodes under "DesgloseTipoOperacion" node in the following order: "PrestacionServicios" (for EU service) and "Entrega'"(for non-EU service)
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseTipoOperacion', 'sii:PrestacionServicios', 'sii:Entrega');

        // [THEN] "sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" node with Normal VAT
        VATEntry.SetRange("VAT Prod. Posting Group", NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" with VAT Exemption
        VATEntry.SetFilter("VAT Prod. Posting Group", '<>%1', NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExemptBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:DesgloseTipoOperacion/PrestacionServicios/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros" with No Taxable VAT
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry) + VATEntry.Base)); // Add VAT Exemption because it doesn't count on No Tax VAT calculation
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoMixedOfEUNonServiceExemptAndNoTaxEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [EU Service] [No Tax] [Exemption]
        // [SCENARIO 310154] XML file structure is correct when export sales credit memo with mix of EU Service, Non-EU Service, Normal, VAT Exemption and No Taxable VAT

        Initialize();

        // [GIVEN] Sales Credit Memo with multiple lines: Normal VAT and not EU Service, VAT Exemption and EU Service, No Taxable VAT and EU Service
        PostSalesDocWithMixedOfEUNonServiceExemptAndNoTaxEntries(
          CustLedgerEntry, NormalVATPostingSetup, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] There are two nodes under "DesgloseTipoOperacion" node in the following order: "PrestacionServicios" (for EU service) and "Entrega'"(for non-EU service)
        LibrarySII.VerifySequenceOfTwoChildNodes(XMLDoc, 'sii:DesgloseTipoOperacion', 'sii:PrestacionServicios', 'sii:Entrega');

        // [THEN] "sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" node with Normal VAT
        VATEntry.SetRange("VAT Prod. Posting Group", NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" with VAT Exemption
        VATEntry.SetFilter("VAT Prod. Posting Group", '<>%1', NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExemptBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:DesgloseTipoOperacion/PrestacionServicios/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros" with No Taxable VAT
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry) + VATEntry.Base)); // Add VAT Exemption because it doesn't count on No Tax VAT calculation
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceEUServiceNormalAndNoTaxable()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [EU Service] [No Tax] [Exemption]
        // [SCENARIO 310154] XML file structure is correct when export sales invoice with EU Service, Normal and No Taxable VAT

        Initialize();

        // [GIVEN] Sales Invoice with multiple lines: Normal VAT and not EU Service, VAT Exemption and EU Service, No Taxable VAT and EU Service
        PostSalesDocWithEUServiceNormalAndNoTaxableVAT(
          CustLedgerEntry, NormalVATPostingSetup, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "sii:PrestacionServicios/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" node with Normal VAT
        VATEntry.SetRange("VAT Prod. Posting Group", NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathEUServiceSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:DesgloseTipoOperacion/PrestacionServicios/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros" with No Taxable VAT
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoEUServiceNormalAndNoTaxable()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [EU Service] [No Tax] [Exemption]
        // [SCENARIO 310154] XML file structure is correct when export sales credit memo with EU Service, Normal and No Taxable VAT

        Initialize();

        // [GIVEN] Sales Credit Memo with multiple lines: Normal VAT and not EU Service, VAT Exemption and EU Service, No Taxable VAT and EU Service
        PostSalesDocWithEUServiceNormalAndNoTaxableVAT(
          CustLedgerEntry, NormalVATPostingSetup, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "sii:PrestacionServicios/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/sii:BaseImponible" node with Normal VAT
        VATEntry.SetRange("VAT Prod. Posting Group", NormalVATPostingSetup."VAT Prod. Posting Group");
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", CustLedgerEntry."Document No.");
        VATEntry.SetRange("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Normal VAT");
        VATEntry.FindFirst();
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathEUServiceSalesBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(-VATEntry.Base));

        // [THEN] "sii:DesgloseTipoOperacion/PrestacionServicios/sii:NoSujeta/sii:ImportePorArticulos7_14_Otros" with No Taxable VAT
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromSalesInvNoTaxAmtCalculation()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 234078] Sales Invoice Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Sales Invoice with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        PostSalesDocWithGLAccIgnoredIn347Report(CustLedgerEntry, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "ImportePorArticulos7_14_Otros" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromSalesCrMemoNoTaxAmtCalculation()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo[
        // [SCENARIO 234078] Sales Credit Memo Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Sales Credit Memo with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        PostSalesDocWithGLAccIgnoredIn347Report(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "ImportePorArticulos7_14_Otros" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromPurchInvNoTaxAmtCalculation()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 234078] Purchase Invoice Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Purchase Invoice with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        PostPurchDocWithGLAccIgnoredIn347Report(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "BaseImponible" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:BaseImponible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromPurchCrMemoNoTaxAmtCalculation()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 234078] Purchase Credit Memo Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Purchase Credit Memo with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        PostPurchDocWithGLAccIgnoredIn347Report(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "BaseImponible" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:BaseImponible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromServInvNoTaxAmtCalculation()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 234078] Service Invoice Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Service Invoice with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          PostServDocWithGLAccIgnoredIn347Report(ServiceHeader."Document Type"::Invoice));

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "ImportePorArticulos7_14_Otros" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IgnoreIn347ReportAccountFromServCrMemoNoTaxAmtCalculation()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo[
        // [SCENARIO 234078] Service Credit Memo Lines with G/L Accounts where "Ignore in 357 Report" is set ignores in Non Taxable VAT Amount calculation

        // [GIVEN] Posted Service Credit Memo with G/L Account for Non Taxable VAT and "Ignore in 357 Report"
        Initialize();
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDocWithGLAccIgnoredIn347Report(ServiceHeader."Document Type"::"Credit Memo"));

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No node "ImportePorArticulos7_14_Otros" for excluded Non Taxable VAT Amount in xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:ImportePorArticulos7_14_Otros');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithNoTaxableLineWithHundredPctDisc()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 263409] XML has node for non taxable amount when No Taxable VAT line with 100% discount exists in Sales Invoice
        Initialize();

        // [GIVEN] Posted Sales Invoice with "VAT Calculation Type" ="No Taxable VAT" and "Line Discount %" = 100
        PostSalesDocWithNoTaxableVATAndHundredPctDisc(CustLedgerEntry, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for zero non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithNoTaxableLineWithHundredPctDisc()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 263409] XML has node for non taxable amount when No Taxable VAT line with 100% discount exists in Sales Credit Memo
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "VAT Calculation Type" ="No Taxable VAT" and "Line Discount %" = 100
        PostSalesDocWithNoTaxableVATAndHundredPctDisc(CustLedgerEntry, SalesHeader."Document Type"::Invoice);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for zero non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServInvWithNoTaxableLineWithHundredPctDisc()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 263409] XML has node for non taxable amount when No Taxable VAT line with 100% discount exists in Service Invoice
        Initialize();

        // [GIVEN] Posted Service Invoice with "VAT Calculation Type" ="No Taxable VAT" and "Line Discount %" = 100
        LibrarySII.FindCustLedgEntryForPostedServInvoice(
          CustLedgerEntry,
          PostServDocWithNoTaxableVATAndHundredPctDisc(ServiceHeader."Document Type"::Invoice));

        // [WHEN] Create xml for Posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for zero non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServCrMemoWithNoTaxableLineWithHundredPctDisc()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 263409] XML has node for non taxable amount when No Taxable VAT line with 100% discount exists in Service Credit Memo
        Initialize();

        // [GIVEN] Posted Service Credit Memo with "VAT Calculation Type" ="No Taxable VAT" and "Line Discount %" = 100
        LibrarySII.FindCustLedgEntryForPostedServCrMemo(
          CustLedgerEntry,
          PostServDocWithNoTaxableVATAndHundredPctDisc(ServiceHeader."Document Type"::"Credit Memo"));

        // [WHEN] Create xml for Posted Service Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for zero non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '', SIIXMLCreator.FormatNumber(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNoTaxableVATPostedFromJournalEUService()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 267012] XML has node "PrestacionServicios" for non taxable amount and EU service when post sales invoice from journal

        Initialize();

        // [GIVEN] Post sales invoice from journal with "No Taxable VAT" and EU Service
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        PostGenJnlLine(
          GenJournalLine, Customer."VAT Bus. Posting Group", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Gen. Posting Type"::Sale, true,
          LibraryRandom.RandDec(100, 2));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [WHEN] Create xml for posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNoTaxableVATPostedFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267012] XML has node "PrestacionServicios" for non taxable amount when post sales invoice from journal

        Initialize();

        // [GIVEN] Post sales invoice from journal with "No Taxable VAT"
        LibrarySales.CreateCustomer(Customer);
        PostGenJnlLine(
          GenJournalLine, Customer."VAT Bus. Posting Group", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Gen. Posting Type"::Sale, false,
          LibraryRandom.RandDec(100, 2));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [WHEN] Create xml for posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithNoTaxableVATPostedFromJournalEUService()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [EU Service]
        // [SCENARIO 267012] XML has node "PrestacionServicios" for non taxable amount and EU service when post sales credit memo from journal

        Initialize();

        // [GIVEN] Post sales credit memo from journal with "No Taxable VAT" and EU Service
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        PostGenJnlLine(
          GenJournalLine, Customer."VAT Bus. Posting Group", GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Gen. Posting Type"::Sale, true,
          -LibraryRandom.RandDec(100, 2));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Create xml for posted sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithNoTaxableVATPostedFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267012] XML has node "PrestacionServicios" for non taxable amount when post sales credit memo from journal

        Initialize();

        // [GIVEN] Post sales credit memo from journal with "No Taxable VAT"
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        PostGenJnlLine(
          GenJournalLine, Customer."VAT Bus. Posting Group", GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Gen. Posting Type"::Sale, true,
          -LibraryRandom.RandDec(100, 2));

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Create xml for posted sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImportePorArticulos7_14_Otros
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:PrestacionServicios'), '',
          SIIXMLCreator.FormatNumber(GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithNoTaxableVATPostedFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267012] XML has node "BaseImponible" with non taxable amount when post purchase invoice from journal

        Initialize();

        // [GIVEN] Post purchase invoice from journal with "No Taxable VAT"
        LibraryPurchase.CreateVendor(Vendor);
        PostGenJnlLine(
          GenJournalLine, Vendor."VAT Bus. Posting Group", GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Bal. Gen. Posting Type"::Purchase, false,
          -LibraryRandom.RandDec(100, 2));

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Document No.");

        // [WHEN] Create xml for posted purchase invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node BaseImponible with No Taxable Amount
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithNoTaxableVATPostedFromJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267012] XML has node "BaseImponible" with non taxable amount when post purchase credit memo from journal

        Initialize();

        // [GIVEN] Post purchase credit memo from journal with "No Taxable VAT"
        LibraryPurchase.CreateVendor(Vendor);
        PostGenJnlLine(
          GenJournalLine, Vendor."VAT Bus. Posting Group", GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Account Type"::Vendor, Vendor."No.", GenJournalLine."Bal. Gen. Posting Type"::Purchase, false,
          LibraryRandom.RandDec(100, 2));

        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Document No.");

        // [WHEN] Create xml for posted purchase credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has node BaseImponible with No Taxable Amount
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-GenJournalLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSujeta_SalesWhenVATNonTaxableDueToLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [No Taxable Type]
        // [SCENARIO 466990] XML has node sii:NoSujeta with child node sii:ImporteTAIReglasLocalizacion
        // [SCENARIO 466990] When Sales Invoice was posted with No Taxable VAT Posting Setup having No Taxable Type = Non Taxable Due To Localization Rules
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT, <zero> VAT Rate and No Taxable Type = "Non Taxable Due To Localization Rules"
        CreateVATPostingSetupWithNoTaxableType(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT",
          VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules", 0);

        // [GIVEN] Posted Sales Invoice with Amount 1000.0
        CreateSalesInvoiceWithVATPostingSetup(SalesHeader, VATPostingSetup);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create XML for posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        // [THEN] Node sii:ImporteTAIReglasLocalizacion has value 1000.0
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesNoTaxLocalTok, '', SIIXMLCreator.FormatNumber(SalesHeader.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSujeta_ServWhenNonTaxableDueToLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        Amount: Decimal;
    begin
        // [FEATURE] [Service] [No Taxable Type]
        // [SCENARIO 466990] XML has node sii:NoSujeta with child node sii:ImporteTAIReglasLocalizacion
        // [SCENARIO 466990] When Service Invoice was posted with No Taxable VAT Posting Setup having No Taxable Type = Non Taxable Due To Localization Rules
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT, <zero> VAT Rate and No Taxable Type = "Non Taxable Due To Localization Rules"
        CreateVATPostingSetupWithNoTaxableType(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT",
          VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules", 0);

        // [GIVEN] Posted Service Invoice with Amount 1000.0
        CreateServiceInvoiceWithVATPostingSetup(ServiceHeader, Amount, VATPostingSetup);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostServiceInvoice(ServiceHeader));

        // [WHEN] Create XML for posted Service Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        // [THEN] Node sii:ImporteTAIReglasLocalizacion has value 1000.0
        LibrarySII.VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesNoTaxLocalTok, '', SIIXMLCreator.FormatNumber(Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoSujeta_PurchWhenVATNonTaxableDueToLocalizationRules()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [No Taxable Type]
        // [SCENARIO 466990] XML has node sii:BaseImponible
        // [SCENARIO 466990] When Purchase Invoice was posted with No Taxable VAT Posting Setup having No Taxable Type = Non Taxable Due To Localization Rules
        Initialize();

        // [GIVEN] VAT Posting Setup with No Taxable VAT, <zero> VAT Rate and No Taxable Type = "Non Taxable Due To Localization Rules"
        CreateVATPostingSetupWithNoTaxableType(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT",
          VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules", 0);

        // [GIVEN] Posted Purchase Invoice with Amount 1000.0
        CreatePurchaseInvoiceWithVATPostingSetup(PurchaseHeader, VATPostingSetup);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create XML for posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:BaseImponible node with Amount 1000.0
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, '/sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseHeader.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithCurrencyAndNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice] [FCY]
        // [SCENARIO 298931] No Taxable node has value in local currency when export sales invoice

        Initialize();

        // [GIVEN] Posted Sales Invoice with currency code, Amount = 100 and "Amount (LCY)" = 33
        CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Invoice);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create XML for posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] A "sii:ImportePorArticulos7_14_Otros" node has value 33
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithCurrencyAndNoTaxableVAT()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo] [FCY]
        // [SCENARIO 298931] No Taxable node has value in local currency when export sales credit memo

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with currency code, Amount = 100 and "Amount (LCY)" = 33
        CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Create XML for posted sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] A "sii:ImportePorArticulos7_14_Otros" node has value -33
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithCurrencyAndNoTaxableVAT()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice] [FCY]
        // [SCENARIO 298931] No Taxable node has value in local currency when export service invoice

        Initialize();

        // [GIVEN] Posted Service Invoice with currency code, Amount = 100 and "Amount (LCY)" = 33
        CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostServiceInvoice(ServiceHeader));

        // [WHEN] Create XML for posted service invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] A "sii:ImportePorArticulos7_14_Otros" node has value 33
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithCurrencyAndNoTaxableVAT()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo] [FCY]
        // [SCENARIO 298931] No Taxable node has value in local currency when export service credit memo

        Initialize();

        // [GIVEN] Posted Service Credit Memo with currency code, Amount = 100 and "Amount (LCY)" = 33
        CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", PostServiceCrMemo(ServiceHeader));

        // [WHEN] Create XML for posted service credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] A "sii:ImportePorArticulos7_14_Otros" node has value -33
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxTok, '',
          SIIXMLCreator.FormatNumber(-LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReplacementCrMemoWithNonTaxableLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        InvNo: Code[20];
        InvNonTaxableAmount: Decimal;
        CrMemoNonTaxableAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 327256] XML has nodes for non taxable amount if No Taxable VAT line exist in Replacement Sales Credit Memo

        Initialize();

        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));

        // [GIVEN] Posted Replacement Sales Invoice "A" with "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        InvNonTaxableAmount := GetNonTaxableAmountSales(SalesHeader, SalesLine);
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [GIVEN] Posted Replacement Sales Cr Memo with two lines and "Corrected Invoice No" = "A", "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 300
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesHeader.Validate("Correction Type", SalesHeader."Correction Type"::Replacement);
        SalesHeader.Validate("Corrected Invoice No.", InvNo);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        CrMemoNonTaxableAmount := GetNonTaxableAmountSales(SalesHeader, SalesLine);

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Replacement Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has sii:ImportePorArticulos7_14_Otros node for non taxable amount 200
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, StrSubstNo(XPathEUSalesNoTaxTok, 'sii:Entrega'), '',
          SIIXMLCreator.FormatNumber(Abs(InvNonTaxableAmount - CrMemoNonTaxableAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithNormalAndNegativeTaxableLinesXml()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NormalAmount: Decimal;
        VATRate: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 386572] XML has negative non taxable node if it has negative amount in Purchase Invoice

        Initialize();

        // [GIVEN] Posted Purchase Invoice with two lines
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice");
        PurchaseHeader.Modify(true);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, NormalAmount, PurchaseHeader, VATBusinessPostingGroup, PurchaseLine."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = -500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, -LibraryRandom.RandInt(100));
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandInt(100));

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice,
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has just two sii:BaseImponible nodes - for normal and non-taxable VAT
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);

        // [THEN] XML file has ImporteTotal node with only normal amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(GetVATEntryTotalAmount(VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithNormalAndNegativeNoTaxableLinesXml()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
        NormalAmount: Decimal;
        VATRate: Decimal;
        VendNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 386572] XML has negative non taxable node if it has negative amount in Purchase Credit Memo
        Initialize();

        // [GIVEN] Posted Purchase Cr Memo with two lines
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendNo);

        // [GIVEN] 1st line where "VAT Calculation Type" = "Normal VAT", "VAT %" = 21 and Amount = 1000
        LibrarySII.CreatePurchLineWithSetup(
          VATRate, NormalAmount, PurchaseHeader, VATBusinessPostingGroup, PurchaseLine."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] 2nd line where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = -500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, -LibraryRandom.RandInt(100));
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandInt(100));

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has just two sii:BaseImponible nodes - for normal and non-taxable VAT
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 2);

        // [THEN] XML file has ImporteTotal node with only normal amount
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(GetVATEntryTotalAmount(VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxablePurchInvoiceWithSpecialSchemeCode08DoesNotHaveVATXmlNodes()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 381227] XML request does not have TipoImpositivo and CuotaSoportada nodes for Purchase Invoice with no taxable VAT and "Special Scheme Code" = "08  IPSI / IGIC"

        Initialize();

        // [GIVEN] Posted Purchase Invoice with one line where "VAT Calculation Type" = "No Taxable VAT"
        PostPurchInvWithNoTaxableVATAndSpecialSchemeCode(VendorLedgerEntry, PurchaseHeader."Special Scheme Code"::"08  IPSI / IGIC");

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No "sii:TipoImpositivo" xml node present in the xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:TipoImpositivo');

        // [THEN] No "sii:CuotaSoportada" xml node present in the xml file
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CuotaSoportada');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoTaxEntriesWithDiffNoTaxType()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        XMLDoc: DotNet XmlDocument;
        NoTaxType: Integer;
    begin
        // [FEATURE] [EU Service] [No Tax]
        // [SCENARIO 449799] A single NoSujeta xml node creates for a sales invoice with a foreign customer and two No Taxable VAT lines with EU Service and differrent No Taxable Type

        Initialize();

        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        for NoTaxType := VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others" to
            VATPostingSetup."No Taxable Type"::"Non Taxable Due To Localization Rules"
        do begin
            LibrarySII.CreateSalesLineWithUnitPrice(
              SalesHeader,
              LibrarySII.CreateItemNoWithSpecificVATSetup(
                LibrarySII.CreateSpecificNoTaxableVATSetup(SalesHeader."VAT Bus. Posting Group", true, 0)));
            SalesLine.FindLast();
            VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
            VATPostingSetup.Validate("No Taxable Type", NoTaxType);
            VATPostingSetup.Validate("EU Service", true);
            VATPostingSetup.Modify(true);
        end;

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type", LibrarySales.PostSalesDocument(SalesHeader, false, false));
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:NoSujeta', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoTaxableSalesInvoiceWithSpecialSchemeCode08DoesNotHaveVATXmlNodes()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 231012] XML has node "ImporteTAIReglasLocalizacion" for non taxable amount when post Sales Invoice with "Non Taxable Type" is blank and "Special Scheme Code" = "08  IPSI / IGIC"

        Initialize();

        // [GIVEN] Posted sales Invoice with one line where "VAT Calculation Type" = "No Taxable VAT"
        PostSalesInvWithNoTaxableVATAndSpecialSchemeCode(CustLedgerEntry, SalesHeader."Special Scheme Code"::"08  IPSI / IGIC");

        // [WHEN] Create xml for Posted sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has nodes for non taxable amount: sii:DesgloseFactura -> sii:NoSujeta -> sii:ImporteTAIReglasLocalizacion
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(LibrarySII.CalcSalesNoTaxableAmount(CustLedgerEntry)));
    end;

    [Test]
    procedure SalesInvoiceWithOneStopShopOption()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A sales invoice with One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Sales invoice
        PostSalesDocWithOneStopShop(CustLedgerEntry, "Sales Document Type"::Invoice, 0);

        // [WHEN] Create xml for sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has a sii:ImporteTAIReglasLocalizacion node with the VAT amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(GetVATBaseAmountFromCustLedgEntry(CustLedgerEntry)));
    end;

    [Test]
    procedure SalesCrMemoWithOneStopShopOption()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A sales credit memo with One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Sales credit memo
        PostSalesDocWithOneStopShop(CustLedgerEntry, "Sales Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has a sii:ImporteTAIReglasLocalizacion node with the VAT amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(GetVATBaseAmountFromCustLedgEntry(CustLedgerEntry)));
    end;

    [Test]
    procedure ReplacementSalesCrMemoWithOneStopShopOption()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A replacement sales credit memo with One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Sales credit memo with "Correction Type" = "Replacement"
        PostSalesDocWithOneStopShop(
          CustLedgerEntry, "Sales Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has a sii:ImporteTAIReglasLocalizacion node with the VAT amount
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoTaxLocalTok, '',
          SIIXMLCreator.FormatNumber(GetVATBaseAmountFromCustLedgEntry(CustLedgerEntry)));
    end;

    [Test]
    procedure SalesInvoiceWithMixedOneStopShopOptions()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A sales invoice with several lines and different One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] Sales invoice with two lines
        // [GIVEN] One line has VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Other line has VAT Posting Setup with "One Stop Shop" option enabled
        PostSalesDocWithMixedOneStopShopOptions(CustLedgerEntry, "Sales Document Type"::Invoice, 0);

        // [WHEN] Create xml for sales invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has both sii:BaseImponible and sii:ImporteTAIReglasLocalizacion nodes
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImporteTAIReglasLocalizacion', 1);
    end;

    [Test]
    procedure SalesCrMemoWithMixedOneStopShopOptions()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A sales credit memo with several lines and different One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] Sales credit memo with two lines
        // [GIVEN] One line has VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Other line has VAT Posting Setup with "One Stop Shop" option enabled
        PostSalesDocWithMixedOneStopShopOptions(CustLedgerEntry, "Sales Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has both sii:BaseImponible and sii:ImporteTAIReglasLocalizacion nodes
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImporteTAIReglasLocalizacion', 1);
    end;

    [Test]
    procedure ReplacementSalesCrMemoWithMixedOneStopShopOptions()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 504302] A replacement sales credit memo with several lines and different One Stop Shop option is correctly reported to the SII

        Initialize();
        // [GIVEN] Sales credit memo with "Correction Type" = "Replacement" and two lines
        // [GIVEN] One line has VAT Posting Setup with "One Stop Shop" option enabled
        // [GIVEN] Other line has VAT Posting Setup with "One Stop Shop" option enabled
        PostSalesDocWithMixedOneStopShopOptions(
          CustLedgerEntry, "Sales Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for sales credit memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has both sii:BaseImponible and sii:ImporteTAIReglasLocalizacion nodes
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImporteTAIReglasLocalizacion', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceTypeR4NormalAndNoTaxableLinesXml()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
        ItemNo: Code[20];
    begin
        // [SCENARIO 535796] "Cuando el importe total está cumplimentado, debe ser igual a la suma de las bases imponibles más las cuotas..."
        // error if you use Invoice type R4 for EU and EXPORT invoices together with Include ImporteTotal in the Spanish version.
        Initialize();

        // [GIVEN] "Include Importe Total" is enabled in the SII Setup
        SetIncludeImporteTotalInSIISetup();

        // [GIVEN] Create Sales Invoice with Special Scheme Code as "02 Export" and Invoice Type as "R4 Corrected Invoice (Other)"
        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"R4 Corrected Invoice (Other)");
        SalesHeader.Modify(true);

        // [GIVEN] Create Sales line with Item where "VAT Calculation Type" = "No Taxable VAT", "VAT %" = 0 and Amount = 500
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));

        // [THEN] Post Sales Invoice and Find Posted Customer Ledger Entry
        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice,
          LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML file has ImporteTotal node contains negative amount
        Assert.IsTrue((GetVATEntryTotalAmount(CustLedgerEntry."Document Type", CustLedgerEntry."Document No.") < 0), AmountShouldBeNegative);
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:ImporteTotal',
          SIIXMLCreator.FormatNumber(GetVATEntryTotalAmount(CustLedgerEntry."Document Type", CustLedgerEntry."Document No.")));
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

    local procedure CreateVATPostingSetupWithNoTaxableType(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; NoTaxableType: Integer; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType, VATRate);
        VATPostingSetup.Validate("No Taxable Type", NoTaxableType);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithVATPostingSetup(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcFields(Amount);
    end;

    local procedure CreateServiceInvoiceWithVATPostingSetup(var ServiceHeader: Record "Service Header"; var Amount: Decimal; VATPostingSetup: Record "VAT Posting Setup")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
        Amount := ServiceLine.Amount;
    end;

    local procedure CreatePurchaseInvoiceWithVATPostingSetup(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields(Amount);
    end;

    local procedure CreateSalesDocumentWithCurrency(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        ExchRateAmount: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        ExchRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        SalesHeader.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRateAmount, ExchRateAmount));
        SalesHeader.Modify(true);

        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocumentWithCurrency(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
        ExchRateAmount: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(
          ServiceHeader, DocType, Customer."No.");
        ExchRateAmount := LibraryRandom.RandDecInRange(10, 50, 2);
        ServiceHeader.Validate("Currency Code",
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRateAmount, ExchRateAmount));
        ServiceHeader.Modify(true);

        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
    end;

    local procedure PostServiceInvoice(ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure PostServiceCrMemo(ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceCrMemoHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure PostPurchInvWithNoTaxableVAT(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        PostCustomPurchInv(VendLedgEntry, "SII Purch. Special Scheme Code"::"01 General");
    end;

    local procedure PostPurchInvWithNoTaxableVATAndSpecialSchemeCode(var VendLedgEntry: Record "Vendor Ledger Entry"; SpecialSchemeCode: Enum "SII Purch. Special Scheme Code")
    begin
        PostCustomPurchInv(VendLedgEntry, SpecialSchemeCode);
    end;

    local procedure PostCustomPurchInv(var VendLedgEntry: Record "Vendor Ledger Entry"; SpecialSchemeCode: Enum "SII Purch. Special Scheme Code")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchHeader: Record "Purchase Header";
        VendNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        PurchHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        PurchHeader.Modify(true);
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        LibrarySII.CreatePurchLineWithUnitCost(PurchHeader, ItemNo);

        VendLedgEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchHeader, false, false));
    end;

    local procedure PostSalesInvWithCurrency(var CustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesDocWithMixedOfEUNonServiceExemptAndNoTaxEntries(var CustLedgerEntry: Record "Cust. Ledger Entry"; var VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        VATClause: Record "VAT Clause";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));

        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);

        // Normal VAT with EU Service = False
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(VATPostingSetup."VAT Prod. Posting Group"));

        // VAT Exemption with EU Service
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(Customer."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E1 Exempt on account of Article 20")));

        // No Taxable with EU Service
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", true, 0)));

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesDocWithEUServiceNormalAndNoTaxableVAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; var VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 25));
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);

        LibrarySII.CreateForeignCustWithVATSetup(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);

        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(VATPostingSetup."VAT Prod. Posting Group"));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", true, 0)));

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesDocWithGLAccIgnoredIn347Report(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type")
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group",
          LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        GLAccount.Validate("Ignore in 347 Report", true);
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(100));
        LibrarySII.UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesInvWithNoTaxableVATAndSpecialSchemeCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; SpecialSchemeCode: Enum "SII Sales Special Scheme Code")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        SalesHeader.Modify(true);
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostPurchDocWithGLAccIgnoredIn347Report(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendNo: Code[20];
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendNo := LibrarySII.CreateVendWithVATSetup(VATBusinessPostingGroup.Code);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GLAccount.Validate("VAT Prod. Posting Group",
          LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusinessPostingGroup.Code, false, 0));
        GLAccount.Validate("Ignore in 347 Report", true);
        GLAccount.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(100));
        LibrarySII.UpdateDirectUnitCostPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));

        VendorLedgerEntry.SetRange("Buy-from Vendor No.", VendNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false));
    end;

    local procedure PostServDocWithGLAccIgnoredIn347Report(DocType: Enum "Service Document Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, Customer."No.", '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group",
          LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
        GLAccount.Validate("Ignore in 347 Report", true);
        GLAccount.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure PostSalesDocWithNoTaxableVATAndHundredPctDisc(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader, LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0)));
        FindLastSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify(true);
        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostServDocWithNoTaxableVATAndHundredPctDisc(DocType: Enum "Service Document Type"): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ItemNo: Code[20];
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, Customer."No.");
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ItemNo :=
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateSpecificNoTaxableVATSetup(ServiceHeader."VAT Bus. Posting Group", false, 0));
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Line Discount %", 100);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure PostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; VATBusPostGroupCode: Code[20]; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; GenPostingType: Enum "General Posting Type"; EUService: Boolean; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        GLAccount.Validate("VAT Prod. Posting Group",
          LibrarySII.CreateSpecificNoTaxableVATSetup(VATBusPostGroupCode, EUService, 0));
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Modify(true);

        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocType, AccType, AccNo, GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetNonTaxableAmountPurch(PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"): Decimal
    var
        NonTaxableAmount: Decimal;
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("VAT Calculation Type", PurchaseLine."VAT Calculation Type"::"No Taxable VAT");
        PurchaseLine.FindFirst();
        NonTaxableAmount := PurchaseLine."Line Amount";
        exit(NonTaxableAmount);
    end;

    local procedure GetNonTaxableAmountSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"): Decimal
    var
        NonTaxableAmount: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("VAT Calculation Type", SalesLine."VAT Calculation Type"::"No Taxable VAT");
        SalesLine.FindFirst();
        NonTaxableAmount := SalesLine."Line Amount";
        exit(NonTaxableAmount);
    end;

    local procedure FindLastSalesLine(var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; DocNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindLast();
    end;

    local procedure GetVATEntryTotalAmount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
        NoTaxableEntry: Record "No Taxable Entry";
    begin
        VATEntry.SetRange("Document Type", DocType);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.CalcSums(Base, Amount);
        NoTaxableEntry.SetRange("Document Type", DocType);
        NoTaxableEntry.SetRange("Document No.", DocNo);
        NoTaxableEntry.CalcSums(Base);
        exit(VATEntry.Base + VATEntry.Amount + NoTaxableEntry.Base);
    end;

    local procedure PostSalesDocWithOneStopShop(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        VATBusinessPostingGroup.Get(SalesHeader."VAT Bus. Posting Group");
        LibrarySII.CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50), false);
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");
        VATPostingSetup.Validate("One Stop Shop Reporting", true);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    procedure PostSalesDocWithMixedOneStopShopOptions(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        SalesLine: Record "Sales Line";
        OneStopShopOption: Boolean;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        VATBusinessPostingGroup.Get(SalesHeader."VAT Bus. Posting Group");
        for OneStopShopOption := false to true do begin
            LibrarySII.CreateVATPostingSetup(
              VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
              VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50), false);
            VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");
            VATPostingSetup.Validate("One Stop Shop Reporting", OneStopShopOption);
            VATPostingSetup.Modify(true);
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
            SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure GetVATBaseAmountFromCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", CustLedgEntry."Document Type");
        VATEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        VATEntry.SetRange("Posting Date", CustLedgEntry."Posting Date");
        VATEntry.SetRange("One Stop Shop Reporting", true);
        VATEntry.FindFirst();
        exit(Abs(VATEntry.Base));
    end;

    local procedure SetIncludeImporteTotalInSIISetup()
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("Include ImporteTotal", true);
        SIISetup.Modify(true);
    end;
}

