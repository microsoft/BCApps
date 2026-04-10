codeunit 134209 "Workflow Overview Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler,WorkflowOverviewModalHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWorkflowsFactboxDrilldown()
    var
        Customer: Record Customer;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Workflow Overview]
        // [SCENARIO] Annie wants to see what workflows her customer is part of
        // [WHEN] Annie opens the Customer card for a customer that is part of an approval workflow
        // [THEN] Annie can see the Workflow Status factbox
        // [WHEN] Annie drils down on the workflow description
        // [THEN] The Workflow Overview page opens with details on the current workflow.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.CustomerWorkflowCode());
        LibrarySales.CreateCustomer(Customer);

        // Exercise - Send for approval
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Verify
        LibraryVariableStorage.Enqueue(Format(Customer.RecordId, 0, 1));
        CustomerCard.WorkflowStatus.First();
        CustomerCard.WorkflowStatus.WorkflowDescription.AssertEquals(Workflow.Description);
        CustomerCard.WorkflowStatus.WorkflowDescription.DrillDown();
        Assert.IsFalse(CustomerCard.WorkflowStatus.Next(), CustomerCard.WorkflowStatus.WorkflowDescription.Value);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCustomerWithMultipleWorkflowsFactbox()
    var
        Customer: Record Customer;
        Workflow1: Record Workflow;
        Workflow2: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Workflow Overview]
        // [SCENARIO] Annie wants to see what workflows her customer is part of
        // [WHEN] Annie opens the Customer card for a customer that is part of an approval workflow and a credit limit change workflow.
        // [THEN] Annie can see the Workflow Status factbox
        // [WHEN] Annie drils down on the workflow description
        // [THEN] The Workflow Overview page opens with details on the current workflow.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow1, WorkflowSetup.CustomerWorkflowCode());
        CreateEnabledWorkflow(Workflow2, WorkflowSetup.CustomerCreditLimitChangeApprovalWorkflowCode());
        LibrarySales.CreateCustomer(Customer);

        // Exercise - Send for approval
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.SendApprovalRequest.Invoke();

        // Exercise - Change credit limit
        CustomerCard."Credit Limit (LCY)".SetValue(LibraryRandom.RandInt(1000));
        CustomerCard.OK().Invoke();

        // Verify
        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);
        CustomerCard.WorkflowStatus.FILTER.SetFilter(CustomerCard.WorkflowStatus.FILTER."Workflow Code", Workflow1.Code);
        Assert.IsTrue(CustomerCard.WorkflowStatus.First(), Workflow1.Description + ' is missing from the factbox.');

        CustomerCard.WorkflowStatus.FILTER.SetFilter(CustomerCard.WorkflowStatus.FILTER."Workflow Code", Workflow2.Code);
        Assert.IsTrue(CustomerCard.WorkflowStatus.First(), Workflow2.Description + ' is missing from the factbox.');
    end;

    [Scope('OnPrem')]
    procedure TestSalesDocWorkflowsFactbox(WorkflowCode: Code[17]; DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Workflow Overview]
        // [SCENARIO] Annie wants to see what workflows her sales document is part of
        // [WHEN] Annie opens the sales document card for a document that is part of an approval workflow
        // [THEN] Annie can see the Workflow Status factbox
        // [WHEN] Annie drils down on the workflow description
        // [THEN] The Workflow Overview page opens with details on the current workflow.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateEnabledWorkflow(Workflow, WorkflowCode);
        CreateSalesDoc(SalesHeader, DocType);

        // Exercise - Send for approval
        LibraryVariableStorage.Enqueue(Workflow.Description);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        ApprovalEntry.SetRange("Record ID to Approve", SalesHeader.RecordId);
        ApprovalEntry.FindFirst();
        ApprovalEntry.ShowRecord();

        // Verify: in handler.
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesInvoiceApprovalWorkflowCode(), SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesOrderWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesOrderApprovalWorkflowCode(), SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('SalesQuotePageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesQuoteWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesQuoteApprovalWorkflowCode(), SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('SalesReturnOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesReturnOrderApprovalWorkflowCode(), SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesBlanketOrderApprovalWorkflowCode(), SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoWorkflowsFactbox()
    var
        SalesHeader: Record "Sales Header";
    begin
        TestSalesDocWorkflowsFactbox(WorkflowSetup.SalesCreditMemoApprovalWorkflowCode(), SalesHeader."Document Type"::"Credit Memo");
    end;

    [Scope('OnPrem')]
    procedure TestPurchDocWorkflowsFactbox(WorkflowCode: Code[17]; DocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Workflow Overview]
        // [SCENARIO] Annie wants to see what workflows her purchase document is part of
        // [WHEN] Annie opens the purchase document card for a document that is part of an approval workflow
        // [THEN] Annie can see the Workflow Status factbox
        // [WHEN] Annie drils down on the workflow description
        // [THEN] The Workflow Overview page opens with details on the current workflow.

        // Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        CreateEnabledWorkflow(Workflow, WorkflowCode);
        CreatePurchaseDoc(PurchaseHeader, DocType);

        // Exercise - Send for approval
        LibraryVariableStorage.Enqueue(Workflow.Description);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        ApprovalEntry.SetRange("Record ID to Approve", PurchaseHeader.RecordId);
        ApprovalEntry.FindFirst();
        ApprovalEntry.ShowRecord();

        // Verify: in handler.
    end;

    [Test]
    [HandlerFunctions('PurchInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchInvoiceWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode(), PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('PurchOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchOrderWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(WorkflowSetup.PurchaseOrderApprovalWorkflowCode(), PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('PurchQuotePageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchQuoteWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(WorkflowSetup.PurchaseQuoteApprovalWorkflowCode(), PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('PurchReturnOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchReturnOrderWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(
          WorkflowSetup.PurchaseReturnOrderApprovalWorkflowCode(), PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('PurchBlanketOrderPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchBlanketOrderWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(
          WorkflowSetup.PurchaseBlanketOrderApprovalWorkflowCode(), PurchaseHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('PurchCreditMemoPageHandler')]
    [Scope('OnPrem')]
    procedure TestPurchCreditMemoWorkflowsFactbox()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        TestPurchDocWorkflowsFactbox(WorkflowSetup.PurchaseCreditMemoApprovalWorkflowCode(), PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WorkflowOverviewModalHandler')]
    [Scope('OnPrem')]
    procedure TestVendorWorkflowsFactboxDrilldown()
    var
        Vendor: Record Vendor;
        Workflow: Record Workflow;
        ApprovalUserSetup: Record "User Setup";
        VendorCard: TestPage "Vendor Card";
    begin
        // [444327]  Missing FactBox for active Workflows on Vendor Card.
        // [WHEN] Annie opens the vendor card for a vendor that is part of an approval workflow
        // [THEN] Annie can see the Workflow Status factbox
        // [WHEN] Annie drills down on the workflow description
        // [THEN] The Workflow Overview page opens with details on the current workflow.

        // [GIVEN] Create the Workflow Setup
        Initialize();
        LibraryDocumentApprovals.SetupUsersForApprovals(ApprovalUserSetup);
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.VendorWorkflowCode());
        LibraryPurchase.CreateVendor(Vendor);

        //[THEN] Exercise - Send for approval
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);
        VendorCard.SendApprovalRequest.Invoke();

        // [VERIFY]
        LibraryVariableStorage.Enqueue(Format(Vendor.RecordId, 0, 1));
        VendorCard.WorkflowStatus.First();
        VendorCard.WorkflowStatus.WorkflowDescription.AssertEquals(Workflow.Description);
        VendorCard.WorkflowStatus.WorkflowDescription.DrillDown();
        Assert.IsFalse(VendorCard.WorkflowStatus.Next(), VendorCard.WorkflowStatus.WorkflowDescription.Value);
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Workflow Overview Tests");
        LibraryWorkflow.DisableAllWorkflows();
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Workflow Overview Tests");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Workflow Overview Tests");
    end;

    local procedure CreateEnabledWorkflow(var Workflow: Record Workflow; WorkflowTemplateCode: Code[17])
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStep: Record "Workflow Step";
    begin
        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowTemplateCode);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();
        LibraryWorkflow.InsertApprovalArgument(WorkflowStep.ID, WorkflowStepArgument."Approver Type"::Approver,
          WorkflowStepArgument."Approver Limit Type"::"Direct Approver", '', false);
        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkflowOverviewModalHandler(var WorkflowOverview: TestPage "Workflow Overview")
    var
        RecID: Variant;
    begin
        LibraryVariableStorage.Dequeue(RecID);
        WorkflowOverview.FILTER.SetFilter("Record ID", RecID);
        Assert.IsTrue(WorkflowOverview.First(), 'Unexpected step.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        SalesInvoice.WorkflowStatus.First();
        SalesInvoice.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(SalesInvoice.WorkflowStatus.Next(), SalesInvoice.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        SalesOrder.WorkflowStatus.First();
        SalesOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(SalesOrder.WorkflowStatus.Next(), SalesOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotePageHandler(var SalesQuote: TestPage "Sales Quote")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        SalesQuote.WorkflowStatus.First();
        SalesQuote.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(SalesQuote.WorkflowStatus.Next(), SalesQuote.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnOrderPageHandler(var SalesReturnOrder: TestPage "Sales Return Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        SalesReturnOrder.WorkflowStatus.First();
        SalesReturnOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(SalesReturnOrder.WorkflowStatus.Next(), SalesReturnOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderPageHandler(var BlanketSalesOrder: TestPage "Blanket Sales Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        BlanketSalesOrder.WorkflowStatus.First();
        BlanketSalesOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(BlanketSalesOrder.WorkflowStatus.Next(), BlanketSalesOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPageHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        SalesCreditMemo.WorkflowStatus.First();
        SalesCreditMemo.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(SalesCreditMemo.WorkflowStatus.Next(), SalesCreditMemo.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchInvoicePageHandler(var PurchaseInvoice: TestPage "Purchase Invoice")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        PurchaseInvoice.WorkflowStatus.First();
        PurchaseInvoice.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(PurchaseInvoice.WorkflowStatus.Next(), PurchaseInvoice.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderPageHandler(var PurchaseOrder: TestPage "Purchase Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        PurchaseOrder.WorkflowStatus.First();
        PurchaseOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(PurchaseOrder.WorkflowStatus.Next(), PurchaseOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchQuotePageHandler(var PurchaseQuote: TestPage "Purchase Quote")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        PurchaseQuote.WorkflowStatus.First();
        PurchaseQuote.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(PurchaseQuote.WorkflowStatus.Next(), PurchaseQuote.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchReturnOrderPageHandler(var PurchaseReturnOrder: TestPage "Purchase Return Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        PurchaseReturnOrder.WorkflowStatus.First();
        PurchaseReturnOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(PurchaseReturnOrder.WorkflowStatus.Next(), PurchaseReturnOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchBlanketOrderPageHandler(var BlanketPurchaseOrder: TestPage "Blanket Purchase Order")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        BlanketPurchaseOrder.WorkflowStatus.First();
        BlanketPurchaseOrder.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(BlanketPurchaseOrder.WorkflowStatus.Next(), BlanketPurchaseOrder.WorkflowStatus.WorkflowDescription.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchCreditMemoPageHandler(var PurchaseCreditMemo: TestPage "Purchase Credit Memo")
    var
        WorkflowDesc: Variant;
    begin
        LibraryVariableStorage.Dequeue(WorkflowDesc);
        PurchaseCreditMemo.WorkflowStatus.First();
        PurchaseCreditMemo.WorkflowStatus.WorkflowDescription.AssertEquals(WorkflowDesc);
        Assert.IsFalse(PurchaseCreditMemo.WorkflowStatus.Next(), PurchaseCreditMemo.WorkflowStatus.WorkflowDescription.Value);
    end;
}

