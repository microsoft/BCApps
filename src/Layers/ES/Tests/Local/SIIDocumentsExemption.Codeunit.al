codeunit 147525 "SII Documents Exemption"
{
    // // [FEATURE] [SII] [Exemption]

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
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XPathPurchBaseImponibleTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/sii:DesgloseFactura/sii:DesgloseIVA/sii:DetalleIVA/';
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        XPathSalesExentaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/';
        SIIExemptionCode: Option " ","E1 Exempt on account of Article 20","E2 Exempt on account of Article 21","E3 Exempt on account of Article 22","E4 Exempt under Articles 23 and 24","E5 Exempt on account of Article 25","E6 Exempt on other grounds";
        XPathSalesNoExentaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/sii:TipoDesglose/sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvWithExemptEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Sales Invoice with VAT Clause
        // [SCENARIO 230250] BaseImponible node has negative value for Sales Invoice with VAT Clause
        // [SCENARIO 254617] Exenta node exports under Entrega\Sujeta parent nodes
        // [SCENARIO 263060] DetalleExenta node uses for VAT exemption details
        Initialize();

        // [GIVEN] Posted Sales Invoice with VAT Clause
        LibrarySII.PostSalesDocWithVATClause(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has nodes with VAT Exemption details
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:CausaExencion', 'E6');
        CustLedgerEntry.CalcFields(Amount);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry.Amount));
        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NormalSalesCrMemoWithExemptEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Sales Credit Memo with VAT Clause
        // [SCENARIO 230250] BaseImponible node has negative value for Sales Credit Memo with VAT Clause
        // [SCENARIO 254617] Exenta node exports under Entrega\Sujeta parent nodes
        // [SCENARIO 263060] DetalleExenta node uses for VAT exemption details
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with VAT Clause
        LibrarySII.PostSalesDocWithVATClause(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has nodes with VAT Exemption details
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:CausaExencion', 'E6');
        CustLedgerEntry.CalcFields(Amount);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(CustLedgerEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoWithExemptEntries()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Sales Credit Memo with "Correction Type" = Replacement and VAT Clause
        // [SCENARIO 230250] BaseImponible node has negative value for Sales Credit Memo with "Correction Type" = Replacement and VAT Clause
        // [SCENARIO 254617] Exenta node exports under Entrega\Sujeta parent nodes
        // [SCENARIO 263060] DetalleExenta node uses for VAT exemption details
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with VAT Clause
        LibrarySII.PostSalesDocWithVATClause(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has nodes with VAT Exemption details
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:CausaExencion', 'E6');
        CustLedgerEntry.CalcFields(Amount);
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-CustLedgerEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvWithExemptEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice] [Normal VAT]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Purchase Invoice with VAT Clause
        // [SCENARIO 228209] "CuotaDeducible" node with zero value for Purchase Invoice with VAT Clause when Normal VAT Calculation Type
        Initialize();

        // [GIVEN] VAT Posting Setup with <zero> VAT Rate, Normal VAT Calculation Type and VAT Clause with SII Exemption Code
        CreateVATPostingSetupWithSIIExemptVATClause(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Posted Purchase Invoice with Amount = 100
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.CalcFields(Amount);

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with <zero> value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "BaseImponible" node with value 100.0 in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-VendorLedgerEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NormalPurchCrMemoWithExemptEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Purchase Credit Memo with VAT Clause
        // [SCENARIO 228209] "CuotaDeducible" node with zero value and no VAT exempt details for Purchase Credit Memo with VAT Clause
        Initialize();

        // [GIVEN] VAT Posting Setup with <zero> VAT Rate Normal VAT Calculation Type and VAT Clause with SII Exemption Code
        CreateVATPostingSetupWithSIIExemptVATClause(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Posted Purchase Credit Memo with <blank> Correction Type
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.CalcFields(Amount);

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with <zero> value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "BaseImponible" node with value -100.0 exists in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-VendorLedgerEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementPurchCrMemoWithExemptEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Normal VAT]
        // [SCENARIO 222174] XML file has nodes with VAT exemption details for Purchase Credit Memo with "Correction Type" = Replacement and VAT Clause
        // [SCENARIO 228209] "CuotaDeducible" node with zero value and no VAT exempt details for Purchase Credit Memo with "Correction Type" = Replacement and VAT Clause
        // [SCENARIO 256251] Purchase Credit Memo with type "Replacement" has positive values for VAT
        Initialize();

        // [GIVEN] VAT Posting Setup with <zero> VAT Rate, Normal VAT Calculation Type and VAT Clause with SII Exemption Code
        CreateVATPostingSetupWithSIIExemptVATClause(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Posted Purchase Credit Memo with Correction Type = Replacement
        CreatePurchaseDocWithVATPostingSetup(
          PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VendorLedgerEntry.CalcFields(Amount);

        // [WHEN] Create xml for Posted Purchase Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with <zero> value in XML file
        LibrarySII.ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(0));

        // [THEN] "BaseImponible" node with value 100.0 in XML file
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchBaseImponibleTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-VendorLedgerEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvEUWithExemptEntriesWhenE5()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT] [E5]
        // [SCENARIO 278726] XML file has "CuotaDeducible" node with VAT Amount
        // [SCENARIO 278726] when Purchase Invoice was posted with Reverse Charge VAT and VAT Clause having SII Exemption Code E5
        Initialize();

        // [GIVEN] VAT Posting Setup with 10% VAT Rate, Reverse Charge VAT and VAT Clause with SII Exemption Code E5
        CreateVATPostingSetupWithSIIExemptVATClause(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        ModifySIIExemptCodeInVATClause(VATPostingSetup."VAT Clause Code", SIIExemptionCode::"E5 Exempt on account of Article 25");

        // [GIVEN] Posted Purchase Invoice with Amount = 100.0
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
        VATEntry.FindFirst();

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with value 10.0 in XML file
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(VATEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoEUWithExemptEntriesWhenE5()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Reverse Charge VAT] [E5]
        // [SCENARIO 278726] XML file has "CuotaDeducible" node with VAT Amount
        // [SCENARIO 278726] when Purchase Credit Memo was posted with Reverse Charge VAT and VAT Clause having SII Exemption Code E5
        Initialize();

        // [GIVEN] VAT Posting Setup with 10% VAT Rate, Reverse Charge VAT and VAT Clause with SII Exemption Code E5
        CreateVATPostingSetupWithSIIExemptVATClause(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        ModifySIIExemptCodeInVATClause(VATPostingSetup."VAT Clause Code", SIIExemptionCode::"E5 Exempt on account of Article 25");

        // [GIVEN] Posted Purchase Credit Memo with Amount = 100.0
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry.SetRange("Transaction No.", VendorLedgerEntry."Transaction No.");
        VATEntry.FindFirst();

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node with value 10.0 in XML file
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(VATEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvEUWithExemptEntriesWhenNotE5()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Invoice] [Reverse Charge VAT] [E5]
        // [SCENARIO 278726] XML file has "CuotaDeducible" node with <zero> value
        // [SCENARIO 278726] when Purchase Invoice was posted with Reverse Charge VAT and VAT Clause having SII Exemption Code E1
        Initialize();

        // [GIVEN] VAT Posting Setup with 10% VAT Rate, Reverse Charge VAT and VAT Clause with SII Exemption Code E1
        CreateVATPostingSetupWithSIIExemptVATClause(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        ModifySIIExemptCodeInVATClause(VATPostingSetup."VAT Clause Code", SIIExemptionCode::"E1 Exempt on account of Article 20");

        // [GIVEN] Posted Purchase Invoice with Amount = 100.0
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::Invoice, 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node has value in XML file
        // TFS 301044: CuotaDeducible for Purchase should be filled like Normal VAT
        FindVATEntry(VATEntry, VendorLedgerEntry."Posting Date", VendorLedgerEntry."Document No.");
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(VATEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoEUWithExemptEntriesWhenNotE5()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Reverse Charge VAT] [E5]
        // [SCENARIO 278726] XML file has "CuotaDeducible" node with <zero> value
        // [SCENARIO 278726] when Purchase Credit Memo was posted with Reverse Charge VAT and VAT Clause having SII Exemption Code E1
        Initialize();

        // [GIVEN] VAT Posting Setup with 10% VAT Rate, Reverse Charge VAT and VAT Clause with SII Exemption Code E1
        CreateVATPostingSetupWithSIIExemptVATClause(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        ModifySIIExemptCodeInVATClause(VATPostingSetup."VAT Clause Code", SIIExemptionCode::"E1 Exempt on account of Article 20");

        // [GIVEN] Posted Purchase Credit Memo with Amount = 100.0
        CreatePurchaseDocWithVATPostingSetup(PurchaseHeader, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo", 0);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for Posted Purchase Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] XML files has no node with VAT Exemption details
        LibrarySII.ValidateNoElementsByName(XMLDoc, 'sii:CausaExencion');

        // [THEN] "CuotaDeducible" node has value in XML file
        // TFS 301044: CuotaDeducible for Purchase should be filled like Normal VAT
        FindVATEntry(VATEntry, VendorLedgerEntry."Posting Date", VendorLedgerEntry."Document No.");
        LibrarySII.ValidateElementByName(
          XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(VATEntry.Amount));

        LibrarySII.AssertLibraryVariableStorage();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvMixOfNormalAndExemptEntries()
    var
        SalesHeader: Record "Sales Header";
        ExemptSalesLine: Record "Sales Line";
        NormalSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 303472] XML nodes of normal and exempt entries of Sales Invoice both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Invoice with two lines
        // [GIVEN] First line has VAT Exemption and Amount = 100
        // [GIVEN] Second line has Normal VAT and Amount = 200
        CreateSalesDocWithMixedNormalAndExemptLines(SalesHeader, NormalSalesLine, ExemptSalesLine, SalesHeader."Document Type"::Invoice, 0);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Invoice
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] VAT Exemption amount equals 100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(ExemptSalesLine.Amount));

        // [THEN] Normal VAT amount equals 200 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(NormalSalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoMixOfNormalAndExemptEntries()
    var
        SalesHeader: Record "Sales Header";
        ExemptSalesLine: Record "Sales Line";
        NormalSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 303472] XML nodes of normal and exempt entries of Sales Credit Memo both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with two lines
        // [GIVEN] First line has VAT Exemption and Amount = 100
        // [GIVEN] Second line has Normal VAT and Amount = 200
        CreateSalesDocWithMixedNormalAndExemptLines(
          SalesHeader, NormalSalesLine, ExemptSalesLine, SalesHeader."Document Type"::"Credit Memo", 0);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] VAT Exemption amount equals -100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-ExemptSalesLine.Amount));

        // [THEN] Normal VAT amount equals -200 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-NormalSalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoMixOfNormalAndExemptEntries()
    var
        SalesHeader: Record "Sales Header";
        ExemptSalesLine: Record "Sales Line";
        NormalSalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 303472] XML nodes of normal and exempt entries of Replacement Sales Credit Memo both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "Correction Type" = Replacement and two lines
        // [GIVEN] First line has VAT Exemption and Amount = 100
        // [GIVEN] Second line has Normal VAT and Amount = 200
        CreateSalesDocWithMixedNormalAndExemptLines(
          SalesHeader, NormalSalesLine, ExemptSalesLine, SalesHeader."Document Type"::"Credit Memo",
          SalesHeader."Correction Type"::Replacement);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted Replacenet Sales Credit Memo
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] VAT Exemption amount equals 100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(ExemptSalesLine.Amount));

        // [THEN] Normal VAT amount equals 200 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:NoExenta/sii:DesgloseIVA/sii:DetalleIVA/"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesNoExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(NormalSalesLine.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvZeroNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 331968] XML nodes of normal zero VAT and exempt entries of Sales Invoice both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Invoice with zero VAT % and VAT Base = 100
        CreateSalesDocZeroVAT(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, 0);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No VAT Exemption amount equals 100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoZeroNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 330227] XML nodes of normal zero VAT and exempt entries of Sales Credit Memo both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with zero VAT % and VAT Base = 100
        CreateSalesDocZeroVAT(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", 0);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No VAT Exemption amount equals -100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(-SalesLine.Amount), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplacementSalesCrMemoZeroNormalVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 330227] XML nodes of normal zero VAT and exempt entries of Replacement Sales Credit Memo both located under correct parent node "Sujeta"

        Initialize();

        // [GIVEN] Posted Sales Replacement Credit Memo with zero VAT % and VAT Base = -100
        CreateSalesDocZeroVAT(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.PostSalesDocument(SalesHeader, false, false));

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] No VAT Exemption amount equals 100 exports in node "sii:DesgloseFactura/sii:Sujeta/sii:Exenta/sii:DetalleExenta/"
        LibrarySII.VerifyNodeCountWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(SalesLine.Amount), 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleDetalleExentaUnderSingleExentaNodeExistsForSalesInvWithMultipleExemptionCodes()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 391064] Multiple "DetalleExenta" xml nodes exist under the single "Exente" xml node for the sales invoice with multiple exemption codes

        Initialize();
        // [GIVEN] Sales invoice with two lines
        // [GIVEN] First one with the "SII Exemption Code" equals "E1", the second with the "SII Exemption Code" equals "E2"
        PostSalesDocWithMultipleClauses(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for Posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] One "Exenta" node
        LibrarySII.VerifyCountOfElements(XMLDoc, 'sii:Exenta', 1);

        // [THEN] Two DetalleExenta nodes. One with "E1", the other one with "E2"
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:CausaExencion', 'E1');
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesExentaTok, 'sii:CausaExencion', 'E2');
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

    local procedure PostSalesDocWithMultipleClauses(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    var
        SalesHeader: Record "Sales Header";
        VATClause: Record "VAT Clause";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(
              SalesHeader."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E1 Exempt on account of Article 20")));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(
              SalesHeader."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21")));
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateVATPostingSetupWithSIIExemptVATClause(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATClause: Record "VAT Clause";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATPostingSetup.Get(
          VATBusinessPostingGroup.Code,
          LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(
            VATBusinessPostingGroup.Code, VATClause."SII Exemption Code"::"E1 Exempt on account of Article 20"));
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePurchaseDocWithVATPostingSetup(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Purchase Document Type"; CorrectionType: Integer)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocType, LibrarySII.CreateVendWithVATSetup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Correction Type", CorrectionType);
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader, LibrarySII.CreateItemNoWithSpecificVATSetup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure CreateSalesDocWithMixedNormalAndExemptLines(var SalesHeader: Record "Sales Header"; var NormalSalesLine: Record "Sales Line"; var ExemptSalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    begin
        LibrarySII.CreateSalesDocWithVATClause(SalesHeader, DocType, CorrectionType);
        FindLastSalesLine(ExemptSalesLine, SalesHeader);
        AddNormalVATSalesLine(NormalSalesLine, SalesHeader, LibraryRandom.RandInt(50));
    end;

    local procedure CreateSalesDocZeroVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    var
        Customer: Record Customer;
    begin
        LibrarySII.CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);
        AddNormalVATSalesLine(SalesLine, SalesHeader, 0);
    end;

    local procedure ModifySIIExemptCodeInVATClause(VATClauseCode: Code[20]; SIIExemptionCode: Integer)
    var
        VATClause: Record "VAT Clause";
    begin
        VATClause.Get(VATClauseCode);
        VATClause.Validate("SII Exemption Code", SIIExemptionCode);
        VATClause.Modify(true);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; PostingDate: Date; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure FindLastSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
    end;

    local procedure AddNormalVATSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATRate: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(VATPostingSetup."VAT Prod. Posting Group"));
        FindLastSalesLine(SalesLine, SalesHeader);
    end;
}

