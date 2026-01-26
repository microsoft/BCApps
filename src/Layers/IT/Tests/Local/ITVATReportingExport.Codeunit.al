codeunit 144012 "IT - VAT Reporting - Export"
{
    // // [FEATURE] [Spesometro]
    // TODO
    // - company tax representative empty
    // - Add aggregated tests

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        GenJournalLine2: Record "Gen. Journal Line";
        VATReportHeader2: Record "VAT Report Header";
        VATReportLine2: Record "VAT Report Line";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySplitVAT: Codeunit "Library - Split VAT";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySpesometro: Codeunit "Library - Spesometro";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryITDatifattura: Codeunit "Library - IT Datifattura";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryInventory: Codeunit "Library - Inventory";
        isInitialized: Boolean;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN;
        NoVerifierMatchedErr: Label 'No verifier function matches the generated VAT report.';
        StandardDatifatturaXmlnsXsAttrTxt: Label 'http://www.w3.org/2001/XMLSchema', Locked = true;
        StandardDatifatturaXmlnsDsAttrTxt: Label 'http://www.w3.org/2000/09/xmldsig#', Locked = true;
        StandardDatifatturaXmlnsNs2AttrTxt: Label 'http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v2.0', Locked = true;
        DatiFatturaForOneDocumentWithMultipleLinesErr: Label 'DatiFattura Report has wrong number of elements for document with multiple lines.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesResidentIndividual()
    begin
        // [SCENARIO] Export sales invoice for individual resident customer
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> FE
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesResidentNonIndividual()
    begin
        // [SCENARIO] Export sales invoice for non-individual resident customer
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> FE
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesNonResidentIndividual()
    begin
        // [SCENARIO] Export sales invoice for individual non-resident customer
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::"Non-Resident", true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> FN
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesNonResidentNonIndividual()
    begin
        // [SCENARIO] Export sales invoice for non-individual non-resident customer
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::"Non-Resident", false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> FN
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoResidentIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> NE
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoResNonIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::Resident, false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract") // -> NE
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoNonResIndividual()
    begin
        asserterror ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::"Non-Resident", true,
            VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
            VATReportLine2."Contract Payment Type"::"Without Contract");

        Assert.ExpectedError('There is no VAT Report Line within the filter.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoNonResNonIndividual()
    begin
        asserterror ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::"Non-Resident", false,
            VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
            VATReportLine2."Contract Payment Type"::"Without Contract");

        Assert.ExpectedError('There is no VAT Report Line within the filter.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchResidentIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchResidentNonIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchNonResidentIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::"Non-Resident", true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchNonResidentNonIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::"Non-Resident", false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoResidentIndividual()
    begin
        ExportTest(
          GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoResNonIndividual()
    begin
        ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::Resident, false,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoNonResIndividual()
    begin
        asserterror ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::"Non-Resident", true,
            VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
            VATReportLine2."Contract Payment Type"::"Without Contract");

        Assert.ExpectedError('There is no VAT Report Line within the filter.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchCrMemoNonResNonIndividual()
    begin
        asserterror ExportTest(GenJournalLine2."Document Type"::"Credit Memo", GenJournalLine2.Resident::"Non-Resident", false,
            VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Purchase,
            VATReportLine2."Contract Payment Type"::"Without Contract");

        Assert.ExpectedError('There is no VAT Report Line within the filter.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SpecialContract()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Standard, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::Other)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CancelReport()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::"Cancellation ", GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SubstitutiveReport()
    begin
        ExportTest(GenJournalLine2."Document Type"::Invoice, GenJournalLine2.Resident::Resident, true,
          VATReportHeader2."VAT Report Type"::Corrective, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportLine2."Contract Payment Type"::"Without Contract")
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IntermediatoryFieldsBlank()
    begin
        ExportTestForIntermediary(true, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IntermediatoryTaxRepBlank()
    begin
        ExportTestForIntermediary(false, true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure IntermediatoryTaxRepNotBlank()
    begin
        ExportTestForIntermediary(false, false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportedVATReportConsistsOfLinesFromOneVATReport_Datifattura()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        Customer: Record Customer;
        NameValueBuffer: Record "Name/Value Buffer";
        PostingDate: array[2] of Date;
        Numero: array[2] of Text;
        FileName: Text;
    begin
        // [FEATURE] [VAT Report Suggest Lines]
        // [SCENARIO 227220] VAT Report Lines from different reports must be included in different XML-files
        // [SCENARIO 228340] Exported XML has attributes 'xmlns:xs', 'xmlns:ds' in DatiFattura node
        // [SCENARIO 264740] Exported XML does not have tags <Detraibile> and <Deducibile>
        Initialize();
        PostingDate[1] := CalcDate('<CM+1Y>', GetPostingDate());
        PostingDate[2] := PostingDate[1] + 1;

        // [GIVEN] Posted Sales Invoice on 15.03.2019
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CreateCustomer_Datifattura(Customer), LibraryRandom.RandDec(1000, 2), PostingDate[1], true, true);

        // [GIVEN] Customer with "VAT Busines Posting Group" = "VATGR"
        CreateCustomer_Datifattura(Customer);

        // [GIVEN] (251953) "Default Sales Operation Type" contains "-" sign in "VAT Busines Posting Group" "VATGR"
        UpdateDefaultSalesOperationTypeInVATBusinessPostingGroup(Customer."VAT Bus. Posting Group");

        // [GIVEN] Posted Sales Invoice on 30.03.2019
        // [GIVEN] "No." = 'PSI-001' in Posted Sales Invoice
        Numero[1] :=
          CreateAndPostSalesDocument(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
            Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate[2], true, true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          CreateVendor_Datifattura(Vendor), LibraryRandom.RandDec(1000, 2), PostingDate[1], true, true);

        // [GIVEN] Posted Purchase Invoice on 30.03.2019
        // [GIVEN] "Vendor Invoice No." = 'VIN-001' in Posted Purchase Invoice
        // [GIVEN] (251953) "External Document No." = 'VIN-001'
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          CreateVendor_Datifattura(Vendor), LibraryRandom.RandDec(1000, 2), PostingDate[2], true, true);
        Numero[2] := PurchaseHeader."Vendor Invoice No.";

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate[1], PostingDate[1]);

        // [GIVEN] VAT Report on 30.03.2019..30.03.2019 with "VAT Report Config. Code" = Datifattura
        Clear(VATReportHeader);
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate[2], PostingDate[2]);

        // [WHEN] Export VAT Report on 30.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Two files were exported with info about posted invoices on 30.03.2019 only
        NameValueBuffer.SetRange(Name, 'FileGUID');
        Assert.RecordCount(NameValueBuffer, 2);

        // [THEN] The first file has Numero = 'PSI001'
        // [THEN] (251953) Numero must be reported in an alphanumeric format
        // [THEN] (231531) Data = '2019-03-30'
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        VerifyDatiFatturaInvoiceNoAndDate(FileName, PostingDate[2], Numero[1]);

        // [THEN] File exported with attributes xmlns:xs, xmlns:ds, versione, xmlns:ns2 in namespace ns2
        VerifyDatiFatturaAttributes(FileName);

        // [THEN] The second file has Numero = 'VIN001'
        // [THEN] (251953) Numero must be reported in an alphanumeric format
        // [THEN] (231531) Data = '2019-03-30'
        NameValueBuffer.Next();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        VerifyDatiFatturaInvoiceNoAndDate(FileName, PostingDate[2], Numero[2]);

        // [THEN] File exported with attributes xmlns:xs, xmlns:ds, versione, xmlns:ns2 in namespace ns2
        VerifyDatiFatturaAttributes(FileName);

        // [THEN] File does not have tags <Detraibile> and <Deducibile>
        VerifyDetraibileAndDeducibileNonExistInXmlFile(FileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportFiscalCodeFromIndividualVendorInVATReport_Datifattura()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Vendor: Record Vendor;
        DotNetXmlNode: DotNet XmlNode;
        PostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [VAT Report Suggest Lines]
        // [SCENARIO 227227] "Fiscal Code" in vendor card must be exported instead of "VAT Registration No." if it is blank
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor with blank "VAT Registration No." and "Fiscal Code" = 'PNDLSN69C50F205N'
        CreateIndividualVendor(Vendor);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] (252103) File has two CodiceFiscale nodes
        // [THEN] (252103) The second CodiceFiscale value = 'PNDLSN69C50F205N'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('CodiceFiscale'), 'Incorrect CodiceFiscale count');
        Assert.AreEqual(Vendor."Fiscal Code", LibraryXMLRead.GetNodeValueAtIndex('CodiceFiscale', 1), 'Incorrect CodiceFiscale value');

        // [THEN] (231530) File must contain the Sede node
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTR/CedentePrestatoreDTR/AltriDatiIdentificativi/Sede', DotNetXmlNode);

        // [THEN] (232899) TipoDocumento = TD01
        LibraryXPathXMLReader.VerifyNodeValue('DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiGenerali/TipoDocumento', 'TD01');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportFiscalCodeFromIndividualCustomerInVATReport_Datifattura()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        Customer: Record Customer;
        DotNetXmlNode: DotNet XmlNode;
        PostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [VAT Report Suggest Lines]
        // [SCENARIO 227227] "Fiscal Code" in customer card must be exported instead of "VAT Registration No." if it is blank
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer with blank "VAT Registration No." and "Fiscal Code" = 'PNDLSN69C50F205N'
        CreateIndividualCustomer(Customer);

        // [GIVEN] Posted Sales Invoice on 15.03.2019
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] (252103) File has two CodiceFiscale nodes
        // [THEN] (252103) The second CodiceFiscale value = 'PNDLSN69C50F205N'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('CodiceFiscale'), 'Incorrect IdCodice count');
        Assert.AreEqual(Customer."Fiscal Code", LibraryXMLRead.GetNodeValueAtIndex('CodiceFiscale', 1), 'Incorrect IdCodice value');

        // [THEN] (231530) File must contain the Sede node
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTE/CessionarioCommittenteDTE/AltriDatiIdentificativi/Sede', DotNetXmlNode);

        // [THEN] (232899) TipoDocumento = TD01
        LibraryXPathXMLReader.VerifyNodeValue('DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiGenerali/TipoDocumento', 'TD01');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SplitFileOnSalesAndPurchases_Datifattura()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CompanyInformation: Record "Company Information";
        NameValueBuffer: Record "Name/Value Buffer";
        DotNetXmlNode: DotNet XmlNode;
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 227476] Export different files for sales (DTE) and purchases (DTR).
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());
        CompanyInformation.Get();

        // [GIVEN] Two Posted Sales Invoice on 15.03.2019
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CreateCustomer_Datifattura(Customer), LibraryRandom.RandDec(1000, 2), PostingDate, true, true);
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          CreateCustomer_Datifattura(Customer), LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] Two Posted Purchase Invoice on 15.03.2019
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          CreateVendor_Datifattura(Vendor), LibraryRandom.RandDec(1000, 2), PostingDate, true, true);
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          CreateVendor_Datifattura(Vendor), LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Two files were exported
        NameValueBuffer.SetRange(Name, 'FileGUID');
        Assert.RecordCount(NameValueBuffer, 2);

        // [THEN] One file is for sales with CedentePrestatoreDTE node
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXMLRead.Initialize(FileName);

        // [THEN] (231518) One CedentePrestatoreDTE appearance
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('CedentePrestatoreDTE'), '');

        // [THEN] (230922) DTE node contains CedentePrestatoreDTE and CessionarioCommittenteDTE nodes
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTE/CedentePrestatoreDTE', DotNetXmlNode);
        LibraryXPathXMLReader.GetNodeByXPath('DTE/CessionarioCommittenteDTE', DotNetXmlNode);

        // [THEN] (231530) File must contain the Sede node
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTE/CessionarioCommittenteDTE/AltriDatiIdentificativi/Sede', DotNetXmlNode);

        // [THEN] (230922) CessionarioCommittenteDTE appeares two times
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('CessionarioCommittenteDTE'), '');

        // [THEN] The second file is for purchases with CessionarioCommittenteDTR node
        NameValueBuffer.Next();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXMLRead.Initialize(FileName);

        // [THEN] (231518) One CessionarioCommittenteDTR appearance
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('CessionarioCommittenteDTR'), '');

        // [THEN] (230922) DTR node contains CessionarioCommittenteDTR and CedentePrestatoreDTR nodes
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTR/CessionarioCommittenteDTR', DotNetXmlNode);
        LibraryXPathXMLReader.GetNodeByXPath('DTR/CedentePrestatoreDTR', DotNetXmlNode);

        // [THEN] (231530) File must contain the Sede node
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.GetNodeByXPath('DTR/CedentePrestatoreDTR/AltriDatiIdentificativi/Sede', DotNetXmlNode);

        // [THEN] (230922) CedentePrestatoreDTR appeares two times
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('CedentePrestatoreDTR'), '');

        // [THEN] (255742) File has three IdPaese, IdCodice, Denominazione, Indirizzo, Comune, Nazione nodes
        VerifyIdentificativiFiscaliAndAltriDatiIdentificativiSubnodesCount(LibraryXMLRead, 3);

        // [THEN] (228951) The first suggested file name is 'IT08106710158_DF_V0001'
        NameValueBuffer.SetRange(Name, 'SuggestedFileName');
        NameValueBuffer.FindFirst();
        Assert.AreEqual(
          'IT' + CompanyInformation."VAT Registration No." + '_DF_V0001.xml', NameValueBuffer.Value, 'Sales file name is incorrect');

        // [THEN] (228951) The second suggested file name is 'IT08106710158_DF_00002'
        NameValueBuffer.Next();
        Assert.AreEqual(
          'IT' + CompanyInformation."VAT Registration No." + '_DF_00002.xml', NameValueBuffer.Value, 'Purchases file name is incorrect');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SplitFileDependingOnCessionarioCommittenteDTECount_Datifattura()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CompanyInformation: Record "Company Information";
        VATEntry: Record "VAT Entry";
        PostingDate: Date;
        i: Integer;
        CustomerNo: Code[20];
        SuggestedFileName: array[3] of Text;
    begin
        // [SCENARIO 228490] One file must be exported for every 1000 CessionarioCommittenteDTE occurences and its name must contain progressive number from the second file
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());
        CompanyInformation.Get();

        // [GIVEN] 2001 Posted Sales Invoices on 15.03.2019
        CustomerNo := CreateCustomer_Datifattura(Customer);
        for i := 1 to 2001 do
            CreateVATEntry(PostingDate, VATEntry.Type::Sale, CustomerNo);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Three files were exported
        // [THEN] One is for the first 1000 CessionarioCommittenteDTE nodes
        // [THEN] One is for the second 1000 CessionarioCommittenteDTE node
        // [THEN] One is for the last 1 CessionarioCommittenteDTE node
        // [THEN] The first suggested file name is 'IT08106710158_DF_V0001'
        // [THEN] The second suggested file name is 'IT08106710158_DF_V0002_002'
        // [THEN] The third suggested file name is 'IT08106710158_DF_V0003_003'
        SuggestedFileName[1] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_V0001.xml';
        SuggestedFileName[2] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_V0002_002.xml';
        SuggestedFileName[3] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_V0003_003.xml';
        VerifyDatiFatturaSplittedFilesForScenarioWithThreeFiles('CessionarioCommittenteDTE', SuggestedFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SplitFileDependingOnCedentePrestatoreDTRCount_Datifattura()
    var
        Vendor: Record Vendor;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CompanyInformation: Record "Company Information";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostingDate: Date;
        i: Integer;
        VendorNo: Code[20];
        SuggestedFileName: array[3] of Text;
    begin
        // [SCENARIO 228490] One file must be exported for every 1000 CedentePrestatoreDTR occurences and its name must contain progressive number from the second file
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());
        CompanyInformation.Get();

        // [GIVEN] 2001 Posted Purchase Invoices on 15.03.2019
        VendorNo := CreateVendor_Datifattura(Vendor);
        for i := 1 to 2001 do begin
            VATEntry.Get(CreateVATEntry(PostingDate, VATEntry.Type::Purchase, VendorNo));
            MockGLEntryAndVendorLedgerEntry(
              VATEntry."Document No.", PostingDate, VATEntry."Transaction No.", VendorNo, VendorLedgerEntry."Document Type"::Invoice);
        end;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Three files were exported
        // [THEN] One is for the first 1000 CedentePrestatoreDTR nodes
        // [THEN] One is for the second 1000 CedentePrestatoreDTR node
        // [THEN] One is for the last 1 CedentePrestatoreDTR node
        // [THEN] The first suggested file name is 'IT08106710158_DF_00001'
        // [THEN] The second suggested file name is 'IT08106710158_DF_00002_002'
        // [THEN] The third suggested file name is 'IT08106710158_DF_00003_003'
        SuggestedFileName[1] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_00001.xml';
        SuggestedFileName[2] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_00002_002.xml';
        SuggestedFileName[3] := 'IT' + CompanyInformation."VAT Registration No." + '_DF_00003_003.xml';
        VerifyDatiFatturaSplittedFilesForScenarioWithThreeFiles('CedentePrestatoreDTR', SuggestedFileName);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportOneFileHaving1000CessionarioCommittenteDTECount_Datifattura()
    var
        Customer: Record Customer;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        CompanyInformation: Record "Company Information";
        PostingDate: Date;
        i: Integer;
        CustomerNo: Code[20];
    begin
        // [SCENARIO 228490] One file with 1000 CessionarioCommittenteDTE occurences having one numeric suffix must be exported
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());
        CompanyInformation.Get();

        // [GIVEN] 1000 Posted Sales Invoices on 15.03.2019
        CustomerNo := CreateCustomer_Datifattura(Customer);
        for i := 1 to 1000 do
            CreateVATEntry(PostingDate, VATEntry.Type::Sale, CustomerNo);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One file having 1000 CessionarioCommittenteDTE nodes was exported
        // [THEN] Suggested file name is 'IT08106710158_DF_V0001'
        VerifyDatiFatturaFileForScenarioWithOneFile(
          'CessionarioCommittenteDTE', 'IT' + CompanyInformation."VAT Registration No." + '_DF_V0001.xml');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportOneFileHaving1000CedentePrestatoreDTRCount_Datifattura()
    var
        Vendor: Record Vendor;
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        CompanyInformation: Record "Company Information";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostingDate: Date;
        i: Integer;
        VendorNo: Code[20];
    begin
        // [SCENARIO 228490] One file with 1000 CedentePrestatoreDTR occurences having one numeric suffix must be exported
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());
        CompanyInformation.Get();

        // [GIVEN] 1000 Posted Purchase Invoices on 15.03.2019
        VendorNo := CreateVendor_Datifattura(Vendor);
        for i := 1 to 1000 do begin
            VATEntry.Get(CreateVATEntry(PostingDate, VATEntry.Type::Purchase, VendorNo));
            MockGLEntryAndVendorLedgerEntry(
              VATEntry."Document No.",
              VATEntry."Posting Date",
              VATEntry."Transaction No.",
              VendorNo,
              VendorLedgerEntry."Document Type"::Invoice);
        end;

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One file having 1000 CedentePrestatoreDTR nodes was exported
        // [THEN] Suggested file name is 'IT08106710158_DF_00001'
        VerifyDatiFatturaFileForScenarioWithOneFile(
          'CedentePrestatoreDTR', 'IT' + CompanyInformation."VAT Registration No." + '_DF_00001.xml');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportForIndividualVendorWithoutFiscalCodeAndVATRegNo_Datifattura()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [SCENARIO 229923] Error is expected when export VAT Report for individual vendor without "Fiscal Code" and "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Individual Vendor "V" without "Fiscal Code" and "VAT Registration No."
        CreateIndividualVendor(Vendor);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Validate("Fiscal Code", '');
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"Fiscal Code" in Vendor: "V" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Vendor.FieldName("Fiscal Code"), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForIndividualVendorWithoutFiscalCode_Datifattura()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for individual vendor with "VAT Registration No." = '08106710158' and blank "Fiscal Code"
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Individual Vendor "V" without "Fiscal Code" and "VAT Registration No." = '08106710158'
        CreateIndividualVendor(Vendor);
        Vendor.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor));
        Vendor.Validate("Fiscal Code", '');
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] The second IdCodice value = '08106710158'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Vendor."VAT Registration No.", LibraryXMLRead.GetNodeValueAtIndex('IdCodice', 1), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportForVendorWithoutFiscalCodeAndVATRegNo_Datifattura()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [SCENARIO 229923] Error is expected when export VAT Report for vendor without "Fiscal Code" and "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "V" without "Fiscal Code" and "VAT Registration No."
        CreateVendor_Datifattura(Vendor);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Validate("Fiscal Code", '');
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"VAT Registration No." in Vendor: "V" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Vendor.FieldName("VAT Registration No."), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForVendorWithoutVATRegNo_Datifattura()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for vendor with "Fiscal Code" = 'PNDLSN69C50F205N'and blank "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "V" without "VAT Registration No." and "Fiscal Code" = 'PNDLSN69C50F205N'
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Validate("Fiscal Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor));
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] (252103) The second CodiceFiscale value = 'PNDLSN69C50F205N'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Vendor."Fiscal Code", LibraryXMLRead.GetNodeValueAtIndex('CodiceFiscale', 1), 'Incorrect CodiceFiscale value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForVendorWithoutFiscalCode_Datifattura()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for vendor with "VAT Registration No." = '08106710158' and blank "Fiscal Code"
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "V" without "Fiscal Code" and "VAT Registration No." = '08106710158'
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor));
        Vendor.Validate("Fiscal Code", '');
        Vendor.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] The second IdCodice value = '08106710158'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Vendor."VAT Registration No.", LibraryXMLRead.GetNodeValueAtIndex('IdCodice', 1), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportForIndividualCustomerWithoutFiscalCodeAndVATRegNo_Datifattura()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [SCENARIO 229923] Error is expected when export VAT Report for individual customer without "Fiscal Code" and "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Individual Customer "C" without "Fiscal Code" and "VAT Registration No."
        CreateIndividualCustomer(Customer);
        Customer.Validate("VAT Registration No.", '');
        Customer.Validate("Fiscal Code", '');
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice on 15.03.2019 for Customer "C"
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"Fiscal Code" in Customer: "C" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Customer.FieldName("Fiscal Code"), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForIndividualCustomerWithoutFiscalCode_Datifattura()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for individual customer with "VAT Registration No. = '08106710158' and blank "Fiscal Code"
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Individual Customer "C" with "VAT Registration No. = '08106710158' and blank "Fiscal Code"
        CreateIndividualCustomer(Customer);
        Customer.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer));
        Customer.Validate("Fiscal Code", '');
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice on 15.03.2019 for Customer "C"
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] (252103) The second IdCodice value = '08106710158'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Customer."VAT Registration No.", LibraryXMLRead.GetNodeValueAtIndex('IdCodice', 1), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenExportForCustomerWithoutFiscalCodeAndVATRegNo_Datifattura()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [SCENARIO 229923] Error is expected when export VAT Report for customer without "Fiscal Code" and "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer "C" without "Fiscal Code" and "VAT Registration No."
        CreateCustomer_Datifattura(Customer);
        Customer.Validate("VAT Registration No.", '');
        Customer.Validate("Fiscal Code", '');
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice on 15.03.2019 for Customer "C"
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"Fiscal Code" in Customer: "C" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Customer.FieldName("VAT Registration No."), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForCustomerWithoutVATRegNo_Datifattura()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for customer with "Fiscal Code" = 'PNDLSN69C50F205N'and blank "VAT Registration No."
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer "C" with "Fiscal Code" = 'PNDLSN69C50F205N'and blank "VAT Registration No."
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer.Validate("VAT Registration No.", '');
        Customer.Validate("Fiscal Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer));
        Customer."Country/Region Code" := 'IT';
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice on 15.03.2019 for Customer "C"
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] The second CodiceFiscale value = 'PNDLSN69C50F205N'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Customer."Fiscal Code", LibraryXMLRead.GetNodeValueAtIndex('CodiceFiscale', 1), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForCustomerWithoutFiscalCode_Datifattura()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 229923] Export VAT Report for customer with "VAT Registration No. = '08106710158' and blank "Fiscal Code"
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer "C" with "VAT Registration No. = '08106710158' and blank "Fiscal Code"
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer.Validate(
          "VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer));
        Customer.Validate("Fiscal Code", '');
        Customer."Country/Region Code" := 'IT';
        Customer.Modify(true);

        // [GIVEN] Posted Sales Invoice on 15.03.2019 for Customer "C"
        CreateAndPostSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] (252103) The second IdCodice value = '08106710158'
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Customer."VAT Registration No.", LibraryXMLRead.GetNodeValueAtIndex('IdCodice', 1), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportEUPurchaseInvoiceForGoods()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        NameValueBuffer: Record "Name/Value Buffer";
        CountryRegion: Record "Country/Region";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 232899] Export VAT Report for EU vendor with "EU Service" = No in VAT Posting Setup
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "V" with "Country/Region Code" = 'ES'
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] "Country/Region" ES with "EU Country/Region Code" = 'ES'
        CountryRegion.Get(Vendor."Country/Region Code");
        CountryRegion.Validate("EU Country/Region Code", Vendor."Country/Region Code");
        CountryRegion.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] TipoDocumento = 'TD10'
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.VerifyNodeValue('DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiGenerali/TipoDocumento', 'TD10');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportEUPurchaseInvoiceForServices()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        NameValueBuffer: Record "Name/Value Buffer";
        CountryRegion: Record "Country/Region";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
        FileName: Text;
    begin
        // [SCENARIO 232899] Export VAT Report for EU vendor with "EU Service" = Yes in VAT Posting Setup
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "V" with "Country/Region Code" = 'ES'
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] "Country/Region" ES with "EU Country/Region Code" = 'ES'
        CountryRegion.Get(Vendor."Country/Region Code");
        CountryRegion.Validate("EU Country/Region Code", Vendor."Country/Region Code");
        CountryRegion.Modify(true);

        // [GIVEN] VAT Posting Setup with "EU Service" = Yes
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50));
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Posted Purchase Invoice on 15.03.2019 for Vendor "V" and Item with the new VAT Posting Setup
        CreateAndPostPurchDocumentWithVATSetupEUService(
          PurchaseHeader, PurchaseLine, VATPostingSetup, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report on 15.03.2019
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] TipoDocumento = 'TD11'
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.VerifyNodeValue('DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiGenerali/TipoDocumento', 'TD11');

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportForeignGoodsPurchaseInvoiceWithLinkedCustomsAuthorityPurchaseInvoice()
    var
        CustomsAuthorityVendor: Record Vendor;
        ForeignVendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        FileName: Text;
        PostingDate: Date;
        RelatedEntryNo: Integer;
    begin
        // [SCENARIO 255742] Export foreign goods Purchase Invoice with linked Customs Authority Purchase Invoice
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Foreign Vendor "VF" with Country/Region = "US", "VAT Registration No." = "503912693"
        CreateVendor_Datifattura(ForeignVendor);

        // [GIVEN] Customs authority Vendor "Dogana", Address = "Via Monte Napoleone, 1", City = "Milan", "Country/Region Code" = "IT"
        CreateVendor_Datifattura(CustomsAuthorityVendor);
        UpdateCustomsAuthorityVendor(CustomsAuthorityVendor."No.");

        // [GIVEN] Posted foreign goods Purchase Invoice for Vendor "VF"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          ForeignVendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);
        RelatedEntryNo := FindVendorLedgerEntry(PostingDate, ForeignVendor."No.");

        // [GIVEN] Posted customs Purchase Invoice for "Dogana" with Related Entry No. = Entry No. from Vendor Ledger Entry posted at step 3;
        CreateLinkAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          CustomsAuthorityVendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true, RelatedEntryNo);

        // [WHEN] Export VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] File has two IdPaese, IdCodice, Denominazione, Indirizzo, Comune, Nazione nodes
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        VerifyIdentificativiFiscaliAndAltriDatiIdentificativiSubnodesCount(LibraryXMLRead, 2);

        // [THEN] CedentePrestatoreDTR/IdentificativiFiscali/IdFiscaleIVA/ nodes are related to the foreign Vendor "VF"
        // [THEN] IdPaese = "US"
        // [THEN] IdCodice = "503912693"
        VerifyIdentificativiFiscaliValuesByVendor(ForeignVendor, LibraryXMLRead, 1);

        // [THEN] CedentePrestatoreDTR/AltriDatiIdentificativi/ nodes are related to the customs authority Vendor "Dogana"
        // [THEN] Denominazione = "Dogana"
        // [THEN] Sede/Indirizzo = "Via Monte Napoleone, 1"
        // [THEN] Sede/Comune = "Milan"
        // [THEN] Sede/Nazione = "IT"
        VerifyAltriDatiIdentificativiValuesByVendor(CustomsAuthorityVendor, LibraryXMLRead, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportTwoPurchaseInvoicesWithoutVendLedgEntries()
    var
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [SCENARIO 255742] Export two Purchase Invoice without Vendor Ledger Entries
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor "Vend1"
        CreateVendor_Datifattura(Vendor1);

        // [GIVEN] Vendor "Vend2"
        CreateVendor_Datifattura(Vendor2);

        // [GIVEN] Posted Purchase Invoice for Vendor "Vend1" without Vendor Ledger Entries
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor1."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);
        DeleteVendorLedgerEntry(PostingDate, Vendor1."No.");

        // [GIVEN] Posted Purchase Invoice invoice for Vendor "Vend2" without Vendor Ledger Entries
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor2."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);
        DeleteVendorLedgerEntry(PostingDate, Vendor2."No.");

        // [WHEN] Export VAT Report on 15.03.2019..15.03.2019 with "VAT Report Config. Code" = Datifattura
        asserterror LibraryVATUtils.CreateVATReport(
            VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [THEN] There is no VAT Report on 15.03.2019
        VATReportHeader.SetRange("End Date", PostingDate);
        VATReportHeader.SetRange("Start Date", PostingDate);
        VATReportHeader.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::Datifattura);
        Assert.RecordIsEmpty(VATReportHeader);

        // [THEN] Expected error is "There is no Vendor Ledger Entry within the filter"
        Assert.ExpectedError('There is no Vendor Ledger Entry within the filter');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorIfContactCompanyWithBlankVATRegNoIsTaxRepresentativeOfVendor()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Tax Representative] [Company]
        // [SCENARIO 264347] Error shown if export VAT Report for vendor with Company contact with blank "VAT Registration No." as Tax Representative

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Contact "X" with type "Company" and blank "VAT Registration No."
        CreateContactCompany(Contact, '');

        // [GIVEN] Vendor "V" without "Tax Representative Type" = "Contact" and "Tax Representative No." = "X"
        VendNo := CreateVendorWithContactTypeRepresentative(Contact."No.");

        // [GIVEN] Posted Purchase Invoice for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendNo, LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"VAT Registration No." in Contact: "X" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Contact.FieldName("VAT Registration No."), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ContactCompanyWithVATRegNoIsTaxRepresentativeOfVendor()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendNo: Code[20];
        PostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [Tax Representative] [Company]
        // [SCENARIO 264347] Export VAT Report for vendor with Company contact with "VAT Registration No." as Tax Representative

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Contact "X" with type "Company" and "VAT Registration No." = "Y"
        CreateContactCompany(Contact, LibraryUtility.GenerateRandomCode(Contact.FieldNo("VAT Registration No."), DATABASE::Contact));

        // [GIVEN] Vendor "V" without "Tax Representative Type" = "Contact" and "Tax Representative No." = "X"
        VendNo := CreateVendorWithContactTypeRepresentative(Contact."No.");

        // [GIVEN] Posted Purchase Invoice for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendNo, LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] The third CodiceFiscale node has value "Y"
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Contact."VAT Registration No.", LibraryXMLRead.GetNodeValueAtIndex('IdCodice', 2), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorIfContactPersonWithBlankSurnameIsTaxRepresentativeOfVendor()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Tax Representative] [Person]
        // [SCENARIO 264347] Error shown if export VAT Report for vendor with Person contact with blank "Surname" as Tax Representative

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Contact "X" with type "Person" and blank "Surname"
        CreateContactPerson(Contact, '', '');

        // [GIVEN] Vendor "V" without "Tax Representative Type" = "Contact" and "Tax Representative No." = "X"
        VendNo := CreateVendorWithContactTypeRepresentative(Contact."No.");

        // [GIVEN] Posted Purchase Invoice for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendNo, LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is 'Surname in Contact: "X" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Contact.FieldName(Surname), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('ErrorMessagesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorIfContactPersonWithBlankFirstnameIsTaxRepresentativeOfVendor()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Tax Representative] [Person]
        // [SCENARIO 264347] Error shown if export VAT Report for vendor with Person contact with blank "First Name" as Tax Representative

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Contact "X" with type "Person", Surname and blank "First Name"
        CreateContactPerson(
          Contact, LibraryUtility.GenerateRandomCode(Contact.FieldNo(Surname), DATABASE::Contact), '');

        // [GIVEN] Vendor "V" without "Tax Representative Type" = "Contact" and "Tax Representative No." = "X"
        VendNo := CreateVendorWithContactTypeRepresentative(Contact."No.");

        // [GIVEN] Posted Purchase Invoice for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendNo, LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        asserterror ExportFile_Datifattura(VATReportHeader);

        // [THEN] Expected error description on page is '"First Name" in Contact: "X" must not be blank.'
        // Value is remembered in ErrorMessagesPageHandler
        Assert.ExpectedMessage(Contact.FieldName("First Name"), LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportContactPersonWithSurnameAndFirstnameIsTaxRepresentativeOfVendor()
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VendNo: Code[20];
        PostingDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [Tax Representative] [Person]
        // [SCENARIO 264347] Export VAT Report for vendor with Person contact with Surname and "First Name" as Tax Representative

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Contact "X" with type "Person", Surname and "First Name"
        CreateContactPerson(
          Contact, LibraryUtility.GenerateRandomCode(Contact.FieldNo(Surname), DATABASE::Contact),
          LibraryUtility.GenerateRandomCode(Contact.FieldNo("First Name"), DATABASE::Contact));

        // [GIVEN] Vendor "V" without "Tax Representative Type" = "Contact" and "Tax Representative No." = "X"
        VendNo := CreateVendorWithContactTypeRepresentative(Contact."No.");

        // [GIVEN] Posted Purchase Invoice for Vendor "V"
        CreateAndPostPurchDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          VendNo, LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Cognome node has value of Surname, Nome node has value of Name
        InitLibraryXMLRead_Datifattura(LibraryXMLRead, FileName);
        Assert.AreEqual(Contact.Surname, LibraryXMLRead.GetNodeValueAtIndex('Cognome', 0), 'Incorrect IdCodice value');
        Assert.AreEqual(Contact."First Name", LibraryXMLRead.GetNodeValueAtIndex('Nome', 0), 'Incorrect IdCodice value');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesFromOneSalesDocumentCreateOneDatiFatturaBody()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        DocumentNo: Code[20];
        FileName: Text;
        NoOfEntries: Integer;
        i: Integer;
        PostingDate: Date;
    begin
        // [SCENARIO 266128] Exported Datifattura Report file has one DatiFatturaBody part for one sales document with multiply lines.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer fot Datifattura Report.
        CreateCustomer_Datifattura(Customer);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number and Type = Sale.
        NoOfEntries := LibraryRandom.RandIntInRange(2, 100);
        for i := 1 to NoOfEntries do
            CreateVATEntryWithDocNoAndType(
              PostingDate, VATEntry.Type::Sale, Customer."No.", DocumentNo, VATEntry."Document Type"::Invoice);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] One DatiFatturaBodyDTE appearance.
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTE'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo appearance.
        Assert.AreEqual(NoOfEntries, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesFromOnePurchDocumentCreateOneDatiFatturaBody()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        FileName: Text;
        NoOfEntries: Integer;
        i: Integer;
        PostingDate: Date;
    begin
        // [SCENARIO 266128] Exported Datifattura Report file has one DatiFatturaBody part for one purchase document with multiply lines.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor fot Datifattura Report.
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number and Type = Purchase.
        NoOfEntries := LibraryRandom.RandIntInRange(2, 100);
        for i := 1 to NoOfEntries do begin
            CreateVATEntryWithDocNoAndType(
              PostingDate, VATEntry.Type::Purchase, Vendor."No.", DocumentNo, VATEntry."Document Type"::Invoice);
            MockGLEntryAndVendorLedgerEntry(
              DocumentNo, PostingDate, 0, Vendor."No.", VendorLedgerEntry."Document Type"::Invoice);
        end;

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] One DatiFatturaBodyDTR appearance.
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTR'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo appearance.
        Assert.AreEqual(NoOfEntries, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesFromTwoSalesDocumentsWithSameNoCreateTwoDatiFatturaBody()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        DocumentNo: Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [SCENARIO 266128] Exported Datifattura Report file has two DatiFatturaBody part for two sales documents with same Document No.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer fot Datifattura Report.
        CreateCustomer_Datifattura(Customer);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number, Type = Sale and different Document Type.
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Sale, Customer."No.", DocumentNo, VATEntry."Document Type"::Invoice);
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Sale, Customer."No.", DocumentNo, VATEntry."Document Type"::"Credit Memo");

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] Two DatiFatturaBodyDTE appearance.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTE'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo appearance.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure LinesFromTwoPurchDocumentsWithSameNoCreateTwoDatiFatturaBody()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [SCENARIO 266128] Exported Datifattura Report file has two DatiFatturaBody part for two purchase documents with same Document No.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor fot Datifattura Report.
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number, Type = Purchase and different Document Type.
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Purchase, Vendor."No.", DocumentNo, VATEntry."Document Type"::Invoice);
        MockGLEntryAndVendorLedgerEntry(
          DocumentNo, PostingDate, 0, Vendor."No.", VendorLedgerEntry."Document Type"::Invoice);

        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Purchase, Vendor."No.", DocumentNo, VATEntry."Document Type"::"Credit Memo");
        MockGLEntryAndVendorLedgerEntry(
          DocumentNo, PostingDate, 0, Vendor."No.", VendorLedgerEntry."Document Type"::"Credit Memo");

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] Two DatiFatturaBodyDTR appearance.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTR'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo appearance.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaForPurchaseInvoiceDatiIVA()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 267045] DatiIVA XML Node exist in exported DatiFattura VAT Report for Purchase Invoice with Posting Groups.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor.
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50));

        // [GIVEN] Posted Purchase Invoice for Vendor with the VAT Posting Setup.
        CreateAndPostPurchDocumentWithVATSetup(
          PurchaseHeader, PurchaseLine, VATPostingSetup, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has DatiIVA node.
        VerifyPurchaseDatiFatturaDatiIVANode(VATReportLine.Amount, VATPostingSetup."VAT %");

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaForSalesInvoiceDatiIVA()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267045] DatiIVA XML Node exist in exported DatiFattura VAT Report for Sales Invoice with Posting Groups.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer.
        CreateCustomer_Datifattura(Customer);

        // [GIVEN] VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50));

        // [GIVEN] Posted Sales Invoice for Customer with the VAT Posting Setup.
        CreateAndPostSalesDocumentWithVATSetup(
          SalesHeader, SalesLine, VATPostingSetup, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has DatiIVA node.
        VerifySalesDatiFatturaDatiIVANode(VATReportLine.Amount, VATPostingSetup."VAT %");

        // Tear Down
        VATPostingSetup.Delete();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaForPurchaseInvoiceDateNodes()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 266981] Data XML Node contains Document Date in exported DatiFattura VAT Report for Purchase Invoice.
        // [SCENARIO 266981] DataRegistrazione XML Node contains Posting Date in exported DatiFattura VAT Report for Purchase Invoice.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Vendor.
        CreateVendor_Datifattura(Vendor);

        // [GIVEN] Posted Purchase Invoice for Vendor with Document Date = 01.01.2018 and Posting Date = 01.02.2018.
        CreateAndPostPurchDocumentWithDates(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2),
          PostingDate, CalcDate('<-1M>', PostingDate), CalcDate('<-2M>', PostingDate),
          true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has Data XML Node with 01.01.2018 and DataRegistrazione XML Node with 01.02.2018.
        VerifyPurchaseDatiFatturaDateNodes(PurchaseHeader."Document Date", PurchaseHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaForSalesInvoiceDateNodes()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 267045] Data XML Node contains Document Date in exported DatiFattura VAT Report for Sales Invoice.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Customer.
        CreateCustomer_Datifattura(Customer);

        // [GIVEN] Posted Sales Invoice for Vendor with Document Date = 01.01.2018 and Posting Date = 01.02.2018.
        CreateAndPostSalesDocumentWithDates(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2),
          PostingDate, CalcDate('<-1M>', PostingDate), CalcDate('<-2M>', PostingDate),
          true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has Data XML Node with 01.01.2018.
        VerifySalesDatiFatturaDateNodes(SalesHeader."Document Date");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaNaturaReverseChargeVAT()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Datifattura] [Reverse Charge VAT] [VAT Report] [Export]
        // [SCENARIO 320154] Natura XML Node exists in exported DatiFattura VAT Report for Purchase Invoice with Reverse Charge VAT Posting Setup
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Created Vendor and Reverse Charge VAT Posting Setup with Natura code
        CreateVendor_Datifattura(Vendor);
        CreateReverseChargeVATPostingSetupWithNatura(VATPostingSetup, LibrarySplitVAT.CreateVATTransactionNatureCode());

        // [GIVEN] Posted Purchase Invoice for Vendor with VAT Posting Setup
        CreateAndPostPurchDocumentWithVATSetup(
          PurchaseHeader, PurchaseLine, VATPostingSetup, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] Created VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has correct Natura node
        VerifyPurchaseDatiFatturaNaturaNode(VATPostingSetup."VAT Transaction Nature");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DatifatturaSalesDocumentsWithSameNoAndTypeForDifferenVendorExportedAsSeparateElements()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Customer: array[2] of Record Customer;
        DocumentNo: Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Datifattura] [VAT Report] [Export]
        // [SCENARIO 354448] Exported Datifattura Report file has three AltriDatiIdentificativi elements for two sales documents with same Document No, Document Type but different Customers.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Two Customers for Datifattura Report.
        CreateCustomer_Datifattura(Customer[1]);
        CreateCustomer_Datifattura(Customer[2]);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number, Type = Sale and same Document Type for Customers.
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Sale, Customer[1]."No.", DocumentNo, VATEntry."Document Type"::Invoice);
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Sale, Customer[2]."No.", DocumentNo, VATEntry."Document Type"::Invoice);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] Three AltriDatiIdentificativi elements (one for Company and each Customer).
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('AltriDatiIdentificativi'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiFatturaBodyDTE elements.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTE'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo elements.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DatifatturaPurchaseDocumentsWithSameNoAndTypeForDifferenVendorExportedAsSeparateElements()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        Vendor: array[2] of Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        FileName: Text;
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Datifattura] [VAT Report] [Export]
        // [SCENARIO 354448] Exported Datifattura Report file has three AltriDatiIdentificativi elements for two purchase documents with same Document No, Document Type but different Vendors.
        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Two Vendors for Datifattura Report.
        CreateVendor_Datifattura(Vendor[1]);
        CreateVendor_Datifattura(Vendor[2]);

        // [GIVEN] One Document Number for all VAT Entries.
        DocumentNo :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."Document No."));

        // [GIVEN] Two VAT Entries with one Document Number, Type = Purchase and same Document Type for Vendors.
        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Purchase, Vendor[1]."No.", DocumentNo, VATEntry."Document Type"::Invoice);
        MockGLEntryAndVendorLedgerEntry(
          DocumentNo, PostingDate, 0, Vendor[1]."No.", VendorLedgerEntry."Document Type"::Invoice);

        CreateVATEntryWithDocNoAndType(
          PostingDate, VATEntry.Type::Purchase, Vendor[2]."No.", DocumentNo, VATEntry."Document Type"::Invoice);
        MockGLEntryAndVendorLedgerEntry(
          DocumentNo, PostingDate, 0, Vendor[2]."No.", VendorLedgerEntry."Document Type"::Invoice);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura.
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] One files was exported.
        FileName := GetFileNameWithCountCheck();
        LibraryXMLRead.Initialize(FileName);

        // [THEN] Three AltriDatiIdentificativi elements (one for Company and each Vendor).
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('AltriDatiIdentificativi'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiFatturaBodyDTR elements.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiFatturaBodyDTR'), DatiFatturaForOneDocumentWithMultipleLinesErr);

        // [THEN] Two DatiRiepilogo elements.
        Assert.AreEqual(2, LibraryXMLRead.GetNodesCount('DatiRiepilogo'), DatiFatturaForOneDocumentWithMultipleLinesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaForSalesInvoiceWithNonDefaultFatturaDocType()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 394014] TipoDocumento XML node has a value of Fattura Document Type of the posted sales invoice in the exported DatiFattura VAT Report

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Posted sales invoice with "Fattura Document Type" = "TD26"
        CreateCustomer_Datifattura(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Fattura Document Type", LibraryITLocalization.GetRandomFatturaDocType(''));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [WHEN] Export VAT Report.
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has TipoDocumento xml node with value "TD26"
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiGenerali/TipoDocumento', SalesHeader."Fattura Document Type");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportDatiFatturaAfterChangingFatturaDocTypeInVATReportLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostingDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 394014] TipoDocumento XML node has a value of Fattura Document Type of the VAT Report Line in the exported DatiFattura VAT Report

        Initialize();
        PostingDate := CalcDate('<CM+1Y>', GetPostingDate());

        // [GIVEN] Posted sales invoice with default "Fattura Document Type" = "TD01"
        CreateCustomer_Datifattura(Customer);
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(50));
        CreateAndPostSalesDocumentWithVATSetup(
          SalesHeader, SalesLine, VATPostingSetup, SalesHeader."Document Type"::Invoice,
          Customer."No.", LibraryRandom.RandDec(1000, 2), PostingDate, true, true);

        // [GIVEN] VAT Report with "VAT Report Config. Code" = Datifattura
        LibraryVATUtils.CreateVATReport(
          VATReportHeader, VATReportLine, VATReportHeader."VAT Report Config. Code"::Datifattura, PostingDate, PostingDate);

        // [GIVEN] "Fattura Document Type" is changed in VAT Report Line to "TD26"
        VATReportLine.Validate("Fattura Document Type", LibraryITLocalization.GetRandomFatturaDocType(''));
        VATReportLine.Modify(true);

        // [WHEN] Export VAT Report
        ExportFile_Datifattura(VATReportHeader);

        // [THEN] Exported DatiFattura VAT Report has TipoDocumento xml node with value "TD26"
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiGenerali/TipoDocumento', VATReportLine."Fattura Document Type");
    end;

    local procedure Initialize()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        NameValueBuffer.DeleteAll();
        UpdateVATPostingSetup(VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);
        LibraryITDatifattura.CreateGeneralSetup();
        LibraryITDatifattura.CreateGeneralSetupDatifattura();

        if isInitialized then
            exit;

        CreateVATReportSetup();
        isInitialized := true;
        Commit();
    end;

    local procedure AddNewNameValueBuffer(Name: Text; Value: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
        Id: Integer;
    begin
        if NameValueBuffer.FindLast() then;
        Id := NameValueBuffer.ID + 1;

        NameValueBuffer.ID := Id;
        NameValueBuffer.Name := CopyStr(Name, 1, MaxStrLen(NameValueBuffer.Name));
        NameValueBuffer.Value := CopyStr(Value, 1, MaxStrLen(NameValueBuffer.Value));
        NameValueBuffer.Insert();
    end;

    local procedure AssertIsAlphanumeric(Value: Text)
    var
        AlphanumericValue: Text;
    begin
        AlphanumericValue := GetAlphanumeric(Value);
        Assert.AreEqual(AlphanumericValue, Value, '');
    end;

    [HandlerFunctions('MessageHandler')]
    local procedure ExportTest(DocumentType: Enum "Gen. Journal Document Type"; Resident: Option; IndividualPerson: Boolean; VATReportType: Option; GenPostingType: Enum "General Posting Type"; ContractPaymentType: Option)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        TextFile: BigText;
        Index: Integer;
        Verified: Boolean;
        CurrWorkDate: Date;
    begin
        Initialize();
        CurrWorkDate := WorkDate();

        // Setup
        LibraryITDatifattura.CreateGeneralSetup();
        GenerateReportLine(VATReportHeader, VATReportLine, IndividualPerson, Resident,
          DocumentType, GenPostingType, VATReportType, ContractPaymentType);

        // Execute
        ExportFile(TextFile, VATReportHeader, true);

        // Verify line structure
        for Index := 1 to Round(TextFile.Length / 1900, 1, '>') do
            VerifyLine(TextFile, Index);

        // Verify Header
        VerifyHeader(TextFile, VATReportHeader, 1, 1);
        VerifyBRecord(TextFile, VATReportHeader, 2);

        if VATReportType = VATReportHeader."VAT Report Type"::"Cancellation " then begin
            VerifyFooter(TextFile, 3);
            exit;
        end;

        VerifyERecord(TextFile, 4);
        VerifyFooter(TextFile, 5);

        // Verify specific line
        Verified := false;
        if (Resident = GenJournalLine2.Resident::Resident) and (DocumentType = GenJournalLine2."Document Type"::Invoice) then
            if IndividualPerson and (GenPostingType = GenJournalLine2."Gen. Posting Type"::Sale) then
                Verified := VerifyResidentFiscalCode(TextFile, VATReportLine, 3)
            else
                if GenPostingType = GenJournalLine2."Gen. Posting Type"::Sale then
                    Verified := VerifyResidentVATRegNoSale(TextFile, VATReportLine, 3)
                else
                    Verified := VerifyResidentVATRegNoPurchase(TextFile, VATReportLine, 3);

        if (Resident = GenJournalLine2.Resident::Resident) and
           (DocumentType = GenJournalLine2."Document Type"::"Credit Memo") and
           (GenPostingType = GenJournalLine2."Gen. Posting Type"::Sale)
        then
            Verified := VerifyCrMemoResidentSale(TextFile, VATReportLine, 3);

        if (Resident = GenJournalLine2.Resident::Resident) and
           (DocumentType = GenJournalLine2."Document Type"::"Credit Memo") and
           (GenPostingType = GenJournalLine2."Gen. Posting Type"::Purchase)
        then
            Verified := VerifyCrMemoResidentPurchase(TextFile, VATReportLine, 3);

        if (Resident = GenJournalLine2.Resident::"Non-Resident") and
           (DocumentType = GenJournalLine2."Document Type"::Invoice) and
           (GenPostingType = GenJournalLine2."Gen. Posting Type"::Sale)
        then
            Verified := VerifyNonResidentSale(TextFile, VATReportLine, 3);

        if (Resident = GenJournalLine2.Resident::"Non-Resident") and
           (DocumentType = GenJournalLine2."Document Type"::Invoice) and
           (GenPostingType = GenJournalLine2."Gen. Posting Type"::Purchase)
        then
            Verified := VerifyNonResidentPurchase(TextFile, VATReportLine, 3);

        if (Resident = GenJournalLine2.Resident::"Non-Resident") and (DocumentType = GenJournalLine2."Document Type"::"Credit Memo") then
            Verified := VerifyCrMemoNonResident(TextFile, VATReportLine, 3);

        if Verified = false then
            Error(NoVerifierMatchedErr);

        // Tear Down
        WorkDate(CurrWorkDate);
    end;

    [HandlerFunctions('MessageHandler')]
    local procedure ExportTestForIntermediary(IntermediaryBlank: Boolean; TaxRepBlank: Boolean)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        VATReportSetup: Record "VAT Report Setup";
        CompanyInfo: Record "Company Information";
        TextFile: BigText;
        CurrWorkDate: Date;
    begin
        Initialize();
        CurrWorkDate := WorkDate();

        // Setup
        LibraryITDatifattura.CreateGeneralSetup();

        if IntermediaryBlank then begin
            VATReportSetup.Get();
            VATReportSetup.Validate("Intermediary CAF Reg. No.", '');
            VATReportSetup.Validate("Intermediary Date", 0D);
            VATReportSetup.Modify(true);
        end;
        if TaxRepBlank then begin
            CompanyInfo.Get();
            CompanyInfo.Validate("Tax Representative No.", '');
            CompanyInfo.Modify(true);
        end;

        GenerateReportLine(VATReportHeader, VATReportLine, true, GenJournalLine2.Resident::Resident,
          GenJournalLine2."Document Type"::Invoice, GenJournalLine2."Gen. Posting Type"::Sale,
          VATReportHeader2."VAT Report Type"::Standard,
          VATReportLine2."Contract Payment Type"::"Without Contract");

        // Execute
        ExportFile(TextFile, VATReportHeader, true);

        // Verify Header and Footer lines
        VerifyHeader(TextFile, VATReportHeader, 1, 1);
        VerifyBRecord(TextFile, VATReportHeader, 2);
        VerifyFooter(TextFile, 5);

        // Tear Down
        WorkDate(CurrWorkDate);
    end;

    local procedure ExportFile(var TextFile: BigText; VATReportHeader: Record "VAT Report Header"; DetailedExport: Boolean)
    var
        ExportVATTransactions: Report "Export VAT Transactions";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        FileName: Text[250];
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
        VATReportHeader.SetFilter("No.", VATReportHeader."No.");
        ExportVATTransactions.SetTableView(VATReportHeader);
        ExportVATTransactions.UseRequestPage(false);
        FileName := TemporaryPath + LibraryUtility.GenerateGUID() + '.ccf';
        ExportVATTransactions.InitializeRequest(FileName, DetailedExport);
        ExportVATTransactions.RunModal();
        LoadFile(TextFile, FileName);
    end;

    local procedure ExportFile_Datifattura(VATReportHeader: Record "VAT Report Header")
    var
        DatifatturaExport: Codeunit "Datifattura Export";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        ITVATReportingExport: Codeunit "IT - VAT Reporting - Export";
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
        VATReportHeader.SetFilter("No.", VATReportHeader."No.");
        BindSubscription(ITVATReportingExport);
        DatifatturaExport.Run(VATReportHeader);
        UnbindSubscription(ITVATReportingExport);
    end;

    local procedure FormatAmount(Amount: Decimal; FieldLength: Integer) FormattedAmount: Text[250]
    var
        Index: Integer;
    begin
        Amount := Round(Amount, 1);
        FormattedAmount := Format(Amount, 0, '<Integer>');
        for Index := 1 to FieldLength - StrLen(FormattedAmount) do
            FormattedAmount := '0' + FormattedAmount;
    end;

    local procedure FormatDateDDMMYYYY(Date: Date): Text[8]
    begin
        if Date <> 0D then
            exit(Format(Date, 0, '<Day,2><Month,2><Year4>'));
        exit(LibrarySpesometro.FormatNumber('0', 8));
    end;

    local procedure GetAlphanumeric(Value: Text) AlphanumericValue: Text
    var
        Char: Char;
        i: Integer;
    begin
        for i := 1 to StrLen(Value) do begin
            Char := Value[i];
            if Char in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z'] then
                AlphanumericValue += Format(Value[i]);
        end;
    end;

    local procedure GetFileNameByGUID(FileGIUD: Text) FileName: Text
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, FileGIUD);
        NameValueBuffer.FindSet();
        repeat
            FileName += NameValueBuffer.Value;
        until NameValueBuffer.Next() = 0;
    end;

    local procedure GetFileNameWithCountCheck(): Text
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, 'FileGUID');
        Assert.RecordCount(NameValueBuffer, 1);
        NameValueBuffer.FindFirst();
        exit(GetFileNameByGUID(NameValueBuffer.Value));
    end;

    local procedure GetInetRoot(): Text
    begin
        exit(ApplicationPath + '\..\..\..\');
    end;

    local procedure GenerateReportLine(var VATReportHeader: Record "VAT Report Header"; var VATReportLine: Record "VAT Report Line"; IndividualPerson: Boolean; Resident: Option; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; VATReportType: Option; ContractPaymentType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
        VATReportMediator: Codeunit "VAT Report Mediator";
        VATReportNo: Code[20];
        AccountType: Enum "Gen. Journal Account Type";
    begin
        WorkDate(GetPostingDate());
        SetupThresholdAmount(WorkDate());
        UpdateVATPostingSetup(VATPostingSetup."VAT Calculation Type"::"Normal VAT", true);
        if GenPostingType = GenJournalLine."Gen. Posting Type"::Sale then
            AccountType := GenJournalLine."Account Type"::Customer
        else
            AccountType := GenJournalLine."Account Type"::Vendor;
        CreatePostGenJnlLine(GenJournalLine, DocumentType, AccountType,
          GenPostingType, IndividualPerson, Resident);
        CreateVATReport(VATReportHeader, VATReportLine, VATReportHeader."VAT Report Type"::Standard);

        if VATReportType <> VATReportHeader."VAT Report Type"::Standard then begin
            VATReportNo := VATReportHeader."No.";
            VATReportHeader.Validate("Tax Auth. Receipt No.", Format(LibraryRandom.RandInt(100)));
            VATReportHeader.Validate("Tax Auth. Document No.", Format(LibraryRandom.RandInt(100)));
            VATReportHeader.Modify(true);
            VATReportReleaseReopen.Release(VATReportHeader);
            VATReportReleaseReopen.Submit(VATReportHeader);
            Clear(VATReportHeader);
            CreateVATReportHeader(VATReportHeader, VATReportType);
            VATReportHeader.Validate("Original Report No.", VATReportNo);
            VATReportHeader.Modify(true);
            VATReportMediator.GetLines(VATReportHeader);
            VATReportLine.SetFilter("VAT Report No.", VATReportHeader."No.");
            if VATReportType = VATReportHeader."VAT Report Type"::Corrective then
                VATReportLine.FindFirst();
        end;

        if VATReportType <> VATReportHeader."VAT Report Type"::"Cancellation " then begin
            VATReportLine.Validate("Contract Payment Type", ContractPaymentType);
            VATReportLine.Modify(true);
        end;
    end;

    local procedure LoadFile(var TextFile: BigText; FileName: Text[250])
    var
        File: File;
        InStr: InStream;
    begin
        File.Open(FileName);
        File.CreateInStream(InStr);
        TextFile.Read(InStr);
    end;

    [Scope('OnPrem')]
    procedure ValidateXmlAgainstXsdSchema(XMLDoc: DotNet XmlDocument)
    var
        FileManagement: Codeunit "File Management";
        LibraryVerifyXMLSchema: Codeunit "Library - Verify XML Schema";
        XmlStream: OutStream;
        XmlFile: File;
        XmlPath: Text;
        XsdPath: Text;
        SignatureXsdPath: Text;
        Message: Text;
    begin
        XmlPath := FileManagement.ServerTempFileName('xml');
        XmlFile.Create(XmlPath);
        XmlFile.CreateOutStream(XmlStream);
        XMLDoc.Save(XmlStream);
        XmlFile.Close();

        SignatureXsdPath := GetInetRoot() + '\GDL\IT\App\Test\XMLSchemas\xmldsig-core-schema.xsd';
        LibraryVerifyXMLSchema.SetAdditionalSchemaPath(SignatureXsdPath);
        XsdPath := GetInetRoot() + '\GDL\IT\App\Test\XMLSchemas\fornituraIvp_2018_v1.xsd';
        Assert.IsTrue(LibraryVerifyXMLSchema.VerifyXMLAgainstSchema(XmlPath, XsdPath, Message), Message);
    end;

    local procedure VerifyCrMemoNonResident(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    begin
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        VerifyNonResidentDataSale(TextFile, VATReportLine, LineNo);

        LibrarySpesometro.VerifyValue(TextFile, FormatDateDDMMYYYY(VATReportLine."Operation Occurred Date"), LineNo, 242, 8, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, VATReportLine."Document No.", LineNo, 250, 15, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, FormatAmount(VATReportLine.Base, 9), LineNo, 265, 9, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, FormatAmount(VATReportLine.Amount, 9), LineNo, 274, 9, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, FormatDateDDMMYYYY(VATReportLine."Invoice Date"), LineNo, 283, 8, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, VATReportLine."Invoice No.", LineNo, 291, 15, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, 'C', LineNo, 306, 1, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, 'C', LineNo, 307, 1, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 308, 1490 - (1490 - 1024), ConstFormat::CB); // 1024 characters limit on Text length
        LibrarySpesometro.VerifyValue(TextFile, '', LineNo, 308 + 1024, 1490 - 1024, ConstFormat::CB); // 1024 characters limit on Text length
        LibrarySpesometro.VerifyValue(TextFile, 'A', LineNo, 1798, 1, ConstFormat::CB);
        exit(true);
    end;

    local procedure VerifyCrMemoResidentSale(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(VATReportLine."VAT Entry No.");
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);

        if VATEntry."Individual Person" then begin
            VerifyBlockValue(TextFile, LineNo, 'NE001001', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'NE001002', VATEntry."Fiscal Code", false, true)
        end else begin
            VerifyBlockValue(
              TextFile, LineNo, 'NE001001', LibrarySpesometro.FormatPadding(ConstFormat::PI, VATEntry."VAT Registration No.", 16), false, true);
            VerifyBlockValue(TextFile, LineNo, 'NE001002', '', true, true)
        end;
        VerifyBlockValue(
          TextFile, LineNo, 'NE001003',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NE001004',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(TextFile, LineNo, 'NE001005', VATEntry."Document No.", false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NE001006',
          LibrarySpesometro.FormatPadding(ConstFormat::NU,
            Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NE001007',
          LibrarySpesometro.FormatPadding(ConstFormat::NU,
            Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'NE001008', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'NE001008', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);
        exit(true);
    end;

    local procedure VerifyCrMemoResidentPurchase(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        VATEntry.Get(VATReportLine."VAT Entry No.");
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, 'NR', LineNo, 90, 2, ConstFormat::CB);
        Vendor.Get(VATReportLine."Bill-to/Pay-to No.");

        if not (VATEntry."Individual Person" and (GetVendorVATRegNo(Vendor, VATEntry) = '')) then
            VerifyBlockValue(
              TextFile, LineNo, 'NR001001', LibrarySpesometro.FormatPadding(ConstFormat::PI, GetVendorVATRegNo(Vendor, VATEntry), 16), false,
              true);

        VerifyBlockValue(
          TextFile, LineNo, 'NR001002',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16)
          , false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NR001003',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NR001004',
          LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0,
              '<integer>'), 16), false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'NR001005',
          LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0
              , '<integer>'), 16), false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'NR001006', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'NR001006', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);

        exit(true);
    end;

    local procedure VerifyDatiFatturaAttributes(FileName: Text)
    var
        XMLDoc: DotNet XmlDocument;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLDoc.Load(FileName);
        ValidateXmlAgainstXsdSchema(XMLDoc);
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyAttributeValue('ns2:DatiFattura', 'xmlns:xs', StandardDatifatturaXmlnsXsAttrTxt);
        LibraryXMLRead.VerifyAttributeValue('ns2:DatiFattura', 'xmlns:ds', StandardDatifatturaXmlnsDsAttrTxt);
        LibraryXMLRead.VerifyAttributeValue('ns2:DatiFattura', 'versione', 'DAT20');
        LibraryXMLRead.VerifyAttributeValue('ns2:DatiFattura', 'xmlns:ns2', StandardDatifatturaXmlnsNs2AttrTxt);
    end;

    local procedure VerifyDatiFatturaInvoiceNoAndDate(FileName: Text; PostingDate: Date; Numero: Text)
    begin
        LibraryXMLRead.Initialize(FileName);
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('Numero'), 'Incorrect Numero count');
        Assert.AreEqual(GetAlphanumeric(Numero), LibraryXMLRead.GetNodeValueAtIndex('Numero', 0), 'Incorrect Numero value');
        AssertIsAlphanumeric(LibraryXMLRead.GetNodeValueAtIndex('Numero', 0));
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('Data'), 'Incorrect Data count');
        Assert.AreEqual(
          Format(PostingDate, 0, '<Year4>-<Month,2>-<Day,2>'), LibraryXMLRead.GetNodeValueAtIndex('Data', 0), 'Incorrect Data value');
    end;

    local procedure VerifyDatiFatturaFileForScenarioWithOneFile(NodeName: Text; SuggestedFileName: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, 'FileGUID');
        Assert.RecordCount(NameValueBuffer, 1);
        NameValueBuffer.FindFirst();
        LibraryXMLRead.Initialize(GetFileNameByGUID(NameValueBuffer.Value));
        Assert.AreEqual(1000, LibraryXMLRead.GetNodesCount(NodeName), 'File is incorrect');

        NameValueBuffer.SetRange(Name, 'SuggestedFileName');
        NameValueBuffer.FindFirst();
        Assert.AreEqual(SuggestedFileName, NameValueBuffer.Value, 'File name is incorrect');
    end;

    local procedure VerifyDatiFatturaSplittedFilesForScenarioWithThreeFiles(NodeName: Text; SuggestedFileName: array[3] of Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.SetRange(Name, 'FileGUID');
        Assert.RecordCount(NameValueBuffer, 3);
        NameValueBuffer.FindFirst();
        LibraryXMLRead.Initialize(GetFileNameByGUID(NameValueBuffer.Value));
        Assert.AreEqual(1000, LibraryXMLRead.GetNodesCount(NodeName), 'First file is incorrect');
        NameValueBuffer.Next();
        LibraryXMLRead.Initialize(GetFileNameByGUID(NameValueBuffer.Value));
        Assert.AreEqual(1000, LibraryXMLRead.GetNodesCount(NodeName), 'Second file is incorrect');
        NameValueBuffer.Next();
        LibraryXMLRead.Initialize(GetFileNameByGUID(NameValueBuffer.Value));
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount(NodeName), 'Third file is incorrect');

        NameValueBuffer.SetRange(Name, 'SuggestedFileName');
        NameValueBuffer.FindFirst();
        Assert.AreEqual(SuggestedFileName[1], NameValueBuffer.Value, 'First file name is incorrect');
        NameValueBuffer.Next();
        Assert.AreEqual(SuggestedFileName[2], NameValueBuffer.Value, 'Second file name is incorrect');
        NameValueBuffer.Next();
        Assert.AreEqual(SuggestedFileName[3], NameValueBuffer.Value, 'Third file name is incorrect');
    end;

    local procedure VerifyLine(var TextFile: BigText; LineNo: Integer)
    begin
        LibrarySpesometro.VerifyLine(TextFile, LineNo);
    end;

    local procedure VerifyHeader(var TextFile: BigText; var VATReportHeader: Record "VAT Report Header"; LineNo: Integer; NoTransmissions: Integer)
    begin
        LibrarySpesometro.VerifyHeader(TextFile, LineNo, 1, NoTransmissions, VATReportHeader."Start Date", VATReportHeader."End Date");
    end;

    local procedure VerifyFooter(var TextFile: BigText; LineNo: Integer)
    begin
        LibrarySpesometro.VerifyFooter(TextFile, LineNo);
    end;

    local procedure VerifyNonResidentSale(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(VATReportLine."VAT Entry No.");
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        VerifyNonResidentDataSale(TextFile, VATReportLine, LineNo);
        VerifyBlockValue(
          TextFile, LineNo, 'FN001011',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16)
          , false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FN001012',
          LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(TextFile, LineNo, 'FN001013', VATEntry."Document No.", false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FN001015',
          LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0,
              '<integer>'), 16), false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FN001016',
          LibrarySpesometro.FormatPadding(ConstFormat::NP, Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0
              , '<integer>'), 16), false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'FN001017', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FN001017', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);

        exit(true);
    end;

    local procedure VerifyNonResidentPurchase(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(VATReportLine."VAT Entry No.");
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        VerifyNonResidentDataPurchase(TextFile, VATReportLine, LineNo);
        VerifyBlockValue(
          TextFile, LineNo, 'SE001012',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'SE001013',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(TextFile, LineNo, 'SE001014', VATEntry."Document No.", false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'SE001015',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'SE001016',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'SE001017', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'SE001017', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);
        exit(true);
    end;

    local procedure VerifyNonResidentDataSale(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer)
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        VATEntry: Record "VAT Entry";
    begin
        CountryRegion.Get(VATReportLine."Country/Region Code");
        VATEntry.Get(VATReportLine."VAT Entry No.");
        Customer.Get(VATReportLine."Bill-to/Pay-to No.");
        if VATEntry."Individual Person" then begin
            VerifyBlockValue(TextFile, LineNo, 'FN001001', VATEntry."Last Name", false, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001002', VATEntry."First Name", false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'FN001003',
              LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Date of Birth", ConstFormat::DT), 16),
              false,
              true);
            VerifyBlockValue(TextFile, LineNo, 'FN001004', VATEntry."Place of Birth", false, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001005', Customer.County, false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'FN001006', LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
              false, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001007', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001008', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001009', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001010', '', true, true);
        end else begin
            VerifyBlockValue(TextFile, LineNo, 'FN001001', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001002', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001003', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001004', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001005', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001006', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001007', Customer.Name, false, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001008', Customer.City, false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'FN001009', LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
              false, true);
            VerifyBlockValue(TextFile, LineNo, 'FN001010', Customer.Address, false, true);
        end;
    end;

    local procedure VerifyNonResidentDataPurchase(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer)
    var
        Vendor: Record Vendor;
        CountryRegion: Record "Country/Region";
        VATEntry: Record "VAT Entry";
    begin
        CountryRegion.Get(VATReportLine."Country/Region Code");
        VATEntry.Get(VATReportLine."VAT Entry No.");
        Vendor.Get(VATReportLine."Bill-to/Pay-to No.");
        if VATEntry."Individual Person" then begin
            VerifyBlockValue(TextFile, LineNo, 'SE001001', VATEntry."Last Name", false, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001002', VATEntry."First Name", false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'SE001003',
              LibrarySpesometro.FormatPadding(ConstFormat::DT, LibrarySpesometro.FormatDate(VATEntry."Date of Birth", ConstFormat::DT), 16),
              false,
              true);
            VerifyBlockValue(TextFile, LineNo, 'SE001004', VATEntry."Place of Birth", false, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001005', Vendor.County, false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'SE001006', LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
              false, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001007', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001008', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001009', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001010', '', true, true);
        end else begin
            VerifyBlockValue(TextFile, LineNo, 'SE001001', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001002', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001003', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001004', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001005', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001006', '', true, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001007', Vendor.Name, false, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001008', Vendor.City, false, true);
            VerifyBlockValue(
              TextFile, LineNo, 'SE001009', LibrarySpesometro.FormatPadding(ConstFormat::NU, CountryRegion."Foreign Country/Region Code", 16),
              false, true);
            VerifyBlockValue(TextFile, LineNo, 'SE001010', Vendor.Address, false, true);
        end;
    end;

    local procedure VerifyResidentFiscalCode(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);

        LibrarySpesometro.VerifyValue(TextFile, 'FE', LineNo, 90, 2, ConstFormat::CB);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        VerifyBlockValue(TextFile, LineNo, 'FE001001', '', true, true);
        VerifyBlockValue(TextFile, LineNo, 'FE001002', VATEntry."Fiscal Code", false, true);
        if VATEntry."Deductible %" < 100 then
            VerifyBlockValue(TextFile, LineNo, 'FE001004', '1', false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001007',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001008',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(TextFile, LineNo, 'FE001009', VATEntry."Document No.", false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001010',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001011',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'FE001012', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FE001012', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);

        exit(true);
    end;

    local procedure VerifyResidentVATRegNoSale(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
    begin
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, 'FE', LineNo, 90, 2, ConstFormat::CB);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        VerifyBlockValue(
          TextFile, LineNo, 'FE001001', LibrarySpesometro.FormatPadding(ConstFormat::PI, VATReportLine."VAT Registration No.", 16), false,
          true);
        VerifyBlockValue(TextFile, LineNo, 'FE001002', '', true, true);
        if VATEntry."Deductible %" < 100 then
            VerifyBlockValue(TextFile, LineNo, 'FE001004', '1', false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001007',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001008',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(TextFile, LineNo, 'FE001009', VATEntry."Document No.", false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001010',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FE001011',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'FE001012', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FE001012', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);
        exit(true);
    end;

    local procedure VerifyResidentVATRegNoPurchase(var TextFile: BigText; var VATReportLine: Record "VAT Report Line"; LineNo: Integer): Boolean
    var
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
    begin
        LibrarySpesometro.VerifyValue(TextFile, 'D', LineNo, 1, 1, ConstFormat::CB);
        LibrarySpesometro.VerifyValue(TextFile, 'FR', LineNo, 90, 2, ConstFormat::CB);
        VATEntry.Get(VATReportLine."VAT Entry No.");
        Vendor.Get(VATReportLine."Bill-to/Pay-to No.");

        if GetVendorVATRegNo(Vendor, VATEntry) <> '' then
            VerifyBlockValue(
              TextFile, LineNo, 'FR001001', LibrarySpesometro.FormatPadding(ConstFormat::PI, GetVendorVATRegNo(Vendor, VATEntry), 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FR001002', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), true, true);

        VerifyBlockValue(
          TextFile, LineNo, 'FR001003',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Document Date", ConstFormat::DT), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FR001004',
          LibrarySpesometro.FormatPadding(ConstFormat::DT,
            LibrarySpesometro.FormatDate(VATEntry."Posting Date", ConstFormat::DT), 16),
          false, true);

        if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then
            VerifyBlockValue(TextFile, LineNo, 'FR001006', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FR001006', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);

        VerifyBlockValue(TextFile, LineNo, 'FR001007', '', true, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FR001008',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryBase(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        VerifyBlockValue(
          TextFile, LineNo, 'FR001009',
          LibrarySpesometro.FormatPadding(ConstFormat::NP,
            Format(Round(LibraryVATUtils.TotalVATEntryAmount(VATEntry), 1), 0, '<integer>'), 16),
          false, true);
        if LibraryVATUtils.TotalVATEntryBase(VATEntry) > LibrarySpesometro.GetThresholdAmount() then
            VerifyBlockValue(TextFile, LineNo, 'FR001010', LibrarySpesometro.FormatPadding(ConstFormat::CB, '1', 16), false, true)
        else
            VerifyBlockValue(TextFile, LineNo, 'FR001010', LibrarySpesometro.FormatPadding(ConstFormat::CB, '0', 16), false, true);
        exit(true);
    end;

    local procedure VerifyBRecord(var TextFile: BigText; var VATReportHeader: Record "VAT Report Header"; LineNo: Integer)
    var
        SpesometroExport: Codeunit "Spesometro Export";
    begin
        LibrarySpesometro.VerifyBRecord(TextFile, LineNo, 'D',
          SpesometroExport.MapVATReportType(VATReportHeader."VAT Report Type"), VATReportHeader."Original Report No.",
          VATReportHeader."Start Date");
    end;

    local procedure VerifyERecord(var TextFile: BigText; LineNo: Integer)
    begin
        LibrarySpesometro.VerifyERecord(TextFile, LineNo);
    end;

    local procedure VerifyIdentificativiFiscaliAndAltriDatiIdentificativiSubnodesCount(var LibraryXMLRead2: Codeunit "Library - XML Read"; "Count": Integer)
    begin
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('IdPaese'), 'Incorrect IdPaese count');
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('IdCodice'), 'Incorrect IdCodice count');
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('Denominazione'), 'Incorrect Denominazione count');
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('Indirizzo'), 'Incorrect Indirizzo count');
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('Comune'), 'Incorrect Comune count');
        Assert.AreEqual(Count, LibraryXMLRead2.GetNodesCount('Nazione'), 'Incorrect Nazione count');
    end;

    local procedure VerifyIdentificativiFiscaliValuesByVendor(Vendor: Record Vendor; var LibraryXMLRead2: Codeunit "Library - XML Read"; Index: Integer)
    begin
        Assert.AreEqual(Vendor."Country/Region Code", LibraryXMLRead2.GetNodeValueAtIndex('IdPaese', Index), 'IdPaese');
        Assert.AreEqual(Vendor."VAT Registration No.", LibraryXMLRead2.GetNodeValueAtIndex('IdCodice', Index), 'IdCodice');
    end;

    local procedure VerifyAltriDatiIdentificativiValuesByVendor(Vendor: Record Vendor; var LibraryXMLRead2: Codeunit "Library - XML Read"; Index: Integer)
    begin
        Assert.AreEqual(Vendor.Name, LibraryXMLRead2.GetNodeValueAtIndex('Denominazione', Index), 'Denominazione');
        Assert.AreEqual(Vendor.Address, LibraryXMLRead2.GetNodeValueAtIndex('Indirizzo', Index), 'Indirizzo');
        Assert.AreEqual(Vendor.City, LibraryXMLRead2.GetNodeValueAtIndex('Comune', Index), 'Comune');
        Assert.AreEqual(Vendor."Country/Region Code", LibraryXMLRead2.GetNodeValueAtIndex('Nazione', Index), 'Nazione');
    end;

    local procedure VerifySalesDatiFatturaDatiIVANode(VATReportLineAmount: Decimal; VATPostingSetupVATPercent: Decimal)
    begin
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/DatiIVA/Imposta',
          Format(Abs(VATReportLineAmount), 0, '<Precision,2:2><Standard Format,9>'));
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/DatiIVA/Aliquota',
          Format(VATPostingSetupVATPercent, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure VerifyPurchaseDatiFatturaDatiIVANode(VATReportLineAmount: Decimal; VATPostingSetupVATPercent: Decimal)
    begin
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiRiepilogo/DatiIVA/Imposta',
          Format(Abs(VATReportLineAmount), 0, '<Precision,2:2><Standard Format,9>'));
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiRiepilogo/DatiIVA/Aliquota',
          Format(VATPostingSetupVATPercent, 0, '<Precision,2:2><Standard Format,9>'));
    end;

    local procedure VerifySalesDatiFatturaDateNodes(DocumentDate: Date)
    begin
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiGenerali/Data',
          Format(DocumentDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure VerifyPurchaseDatiFatturaDateNodes(DocumentDate: Date; PostingDate: Date)
    begin
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiGenerali/Data',
          Format(DocumentDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiGenerali/DataRegistrazione',
          Format(PostingDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    local procedure VerifyPurchaseDatiFatturaNaturaNode(Natura: Code[4])
    begin
        InitXMLReaderFile();
        LibraryXPathXMLReader.VerifyNodeValue(
          'DTR/CedentePrestatoreDTR/DatiFatturaBodyDTR/DatiRiepilogo/Natura', Format(Natura));
    end;

    local procedure InitXMLReaderFile()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        FileName: Text;
    begin
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXPathXMLReader.Initialize(FileName, '');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    local procedure AdjustAmountSign(Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if (AccountType = GenJournalLine."Account Type"::Vendor) and
           (DocumentType in [GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Refund]) or
           (AccountType = GenJournalLine."Account Type"::Customer) and
           (DocumentType in [GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::"Credit Memo"])
        then
            Amount := -Amount;
        exit(Amount);
    end;

    local procedure CalculateAmount(StartingDate: Date; InclVAT: Boolean; InclInVATTransRep: Boolean) Amount: Decimal
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
        Base: Decimal;
        Delta: Decimal;
    begin
        VATTransactionReportAmount.SetFilter("Starting Date", '<=%1', StartingDate);
        if not VATTransactionReportAmount.FindLast() then
            exit;

        if InclVAT then
            Base := VATTransactionReportAmount."Threshold Amount Incl. VAT"
        else
            Base := VATTransactionReportAmount."Threshold Amount Excl. VAT";

        // Random delta should be less than difference between Threshold Incl. VAT and Excl. VAT.
        Delta :=
          LibraryRandom.RandDec(
            VATTransactionReportAmount."Threshold Amount Incl. VAT" - VATTransactionReportAmount."Threshold Amount Excl. VAT", 2);

        if InclInVATTransRep then
            Amount := Base + Delta
        else
            Amount := Base - Delta;
    end;

    local procedure CreatePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; IndividualPerson: Boolean; Resident: Option)
    var
        AccountNo: Code[20];
        Amount: Decimal;
    begin
        Amount := CalculateAmount(WorkDate(), true, true);
        Amount := AdjustAmountSign(Amount, DocumentType, AccountType);

        // Create Account.
        case AccountType of
            GenJournalLine."Account Type"::Customer:
                AccountNo := CreateCustomer(IndividualPerson, Resident, true, false);
            GenJournalLine."Account Type"::Vendor:
                AccountNo := CreateVendor(IndividualPerson, Resident, true, false);
            GenJournalLine."Account Type"::"G/L Account":
                AccountNo := CreateGLAccount(GenPostingType);
        end;

        // Create Gen. Journal Line.
        CreateGenJnlLine(GenJournalLine, DocumentType, GenPostingType, AccountType, AccountNo, Amount);

        // Set Refers To.
        if DocumentType = GenJournalLine."Document Type"::"Credit Memo" then begin
            GenJournalLine.Validate("Refers to Period", GenJournalLine."Refers to Period"::"Current Calendar Year");
            GenJournalLine.Modify(true);
        end;

        // Update Individual Person, Resident.
        if AccountType = GenJournalLine."Account Type"::"G/L Account" then begin
            GenJournalLine.Validate("Individual Person", IndividualPerson);
            GenJournalLine.Validate(Resident, Resident);
            GenJournalLine.Modify(true);
        end;

        // Update Required Fields like VAT Registration No., Fiscal Code.
        UpdateReqFldsGenJnlLine(GenJournalLine);

        // Post Gen. Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustomer(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(Name, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer));
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Individual Person", IndividualPerson);
        Customer.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Customer.Resident::"Non-Resident" then
                Customer.Validate("Country/Region Code", GetCountryCode());
            if not IndividualPerson then
                Customer.Validate(
                  "VAT Registration No.", LibraryUtility.GenerateRandomCode(Customer.FieldNo("VAT Registration No."), DATABASE::Customer))
            else
                case Resident of
                    Customer.Resident::Resident:
                        Customer."Fiscal Code" := LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer); // Validation of Fiscal Code is not important.  - important for EXPORT
                    Customer.Resident::"Non-Resident":
                        begin
                            Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
                            Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
                            Customer.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Customer.Validate(
                              "Place of Birth", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Place of Birth"), DATABASE::Customer));
                        end;
                end;
        end;

        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomer_Datifattura(var Customer: Record Customer): Code[20]
    begin
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        Customer.Validate(County, LibraryUtility.GenerateRandomCode(Customer.FieldNo(County), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateIndividualCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", 'IT');
        Customer.Validate("Fiscal Code", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Fiscal Code"), DATABASE::Customer));
        Customer.Validate("Individual Person", true);
        Customer.Validate("First Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("First Name"), DATABASE::Customer));
        Customer.Validate("Last Name", LibraryUtility.GenerateRandomCode(Customer.FieldNo("Last Name"), DATABASE::Customer));
        Customer.Validate(County, LibraryUtility.GenerateRandomCode(Customer.FieldNo(County), DATABASE::Customer));
        Customer.Validate(Address, LibraryUtility.GenerateRandomCode(Customer.FieldNo(Address), DATABASE::Customer));
        Customer.Validate(City, LibraryUtility.GenerateRandomCode(Customer.FieldNo(City), DATABASE::Customer));
        Customer.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; GenPostingType: Enum "General Posting Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        BalAccountType: Enum "Gen. Journal Account Type";
        BalAccountNo: Code[20];
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate());
        case AccountType of
            GenJournalLine."Account Type"::"G/L Account":
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"Bank Account";
                    LibraryERM.FindBankAccount(BankAccount);
                    BalAccountNo := BankAccount."No.";
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
            GenJournalLine."Account Type"::Vendor:
                begin
                    BalAccountType := GenJournalLine."Bal. Account Type"::"G/L Account";
                    BalAccountNo := CreateGLAccount(GenPostingType);
                end;
        end;
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        // Always use Normal for G/L Accounts.
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);

        // Gen. Posting Type, Gen. Bus. and VAT Bus. Posting Groups are required for General Journal.
        if GenPostingType <> GLAccount."Gen. Posting Type"::" " then begin
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
            GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
            GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        end;
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostPurchDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; PostingDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        CreatePurchDocument(PurchHeader, PurchLine, DocumentType, VendorNo, LineAmount, 0);
        UpdatePurchaseHeaderPostingDates(PurchHeader, PostingDate, PostingDate, PostingDate);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreateAndPostPurchDocumentWithDates(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; PostingDate: Date; DocumentDate: Date; OperationOccurredDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        CreatePurchDocument(PurchHeader, PurchLine, DocumentType, VendorNo, LineAmount, 0);
        UpdatePurchaseHeaderPostingDates(PurchHeader, PostingDate, DocumentDate, OperationOccurredDate);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreateAndPostPurchDocumentWithVATSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; PostingDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        CreatePurchDocumentWithVATSetup(PurchaseHeader, PurchaseLine, VATPostingSetup, DocumentType, VendorNo, LineAmount);
        UpdatePurchaseHeaderPostingDates(PurchaseHeader, PostingDate, PostingDate, PostingDate);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreateAndPostPurchDocumentWithVATSetupEUService(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; PostingDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        CreatePurchDocumentWithVATSetup(PurchaseHeader, PurchaseLine, VATPostingSetup, DocumentType, VendorNo, LineAmount);
        ModifyPurchDocumentWithVATSetupForEUService(PurchaseHeader, PurchaseLine);
        UpdatePurchaseHeaderPostingDates(PurchaseHeader, PostingDate, PostingDate, PostingDate);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreateAndPostSalesDocumentWithVATSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal; PostingDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean)
    begin
        CreateSalesDocumentWithVATSetup(SalesHeader, SalesLine, VATPostingSetup, DocumentType, CustomerNo, LineAmount);
        UpdateSalesHeaderPostingDates(SalesHeader, PostingDate, PostingDate, PostingDate);
        LibrarySales.PostSalesDocument(SalesHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreateLinkAndPostPurchDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; PostingDate: Date; ToShipReceive: Boolean; ToInvoice: Boolean; RelatedEntryNo: Integer)
    begin
        CreatePurchDocument(PurchHeader, PurchLine, DocumentType, VendorNo, LineAmount, RelatedEntryNo);
        UpdatePurchaseHeaderPostingDates(PurchHeader, PostingDate, PostingDate, PostingDate);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, ToShipReceive, ToInvoice);
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal; RelatedEntryNo: Integer)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Purch. Header.
        CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        PurchHeader.Validate("Related Entry No.", RelatedEntryNo);
        PurchHeader.Modify(true);

        // Create Purch. Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount, LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "));

        PurchHeader.Validate("Check Total", LineAmount);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchDocumentWithVATSetup(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        GLAccount.Get(LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "));
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        // Create Purch. Header.
        CreatePurchHeader(PurchHeader, DocumentType, VendorNo);

        // Create Purch. Line.
        CreatePurchLine(PurchHeader, PurchLine, LineAmount, GLAccount."No.");

        PurchHeader.Validate("Check Total", LineAmount);
        PurchHeader.Modify(true);
    end;

    local procedure ModifyPurchDocumentWithVATSetupForEUService(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
    begin
        LibraryITLocalization.CreateTransportMethod(TransportMethod);
        PurchHeader.Validate("Transport Method", TransportMethod.Code);
        PurchHeader.Modify(true);

        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        PurchLine.Validate("Service Tariff No.", ServiceTariffNumber."No.");
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithVATSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        GLAccount.Get(LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "));
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        // Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount, GLAccount."No.");
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        VendorInvoiceNo: Code[35];
    begin
        // Create Purch. Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        VendorInvoiceNo := PurchHeader."Vendor Invoice No.";
        VendorInvoiceNo[1 + LibraryRandom.RandInt(StrLen(VendorInvoiceNo) - 2)] := '-';
        PurchHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchHeader.Modify(true);

        if (DocumentType = PurchHeader."Document Type"::"Credit Memo") or
           (DocumentType = PurchHeader."Document Type"::"Return Order")
        then begin
            PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
            PurchHeader.Modify(true);
        end;
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineAmount: Decimal; No: Code[20])
    begin
        // Create Purch. Line.
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2));
        PurchLine.Validate("Direct Unit Cost", LineAmount / PurchLine.Quantity);
        PurchLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal; PostingDate: Date; NewShipReceive: Boolean; NewInvoice: Boolean): Code[20]
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, LineAmount);
        UpdateSalesHeaderPostingDates(SalesHeader, PostingDate, PostingDate, PostingDate);
        exit(LibrarySales.PostSalesDocument(SalesHeader, NewShipReceive, NewInvoice));
    end;

    local procedure CreateAndPostSalesDocumentWithDates(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal; PostingDate: Date; DocumentDate: Date; OperationOccurredDate: Date; NewShipReceive: Boolean; NewInvoice: Boolean): Code[20]
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, LineAmount);
        UpdateSalesHeaderPostingDates(SalesHeader, PostingDate, DocumentDate, OperationOccurredDate);
        exit(LibrarySales.PostSalesDocument(SalesHeader, NewShipReceive, NewInvoice));
    end;

    local procedure CreateNoSeriesWithSpecialSigns(Default: Boolean; Manual: Boolean; DateOrder: Boolean; NoSeriesType: Enum "No. Series Type"): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DashPosition: Integer;
        NoSeriesCode: Code[20];
    begin
        NoSeries.Init();
        NoSeriesCode := LibraryUtility.GenerateRandomCode(NoSeries.FieldNo(Code), DATABASE::"No. Series");
        DashPosition := 1 + LibraryRandom.RandInt(StrLen(NoSeriesCode) - 2);
        NoSeriesCode[DashPosition] := '-';
        NoSeries.Validate(Code, NoSeriesCode);
        NoSeries.Validate("Default Nos.", Default);
        NoSeries.Validate("Manual Nos.", Manual);
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Validate("No. Series Type", NoSeriesType);
        NoSeries.Insert(true);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        LibraryERM.CreateNoSeriesLine(
          NoSeriesLine, NoSeries.Code, PadStr(NoSeriesCode, 20, '0'), PadStr(NoSeriesCode, 20, '9'));

        exit(NoSeries.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        // Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        // Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, LineAmount, LibraryVATUtils.CreateGLAccount(GLAccount."Gen. Posting Type"::" "));
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineAmount: Decimal; No: Code[20])
    begin
        // Create Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", No, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LineAmount / SalesLine.Quantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(IndividualPerson: Boolean; Resident: Option; ReqFlds: Boolean; PricesInclVAT: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        if not FindVATPostingSetup(VATPostingSetup, true) then
            FindVATPostingSetup(VATPostingSetup, false);
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate(Name, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Vendor));
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate("Individual Person", IndividualPerson);
        Vendor.Validate(Resident, Resident);

        if ReqFlds then begin
            if Resident = Vendor.Resident::"Non-Resident" then
                Vendor.Validate("Country/Region Code", GetCountryCode());

            if not IndividualPerson then
                Vendor.Validate(
                  "VAT Registration No.", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor))
            else
                case Resident of
                    Vendor.Resident::Resident:
                        Vendor."Fiscal Code" := LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor); // Validation of Fiscal Code is not important.
                    Vendor.Resident::"Non-Resident":
                        begin
                            Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
                            Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
                            Vendor.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
                            Vendor.Validate("Birth City", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Birth City"), DATABASE::Vendor));
                        end;
                end;
        end;

        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("Prices Including VAT", PricesInclVAT);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendor_Datifattura(var Vendor: Record Vendor): Code[20]
    begin
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithContactTypeRepresentative(ContactNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor.Validate(Address, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Address), DATABASE::Vendor));
        Vendor.Validate(City, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(City), DATABASE::Vendor));
        Vendor.Validate("VAT Registration No.",
          LibraryUtility.GenerateRandomCode(Vendor.FieldNo("VAT Registration No."), DATABASE::Vendor));
        Vendor.Validate(Resident, Vendor.Resident::"Non-Resident");
        Vendor.Validate("Tax Representative Type", Vendor."Tax Representative Type"::Contact);
        Vendor.Validate("Tax Representative No.", ContactNo);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateContactCompany(var Contact: Record Contact; VATRegistrationNo: Text[20]): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Contact.Validate("Country/Region Code", CountryRegion.Code);
        Contact.Validate("VAT Registration No.", VATRegistrationNo);
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateContactPerson(var Contact: Record Contact; Surname: Text[30]; FirstName: Text[30]): Code[20]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Contact.Validate("Country/Region Code", CountryRegion.Code);
        Contact.Validate(Surname, Surname);
        Contact.Validate("First Name", FirstName);
        Contact.Modify(true);
        exit(Contact."No.");
    end;

    local procedure CreateIndividualVendor(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        Vendor.Validate("Fiscal Code", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Fiscal Code"), DATABASE::Vendor));
        Vendor.Validate("Individual Person", true);
        Vendor.Validate("First Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("First Name"), DATABASE::Vendor));
        Vendor.Validate("Last Name", LibraryUtility.GenerateRandomCode(Vendor.FieldNo("Last Name"), DATABASE::Vendor));
        Vendor.Validate(County, LibraryUtility.GenerateRandomCode(Vendor.FieldNo(County), DATABASE::Vendor));
        Vendor."Country/Region Code" := 'IT';
        Vendor.Modify(true);
    end;

    local procedure CreateReverseChargeVATPostingSetupWithNatura(var VATPostingSetup: Record "VAT Posting Setup"; NaturaCode: Code[4])
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandInt(50));
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", VATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate("VAT Transaction Nature", NaturaCode);
        VATPostingSetup.Modify();
    end;

    local procedure CreateVATTransReportAmount(var VATTransRepAmount: Record "VAT Transaction Report Amount"; StartingDate: Date)
    begin
        VATTransRepAmount.Init();
        VATTransRepAmount.Validate("Starting Date", StartingDate);
        VATTransRepAmount.Insert(true);
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header"; VATReportType: Option)
    begin
        VATReportHeader.Init();
        VATReportHeader."No." := LibraryUtility.GenerateGUID();
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code"::"VAT Transactions Report");
        VATReportHeader.Validate("VAT Report Type", VATReportType);
        VATReportHeader.Modify(true);
    end;

    local procedure CreateVATReport(var VATReportHeader: Record "VAT Report Header"; var VATReportLine: Record "VAT Report Line"; VATReportType: Option)
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        // Create VAT Report Header.
        CreateVATReportHeader(VATReportHeader, VATReportType);
        // Get VAT Report Lines.
        VATReportMediator.GetLines(VATReportHeader);

        // Find VAT Report Lines.
        VATReportLine.SetFilter("VAT Report No.", VATReportHeader."No.");
        VATReportLine.FindFirst();
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        if not VATReportSetup.Get() then
            VATReportSetup.Insert(true);

        VATReportSetup.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        VATReportSetup.Validate("Intermediary VAT Reg. No.", Format(LibraryRandom.RandInt(100)));
        VATReportSetup.Validate("Intermediary CAF Reg. No.", '');
        VATReportSetup.Validate("Intermediary Date", CalcDate('<-3M>', Today));
        VATReportSetup.Validate("Modify Submitted Reports", false);
        VATReportSetup.Modify(true);
    end;

    local procedure CreateVATEntry(PostingDate: Date; Type: Enum "General Posting Type"; BillToPayToNo: Code[20]): Integer
    var
        VATEntry: Record "VAT Entry";
        EntryNo: Integer;
    begin
        VATEntry.FindLast();
        EntryNo := VATEntry."Entry No." + 1;
        VATEntry.Init();
        VATEntry."Entry No." := EntryNo;
        VATEntry.Insert();
        VATEntry.Type := Type;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."Document Date" := PostingDate;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("Document No."), DATABASE::"VAT Entry");
        VATEntry."External Document No." :=
          LibraryUtility.GenerateRandomCode(VATEntry.FieldNo("External Document No."), DATABASE::"VAT Entry");
        VATEntry."VAT Transaction Nature" :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("VAT Transaction Nature"), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."VAT Transaction Nature"));
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry.Modify();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateVATEntryWithDocNoAndType(PostingDate: Date; EntryType: Enum "General Posting Type"; BillToPayToNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(CreateVATEntry(PostingDate, EntryType, BillToPayToNo));
        VATEntry."Document No." := DocumentNo;
        VATEntry."External Document No." := DocumentNo;
        VATEntry."Document Type" := DocumentType;
        VATEntry."VAT Identifier" :=
          CopyStr(LibraryUtility.GenerateRandomCode(
              VATEntry.FieldNo("VAT Identifier"), DATABASE::"VAT Entry"), 1, MaxStrLen(VATEntry."VAT Identifier"));
        VATEntry.Modify();
    end;

    local procedure DeleteVendorLedgerEntry(PostingDate: Date; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo := FindLastPostedPurchaseInvoiceNoForVendor(PostingDate, VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.Delete();
    end;

    local procedure FindLastPostedPurchaseInvoiceNoForVendor(PostingDate: Date; VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Posting Date", PostingDate);
        PurchInvHeader.FindLast();
        exit(PurchInvHeader."No.");
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean): Boolean
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT"));
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.SetRange("Deductible %", 100);
        exit(VATPostingSetup.FindFirst())
    end;

    local procedure FindVendorLedgerEntry(PostingDate: Date; VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        DocumentNo := FindLastPostedPurchaseInvoiceNoForVendor(PostingDate, VendorNo);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure GetCountryCode(): Code[10]
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("EU Country/Region Code", '');
        LibraryERM.FindCountryRegion(CountryRegion);
        CountryRegion.Validate("Foreign Country/Region Code", Format(LibraryRandom.RandInt(100)));
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure GetPostingDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Operation Occurred Date");
        VATEntry.FindLast();
        exit(CalcDate('<1D>', VATEntry."Posting Date"));
    end;

    local procedure MockGLEntryAndVendorLedgerEntry(DocumentNo: Code[20]; PostingDate: Date; TransactionNo: Integer; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry.Insert();

        VendorLedgerEntry."Entry No." := GLEntry."Entry No.";
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Type" := DocumentType;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Transaction No." := TransactionNo;
        VendorLedgerEntry.Insert();
    end;

    local procedure InitLibraryXMLRead_Datifattura(var LibraryXMLRead2: Codeunit "Library - XML Read"; var FileName: Text)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.FindFirst();
        FileName := GetFileNameByGUID(NameValueBuffer.Value);
        LibraryXMLRead2.Initialize(FileName);
    end;

    local procedure UpdateCustomsAuthorityVendor(VendorNo: Code[20])
    var
        CustomsAuthorityVendor: Record "Customs Authority Vendor";
    begin
        CustomsAuthorityVendor.Init();
        CustomsAuthorityVendor.Validate("Vendor No.", VendorNo);
        CustomsAuthorityVendor.Insert(true);
    end;

    local procedure UpdateReqFldsGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        // Update fields required for posting when Incl. in VAT Transac. Report is TRUE.
        if GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident" then
            GenJournalLine.Validate("Country/Region Code", GetCountryCode());

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::"Non-Resident") then begin
            GenJournalLine.Validate("First Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("First Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Last Name", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Last Name"), DATABASE::"Gen. Journal Line"));
            GenJournalLine.Validate("Date of Birth", CalcDate('<-' + Format(LibraryRandom.RandInt(100)) + 'Y>'));
            GenJournalLine.Validate("Place of Birth", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Place of Birth"), DATABASE::"Gen. Journal Line"));
        end;

        if GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) and (GenJournalLine."Fiscal Code" = '') then
            GenJournalLine."Fiscal Code" := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Fiscal Code"), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        if not GenJournalLine."Individual Person" and (GenJournalLine.Resident = GenJournalLine.Resident::Resident) and (GenJournalLine."VAT Registration No." = '') then
            GenJournalLine."VAT Registration No." := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("VAT Registration No."), DATABASE::"Gen. Journal Line");
        // Validation skipped.
        GenJournalLine.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderPostingDates(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date; DocumentDate: Date; OperationOccurredDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Operation Occurred Date", OperationOccurredDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSalesHeaderPostingDates(var SalesHeader: Record "Sales Header"; PostingDate: Date; DocumentDate: Date; OperationOccurredDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", DocumentDate);
        SalesHeader.Validate("Operation Occurred Date", OperationOccurredDate);
        SalesHeader.Modify(true);
    end;

    local procedure SetupThresholdAmount(StartingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATTransRepAmount: Record "VAT Transaction Report Amount";
        ThresholdAmount: Decimal;
        VATRate: Decimal;
    begin
        // Law States Threshold Incl. VAT as 3600 and Threshold Excl. VAT as 3000.
        // For test purpose Threshold Excl. VAT is generated randomly in 1000..10000 range.
        CreateVATTransReportAmount(VATTransRepAmount, StartingDate);
        VATRate := LibraryVATUtils.FindMaxVATRate(VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        ThresholdAmount := 1000 * LibraryRandom.RandInt(10);
        VATTransRepAmount.Validate("Threshold Amount Incl. VAT", ThresholdAmount * (1 + VATRate / 100));
        VATTransRepAmount.Validate("Threshold Amount Excl. VAT", ThresholdAmount);

        VATTransRepAmount.Modify(true);
    end;

    local procedure UpdateDefaultSalesOperationTypeInVATBusinessPostingGroup(VATBusPostingGroupCode: Code[20])
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        NoSeries: Record "No. Series";
    begin
        VATBusinessPostingGroup.Get(VATBusPostingGroupCode);
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", CreateNoSeriesWithSpecialSigns(true, true, true, NoSeries."No. Series Type"::Sales));
        VATBusinessPostingGroup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATCalculationType: Enum "Tax Calculation Type"; InclInVATTransRep: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '''''');
        VATPostingSetup.SetRange("VAT %", LibraryVATUtils.FindMaxVATRate(VATCalculationType));
        VATPostingSetup.SetRange("Deductible %", 100);
        VATPostingSetup.FindFirst();

        VATPostingSetup.Validate("Include in VAT Transac. Rep.", InclInVATTransRep);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyBlockValue(var TextFile: BigText; LineNo: Integer; "Key": Text; Value: Text; AllowEmpty: Boolean; ThrowError: Boolean): Boolean
    begin
        exit(LibrarySpesometro.VerifyBlockValue(TextFile, LineNo, Key, Value, AllowEmpty, ThrowError));
    end;

    local procedure GetVendorVATRegNo(var Vendor: Record Vendor; var VATEntry: Record "VAT Entry"): Text
    begin
        exit(LibrarySpesometro.GetVendorVATRegNo(Vendor, VATEntry));
    end;

    local procedure VerifyDetraibileAndDeducibileNonExistInXmlFile(FileName: Text)
    var
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        LibraryXPathXMLReader.Initialize(FileName, 'ns2:DatiFattura');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/Detraibile', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('/DTE/CessionarioCommittenteDTE/DatiFatturaBodyDTE/DatiRiepilogo/Deducibile', 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Datifattura Export", 'OnBeforeSaveFileOnClient', '', false, false)]
    local procedure SetFileNameOnBeforeSaveFileOnClient(var NewServerFilePath: Text)
    var
        FileManagement: Codeunit "File Management";
        FileGUID: Text;
    begin
        NewServerFilePath := FileManagement.ServerTempFileName('xml');

        FileGUID := Format(CreateGuid());
        AddNewNameValueBuffer('FileGUID', FileGUID);
        while StrLen(NewServerFilePath) > 250 do begin
            AddNewNameValueBuffer(FileGUID, NewServerFilePath);
            NewServerFilePath := CopyStr(NewServerFilePath, 251);
        end;
        AddNewNameValueBuffer(FileGUID, NewServerFilePath);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Datifattura Export", 'OnAfterSaveFileOnClient', '', false, false)]
    local procedure GetSuggestedFileNameOnAfterSaveFileOnClient(SuggestedFileName: Text)
    begin
        AddNewNameValueBuffer('SuggestedFileName', SuggestedFileName);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageHandler(var ErrorMessages: TestPage "Error Messages")
    begin
        LibraryVariableStorage.Enqueue(ErrorMessages.Description.Value);
    end;
}

