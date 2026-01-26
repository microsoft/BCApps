codeunit 144103 "E-Invoice Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EHF] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        EInvoiceHelper: Codeunit "E-Invoice Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        EInvoiceSalesHelper: Codeunit "E-Invoice Sales Helper";
        EInvoiceXMLXSDValidation: Codeunit "E-Invoice XML XSD Validation";
        NOXMLReadHelper: Codeunit "NO XML Read Helper";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        HighRate: Decimal;
        LowRate: Decimal;
        NoTaxRate: Decimal;
        ReducedRate: Decimal;
        StandardRate: Decimal;
        SchemaDocumentType: Option Invoice,CrMemo,Reminder;
        isInitialized: Boolean;
        MissingUnitOfMeasureCodeErr: Label 'You must specify a valid %1 for the %2 for';
        SuccessfullyCreatedMsg: Label 'Successfully created ';
        TestValueTxt: Label 'Test Value';
        IncorrectFieldValueEInvoiceErr: Label 'Incorrect bool value of field E-Invoice on the Sales Header table';
        TestFieldErrorCodeTok: Label 'TestField';
        SwiftCodeErr: Label 'SWIFT Code must have a value in Company Information: Primary Key=. It cannot be zero or empty.';
        FormatTok: Label '<Precision,%1:%1><Standard Format,2>', Locked = true;
        SuccessfullyCreatedElectronicInvoiceMsg: Label 'Successfully created 1 electronic invoice documents.';

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure CreateEInvoiceSalesInvoiceFile()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        XmlFileName := EInvoiceSalesInvoice();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesBBAN()
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

        // [GIVEN] A posted sales invoice to export
        XmlFileName := EInvoiceSalesInvoice();

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
    procedure EInvoiceSalesIBAN()
    var
        IBAN: Code[50];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [IBAN]
        // [SCENARIO 1.4.27] Bank Account, IBAN
        Initialize();

        // [GIVEN] Company information is set up with IBAN
        // [GIVEN] Company information is set up without BBAN
        IBAN := 'GB 12 CPBK 08929965044991';
        EInvoiceXMLXSDValidation.SetBankInformation('', IBAN);

        // [GIVEN] A posted sales invoice to export
        XmlFileName := EInvoiceSalesInvoice();

        // [THEN] IBAN is present in the XML file under Invoice->PaymentMeans->PayeeFinancialAccount
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "IBAN"]', IBAN);

        // [THEN] BBAN is not present
        NOXMLReadHelper.VerifyNodeAbsence('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "BBAN"]');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesIBANAndBBAN()
    var
        AccountList: DotNet XmlNodeList;
        BankAccountNo: Text[30];
        IBAN: Code[50];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [BBAN] [IBAN]
        // [SCENARIO 1.4.27] Bank Account, both IBAN and BBAN
        Initialize();

        // [GIVEN] Company information is set up with both IBAN and BBAN
        BankAccountNo := '99-99-888';
        IBAN := 'GB 12 CPBK 08929965044991';
        EInvoiceXMLXSDValidation.SetBankInformation(BankAccountNo, IBAN);

        // [GIVEN] A posted sales invoice to export
        XmlFileName := EInvoiceSalesInvoice();

        // [THEN] Both IBAN and BBAN are present in the XML file under Invoice->PaymentMeans->PayeeFinancialAccount
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:ID[@schemeID = "IBAN"]', IBAN);
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
    procedure EInvoiceSalesInvDeliveryLocationOnLine()
    var
        XMLFileName: Text;
        SalesInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Invoice]
        // Validate the child nodes of 'Delivery', on the Invoice Lines
        Initialize();

        SalesInvoiceHeaderId := EInvoiceSalesHelper.CreateSalesInvoice();
        XMLFileName := ExecEInvoice(SalesInvoiceHeaderId);

        VerifyDeliveryOnSalesInvoice(XMLFileName, 'cac:InvoiceLine/cac:Delivery/cac:DeliveryLocation/cac:Address', SalesInvoiceHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesInvFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        SalesInvHdr: Record "Sales Invoice Header";
        XmlFileName: Text[1024];
        VatId: Text[30];
        SalesNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);

        SalesNo := EInvoiceSalesHelper.CreateSalesInvoice();
        CompanyInfo.Get();
        SalesInvHdr.Get(SalesNo);

        // exercise
        XmlFileName := ExecEInvoice(SalesNo);

        // verify
        VatId := CompanyInfo."VAT Registration No.";
        EInvoiceXMLXSDValidation.VerifyEntRegElements(XmlFileName, SalesInvHdr."Bill-to Name", VatId, true);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesInvFileNoEntReg()
    var
        CompanyInfo: Record "Company Information";
        SalesInvHdr: Record "Sales Invoice Header";
        XmlFileName: Text[1024];
        SalesNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);

        SalesNo := EInvoiceSalesHelper.CreateSalesInvoice();
        CompanyInfo.Get();
        SalesInvHdr.Get(SalesNo);

        // exercise
        XmlFileName := ExecEInvoice(SalesNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(
          XmlFileName, SalesInvHdr."Bill-to Name", CompanyInfo."VAT Registration No.", false);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesInvEndpointID()
    begin
        // [FEATURE] [Invoice]
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceSalesInvoice());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvSalesInvHeaderFixedValueAttributes()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.10] Fixed value attributes added to sales invoice
        Initialize();

        // [GIVEN] A posted sales invoice
        SalesNo := EInvoiceSalesHelper.CreateSalesInvoice();

        // [WHEN] Posted sales invoice is exported
        XmlFileName := ExecEInvoice(SalesNo);
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
    procedure EInvSalesInvInvoicedQuantity()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.10] Fixed value attributes added to sales invoice with invoiced quantity
        Initialize();

        // [GIVEN] A posted sales invoice
        SalesNo := EInvoiceSalesHelper.CreateSalesInvoice();

        // [WHEN] Posted sales invoice is exported
        XmlFileName := ExecEInvoice(SalesNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header element InvoicedQuantity contains attributes: unitCode and listID
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCode', EInvoiceSalesHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCodeListID', GetDefaultUnitCodeListID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvNoUNECECode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Invoice]
        Initialize();
        asserterror EInvoiceSalesHelper.CreateSalesInvoiceNoUNECECode();
        Assert.ExpectedError(
          StrSubstNo(MissingUnitOfMeasureCodeErr, UnitOfMeasure.FieldCaption("International Standard Code"), UnitOfMeasure.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccCostCodeAddedInSalesInv()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        XmlFileName := EInvoiceSalesInvoice();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeValue('//cbc:AccountingCost', Format(TestValueTxt));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure NoAccCostCodeAddedInSalesCrMem()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        XmlFileName := EInvoiceSalesCrMemo();

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCostCode');
        NOXMLReadHelper.VerifyNodeAbsence('//cbc:AccountingCost');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceAccountingParty()
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
          EInvoiceSalesHelper.CreateSalesInvoiceWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);
        XmlFileName := ExecEInvoice(SalesInvoiceHeaderId);

        // AccountingCustomerParty and AccountingSupplierParty
        EInvoiceXMLXSDValidation.VerifyAccountingParty(TempExpectedCustomerInfo, SalespersonPurchaser.Code, XmlFileName);

        // The 'Delivery' node on the header contains the updated address node
        VerifyDeliveryOnSalesInvoice(XmlFileName, 'cac:Delivery/cac:DeliveryLocation/cac:Address', SalesInvoiceHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceForeignCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceNo: Code[20];
        XmlFileName: Text;
    begin
        // [FEATURE] [Invoice] [FCY]
        // [SCENARIO 1.4.10] Foreign currency exchange rate information is added to the Sales Invoice
        Initialize();

        // [GIVEN] A sales invoice to export in a foreign currency with Tax Exchange Rate = X
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesDocInForeignCurrency(SalesHeader."Document Type"::Invoice);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] Validate all foreign currency nodes are added with correct values
        EInvoiceXMLXSDValidation.VerifyForeignCurrencyNodes(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithAllVATGroups()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        SalesInvoiceWithNoOfVATGroups(5);
    end;

    local procedure SalesInvoiceWithNoOfVATGroups(NoOfGroups: Integer)
    var
        SalesHeader: Record "Sales Header";
        TempVATEntry: Record "VAT Entry" temporary;
        SalesInvoiceNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text[1024];
    begin
        SetVATRates(NoOfGroups, VATRate);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesDocWithVATGroups(SalesHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(SalesHeader."Document Type", SalesInvoiceNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecEInvoice(SalesInvoiceNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithOneVATGroup()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        SalesInvoiceWithNoOfVATGroups(1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithReverseVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice] [Reverse Charge]
        // [SCENARIO 1.4.8] VAT category Z is added to the sales Invoice with reversed VAT
        Initialize();

        // [GIVEN] A sales Invoice to export with VAT % = 0 and Reverse Charge
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesDocWithZeroVAT(SalesHeader, true, false);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] The XML file correctly classifies VAT Type as K
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'K', SalesInvoiceNo, SalesHeader."Document Type", SchemaDocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOutsideTaxArea()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.8] VAT category Z is added to the sales Invoice outside tax area
        Initialize();

        // [GIVEN] A sales Invoice to export with VAT % = 0 and Outside tax area
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesDocWithZeroVAT(SalesHeader, false, true);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] The XML file correctly classifies VAT Type as Z
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'Z', SalesInvoiceNo, SalesHeader."Document Type", SchemaDocumentType::Invoice);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithTwoVATGroups()
    begin
        // [FEATURE] [Invoice]
        Initialize();

        SalesInvoiceWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithoutVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text;
        SalesInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.28] Customer without VAT Reg. No. in Sales Invoice
        Initialize();

        // [GIVEN] A posted Sales Invoice to export to a customer with no VAT Reg. No.
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        TempExpectedCustomerInfo."VAT Registration No." := '';
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesInvoiceHeaderId :=
          EInvoiceSalesHelper.CreateSalesInvoiceWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecEInvoice(SalesInvoiceHeaderId);

        // [THEN] AccountingCustomerParty does not have a VAT Registration No.
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsenceByXPath('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        SalesInvoiceHeaderId: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 1.4.28] EndPointID contains customer VAT Reg No. in Sales Invoice
        Initialize();

        // [GIVEN] A posted Sales Invoice to export where bill-to customer has "VAT  Reg. No." = X
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesInvoiceHeaderId :=
          EInvoiceSalesHelper.CreateSalesInvoiceWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecEInvoice(SalesInvoiceHeaderId);

        // [THEN] AccountingCustomerParty has schemeID set to NO:ORGNR and inner value is X
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]',
          TempExpectedCustomerInfo."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvSalesInvoiceFile()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        Initialize();

        SalesNo := EInvoiceSalesHelper.CreateSalesInvoice();
        XmlFileName := ExecEInvoice(SalesNo);

        NOXMLReadHelper.Initialize(XmlFileName);

        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:bii04:ver2.0');
        NOXMLReadHelper.VerifyNodeValue('//cbc:CustomizationID', GetInvoiceCustomizationID(SalesNo));

        NOXMLReadHelper.VerifyAttributeValue('//cbc:BaseQuantity', 'unitCode', EInvoiceSalesHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:BaseQuantity', 'unitCodeListID', GetDefaultUnitCodeListID());
        NOXMLReadHelper.VerifyNodeValue('//cbc:BaseQuantity', '1.00');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure CreateEInvoiceSalesCrMemoFile()
    var
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        XmlFileName := EInvoiceSalesCrMemo();

        EInvoiceXMLXSDValidation.CheckIfFileExists(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesCrMemoDeliveryLocationOnLine()
    var
        XMLFileName: Text;
        SalesCrMemoHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO] Validate the child nodes of 'Delivery', on the CreditNote Lines
        Initialize();

        SalesCrMemoHeaderId := EInvoiceSalesHelper.CreateSalesCrMemo();
        XMLFileName := ExecECrMemo(SalesCrMemoHeaderId);

        VerifyDeliveryOnSalesCrMemo(XMLFileName, 'cac:CreditNoteLine/cac:Delivery/cac:DeliveryLocation/cac:Address', SalesCrMemoHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesCrMemoEndpointID()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();
        EInvoiceXMLXSDValidation.VerifyEndpointID(EInvoiceSalesCrMemo());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesCrMemoFileEntReg()
    var
        CompanyInfo: Record "Company Information";
        SalesHdr: Record "Sales Cr.Memo Header";
        XmlFileName: Text[1024];
        SalesNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();
        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(true);

        SalesNo := EInvoiceSalesHelper.CreateSalesCrMemo();
        CompanyInfo.Get();
        SalesHdr.Get(SalesNo);

        // exercise
        XmlFileName := ExecECrMemo(SalesNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(
          XmlFileName, SalesHdr."Bill-to Name", CompanyInfo."VAT Registration No.", true);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesCrMemoFileNoEntRg()
    var
        CompanyInfo: Record "Company Information";
        SalesHdr: Record "Sales Cr.Memo Header";
        XmlFileName: Text[1024];
        SalesNo: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        // setup
        LibraryERM.SetEnterpriseRegisterCompInfo(false);

        SalesNo := EInvoiceSalesHelper.CreateSalesCrMemo();
        CompanyInfo.Get();
        SalesHdr.Get(SalesNo);

        // exercise
        XmlFileName := ExecECrMemo(SalesNo);

        // verify
        EInvoiceXMLXSDValidation.VerifyEntRegElements(
          XmlFileName, SalesHdr."Bill-to Name", CompanyInfo."VAT Registration No.", false);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvSalesCrMemoHeaderFixedValueAttributes()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.10] Fixed value attributes added to sales credit memo
        Initialize();

        // [GIVEN] A posted sales invoice
        SalesNo := EInvoiceSalesHelper.CreateSalesCrMemo();

        // [WHEN] Posted sales invoice is exported
        XmlFileName := ExecECrMemo(SalesNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header contains attributes: CurrencyCode,SchemaId
        EInvoiceXMLXSDValidation.VerifyDocumentCurrencyCode(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyTaxCategorySchemaIdAttribute(XmlFileName);
        EInvoiceXMLXSDValidation.VerifyIdentificationCode(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvSalesCrMemoCreditedQuantity()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.10] Fixed value attributes added to Sales Credut Memo with credited quantity
        Initialize();

        // [GIVEN] A posted sales invoice
        SalesNo := EInvoiceSalesHelper.CreateSalesCrMemo();

        // [WHEN] Posted sales invoice is exported
        XmlFileName := ExecECrMemo(SalesNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] XML File Header element CreditedQuantity contains attributes: unitCode and listID
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCode', EInvoiceSalesHelper.DefaultUNECERec20Code());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCodeListID', GetDefaultUnitCodeListID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesCrMNoUNECECode()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [Credit Memo]
        Initialize();
        asserterror EInvoiceSalesHelper.CreateSalesCrMemoNoUNECECode();
        Assert.ExpectedError(
          StrSubstNo(MissingUnitOfMeasureCodeErr, UnitOfMeasure.FieldCaption("International Standard Code"), UnitOfMeasure.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoAccountingParty()
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
          EInvoiceSalesHelper.CreateSalesCrMemoWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);
        XmlFileName := ExecECrMemo(SalesInvoiceHeaderId);

        // AccountingCustomerParty and AccountingSupplierParty
        EInvoiceXMLXSDValidation.VerifyAccountingParty(TempExpectedCustomerInfo, SalespersonPurchaser.Code, XmlFileName);

        // The 'Delivery' node on the header contains the updated address node
        VerifyDeliveryOnSalesCrMemo(XmlFileName, 'cac:Delivery/cac:DeliveryLocation/cac:Address', SalesInvoiceHeaderId);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoForeignCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoNo: Code[20];
        XmlFileName: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.10] Foreign currency exchange rate information is added to the sales credit memo
        Initialize();

        // [GIVEN] A sales credit memo to export in a foreign currency with Tax Exchange Rate = X
        SalesCrMemoNo := EInvoiceSalesHelper.CreateSalesDocInForeignCurrency(SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(SalesCrMemoNo);

        // [THEN] Validate all foreign currency nodes are added with correct values
        EInvoiceXMLXSDValidation.VerifyForeignCurrencyNodes(XmlFileName);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithOneVATGroup()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        SalesCrMemoWithNoOfVATGroups(1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithTwoVATGroups()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        SalesCrMemoWithNoOfVATGroups(2);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithAllVATGroups()
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        SalesCrMemoWithNoOfVATGroups(5);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithReverseVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo] [Reverse Charge]
        // [SCENARIO 1.4.8] VAT category Z is added to the sales Credit Memo with reversed VAT
        Initialize();

        // [GIVEN] A sales Credit Memo to export with VAT % = 0 and Reverse Charge
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesCrMemoNo := EInvoiceSalesHelper.CreateSalesDocWithZeroVAT(SalesHeader, true, false);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(SalesCrMemoNo);

        // [THEN] The XML file correctly classifies VAT Type as K
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'K', SalesCrMemoNo, SalesHeader."Document Type", SchemaDocumentType::CrMemo);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoOutsideTaxArea()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.8] VAT category Z is added to the sales Credit Memo outside tax area
        Initialize();

        // [GIVEN] A sales Credit Memo to export with VAT % = 0 and Outside tax area
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesCrMemoNo := EInvoiceSalesHelper.CreateSalesDocWithZeroVAT(SalesHeader, false, true);

        // [WHEN] The user exports the E-Invoice
        XmlFileName := ExecECrMemo(SalesCrMemoNo);

        // [THEN] The XML file correctly classifies VAT Type as Z
        // [THEN] The head level TaxCategory contains VAT rate as well
        // [THEN] XML file validates
        EInvoiceXMLXSDValidation.VerifyZeroVATCategory(
          XmlFileName, 'Z', SalesCrMemoNo, SalesHeader."Document Type", SchemaDocumentType::CrMemo);
    end;

    local procedure SalesCrMemoWithNoOfVATGroups(NoOfGroups: Integer)
    var
        SalesHeader: Record "Sales Header";
        TempVATEntry: Record "VAT Entry" temporary;
        SalesCrMemoNo: Code[20];
        VATRate: array[5] of Decimal;
        XmlFileName: Text[1024];
    begin
        SetVATRates(NoOfGroups, VATRate);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesCrMemoNo := EInvoiceSalesHelper.CreateSalesDocWithVATGroups(SalesHeader, VATRate);

        EInvoiceXMLXSDValidation.VerifyVATEntriesCount(SalesHeader."Document Type", SalesCrMemoNo, NoOfGroups, TempVATEntry);

        XmlFileName := ExecECrMemo(SalesCrMemoNo);
        EInvoiceXMLXSDValidation.VerifyVATDataInTaxSubtotal(TempVATEntry, XmlFileName, NoOfGroups);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithoutVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text;
        SalesCrMemoHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.28] Customer without VAT Reg. No. in Sales Credit Memo
        Initialize();

        // [GIVEN] A posted Credit Memo to export to a customer with no VAT Reg. No.
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        TempExpectedCustomerInfo."VAT Registration No." := '';
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesCrMemoHeaderId :=
          EInvoiceSalesHelper.CreateSalesCrMemoWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecECrMemo(SalesCrMemoHeaderId);

        // [THEN] AccountingCustomerParty does not have a VAT Registration No.
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeAbsenceByXPath('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithVATRegNo()
    var
        TempExpectedCustomerInfo: Record Customer temporary;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        XmlFileName: Text[1024];
        SalesCrMemoHeaderId: Code[20];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 1.4.28] EndPointID contains customer VAT Reg No. in Sales Credit Memo
        Initialize();

        // [GIVEN] A posted Sales Invoice to export where bill-to customer has "VAT  Reg. No." = X
        EInvoiceHelper.InitExpectedCustomerInfo(TempExpectedCustomerInfo);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        SalesCrMemoHeaderId :=
          EInvoiceSalesHelper.CreateSalesCrMemoWithCustomerAndSalesPerson(TempExpectedCustomerInfo, SalespersonPurchaser.Code);

        // [WHEN] The user exports the e-invoice
        XmlFileName := ExecECrMemo(SalesCrMemoHeaderId);

        // [THEN] AccountingCustomerParty has schemeID set to NO:ORGNR and inner value is X
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('cac:AccountingCustomerParty/cac:Party/cbc:EndpointID[@schemeID="NO:ORGNR"]',
          TempExpectedCustomerInfo."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateEInvSalesCrMemoFile()
    var
        SalesNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        Initialize();

        SalesNo := EInvoiceSalesHelper.CreateSalesCrMemo();
        XmlFileName := ExecECrMemo(SalesNo);

        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cbc:ProfileID', 'urn:www.cenbii.eu:profile:biixx:ver2.0');
        NOXMLReadHelper.VerifyNodeValue('//cbc:CustomizationID', GetCrMemoCustomizationID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EInvoiceFlagOnSalesDocumentTakenFromSellTo()
    var
        CustomerWithEInvoice: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [E-Invoice]
        // [SCENARIO] E-Invoice Flag copied from Sell-To Customer on the Sales Header
        // [GIVEN] A Sales document, where the the Sales Header "E-Invoice" = FALSE
        // [GIVEN] Sell-To Customer No. is set to a customer having E-Invoice = TRUE
        LibrarySales.CreateCustomer(CustomerWithEInvoice);
        CustomerWithEInvoice.Validate("E-Invoice", true);
        CustomerWithEInvoice.Modify();

        // [WHEN] The Sales Header is created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerWithEInvoice."No.");

        // [THEN] The Sales Header "E-Invoice" becomes TRUE
        Assert.IsTrue(SalesHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);
    end;

    [Test]
    [HandlerFunctions('ChangeBillToCustomerNoConfirmHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceFlagOnSalesDocumentTakenFromBillTo()
    var
        CustomerWithEInvoice: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [E-Invoice]
        // [SCENARIO] E-Invoice Flag copied from Bill-To Customer on the Sales Header
        // [GIVEN] A Sales document, where the the Sales Header "E-Invoice" = FALSE
        // [GIVEN] Sell-To Customer No. is set to a customer having E-Invoice = FALSE
        LibrarySales.CreateCustomer(CustomerWithEInvoice);
        CustomerWithEInvoice.Validate("E-Invoice", true);
        CustomerWithEInvoice.Modify();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');

        // [GIVEN] The E-Invoice field on the Sales Header is FALSE
        Assert.IsFalse(SalesHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);

        // [WHEN] The Bill-To Customer No. is set to a second customer having E-Invoice = TRUE
        SalesHeader.Validate("Bill-to Customer No.", CustomerWithEInvoice."No.");

        // [THEN] The Sales Header "E-Invoice" becomes TRUE
        Assert.IsTrue(SalesHeader."E-Invoice", IncorrectFieldValueEInvoiceErr);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesCompanyID()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        XmlFileName: Text;
        VATRegNo: Text[30];
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [VAT Registration No.]
        // [SCENARIO] Export "VAT Registration No." to <CompanyID> tag
        Initialize();

        // [GIVEN] Company information "VAT Registration No."  = "GB123456789"
        // [GIVEN] Customer "VAT Registration No."  = "012345678"
        VATRegNo := EInvoiceXMLXSDValidation.SetRandomVATRegNoInCompanyInfo();

        // [GIVEN] A posted sales invoice to export
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesInvoice();
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        // [WHEN] Export sales invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);
        NOXMLReadHelper.Initialize(XmlFileName);

        // [THEN] <AccountingSupplierParty/Party/PartyLegalEntity/CompanyID> = 123456789
        VATRegNo := EInvoiceXMLXSDValidation.StripVATRegNo(VATRegNo);
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', VATRegNo);
        // [THEN] <AccountingSupplierParty/Party/PartyTaxScheme/CompanyID> = 123456789MVA
        VATRegNo += 'MVA';
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', VATRegNo);

        // [THEN] <AccountingCustomerParty/Party/PartyLegalEntity/CompanyID> = 012345678
        VATRegNo := Customer."VAT Registration No.";
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:AccountingCustomerParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID', VATRegNo);
        // [THEN] <AccountingCustomerParty/Party/PartyTaxScheme/CompanyID> = 012345678MVA
        VATRegNo += 'MVA';
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:AccountingCustomerParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID', VATRegNo);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceBlankYourReference()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 376010] Export Sales Invoice without "Your Reference"
        Initialize();

        // [GIVEN] A posted sales invoice where "Your Reference" is blank
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesInvoice();
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        SalesInvoiceHeader."Your Reference" := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Export sales invoice
        NOXMLReadHelper.Initialize(ExecEInvoice(SalesInvoiceNo));

        // [THEN] <AccountingCustomerParty/Party/Contact/ID> = NA
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:AccountingCustomerParty/cac:Party/cac:Contact/cbc:ID', 'NA');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_TransferFieldAccCodeFromFromSalesInvHeaderToEInvoiceExportHeader()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        EInvExportHeader: Record "E-Invoice Export Header";
    begin
        // [FEATURE] [Invoice] [UT]
        // [SCENARIO 375592] The value of the field "Account Code" should be transfered from "Sales Invoice Header" to field "Payment ID" in "E-Invoice Export Header" by TRANSFERFIELDS

        Initialize();
        // [GIVEN] "Account Code" in "Sales Invoice Header" = "X" (the value with maximum length for this field)
        SalesInvHeader.Init();
        SalesInvHeader."Account Code" :=
          CopyStr(LibraryUtility.GenerateRandomText(
              MaxStrLen(SalesInvHeader."Account Code")), 1, MaxStrLen(SalesInvHeader."Account Code"));

        // [WHEN] TRANSFERFIELDS from "Sales Invoice Header" to "E-Invoice Export Header"
        EInvExportHeader.TransferFields(SalesInvHeader);

        // [THEN] "Payment ID" in "E-Invoice Export Header" = "X"
        EInvExportHeader.TestField("Payment ID", SalesInvHeader."Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_BlankCompanySWIFTCode()
    var
        CompanyInformation: Record "Company Information";
        EInvoiceCheckSalesInvoice: Codeunit "E-Invoice Check Sales Invoice";
    begin
        // [FEATURE] [UT]
        // [SCENARIO] System should throw error on E-Invoice export when "SWIFT Code" is not set in "Company Information"
        CompanyInformation.Get();
        CompanyInformation."SWIFT Code" := '';
        CompanyInformation.Modify(true);

        asserterror EInvoiceCheckSalesInvoice.CheckCompanyInfo();

        Assert.ExpectedErrorCode(TestFieldErrorCodeTok);
        Assert.ExpectedError(SwiftCodeErr);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceWithRoundingToWholeNumber()
    var
        GLEntry: Record "G/L Entry";
        ExpectedAmount: Text;
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Rounding] [UT]
        // [SCENARIO 376699] E-Invoice document for Sales Invoice should be valid in case of Inv. Rounding Precision to the whole number

        Initialize();

        // [GIVEN] Inv. Rounding Precision to the whole number
        LibraryERM.SetInvRoundingPrecisionLCY(1.0);

        // [GIVEN] A posted sales invoice
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesInvoice();

        GLEntry.SetRange("Document No.", SalesInvoiceNo);
        GLEntry.SetFilter(Amount, '>%1', 0);
        GLEntry.FindLast();

        // [WHEN] Export sales invoice
        NOXMLReadHelper.Initialize(ExecEInvoice(SalesInvoiceNo));

        // [THEN] <LegalMonetaryTotal/TaxInclusiveAmount> = Full amount to pay rounded to whole number
        ExpectedAmount := FormatAmount(GLEntry.Amount);
        NOXMLReadHelper.VerifyNodeValueByXPath('cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_DoNotUse()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '12345' in case of "KID Setup"="Do not use", DocNo='12345'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Do not use", '12345');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_DocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '00000123455' in case of "KID Setup"="Document No.", DocNo='12345'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Document No.", '00000123455');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_DocNoCustNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '000001234500000678909' in case of "KID Setup"="Document No.+Customer No.", DocNo='12345', CustNo='67890'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Document No.+Customer No.", '000001234500000678909');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_DocNoDocType()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '000001234517' in case of "KID Setup"="Document No.+Document Type", DocNo='12345', DocType='1'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Document No.+Document Type", '000001234517');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_CustNoDocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '000006789000000123459' in case of "KID Setup"="Document No.+Customer No.", DocNo='12345', CustNo='67890'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Customer No.+Document No.", '000006789000000123459');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_DocTypeDocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns '100000123453' in case of "KID Setup"="Document No.+Document Type", DocNo='12345', DocType='1'
        GetEInvoiceExportPaymentID_UT(true, SalesReceivablesSetup."KID Setup"::"Document Type+Document No.", '100000123453');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEInvoiceExportPaymentID_UT_CustomDocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID] [UT]
        // [SCENARIO] COD10601 DocumentTools.GetEInvoiceExportPaymentID() returns 'TEST12345' in case of "KID Setup"="Document No.", DocNo='TEST12345'
        GetEInvoiceExportPaymentID_UT(false, SalesReceivablesSetup."KID Setup"::"Document No.", 'TEST12345');
    end;

    local procedure GetDefaultUnitCode(): Text
    begin
        exit('EA');
    end;

    local procedure GetDefaultUnitCodeListID(): Text
    begin
        exit('UNECERec20');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure EInvoiceSalesPaymentIDWithKIDSetupDocNo()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DummyEInvoiceExportHeader: Record "E-Invoice Export Header";
        DocumentTools: Codeunit DocumentTools;
        XmlFileName: Text[1024];
        SalesInvoiceNo: Code[20];
        ExpectedResult: Code[30];
    begin
        // [FEATURE] [KID]
        // [SCENARIO 377047] Verify exported XML "PaymentID" node value in case of "KID Setup"::"Document No."
        Initialize();

        // [GIVEN] Sales Receivables Setup: "KID Setup" = "Document No.", "Document No. length" = 20
        EInvoiceHelper.KIDSetup(SalesReceivablesSetup."KID Setup"::"Document No.", 20, 0);

        // [GIVEN] Posted Sales Invoice No. = "103032"
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesInvoice();

        // [WHEN] Perform "Create Electronic Invoice" on posted Sales Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] Exported XML file has node value "PaymentID" = "000000000000001030329"
        DummyEInvoiceExportHeader."No." := SalesInvoiceNo;
        ExpectedResult := DocumentTools.GetEInvoiceExportPaymentID(DummyEInvoiceExportHeader);
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:PaymentMeans/cbc:PaymentID', ExpectedResult);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceAndLineDiscounts()
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceNo: Code[20];
        XmlFileName: Text[1024];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Discount] [Line Discount]
        // [SCENARIO 259032] Electronic Invoice exports "LineExtensionAmount" xml tag value including invoice/line discount
        Initialize();

        // [GIVEN] Posted sales invoice with Amount = 700, including "Inv. Discount Amount" = 100, "Line Discount Amount" = 200
        SalesInvoiceNo := CreatePostSalesInvoiceWithDiscount(SalesLine, LibraryRandom.RandDecInRange(1000, 2000, 2), 1);

        // [WHEN] Create Electronic Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] XML "LegalMonetaryTotal/LineExtensionAmount" = 1000
        // [THEN] XML "InvoiceLine/LineExtensionAmount" = 1000
        TotalAmount := SalesLine.Amount + SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount";
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', FormatAmount(TotalAmount));
        NOXMLReadHelper.VerifyNodeValue('//cac:InvoiceLine/cbc:LineExtensionAmount', FormatAmount(TotalAmount));
        NOXMLReadHelper.VerifyNodeValue('//cac:InvoiceLine/cbc:InvoicedQuantity', '1.00');
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceAndLineDiscountsForTwoVATGroups()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATProdPostingGroupCode: Code[20];
        SalesInvoiceNo: Code[20];
        XmlFileName: Text[1024];
        DiscountAmount: array[2] of Decimal;
        VATRate: array[5] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [Discount] [Line Discount]
        // [SCENARIO 300762] Electronic Invoice exports "AllowanceCharge" tag value with Discount Amount per each VAT Prod. Posting Group
        Initialize();

        // [GIVEN] Posted sales invoice with Line 1 of Amount = 700, including "Inv. Discount Amount" = 100, "Line Discount Amount" = 200
        // [GIVEN] Posted sales invoice with Line 2 of Amount = 500, including "Inv. Discount Amount" = 30, "Line Discount Amount" = 70
        SetVATRates(2, VATRate);
        EInvoiceHelper.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Your Reference" := Customer."No.";
        SalesHeader.Modify();

        for i := 1 to ArrayLen(SalesLine) do begin
            VATProdPostingGroupCode := EInvoiceSalesHelper.NewVATPostingSetup(VATRate[i], SalesHeader."VAT Bus. Posting Group", false);
            LibrarySales.CreateSalesLine(
              SalesLine[i], SalesHeader, SalesLine[i].Type::Item, EInvoiceHelper.CreateItem(VATProdPostingGroupCode),
              LibraryRandom.RandInt(5));
            UpdateDiscountsInSalesLine(SalesLine[i], LibraryRandom.RandDecInRange(1000, 2000, 2));
            DiscountAmount[i] := SalesLine[i]."Line Discount Amount" + SalesLine[i]."Inv. Discount Amount";
        end;
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Create Electronic Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] XML Node with '//cac:AllowanceCharge/cbc:Amount' has value 300 per Line 1
        // [THEN] XML Node with '//cac:AllowanceCharge/cbc:Amount' has value 100 per Line 2
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:AllowanceCharge/cbc:Amount', FormatAmount(DiscountAmount[1]));
        NOXMLReadHelper.VerifyNextNodeValue('//cac:AllowanceCharge/cbc:Amount', FormatAmount(DiscountAmount[2]), 1);
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure UnitOfMeasureInSalesInvoiceWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 300603] Electronic Invoice exports 'unitCode' EA for line of type G/L Account with blank Unit of Measure code
        Initialize();

        // [GIVEN] Posted sales invoice where G/L Account line with blank Unit of Measure code
        DocumentNo := CreatePostSalesDocumentWithGLAccount(SalesHeader."Document Type"::Invoice);

        // [WHEN] Create Electronic Invoice
        XmlFileName := ExecEInvoice(DocumentNo);

        // [THEN] XML File Header element <InvoicedQuantity> contains default attributes unitCode = 'EA' and listID
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCode', GetDefaultUnitCode());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:InvoicedQuantity', 'unitCodeListID', GetDefaultUnitCodeListID());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure UnitOfMeasureInSalesCreditMemoWithGLAccount()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        XmlFileName: Text[1024];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 300603] Electronic Credit Memo exports 'unitCode' EA for line of type G/L Account with blank Unit of Measure code
        Initialize();

        // [GIVEN] Posted sales credit memo where G/L Account line with blank Unit of Measure code
        DocumentNo := CreatePostSalesDocumentWithGLAccount(SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Create Electronic Credit Memo
        XmlFileName := ExecECrMemo(DocumentNo);

        // [THEN] XML File Header element <CreditedQuantity> contains default attributes unitCode = 'EA' and listID
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCode', GetDefaultUnitCode());
        NOXMLReadHelper.VerifyAttributeValue('//cbc:CreditedQuantity', 'unitCodeListID', GetDefaultUnitCodeListID());
    end;

    [Test]
    [HandlerFunctions('SuccessMsgHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithInvoiceAndLineDiscountsOfFiveDecimalsInQtyAndPrice()
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceNo: Code[20];
        XmlFileName: Text[1024];
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Discount] [Line Discount] [Rounding]
        // [SCENARIO 308547] Electronic Invoice exports Unit Price and Quantity with all decimal places
        Initialize();

        // [GIVEN] Posted sales invoice with Amount = 700, including "Inv. Discount Amount" = 100, "Line Discount Amount" = 200
        // [GIVEN] Unit Price = 1000.98765 and Quantity = 1.23456
        SalesInvoiceNo := CreatePostSalesInvoiceWithDiscount(SalesLine, 1000.98765, 1.23456);

        // [WHEN] Create Electronic Invoice
        XmlFileName := ExecEInvoice(SalesInvoiceNo);

        // [THEN] XML "LegalMonetaryTotal/LineExtensionAmount" = 1000
        // [THEN] XML "InvoiceLine/LineExtensionAmount" = 1000
        // [THEN] XML "InvoiceLine/InvoicedQuantity" = 1.23456
        // [THEN] XML "Price/PriceAmount" = 1000.98765
        TotalAmount := SalesLine.Amount + SalesLine."Line Discount Amount" + SalesLine."Inv. Discount Amount";
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', Format(TotalAmount, 0, 9));
        NOXMLReadHelper.VerifyNodeValue('//cac:InvoiceLine/cbc:LineExtensionAmount', Format(TotalAmount, 0, 9));
        NOXMLReadHelper.VerifyNodeValue('//cac:InvoiceLine/cbc:InvoicedQuantity', '1.23456');
        NOXMLReadHelper.VerifyNodeValue('//cac:Price/cbc:PriceAmount', '1000.98765');
    end;

    [Test]
    [HandlerFunctions('SuccessfullyCreatedElectronicInvoiceMessageHandler')]
    [Scope('OnPrem')]
    procedure ItemNameIsNotTruncatedInElectronicInvoice()
    var
        Item: Record Item;
        PostedSalesInvoiceNo: Text[20];
        XmlFileName: Text[1024];
    begin
        // [SCENARIO 308770] Item line name is not truncated when export posted sales invoice as e-invoice.
        Initialize();

        // [GIVEN] Posted sales invoice with an item.
        CreateAndPostSalesInvoice(Item, PostedSalesInvoiceNo);

        // [WHEN] Create Electronic Invoice.
        XmlFileName := ExecEInvoice(PostedSalesInvoiceNo);

        // [THEN] The value of XML Node with '//cac:InvoiceLine/cac:Item/cbc:Name' is equal to item's description.
        NOXMLReadHelper.Initialize(XmlFileName);
        NOXMLReadHelper.VerifyNodeValue('//cac:InvoiceLine/cac:Item/cbc:Name', Item.Description);
    end;

    local procedure Initialize()
    var
        SalesHeader: Record "Sales Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateGeneralPostingSetupData();
        InitGlobalVATRates();
        ConfigureVATPostingSetup();
        SetCompanySwiftCode();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
        Commit();
    end;

    local procedure GetEInvoiceExportPaymentID_UT(DigitDocNo: Boolean; KIDSetup: Option; ExpectedResult: Code[30])
    var
        EInvoiceExportHeader: Record "E-Invoice Export Header";
        DocumentTools: Codeunit DocumentTools;
    begin
        Initialize();
        EInvoiceHelper.KIDSetup(KIDSetup, 10, 10);

        EInvoiceExportHeader."No." := GetEInvoiceNo(DigitDocNo);
        EInvoiceExportHeader."Bill-to Customer No." := '67890';

        Assert.AreEqual(
          ExpectedResult,
          DocumentTools.GetEInvoiceExportPaymentID(EInvoiceExportHeader),
          EInvoiceExportHeader.FieldCaption("Payment ID"));
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure CreateAndPostSalesInvoice(var Item: Record Item; var PostedSalesInvoiceNo: Text[20])
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        EInvoiceHelper.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Your Reference", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 1));
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostSalesInvoiceWithDiscount(var SalesLine: Record "Sales Line"; UnitPrice: Decimal; Quantity: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        EInvoiceHelper.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Your Reference", SalesHeader."No.");
        SalesHeader.Modify(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, EInvoiceHelper.CreateItem(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        UpdateDiscountsInSalesLine(SalesLine, UnitPrice);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesDocumentWithGLAccount(DocumentType: Enum "Sales Document Type"): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        EInvoiceHelper.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader."Your Reference" := Customer."No.";
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit of Measure Code", '');
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure EInvoiceSalesCrMemo(): Text[1024]
    var
        SalesCrMemoNo: Code[20];
    begin
        SalesCrMemoNo := EInvoiceSalesHelper.CreateSalesCrMemo();
        exit(ExecECrMemo(SalesCrMemoNo));
    end;

    local procedure EInvoiceSalesInvoice(): Text[1024]
    var
        SalesInvoiceNo: Code[20];
    begin
        SalesInvoiceNo := EInvoiceSalesHelper.CreateSalesInvoice();
        exit(ExecEInvoice(SalesInvoiceNo));
    end;

    local procedure ExecEInvoice(SalesInvoiceNo: Code[20]): Text[1024]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceHelper.SetupEInvoiceForSales(Path);

        SalesInvoiceHeader.SetRange("No.", SalesInvoiceNo);
        REPORT.Run(REPORT::"Create Electronic Invoices", false, true, SalesInvoiceHeader);

        exit(Path + SalesInvoiceNo + '.xml');
    end;

    local procedure ExecECrMemo(SalesCrMemoNo: Code[20]): Text[1024]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Path: Text[250];
    begin
        Path := EInvoiceHelper.GetTempPath();
        EInvoiceHelper.SetupEInvoiceForSales(Path);

        SalesCrMemoHeader.SetRange("No.", SalesCrMemoNo);
        REPORT.Run(REPORT::"Create Electronic Credit Memos", false, true, SalesCrMemoHeader);

        exit(Path + SalesCrMemoNo + '.xml');
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, StrSubstNo(FormatTok, 2)));
    end;

    local procedure InitGlobalVATRates()
    begin
        NoTaxRate := 0;
        LowRate := 10;
        ReducedRate := 11.11;
        HighRate := 15;
        StandardRate := 25;
    end;

    local procedure SetCompanySwiftCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(GLN, '1234567890128');
        CompanyInformation.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInformation.Modify(true);
    end;

    local procedure GetCrMemoCustomizationID(): Text[250]
    var
        CustomizationID: Text[250];
    begin
        CustomizationID :=
          'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:' +
          'urn:www.cenbii.eu:profile:biixx:ver2.0:extended:' +
          'urn:www.difi.no:ehf:kreditnota:ver2.0';

        exit(CustomizationID);
    end;

    local procedure GetInvoiceCustomizationID(SalesInvoiceNo: Code[20]): Text[250]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        CustomizationID: Text[250];
    begin
        CustomizationID := 'urn:www.cenbii.eu:transaction:biitrns010:ver2.0:extended:';

        SalesInvoiceHeader.Get(SalesInvoiceNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        CompanyInfo.Get();

        if Customer."Country/Region Code" = CompanyInfo."Country/Region Code" then begin
            CustomizationID += 'urn:www.peppol.eu:bis:peppol4a:ver2.0:extended:';
            CustomizationID += 'urn:www.difi.no:ehf:faktura:ver2.0';
        end else
            CustomizationID += 'urn:www.peppol.eu:bis:peppol4a:ver2.0';
        exit(CustomizationID);
    end;

    local procedure GetEInvoiceNo(IsDigitDocNo: Boolean): Code[20]
    begin
        // Use hardcoded values in order to verify checksum digits
        if IsDigitDocNo then
            exit('12345');
        exit('TEST12345');
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

    local procedure UpdateDiscountsInSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount Amount", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Inv. Discount Amount", LibraryRandom.RandDecInRange(200, 300, 2));
        SalesLine.Modify(true);
    end;

    local procedure VerifyDeliveryOnSalesCrMemo(XMLFileName: Text; XPath: Text; HeaderId: Code[20])
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(HeaderId);
        Customer.Init();
        Customer.Address := SalesCrMemoHeader."Ship-to Address";
        Customer."Address 2" := SalesCrMemoHeader."Ship-to Address 2";
        Customer.City := SalesCrMemoHeader."Ship-to City";
        Customer."Post Code" := SalesCrMemoHeader."Ship-to Post Code";
        Customer."Country/Region Code" := SalesCrMemoHeader."Ship-to Country/Region Code";
        EInvoiceXMLXSDValidation.VerifyAddress(XMLFileName, XPath, Customer);
    end;

    local procedure VerifyDeliveryOnSalesInvoice(XMLFileName: Text; XPath: Text; SalesInvoiceHeaderId: Code[20])
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(SalesInvoiceHeaderId);
        Customer.Init();
        Customer.Address := SalesInvoiceHeader."Ship-to Address";
        Customer."Address 2" := SalesInvoiceHeader."Ship-to Address 2";
        Customer.City := SalesInvoiceHeader."Ship-to City";
        Customer."Post Code" := SalesInvoiceHeader."Ship-to Post Code";
        Customer."Country/Region Code" := SalesInvoiceHeader."Ship-to Country/Region Code";
        EInvoiceXMLXSDValidation.VerifyAddress(XMLFileName, XPath, Customer);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessMsgHandler(Text: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessfullyCreatedMsg, Text);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SuccessfullyCreatedElectronicInvoiceMessageHandler(MessageText: Text[1024])
    begin
        Assert.ExpectedMessage(SuccessfullyCreatedElectronicInvoiceMsg, MessageText);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ChangeBillToCustomerNoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual('Do you want to change %1?', Question, 'Unexpected confirmation message');
        Reply := true;
    end;
}

