codeunit 144150 "Periodic VAT Pmt. Comm. Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [VAT Payment Communication]
    end;

    var
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        VATPmtCommXMLGenerator: Codeunit "VAT Pmt. Comm. XML Generator";
        FileManagement: Codeunit "File Management";
        LibraryVerifyXMLSchema: Codeunit "Library - Verify XML Schema";
        VATPmtCommDataLookup: Codeunit "VAT Pmt. Comm. Data Lookup";
        PeriodicVATPmtCommTests: Codeunit "Periodic VAT Pmt. Comm. Tests";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        Initialized: Boolean;
        MethodOfCalcAdvancedRef: Option "No advance",Historical,Budgeting,Analytical,"Specific Subjects";
        ModuleNumberRef: Option ,"1","2","3","4","5";
        SpecifyMethodOfCalcAdvancedAmountErr: Label 'You must select a calculation method for advanced amounts.';
        ModuleNumberBlankErr: Label 'You must enter a module number.';
        WrongCaptionErr: Label 'Wrong caption.';

    [Test]
    [Scope('OnPrem')]
    procedure TestTagsMeseTrimestre()
    var
        XmlDoc: DotNet XmlDocument;
    begin
        // [SCENARIO] For every Modulo tag either Mese tag is present or Trimestre tag is.
        Initialize();
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        VerifyTagsCount(XmlDoc, 'Mese', 'Trimestre');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoMoreThanFiveModuloTags()
    var
        XmlDoc: DotNet XmlDocument;
        FoundXMLNodeList: DotNet XmlNodeList;
    begin
        // [SCENARIO] There are at maximum 5 Modulo tags (xsd validation does not capture this).
        Initialize();
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        FoundXMLNodeList := XmlDoc.GetElementsByTagName('Modulo');

        Assert.IsTrue(FoundXMLNodeList.Count > 0, 'There was no Modulo Tag.');
        Assert.IsTrue(FoundXMLNodeList.Count <= 5, 'There were more than 5 Modulo Tags.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTagCFDichiarante()
    var
        FoundXMLNodeList: DotNet XmlNodeList;
        XmlDoc: DotNet XmlDocument;
        CFDichiaranteCount: Integer;
    begin
        // [SCENARIO] Tag CodiceCaricaDichiarante must be present if Tag CodiceCaricaDichiarante is present.
        Initialize();
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        FoundXMLNodeList := XmlDoc.GetElementsByTagName('CFDichiarante');
        CFDichiaranteCount := FoundXMLNodeList.Count();

        FoundXMLNodeList := XmlDoc.GetElementsByTagName('CodiceCaricaDichiarante');
        Assert.IsTrue(
          FoundXMLNodeList.Count = CFDichiaranteCount,
          'Tag CodiceCaricaDichiarante must be present if Tag CodiceCaricaDichiarante is present.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTagCFIntermediario()
    var
        XmlDoc: DotNet XmlDocument;
        CFIntermediarioCount: Integer;
    begin
        // [SCENARIO] Tag DataImpegno must be present if Tag CFIntermediario is present.
        // [SCENARIO] Tag FirmaIntermediario must be present if Tag CFIntermediario is present.
        Initialize();
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        CFIntermediarioCount := XmlDoc.GetElementsByTagName('CFIntermediario').Count();

        Assert.IsTrue(
          XmlDoc.GetElementsByTagName('DataImpegno').Count = CFIntermediarioCount,
          'Tag DataImpegno must be present if Tag CFIntermediario is present.');
        Assert.IsTrue(
          XmlDoc.GetElementsByTagName('FirmaIntermediario').Count = CFIntermediarioCount,
          'Tag FirmaIntermediario must be present if Tag CFIntermediario is present.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTagsIVA()
    var
        XmlDoc: DotNet XmlDocument;
        TotalSales: Decimal;
        TotalPurchases: Decimal;
        TotalSalesTax: Decimal;
        TotalPurchaseTax: Decimal;
    begin
        // [SCENARIO] Either IvaDovuta tag or IvaCredito tag is present
        Initialize();
        PopulateVATEntryTable(DMY2Date(1, 10, 2017), TotalSales, TotalPurchases, TotalSalesTax, TotalPurchaseTax);
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        VerifyTagsCount(XmlDoc, 'IvaDovuta', 'IvaCredito');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestTagsImporto()
    var
        XmlDoc: DotNet XmlDocument;
        TotalSales: Decimal;
        TotalPurchases: Decimal;
        TotalSalesTax: Decimal;
        TotalPurchaseTax: Decimal;
    begin
        // [SCENARIO] Either ImportoDaVersare tag or ImportoACredito tag is present
        Initialize();
        PopulateVATEntryTable(DMY2Date(1, 10, 2017), TotalSales, TotalPurchases, TotalSalesTax, TotalPurchaseTax);
        VATPmtCommXMLGenerator.CreateXml(XmlDoc);

        VerifyTagsCount(XmlDoc, 'ImportoACredito', 'ImportoDaVersare');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecimalToText()
    begin
        // [SCENARIO] Test the function to represent the decimal in the correct format
        Assert.AreEqual('15235,23', VATPmtCommXMLGenerator.DecimalToText(15235.23), 'Numeral compliance');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestLookup()
    var
        CompanyOfficials: Record "Company Officials";
        AppointmentCode: Record "Appointment Code";
        CompanyInformation: Record "Company Information";
        VATReportSetup: Record "VAT Report Setup";
        VATPaymentCommunication: Report "VAT Payment Communication";
        StartDate: Date;
        DestinationPath: Text;
        SchemaPath: Text;
        SignatureSchemaPath: Text;
        Message: Text;
        TotalSales: Decimal;
        TotalPurchases: Decimal;
        TotalSalesTax: Decimal;
        TotalPurchaseTax: Decimal;
    begin
        // [SCENARIO] The data returned from the lookup methods are correct
        Initialize();
        BindSubscription(PeriodicVATPmtCommTests);
        // [GIVEN] Initialize the instance
        VATPmtCommDataLookup.Init();

        // [WHEN] Set the parameters on the instance
        StartDate := DMY2Date(1, 10, 2018);
        VATPmtCommDataLookup.SetStartDate(StartDate);
        VATPmtCommDataLookup.SetYearOfDeclaration(18);

        // [GIVEN] VAT entry records are present
        PopulateVATEntryTable(StartDate, TotalSales, TotalPurchases, TotalSalesTax, TotalPurchaseTax);

        // [THEN] Check the return values
        Assert.AreEqual('IVP18', VATPmtCommDataLookup.GetSupplyCode(), 'GetSupplyCode incorrect');
        Assert.AreEqual('', VATPmtCommDataLookup.GetSystemID(), 'GetSystemID incorrect');
        Assert.IsFalse(VATPmtCommDataLookup.HasTaxDeclarant(), 'HasTaxDeclarant incorrect');
        Assert.IsFalse(VATPmtCommDataLookup.HasChargeCode(), 'HasChargeCode incorrect');
        Assert.AreEqual('2018', VATPmtCommDataLookup.GetCurrentYear(), 'GetCurrentYear incorrect');
        Assert.AreEqual(TotalSales, VATPmtCommDataLookup.GetTotalSales(),
          'GetTotalSales incorrect');
        Assert.AreEqual(TotalPurchases, VATPmtCommDataLookup.GetTotalPurchases(),
          'GetTotalPurchases incorrect');
        Assert.AreEqual(TotalSalesTax, VATPmtCommDataLookup.GetVATSales(),
          'GetVATSales incorrect');
        Assert.AreEqual(TotalPurchaseTax, VATPmtCommDataLookup.GetVATPurchases(),
          'GetVATPurchases incorrect');
        Assert.AreEqual('4', VATPmtCommDataLookup.GetQuarter(), 'GetQuarter incorrect');

        // [WHEN] Setting values for HasCodiceFiscaleDichiarante & related nodes
        VATPmtCommDataLookup.SetTaxDeclarant('28051977200');
        VATPmtCommDataLookup.SetChargeCode('12');

        // [THEN] Check the return values
        Assert.IsTrue(VATPmtCommDataLookup.HasTaxDeclarant(), 'HasTaxDeclarant incorrect');
        Assert.IsTrue(VATPmtCommDataLookup.HasChargeCode(), 'HasChargeCode incorrect');

        // [WHEN] General manager parameters
        CompanyOfficials.Init();
        CompanyOfficials."No." := 'GM';
        CompanyOfficials."Fiscal Code" := '28051977200';
        AppointmentCode.Init();
        AppointmentCode.Code := '15';
        AppointmentCode.Insert();
        CompanyOfficials."Appointment Code" := AppointmentCode.Code;
        CompanyOfficials.Insert();
        CompanyInformation."General Manager No." := CompanyOfficials."No.";
        CompanyInformation."Fiscal Code" := '28051977200';
        CompanyInformation."VAT Registration No." := '28051977200';
        CompanyInformation.Modify();
        VATPmtCommDataLookup.Init();

        // [THEN] Check Dichirante
        Assert.AreEqual('28051977200', VATPmtCommDataLookup.GetDeclarantFiscalCode(), 'GetTaxDeclarant incorrect');
        Assert.AreEqual(AppointmentCode.Code, VATPmtCommDataLookup.GetTaxDeclarantPosionCode(),
          'GetTaxDeclarantPosionCode incorrect');

        // [WHEN] Intermmediaries parameters
        SetIntermediaryValuesInVATReportSetup();
        VATReportSetup.Get();
        VATReportSetup.Modify();
        VATPmtCommDataLookup.Init();

        // [THEN] Check intermmediaries
        Assert.IsTrue(VATPmtCommDataLookup.HasIntermediary(), 'HasIntermediary incorrect');
        Assert.AreEqual('28051977200', VATPmtCommDataLookup.GetIntermediary(), 'GetIntermediary incorrect');
        Assert.AreEqual(Format(VATReportSetup."Intermediary Date", 0, '<Day,2><Month,2><Year4>'),
          VATPmtCommDataLookup.GetIntermediaryDate(), 'GetIntermediaryDate incorrect');

        // [WHEN] Running the XML generator with the above data
        DestinationPath := FileManagement.ServerTempFileName('xml');
        VATPaymentCommunication.InitializeRequest(StartDate, Date2DMY(StartDate, 3) - 2000, '28051977200',
          VATPmtCommDataLookup.GetChargeCode(), false,
          0, false,
          true, false,
          1, false, 0, 1, DestinationPath);
        VATPaymentCommunication.UseRequestPage(false);
        VATPaymentCommunication.Run();

        // [THEN] XML generated conforms to the XSD
        SignatureSchemaPath := GetInetRoot() + '\GDL\IT\App\Test\XMLSchemas\xmldsig-core-schema.xsd';
        LibraryVerifyXMLSchema.SetAdditionalSchemaPath(SignatureSchemaPath);
        SchemaPath := GetInetRoot() + '\GDL\IT\App\Test\XMLSchemas\fornituraIvp_2018_v1.xsd';
        Assert.IsTrue(LibraryVerifyXMLSchema.VerifyXMLAgainstSchema(DestinationPath, SchemaPath, Message), Message);
        UnbindSubscription(PeriodicVATPmtCommTests);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetFirstDateOfQuarter()
    var
        VATPmtCommXMLGenerator: Codeunit "VAT Pmt. Comm. XML Generator";
        Result: Date;
    begin
        // [SCENARIO] Because of a platform issue 217749, a workaround was created to get to the first date in a quarter

        // [WHEN] The given date is 12 June
        Result := VATPmtCommXMLGenerator.GetFirstDateOfQuarter(DMY2Date(12, 6, 2017));

        // [THEN] The first date is 01 April
        Assert.AreEqual(DMY2Date(1, 4, 2017), Result, 'The first date of the quarter for 12 June is 01 Apr');

        // [WHEN] The given date is 01 Oct
        Result := VATPmtCommXMLGenerator.GetFirstDateOfQuarter(DMY2Date(1, 10, 2017));

        // [THEN] The first date of the quarter is 01 Oct
        Assert.AreEqual(DMY2Date(1, 10, 2017), Result, 'The first date of the quarter for 01 Oct is itself');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPmtCommDataLookup_GetTotalSales()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntryDate: Date;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223234] COD 12151 "VAT Pmt. Comm. Data Lookup".GetTotalSales() returns sum of positive VATEntry."Base" excluding Reverse Charge VAT
        Initialize();
        VATEntryDate := CalcDate('<-CM+1M>', GetLastVATEntryOpOccrDate());
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Four VAT Entries having Type = "Settlement":
        // [GIVEN] "Base" = 100000, "Amount" = 10000, "VAT Calculation Type" = "Normal VAT"
        // [GIVEN] "Base" = -10000, "Amount" = -1000, "VAT Calculation Type" = "Normal VAT"
        // [GIVEN] "Base" =   1000, "Amount" =   100, "VAT Calculation Type" = "Reverse Charge VAT"
        // [GIVEN] "Base" =   -100, "Amount" =   -10, "VAT Calculation Type" = "Reverse Charge VAT"
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -100000, -50000, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, 10000, 4000, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -1000, -300, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, 100, 20, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Perform COD 12151 "VAT Pmt. Comm. Data Lookup".GetTotalSales/GetTotalPurchases/GetVATSales/GetVATPurchases/GetVATDebit/GetVATCredit

        // [THEN] System returns following result:
        // [THEN] GetTotalSales() = 100000
        // [THEN] GetTotalPurchases() = 10100
        // [THEN] GetVATSales() = 50300
        // [THEN] GetVATPurchases() = 4020
        // [THEN] GetVATDebit() = 46280
        // [THEN] GetVATCredit() = 0
        Assert.AreEqual(DecimalToText(100000), DecimalToText(VATPmtCommDataLookup.GetTotalSales()), '');
        Assert.AreEqual(10100, VATPmtCommDataLookup.GetTotalPurchases(), '');
        Assert.AreEqual(50300, VATPmtCommDataLookup.GetVATSales(), '');
        Assert.AreEqual(4020, VATPmtCommDataLookup.GetVATPurchases(), '');
        Assert.AreEqual(46280, VATPmtCommDataLookup.GetVATDebit(), '');
        Assert.AreEqual(0, VATPmtCommDataLookup.GetVATCredit(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPaymentCommunicationReport_TotalSales_ReverseCharge()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntryDate: Date;
        FileName: Text;
    begin
        // [FEATURE] [Report] [UT]
        // [SCENARIO 223234] REP 12150 "VAT Payment Communication" exports "TotaleOperazioniAttive" = sum of positive VATEntry."Base" excluding Reverse Charge VAT
        Initialize();
        VATEntryDate := CalcDate('<-CY+1Y>', GetLastVATEntryOpOccrDate());
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Four VAT Entries having Type = "Settlement":
        // [GIVEN] "Base" = 100000, "Amount" = 10000, "VAT Calculation Type" = "Normal VAT"
        // [GIVEN] "Base" = -10000, "Amount" = -1000, "VAT Calculation Type" = "Normal VAT"
        // [GIVEN] "Base" =   1000, "Amount" =   100, "VAT Calculation Type" = "Reverse Charge VAT"
        // [GIVEN] "Base" =   -100, "Amount" =   -10, "VAT Calculation Type" = "Reverse Charge VAT"
        CreateVATEntryWithVATPostingSetup(VATEntry,
          VATPostingSetup, VATEntry.Type::Sale, -100000, -50000, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(VATEntry,
          VATPostingSetup, VATEntry.Type::Purchase, 10000, 4000, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(VATEntry,
          VATPostingSetup, VATEntry.Type::Sale, -1000, -300, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetup(VATEntry,
          VATPostingSetup, VATEntry.Type::Purchase, 100, 20, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] XML has been exported with following values:
        // [THEN] "TotaleOperazioniAttive" = 100000
        // [THEN] "TotaleOperazioniPassive" = 10100
        // [THEN] "IvaEsigibile" = 50300
        // [THEN] "IvaDetratta" = 4020
        // [THEN] "IvaDovuta" = 46280
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniAttive', DecimalToText(100000));
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniPassive', DecimalToText(10100));
        LibraryXMLRead.VerifyNodeValue('IvaEsigibile', DecimalToText(50300));
        LibraryXMLRead.VerifyNodeValue('IvaDetratta', DecimalToText(4020));
        LibraryXMLRead.VerifyNodeValue('IvaDovuta', DecimalToText(46280));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATPaymentCommunicationReport_IvaDovuta_FullVAT()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntryDate: Date;
        SalesVATAmount: Decimal;
        PurchVATAmount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 224532] Check XML when "VAT Calculation Type" = "Full VAT", "Deductible %" = 100
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        SalesVATAmount := LibraryRandom.RandDec(1000, 2);
        PurchVATAmount := -SalesVATAmount / 2;
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Two VAT Entries having Type = "Settlement":
        // [GIVEN] "Base" = 0, "Amount" = 1000, "VAT Calculation Type" = "Full VAT"
        // [GIVEN] "Base" = 0, "Amount" = -500, "VAT Calculation Type" = "Full VAT"
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, 0, -SalesVATAmount, VATEntryDate, VATEntry."VAT Calculation Type"::"Full VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, 0, -PurchVATAmount, VATEntryDate, VATEntry."VAT Calculation Type"::"Full VAT");

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] XML has been exported with following values:
        // [THEN] "IvaDovuta" = 500
        // [THEN] "ImportoDaVersare" = 500
        // [THEN] Sales VAT Amount = 1000
        // [THEN] Purchase VAT Amount = -500
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('IvaDovuta', DecimalToText(SalesVATAmount + PurchVATAmount));
        LibraryXMLRead.VerifyNodeValue('ImportoDaVersare', DecimalToText(SalesVATAmount + PurchVATAmount));
        Assert.AreEqual(SalesVATAmount, VATPmtCommDataLookup.GetVATSales(), 'Incorrect Sales VAT Amount');
        Assert.AreEqual(-PurchVATAmount, VATPmtCommDataLookup.GetVATPurchases(), 'Incorrect Purchase VAT Amount');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATPaymentCommunicationReport_IvaDovuta_DifferentVATCalculationTypes()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntryDate: Date;
        Amount: array[5] of Decimal;
        Base: array[5] of Decimal;
        TotalVATAmount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 224532] Check XML when "VAT Calculation Type" differ in lines, one of lines has "VAT Calculation Type" = "Full VAT", "Deductible %" = 100
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        PrepareVATBaseAndAmountArray(Amount, Base);
        TotalVATAmount := Amount[1] + Amount[2] + Amount[3] + Amount[4] + Amount[5];
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] Five VAT Entries having Type = "Settlement":
        // [GIVEN] "Base" = 0, "Amount" = 1000, "VAT Calculation Type" = "Full VAT"
        // [GIVEN] "Base" = 100000, "Amount" = 50000, "VAT Calculation Type" = "Normal VAT" for sales
        // [GIVEN] "Base" = -10000, "Amount" = -4000, "VAT Calculation Type" = "Normal VAT" for purchase
        // [GIVEN] "Base" =   1000, "Amount" =   300, "VAT Calculation Type" = "Reverse Charge VAT" for sales
        // [GIVEN] "Base" =   -100, "Amount" =   -20, "VAT Calculation Type" = "Reverse Charge VAT" for purchase
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -Base[1], -Amount[1],
          VATEntryDate, VATEntry."VAT Calculation Type"::"Full VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -Base[2], -Amount[2],
          VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -Base[3], -Amount[3],
          VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, -Base[4], -Amount[4],
          VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, -Base[5], -Amount[5],
          VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] XML has been exported with following values:
        // [THEN] "TotaleOperazioniAttive" = 100000
        // [THEN] "TotaleOperazioniPassive" = 10100
        // [THEN] "IvaEsigibile" = 50300 + SalesVATAmount = 51300
        // [THEN] "IvaDetratta" = 4020
        // [THEN] "IvaDovuta" = 46280 + SalesVATAmount = 47280
        // [THEN] "ImportoDaVersare" = 46280 + SalesVATAmount = 47280
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniAttive', DecimalToText(Base[1] + Base[2] + Base[3]));
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniPassive', DecimalToText(-Base[4] - Base[5]));
        LibraryXMLRead.VerifyNodeValue('IvaEsigibile', DecimalToText(Amount[1] + Amount[2] + Amount[3]));
        LibraryXMLRead.VerifyNodeValue('IvaDetratta', DecimalToText(-Amount[4] - Amount[5]));
        LibraryXMLRead.VerifyNodeValue('IvaDovuta', DecimalToText(TotalVATAmount));
        LibraryXMLRead.VerifyNodeValue('ImportoDaVersare', DecimalToText(TotalVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPmtCommReportExcludeBaseWhenVATAmountEqZero()
    var
        VATEntry: Record "VAT Entry";
        VATEntryDate: Date;
        Base: array[5] of Decimal;
        FileName: Text;
    begin
        // [SCENARIO 232382] TotaleOperazioniAttive and TotaleOperazioniPassive must absent in communication XML when "Include in VAT Comm. Rep." in VAT Posting Setup is disabled and VAT Amount = 0
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        PrepareVATBaseArray(Base);
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Entries
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 2, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = -2, Amount = 0 for sales
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 4, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = -4, Amount = 0 for sales
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 8, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = -8, Amount = 0 for sales
        CreateVATEntry(VATEntry, VATEntry.Type::Purchase, Base[3], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntry(VATEntry, VATEntry.Type::Sale, -Base[3], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntry(VATEntry, VATEntry.Type::Purchase, Base[4], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntry(VATEntry, VATEntry.Type::Sale, -Base[4], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntry(VATEntry, VATEntry.Type::Purchase, Base[5], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");
        CreateVATEntry(VATEntry, VATEntry.Type::Sale, -Base[5], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] TotaleOperazioniAttive and TotaleOperazioniPassive nodes absent
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeAbsence('TotaleOperazioniAttive');
        LibraryXMLRead.VerifyNodeAbsence('TotaleOperazioniPassive');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPmtCommReportIncludeBaseWhenVATAmountEqZeroAndIncludeInVATCommRepInVATPostingSetup()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntryDate: Date;
        Base: array[5] of Decimal;
        FileName: Text;
    begin
        // [SCENARIO 232382] TotaleOperazioniAttive and TotaleOperazioniPassive must exist in communication XML when "Include in VAT Comm. Rep." in VAT Posting Setup is enabled and VAT Amount = 0
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        PrepareVATBaseArray(Base);
        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [GIVEN] VAT Entries
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 2, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = -2, Amount = 0 for sales
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 4, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = -4, Amount = 0 for sales
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 8, Amount = 0 for purchases
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = -8, Amount = 0 for sales
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, Base[3], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, -Base[3], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, -Base[4], 0,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, Base[4], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, -Base[5], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, Base[5], 0, VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] TotaleOperazioniAttive = 11: "Normal VAT" + "Sales Tax" Bases
        // [THEN] TotaleOperazioniPassive = 15: "Normal VAT" + "Reverse Charge VAT" + "Sales Tax" Bases
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniAttive', DecimalToText(Base[3] - Base[5]));
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniPassive', DecimalToText(Base[3] - Base[4] - Base[5]));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenValidateInclInVATCommRepForNormalVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Error when trying validate "Include in VAT Comm. Rep." in VAT Posting Setup with "VAT Calculation Type" = "Normal VAT" and "VAT %" <> 0
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "Normal VAT" and "VAT %" <> 0
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(10));

        // [WHEN] Set "Include in VAT Comm. Rep." = TRUE
        VATPostingSetup.Validate("Include in VAT Comm. Rep.", true);

        // [THEN] (252305) "Include in VAT Comm. Rep." is TRUE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenValidateInclInVATCommRepForReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Error when trying validate "Include in VAT Comm. Rep." in VAT Posting Setup with "VAT Calculation Type" = "Reverse Charge VAT" and "VAT %" <> 0
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "Reverse Charge VAT" and "VAT %" <> 0
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", LibraryRandom.RandInt(10));

        // [WHEN] Set "Include in VAT Comm. Rep." = TRUE
        VATPostingSetup.Validate("Include in VAT Comm. Rep.", true);

        // [THEN] (252305) "Include in VAT Comm. Rep." is TRUE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateInclInVATCommRepForNormalVATAndZeroVATPercent()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Error when trying validate "Include in VAT Comm. Rep." in VAT Posting Setup with "VAT Calculation Type" = "Normal VAT" and "VAT %" = 0
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "Normal VAT" and "VAT %" = 0
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [WHEN] Set "Include in VAT Comm. Rep." = TRUE
        VATPostingSetup.Validate("Include in VAT Comm. Rep.", true);

        // [THEN] "Include in VAT Comm. Rep." is TRUE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateInclInVATCommRepForReverseChargeVATAndZeroVATPercent()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Error when trying validate "Include in VAT Comm. Rep." in VAT Posting Setup with "VAT Calculation Type" = "Reverse Charge VAT" and "VAT %" = 0
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Calculation Type" = "Reverse Charge VAT" and "VAT %" = 0
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 0);

        // [WHEN] Set "Include in VAT Comm. Rep." = TRUE
        VATPostingSetup.Validate("Include in VAT Comm. Rep.", true);

        // [THEN] "Include in VAT Comm. Rep." is TRUE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateIncludeInVATCommRepFieldWhenChangeVATPercent()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Untick "Include in VAT Comm. Rep." in VAT Posting Setup when "VAT %" was changed from 0
        Initialize();

        // [GIVEN] VAT Posting Setup with ticked "Include in VAT Comm. Rep." and "VAT %" = 0
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [WHEN] Set "VAT %" = 10
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));

        // [THEN] "Include in VAT Comm. Rep." = FALSE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateIncludeInVATCommRepFieldWhenChangeVATCalculationType()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 232382] Untick "Include in VAT Comm. Rep." in VAT Posting Setup when "VAT Calculation Type" was validated with "Sales Tax"
        Initialize();

        // [GIVEN] VAT Posting Setup with ticked "Include in VAT Comm. Rep." and ""VAT Calculation Type" "Normal VAT"
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        // [WHEN] Set "VAT Calculation Type" = "Sales Tax"
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");

        // [THEN] "Include in VAT Comm. Rep." = FALSE
        VATPostingSetup.TestField("Include in VAT Comm. Rep.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SettlementLinesMustNotBeExported()
    var
        Amount: Decimal;
        Base: Decimal;
        FileName: Text;
        VATEntryDate: Date;
    begin
        // [SCENARIO 252305] Settlement VAT Entries must not be exported in VAT Settlement Communication report
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        Amount := LibraryRandom.RandDec(1000, 2);
        Base := LibraryRandom.RandDec(1000, 2);

        // [GIVEN] VAT Entries with different VAT Calculation Types for sales with "Include in VAT Comm. Rep." disabled in "VAT Posting Setup"
        // [GIVEN] VAT Entries with different VAT Calculation Types for purchases with "Include in VAT Comm. Rep." disabled in "VAT Posting Setup"
        Create4SettlementVATEntryWithDifferentVATCalculationType(Amount, Base, VATEntryDate);
        Create4SettlementVATEntryWithDifferentVATCalculationType(-Amount, -Base, VATEntryDate);

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] Check absence of nodes TotaleOperazioniAttive, TotaleOperazioniPassive, IvaEsigibile, IvaDetratta, IvaDovuta, ImportoDaVersare
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeAbsence('TotaleOperazioniAttive');
        LibraryXMLRead.VerifyNodeAbsence('TotaleOperazioniPassive');
        LibraryXMLRead.VerifyNodeAbsence('IvaEsigibile');
        LibraryXMLRead.VerifyNodeAbsence('IvaDetratta');
        LibraryXMLRead.VerifyNodeAbsence('IvaDovuta');
        LibraryXMLRead.VerifyNodeAbsence('ImportoDaVersare');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportWithNonDeductiblePurchaseVATAmount()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        Amount: array[5] of Decimal;
        Base: array[5] of Decimal;
        DeductiblePercent: Decimal;
        FileName: Text;
        VATEntryDate: Date;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 252548] Export VAT Payment Communication Report for purchase with non-deductible VAT amount
        Initialize();
        VATEntryDate := CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate());
        PrepareVATBaseAndAmountArray(Amount, Base);

        // [GIVEN] VAT Posting Setup "VPS1" with "Include in VAT Comm. Rep." enabled, "VAT %" = 20, "Deductible %" = 70
        DeductiblePercent := LibraryRandom.RandDecInDecimalRange(0.01, 0.99, 2);
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        UpdateVATPostingSetupDeductible(VATPostingSetup, DeductiblePercent);

        // [GIVEN] VAT Posting Setup "VPS2" with "Include in VAT Comm. Rep." enabled, "VAT %" = 20, "Deductible %" = 0
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup2, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        UpdateVATPostingSetupDeductible(VATPostingSetup2, 0);

        // [GIVEN] Purchase VAT Entries with "VAT Prod. Posting group" = "VPS1"
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 70, Amount = 14, "Nondeductible Base" = 30, "Nondeductible Amount" = 6
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 70, Amount = 14, "Nondeductible Base" = 30, "Nondeductible Amount" = 6
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 70, Amount = 14, "Nondeductible Base" = 30, "Nondeductible Amount" = 6
        // [GIVEN] "VAT Calculation Type" = "Full VAT", Base = 0, Amount = 14, "Nondeductible Base" = 0, "Nondeductible Amount" = 6
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, Amount[2], Base[2], DeductiblePercent, VATEntryDate, VATEntry.Type::Purchase);

        // [GIVEN] Purchase VAT Entries with "VAT Prod. Posting group" = "VPS2"
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 0, Amount = 0, "Nondeductible Amount" = 100, "Nondeductible Base" = 20
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 0, Amount = 0, "Nondeductible Amount" = 100, "Nondeductible Base" = 20
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 0, Amount = 0, "Nondeductible Amount" = 100, "Nondeductible Base" = 20
        // [GIVEN] "VAT Calculation Type" = "Full VAT", Base = 0, Amount = 0, "Nondeductible Amount" = 100, "Nondeductible Base" = 20
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup2, Amount[3], Base[3], 0, VATEntryDate, VATEntry.Type::Purchase);

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(VATEntryDate);

        // [THEN] TotaleOperazioniPassive = 600
        // [THEN] TotaleOperazioniPassive includes "Normal VAT" + "Reverse Charge VAT" + "Sales Tax" Nondeductible and deductible bases
        // [THEN] IvaDetratta = 56 = 14 * 4
        // [THEN] IvaDetratta includes "Normal VAT" + "Reverse Charge VAT" + "Sales Tax" + "Full VAT" deductible amounts
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniPassive', DecimalToText(Base[2] * 3 + Base[3] * 3));
        LibraryXMLRead.VerifyNodeValue('IvaDetratta', DecimalToText(Amount[2] * 4 * DeductiblePercent));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportFor3Months()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: array[5] of Decimal;
        Base: array[5] of Decimal;
        FileName: Text;
        VATEntryDate: Date;
    begin
        // [SCENARIO 255474] Amounts for the second and third months must not contain amounts for the previous months.
        Initialize();
        VATEntryDate := VATPmtCommXMLGenerator.GetFirstDateOfQuarter(CalcDate('<CY+1Y>', GetLastVATEntryOpOccrDate()));
        PrepareVATBaseAndAmountArray(Amount, Base);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);

        // [GIVEN] 4 VAT lines for purchases and for sales at January
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 100, Amount = 20
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 100, Amount = 20
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 100, Amount = 20
        // [GIVEN] "VAT Calculation Type" = "Full VAT", Base = 100, Amount = 20
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, Amount[2], Base[2], 1, VATEntryDate, VATEntry.Type::Purchase);
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, -Amount[2], -Base[2], 1, VATEntryDate, VATEntry.Type::Sale);

        // [GIVEN] 4 VAT lines for purchases and for sales at February
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 200, Amount = 40
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 200, Amount = 40
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 200, Amount = 40
        // [GIVEN] "VAT Calculation Type" = "Full VAT", Base = 200, Amount = 40
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, Amount[3], Base[3], 1, CalcDate('<CM+1D>', VATEntryDate), VATEntry.Type::Purchase);
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, -Amount[3], -Base[3], 1, CalcDate('<CM+1D>', VATEntryDate), VATEntry.Type::Sale);

        // [GIVEN] 4 VAT lines for purchases and for sales at March
        // [GIVEN] "VAT Calculation Type" = "Normal VAT", Base = 300, Amount = 60
        // [GIVEN] "VAT Calculation Type" = "Reverse Charge VAT", Base = 300, Amount = 60
        // [GIVEN] "VAT Calculation Type" = "Sales Tax", Base = 300, Amount = 60
        // [GIVEN] "VAT Calculation Type" = "Full VAT", Base = 300, Amount = 60
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, -Amount[4], -Base[4], 1, CalcDate('<CM+1M+1D>', VATEntryDate), VATEntry.Type::Purchase);
        Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(
          VATPostingSetup, Amount[4], Base[4], 1, CalcDate('<CM+1M+1D>', VATEntryDate), VATEntry.Type::Sale);

        // [WHEN] Export "VAT Payment Communication"
        FileName := RunVATPaymentCommunicationRep(CalcDate('<CM+2M>', VATEntryDate));
        LibraryXMLRead.Initialize(FileName);

        // [THEN] The file contans next TotaleOperazioniAttive, TotaleOperazioniPassive, IvaEsigibile, IvaDetratta 3 times
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('TotaleOperazioniAttive'), '');
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('TotaleOperazioniPassive'), '');
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('IvaEsigibile'), '');
        Assert.AreEqual(3, LibraryXMLRead.GetNodesCount('IvaDetratta'), '');

        // [THEN] The values for the first month contain of amounts posted at January
        // [THEN] TotaleOperazioniAttive = 200 - Sales VAT Base
        // [THEN] TotaleOperazioniPassive = 300 - Purchases VAT Base
        // [THEN] IvaEsigibile = 80 - Sales VAT Amount
        // [THEN] IvaDetratta = 80 - Purchases VAT Amount
        VerifyVATAmountAndBase(Base[2] * 2, Base[2] * 3, Amount[2] * 4, Amount[2] * 4, 1);

        // [THEN] The values for the first month contain of amounts posted at February
        // [THEN] TotaleOperazioniAttive = 400 - Sales VAT Base
        // [THEN] TotaleOperazioniPassive = 600 - Purchases VAT Base
        // [THEN] IvaEsigibile = 160 - Sales VAT Amount
        // [THEN] IvaDetratta = 160 - Purchases VAT Amount
        VerifyVATAmountAndBase(Base[3] * 2, Base[3] * 3, Amount[3] * 4, Amount[3] * 4, 2);

        // [THEN] The values for the first month contain of amounts posted at March
        // [THEN] TotaleOperazioniAttive = 600 - Sales VAT Base
        // [THEN] TotaleOperazioniPassive = 900 - Purchases VAT Base
        // [THEN] IvaEsigibile = 240 - Sales VAT Amount
        // [THEN] IvaDetratta = 240 - Purchases VAT Amount
        VerifyVATAmountAndBase(-Base[4] * 2, -Base[4] * 3, -Amount[4] * 4, -Amount[4] * 4, 3);

        // [THEN] 'Mese' tag is exported for month, 'Trimestre' is not exported (TFS 270793)
        // [THEN] 'NumeroModulo' tag is exported sequentially for each month (TFS 270742)
        Verify3MonthXMLTags(VATEntryDate, ModuleNumberRef::"1");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterWithAdvancedAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntryDate: Date;
        StartDate: Date;
        Amount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 264706] Mandatory tags on quarter export of VAT Communication report 2018 with advanced amount
        Initialize();

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);
        VATEntryDate := CalcDate('<+1Q>', GetLastVATEntryOpOccrDate());
        StartDate := CalcDate('<-CQ>', VATEntryDate);

        // [GIVEN] Periodic Settlement VAT Entry has "Advanced Amount" = 100
        MockPeriodicVATSettlementEntry(CalcDate('<1Q - 1D>', StartDate));

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        // [GIVEN] Three VAT enties with the same VAT Base = 150 on 01-01-18, 31-03-18, and 450 on 15-04-18
        Amount := LibraryRandom.RandDec(10000, 2);
        CreateThreeVATEntriesInsideAndOutQuarter(VATEntryDate, Amount);

        // [GIVEN] Use parameters: Extraordinary Operations = Yes, Method Of Calc Advanced = Analytical, Module Number = '1', Signed = Yes
        // [WHEN] Run "VAT Payment Communication"
        FileName :=
          RunVATPaymentCommunicationRepExtended(StartDate, true, MethodOfCalcAdvancedRef::Analytical, ModuleNumberRef::"1", true);
        LibraryXMLRead.Initialize(FileName);

        // [THEN] ModuleNumber is exported as '1'
        // [THEN] Method is exported as '3' (Analytical) with Advanced Amount = 100
        // [THEN] Extraordinary Operation is exported as '1'
        // [THEN] Total VAT Base is exported for 2 operations as 300 (150 + 150)
        // [THEN] 'Trimestre' tag is exported for quarter, 'Mese' is not exported (TFS 270793)
        // [THEN] 'FirmaDichiarazione' tag is exported as '1' (TFS 272151)
        LibraryXMLRead.VerifyNodeValue('NumeroModulo', ModuleNumberRef::"1");
        LibraryXMLRead.VerifyNodeValue('Metodo', MethodOfCalcAdvancedRef::Analytical);
        LibraryXMLRead.VerifyNodeValue('Acconto', DecimalToText(GetAdvancedAmountFromPeriodicVATEntry(CalcDate('<1Q - 1D>', StartDate))));
        LibraryXMLRead.VerifyNodeValue('OperazioniStraordinarie', '1');
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniAttive', DecimalToText(-Amount * 2));
        LibraryXMLRead.VerifyNodeValue('Trimestre', Format(StartDate, 0, '<Quarter>'));
        LibraryXMLRead.VerifyNodeAbsence('Mese');
        LibraryXMLRead.VerifyNodeValue('FirmaDichiarazione', '1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterWithoutAdvancedAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntryDate: Date;
        StartDate: Date;
        Amount: Decimal;
        FileName: Text;
    begin
        // [SCENARIO 264706] Mandatory tags on quarter export of VAT Communication report 2018 without advanced amount
        Initialize();

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);
        VATEntryDate := CalcDate('<+1Q>', GetLastVATEntryOpOccrDate());
        StartDate := CalcDate('<-CQ>', VATEntryDate);

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        // [GIVEN] Three VAT enties with the same VAT Base = 150 on 01-01-18, 31-03-18, and 450 on 15-04-18
        Amount := LibraryRandom.RandDec(10000, 2);
        CreateThreeVATEntriesInsideAndOutQuarter(VATEntryDate, Amount);

        // [GIVEN] Use parameters: Extraordinary Operations = Yes, Method Of Calc Advanced = Analytical, Module Number = '1', Signed = No
        // [WHEN] Run "VAT Payment Communication"
        FileName :=
          RunVATPaymentCommunicationRepExtended(StartDate, false, MethodOfCalcAdvancedRef::"No advance", ModuleNumberRef::"1", false);
        LibraryXMLRead.Initialize(FileName);

        // [THEN] ModuleNumber is exported as '1'
        // [THEN] tags for Method and Advanced Amount are not exported
        // [THEN] Extraordinary Operation is exported as '0'
        // [THEN] Total VAT Base is exported for 2 operations as 300 (150 + 150)
        // [THEN] 'Trimestre' tag is exported for quarter, 'Mese' is not exported (TFS 270793)
        // [THEN] 'FirmaDichiarazione' tag is exported as '0' (TFS 272151)
        LibraryXMLRead.VerifyNodeValue('NumeroModulo', ModuleNumberRef::"1");
        LibraryXMLRead.VerifyNodeAbsence('Metodo');
        LibraryXMLRead.VerifyNodeAbsence('Acconto');
        LibraryXMLRead.VerifyNodeValue('OperazioniStraordinarie', '0');
        LibraryXMLRead.VerifyNodeValue('TotaleOperazioniAttive', DecimalToText(-Amount * 2));
        LibraryXMLRead.VerifyNodeValue('Trimestre', Format(StartDate, 0, '<Quarter>'));
        LibraryXMLRead.VerifyNodeAbsence('Mese');
        LibraryXMLRead.VerifyNodeValue('FirmaDichiarazione', '0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterWithAdvancedAmountNoMethod()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VATEntryDate: Date;
        StartDate: Date;
    begin
        // [SCENARIO 264706] Advanced Amount cannot be exported with blank method of calculation in VAT Communication report
        Initialize();

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);
        VATEntryDate := CalcDate('<+1Q>', GetLastVATEntryOpOccrDate());
        StartDate := CalcDate('<-CQ>', VATEntryDate);

        // [GIVEN] Periodic Settlement VAT Entry has "Advanced Amount" = 100
        MockPeriodicVATSettlementEntry(CalcDate('<1Q - 1D>', StartDate));

        // [GIVEN] VAT Entry for VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(20, 2));
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, LibraryRandom.RandDec(10000, 2), 0,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Run "VAT Payment Communication"
        asserterror
          RunVATPaymentCommunicationRepExtended(StartDate, false, MethodOfCalcAdvancedRef::"No advance", ModuleNumberRef::"1", false);

        // [THEN] Error raised: Specify method of calculation of advanced amount
        Assert.ExpectedError(SpecifyMethodOfCalcAdvancedAmountErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterNoModuleNumber()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        VATEntryDate: Date;
        StartDate: Date;
    begin
        // [SCENARIO 264706] Report cannot be exported with blank module number in VAT Communication report
        Initialize();

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);
        VATEntryDate := CalcDate('<+1Q>', GetLastVATEntryOpOccrDate());
        StartDate := CalcDate('<-CQ>', VATEntryDate);

        // [GIVEN] Periodic Settlement VAT Entry has "Advanced Amount" = 100
        MockPeriodicVATSettlementEntry(CalcDate('<1Q - 1D>', StartDate));

        // [GIVEN] VAT Entry for VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(20, 2));
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, LibraryRandom.RandDec(10000, 2), 0,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");

        // [WHEN] Run "VAT Payment Communication"
        asserterror
          RunVATPaymentCommunicationRepExtended(StartDate, false, MethodOfCalcAdvancedRef::"No advance", 0, false);

        // [THEN] Error raised: You have to choose Module Number
        Assert.ExpectedError(ModuleNumberBlankErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('VATCommReportReqPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyControlsOnReqPageOfVATCommReport()
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 264706] Controls on VAT Communication report request page are accessible
        Initialize();
        Commit();
        REPORT.Run(REPORT::"VAT Payment Communication");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterWithPriorPeriodInputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        FileName: Text;
        PrevPeriodVATAmount: Decimal;
        CurrPeriodVATAmount: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO 366707] Run "Periodic VAT Payment Communication" report in case VAT Settlement with nonzero VAT was calculated for the previous quarter.
        Initialize();
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup.
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);

        // [GIVEN] Purchase Invoice with VAT Amount = "VA1", that was posted in a quarter Q2.
        // [GIVEN] Report "Calc. And Post VAT Settlement" was run for the quarter Q2.
        StartDate := CalcDate('<CQ + 1D>', LibraryERM.MaxDate(GetLastVATEntryOpOccrDate(), GetLastVATSettlementEndDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        PrevPeriodVATAmount := CreateAndPostPurchaseInvoiceWithVAT(VATPostingSetup, StartDate);
        RunCalcAndPostVATSettlementReport(VATPostingSetup, StartDate, EndDate);

        // [GIVEN] Purchase Invoice with VAT Amount = "VA2", that was posted in the next quarter Q3.
        // [GIVEN] Report "Calc. And Post VAT Settlement" was run for the quarter Q3.
        StartDate := EndDate + 1;
        EndDate := CalcDate('<CQ>', StartDate);
        CurrPeriodVATAmount := CreateAndPostPurchaseInvoiceWithVAT(VATPostingSetup, StartDate);
        RunCalcAndPostVATSettlementReport(VATPostingSetup, StartDate, EndDate);

        // [WHEN] Run "Periodic VAT Payment Communication" report for Q3; VAT settlement ending date = 30.09.22, it is the last day of the quarter Q3.
        FileName := RunVATPaymentCommunicationRep(EndDate);

        // [THEN] XML file is created. It contains tag CreditoPeriodoPrecedente with value "VA1", it is VAT Settlement for the previous quarter Q2.
        // [THEN] Tag ImportoACredito has value "VA1" + "VA2".
        LibraryXPathXMLReader.Initialize(FileName, 'urn:www.agenziaentrate.gov.it:specificheTecniche:sco:ivp');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//Comunicazione/DatiContabili/Modulo/CreditoPeriodoPrecedente', DecimalToText(PrevPeriodVATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//Comunicazione/DatiContabili/Modulo/IvaCredito', DecimalToText(CurrPeriodVATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//Comunicazione/DatiContabili/Modulo/ImportoACredito', DecimalToText(PrevPeriodVATAmount + CurrPeriodVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportVATPmtCommReportQuarterWithoutPriorPeriodInputVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        FileName: Text;
        CurrPeriodVATAmount: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO 366707] Run "Periodic VAT Payment Communication" report in case VAT Settlement with zero VAT was calculated for the previous quarter.
        Initialize();
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] VAT Settlement Period is Quarter in General Ledger Setup.
        UpdateGLSetupWithVATPeriod(GeneralLedgerSetup."VAT Settlement Period"::Quarter);

        // [GIVEN] "Periodic Settlement VAT Entry" record with "VAT Settlement" = 0 for a quarter Q2.
        StartDate := CalcDate('<CQ + 1D>', LibraryERM.MaxDate(GetLastVATEntryOpOccrDate(), GetLastVATSettlementEndDate()));
        EndDate := CalcDate('<CQ>', StartDate);
        MockPeriodicVATSettlementEntry(EndDate);

        // [GIVEN] Purchase Invoice with VAT Amount = "VA1", that was posted in the next quarter Q3.
        // [GIVEN] Report "Calc. And Post VAT Settlement" was run for the quarter Q3.
        StartDate := EndDate + 1;
        EndDate := CalcDate('<CQ>', StartDate);
        CurrPeriodVATAmount := CreateAndPostPurchaseInvoiceWithVAT(VATPostingSetup, StartDate);
        RunCalcAndPostVATSettlementReport(VATPostingSetup, StartDate, EndDate);

        // [WHEN] Run "Periodic VAT Payment Communication" report for Q3; VAT settlement ending date = 30.09.22, it is the last day of the quarter Q3.
        FileName := RunVATPaymentCommunicationRep(EndDate);

        // [THEN] XML file is created. It does not contain tag CreditoPeriodoPrecedente.
        // [THEN] Tag ImportoACredito has value "VA1".
        LibraryXPathXMLReader.Initialize(FileName, 'urn:www.agenziaentrate.gov.it:specificheTecniche:sco:ivp');
        LibraryXPathXMLReader.VerifyNodeAbsence('//Comunicazione/DatiContabili/Modulo/CreditoPeriodoPrecedente');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//Comunicazione/DatiContabili/Modulo/IvaCredito', DecimalToText(CurrPeriodVATAmount));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '//Comunicazione/DatiContabili/Modulo/ImportoACredito', DecimalToText(CurrPeriodVATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CFIntermediarioNodeExportsInsteadOfCodicefiscaleSocietaNodeWhenIntermediaryOptionUsed()
    var
        LocalVATPmtCommDataLookup: Codeunit "VAT Pmt. Comm. Data Lookup";
        LocalVATPmtCommXMLGenerator: Codeunit "VAT Pmt. Comm. XML Generator";
        XmlDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 405053] A "CFIntermediarioNode" xml node exports instead of "CodicefiscaleSocieta" node when "Intermediary" option is used

        Initialize();

        SetIntermediaryValuesInVATReportSetup();
        LocalVATPmtCommDataLookup.Init();
        LocalVATPmtCommDataLookup.SetStartDate(WorkDate());
        LocalVATPmtCommDataLookup.SetIsIntermediary(true);
        LocalVATPmtCommXMLGenerator.SetVATPmtCommDataLookup(LocalVATPmtCommDataLookup);
        LocalVATPmtCommXMLGenerator.CreateXml(XmlDoc);

        Assert.AreEqual(0, XmlDoc.GetElementsByTagName('CodicefiscaleSocieta').Count, '');
        Assert.AreEqual(1, XmlDoc.GetElementsByTagName('CFIntermediario').Count, '');
    end;

    [Scope('OnPrem')]
    procedure Initialize()
    begin
        Clear(VATPmtCommDataLookup);
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;

        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(DMY2Date(1, 10, 2017));
        VATPmtCommXMLGenerator.SetVATPmtCommDataLookup(VATPmtCommDataLookup);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Initialized := true;
    end;

    local procedure GetInetRoot(): Text
    begin
        exit(ApplicationPath + '\..\..\..\');
    end;

    local procedure PopulateVATEntryTable(StartDate: Date; var TotalSales: Decimal; var TotalPurchases: Decimal; var TotalSalesTax: Decimal; var TotalPurchaseTax: Decimal)
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATEntry.DeleteAll();
        TotalPurchases := 0;
        TotalPurchaseTax := 0;
        TotalSales := 0;
        TotalSalesTax := 0;

        // [GIVEN] VAT Posting Setup with "Include in VAT Comm. Rep." enabled
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);

        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Purchase, 50, 10,
          CalcDate('<-1M>', StartDate), VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetupGetTotal(
          VATPostingSetup, -100, -25, VATEntry.Type::Sale, StartDate + 1, TotalSales, TotalSalesTax, -1);
        CreateVATEntryWithVATPostingSetupGetTotal(
          VATPostingSetup, 450, 100, VATEntry.Type::Purchase, StartDate + 5, TotalPurchases, TotalPurchaseTax, 1);
        CreateVATEntryWithVATPostingSetupGetTotal(
          VATPostingSetup, -1000, -200, VATEntry.Type::Sale, StartDate + 10, TotalSales, TotalSalesTax, -1);
        CreateVATEntryWithVATPostingSetupGetTotal(
          VATPostingSetup, 5000, 500, VATEntry.Type::Purchase, StartDate + 5, TotalPurchases, TotalPurchaseTax, 1);
    end;

    local procedure PrepareVATBaseAndAmountArray(var Amount: array[5] of Decimal; var Base: array[5] of Decimal)
    begin
        Amount[1] := LibraryRandom.RandDec(1000, 2);
        Amount[2] := LibraryRandom.RandDec(1000, 2);
        Amount[3] := LibraryRandom.RandDec(1000, 2);
        Amount[4] := -Amount[1] / 2; // need to get total Amount positive
        Amount[5] := -Amount[2] / 2;
        PrepareVATBaseArray(Base);
    end;

    local procedure PrepareVATBaseArray(var Base: array[5] of Decimal)
    begin
        Base[1] := 0;
        Base[2] := LibraryRandom.RandDec(1000, 2);
        Base[3] := LibraryRandom.RandDec(1000, 2);
        Base[4] := -LibraryRandom.RandDec(1000, 2);
        Base[5] := -LibraryRandom.RandDec(1000, 2);
    end;

    local procedure Create4SettlementVATEntryWithDifferentVATCalculationType(Amount: Decimal; Base: Decimal; VATEntryDate: Date)
    var
        VATEntry: Record "VAT Entry";
    begin
        CreateVATEntry(
          VATEntry, VATEntry.Type::Settlement, Base, Amount, VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntry(
          VATEntry, VATEntry.Type::Settlement, Base, Amount, VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntry(
          VATEntry, VATEntry.Type::Settlement, 0, Amount, VATEntryDate, VATEntry."VAT Calculation Type"::"Full VAT");
        CreateVATEntry(
          VATEntry, VATEntry.Type::Settlement, Base, Amount, VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");
    end;

    local procedure Create4VATEntryWithVATPostingSetupAndDifferentVATCalculationType(VATPostingSetup: Record "VAT Posting Setup"; Amount: Decimal; Base: Decimal; DeductiblePercent: Decimal; VATEntryDate: Date; VATType: Enum "General Posting Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        CreateVATEntryWithVATPostingSetupDeductPercent(
          VATEntry, VATPostingSetup, DeductiblePercent, VATType, Base, Amount,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetupDeductPercent(
          VATEntry, VATPostingSetup, DeductiblePercent, VATType, Base, Amount,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Reverse Charge VAT");
        CreateVATEntryWithVATPostingSetupDeductPercent(
          VATEntry, VATPostingSetup, DeductiblePercent, VATType, 0, Amount,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Full VAT");
        CreateVATEntryWithVATPostingSetupDeductPercent(
          VATEntry, VATPostingSetup, DeductiblePercent, VATType, Base, Amount,
          VATEntryDate, VATEntry."VAT Calculation Type"::"Sales Tax");
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; VATType: Enum "General Posting Type"; VATBase: Decimal; VATAmount: Decimal; OpOccuredDate: Date; VATCalculationType: Enum "Tax Calculation Type")
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATType;
        VATEntry."VAT Calculation Type" := VATCalculationType;
        VATEntry.Base := VATBase;
        VATEntry.Amount := VATAmount;
        VATEntry."Operation Occurred Date" := OpOccuredDate;
        VATEntry.Insert(true);
    end;

    local procedure CreateVATEntryWithVATPostingSetupDeductPercent(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; DeductiblePercent: Decimal; VATType: Enum "General Posting Type"; VATBase: Decimal; VATAmount: Decimal; OpOccuredDate: Date; VATCalculationType: Enum "Tax Calculation Type")
    begin
        CreateVATEntry(VATEntry, VATType, VATBase, VATAmount, OpOccuredDate, VATCalculationType);
        UpdateVATEntryPostingGroups(VATEntry, VATPostingSetup);
        VATEntry."Deductible %" := DeductiblePercent * 100;
        VATEntry.Base := VATBase * DeductiblePercent;
        VATEntry.Amount := VATAmount * DeductiblePercent;
        VATEntry."Nondeductible Base" := VATBase * (1 - DeductiblePercent);
        VATEntry."Nondeductible Amount" := VATAmount * (1 - DeductiblePercent);
        VATEntry.Modify(true);
    end;

    local procedure CreateVATEntryWithVATPostingSetupGetTotal(VATPostingSetup: Record "VAT Posting Setup"; VATBase: Decimal; VATAmount: Decimal; VATEntryType: Enum "General Posting Type"; OpOccuredDate: Date; var TotalSales: Decimal; var TotalSalesTax: Decimal; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntryType, VATBase, VATAmount,
          OpOccuredDate, VATEntry."VAT Calculation Type"::"Normal VAT");
        TotalSales += Sign * VATEntry.Base;
        TotalSalesTax += Sign * VATEntry.Amount;
    end;

    local procedure CreateVATEntryWithVATPostingSetup(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; VATType: Enum "General Posting Type"; VATBase: Decimal; VATAmount: Decimal; OpOccuredDate: Date; VATCalculationType: Enum "Tax Calculation Type")
    begin
        CreateVATEntry(VATEntry, VATType, VATBase, VATAmount, OpOccuredDate, VATCalculationType);
        UpdateVATEntryPostingGroups(VATEntry, VATPostingSetup);
    end;

    local procedure CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATCommRep: Boolean; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType, VATRate);
        VATPostingSetup.Validate("Include in VAT Comm. Rep.", IncludeInVATCommRep);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateThreeVATEntriesInsideAndOutQuarter(VATEntryDate: Date; Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        CreateVATPostingSetupWithAccountsAndIncludeInVATCommRep(
          VATPostingSetup, true, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDec(20, 2));
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, Amount, 0,
          CalcDate('<-CQ>', VATEntryDate), VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, Amount, 0,
          CalcDate('<CQ>', VATEntryDate), VATEntry."VAT Calculation Type"::"Normal VAT");
        CreateVATEntryWithVATPostingSetup(
          VATEntry, VATPostingSetup, VATEntry.Type::Sale, Amount * 3, 0,
          CalcDate('<+1Q>', VATEntryDate), VATEntry."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVAT(VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date) VATAmount: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Document Date", PostingDate);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
    end;

    local procedure GetAdvancedAmountFromPeriodicVATEntry(PeriodDate: Date): Decimal
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntry.Get(GetVATPeriodFromDate(PeriodDate));
        exit(PeriodicSettlementVATEntry."Advanced Amount");
    end;

    local procedure GetLastVATEntryOpOccrDate(): Date
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Operation Occurred Date", Type, "Document Type", "Document No.", "Contract No.");
        VATEntry.FindLast();
        exit(VATEntry."Operation Occurred Date");
    end;

    local procedure GetLastVATSettlementEndDate(): Date
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntry.FindLast();
        exit(GetEndDateFromVATPeriod(PeriodicSettlementVATEntry."VAT Period"));
    end;

    local procedure GetVATPeriodFromDate(PeriodDate: Date): Code[10]
    begin
        exit(Format(Date2DMY(PeriodDate, 3)) + '/' +
          ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0'));
    end;

    local procedure GetEndDateFromVATPeriod(VATPeriod: Code[10]) EndDate: Date
    var
        Year: Integer;
        Month: Integer;
    begin
        Evaluate(Year, CopyStr(VATPeriod, 1, 4));
        Evaluate(Month, CopyStr(VATPeriod, 6, 2));
        EndDate := DMY2Date(1, Month, Year);
        EndDate := CalcDate('<CM>', EndDate);
    end;

    local procedure MockPeriodicVATSettlementEntry(PeriodDate: Date)
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        PeriodicSettlementVATEntry.Init();
        PeriodicSettlementVATEntry."VAT Period" := GetVATPeriodFromDate(PeriodDate);
        PeriodicSettlementVATEntry."Advanced Amount" := LibraryRandom.RandDecInRange(100, 200, 2);
        PeriodicSettlementVATEntry.Insert();
    end;

    local procedure RunVATPaymentCommunicationRep(VATEntryDate: Date) FileName: Text
    var
        VATPaymentCommunication: Report "VAT Payment Communication";
        FileMgt: Codeunit "File Management";
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        Clear(VATPaymentCommunication);
        VATPaymentCommunication.InitializeRequest(VATEntryDate, 0, '', '', false, 0, false, false, false, 0, false, 0, 1, FileName);
        VATPaymentCommunication.UseRequestPage(false);
        VATPaymentCommunication.Run();
    end;

    local procedure RunVATPaymentCommunicationRepExtended(VATEntryDate: Date; ExtraordinaryOperation: Boolean; MetodOfCalcAdvanced: Option; ModuleNumber: Option; IsSigned: Boolean) FileName: Text
    var
        VATPaymentCommunication: Report "VAT Payment Communication";
        FileMgt: Codeunit "File Management";
    begin
        FileName := FileMgt.ServerTempFileName('xml');
        Clear(VATPaymentCommunication);
        VATPaymentCommunication.InitializeRequest(
          VATEntryDate, 0, '', '', IsSigned, 0, false, false, false, 0,
          ExtraordinaryOperation, MetodOfCalcAdvanced, ModuleNumber, FileName);
        VATPaymentCommunication.UseRequestPage(false);
        VATPaymentCommunication.Run();
    end;

    local procedure RunCalcAndPostVATSettlementReport(VATPostingSetup: Record "VAT Posting Setup"; StartDate: Date; PostingDate: Date)
    var
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        VATPostingSetup.SetRecFilter();
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(
          StartDate, PostingDate, PostingDate, LibraryUtility.GenerateGUID(), LibraryERM.CreateGLAccountNo(),
          LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo(), false, true);
        CalcAndPostVATSettlement.UseRequestPage(false);
        CalcAndPostVATSettlement.SaveAsXml('');
    end;

    local procedure SetIntermediaryValuesInVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup."Intermediary Date" := DMY2Date(1, 9, 2018);
        VATReportSetup."Intermediary VAT Reg. No." := '28051977200';
        VATReportSetup.Modify();
    end;

    local procedure UpdateVATEntryPostingGroups(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATEntry.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.Modify(true);
    end;

    local procedure UpdateVATPostingSetupDeductible(var VATPostingSetup: Record "VAT Posting Setup"; Deductible: Decimal)
    begin
        VATPostingSetup.Validate("Deductible %", Deductible);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateGLSetupWithVATPeriod(VATPeriod: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT Settlement Period" := VATPeriod;
        GeneralLedgerSetup.Modify();
    end;

    local procedure DecimalToText(DecimalValue: Decimal): Text
    begin
        exit(Format(DecimalValue, 0, '<Precision,2><Sign><Integer><Decimals><Comma,,>'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application System Constants", 'OnAfterGetApplicationVersion', '', false, false)]
    local procedure OnAfterGetApplicationVersion(var ApplicationVersion: Text[248])
    begin
        ApplicationVersion := '13.01.02';
    end;

    local procedure VerifyTagsCount(XmlDoc: DotNet XmlDocument; Tag1: Text; Tag2: Text)
    var
        ModuloCount: Integer;
        Tag1Count: Integer;
        Tag2Count: Integer;
    begin
        ModuloCount := XmlDoc.GetElementsByTagName('Modulo').Count();
        Tag1Count := XmlDoc.GetElementsByTagName(Tag1).Count();
        Tag2Count := XmlDoc.GetElementsByTagName(Tag2).Count();

        Assert.AreEqual(
          Tag1Count + Tag2Count,
          ModuloCount,
          'For every Modulo tag there is only one ' + Tag1 + ' tag or one ' + Tag2 + ' tag.');
    end;

    local procedure VerifyVATAmountAndBase(TotaleOperazioniAttive: Decimal; TotaleOperazioniPassive: Decimal; IvaEsigibile: Decimal; IvaDetratta: Decimal; Month: Integer)
    begin
        Assert.AreEqual(
          DecimalToText(TotaleOperazioniAttive), LibraryXMLRead.GetNodeValueAtIndex('TotaleOperazioniAttive', Month - 1),
          StrSubstNo('Month %1 - TotaleOperazioniAttive', Month));
        Assert.AreEqual(
          DecimalToText(TotaleOperazioniPassive), LibraryXMLRead.GetNodeValueAtIndex('TotaleOperazioniPassive', Month - 1),
          StrSubstNo('Month %1 - TotaleOperazioniPassive'));
        Assert.AreEqual(
          DecimalToText(IvaEsigibile), LibraryXMLRead.GetNodeValueAtIndex('IvaEsigibile', Month - 1),
          StrSubstNo('Month %1 - IvaEsigibile'));
        Assert.AreEqual(
          DecimalToText(IvaDetratta), LibraryXMLRead.GetNodeValueAtIndex('IvaDetratta', Month - 1),
          StrSubstNo('Month %1 - IvaDetratta'));
    end;

    local procedure Verify3MonthXMLTags(StartDate: Date; StartNumber: Integer)
    var
        i: Integer;
    begin
        for i := 0 to 2 do begin
            Assert.AreEqual(Format(StartNumber + i), LibraryXMLRead.GetNodeValueAtIndex('NumeroModulo', i), '');
            Assert.AreEqual(Format(Date2DMY(StartDate, 2)), LibraryXMLRead.GetNodeValueAtIndex('Mese', i), '');
            StartDate := CalcDate('<-CM+1M>', StartDate);
        end;
        LibraryXMLRead.VerifyNodeAbsence('Trimestre');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATCommReportReqPageHandler(var VATPaymentCommunication: TestRequestPage "VAT Payment Communication")
    var
        ExtraordinaryOperation: Boolean;
    begin
        Evaluate(ExtraordinaryOperation, VATPaymentCommunication.ExtraordinaryOperations.Value);
        VATPaymentCommunication.ExtraordinaryOperations.SetValue(not ExtraordinaryOperation);
        VATPaymentCommunication.MethodOfCalcAdvanced.SetValue(MethodOfCalcAdvancedRef::Budgeting);
        VATPaymentCommunication."Module Number".SetValue(ModuleNumberRef::"2");

        Assert.AreEqual('VAT settlement ending date', VATPaymentCommunication.VATSettlementEndingDate.Caption, WrongCaptionErr);
        Assert.AreEqual('Declarant fiscal code', VATPaymentCommunication.DeclarantFiscalcode.Caption, WrongCaptionErr);
        Assert.AreEqual('Declarant appointment code', VATPaymentCommunication.DeclarantAppointmentCode.Caption, WrongCaptionErr);
        VATPaymentCommunication.YearOfDeclaration.AssertEquals(18); // TFS ID 404191: Years of declaration is "Supply code" which is always equal to "18"

        VATPaymentCommunication.Cancel().Invoke();
    end;
}

