codeunit 139056 "Outlook Add-in Commands"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [Sales] [Purchasing]
    end;

    var
        TempOfficeAddinContext: Record "Office Add-in Context" temporary;
        SMBOfficePages: Codeunit "SMB Office Pages";
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryTemplates: Codeunit "Library - Templates";
        OutlookCommand: DotNet OutlookCommand;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandOpensCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize('');
        SetupCustomer(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        RunMailEngine();

        // Verify
        CustomerCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandOpensVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize('');
        SetupVendor(Email, No, ContactNo);

        // Execute
        VendorCard.Trap();
        RunMailEngine();

        // Verify
        VendorCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesQuoteOpensQuoteThenCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesQuote);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        SalesQuote.Trap();
        RunMailEngine();

        // Verify
        SalesQuote.Control1903720907."No.".AssertEquals(No);
        CustomerCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesInvoiceOpensInvoiceThenCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesInvoice);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        SalesInvoice.Trap();
        RunMailEngine();

        // Verify
        SalesInvoice."Sell-to Contact No.".AssertEquals(ContactNo);
        CustomerCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderOpensOrderThenCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesOrder);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        SalesOrder.Trap();
        RunMailEngine();

        // Verify
        SalesOrder.Control1903720907."No.".AssertEquals(No);
        CustomerCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesCrMemoOpensMemoThenCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesCreditMemo);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        SalesCreditMemo.Trap();
        RunMailEngine();

        // Verify
        SalesCreditMemo."Sell-to Contact No.".AssertEquals(ContactNo);
        CustomerCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceOpensCreateVendorDialog()
    var
        VendorCard: TestPage "Vendor Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseInvoice);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        VendorCard.Trap();
        VendorDrillDownCreate();

        // Verify
        VendorCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderOpensCreateVendorDialog()
    var
        VendorCard: TestPage "Vendor Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // [SCENARIO] New Purchase Order command is selected and a vendor doesn't exist with given email the Create Vendor dialog is displayed

        // [GIVEN] New Purchase Order command is selected
        Initialize(OutlookCommand.NewPurchaseOrder);

        // [GIVEN] No Vendor exists but a Customer does
        SetupCustomer(Email, No, ContactNo);

        // [WHEN] User selects Create Vendor
        VendorCard.Trap();
        VendorDrillDownCreate();

        // [THEN] The Vendor is created with the correct email
        VendorCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderSend()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
        ContactNo: Code[20];
        PurchaseOrderNo: Code[20];
        Email: Text[80];
    begin
        // [SCENARIO] New Purchase Order command is selected and Purchase Order is sent

        // [GIVEN] New Purchase Order command is selected
        Initialize(OutlookCommand.NewPurchaseOrder);
        SetupVendor(Email, No, ContactNo);

        // [WHEN] The Purchase Order page is displayed
        VendorCard.Trap();
        PurchaseOrder.Trap();
        RunMailEngine();

        // Gather expected parameters
        LibraryVariableStorage.Enqueue('sendAttachment');
        PurchaseOrderNo := PurchaseOrder."No.".Value();
        LibraryVariableStorage.Enqueue(StrSubstNo('Purchase Order %1.pdf', PurchaseOrderNo));

        // [WHEN] Email action is invoked from the Purchase Order page
        PurchaseOrder.SendCustom.Invoke();

        // [THEN] ActionHandler verifies that the expected JS function is called with the correct parameters
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseCrMemoOpensCreateVendorDialog()
    var
        VendorCard: TestPage "Vendor Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseCreditMemo);
        SetupCustomer(Email, No, ContactNo);

        // Execute
        VendorCard.Trap();
        VendorDrillDownCreate();

        // Verify
        VendorCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesQuoteOpensCreateCustomerDialog()
    var
        CustomerCard: TestPage "Customer Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesQuote);
        SetupVendor(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesInvoiceOpensCreateCustomerDialog()
    var
        CustomerCard: TestPage "Customer Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesInvoice);
        SetupVendor(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesOrderOpensCreateCustomerDialog()
    var
        CustomerCard: TestPage "Customer Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesOrder);
        SetupVendor(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesCrMemoOpensCreateCustomerDialog()
    var
        CustomerCard: TestPage "Customer Card";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesCreditMemo);
        SetupVendor(Email, No, ContactNo);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(Email);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderOpensOrderThenVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // [SCENARIO] New Purchase Order command is selected with an existing Vendor with the given email address the Purchase Order page is displayed

        // [GIVEN] New Purchase Order command is selected
        Initialize(OutlookCommand.NewPurchaseOrder);
        SetupVendor(Email, No, ContactNo);

        // [WHEN] The Purchase Order page is displayed
        VendorCard.Trap();
        PurchaseOrder.Trap();
        RunMailEngine();

        // [THEN] The Purchase Order page has the correct contact information
        PurchaseOrder."Buy-from Contact No.".AssertEquals(ContactNo);
        VendorCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceOpensInvoiceThenVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseInvoice);
        SetupVendor(Email, No, ContactNo);

        // Execute
        VendorCard.Trap();
        PurchaseInvoice.Trap();
        RunMailEngine();

        // Verify
        PurchaseInvoice."Buy-from Contact No.".AssertEquals(ContactNo);
        VendorCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseCrMemoOpensMemoThenVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        No: Code[20];
        ContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseCreditMemo);
        SetupVendor(Email, No, ContactNo);

        // Execute
        VendorCard.Trap();
        PurchaseCreditMemo.Trap();
        RunMailEngine();

        // Verify
        PurchaseCreditMemo."Buy-from Contact No.".AssertEquals(ContactNo);
        VendorCard."No.".AssertEquals(No);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesQuoteOpensQuoteThenCustomerCardWhenEmailAssociatedToCustomerAndVendor()
    var
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        CustomerContactNo: Code[20];
        VendorContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesQuote);
        SetupCustomer(Email, CustomerNo, CustomerContactNo);
        SetupVendor(Email, VendorNo, VendorContactNo);

        // Execute
        SalesQuote.Trap();
        CustomerCard.Trap();
        RunMailEngine();

        // Verify
        SalesQuote."Sell-to Contact No.".AssertEquals(CustomerContactNo);
        CustomerCard."No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceOpensInvoiceThenVendorCardWhenEmailAssociatedToCustomerAndVendor()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        CustomerNo: Code[20];
        CustomerContactNo: Code[20];
        VendorNo: Code[20];
        VendorContactNo: Code[20];
        Email: Text[80];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseInvoice);
        SetupCustomer(Email, CustomerNo, CustomerContactNo);
        SetupVendor(Email, VendorNo, VendorContactNo);

        // Execute
        PurchaseInvoice.Trap();
        VendorCard.Trap();
        RunMailEngine();

        // Verify
        PurchaseInvoice."Buy-from Contact No.".AssertEquals(VendorContactNo);
        VendorCard."No.".AssertEquals(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandForCompanyContactThatIsACustomerOpensCustomerCard()
    var
        CustomerCard: TestPage "Customer Card";
        CustomerNo: Code[20];
    begin
        Initialize('');
        CustomerNo := CreateCompanyContactWithCustomer();

        CustomerCard.Trap();
        RunMailEngine();

        // Verify
        CustomerCard."No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderCommandForCompanyContactThatIsACustomerOpensSalesOrderAndCustomerCard()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
        CustomerNo: Code[20];
    begin
        Initialize(OutlookCommand.NewSalesOrder);
        CustomerNo := CreateCompanyContactWithCustomer();
        Customer.Get(CustomerNo);

        SalesOrder.Trap();
        CustomerCard.Trap();
        RunMailEngine();

        // Verify
        SalesOrder."Bill-to Name".AssertEquals(Customer.Name);
        CustomerCard."No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceCommandForCompanyContactThatIsACustomerOpensNewVendorDialog()
    var
        OfficeNoVendorDlg: TestPage "Office No Vendor Dlg";
    begin
        Initialize(OutlookCommand.NewPurchaseInvoice);
        CreateCompanyContactWithCustomer();

        OfficeNoVendorDlg.Trap();
        RunMailEngine();

        // Verify
        OfficeNoVendorDlg.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandForCompanyContactThatIsVendorOpensVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        VendorNo: Code[20];
    begin
        // Setup
        Initialize('');
        VendorNo := CreateCompanyContactWithVendor();

        // Execute
        VendorCard.Trap();
        RunMailEngine();

        // Verify
        VendorCard."No.".AssertEquals(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderCommandForCompanyContactThatIsAVendorOpensOpensNewCustomerDialog()
    var
        OfficeNoCustomerDlg: TestPage "Office No Customer Dlg";
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesOrder);
        CreateCompanyContactWithVendor();

        // Execute
        OfficeNoCustomerDlg.Trap();
        RunMailEngine();

        // Verify
        OfficeNoCustomerDlg.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceCommandForCompanyContactThatIsAVendorOpensPurchaseInvoiceAndVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorNo: Code[20];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseInvoice);
        VendorNo := CreateCompanyContactWithVendor();

        // Execute
        VendorCard.Trap();
        PurchaseInvoice.Trap();
        RunMailEngine();

        // Verify
        VendorCard."No.".AssertEquals(VendorNo);
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandForCompanyContactThatIsCustomerAndVendorOpensContactAssociationsList()
    var
        OfficeContactAssociations: TestPage "Office Contact Associations";
        Email: Text[80];
        CustomerNo: Code[20];
        VendorNo: Code[20];
        ContactNo: Code[20];
    begin
        // Setup
        Initialize('');
        Email := RandomEmail();
        VendorNo := CreateCompanyContactWithCustomerWithEmail(Email, ContactNo);
        CustomerNo := CreateCompanyContactWithVendorWithEmail(Email, ContactNo);

        // Execute
        OfficeContactAssociations.Trap();
        RunMailEngine();

        // Verify
        OfficeContactAssociations.First();
        OfficeContactAssociations."No.".AssertEquals(VendorNo);
        OfficeContactAssociations.Next();
        OfficeContactAssociations."No.".AssertEquals(CustomerNo);
        OfficeContactAssociations.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewSalesOrderCommandForCompanyContactThatIsACustomerAndVendorOpensSalesOrderAndCustomerCard()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
        CustomerCard: TestPage "Customer Card";
        Email: Text[80];
        CustomerNo: Code[20];
        ContactNo: Code[20];
    begin
        // Setup
        Initialize(OutlookCommand.NewSalesOrder);
        Email := RandomEmail();
        CreateCompanyContactWithVendorWithEmail(Email, ContactNo);
        CustomerNo := CreateCompanyContactWithCustomerWithEmail(Email, ContactNo);
        Customer.Get(CustomerNo);

        // Execute
        SalesOrder.Trap();
        CustomerCard.Trap();
        RunMailEngine();

        // Verify
        SalesOrder."Bill-to Name".AssertEquals(Customer.Name);
        CustomerCard."No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceCommandForCompanyContactThatIsACustomerAndVendorOpensPurchaseInvoiceAndVendorCard()
    var
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        Email: Text[80];
        VendorNo: Code[20];
        ContactNo: Code[20];
    begin
        // Setup
        Initialize(OutlookCommand.NewPurchaseInvoice);
        Email := RandomEmail();
        VendorNo := CreateCompanyContactWithVendorWithEmail(Email, ContactNo);
        CreateCompanyContactWithCustomerWithEmail(Email, ContactNo);

        // Execute
        VendorCard.Trap();
        PurchaseInvoice.Trap();
        RunMailEngine();

        // Verify
        VendorCard."No.".AssertEquals(VendorNo);
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(VendorNo);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesQuoteForCompanyContactThatIsNotCustOrVendAndAssignedToCompanyThatIsNotCustOrVend()
    var
        CustomerCard: TestPage "Customer Card";
        CompanyNo: Code[20];
        CompanyEmail: Text[80];
        PersonEmail: Text[80];
    begin
        // Setup
        CompanyNo := CreateCompanyContactWithNoLinkToCustomerOrVendor(CompanyEmail);
        CreatePersonContactForCompanyWithNoLinkToCustomerOrVendor(CompanyNo, PersonEmail);
        InitializeOutlookAddin(OutlookCommand.NewSalesQuote, CompanyEmail);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(CompanyEmail);
    end;

    [Test]
    [HandlerFunctions('UseTemplateConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewSalesQuoteForPersonContactThatIsNotCustOrVendAndAssignedToCompanyThatIsNotCustOrVend()
    var
        CustomerCard: TestPage "Customer Card";
        CompanyNo: Code[20];
        CompanyEmail: Text[80];
        PersonEmail: Text[80];
    begin
        // Setup
        CompanyNo := CreateCompanyContactWithNoLinkToCustomerOrVendor(CompanyEmail);
        CreatePersonContactForCompanyWithNoLinkToCustomerOrVendor(CompanyNo, PersonEmail);
        InitializeOutlookAddin(OutlookCommand.NewSalesQuote, PersonEmail);

        // Execute
        CustomerCard.Trap();
        CustomerDrillDownCreate();

        // Verify
        CustomerCard."E-Mail".AssertEquals(CompanyEmail);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceForContactThatIsNotCustOrVendAndAssignedToCompanyThatIsNotCustOrVend()
    var
        VendorCard: TestPage "Vendor Card";
        CompanyNo: Code[20];
        CompanyEmail: Text[80];
        PersonEmail: Text[80];
    begin
        // Setup
        CompanyNo := CreateCompanyContactWithNoLinkToCustomerOrVendor(CompanyEmail);
        CreatePersonContactForCompanyWithNoLinkToCustomerOrVendor(CompanyNo, PersonEmail);
        InitializeOutlookAddin(OutlookCommand.NewPurchaseInvoice, CompanyEmail);

        // Execute
        VendorCard.Trap();
        VendorDrillDownCreate();

        // Verify
        VendorCard."E-Mail".AssertEquals(CompanyEmail);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoCommandForCompanyContactThatIsCustomerAndVendorPlusPersonContactOpensContactAssociationsList()
    var
        Contact: Record Contact;
        OfficeContactAssociations: TestPage "Office Contact Associations";
        Email: Text[80];
        CustomerNo: Code[20];
        VendorNo: Code[20];
        CustomerContactNo: Code[20];
        VendorContactNo: Code[20];
    begin
        // Setup
        Initialize('');
        Email := RandomEmail();
        VendorNo := CreateCompanyContactWithVendorWithEmail(Email, VendorContactNo);
        CustomerNo := CreateCompanyContactWithCustomerWithEmail(Email, CustomerContactNo);

        Contact.Init();
        Contact.Type := Contact.Type::Person;
        Contact."E-Mail" := Email;
        Contact."Company No." := CustomerContactNo;
        Contact.Insert(true);

        // Execute
        OfficeContactAssociations.Trap();
        RunMailEngine();

        // Verify
        OfficeContactAssociations.First();
        OfficeContactAssociations."No.".AssertEquals(VendorNo);
        OfficeContactAssociations.Next();
        OfficeContactAssociations."No.".AssertEquals(CustomerNo);
        OfficeContactAssociations.Next();
        OfficeContactAssociations."No.".AssertEquals(CustomerNo);
        OfficeContactAssociations.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddinContextCommandTypeCustomer()
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
        OutlookCommand: DotNet OutlookCommand;
    begin
        SetAndVerifyAddinCommandType(OutlookCommand.NewSalesInvoice, DummyOfficeContactDetails."Associated Table"::Customer);
        SetAndVerifyAddinCommandType(OutlookCommand.NewSalesCreditMemo, DummyOfficeContactDetails."Associated Table"::Customer);
        SetAndVerifyAddinCommandType(OutlookCommand.NewSalesOrder, DummyOfficeContactDetails."Associated Table"::Customer);
        SetAndVerifyAddinCommandType(OutlookCommand.NewSalesQuote, DummyOfficeContactDetails."Associated Table"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddinContextCommandTypeVendor()
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
        OutlookCommand: DotNet OutlookCommand;
    begin
        SetAndVerifyAddinCommandType(OutlookCommand.NewPurchaseCreditMemo, DummyOfficeContactDetails."Associated Table"::Vendor);
        SetAndVerifyAddinCommandType(OutlookCommand.NewPurchaseInvoice, DummyOfficeContactDetails."Associated Table"::Vendor);
        SetAndVerifyAddinCommandType(OutlookCommand.NewPurchaseOrder, DummyOfficeContactDetails."Associated Table"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddinContextCommandTypeEmpty()
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
    begin
        SetAndVerifyAddinCommandType('', DummyOfficeContactDetails."Associated Table"::" ");
        SetAndVerifyAddinCommandType(CopyStr(CreateGuid(), 1, 30), DummyOfficeContactDetails."Associated Table"::" ");
    end;

    [Scope('OnPrem')]
    procedure SetAndVerifyAddinCommandType(Command: Text[30]; AssociatedTable: Integer)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Assert: Codeunit Assert;
    begin
        OfficeAddinContext.Command := Command;
        Assert.AreEqual(AssociatedTable, OfficeAddinContext.CommandType(), 'Unexpected command type.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UseTemplateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [Scope('OnPrem')]
    procedure Initialize(OutlookCommand: Text[30])
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        OfficeHostType: DotNet OfficeHostType;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Outlook Add-in Commands");

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        Clear(TempOfficeAddinContext);
        TempOfficeAddinContext.Init();
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType.OutlookItemRead);
        TempOfficeAddinContext.SetRange(Version, OfficeAddin.Version);
        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookTaskPane);
        OfficeAttachmentManager.Done();

        if not IsInitialized then begin
            LibraryTemplates.EnableTemplatesFeature();
            SMBOfficePages.SetupSales();
            SMBOfficePages.SetupMarketing();
            IsInitialized := true;
        end;

        TempOfficeAddinContext.SetFilter(Command, OutlookCommand);
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetupCustomer(var Email: Text[80]; var No: Code[20]; var ContactNo: Code[20])
    begin
        SetupCustomerVendor(Email, No, ContactNo, false);
    end;

    [Scope('OnPrem')]
    procedure SetupVendor(var Email: Text[80]; var No: Code[20]; var ContactNo: Code[20])
    begin
        SetupCustomerVendor(Email, No, ContactNo, true);
    end;

    [Scope('OnPrem')]
    procedure SetupCustomerVendor(var Email: Text[80]; var No: Code[20]; var ContactNo: Code[20]; Vendor: Boolean)
    var
        NewBusRelCode: Code[10];
    begin
        if Email = '' then
            Email := RandomEmail();

        if Vendor then
            No := SMBOfficePages.CreateContactFromVendor(Email, ContactNo, NewBusRelCode, true)
        else
            No := SMBOfficePages.CreateContactFromCustomer(Email, ContactNo, NewBusRelCode, true);
        TempOfficeAddinContext.SetRange(Email, Email);
        TempOfficeAddinContext.SetRange(Name, Email);
    end;

    local procedure RunMailEngine()
    var
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", TempOfficeAddinContext);
    end;

    local procedure VendorDrillDownCreate()
    var
        OfficeNoVendorDlg: TestPage "Office No Vendor Dlg";
    begin
        OfficeNoVendorDlg.Trap();
        RunMailEngine();

        // The drilldown closes the page and causes an error here, which is why we need to ASSERTERROR.
        asserterror OfficeNoVendorDlg.CreateVend.DrillDown();
        if GetLastErrorText <> 'The TestPage is not open.' then
            Error(GetLastErrorText);
    end;

    local procedure CustomerDrillDownCreate()
    var
        OfficeNoCustomerDlg: TestPage "Office No Customer Dlg";
    begin
        OfficeNoCustomerDlg.Trap();
        RunMailEngine();

        // The drilldown closes the page and causes an error here, which is why we need to ASSERTERROR.
        asserterror OfficeNoCustomerDlg.CreateCust.DrillDown();
        if GetLastErrorText <> 'The TestPage is not open.' then
            Error(GetLastErrorText);
    end;

    local procedure CreateCompanyContactWithCustomer(): Code[20]
    var
        Email: Text[80];
        ContactNo: Code[20];
    begin
        Email := RandomEmail();
        exit(CreateCompanyContactWithCustomerWithEmail(Email, ContactNo));
    end;

    local procedure CreateCompanyContactWithVendor(): Code[20]
    var
        Email: Text[80];
        ContactNo: Code[20];
    begin
        Email := RandomEmail();
        exit(CreateCompanyContactWithVendorWithEmail(Email, ContactNo));
    end;

    local procedure CreateCompanyContactWithCustomerWithEmail(Email: Text[80]; var ContactNo: Code[20]) No: Code[20]
    var
        NewBusRelCode: Code[10];
    begin
        No := SMBOfficePages.CreateContactFromCustomer(Email, ContactNo, NewBusRelCode, false);

        TempOfficeAddinContext.SetFilter(Email, Email);
    end;

    local procedure CreateCompanyContactWithVendorWithEmail(Email: Text[80]; var ContactNo: Code[20]) No: Code[20]
    var
        Contact: Record Contact;
        NewBusRelCode: Code[10];
    begin
        // Test issue - vendor has to be set to Person and then flipped because business contact will set fields on the vendor name
        No := SMBOfficePages.CreateContactFromVendor(Email, ContactNo, NewBusRelCode, true);
        Contact.Get(ContactNo);
        Contact.Type := Contact.Type::Company;
        Contact.Modify();

        TempOfficeAddinContext.SetFilter(Email, Email);
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@example.com', CreateGuid()));
    end;

    local procedure CreateCompanyContactWithNoLinkToCustomerOrVendor(var CompanyEmail: Text[80]): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        exit(SetEmailAndCompanyNoOnContact(Contact, Contact."No.", CompanyEmail));
    end;

    local procedure CreatePersonContactForCompanyWithNoLinkToCustomerOrVendor(CompanyNo: Code[20]; var PersonEmail: Text[80]): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreatePersonContact(Contact);
        exit(SetEmailAndCompanyNoOnContact(Contact, CompanyNo, PersonEmail));
    end;

    local procedure SetEmailAndCompanyNoOnContact(Contact: Record Contact; CompanyNo: Code[20]; var ContactEmail: Text[80]): Code[20]
    begin
        Contact."Company No." := CompanyNo;
        Contact."E-Mail" := RandomEmail();
        Contact."Search E-Mail" := UpperCase(Contact."E-Mail");
        Contact.Modify(true);
        ContactEmail := Contact."E-Mail";
        exit(Contact."No.");
    end;

    local procedure InitializeOutlookAddin(OutlookCommandTxt: Text[30]; Email: Text[80])
    begin
        Initialize(OutlookCommandTxt);

        TempOfficeAddinContext.SetRange(Email, Email);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ActionHandler(Message: Text[1024])
    var
        Assert: Codeunit Assert;
        ExpectedAction: Variant;
        ExpectedParam2: Variant;
        ActualAction: Text;
        ActualParam1: Text;
        ActualParam2: Text;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAction);
        LibraryVariableStorage.Dequeue(ExpectedParam2);
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, ActualParam1);
        ActualParam2 := Message;
        Assert.AreEqual(ExpectedAction, ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreNotEqual(0, StrPos(ActualParam2, ExpectedParam2), 'Incorrect document attachment type.');
        Assert.AreNotEqual('', ActualParam1, 'The file URL is empty.');
    end;

    local procedure ExtractComponent(var String: Text; var Component: Text)
    var
        DelimiterPos: Integer;
    begin
        DelimiterPos := StrPos(String, '|');
        Component := CopyStr(String, 1, DelimiterPos - 1);
        String := CopyStr(String, DelimiterPos + 1);
    end;
}

