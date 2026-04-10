codeunit 139306 "Doc. App. Setup Wizard Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Approval Setup]
    end;

    var
        LibraryWorkflow: Codeunit "Library - Workflow";
        ApprovalWorkflowSetupMgt: Codeunit "Approval Workflow Setup Mgt.";
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        WorkflowEnabledErr: Label 'Workflow is enabled';
        WorkflowNotEnabledErr: Label 'Workflow is not enabled';
        WorkflowCreatedErr: Label 'A new workflow was created';
        WorkflowNotCreatedErr: Label 'Workflow was not created';
        ApproverTypeErr: Label 'The approver type is incorrect';
        ApproverLimitTypeErr: Label 'The approver limit type is incorrect';
        UnlimitedPurchaseApprovalErr: Label 'Unlimited Purchase Approval is not selected';
        UnlimitedSalesApprovalErr: Label 'Unlimited Sales Approval is not selected';
        ApprovalAmountLimitErr: Label 'The Aproval amount limit is not correct';
        ApproverIDErr: Label 'The Unlimited Approver Name is not correct';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOverwriteApprovalUserSetup()
    begin
        TestApprovalUserSetup(false); // It does not use the existing approval user setup
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUseExistingApprovalUserSetup()
    begin
        TestApprovalUserSetup(true); // It uses the existing approval user setup
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestCreateApprovalWorkflowSetup()
    var
        TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary;
        User: Record User;
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryRandom: Codeunit "Library - Random";
        SalesApprovalAmountLimit: Decimal;
        PurchApprovalAmountLimit: Decimal;
    begin
        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] More than 2 NAV users
        LibraryPermissions.CreateWindowsUserSecurityID(UserId);
        CreateNonWindowsUsers(LibraryRandom.RandIntInRange(1, 5));

        // [GIVEN] One user is unlimited approper and the others have approval limits
        User.SetRange("User Name", UserId);
        User.FindFirst(); // The Windows user is set as unlimited approver
        SalesApprovalAmountLimit := LibraryRandom.RandInt(100);
        PurchApprovalAmountLimit := LibraryRandom.RandInt(100);

        // [WHEN] User creates purchase invoice and sales invoice approval workflows together with approval users through wizard
        InsertWizardData(
          TempApprovalWorkflowWizard, true, true, false, User."User Name", PurchApprovalAmountLimit,
          SalesApprovalAmountLimit);
        ApprovalWorkflowSetupMgt.ApplyInitialWizardUserInput(TempApprovalWorkflowWizard);

        // [THEN] Sales Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.SalesInvoiceApprovalWorkflowCode()));
        // [THEN] Purchase Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(
          WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode()));
        // [THEN] All users in NAV have approval user setup
        VerifyApprovalUserSetup(TempApprovalWorkflowWizard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSalesInvoiceApprovalWorkflow()
    var
        SalesHeader: Record "Sales Header";
        WorkflowCode: Code[20];
    begin
        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [WHEN] A Sales Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        // [THEN] Sales Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePurchaseInvoiceApprovalWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowCode: Code[20];
    begin
        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [WHEN] A Purchase Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        // [THEN] Purchase Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateSInvAppWFWithExistingWorkflowEnabled()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] A sales invoice approval workflow is created usign the wizard (WZ-SIAPW).
        // A workflow with same entry event and event conditions is already available and enabled.
        // New workflow (WZ-SIAPW) is created, and the old one is disabled.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A Sales Invoice Approval Workflow is created and enabled
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // [WHEN] A Sales Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The old workflow is disabled
        Workflow.Get(Workflow.Code);
        Assert.IsFalse(Workflow.Enabled, WorkflowEnabledErr);
        // [THEN] A new workflow is created - WZ-SIAPW
        Assert.AreNotEqual(WorkflowCode, Workflow.Code, WorkflowNotCreatedErr);
        VerifyApprovalDocumentWorkflow(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreatePInvAppWFWithExistingWorkflowEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowCode: Code[20];
    begin
        // [SCENARIO] A purchase invoice approval workflow is created using the wizard (WZ-PIAPW).
        // A workflow with same entry event and event conditions is already available and enabled.
        // New workflow (WZ-PIAPW) is created, and the old one is disabled.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A Purchase Invoice Approval Workflow is created and enabled
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        // [WHEN] A Purchase Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The old workflow is disabled
        Workflow.Get(Workflow.Code);
        Assert.IsFalse(Workflow.Enabled, WorkflowEnabledErr);
        // [THEN] A new workflow is created - WZ-PIAPW
        Assert.AreNotEqual(WorkflowCode, Workflow.Code, WorkflowNotCreatedErr);
        VerifyApprovalDocumentWorkflow(WorkflowCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEnabledSInvAppWorkflow()
    var
        SalesHeader: Record "Sales Header";
        WorkflowCode: Code[20];
        WorkflowCode2: Code[20];
        DateFormula: DateFormula;
    begin
        // [SCENARIO] A sales invoice approval workflow is created usign the wizard (WZ-SIAPW).
        // The wizard is then used to update the workflow.
        // The workflow is updated accordingly.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A Sales Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        // [WHEN] The wizard is used to update the workflow with a new due date
        Evaluate(DateFormula, '<1W>');
        WorkflowCode2 := ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The old workflow is updated
        Assert.AreEqual(WorkflowCode, WorkflowCode2, WorkflowCreatedErr);
        // [THEN] Workflow updated is enabled and has new due date formula
        VerifyApprovalDocumentWorkflow(WorkflowCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateEnabledPInvAppWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
        WorkflowCode: Code[20];
        WorkflowCode2: Code[20];
        DateFormula: DateFormula;
    begin
        // [SCENARIO] A purchase invoice approval workflow is created usign the wizard (WZ-PIAPW).
        // The wizard is then used to update the workflow.
        // The workflow is updated accordingly.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A Purchase Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        // [WHEN] The wizard is used to update the workflow with a new due date
        Evaluate(DateFormula, '<1W>');
        WorkflowCode2 :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The old workflow is updated
        Assert.AreEqual(WorkflowCode, WorkflowCode2, WorkflowCreatedErr);
        // [THEN] Workflow updated is enabled and has new due date
        VerifyApprovalDocumentWorkflow(WorkflowCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdateSInvAppWFWithExistingWorkflowEnabled()
    var
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowCode: Code[20];
        WorkflowCode2: Code[20];
        DateFormula: DateFormula;
    begin
        // [SCENARIO] A sales invoice approval workflow is created usign the wizard (WZ-SIAPW).
        // A workflow with same entry event and event conditions is created an enabled.
        // The wizard is then used to update the workflow created with the wizard (WZ-SIAPW).
        // The wokflow is updated accordingly.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A Sales Invoice Approval Workflow is created from wizard with a given due date and other default values
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());
        Workflow.Get(WorkflowCode);
        Workflow.Validate(Enabled, false);
        Workflow.Modify();

        // [GIVEN] A Sales Invoice Approval Workflow is created and enabled
        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.SalesInvoiceApprovalWorkflowCode());

        // [WHEN] The wizard is used to update the workflow with a new due date
        Evaluate(DateFormula, '<1W>');
        WorkflowCode2 := ApprovalWorkflowSetupMgt.CreateSalesDocumentApprovalWorkflow(SalesHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The workflow not created through the wizard is disabled
        Workflow.Get(Workflow.Code);
        Assert.IsFalse(Workflow.Enabled, WorkflowEnabledErr);
        Assert.AreNotEqual(Workflow.Code, WorkflowCode2, WorkflowNotCreatedErr);

        // [THEN] The old workflow is updated
        Assert.AreEqual(WorkflowCode, WorkflowCode2, WorkflowCreatedErr);
        // [THEN] Workflow updated is enabled and has new due date
        VerifyApprovalDocumentWorkflow(WorkflowCode2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatePInvAppWFWithExistingWorkflowEnabled()
    var
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        LibraryWorkflow: Codeunit "Library - Workflow";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowCode: Code[20];
        WorkflowCode2: Code[20];
        DateFormula: DateFormula;
    begin
        // [SCENARIO] A first request from wizard to create a sales invoice approval workflow is made (WZ-PIAPW).
        // A workflow with same entry event and same event conditions is already available and enabled.
        // New workflow is created, and the old one is disabled.

        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] A request for a Sales invoice approval workflow to be created is made
        WorkflowCode :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());
        Workflow.Get(WorkflowCode);
        Workflow.Validate(Enabled, false);
        Workflow.Modify();

        LibraryWorkflow.CreateEnabledWorkflow(Workflow, WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode());

        Evaluate(DateFormula, '<1W>');
        // [WHEN] A request to update the Sales invoice approval workflow is made
        WorkflowCode2 :=
          ApprovalWorkflowSetupMgt.CreatePurchaseDocumentApprovalWorkflow(PurchaseHeader."Document Type"::Invoice.AsInteger());

        // [THEN] The other workflow is disabled
        Workflow.Get(Workflow.Code);
        Assert.IsFalse(Workflow.Enabled, WorkflowEnabledErr);
        Assert.AreNotEqual(Workflow.Code, WorkflowCode2, WorkflowNotCreatedErr);

        // [THEN] The old workflow is updated
        Assert.AreEqual(WorkflowCode, WorkflowCode2, WorkflowCreatedErr);
        // [THEN] Workflow updated is enabled and has new due date
        VerifyApprovalDocumentWorkflow(WorkflowCode2);
    end;

    local procedure TestApprovalUserSetup(UseExistingApprovalUserSetup: Boolean)
    var
        TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary;
        TempApprovalWorkflowWizard2: Record "Approval Workflow Wizard" temporary;
        User: Record User;
        WorkflowSetup: Codeunit "Workflow Setup";
        LibraryRandom: Codeunit "Library - Random";
        SalesApprovalAmountLimit: Decimal;
        PurchApprovalAmountLimit: Decimal;
    begin
        // [GIVEN] A newly provisioned database, which has been initialized and only contains base data
        Initialize();

        // [GIVEN] More than 2 NAV users
        LibraryPermissions.CreateWindowsUserSecurityID(UserId);
        CreateNonWindowsUsers(LibraryRandom.RandIntInRange(1, 5));

        // [GIVEN] All created users have approval user setup
        User.SetRange("User Name", UserId);
        User.FindFirst(); // The Windows user is set as unlimited approver
        SalesApprovalAmountLimit := LibraryRandom.RandInt(100);
        PurchApprovalAmountLimit := LibraryRandom.RandInt(100);
        InsertWizardData(
          TempApprovalWorkflowWizard, true, true, false, User."User Name", PurchApprovalAmountLimit,
          SalesApprovalAmountLimit);
        ApprovalWorkflowSetupMgt.CreateApprovalSetup(TempApprovalWorkflowWizard);

        // [WHEN] New purchase amount and sales amount approval limists are chosen by the admin
        SalesApprovalAmountLimit := LibraryRandom.RandInt(100);
        PurchApprovalAmountLimit := LibraryRandom.RandInt(100);

        // [WHEN] Admin decides if to use the new limits or not (UseExistingApprovalUserSetup)
        InsertWizardData(
          TempApprovalWorkflowWizard2, true, true, UseExistingApprovalUserSetup, User."User Name", PurchApprovalAmountLimit,
          SalesApprovalAmountLimit);
        ApprovalWorkflowSetupMgt.ApplyInitialWizardUserInput(TempApprovalWorkflowWizard2);

        // [THEN] Sales Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.SalesInvoiceApprovalWorkflowCode()));
        // [THEN] Purchase Invoice Approval workflow is set according to the user's options
        VerifyApprovalDocumentWorkflow(
          WorkflowSetup.GetWorkflowWizardCode(WorkflowSetup.PurchaseInvoiceApprovalWorkflowCode()));
        // [THEN] The approval amount and sales amount approval limits reflect admin's decission
        if UseExistingApprovalUserSetup then
            VerifyApprovalUserSetup(TempApprovalWorkflowWizard)
        else
            VerifyApprovalUserSetup(TempApprovalWorkflowWizard2);
    end;

    local procedure Initialize()
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowResponse: Record "Workflow Response";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowEvent.DeleteAll();
        WorkflowResponse.DeleteAll();

        WorkflowSetup.InitWorkflow();
    end;

    local procedure InsertWizardData(var TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary; PurchInvAppWF: Boolean; SalesInvAppWF: Boolean; UseExistApprovalUserSetup: Boolean; ApproverID: Code[50]; PurchAmounApprovaltLimit: Decimal; SalesAmountApprovalLimit: Decimal)
    begin
        TempApprovalWorkflowWizard.Init();
        TempApprovalWorkflowWizard."Purch Invoice App. Workflow" := PurchInvAppWF;
        TempApprovalWorkflowWizard."Sales Invoice App. Workflow" := SalesInvAppWF;
        TempApprovalWorkflowWizard."Use Exist. Approval User Setup" := UseExistApprovalUserSetup;
        TempApprovalWorkflowWizard."Approver ID" := ApproverID;
        TempApprovalWorkflowWizard."Purch Amount Approval Limit" := PurchAmounApprovaltLimit;
        TempApprovalWorkflowWizard."Sales Amount Approval Limit" := SalesAmountApprovalLimit;
        TempApprovalWorkflowWizard.Insert();
    end;

    local procedure VerifyApprovalDocumentWorkflow(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        Workflow.Get(WorkflowCode);
        Assert.RecordIsNotEmpty(Workflow);
        Assert.IsTrue(Workflow.Enabled, WorkflowNotEnabledErr);

        // Get the step
        WorkflowStep.SetFilter("Workflow Code", WorkflowCode);
        WorkflowStep.SetRange(Type, WorkflowStep.Type::Response);
        WorkflowStep.SetFilter("Function Name", WorkflowResponseHandling.CreateApprovalRequestsCode());
        WorkflowStep.FindFirst();
        Assert.RecordIsNotEmpty(WorkflowStep);

        // Get the step arguments
        WorkflowStepArgument.SetFilter(ID, WorkflowStep.Argument);
        WorkflowStepArgument.SetRange(Type, WorkflowStepArgument.Type::Response);
        WorkflowStepArgument.SetFilter("Response Function Name", WorkflowStep."Function Name");
        WorkflowStepArgument.FindFirst();
        Assert.RecordIsNotEmpty(WorkflowStepArgument);

        // Verify user's input from wizard and default settings
        Assert.AreEqual(
          WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Type", ApproverTypeErr);
        Assert.AreEqual(WorkflowStepArgument."Approver Limit Type"::"First Qualified Approver",
          WorkflowStepArgument."Approver Limit Type", ApproverLimitTypeErr);
    end;

    local procedure VerifyApprovalUserSetup(TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary)
    var
        User: Record User;
        ApprovalUserSetup: Record "User Setup";
    begin
        ApprovalUserSetup.Get(TempApprovalWorkflowWizard."Approver ID");
        Assert.IsTrue(ApprovalUserSetup."Unlimited Purchase Approval", UnlimitedPurchaseApprovalErr);
        Assert.IsTrue(ApprovalUserSetup."Unlimited Sales Approval", UnlimitedSalesApprovalErr);

        User.SetFilter("User Name", '<>%1', TempApprovalWorkflowWizard."Approver ID");

        if User.FindSet() then
            repeat
                ApprovalUserSetup.Get(User."User Name");
                if TempApprovalWorkflowWizard."Sales Invoice App. Workflow" then
                    Assert.AreEqual(
                      TempApprovalWorkflowWizard."Sales Amount Approval Limit", ApprovalUserSetup."Sales Amount Approval Limit",
                      ApprovalAmountLimitErr);
                if TempApprovalWorkflowWizard."Purch Invoice App. Workflow" then
                    Assert.AreEqual(
                      TempApprovalWorkflowWizard."Purch Amount Approval Limit", ApprovalUserSetup."Purchase Amount Approval Limit",
                      ApprovalAmountLimitErr);
                Assert.AreEqual(TempApprovalWorkflowWizard."Approver ID", ApprovalUserSetup."Approver ID", ApproverIDErr);
            until User.Next() = 0;
    end;

    local procedure CreateNonWindowsUsers(NoOfUsers: Integer)
    var
        User: Record User;
        I: Integer;
        UserName: Code[50];
    begin
        for I := 1 to NoOfUsers do begin
            UserName := GenerateUserName();
            LibraryPermissions.CreateUser(User, UserName, false);
        end;
    end;

    local procedure GenerateUserName() UserName: Code[50]
    var
        User: Record User;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        repeat
            UserName :=
              CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
                1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
            User.SetRange("User Name", UserName);
        until User.IsEmpty();
    end;
}

