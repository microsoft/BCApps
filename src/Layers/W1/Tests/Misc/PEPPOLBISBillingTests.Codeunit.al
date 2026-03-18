codeunit 139145 "PEPPOL BIS BillingTests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [PEPPOL] [BIS Billing]
    end;

    var
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        WrongFileNameErr: Label 'File name should be: %1', Comment = '%1 - Client File Name';

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoiceVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with VAT Registration No. and "External Document No."
        Initialize();

        // [GIVEN] Posted Sales Invoice with "VAT Registration No." = 'BE1234567890' and "External Document No." = "INV01" and text line
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(Customer."No.", SalesHeader."Document Type"::Invoice));
        SalesInvoiceHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Modify();
        MockTextSalesInvoiceLine(SalesInvoiceHeader."No.");

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] PEPPOL BIS identifers are exported in <CustomizationID> and <ProfileID>
        // [THEN] <AccountingCustomerParty> has <CompanyID> = 'BE1234567890'
        // [THEN] <OrderReference> is "INV01"
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyPEPPOLBISIdentifiers('Invoice');
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:CompanyID', Customer."VAT Registration No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('Invoice', 'cac:OrderReference', SalesInvoiceHeader."External Document No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('Invoice', 'cbc:DueDate', Format(SalesInvoiceHeader."Due Date", 0, 9));
        // [THEN] One node 'InvoiceLine' created
        Assert.AreEqual(LibraryXMLRead.GetNodesCount('cac:InvoiceLine'), 1, '');
        // [THEN] <EndpointID> exported as 'BE1234567890' with VAT schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer."VAT Registration No.", GetVATSchemaID(Customer."Country/Region Code"));
        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        VerifyTaxTotalNode('Invoice', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoiceGLN()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with GLN where "External Document No." is blank
        Initialize();

        // [GIVEN] Posted Sales Invoice with "GLN" = '1234567890123' and "External Document No." = blank
        Customer.Get(CreateCustomerWithAddressAndGLN());
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(Customer."No.", SalesHeader."Document Type"::Invoice));
        SalesInvoiceHeader."External Document No." := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <AccountingCustomerParty> has <ID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <OrderReference> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeAbsence('cac:OrderReference');
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_CompInfVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInformation: Record "Company Information";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice when Company Information has VAT Registration No.
        Initialize();

        // [GIVEN] Company has "VAT Registration No." = 'NO1234567890'
        UpdateCompanyVATRegNo();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::Invoice));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <AccountingSupplierParty> has <CompanyID> = 'NO1234567890'
        // [THEN] <PartyTaxScheme> has <CompanyID> = 'NO1234567890'
        CompanyInformation.Get();
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:AccountingSupplierParty', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:PartyTaxScheme', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        // [THEN] <EndpointID> exported as 'NO1234567890' with VAT schema ID (TFS 340767)
        VerifySupplierEndpoint(
          GetCountryPrefix(CompanyInformation."Country/Region Code") + DelChr(CompanyInformation."VAT Registration No."),
          GetVATSchemaID(CompanyInformation."Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_CompInfGLN()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CompanyInformation: Record "Company Information";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice when Company Information has GLN
        Initialize();

        // [GIVEN] Company has GLN = '1234567890123'
        UpdateCompanyGLN();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::Invoice));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <PartyLegalEntity> of <AccountingCustomerParty> has <CompanyID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <PartyTaxScheme> has <CompanyID> = 'NO1234567890'
        CompanyInformation.Get();
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:PartyLegalEntity', 'cbc:CompanyID', CompanyInformation.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:PartyLegalEntity', 'cbc:CompanyID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:PartyTaxScheme', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifySupplierEndpoint(CompanyInformation.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryS()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'S' - ordinary rate
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'S', VAT Percent = 10
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryS(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'S', <Percent> = 10
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryS());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesInvoice(SalesInvoiceHeader));

        // [THEN] 'schemeID' attriute is not exported for TaxCategory (TFS 388773)
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree('cac:TaxTotal', 'cac:TaxCategory', 'schemeID');
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree('cac:InvoiceLine', 'cac:ClassifiedTaxCategory', 'schemeID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'E' - VAT Exempt
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'E'
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryE(), 0));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'E', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryE());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryO()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'O' - no VAT
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'O', VAT Percent = 0
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryO(), 0));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'O'
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        // [THEN] <AccountingSupplierParty> does not contain <PartyTaxScheme>
        // [THEN] <ClassifiedTaxCategory> does not contain <Percent>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryO());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader));
        LibraryXMLRead.VerifyNodeAbsence('cbc:PartyTaxScheme');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('cac:ClassifiedTaxCategory', 'cbc:Percent');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryZ()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'Z' - VAT Exempt for goods not included in the VAT regulations
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'Z'
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryZ(), 0));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'Z', <Percent> = 0
        // [THEN] <TaxExemptionReason> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryZ());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeAbsence('cbc:TaxExemptionReason');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryAE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'AE' - Reverse charge
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'AE' and VAT% = 10
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategoryReverseVAT(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryAE(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'AE', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryAE());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryG()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'G' - Export outside EU
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'G'
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryG(), 0));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'G', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryG());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryL()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'L' // IGIC
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'L', VAT Percent = 7
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryL(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'L', <Percent> = 7
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryL());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryM()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'M' // IPSI
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'M', VAT Percent = 4
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryM(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'M', <Percent> = 4
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryM());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_TaxCategoryK()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Invoice with Tax Category 'K' - intra-community supply
        Initialize();

        // [GIVEN] Posted Sales Invoice with Tax Category 'K', VAT Percent = 0
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::Invoice, GetTaxCategoryK(), 0));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCategory> has <ID> 'K'
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        // [THEN] <AccountingSupplierParty> does not contain <PartyTaxScheme>
        // [THEN] <ClassifiedTaxCategory> does not contain <Percent>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryK());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemoVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with VAT Registration No. and "External Document No."
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "VAT Registration No." = 'BE1234567890' and "External Document No." = "INV01" and text line
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(Customer."No.", SalesHeader."Document Type"::"Credit Memo"));
        SalesCrMemoHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Modify();
        MockTextSalesCrMemoLine(SalesCrMemoHeader."No.");

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] PEPPOL BIS identifers are exported in <CustomizationID> and <ProfileID>
        // [THEN] <AccountingCustomerParty> has <CompanyID> = 'BE1234567890'
        // [THEN] <OrderReference> is "INV01"
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyPEPPOLBISIdentifiers('CreditNote');
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:CompanyID', Customer."VAT Registration No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('CreditNote', 'cac:OrderReference', SalesCrMemoHeader."External Document No.");
        // [THEN] One node 'CreditNoteLine' created
        Assert.AreEqual(LibraryXMLRead.GetNodesCount('cac:CreditNoteLine'), 1, '');
        // [THEN] <EndpointID> exported as 'BE1234567890' with VAT schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer."VAT Registration No.", GetVATSchemaID(Customer."Country/Region Code"));
        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        VerifyTaxTotalNode('CreditNote', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemoGLN()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with GLN where "External Document No." is blank
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "GLN" = '1234567890123' and "External Document No." = blank
        Customer.Get(CreateCustomerWithAddressAndGLN());
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(Customer."No.", SalesHeader."Document Type"::"Credit Memo"));
        SalesCrMemoHeader."External Document No." := '';
        SalesCrMemoHeader.Modify();

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <AccountingCustomerParty> has <ID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <OrderReference> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeAbsence('cac:OrderReference');
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_CompInfVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CompanyInformation: Record "Company Information";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo when Company Information has VAT Registration No.
        Initialize();

        // [GIVEN] Company has "VAT Registration No." = 'NO1234567890'
        UpdateCompanyVATRegNo();

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::"Credit Memo"));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <AccountingSupplierParty> has <CompanyID> = 'NO1234567890'
        // [THEN] <PartyTaxScheme> has <CompanyID> = 'NO1234567890'
        CompanyInformation.Get();
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:AccountingSupplierParty', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:PartyTaxScheme', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        // [THEN] <EndpointID> exported as 'NO1234567890' with VAT schema ID (TFS 340767)
        VerifySupplierEndpoint(
          GetCountryPrefix(CompanyInformation."Country/Region Code") + DelChr(CompanyInformation."VAT Registration No."),
          GetVATSchemaID(CompanyInformation."Country/Region Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_CompInfGLN()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CompanyInformation: Record "Company Information";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo when Company Information has GLN
        Initialize();

        // [GIVEN] Company has GLN = '1234567890123'
        UpdateCompanyGLN();

        // [GIVEN] Posted Sales Credit Memo
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::"Credit Memo"));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <PartyLegalEntity> of <AccountingCustomerParty> has <CompanyID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <PartyTaxScheme> has <CompanyID> = 'NO1234567890'
        CompanyInformation.Get();
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:PartyLegalEntity', 'cbc:CompanyID', CompanyInformation.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:PartyLegalEntity', 'cbc:CompanyID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:PartyTaxScheme', 'cbc:CompanyID', GetCompanyVATRegNo(CompanyInformation));
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifySupplierEndpoint(CompanyInformation.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryS()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'S' - ordinary rate
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'S', VAT Percent = 10
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryS(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'S', <Percent> = 10
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryS());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesCrMemo(SalesCrMemoHeader));

        // [THEN] 'schemeID' attirbute is not exported for TaxCategory (TFS 388773)
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree('cac:TaxTotal', 'cac:TaxCategory', 'schemeID');
        LibraryXMLRead.VerifyAttributeAbsenceInSubtree('cac:CreditNoteLine', 'cac:ClassifiedTaxCategory', 'schemeID');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryE()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'E' - VAT Exempt
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'E'
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryE(), 0));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'E', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryE());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryO()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'O' - no VAT
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'O', VAT Percent = 0
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryO(), 0));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'O'
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        // [THEN] <AccountingSupplierParty> does not contain <PartyTaxScheme>
        // [THEN] <ClassifiedTaxCategory> does not contain <Percent>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryO());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader));
        LibraryXMLRead.VerifyNodeAbsence('cbc:PartyTaxScheme');
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('cac:ClassifiedTaxCategory', 'cbc:Percent');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryZ()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'Z' - VAT Exempt for goods not included in the VAT regulations
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'Z'
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryZ(), 0));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'Z', <Percent> = 0
        // [THEN] <TaxExemptionReason> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryZ());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeAbsence('cbc:TaxExemptionReason');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryAE()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'AE' - Reverse charge
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'AE' and VAT% = 10
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategoryReverseVAT(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryAE(),
            LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'AE', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryAE());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryG()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'G' - Export outside EU
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'G'
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryG(), 0));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'G', <Percent> = 0
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryG());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', 0);
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryL()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'L'
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'L', VAT Percent = 10
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryL(),
            LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'L', <Percent> = 10
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryL());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryM()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'M'
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'M', VAT Percent = 10
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryM(), LibraryRandom.RandIntInRange(10, 20)));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'M', <Percent> = 10
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryM());
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:Percent', GetVATPctPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_TaxCategoryK()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Tax Category]
        // [SCENARIO 281593] PEPPOL BIS3. Export Sales Credit Memo with Tax Category 'K' - intra-community supply
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with Tax Category 'K', VAT Percent = 0
        SalesCrMemoHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::"Credit Memo", GetTaxCategoryK(), 0));

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCategory> has <ID> 'K'
        // [THEN] <TaxCategory> has <TaxExemptionReason>
        // [THEN] <AccountingSupplierParty> does not contain <PartyTaxScheme>
        // [THEN] <ClassifiedTaxCategory> does not contain <Percent>
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:TaxCategory', 'cbc:ID', GetTaxCategoryK());
        LibraryXMLRead.VerifyNodeValueInSubtree(
          'cac:TaxCategory', 'cbc:TaxExemptionReason', GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_ServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 281593] PEPPOL BIS3. Export Service Invoice
        Initialize();

        // [GIVEN] Posted Service Invoice for Customer with GLN = '1234567890123'
        CreatePostServiceInvoice(ServiceInvoiceHeader, '');
        Customer.Get(ServiceInvoiceHeader."Customer No.");

        // [WHEN] Export Service Credit Memo with PEPPOL BIS3
        ServiceInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(ServiceInvoiceHeader, CreateBISElectronicDocumentFormatServiceInvoice());

        // [THEN] <AccountingCustomerParty> has <ID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <OrderReference> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyPEPPOLBISIdentifiers('Invoice');
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeAbsence('cac:OrderReference');
        LibraryXMLRead.VerifyNodeValueInSubtree('Invoice', 'cbc:DueDate', Format(ServiceInvoiceHeader."Due Date", 0, 9));
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_ServiceCrMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 281593] PEPPOL BIS3. Export Service Credit Memo
        Initialize();

        // [GIVEN] Posted Service Credit Memo for Customer with GLN = '1234567890123'
        CreatePostServiceCrMemo(ServiceCrMemoHeader, '');
        Customer.Get(ServiceCrMemoHeader."Customer No.");

        // [WHEN] Export Service Credit Memo with PEPPOL BIS3
        ServiceCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(ServiceCrMemoHeader, CreateBISElectronicDocumentFormatServiceCrMemo());

        // [THEN] <AccountingCustomerParty> has <ID> = '1234567890123' with <SchemeID> = '0088'
        // [THEN] <OrderReference> is not exported
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyPEPPOLBISIdentifiers('CreditNote');
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', Customer.GLN);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingCustomerParty', 'cbc:ID', 'schemeID', GetGLNSchemeID());
        LibraryXMLRead.VerifyNodeAbsence('cac:OrderReference');
        // [THEN] <EndpointID> exported as '1234567890123' with GLN schema ID (TFS 340767)
        VerifyCustomerEndpoint(Customer.GLN, GetGLNSchemeID());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_BlankFields()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 340475] Export PEPPOL BIS3 Sales Invoice when Salesperson and Payment Terms are not defined
        Initialize();

        // [GIVEN] Posted Sales Invoice with blank Salesperson and Payment Terms fields
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::Invoice));
        SalesInvoiceHeader."Salesperson Code" := '';
        SalesInvoiceHeader."Payment Terms Code" := '';
        SalesInvoiceHeader.Modify();

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] 'Contact' node is not exported for 'AccountingSupplierParty'
        // [THEN] 'PaymentTerms' node is not generated
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('cac:AccountingSupplierParty', 'cac:Contact');
        LibraryXMLRead.VerifyNodeAbsence('cac:PaymentTerms');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemo_BlankFields()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 340475] Export PEPPOL BIS3 Sales Credit Memo when Salesperson and Payment Terms are not defined
        Initialize();

        // [GIVEN] Posted Sales Credit Memo with blank Salesperson and Payment Terms fields
        SalesCrMemoHeader.Get(
          CreatePostSalesDoc(CreateCustomerWithAddressAndVATRegNo(), SalesHeader."Document Type"::"Credit Memo"));
        SalesCrMemoHeader."Salesperson Code" := '';
        SalesCrMemoHeader."Payment Terms Code" := '';
        SalesCrMemoHeader.Modify();

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] 'Contact' node is not exported for 'AccountingSupplierParty'
        // [THEN] 'PaymentTerms' node is not generated
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeAbsenceInSubtree('cac:AccountingSupplierParty', 'cac:Contact');
        LibraryXMLRead.VerifyNodeAbsence('cac:PaymentTerms');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoiceFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Currency]
        // [SCENARIO 389982] PEPPOL BIS3. Export Sales Invoice in FCY
        Initialize();

        // [GIVEN] Posted Sales Invoice in FCY
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesDoc(SalesHeader, SalesLine, Customer."No.", SalesHeader."Document Type"::Invoice, CreateCurrencyCode());
        SalesInvoiceHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Modify();

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_SalesCreditMemoFCY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Currency]
        // [SCENARIO 389982] PEPPOL BIS3. Export Sales Credit Memo in FCY
        Initialize();

        // [GIVEN] Posted Sales Credit Memo in FCY
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesDoc(SalesHeader, SalesLine, Customer."No.", SalesHeader."Document Type"::"Credit Memo", CreateCurrencyCode());
        SalesCrMemoHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Modify();

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('CreditNote', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_ServiceInvoiceFCY()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Service] [Invoice] [Currency]
        // [SCENARIO 281593] PEPPOL BIS3. Export Service Invoice in FCY
        Initialize();

        // [GIVEN] Posted Service Invoice in FCY
        CreatePostServiceInvoice(ServiceInvoiceHeader, CreateCurrencyCode());
        Customer.Get(ServiceInvoiceHeader."Customer No.");

        // [WHEN] Export Service Invoice with PEPPOL BIS3
        ServiceInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(ServiceInvoiceHeader, CreateBISElectronicDocumentFormatServiceInvoice());

        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_PEPPOL_BIS3_ServiceCrMemoFCY()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Customer: Record Customer;
        XMLFilePath: Text;
    begin
        // [FEATURE] [Service] [Credit Memo] [FCY]
        // [SCENARIO 281593] PEPPOL BIS3. Export Service Credit Memo in FCY
        Initialize();

        // [GIVEN] Posted Service Credit Memo in FCY
        CreatePostServiceCrMemo(ServiceCrMemoHeader, CreateCurrencyCode());
        Customer.Get(ServiceCrMemoHeader."Customer No.");

        // [WHEN] Export Service Credit Memo with PEPPOL BIS3
        ServiceCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(ServiceCrMemoHeader, CreateBISElectronicDocumentFormatServiceCrMemo());

        // [THEN] <TaxCurrencyCode> is not exported, one <TaxTotal> node in XML (TFS 389982)
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('CreditNote', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_SalesInvoiceLCY_InvRounding_Positive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Invoice Rounding]
        // [SCENARIO 363865] PEPPOL BIS3. Export Sales Invoice with positive invoice rounding
        Initialize();
        // [GIVEN] Invoice Rounging = 0.05 in General Ledger Setup
        UpdateGLSetupInvoiceRounding(0.05);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted Sales Invoice has two lines with Amount = 100.01 and 100.01, VAT% = 25, invoice rounding amount = 0.02.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesHeader(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice, '');
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", GetTaxCategoryS(),
          25, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        SalesInvoiceHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] 'TaxTotal' node has 'cbc:TaxableAmount' = 200.02
        // [THEN] Two 'InvoiceLine' nodes with 'cbc:LineExtensionAmount' = 100.01 and 100.01
        // [THEN] 'LegalMonetaryTotal' node with 'cbc:PayableRoundingAmount' = 0.02 and 'cbc:PayableAmount' = 250.05
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 1);
        VerifyTaxTotalAmounts(200.02, 25, 0, 0);
        VerifyInvoiceLineAmounts(100.01, 25, 1, 1);
        VerifyInvoiceLineAmounts(100.01, 25, 2, 2);
        VerifyLegalMonetaryTotalAmounts(200.02, 200.02, 250.03, 0.02, 250.05);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_SalesInvoiceLCY_InvRounding_Negative()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Invoice Rounding]
        // [SCENARIO 363865] PEPPOL BIS3. Export Sales Invoice with negative invoice rounding
        Initialize();
        // [GIVEN] Invoice Rounging = 0.05 in General Ledger Setup
        UpdateGLSetupInvoiceRounding(0.05);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted Sales Invoice has line with Amount = 100.01, VAT% = 25, invoice rounding amount = -0.01.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesHeader(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice, '');
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", GetTaxCategoryS(), 25, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        SalesInvoiceHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] 'TaxTotal' node has 'cbc:TaxableAmount' = 100.01
        // [THEN] 'InvoiceLine' node with 'cbc:LineExtensionAmount' = 100.01
        // [THEN] 'LegalMonetaryTotal' node with 'cbc:PayableRoundingAmount' = -0.01 and 'cbc:PayableAmount' = 125
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 1);
        VerifyTaxTotalAmounts(100.01, 25, 0, 0);
        VerifyInvoiceLineAmounts(100.01, 25, 0, 1);
        VerifyLegalMonetaryTotalAmounts(100.01, 100.01, 125.01, -0.01, 125);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_SalesInvoiceLCY_InvRounding_NegativeTwoDiffVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Invoice Rounding]
        // [SCENARIO 363865] PEPPOL BIS3. Export Sales Invoice 2 lines with negative invoice rounding
        Initialize();
        // [GIVEN] Invoice Rounging = 0.05 in General Ledger Setup
        UpdateGLSetupInvoiceRounding(0.05);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted Sales Invoice has two lines: Amount = 100.01, VAT% = 25, Amount = 100.01, VAT% = 10, invoice rounding amount = -0.01.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesHeader(SalesHeader, Customer."No.", SalesHeader."Document Type"::Invoice, '');
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", GetTaxCategoryS(), 25, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", GetTaxCategoryS(), 10, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        SalesInvoiceHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] Two 'TaxTotal' nodes with 'cbc:TaxableAmount' = 100.01
        // [THEN] Two 'InvoiceLine' nodes with 'cbc:LineExtensionAmount' = 100.01 and 100.01
        // [THEN] 'LegalMonetaryTotal' node with 'cbc:PayableRoundingAmount' = -0.02 and 'cbc:PayableAmount' = 235
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 2);
        VerifyTaxTotalAmounts(100.01, 10, 0, 0);
        VerifyTaxTotalAmounts(100.01, 25, 1, 1);
        VerifyInvoiceLineAmounts(100.01, 25, 1, 2);
        VerifyInvoiceLineAmounts(100.01, 10, 2, 3);
        VerifyLegalMonetaryTotalAmounts(200.02, 200.02, 235.02, -0.02, 235);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_SalesCrMemoLCY_InvRounding_Positive()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Credit Memo] [Invoice Rounding]
        // [SCENARIO 363865] PEPPOL BIS3. Export Sales Credit Memo with positive invoice rounding
        Initialize();
        // [GIVEN] Invoice Rounging = 0.05 in General Ledger Setup
        UpdateGLSetupInvoiceRounding(0.05);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted Sales Credit Memo has two lines with Amount = 100.01 and 100.01, VAT% = 25, invoice rounding amount = 0.02.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesHeader(SalesHeader, Customer."No.", SalesHeader."Document Type"::"Credit Memo", '');
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", GetTaxCategoryS(), 25, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        CreateSalesLineWithVAT(SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        SalesCrMemoHeader.Get(
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.CalcFields("Amount Including VAT");

        // [WHEN] Export Sales Credit Memo with PEPPOL BIS3
        SalesCrMemoHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesCrMemoHeader, CreateBISElectronicDocumentFormatSalesCrMemo());

        // [THEN] 'TaxTotal' node has 'cbc:TaxableAmount' = 200.02
        // [THEN] Two 'InvoiceLine' nodes with 'cbc:LineExtensionAmount' = 100.01 and 100.01
        // [THEN] 'LegalMonetaryTotal' node with 'cbc:PayableRoundingAmount' = 0.02 and 'cbc:PayableAmount' = 250.05
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('CreditNote', 1);
        VerifyTaxTotalAmounts(200.02, 25, 0, 0);
        VerifyInvoiceLineAmounts(100.01, 25, 1, 1);
        VerifyInvoiceLineAmounts(100.01, 25, 2, 2);
        VerifyLegalMonetaryTotalAmounts(200.02, 200.02, 250.03, 0.02, 250.05);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXml_ServiceInvoiceLCY_InvRounding_Positive()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        XMLFilePath: Text;
    begin
        // [FEATURE] [Invoice] [Invoice Rounding] [Service]
        // [SCENARIO 486744] PEPPOL BIS3. Export Service Invoice with positive invoice rounding
        Initialize();
        // [GIVEN] Invoice Rounging = 0.05 in General Ledger Setup
        UpdateGLSetupInvoiceRounding(0.05);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted Service Invoice has two lines with Amount = 100.01 and 100.01, VAT% = 25, invoice rounding amount = 0.02.
        Customer.Get(CreateCustomerWithAddressAndGLN());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceHeader.Validate("Due Date", LibraryRandom.RandDate(10));
        ServiceHeader.Modify(true);
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, ServiceHeader."VAT Bus. Posting Group", GetTaxCategoryS(),
          25, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateServiceLineWithVAT(ServiceLine, ServiceHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        CreateServiceLineWithVAT(ServiceLine, ServiceHeader, VATPostingSetup."VAT Prod. Posting Group", 100.01);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();

        // [WHEN] Export Service Invoice with PEPPOL BIS3
        ServiceInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(ServiceInvoiceHeader, CreateBISElectronicDocumentFormatServiceInvoice());

        // [THEN] 'TaxTotal' node has 'cbc:TaxableAmount' = 200.02
        // [THEN] Two 'InvoiceLine' nodes with 'cbc:LineExtensionAmount' = 100.01 and 100.01
        // [THEN] 'LegalMonetaryTotal' node with 'cbc:PayableRoundingAmount' = 0.02 and 'cbc:PayableAmount' = 250.05
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalNode('Invoice', 1);
        VerifyTaxTotalAmounts(200.02, 25, 0, 0);
        VerifyInvoiceLineAmounts(100.01, 25, 1, 1);
        VerifyInvoiceLineAmounts(100.01, 25, 2, 2);
        VerifyLegalMonetaryTotalAmounts(200.02, 200.02, 250.03, 0.02, 250.05);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportXmlToVerifyFileName()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        FileMgt: Codeunit "File Management";
        ActualClientFileName: Text;
        ExpectedClientFileName: Text;
    begin
        // [SCENARIO 435433] To verify if file name with Electronic Document option from Posted Sales Invoice is following a nomenclature : CompanyName - Invoice Document No.xml
        Initialize();

        // [GIVEN] Create a Posted Sales Invoice document.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        SalesInvoiceHeader.Get(
          CreatePostSalesDoc(Customer."No.", SalesHeader."Document Type"::Invoice));
        SalesInvoiceHeader."External Document No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Your Reference" := LibraryRandom.RandText(35);
        SalesInvoiceHeader.Modify();
        MockTextSalesInvoiceLine(SalesInvoiceHeader."No.");
        ExpectedClientFileName := CopyStr(
            StrSubstNo('%1 - %2 %3.%4', FileMgt.StripNotsupportChrInFileName(CompanyName), Format("Sales Document Type"::Invoice), SalesInvoiceHeader."No.", 'XML'), 1, 250);

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        ActualClientFileName := GetXMLExportFileName(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] Client File Name should be CompanyName - Invoice Document No.xml
        Assert.AreEqual(ExpectedClientFileName, ActualClientFileName, StrSubstNo(WrongFileNameErr, ExpectedClientFileName));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccountingSupplierPartyLegalEntity_VATRegNo_DK()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        PEPPOLMgt: Codeunit "PEPPOL Management";
        PartyLegalEntityRegName: Text;
        PartyLegalEntityCompanyID: Text;
        PartyLegalEntitySchemeID: Text;
        SupplierRegAddrCityName: Text;
        SupplierRegAddrCountryIdCode: Text;
        SupplRegAddrCountryIdListId: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 533311] DK VAT Registration No. always should have a prefix in Supplier Legal Entity.
        Initialize();

        // [GIVEN] Company Information with DK VAT Registration No. = '12345678'
        CompanyInfo.Get();
        CompanyInfo.GLN := '';
        CompanyInfo."Use GLN in Electronic Document" := true;
        CompanyInfo.Validate("Country/Region Code", GetISOCountryCodeDK());
        CompanyInfo."VAT Registration No." := Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        CompanyInfo.Modify();

        // [WHEN] Get Accounting Supplier Party Legal Entity
        PEPPOLMgt.GetAccountingSupplierPartyLegalEntityBIS(
          PartyLegalEntityRegName, PartyLegalEntityCompanyID, PartyLegalEntitySchemeID, SupplierRegAddrCityName,
          SupplierRegAddrCountryIdCode, SupplRegAddrCountryIdListId);

        // [THEN] VAT Registration No. should have a prefix, , SchemaID is taken from CountryRegion (0184)
        CountryRegion.Get(CompanyInfo."Country/Region Code");
        Assert.AreEqual(CompanyInfo.Name, PartyLegalEntityRegName, '');
        Assert.AreEqual(GetISOCountryCodeDK() + CompanyInfo."VAT Registration No.", PartyLegalEntityCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", PartyLegalEntitySchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAccountingCustomerPartyLegalEntity_VATRegNo_DK()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        PEPPOLMgt: Codeunit "PEPPOL Management";
        CustPartyLegalEntityRegName: Text;
        CustPartyLegalEntityCompanyID: Text;
        CustPartyLegalEntityIDSchemeID: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 533311] DK VAT Registration No. always should have a prefix in Customer Legal Entity.
        Initialize();

        // [GIVEN] Customer with DK VAT Registration No. = '12345678'
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := GetISOCountryCodeDK();
        Customer."VAT Registration No." := Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        Customer.GLN := '';
        Customer."Use GLN in Electronic Document" := true;
        Customer.Modify();

        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Validate("VAT Registration No.", Customer."VAT Registration No.");

        // [WHEN] Get Accounting Customer Party Legal Entity
        PEPPOLMgt.GetAccountingCustomerPartyLegalEntityBIS(
          SalesHeader, CustPartyLegalEntityRegName, CustPartyLegalEntityCompanyID, CustPartyLegalEntityIDSchemeID);

        // [THEN] VAT Registration No. should have a prefix, SchemaID is taken from CountryRegion (0184)
        CountryRegion.Get(Customer."Country/Region Code");
        Assert.AreEqual(Customer.Name, CustPartyLegalEntityRegName, '');
        Assert.AreEqual(GetISOCountryCodeDK() + Customer."VAT Registration No.", CustPartyLegalEntityCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CustPartyLegalEntityIDSchemeID, '');
    end;

    [Test]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoiceDocumentAttachment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        RecordRef: RecordRef;
        XMLFilePath: Text;
        InStream: InStream;
        OutStream: OutStream;
    begin
        // [FEATURE] [Invoice] [Document Attachment]
        //
        Initialize();

        // [GIVEN] Posted Sales Invoice
        SalesInvoiceHeader.Get(
          CreatePostSalesDocWithTaxCategory(
            CreateCustomerWithAddressAndGLN(), SalesHeader."Document Type"::Invoice, GetTaxCategoryS(), LibraryRandom.RandIntInRange(10, 20)));

        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('Test');
        TempBlob.CreateInStream(InStream);
        RecordRef.GetTable(SalesInvoiceHeader);
        DocumentAttachment.SaveAttachmentFromStream(InStream, RecordRef, 'Test.pdf');

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN]
        LibraryXMLRead.Initialize(XMLFilePath);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AdditionalDocumentReference', 'cbc:ID', SalesInvoiceHeader."No.");
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:Attachment', 'cbc:EmbeddedDocumentBinaryObject', Base64Convert.ToBase64('Test'));
    end;

    [Test]
    procedure ExportXml_PEPPOL_BIS3_SalesInvoice_CheckTaxTotalWhenUnitPriceZero()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        XMLFilePath: Text;
        VatPer: Decimal;
    begin
        // [SCENARIO 580032] Peppol invoice with zero amount not generated correctly and does not pass validation.
        Initialize();

        // [GIVEN] Posted Sales Invoice.
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        CreateSalesDocWithItemAndZeroUnitOrice(SalesHeader, SalesLine, Customer."No.", SalesHeader."Document Type"::Invoice, CreateCurrencyCode());
        VatPer := SalesLine."VAT %";
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Export Sales Invoice with PEPPOL BIS3
        SalesInvoiceHeader.SetRecFilter();
        XMLFilePath := PEPPOLXMLExport(SalesInvoiceHeader, CreateBISElectronicDocumentFormatSalesInvoice());

        // [THEN] Verify Tax Total Amounts
        LibraryXMLRead.Initialize(XMLFilePath);
        VerifyTaxTotalAmounts(0, VatPer, 0, 0);
    end;

    local procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"PEPPOL BIS BillingTests");

        if not IsInitialized then begin
            LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"PEPPOL BIS BillingTests");
            CompanyInfo.Get();
            CompanyInfo.Validate(IBAN, 'GB29NWBK60161331926819');
            CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
            CompanyInfo.Validate("Bank Branch No.", '1234');

            if CompanyInfo."VAT Registration No." = '' then
                CompanyInfo."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInfo."Country/Region Code");
            CompanyInfo.Validate("Use GLN in Electronic Document", true);
            CompanyInfo.Modify(true);

            ConfigureVATPostingSetup();

            AddCompPEPPOLIdentifier();

            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateGeneralLedgerSetup();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            LibraryERMCountryData.UpdateSalesReceivablesSetup();
            LibraryERMCountryData.UpdateLocalData();
            UpdateElectronicDocumentFormatSetup();
            LibraryService.SetupServiceMgtNoSeries();
            LibrarySetupStorage.Save(DATABASE::"Company Information");
            LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

            IsInitialized := true;
            LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"PEPPOL BIS BillingTests");
        end;
    end;

    local procedure AddCustPEPPOLIdentifier(CustNo: Code[20])
    var
        Cust: Record Customer;
    begin
        Cust.Get(CustNo);
        Cust.Validate(GLN, '1234567891231');
        Cust.Modify(true);
    end;

    local procedure CreateCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Init();
        Currency.Validate(Code, LibraryUtility.GenerateRandomAlphabeticText(3, 0));
        if not Currency.Insert(true) then
            exit(Currency.Code);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateElectronicDocumentFormatSetup(NewCode: Code[20]; NewUsage: Enum "Electronic Document Format Usage"; NewCodeunitID: Integer): Code[20]
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := NewCode;
        ElectronicDocumentFormat.Usage := NewUsage;
        ElectronicDocumentFormat."Codeunit ID" := NewCodeunitID;
        if ElectronicDocumentFormat.Insert() then;
        exit(ElectronicDocumentFormat.Code);
    end;

    local procedure CreateBISElectronicDocumentFormatSalesInvoice(): Code[20]
    begin
        exit(
          CreateElectronicDocumentFormatSetup(
            LibraryUtility.GenerateGUID(), "Electronic Document Format Usage"::"Sales Invoice", CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0"));
    end;

    local procedure CreateBISElectronicDocumentFormatSalesCrMemo(): Code[20]
    begin
        exit(
          CreateElectronicDocumentFormatSetup(
            LibraryUtility.GenerateGUID(), "Electronic Document Format Usage"::"Sales Credit Memo", CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0"));
    end;

    local procedure CreateBISElectronicDocumentFormatServiceInvoice(): Code[20]
    begin
        exit(
          CreateElectronicDocumentFormatSetup(
            LibraryUtility.GenerateGUID(), "Electronic Document Format Usage"::"Service Invoice", CODEUNIT::"Exp. Serv.Inv. PEPPOL BIS3.0"));
    end;

    local procedure CreateBISElectronicDocumentFormatServiceCrMemo(): Code[20]
    begin
        exit(
          CreateElectronicDocumentFormatSetup(
            LibraryUtility.GenerateGUID(), "Electronic Document Format Usage"::"Service Credit Memo", CODEUNIT::"Exp. Serv.CrM. PEPPOL BIS3.0"));
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    local procedure AddCompPEPPOLIdentifier()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.Validate(GLN, '1234567891231');
        CompanyInfo.Modify(true);
    end;

    local procedure CreatePostSalesDoc(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDoc(SalesHeader, SalesLine, CustomerNo, DocumentType, '');
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    begin
        CreateSalesHeader(SalesHeader, CustomerNo, DocumentType, CurrencyCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), DATABASE::"Sales Header"));
        SalesHeader.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineWithVAT(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroup: Code[20]; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceLineWithVAT(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; VATProdPostingGroup: Code[20]; UnitPrice: Decimal)
    begin
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.Modify(true);
    end;

    local procedure CreatePostSalesDocWithTaxCategory(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; TaxCategory: Code[10]; VATPct: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDoc(SalesHeader, SalesLine, CustomerNo, DocumentType, '');
        SalesLine.Validate(
          "VAT Prod. Posting Group", CreateVATPostingSetupWithTaxCategory(SalesHeader."VAT Bus. Posting Group", TaxCategory, VATPct));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesDocWithTaxCategoryReverseVAT(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; TaxCategory: Code[10]; VATPct: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDoc(SalesHeader, SalesLine, CustomerNo, DocumentType, '');
        SalesLine.Validate(
          "VAT Prod. Posting Group",
          CreateVATPostingSetupWithTaxCategoryReverseVAT(SalesHeader."VAT Bus. Posting Group", TaxCategory, VATPct));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostServiceInvoice(var ServiceInvoiceHeader: Record "Service Invoice Header"; CurrencyCode: Code[10])
    var
        DummyServiceHeader: Record "Service Header";
    begin
        ServiceInvoiceHeader.SetRange(
          "Pre-Assigned No.", CreatePostServiceDoc(DummyServiceHeader."Document Type"::Invoice, CurrencyCode));
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure CreatePostServiceCrMemo(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; CurrencyCode: Code[10])
    var
        DummyServiceHeader: Record "Service Header";
    begin
        ServiceCrMemoHeader.SetRange(
          "Pre-Assigned No.", CreatePostServiceDoc(DummyServiceHeader."Document Type"::"Credit Memo", CurrencyCode));
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure CreatePostServiceDoc(DocumentType: Enum "Service Document Type"; CurrencyCode: Code[10]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomerWithAddressAndGLN());
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        ServiceHeader.Validate("Due Date", LibraryRandom.RandDate(10));
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    local procedure CreateCustomerWithAddressAndGLN(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomerWithAddressAndVATRegNo());
        AddCustPEPPOLIdentifier(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithAddressAndVATRegNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer."Use GLN in Electronic Document" := true;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateVATPostingSetupWithTaxCategory(VATBusPostGr: Code[20]; TaxCategory: Code[10]; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, VATBusPostGr, TaxCategory, VATPct, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetupWithTaxCategoryReverseVAT(VATBusPostGr: Code[20]; TaxCategory: Code[10]; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetupWithTATCalcType(
          VATPostingSetup, VATBusPostGr, TaxCategory, VATPct, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetupWithTATCalcType(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostGr: Code[20]; TaxCategory: Code[10]; VATPct: Decimal; VATCalcType: Enum "Tax Calculation Type"): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGr, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := LibraryUtility.GenerateGUID(); // skip check relation
        VATPostingSetup.Validate("VAT Calculation Type", VATCalcType);
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    local procedure GetISOCountryCodeDK(): Code[10]
    begin
        exit('DK');
    end;

    local procedure GetCompanyVATRegNo(CompanyInformation: Record "Company Information"): Text
    begin
        exit(CompanyInformation."Country/Region Code" + DelChr(CompanyInformation."VAT Registration No."));
    end;

    local procedure GetGLNSchemeID(): Text
    begin
        exit('0088');
    end;

    local procedure GetGNLID(): Code[13]
    begin
        exit('0399999000208');
    end;

    local procedure GetVATPctPostedSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        exit(SalesInvoiceLine."VAT %");
    end;

    local procedure GetVATPctPostedSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Decimal
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        exit(SalesCrMemoLine."VAT %");
    end;

    local procedure GetExemptReasonPostedSalesInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VATProductPostingGroup.Get(SalesInvoiceLine."VAT Prod. Posting Group");
        exit(VATProductPostingGroup.Description);
    end;

    local procedure GetExemptReasonPostedSalesCrMemo(SalesCrMemoHeader: Record "Sales Cr.Memo Header"): Text
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        VATProductPostingGroup.Get(SalesCrMemoLine."VAT Prod. Posting Group");
        exit(VATProductPostingGroup.Description);
    end;

    local procedure GetTaxCategoryS(): Text[10]
    begin
        exit('S');
    end;

    local procedure GetTaxCategoryE(): Text[10]
    begin
        exit('E');
    end;

    local procedure GetTaxCategoryK(): Text[10]
    begin
        exit('K');
    end;

    local procedure GetTaxCategoryL(): Text[10]
    begin
        exit('L');
    end;

    local procedure GetTaxCategoryM(): Text[10]
    begin
        exit('M');
    end;

    local procedure GetTaxCategoryO(): Text[10]
    begin
        exit('O');
    end;

    local procedure GetTaxCategoryZ(): Text[10]
    begin
        exit('Z');
    end;

    local procedure GetTaxCategoryAE(): Text[10]
    begin
        exit('AE');
    end;

    local procedure GetTaxCategoryG(): Text[10]
    begin
        exit('G');
    end;

    local procedure GetVATSchemaID(CountryCode: Code[20]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        exit(CountryRegion."VAT Scheme");
    end;

    local procedure MockTextSalesInvoiceLine(DocumentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.Init();
        SalesInvoiceLine."Document No." := DocumentNo;
        SalesInvoiceLine."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Line No."));
        SalesInvoiceLine.Description := LibraryUtility.GenerateGUID();
        SalesInvoiceLine.Insert();
    end;

    local procedure MockTextSalesCrMemoLine(DocumentNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."Document No." := DocumentNo;
        SalesCrMemoLine."Line No." := LibraryUtility.GetNewRecNo(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Line No."));
        SalesCrMemoLine.Description := LibraryUtility.GenerateGUID();
        SalesCrMemoLine.Insert();
    end;

    local procedure PEPPOLXMLExport(DocumentVariant: Variant; FormatCode: Code[20]): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        ServerFileName: Text[250];
        ClientFileName: Text[250];
    begin
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, FormatCode);
        ServerFileName := CopyStr(FileManagement.ServerTempFileName('xml'), 1, 250);
        FileManagement.BLOBExportToServerFile(TempBlob, ServerFileName);
        exit(ServerFileName);
    end;

    local procedure UpdateCompanyGLN()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.GLN := GetGNLID();
        CompanyInformation.Modify();
    end;

    local procedure UpdateCompanyVATRegNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.GLN := '';
        CompanyInformation.Modify();
    end;

    local procedure UpdateGLSetupInvoiceRounding(InvoiceRounding: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Type (LCY)", GeneralLedgerSetup."Inv. Rounding Type (LCY)"::Nearest);
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", InvoiceRounding);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateElectronicDocumentFormatSetup()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        CreateElectronicDocumentFormatSetup(
          'PEPPOL BIS3', ElectronicDocumentFormat.Usage::"Sales Invoice", CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0");
        CreateElectronicDocumentFormatSetup(
          'PEPPOL BIS3', ElectronicDocumentFormat.Usage::"Sales Credit Memo", CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0");
        CreateElectronicDocumentFormatSetup(
          'PEPPOL BIS3', ElectronicDocumentFormat.Usage::"Service Invoice", CODEUNIT::"Exp. Serv.Inv. PEPPOL BIS3.0");
        CreateElectronicDocumentFormatSetup(
          'PEPPOL BIS3', ElectronicDocumentFormat.Usage::"Service Credit Memo", CODEUNIT::"Exp. Serv.CrM. PEPPOL BIS3.0");
    end;

    local procedure VerifyPEPPOLBISIdentifiers(RootNode: Text)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree(
          RootNode, 'cbc:CustomizationID', 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0');
        LibraryXMLRead.VerifyNodeValueInSubtree(RootNode, 'cbc:ProfileID', 'urn:fdc:peppol.eu:2017:poacc:billing:01:1.0');
    end;

    local procedure VerifySupplierEndpoint(EndpointID: Text; schemeID: Text)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingSupplierParty', 'cbc:EndpointID', EndpointID);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingSupplierParty', 'cbc:EndpointID', 'schemeID', schemeID);
    end;

    local procedure VerifyCustomerEndpoint(EndpointID: Text; schemeID: Text)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:AccountingCustomerParty', 'cbc:EndpointID', EndpointID);
        LibraryXMLRead.VerifyAttributeValueInSubtree('cac:AccountingCustomerParty', 'cbc:EndpointID', 'schemeID', schemeID);
    end;

    local procedure VerifyTaxTotalNode(DocumentType: Text; SubTotalQty: Integer)
    begin
        LibraryXMLRead.VerifyElementAbsenceInSubtree(DocumentType, 'cbc:TaxCurrencyCode');
        Assert.AreEqual(1, LibraryXMLRead.GetNodesCount('cac:TaxTotal'), '');
        Assert.AreEqual(SubTotalQty, LibraryXMLRead.GetNodesCount('cac:TaxSubtotal'), '');
    end;

    local procedure VerifyTaxTotalAmounts(TaxableAmount: Decimal; VATPct: Decimal; IdxAmount: Integer; IdxPct: Integer)
    begin
        Assert.AreEqual(Format(TaxableAmount), LibraryXMLRead.GetNodeValueAtIndex('cbc:TaxableAmount', IdxAmount), '');
        Assert.AreEqual(Format(VATPct), LibraryXMLRead.GetNodeValueAtIndex('cbc:Percent', IdxPct), '');
    end;

    local procedure VerifyInvoiceLineAmounts(LineExtensionAmount: Decimal; VATPct: Decimal; IdxAmount: Integer; IdxPct: Integer)
    begin
        Assert.AreEqual(Format(LineExtensionAmount), LibraryXMLRead.GetNodeValueAtIndex('cbc:LineExtensionAmount', IdxAmount), '');
        Assert.AreEqual(Format(VATPct), LibraryXMLRead.GetNodeValueAtIndex('cbc:Percent', IdxPct), '');
    end;

    local procedure VerifyLegalMonetaryTotalAmounts(LineExtensionAmount: Decimal; TaxExclusiveAmount: Decimal; TaxInclusiveAmount: Decimal; PayableRoundingAmount: Decimal; PayableAmount: Decimal)
    begin
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:LineExtensionAmount', LineExtensionAmount);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxExclusiveAmount', TaxExclusiveAmount);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:TaxInclusiveAmount', TaxInclusiveAmount);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:PayableRoundingAmount', PayableRoundingAmount);
        LibraryXMLRead.VerifyNodeValueInSubtree('cac:LegalMonetaryTotal', 'cbc:PayableAmount', PayableAmount);
    end;

    local procedure GetCountryPrefix(CountryCode: Code[10]): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CountryCode) then
            exit('');
        if CountryRegion."ISO Code" = 'DK' then
            exit('DK');
        exit('');
    end;

    local procedure GetXMLExportFileName(DocumentVariant: Variant; FormatCode: Code[20]): Text
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        ElectronicDocumentFormat.SendElectronically(TempBlob, ClientFileName, DocumentVariant, FormatCode);
        exit(ClientFileName);
    end;

    local procedure CreateSalesDocWithItemAndZeroUnitOrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateSalesHeader(SalesHeader, CustomerNo, DocumentType, CurrencyCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 0);
        SalesLine.Modify(true);
    end;
}
