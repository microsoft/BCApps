codeunit 144001 VATSTAT
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Statement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileMgt: Codeunit "File Management";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        FdfFileHelper: Codeunit FDFFileHelper;
        ReportingType: Option Quarter,Month,"Defined period";
        DefaultFdfTxt: Label 'Default.fdf';
        DefaultXmlTxt: Label 'Default.xml';
        arguments: Option ,Zahl101,Zahl102,Zahl103,Zahl104,Zahl105,Zahl106,Zahl107,Zahl108,Zahl109,Zahl110,Zahl111,Zahl112,Zahl113,Zahl115a,Zahl116a,Zahl117a,Zahl118a,Zahl119a,Zahl120a,Zahl121a,Zahl123,Zahl124,Zahl125,Zahl125b,Zahl125a,Zahl126,Zahl127,Zahl128a,Zahl129a,Zahl130a,Zahl130aa,Zahl131,Zahl132,Zahl133,Zahl134,Zahl134a,Zahl135,Zahl136,Zahl136a,Zahl137a,Zahl137,Zahl138,Zahl139,DD140,Zahl140,DD141,Zahl141,DD143_27,Zahl143_27,DD143_28,Zahl143_28,DD143,Zahl143,Checkbox100X,Checkbox100Xx;
        PdfFileName: Text[260];
        FdfFileName: Text[260];
        XmlFileName: Text[260];
        IsInitialized: Boolean;
        AdjustDatesMsg: Label 'Would you like to set the Starting and Ending Date according to the selected Reporting Type?';
        StringContainsErr: Label 'The specified substring=''%2'' did not occur within this string=''%1''.';
        NumberOffFdfHeaderAndFooterLinesTok: Label '15';
        DefinedHeaderAndFooterLines: Integer;
        TestClassWorkdate: Date;
        MissingFDFTagErr: Label 'Assert.IsTrue failed. The key="%1" could not be found';
        MissingXMLElementErr: Label 'Assert.AreNotEqual failed. Expected any value except:<0> (Integer). Actual:<0> (Integer)';
        ClaimTaxfreeRevErr: Label 'In order to claim taxfree revenues without input tax reduction (position 020) the necessary number of Art. 6 Abs. 1 has to be specified.\KZ 020 only together with "Number of Art. 6 Abs. 1".';

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure FDFFileInsteadOfPrintOut()
    var
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize();
        EnqueRequestPageFields(WorkDate(), 0D, "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::Month, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify that the Fdf file is generated
        Assert.IsTrue(Exists(FdfFileName), StrSubstNo('File %1 must be generated', FdfFileName));
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure XMLFileInsteadOfPrintOut()
    var
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize();
        EnqueRequestPageFields(0D, WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::Quarter, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify that the Xml file are generated
        Assert.IsTrue(Exists(XmlFileName), StrSubstNo('File %1 must be generated', XmlFileName));
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic sales invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, GetDomesticGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl115a, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ022', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu sales invoice and verify that the data in the generated FDF file.
        Initialize();
        SetupVatStatementLine('1000', 'EULIEF', true, GetTemplateName());
        SetupVatStatementLine('1017', 'EULIEF', true, GetTemplateName());
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, GetEUGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl108, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ017', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignSalesInvoiceInFDFFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a foreign sales invoice and verify that the data in the generated FDF file.
        Initialize();
        SetupVatStatementLine('1011', 'BU0', true, GetTemplateName());
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, GetExportGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, VATEntry.Base + VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl105, VATEntry.Base);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -(VATEntry.Base + VATEntry.Amount));
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ011', -VATEntry.Base);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic purchase invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, GetDomesticGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl133, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 1);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ060', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 2);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu purchase invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, GetEUGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl126, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl128a, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl135, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/KZ070', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/VERSTEUERT_IGE/KZ072', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ065', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignPurchaseInvoiceInFDFFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, GetExportGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter a domestic sales invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a domestic sales invoice.
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", GetDomesticGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl110, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ019', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', -VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NationalSalesCreditMemo1067InFile()
    var
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379404] VAT Statement Line '1067' is exported in case of Sales Credit Memo
        Initialize();

        // [GIVEN] Setup VAT Statement Line '1067' with 'Row Totaling' = 'UST20' (Sale Domestic VAT20)
        SetupVatStatementLine('1067', 'UST20', true, GetTemplateName());
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Posted domestic Sales Credit Memo (VAT Amount = 100)
        DocNo := CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", GetDomesticGroup());
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // [THEN] '1067' is exported:
        // [THEN] FDF file 'DD141' = '-'
        // [THEN] FDF file 'Zahl141' = '100'
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD141);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 5);

        // [THEN] XML file 'KZ067' = '-100'
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);

        // Tear Down
        SetupVatStatementLine('1067', '', false, GetTemplateName());
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUPurchaseCreditMemo1067InFile()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
        PurchInvoiceVATEntryAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382292] VAT Statement Line '1067' is exported in case of Purchase Credit Memo
        Initialize();

        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Posted EU Purchase Invoice (VAT Amount = 100)
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, GetEUGroup());
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);
        PurchInvoiceVATEntryAmount := VATEntry.Amount;

        // [GIVEN] Posted EU Purchase Credit Memo (VAT Amount = -300)
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", GetEUGroup());
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // [THEN] '1067' is exported:
        // [THEN] FDF file 'Zahl141' = '-200'
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, PurchInvoiceVATEntryAmount + VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        // [THEN] XML file 'KZ067' = '200'
        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -(PurchInvoiceVATEntryAmount + VATEntry.Amount));

        // [THEN] XML file 'KZ090' = '-200'
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', PurchInvoiceVATEntryAmount + VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure EUSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // Enter an eu sales invoice and verify that the data in the generated FDF file.
        Initialize();
        SetupVatStatementLine('1000', 'EULIEF', true, GetTemplateName());
        SetupVatStatementLine('1017', 'EULIEF', true, GetTemplateName());
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create an eu sales invoice.
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", GetEUGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ForeignSalesCreditMemoInFile()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
    begin
        // [FEATURE] [Sales]
        // Enter a foreign sales invoice and verify that the data in the generated FDF file
        Initialize();

        // [GIVEN] Setup VAT Statement Line '1011' with 'Row Totaling' = 'BU0' (Sale Export VAT10)
        SetupVatStatementLine('1011', 'BU0', true, GetTemplateName());
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // [GIVEN] Foreign sales invoice
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", GetExportGroup());

        // [WHEN] Export VAT Statement
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // [THEN] There is one KZ line
        // [THEN] '1090' is exported with amount -1000
        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize();

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1048', VATTotalRowNo);
        CreateRowTotVATStmtLine('1082', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl125, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl136a, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ048', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ082', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize();

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1048', VATTotalRowNo);
        CreateRowTotVATStmtLine('1082', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionReverseChargePurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize();

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1057', VATTotalRowNo);
        CreateRowTotVATStmtLine('1066', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl124, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl136, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 2);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ057', VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ066', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ConstructionReverseChargeCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementLine: Record "VAT Statement Line";
        VATEntry: Record "VAT Entry";
        Item: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATTotalRowNo: Code[10];
        DocNo: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data in the generated FDF file.
        Initialize();

        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        VATTotalRowNo := LibraryUtility.GenerateRandomCode(VATStatementLine.FieldNo("Row No."), DATABASE::"VAT Statement Line");
        CreateVATEntTotVATStmtLine(VATTotalRowNo, VATBusPostingGroupCode, VATProPostingGroupCode);
        CreateRowTotVATStmtLine('1057', VATTotalRowNo);
        CreateRowTotVATStmtLine('1066', VATTotalRowNo);

        CreateItem(Item, VATProPostingGroupCode);

        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);

        // Create a foreign purchase invoice.
        DocNo := CreateAndPostPurchaseDocumentOnItem(
            PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VATBusPostingGroupCode, Item);

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineMinus(FdfFileHelper, arguments::DD143);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 3);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 3);
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure ReportOtionSurplusAndMail()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo: Code[20];
    begin
        // Enter an eu purchase invoice and verify that the data in the generated FDF file.
        Initialize();
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, true, true, 0);

        // Create an eu purchase invoice.
        DocNo := CreateAndPostPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, GetEUGroup());

        // Exercise.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry, DocNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl126, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl128a, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl135, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Checkbox100X, 1);
        VerifyFDFLineValue(FdfFileHelper, arguments::Checkbox100Xx, 1);
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines + 5);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/KZ070', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/VERSTEUERT_IGE/KZ072', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ065', VATEntry.Amount);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 4);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/VORSTEUER/ARE', 'J');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/VORSTEUER/REPO', 'J');
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure NewReportIDs27And28()
    var
        PurchaseHeader: Record "Purchase Header";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        Item1: Record Item;
        Item2: Record Item;
        VATStatementAT: Report "VAT Statement AT";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocNo1: Code[20];
        DocNo2: Code[20];
        VATBusPostingGroupCode: Code[20];
        VATProPostingGroupCode: Code[20];
    begin
        // Enter a foreign purchase invoice and verify that the data is NOT in the generated FDF file (field 27 and 28 have been removed in 2014).
        Initialize();

        // Setup: Item1
        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateVATEntTotVATStmtLine('1027', VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateItem(Item1, VATProPostingGroupCode);

        // Setup: Item2
        CreateVATPostingGroup(VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateVATEntTotVATStmtLine('1028', VATBusPostingGroupCode, VATProPostingGroupCode);

        CreateItem(Item2, VATProPostingGroupCode);

        // Create a foreign purchase invoice.
        DocNo1 :=
          CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item1);
        DocNo2 :=
          CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VATBusPostingGroupCode, Item2);

        // Exercise.
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::"Defined period", false, false, false, false, 0);
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify various Amounts in the VAT Statement report.
        GetVATEntry(VATEntry1, DocNo1, VATEntry1."Document Type"::Invoice, VATEntry1.Type::Purchase);
        GetVATEntry(VATEntry2, DocNo2, VATEntry2."Document Type"::Invoice, VATEntry2.Type::Purchase);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFHeader(FdfFileHelper);
        // These fields are missing
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry1.Amount + VATEntry2.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl141)));
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143_27, VATEntry1.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl143_27)));
        asserterror VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143_28, VATEntry2.Amount);
        Assert.ExpectedError(StrSubstNo(MissingFDFTagErr, Format(arguments::Zahl143_28)));
        FdfFileHelper.VerifyCount(DefinedHeaderAndFooterLines);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLHeader(LibraryXPathXMLReader);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        // These fields are missing
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', VATEntry1.Amount + VATEntry2.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ027', VATEntry1.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        asserterror VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ028', VATEntry2.Amount);
        Assert.ExpectedError(MissingXMLElementErr);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('descendant::*[@type="kz"]', 1);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateRequestPageHandler,UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateVATStatementTemplate()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        StatementTemplateName: Code[10];
    begin
        Initialize();

        // Setup: Clear all date to be created by update
        StatementTemplateName := GetTemplateName();
        VATStatementLine.SetRange("Statement Template Name", StatementTemplateName);
        VATStatementLine.DeleteAll();
        VATStatementTemplate.SetRange(Name, StatementTemplateName);
        VATStatementTemplate.DeleteAll();
        VATStatementName.SetRange("Statement Template Name", StatementTemplateName);
        VATStatementName.DeleteAll();

        Commit();

        // Execute: Run the report
        REPORT.Run(REPORT::"Update VAT Statement Template");

        // Validate: Statement Lines should hold data
        VATStatementLine.SetRange("Statement Template Name", StatementTemplateName);
        Assert.IsFalse(VATStatementLine.IsEmpty, 'VAT Statment Lines should hold the updateded values');
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateRequestPageHandler,UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestUpdateVATStatementTemplateWithData()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATLineCount: Integer;
    begin
        Initialize();

        // Setup: Clear all date to be created by update
        REPORT.Run(REPORT::"Update VAT Statement Template");

        VATStatementLine.SetRange("Statement Template Name", GetTemplateName());
        VATLineCount := VATStatementLine.Count();

        VATStatementLine.SetFilter("Row Totaling", '<>''''');
        VATStatementLine.DeleteAll();
        VATStatementLine.SetRange("Row Totaling");
        Assert.IsTrue(VATLineCount > VATStatementLine.Count, 'Verify that we did delete something');

        Commit();

        // Execute: Run the report
        REPORT.Run(REPORT::"Update VAT Statement Template");

        // Validate: Statement Lines should hold data
        Assert.AreEqual(VATLineCount, VATStatementLine.Count, 'VAT Statment Lines should be recreated');
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoInVATStatement()
    var
        CompanyInformation: Record "Company Information";
        VATStatementAT: Report "VAT Statement AT";
    begin
        // Purpose of the test is to validate that a FDF file is generated.
        // Setup.
        Initialize();
        CompanyInformation.Get();
        CompanyInformation."Address 2" := 'Zenter';
        CompanyInformation."House Number" := '20House';
        CompanyInformation."Floor Number" := '07Floor';
        CompanyInformation."Room Number" := '86Raum';
        CompanyInformation.Modify();
        Commit();
        EnqueRequestPageFields(0D, WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::Quarter, false, false, false, false, 0);

        // Exercise: Run the VAT Statement AT report.
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // Verify that the Xml file are generated
        Assert.IsTrue(Exists(XmlFileName), StrSubstNo('File %1 must be generated', XmlFileName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelocationOfLocalVATReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Get(ReportSelections.Usage::"VAT Statement", 1);
        Assert.AreEqual(11110, ReportSelections."Report ID", 'Report 11110 was expected');
        ReportSelections.Get(ReportSelections.Usage::"Sales VAT Acc. Proof", 1);
        Assert.AreEqual(11, ReportSelections."Report ID", 'Report 11 was expected');
        ReportSelections.Get(ReportSelections.Usage::"VAT Statement Schedule", 1);
        Assert.AreEqual(11010, ReportSelections."Report ID", 'Report 11010 was expected');
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure TestKZ020WithArt6Abs1()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
    begin
        // [SCENARIO 343187] Running VAT Statement AT report with KZ020 <> 0 and "Number of Art. 6 Abs. 1" <> 0 doesn't raise errors
        Initialize();

        // [GIVEN] Setup VAT Statement Line for Row Check and set Row1020 = BU0
        SetupVatStatementLine('1000', 'BU0', false, GetTemplateName());
        SetupVatStatementLine('1011', '', false, GetTemplateName());
        SetupVatStatementLine('1020', 'BU0', false, GetTemplateName());
        SetupVatStatementLine('1019', '', false, 'VAT');

        // [GIVEN] Set VAT Statement AT request page parameters with "Number of Art. 6 Abs. 1" = 1 and post a sales document
        EnqueRequestPageFields(WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
          ReportingType::Quarter, true, false, false, false, 1);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, GetExportGroup());

        // [WHEN] Run VAT Statement AT report
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();

        // [THEN] The report has run correctly and an output file created
        Assert.IsTrue(Exists(XmlFileName), StrSubstNo('File %1 must be generated', XmlFileName));
    end;

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestKZ020WithoutArt6Abs1Error()
    var
        SalesHeader: Record "Sales Header";
        VATStatementAT: Report "VAT Statement AT";
    begin
        // [SCENARIO 343187] Running VAT Statement AT report with KZ020 <> 0 and "Number of Art. 6 Abs. 1" = 0 raises an error
        Initialize();

        // [GIVEN] Setup VAT Statement Line for Row Check and set Row1020 = BU0
        SetupVatStatementLine('1000', 'BU0', false, GetTemplateName());
        SetupVatStatementLine('1011', '', false, GetTemplateName());
        SetupVatStatementLine('1020', 'BU0', false, GetTemplateName());
        SetupVatStatementLine('1019', '', false, 'VAT');

        // [GIVEN] Set VAT Statement AT request page parameters with "Number of Art. 6 Abs. 1" = 0 and post a sales document
        EnqueRequestPageFields(
            WorkDate(), WorkDate(), "VAT Statement Report Selection"::"Open and Closed", "VAT Statement Report Period Selection"::"Within Period",
            ReportingType::Quarter, true, false, false, false, 0);
        CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, GetExportGroup());

        // [WHEN] Run VAT Statement AT report
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        asserterror VATStatementAT.RunModal();

        // [THEN] An error is thrown: "In order to claim taxfree revenues without input tax reduction (position 020)..."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(ClaimTaxfreeRevErr);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplate2020_VAT5Pct()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATProductPostingGroup5Pct: Code[20];
    begin
        // [SCENARIO 365653] Changes in AT VAT Statement Template from August 2020: new ciphers KZ009, KZ010 for VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);

        AssertVATStatementLineExists(VATStatementLine, 'BU5');
        AssertVATStatementLineExists(VATStatementLine, 'BU0');
        AssertVATStatementLineExists(VATStatementLine, 'UST5');
        AssertVATStatementLineExists(VATStatementLine, 'UST0');
        AssertVATStatementLineExists(VATStatementLine, 'BV5');
        AssertVATStatementLineExists(VATStatementLine, 'BV0');
        AssertVATStatementLineExists(VATStatementLine, 'VST5');
        AssertVATStatementLineExists(VATStatementLine, 'VST0');
        AssertVATStatementLineExists(VATStatementLine, 'BES5');
        AssertVATStatementLineExists(VATStatementLine, 'ES5');
        AssertVATStatementLineExists(VATStatementLine, 'ES5');

        VATStatementLine.SetRange("VAT Prod. Posting Group", VATProductPostingGroup5Pct);
        AssertVATStatementLineExists(VATStatementLine, 'EULIEF');
        VATStatementLine.SetRange("VAT Prod. Posting Group");

        AssertVATStatementRowTotalling(VATStatementLine, '0009', 'BU5');
        AssertVATStatementRowTotalling(VATStatementLine, '1009', 'UST5');

        AssertVATStatementRowTotalling(VATStatementLine, '0010', 'BES5');
        AssertVATStatementRowTotalling(VATStatementLine, '1010', 'ES5');

        AssertVATStatementRowTotalling(VATStatementLine, '1000', 'BU20|BU10|BU13|BU19|BULW10|BULW7|BU0|BU5|EULIEF');
        AssertVATStatementRowTotalling(VATStatementLine, '0070', 'BES20|BES10|BES13|BES19|BES0|BES5');
        AssertVATStatementRowTotalling(VATStatementLine, '1060', 'VST20|VST10|VST13|VST19|VST5');
        AssertVATStatementRowTotalling(VATStatementLine, '1065', 'ES20|ES10|ES13|ES19|ES5');
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_Domestic_Invoice()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for domestic sales invoice VAT 5% (new cipher KZ009 from August 2020)
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::Invoice, GetDomesticGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl121a, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, -VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/VERSTEUERT/KZ009', -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_Domestic_CrMemo()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for domestic sales credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::"Credit Memo", GetDomesticGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, -VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', -VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_EU_Invoice()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for EU sales invoice VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::Invoice, GetEUGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl108, -VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, -VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ017', -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_EU_CrMemo()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for EU sales credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::"Credit Memo", GetEUGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_Export_Invoice()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for Export sales invoice VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::Invoice, GetExportGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl105, -VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl101, -VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', -VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/STEUERFREI/KZ011', -VATEntry.Base);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Sales_Export_CrMemo()
    var
        SalesHeader: Record "Sales Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for Export sales credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostSalesDocumentOnVATGroups(
            SalesHeader."Document Type"::"Credit Memo", GetExportGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Sale);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_Domestic_Invoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for domestic purchase invoice VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::Invoice, GetDomesticGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl133, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ060', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_Domestic_CrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for domestic purchase credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::"Credit Memo", GetDomesticGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_EU_Invoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for domestic purchase invoice VAT 5% (new cipher KZ010 from August 2020)
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::Invoice, GetEUGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl130aa, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl126, VATEntry.Base);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl135, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/VERSTEUERT_IGE/KZ010', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'INNERGEMEINSCHAFTLICHE_ERWERBE/KZ070', VATEntry.Base);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ065', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_EU_CrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for domestic purchase credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::"Credit Memo", GetEUGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl143, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl141, VATEntry.Amount);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ067', -VATEntry.Amount);
        VerifyXMLLine(LibraryXPathXMLReader, 'VORSTEUER/KZ090', VATEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_Export_Invoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Invoice]
        // [SCENARIO 365653] AT VAT Statement for Export purchase invoice VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::Invoice, GetExportGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::Invoice, VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
    end;

    [Test]
    [HandlerFunctions('UpdateVATStmtTemplateConfirmHandler,VATStmtATMessageHandler,VATStmtATRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VAT5Pct_Purch_Export_CrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATStatementName: Record "VAT Statement Name";
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        VATProductPostingGroup5Pct: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Credit Memo]
        // [SCENARIO 365653] AT VAT Statement for Export purchase credit memo VAT 5%
        Initialize();
        VATProductPostingGroup5Pct := CheckCreateVATSetup5Pct();
        CreateUpdateVATStatementTemplate(VATStatementName);

        DocumentNo :=
          CreateAndPostPurchaseInvoiceOnVATGroups(
            PurchaseHeader."Document Type"::"Credit Memo", GetExportGroup(), VATProductPostingGroup5Pct);
        GetVATEntry(VATEntry, DocumentNo, VATEntry."Document Type"::"Credit Memo", VATEntry.Type::Purchase);
        VATEntry.TestField(Base);
        VATEntry.TestField(Amount, 0);

        RunVATStatement(VATStatementName);

        FdfFileHelper.ReadFdfFile(FdfFileName);
        VerifyFDFLineValue(FdfFileHelper, arguments::Zahl104, 0);

        LibraryXPathXMLReader.Initialize(XmlFileName, '');
        VerifyXMLLine(LibraryXPathXMLReader, 'LIEFERUNGEN_LEISTUNGEN_EIGENVERBRAUCH/KZ000', 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PdfFile: File;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::VATSTAT);
        LibraryVariableStorage.Clear();

        if TestClassWorkdate <> 0D then begin
            TestClassWorkdate := CalcDate('<+1D>', TestClassWorkDate);
            WorkDate := TestClassWorkdate;
        end;

        if Exists(FdfFileName) and not Erase(FdfFileName) then
            Assert.IsFalse(Exists(XmlFileName), StrSubstNo('File %1 must be removed', FdfFileName));

        if Exists(XmlFileName) and not Erase(XmlFileName) then
            Assert.IsFalse(Exists(XmlFileName), StrSubstNo('File %1 must be removed', XmlFileName));

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::VATSTAT);

        PdfFileName := CopyStr(FileMgt.ServerTempFileName('pdf'), 1, 260);
        PdfFile.Create(PdfFileName);
        PdfFile.Write(PdfFileName);
        PdfFile.Close();

        FdfFileName := CopyStr(FileMgt.GetDirectoryName(PdfFileName) + '\' + DefaultFdfTxt, 1, 260);
        XmlFileName := CopyStr(FileMgt.GetDirectoryName(PdfFileName) + '\' + DefaultXmlTxt, 1, 260);

        if Exists(FdfFileName) then
            Erase(FdfFileName);

        if Exists(XmlFileName) then
            Erase(XmlFileName);

        TestClassWorkdate := CalcDate('<-1Y>', Today);
        WorkDate := TestClassWorkdate;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();

        Evaluate(DefinedHeaderAndFooterLines, NumberOffFdfHeaderAndFooterLinesTok);

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::VATSTAT);
    end;

    local procedure SetupVatStatementLine(RowNo: Code[10]; RowTotalingFilter: Text; Add: Boolean; TemplateName: Code[10])
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.SetFilter("Statement Template Name", TemplateName);
        VATStatementLine.SetFilter("Row No.", RowNo);
        VATStatementLine.FindFirst();
        if not StringContains(VATStatementLine."Row Totaling", RowTotalingFilter) then begin
            if Add then begin
                if VATStatementLine."Row Totaling" <> '' then
                    RowTotalingFilter := '|' + RowTotalingFilter;
                VATStatementLine."Row Totaling" := CopyStr(VATStatementLine."Row Totaling" + RowTotalingFilter, 1, MaxStrLen(VATStatementLine."Row Totaling"));
            end else
                VATStatementLine."Row Totaling" := CopyStr(RowTotalingFilter, 1, MaxStrLen(VATStatementLine."Row Totaling"));
            VATStatementLine.Modify();
        end;
    end;

    local procedure EnqueRequestPageFields(StartingDate: Date; EndingDate: Date; IncludeVATEntries: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; ReportingType: Option; CheckPositions: Boolean; RoundToWholeNumbers: Boolean; SurplusUsedToPayDues: Boolean; AdditionalInvoicesSentViaMail: Boolean; NumberPar6Abs1: Integer)
    begin
        LibraryVariableStorage.Enqueue(ReportingType);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(IncludeVATEntries);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(CheckPositions);
        LibraryVariableStorage.Enqueue(RoundToWholeNumbers);
        LibraryVariableStorage.Enqueue(SurplusUsedToPayDues);
        LibraryVariableStorage.Enqueue(AdditionalInvoicesSentViaMail);
        LibraryVariableStorage.Enqueue(NumberPar6Abs1);
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; BusPostingGroup: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Find an Item and Create Sales Order with Random Quantity
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(BusPostingGroup));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostSalesDocumentOnVATGroups(DocumentType: Enum "Sales Document Type"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]): Code[20];
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateItem(Item, VATProdPostingGroupCode);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(VATBusPostingGroupCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BusPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Find an Item and Create Purchase Order with Random Quantity
        // Returns the number of the purchase document
        LibrarySales.FindItem(Item);
        exit(CreateAndPostPurchaseDocumentOnItem(PurchaseHeader, DocumentType, BusPostingGroup, Item));
    end;

    local procedure CreateAndPostPurchaseDocumentOnItem(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BusPostingGroup: Code[20]; Item: Record Item): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with Random Quantity
        // Returns the number of the purchase document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(BusPostingGroup));
        PurchaseHeader.Validate(
          "Vendor Cr. Memo No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Cr. Memo No."), DATABASE::"Purchase Header"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceOnVATGroups(DocumentType: enum "Purchase Document Type"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        CreateItem(Item, VATProdPostingGroupCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(VATBusPostingGroupCode));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomer(BusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        // Create a new Domestic Customer.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", BusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", BusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(BusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create a new Domestic Customer.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", BusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", BusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVATPostingGroup(var VATBusinessPostingGroupCode: Code[20]; var VATProductPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VST_GLAccount: Record "G/L Account";
        UST_GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATProductPostingGroupCode := VATProductPostingGroup.Code;
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATBusinessPostingGroupCode := VATBusinessPostingGroup.Code;

        LibraryERM.CreateGLAccount(VST_GLAccount);
        LibraryERM.CreateGLAccount(UST_GLAccount);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroupCode);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Purchase VAT Account", VST_GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", UST_GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; VATProPostingGroupCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProPostingGroupCode);
        Item.Modify(true);
    end;

    local procedure CreateUpdateVATStatementTemplate(var VATStatementName: Record "VAT Statement Name")
    var
        VATStatementTemplate: Record "VAT Statement Template";
        UpdateVATAT: Codeunit "Update VAT-AT";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        UpdateVATAT.UpdateVATStatementTemplate(VATStatementTemplate.Name, VATStatementTemplate.Description, '');
        VATStatementName.SetRange("Statement Template Name", VATStatementTemplate.Name);
        VATStatementName.FindFirst();
    end;

    local procedure CheckCreateVATProductPostingGroup5Pct(): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATProductPostingGroupCode: Code[20];
    begin
        VATProductPostingGroupCode := GetVAT5Group();
        if not VATProductPostingGroup.GET(VATProductPostingGroupCode) then begin
            VATProductPostingGroup.Code := VATProductPostingGroupCode;
            VATProductPostingGroup.Description := LibraryUtility.GenerateGUID();
            VATProductPostingGroup.Insert();
        end;
        exit(VATProductPostingGroup.Code);
    end;

    local procedure CheckCreateVATSetup5Pct(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProductPostingGroup5Pct: Code[20];
    begin
        VATProductPostingGroup5Pct := CheckCreateVATProductPostingGroup5Pct();
        VATPostingSetup.SetRange("VAT Prod. Posting Group", GetVAT10Group());
        if VATPostingSetup.FindSet() then
            repeat
                if not VATPostingSetup2.GET(VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup5Pct) then
                    CopyInsertVATSetup(VATPostingSetup, VATProductPostingGroup5Pct, 5);
            until VATPostingSetup.Next() = 0;
        exit(VATProductPostingGroup5Pct);
    end;

    local procedure CopyInsertVATSetup(SourceVATPostingSetup: Record "VAT Posting Setup"; VATProductPostingGroup: Code[20]; VATPct: Decimal)
    var
        NewVATPostingSetup: Record "VAT Posting Setup";
    begin
        NewVATPostingSetup := SourceVATPostingSetup;
        NewVATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup;
        NewVATPostingSetup."VAT Identifier" := VATProductPostingGroup;
        if NewVATPostingSetup."VAT %" <> 0 then
            NewVATPostingSetup."VAT %" := VATPct;
        NewVATPostingSetup.Description := LibraryUtility.GenerateGUID();
        NewVATPostingSetup.Insert();
    end;

    local procedure StringContains(String: Text; SubString: Text): Boolean
    begin
        exit(StrPos(String, SubString) > 0);
    end;

    local procedure RunVATStatement(VATStatementName: Record "VAT Statement Name")
    var
        VATStatementAT: Report "VAT Statement AT";
        IncludeVATEntries: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        EnqueRequestPageFields(
          WorkDate(), WorkDate(), IncludeVATEntries::Open, PeriodSelection::"Within Period",
          ReportingType::"Defined period", true, false, false, false, 0);
        VATStatementName.SetRecFilter();
        VATStatementAT.SetTableView(VATStatementName);
        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        VATStatementAT.RunModal();
    end;

    local procedure AssertStringContains(String: Text; SubString: Text)
    begin
        if (SubString = '') or (SubString = ' ') then
            exit;
        Assert.IsTrue(StringContains(String, SubString), StrSubstNo(StringContainsErr, String, SubString));
    end;

    local procedure AssertStringContainsDec(String: Text; Amount: Decimal)
    begin
        Assert.AreEqual(String.Replace(',', '.'), Format(Abs(Amount), 0, 1).Replace(',', '.'), StrSubstNo(StringContainsErr, String, Amount));
    end;

    local procedure AssertVATStatementLineExists(var VATStatementLine: Record "VAT Statement Line"; RowNo: Code[10])
    begin
        VATStatementLine.SetRange("Row No.", RowNo);
        Assert.RecordIsNotEmpty(VATStatementLine);
    end;

    local procedure AssertVATStatementRowTotalling(var VATStatementLine: Record "VAT Statement Line"; RowNo: Code[10]; RowTotalling: Text[50])
    begin
        VATStatementLine.SetRange("Row No.", RowNo);
        VATStatementLine.FindFirst();
        VATStatementLine.TestField("Row Totaling", RowTotalling);
    end;

    local procedure VerifyFDFHeader(FDFFileHelper: Codeunit FDFFileHelper)
    var
        CompanyInformation: Record "Company Information";
        actualValue: Text;
    begin
        CompanyInformation.Get();

        actualValue := FDFFileHelper.GetValue('Text01');
        AssertStringContains(actualValue, CompanyInformation."Tax Office Name");
        AssertStringContains(actualValue, CompanyInformation."Tax Office Address");
        AssertStringContains(actualValue, CompanyInformation."Tax Office Post Code");
        AssertStringContains(actualValue, CompanyInformation."Tax Office City");

        actualValue := FDFFileHelper.GetValue('Zahl02_1');
        AssertStringContains(actualValue, CopyStr(CompanyInformation."Registration No.", 1, 3));

        actualValue := FDFFileHelper.GetValue('Zahl02_2');
        AssertStringContains(actualValue, CopyStr(CompanyInformation."Registration No.", 5, 4));

        actualValue := FDFFileHelper.GetValue('Zahl03');
        AssertStringContains(actualValue, CompanyInformation."Tax Office Number");

        actualValue := FDFFileHelper.GetValue('Text03');
        AssertStringContains(actualValue, CompanyInformation.Name);
        AssertStringContains(actualValue, CompanyInformation."Name 2");

        actualValue := FDFFileHelper.GetValue('Text05');
        AssertStringContains(actualValue, CompanyInformation.Address);
        AssertStringContains(actualValue, CompanyInformation."Address 2");

        actualValue := FDFFileHelper.GetValue('Text06');
        AssertStringContains(actualValue, CompanyInformation."House Number");

        actualValue := FDFFileHelper.GetValue('Text07');
        AssertStringContains(actualValue, CompanyInformation."Floor Number");

        actualValue := FDFFileHelper.GetValue('Text07a');
        AssertStringContains(actualValue, CompanyInformation."Room Number");

        actualValue := FDFFileHelper.GetValue('Text07b');
        AssertStringContains(actualValue, CompanyInformation."Country/Region Code");

        actualValue := FDFFileHelper.GetValue('Text07c');
        AssertStringContains(actualValue, CompanyInformation."Phone No.");

        actualValue := FDFFileHelper.GetValue('Text07d');
        AssertStringContains(actualValue, CompanyInformation."Post Code");

        actualValue := FDFFileHelper.GetValue('Text07e');
        AssertStringContains(actualValue, CompanyInformation.City);
    end;

    local procedure VerifyFDFLineValue(FDFFileHelper: Codeunit FDFFileHelper; "key": Option; expectedValue: Decimal)
    var
        actualValue: Text;
    begin
        arguments := key;
        actualValue := FDFFileHelper.GetValue(Format(arguments));
        AssertStringContainsDec(actualValue, expectedValue);
    end;

    local procedure VerifyFDFLineMinus(FDFFileHelper: Codeunit FDFFileHelper; "key": Option)
    var
        actualValue: Text;
    begin
        arguments := key;
        actualValue := FDFFileHelper.GetValue(Format(arguments));
        AssertStringContains(actualValue, '-');
    end;

    local procedure VerifyXMLHeader(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader")
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/ART_IDENTIFIKATIONSBEGRIFF', 'FASTNR');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/IDENTIFIKATIONSBEGRIFF', '991234567');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/PAKET_NR', '999999999');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/INFO_DATEN/ANZAHL_ERKLAERUNGEN', '1');

        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, '@art', 'U30');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'SATZNR', '1');

        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ANBRINGEN', 'U30');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRVON/@type', 'jahrmonat');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRVON', Format(WorkDate(), 0, '<Year4>-<Month,2>'));
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRBIS/@type', 'jahrmonat');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/ZRBIS', Format(WorkDate(), 0, '<Year4>-<Month,2>'));
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, 'ALLGEMEINE_DATEN/FASTNR', '991234567');
    end;

    local procedure VerifyXMLLine(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; Path: Text; Value: Decimal)
    begin
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, Path + '/@type', 'kz');
        VerifyXMLValueInErklaerung(LibraryXPathXMLReader, Path, Format(Value, 0, '<sign><integer><decimals,3><comma,.>'));
    end;

    local procedure VerifyXMLValueInErklaerung(LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader"; XPath: Text; ExpectedValue: Text)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/' + XPath, ExpectedValue);
    end;

    local procedure GetVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Type: Enum "General Posting Type")
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange(Type, Type);
        VATEntry.FindFirst();
        Assert.AreEqual(1, VATEntry.Count, '');
    end;

    local procedure CreateVATEntTotVATStmtLine(RowNo: Code[10]; BusPostingGroup: Code[20]; ProdPostingGroup: Code[20])
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        LineNoToCreate: Integer;
    begin
        VATStatementTemplate.FindFirst();

        VATStatementLine.SetRange("Statement Template Name", VATStatementTemplate.Name);
        if VATStatementLine.FindLast() then
            LineNoToCreate := VATStatementLine."Line No." + 10000
        else
            LineNoToCreate := 1;

        VATStatementLine.Init();
        VATStatementLine.Validate("Line No.", LineNoToCreate);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"VAT Entry Totaling");
        VATStatementLine.Validate("Gen. Posting Type", VATStatementLine."Gen. Posting Type"::Purchase);
        VATStatementLine.Validate("VAT Bus. Posting Group", BusPostingGroup);
        VATStatementLine.Validate("VAT Prod. Posting Group", ProdPostingGroup);
        VATStatementLine.Validate("Amount Type", VATStatementLine."Amount Type"::Amount);
        VATStatementLine.Validate(Print, true);
        VATStatementLine.Insert(true);
    end;

    local procedure CreateRowTotVATStmtLine(RowNo: Code[10]; RowTotaling: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
        VATStatementLine: Record "VAT Statement Line";
        LineNoToCreate: Integer;
    begin
        VATStatementTemplate.FindFirst();

        VATStatementLine.SetRange("Statement Template Name", VATStatementTemplate.Name);
        if VATStatementLine.FindLast() then
            LineNoToCreate := VATStatementLine."Line No." + 10000
        else
            LineNoToCreate := 1;

        VATStatementLine.Init();
        VATStatementLine.Validate("Line No.", LineNoToCreate);
        VATStatementLine.Validate("Row No.", RowNo);
        VATStatementLine.Validate(Type, VATStatementLine.Type::"Row Totaling");
        VATStatementLine.Validate("Row Totaling", RowTotaling);
        VATStatementLine.Validate(Print, true);
        VATStatementLine.Insert(true);
    end;

    local procedure GetDomesticGroup(): Code[20]
    begin
        exit('DOMESTIC');
    end;

    local procedure GetEUGroup(): Code[20]
    begin
        exit('EU');
    end;

    local procedure GetExportGroup(): Code[20]
    begin
        exit('EXPORT');
    end;

    local procedure GetVAT5Group(): Code[20]
    begin
        exit('VAT5');
    end;

    local procedure GetVAT10Group(): Code[20]
    begin
        exit('VAT10');
    end;

    local procedure GetTemplateName(): Code[10]
    begin
        exit('UVA-2020');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtATRequestPageHandler(var VATStatementAT: TestRequestPage "VAT Statement AT")
    var
        Variables: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.ReportingType.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.StartingDate.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.EndingDate.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.IncludeVATEntries.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.PeriodSelection.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.CheckPositions.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.RoundToWholeNumbers.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.SurplusUsedToPayDues.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.AdditionalInvoicesSentViaMail.SetValue(Variables);
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.NumberPar6Abs1.SetValue(Variables);
        VATStatementAT.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VATStmtATConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question = AdjustDatesMsg then
            Reply := true
        else
            Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VATStmtATMessageHandler(Msg: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStmtTemplateRequestPageHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    begin
        UpdateVATStatementTemplate.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStmtTemplateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

