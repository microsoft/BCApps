codeunit 134425 "Payment Services Test"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Sales Invoice Header" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Service]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        PaymentServiceExtensionMock: Codeunit "Payment Service Extension Mock";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        Initialized: Boolean;
        TestServiceNameTxt: Label 'Test App for Payment Service';
        TestServiceDescriptionTxt: Label 'Test App used to test Payment Service objects';
        NoPaymentMethodsSelectedTxt: Label 'No payment service is made available.';
        TestServiceTemplateKeyTok: Label 'TESTSERVICE01';
        TermsOfServiceURLTxt: Label 'https://localhost:999/TermsOfService/';
        ReminderToSendAgainMsg: Label 'The payment service was successfully changed.';
        NoPaymentServicesAvailableErr: Label 'No payment service extension has been installed.';
        UpdateOrCreateNewOption: Option Cancel,"Update Existing","Create New";
        LCY: Code[10];
        ItemNo: Code[20];

    local procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
        PaymentServiceSetup: Record "Payment Service Setup";
        PaymentReportingArgument: Record "Payment Reporting Argument";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Payment Services Test");
        BindActiveDirectoryMockEvents();
        CompanyInfo.Get();
        CompanyInfo."Allow Blank Payment Info." := true;
        CompanyInfo.Modify();
        PaymentServiceExtensionMock.AssertQueuesEmpty();

        PaymentServiceExtensionMock.EmptyTempPaymentServiceTables();
        LibraryVariableStorage.AssertEmpty();
        SalesInvoiceHeader.DeleteAll();
        SalesHeader.DeleteAll();

        Assert.IsTrue(PaymentServiceSetup.IsEmpty, 'Payment Service Setup table should be empty. It should be used as a temporary table');
        Assert.IsTrue(
          PaymentReportingArgument.IsEmpty, 'Payment Reporting Argument table should be empty. It should be used as a temporary table');

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Payment Services Test");

        LCY := '';
        BindSubscription(PaymentServiceExtensionMock);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        SetupReportSelections();
        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Payment Services Test");
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceTypeModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCreateNewPaymentServiceMultipleProviders()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
        CancelSelectionDialog: Boolean;
    begin
        // Setup
        Initialize();

        CreateTemplate(TempTemplatePaymentServiceSetup);
        CreateTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempTemplatePaymentServiceSetup);

        CancelSelectionDialog := false;
        SetSelectPaymentServiceTypeParameters(CancelSelectionDialog, TempTemplatePaymentServiceSetup.Name);

        PaymentServices.OpenEdit();

        // Execute
        PaymentServices.NewAction.Invoke();

        // Verify
        VerifyPaymentServicePage(PaymentServices, TempExpectedPaymentServiceSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateNewPaymentServiceSingleProvider()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        TempExpectedPaymentServiceSetup.TransferFields(TempTemplatePaymentServiceSetup, false);
        TempExpectedPaymentServiceSetup.Enabled := true;

        // Set parameters to
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Name);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Description);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Enabled);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup."Always Include on Documents");

        PaymentServices.OpenEdit();

        // Execute
        PaymentServices.NewAction.Invoke();

        // Verify
        VerifyPaymentServicePage(PaymentServices, TempExpectedPaymentServiceSetup);
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceTypeModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCancelWhenCreatingNewPaymentService()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
        CancelSelectionDialog: Boolean;
    begin
        // Setup
        Initialize();

        CreateTemplate(TempPaymentServiceSetup);
        CreateTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        PaymentServices.OpenEdit();
        CancelSelectionDialog := true;
        SetSelectPaymentServiceTypeParameters(CancelSelectionDialog, TempPaymentServiceSetup.Name);

        // Execute
        PaymentServices.NewAction.Invoke();

        // Verify
        Assert.IsFalse(PaymentServices.First(), 'No records should be present');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpeningPaymentServicesWithRecordsPresent()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
        FirstRowDescription: Text[50];
        SecondRowName: Text[50];
    begin
        // Setup
        Initialize();

        FirstRowDescription := GenerateRandomAlphanumericText();
        SecondRowName := GenerateRandomAlphanumericText();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        TempPaymentServiceSetup.Description := FirstRowDescription;
        TempPaymentServiceSetup.Modify();

        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        TempPaymentServiceSetup.Name := SecondRowName;
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        PaymentServices.OpenEdit();

        // Verify first record
        PaymentServices.First();
        Assert.AreEqual(FirstRowDescription, PaymentServices.Description.Value, 'Description was not set correctly on the first row');

        // Verify second record
        PaymentServices.Next();
        Assert.AreEqual(SecondRowName, PaymentServices.Name.Value, 'Description was not set correctly on the second row');
        Assert.AreEqual(true, PaymentServices.Enabled.AsBoolean(), 'Enabled was not set correctly');
        Assert.AreEqual(
          true, PaymentServices."Always Include on Documents".AsBoolean(), 'Always include on documents was not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestOpeningPaymentServicesWithNoProvidersPresentRaisesError()
    var
        PaymentServices: TestPage "Payment Services";
    begin
        // Setup
        Initialize();

        asserterror PaymentServices.OpenEdit();
        Assert.ExpectedError(NoPaymentServicesAvailableErr);
    end;

    [Test]
    [HandlerFunctions('OpenSetupCardMockHandler')]
    [Scope('OnPrem')]
    procedure TestOpeningSetupFromPaymentServiceSetup()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        TempPaymentServiceSetup.Init();
        TempPaymentServiceSetup.Insert();
        LibraryVariableStorage.Enqueue(AssignMockSetupPageAndRecord(TempPaymentServiceSetup));
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        PaymentServices.OpenEdit();
        PaymentServices.FILTER.SetFilter("Management Codeunit ID", '');
        PaymentServices.First();
        PaymentServices.Setup.Invoke();

        // Verify - within the handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAssignKeyOnPaymentServiceSetup()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
    begin
        // Setup
        Initialize();
        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        TempPaymentServiceSetup.Init();
        TempPaymentServiceSetup."Setup Record ID" := SalesHeader.RecordId;
        TempPaymentServiceSetup.Insert();

        // Execute
        TempPaymentServiceSetup.AssignPrimaryKey(TempPaymentServiceSetup);

        // Verify
        Assert.AreEqual(TempPaymentServiceSetup."No.", Format(SalesHeader.RecordId), 'Wrong primary key was assigned');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeletePaymentServiceSetup()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
    begin
        // Setup - any record should work
        Initialize();
        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        TempPaymentServiceSetup.Init();
        TempPaymentServiceSetup."Setup Page ID" := PAGE::"Sales Order";
        TempPaymentServiceSetup."Setup Record ID" := SalesHeader.RecordId;
        TempPaymentServiceSetup.Insert();

        // Execute
        TempPaymentServiceSetup.Delete(true);

        // Verify that connected record is deleted
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No."), 'Sales Header record should been deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSettingUpNewPaymentServicesFromSalesInvoice()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesInvoice: TestPage "Sales Invoice";
        ConfirmSetupOfPaymentServices: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempPaymentServiceSetup);

        ConfirmSetupOfPaymentServices := true;
        LibraryVariableStorage.Enqueue(ConfirmSetupOfPaymentServices);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesInvoice.SelectedPayments.Value, TempExpectedPaymentServiceSetup.Name, 'Wrong value set on Sales Invoice');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSettingUpNewPaymentServicesFromSalesSalesQuote()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesQuote: TestPage "Sales Quote";
        ConfirmSetupOfPaymentServices: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempPaymentServiceSetup);

        ConfirmSetupOfPaymentServices := true;
        LibraryVariableStorage.Enqueue(ConfirmSetupOfPaymentServices);

        CreateSalesQuote(SalesHeader, DummyPaymentMethod, LCY);

        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // Execute
        SalesQuote.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesQuote.SelectedPayments.Value, TempExpectedPaymentServiceSetup.Name, 'Wrong value set on Sales Quote');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSettingUpNewPaymentServicesFromSalesOrder()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesOrder: TestPage "Sales Order";
        ConfirmSetupOfPaymentServices: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempPaymentServiceSetup);

        ConfirmSetupOfPaymentServices := true;
        LibraryVariableStorage.Enqueue(ConfirmSetupOfPaymentServices);

        CreateSalesOrder(SalesHeader, DummyPaymentMethod, LCY);

        // Execute
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesOrder.SelectedPayments.Value, TempExpectedPaymentServiceSetup.Name, 'Wrong value set on Sales Order');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestSettingUpNewPaymentServicesFromPostedSalesInvoice()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ConfirmSetupOfPaymentServices: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempPaymentServiceSetup);

        ConfirmSetupOfPaymentServices := true;
        LibraryVariableStorage.Enqueue(ConfirmSetupOfPaymentServices);

        CreatePaymentMethod(PaymentMethod, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        LibraryVariableStorage.Enqueue(ReminderToSendAgainMsg);

        // Execute
        PostedSalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(
          PostedSalesInvoice.SelectedPayments.Value, TempExpectedPaymentServiceSetup.Name, 'Wrong value set on Posted Sales Invoice');
    end;

    [Test]
    [HandlerFunctions('UpdateExistingOrCreateNewServiceHandler,EnableDisabledPageModalHandler')]
    [Scope('OnPrem')]
    procedure TestEnablingDisabledSalesInvoicesPaymentServicesFromSalesInvoice()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        LibraryVariableStorage.Enqueue(UpdateOrCreateNewOption::"Update Existing");

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesInvoice.SelectedPayments.Value, TempTemplatePaymentServiceSetup.Name, 'Wrong value set on Sales Invoice');
    end;

    [Test]
    [HandlerFunctions('UpdateExistingOrCreateNewServiceHandler')]
    [Scope('OnPrem')]
    procedure TestSettingUpNewPaymentServicesFromSalesInvoiceDisabledExist()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        AssignMockSetupRecordID(TempPaymentServiceSetup);

        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        LibraryVariableStorage.Enqueue(UpdateOrCreateNewOption::"Create New");
        SetCreateNewPaymentServiceTypeParameters(TempExpectedPaymentServiceSetup, TempTemplatePaymentServiceSetup);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesInvoice.SelectedPayments.Value, TempExpectedPaymentServiceSetup.Name, 'Wrong value set on Sales Invoice');
    end;

    [Test]
    [HandlerFunctions('UpdateExistingOrCreateNewServiceHandler')]
    [Scope('OnPrem')]
    procedure TestCancelingSetupOfDisabledSalesInvoiceFromSapesInvoicePage()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        LibraryVariableStorage.Enqueue(UpdateOrCreateNewOption::Cancel);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(SalesInvoice.SelectedPayments.Value, NoPaymentMethodsSelectedTxt, 'Wrong value set on Sales Invoice');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestRefusingToSetupNewPaymentServices()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        ConfirmSetupOfPaymentServices: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempPaymentServiceSetup);

        ConfirmSetupOfPaymentServices := false;
        LibraryVariableStorage.Enqueue(ConfirmSetupOfPaymentServices);

        CreatePaymentMethod(PaymentMethod, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // Execute
        PostedSalesInvoice.SelectedPayments.AssistEdit();

        // Verify - No Page should be open
        Assert.AreEqual(NoPaymentMethodsSelectedTxt, PostedSalesInvoice.SelectedPayments.Value, 'No payment services should be selected');
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestSelectingEnabledPaymentService()
    var
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
        EnabledServiceName: Text[50];
        EnabledServiceDescription: Text[50];
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        // Create Enabled Payment Services
        CreateEnabledPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        EnabledServiceName := 'Enabled Service Name';
        EnabledServiceDescription := 'Enabled Service Description';
        TempPaymentServiceSetup.Name := EnabledServiceName;
        TempPaymentServiceSetup.Description := EnabledServiceDescription;
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();

        // Create Regular Payment Service
        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SetSelectPaymentServiceParameters(false, EnabledServiceName, false, true);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(EnabledServiceName, SalesInvoice.SelectedPayments.Value, 'Wrong Payment Service selected');
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestChangingSelectedPaymentService()
    var
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
        PaymentService1Name: Text[50];
        PaymentService1Description: Text[50];
        PaymentService2Name: Text[50];
        PaymentService2Description: Text[50];
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        // Create First Payment Service
        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentService1Name := 'Payment Service 1';
        PaymentService1Description := 'Payment Service 1 Description';
        TempPaymentServiceSetup.Name := PaymentService1Name;
        TempPaymentServiceSetup.Description := PaymentService1Description;
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();

        // Create Second Payment Service
        CreateEnabledPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentService2Name := 'Payment Service 2';
        PaymentService2Description := 'Payment Service 2 Description';
        TempPaymentServiceSetup.Name := PaymentService2Name;
        TempPaymentServiceSetup.Description := PaymentService2Description;
        AssignMockSetupRecordID2(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        Assert.AreEqual(PaymentService1Name, SalesInvoice.SelectedPayments.Value, 'Payment Service should be selected by default');
        SetSelectPaymentServiceParameters(false, PaymentService2Name, false, true);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(PaymentService2Name, SalesInvoice.SelectedPayments.Value, 'Wrong Payment Service selected');
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDeselectingSelectedPaymentService()
    var
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SetSelectPaymentServiceParameters(false, TempPaymentServiceSetup.Name, true, false);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(NoPaymentMethodsSelectedTxt, SalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [HandlerFunctions('SelectPaymentServiceModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestCancelingSelectPaymentServices()
    var
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SetSelectPaymentServiceParameters(true, TempPaymentServiceSetup.Name, true, false);

        // Execute
        SalesInvoice.SelectedPayments.AssistEdit();

        // Verify
        Assert.AreEqual(TempPaymentServiceSetup.Name, SalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncludeAlwaysIsSetByDefaultOnInvoice()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.New();

        // Verify
        Assert.AreEqual(TempPaymentServiceSetup.Name, SalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncludeAlwaysIsSetByDefaultOnOrder()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        SalesOrder.OpenEdit();
        SalesOrder.New();

        // Verify
        Assert.AreEqual(TempPaymentServiceSetup.Name, SalesOrder.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncludeAlwaysIsSetByDefaultOnQuote()
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesQuote: TestPage "Sales Quote";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        SalesQuote.OpenEdit();
        SalesQuote.New();

        // Verify
        Assert.AreEqual(TempPaymentServiceSetup.Name, SalesQuote.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncludeAlwaysMultiplePaymentServices()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
        NumberOfServices: Integer;
    begin
        // Setup
        Initialize();

        NumberOfServices := LibraryRandom.RandIntInRange(2, 10);
        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, NumberOfServices);
        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, NumberOfServices);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.New();

        // Verify
        Assert.AreEqual(GetExpectedName(TempPaymentServiceSetup), SalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncludeAlwaysAndDisabledIsNotSetByOnInvoices()
    var
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateTemplatesAndAccountsForSelectionTest(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Enabled := false;
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateSalesInvoiceLCY(SalesHeader, DummyPaymentMethod);

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Verify
        Assert.AreEqual(NoPaymentMethodsSelectedTxt, SalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetPaymentServiceWhenPaymentMethodIsMarkingInvoiceAsPaid()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, true);
        CreateSalesInvoiceLCY(SalesHeader, PaymentMethod);

        // Execute
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // Verify
        Assert.IsFalse(
          SalesInvoice.SelectedPayments.Enabled(),
          'Invoice - Selected Payments should be set to disabled when payment method has balancing account');
        Assert.IsTrue(
          SalesInvoice.SelectedPayments.Visible(), 'Invoice - Selected Payments should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetPaymentServiceWhenPaymentMethodIsMarkingQuoteAsPaid()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesQuote: TestPage "Sales Quote";
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, true);
        CreateSalesQuote(SalesHeader, PaymentMethod, LCY);

        // Execute
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // Verify
        Assert.IsFalse(
          SalesQuote.SelectedPayments.Enabled(),
          'Quote - Selected Payments should be set to disabled when payment method has balancing account');
        Assert.IsTrue(
          SalesQuote.SelectedPayments.Visible(), 'Quote - Selected Payments should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetPaymentServiceWhenPaymentMethodIsMarkingOrderAsPaid()
    var
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, true);
        CreateSalesOrder(SalesHeader, PaymentMethod, LCY);

        // Execute
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // Verify
        Assert.IsFalse(
          SalesOrder.SelectedPayments.Enabled(),
          'Order - Selected Payments should be set to disabled when payment method has balancing account');
        Assert.IsTrue(
          SalesOrder.SelectedPayments.Visible(), 'Order - Selected Payments should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotChangePaymentServiceOnPaidPostedSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, true);
        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        // Execute
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // Verify
        Assert.IsFalse(
          PostedSalesInvoice.SelectedPayments.Enabled(),
          'Selected Payments should be set to disabled when payment method has balancing account');
        Assert.IsTrue(
          PostedSalesInvoice.SelectedPayments.Visible(), 'Selected Payments should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectedPaymentServiceIsBlankedWhenPaymentMehodIsChangedInvoice()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        PaymentMethodWithBalancingAccount: Record "Payment Method";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup
        Initialize();

        CreatePaymentMethod(PaymentMethod, false);
        CreatePaymentMethod(PaymentMethodWithBalancingAccount, true);
        CreateSalesInvoiceLCY(SalesHeader, PaymentMethod);

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        // Execute
        SalesHeader.Validate("Payment Method Code", PaymentMethodWithBalancingAccount.Code);
        SalesHeader.Modify();

        // Verify
        Assert.AreEqual(0, SalesHeader."Payment Service Set ID", 'SalesInvoice - Payment service should be blanked');
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        Assert.AreEqual(
          NoPaymentMethodsSelectedTxt, SalesInvoice.SelectedPayments.Value, 'SalesInvoice - Wrong value was set on the Sales Invoice');
        Assert.IsTrue(
          SalesInvoice.SelectedPayments.Visible(), 'SalesInvoice - Selected Payments should be visible');

        Assert.IsFalse(
          SalesInvoice.SelectedPayments.Enabled(),
          'SalesInvoice - Selected Payments should be set to disabled when payment method has balancing account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectedPaymentServiceIsBlankedWhenPaymentMehodIsChangedOrder()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        PaymentMethodWithBalancingAccount: Record "Payment Method";
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup
        Initialize();

        CreatePaymentMethod(PaymentMethod, false);
        CreatePaymentMethod(PaymentMethodWithBalancingAccount, true);
        CreateSalesOrder(SalesHeader, PaymentMethod, LCY);

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        // Execute
        SalesHeader.Validate("Payment Method Code", PaymentMethodWithBalancingAccount.Code);
        SalesHeader.Modify();

        // Verify
        Assert.AreEqual(0, SalesHeader."Payment Service Set ID", 'SalesOrder - Payment service should be blanked');
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        Assert.AreEqual(
          NoPaymentMethodsSelectedTxt, SalesOrder.SelectedPayments.Value, 'SalesOrder - Wrong value was set on the Sales Invoice');
        Assert.IsTrue(
          SalesOrder.SelectedPayments.Visible(), 'SalesOrder - Selected Payments should be visible');

        Assert.IsFalse(
          SalesOrder.SelectedPayments.Enabled(),
          'SalesOrder - Selected Payments should be set to disabled when payment method has balancing account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectedPaymentServiceIsBlankedWhenPaymentMehodIsChangedQuote()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        PaymentMethod: Record "Payment Method";
        PaymentMethodWithBalancingAccount: Record "Payment Method";
        SalesQuote: TestPage "Sales Quote";
    begin
        // Setup
        Initialize();

        CreatePaymentMethod(PaymentMethod, false);
        CreatePaymentMethod(PaymentMethodWithBalancingAccount, true);
        CreateSalesQuote(SalesHeader, PaymentMethod, LCY);

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        // Execute
        SalesHeader.Validate("Payment Method Code", PaymentMethodWithBalancingAccount.Code);
        SalesHeader.Modify();

        // Verify
        Assert.AreEqual(0, SalesHeader."Payment Service Set ID", 'SalesQuote - Payment service should be blanked');
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        Assert.AreEqual(
          NoPaymentMethodsSelectedTxt, SalesQuote.SelectedPayments.Value, 'SalesQuote - Wrong value was set on the Sales Invoice');
        Assert.IsTrue(
          SalesQuote.SelectedPayments.Visible(), 'SalesQuote - Selected Payments should be visible');

        Assert.IsFalse(
          SalesQuote.SelectedPayments.Enabled(),
          'SalesQuote - Selected Payments should be set to disabled when payment method has balancing account');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,NotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestQuoteToOrderCarriesPaymentService()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesQuote: TestPage "Sales Quote";
        SalesOrder: TestPage "Sales Order";
        ConfirmConvertingToOrder: Boolean;
        ConfirmOpeningNewDocument: Boolean;
    begin
        // Setup
        Initialize();
        LibraryERM.SetEnableDataCheck(false);

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);

        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateSalesQuote(SalesHeader, DummyPaymentMethod, LCY);

        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        ItemNo := SalesQuote.SalesLines."No.".Value();

        // Execute
        ConfirmConvertingToOrder := true;
        ConfirmOpeningNewDocument := true;
        LibraryVariableStorage.Enqueue(ConfirmConvertingToOrder);
        LibraryVariableStorage.Enqueue(ConfirmOpeningNewDocument);

        SalesOrder.Trap();
        SalesQuote.MakeOrder.Invoke();

        // Verify
        Assert.AreEqual(
          SalesOrder.SelectedPayments.Value, TempPaymentServiceSetup.Name, 'Payment service should be carried over to Sales Order');
        NotificationLifecycleMgt.RecallAllNotifications();

        LibraryERM.SetEnableDataCheck(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestQuoteToInvoiceCarriesPaymentService()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        DummyPaymentMethod: Record "Payment Method";
        SalesQuote: TestPage "Sales Quote";
        SalesInvoice: TestPage "Sales Invoice";
        ConfirmConvertingToInvoice: Boolean;
        ConfirmOpeningNewDocument: Boolean;
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);

        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateSalesQuote(SalesHeader, DummyPaymentMethod, LCY);

        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // Execute
        ConfirmConvertingToInvoice := true;
        ConfirmOpeningNewDocument := true;
        LibraryVariableStorage.Enqueue(ConfirmConvertingToInvoice);
        LibraryVariableStorage.Enqueue(ConfirmOpeningNewDocument);

        SalesInvoice.Trap();
        SalesQuote.MakeInvoice.Invoke();

        // Verify
        Assert.AreEqual(
          SalesInvoice.SelectedPayments.Value, TempPaymentServiceSetup.Name, 'Payment service should be carried over to Sales Invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostedInvoiceDoesntShowDeletedPaymentService()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();

        CreatePaymentMethod(PaymentMethod, false);
        CreateSalesInvoiceLCY(SalesHeader, PaymentMethod);
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        TempPaymentServiceSetup."Setup Record ID" := SalesHeader.RecordId;
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        // Execute
        SalesHeader.Delete();
        Clear(TempPaymentServiceSetup."Setup Record ID");
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Verify
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        Assert.AreEqual(NoPaymentMethodsSelectedTxt, PostedSalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostedInvoiceDoesntShowDeletedPaymentServiceMultipleServicesSelected()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        SalesHeader: Record "Sales Header";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();

        CreatePaymentMethod(PaymentMethod, false);
        CreateSalesInvoiceLCY(SalesHeader, PaymentMethod);
        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, LibraryRandom.RandIntInRange(2, 10));
        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, LibraryRandom.RandIntInRange(2, 10));
        TempPaymentServiceSetup."Setup Record ID" := SalesHeader.RecordId;
        TempPaymentServiceSetup.Modify();

        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        // Execute
        SalesHeader.Delete();
        Clear(TempPaymentServiceSetup."Setup Record ID");
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Verify
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        TempPaymentServiceSetup.Delete();

        Assert.AreEqual(
          GetExpectedName(TempPaymentServiceSetup), PostedSalesInvoice.SelectedPayments.Value, 'Non existing recods should not be shown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostedInvoiceShowsDisabledPaymentServiceMultipleServicesSelected()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentMethod: Record "Payment Method";
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();

        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, LibraryRandom.RandIntInRange(2, 10));
        CreateServiceWithAccounts(TempTemplatePaymentServiceSetup, TempPaymentServiceSetup, LibraryRandom.RandIntInRange(2, 10));
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);
        TempPaymentServiceSetup.Enabled := false;
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // Verify
        Assert.AreEqual(GetExpectedName(TempPaymentServiceSetup), PostedSalesInvoice.SelectedPayments.Value, 'Wrong value was set');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceConnectionListShowsDisabledPaymentServices()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        ServiceConnections: TestPage "Service Connections";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        ServiceConnections.OpenEdit();

        // Verify
        VerifyPaymentServiceIsShownOnServiceConnectionsPage(ServiceConnections, TempPaymentServiceSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceConnectionListShowsEnabledPaymentServices()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        ServiceConnections: TestPage "Service Connections";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreateEnabledPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        ServiceConnections.OpenEdit();

        // Verify
        VerifyPaymentServiceIsShownOnServiceConnectionsPage(ServiceConnections, TempPaymentServiceSetup);
    end;

    [Test]
    [HandlerFunctions('OpenSetupCardMockHandler')]
    [Scope('OnPrem')]
    procedure TestServiceConnectionListOpensPaymentServicesSetupCard()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        ServiceConnections: TestPage "Service Connections";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreateEnabledPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        LibraryVariableStorage.Enqueue(AssignMockSetupPageAndRecord(TempPaymentServiceSetup));
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        ServiceConnections.OpenEdit();
        ServiceConnections.FILTER.SetFilter(Name, TempPaymentServiceSetup.Description);

        // Execute
        ServiceConnections.Setup.Invoke();
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure TestTermsOfServicesAreSet()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        TempTemplatePaymentServiceSetup."Terms of Service" := TermsOfServiceURLTxt;
        TempTemplatePaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        PaymentServices.OpenEdit();

        // Verify first record
        PaymentServices.First();
        PaymentServices."Terms of Service".DrillDown();

        // Verify second record
        Assert.AreEqual(TermsOfServiceURLTxt, PaymentServices."Terms of Service".Value, 'Terms of service have not been set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTermsOfServicesAreNotSet()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentServices: TestPage "Payment Services";
    begin
        // Setup
        Initialize();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        // Execute
        PaymentServices.OpenEdit();

        // Verify first record
        PaymentServices.First();
        PaymentServices."Terms of Service".DrillDown();

        // Verify second record
        Assert.AreEqual('', PaymentServices."Terms of Service".Value, 'Terms of service have not been set correctly');
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestBodyLinkIsSet()
    begin
        BodyLinkIsSet();
    end;

    procedure BodyLinkIsSet()
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
        PaymentMethod: Record "Payment Method";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary;
        LibraryEmail: Codeunit "Library - Email";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);
        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);

        CreatePaymentMethod(PaymentMethod, false);
        CreateAndPostSalesInvoice(SalesInvoiceHeader, PaymentMethod);

        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);

        // Exercise
        TempPaymentServiceSetup.CreateReportingArgs(TempPaymentReportingArgument, SalesInvoiceHeader);
        PostedSalesInvoice.Email.Invoke();

        // Verify
        TempPaymentReportingArgument.FindFirst();
        VerifyBodyText(TempPaymentReportingArgument, SalesInvoiceHeader);
    end;

    local procedure SetCreateNewPaymentServiceTypeParameters(var TempExpectedPaymentServiceSetup: Record "Payment Service Setup" temporary; TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        TempExpectedPaymentServiceSetup.TransferFields(TempTemplatePaymentServiceSetup, false);
        TempExpectedPaymentServiceSetup.Enabled := true;

        // Set parameters to
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Name);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Description);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup.Enabled);
        PaymentServiceExtensionMock.EnqueueForMockEvent(TempExpectedPaymentServiceSetup."Always Include on Documents");
    end;

    local procedure SetSelectPaymentServiceTypeParameters(CancelDialog: Boolean; PaymentServiceName: Text)
    begin
        LibraryVariableStorage.Enqueue(CancelDialog);
        if CancelDialog then
            exit;

        LibraryVariableStorage.Enqueue(PaymentServiceName);
    end;

    local procedure SetSelectPaymentServiceParameters(SelectCancel: Boolean; PaymentServiceName: Text; ExpectedAvailable: Boolean; NewAvailable: Boolean)
    begin
        LibraryVariableStorage.Enqueue(SelectCancel);
        LibraryVariableStorage.Enqueue(PaymentServiceName);
        LibraryVariableStorage.Enqueue(ExpectedAvailable);
        LibraryVariableStorage.Enqueue(NewAvailable);
    end;

    local procedure SetupReportSelections()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.DeleteAll();
        CreateDefaultReportSelection();

        GetCustomBodyLayout(CustomReportLayout);

        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"S.Invoice");
        ReportSelections.FindFirst();
        ReportSelections.Validate("Use for Email Attachment", true);
        ReportSelections.Validate("Use for Email Body", true);
        ReportSelections.Validate("Email Body Layout Code", CustomReportLayout.Code);
        ReportSelections.Modify(true);
    end;

    local procedure CreateDefaultReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"S.Invoice";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := REPORT::"Standard Sales - Invoice";
        ReportSelections.Insert();
    end;

    local procedure GetReportID(): Integer
    begin
        exit(REPORT::"Standard Sales - Invoice");
    end;

    local procedure GetCustomBodyLayout(var CustomReportLayout: Record "Custom Report Layout")
    var
        ReportLayoutList: Record "Report Layout List";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        CustomReportLayout.SetRange("Report ID", GetReportID());
        CustomReportLayout.SetRange(Type, CustomReportLayout.Type::Word);
        CustomReportLayout.SetFilter(Description, '''@*Email Body*''');
        if not CustomReportLayout.FindLast() then begin
            ReportLayoutList.SetRange("Report ID", GetReportID());
            ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
            ReportLayoutList.SetFilter(Name, '''@*Email*''');
            ReportLayoutList.FindFirst();

            TempBlob.CreateOutStream(OutStr);
            ReportLayoutList.Layout.ExportStream(OutStr);
            TempBlob.CreateInStream(InStr);

            CustomReportLayout.Init();
            CustomReportLayout."Report ID" := GetReportID();
            CustomReportLayout.Code := CopyStr(StrSubstNo('MS-X%1', Random(9999)), 1, 10);
            CustomReportLayout."File Extension" := 'docx';
            CustomReportLayout.Description := CopyStr(ReportLayoutList.Name, 1, MaxStrLen(CustomReportLayout.Description));
            CustomReportLayout.Type := CustomReportLayout.Type::Word;
            CustomReportLayout.Layout.CreateOutStream(OutStr);

            CopyStream(OutStr, InStr);

            CustomReportLayout.Insert();
        end;
    end;

    local procedure AssignMockSetupRecordID(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        TempPaymentServiceSetup."Setup Record ID" := Customer.RecordId;
        TempPaymentServiceSetup.Modify();
    end;

    local procedure AssignMockSetupRecordID2(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    var
        CompanyInformation: Record "Company Information";
    begin
        if not CompanyInformation.Get() then
            CompanyInformation.Insert();

        TempPaymentServiceSetup."Setup Record ID" := CompanyInformation.RecordId;
        TempPaymentServiceSetup.Modify();
    end;

    local procedure AssignMockSetupPageAndRecord(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        TempPaymentServiceSetup."Setup Record ID" := Customer.RecordId;
        TempPaymentServiceSetup."Setup Page ID" := PAGE::"Customer Card";
        TempPaymentServiceSetup.Modify();

        exit(Customer."No.");
    end;

    local procedure CreateTemplatesAndAccountsForSelectionTest(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    var
        TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary;
        Description: Text[50];
    begin
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);
        PaymentServiceExtensionMock.SetPaymentServiceTemplates(TempTemplatePaymentServiceSetup);

        CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        Description := 'Default Service Description';
        TempPaymentServiceSetup.Description := Description;
        AssignMockSetupRecordID(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
    end;

    local procedure CreateServiceWithAccounts(var TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary; var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; NumberOfAccounts: Integer)
    var
        I: Integer;
    begin
        CreateDefaultTemplate(TempTemplatePaymentServiceSetup);

        for I := 1 to NumberOfAccounts do begin
            CreateDefaultPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
            TempPaymentServiceSetup.Description := StrSubstNo('Default Service Description %1', I);
            TempPaymentServiceSetup.Name := StrSubstNo('%1 %2', TempPaymentServiceSetup.Name, I);
            AssignMockSetupRecordID(TempPaymentServiceSetup);
            TempPaymentServiceSetup.Modify();
        end;

        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
    end;

    local procedure CreateDefaultTemplate(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        CreateTemplate(TempPaymentServiceSetup);
        TempPaymentServiceSetup.Name := TestServiceNameTxt;
        TempPaymentServiceSetup.Description := TestServiceDescriptionTxt;
        TempPaymentServiceSetup.Modify();
    end;

    local procedure CreateTemplate(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        TempPaymentServiceSetup.Init();
        TempPaymentServiceSetup."No." := LibraryUtility.GenerateGUID();
        TempPaymentServiceSetup.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 1), 1, 10);
        TempPaymentServiceSetup.Description := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(10, 1), 1, 10);
        TempPaymentServiceSetup."Management Codeunit ID" := PaymentServiceExtensionMock.GetCodeunitID();
        TempPaymentServiceSetup.Insert();

        AssignMockSetupRecordID(TempPaymentServiceSetup);
    end;

    local procedure CreatePaymentService(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary)
    var
        NextKey: Text;
    begin
        NextKey := TestServiceTemplateKeyTok;
        if TempPaymentServiceSetup.FindLast() then
            NextKey := IncStr(TempPaymentServiceSetup."No.");

        Clear(TempPaymentServiceSetup);
        TempPaymentServiceSetup.TransferFields(TempTemplatePaymentServiceSetup, false);
        TempPaymentServiceSetup."No." := CopyStr(NextKey, 1, 50);
        TempPaymentServiceSetup.Insert();
    end;

    local procedure CreateEnabledPaymentService(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        CreatePaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        TempPaymentServiceSetup.Enabled := true;
        TempPaymentServiceSetup.Modify();
    end;

    local procedure CreateDefaultPaymentService(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary; var TempTemplatePaymentServiceSetup: Record "Payment Service Setup" temporary)
    begin
        CreateEnabledPaymentService(TempPaymentServiceSetup, TempTemplatePaymentServiceSetup);
        TempPaymentServiceSetup."Always Include on Documents" := true;
        TempPaymentServiceSetup.Modify();
    end;

    local procedure CreateAndPostSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; PaymentMethod: Record "Payment Method")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesInvoiceLCY(SalesHeader, PaymentMethod);
        PostSalesInvoice(SalesHeader, SalesInvoiceHeader);
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetAutoCalcFields(Closed);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesInvoiceLCY(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method")
    begin
        CreateSalesInvoice(SalesHeader, PaymentMethod, '');
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method"; CurrencyCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, PaymentMethod, CurrencyCode, SalesHeader."Document Type"::Invoice);
    end;

    local procedure CreateSalesQuote(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method"; CurrencyCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, PaymentMethod, CurrencyCode, SalesHeader."Document Type"::Quote);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method"; CurrencyCode: Code[10])
    begin
        CreateSalesDocument(SalesHeader, PaymentMethod, CurrencyCode, SalesHeader."Document Type"::Order);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; PaymentMethod: Record "Payment Method"; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);

        if CurrencyCode <> '' then
            SalesHeader.Validate("Currency Code", CurrencyCode);

        SalesHeader.SetDefaultPaymentServices();
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          1);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 1000 + LibraryRandom.RandDec(100, 2));  // Take Random Unit Price greater than 1000 to avoid rounding issues.
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method"; SetBalancingAccount: Boolean)
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        if SetBalancingAccount then begin
            PaymentMethod."Bal. Account Type" := PaymentMethod."Bal. Account Type"::"G/L Account";
            PaymentMethod."Bal. Account No." := LibraryERM.CreateGLAccountNo();
            PaymentMethod.Modify(true);
        end;
    end;

    local procedure GenerateRandomAlphanumericText(): Text[50]
    begin
        exit(LibraryUtility.GenerateRandomAlphabeticText(50, 0));
    end;

    local procedure GetExpectedName(var TempPaymentServiceSetup: Record "Payment Service Setup" temporary): Text
    var
        ExpectedName: Text;
    begin
        TempPaymentServiceSetup.SetRange("Always Include on Documents", true);
        if not TempPaymentServiceSetup.FindFirst() then
            exit('');

        repeat
            ExpectedName += StrSubstNo(',%1', TempPaymentServiceSetup.Name);
        until TempPaymentServiceSetup.Next() = 0;

        exit(CopyStr(ExpectedName, 2));
    end;

    local procedure VerifyPaymentServicePage(PaymentServices: TestPage "Payment Services"; ExpectedPaymentServiceSetup: Record "Payment Service Setup")
    begin
        Assert.AreEqual(ExpectedPaymentServiceSetup.Name, PaymentServices.Name.Value, 'Wrong value set for Name');
        Assert.AreEqual(ExpectedPaymentServiceSetup.Description, PaymentServices.Description.Value, 'Wrong value set for Description');
        Assert.AreEqual(ExpectedPaymentServiceSetup.Enabled, PaymentServices.Enabled.AsBoolean(), 'Wrong value set for Enabled');
        Assert.AreEqual(
          ExpectedPaymentServiceSetup."Always Include on Documents", PaymentServices."Always Include on Documents".AsBoolean(),
          'Wrong value set for Always Include on Documents');
    end;

    local procedure VerifyPaymentServiceIsShownOnServiceConnectionsPage(var ServiceConnections: TestPage "Service Connections"; PaymentServiceSetup: Record "Payment Service Setup")
    var
        ServiceConnection: Record "Service Connection";
    begin
        ServiceConnections.FILTER.SetFilter(Name, PaymentServiceSetup.Description);

        Assert.AreEqual(
          PaymentServiceSetup.Description, ServiceConnections.Name.Value,
          'Description was not set correctly on Service Connections page');

        if PaymentServiceSetup.Enabled then
            Assert.AreEqual(
              Format(ServiceConnection.Status::Enabled), ServiceConnections.Status.Value,
              'Status was not set correctly on Service Connections page')
        else
            Assert.AreEqual(
              Format(ServiceConnection.Status::Disabled), ServiceConnections.Status.Value,
              'Status was not set correctly on Service Connections page');
    end;

    local procedure VerifyBodyText(var TempPaymentReportingArgument: Record "Payment Reporting Argument" temporary; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        BodyHTMLText: Text;
    begin
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        BodyHTMLText := LibraryVariableStorage.DequeueText();

        Assert.AreNotEqual('', TempPaymentReportingArgument."URL Caption", 'Wrong setup data');
        Assert.IsTrue(StrPos(BodyHTMLText, TempPaymentReportingArgument."URL Caption") > 0, 'Url Caption was not set correctly');
        Assert.IsTrue(StrPos(BodyHTMLText, SalesInvoiceHeader."No.") > 0, 'Document No. was not set correctly');
        Assert.IsTrue(
          StrPos(BodyHTMLText, Format(SalesInvoiceHeader."Amount Including VAT", 0, 9)) > 0, 'Total amount was not set correctly');

        GeneralLedgerSetup.Get();
        Assert.IsTrue(
          StrPos(BodyHTMLText, GeneralLedgerSetup.GetCurrencyCode(SalesInvoiceHeader."Currency Code")) > 0,
          'Currency Code was not set correctly');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPaymentServiceTypeModalPageHandler(var SelectPaymentServiceType: TestPage "Select Payment Service Type")
    var
        SelectCancel: Boolean;
        ServiceName: Text;
    begin
        SelectCancel := LibraryVariableStorage.DequeueBoolean();
        if SelectCancel then begin
            SelectPaymentServiceType.Cancel().Invoke();
            exit;
        end;

        ServiceName := LibraryVariableStorage.DequeueText();
        SelectPaymentServiceType.FILTER.SetFilter(Name, ServiceName);
        SelectPaymentServiceType.First();

        Assert.AreEqual(SelectPaymentServiceType.Name.Value,
          ServiceName, 'Could not find the record on the page');

        SelectPaymentServiceType.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectPaymentServiceModalPageHandler(var SelectPaymentService: TestPage "Select Payment Service")
    var
        CancelDialog: Boolean;
        RowFound: Boolean;
        PaymentServiceName: Text;
        ExpectedAvailable: Boolean;
        NewAvailable: Boolean;
    begin
        CancelDialog := LibraryVariableStorage.DequeueBoolean();

        PaymentServiceName := LibraryVariableStorage.DequeueText();
        ExpectedAvailable := LibraryVariableStorage.DequeueBoolean();
        NewAvailable := LibraryVariableStorage.DequeueBoolean();

        SelectPaymentService.Last();
        RowFound := false;
        repeat
            if SelectPaymentService.Name.Value = PaymentServiceName then begin
                RowFound := true;
                Assert.AreEqual(ExpectedAvailable, SelectPaymentService.Available.AsBoolean(), 'Available was not set correctly');
                SelectPaymentService.Available.SetValue(NewAvailable);
            end else
                SelectPaymentService.Available.SetValue(false);
        until SelectPaymentService.Previous() = false;

        Assert.IsTrue(RowFound, 'Row was not found on the page');

        if CancelDialog then
            SelectPaymentService.Cancel().Invoke()
        else
            SelectPaymentService.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OpenSetupCardMockHandler(var CustomerCard: TestPage "Customer Card")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), CustomerCard."No.".Value, 'Wrong record opened');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        LibraryVariableStorage.Enqueue(EmailEditor.BodyField.Value);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(MessageText: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure UpdateExistingOrCreateNewServiceHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnableDisabledPageModalHandler(var PaymentServices: TestPage "Payment Services")
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        PaymentServiceExtensionMock.GetPaymentServiceTemplates(TempPaymentServiceSetup);
        TempPaymentServiceSetup.FindFirst();
        TempPaymentServiceSetup.Enabled := true;
        TempPaymentServiceSetup.Modify();
        PaymentServiceExtensionMock.SetPaymentServiceAccounts(TempPaymentServiceSetup);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure NotificationHandler(var Notification: Notification): Boolean
    var
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        Inventory: Decimal;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual(Notification.GetData('ItemNo'), Item."No.", 'Item No. was different than expected');
        Item.CalcFields(Inventory);
        Evaluate(Inventory, Notification.GetData('InventoryQty'));
        Assert.AreEqual(Inventory, Item.Inventory, 'Available Inventory was different than expected');
        ItemCheckAvail.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var ItemAvailabilityCheck: TestPage "Item Availability Check")
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        ItemAvailabilityCheck.AvailabilityCheckDetails."No.".AssertEquals(Item."No.");
        ItemAvailabilityCheck.AvailabilityCheckDetails.Description.AssertEquals(Item.Description);
        ItemAvailabilityCheck.InventoryQty.AssertEquals(Item.Inventory);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}
