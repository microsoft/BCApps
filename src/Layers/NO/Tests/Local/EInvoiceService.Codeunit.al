codeunit 144111 "E-Invoice Service"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EHF] [Service]
    end;

    var
        Assert: Codeunit Assert;
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        EInvoiceServiceHelper: Codeunit "E-Invoice Service Helper";
        EInvoiceXMLXSDValidation: Codeunit "E-Invoice XML XSD Validation";
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
        NOXMLReadHelper: Codeunit "NO XML Read Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        SchemaDocumentType: Option Invoice,CrMemo,Reminder;
        NoTaxRate: Decimal;
        LowRate: Decimal;
        ReducedRate: Decimal;
        HighRate: Decimal;
        StandardRate: Decimal;
        SuccessfullyCreatedMsg: Label 'Successfully created ';
        TestValueTxt: Label 'Test Value';
        IncorrectFieldValueEInvoiceErr: Label 'Incorrect bool value of field E-Invoice on the Service Header table';
        ChangeBillToCustomerNoQst: Label 'Do you want to change the %1?';
        ExternalDocumentNoErr: Label 'External Document No. should be passed from Service Header to Service Shipment Header.';

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure CreateEInvoiceServInvoiceFile()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        XmlFileName := EInvoiceServInvoice();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServiceInvFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        ServInvHdr: Record "Service Invoice Header";
        XmlFileName: Text[1024];
        ServInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);
        ServInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();
        CompanyInfo.Get();
        ServInvHdr.Get(ServInvoiceNo);

        // exercise
        XmlFileName := ExecEInvoice(ServInvoiceNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, ServInvHdr."Bill-to Name",
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), true); // entRegistered = TRUE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServiceInvFileNoEntReg()
    var
        CompanyInfo: Record "Company Information";
        ServInvHdr: Record "Service Invoice Header";
        XmlFileName: Text[1024];
        ServInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);
        ServInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();
        ServInvHdr.Get(ServInvoiceNo);
        CompanyInfo.Get();

        // exercise
        XmlFileName := ExecEInvoice(ServInvoiceNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, ServInvHdr."Bill-to Name",
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), false); // entRegistered = FALSE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServBBAN()
    var
        BankAccountNo: Text[30];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [BBAN]
        // [SCENARIO 1.4.27] Bank Account, BBAN
        Initialize();

        // [GIVEN] Company information is set up without IBAN
        // [GIVEN] Company information is set up with BBAN
        BankAccountNo := '99-99-888';
        EInvoiceXMLXSDValidation.SetBankInformation(BankAccountNo, '');

        // [GIVEN] A posted Service invoice to export
        XmlFileName := EInvoiceServInvoice();

        // [THEN] IBAN is not present
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "IBAN"]');

        // [THEN] BBAN is present in the XML file under Invoice->PaymentMeans->PayeeFinancialAccount
        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "BBAN"]', DelChr(BankAccountNo, '=', '-'));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServIBAN()
    var
        IBAN: Code[50];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [IBAN]
        // [SCENARIO 1.4.27] Bank Account, IBAN
        Initialize();

        // [GIVEN] Company information is set up with IBAN
        IBAN := 'GB 12 CPBK 08929965044991';
        EInvoiceXMLXSDValidation.SetBankInformation('', IBAN);
        // [GIVEN] Company information is set up without BBAN

        // [GIVEN] A posted Service invoice to export
        XmlFileName := EInvoiceServInvoice();

        // [THEN] IBAN is present in the XML file under Invoice->PaymentMeans->PayeeFinancialAccount
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "IBAN"]', IBAN);

        // [THEN] BBAN is not present
        NOXMLReadHelper.VerifyNodeAbsence('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "BBAN"]');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServIBANAndBBAN()
    var
        AccountList: DotNet XmlNodeList;
        BankAccountNo: Text[30];
        IBAN: Code[50];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [IBAN] [BBAN]
        // [SCENARIO 1.4.27] Bank Account, Both IBAN and BBAN
        Initialize();

        // [GIVEN] Company information is set up with both IBAN and BBAN
        BankAccountNo := '99-99-888';
        IBAN := 'GB 12 CPBK 08929965044991';
        EInvoiceXMLXSDValidation.SetBankInformation(BankAccountNo, IBAN);

        // [GIVEN] A posted Service invoice to export
        XmlFileName := EInvoiceServInvoice();

        // [THEN] Both IBAN and BBAN are present in the XML file under Invoice->PaymentMeans->PayeeFinancialAccount
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "IBAN"]', IBAN);
        NOXMLReadHelper.VerifyNodeValueByXPath(
          'cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "BBAN"]', DelChr(BankAccountNo, '=', '-'));

        // [THEN] BBAN is located BEFORE IBAN
        NOXMLReadHelper.GetNodeList('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID', AccountList);

        Assert.AreEqual(2, AccountList.Count, 'Number of PayeeFinancialAccounts does not match.');
        NOXMLReadHelper.VerifyAttributeFromNode(AccountList.Item(0), 'schemeID', 'BBAN');
        NOXMLReadHelper.VerifyAttributeFromNode(AccountList.Item(1), 'schemeID', 'IBAN');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServiceInvDeliveryLocationOnLine()
    var
        XMLFileName: Text;
        ServiceInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] Validate the child nodes of 'Delivery', on the Invoice Lines
        Initialize();

        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();
        XMLFileName := ExecEInvoice(ServiceInvoiceNo);

        VerifyDeliveryOnServiceInvoice(XMLFileName, 'cac:InvoiceLine/cac:Delivery/cac:DeliveryLocation/cac:Address', ServiceInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServInvEndpointID()
    begin
        // [FEATURE] [Invoice]
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceServInvoice());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServInvHeaderFixedValueAttributes()
    var
        ServiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.10] Fixed value attributes added: CurrencyCode, InvoiceTypeCode, PaymentMeansCode, SchemaId
        Initialize();

        // [GIVEN] A posted service invoice
        ServiceNo := EInvoiceServiceHelper.CreateServiceInvoice();

        // [WHEN] Posted service invoice is exported
        XmlFileName := ExecEInvoice(ServiceNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header contains attributes: CurrencyCode,InvoiceTypeCode,PaymentMeansCode,SchemaId
        EInvoiceXMLXSDValidation.VerifyDocumentCurrencyCode(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyInvoiceTypeCode(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyPaymentMeansCode(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyTaxCategorySchemaIdAttribute(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyIdentificationCode(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServiceInvInvoicedQuantity()
    var
        ServiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.10] Fixed value attributes added for InvoicedQuantity: unitCode, unitCodeListID.
        Initialize();

        // [GIVEN] A posted service invoice
        ServiceNo := EInvoiceServiceHelper.CreateServiceInvoice();

        // [WHEN] Posted service invoice is exported
        XmlFileName := ExecEInvoice(ServiceNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header element InvoicedQuantity contains attributes: unitCode and listID
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCode', EInvoiceHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCodeListID', 'UNECERec20');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccCostCodeAddedInServInv()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        XmlFileName := EInvoiceServInvoice();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeValue('//cbc:AccountingCost', Format(TestValueTxt));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceForeignCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceNo: Code[20];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [FCY]
        // [SCENARIO 1.4.10] Foreign currency exchange rate information is added to the service invoice
        Initialize();

        // [GIVEN] A service invoice to export in a foreign currency with Tax Exchange Rate = X
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceInForeignCurrency(ServiceHeader."Document Type"::Invoice);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(ServiceInvoiceNo);

        // [THEN] Validate all foreign currency nodes are added with correct values
        EInvoiceXMLXSDValidation.VerifyForeignCurrencyNodes(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceAccountingParty()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        SalesInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] AccountingSupplierParty, AccountingCustomerParty and Delivery (on the header) contain the updated UBL 2.1 xml
        // [SCENARIO] namely the AddressType used in PostalAddress and Delivery Address is changed, as well as the Customer Contact
        // [SCENARIO] additionally a node has been removed: AccountingSupplierParty/Party/Person (as well as AccountingCustomerParty/Party/Person)
        Initialize();
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesInvoiceHeaderId :=
          EInvoiceServiceHelper.CreateServiceInvoiceWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);
        XmlFileName := ExecEInvoice(SalesInvoiceHeaderId);

        // AccountingCustomerParty and AccountingSupplierParty
        EInvoiceXMLXSDValidation.VerifyAccountingParty(TempExpectedCustomerInfo, SalespersonPurchaser.Code, XmlFileName);

        // The 'Delivery' node on the header contains the updated address node
        VerifyDeliveryOnServiceInvoice(XmlFileName, 'cac:Delivery/cac:DeliveryLocation/cac:Address', SalesInvoiceHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithAllVATGroups()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        ServiceInvWithNoOfVATGroups(5);
    end;

    local procedure ServiceInvWithNoOfVATGroups(NoOfGroups: Integer)
    var
        ServiceHeader: Record "Service Header";
        TempVATEntry: Record "VAT Entry" temporary;
        ServiceInvoiceNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text[1024];
    begin
        SetVATRates(NoOfGroups, VATRate);
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceDocWithVATGroups(ServiceHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(ServiceHeader."Document Type", ServiceInvoiceNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecEInvoice(ServiceInvoiceNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithOneVATGroup()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        ServiceInvWithNoOfVATGroups(1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithReverseCharge()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice] [Reverse Charge]
        // [SCENARIO 1.4.8] VAT category K is added to the Service Invoice
        Initialize();

        // [GIVEN] A Service Invoice to export with VAT % = 0 and Reverse Charge
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceDocWithZeroVAT(ServiceHeader, true, false);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(ServiceInvoiceNo);

        // [THEN] The XML file correctly classifies VAT Type as K
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'K', ServiceInvoiceNo, ServiceHeader."Document Type", SchemaDocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceOutsideTaxArea()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.8] VAT category Z is added to the Service Invoice
        Initialize();

        // [GIVEN] A Service Invoice to export with VAT % = 0 and Outside tax area
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceDocWithZeroVAT(ServiceHeader, false, true);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(ServiceInvoiceNo);

        // [THEN] The XML file correctly classifies VAT Type as Z
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'Z', ServiceInvoiceNo, ServiceHeader."Document Type", SchemaDocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithTwoVATGroups()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        ServiceInvWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        ServiceInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.28] EndPointID contains customer VAT Reg No.
        Initialize();

        // [GIVEN] A posted service Invoice to export where bill-to customer has "VAT  Reg. No." = X
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        ServiceInvoiceHeaderId :=
          EInvoiceServiceHelper.CreateServiceInvoiceWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecEInvoice(ServiceInvoiceHeaderId);

        // [THEN] AccountingCustomerParty has schemeID set to NO:ORGNR and inner value is X
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]',
          TempExpectedCustomerInfo."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvServInvoiceFile()
    var
        XmlFileName: Text[1024];
        ServiceInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();
        XmlFileName := ExecEInvoice(ServiceInvoiceNo);

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:bii05:ver2.0');
        NOXMLReadHelper.VerifyNodeValue('//cbc:CustomizationID', GetInvoiceCustomizationID(ServiceInvoiceNo));

        NOXMLReadHelper.VerifyAttributeValue('//cbc:BaseQuantity', 'unitCode', EInvoiceHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:BaseQuantity', 'unitCodeListID', 'UNECERec20');
        NOXMLReadHelper.VerifyNodeValue('//cbc:BaseQuantity', '1.00');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure CreateEInvoiceServCrMemoFile()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        XmlFileName := EInvoiceServCrMemo();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServiceCrMemoDeliveryLocationOnLine()
    var
        XMLFileName: Text;
        CrMemoHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] Validate the child nodes of 'Delivery', on the CreditNote Lines
        Initialize();

        CrMemoHeaderId := EInvoiceServiceHelper.CreateServiceCrMemo();
        XMLFileName := ExecECrMemo(CrMemoHeaderId);

        VerifyDeliveryOnServiceCrMemo(XMLFileName, 'cac:CreditNoteLine/cac:Delivery/cac:DeliveryLocation/cac:Address', CrMemoHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoAccountingParty()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        SalesInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] AccountingSupplierParty, AccountingCustomerParty and Delivery (on the header) contain the updated UBL 2.1 xml
        // [SCENARIO] namely the AddressType used in PostalAddress and Delivery Address is changed, as well as the Customer Contact
        // [SCENARIO] additionally a node has been removed: AccountingSupplierParty/Party/Person (as well as AccountingCustomerParty/Party/Person)
        Initialize();
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesInvoiceHeaderId :=
          EInvoiceServiceHelper.CreateServiceCrMemoWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);
        XmlFileName := ExecECrMemo(SalesInvoiceHeaderId);

        // AccountingCustomerParty and AccountingSupplierParty
        EInvoiceXMLXSDValidation.VerifyAccountingParty(TempExpectedCustomerInfo, SalespersonPurchaser.Code, XmlFileName);

        // The 'Delivery' node on the header contains the updated address node
        VerifyDeliveryOnServiceCrMemo(XmlFileName, 'cac:Delivery/cac:DeliveryLocation/cac:Address', SalesInvoiceHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServCrMemoEndpointID()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceServCrMemo());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServiceCrMemoFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        ServCrMemoHdr: Record "Service Cr.Memo Header";
        XmlFileName: Text[1024];
        ServCrMemoNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);
        ServCrMemoNo := EInvoiceServiceHelper.CreateServiceCrMemo();
        CompanyInfo.Get();
        ServCrMemoHdr.Get(ServCrMemoNo);

        // exercise
        XmlFileName := ExecECrMemo(ServCrMemoNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, ServCrMemoHdr."Bill-to Name",
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), true); // entRegistered = TRUE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServiceCrMemoFileNonEntReg()
    var
        CompanyInfo: Record "Company Information";
        ServCrMemoHdr: Record "Service Cr.Memo Header";
        XmlFileName: Text[1024];
        ServCrMemoNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);
        ServCrMemoNo := EInvoiceServiceHelper.CreateServiceCrMemo();
        CompanyInfo.Get();
        ServCrMemoHdr.Get(ServCrMemoNo);

        // exercise
        XmlFileName := ExecECrMemo(ServCrMemoNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, ServCrMemoHdr."Bill-to Name",
          EInvoiceExportCommon.WriteCompanyID(CompanyInfo."VAT Registration No."), false);  // entRegistered = FALSE
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServiceCrMemoHeaderFixedValueAttributes()
    var
        ServCrMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.10] Fixed value attributes added: CurrencyCode, SchemaId
        Initialize();

        // [GIVEN] A posted service invoice
        ServCrMemoNo := EInvoiceServiceHelper.CreateServiceCrMemo();

        // [WHEN] Posted service invoice is exported
        XmlFileName := ExecECrMemo(ServCrMemoNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header contains attributes: CurrencyCode,SchemaId
        EInvoiceXMLXSDValidation.VerifyDocumentCurrencyCode(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyTaxCategorySchemaIdAttribute(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyIdentificationCode(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvServiceCrMemoCreditedQuantity()
    var
        ServiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.10] Fixed value attributes added for CreditedQuantity: unitCode, unitCodeListID.
        Initialize();

        // [GIVEN] A posted service invoice
        ServiceNo := EInvoiceServiceHelper.CreateServiceCrMemo();

        // [WHEN] Posted service invoice is exported
        XmlFileName := ExecECrMemo(ServiceNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File element CreditedQuantity contains attributes: unitCode and listID
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCode', EInvoiceHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCodeListID', 'UNECERec20');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccCostCodeAddedInServCrMem()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        XmlFileName := EInvoiceServCrMemo();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCost');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoForeignCurrency()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoNo: Code[20];
        XmlFileName: Text;
    begin
        // [FEATURE] [Credit Memo] [FCY]
        // [SCENARIO 1.4.10] Foreign currency exchange rate information is added to the service credit memo
        Initialize();

        // [GIVEN] A service credit memo to export in a foreign currency with Tax Exchange Rate = X
        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceInForeignCurrency(ServiceHeader."Document Type"::"Credit Memo");

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(ServiceCrMemoNo);

        // [THEN] Validate all foreign currency nodes are added with correct values
        EInvoiceXMLXSDValidation.VerifyForeignCurrencyNodes(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithAllVATGroups()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        ServiceCrMemoWithNoOfVATGroups(5);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithOneVATGroup()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        ServiceCrMemoWithNoOfVATGroups(1);
    end;

    local procedure ServiceCrMemoWithNoOfVATGroups(NoOfGroups: Integer)
    var
        ServiceHeader: Record "Service Header";
        TempVATEntry: Record "VAT Entry" temporary;
        ServiceCrMemoNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text[1024];
    begin
        SetVATRates(NoOfGroups, VATRate);
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";
        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceDocWithVATGroups(ServiceHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(ServiceHeader."Document Type", ServiceCrMemoNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecECrMemo(ServiceCrMemoNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithReverseCharge()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo] [Reverse Charge]
        // [SCENARIO 1.4.8] VAT category K is added to the Service Credit Memo
        Initialize();

        // [GIVEN] A Service credit memo to export with VAT % = 0 and Reverse Charge
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";
        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceDocWithZeroVAT(ServiceHeader, true, false);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(ServiceCrMemoNo);

        // [THEN] The XML file correctly classifies VAT Type as K
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'K', ServiceCrMemoNo, ServiceHeader."Document Type", SchemaDocumentType::CrMemo);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoOutsideTaxArea()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.8] VAT category Z is added to the Service Credit Memo
        Initialize();

        // [GIVEN] A Service credit memo to export with VAT % = 0 and Outside tax area
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";
        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceDocWithZeroVAT(ServiceHeader, false, true);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(ServiceCrMemoNo);

        // [THEN] The XML file correctly classifies VAT Type as Z
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'Z', ServiceCrMemoNo, ServiceHeader."Document Type", SchemaDocumentType::CrMemo);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithTwoVATGroups()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        ServiceCrMemoWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        ServiceCrMemoHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.28] EndPointID contains customer VAT Reg No.
        Initialize();

        // [GIVEN] A posted Service credit memo to export where bill-to customer has "VAT  Reg. No." = X
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        ServiceCrMemoHeaderId :=
          EInvoiceServiceHelper.CreateServiceCrMemoWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecECrMemo(ServiceCrMemoHeaderId);

        // [THEN] AccountingCustomerParty has schemeID set to NO:ORGNR and inner value is X
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]',
          TempExpectedCustomerInfo."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvServCrMemoFile()
    var
        XmlFileName: Text[1024];
        ServiceCrMemoNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceCrMemo();
        XmlFileName := ExecECrMemo(ServiceCrMemoNo);

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:bii05:ver2.0');
        NOXMLReadHelper.VerifyNodeValue('//cbc:CustomizationID', GetCrMemoCustomizationID(ServiceCrMemoNo));

        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCode', EInvoiceHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCodeListID', 'UNECERec20');
    end;

    local procedure EInvoiceServCrMemo(): Text[1024]
    var
        ServiceCrMemoNo: Code[20];
    begin
        ServiceCrMemoNo := EInvoiceServiceHelper.CreateServiceCrMemo();
        exit(ExecECrMemo(ServiceCrMemoNo));
    end;

    local procedure EInvoiceServInvoice(): Text[1024]
    var
        ServiceInvoiceNo: Code[20];
    begin
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();
        exit(ExecEInvoice(ServiceInvoiceNo));
    end;

    local procedure ExecECrMemo(ServiceCrMemoNo: Code[20]): Text[1024]
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceServiceHelper.SetupEInvoiceForService(Path);

        ServCrMemoHeader.SetRange("No.", ServiceCrMemoNo);
        REPORT.Run(REPORT::"Create Elec. Service Cr. Memos", false, true, ServCrMemoHeader);

        exit(Path + ServiceCrMemoNo + '.xml');
    end;

    local procedure ExecEInvoice(ServiceInvoiceNo: Code[20]): Text[1024]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceServiceHelper.SetupEInvoiceForService(Path);

        ServiceInvoiceHeader.SetRange("No.", ServiceInvoiceNo);
        REPORT.Run(REPORT::"Create Elec. Service Invoices", false, true, ServiceInvoiceHeader);

        exit(Path + ServiceInvoiceNo + '.xml');
    end;

    local procedure GetCrMemoCustomizationID(ServiceCrMemoNo: Code[20]): Text[250]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustomizationID: Text[250];
    begin
        ServiceCrMemoHeader.Get(ServiceCrMemoNo);
        Customer.Get(ServiceCrMemoHeader."Customer No.");
        CompanyInfo.Get();

        if Customer."Country/Region Code" = CompanyInfo."Country/Region Code" then begin
            CustomizationID := 'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:';
            CustomizationID += 'urn:www.peppol.eu:bis:peppol5a:ver2.0:extended:';
            CustomizationID += 'urn:www.difi.no:ehf:kreditnota:ver2.0';
        end else begin
            CustomizationID := 'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:';
            CustomizationID += 'urn:www.peppol.eu:bis:peppol5a:ver2.0';
        end;
        exit(CustomizationID);
    end;

    local procedure GetInvoiceCustomizationID(ServiceInvoiceNo: Code[20]): Text[250]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustomizationID: Text[250];
    begin
        ServiceInvoiceHeader.Get(ServiceInvoiceNo);
        Customer.Get(ServiceInvoiceHeader."Customer No.");
        CompanyInfo.Get();

        if Customer."Country/Region Code" = CompanyInfo."Country/Region Code" then begin
            CustomizationID := 'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:';
            CustomizationID += 'urn:www.peppol.eu:bis:peppol5a:ver2.0:extended:';
            CustomizationID += 'urn:www.difi.no:ehf:faktura:ver2.0';
        end else begin
            CustomizationID := 'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended';
            CustomizationID += 'urn:www.peppol.eu:bis:peppol5a:ver2.0';
        end;
        exit(CustomizationID);
    end;

    local procedure InitGlobalVATRates()
    begin
        NoTaxRate := 0;
        LowRate := 10;
        ReducedRate := 11.11;
        HighRate := 15;
        StandardRate := 25;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EInvoiceFlagOnSalesDocumentTakenFromSellTo()
    var
        CustomerWithEInvoice: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] E-Invoice Flag copied from Sell-To Customer on the Service Header
        // [GIVEN] A service document, where the the Service Header "E-Invoice" = FALSE
        // [GIVEN] Sell-To Customer No. is set to a customer having E-Invoice = TRUE
        LibrarySales.CreateCustomer(CustomerWithEInvoice);
        CustomerWithEInvoice.Validate("E-Invoice", true);
        CustomerWithEInvoice.Modify();

        // [WHEN] The Service Header is created
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerWithEInvoice."No.");

        // [THEN] The Service Header "E-Invoice" becomes TRUE
        Assert.IsTrue(ServiceHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);
    end;

    [Test]
    [HandlerFunctions('ChangeBillToCustomerNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceFlagOnSalesDocumentTakenFromBillTo()
    var
        CustomerWithEInvoice: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] E-Invoice Flag copied from Bill-To Customer on the Service Header
        // [GIVEN] A service document, where the the Sales Header "E-Invoice" = FALSE
        // [GIVEN] Sell-To Customer No. is set to a customer having E-Invoice = FALSE
        LibrarySales.CreateCustomer(CustomerWithEInvoice);
        CustomerWithEInvoice.Validate("E-Invoice", true);
        CustomerWithEInvoice.Modify();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');

        // [GIVEN] The E-Invoice field on the Sales Header is FALSE
        Assert.IsFalse(ServiceHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);

        // [WHEN] The Bill-To Customer No. is set to a second customer having E-Invoice = TRUE
        LibraryVariableStorage.Enqueue(
          StrSubstNo(ChangeBillToCustomerNoQst, ServiceHeader.FieldCaption("Bill-to Customer No.")));
        ServiceHeader.Validate("Bill-to Customer No.", CustomerWithEInvoice."No.");

        // [THEN] The Sales Header "E-Invoice" becomes TRUE
        Assert.IsTrue(ServiceHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceServicePaymentIDWithKIDSetupDocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DummyEInvoiceExportHeader: Record "E-Invoice Export Header";
        DocumentTools: Codeunit DocumentTools;
        XmlFileName: Text[1024];
        ServiceInvoiceNo: Code[20];
        ExpectedResult: Code[30];
    begin
        // [FEATURE] [KID]
        // [SCENARIO 377047] Verify exported Service Electronic Invoice XML "PaymentID" node value in case of "KID Setup"::"Document No."
        Initialize();

        // [GIVEN] Sales Receivables Setup: "KID Setup" = "Document No.", "Document No. length" = 20
        EInvoiceHelper.KIDSetup(SalesReceivablesSetup."KID Setup"::"Document No.", 20, 0);

        // [GIVEN] Posted Service Invoice No. = "103032"
        ServiceInvoiceNo := EInvoiceServiceHelper.CreateServiceInvoice();

        // [WHEN] Perform "Create Electronic Invoice" on posted Service Invoice
        XmlFileName := ExecEInvoice(ServiceInvoiceNo);

        // [THEN] Exported XML file has node value "PaymentID" = "000000000000001030329"
        DummyEInvoiceExportHeader."No." := ServiceInvoiceNo;
        ExpectedResult := DocumentTools.GetEInvoiceExportPaymentID(DummyEInvoiceExportHeader);
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:PaymentMeans/cbc:PaymentID', ExpectedResult);
    end;

    [Test]
    procedure TransferExternalDocumentNoWhilePostingServiceOrderToShipmentOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ExternalDocumentNo: Code[10];
    begin
        // [SCENARIO 545779] Service Order transfers "External Document No." when posting the shipment to the Posted Service Shipment.
        Initialize();

        // [GIVEN] Create a service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Generate and Validate Random text for External Document No.
        ExternalDocumentNo := LibraryRandom.RandText(10);
        ServiceHeader.Validate("External Document No.", ExternalDocumentNo);
        ServiceHeader.Modify(true);

        // [GIVEN] Create Service Line and Validate Quantity.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Modify(true);

        // [WHEN] Post the Service Order as Shipped.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] External Document No. must be populated in Service Shipment Header.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        Assert.AreEqual(ServiceShipmentHeader."External Document No.", ExternalDocumentNo, ExternalDocumentNoErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateGeneralPostingSetupData();
        InitGlobalVATRates();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure VerifyDeliveryOnServiceCrMemo(XMLFileName: Text; XPath: Text; HeaderId: Code[20])
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.Get(HeaderId);
        Customer.Init();
        Customer.Address := ServiceCrMemoHeader."Ship-to Address";
        Customer."Address 2" := ServiceCrMemoHeader."Ship-to Address 2";
        Customer.City := ServiceCrMemoHeader."Ship-to City";
        Customer."Post Code" := ServiceCrMemoHeader."Ship-to Post Code";
        Customer."Country/Region Code" := ServiceCrMemoHeader."Ship-to Country/Region Code";
        EInvoiceXMLXSDValidation.VerifyAddress(XMLFileName, XPath, Customer);
    end;

    local procedure VerifyDeliveryOnServiceInvoice(XMLFileName: Text; XPath: Text; HeaderId: Code[20])
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.Get(HeaderId);
        Customer.Init();
        Customer.Address := ServiceInvoiceHeader."Ship-to Address";
        Customer."Address 2" := ServiceInvoiceHeader."Ship-to Address 2";
        Customer.City := ServiceInvoiceHeader."Ship-to City";
        Customer."Post Code" := ServiceInvoiceHeader."Ship-to Post Code";
        Customer."Country/Region Code" := ServiceInvoiceHeader."Ship-to Country/Region Code";
        EInvoiceXMLXSDValidation.VerifyAddress(XMLFileName, XPath, Customer);
    end;

    local procedure SetVATRates(NoOfGroups: Integer; var VATRate: array[5] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATRate) do
            VATRate[i] := -1;

        if NoOfGroups > 0 then
            VATRate[1] := StandardRate;
        if NoOfGroups > 1 then
            VATRate[2] := LowRate;
        if NoOfGroups > 2 then
            VATRate[3] := NoTaxRate;
        if NoOfGroups > 3 then
            VATRate[4] := ReducedRate;
        if NoOfGroups > 4 then
            VATRate[5] := HighRate;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessMsgHandler(Text: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessfullyCreatedMsg, Text);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeBillToCustomerNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Unexpected confirmation message');
        Reply := true;
    end;
}

