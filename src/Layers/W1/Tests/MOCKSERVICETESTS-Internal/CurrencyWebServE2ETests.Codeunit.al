codeunit 134272 "Currency Web Serv. E2E Tests"
{
    Permissions = TableData "Data Exch." = d;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Currency Exchange Rate]
    end;

    var
        DummyDataExchColumnDef: Record "Data Exch. Column Def";
        DummyDataExchDef: Record "Data Exch. Def";
        Assert: Codeunit Assert;
        CurrExchRateFileMgt: Codeunit "Currency Exch. Rate File Mgt.";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        XMLDOMManagement: Codeunit "XML DOM Management";
        Initialized: Boolean;
        NationalBankenURLTxt: Label 'https://localhost:8080/NationalBanken', Locked = true;
        NationalBankenLineDefXPathTxt: Label '/exchangerates/dailyrates/currency';
        NationalBankenCurrencyCodeXPathTxt: Label '/exchangerates/dailyrates/currency/@code';
        NationalBankenStartingDateXPathTxt: Label '/exchangerates/dailyrates/@id';
        NationalBankenExchangeRateXPathTxt: Label '/exchangerates/dailyrates/currency/@rate';
        ExpectedCurrencyExchRateFieldNotFoundErr: Label 'Expected field not found in the mapping field list.';
        ExpectedSourceFieldNotFoundErr: Label 'Expected XML node %1 not found in the generated XML structure.', Comment = ' %1 - XML node name';
        MissingDataLineTagErr: Label '%1 for %2 must not be blank.', Comment = '%1 - source XML node; %2 - parent node for caption code';
        MissingServiceURLErr: Label 'The %1 field must not be blank.', Comment = '%1 - Service URL';
        DataExchangeLineDefNameTxt: Label 'Parent Node for Currency Code';
        InvalidUriErr: Label 'The URI is not valid.';
        XEBankStartingDateXPathTxt: Label '/xe-datafeed/header[3]/hvalue';
        InvalidResponseErr: Label 'The response was not valid.';

    [Test]
    [HandlerFunctions('GetGetFileStructureHandler')]
    [Scope('OnPrem')]
    procedure TestDanishXMLCurrencyImportUI()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        DataExchDef: Record "Data Exch. Def";
        DanishCurrencyExchRateFile: Text;
    begin
        // [SCENARIO] Import Currency Exchange Rate from the Danish Central Bank
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user runs a service (here it is done through mocking)
        // [THEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [THEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [THEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [THEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [THEN] Import the actual data from the url to the Currency Exchange Rate table

        // Setup
        Initialize();

        DanishCurrencyExchRateFile := CreateDanishCurrencyExchRateFile(TempCurrExchRateNew);
        SetupDanishCurrExch(CurrExchRateUpdateSetup, DataExchDef."File Type"::Xml, DanishCurrencyExchRateFile);

        // Execute
        ImportCurrencyData(DanishCurrencyExchRateFile, CurrExchRateUpdateSetup);

        // Verify
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [HandlerFunctions('GetGetFileStructureHandler')]
    [Scope('OnPrem')]
    procedure TestDanishJsonCurrencyImportUI()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        DataExchDef: Record "Data Exch. Def";
        CurrencyExchRateXMLFile: Text;
        DanishCurrencyExchRateFile: Text;
    begin
        // [SCENARIO] Import Currency Exchange Rate in json from the Danish Central Bank
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user runs a service (here it is done through mocking)
        // [THEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [THEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [THEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [THEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [THEN] Import the actual data from the url to the Currency Exchange Rate table

        // Setup
        Initialize();

        CurrencyExchRateXMLFile := CreateDanishCurrencyExchRateFile(TempCurrExchRateNew);
        DanishCurrencyExchRateFile := ConvertXMLToJSon(CurrencyExchRateXMLFile);
        SetupDanishCurrExch(CurrExchRateUpdateSetup, DataExchDef."File Type"::Json, DanishCurrencyExchRateFile);

        // Execute
        ImportCurrencyData(DanishCurrencyExchRateFile, CurrExchRateUpdateSetup);

        // Verify
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestECBCurrencyImportToday()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        SetUpCurrExchRateService: Codeunit "Set Up Curr Exch Rate Service";
        CurrencyExchRateXMLFile: Text;
    begin
        // [SCENARIO] Import today Currency Exchange Rate from the European Central Bank

        Initialize();

        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [GIVEN] actual on today date = "D" (TFS 381351)
        CurrencyExchRateXMLFile := CreateECBCurrencyExchRateFile(TempCurrExchRateNew, Today);

        // [GIVEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [GIVEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [GIVEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [GIVEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [GIVEN] Import the actual data from the url to the Currency Exchange Rate table
        SetUpCurrExchRateService.SetupECBDataExchange(CurrExchRateUpdateSetup, CurrencyExchRateXMLFile);
        Commit();

        // [WHEN] Import ECB currency excange rates (here it is done through mocking)
        ImportCurrencyData(CurrencyExchRateXMLFile, CurrExchRateUpdateSetup);

        // [THEN] Downloaded currency exchange rate date is equal to published date = "D" (TFS 381351)
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestECBCurrencyImportYesterday()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        SetUpCurrExchRateService: Codeunit "Set Up Curr Exch Rate Service";
        CurrencyExchRateXMLFile: Text;
    begin
        // [SCENARIO] Import yesterday's Currency Exchange Rate from the European Central Bank

        Initialize();

        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [GIVEN] actual on yesterday date = "D" (TFS 381351)
        CurrencyExchRateXMLFile := CreateECBCurrencyExchRateFile(TempCurrExchRateNew, Today - 1);

        // [GIVEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [GIVEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [GIVEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [GIVEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [GIVEN] Import the actual data from the url to the Currency Exchange Rate table
        SetUpCurrExchRateService.SetupECBDataExchange(CurrExchRateUpdateSetup, CurrencyExchRateXMLFile);
        Commit();

        // [WHEN] Import ECB currency excange rates (here it is done through mocking)
        ImportCurrencyData(CurrencyExchRateXMLFile, CurrExchRateUpdateSetup);

        // [THEN] Downloaded currency exchange rate date is equal to published date = "D" (TFS 381351)
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestXE_XMLCurrencyImport()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        CurrencyExchRateXMLFile: Text;
    begin
        // [SCENARIO] Import Currency Exchange Rate from XE Currency Exchange Web Service
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user runs a service (here it is done through mocking)
        // [THEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [THEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [THEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [THEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [THEN] Import the actual data from the url to the Currency Exchange Rate table

        // Setup
        Initialize();

        CurrencyExchRateXMLFile := CreateXE_CurrencyExchRateFile(TempCurrExchRateNew);

        SetupXE_CurrExch(CurrExchRateUpdateSetup, CurrencyExchRateXMLFile);

        Commit();
        // Exercise
        ImportCurrencyData(CurrencyExchRateXMLFile, CurrExchRateUpdateSetup);

        // Verify
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCanadianXMLCurrencyImport()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        CurrencyExchRateXMLFile: Text;
    begin
        // [SCENARIO] Import Currency Exchange Rate from the Canadian Central Bank Web Service
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user runs a service (here it is done through mocking)
        // [THEN] Create a Data Exchange Definition, Line Definition and Mapping Header for the service
        // [THEN] Create a Mapping Header to point to the Currency Exchange Rate table as the destination
        // [THEN] Using the URL to the xml, parse and import the structure of the source onto the Data Exchange Column Definition
        // [THEN] Map the Data Exchange Column Definition to the Currency Exchange Rate fields
        // [THEN] Import the actual data from the url to the Currency Exchange Rate table

        // Setup
        Initialize();

        CurrencyExchRateXMLFile := CreateCanadianCurrencyExchRateFile(TempCurrExchRateNew);

        SetupCanadianCurrExch(CurrExchRateUpdateSetup, CurrencyExchRateXMLFile);

        // Exercise
        ImportCurrencyData(CurrencyExchRateXMLFile, CurrExchRateUpdateSetup);

        // Verify
        VerifyCurrExchRates(TempCurrExchRateNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFileBasedCurrencyImport()
    var
        TempCurrExchRateNew: Record "Currency Exchange Rate" temporary;
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchRateXMLFile: Text;
    begin
        // [GIVEN] Given a URL to an xml file source containg currency exchange rates
        // [WHEN] A user enters the path
        // [THEN] An error occurs as it is not a valid HTTP URI

        // Setup
        Initialize();

        CurrencyExchRateXMLFile := CreateCanadianCurrencyExchRateFile(TempCurrExchRateNew);

        // Exercise
        ExchRateUpdateSetupCard.OpenNew();
        ExchRateUpdateSetupCard.Code.SetValue('TEST');
        asserterror ExchRateUpdateSetupCard.ServiceURL.SetValue(CurrencyExchRateXMLFile);

        // Verify
        Assert.ExpectedError(InvalidUriErr);
    end;

    [Test]
    [HandlerFunctions('SelectSourceModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestCreatingSetupE2E()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        TempField: Record "Field" temporary;
        TransformationRule: Record "Transformation Rule";
        MapCurrencyExchangeRate: Codeunit "Map Currency Exchange Rate";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeRates: TestPage "Currency Exchange Rates";
        CurrencyExchangeSetupCode: Code[20];
        NationalBankenDefaultAmount: Integer;
        StartDateNodeName: Text;
        ExpectedText: Text;
        ExpectedDate: Date;
    begin
        // [SCENARIO] Create a setup to Update Currency Exchange Rates
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user go to a Setup Page
        // [THEN] After entering a code the suggested fields are inserted
        // [THEN] User can provide path manually
        // [THEN] User can use suggestion to provide path
        // [THEN] After mapping is done User can test the connection and see what data is generated

        ExchRateUpdateSetupCard.OpenNew();

        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.ServiceURL.SetValue(NationalBankenURLTxt);

        ExchRateUpdateSetupCard.Close();
        ExchRateUpdateSetupCard.OpenEdit();
        CurrExchRateUpdateSetup.Get(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.GotoRecord(CurrExchRateUpdateSetup);

        MapCurrencyExchangeRate.GetSuggestedFields(TempField);

        // Verify suggested fields are created
        repeat
            ExchRateUpdateSetupCard.SimpleDataExchSetup.FILTER.SetFilter(Caption, TempField."Field Caption");
            Assert.AreEqual(TempField."Field Caption", ExchRateUpdateSetupCard.SimpleDataExchSetup.CaptionField.Value,
              'Suggested field was not inserted');
        until TempField.Next() = 0;

        ExchRateUpdateSetupCard.SimpleDataExchSetup.FILTER.SetFilter(Caption, '');

        // Enter lines manually
        ExchRateUpdateSetupCard.SimpleDataExchSetup.First();
        ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.SetValue(NationalBankenLineDefXPathTxt);

        ExchRateUpdateSetupCard.SimpleDataExchSetup.Next();
        ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.SetValue(NationalBankenCurrencyCodeXPathTxt);
        TransformationRule.FindFirst();
        ExchRateUpdateSetupCard.SimpleDataExchSetup."Transformation Rule".SetValue(TransformationRule.Code);

        StartDateNodeName := 'id';
        LibraryVariableStorage.Enqueue(StartDateNodeName);
        ExchRateUpdateSetupCard.SimpleDataExchSetup.Next();
        ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.AssistEdit();

        ExpectedText := NationalBankenStartingDateXPathTxt;
        Assert.AreEqual(ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.Value, ExpectedText,
          'XPath for source was not set correctly');

        NationalBankenDefaultAmount := 100;
        ExchRateUpdateSetupCard.SimpleDataExchSetup.Next();
        ExchRateUpdateSetupCard.SimpleDataExchSetup."Default Value".SetValue(NationalBankenDefaultAmount);

        ExchRateUpdateSetupCard.SimpleDataExchSetup.Next();
        ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.SetValue(NationalBankenExchangeRateXPathTxt);

        // Test Setup
        CurrencyExchangeRates.Trap();
        ExchRateUpdateSetupCard.Preview.Invoke();

        ExpectedDate := DMY2Date(3, 3, 2015);
        VerifyCurrExchRatesOnPage(CurrencyExchangeRates, NationalBankenDefaultAmount, ExpectedDate);
    end;

    [Test]
    [HandlerFunctions('CurrencyExchangeRateFieldListVerifier,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestAssistEditOnCaptionField()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user go to a Setup Page and click on assist edit of the Caption field
        // [THEN] User sees the field list of Currency Exchange Rate Fields
        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.ServiceURL.SetValue(NationalBankenURLTxt);

        ExchRateUpdateSetupCard.SimpleDataExchSetup.Last();
        ExchRateUpdateSetupCard.SimpleDataExchSetup.Next();

        // Verification is in the handler method
        ExchRateUpdateSetupCard.SimpleDataExchSetup.CaptionField.AssistEdit();
    end;

    [Test]
    [HandlerFunctions('SelectSourceVerifierForDanishExchangeRateFile,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestAssistEditOnSourceField()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user go to a Setup Page and click on assist edit of the Source field
        // [THEN] User sees the XML nodes from the file specified in the Service URL
        Initialize();

        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.ServiceURL.SetValue(NationalBankenURLTxt);
        ExchRateUpdateSetupCard.SimpleDataExchSetup.First();

        // Verification is in the handler method
        ExchRateUpdateSetupCard.SimpleDataExchSetup.SourceField.AssistEdit();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestPreviewWithBlankParentNodeForCurrencyCode()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user go to a Setup Page and doesn't fill out the Source field of the mandatory field
        // [WHEN] User invokes Preview action
        // [THEN] User gets an error message
        Initialize();

        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.ServiceURL.SetValue(NationalBankenURLTxt);
        ExchRateUpdateSetupCard.SimpleDataExchSetup.First();
        asserterror ExchRateUpdateSetupCard.Preview.Invoke();
        Assert.ExpectedError(StrSubstNo(MissingDataLineTagErr, DataExchFieldMappingBuf.FieldCaption(Source), DataExchangeLineDefNameTxt));
    end;

    [Test]
    [HandlerFunctions('ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestEnableWithBlankParentNodeForCurrencyCode()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        DataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf.";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [GIVEN] Given a URL to an xml source containg currency exchange rates
        // [WHEN] A user go to a Setup Page and doesn't fill out the Source field of the mandatory field
        // [WHEN] User checks Enabled checkbox
        // [THEN] User gets an error message
        Initialize();

        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        ExchRateUpdateSetupCard.ServiceURL.SetValue(NationalBankenURLTxt);
        ExchRateUpdateSetupCard.SimpleDataExchSetup.First();
        asserterror ExchRateUpdateSetupCard.Enabled.SetValue(true);
        Assert.ExpectedError(StrSubstNo(MissingDataLineTagErr, DataExchFieldMappingBuf.FieldCaption(Source), DataExchangeLineDefNameTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorIfExchangeRatesFileIsCorrupt()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        XMLBuffer: Record "XML Buffer";
        CurrencyExchRateXMLFile: Text;
    begin
        // [WHEN] User enters a URL to an xml source containing an empty currency exchange rates file
        // [THEN] User gets an error message
        Initialize();
        CurrencyExchRateXMLFile := CreateEmptyCurrencyExchRateFile();

        asserterror CurrExchRateUpdateSetup.GetXMLStructure(XMLBuffer, CurrencyExchRateXMLFile);
        Assert.ExpectedError(InvalidResponseErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPreviewWithBlankServiceURL()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [WHEN] User does not fill in Service URL and invokes Preview
        // [THEN] User gets an error message
        Initialize();
        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        asserterror ExchRateUpdateSetupCard.Preview.Invoke();
        Assert.ExpectedError(StrSubstNo(MissingServiceURLErr, CurrExchRateUpdateSetup.FieldCaption("Web Service URL")));
    end;

    [Test]
    [HandlerFunctions('ConsentConfirmYes')]
    [Scope('OnPrem')]
    procedure TestEnableWithBlankServiceURL()
    var
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        ExchRateUpdateSetupCard: TestPage "Curr. Exch. Rate Service Card";
        CurrencyExchangeSetupCode: Code[20];
    begin
        // [WHEN] User does not fill in Service URL and checks Enabled
        // [THEN] User gets an error message
        Initialize();
        ExchRateUpdateSetupCard.OpenNew();
        CurrencyExchangeSetupCode :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        ExchRateUpdateSetupCard.Code.SetValue(CurrencyExchangeSetupCode);
        asserterror ExchRateUpdateSetupCard.Enabled.SetValue(true);
        Assert.ExpectedError(StrSubstNo(MissingServiceURLErr, CurrExchRateUpdateSetup.FieldCaption("Web Service URL")));
    end;

    local procedure ConvertXMLToJSon(XMLFilePath: Text) JsonFilePath: Text
    var
        FileMgt: Codeunit "File Management";
        OutStream: OutStream;
        JsonConvert: DotNet JsonConvert;
        XmlDocument: DotNet XmlDocument;
        File: File;
    begin
        XMLDOMManagement.LoadXMLDocumentFromFile(XMLFilePath, XmlDocument);

        JsonFilePath := FileMgt.ServerTempFileName('.json');

        File.Create(JsonFilePath);
        File.CreateOutStream(OutStream);

        OutStream.Write(JsonConvert.SerializeObject(XmlDocument));

        File.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTSameNode()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "." when Node path is equal to Root path
        Assert.AreEqual(XMLDOMManagement.GetRelativePath(
            '/gesmes:Envelope/Cube/Cube/Cube', '/gesmes:Envelope/Cube/Cube/Cube'), '.', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeAboveBase()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "../F": when pass "/A/B/C/F" and "/A/B/C/D"
        Assert.AreEqual('../@time',
          XMLDOMManagement.GetRelativePath('/gesmes:Envelope/Cube/Cube/@time', '/gesmes:Envelope/Cube/Cube/Cube'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeAbove2Base()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "../../../F/G/H": when pass "/A/F/G/H" and "/A/B/C/D"
        Assert.AreEqual('../../../rate/date/@time',
          XMLDOMManagement.GetRelativePath('/gesmes:Envelope/rate/date/@time', '/gesmes:Envelope/Cube/Cube/Cube'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeInBase()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "E" when pass "/A/B/C/D/E" and "/A/B/C/D"
        Assert.AreEqual('@currency',
          XMLDOMManagement.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/@currency', '/gesmes:Envelope/Cube/Cube/Cube'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeBelowBase()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "E/F": when pass "/A/B/C/D/E/F" and "/A/B/C/D"
        Assert.AreEqual('rate/@rate',
          XMLDOMManagement.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/rate/@rate', '/gesmes:Envelope/Cube/Cube/Cube'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeBelow2Base()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] XMLDOMManagement.GetRelativePath returns "E/F"/G: when pass "/A/B/C/D/E/F/G" and "/A/B/C/D"
        Assert.AreEqual('rate/rate/@rate',
          XMLDOMManagement.GetRelativePath('/gesmes:Envelope/Cube/Cube/Cube/rate/rate/@rate', '/gesmes:Envelope/Cube/Cube/Cube'), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTNodeIsEmpty()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] System throws error "Node path cannot be empty." when XMLDOMManagement.GetRelativePath called with blank Node path
        asserterror XMLDOMManagement.GetRelativePath('', '/gesmes:Envelope/Cube/Cube/Cube');
        Assert.ExpectedError('Node path cannot be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetRelativePathUTBaseIsEmpty()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381351] System throws error "Base path cannot be empty." when XMLDOMManagement.GetRelativePath called with blank Base path
        asserterror XMLDOMManagement.GetRelativePath('/gesmes:Envelope/Cube/Cube/@time', '');
        Assert.ExpectedError('Base path cannot be empty.');
    end;

    local procedure Initialize()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup";
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryVariableStorage.Clear();
        CurrencyExchangeRate.DeleteAll();
        DataExch.DeleteAll(true);
        DataExchDef.DeleteAll(true);
        CurrExchRateUpdateSetup.DeleteAll(true);

        if Initialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        Initialized := true;

        Commit();
    end;

    local procedure CreateCurrencyExchangeSetup(DataExchLineDef: Record "Data Exch. Line Def"; var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    begin
        CurrExchRateUpdateSetup.Code :=
          LibraryUtility.GenerateRandomCode(CurrExchRateUpdateSetup.FieldNo(Code), DATABASE::"Curr. Exch. Rate Update Setup");
        CurrExchRateUpdateSetup."Data Exch. Def Code" := DataExchLineDef."Data Exch. Def Code";
        CurrExchRateUpdateSetup.Enabled := true;
        CurrExchRateUpdateSetup.Insert();
    end;

    local procedure CreateDataExch(var DataExchLineDef: Record "Data Exch. Line Def"; FileType: Option; RepeaterPath: Text[250])
    begin
        CreateExchDef(CurrExchRateFileMgt.GetDataExchDefCode(), FileType, CurrExchRateFileMgt.GetReadingWritingCodeunit());
        CreateExchLineDef(DataExchLineDef, CurrExchRateFileMgt.GetDataExchDefCode(), RepeaterPath);
    end;

    local procedure SetupDanishCurrExch(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; DataExchLineDefType: Option; FilePath: Text)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchDefCard: TestPage "Data Exch Def Card";
    begin
        CreateDataExch(DataExchLineDef, DataExchLineDefType, CurrExchRateFileMgt.GetDanishRepeaterPath());

        DataExchDef.Get(DataExchLineDef."Data Exch. Def Code");
        DataExchDefCard.OpenEdit();
        DataExchDefCard.GotoRecord(DataExchDef);

        Commit();

        LibraryVariableStorage.Enqueue(FilePath);
        DataExchDefCard."Column Definitions".GetFileStructure.Invoke();

        MapDanishBankDataExch(DataExchLineDef);

        CreateCurrencyExchangeSetup(DataExchLineDef, CurrExchRateUpdateSetup);
    end;

    local procedure SetupXE_CurrExch(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; CurrencyExchRateXMLFile: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
    begin
        CreateDataExch(DataExchLineDef, DummyDataExchDef."File Type"::Xml, CurrExchRateFileMgt.GetXE_RepeaterPath());
        SuggestColDefinitionXML.GenerateDataExchColDef(CurrencyExchRateXMLFile, DataExchLineDef);
        MapXE_BankDataExch(DataExchLineDef);
        CreateCurrencyExchangeSetup(DataExchLineDef, CurrExchRateUpdateSetup);
    end;

    local procedure SetupCanadianCurrExch(var CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup"; CurrencyExchRateXMLFile: Text)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        SuggestColDefinitionXML: Codeunit "Suggest Col. Definition - XML";
    begin
        CreateDataExch(DataExchLineDef, DummyDataExchDef."File Type"::Xml, CurrExchRateFileMgt.GetCanadianRepeaterPath());
        SuggestColDefinitionXML.GenerateDataExchColDef(CurrencyExchRateXMLFile, DataExchLineDef);
        MapCanadianBankDataExch(DataExchLineDef);
        CreateCurrencyExchangeSetup(DataExchLineDef, CurrExchRateUpdateSetup);
    end;

    local procedure MapDanishBankDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
        TransformationRule: Record "Transformation Rule";
    begin
        CreateExchMappingHeader(DataExchLineDef);
        // Create Mapping using sample xml
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, CurrExchRateFileMgt.GetMappingTable());
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetCurrencyCodeXMLElement(), CurrExchRateFileMgt.GetCurrencyCodeFieldNo(),
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '');
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetStartingDateXMLElement(), CurrExchRateFileMgt.GetStartingDateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Date, 1, '', '');

        TransformationRule.CreateDefaultTransformations();
        TransformationRule.Get(TransformationRule.GetDanishDecimalFormatCode());

        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetRelationalExchRateXMLElement(), CurrExchRateFileMgt.GetRelationalExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1,
          TransformationRule.Code, '');
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetExchRateXMLElement(), CurrExchRateFileMgt.GetExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, CurrExchRateFileMgt.GetRelationalExhangeRate(),
          TransformationRule.Code, '');
    end;

    local procedure MapXE_BankDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        CreateExchMappingHeader(DataExchLineDef);

        // Create Mapping using sample xml
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, CurrExchRateFileMgt.GetMappingTable());
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetXE_CurrencyCodeXMLElement(), CurrExchRateFileMgt.GetCurrencyCodeFieldNo(),
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '');
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetXE_StartingDateXMLElement(), CurrExchRateFileMgt.GetStartingDateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Date, 1, '', '');

        // Update XPath to third element
        DataExchFieldMapping.SetRange("Field ID", CurrExchRateFileMgt.GetStartingDateFieldNo());
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchFieldMapping.FindFirst();
        DataExchColumnDef.Get(
          DataExchFieldMapping."Data Exch. Def Code", DataExchFieldMapping."Data Exch. Line Def Code",
          DataExchFieldMapping."Column No.");
        DataExchColumnDef.Path := XEBankStartingDateXPathTxt;
        DataExchColumnDef.Modify(true);

        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetXE_ExchRateXMLElement(), CurrExchRateFileMgt.GetExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '');
        CreateExchMappingLine(
          DataExchMapping, '', CurrExchRateFileMgt.GetRelationalExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '1');
    end;

    local procedure MapCanadianBankDataExch(var DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        CreateExchMappingHeader(DataExchLineDef);

        // Create Mapping using sample xml
        DataExchMapping.Get(DataExchLineDef."Data Exch. Def Code", DataExchLineDef.Code, CurrExchRateFileMgt.GetMappingTable());

        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetCanadianCurrencyCodeXMLElement(), CurrExchRateFileMgt.GetCurrencyCodeFieldNo(),
          DummyDataExchColumnDef."Data Type"::Text, 1, '', '');
        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetCanadianStartingDateXMLElement(), CurrExchRateFileMgt.GetStartingDateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Date, 1, '', '');

        CreateExchMappingLine(
          DataExchMapping, CurrExchRateFileMgt.GetCanadianExchRateXMLElement(),
          CurrExchRateFileMgt.GetExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '');
        CreateExchMappingLine(
          DataExchMapping, '', CurrExchRateFileMgt.GetRelationalExchRateFieldNo(),
          DummyDataExchColumnDef."Data Type"::Decimal, 1, '', '1');
    end;

    local procedure ImportCurrencyData(FilePath: Text; CurrExchRateUpdateSetup: Record "Curr. Exch. Rate Update Setup")
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        InStream: InStream;
        File: File;
    begin
        File.Open(FilePath);
        File.CreateInStream(InStream);
        UpdateCurrencyExchangeRates.UpdateCurrencyExchangeRates(CurrExchRateUpdateSetup, InStream, FilePath);
        File.Close();
    end;

    local procedure WriteECBCurrencyToStream(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        WriteECBXMLCurrencyHeader(OutStream, Date);
        WriteECBXMLCurrencyExchRates(OutStream, CurrExchRate, Date);
        WriteECBXMLCurrencyFooter(OutStream);
    end;

    local procedure WriteDanishCurrencyToStream(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    begin
        WriteDanishXMLCurrencyHeader(OutStream);
        WriteDanishXMLCurrencyExchRates(OutStream, CurrExchRate);
        WriteDanishXMLCurrencyFooter(OutStream);
    end;

    local procedure WriteXE_CurrencyToStream(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    begin
        WriteXE_XMLCurrencyHeader(OutStream);
        WriteXE_XMLCurrencyExchRates(OutStream, CurrExchRate);
        WriteXE_XMLCurrencyFooter(OutStream);
    end;

    local procedure WriteCanadianCurrencyToStream(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    begin
        WriteCanadianXMLCurrencyHeader(OutStream);
        WriteCanadianXMLCurrencyExchRates(OutStream, CurrExchRate);
        WriteCanadianXMLCurrencyFooter(OutStream);
    end;

    local procedure WriteECBXMLCurrencyHeader(var OutStream: OutStream; Date: Date)
    begin
        CurrExchRateFileMgt.WriteECB_XMLHeader(OutStream, Date);
    end;

    local procedure WriteECBXMLCurrencyExchRates(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'AUD', 526.85);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'BGN', 380.18);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'BRL', 246.72);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'CAD', 531.15);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'CHF', 743.77);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'CNY', 103.25);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'CZK', 26.61);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'EUR', 743.55);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'GBP', 969.3);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'HKD', 82.73);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'HRK', 96.48);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'HUF', 2.358);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'IDR', 0.0513);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'ILS', 163.35);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'INR', 10.42);
        // InsertECBExchRateLine(OutStream,CurrExchRate,Date,'ISK',0);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'JPY', 5.4645);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'KRW', 0.5923);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'MXN', 43.91);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'MYR', 177.76);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'NOK', 84.25);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'NZD', 491.64);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'PHP', 14.45);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'PLN', 172.69);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'RON', 164.91);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'RUB', 9.77);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'SEK', 78.9);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'SGD', 481.11);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'THB', 19.7);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'TRY', 273.96);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'USD', 641.38);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'XDR', 911.55);
        InsertECBExchRateLine(OutStream, CurrExchRate, Date, 'ZAR', 55.55);
    end;

    local procedure WriteECBXMLCurrencyFooter(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteECB_XMLFooter(OutStream);
    end;

    local procedure WriteDanishXMLCurrencyHeader(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteDanishXMLHeader(OutStream, CurrExchRateFileMgt.GetCurrencyCode(), 1);
        CurrExchRateFileMgt.WriteDanishXMLExchHeader(OutStream, CurrExchRateFileMgt.GetExchangeRateDate());
    end;

    local procedure WriteDanishXMLCurrencyExchRates(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    var
        Date: Date;
    begin
        Date := CurrExchRateFileMgt.GetExchangeRateDate();
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'AUD', 'Australian dollars', 526.85);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'BGN', 'Bulgarian lev', 380.18);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'BRL', 'Brazilian real', 246.72);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'CAD', 'Canadian dollars', 531.15);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'CHF', 'Swiss francs', 743.77);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'CNY', 'Chinese yuan renminbi', 103.25);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'CZK', 'Czech koruny', 26.61);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'EUR', 'Euro', 743.55);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'GBP', 'Pounds sterling', 969.3);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'HKD', 'Hong Kong dollars', 82.73);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'HRK', 'Croatian kuna', 96.48);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'HUF', 'Hungarian forints', 2.358);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'IDR', 'Indonesian rupiah', 0.0513);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'ILS', 'Israeli shekel', 163.35);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'INR', 'Indian rupee', 10.42);
        // InsertExchRateLine(OutStream,CurrExchRate,Date,'ISK','Icelandic kronur *',0);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'JPY', 'Japanese yen', 5.4645);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'KRW', 'South Korean won', 0.5923);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'MXN', 'Mexican peso', 43.91);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'MYR', 'Malaysian ringgit', 177.76);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'NOK', 'Norwegian kroner', 84.25);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'NZD', 'New Zealand dollars', 491.64);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'PHP', 'Philippine peso', 14.45);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'PLN', 'Polish zlotys', 172.69);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'RON', 'Romanian leu', 164.91);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'RUB', 'Russian rouble', 9.77);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'SEK', 'Swedish kronor', 78.9);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'SGD', 'Singapore dollars', 481.11);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'THB', 'Thai baht', 19.7);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'TRY', 'Turkish lira', 273.96);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'USD', 'US dollars', 641.38);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'XDR', 'SDR (Calculated **)', 911.55);
        InsertExchRateLine(OutStream, CurrExchRate, Date, 'ZAR', 'South African rand', 55.55);
    end;

    local procedure WriteDanishXMLCurrencyFooter(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteDanishXMLExchFooter(OutStream);
        CurrExchRateFileMgt.WriteDanishXMLFooter(OutStream);
    end;

    local procedure WriteXE_XMLCurrencyHeader(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteXE_XMLHeader(OutStream, CurrExchRateFileMgt.GetCurrencyCode(), CurrExchRateFileMgt.GetExchangeRateDate());
    end;

    local procedure WriteXE_XMLCurrencyExchRates(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    var
        Date: Date;
    begin
        Date := CurrExchRateFileMgt.GetExchangeRateDate();

        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AED', 'United Arab Emirates Dirhams', 3.6731504268, 0.2722458609);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AFN', 'Afghanistan Afghanis', 51.0699355345, 0.019580992);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ALL', 'Albania Leke', 107.8045028797, 0.0092760504);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AMD', 'Armenia Drams', 405.5493188604, 0.0024657913);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ANG', 'Netherlands Antilles Guilders', 1.7900065479, 0.5586571743);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AOA', 'Angola Kwanza', 95.4514191649, 0.0104765336);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ARS', 'Argentina Pesos', 4.7477313465, 0.2106269136);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AUD', 'Australia Dollars', 0.965543345, 1.035686285);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AWG', 'Aruba Guilders', 1.79, 0.5586592179);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'AZN', 'Azerbaijan New Manats', 0.7849999004, 1.273885512);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BAM', 'Bosnia and Herzegovina Convertible Marka', 1.5075586807, 0.6633240966);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BBD', 'Barbados Dollars', 2.0, 0.5);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BDT', 'Bangladesh Taka', 81.2335455669, 0.0123101853);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BGN', 'Bulgaria Leva', 1.5103089441, 0.6621161875);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BHD', 'Bahrain Dinars', 0.3770660445, 2.6520552953);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BIF', 'Burundi Francs', 1469.9854792951, 0.0006802788);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BMD', 'Bermuda Dollars', 1.0, 1.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BND', 'Brunei Dollars', 1.2218783783, 0.8184120595);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BOB', 'Bolivia Bolivianos', 6.910038725, 0.1447169893);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BRL', 'Brazil Reais', 2.0261701749, 0.4935419603);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BSD', 'Bahamas Dollars', 1.0, 1.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BTN', 'Bhutan Ngultrum', 53.7350438941, 0.0186098294);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BWP', 'Botswana Pulas', 7.9428117343, 0.1259000003);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BYR', 'Belarus Rubles', 8567.347323804, 0.0001167222);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'BZD', 'Belize Dollars', 1.9983475973, 0.5004134423);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CAD', 'Canada Dollars', 0.9937178688, 1.0063218458);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CDF', 'Congo/Kinshasa Francs', 918.4058334366, 0.0010888433);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CHF', 'Switzerland Francs', 0.9324570458, 1.0724354591);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CLP', 'Chile Pesos', 482.6449621362, 0.0020719164);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CNY', 'China Yuan Renminbi', 6.2493774166, 0.1600159397);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'COP', 'Colombia Pesos', 1817.4879752828, 0.00055021);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CRC', 'Costa Rica Colones', 499.7003438423, 0.0020011993);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CUC', 'Cuba Convertible Pesos', 1.0, 1.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CUP', 'Cuba Pesos', 26.5, 0.0377358491);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CVE', 'Cape Verde Escudos', 84.8272444446, 0.0117886654);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'CZK', 'Czech Republic Koruny', 19.2751896525, 0.051880164);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'DJF', 'Djibouti Francs', 180.9782900636, 0.0055255246);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'DKK', 'Denmark Kroner', 5.7495230878, 0.1739274692);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'DOP', 'Dominican Republic Pesos', 39.4499537436, 0.0253485722);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'DZD', 'Algeria Dinars', 79.641178521, 0.0125563185);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'EEK', 'Estonia Krooni', 12.0604694453, 0.0829155121);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'EGP', 'Egypt Pounds', 6.1017240456, 0.1638881065);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ERN', 'Eritrea Nakfa', 15.0999963706, 0.0662251815);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ETB', 'Ethiopia Birr', 18.110875548, 0.0552154421);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'EUR', 'Euro', 0.7708025139, 1.297349168);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'FJD', 'Fiji Dollars', 1.7856860011, 0.5600088702);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'FKP', 'Falkland Islands Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GBP', 'United Kingdom Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GEL', 'Georgia Lari', 1.6589860955, 0.6027778067);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GGP', 'Guernsey Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GHS', 'Ghana Cedis', 1.8754869661, 0.5331948545);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GIP', 'Gibraltar Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GMD', 'Gambia Dalasi', 30.7299995422, 0.0325414909);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GNF', 'Guinea Francs', 7004.2665744774, 0.0001427701);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GTQ', 'Guatemala Quetzales', 7.845498609, 0.1274616248);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'GYD', 'Guyana Dollars', 203.7001666401, 0.0049091762);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'HKD', 'Hong Kong Dollars', 7.7506258993, 0.1290218381);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'HNL', 'Honduras Lempiras', 19.7001317519, 0.0507610818);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'HRK', 'Croatia Kuna', 5.8189549916, 0.1718521627);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'HTG', 'Haiti Gourdes', 42.1519413686, 0.0237236997);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'HUF', 'Hungary Forint', 216.4073401813, 0.0046209153);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'IDR', 'Indonesia Rupiahs', 9609.999936, 0.0001040583);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ILS', 'Israel New Shekels', 3.8647817668, 0.258746822);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'IMP', 'Isle of Man Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'INR', 'India Rupees', 53.7350438941, 0.0186098294);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'IQD', 'Iraq Dinars', 1165.236170174, 0.0008581951);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'IRR', 'Iran Rials', 12269.9389274289, 0.0000815);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ISK', 'Iceland Kronur', 126.6906309, 0.0078932435);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'JEP', 'Jersey Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'JMD', 'Jamaica Dollars', 90.3472220516, 0.0110684089);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'JOD', 'Jordan Dinars', 0.708694349, 1.4110455396);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'JPY', 'Japan Yen', 79.8129697489, 0.012529292);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KES', 'Kenya Shillings', 84.999644439, 0.0117647551);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KGS', 'Kyrgyzstan Soms', 47.0658888198, 0.0212468101);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KHR', 'Cambodia Riels', 4039.9948839613, 0.0002475251);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KMF', 'Comoros Francs', 379.2099784342, 0.0026370614);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KPW', 'North Korea Won', 129.7481069386, 0.0077072415);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KRW', 'South Korea Won', 1103.869222586, 0.0009059044);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KWD', 'Kuwait Dinars', 0.281425803, 3.5533344473);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KYD', 'Cayman Islands Dollars', 0.8199999978, 1.2195121985);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'KZT', 'Kazakhstan Tenge', 150.6103872742, 0.0066396483);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LAK', 'Laos Kips', 7962.336162729, 0.0001255913);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LBP', 'Lebanon Pounds', 1504.8595788508, 0.0006645138);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LKR', 'Sri Lanka Rupees', 130.1156298311, 0.0076854718);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LRD', 'Liberia Dollars', 73.9999660179, 0.0135135197);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LSL', 'Lesotho Maloti', 8.7835641577, 0.1138490005);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LTL', 'Lithuania Litai', 2.6614269198, 0.3757382901);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LVL', 'Latvia Lati', 0.5367088616, 1.8632075444);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'LYD', 'Libya Dinars', 1.2465002713, 0.802246115);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MAD', 'Morocco Dirhams', 8.5645316632, 0.1167606168);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MDL', 'Moldova Lei', 12.2697892198, 0.0815009926);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MGA', 'Madagascar Ariary', 2215.067891989, 0.0004514534);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MKD', 'Macedonia Denars', 47.526418566, 0.021040929);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MMK', 'Myanmar Kyats', 851.4870370425, 0.001174416);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MNT', 'Mongolia Tugriks', 1382.4937888959, 0.0007233306);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MOP', 'Macau Patacas', 7.9831446763, 0.1252639205);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MRO', 'Mauritania Ouguiyas', 297.2492791706, 0.0033641797);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MUR', 'Mauritius Rupees', 31.2499186395, 0.0320000833);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MVR', 'Maldives Rufiyaa', 15.4095599151, 0.06489478);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MWK', 'Malawi Kwachas', 302.9999616, 0.0033003305);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MXN', 'Mexico Pesos', 12.9930006191, 0.0769645157);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MYR', 'Malaysia Ringgits', 3.0612458752, 0.3266643846);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'MZN', 'Mozambique Meticais', 29.1498932211, 0.034305443);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NAD', 'Namibia Dollars', 8.7835641577, 0.1138490005);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NGN', 'Nigeria Nairas', 157.3016860797, 0.0063572109);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NIO', 'Nicaragua Cordobas', 23.9050030583, 0.0418322473);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NOK', 'Norway Kroner', 5.7485210491, 0.173957787);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NPR', 'Nepal Rupees', 85.8609171723, 0.0116467426);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'NZD', 'New Zealand Dollars', 1.2187355651, 0.8205225388);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'OMR', 'Oman Rials', 0.3849989524, 2.5974096652);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PAB', 'Panama Balboas', 1.0, 1.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PEN', 'Peru Nuevos Soles', 2.5839879384, 0.3869987105);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PGK', 'Papua New Guinea Kina', 2.0544163938, 0.4867562404);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PHP', 'Philippines Pesos', 41.4621855861, 0.024118362);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PKR', 'Pakistan Rupees', 95.7173122848, 0.0104474308);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PLN', 'Poland Zlotych', 3.2056255001, 0.3119515988);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'PYG', 'Paraguay Guarani', 4470.0110764011, 0.0002237131);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'QAR', 'Qatar Riyals', 3.6411484621, 0.2746386231);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'RON', 'Romania New Lei', 3.5244723474, 0.2837304145);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'RSD', 'Serbia Dinars', 87.5954413557, 0.0114161192);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'RUB', 'Russia Rubles', 31.41607934, 0.0318308338);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'RWF', 'Rwanda Francs', 626.1686594038, 0.0015970138);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SAR', 'Saudi Arabia Riyals', 3.7503830235, 0.2666394322);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SBD', 'Solomon Islands Dollars', 7.1308144027, 0.1402364363);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SCR', 'Seychelles Rupees', 13.081027836, 0.0764465922);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SDG', 'Sudan Pounds', 4.4124948065, 0.2266291619);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SEK', 'Sweden Kronor', 6.6835282569, 0.1496215714);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SGD', 'Singapore Dollars', 1.2218783783, 0.8184120595);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SHP', 'Saint Helena Pounds', 0.6235032078, 1.6038409866);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SLL', 'Sierra Leone Leones', 4349.9051744271, 0.0002298901);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SOS', 'Somalia Shillings', 1615.4865420464, 0.0006190086);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SPL', 'Seborga Luigini', 0.1666666667, 6.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SRD', 'Suriname Dollars', 3.2746280655, 0.3053781926);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'STD', 'S?o Tome and Principe Dobras', 18949.99968, 0.0000527704);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SVC', 'El Salvador Colones', 8.75, 0.1142857143);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SYP', 'Syria Pounds', 68.8993542956, 0.0145139241);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'SZL', 'Swaziland Emalangeni', 8.7835641577, 0.1138490005);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'THB', 'Thailand Baht', 30.7349328686, 0.0325362676);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TJS', 'Tajikistan Somoni', 4.7642953443, 0.2098946282);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TMM', 'Turkmenistan Manats', 14250.0, 0.0000701754);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TMT', 'Turkmenistan New Manats', 2.85, 0.350877193);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TND', 'Tunisia Dinars', 1.5694989929, 0.6371459966);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TOP', 'Tonga Pa''anga', 1.7467248909, 0.5725);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TRY', 'Turkey Lira', 1.8031986385, 0.5545700727);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TTD', 'Trinidad and Tobago Dollars', 6.4082603621, 0.156048591);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TVD', 'Tuvalu Dollars', 0.965543345, 1.035686285);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TWD', 'Taiwan New Dollars', 29.2944166749, 0.0341361977);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'TZS', 'Tanzania Shillings', 1584.6369742799, 0.0006310594);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'UAH', 'Ukraine Hryvnia', 8.1639972902, 0.1224890166);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'UGX', 'Uganda Shillings', 2589.9353298572, 0.00038611);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'USD', 'United States Dollars', 1.0, 1.0);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'UYU', 'Uruguay Pesos', 19.7499465359, 0.0506330485);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'UZS', 'Uzbekistan Sums', 1952.5919412661, 0.0005121398);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'VEB', 'Venezuela Bolivares', 4300.0, 0.0002325581);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'VEF', 'Venezuela Bolivares Fuertes', 4.3, 0.2325581395);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'VND', 'Vietnam Dong', 20832.4698874844, 0.000048002);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'VUV', 'Vanuatu Vatu', 91.6472729901, 0.0109113994);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'WST', 'Samoa Tala', 2.2883295193, 0.437);
        InsertXE_ExchRateLine(
          OutStream, CurrExchRate, Date, 'XAF', 'Communaut? Financi?re Africaine Francs BEAC', 505.6133045789, 0.0019777961);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XAG', 'Silver Ounces', 0.0314864617, 31.7596816606);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XAU', 'Gold Ounces', 0.0005875548, 1701.9689238712);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XCD', 'East Caribbean Dollars', 2.700000435, 0.3703703107);
        InsertXE_ExchRateLine(
          OutStream, CurrExchRate, Date, 'XDR', 'International Monetary Fund Special Drawing Rights', 0.6503500276, 1.5376335168);
        InsertXE_ExchRateLine(
          OutStream, CurrExchRate, Date, 'XOF', 'Communaut? Financi?re Africaine Francs BCEAO', 505.6133045789, 0.0019777961);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XPD', 'Palladium Ounces', 0.0016789977, 595.5934226509);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XPF', 'Comptoirs Fran?ais du Pacifique Francs', 91.9812069036, 0.010871786);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'XPT', 'Platinum Ounces', 0.0006411382, 1559.726154931);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'YER', 'Yemen Rials', 214.6046985097, 0.0046597302);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ZAR', 'South Africa Rand', 8.7835641577, 0.1138490005);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ZMK', 'Zambia Kwacha', 5290.0673950503, 0.0001890335);
        InsertXE_ExchRateLine(OutStream, CurrExchRate, Date, 'ZWD', 'Zimbabwe Dollars', 361.9, 0.0027631943);
    end;

    local procedure WriteXE_XMLCurrencyFooter(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteXE_XMLFooter(OutStream);
    end;

    local procedure WriteCanadianXMLCurrencyHeader(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteCanadianXMLHeader(OutStream);
    end;

    local procedure WriteCanadianXMLCurrencyExchRates(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate")
    var
        Date: Date;
    begin
        Date := CurrExchRateFileMgt.GetExchangeRateDate();
        WriteCanadianXMLCurrencyExchRatesDay1(OutStream, CurrExchRate, Date);

        Date := CalcDate('<+1D>', Date);
        WriteCanadianXMLCurrencyExchRatesDay2(OutStream, CurrExchRate, Date);

        Date := CalcDate('<+1D>', Date);
        WriteCanadianXMLCurrencyExchRatesDay3(OutStream, CurrExchRate, Date);

        Date := CalcDate('<+1D>', Date);
        WriteCanadianXMLCurrencyExchRatesDay4(OutStream, CurrExchRate, Date);

        Date := CalcDate('<+1D>', Date);
        WriteCanadianXMLCurrencyExchRatesDay5(OutStream, CurrExchRate, Date);
    end;

    local procedure WriteCanadianXMLCurrencyExchRatesDay1(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.S. dollar', 'USD', 1.2523, 0.7985);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Argentine peso', 'ARS', 0.1446, 6.9156);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Australian dollar', 'AUD', 0.9776, 1.0229);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Bahamian dollar', 'BSD', 1.2523, 0.7985);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Brazilian real', 'BRL', 0.4522, 2.2114);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFA franc', 'XAF', 0.002163, 462.3209);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFP franc', 'XPF', 0.01189, 84.1043);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chilean peso', 'CLP', 0.001997, 500.7511);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chinese renminbi', 'CNY', 0.2006, 4.985);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Colombian peso', 'COP', 0.000524, 1908.3969);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Croatian kuna', 'HRK', 0.184, 5.4348);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Czech Republic koruna', 'CZK', 0.05125, 19.5122);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Danish krone', 'DKK', 0.1907, 5.2438);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'East Caribbean dollar', 'XCD', 0.4655, 2.1482);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'European Euro', 'EUR', 1.4189, 0.7048);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Fiji dollar', 'FJD', 0.6174, 1.6197);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Ghanaian cedi', 'GHS', 0.3705, 2.6991);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Guatemalan quetzal', 'GTQ', 0.1599, 6.2539);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Honduran lempira', 'HNL', 0.05963, 16.7701);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hong Kong dollar', 'HKD', 0.161535, 6.190609);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hungarian forint', 'HUF', 0.004641, 215.4708);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Icelandic krona', 'ISK', 0.009481, 105.4741);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indian rupee', 'INR', 0.0202, 49.505);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indonesian rupiah', 'IDR', 0.000099, 10101.0101);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Israeli new shekel', 'ILS', 0.3221, 3.1046);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Jamaican dollar', 'JMD', 0.01084, 92.2509);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Japanese yen', 'JPY', 0.01051, 95.1475);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Malaysian ringgit', 'MYR', 0.3536, 2.8281);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Mexican peso', 'MXN', 0.08393, 11.9147);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Moroccan dirham', 'MAD', 0.131, 7.6336);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Myanmar (Burma) kyat', 'MMK', 0.00122, 819.67213);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Neth. Antilles guilder', 'ANG', 0.7115, 1.4055);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'New Zealand dollar', 'NZD', 0.9216, 1.0851);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Norwegian krone', 'NOK', 0.1649, 6.0643);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Pakistan rupee', 'PKR', 0.01237, 80.8407);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Panamanian balboa', 'PAB', 1.2523, 0.7985);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Peruvian new sol', 'PEN', 0.4079, 2.4516);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Philippine peso', 'PHP', 0.02832, 35.3107);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Polish zloty', 'PLN', 0.3415, 2.9283);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Romanian new leu', 'RON', 0.3217, 3.1085);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Russian ruble', 'RUB', 0.01867, 53.5619);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Serbian dinar', 'RSD', 0.01166, 85.7633);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Singapore dollar', 'SGD', 0.9266, 1.0792);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South African rand', 'ZAR', 0.1088, 9.1912);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South Korean won', 'KRW', 0.001141, 876.4242);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Sri Lanka rupee', 'LKR', 0.009416, 106.2022);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swedish krona', 'SEK', 0.1493, 6.6979);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swiss franc', 'CHF', 1.3565, 0.7372);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Taiwanese new dollar', 'TWD', 0.03965, 25.2207);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Thai baht', 'THB', 0.03836, 26.0688);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Trinidad and Tobago dollar', 'TTD', 0.1972, 5.071);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Tunisian dinar', 'TND', 0.6482, 1.5427);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Turkish lira', 'TRY', 0.5066, 1.9739);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.A.E. dirham', 'AED', 0.3409, 2.9334);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.K. pound sterling', 'GBP', 1.9091, 0.5238);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Venezuelan bolivar fuerte', 'VEF', 0.1988, 5.0302);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Vietnamese dong', 'VND', 0.000059, 16949.1525);
    end;

    local procedure WriteCanadianXMLCurrencyExchRatesDay2(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.S. dollar', 'USD', 1.2448, 0.8033);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Argentine peso', 'ARS', 0.1438, 6.9541);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Australian dollar', 'AUD', 0.9724, 1.0284);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Bahamian dollar', 'BSD', 1.2448, 0.8033);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Brazilian real', 'BRL', 0.4466, 2.2391);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFA franc', 'XAF', 0.002147, 465.7662);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFP franc', 'XPF', 0.0118, 84.7458);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chilean peso', 'CLP', 0.001993, 501.7561);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chinese renminbi', 'CNY', 0.1993, 5.0176);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Colombian peso', 'COP', 0.000526, 1901.1407);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Croatian kuna', 'HRK', 0.1826, 5.4765);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Czech Republic koruna', 'CZK', 0.05086, 19.6618);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Danish krone', 'DKK', 0.1892, 5.2854);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'East Caribbean dollar', 'XCD', 0.4628, 2.1608);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'European Euro', 'EUR', 1.4086, 0.7099);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Fiji dollar', 'FJD', 0.6134, 1.6303);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Ghanaian cedi', 'GHS', 0.3683, 2.7152);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Guatemalan quetzal', 'GTQ', 0.1589, 6.2933);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Honduran lempira', 'HNL', 0.05928, 16.8691);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hong Kong dollar', 'HKD', 0.160551, 6.22855);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hungarian forint', 'HUF', 0.004578, 218.436);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Icelandic krona', 'ISK', 0.0094, 106.383);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indian rupee', 'INR', 0.02004, 49.9002);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indonesian rupiah', 'IDR', 0.000098, 10204.0816);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Israeli new shekel', 'ILS', 0.3208, 3.1172);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Jamaican dollar', 'JMD', 0.01077, 92.8505);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Japanese yen', 'JPY', 0.01049, 95.3289);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Malaysian ringgit', 'MYR', 0.3495, 2.8612);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Mexican peso', 'MXN', 0.08405, 11.8977);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Moroccan dirham', 'MAD', 0.1301, 7.6864);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Myanmar (Burma) kyat', 'MMK', 0.00121, 826.44628);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Neth. Antilles guilder', 'ANG', 0.7073, 1.4138);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'New Zealand dollar', 'NZD', 0.923, 1.0834);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Norwegian krone', 'NOK', 0.1634, 6.12);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Pakistan rupee', 'PKR', 0.01231, 81.2348);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Panamanian balboa', 'PAB', 1.2448, 0.8033);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Peruvian new sol', 'PEN', 0.4063, 2.4612);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Philippine peso', 'PHP', 0.02803, 35.6761);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Polish zloty', 'PLN', 0.3368, 2.9691);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Romanian new leu', 'RON', 0.3182, 3.1427);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Russian ruble', 'RUB', 0.01897, 52.7148);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Serbian dinar', 'RSD', 0.01151, 86.881);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Singapore dollar', 'SGD', 0.9194, 1.0877);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South African rand', 'ZAR', 0.1073, 9.3197);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South Korean won', 'KRW', 0.001134, 881.8342);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Sri Lanka rupee', 'LKR', 0.009366, 106.7692);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swedish krona', 'SEK', 0.1489, 6.7159);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swiss franc', 'CHF', 1.3443, 0.7439);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Taiwanese new dollar', 'TWD', 0.03939, 25.3872);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Thai baht', 'THB', 0.03816, 26.2055);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Trinidad and Tobago dollar', 'TTD', 0.1966, 5.0865);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Tunisian dinar', 'TND', 0.6434, 1.5542);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Turkish lira', 'TRY', 0.5018, 1.9928);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.A.E. dirham', 'AED', 0.3389, 2.9507);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.K. pound sterling', 'GBP', 1.8941, 0.528);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Venezuelan bolivar fuerte', 'VEF', 0.1976, 5.0607);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Vietnamese dong', 'VND', 0.000058, 17241.3793);
    end;

    local procedure WriteCanadianXMLCurrencyExchRatesDay3(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.S. dollar', 'USD', 1.2528, 0.7982);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Argentine peso', 'ARS', 0.1445, 6.9204);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Australian dollar', 'AUD', 0.9747, 1.026);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Bahamian dollar', 'BSD', 1.2528, 0.7982);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Brazilian real', 'BRL', 0.4425, 2.2599);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFA franc', 'XAF', 0.002161, 462.7487);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFP franc', 'XPF', 0.01188, 84.1751);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chilean peso', 'CLP', 0.002001, 499.7501);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chinese renminbi', 'CNY', 0.2007, 4.9826);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Colombian peso', 'COP', 0.000526, 1901.1407);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Croatian kuna', 'HRK', 0.1838, 5.4407);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Czech Republic koruna', 'CZK', 0.05128, 19.5008);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Danish krone', 'DKK', 0.1904, 5.2521);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'East Caribbean dollar', 'XCD', 0.4657, 2.1473);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'European Euro', 'EUR', 1.4176, 0.7054);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Fiji dollar', 'FJD', 0.617, 1.6207);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Ghanaian cedi', 'GHS', 0.3762, 2.6582);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Guatemalan quetzal', 'GTQ', 0.16, 6.25);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Honduran lempira', 'HNL', 0.05966, 16.7616);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hong Kong dollar', 'HKD', 0.161562, 6.189574);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hungarian forint', 'HUF', 0.00459, 217.8649);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Icelandic krona', 'ISK', 0.009473, 105.5632);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indian rupee', 'INR', 0.0201, 49.7512);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indonesian rupiah', 'IDR', 0.000099, 10101.0101);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Israeli new shekel', 'ILS', 0.3238, 3.0883);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Jamaican dollar', 'JMD', 0.01084, 92.2509);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Japanese yen', 'JPY', 0.0105, 95.2381);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Malaysian ringgit', 'MYR', 0.35, 2.8571);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Mexican peso', 'MXN', 0.08377, 11.9374);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Moroccan dirham', 'MAD', 0.1311, 7.6278);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Myanmar (Burma) kyat', 'MMK', 0.00122, 819.67213);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Neth. Antilles guilder', 'ANG', 0.7118, 1.4049);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'New Zealand dollar', 'NZD', 0.9285, 1.077);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Norwegian krone', 'NOK', 0.1654, 6.0459);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Pakistan rupee', 'PKR', 0.01239, 80.7103);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Panamanian balboa', 'PAB', 1.2528, 0.7982);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Peruvian new sol', 'PEN', 0.4076, 2.4534);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Philippine peso', 'PHP', 0.02822, 35.4359);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Polish zloty', 'PLN', 0.3377, 2.9612);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Romanian new leu', 'RON', 0.3198, 3.127);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Russian ruble', 'RUB', 0.01888, 52.9661);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Serbian dinar', 'RSD', 0.01163, 85.9845);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Singapore dollar', 'SGD', 0.9242, 1.082);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South African rand', 'ZAR', 0.107, 9.3458);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South Korean won', 'KRW', 0.001139, 877.9631);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Sri Lanka rupee', 'LKR', 0.009427, 106.0783);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swedish krona', 'SEK', 0.1503, 6.6534);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swiss franc', 'CHF', 1.3523, 0.7395);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Taiwanese new dollar', 'TWD', 0.03968, 25.2016);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Thai baht', 'THB', 0.03838, 26.0552);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Trinidad and Tobago dollar', 'TTD', 0.1979, 5.0531);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Tunisian dinar', 'TND', 0.6479, 1.5434);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Turkish lira', 'TRY', 0.5015, 1.994);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.A.E. dirham', 'AED', 0.3411, 2.9317);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.K. pound sterling', 'GBP', 1.9106, 0.5234);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Venezuelan bolivar fuerte', 'VEF', 0.1989, 5.0277);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Vietnamese dong', 'VND', 0.000059, 16949.1525);
    end;

    local procedure WriteCanadianXMLCurrencyExchRatesDay4(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.S. dollar', 'USD', 1.2635, 0.7915);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Argentine peso', 'ARS', 0.1456, 6.8681);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Australian dollar', 'AUD', 0.9745, 1.0262);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Bahamian dollar', 'BSD', 1.2635, 0.7915);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Brazilian real', 'BRL', 0.4398, 2.2738);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFA franc', 'XAF', 0.002176, 459.5588);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFP franc', 'XPF', 0.01196, 83.612);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chilean peso', 'CLP', 0.002005, 498.7531);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chinese renminbi', 'CNY', 0.2024, 4.9407);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Colombian peso', 'COP', 0.000523, 1912.0459);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Croatian kuna', 'HRK', 0.185, 5.4054);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Czech Republic koruna', 'CZK', 0.05166, 19.3573);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Danish krone', 'DKK', 0.1918, 5.2138);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'East Caribbean dollar', 'XCD', 0.4697, 2.129);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'European Euro', 'EUR', 1.4271, 0.7007);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Fiji dollar', 'FJD', 0.6147, 1.6268);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Ghanaian cedi', 'GHS', 0.3711, 2.6947);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Guatemalan quetzal', 'GTQ', 0.1613, 6.1996);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Honduran lempira', 'HNL', 0.06017, 16.6196);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hong Kong dollar', 'HKD', 0.162933, 6.137492);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hungarian forint', 'HUF', 0.004621, 216.4034);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Icelandic krona', 'ISK', 0.009551, 104.7011);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indian rupee', 'INR', 0.02024, 49.4071);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indonesian rupiah', 'IDR', 0.000099, 10101.0101);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Israeli new shekel', 'ILS', 0.325, 3.0769);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Jamaican dollar', 'JMD', 0.01094, 91.4077);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Japanese yen', 'JPY', 0.0105, 95.2381);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Malaysian ringgit', 'MYR', 0.3512, 2.8474);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Mexican peso', 'MXN', 0.08365, 11.9546);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Moroccan dirham', 'MAD', 0.1321, 7.57);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Myanmar (Burma) kyat', 'MMK', 0.00123, 813.00813);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Neth. Antilles guilder', 'ANG', 0.7179, 1.393);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'New Zealand dollar', 'NZD', 0.9325, 1.0724);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Norwegian krone', 'NOK', 0.165, 6.0606);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Pakistan rupee', 'PKR', 0.01246, 80.2568);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Panamanian balboa', 'PAB', 1.2635, 0.7915);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Peruvian new sol', 'PEN', 0.4083, 2.4492);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Philippine peso', 'PHP', 0.02841, 35.1989);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Polish zloty', 'PLN', 0.3387, 2.9525);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Romanian new leu', 'RON', 0.3211, 3.1143);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Russian ruble', 'RUB', 0.01909, 52.3834);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Serbian dinar', 'RSD', 0.01171, 85.3971);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Singapore dollar', 'SGD', 0.9282, 1.0774);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South African rand', 'ZAR', 0.1065, 9.3897);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South Korean won', 'KRW', 0.001139, 877.9631);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Sri Lanka rupee', 'LKR', 0.009507, 105.1857);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swedish krona', 'SEK', 0.1506, 6.6401);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swiss franc', 'CHF', 1.3599, 0.7353);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Taiwanese new dollar', 'TWD', 0.03995, 25.0313);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Thai baht', 'THB', 0.03867, 25.8598);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Trinidad and Tobago dollar', 'TTD', 0.1995, 5.0125);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Tunisian dinar', 'TND', 0.654, 1.5291);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Turkish lira', 'TRY', 0.505, 1.9802);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.A.E. dirham', 'AED', 0.344, 2.907);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.K. pound sterling', 'GBP', 1.9243, 0.5197);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Venezuelan bolivar fuerte', 'VEF', 0.2006, 4.985);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Vietnamese dong', 'VND', 0.000059, 16949.1525);
    end;

    local procedure WriteCanadianXMLCurrencyExchRatesDay5(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date)
    begin
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.S. dollar', 'USD', 1.2462, 0.8024);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Argentine peso', 'ARS', 0.1436, 6.9638);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Australian dollar', 'AUD', 0.9672, 1.0339);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Bahamian dollar', 'BSD', 1.2462, 0.8024);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Brazilian real', 'BRL', 0.4414, 2.2655);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFA franc', 'XAF', 0.002167, 461.4675);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'CFP franc', 'XPF', 0.01191, 83.9631);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chilean peso', 'CLP', 0.002003, 499.2511);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Chinese renminbi', 'CNY', 0.1996, 5.01);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Colombian peso', 'COP', 0.000522, 1915.7088);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Croatian kuna', 'HRK', 0.1844, 5.423);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Czech Republic koruna', 'CZK', 0.05145, 19.4363);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Danish krone', 'DKK', 0.191, 5.2356);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'East Caribbean dollar', 'XCD', 0.4633, 2.1584);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'European Euro', 'EUR', 1.4217, 0.7034);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Fiji dollar', 'FJD', 0.6104, 1.6383);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Ghanaian cedi', 'GHS', 0.3655, 2.736);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Guatemalan quetzal', 'GTQ', 0.1591, 6.2854);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Honduran lempira', 'HNL', 0.05934, 16.852);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hong Kong dollar', 'HKD', 0.16069, 6.223163);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Hungarian forint', 'HUF', 0.004649, 215.1);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Icelandic krona', 'ISK', 0.009492, 105.3519);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indian rupee', 'INR', 0.02008, 49.8008);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Indonesian rupiah', 'IDR', 0.000097, 10309.2784);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Israeli new shekel', 'ILS', 0.3206, 3.1192);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Jamaican dollar', 'JMD', 0.01078, 92.7644);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Japanese yen', 'JPY', 0.0105, 95.2381);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Malaysian ringgit', 'MYR', 0.3455, 2.8944);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Mexican peso', 'MXN', 0.08368, 11.9503);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Moroccan dirham', 'MAD', 0.1314, 7.6104);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Myanmar (Burma) kyat', 'MMK', 0.00121, 826.44628);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Neth. Antilles guilder', 'ANG', 0.7081, 1.4122);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'New Zealand dollar', 'NZD', 0.9295, 1.0758);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Norwegian krone', 'NOK', 0.1628, 6.1425);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Pakistan rupee', 'PKR', 0.01229, 81.367);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Panamanian balboa', 'PAB', 1.2462, 0.8024);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Peruvian new sol', 'PEN', 0.4055, 2.4661);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Philippine peso', 'PHP', 0.02813, 35.5492);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Polish zloty', 'PLN', 0.3407, 2.9351);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Romanian new leu', 'RON', 0.321, 3.1153);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Russian ruble', 'RUB', 0.01903, 52.5486);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Serbian dinar', 'RSD', 0.01171, 85.3971);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Singapore dollar', 'SGD', 0.9193, 1.0878);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South African rand', 'ZAR', 0.1066, 9.3809);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'South Korean won', 'KRW', 0.001131, 884.1733);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Sri Lanka rupee', 'LKR', 0.00937, 106.7236);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swedish krona', 'SEK', 0.148, 6.7568);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Swiss franc', 'CHF', 1.3423, 0.745);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Taiwanese new dollar', 'TWD', 0.03979, 25.1319);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Thai baht', 'THB', 0.03818, 26.1917);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Trinidad and Tobago dollar', 'TTD', 0.1965, 5.0891);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Tunisian dinar', 'TND', 0.6482, 1.5427);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Turkish lira', 'TRY', 0.5051, 1.9798);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.A.E. dirham', 'AED', 0.3393, 2.9472);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'U.K. pound sterling', 'GBP', 1.9165, 0.5218);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Venezuelan bolivar fuerte', 'VEF', 0.1978, 5.0556);
        InsertCanadianExchRateLine(OutStream, CurrExchRate, Date, 'Vietnamese dong', 'VND', 0.000059, 16949.1525);
    end;

    local procedure WriteCanadianXMLCurrencyFooter(var OutStream: OutStream)
    begin
        CurrExchRateFileMgt.WriteCanadianXMLFooter(OutStream);
    end;

    local procedure InsertECBExchRateLine(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date; CurrencyCode: Code[10]; Rate: Decimal)
    begin
        InsertCurrency(CurrencyCode, '');
        InsertCurrencyExchRate(CurrExchRate, CurrencyCode, Date, Rate);

        CurrExchRateFileMgt.WriteECB_XMLExchLine(OutStream, CurrencyCode, Rate);
    end;

    local procedure InsertExchRateLine(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date; CurrencyCode: Code[10]; CurrencyName: Text; Rate: Decimal)
    begin
        InsertCurrency(CurrencyCode, CurrencyName);
        InsertCurrencyExchRate(CurrExchRate, CurrencyCode, Date, Rate);

        CurrExchRateFileMgt.WriteDanishXMLExchLine(OutStream, CurrencyCode, CurrencyName, Rate, true);
    end;

    local procedure InsertXE_ExchRateLine(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date; CurrencyCode: Code[10]; CurrencyName: Text; Rate: Decimal; InverseRate: Decimal)
    begin
        InsertCurrency(CurrencyCode, CurrencyName);
        InsertCurrencyExchRate(CurrExchRate, CurrencyCode, Date, Rate);

        CurrExchRateFileMgt.WriteXE_XMLExchLine(OutStream, CurrencyCode, CurrencyName, Rate, InverseRate);
    end;

    local procedure InsertCanadianExchRateLine(var OutStream: OutStream; var CurrExchRate: Record "Currency Exchange Rate"; Date: Date; CurrencyName: Text; CurrencyCode: Code[10]; Rate: Decimal; InverseRate: Decimal)
    begin
        InsertCurrency(CurrencyCode, CurrencyName);
        InsertCurrencyExchRate(CurrExchRate, CurrencyCode, Date, Rate);

        CurrExchRateFileMgt.WriteCanadianXMLExchLine(OutStream, CurrencyCode, CurrencyName, Rate, InverseRate, Date);
    end;

    local procedure InsertCurrency(CurrencyCode: Code[10]; CurrencyName: Text)
    var
        Currency: Record Currency;
    begin
        if not Currency.Get(CurrencyCode) then begin
            Currency.Init();
            Currency.Validate(Code, CurrencyCode);
            Currency.Validate(Description, CopyStr(CurrencyName, 1, MaxStrLen(Currency.Description)));
            Currency.Insert();
        end;
    end;

    local procedure InsertCurrencyExchRate(var CurrExchRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; Date: Date; Rate: Decimal)
    begin
        if Rate = 0 then
            exit;
        CurrExchRate.Init();
        CurrExchRate.Validate("Currency Code", CurrencyCode);
        CurrExchRate.Validate("Starting Date", Date);

        CurrExchRate.Validate("Relational Exch. Rate Amount", CurrExchRateFileMgt.GetRelationalExhangeRate());
        CurrExchRate.Validate("Exchange Rate Amount", Rate);

        CurrExchRate.Validate("Relational Adjmt Exch Rate Amt", CurrExchRate."Relational Exch. Rate Amount");
        CurrExchRate.Validate("Adjustment Exch. Rate Amount", Rate);
        CurrExchRate.Insert();
    end;

    local procedure CreateExchDef(DataExchDefCode: Code[20]; FileType: Option; ReadingWritingCodeunit: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if DataExchDef.Get(DataExchDefCode) then
            DataExchDef.Delete(true);

        DataExchDef.Init();
        DataExchDef.Validate(Code, DataExchDefCode);
        DataExchDef.Validate("File Type", FileType);
        DataExchDef.Validate("Reading/Writing Codeunit", ReadingWritingCodeunit);
        DataExchDef.Insert(true);
    end;

    local procedure CreateExchLineDef(var DataExchLineDef: Record "Data Exch. Line Def"; DataExchDefCode: Code[20]; RepeaterPath: Text[250])
    begin
        DataExchLineDef.Init();
        DataExchLineDef.Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.Validate(Code, DataExchDefCode);
        DataExchLineDef.Validate("Data Line Tag", RepeaterPath);
        DataExchLineDef.Insert(true);
    end;

    local procedure CreateExchMappingHeader(DataExchLineDef: Record "Data Exch. Line Def")
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.Init();
        DataExchMapping.Validate("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchMapping.Validate("Table ID", CurrExchRateFileMgt.GetMappingTable());
        DataExchMapping.Validate("Mapping Codeunit", CurrExchRateFileMgt.GetMappingCodeunit());
        DataExchMapping.Insert(true);
    end;

    local procedure CreateExchMappingLine(DataExchMapping: Record "Data Exch. Mapping"; FromColumnName: Text[250]; ToFieldNo: Integer; DataType: Option; NewMultiplier: Decimal; NewTransformationCode: Code[20]; NewDefaultValue: Text[250])
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        if NewDefaultValue <> '' then begin
            if DataExchColumnDef.FindLast() then begin
                DataExchColumnDef.Init();
                DataExchColumnDef."Column No." += 10000;
                DataExchColumnDef.Insert();
            end
        end else begin
            DataExchColumnDef.SetRange(Name, FromColumnName);
            DataExchColumnDef.FindFirst();
        end;
        DataExchColumnDef.Validate("Data Type", DataType);
        DataExchColumnDef.Modify(true);

        DataExchFieldMapping.Init();
        DataExchFieldMapping.Validate("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.Validate("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.Validate("Table ID", DataExchMapping."Table ID");
        DataExchFieldMapping.Validate("Column No.", DataExchColumnDef."Column No.");
        DataExchFieldMapping.Validate("Field ID", ToFieldNo);
        DataExchFieldMapping.Validate(Multiplier, NewMultiplier);
        DataExchFieldMapping.Validate("Transformation Rule", NewTransformationCode);
        DataExchFieldMapping.Validate("Default Value", NewDefaultValue);
        DataExchFieldMapping.Insert(true);
    end;

    local procedure CreateECBCurrencyExchRateFile(var CurrExchRate: Record "Currency Exchange Rate"; Date: Date) ResultFileName: Text
    var
        FileMgt: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ResultFileName := FileMgt.ServerTempFileName('.xml');
        File.Create(ResultFileName);
        File.CreateOutStream(OutStream);

        WriteECBCurrencyToStream(OutStream, CurrExchRate, Date);

        File.Close();
    end;

    local procedure CreateDanishCurrencyExchRateFile(var CurrExchRate: Record "Currency Exchange Rate") ResultFileName: Text
    var
        FileMgt: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ResultFileName := FileMgt.ServerTempFileName('.xml');
        File.Create(ResultFileName);
        File.CreateOutStream(OutStream);

        WriteDanishCurrencyToStream(OutStream, CurrExchRate);

        File.Close();
    end;

    local procedure CreateEmptyCurrencyExchRateFile() ResultFileName: Text
    var
        FileMgt: Codeunit "File Management";
        File: File;
    begin
        ResultFileName := FileMgt.ServerTempFileName('.xml');
        File.Create(ResultFileName);
        File.Close();
    end;

    local procedure CreateXE_CurrencyExchRateFile(var CurrExchRate: Record "Currency Exchange Rate") ResultFileName: Text
    var
        FileMgt: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ResultFileName := FileMgt.ServerTempFileName('.xml');
        File.Create(ResultFileName);
        File.CreateOutStream(OutStream);

        WriteXE_CurrencyToStream(OutStream, CurrExchRate);

        File.Close();
    end;

    local procedure CreateCanadianCurrencyExchRateFile(var CurrExchRate: Record "Currency Exchange Rate") ResultFileName: Text
    var
        FileMgt: Codeunit "File Management";
        File: File;
        OutStream: OutStream;
    begin
        ResultFileName := FileMgt.ServerTempFileName('.xml');
        File.Create(ResultFileName);
        File.CreateOutStream(OutStream);

        WriteCanadianCurrencyToStream(OutStream, CurrExchRate);

        File.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetGetFileStructureHandler(var GetFileStructure: TestRequestPage "Get File Structure")
    var
        CurrencyExchRateFile: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyExchRateFile);
        GetFileStructure.FilePath.SetValue(CurrencyExchRateFile);
        GetFileStructure.OK().Invoke();
    end;

    local procedure VerifyCurrExchRates(var ExpectedCurrExchRate: Record "Currency Exchange Rate")
    var
        ActualCurrExchRate: Record "Currency Exchange Rate";
    begin
        ExpectedCurrExchRate.FindSet();
        ActualCurrExchRate.FindSet();
        repeat
            Assert.AreEqual(ExpectedCurrExchRate."Currency Code", ActualCurrExchRate."Currency Code", 'Wrong Currency Code');
            Assert.AreEqual(ExpectedCurrExchRate."Starting Date", ActualCurrExchRate."Starting Date", 'Wrong Starting Date');

            Assert.AreEqual(ExpectedCurrExchRate."Exchange Rate Amount", ActualCurrExchRate."Exchange Rate Amount", 'Wrong Exchange Rate Amount');
            Assert.AreEqual(
              ExpectedCurrExchRate."Relational Exch. Rate Amount", ActualCurrExchRate."Relational Exch. Rate Amount", 'Wrong Relational Exch. Rate Amount');
            Assert.AreEqual(
              ExpectedCurrExchRate."Adjustment Exch. Rate Amount", ActualCurrExchRate."Adjustment Exch. Rate Amount", 'Wrong Adjustment Exch. Rate Amount');
            Assert.AreEqual(
              ExpectedCurrExchRate."Relational Adjmt Exch Rate Amt", ActualCurrExchRate."Relational Adjmt Exch Rate Amt",
              'Wrong Relational Adjmt Exch Rate Amt');
            Assert.AreEqual(ExpectedCurrExchRate."Fix Exchange Rate Amount", ActualCurrExchRate."Fix Exchange Rate Amount", 'Wrong Fix Exchange Rate Amount');

            ExpectedCurrExchRate.Delete();
            if ExpectedCurrExchRate.Next() <> 0 then;
        until ActualCurrExchRate.Next() = 0;
    end;

    local procedure VerifyCurrExchRateOnPage(var CurrencyExchangeRates: TestPage "Currency Exchange Rates"; ExpectedCode: Code[10]; ExpectedExchangeRateAmount: Decimal; ExpectedStartingDate: Date; ExpectedRelationalExchRateAmount: Decimal)
    begin
        Assert.AreEqual(ExpectedCode, CurrencyExchangeRates."Currency Code".Value, 'Wrong code value was mapped for the first record');
        Assert.AreEqual(ExpectedExchangeRateAmount, CurrencyExchangeRates."Exchange Rate Amount".AsDecimal(), 'Wrong exchange rate amount was provided');
        Assert.AreEqual(ExpectedStartingDate, CurrencyExchangeRates."Starting Date".AsDate(), 'Wrong date was provided');
        Assert.AreEqual(ExpectedRelationalExchRateAmount, CurrencyExchangeRates."Relational Exch. Rate Amount".AsDecimal(), 'Wrong Amount was provided');
    end;

    local procedure VerifyCurrExchRatesOnPage(var CurrencyExchangeRates: TestPage "Currency Exchange Rates"; ExpectedExchangeRateAmount: Decimal; ExpectedStartingDate: Date)
    begin
        CurrencyExchangeRates.First();
        VerifyCurrExchRateOnPage(CurrencyExchangeRates, 'AUD', ExpectedExchangeRateAmount, ExpectedStartingDate, 527.74);
        CurrencyExchangeRates.Next();
        VerifyCurrExchRateOnPage(CurrencyExchangeRates, 'CAD', ExpectedExchangeRateAmount, ExpectedStartingDate, 543.73);
        CurrencyExchangeRates.Next();
        VerifyCurrExchRateOnPage(CurrencyExchangeRates, 'CHF', ExpectedExchangeRateAmount, ExpectedStartingDate, 713.92);
        CurrencyExchangeRates.Next();
        VerifyCurrExchRateOnPage(CurrencyExchangeRates, 'EUR', ExpectedExchangeRateAmount, ExpectedStartingDate, 746.97);
        CurrencyExchangeRates.Next();
        VerifyCurrExchRateOnPage(CurrencyExchangeRates, 'USD', ExpectedExchangeRateAmount, ExpectedStartingDate, 694.27);
        CurrencyExchangeRates.Next();
        Assert.AreEqual('', CurrencyExchangeRates."Currency Code".Value, 'Unexpected currency code at the end of the list.');
        Assert.IsFalse(CurrencyExchangeRates.Next(), 'Unexpected currency code at the end of the list.');
    end;

    local procedure VerifyExpectedNodeInGeneratedXmlStructure(var SelectSource: TestPage "Select Source"; NodeNameTxt: Text)
    begin
        Assert.IsTrue(SelectSource.FindFirstField(Name, NodeNameTxt), StrSubstNo(ExpectedSourceFieldNotFoundErr, NodeNameTxt));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSourceModalPageHandler(var SelectSource: TestPage "Select Source")
    var
        NodeName: Variant;
        NodeNameTxt: Text;
    begin
        LibraryVariableStorage.Dequeue(NodeName);
        NodeNameTxt := NodeName;

        SelectSource.FILTER.SetFilter(Name, NodeNameTxt);

        SelectSource.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrencyExchangeRateFieldListVerifier(var FieldsLookup: TestPage "Fields Lookup")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Currency Code")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Starting Date")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Exchange Rate Amount")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Adjustment Exch. Rate Amount")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Relational Currency Code")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Relational Exch. Rate Amount")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Fix Exchange Rate Amount")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
        Assert.IsTrue(FieldsLookup.FindFirstField(FieldName, CurrencyExchangeRate.FieldCaption("Relational Adjmt Exch Rate Amt")),
          ExpectedCurrencyExchRateFieldNotFoundErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSourceVerifierForDanishExchangeRateFile(var SelectSource: TestPage "Select Source")
    begin
        VerifyExpectedNodeInGeneratedXmlStructure(SelectSource, 'exchangerates');
        VerifyExpectedNodeInGeneratedXmlStructure(SelectSource, 'dailyrates');
        VerifyExpectedNodeInGeneratedXmlStructure(SelectSource, 'currency');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConsentConfirmYes(var CustConsentConfirmation: TestPage "Cust. Consent Confirmation")
    begin
        CustConsentConfirmation.Accept.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;
}

