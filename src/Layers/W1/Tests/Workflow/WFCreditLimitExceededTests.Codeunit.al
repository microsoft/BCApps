codeunit 134318 "WF Credit Limit Exceeded Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Event] [Credit Limit]
    end;

    var
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure TestCreditLimitExceededWhenAddingNewSalesLine()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LineAmount: Integer;
    begin
        // [SCENARIO 1] When adding a new Sales Line, the OnCustomerCreditLimitExceeded event is triggered and processed by a workflow.
        // [GIVEN] A customer with a small credit limit.
        // [WHEN] A SalesHeader is created and a SalesLine is added and the amount exceeds the credit limit of the customer.
        // [THEN] The OnCustomerCreditLimitExceeded event is triggered and processed by a workflow.

        LineAmount := LibraryRandom.RandIntInRange(1, 1000);
        CreateCustomerAndSalesLineAndExecuteWorkflow(
          LineAmount, LineAmount / 10, WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitExceededCode());
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditLimitNotExceededWhenAddingNewSalesLine()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LineAmount: Integer;
    begin
        // [SCENARIO 2] When adding a new Sales Line, the OnCustomerCreditLimitNotExceeded event is triggered and processed by a workflow.
        // [GIVEN] A customer with a big credit limit.
        // [WHEN] A SalesHeader is created and a SalesLine is added and the amount does not exceeds the credit limit of the customer.
        // [THEN] The OnCustomerCreditLimitNotExceeded event is triggered and processed by a workflow.

        LineAmount := LibraryRandom.RandIntInRange(1, 1000);
        CreateCustomerAndSalesLineAndExecuteWorkflow(LineAmount, LineAmount * 10,
          WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditLimitNotExceededWhenAddingNewSalesLineAndCustomerCreditLimitIsZero()
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LineAmount: Integer;
    begin
        // [SCENARIO 3] When adding a new Sales Line, the OnCustomerCreditLimitNotExceeded event is triggered and processed by a workflow.
        // [GIVEN] A customer with a credit limit of 0 (zero).
        // [WHEN] A SalesHeader is created and a SalesLine is added.
        // [THEN] The OnCustomerCreditLimitNotExceeded event is triggered and processed by a workflow.

        LineAmount := LibraryRandom.RandIntInRange(1, 1000);
        CreateCustomerAndSalesLineAndExecuteWorkflow(LineAmount, 0,
          WorkflowEventHandling.RunWorkflowOnCustomerCreditLimitNotExceededCode());
    end;

    local procedure CreateCustomerAndSalesLineAndExecuteWorkflow(LineAmount: Integer; CreditLimit: Decimal; WorkflowEvent: Code[128])
    var
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Workflow: Record Workflow;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        // Setup
        LibraryWorkflow.CreateWorkflow(Workflow);

        LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEvent);
        Workflow.Enabled := true;
        Workflow.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Modify(true);

        // Execute
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);

        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.GotoRecord(SalesLine);
        SalesInvoice.SalesLines."Unit Price".SetValue(LineAmount);
        SalesInvoice.Close();

        // Verify
        Assert.IsFalse(WorkflowStepInstanceArchive.IsEmpty, 'No workflow was archived');
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Credit Limit Exceeded Tests");
        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnableFoundationSetup();

        SalesReceivablesSetup.FindFirst();
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"Both Warnings");
        SalesReceivablesSetup.Modify(true);
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Credit Limit Exceeded Tests");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Credit Limit Exceeded Tests");
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

