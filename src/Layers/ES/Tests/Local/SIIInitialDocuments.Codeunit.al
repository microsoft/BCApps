codeunit 147526 "SII Initial Documents"
{
    // // [FEATURE] [SII] [Initial Upload]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        SIIXMLCreator: Codeunit "SII XML Creator";
        IsInitialized: Boolean;
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida';
        XPathSalesDetalleIVATok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/';
        XPathSalesNoExentaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/';
        XPathPurchDetalleIVATok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';
        RegistroDelPrimerSemestreTxt: Label 'Registro del primer semestre';
        UploadType: Option Regular,Intracommunity,RetryAccepted;

    [Test]
    [Scope('OnPrem')]
    procedure InitialSalesInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 230255] DescripcionOperacion node does not inherit value from Sales Invoice with "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Posted Sales Invoice with VAT Clause
        PostSalesDocWithBlankOperationDescriptionAndInitialPostingDate(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialNormalSalesCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 230255] DescripcionOperacion node does not inherit value from Sales Credit Memo with "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with VAT Clause
        PostSalesDocWithBlankOperationDescriptionAndInitialPostingDate(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialReplacementSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 230255] DescripcionOperacion node does not inherit value from Sales Credit Memo with "Correction Type" = Replacement and "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with VAT Clause
        PostSalesDocWithBlankOperationDescriptionAndInitialPostingDate(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 230255] CuotaDeducible node has zero value and DescripcionOperacion node does not inherit value from Purchase Invoice with "Posting Date" before 30.06.2017
        // [SCENARIO 233942] FechaRegContable node has value Work Date for Purchase Invoice with "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Work Date is 01.12.2017
        // [GIVEN] Posted Purchase Invoice with VAT Clause and Amount = 100
        PostPurchDocWithBlankOperationDescriptionAndInitialPostingDate(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Purchase Invoice with "Posting Date" = 05.03.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with zero value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        // [THEN] "FechaRegContable" node has value "01.12.2017" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:FechaRegContable', SIIXMLCreator.FormatDate(WorkDate()));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialNormalPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 230255] CuotaDeducible node has zero value and DescripcionOperacion node does not inherit value from Purchase Credit Memo with "Posting Date" before 30.06.2017
        // [SCENARIO 233942] FechaRegContable node has value Work Date for normal Purchase Credit Memo with "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Work Date is 01.12.2017
        // [GIVEN] Posted Purchase Credit Memo with VAT Clause (VAT Exempt)
        PostPurchDocWithBlankOperationDescriptionAndInitialPostingDate(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted Purchase Credit Memo "Posting Date" = 05.03.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with zero value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        // [THEN] "FechaRegContable" node has value "01.12.2017" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:FechaRegContable', SIIXMLCreator.FormatDate(WorkDate()));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialReplacementPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 230255] CuotaDeducible node has zero value and DescripcionOperacion node does not inherit value from Purchase Credit Memo with "Correction Type" = Replacement and "Posting Date" before 30.06.2017
        // [SCENARIO 233942] FechaRegContable node has value Work Date for Purchase Credit Memo with Type = "Replacement" and "Posting Date" before 30.06.2017

        Initialize();

        // [GIVEN] Work Date is 01.12.2017
        // [GIVEN] Posted Purchase Credit Memo with VAT Clause
        PostPurchDocWithBlankOperationDescriptionAndInitialPostingDate(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted Purchase Credit Memo with Type = "Replacement" and "Posting Date" = 05.03.2017
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with zero value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "DescripcionOperacion" node has value "Registro del primer semestre" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:DescripcionOperacion', RegistroDelPrimerSemestreTxt);

        // [THEN] "FechaRegContable" node has value "01.12.2017" in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, '/sii:FechaRegContable', SIIXMLCreator.FormatDate(WorkDate()));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialNonTaxableSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [No Tax] [Invoice]
        // [SCENARIO 253774] Non Taxable Sales Invoice with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Sales Invoice with Non Taxable VAT, "Posting Date" = 01.01.2017 and Total Amount = 120
        LibrarySII.PostSalesDocWithNoTaxableVATOnDate(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, SIIInitialDocUpload.GetInitialStartDate(), false, 0);

        // [WHEN] Create xml for Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = 120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialNonTaxableSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [No Tax] [Credit Memo]
        // [SCENARIO 253774] Non Taxable Sales Credit Memo with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Sales Credit Memo with Non Taxable VAT, "Posting Date" = 01.01.2017 and Total Amount = -120
        LibrarySII.PostSalesDocWithNoTaxableVATOnDate(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SIIInitialDocUpload.GetInitialStartDate(), false, 0);

        // [WHEN] Create xml for Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = -120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoExentaTok, 'sii:TipoNoExenta', 'S1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialVATExemptionSalesInvoice()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Exemption] [Invoice]
        // [SCENARIO 253774] VAT Exemption Sales Invoice with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Sales Invoice with VAT Exemption, "Posting Date" = 01.01.2017 and Total Amount = 120
        LibrarySII.PostSalesDocWithVATClauseOnDate(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SIIInitialDocUpload.GetInitialStartDate(), 0);

        // [WHEN] Create xml for Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = 120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialVATExemptionSalesCrMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Exemption] [Credit Memo]
        // [SCENARIO 253774] VAT Exemption Sales Credit Memo with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Sales Credit Memo with VAT Exemption, "Posting Date" = 01.01.2017 and Total Amount = -120
        LibrarySII.PostSalesDocWithVATClauseOnDate(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, SIIInitialDocUpload.GetInitialStartDate(), 0);

        // [WHEN] Create xml for Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = -120
        CustLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry."Amount (LCY)"));
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoExentaTok, 'sii:TipoNoExenta', 'S1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialPurchInvRevChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT] [Invoice]
        // [SCENARIO 253774] Reverse Charge Purchase Invoice with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Purchase Invoice with Reverse Charge VAT, "Posting Date" = 01.01.2017 and Total Amount = 120
        PostPurchDocWithReverseChargeVAT(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Create xml for Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = 120
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InitialPurchCrMemoRevChargeVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Reverse Charge VAT] [Credit Memo]
        // [SCENARIO 253774] Reverse Charge Purchase Credit Memo with "Posting Date" before 30.06.2017 has amount under node NoExenta

        Initialize();

        // [GIVEN] Purchase Credit Memo with Reverse Charge VAT, "Posting Date" = 01.01.2017 and Total Amount = 120
        PostPurchDocWithReverseChargeVAT(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Create xml for Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] BaseImponible node exists under NoExenta\DesgloseIVA node with value = 120
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchDetalleIVATok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-VendorLedgerEntry."Amount (LCY)"));
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

    local procedure PostSalesDocWithBlankOperationDescriptionAndInitialPostingDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    var
        SalesHeader: Record "Sales Header";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Posting Date", SIIInitialDocUpload.GetInitialStartDate());
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Validate("Operation Description", '');
        SalesHeader.Validate("Operation Description 2", '');
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, LibraryInventory.CreateItemNo());
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostPurchDocWithBlankOperationDescriptionAndInitialPostingDate(var VendLedgEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrectionType: Option)
    var
        PurchHeader: Record "Purchase Header";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("Posting Date", SIIInitialDocUpload.GetInitialStartDate());
        PurchHeader.Validate("Correction Type", CorrectionType);
        PurchHeader.Validate("Operation Description", '');
        PurchHeader.Validate("Operation Description 2", '');
        PurchHeader.Modify(true);
        LibrarySII.CreatePurchLineWithUnitCost(PurchHeader, LibraryInventory.CreateItemNo());
        VendLedgEntry.SetRange("Buy-from Vendor No.", PurchHeader."Buy-from Vendor No.");
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchHeader, false, false));
    end;

    local procedure PostPurchDocWithReverseChargeVAT(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        CountryRegion: Record "Country/Region";
        SIIInitialDocUpload: Codeunit "SII Initial Doc. Upload";
        VATRateReverseCharge: Decimal;
        AmountReverse: Decimal;
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySII.CreatePurchHeaderWithSetup(PurchaseHeader, VATBusinessPostingGroup, DocType, CountryRegion.Code);
        PurchaseHeader.Validate("Posting Date", SIIInitialDocUpload.GetInitialStartDate());
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithSetup(
          VATRateReverseCharge, AmountReverse, PurchaseHeader, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, DocType, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;
}

