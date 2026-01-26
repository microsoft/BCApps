codeunit 144210 "FatturaPA Document Type"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        OptionAlreadySpecifiedErr: Label 'Documents of type %1 already have code %2 as default. You can only use one code for each type of document.', Comment = '%1 = field caption;%2 = code value.';
        FatturaDocTypeDiffQst: Label 'There are one or more different values of Fattura document type coming from the VAT posting setup of lines. As it''''s not possible to identify the value, %1 from the header will be used.\\Do you want to continue?', Comment = '%1 = the value of Fattura Document type from the header';

    [Test]
    [Scope('OnPrem')]
    procedure FatturaDocTypeListCreatesOnPageOpening()
    var
        FatturaDocumentType: Record "Fattura Document Type";
        FatturaDocumentTypeList: TestPage "Fattura Document Type List";
    begin
        // [FEATURE] [DEMO] [UI]

        Initialize();
        LibraryLowerPermissions.SetLocal();
        FatturaDocumentTypeList.OpenView();
        Assert.IsFalse(FatturaDocumentType.IsEmpty(), 'Fattura Document Type list is empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDefaultTypeOfFatturaDocumentType()
    var
        FatturaDocumentType: Record "Fattura Document Type";
        InvoiceFatturaDocumentType: Record "Fattura Document Type";
        CrMemoFatturaDocumentType: Record "Fattura Document Type";
        SelfBillingFatturaDocumentType: Record "Fattura Document Type";
        PrepaymentFatturaDocumentType: Record "Fattura Document Type";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [DEMO] [UT]
        // [SCENARIO 352458] A list of the Fattura Document Type codes can have only one default value of Invoice, Credit Memo, Self-Billing and Prepayment

        Initialize();
        FatturaDocHelper.InsertFatturaDocumentTypeList();
        InvoiceFatturaDocumentType.SetRange(Invoice, true);
        Assert.IsTrue(InvoiceFatturaDocumentType.FindFirst(), 'No code for the Invoice');
        CrMemoFatturaDocumentType.SetRange("Credit Memo", true);
        Assert.IsTrue(CrMemoFatturaDocumentType.FindFirst(), 'No code for the Credit Memo');
        SelfBillingFatturaDocumentType.SetRange("Self-Billing", true);
        Assert.IsTrue(SelfBillingFatturaDocumentType.FindFirst(), 'No code for the Self-Billing');
        PrepaymentFatturaDocumentType.SetRange(Prepayment, true);
        Assert.IsTrue(PrepaymentFatturaDocumentType.FindFirst(), 'No code for the Prepayment');
        Commit();

        LibraryITLocalization.FilterFatturaDocumentTypeNoDefaultValues(FatturaDocumentType);
        FatturaDocumentType.FindFirst();
        asserterror FatturaDocumentType.Validate(Invoice, true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Invoice), InvoiceFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate("Credit Memo", true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Credit Memo"), CrMemoFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate("Self-Billing", true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption("Self-Billing"), SelfBillingFatturaDocumentType."No."));
        asserterror FatturaDocumentType.Validate(Prepayment, true);
        Assert.ExpectedError(
          StrSubstNo(OptionAlreadySpecifiedErr, FatturaDocumentType.FieldCaption(Prepayment), PrepaymentFatturaDocumentType."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelfBillingTypeIsCustVATRegMatchesCompanyInfInSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 352458] A "Fattura Document Type" is self-billing in the Sales Document if customer has the same VAT Registration No. as Company

        Initialize();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetInvoiceCode());

        Customer.Get(LibraryITLocalization.CreateCustomer());
        SetVATRegistrationNoInCompanyInformation(Customer."VAT Registration No.");
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetSelfBillingCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelfBillingTypeIsCustVATRegMatchesCompanyInfInServDoc()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [SCENARIO 352458] A "Fattura Document Type" is self-billing in the Service Document if customer has the same VAT Registration No. as Company

        Initialize();
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetInvoiceCode());

        Customer.Get(LibraryITLocalization.CreateCustomer());
        SetVATRegistrationNoInCompanyInformation(Customer."VAT Registration No.");
        ServiceHeader.Validate("Bill-to Customer No.", Customer."No.");
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetSelfBillingCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoDocTypeInSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342458] A "Fattura Document Type" is credit memo in the Sales Credit Memo document

        Initialize();
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrMemoDocTypeInServDoc()
    var
        ServiceHeader: Record "Service Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342458] A "Fattura Document Type" is credit memo in the Service Credit Memo document

        Initialize();
        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDocTypeInSalesDoc()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocumentNo: Code[20];
        FatturaDocType: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 352458] A FatturaPA xml file has Fattura Document Type code manually entered in the sales document

        Initialize();
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        DocumentNo := PostSalesInvoice(FatturaDocType);
        SalesInvoiceHeader.SetRange("No.", DocumentNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(TempBlob, FatturaDocType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualDocTypeInServDoc()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        CustomerNo: Code[20];
        FatturaDocType: Code[20];
        ClientFileName: Text[250];
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 352458] A FatturaPA xml file has Fattura Document Type code manually entered in the service document

        Initialize();
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CustomerNo := PostServiceInvoice(FatturaDocType);
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);

        // [WHEN] The document is exported to FatturaPA
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        // [THEN] TipoDocumento is "TD02" in exported file
        VerifyTipoDocumento(TempBlob, FatturaDocType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAssignVATPostingSetupWithValidateDocumentAllLinesSameDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 373967] "Fattura Document Type" assigns to the sales document during posting from the VAT Posting Setup when all lines have the same value and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Sales & Receivables Setup"
        UpdateValidateDocumentOnPostingInSalesSetup(true);
        CreateSalesHeader(SalesHeader);
        // [GIVEN] Sales Invoice with two lines, both has different VAT Posting Setup but with the same value of "Fattura Document Type" = "X"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));

        // [WHEN] Post invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] "Fattura Document Type" in the posted sales invoice is "X"
        SalesInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure SalesAssignVATPostingSetupWithValidateDocumentLinesHasDiffDocTypeConfirm()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 373967] "Fattura Document Type" remains default in the sales document during posting with confirmation/
        // [SCENARIO 373967] when lines have different value of the "Fattura Document Type" in the the VAT Posting Setup and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Sales & Receivables Setup"
        UpdateValidateDocumentOnPostingInSalesSetup(true);
        CreateSalesHeader(SalesHeader);
        // [GIVEN] Sales Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader,
          CreateVATPostingSetupWithFatturaDocType(
            SalesHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));
        LibraryVariableStorage.Enqueue(StrSubstNo(FatturaDocTypeDiffQst, SalesHeader."Fattura Document Type"));
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Post invoice with confirmation
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] "Fattura Document Type" in the posted sales invoice is "X"
        SalesInvoiceHeader.TestField("Fattura Document Type", SalesHeader."Fattura Document Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure SalesAssignVATPostingSetupWithValidateDocumentLinesHasDiffDocTypeDoNotConfirm()
    var
        SalesHeader: Record "Sales Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 373967] Posting sales document cancelled after user does not confirm that lines have different value of the "Fattura Document Type" in the VAT Posting Setup
        // [SCENARIO 373967] and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Sales & Receivables Setup"
        UpdateValidateDocumentOnPostingInSalesSetup(true);
        CreateSalesHeader(SalesHeader);
        // [GIVEN] Sales Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader,
          CreateVATPostingSetupWithFatturaDocType(
            SalesHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));
        Commit();
        LibraryVariableStorage.Enqueue(StrSubstNo(FatturaDocTypeDiffQst, SalesHeader."Fattura Document Type"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Post invoice without confirmation
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Invoice remains unposted
        SalesHeader.Find();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAssignVATPostingSetupWithoutValidateDocumentAllLinesSameDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 373967] "Fattura Document Type" assigns to the sales document during posting from the VAT Posting Setup when all lines have the same value and "Validate Document On Posting" is disabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is disabled in "Sales & Receivables Setup"
        UpdateValidateDocumentOnPostingInSalesSetup(false);
        CreateSalesHeader(SalesHeader);
        // [GIVEN] Sales Invoice with two lines, both has different VAT Posting Setup but with the same value of "Fattura Document Type" = "X"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));

        // [WHEN] Post invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] "Fattura Document Type" in the posted sales invoice is "X"
        SalesInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAssignVATPostingSetupWithoutValidateDocumentLineHasDiffDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Sales] [Export]
        // [SCENARIO 373967] "Fattura Document Type" remains default in the sales document during posting
        // [SCENARIO 373967] when lines have different value of the "Fattura Document Type" in the the VAT Posting Setup and "Validate Document On Posting" is disabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is disabled in "Sales & Receivables Setup"
        UpdateValidateDocumentOnPostingInSalesSetup(false);
        CreateSalesHeader(SalesHeader);
        // [GIVEN] Sales Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader, CreateVATPostingSetupWithFatturaDocType(SalesHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateSalesLineWithVATProdPostGroup(
          SalesHeader,
          CreateVATPostingSetupWithFatturaDocType(
            SalesHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));

        // [WHEN] Post invoice with confirmation
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] "Fattura Document Type" in the posted sales invoice is "X"
        SalesInvoiceHeader.TestField("Fattura Document Type", SalesHeader."Fattura Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServAssignVATPostingSetupWithValidateDocumentAllLinesSameDocType()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service] [Export]
        // [SCENARIO 373967] "Fattura Document Type" assigns to the service document during posting from the VAT Posting Setup when all lines have the same value and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Service Setup"
        UpdateValidateDocumentOnPostingInServiceSetup(true);
        CreateServiceHeader(ServiceHeader);
        // [GIVEN] Service Invoice with two lines, both has different VAT Posting Setup but with the same value of "Fattura Document Type" = "X"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));

        // [WHEN] Post invoice
        GetServiceInvoiceHeaderAfterPosting(ServiceInvoiceHeader, ServiceHeader);

        // [THEN] "Fattura Document Type" in the posted service invoice is "X"
        ServiceInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure ServAssignVATPostingSetupWithValidateDocumentLinesHasDiffDocTypeConfirm()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service] [Export]
        // [SCENARIO 373967] "Fattura Document Type" remains default in the service document during posting with confirmation/
        // [SCENARIO 373967] when lines have different value of the "Fattura Document Type" in the the VAT Posting Setup and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Service Setup"
        UpdateValidateDocumentOnPostingInServiceSetup(true);
        CreateServiceHeader(ServiceHeader);
        // [GIVEN] Service Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader,
          CreateVATPostingSetupWithFatturaDocType(
            ServiceHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));
        LibraryVariableStorage.Enqueue(StrSubstNo(FatturaDocTypeDiffQst, ServiceHeader."Fattura Document Type"));
        LibraryVariableStorage.Enqueue(true);

        // [WHEN] Post invoice with confirmation
        GetServiceInvoiceHeaderAfterPosting(ServiceInvoiceHeader, ServiceHeader);

        // [THEN] "Fattura Document Type" in the posted service invoice is "X"
        ServiceInvoiceHeader.TestField("Fattura Document Type", ServiceHeader."Fattura Document Type");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification')]
    [Scope('OnPrem')]
    procedure ServAssignVATPostingSetupWithValidateDocumentLinesHasDiffDocTypeDoNotConfirm()
    var
        ServiceHeader: Record "Service Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service] [Export]
        // [SCENARIO 373967] Posting service document cancelled after user does not confirm that lines have different value of the "Fattura Document Type" in the VAT Posting Setup and "Validate Document On Posting" is enabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is enabled in "Service Setup"
        UpdateValidateDocumentOnPostingInServiceSetup(true);
        CreateServiceHeader(ServiceHeader);
        // [GIVEN] Service Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader,
          CreateVATPostingSetupWithFatturaDocType(
            ServiceHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));
        Commit();
        LibraryVariableStorage.Enqueue(StrSubstNo(FatturaDocTypeDiffQst, ServiceHeader."Fattura Document Type"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Post invoice without confirmation
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service Invoice remains unposted
        ServiceHeader.Find();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServAssignVATPostingSetupWithoutValidateDocumentAllLinesSameDocType()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service] [Export]
        // [SCENARIO 373967] "Fattura Document Type" assigns to the service document during posting from the VAT Posting Setup when all lines have the same value and "Validate Document On Posting" is disabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is disabled in "Service Setup"
        UpdateValidateDocumentOnPostingInServiceSetup(false);
        CreateServiceHeader(ServiceHeader);
        // [GIVEN] Service Invoice with two lines, both has different VAT Posting Setup but with the same value of "Fattura Document Type" = "X"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));

        // [WHEN] Post invoice
        GetServiceInvoiceHeaderAfterPosting(ServiceInvoiceHeader, ServiceHeader);

        // [THEN] "Fattura Document Type" in the posted service invoice is "X"
        ServiceInvoiceHeader.TestField("Fattura Document Type", FatturaDocType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServAssignVATPostingSetupWithoutValidateDocumentLineHasDiffDocType()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        FatturaDocType: Code[20];
    begin
        // [FEATURE] [Service] [Export]
        // [SCENARIO 373967] "Fattura Document Type" remains default in the service document during posting
        // [SCENARIO 373967] when lines have different value of the "Fattura Document Type" in the the VAT Posting Setup and "Validate Document On Posting" is disabled

        Initialize();
        // [GIVEN] "Validate Document On Posting" is disabled in "Service Setup"
        UpdateValidateDocumentOnPostingInServiceSetup(false);
        CreateServiceHeader(ServiceHeader);
        // [GIVEN] Service Invoice with "Fattura Document Type" = "X" in the header and two lines
        // [GIVEN] The first line has VAT Posting Setup with "Fattura Document Type" = "Y"
        // [GIVEN] The second line has VAT Posting Setup with "Fattura Document Type" = "Z"
        FatturaDocType := LibraryITLocalization.GetRandomFatturaDocType('');
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader, CreateVATPostingSetupWithFatturaDocType(ServiceHeader."VAT Bus. Posting Group", FatturaDocType));
        CreateServiceLineWithVATProdPostGroup(
          ServiceHeader,
          CreateVATPostingSetupWithFatturaDocType(
            ServiceHeader."VAT Bus. Posting Group", LibraryITLocalization.GetRandomFatturaDocType(FatturaDocType)));

        // [WHEN] Post invoice with confirmation
        GetServiceInvoiceHeaderAfterPosting(ServiceInvoiceHeader, ServiceHeader);

        // [THEN] "Fattura Document Type" in the posted service invoice is "X"
        ServiceInvoiceHeader.TestField("Fattura Document Type", ServiceHeader."Fattura Document Type");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCorrectiveCreditMemoHasTD04DocumentTypeByDefault()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo] [Corrective Documents]
        // [SCENARIO 391665] A sales corrective credit memo has TD04 fattura document type by default

        Initialize();

        // [GIVEN] Posted sales invoice
        CreateSalesHeader(SalesHeader);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Clear(SalesHeader);

        // [WHEN] Create corrective credit memo for the posted sales invoice
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvHeader, SalesHeader);

        // [THEN] Corrective credit memo has "Fattura Document Type" = "TD04"
        // TFS ID 403084: Corrective credit memo does not have "TD04" code
        SalesHeader.Find();
        SalesHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceFatturaDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [Sales] [Prepayment]
        // [SCENARIO 571369] "Fattura Document Type" is 'TD02' in the Sales Prepayment Invoice document
        Initialize();

        // [GIVEN] Sales order with prepayment
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibraryITLocalization.CreateCustomer(), '', 1, '', 0D);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 20));
        SalesHeader.Modify(true);

        // [WHEN] Post prepayment invoice for the sales order
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Sales prepayment invoice has "Fattura Document Type" = "TD02"
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Fattura Document Type", FatturaDocHelper.GetPrepaymentCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesCrMemoFatturaDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [Sales] [Prepayment] [Credit Memo]
        // [SCENARIO 571369] "Fattura Document Type" is 'TD04' in the Sales Prepayment Credit Memo document
        Initialize();

        // [GIVEN] Sales order with prepayment
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibraryITLocalization.CreateCustomer(), '', 1, '', 0D);
        SalesHeader.Validate(SalesHeader."Prepayment %", LibraryRandom.RandIntInRange(10, 20));
        SalesHeader.Modify(true);

        // [GIVEN] Posted prepayment invoice for the sales order
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post prepayment credit memo for the sales order        
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);

        // [THEN] Sales prepayment credit memo has "Fattura Document Type" = "TD04"
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderFatturaDocType()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
    begin
        // [FEATURE] [Sales] [Return Order] [Credit Memo]
        // [SCENARIO 571369] "Fattura Document Type" is 'TD04' in the Sales Credit Memo posted for Return Order document
        Initialize();

        // [GIVEN] Sales return order
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", LibraryITLocalization.CreateCustomer(), '', 1, '', 0D);

        // [WHEN] Post sales return order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales credit memo has "Fattura Document Type" = "TD04"
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Fattura Document Type", FatturaDocHelper.GetCrMemoCode());
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"FatturaPA Document Type");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"FatturaPA Document Type");
        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.SaveCompanyInformation();
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"FatturaPA Document Type");
        IsInitialized := true;
    end;

    local procedure PostSalesInvoice(FatturaDocType: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice,
          LibraryITLocalization.CreateCustomer(), '', 5, '', 0D);
        UpdateSalesHeaderWithFatturaCodes(SalesHeader, FatturaDocType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer());
        UpdateSalesHeaderWithFatturaCodes(SalesHeader, SalesHeader."Fattura Document Type");
    end;

    local procedure CreateSalesLineWithVATProdPostGroup(SalesHeader: Record "Sales Header"; VATProdPostGroupCode: Code[20])
    var
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        GLAccount.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesHeaderWithFatturaCodes(var SalesHeader: Record "Sales Header"; FatturaDocType: Code[20])
    begin
        SalesHeader.Validate("Fattura Document Type", FatturaDocType);
        SalesHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        SalesHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header")
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer());
        UpdateServiceaderWithFatturaCodes(ServiceHeader, ServiceHeader."Fattura Document Type");
    end;

    local procedure CreateServiceLineWithVATProdPostGroup(ServiceHeader: Record "Service Header"; VATProdPostGroupCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroupCode);
        Item.Modify(true);
        CreateServiceLine(ServiceHeader, Item."No.");
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure UpdateServiceaderWithFatturaCodes(var ServiceHeader: Record "Service Header"; FatturaDocType: Code[20])
    begin
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        ServiceHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        ServiceHeader.Validate("Fattura Document Type", FatturaDocType);
        ServiceHeader.Modify(true);
    end;

    local procedure PostServiceInvoice(FatturaDocType: Code[20]): Code[20]
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, LibraryITLocalization.CreateCustomer());
        UpdateServiceaderWithFatturaCodes(ServiceHeader, FatturaDocType);
        CreateServiceLine(ServiceHeader, LibraryInventory.CreateItemNo());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."Customer No.");
    end;

    local procedure GetServiceInvoiceHeaderAfterPosting(var ServiceInvoiceHeader: Record "Service Invoice Header"; var ServiceHeader: Record "Service Header")
    begin
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure SetVATRegistrationNoInCompanyInformation(VATRegistrationNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("VAT Registration No.", VATRegistrationNo);
        CompanyInformation.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithFatturaDocType(VATBusPostGroupCode: Code[20]; FatturaDocType: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Fattura Document Type", FatturaDocType);
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure UpdateValidateDocumentOnPostingInSalesSetup(NewValidateDocumentOnPosting: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Validate Document On Posting", NewValidateDocumentOnPosting);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateValidateDocumentOnPostingInServiceSetup(NewValidateDocumentOnPosting: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Validate Document On Posting", NewValidateDocumentOnPosting);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure VerifyTipoDocumento(TempBlob: Codeunit "Temp Blob"; ExpectedElementValue: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/TipoDocumento');
        Assert.AreEqual(ExpectedElementValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName(), ExpectedElementValue, TempXMLBuffer.Value));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVerification(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

