codeunit 144025 "Test Enterprise No and Branch"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Enterprise No]
    end;

    var
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        BillToNameMustHaveValueErr: Label 'Bill-to Name must have a value';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoMustBe10Digits()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize();

        CompanyInformation.Init();
        CompanyInformation.FindFirst();
        asserterror CompanyInformation.Validate("Enterprise No.", '200.068.636');
        CompanyInformation.Validate("Enterprise No.", '0200.068.636');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoIsResetWhenEnterpriseNoIsSet()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize();

        CompanyInformation.Init();
        CompanyInformation.FindFirst();
        CompanyInformation.Validate("Enterprise No.", '');
        CompanyInformation."VAT Registration No." := LibraryBEHelper.CreateVatRegNo(GetCountryBE());

        Assert.AreNotEqual('', CompanyInformation."VAT Registration No.", '');
        CompanyInformation.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.AreEqual('', CompanyInformation."VAT Registration No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetNonMod7NumberAsEnterpriseNo()
    var
        CompanyInformation: Record "Company Information";
    begin
        Initialize();

        CompanyInformation.Init();
        CompanyInformation.FindFirst();

        asserterror CompanyInformation.Validate("Enterprise No.", '0123456789');
        Assert.ExpectedError('Enterprise');

        asserterror CompanyInformation.Validate("Enterprise No.", 'SampleEnNo');
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldBeSetOnBelgianCustomer()
    var
        Customer: Record Customer;
        EnterpriseNo: Code[20];
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryBE());
        Customer.Modify();

        asserterror Customer.Validate("VAT Registration No.", LibraryBEHelper.CreateVatRegNo(GetCountryBE()));
        Assert.ExpectedError('Enterprise');

        EnterpriseNo := LibraryBEHelper.CreateEnterpriseNo();
        Customer.Validate("Enterprise No.", EnterpriseNo);

        Assert.AreEqual(EnterpriseNo, Customer."Enterprise No.", 'Enterprise number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoIsResetWhenEnterpriseNoIsSetOnBelgianCustomer()
    var
        Customer: Record Customer;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryBE());
        Customer.Modify();

        Customer.Validate("Enterprise No.", '');
        Customer."VAT Registration No." := LibraryBEHelper.CreateVatRegNo(GetCountryBE());

        Assert.AreNotEqual('', Customer."VAT Registration No.", '');
        Customer.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.AreEqual('', Customer."VAT Registration No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetNonMod7NumberAsEnterpriseNoOnBelgianCustomer()
    var
        Customer: Record Customer;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryBE());
        Customer.Modify();

        asserterror Customer.Validate("Enterprise No.", '0123456789');
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldNotBeSetOnNonBelgianCustomer()
    var
        Customer: Record Customer;
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryEU());
        Customer.Modify();

        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code"));

        asserterror Customer.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.ExpectedError('Enterprise');

        // a string can be set as the enterprise no.
        Customer.Validate("Enterprise No.", 'junk');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindVEndorByEnterpriseNo()
    var
        Vendor: Record Vendor;
        LibraryBEHelper: Codeunit "Library - BE Helper";
        EnterpriseNo: Code[20];
        VendorNoToFind: Code[20];

    begin
        // [GIVEN] A Vendor with a valid Enterprise No.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryBE());
        Vendor.Modify();

        Vendor.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        EnterpriseNo := Vendor."Enterprise No.";
        Vendor.Modify();

        // [When] Find Vendor by Enterprise No.
        VendorNoToFind := Vendor.FindVendorByVATRegistrationNo(EnterpriseNo);

        Assert.AreEqual(EnterpriseNo, Vendor."Enterprise No.", 'Enterprise number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoCanBeSetOnNonBelgianCustomer()
    var
        Customer: Record Customer;
        VATNo: Code[20];
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryEU());
        Customer.Modify();

        VATNo := LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code");
        Customer.Validate("VAT Registration No.", VATNo);

        Assert.AreEqual(VATNo, Customer."VAT Registration No.", 'VAT Registration number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldBeSetOnBelgianVendor()
    var
        Vendor: Record Vendor;
        EnterpriseNo: Code[20];
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryBE());
        Vendor.Modify();

        asserterror Vendor.Validate("VAT Registration No.", LibraryBEHelper.CreateVatRegNo(GetCountryBE()));
        Assert.ExpectedError('Enterprise');

        EnterpriseNo := LibraryBEHelper.CreateEnterpriseNo();
        Vendor.Validate("Enterprise No.", EnterpriseNo);

        Assert.AreEqual(EnterpriseNo, Vendor."Enterprise No.", 'Enterprise number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoIsResetWhenEnterpriseNoIsSetOnBelgianVendor()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryBE());
        Vendor.Modify();

        Vendor.Validate("Enterprise No.", '');
        Vendor."VAT Registration No." := LibraryBEHelper.CreateVatRegNo(GetCountryBE());

        Assert.AreNotEqual('', Vendor."VAT Registration No.", '');
        Vendor.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.AreEqual('', Vendor."VAT Registration No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetNonMod7NumberAsEnterpriseNoOnBelgianVendor()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryBE());
        Vendor.Modify();

        asserterror Vendor.Validate("Enterprise No.", '0123456789');
        Assert.ExpectedError('Enterprise');

        asserterror Vendor.Validate("Enterprise No.", 'SampleEnNo');
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldNotBeSetOnNonBelgianVendor()
    var
        Vendor: Record Vendor;
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryEU());
        Vendor.Modify();

        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Vendor."Country/Region Code"));

        asserterror Vendor.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoCanBeSetOnNonBelgianVendor()
    var
        Vendor: Record Vendor;
        VATNo: Code[20];
    begin
        Initialize();

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", GetCountryEU());
        Vendor.Modify();

        VATNo := LibraryERM.GenerateVATRegistrationNo(Vendor."Country/Region Code");
        Vendor.Validate("VAT Registration No.", VATNo);

        Assert.AreEqual(VATNo, Vendor."VAT Registration No.", 'VAT Registration number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldBeSetOnBelgianContact()
    var
        Contact: Record Contact;
        EnterpriseNo: Code[20];
    begin
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", GetCountryBE());
        Contact.Modify();

        asserterror Contact.Validate("VAT Registration No.", LibraryBEHelper.CreateVatRegNo(GetCountryBE()));
        Assert.ExpectedError('Enterprise');

        EnterpriseNo := LibraryBEHelper.CreateEnterpriseNo();
        Contact.Validate("Enterprise No.", EnterpriseNo);

        Assert.AreEqual(EnterpriseNo, Contact."Enterprise No.", 'Enterprise number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoIsResetWhenEnterpriseNoIsSetOnBelgianContact()
    var
        Contact: Record Contact;
    begin
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", GetCountryBE());
        Contact.Modify();

        Contact.Validate("Enterprise No.", '');
        Contact."VAT Registration No." := LibraryBEHelper.CreateVatRegNo(GetCountryBE());

        Assert.AreNotEqual('', Contact."VAT Registration No.", '');
        Contact.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.AreEqual('', Contact."VAT Registration No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetNonMod7NumberAsEnterpriseNoOnBelgianContact()
    var
        Contact: Record Contact;
    begin
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", GetCountryBE());
        Contact.Modify();

        asserterror Contact.Validate("Enterprise No.", '0123456789');
        Assert.ExpectedError('Enterprise');

        asserterror Contact.Validate("Enterprise No.", 'SampleEnNo');
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnterpriseNoShouldNotBeSetOnNonBelgianContact()
    var
        Contact: Record Contact;
    begin
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", GetCountryEU());
        Contact.Modify();

        Contact.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Contact."Country/Region Code"));

        asserterror Contact.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Assert.ExpectedError('Enterprise');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoCanBeSetOnNonBelgianContact()
    var
        Contact: Record Contact;
        VATNo: Code[20];
    begin
        Initialize();

        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Country/Region Code", GetCountryEU());
        Contact.Modify();

        VATNo := LibraryERM.GenerateVATRegistrationNo(Contact."Country/Region Code");
        Contact.Validate("VAT Registration No.", VATNo);

        Assert.AreEqual(VATNo, Contact."VAT Registration No.", 'VAT Registration number is not set.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceHeaderContainsEnterpriseNoOfBelgianCustomer()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60105
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Enterprise No.", LibraryBEHelper.CreateEnterpriseNo());
        Customer.Modify();

        ServiceHeader.Init();
        ServiceHeader.Validate("Customer No.", Customer."No.");
        Assert.AreEqual(Customer."Enterprise No.", ServiceHeader."Enterprise No.", 'Enterprise No. is not as expected.');
    end;

    [Test]
    [HandlerFunctions('ServiceInvoicePrintRequestHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHasEnterpriseNumbers()
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        PostedServiceInvoicesPage: TestPage "Posted Service Invoices";
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60106
        Initialize();

        LibraryBEHelper.CreateDomesticCustomerResourceServiceDocumentAndPost(Customer, "Service Document Type"::Invoice);

        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst();

        Assert.AreEqual(VATEntry."VAT Registration No.", '', '');

        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();

        PostedServiceInvoicesPage.OpenView();
        PostedServiceInvoicesPage.GotoRecord(ServiceInvoiceHeader);

        LibraryReportDataset.Reset();
        PostedServiceInvoicesPage."&Print".Invoke();

        // Validation
        CompanyInfo.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEnterpriseNo', CompanyInfo."Enterprise No.");
        LibraryReportDataset.AssertElementWithValueExists('NoText', Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ServiceInvoicePrintRequestHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportHasVATNumberForNonDomesticCust()
    var
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        PostedServiceInvoicesPage: TestPage "Posted Service Invoices";
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60106
        Initialize();

        LibraryBEHelper.CreateForeignCustomerResourceServiceDocumentAndPost(Customer, "Service Document Type"::Invoice);

        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst();

        Assert.AreEqual(Customer."VAT Registration No.", VATEntry."VAT Registration No.", '');

        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();

        PostedServiceInvoicesPage.OpenView();
        PostedServiceInvoicesPage.GotoRecord(ServiceInvoiceHeader);

        LibraryReportDataset.Reset();
        PostedServiceInvoicesPage."&Print".Invoke();

        // Validation
        CompanyInfo.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEnterpriseNo', CompanyInfo."Enterprise No.");
        LibraryReportDataset.AssertElementWithValueExists('NoText', Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoPrintRequestHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoReportHasEnterpriseNumbers()
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        PostedServiceCreditMemosPage: TestPage "Posted Service Credit Memos";
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60106
        Initialize();

        LibraryBEHelper.CreateDomesticCustomerResourceServiceDocumentAndPost(Customer, "Service Document Type"::"Credit Memo");

        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst();

        Assert.AreEqual(VATEntry."VAT Registration No.", '', '');

        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindFirst();

        PostedServiceCreditMemosPage.OpenView();
        PostedServiceCreditMemosPage.GotoRecord(ServiceCrMemoHeader);

        LibraryReportDataset.Reset();
        PostedServiceCreditMemosPage."&Print".Invoke();

        // Validation
        CompanyInfo.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEnterpriseNo', CompanyInfo."Enterprise No.");
        LibraryReportDataset.AssertElementWithValueExists('NoText', Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoPrintRequestHandler')]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoReportHasVATNumberForNonDomesticCust()
    var
        Customer: Record Customer;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        PostedServiceCreditMemosPage: TestPage "Posted Service Credit Memos";
    begin
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60106
        Initialize();

        LibraryBEHelper.CreateForeignCustomerResourceServiceDocumentAndPost(Customer, "Service Document Type"::"Credit Memo");

        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");
        VATEntry.FindFirst();

        Assert.AreEqual(Customer."VAT Registration No.", VATEntry."VAT Registration No.", '');

        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindFirst();

        PostedServiceCreditMemosPage.OpenView();
        PostedServiceCreditMemosPage.GotoRecord(ServiceCrMemoHeader);

        LibraryReportDataset.Reset();
        PostedServiceCreditMemosPage."&Print".Invoke();

        // Validation
        CompanyInfo.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoEnterpriseNo', CompanyInfo."Enterprise No.");
        LibraryReportDataset.AssertElementWithValueExists('NoText', Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BillToBelgianCustomerUpdatesEntNoOnServiceHeader()
    var
        CustomerBelgian: Record Customer;
        CustomerNonBelgian: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        Initialize();

        LibraryBEHelper.CreateDomesticCustomer(CustomerBelgian);
        LibraryBEHelper.CreateCustomer(CustomerNonBelgian, GetCountryEU());

        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader.Validate("Customer No.", CustomerNonBelgian."No.");
        ServiceHeader.Validate("Bill-to Customer No.", CustomerBelgian."No.");

        Assert.AreEqual(CustomerBelgian."Enterprise No.", ServiceHeader."Enterprise No.", '');
        Assert.AreEqual('', ServiceHeader."VAT Registration No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingSupplierPartyTaxScheme_EnterpriseNo()
    var
        CompanyInformation: Record "Company Information";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".GetAccountingSupplierPartyTaxScheme() returns "Enterprise No." for Belgium country
        Initialize();
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := GetCountryBE();
        CompanyInformation.Modify();
        CompanyInformation.TestField("Enterprise No.");
        CompanyInformation.TestField("VAT Registration No.", '');

        PEPPOLManagement.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        Assert.AreEqual(CompanyInformation."Country/Region Code" + CompanyInformation."Enterprise No.", CompanyID, '');
        Assert.AreEqual(GetVATScheme(), CompanyIDSchemeID, '');
        Assert.AreEqual('VAT', TaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingSupplierPartyTaxScheme_VATRegNo()
    var
        CompanyInformation: Record "Company Information";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".GetAccountingSupplierPartyTaxScheme() returns "VAT Registration No." for non Belgium country
        Initialize();
        CompanyInformation.Get();
        CompanyInformation."Country/Region Code" := GetCountryEU();
        CompanyInformation.Modify();
        UpdateCompanyInfo(CompanyInformation, '', LibraryERM.GenerateVATRegistrationNo(GetCountryEU()), '');

        CompanyInformation.TestField("Enterprise No.", '');
        CompanyInformation.TestField("VAT Registration No.");

        PEPPOLManagement.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", CompanyID, '');
        Assert.AreEqual(GetVATScheme(), CompanyIDSchemeID, '');
        Assert.AreEqual('VAT', TaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingSupplierPartyTaxScheme_Empty()
    var
        CompanyInformation: Record "Company Information";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CompanyID: Text;
        CompanyIDSchemeID: Text;
        TaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".GetAccountingSupplierPartyTaxScheme() returns empty result when "Enterprise No." and "VAT Registration No." are empty
        Initialize();
        UpdateCompanyInfo(CompanyInformation, '', '', '');

        CompanyInformation.TestField("Enterprise No.", '');
        CompanyInformation.TestField("VAT Registration No.", '');

        PEPPOLManagement.GetAccountingSupplierPartyTaxScheme(CompanyID, CompanyIDSchemeID, TaxSchemeID);
        Assert.AreEqual('', CompanyID, '');
        Assert.AreEqual(GetVATScheme(), CompanyIDSchemeID, '');
        Assert.AreEqual('VAT', TaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingCustomerPartyTaxScheme_EnterpriseNo()
    var
        SalesHeader: Record "Sales Header";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".CustPartyTaxSchemeCompanyID() returns "Enterprise No." for Belgium country
        Initialize();
        SalesHeader."Enterprise No." := LibraryUtility.GenerateGUID();
        SalesHeader."VAT Registration No." := '';
        SalesHeader."Bill-to Country/Region Code" := GetCountryBE();

        PEPPOLManagement.GetAccountingCustomerPartyTaxScheme(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);

        Assert.AreEqual(SalesHeader."Enterprise No.", CustPartyTaxSchemeCompanyID, '');
        Assert.AreEqual(GetVATScheme(), CustPartyTaxSchemeCompIDSchID, '');
        Assert.AreEqual('VAT', CustTaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingCustomerPartyTaxScheme_VATRegNo()
    var
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".CustPartyTaxSchemeCompanyID() returns "VAT Registration No." for non Belgium country
        Initialize();
        SalesHeader."Enterprise No." := '';
        SalesHeader."VAT Registration No." := LibraryUtility.GenerateGUID();
        CountryRegion.Get(GetCountryEU());
        SalesHeader."Bill-to Country/Region Code" := CountryRegion.Code;

        PEPPOLManagement.GetAccountingCustomerPartyTaxScheme(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);

        Assert.AreEqual(SalesHeader."VAT Registration No.", CustPartyTaxSchemeCompanyID, '');
        Assert.AreEqual(CountryRegion."VAT Scheme", CustPartyTaxSchemeCompIDSchID, '');
        Assert.AreEqual('VAT', CustTaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLMgt_GetAccountingCustomerPartyTaxScheme_Empty()
    var
        SalesHeader: Record "Sales Header";
        PEPPOLManagement: Codeunit "PEPPOL Management";
        CustPartyTaxSchemeCompanyID: Text;
        CustPartyTaxSchemeCompIDSchID: Text;
        CustTaxSchemeID: Text;
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 341241] COD 1605 "PEPPOL Management".CustPartyTaxSchemeCompanyID() returns empty result when "Enterprise No." and "VAT Registration No." are empty
        Initialize();
        SalesHeader."Enterprise No." := '';
        SalesHeader."VAT Registration No." := '';

        PEPPOLManagement.GetAccountingCustomerPartyTaxSchemeBIS(
          SalesHeader, CustPartyTaxSchemeCompanyID, CustPartyTaxSchemeCompIDSchID, CustTaxSchemeID);

        Assert.AreEqual('', CustPartyTaxSchemeCompanyID, '');
        Assert.AreEqual('', CustPartyTaxSchemeCompIDSchID, '');
        Assert.AreEqual('VAT', CustTaxSchemeID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_YouMustSpecifyEnterpriseNo()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 201964] COD 1620 "PEPPOL Validation" throws an error "You must specify either GLN or VAT Registration No. or Enterprise No. in Company Information." in case of empty fields
        Initialize();
        UpdateCompanyInfo(CompanyInformation, '', '', '');

        CompanyInformation.TestField("Enterprise No.", '');
        CompanyInformation.TestField("VAT Registration No.", '');
        CompanyInformation.TestField(GLN, '');

        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          'You must fill in either the GLN, VAT Registration No., or Enterprise No. field in the Company Information window.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_EnterpriseNo()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 201964] COD 1620 "PEPPOL Validation" throws an error "Bill-to Name must have a value" for an empty Sales Header and filled "Enterprise No."
        Initialize();
        CompanyInformation.Get();
        UpdateCompanyInfo(CompanyInformation, CompanyInformation."Enterprise No.", '', '');

        CompanyInformation.TestField("Enterprise No.");
        CompanyInformation.TestField("VAT Registration No.", '');
        CompanyInformation.TestField(GLN, '');

        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(BillToNameMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_VATRegNo()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 201964] COD 1620 "PEPPOL Validation" throws an error "Bill-to Name must have a value" for an empty Sales Header and filled "VAT Registration No."
        Initialize();
        UpdateCompanyInfo(CompanyInformation, '', LibraryBEHelper.CreateVatRegNo(GetCountryBE()), '');

        CompanyInformation.TestField("Enterprise No.", '');
        CompanyInformation.TestField("VAT Registration No.");
        CompanyInformation.TestField(GLN, '');

        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(BillToNameMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_GLN()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT]
        // [SCENARIO 201964] COD 1620 "PEPPOL Validation" throws an error "Bill-to Name must have a value" for an empty Sales Header and filled "GLN"
        Initialize();
        UpdateCompanyInfo(CompanyInformation, '', '', '1234567890128');

        CompanyInformation.TestField("Enterprise No.", '');
        CompanyInformation.TestField("VAT Registration No.", '');
        CompanyInformation.TestField(GLN);

        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(BillToNameMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_Customer_YouMustSpecifyEnterpriseNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 205111] COD 1620 "PEPPOL Validation" throws an error "You must fill in either the GLN, VAT Registration No., or Enterprise No. field in the Customer..." in case of empty  customer's fields
        Initialize();
        UpdateCompanySwiftCode();

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerNo('', '', ''));

        SalesHeader.TestField("Enterprise No.", '');
        SalesHeader.TestField("VAT Registration No.", '');

        asserterror CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo('You must fill in either the GLN, VAT Registration No., or Enterprise No. field for customer %1.',
            SalesHeader."Bill-to Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_Customer_EnterpriseNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 205111] Sales Invoice is validated successfully with COD 1620 "PEPPOL Validation" when Customer."Enterprise No." has value
        Initialize();
        UpdateCompanySwiftCode();

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerNo('', LibraryUtility.GenerateGUID(), ''));
        SalesHeader."Your Reference" := LibraryUtility.GenerateGUID();

        SalesHeader.TestField("Enterprise No.");
        SalesHeader.TestField("VAT Registration No.", '');

        CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_Customer_VATRegNo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 205111] Sales Invoice is validated successfully with COD 1620 "PEPPOL Validation" when Customer."VAT Registration No." has value
        Initialize();
        UpdateCompanySwiftCode();

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerNo(LibraryUtility.GenerateGUID(), '', ''));
        SalesHeader."Your Reference" := LibraryUtility.GenerateGUID();

        SalesHeader.TestField("Enterprise No.", '');
        SalesHeader.TestField("VAT Registration No.");

        CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PEPPOLValidation_Customer_GLN()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [PEPPOL] [UT] [Customer]
        // [SCENARIO 205111] Sales Invoice is validated successfully with COD 1620 "PEPPOL Validation" when Customer."GLN" has value
        Initialize();
        UpdateCompanySwiftCode();

        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomerNo('', '', LibraryUtility.GenerateGUID()));
        SalesHeader."Your Reference" := LibraryUtility.GenerateGUID();

        SalesHeader.TestField("Enterprise No.", '');
        SalesHeader.TestField("VAT Registration No.", '');

        CODEUNIT.Run(CODEUNIT::"PEPPOL Validation", SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInfoGetVatRegNoReturnsEnterpriseNoForBE()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297251] Company Information GetVATRegistrationNumber returns Enterprise No if company is BE
        Initialize();

        CompanyInformation.Get();

        // [GIVEN] Current company's Country Code is BE
        CompanyInformation.Validate("Country/Region Code", GetCountryBE());

        // [GIVEN] Enterprise No is set
        CompanyInformation.Validate("Enterprise No.", '0200.068.636');

        // [THEN] GetVATRegistrationNumber returns Enterprise No
        Assert.AreEqual(
          CompanyInformation."Enterprise No.",
          CompanyInformation.GetVATRegistrationNumber(), 'Numbers must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInfoGetVatRegNoLblReturnsEnterpriseNoLblForBE()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297251] Company Information GetVATRegistrationNumberLbl returns Enterprise No text label if company is BE
        Initialize();

        CompanyInformation.Get();

        // [GIVEN] Current company's Country Code is BE
        CompanyInformation.Validate("Country/Region Code", GetCountryBE());

        // [GIVEN] Enterprise No is set
        CompanyInformation.Validate("Enterprise No.", '0200.068.636');

        // [THEN] GetVATRegistrationNumberLbl returns Enterprise No label
        Assert.AreEqual(
          CompanyInformation.FieldCaption("Enterprise No."),
          CompanyInformation.GetVATRegistrationNumberLbl(), 'Labels must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInfoGetVatRegNoReturnsVATRegNoForNonBE()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297251] Company Information GetVATRegistrationNumber returns VAT Registration No. if company is non-BE
        Initialize();

        CompanyInformation.Get();

        // [GIVEN] Current company's Country Code is BE
        CompanyInformation.Validate("Country/Region Code", 'DE');

        // [GIVEN] VAT Registration No. is set
        CompanyInformation.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo('DE'));

        // [THEN] GetVATRegistrationNumber returns Enterprise No
        Assert.AreEqual(
          CompanyInformation."VAT Registration No.",
          CompanyInformation.GetVATRegistrationNumber(), 'Numbers must be equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInfoGetVatRegNoLblReturnVATRegNoLblForNonBE()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 297251] Company Information GetVATRegistrationNumberLbl returns VAT Registration No. text label if company is non-BE
        Initialize();

        CompanyInformation.Get();

        // [GIVEN] Current company's Country Code is BE
        CompanyInformation.Validate("Country/Region Code", 'DE');

        // [GIVEN] VAT Registration No. is set
        CompanyInformation.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo('DE'));

        // [THEN] GetVATRegistrationNumberLbl returns Enterprise No label
        Assert.AreEqual(
          CompanyInformation.FieldCaption("VAT Registration No."),
          CompanyInformation.GetVATRegistrationNumberLbl(), 'Labels must be equal');
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderReportCustomerEnterpriseNo()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [UT] [Reminder]
        // [SCENARIO 315402] Report Reminder prints Enterprise No. for the local customer
        Initialize();

        // [GIVEN] Issued reminder for the local customer with Enterprise No. = "ENO"
        MockIssuedReminder(IssuedReminderHeader, GetCountryBE());
        IssuedReminderHeader."Enterprise No." := LibraryBEHelper.CreateEnterpriseNo();
        IssuedReminderHeader.Modify();

        // [WHEN] Reminder is being printed
        IssuedReminderHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] Enterprise No. caption and number "ENO" printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATNoText', IssuedReminderHeader.FieldCaption("Enterprise No."));
        LibraryReportDataset.AssertElementWithValueExists('VatRegNo_IssueReminderHdr', IssuedReminderHeader."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReminderReportCustomerVATRegistrationNo()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [UT] [Reminder]
        // [SCENARIO 315402] Report Reminder prints VAT Registration No. for the foreign customer
        Initialize();

        // [GIVEN] Issued reminder for the foreign customer with VAT Registration No. = "VATREGNO"
        MockIssuedReminder(IssuedReminderHeader, GetCountryEU());
        IssuedReminderHeader."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(IssuedReminderHeader."Country/Region Code");
        IssuedReminderHeader.Modify();

        // [WHEN] Reminder is being printed
        IssuedReminderHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] VAT Registration No. caption and number "VATREGNO" printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATNoText', IssuedReminderHeader.FieldCaption("VAT Registration No."));
        LibraryReportDataset.AssertElementWithValueExists('VatRegNo_IssueReminderHdr', IssuedReminderHeader."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportCustomerEnterpriseNo()
    var
        IssuedFinanceChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [UT] [Finance Charge Memo]
        // [SCENARIO 315402] Report Finance Charge Memo prints Enterprise No. for the local customer
        Initialize();

        // [GIVEN] Issued Finance Charge Memo for the local customer with Enterprise No. = "ENO"
        MockIssuedFinanceChargeMemo(IssuedFinanceChargeMemoHeader, GetCountryBE());
        IssuedFinanceChargeMemoHeader."Enterprise No." := LibraryBEHelper.CreateEnterpriseNo();
        IssuedFinanceChargeMemoHeader.Modify();

        // [WHEN] Finance Charge Memo is being printed
        IssuedFinanceChargeMemoHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo", true, false, IssuedFinanceChargeMemoHeader);

        // [THEN] Enterprise No. caption and number "ENO" printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATNoText', IssuedFinanceChargeMemoHeader.FieldCaption("Enterprise No."));
        LibraryReportDataset.AssertElementWithValueExists('VatRNo_IssuFinChrgMemoHr', IssuedFinanceChargeMemoHeader."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoReportCustomerVATRegistrationNo()
    var
        IssuedFinanceChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [UT] [Finance Charge Memo]
        // [SCENARIO 315402] Report Finance Charge Memo prints VAT Registration No. for the foreign customer
        Initialize();

        // [GIVEN] Issued Finance Charge Memo for the foreign customer with VAT Registration No. = "VATREGNO"
        MockIssuedFinanceChargeMemo(IssuedFinanceChargeMemoHeader, GetCountryEU());
        IssuedFinanceChargeMemoHeader."VAT Registration No." :=
            LibraryERM.GenerateVATRegistrationNo(IssuedFinanceChargeMemoHeader."Country/Region Code");
        IssuedFinanceChargeMemoHeader.Modify();

        // [WHEN] Finance Charge Memo is being printed
        IssuedFinanceChargeMemoHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Finance Charge Memo", true, false, IssuedFinanceChargeMemoHeader);

        // [THEN] VAT Registration No. caption and number "VATREGNO" printed
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATNoText', IssuedFinanceChargeMemoHeader.FieldCaption("VAT Registration No."));
        LibraryReportDataset.AssertElementWithValueExists('VatRNo_IssuFinChrgMemoHr', IssuedFinanceChargeMemoHeader."VAT Registration No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServIvoiceWithEnterpriseNo()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        ServiceInvoiceNo: Code[20];
    begin
        // [FEATURE] [Customer] [Service]
        // [SCENARIO 322818] VAT Entry's "Enterprise No." has a value after a Service Invoice for a Customer with "Enterprise No." is posted
        Initialize();

        // [GIVEN] Created a Customer with "Enterprise No."
        CreateCustomerWithEnterpriseNo(Customer);

        // [WHEN] Post a Service Invoice
        ServiceInvoiceNo := CreatePostServiceInvoice(Customer."No.");

        // [THEN] VAT Entry related to the posted Service Invoice has its "Enterprise No."
        FindVATEntry(VATEntry, VATEntry."Document Type"::Invoice, ServiceInvoiceNo);
        VATEntry.TestField("Enterprise No.", Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure PrintProFormaInvoiceDomesticCustomer()
    var
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
    begin
        // [FEATURE] [Pro Forma Invoive] [UI] [Order]
        // [SCENARIO 337630] Print REP 1302 "Standard Sales - Pro Forma Inv" from Sales Order page
        Initialize();

        // [GIVEN] Domestic customer was created
        LibraryBEHelper.CreateDomesticCustomer(Customer);

        // [GIVEN] Sales Invoice was created
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        Commit();

        // [WHEN] Run "Proforma Invoice"
        REPORT.Run(REPORT::"Standard Sales - Pro Forma Inv", true, false, SalesHeader);
        // UI Handled by ProFormaInvoiceXML_RPH

        // [THEN] REP 1302 "Standard Sales - Pro Forma Inv" has been printed
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Document has "Enterprise No." caption and company's Enterprise No. printed
        LibraryReportDataset.AssertElementTagWithValueExists('VATRegNoLbl', CompanyInformation.FieldCaption("Enterprise No."));
        LibraryReportDataset.AssertElementTagWithValueExists('CompanyVATRegNo', CompanyInformation."Enterprise No.");

        // [THEN] Customer has "Enterprise No." caption and customer's Enterprise No. printed
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerVATRegistrationNoLbl', Customer.FieldCaption("Enterprise No."));
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerVATRegNo', Customer."Enterprise No.");
    end;

    [Test]
    [HandlerFunctions('ProFormaInvoiceXML_RPH')]
    [Scope('OnPrem')]
    procedure PrintProFormaInvoiceForeignCustomer()
    var
        SalesHeader: Record "Sales Header";
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
    begin
        // [FEATURE] [Pro Forma Invoive] [UI] [Order]
        // [SCENARIO 337630] Print REP 1302 "Standard Sales - Pro Forma Inv" from Sales Order page
        Initialize();

        // [GIVEN] Foreign customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Invoice was created
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");

        Commit();

        // [WHEN] Run "Proforma Invoice"
        REPORT.Run(REPORT::"Standard Sales - Pro Forma Inv", true, false, SalesHeader);
        // UI Handled by ProFormaInvoiceXML_RPH

        // [THEN] REP 1302 "Standard Sales - Pro Forma Inv" has been printed
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Document has "Enterprise No." caption and company's Enterprise No. printed
        LibraryReportDataset.AssertElementTagWithValueExists('VATRegNoLbl', CompanyInformation.FieldCaption("Enterprise No."));
        LibraryReportDataset.AssertElementTagWithValueExists('CompanyVATRegNo', CompanyInformation."Enterprise No.");

        // [THEN] Customer has "VAT Registraion No." caption and customer's VAT Registration No. printed
        LibraryReportDataset.AssertElementTagWithValueExists(
          'CustomerVATRegistrationNoLbl', Customer.FieldCaption("VAT Registration No."));
        LibraryReportDataset.AssertElementTagWithValueExists('CustomerVATRegNo', Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPage')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportRevChargeEnterpriseNo()
    var
        CountryRegion: Record "Country/Region";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Report] [Reverse Charge VAT] [VAT Registration No.]
        // [SCENARIO 363740] The "Sales Document Test" report runs without errors with "Reverse Charge VAT" and "Bill-to Country/Region Code" specified
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Set up CountryRegion, GLAccount and VATPostingSetup
        LibraryERM.CreateCountryRegion(CountryRegion);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Created Sales Invoice with "Bill-to Country/Region Code" and "Enterprise No." specified
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Bill-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Validate("Enterprise No.", LibraryUtility.GenerateRandomXMLText(50));
        SalesHeader.Validate("VAT Registration No.", '');
        SalesHeader.Modify(true);

        // [GIVEN] Created Sales Line with "Reverse Charge VAT"
        UpdateVATPostSetupWithRevCharge(SalesHeader."VAT Bus. Posting Group", GLAccount."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        SalesLine.Modify(true);

        // [WHEN] Run "Sales Document Test" report for posted Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
        RunSalesTestDocumentReport(SalesHeader);

        // [THEN] The report has no error lines
        VerifySalesDocumentTestReportHasNoErrors();
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPage')]
    [Scope('OnPrem')]
    procedure SalesDocumentTestReportRevChargeVATRegNo()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Report] [Reverse Charge VAT] [VAT Registration No.]
        // [SCENARIO 363740] The "Sales Document Test" report runs without errors with "Reverse Charge VAT" and no "Bill-to Country/Region Code" specified
        Initialize();
        VATEntry.DeleteAll();

        // [GIVEN] Set up GLAccount and VATPostingSetup
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");

        // [GIVEN] Created Sales Invoice with no "Bill-to Country/Region Code" and "VAT Registration No." specified
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Bill-to Country/Region Code", '');
        SalesHeader.Validate("Enterprise No.", '');
        SalesHeader.Validate("VAT Registration No.", LibraryBEHelper.CreateVatRegNo(GetCountryBE()));
        SalesHeader.Modify(true);

        // [GIVEN] Created Sales Line with "Reverse Charge VAT"
        UpdateVATPostSetupWithRevCharge(SalesHeader."VAT Bus. Posting Group", GLAccount."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        SalesLine.Modify(true);

        // [WHEN] Run "Sales Document Test" report for posted Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, false, false);
        RunSalesTestDocumentReport(SalesHeader);

        // [THEN] The report has no error lines
        VerifySalesDocumentTestReportHasNoErrors();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentHeaderGetCustomerVATRegistrationNumber_EnterpriseNo()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 430032] Function GetCustomerVATRegistrationNumber of table SalesShipmentHeader returns Enterprise No. for local customer
        Initialize();

        // [GIVEN] Mock SalesShipmentHeader with empty country code and Entrprise No.  ="123"
        SalesShipmentHeader.Init();
        SalesShipmentHeader.TestField("Bill-to Country/Region Code", '');
        SalesShipmentHeader."Enterprise No." := LibraryUtility.GenerateRandomNumericText(MaxStrLen(SalesShipmentHeader."Enterprise No."));

        // [WHEN] Run function SalesShipmentHeader.GetCustomerVATRegistrationNumber
        // [THEN] It returns "123"
        Assert.AreEqual(SalesShipmentHeader."Enterprise No.", SalesShipmentHeader.GetCustomerVATRegistrationNumber(), 'Invalid Enterprise No.');
        // [WHEN] Run function SalesShipmentHeader.GetCustomerVATRegistrationNumberLbl
        // [THEN] It returns "Enterprise No."
        Assert.AreEqual(SalesShipmentHeader.FieldCaption("Enterprise No."), SalesShipmentHeader.GetCustomerVATRegistrationNumberLbl(), 'Invalid Enterprise No. label');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentHeaderGetCustomerVATRegistrationNumber_VATRegNo()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 430032] Function GetCustomerVATRegistrationNumber of table SalesShipmentHeader returns VAT Registration No. for foreign customer
        Initialize();

        // [GIVEN] Mock SalesShipmentHeader with foreign country code and VAT Registration No.  ="123"
        SalesShipmentHeader.Init();
        SalesShipmentHeader."Bill-to Country/Region Code" := GetCountryEU();
        SalesShipmentHeader."VAT Registration No." := LibraryUtility.GenerateRandomNumericText(MaxStrLen(SalesShipmentHeader."VAT Registration No."));

        // [WHEN] Run function SalesShipmentHeader.GetCustomerVATRegistrationNumber
        // [THEN] It returns "123"
        Assert.AreEqual(SalesShipmentHeader."VAT Registration No.", SalesShipmentHeader.GetCustomerVATRegistrationNumber(), 'Invalid VAT Registration No.');
        // [WHEN] Run function SalesShipmentHeader.GetCustomerVATRegistrationNumberLbl
        // [THEN] It returns "VAT Registration No."
        Assert.AreEqual(SalesShipmentHeader.FieldCaption("VAT Registration No."), SalesShipmentHeader.GetCustomerVATRegistrationNumberLbl(), 'Invalid VAT Registration No. label');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnRcptHeaderGetCustomerVATRegistrationNumber_EnterpriseNo()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 430032] Function GetCustomerVATRegistrationNumber of table ReturnRcptHeader returns Enterprise No. for local customer
        Initialize();

        // [GIVEN] Mock ReturnRcptHeader with empty country code and Entrprise No.  ="123"
        ReturnRcptHeader.Init();
        ReturnRcptHeader.TestField("Bill-to Country/Region Code", '');
        ReturnRcptHeader."Enterprise No." := LibraryUtility.GenerateRandomNumericText(MaxStrLen(ReturnRcptHeader."Enterprise No."));

        // [WHEN] Run function ReturnRcptHeader.GetCustomerVATRegistrationNumber
        // [THEN] It returns "123"
        Assert.AreEqual(ReturnRcptHeader."Enterprise No.", ReturnRcptHeader.GetCustomerVATRegistrationNumber(), 'Invalid Enterprise No.');
        // [WHEN] Run function ReturnRcptHeader.GetCustomerVATRegistrationNumberLbl
        // [THEN] It returns "Enterprise No."
        Assert.AreEqual(ReturnRcptHeader.FieldCaption("Enterprise No."), ReturnRcptHeader.GetCustomerVATRegistrationNumberLbl(), 'Invalid Enterprise No. label');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnRcptHeaderGetCustomerVATRegistrationNumber_VATRegNo()
    var
        ReturnRcptHeader: Record "Return Receipt Header";
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 430032] Function GetCustomerVATRegistrationNumber of table ReturnRcptHeader returns VAT Registration No. for foreign customer
        Initialize();

        // [GIVEN] Mock ReturnRcptHeader with foreign country code and VAT Registration No.  ="123"
        ReturnRcptHeader.Init();
        ReturnRcptHeader."Bill-to Country/Region Code" := GetCountryEU();
        ReturnRcptHeader."VAT Registration No." := LibraryUtility.GenerateRandomNumericText(MaxStrLen(ReturnRcptHeader."VAT Registration No."));

        // [WHEN] Run function ReturnRcptHeader.GetCustomerVATRegistrationNumber
        // [THEN] It returns "123"
        Assert.AreEqual(ReturnRcptHeader."VAT Registration No.", ReturnRcptHeader.GetCustomerVATRegistrationNumber(), 'Invalid VAT Registration No.');
        // [WHEN] Run function ReturnRcptHeader.GetCustomerVATRegistrationNumberLbl
        // [THEN] It returns "VAT Registration No."
        Assert.AreEqual(ReturnRcptHeader.FieldCaption("VAT Registration No."), ReturnRcptHeader.GetCustomerVATRegistrationNumberLbl(), 'Invalid VAT Registration No. label');
    end;

    [Test]
    procedure EnterpriseNoTakenFromCustomerWhenSellToVATCalcInGenLedgSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 574040] Enterprise number is taken from the customer card when "Bill-to/Sell-to VAT Calc." is "Sell-to/Buy-from No." in general ledger setup

        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Customer with "Enterprise No." = "X"
        LibrarySales.CreateCustomer(Customer);
        Customer."Enterprise No." := LibraryUtility.GenerateGUID();
        Customer.Modify(true);
        // [WHEN] Stan creates sales invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [THEN] Enterprise No. is set to "X" in the sales invoice
        SalesHeader.Testfield("Enterprise No.", Customer."Enterprise No.");
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        LibrarySetupStorage.Restore();

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        if IsInitialized then
            exit;

        LibraryBEHelper.InitializeCompanyInformation();
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
    end;

    local procedure UpdateCompanyInfo(var CompanyInformation: Record "Company Information"; EnterpriseNo: Text[50]; VATRegNo: Text[20]; GLNNo: Text[13])
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Enterprise No.", EnterpriseNo);
        CompanyInformation."VAT Registration No." := VATRegNo;
        CompanyInformation.Validate(GLN, GLNNo);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateCompanySwiftCode()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("SWIFT Code", Format(LibraryRandom.RandIntInRange(1000000, 9999999)));
        CompanyInformation.Modify(true);
    end;

    local procedure CreateCustomerNo(VATRegNo: Text[20]; EnterpriseNo: Text[50]; GLNNo: Code[13]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer."VAT Registration No." := VATRegNo;
        Customer."Enterprise No." := EnterpriseNo;
        Customer.GLN := GLNNo;
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithEnterpriseNo(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Enterprise No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer."Enterprise No."), 1));
        Customer.Modify(true);
    end;

    local procedure CreatePostServiceInvoice(CustomerNo: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        CreateServiceLine(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; PreAssignedNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure GetCountryBE(): Code[10]
    begin
        exit('BE');
    end;

    local procedure GetCountryEU(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.SetFilter(Code, '<>%1', GetCountryBE());
        CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '');
        CountryRegion.SetFilter("VAT Scheme", '<>%1', '');
        CountryRegion.Next(CountryRegion.Count() - 1);
        exit(CountryRegion.Code);
    end;

    local procedure GetVATScheme(): Text
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        exit(CountryRegion."VAT Scheme");
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header"; CountryCode: Code[10])
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader."Country/Region Code" := CountryCode;
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure MockIssuedFinanceChargeMemo(var IssuedFinanceChargeMemoHeader: Record "Issued Fin. Charge Memo Header"; CountryCode: Code[10])
    var
        IssuedFinanceChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedFinanceChargeMemoHeader.Init();
        IssuedFinanceChargeMemoHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedFinanceChargeMemoHeader.FieldNo("No."), DATABASE::"Issued Fin. Charge Memo Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedFinanceChargeMemoHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedFinanceChargeMemoHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedFinanceChargeMemoHeader."Country/Region Code" := CountryCode;
        IssuedFinanceChargeMemoHeader.Insert();
        IssuedFinanceChargeMemoLine.Init();
        IssuedFinanceChargeMemoLine."Line No." := LibraryUtility.GetNewRecNo(IssuedFinanceChargeMemoLine, IssuedFinanceChargeMemoLine.FieldNo("Line No."));
        IssuedFinanceChargeMemoLine."Finance Charge Memo No." := IssuedFinanceChargeMemoHeader."No.";
        IssuedFinanceChargeMemoLine."Due Date" := IssuedFinanceChargeMemoHeader."Due Date";
        IssuedFinanceChargeMemoLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedFinanceChargeMemoLine.Amount := IssuedFinanceChargeMemoLine."Remaining Amount";
        IssuedFinanceChargeMemoLine.Type := IssuedFinanceChargeMemoLine.Type::"G/L Account";
        IssuedFinanceChargeMemoLine.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoicePrintRequestHandler(var RequestPage: TestRequestPage "Service - Invoice")
    begin
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoPrintRequestHandler(var RequestPage: TestRequestPage "Service - Credit Memo")
    begin
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoRequestPageHandler(var FinanceChargeMemo: TestRequestPage "Finance Charge Memo")
    begin
        FinanceChargeMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProFormaInvoiceXML_RPH(var ProFormaInvoice: TestRequestPage "Standard Sales - Pro Forma Inv")
    begin
        ProFormaInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunSalesTestDocumentReport(SalesHeader: Record "Sales Header")
    var
        SalesDocumentTest: Report "Sales Document - Test";
    begin
        Clear(SalesDocumentTest);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesDocumentTest.SetTableView(SalesHeader);
        Commit();
        SalesDocumentTest.Run();
    end;

    local procedure UpdateVATPostSetupWithRevCharge(VATBusPostGrCode: Code[20]; GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(GLAccNo);
        VATPostingSetup.Get(VATBusPostGrCode, GLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifySalesDocumentTestReportHasNoErrors()
    var
        i: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        for i := 1 to LibraryReportDataset.RowCount() do begin
            LibraryReportDataset.MoveToRow(i);
            Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement('LineErrorCounter_Number'), 'Sales Document Test Report has errors.');
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPage(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

