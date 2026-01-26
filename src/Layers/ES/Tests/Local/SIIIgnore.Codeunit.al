codeunit 147547 "SII Ignore"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SII]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySII: Codeunit "Library - SII";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;

    [Test]
    procedure SalesInvoiceNormalVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT sales invoice with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales invoice with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(SalesLine."Amount Including VAT"));
    end;

    [Test]
    procedure SalesCrMemoNormalVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT sales invoice with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales invoice with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-SalesLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-SalesLine."Amount Including VAT"));
    end;

    [Test]
    procedure SalesReplacementCrMemoNormalVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT replacement sales credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales invoice with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", SalesHeader."Correction Type"::Replacement);
        SalesHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-SalesLine."Amount Including VAT"));
    end;

    [Test]
    procedure SalesInvoiceNoTaxableVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT sales invoice with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales invoice with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Type", SalesHeader."Invoice Type"::"F2 Simplified Invoice");
        SalesHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:ImportePorArticulos7_14_Otros', SIIXMLCreator.FormatNumber(SalesLine.Amount));
    end;

    [Test]
    procedure SalesCrMemoNoTaxableVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT sales credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales credit memo with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:ImportePorArticulos7_14_Otros', SIIXMLCreator.FormatNumber(-SalesLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-SalesLine."Amount Including VAT"));
    end;

    [Test]
    procedure SalesReplacementCrMemoNoTaxableVATIgnoreInSIISunshine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT replacement sales credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Sales invoice with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", SalesHeader."Correction Type"::Replacement);
        SalesHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibrarySales.CreateSalesLine(
                SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(SalesHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:ImportePorArticulos7_14_Otros', 1);
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:ImportePorArticulos7_14_Otros', SIIXMLCreator.FormatNumber(SalesLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-SalesLine."Amount Including VAT"));
    end;

    [Test]
    procedure PurchInvoiceNormalVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT purchase invoice with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase invoice with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice");
        PurchaseHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT"));
    end;

    [Test]
    procedure PurchCrMemoNormalVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT purchase credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase credit memo with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount - PurchaseLine."Amount Including VAT"));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT"));
    end;

    [Test]
    procedure PurchReplacementCrMemoNormalVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a normal VAT replacement purchase credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase replacement credit memo with Normal VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", PurchaseHeader."Correction Type"::Replacement);
        PurchaseHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNormalVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(PurchaseLine."Amount Including VAT" - PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT"));
    end;

    [Test]
    procedure PurchInvoiceNoTaxableVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT purchase invoice with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase invoice with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Invoice Type", PurchaseHeader."Invoice Type"::"F2 Simplified Invoice");
        PurchaseHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(PurchaseLine.Amount));
    end;

    [Test]
    procedure PurchCrMemoNoTaxableVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT purchase credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase credit memo with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT"));
    end;

    [Test]
    procedure PurchReplacementCrMemoNoTaxableVATIgnoreInSIISunshine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
        IgnoreInSII: Boolean;
    begin
        // [SCENARIO 498726] Stan can post a no taxable VAT purchase replacement credit memo with the G/L account that will be excluded from the SII reporting

        Initialize();
        // [GIVEN] Purchase credit memo with No Taxable VAT and two G/L accounts
        // [GIVEN] Account "A" is included in the SII reporting
        // [GIVEN] Account "B" is excluded from the SII reporting
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", PurchaseHeader."Correction Type"::Replacement);
        PurchaseHeader.Modify(true);
        for IgnoreInSII := true downto false do begin
            LibraryPurchase.CreatePurchaseLine(
                PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountWithNoTaxableVAT(PurchaseHeader."VAT Bus. Posting Group", IgnoreInSII),
                LibraryRandom.RandInt(100));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Stan generates the SII xml file
        SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false);

        // [THEN] Stan can see that only the account "A" exist in the SII xml file
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:BaseImponible', 1);
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-PurchaseLine.Amount));
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:ImporteTotal', SIIXMLCreator.FormatNumber(-PurchaseLine."Amount Including VAT"));
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SII Ignore");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SII Ignore");

        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(DATABASE::"SII Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SII Ignore");
    end;

    local procedure CreateGLAccountWithNormalVAT(VATBusPostGroupCode: Code[20]; IgnoreInSII: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(50));
        UpdateVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Ignore In SII", IgnoreInSII);
        VATPostingSetup.Modify(true);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);
        exit(GLAccount."No.")
    end;

    local procedure CreateGLAccountWithNoTaxableVAT(VATBusPostGroupCode: Code[20]; IgnoreInSII: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
        VATPostingSetup.Validate("No Taxable Type", VATPostingSetup."No Taxable Type"::"Non Taxable Art 7-14 and others");
        UpdateVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("Ignore In SII", IgnoreInSII);
        VATPostingSetup.Modify(true);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);
        exit(GLAccount."No.")
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
    end;
}