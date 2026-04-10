codeunit 135413 "Service Mgmt. Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions] [Service Mgmt.] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTemplates: Codeunit "Library - Templates";
        Resource: Code[20];
        GLAccountNo: Code[20];
        IsInitialized: Boolean;
        MissingPermissionsErr: Label 'Sorry, the current permissions prevented the action.';
        TeamMemberErr: Label 'You are logged in as a Team Member role, so you cannot complete this task.';

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsViralSignup()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();

        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Viral Signup Plan
        LibraryE2EPlanPermissions.SetViralSignupPlan();

        // [WHEN] A sales order is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A Service Order is created and posted
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);
        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsPremiumUser()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Premium User Plan
        LibraryE2EPlanPermissions.SetPremiumUserPlan();

        // [WHEN] A sales order is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A Service Order is created and posted
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);
        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsBusinessManager()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] It fails with a permission error
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [WHEN] A Service Order is posted
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('FormAbort:Permission');
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);

        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsExternalAccountant()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A user with External Accountant Plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] A sales order is created and posted
        ErrorMessagesPage.Trap();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] It fails with a permission error
        Assert.ExpectedMessage(MissingPermissionsErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        // [WHEN] A Service Order is posted
        ErrorMessagesPage.Trap();
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(MissingPermissionsErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);

        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsTeamMember()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        SalesOrderNo: Code[20];
        ServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Team Member Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] A sales order is created
        asserterror SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] A sales order is Posted
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [WHEN] A Service Order is posted
        ErrorMessagesPage.Trap();
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(MissingPermissionsErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        // [THEN] There are no GL Entries to be verified
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsPremiumISVEmbUser()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Premium ISV Emb User Plan
        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();

        // [WHEN] A sales order is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A Service Order is created and posted
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);
        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsEssentialISVEmbUser()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Essential ISV Emb Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] It fails with a permission error
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        // [WHEN] A Service Order is posted
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('FormAbort:Permission');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);

        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsTeamMemberISVEmb()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        SalesOrderNo: Code[20];
        ServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] A sales order is created
        asserterror SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('TestValidation');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] A sales order is Posted
        ErrorMessagesPage.Trap();
        PostSalesOrder(SalesOrderNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(TeamMemberErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        PostSalesOrder(SalesOrderNo, false);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [WHEN] A Service Order is posted
        ErrorMessagesPage.Trap();
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(MissingPermissionsErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        // [THEN] There are no GL Entries to be verified
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceItemWorksheetModalPageHandler,PostedServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateAndPostServiceItemAndServiceOrderAsDeviceISVEmbUser()
    var
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
        ServiceOrderNo: Code[20];
        PostedServiceOrderNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating and posting a Service Order for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Device ISV Emb Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] It fails with a permission error
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        // [WHEN] A Service Order is created
        asserterror ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('DB:ClientInsertDenied');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        ServiceOrderNo := CreateServiceOrder(CustomerNo, ServiceItemNo);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        // [WHEN] A Service Order is posted
        asserterror PostServiceOrder(ServiceOrderNo);
        // [THEN] A permission error is thrown
        Assert.ExpectedErrorCode('FormAbort:Permission');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        PostedServiceOrderNo := PostServiceOrder(ServiceOrderNo);

        // [THEN] GL Entries contains lines pointing to that order
        VerifyGLEntriesForPostedServiceOrder(PostedServiceOrderNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsViralSignup()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Viral Signup Plan
        LibraryE2EPlanPermissions.SetViralSignupPlan();

        // [WHEN] A sales order is created and posted
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A service contract is created and signed
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsBusinessManager()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsExternalAccountant()
    var
        ErrorMessagesPage: TestPage "Error Messages";
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A user with External Accountant Plan
        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] A sales order is created and posted
        ErrorMessagesPage.Trap();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedMessage(MissingPermissionsErr, ErrorMessagesPage.Description.Value);
        ErrorMessagesPage.Close();

        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsTeamMember()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] A posted sales order
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [GIVEN] A Service Item
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);
        // [GIVEN] A user with Business Manager Plan
        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetPremiumUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsEssentialISVEmb()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Essential ISV Emb Plan
        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsTeamMemberISVEmb()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] A posted sales order
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);
        // [GIVEN] A Service Item
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [GIVEN] A user with Team Member ISV Emb Plan
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SelectCustomerTemplListModalPageHandler,SelectItemTemplListModalPageHandler,ConfirmHandlerYes,PostedSalesInvoicePageHandler,OrderPostActionHandler,ServiceContractSignMessageHandler')]
    [Scope('OnPrem')]
    procedure TestSignAndCreateServiceContractAsDeviceISVEmb()
    var
        ServiceAccountGroupCode: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        ServiceItemNo: Code[20];
    begin
        // [E2E] Scenario going through the process of posting a Sales Order with an Item with Service Item Group
        // then creating a Service Contract for the Service Item

        Initialize();
        // [GIVEN] A service account group
        ServiceAccountGroupCode := CreateServiceContractAccountGroup();
        // [GIVEN] An item with service item group
        ItemNo := CreateItem(CreateServiceItemGroup());
        // [GIVEN] A customer
        CustomerNo := CreateCustomer();
        // [GIVEN] A user with Device ISV Emb Plan
        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] A sales order is created and posted
        asserterror CreateAndPostSalesOrder(CustomerNo, ItemNo, true);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndPostSalesOrder(CustomerNo, ItemNo, false);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();
        // [THEN] Service Items contain a Service Item for the given ItemNo
        ServiceItemNo := GetServiceItemNoFromItemNo(ItemNo);

        // [WHEN] A service contract is created and signed
        asserterror CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);
        // [THEN] A permission error is thrown
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();
        CreateAndSignServiceContract(CustomerNo, ServiceItemNo, ServiceAccountGroupCode);

        // [THEN] A service invoice is created
        VerifyServiceInvoiceExists(CustomerNo);
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        PlanningAssignment: Record "Planning Assignment";
        ServiceContractTemplate: Record "Service Contract Template";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Mgmt. Plan-based E2E");

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
        LibraryVariableStorage.Clear();
        LibraryE2EPlanPermissions.SetPremiumUserPlan();

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Preview));

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Mgmt. Plan-based E2E");

        ServiceContractTemplate.DeleteAll();
        PlanningAssignment.DeleteAll();

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryTemplates.EnableTemplatesFeature();

        LibraryERMCountryData.CreateVATData();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        Resource := CreateItem(CreateServiceItemGroup());
        CreateServiceMgmtSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Mgmt. Plan-based E2E");
    end;

    local procedure CreateSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) SalesOrderNo: Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer No.".SetValue(CustomerNo);
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.FilteredTypeField.SetValue(Format(SalesLine.Type::Item));
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        SalesOrder.SalesLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.OK().Invoke();
    end;

    local procedure PostSalesOrder(SalesOrderNo: Code[20]; ExpectFailure: Boolean) PostedSalesOrderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoKey(SalesHeader."Document Type"::Order, SalesOrderNo);
        SalesOrder.Post.Invoke();
        if not ExpectFailure then
            PostedSalesOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostedSalesOrderNo));
    end;

    local procedure CreateAndPostSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; ExpectFailure: Boolean) PostedSalesOrderNo: Code[20]
    var
        SalesOrderNo: Code[20];
    begin
        SalesOrderNo := CreateSalesOrder(CustomerNo, ItemNo);
        PostedSalesOrderNo := PostSalesOrder(SalesOrderNo, ExpectFailure);
    end;

    local procedure CreateServiceOrder(CustomerNo: Code[20]; ServiceItemNo: Code[20]) ServiceOrderNo: Code[20]
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenNew();
        ServiceOrder."Customer No.".SetValue(CustomerNo);
        ServiceOrder.ServItemLines.New();
        ServiceOrder.ServItemLines.ServiceItemNo.SetValue(ServiceItemNo);
        ServiceOrder.ServItemLines."Item No.".Activate();
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        ServiceOrderNo := ServiceOrder."No.".Value();
        ServiceOrder.OK().Invoke();
    end;

    local procedure PostServiceOrder(ServiceOrderNo: Code[20]) PostedServiceOrderNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoKey(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        ServiceOrder.Post.Invoke();
        PostedServiceOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(PostedServiceOrderNo));
    end;

    local procedure CreateAndSignServiceContract(CustomerNo: Code[20]; ServiceItemNo: Code[20]; ServiceAccountGroupCode: Code[10]) ServiceContractNo: Code[20]
    var
        ServiceContract: TestPage "Service Contract";
        OldDate: Date;
    begin
        OldDate := WorkDate();
        WorkDate := CalcDate('<-1D>', WorkDate());
        ServiceContract.OpenNew();
        ServiceContract."Customer No.".Activate();
        ServiceContract."Customer No.".SetValue(CustomerNo);
        ServiceContract."Serv. Contract Acc. Gr. Code".SetValue(ServiceAccountGroupCode);
        ServiceContract."Service Period".SetValue('1Y');
        ServiceContract.ServContractLines."Service Item No.".SetValue(ServiceItemNo);
        ServiceContract.ServContractLines."Line Value".SetValue(10);
        ServiceContractNo := ServiceContract."Contract No.".Value();
        WorkDate := OldDate;
        ServiceContract.SignContract.Invoke();
    end;

    local procedure CreateBaseCalendar() BaseCalendarCode: Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        BaseCalendarCard: TestPage "Base Calendar Card";
    begin
        BaseCalendarCard.OpenNew();
        BaseCalendarCode :=
          LibraryUtility.GenerateRandomCodeWithLength(BaseCalendar.FieldNo(Code), DATABASE::"Base Calendar", MaxStrLen(BaseCalendar.Code));
        BaseCalendarCard.Code.SetValue(BaseCalendarCode);
    end;

    local procedure CreateServiceMgmtSetup()
    var
        ServiceMgtSetup: TestPage "Service Mgt. Setup";
    begin
        ServiceMgtSetup.OpenEdit();
        ServiceMgtSetup."Base Calendar Code".SetValue(CreateBaseCalendar());
        ServiceMgtSetup."Shipment on Invoice".SetValue(true);
        ServiceMgtSetup."Service Item Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Service Quote Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Service Order Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Service Invoice Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Posted Service Invoice Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Service Credit Memo Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Posted Serv. Credit Memo Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Posted Service Shipment Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Loaner Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Troubleshooting Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Service Contract Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Contract Template Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Contract Invoice Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Contract Credit Memo Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup."Prepaid Posting Document Nos.".SetValue(LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup.OK().Invoke();
        Commit();
    end;

    local procedure CreateItem(ServiceItemGroup: Code[10]) ItemNo: Code[20]
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenNew();
        ItemCard.Description.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Item.Description)));
        ItemCard."Service Item Group".SetValue(ServiceItemGroup);
        ItemNo := ItemCard."No.".Value();
        ItemCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateCustomer() CustomerNo: Code[20]
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        CustomerCard.OpenNew();
        CustomerCard.Name.SetValue(LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name)));
        CustomerNo := CustomerCard."No.".Value();
        CustomerCard.OK().Invoke();
        Commit();
    end;

    local procedure CreateServiceItemGroup() ServiceItemGroupCode: Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
        ServiceItemGroups: TestPage "Service Item Groups";
    begin
        ServiceItemGroups.OpenEdit();
        ServiceItemGroups.New();
        ServiceItemGroupCode :=
          LibraryUtility.GenerateRandomCodeWithLength(
            ServiceItemGroup.FieldNo(Code), DATABASE::"Service Item Group", MaxStrLen(ServiceItemGroup.Code));
        ServiceItemGroups.Code.SetValue(ServiceItemGroupCode);
        ServiceItemGroups."Default Response Time (Hours)".SetValue(LibraryRandom.RandInt(10));
        ServiceItemGroups."Create Service Item".SetValue(true);
        ServiceItemGroups.OK().Invoke();
        Commit();
    end;

    local procedure CreateServiceContractAccountGroup() ServContractAccountGroupCode: Code[10]
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServContractAccountGroups: TestPage "Serv. Contract Account Groups";
    begin
        ServContractAccountGroups.OpenEdit();
        ServContractAccountGroups.New();
        ServContractAccountGroupCode :=
          LibraryUtility.GenerateRandomCodeWithLength(
            ServiceContractAccountGroup.FieldNo(Code), DATABASE::"Service Contract Account Group",
            MaxStrLen(ServiceContractAccountGroup.Code));
        ServContractAccountGroups.Code.SetValue(ServContractAccountGroupCode);
        ServContractAccountGroups."Non-Prepaid Contract Acc.".SetValue(GLAccountNo);
        ServContractAccountGroups."Prepaid Contract Acc.".SetValue(GLAccountNo);
        ServContractAccountGroups.OK().Invoke();
        Commit();
    end;

    local procedure GetServiceItemNoFromItemNo(ItemNo: Code[20]) ServiceItemNo: Code[20]
    var
        ServiceItemList: TestPage "Service Item List";
    begin
        ServiceItemList.OpenView();
        ServiceItemList.FILTER.SetFilter("Item No.", Format(ItemNo));
        Assert.IsTrue(ServiceItemList.First(), 'Service Item List should contain at least a service item of the given no');
        ServiceItemNo := ServiceItemList."No.".Value();
    end;

    local procedure VerifyGLEntriesForPostedServiceOrder(DocumentNo: Code[20])
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        GeneralLedgerEntries.OpenView();
        GeneralLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        Assert.IsTrue(GeneralLedgerEntries.First(), 'G/L Entries does not contain any entry for the given No');
    end;

    local procedure VerifyServiceInvoiceExists(CustomerNo: Code[20])
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenView();
        ServiceInvoices.FILTER.SetFilter("Customer No.", CustomerNo);
        Assert.IsTrue(ServiceInvoices.First(), 'Service Invoices does not contain any document for the given customer no.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ConfigTemplatesModalPageHandler(var ConfigTemplates: TestPage "Config Templates")
    begin
        ConfigTemplates.First();
        ConfigTemplates.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCustomerTemplListModalPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectItemTemplListModalPageHandler(var SelectItemTemplList: TestPage "Select Item Templ. List")
    begin
        SelectItemTemplList.First();
        SelectItemTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetModalPageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceItemWorksheet.ServInvLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(Resource);
        ServiceItemWorksheet.ServInvLines.Quantity.SetValue(LibraryRandom.RandInt(10));
        ServiceItemWorksheet.ServInvLines."Unit Price".SetValue(LibraryRandom.RandDecInRange(1, 1000, 2));
        ServiceItemWorksheet.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OrderPostActionHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 3 // Receive/Ship & Invoice
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedSalesInvoice."No.".Value);
        PostedSalesInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicePageHandler(var PostedServiceInvoice: TestPage "Posted Service Invoice")
    begin
        LibraryVariableStorage.Enqueue(PostedServiceInvoice."No.".Value);
        PostedServiceInvoice.Close();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractSignMessageHandler(Message: Text[1024])
    begin
        // Dummy message handler
    end;
}

