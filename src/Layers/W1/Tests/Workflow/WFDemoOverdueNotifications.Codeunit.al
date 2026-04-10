codeunit 134186 "WF Demo Overdue Notifications"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Approval] [Overdue Notification]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        NoWorkflowEnabledErr: Label 'There is no workflow enabled for sending overdue approval notifications.';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SendOverdueNotificationsTest()
    var
        ApprovalWorkflowPurchaseDoc: Record Workflow;
        ApprovalWorkflowSalesDoc: Record Workflow;
        UserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        // [SCENARIO] Send overdue notifications with notification template defined.
        // [GIVEN] An active workflow for Send Overdue Approval Notifications.
        // [GIVEN] A user setup with 3 users and approval chain.
        // [GIVEN] A set of sales and purchase invoices mixed overdue and not overdue.
        // [WHEN] Send Overdue Notifications workflow is triggered.
        // [THEN] Notifications get created for approvers.

        // Setup
        Initialize();
        EnableOverdueWorkflow();

        LibraryWorkflow.CopyWorkflowTemplate(ApprovalWorkflowPurchaseDoc, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());
        LibraryWorkflow.CopyWorkflowTemplate(ApprovalWorkflowSalesDoc, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        ChangeApprovalWorkflowsWithDueDateFormula(ApprovalWorkflowPurchaseDoc, 0);
        ChangeApprovalWorkflowsWithDueDateFormula(ApprovalWorkflowSalesDoc, 0);
        CreateApproverChain(UserSetup, ApproverUserSetup);

        SendDocumentsForApproval(ApproverUserSetup);

        // Move due date in the future.
        ChangeApprovalWorkflowsWithDueDateFormula(ApprovalWorkflowPurchaseDoc, 5);
        ChangeApprovalWorkflowsWithDueDateFormula(ApprovalWorkflowSalesDoc, 5);

        SendDocumentsForApproval(ApproverUserSetup);

        // Exercise.
        REPORT.Run(REPORT::"Send Overdue Appr. Notif.");

        // Verify.
        VerifyOverdueNotifications(ApproverUserSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorWhenWorkflowIsNotEnabled()
    begin
        // [SCENARIO] When the overdue notifications workflow is not enabled, an error will be shown for the user invoking the report.
        // [GIVEN] The overdue notifications workflow is not enabled.
        // [WHEN] An user invokes the report.
        // [THEN] An error is shown to the user.

        // Setup
        DisableOverdueWorkflow();

        // Exercise
        asserterror REPORT.Run(REPORT::"Send Overdue Appr. Notif.");

        // Verify
        Assert.ExpectedError(NoWorkflowEnabledErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"WF Demo Overdue Notifications");
        LibraryERMCountryData.InitializeCountry();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"WF Demo Overdue Notifications");
        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"WF Demo Overdue Notifications");
    end;

    local procedure CreatePurchInvWithLine(var PurchHeader: Record "Purchase Header"; Amount: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, '', 1);
        PurchLine.Validate("Direct Unit Cost", Amount);
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesInvWithLine(var SalesHeader: Record "Sales Header"; Amount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
    end;

    local procedure CreateApproverChain(var UserSetup: Record "User Setup"; var ApproverUserSetup: Record "User Setup")
    begin
        CreateOrFindUserSetup(UserSetup, UserId);
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);

        SetApprover(UserSetup, ApproverUserSetup);

        SetPurchaseApprovalLimit(UserSetup, 100);
        SetUnlimitedPurchaseApprovalLimit(ApproverUserSetup);

        SetSalesApprovalLimit(UserSetup, 100);
        SetUnlimitedSalesApprovalLimit(ApproverUserSetup);
    end;

    local procedure SetApprover(var UserSetup: Record "User Setup"; var ApproverUserSetup: Record "User Setup")
    begin
        UserSetup."Approver ID" := ApproverUserSetup."User ID";
        UserSetup.Modify(true);
    end;

    local procedure SetPurchaseApprovalLimit(var UserSetup: Record "User Setup"; PurchaseApprovalLimit: Integer)
    begin
        UserSetup."Purchase Amount Approval Limit" := PurchaseApprovalLimit;
        UserSetup."Unlimited Purchase Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedPurchaseApprovalLimit(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure SetSalesApprovalLimit(var UserSetup: Record "User Setup"; SalesApprovalLimit: Integer)
    begin
        UserSetup."Sales Amount Approval Limit" := SalesApprovalLimit;
        UserSetup."Unlimited Sales Approval" := false;
        UserSetup.Modify(true);
    end;

    local procedure SetUnlimitedSalesApprovalLimit(var UserSetup: Record "User Setup")
    begin
        UserSetup."Unlimited Sales Approval" := true;
        UserSetup.Modify(true);
    end;

    local procedure CreateOrFindUserSetup(var UserSetup: Record "User Setup"; UserName: Text[208])
    begin
        if not LibraryDocumentApprovals.GetUserSetup(UserSetup, CopyStr(UserName, 1, 50)) then
            LibraryDocumentApprovals.CreateUserSetup(UserSetup, CopyStr(UserName, 1, 50), '');
    end;

    local procedure EnableOverdueWorkflow()
    var
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.OverdueNotificationsWorkflowCode());
    end;

    local procedure DisableOverdueWorkflow()
    var
        Workflow: Record Workflow;
    begin
        Workflow.SetRange(Enabled, true);
        if Workflow.FindSet() then
            repeat
                Workflow.Validate(Enabled, false);
                Workflow.Modify(true);
            until Workflow.Next() = 0;
    end;

    local procedure ChangeApprovalWorkflowsWithDueDateFormula(Workflow: Record Workflow; DueDateDelay: Integer)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        DueDateFormula: DateFormula;
    begin
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);

        WorkflowStep.SetRange("Workflow Code", Workflow.Code);
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();

        Evaluate(DueDateFormula, '<' + Format(DueDateDelay) + 'D>');
        WorkflowStepArgument.Get(WorkflowStep.Argument);
        WorkflowStepArgument.Validate("Due Date Formula", DueDateFormula);
        WorkflowStepArgument.Modify(true);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure SendDocumentsForApproval(ApproverUserSetup: Record "User Setup")
    var
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup - Create invoices.
        CreatePurchInvWithLine(PurchaseHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdatePurchaseDocPurchaserCode(PurchaseHeader, ApproverUserSetup."Salespers./Purch. Code");

        CreateSalesInvWithLine(SalesHeader, LibraryRandom.RandDecInRange(5000, 15000, 1));
        UpdateSalesDocSalespersonCode(SalesHeader, ApproverUserSetup."Salespers./Purch. Code");

        // Setup - Send for approval.
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
    end;

    local procedure UpdatePurchaseDocPurchaserCode(var PurchaseHeader: Record "Purchase Header"; PurchaserCode: Code[20])
    begin
        PurchaseHeader."Purchaser Code" := PurchaserCode;
        PurchaseHeader.Modify();
    end;

    local procedure UpdateSalesDocSalespersonCode(var SalesHeader: Record "Sales Header"; SalespersonCode: Code[20])
    begin
        SalesHeader."Salesperson Code" := SalespersonCode;
        SalesHeader.Modify();
    end;

    local procedure VerifyOverdueNotifications(ApproverUserSetup: Record "User Setup")
    var
        NotificationEntry: Record "Notification Entry";
    begin
        NotificationEntry.SetRange("Recipient User ID", ApproverUserSetup."User ID");
        NotificationEntry.SetRange(Type, NotificationEntry.Type::Overdue);
        Assert.AreEqual(2, NotificationEntry.Count, 'Unexpected overdue notifications.');
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

