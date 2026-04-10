codeunit 139175 "CRM Sales Order Integr. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration] [Sales] [Order]
        isInitialized := false;
    end;

    var
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        FieldMustHaveAValueErr: Label '%1 must have a value in %2';
        SyncStartedMsg: Label 'The synchronization has been scheduled.';
        DisabledSalesOrderIntSubmittedOrderErr: Label 'You cannot disable CRM sales order integration when a CRM sales order has the Submitted status.';
        SalesOrdernoteNotFoundErr: Label 'Couldn''t find a note for sales order %1 with note text %2.', Locked = true;
        CRMSalesOrdernoteNotFoundErr: Label 'Couldn''t find a note for CRM sales order %1 with note text %2.', Locked = true;
        OrderStatusReleasedTxt: Label 'The order status has changed to Released.';
        OrderShipmentCreatedTxt: Label 'A shipment has been created for the order.';
        MissingWriteInProductNoErr: Label '%1 %2 %3 contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.', Comment = '%1 - Dataverse service name,%2 - document type (order or quote), %3 - document number';

    [Test]
    [Scope('OnPrem')]
    procedure PostToCRMSalesOrderWhenSalesOrderIsReleased()
    var
        CRMPost: Record "CRM Post";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMOrderStatusUpdateJob: Codeunit "CRM Order Status Update Job";
    begin
        // [SCENARIO] Test that a Post is posted to the CRM Sales Order when a Sales Order is released in NAV
        // [GIVEN] We have a coupled CRM Sales Order and NAV Sales Order
        // [WHEN] The Sales Order is released
        // [THEN] A Post is created on the CRM Sales Order
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [GIVEN] No posts on the CRM Sales Order
        CRMPost.SetRange(RegardingObjectId, CRMSalesorder.SalesOrderId);
        CRMPost.SetRange(RegardingObjectTypeCode, CRMPost.RegardingObjectTypeCode::salesorder);
        Assert.AreEqual(0, CRMPost.Count, 'There should be no posts at this point');

        // [WHEN] The user releases the sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] The codeunit CRM Sales Order Status Job runs asynchronously
        CRMOrderStatusUpdateJob.CreateStatusPostOnModifiedOrders();

        // [THEN] A Post is created on the CRM Sales Order
        CRMPost.SetRange(Text, OrderStatusReleasedTxt);
        Assert.AreEqual(1, CRMPost.Count, 'Post about releasing sales order not created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostToCRMSalesOrderWhenSalesOrderIsShipped()
    var
        CRMPost: Record "CRM Post";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMOrderStatusUpdateJob: Codeunit "CRM Order Status Update Job";
    begin
        // [SCENARIO] Test that a Post is posted to the CRM Sales Order when a Sales Order is released in NAV
        // [GIVEN] We have a coupled CRM Sales Order and NAV Sales Order
        // [WHEN] A shipment is posted for the sales order
        // [THEN] A Post is created on the CRM Sales Order
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [GIVEN] No posts on the CRM Sales Order
        CRMPost.SetRange(RegardingObjectId, CRMSalesorder.SalesOrderId);
        CRMPost.SetRange(RegardingObjectTypeCode, CRMPost.RegardingObjectTypeCode::salesorder);
        Assert.AreEqual(0, CRMPost.Count, 'There should be no posts at this point');

        // [WHEN] The user posts a shipment for the sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] The codeunit CRM Sales Order Status Job runs asynchronously
        CRMOrderStatusUpdateJob.CreateStatusPostOnModifiedOrders();

        // [THEN] A Post is created on the CRM Sales Order
        CRMPost.SetRange(Text, OrderShipmentCreatedTxt);
        Assert.AreEqual(1, CRMPost.Count, 'Post about shipping sales order not created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostToAccountWhenSalesOrderIsPosted()
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        // [SCENARIO] Test that a Post is posted to the CRM Account when a Sales Order is posted in NAV
        // [GIVEN] We have a coupled CRM Account and NAV Customer
        // [GIVEN] We have a Sales Order created to that Customer
        // [WHEN] The Sales Order is posted
        // [THEN] A Post is created on the Account
        Initialize(false);
        CleanCRMPostBuffer(CRMPostBuffer);

        // [GIVEN] CRM Salesorder in local currency
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        Assert.IsTrue(CRMPostBuffer.IsEmpty(), 'CRMPostBuffer should be empty');

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.AreEqual(4, CRMPostBuffer.Count(), 'Nothing is posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DontPostToAccountWhenUncoupledInvoiceIsPosted()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMPostBuffer: Record "CRM Post Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Test that a Post is posted to the CRM Account when an Invoice is posted in NAV
        // [GIVEN] We have a coupled CRM Account and NAV Customer
        // [GIVEN] We have a Invoice created to that Customer
        // [WHEN] The Sales Order is posted
        // [THEN] A Post is created on the Account
        Initialize(false);
        CleanCRMPostBuffer(CRMPostBuffer);

        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        ItemNo := '';
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Invoice, Customer."No.", ItemNo, 1, '', WorkDate());

        Assert.IsTrue(CRMPostBuffer.IsEmpty(), 'CRMPostBuffer should be empty');

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.AreEqual(0, CRMPostBuffer.Count(), 'Nothing is posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotPostToAccountWhenCreditMemoIsPosted()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMPostBuffer: Record "CRM Post Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Test that nothing is posted to the CRM Account when a Credit Memo is posted in NAV
        // [GIVEN] We have a coupled CRM Account and NAV Customer
        // [GIVEN] We have a Invoice created to that Customer
        // [WHEN] The Sales Order is posted
        // [THEN] A Post is created on the Account
        Initialize(false);
        CleanCRMPostBuffer(CRMPostBuffer);

        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        ItemNo := '';
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
          SalesHeader."Document Type"::"Credit Memo", Customer."No.", ItemNo, 1, '', WorkDate());

        Assert.IsTrue(CRMPostBuffer.IsEmpty(), 'CRMPostBuffer should be empty');

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.IsTrue(CRMPostBuffer.IsEmpty(), 'CRMPostBuffer should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderFCY()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        FCYCurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Salesorder in FCY can be created in NAV
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder in 'X' currency
        FCYCurrencyCode := GetFCYCurrencyCode();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, FCYCurrencyCode);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where "Currency Code" is 'X'
        SalesHeader.TestField("Currency Code", FCYCurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderFCYNotExists()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        FCYCurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Salesorder in FCY cannot be created in NAV if Currency not exists
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder in 'X' currency, Currency not exists in NAV
        FCYCurrencyCode := GetFCYCurrencyCode();
        DeleteCurrencyInNAV(FCYCurrencyCode);
        CreateCRMSalesorderWithCurrency(CRMSalesorder, FCYCurrencyCode);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        asserterror CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Error: Currency 'X' does not exist
        Assert.ExpectedErrorCannotFind(Database::Currency);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderLCY()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 144800] CRM Sales Order in LCY can be created in NAV
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where "Currency Code" is ''
        SalesHeader.TestField("Currency Code", '');
        // [GIVEN] CRM Sales Order's "State" is Submitted, "Status" is 'InProgress', LastBackofficeSubmit is TODAY
        VerifyCRMSalesorderStateAndStatus(
          CRMSalesorder, CRMSalesorder.StateCode::Submitted, CRMSalesorder.StatusCode::InProgress);
        CRMSalesorder.TestField(LastBackofficeSubmit, Today);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderLCYWithExternalDocNoCanBePosted()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [External Document No.]
        // [SCENARIO 175130] CRM Sales Order can be invoiced, if "External Document No." is changed in NAV Order
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        // [GIVEN] Created NAV Order from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);
        // [GIVEN] "External Document No." is changed in NAV Order
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);

        // [WHEN] Post the NAV Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] CRM Sales Order's "State" is 'Invoiced', "Status" is 'Invoiced'
        VerifyCRMSalesorderStateAndStatus(
          CRMSalesorder, CRMSalesorder.StateCode::Invoiced, CRMSalesorder.StatusCode::Invoiced);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderManualDiscInLine()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where 1 line has manual discount, created in NAV with line discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where 1 line has manual discount 100
        PrepareCRMSalesOrder(CRMSalesorder, LibraryRandom.RandDecInRange(5, 10, 2), 0);

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where one line has "Line Discount Amount" = 100
        VerifySalesLineFromCRM(CRMSalesorder.SalesOrderId, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderVolumeDiscInLine()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where 1 line has volume discount, created in NAV with line discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where 1 line has volume discount 150
        PrepareCRMSalesOrder(CRMSalesorder, 0, LibraryRandom.RandDecInRange(5, 10, 2));

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where one line has "Line Discount Amount" = 150
        VerifySalesLineFromCRM(CRMSalesorder.SalesOrderId, SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderManualAndVolumeDiscInLine()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where 1 line has manual and volume discount, created in NAV with summed line discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where 1 line has manual discount 100 and volume discount 150
        PrepareCRMSalesOrder(
          CRMSalesorder, LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(5, 10, 2));

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where one line has "Line Discount Amount" = 250
        VerifySalesLineFromCRM(CRMSalesorder.SalesOrderId, SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CRMSalesOrderAmountDiscInHeader()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where is amount discount, created in NAV with order discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where is amount discount 400
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);
        LibraryCRMIntegration.SetCRMSalesOrderDiscount(CRMSalesorder, 0, LibraryRandom.RandDecInRange(5, 10, 2));

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where is "Invoice Discount Amount" = 400
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", CRMSalesorder.DiscountAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CRMSalesOrderPercentageDiscInHeader()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        ExpectedDiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where is percentage discount, created in NAV with order discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where is percentage discount 300
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);
        LibraryCRMIntegration.SetCRMSalesOrderDiscount(CRMSalesorder, LibraryRandom.RandIntInRange(1, 5), 0);

        ExpectedDiscountAmount :=
          LibraryERM.ApplicationAmountRounding(
            CRMSalesorder.TotalLineItemAmount * CRMSalesorder.DiscountPercentage / 100, SalesHeader."Currency Code");

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where is "Order Discount Amount" = 300
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", ExpectedDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CRMSalesOrderAmountAndPercentageDiscInHeader()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        ExpectedDiscountAmount: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 172256] CRM Sales Order, where is percentage and amount discount, created in NAV with summed order discount
        Initialize(false);
        ClearCRMData();

        // [GIVEN]  CRM Salesorder, where is percentage discount 300, amount discount 400
        PrepareCRMSalesOrder(CRMSalesorder, 0, 0);
        LibraryCRMIntegration.SetCRMSalesOrderDiscount(
          CRMSalesorder, LibraryRandom.RandIntInRange(1, 5), LibraryRandom.RandDecInRange(5, 10, 2));

        ExpectedDiscountAmount :=
          CRMSalesorder.DiscountAmount +
          LibraryERM.ApplicationAmountRounding(
            CRMSalesorder.TotalLineItemAmount * CRMSalesorder.DiscountPercentage / 100, SalesHeader."Currency Code");

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where is "Order Discount Amount" = 700
        SalesHeader.CalcFields("Invoice Discount Amount");
        SalesHeader.TestField("Invoice Discount Amount", ExpectedDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnFreightAccountIsEmpty()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Freight]
        // [SCENARIO 172256] Error expected when create NAV Sales Order from CRM Sales Order with freight amount, if "Sales & Receivables Setup"."G/L Freight Account No." is empty
        Initialize(false);
        ClearCRMData();

        // [GIVEN] "G/L Freight Account No." is empty in Sales & Receivables Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", '');
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] CRM Salesorder, where is freight amount 300
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup.GetCurrencyCode(''));
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CRMSalesorder.FreightAmount := LibraryRandom.RandDecInRange(10, 100, 2);
        CRMSalesorder.Modify();

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        asserterror CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Sales Order created, where is "Order Discount Amount" = 700
        Assert.ExpectedError(
          StrSubstNo(
            FieldMustHaveAValueErr,
            SalesReceivablesSetup.FieldCaption("Freight G/L Acc. No."),
            SalesReceivablesSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderFreightInHeader()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        FreightGLAccNo: Code[20];
    begin
        // [FEATURE] [Freight]
        // [SCENARIO 172256] CRM Sales Order, where is freight amount, created in NAV with G/L account freight line
        Initialize(false);
        ClearCRMData();

        // [GIVEN] "G/L Freight Account No." is not empty in Sales & Receivables Setup
        FreightGLAccNo := LibraryCRMIntegration.SetFreightGLAccNo();

        // [GIVEN] CRM Salesorder, where is freight amount 300
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup.GetCurrencyCode(''));
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CRMSalesorder.FreightAmount := LibraryRandom.RandDecInRange(10, 100, 2);
        CRMSalesorder.Modify();

        // [WHEN] Run 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);
        // [THEN] Sales Order created, where is "Order Discount Amount" = 700
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", FreightGLAccNo);
        SalesLine.FindFirst();
        SalesLine.TestField(Amount, CRMSalesorder.FreightAmount);
    end;

    [Test]
    [HandlerFunctions('SyncStartedNotificationHandler,ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FreighLineOfSalesInvoiceCopiedToCRMInvoice()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        // [FEATURE] [Freight] [Discount] [Sales] [Invoice]
        // [SCENARIO] Sales Order with Freight Line should should be copied to CRM Invoice.
        Initialize(false);
        LibraryCRMIntegration.CreateCRMOrganization();
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup.Modify();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);

        // [GIVEN] Posted Invoice with 2 lines: the Freight Line, where G/L Account = 'F'; the Item line, where Item = 'I'
        PostCRMSalesOrderWithFreightAndDiscounts(CRMSalesorder, CRMSalesorderdetail, SalesInvoiceHeader);
        // [GIVEN] CRM Salesorder is created, where FreightAmount, DiscountAmount, and DiscountPercentage are not blank
        CRMSalesorder.TestField(FreightAmount);
        CRMSalesorder.TestField(DiscountAmount);
        CRMSalesorder.TestField(DiscountPercentage);

        // [WHEN] run "Create CRM Invoice"
        LibraryCRMIntegration.UnbindBusLogicSimulator();
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMIntegrationManagement.CreateNewRecordsInCRM(SalesInvoiceHeader.RecordId);
        // JobQueueEntry is inserted and executed
        SalesInvoiceHeader.SetRange(SystemId, SalesInvoiceHeader.SystemId);
        LibraryCRMIntegration.RunJobQueueEntry(
          DATABASE::"Sales Invoice Header", SalesInvoiceHeader.GetView(), IntegrationTableMapping);

        // [THEN] CRM Invoice created, with 2 Item lines:
        CRMIntegrationRecord.FindByRecordID(SalesInvoiceHeader.RecordId);
        CRMInvoice.Get(CRMIntegrationRecord."CRM ID");
        CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(SalesInvoiceLine.Count, CRMInvoicedetail.Count, 'line counter is wrong.');
        // [THEN] the one line is for Item, where ExtendedAmount also includes both Invoice and Line discounts
        SalesInvoiceLine.FindFirst();
        CRMInvoicedetail.SetRange(LineItemNumber, SalesInvoiceLine."Line No.");
        CRMInvoicedetail.FindFirst();
        CRMInvoicedetail.TestField(IsProductOverridden, false);
        CRMInvoicedetail.TestField(
          ExtendedAmount,
          SalesInvoiceLine."Amount Including VAT" + SalesInvoiceLine."Inv. Discount Amount" + SalesInvoiceLine."Line Discount Amount");
        // [THEN] the second line is for Freight, where IsProductOverridden = 'Yes',ProductDescription = 'F', BaseAmount = Order's FreightAmount
        SalesInvoiceLine.FindLast();
        CRMInvoicedetail.SetRange(LineItemNumber, SalesInvoiceLine."Line No.");
        CRMInvoicedetail.FindFirst();
        CRMInvoicedetail.TestField(IsProductOverridden, true);
        Assert.ExpectedMessage(SalesInvoiceLine.Description, CRMInvoicedetail.ProductDescription);
        CRMInvoicedetail.TestField(BaseAmount, CRMSalesorder.FreightAmount);
        CRMInvoicedetail.TestField(ExtendedAmount, SalesInvoiceLine."Amount Including VAT" + SalesInvoiceLine."Inv. Discount Amount");

        // [THEN] CRM Invoice header, where FreightAmount = 0, DiscountPercentage = 0,  DiscountAmount = Order's TotalDiscountAmount
        CRMInvoice.TestField(FreightAmount, 0);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        CRMInvoice.TestField(TotalAmount, SalesInvoiceHeader."Amount Including VAT");
        CRMInvoice.TestField(DiscountAmount, CRMSalesorder.TotalDiscountAmount);
        CRMInvoice.TestField(DiscountPercentage, 0);
        CRMInvoice.TestField(FreightAmount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableCRMSalesOrderIntegrationWithSOInSubmittedState()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211784] CRM Sales Order Integration cannot be disabled when CRM Sales Order in Submitted Status exist
        Initialize(false);

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(true);

        // [GIVEN] CRM Salesorder in "Submitted" State
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is CRM Solution Installed" := true;
        CRMConnectionSetup.Modify();

        // [WHEN] Disabled CRM Sales Order Integration action is invoked
        asserterror CRMConnectionSetup.SetCRMSOPDisabled();

        // [THEN] Error message appears stating there are CRM Sales Orders in "Submitted" State
        Assert.ExpectedError(DisabledSalesOrderIntSubmittedOrderErr);
        CRMConnectionSetup.SetCRMSOPEnabled();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DisableCRMSalesOrderIntegration()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMOrganization: Record "CRM Organization";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211784] Disable CRM Sales Order Integration
        Initialize(false);

        // [GIVEN] CRM Connection Enabled and Sales Order Integration enabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(false);
        CRMConnectionSetup.Get();

        // [WHEN] CRM Connection Setup SetCRMSOPDisabled is invoked
        CRMConnectionSetup.SetCRMSOPDisabled();

        // [THEN] CRMOrganization Record has "IsSOPIntegrationEnabled" = FALSE, CRM Connection Setup has "Sales Order Integration Enabled" = FALSE
        CRMOrganization.FindFirst();
        CRMOrganization.TestField(IsSOPIntegrationEnabled, false);
        CRMConnectionSetup.Get();
        CRMConnectionSetup.TestField("Is S.Order Integration Enabled", false);
        ResetDefaultCRMSetupConfiguration(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnableCRMSalesOrderIntegrationWhenNoCRMSolutionInstalled()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 211784] CRM Sales Order Integration cannot be enabled if CRM Solution is not installed
        Initialize(false);

        // [GIVEN] CRM Connection Enabled and Sales Order Integration disabled
        LibraryCRMIntegration.ConfigureCRM();
        LibraryCRMIntegration.CreateCRMOrganization();
        SetSalesOrderIntegrationInOrg(false);

        // [GIVEN] "Is CRM Solution installed" = FALSE
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is CRM Solution Installed" := false;
        CRMConnectionSetup.Modify();

        // [WHEN] CRM Connection Setup SetCRMSOPEnabled is invoked
        asserterror CRMConnectionSetup.SetCRMSOPEnabled();

        // [THEN] Error message appears stating CRM Solution should be installed
        Assert.ExpectedTestFieldError(CRMConnectionSetup.FieldCaption("Is CRM Solution Installed"), Format(true));
        ResetDefaultCRMSetupConfiguration(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderStateInvoicedAfterFullyInvoicedNAVOrder()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Get Shipment Lines]
        // [SCENARIO 221153] CRM Sales order got State=Invoiced after related NAV sales order became fully invoiced
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        // [GIVEN] Created NAV Order from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeaderOrder);
        // [GIVEN] NAV order posted as ship
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales invoice with line created by Get Shipment Lines from NAV Order
        CreateSalesInvoiceWithGetShipmentLine(SalesHeaderInvoice, SalesHeaderOrder, ShipmentNo);

        // [WHEN] Post the NAV invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] CRM Sales Order's "State" is 'Invoiced', "Status" is 'Invoiced'
        VerifyCRMSalesorderStateAndStatus(
          CRMSalesorder, CRMSalesorder.StateCode::Invoiced, CRMSalesorder.StatusCode::Invoiced);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrdersStateInvoicedAfterFullyInvoicedNAVOrdersByOneInvoice()
    var
        Customer: Record Customer;
        CRMSalesorder: array[3] of Record "CRM Salesorder";
        SalesHeaderInvoice: Record "Sales Header";
        ShipmentNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Get Shipment Lines]
        // [SCENARIO 221153] CRM Sales orders got State=Invoiced after related NAV sales orders became fully invoiced by one sales invoice
        Initialize(false);
        ClearCRMData();

        // [GIVEN] 3 CRM Salesorders in local currency for same customer
        CreateSeveralCRMSalesordersForSameCustomer(Customer, CRMSalesorder, ShipmentNo);

        // [GIVEN] Sales invoice with lines created by Get Shipment Lines from 3 NAV Orders
        CreateSalesInvoiceWithGetShipmentLineFromSeveralOrders(SalesHeaderInvoice, Customer."No.", ShipmentNo);

        // [WHEN] Post the NAV invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] All 3 CRM Sales Orders' "State" is 'Invoiced', "Status" is 'Invoiced'
        for i := 1 to 3 do begin
            CRMSalesorder[i].Find();
            VerifyCRMSalesorderStateAndStatus(
              CRMSalesorder[i], CRMSalesorder[i].StateCode::Invoiced, CRMSalesorder[i].StatusCode::Invoiced);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderStateSubmittedAfterNAVOrderShippedOnly()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeaderOrder: Record "Sales Header";
    begin
        // [FEATURE] [Get Shipment Lines]
        // [SCENARIO 221153] CRM Sales order State=Submitted after related NAV sales order became shipped only
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        // [GIVEN] Created NAV Order from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeaderOrder);

        // [WHEN] NAV order posted as ship
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [THEN] CRM Sales Order's "State" is 'Submitted', "Status" is 'InProgress'
        VerifyCRMSalesorderStateAndStatus(
          CRMSalesorder, CRMSalesorder.StateCode::Submitted, CRMSalesorder.StatusCode::InProgress);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderStateSubmittedAfterPartlyInvoicedNAVOrder()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Get Shipment Lines]
        // [SCENARIO 221153] CRM Sales order State=Submitted after related NAV sales order became partly invoiced
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        // [GIVEN] Created NAV Order from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeaderOrder);
        // [GIVEN] NAV order posted as ship
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales invoice with line created by Get Shipment Lines from NAV Order
        CreateSalesInvoiceWithGetShipmentLine(SalesHeaderInvoice, SalesHeaderOrder, ShipmentNo);

        // [GIVEN] Sales invoice line prepared to be partly invoiced
        SalesLine.SetRange("Document No.", SalesHeaderInvoice."No.");
        SalesLine.SetRange("Document Type", SalesHeaderInvoice."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, SalesLine.Quantity / 2);
        SalesLine.Modify(true);

        // [WHEN] Post the NAV invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] CRM Sales Order's "State" is 'Submitted', "Status" is 'InProgress'
        VerifyCRMSalesorderStateAndStatus(
          CRMSalesorder, CRMSalesorder.StateCode::Submitted, CRMSalesorder.StatusCode::InProgress);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderUncoupledAfterSalesHeaderDelete()
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency
        CreateCRMSalesorderInLCY(CRMSalesorder);

        // [WHEN] The user clicks 'Create in NAV' CRM Sales Orders page
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [WHEN] Sales Order is deleted by the user
        SalesHeader.Delete(true);

        // [THEN] CRM Sales Order is uncoupled
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMSalesorder.SalesOrderId), 'CRM Sales Order should be uncoupled after deleting the Business Central sales order.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateNAVSalesOrderWithAssembleToOrderItem()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        // [FEATURE] [Assembly] [Assemble-to-Order]
        // [SCENARIO 253711] When a sales order is transferred from CRM, and the item being sold has "Assemble-to-Order" assembly policy, linked assembly order should be automatically created

        Initialize(false);

        // [GIVEN] Item "I" replenished by assembly and having "Assemble-to-Order" assembly policy. Item is coulped with a CRM product.
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);

        // [GIVEN] CRM sales order for "X" pcs of item "I"
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.Modify();
        LibraryCRMIntegration.PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);

        // [WHEN] Create NAV sales order from CRM
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Linked assembly order for "X" pcs of item "I" is created
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Qty. to Assemble to Order", CRMSalesorderdetail.Quantity);

        LibraryAssembly.FindLinkedAssemblyOrder(AssemblyHeader, SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        AssemblyHeader.TestField(Quantity, CRMSalesorderdetail.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotDefiendWriteInProductNo()
    var
        SalesHeader: Record "Sales Header";
        SalesSetup: Record "Sales & Receivables Setup";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMProductName: Codeunit "CRM Product Name";
    begin
        // [SCENARIO 211596] Creating Sales Order from CRM Sales Order when SalesSetup."Write-in Product No." is not defined leads to error
        Initialize(false);

        // [GIVEN] Write-in Product No. is not defined
        LibraryCRMIntegration.SetSalesSetupWriteInProduct(SalesSetup."Write-in Product Type"::Item, '');

        // [GIVEN] CRM Sales Order created with line with empty Product Id (sign of write-in product)
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        asserterror CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Function failed with error "Write-in Product No. must have a value in Sales & Receivables Setup"
        Assert.ExpectedError(
          StrSubstNo(
            MissingWriteInProductNoErr,
            CRMProductName.CDSServiceName(),
            SalesHeader."Document Type"::Order,
            CRMSalesorder.OrderNumber));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteInProductItem()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 211596] Create Sales Order from CRM Sales Order with write-in product defined as item
        Initialize(false);

        // [GIVEN] Setup write-in product as Item 'ITEM'
        LibraryCRMIntegration.PrepareWriteInProductItem(Item);

        // [GIVEN] CRM Sales Order created with line with empty Product Id (sign of write-in product)
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains line with item 'ITEM'
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.TestField("No.", Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteInProductResource()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
    begin
        // [SCENARIO 211596] Create Sales Order from CRM Sales Order with write-in product defined as resource
        Initialize(false);

        // [GIVEN] Setup write-in product as Resource 'RES'
        LibraryCRMIntegration.PrepareWriteInProductResource(Resource);

        // [GIVEN] CRM Sales Order created with line with empty Product Id (sign of write-in product)
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains line with resource 'RES'
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange(Type, SalesLine.Type::Resource);
        SalesLine.FindFirst();
        SalesLine.TestField("No.", Resource."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongProductDescriptionItem()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 211535] Long CRM Product (item) description causes creating additional sales lines with Description field containing trancated product description part
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Mock 250 symbols length CRMSalesorderdetail.ProductDescription
        MockLongCRMSalesorderdetailProductDescription(CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesDescription(SalesHeader, CRMSalesorderdetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongProductDescriptionResource()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 211535] Long CRM Product (resource) description causes creating additional sales lines with Description field containing trancated product description part
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency with resource
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLineWithResource(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Mock 250 symbols length CRMSalesorderdetail.ProductDescription
        MockLongCRMSalesorderdetailProductDescription(CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesDescription(SalesHeader, CRMSalesorderdetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongWriteInProductDescription()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // [SCENARIO 211535] Long write-in product description causes creating additional sales lines with Description field containing trancated product description part
        Initialize(false);

        // [GIVEN] Setup write-in product as Item 'ITEM'
        LibraryCRMIntegration.PrepareWriteInProductItem(Item);

        // [GIVEN] CRM Sales Order created with line with empty Product Id (sign of write-in product)
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Mock 250 symbols length CRMSalesorderdetail.ProductDescription
        MockLongCRMSalesorderdetailProductDescription(CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains 5 lines, long description split by 5 pieces for 50 symbols
        VerifySalesLinesWriteInDescription(SalesHeader, CRMSalesorderdetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineItemDescriptionUsedInsteadOfProductDescription()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        InStream: InStream;
        SalesHeaderDescriptionText: Text;
    begin
        // CRM Sales Order Line Description (and not CRM Product Description) is used as Business Central Sales Order line description
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] Mock 250 symbols length CRMSalesorderdetail.ProductDescription
        MockLongCRMSalesorderdetailProductDescription(CRMSalesorderdetail);

        // [GIVEN] Mock long CRMSalesorderdetail.Description
        MockLongCRMSalesorderdetailDescription(CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order is using CRMSalesorderdetail.Description as Description
        CRMSalesorderdetail.CalcFields(Description);
        CRMSalesorderdetail.Description.CreateInStream(InStream, TEXTENCODING::UTF16);
        InStream.Read(SalesHeaderDescriptionText);

        VerifySalesLinesDescription(SalesHeader, SalesHeaderDescriptionText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderNoteToSalesOrderNoteAtCreationTime()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        AnnotationText: Text;
    begin
        // CRM Sales Order note is used as Business Central Sales Order note
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] A CRM note bound to the sales order
        AnnotationText := LibraryRandom.RandText(25);
        MockCRMSalesOrderNote(CRMAnnotation, CRMSalesorder, AnnotationText);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order has a note with the mocked note text
        VerifySalesOrderNote(SalesHeader, AnnotationText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchNewCRMSalesOrderNoteToSalesOrderNote()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        CRMAnnotation2: Record "CRM Annotation";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        CRMNotesSynchJob: Codeunit "CRM Notes Synch Job";
        AnnotationText: Text;
        AnnotationText2: Text;
        CreatedAfterDateTime: DateTime;
    begin
        // CRM Sales Order note is used as Business Central Sales Order note
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] A CRM note bound to the sales order
        AnnotationText := LibraryRandom.RandText(25);
        MockCRMSalesOrderNote(CRMAnnotation, CRMSalesorder, AnnotationText);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [WHEN] Another CRM note bound to the sales order
        AnnotationText2 := LibraryRandom.RandText(25);
        CreatedAfterDateTime := CurrentDateTime;
        MockCRMSalesOrderNote(CRMAnnotation2, CRMSalesorder, AnnotationText2);

        // [WHEN] CODEUNIT::"CRM Notes Synch Job" runs the CreateNotesForCreatedAnnotations method
        CRMNotesSynchJob.CreateNotesForCreatedAnnotations(CreatedAfterDateTime);

        // [THEN] Created NAV Sales Order has two notes with the mocked note texts
        VerifySalesOrderNote(SalesHeader, AnnotationText);
        VerifySalesOrderNote(SalesHeader, AnnotationText2);
    end;

    [Test]
    procedure SynchHTMLCRMSalesOrderNoteToSalesOrderNote()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        AnnotationText: Text;
        RandomText: Text;
        RandomText2: Text;
        LF: Char;
    begin
        // CRM Sales Order note is used as Business Central Sales Order note
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] A CRM note bound to the sales order with HTML content
        RandomText := LibraryRandom.RandText(25);
        RandomText2 := LibraryRandom.RandText(25);
        LF := 10;
        AnnotationText := '<div class="ck-content" data-wrapper="true" dir="ltr" style="--ck-image-style-spacing: 1.5em; --ck-inline-image-style-spacing: calc(var(--ck-image-style-spacing) / 2); --ck-color-selector-caption-background: hsl(0, 0%, 97%); --ck-color-selector-caption-text: hsl(0, 0%, 20%); font-family: Segoe UI; font-size: 11pt;"><p style="margin: 0;">'
        + RandomText + '</p><p style="margin: 0;">' + RandomText2 + '</p></div>';
        MockCRMSalesOrderNote(CRMAnnotation, CRMSalesorder, AnnotationText);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order has a note with the mocked note text without HTML tags
        VerifySalesOrderNote(SalesHeader, RandomText + Format(LF) + RandomText2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchModifiedCRMSalesOrderNoteToSalesOrderNote()
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        CRMNotesSynchJob: Codeunit "CRM Notes Synch Job";
        OutStream: OutStream;
        AnnotationText: Text;
        AnnotationText2: Text;
        ModifiedAfterDateTime: DateTime;
    begin
        // CRM Sales Order note is used as Business Central Sales Order note
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] A CRM note bound to the sales order
        AnnotationText := LibraryRandom.RandText(25);
        MockCRMSalesOrderNote(CRMAnnotation, CRMSalesorder, AnnotationText);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [WHEN] CRM note bound to the sales order is modified
        AnnotationText2 := LibraryRandom.RandText(25);
        ModifiedAfterDateTime := CurrentDateTime;
        CRMAnnotation.NoteText.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.Write(AnnotationText2);
        CRMAnnotation.ModifiedOn := CurrentDateTime;
        CRMAnnotation.Modify();

        // [WHEN] CODEUNIT::"CRM Notes Synch Job" runs the ModifyNotesForModifiedAnnotations method
        CRMNotesSynchJob.ModifyNotesForModifiedAnnotations(ModifiedAfterDateTime);

        // [THEN] Created NAV Sales Order has a note with the modified note text
        VerifySalesOrderNote(SalesHeader, AnnotationText2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SynchNewSalesOrderNoteToCRMSalesOrderNote()
    var
        RecordLink: Record "Record Link";
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        CRMNotesSynchJob: Codeunit "CRM Notes Synch Job";
        AnnotationText: Text;
        AnnotationText2: Text;
    begin
        // CRM Sales Order note is used as Business Central Sales Order note
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] A CRM note bound to the sales order
        AnnotationText := LibraryRandom.RandText(25);
        MockCRMSalesOrderNote(CRMAnnotation, CRMSalesorder, AnnotationText);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [WHEN] Another note bound to the sales order
        AnnotationText2 := LibraryRandom.RandText(25);
        CreateNote(SalesHeader, AnnotationText2, RecordLink);

        // [WHEN] CODEUNIT::"CRM Notes Synch Job" runs the CreateAnnotationsForCreatedNotes method
        CRMNotesSynchJob.CreateAnnotationsForCreatedNotes();

        // [THEN] Coupled CRM Sales Order has a note corresponding to the new BC sales order note
        VerifyCRMSalesOrderNote(SalesHeader, AnnotationText2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMSalesOrderListFilters()
    var
        CRMSalesorder: array[5] of Record "CRM Salesorder";
        CRMSalesOrderList: TestPage "CRM Sales Order List";
    begin
        // [FEATURE] [Sales Order]
        // [SCENARIO] CRM Sales Order page presents only the orders with StateCode=Submitted and LastBackofficeSubmit equal to 0D or 1900-01-01
        Initialize(false);

        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=0D
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder[1]);
        CRMSalesorder[1].StateCode := CRMSalesorder[1].StateCode::Submitted;
        Clear(CRMSalesorder[1].LastBackofficeSubmit);
        CRMSalesorder[1].Modify();
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1899-12-31
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder[2]);
        CRMSalesorder[2].StateCode := CRMSalesorder[2].StateCode::Submitted;
        CRMSalesorder[2].LastBackofficeSubmit := DMY2Date(31, 12, 1899);
        CRMSalesorder[2].Modify();
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-01
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder[3]);
        CRMSalesorder[3].StateCode := CRMSalesorder[3].StateCode::Submitted;
        CRMSalesorder[3].LastBackofficeSubmit := DMY2Date(1, 1, 1900);
        CRMSalesorder[3].Modify();
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-02
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder[4]);
        CRMSalesorder[4].StateCode := CRMSalesorder[4].StateCode::Submitted;
        CRMSalesorder[4].LastBackofficeSubmit := DMY2Date(2, 1, 1900);
        CRMSalesorder[4].Modify();
        // [GIVEN] Active CRM sales order
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder[5]);
        CRMSalesorder[5].StateCode := CRMSalesorder[5].StateCode::Active;
        CRMSalesorder[5].Modify();

        // [WHEN] The user opens CRM Sales Orders page
        CRMSalesOrderList.OpenView();

        // [THEN] Submitted CRM sales order with LastBackofficeSubmit=0D is presented
        Assert.IsTrue(CRMSalesOrderList.GoToRecord(CRMSalesorder[1]), 'Sales Order 1 should be presented.');
        // [THEN] Submitted CRM sales order with LastBackofficeSubmit=1899-12-31 is not presented
        Assert.IsFalse(CRMSalesOrderList.GoToRecord(CRMSalesorder[2]), 'Sales Order 2 should not be presented.');
        // [THEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-01 is presented
        Assert.IsTrue(CRMSalesOrderList.GoToRecord(CRMSalesorder[3]), 'Sales Order 3 should be presented.');
        // [THEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-02 is not presented
        Assert.IsFalse(CRMSalesOrderList.GoToRecord(CRMSalesorder[4]), 'Sales Order 4 should not be presented.');
        // [THEN] Active CRM sales order is not presented
        Assert.IsFalse(CRMSalesOrderList.GoToRecord(CRMSalesorder[5]), 'Sales Order 5 should not be presented.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesOrderInNAVFilters()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorder: array[5] of Record "CRM Salesorder";
        CRMSalesorderdetail: array[5] of Record "CRM Salesorderdetail";
    begin
        // [SCENARIO] Job queue entry "Process submitted sales orders" makes NAV sales order from submitted CRM sales orders with LastBackofficeSubmit equal to 0D or 1900-01-01
        Initialize(false);
        ClearCRMData();

        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=0D
        CreateCRMSalesorderInLCY(CRMSalesorder[1]);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[1], CRMSalesorderdetail[1]);
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1899-12-31
        CreateCRMSalesorderInLCY(CRMSalesorder[2]);
        CRMSalesorder[2].LastBackofficeSubmit := DMY2Date(31, 12, 1899);
        CRMSalesorder[2].Modify();
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[2], CRMSalesorderdetail[2]);
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-01
        CreateCRMSalesorderInLCY(CRMSalesorder[3]);
        CRMSalesorder[3].LastBackofficeSubmit := DMY2Date(1, 1, 1900);
        CRMSalesorder[3].Modify();
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[3], CRMSalesorderdetail[3]);
        // [GIVEN] Submitted CRM sales order with LastBackofficeSubmit=1900-01-02
        CreateCRMSalesorderInLCY(CRMSalesorder[4]);
        CRMSalesorder[4].LastBackofficeSubmit := DMY2Date(2, 1, 1900);
        CRMSalesorder[4].Modify();
        // [GIVEN] Active CRM sales order
        CreateCRMSalesorderInLCY(CRMSalesorder[5]);
        CRMSalesorder[5].StateCode := CRMSalesorder[5].StateCode::Active;
        CRMSalesorder[5].Modify();
        // [WHEN] Job queue entry "Process submitted sales orders" is being run
        RunCodeunitProcessSubmittedCRMSalesOrders();

        // [THEN] Nav sales order created for submitted CRM sales order with LastBackofficeSubmit=0D
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[1].SalesOrderId), 'Coupled sales header is not found for CRM Sales Order 1');
        CRMIntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
        // [THEN] Nav sales order is not created for submitted CRM sales order with LastBackofficeSubmit=1899-12-31
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[2].SalesOrderId), 'Coupled sales header is found for CRM Sales Order 2');
        // [THEN] Nav sales order created for submitted CRM sales order with LastBackofficeSubmit=1900-01-01
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[3].SalesOrderId), 'Coupled sales header is not found for CRM Sales Order 3');
        CRMIntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
        // [THEN] Nav sales order is not created for submitted CRM sales order with LastBackofficeSubmit=1900-01-02
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[4].SalesOrderId), 'Coupled sales header is found for CRM Sales Order 4');
        // [THEN] Nav sales order is not created for active CRM sales order
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[5].SalesOrderId), 'Coupled sales header is found for CRM Sales Order 5');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesOrderInNAVWithJobQueueSunshine()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        // [SCENARIO 211593] Job queue entry "Process submitted sales orders" makes NAV sales order from Submitted CRM sales order
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] Job queue entry "Process submitted sales orders" is being run
        RunCodeunitProcessSubmittedCRMSalesOrders();

        // [THEN] Nav sales order created
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMSalesorder.SalesOrderId), 'Coupled sales header not found');
        CRMIntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesOrderInNAVWithJobQueueAfterFail()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorder: array[2] of Record "CRM Salesorder";
        CRMSalesorderdetail: array[2] of Record "CRM Salesorderdetail";
    begin
        // [SCENARIO 211593] Job queue entry "Process submitted sales orders" should not stop processing orders after first fail
        Initialize(false);
        ClearCRMData();

        // [GIVEN] CRM Salesorder 1 for customer 1 in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder[1]);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[1], CRMSalesorderdetail[1]);

        // [GIVEN] Remove coupling for customer 1 to cause error while creating NAV sales order
        CRMIntegrationRecord.FindByCRMID(CRMSalesorder[1].CustomerId);
        CRMIntegrationRecord.Delete();

        // [GIVEN] CRM Salesorder 2 for customer 2 in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder[2]);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[2], CRMSalesorderdetail[2]);

        // [WHEN] Job queue entry "Process submitted sales orders" is being run
        RunCodeunitProcessSubmittedCRMSalesOrders();

        // [THEN] Nav sales order 1 is not created
        Assert.IsFalse(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[1].SalesOrderId), 'Sales order 1 should not be created');

        // [THEN] Nav sales order 2 created
        Assert.IsTrue(CRMIntegrationRecord.FindByCRMID(CRMSalesorder[2].SalesOrderId), 'Sales order 2 not found');
        CRMIntegrationRecord.TestField("Table ID", DATABASE::"Sales Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRMOrderNameToSalesHeaderExternalDocumentNo()
    var
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        // [FEATURE] [External Document No.]
        // [SCENARIO 230310] CRM Sales Order Name field value is copied to Sales Header External Document No field
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [GIVEN] CRM Salesorder Name = "ABC"
        CRMSalesorder.Name :=
          UpperCase(LibraryUtility.GenerateRandomText(MaxStrLen(CRMSalesorder.Name)));
        CRMSalesorder.Modify();

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created sales header has External Document No. = "ABC"
        SalesHeader.TestField(
          "External Document No.",
          CopyStr(CRMSalesorder.Name, 1, MaxStrLen(SalesHeader."External Document No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostToAccountWhenAccountDeleted()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMPost: Record "CRM Post";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO 270978] Posting Sales Document for coupled Customer when coupled CRM Account is deleted
        Initialize(false);
        LibraryCRMIntegration.ConfigureCRM();
        CleanCRMPost(CRMPost);

        // [GIVEN] We have a coupled CRM Account and NAV Customer
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        ItemNo := '';

        // [GIVEN] CRM Account deleted
        CRMAccount.Delete();

        // [GIVEN] We have a Sales Order created to that Customer
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine,
          SalesHeader."Document Type"::Order, Customer."No.", ItemNo, 1, '', WorkDate());

        // [WHEN] The Sales Order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] No Post is created on the Account
        Assert.RecordCount(CRMPost, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesOrderCoupledToDeletedCRMSalesOrder()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        // [SCENARIO 279148] Sales Order coupled to deleted CRM Sales Order can be deleted
        Initialize(false);
        CRMConnectionSetup.Get();
        CRMConnectionSetup."Is S.Order Integration Enabled" := true;
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();

        // [GIVEN] Created NAV Order from CRM Order
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [GIVEN] CRM Sales Order is deleted
        CRMSalesorder.Delete();

        // [WHEN] Delete Sales Order
        // Deletion of Sales Document succesfull
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderCoupledToDeletedCRMSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        // [SCENARIO 279148] Sales Order coupled to deleted CRM Sales Order can be posted
        Initialize(false);

        // [GIVEN] Created NAV Order from CRM Order
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [GIVEN] CRM Sales Order is deleted
        CRMSalesorder.Delete();

        // [WHEN] Post Sales Order
        // Posting of Sales Document is succesfull
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WriteInItemNameCopiedToSalesOrderLineDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        Item: Record Item;
    begin
        // [SCENARIO 313501] Write-in CRM Product (item) value should be copied to Sales Order line copied from CRM
        Initialize(false);

        // [GIVEN] Setup write-in product as Item 'ITEM'
        LibraryCRMIntegration.PrepareWriteInProductItem(Item);

        // [GIVEN] CRM Sales Order created with line with empty Product Id (sign of write-in product)
        CreateCRMSalesorderInLCY(CRMSalesorder);
        CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order contains 1 line, Description = "X"
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.TestField(Description, CRMSalesorderdetail.ProductDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonWriteInItemNameNotCopiedToSalesOrderLineDescription();
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 321940] Sales Line item description is not overwritten by CRM product description for non-writein product
        Initialize(false);

        // [GIVEN] CRM Salesorder in local currency with item. Item Description in NAV = "X", Product Description in CRM = "Y"
        CreateCRMSalesorderInLCY(CRMSalesorder);
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);

        // [WHEN] NAV Order is being created from CRM Order
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);

        // [THEN] Created NAV Sales Order with Sales Line description = "X"
        SalesLine.setrange("Document No.", SalesHeader."No.");
        SalesLine.setrange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        Item.Get(SalesLine."No.");
        SalesLine.TestField(Description, Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithItemPriceIncludesVAT()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMProduct: Record "CRM Product";
        CRMSalesOrder: Record "CRM Salesorder";
        CRMSalesOrderDetail: Record "CRM Salesorderdetail";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
    begin
        // [SCENARIO 371774] Transfer CRM Sales Order to Sales Order with Prices Includes VAT = TRUE
        Initialize(false);
        ClearCRMData();

        // [GIVEN] Customer "C" with "VAT Bus. Posting Group" = "VATBBus" coupled with Account "CA"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("VAT Bus. Posting Gr. (Price)", Customer."VAT Bus. Posting Group");
        SalesReceivablesSetup.Modify();

        // [GIVEN] Coupled Item "I" (Product "P") with Unit Price = X, "Prices Includes VAT" = true, 
        // "VAT Bus. Posting Gr. (Price)" = Customer."VAT Bus. Posting Group"
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        Item.Validate("VAT Bus. Posting Gr. (Price)", Customer."VAT Bus. Posting Group");
        Item.Validate("Price Includes VAT", true);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        GLSetup.GET();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(GLSetup."LCY Code", 1, 5));

        // [GIVEN] CRM Sales Order for Account "CA", Product "P", Quantity = 1, "Price per Unit" = Item Unit Price
        CreateCRMSalesorder(CRMSalesOrder, CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
        CRMSalesorderdetail.Init();
        LibraryCRMIntegration.PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);
        CRMSalesOrderDetail.Validate(Quantity, 1);
        CRMSalesOrderDetail.Validate(PricePerUnit, Item."Unit Price");
        CRMSalesOrderDetail.Modify();

        // [WHEN] Create Sales Order from CRM Sales Order
        CreateSalesOrderInNAV(CRMSalesOrder, SalesHeader);

        // [THEN] Sales line Amount = Unit Price - VAT
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        Assert.AreNearlyEqual(SalesLine.Amount, Round(Item."Unit Price" / (1 + SalesLine."VAT %" / 100), LibraryERM.GetAmountRoundingPrecision()), 0.01, '');
        // [THEN] Sales Line Amount Including VAT = Unit Price 
        Assert.AreNearlyEqual(SalesLine."Amount Including VAT", Round(SalesLine.Amount + (SalesLine.Amount * SalesLine."VAT %" / 100), LibraryERM.GetAmountRoundingPrecision()), 0.01, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithItemPriceIncludesVATFalse()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMProduct: Record "CRM Product";
        CRMSalesOrder: Record "CRM Salesorder";
        CRMSalesOrderDetail: Record "CRM Salesorderdetail";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
    begin
        // [SCENARIO 371774] Transfer CRM Sales Order to Sales Order with Prices Includes VAT = FALSE
        Initialize(false);
        ClearCRMData();
        // [GIVEN] Customer "C" with "VAT Bus. Posting Group" = "VATBBus" coupled with Account "CA"
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        // [GIVEN] Coupled Item "I" (Product "P") with Unit Price = X, "Prices Includes VAT" = false, 
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        Item.Validate("Price Includes VAT", false);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        GLSetup.GET();
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(GLSetup."LCY Code", 1, 5));

        // [GIVEN] CRM Sales Order for Account "CA", Product "P", Quantity = 1, "Price per Unit" = Item Unit Price
        CreateCRMSalesorder(CRMSalesOrder, CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
        CRMSalesorderdetail.Init();
        LibraryCRMIntegration.PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);
        CRMSalesOrderDetail.Validate(Quantity, 1);
        CRMSalesOrderDetail.Validate(PricePerUnit, Item."Unit Price");
        CRMSalesOrderDetail.Modify();

        // [WHEN] Create Sales Order from CRM Sales Order
        CreateSalesOrderInNAV(CRMSalesOrder, SalesHeader);

        // [THEN] Sales line Amount = Unit Price
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Amount, Item."Unit Price");

        // [THEN] Sales Line Amount Including VAT = Unit Price + VAT
        SalesLine.TestField("Amount Including VAT", ROUND(Item."Unit Price" * (1 + SalesLine."VAT %" / 100), LibraryERM.GetAmountRoundingPrecision()));
    end;


    [Test]
    [Scope('OnPrem')]
    procedure BidirectionalSalesOrderCreatesArchive()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        // [SCENARIO] Bidirectional sales order creates an extra sales order archive
        Initialize(true);
        ClearCRMData();
        SalesHeaderArchive.DeleteAll();
        SalesLineArchive.DeleteAll();

        // [WHEN] A sales order is created and posted
        CreateAndPostSalesOrder();

        // [THEN] Two archive versions created 
        Assert.AreEqual(2, SalesHeaderArchive.Count, 'Two archive versions should be created.');

        // [THEN] Latest archive line Qty. Shipped > 0
        SalesLineArchive.FindLast();
        Assert.AreNotEqual(SalesLineArchive."Quantity Shipped", 0, 'Quantity shipped should not be equal to zero.');
    end;

    [Test]
    [HandlerFunctions('SyncEntityStrMenuHandler')]
    procedure BidirectionalSalesOrderFulfillOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMSalesorder: Record "CRM Salesorder";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntryId: Guid;
    begin
        // [SCENARIO] Bidirectional sales order fulfills fully shipped orders
        Initialize(true);
        ClearCRMData();

        // [GIVEN] A coupled sales order
        LibraryCRMIntegration.CreateCoupledSalesHeaderAndSalesorder(SalesHeader, CRMSalesorder);

        // [WHEN] Sales order is shipped and synced
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindFirst() then begin
            SalesLine."Completely Shipped" := true;
            SalesLine.Modify();
        end;
        CRMIntegrationManagement.UpdateOneNow(SalesHeader.RecordId);
        GetIntegrationTableMapping(IntegrationTableMapping, SalesHeader.RecordId);
        SalesHeader.SetRange(SystemId, SalesHeader.SystemId);
        JobQueueEntryId := LibraryCRMIntegration.RunJobQueueEntry(Database::"Sales Header", SalesHeader.GetView(), IntegrationTableMapping);

        // [THEN] CRM sales order is fulfilled
        CRMIntegrationRecord.FindByRecordID(SalesHeader.RecordId);
        CRMSalesorder.Get(CRMIntegrationRecord."CRM ID");
        Assert.AreEqual(CRMSalesorder.StateCode, CRMSalesorder.StateCode::Fulfilled, 'CRM sales order should be fulfilled.');
    end;

    [Test]
    procedure BidirectionalSalesOrderReservationEntry()
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        CRMSalesorder: Record "CRM Salesorder";
        SalesLine: Record "Sales Line";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemJournalLine: Record "Item Journal Line";
        LibraryInventory: Codeunit "Library - Inventory";

    begin
        // [SCENARIO] Bidirectional sales order creates reservation entry
        Initialize(true);
        ClearCRMData();

        // [GIVEN] A coupled customer and item with auto reservation
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        Customer.Reserve := Customer.Reserve::Always;
        Customer.Modify();
        LibraryCRMIntegration.CreateCoupledItemAndProduct(Item, CRMProduct);
        Item.Reserve := Item.Reserve::Always;
        Item.Modify();
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandIntInRange(10, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        // A CRM sales order
        LibraryCRMIntegration.CreateCRMSalesOrder(CRMSalesorder);
        CRMSalesorder.OrderNumber := LibraryUtility.GenerateGUID();
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
        CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::InProgress;
        CRMSalesorder.CustomerId := CRMAccount.AccountId;
        CRMSalesorder.CustomerIdType := CRMSalesorder.CustomerIdType::account;
        CRMSalesorder.Modify();
        LibraryCRMIntegration.PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMProduct.ProductId);

        // [WHEN] CRM sales order is synced
        LibraryCRMIntegration.DisableTaskOnBeforeJobQueueScheduleTask();
        CRMSalesorder.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
        CRMIntegrationManagement.CreateNewRecordsFromCRM(CRMSalesorder);
        LibraryCRMIntegration.RunJobQueueEntry(Database::"CRM Salesorder", CRMSalesorder.GetView(), IntegrationTableMapping);

        // [THEN] Reservation entry is created
        CRMIntegrationRecord.SetRange("CRM ID", CRMSalesorderdetail.SalesOrderDetailId);
        CRMIntegrationRecord.FindFirst();
        SalesLine.GetBySystemId(CRMIntegrationRecord."Integration ID");
        SalesLine.CalcFields("Reserved Quantity");
        Assert.AreNotEqual(SalesLine."Reserved Quantity", 0, 'Reserved quantity should not be equal to zero.');
    end;

    local procedure Initialize(BidirectionalSOIntegrationEnabled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        MyNotifications: Record "My Notifications";
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CRM Sales Order Integr. Test");

        // Lazy Setup.
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then begin
            CRMConnectionSetup.Get();
            if CRMConnectionSetup."Bidirectional Sales Order Int." = BidirectionalSOIntegrationEnabled then
                exit;
        end else
            LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"CRM Sales Order Integr. Test");
        LibraryPatterns.SETNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        ResetDefaultCRMSetupConfiguration(BidirectionalSOIntegrationEnabled);
        isInitialized := true;
        MyNotifications.InsertDefault(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID(), '', '', false);
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"CRM Sales Order Integr. Test");
    end;

    local procedure ClearCRMData()
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMAccount: Record "CRM Account";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        CRMAccount.DeleteAll();
        CRMTransactioncurrency.DeleteAll();
        CRMSalesorder.DeleteAll();
    end;

    local procedure CreateCRMSalesorderWithCurrency(var CRMSalesorder: Record "CRM Salesorder"; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
    begin
        LibraryCRMIntegration.CreateCRMTransactionCurrency(CRMTransactioncurrency, CopyStr(CurrencyCode, 1, 5));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);
        CreateCRMSalesorder(CRMSalesorder, CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
    end;

    local procedure CreateCRMSalesorder(var CRMSalesorder: Record "CRM Salesorder"; CurrencyId: Guid; AccountId: Guid)
    begin
        LibraryCRMIntegration.CreateCRMSalesOrderWithCustomerFCY(CRMSalesorder, AccountId, CurrencyId);
    end;

    local procedure CreateCRMSalesorderInLCY(var CRMSalesorder: Record "CRM Salesorder")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup.GetCurrencyCode(''));
    end;

    local procedure CreateCRMSalesorderdetailWithEmptyProductId(CRMSalesorder: Record "CRM Salesorder"; var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    begin
        CRMSalesorderdetail.Init();
        LibraryCRMIntegration.PrepareCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail, CRMSalesorderdetail.ProductId);
    end;

    local procedure MockLongCRMSalesorderdetailProductDescription(var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    begin
        CRMSalesorderdetail.ProductDescription :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(CRMSalesorderdetail.ProductDescription)),
            1,
            MaxStrLen(CRMSalesorderdetail.ProductDescription));
        CRMSalesorderdetail.Modify();
    end;

    local procedure MockLongCRMSalesorderdetailDescription(var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    var
        RecRef: RecordRef;
        OutStream: OutStream;
    begin
        RecRef.GetTable(CRMSalesorderdetail);

        CRMSalesorderdetail.Description.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(LibraryUtility.GenerateRandomText(LibraryRandom.RandIntInRange(150, 3000)));

        RecRef.Modify();
        RecRef.SetTable(CRMSalesorderdetail);
    end;

    local procedure MockCRMSalesOrderNote(var CRMAnnotation: Record "CRM Annotation"; CRMSalesorder: Record "CRM Salesorder"; AnnotationText: Text)
    var
        OutStream: OutStream;
    begin
        CRMAnnotation.AnnotationId := CreateGuid();
        CRMAnnotation.IsDocument := false;
        CRMAnnotation.FileSize := 0;
        CRMAnnotation.ObjectId := CRMSalesorder.SalesOrderId;
        CRMAnnotation.ObjectTypeCode := CRMAnnotation.ObjectTypeCode::salesorder;
        CRMAnnotation.CreatedOn := CurrentDateTime;
        CRMAnnotation.ModifiedOn := CRMAnnotation.CreatedOn;
        CRMAnnotation.Insert();

        CRMAnnotation.NoteText.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.Write(AnnotationText);

        CRMAnnotation.Modify();
    end;

    local procedure PrepareCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder"; ManualDiscAmount: Decimal; VolumeDiscAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup."LCY Code");
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CRMSalesorderdetail.VolumeDiscountAmount := VolumeDiscAmount;
        CRMSalesorderdetail.ManualDiscountAmount := ManualDiscAmount;
        CRMSalesorderdetail.Modify();
    end;

    local procedure PostCRMSalesOrderWithFreightAndDiscounts(var CRMSalesorder: Record "CRM Salesorder"; var CRMSalesorderdetail: Record "CRM Salesorderdetail"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
    begin
        GeneralLedgerSetup.Get();
        CreateCRMSalesorderWithCurrency(CRMSalesorder, GeneralLedgerSetup.GetCurrencyCode(''));
        LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder, CRMSalesorderdetail);
        CRMSalesorder.DiscountAmount := Round(CRMSalesorderdetail.BaseAmount / LibraryRandom.RandIntInRange(5, 10));
        CRMSalesorder.DiscountPercentage := LibraryRandom.RandIntInRange(5, 10);
        CRMSalesorder.FreightAmount := LibraryRandom.RandDecInRange(10, 100, 2);
        CRMSalesorder.Modify(); // handled by subscriber COD139184.ValidateSalesOrderOnModify

        LibraryCRMIntegration.SetFreightGLAccNo();
        CreateSalesOrderInNAV(CRMSalesorder, SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure RunCodeunitProcessSubmittedCRMSalesOrders()
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
    begin
        CODEUNIT.Run(CODEUNIT::"Auto Create Sales Orders", TempJobQueueEntry);
    end;

    local procedure CleanCRMPost(var CRMPost: Record "CRM Post")
    begin
        CRMPost.DeleteAll();
        Clear(CRMPost);
    end;

    local procedure CleanCRMPostBuffer(var CRMPostBuffer: Record "CRM Post Buffer")
    begin
        CRMPostBuffer.DeleteAll();
        Clear(CRMPostBuffer);
    end;

    local procedure CreateSalesOrderInNAV(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
    begin
        CRMSalesOrderToSalesOrder.CreateInNAV(CRMSalesorder, SalesHeader);
    end;

    local procedure CreateSalesInvoiceWithGetShipmentLine(var SalesHeaderInvoice: Record "Sales Header"; SalesHeaderOrder: Record "Sales Header"; ShipmentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesShipmentLine.SetRange("Document No.", ShipmentNo);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure CreateSalesInvoiceWithGetShipmentLineFromSeveralOrders(var SalesHeaderInvoice: Record "Sales Header"; CustomerNo: Code[20]; ShipmentNo: array[3] of Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, CustomerNo);

        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        for i := 1 to 3 do begin
            SalesShipmentLine.SetRange("Document No.", ShipmentNo[i]);
            SalesGetShipment.CreateInvLines(SalesShipmentLine);
        end;
    end;

    local procedure CreateSeveralCRMSalesordersForSameCustomer(var Customer: Record Customer; var CRMSalesorder: array[3] of Record "CRM Salesorder"; var ShipmentNo: array[3] of Code[20])
    var
        SalesHeader: array[3] of Record "Sales Header";
        GLSetup: Record "General Ledger Setup";
        CRMAccount: Record "CRM Account";
        CRMSalesorderdetail: array[3] of Record "CRM Salesorderdetail";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        i: Integer;
    begin
        GLSetup.Get();

        LibraryCRMIntegration.CreateCRMTransactionCurrency(
          CRMTransactioncurrency,
          CopyStr(GLSetup.GetCurrencyCode(''), 1, 5));
        LibraryCRMIntegration.CreateCoupledCustomerAndAccount(Customer, CRMAccount);

        for i := 1 to 3 do begin
            CreateCRMSalesorder(CRMSalesorder[i], CRMTransactioncurrency.TransactionCurrencyId, CRMAccount.AccountId);
            LibraryCRMIntegration.CreateCRMSalesOrderLine(CRMSalesorder[i], CRMSalesorderdetail[i]);
            CreateSalesOrderInNAV(CRMSalesorder[i], SalesHeader[i]);
            ShipmentNo[i] := LibrarySales.PostSalesDocument(SalesHeader[i], true, false);
        end;
    end;

    local procedure DeleteCurrencyInNAV(CurrencyISOCode: Text)
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyISOCode);
        Currency.Delete(true);
    end;

    local procedure GetFCYCurrencyCode(): Code[10]
    var
        Currency: Record Currency;
        "Code": Code[10];
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandIntInRange(10, 20), 1));
        Code := LibraryUtility.GenerateGUID();
        Currency.Rename('.' + CopyStr(Code, StrLen(Code) - 3));
        exit(Currency.Code);
    end;

    local procedure VerifySalesLineFromCRM(CRMSalesOrderId: Guid; SalesHeaderNo: Code[20])
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
    begin
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesOrderId);
        CRMSalesorderdetail.FindFirst();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst();

        SalesLine.TestField(
          "Line Discount Amount",
          CRMSalesorderdetail.VolumeDiscountAmount * CRMSalesorderdetail.Quantity + CRMSalesorderdetail.ManualDiscountAmount);
        SalesLine.TestField(Amount, CRMSalesorderdetail.ExtendedAmount);
    end;

    local procedure VerifyCRMSalesorderStateAndStatus(var CRMSalesorder: Record "CRM Salesorder"; ExpectedState: Integer; ExpectedStatus: Integer)
    begin
        CRMSalesorder.Find();
        CRMSalesorder.TestField(StateCode, ExpectedState);
        CRMSalesorder.TestField(StatusCode, ExpectedStatus);
    end;

    local procedure VerifySalesLinesDescription(SalesHeader: Record "Sales Header"; ProductDescription: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        repeat
            SalesLine.Next();
            VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        until StrLen(ProductDescription) = 0;
    end;

    local procedure VerifySalesLinesWriteInDescription(SalesHeader: Record "Sales Header"; ProductDescription: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindSet();
        VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        repeat
            SalesLine.Next();
            VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine, ProductDescription);
        until StrLen(ProductDescription) = 0;
    end;

    local procedure VerifySalesLineDescriptionAndTrancateProdDescription(SalesLine: Record "Sales Line"; var ProductDescription: Text)
    begin
        Assert.AreEqual(
          CopyStr(ProductDescription, 1, MaxStrLen(SalesLine.Description)),
          SalesLine.Description,
          'Invalid description');
        ProductDescription := CopyStr(ProductDescription, MaxStrLen(SalesLine.Description) + 1);
    end;

    local procedure VerifySalesOrderNote(SalesHeader: Record "Sales Header"; AnnotationText: Text)
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
        ActualText: Text;
    begin
        RecordLink.SetAutoCalcFields(Note);
        RecordLink.SetRange("Record ID", SalesHeader.RecordId);
        RecordLink.FindSet();
        repeat
            ActualText := RecordLinkManagement.ReadNote(RecordLink);
            if ActualText = AnnotationText then
                exit;
        until RecordLink.Next() = 0;
        Error(SalesOrdernoteNotFoundErr, SalesHeader."No.", AnnotationText);
    end;

    local procedure VerifyCRMSalesOrderNote(SalesHeader: Record "Sales Header"; AnnotationText: Text)
    var
        CRMAnnotation: Record "CRM Annotation";
        CRMIntegrationRecord: Record "CRM Integration Record";
        InStream: InStream;
        ActualText: Text;
        CRMSalesorderID: Guid;
    begin
        CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesorderID);
        CRMAnnotation.SetRange(ObjectId, CRMSalesorderID);
        CRMAnnotation.FindSet();
        repeat
            CRMAnnotation.CalcFields(NoteText);
            CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
            InStream.Read(ActualText);
            if ActualText = AnnotationText then
                exit;
        until CRMAnnotation.Next() = 0;
        Error(CRMSalesOrdernoteNotFoundErr, CRMSalesorderID, AnnotationText);
    end;

    [Scope('OnPrem')]
    procedure CreateNote(SalesHeader: Record "Sales Header"; AnnotationText: Text; var RecordLink: Record "Record Link")
    var
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink."Record ID" := SalesHeader.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLinkManagement.WriteNote(RecordLink, AnnotationText);
        RecordLink.Created := CurrentDateTime;
        RecordLink.Company := CompanyName;
        RecordLink.Insert(true);
    end;

    local procedure SetSalesOrderIntegrationInOrg(EnabledSalesOrderIntegration: Boolean)
    var
        CRMOrganization: Record "CRM Organization";
    begin
        CRMOrganization.FindFirst();
        CRMOrganization.IsSOPIntegrationEnabled := EnabledSalesOrderIntegration;
        CRMOrganization.Modify();
    end;

    local procedure ResetDefaultCRMSetupConfiguration(BidirectionalSOIntegrationEnabled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ClientSecret: Text;
    begin
        CRMConnectionSetup.Get();
        CDSConnectionSetup.LoadConnectionStringElementsFromCRMConnectionSetup();
        CDSConnectionSetup."Ownership Model" := CDSConnectionSetup."Ownership Model"::Person;
        CDSConnectionSetup.Validate("Client Id", 'ClientId');
        ClientSecret := 'ClientSecret';
        CDSConnectionSetup.SetClientSecret(ClientSecret);
        CDSConnectionSetup.Validate("Redirect URL", 'RedirectURL');
        CDSConnectionSetup.Modify();
        CRMConnectionSetup."Is CRM Solution Installed" := true;
        CRMConnectionSetup."Is S.Order Integration Enabled" := not BidirectionalSOIntegrationEnabled;
        CRMConnectionSetup.Validate("Bidirectional Sales Order Int.", BidirectionalSOIntegrationEnabled);
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Unit Group Mapping Enabled" := false;
        CRMConnectionSetup.Modify();
        CDSSetupDefaults.ResetConfiguration(CDSConnectionSetup);
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
    end;

    local procedure CreateAndPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; RecordId: RecordId)
    begin
        CRMIntegrationManagement.GetIntegrationTableMapping(IntegrationTableMapping, RecordId);
        IntegrationTableMapping.Reset();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SyncStartedNotificationHandler(var SyncCompleteNotification: Notification): Boolean
    begin
        Assert.AreEqual(SyncStartedMsg, SyncCompleteNotification.Message, 'Unexpected notification.');
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SyncEntityStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1;
    end;
}

