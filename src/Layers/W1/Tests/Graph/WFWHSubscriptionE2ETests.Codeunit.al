codeunit 135528 "WFWH Subscription E2E Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Workflow] [Webhook] [Subscription]
    end;

    var
        WorkflowWebhookSubscription: Record "Workflow Webhook Subscription";
        Workflow: Record Workflow;
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        MockOnFindTaskSchedulerAllowed: Codeunit MockOnFindTaskSchedulerAllowed;
        MockOnPostNotificationRequest: Codeunit MockOnPostNotificationRequest;
        MockOnFetchInitParams: Codeunit MockOnFetchInitParams;
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        EmptyJSONErr: Label 'The JSON should not be blank.';
        WrongPropertyValueErr: Label 'Incorrect property value for %1.';
        EnabledErr: Label 'The %1 %2 must be enabled.';
        DisabledErr: Label 'The %1 %2 must be disabled.';
        DummyClientIdTxt: Label '65AC2102-DBA7-403D-8B5D-FEBD268B62A9', Locked = true;
        DummyClientTypeTxt: Label 'Flow', Locked = true;
        DummyConditionsTxt: Label 'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiZG9jdW1lbnRUeXBlIiwiVmFsdWUiOiJPcmRlciJ9LHsiTmFtZSI6InN0YXR1cyIsIlZhbHVlIjoiT3BlbiJ9LHsiTmFtZSI6ImFtb3VudCIsIlZhbHVlIjoiPjAifV19', Locked = true;
        DummySecondConditionsTxt: Label 'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiZG9jdW1lbnRUeXBlIiwiVmFsdWUiOiJPcmRlciJ9LHsiTmFtZSI6InN0YXR1cyIsIlZhbHVlIjoiT3BlbiJ9LHsiTmFtZSI6ImFtb3VudCIsIlZhbHVlIjoiPjEwMDAwIn1dfQ==', Locked = true;
        DummyNotificationUrlTxt: Label 'aHR0cHM6Ly93d3cuYmluZ3NkZi5jb20=', Locked = true;
        WorkflowWebhookSetup: Codeunit "Workflow Webhook Setup";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        ConditionsDoNotAgreeErr: Label 'Generated and expected conditions do not agree.';
        WorkflowWebhookSubscriptionsPage: Page "Workflow Webhook Subscriptions";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"WFWH Subscription E2E Tests");

        LibraryApplicationArea.EnableFoundationSetup();
        LibraryWorkflow.DisableAllWorkflows();
        WorkflowWebhookSubscription.DeleteAll();
        UnbindSubscription(MockOnFindTaskSchedulerAllowed);
        BindSubscription(MockOnFindTaskSchedulerAllowed);
        UnbindSubscription(MockOnPostNotificationRequest);
        BindSubscription(MockOnPostNotificationRequest);
        MockOnPostNotificationRequest.SetReturnType('NoErrorReceived');
        UnbindSubscription(MockOnFetchInitParams);
        BindSubscription(MockOnFetchInitParams);

        if IsInitialized then
            exit;
        IsInitialized := true;

        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanGetWorkflowWebhookSubscriptionNoWorkflow()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Get a WorkflowWebhookSubscripiton with a GET request to the service

        Initialize();

        // [GIVEN] A Workflow Webhook Subscripiton exists.
        CreateWorkflowWebhookSubscriptionNoWorkflow();

        // [WHEN] A GET request is made for a given workflow webhook subscription.
        TargetURL := CreateTargetURL(
            LowerCase(Format(WorkflowWebhookSubscription.Id, 0, 4)), PAGE::"Workflow Webhook Subscriptions",
            WorkflowWebhookSubscriptionsPage.Caption);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response text contains the WorkflowWebhookSubscription information.
        VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(ResponseText, WorkflowWebhookSubscription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCreateWorkflowWebhookSubscriptionWithWorkflow()
    var
        TempWorkflowWebhookSubscription: Record "Workflow Webhook Subscription" temporary;
        ResponseText: Text;
        TargetURL: Text;
        WorkflowWebhookSubscriptionJSON: Text;
        SubscriptionId: Text;
    begin
        // [SCENARIO] Create a WorkflowWebhookSubscripiton and Workflow through a POST request to the service.

        Initialize();

        // [GIVEN] The user has constructed a WorkflowWebhookSubscription JSON object to send in body of POST.
        CreateTempWorkflowWebhookSubscription(TempWorkflowWebhookSubscription, DummyConditionsTxt);
        WorkflowWebhookSubscriptionJSON := GetJSONFromWorkflowWebhookSubscription(TempWorkflowWebhookSubscription);

        // [WHEN] The user makes a POST to the service with the JSON as the body.
        TargetURL := CreateTargetURL('', PAGE::"Workflow Webhook Subscriptions",
            WorkflowWebhookSubscriptionsPage.Caption);
        LibraryGraphMgt.PostToWebService(TargetURL, WorkflowWebhookSubscriptionJSON, ResponseText);

        // [THEN] The response text contains the WorkflowWebhookSubscription information.
        VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(ResponseText, TempWorkflowWebhookSubscription);

        // [THEN] The WorkflowWebhookSubscription was created in the database.
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', SubscriptionId); // get id for the subscription
        WorkflowWebhookSubscription.Get(SubscriptionId);
        VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(ResponseText, WorkflowWebhookSubscription);

        // [THEN] The WorkflowWebhookSubscription created is enabled.
        Assert.IsTrue(WorkflowWebhookSubscription.Enabled, StrSubstNo(EnabledErr, 'WorkflowWebhookSubscription', SubscriptionId));

        // [THEN] The Workflow definition was created.
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");

        // [THEN] The Workflow definition created is enabled.
        Assert.IsTrue(Workflow.Enabled, StrSubstNo(EnabledErr, 'Workflow', Workflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanDeleteWorkflowWebhookSubscriptionWithWorkflow()
    var
        ResponseText: Text;
        WorkflowCode: Code[20];
        WorkflowWebhookSubscriptionId: Guid;
    begin
        // [SCENARIO] Delete a WorkflowWebhookSubscripiton and Workflow through a DELETE request to the service.

        Initialize();

        // [GIVEN] A WorkflowWebhookSubscripiton and corresponding workflow exist.
        CreateWorkflowWebhookSubscriptionAndWorkflow();
        WorkflowWebhookSubscriptionId := WorkflowWebhookSubscription.Id;
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");
        WorkflowCode := Workflow.Code;

        // [WHEN] The user makes a DELETE request to the service.
        ResponseText := MockDeleteFromWebService(WorkflowWebhookSubscription);
        Commit();

        // [THEN] The response text is empty
        Assert.AreEqual('', ResponseText, 'DELETE response should be empty.');

        // [THEN] The WorkflowWebhookSubscripiton is no longer in the database.
        Assert.IsFalse(WorkflowWebhookSubscription.Get(WorkflowWebhookSubscriptionId), 'WorkflowWebhookSubscripiton should be deleted.');

        // [THEN] The Workflow is no longer in the database.
        Assert.IsFalse(Workflow.Get(WorkflowCode), 'Workflow should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanDeleteWorkflowWebhookSubscriptionHavingWorkflowWithActiveWorkflowSteps()
    var
        ResponseText: Text;
        WorkflowCode: Code[20];
        WorkflowWebhookSubscriptionId: Guid;
    begin
        // [SCENARIO] Delete a WorkflowWebhookSubscripiton that has Workflow with active workflow steps through a DELETE request to the service.

        Initialize();

        // [GIVEN] A WorkflowWebhookSubscripiton and corresponding workflow exist.
        CreateWorkflowWebhookSubscriptionAndWorkflow();
        WorkflowWebhookSubscriptionId := WorkflowWebhookSubscription.Id;
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");
        WorkflowCode := Workflow.Code;

        // [GIVEN] A pending Sales Order for the workflow exists.
        CreateSalesOrderAndSendForApproval();

        // [WHEN] The user makes a DELETE request to the service.
        ResponseText := MockDeleteFromWebService(WorkflowWebhookSubscription);
        Commit();

        // [THEN] The response text is empty. No error from not being able to delete workflow with active steps.
        Assert.AreEqual('', ResponseText, 'DELETE response should be empty.');

        // [THEN] The Workflow is still in the database because it has active steps.
        Assert.IsTrue(Workflow.Get(WorkflowCode), 'Workflow should exist because it has active steps.');

        // [THEN] The Workflow is disabled.
        Assert.IsFalse(Workflow.Enabled, StrSubstNo(DisabledErr, 'Workflow', Workflow.Code));

        // [THEN] The WorkflowWebhookSubscripiton is no longer in the database although workflow failed to be deleted.
        Assert.IsFalse(WorkflowWebhookSubscription.Get(WorkflowWebhookSubscriptionId), 'WorkflowWebhookSubscripiton should be deleted.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanUpdateWorkflowWebhookSubscriptionWithWorkflow_PostWithoutDelete()
    var
        TempWorkflowWebhookSubscription: Record "Workflow Webhook Subscription" temporary;
        ResponseText: Text;
        TargetURL: Text;
        WorkflowCode: Code[20];
        WorkflowWebhookSubscriptionId: Guid;
        WorkflowWebhookSubscriptionJSON: Text;
        UpdatedSubscriptionId: Text;
    begin
        // [SCENARIO]
        // Update a WorkflowWebhookSubscripiton and Workflow through POST and DELETE requests to the service. MSFT Flow doesn't support
        // Updates by way of PATCH/PUT requests. Updates from MSFT Flow are sent as 2 parallel POST and DELETE requests. In this scenario
        // we consider the case where the POST request happens assuming we already have the initial subscription and workflow.

        Initialize();

        // [GIVEN] A WorkflowWebhookSubscripiton and corresponding workflow exist.
        CreateWorkflowWebhookSubscriptionAndWorkflow();
        WorkflowWebhookSubscriptionId := WorkflowWebhookSubscription.Id;
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");
        WorkflowCode := Workflow.Code;

        // [GIVEN] The user has constructed a WorkflowWebhookSubscription JSON object with same clientId as current WorkflowWebhookSubscripiton
        // in table but different conditions to send in body of POST.
        CreateTempWorkflowWebhookSubscription(TempWorkflowWebhookSubscription, DummySecondConditionsTxt);
        WorkflowWebhookSubscriptionJSON := GetJSONFromWorkflowWebhookSubscription(TempWorkflowWebhookSubscription);

        // [WHEN] A POST request is made to the service with the JSON as the body.
        TargetURL := CreateTargetURL('', PAGE::"Workflow Webhook Subscriptions",
            WorkflowWebhookSubscriptionsPage.Caption);
        LibraryGraphMgt.PostToWebService(TargetURL, WorkflowWebhookSubscriptionJSON, ResponseText);

        // [THEN] The response text contains the updated WorkflowWebhookSubscription information.
        VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(ResponseText, TempWorkflowWebhookSubscription);

        // [THEN] The previous Workflow definition is disabled.
        Workflow.Get(WorkflowCode);
        Assert.IsFalse(Workflow.Enabled, StrSubstNo(DisabledErr, 'Workflow', Workflow.Code));

        // [THEN] The updated WorkflowWebhookSubscription was created in the database.
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', UpdatedSubscriptionId); // get id for the subscription
        WorkflowWebhookSubscription.Get(UpdatedSubscriptionId);
        VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(ResponseText, WorkflowWebhookSubscription);

        // [THEN] The updated WorkflowWebhookSubscription created is enabled.
        Assert.IsTrue(WorkflowWebhookSubscription.Enabled, StrSubstNo(EnabledErr, 'WorkflowWebhookSubscription', UpdatedSubscriptionId));

        // [THEN] The updated Workflow definition was created.
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");

        // [THEN] The updated Workflow definition created is enabled.
        Assert.IsTrue(Workflow.Enabled, StrSubstNo(EnabledErr, 'Workflow', Workflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanUpdateWorkflowWebhookSubscriptionWithWorkflow_PostThenDelete()
    var
        TempWorkflowWebhookSubscription: Record "Workflow Webhook Subscription" temporary;
        ResponseText: Text;
        TargetURL: Text;
        WorkflowCode: Code[20];
        WorkflowWebhookSubscriptionId: Guid;
        WorkflowWebhookSubscriptionJSON: Text;
        UpdatedSubscriptionId: Text;
    begin
        // [SCENARIO]
        // Update a WorkflowWebhookSubscripiton and Workflow through POST and DELETE requests to the service. MSFT Flow doesn't support
        // Updates by way of PATCH/PUT requests. Updates from MSFT Flow are sent as 2 parallel POST and DELETE requests. In this scenario
        // we consider the case where the POST request happens assuming we already have the initial subscription and workflow and then
        // corresponding DELETE request which completes the Update.

        Initialize();

        // [GIVEN] A WorkflowWebhookSubscripiton and corresponding workflow exist.
        CreateWorkflowWebhookSubscriptionAndWorkflow();
        WorkflowWebhookSubscriptionId := WorkflowWebhookSubscription.Id;
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");
        WorkflowCode := Workflow.Code;

        // [GIVEN] The user has constructed a WorkflowWebhookSubscription JSON object with same clientId as current WorkflowWebhookSubscripiton
        // in table but different conditions to send in body of POST.
        CreateTempWorkflowWebhookSubscription(TempWorkflowWebhookSubscription, DummySecondConditionsTxt);
        WorkflowWebhookSubscriptionJSON := GetJSONFromWorkflowWebhookSubscription(TempWorkflowWebhookSubscription);

        // [WHEN] The user makes a POST to the service with the JSON as the body.
        TargetURL := CreateTargetURL('', PAGE::"Workflow Webhook Subscriptions",
            WorkflowWebhookSubscriptionsPage.Caption);
        LibraryGraphMgt.PostToWebService(TargetURL, WorkflowWebhookSubscriptionJSON, ResponseText);
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', UpdatedSubscriptionId); // get id for the subscription

        // [WHEN] The user makes a  corresponding DELETE request to the service thereby completing the Update.
        ResponseText := MockDeleteFromWebService(WorkflowWebhookSubscription);
        Commit();

        // [THEN] The previous WorkflowWebhookSubscripiton is no longer in the database.
        Assert.IsFalse(WorkflowWebhookSubscription.Get(WorkflowWebhookSubscriptionId), 'WorkflowWebhookSubscripiton should be deleted.');

        // [THEN] The previous Workflow is no longer in the database.
        Assert.IsFalse(Workflow.Get(WorkflowCode), 'Workflow should be deleted.');

        // [THEN] The updated WorkflowWebhookSubscription was created in the database.
        WorkflowWebhookSubscription.Get(UpdatedSubscriptionId);

        // [THEN] The updated WorkflowWebhookSubscription created is enabled.
        Assert.IsTrue(WorkflowWebhookSubscription.Enabled, StrSubstNo(EnabledErr, 'WorkflowWebhookSubscription', UpdatedSubscriptionId));

        // [THEN] The updated Workflow definition was created.
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");

        // [THEN] The updated Workflow definition created is enabled.
        Assert.IsTrue(Workflow.Enabled, StrSubstNo(EnabledErr, 'Workflow', Workflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanUpdateWorkflowWebhookSubscriptionWithWorkflow_DeleteThenPost()
    var
        TempWorkflowWebhookSubscription: Record "Workflow Webhook Subscription" temporary;
        ResponseText: Text;
        TargetURL: Text;
        WorkflowWebhookSubscriptionId: Guid;
        WorkflowWebhookSubscriptionJSON: Text;
        UpdatedSubscriptionId: Text;
    begin
        // [SCENARIO]
        // Update a WorkflowWebhookSubscripiton and Workflow through POST and DELETE requests to the service. MSFT Flow doesn't support
        // Updates by way of PATCH/PUT requests. Updates from MSFT Flow are sent as 2 parallel POST and DELETE requests. In this scenario
        // we consider the case where the DELETE request for the initial subscription happens and then corresponding POST request which completes the Update.

        Initialize();

        // [GIVEN] A WorkflowWebhookSubscripiton and corresponding workflow exist.
        CreateWorkflowWebhookSubscriptionAndWorkflow();
        WorkflowWebhookSubscriptionId := WorkflowWebhookSubscription.Id;
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");

        // [GIVEN] The user has constructed a WorkflowWebhookSubscription JSON object with same clientId as current WorkflowWebhookSubscripiton
        // in table but different conditions to send in body of POST.
        CreateTempWorkflowWebhookSubscription(TempWorkflowWebhookSubscription, DummySecondConditionsTxt);
        WorkflowWebhookSubscriptionJSON := GetJSONFromWorkflowWebhookSubscription(TempWorkflowWebhookSubscription);

        // [WHEN] The user makes a  DELETE request to the service to delete the previous subscription.
        ResponseText := MockDeleteFromWebService(WorkflowWebhookSubscription);
        Commit();

        // [WHEN] The user makes a corresponding POST to the service with the JSON as the body thereby completing the update.
        TargetURL := CreateTargetURL('', PAGE::"Workflow Webhook Subscriptions",
            WorkflowWebhookSubscriptionsPage.Caption);
        LibraryGraphMgt.PostToWebService(TargetURL, WorkflowWebhookSubscriptionJSON, ResponseText);

        // [THEN] The previous WorkflowWebhookSubscripiton is no longer in the database.
        Assert.IsFalse(WorkflowWebhookSubscription.Get(WorkflowWebhookSubscriptionId), 'WorkflowWebhookSubscripiton should be deleted.');

        // [THEN] The updated WorkflowWebhookSubscription was created in the database.
        LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', UpdatedSubscriptionId); // get id for the subscription
        WorkflowWebhookSubscription.Get(UpdatedSubscriptionId);

        // [THEN] The updated WorkflowWebhookSubscription created is enabled.
        Assert.IsTrue(WorkflowWebhookSubscription.Enabled, StrSubstNo(EnabledErr, 'WorkflowWebhookSubscription', UpdatedSubscriptionId));

        // [THEN] The updated Workflow definition was created.
        Workflow.Get(WorkflowWebhookSubscription."WF Definition Id");

        // [THEN] The updated Workflow definition created is enabled.
        Assert.IsTrue(Workflow.Enabled, StrSubstNo(EnabledErr, 'Workflow', Workflow.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoConditionsInputGivesNoConditionsOutput()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions2: FilterPageBuilder;
        EventConditions3: FilterPageBuilder;
        EventConditions1: FilterPageBuilder;
        ConditionsExpected1Txt: Text;
        ConditionsInput2Txt: Text;
        ConditionsResulted2Txt: Text;
        ConditionsExpected2Txt: Text;
        ConditionsInput3Txt: Text;
        ConditionsExpected3Txt: Text;
        ConditionsResulted3Txt: Text;
        ConditionsInput1Txt: Text;
        ConditionsResulted1Txt: Text;
    begin
        // [SCENARIO]
        // Empty string or JSON was received from connector or user did not specify any conditions while creating a flow.
        // Workflow should still be created but should not contain any conditions.
        // This test can fit various Event Codes.

        // [GIVEN] Empty Coniditions input: either no input or encoded empty JSON or empty list of conditions (i.e. '{"HeaderConditions": [],"LinesConditions": []}').
        ConditionsInput1Txt := '';
        ConditionsInput2Txt := 'e30=';
        ConditionsInput3Txt := 'eyJIZWFkZXJDb25kaXRpb25zIjpbXSwiTGluZXNDb25kaXRpb25zIjpbXX0=';

        // [WHEN] Conditions received from Flow are parsed and Conditions Xml is generated.
        ConditionsResulted1Txt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInput1Txt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        ConditionsResulted2Txt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInput2Txt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        ConditionsResulted3Txt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInput3Txt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        ConditionsExpected1Txt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions1, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");
        ConditionsExpected2Txt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions2, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions3.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions3.SetView(EventConditions3.Name(1), SalesHeader.GetView());

        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions3.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions3.SetView(EventConditions3.Name(2), SalesLine.GetView());

        ConditionsExpected3Txt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions3, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Verify generated conditions are as expected.
        Assert.AreEqual(ConditionsExpected1Txt, ConditionsResulted1Txt, 'Empty input should result in XML without conditions.');
        Assert.AreEqual(ConditionsExpected2Txt, ConditionsResulted2Txt, 'Empty JSON input should result in XML without conditions.');
        Assert.AreEqual(ConditionsExpected3Txt, ConditionsResulted3Txt, 'Empty Conditions input should result in XML without conditions.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateConditionsWithEmptySalesLinesForSalesOrderApproval()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // User did not provide any conditions for the Sales Lines while creating Sales Order Approval flow.
        // Created Conditions XML should contain only Sales Header conditions.
        // This test is suitable for Sales Order Approval event only.

        // [GIVEN] Sample of Base64 encoded Conditions input that does not contain Sales Lines conditions.
        ConditionsInputTxt := 'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVOdW1iZXIiLCJWYWx1ZSI6IjEwMCJ9XX0=';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        SalesHeader.Reset();
        SalesHeader.SetFilter("Quote No.", '%1', '100');
        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions.SetView(EventConditions.Name(1), SalesHeader.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateConditionsWithEmptyHeaderLinesForSalesOrderApproval()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // User put in only Sales Lines conditions and did not provide any conditions for the Sales Header while creating Sales Order Approval flow.
        // Created Conditions XML should contain only the Sales Lines conditions.
        // This test is suitable for Sales Order Approval event only.

        // [GIVEN] Sample of Base64 encoded Conditions input that does not contain Header Lines conditions.
        ConditionsInputTxt := 'eyJMaW5lc0NvbmRpdGlvbnMiOlt7Ik5hbWUiOiJhbW91bnQiLCJWYWx1ZSI6IjEwMDAifV19';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        SalesLine.Reset();
        SalesLine.SetFilter(Amount, '%1', 1000);
        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions.SetView(EventConditions.Name(1), SalesLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWrongOrMissingNameParameterConditionGotIgnored()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInput1Txt: Text;
        ConditionsResulted1Txt: Text;
        ConditionsInput2Txt: Text;
        ConditionsResulted2Txt: Text;
    begin
        // [SCENARIO]
        // Input conditions ended up having misspelled "Name" argument or does not have "Name" argument at all (i.e. "Value" argument does not have corresponding "Name" argument).
        // Conditions should be parsed without errors skipping the condition with misdefined/missing name.
        // This test can fit various Event Codes.

        // [GIVEN] Sample of Base64 encoded Conditions input that has misspelled Name property in it and a sample with missing "Name" argument.
        ConditionsInput1Txt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJNaXNzcGVsbGVkTmFtZSI6InNvbWVDb250cm9sTmFtZSIsIlZhbHVlIjoidmFsdWUifSx7Ik5hbWUiOiJxdW90ZU51bWJlciIsIlZhbHVlIjoiMTAwIn1dLCJMaW5lc0NvbmRpdGlvbnMiOlt7Ik5hbWUiOiJhbW91bnQiLCJWYWx1ZSI6IjEwMDAifV19';
        ConditionsInput2Txt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJWYWx1ZSI6InZhbHVlIn0seyJOYW1lIjoicXVvdGVOdW1iZXIiLCJWYWx1ZSI6IjEwMCJ9XSwiTGluZXNDb25kaXRpb25zIjpbeyJOYW1lIjoiYW1vdW50IiwiVmFsdWUiOiIxMDAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResulted1Txt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInput1Txt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        ConditionsResulted2Txt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInput2Txt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        SalesHeader.Reset();
        SalesHeader.SetFilter("Quote No.", '%1', '100');
        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions.SetView(EventConditions.Name(1), SalesHeader.GetView());

        SalesLine.Reset();
        SalesLine.SetFilter(Amount, '%1', 1000);
        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions.SetView(EventConditions.Name(2), SalesLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResulted1Txt, ConditionsDoNotAgreeErr);
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResulted2Txt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyMissingValueParameterConditionGotIgnored()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // "Name" argument does not have corresponding "Value" argument for one or more conditions in the input.
        // Conditions should be parsed without errors skipping the condition that misses the value.

        // [GIVEN] Sample of Base64 encoded Conditions input that has a "Name" argument without corresponding "Value".
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoicGFja2FnZVRyYWNraW5nTnVtYmVyIiwiVmFsdWUiOiIxMDAifSx7Ik5hbWUiOiJvcmRlckRhdGUifV0sIkxpbmVzQ29uZGl0aW9ucyI6W3siTmFtZSI6ImFtb3VudCIsIlZhbHVlIjoiMTAwMCJ9XX0=';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        SalesHeader.Reset();
        SalesLine.Reset();

        SalesHeader.SetFilter("Package Tracking No.", '%1', '100');
        SalesLine.SetFilter(Amount, '%1', 1000);

        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions.SetView(EventConditions.Name(1), SalesHeader.GetView());

        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions.SetView(EventConditions.Name(2), SalesLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyWrongEncodingError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // Conditions received from Flow were not Base64 encoded.
        // Corresponding error message need to be shown.
        // This test can fit various Event Codes.

        // [GIVEN] Sample of Conditions input that is not Base64 encoded.
        ConditionsInputTxt := 'bad encoding input example';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(WorkflowWebhookSubscription.GetUnableToParseEncodingErr());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyInvalidJSONError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // Conditions received from Flow were not in correct JSON format.
        // Corresponding error message need to be shown.
        // This test can fit various Event Codes.

        // [GIVEN] Sample of Base64 encoded Conditions input that has invalid JSON (i.e. missing closing bracket).
        ConditionsInputTxt := 'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoibnVtYmVyIiwiVmFsdWUiOiIxMDAifX0=';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(WorkflowWebhookSubscription.GetUnableToParseInvalidJsonErr());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (i.e. nonexisting control name) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.
        // This test can fit various Event Codes.

        // [GIVEN] Sample of Base64 encoded Conditions input that has a non-existing Control Name in it.
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoibm9uRXhpc3RpbmdDb250cm9sTmFtZSIsIlZhbHVlIjoidmFsdWUifSx7Ik5hbWUiOiJudW1iZXIiLCJWYWx1ZSI6IjEwMCJ9XX0=';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'nonExistingControlName',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Sales Document Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyInvalidJSONArrayError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // For both Header and Lines Web Services list of conditions received from Flow need to be in JSON array format.
        // If that is not the case, corresponding error message need to be shown.
        // This test can fit various Event Codes.

        // [GIVEN] Sample of Base64 encoded Conditions input that has does not have conditions formatted as JSON array.
        ConditionsInputTxt := 'eyJIZWFkZXJDb25kaXRpb25zIjoic2FtcGxlIHZhbHVlIn0=';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(StrSubstNo(WorkflowWebhookSubscription.GetUnableToParseJsonArrayErr(), 'HeaderConditions'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnsupportedWorkflowEventCodeError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // Invalid Event Code was specified at the input during creation of the flow.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample input.
        ConditionsInputTxt := '';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(ConditionsInputTxt, 'Nonexisting Event Code');

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(StrSubstNo(WorkflowWebhookSetup.GetUnsupportedWorkflowEventCodeErr(), UpperCase('Nonexisting Event Code')));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTypeConverionOnParsingError()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // Verifies that when the input for the "Value" argument can not be converted correctly to the type of the corresponding field from the source table, the proper error message is shown.
        // For example, when a condition on the field of BLOB type is tried to get applied, the error message need to be shown, since BLOB type is not supported for conditions at this time.
        // This test can fit various Event Codes.

        // [GIVEN] Sample input that contains condition on a field of type BLOB.
        ConditionsInputTxt := 'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoid29ya0Rlc2NyaXB0aW9uIiwiVmFsdWUiOiJzYW1wbGUgQkxPQiJ9XX0=';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          'The filter "sample BLOB" is not valid for the Work Description field on the Sales Header table. The value "sample BLOB" can' +
          '''t be evaluated into type BLOB.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTypeConverionOnParsing()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        DateTimeSampleValue: DateTime;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // General test for Conditions parsing. Test verifies that all allowed data types that may appear in Conditions input would be parsed correctly.
        // This test can fit various Event Codes.

        // [GIVEN] Sample input with conditions for fields of various types (Option, Code, Text, Date, Decimal, Boolean, DateTime, GUID, Integer, DateFormula).
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiZG9jdW1lbnRUeXBlIiwiVmFsdWUiOiJPcmRlciJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiPjIwMDAifSx7Ik5hbWUiOiJ5b3VyUmVmZXJlbm';
        ConditionsInputTxt :=
          ConditionsInputTxt +
          'NlIiwiVmFsdWUiOiJzYW1wbGUgdGV4dCJ9LHsiTmFtZSI6Im9yZGVyRGF0ZSIsIlZhbHVlIjoiPjAxMDExM0QifSx7Ik5hbWUiOiJwYXltZW50RGlzY291bnRQZXJjZW50IiwiVmFsdWUiOiIx';
        ConditionsInputTxt :=
          ConditionsInputTxt +
          'MCJ9LHsiTmFtZSI6ImNvbW1lbnQiLCJWYWx1ZSI6IlRSVUUifSx7Ik5hbWUiOiJxdW90ZVNlbnRUb0N1c3RvbWVyIiwiVmFsdWUiOiIwMS0wMS0wOCAwOTozNSJ9LHsiTmFtZSI6ImpvYlF1';
        ConditionsInputTxt :=
          ConditionsInputTxt +
          'ZXVlRW50cnlJZCIsIlZhbHVlIjoie0UxNjY1NUE2LTVDRDItNDAwRS05QkQ1LTQwRTQwRUQwOEM2MX0ifSx7Ik5hbWUiOiJpbmNvbWluZ0RvY3VtZW50RW50cnlOdW1iZXIiLCJWYWx1ZSI6';
        ConditionsInputTxt :=
          ConditionsInputTxt +
          'IjEifSx7Ik5hbWUiOiJzaGlwcGluZ1RpbWUiLCJWYWx1ZSI6IjFXIn1dLCJMaW5lc0NvbmRpdGlvbnMiOlt7Ik5hbWUiOiJwcmljZURlc2NyaXB0aW9uIiwiVmFsdWUiOiJzYW1wbGUgdGV4dCJ9XX0=';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        DateTimeSampleValue := CreateDateTime(20080101D, 093500T);

        SalesHeader.Reset();
        SalesHeader.SetFilter("Document Type", '%1', SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("No.", '>2000');
        SalesHeader.SetFilter("Your Reference", '%1', 'sample text');
        SalesHeader.SetFilter("Order Date", '>010113D');
        SalesHeader.SetFilter("Payment Discount %", '%1', 10);
        SalesHeader.SetFilter(Comment, '%1', true);
        SalesHeader.SetFilter("Quote Sent to Customer", '%1', DateTimeSampleValue);
        SalesHeader.SetFilter("Job Queue Entry ID", '%1', 'E16655A6-5CD2-400E-9BD5-40E40ED08C61');
        SalesHeader.SetFilter("Incoming Document Entry No.", '%1', 1);
        SalesHeader.SetFilter("Shipping Time", '1W');
        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions.SetView(EventConditions.Name(1), SalesHeader.GetView());

        SalesLine.Reset();
        SalesLine.SetFilter("Price description", '%1', 'sample text');
        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions.SetView(EventConditions.Name(2), SalesLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorSales()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'aRcdNotInvExVatLcy' (exists in Purchase only)
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbXSwiTGluZXNDb25kaXRpb25zIjpbeyJOYW1lIjoiYVJjZE5vdEludkV4VmF0TGN5IiwiVmFsdWUiOiIxMDAifV19';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'aRcdNotInvExVatLcy',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Sales Document Line Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorPurchase()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Purchase Document Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorGenJournalBatch()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Gen. Journal Batch Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorGenJournalLine()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Gen. Journal Line Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorCustomer()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Workflow - Customer Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorItem()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Workflow - Item Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNonexistingControlNameConditionFromOtherDocumentTypeErrorVendor()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        ConditionsInputTxt: Text;
    begin
        // [SCENARIO]
        // User put a bad value for one or more Name parameters (control name that exist for a different event code, but not for this one) in conditions while creating a flow.
        // In this case correct mapping between (non-existing) control name and its id in the source table could not be found.
        // Corresponding error message need to be shown.

        // [GIVEN] Sample of Base64 encoded Conditions input that has Control Name 'quoteAcceptedDate' (exists in Sales Header only)
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoicXVvdGVBY2NlcHRlZERhdGUiLCJWYWx1ZSI6IjAxMDExNyJ9LHsiTmFtZSI6Im51bWJlciIsIlZhbHVlIjoiMTAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are tried to get parsed.
        asserterror
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());

        // [THEN] Verify that error occured and the error message is correct.
        Assert.ExpectedError(
          StrSubstNo(
            WorkflowWebhookSubscription.GetNoControlOnPageErr(), 'quoteAcceptedDate',
            WorkflowWebhookSubscription.GetPageName(PAGE::"Workflow - Vendor Entity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedSales()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a Sales Approval workflow, is does not generate a Purchase/General Journal Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Sales Document Approval (i.e. Purchase Header/Lines or General Jornal Batch/Line do not have such fields).
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiYmlsbFRvQ2l0eSIsIlZhbHVlIjoiQ2l0eSBOYW1lIn1dLCJMaW5lc0NvbmRpdGlvbnMiOlt7Ik5hbWUiOiJzaGlwbWVudERhdGUiLCJWYWx1ZSI6IjAxMDExNiJ9XX0=';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());

        // [THEN] Generate expected results.
        SalesHeader.Reset();
        SalesHeader.SetFilter("Bill-to City", '%1', 'City Name');
        TableMetadata.Get(DATABASE::"Sales Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Header");
        EventConditions.SetView(EventConditions.Name(1), SalesHeader.GetView());

        SalesLine.Reset();
        SalesLine.SetFilter("Shipment Date", '010116');
        TableMetadata.Get(DATABASE::"Sales Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Sales Line");
        EventConditions.SetView(EventConditions.Name(2), SalesLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesDocCategoryTxt(), DATABASE::"Sales Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedPurchase()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a Purchase Approval workflow, is does not generate a Sales/General Journal Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Purchase Document Approval (i.e. Sales Header/Lines or General Jornal Batch/Line do not have such fields).
        ConditionsInputTxt :=
          'eyJIZWFkZXJDb25kaXRpb25zIjpbeyJOYW1lIjoiY3JlZGl0b3JOdW1iZXIiLCJWYWx1ZSI6IjAwMSJ9LHsiTmFtZSI6Im9yZGVyRGF0ZSJ9XSwiTGluZXNDb25kaXRpb25zIjpbeyJOYW1lIjoiYVJjZE5vdEludkV4VmF0TGN5IiwiVmFsdWUiOiIxMDAifV19';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());

        // [THEN] Generate expected results.
        PurchaseHeader.Reset();
        PurchaseHeader.SetFilter("Creditor No.", '%1', '001');
        TableMetadata.Get(DATABASE::"Purchase Header");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Purchase Header");
        EventConditions.SetView(EventConditions.Name(1), PurchaseHeader.GetView());

        PurchaseLine.Reset();
        PurchaseLine.SetFilter("A. Rcd. Not Inv. Ex. VAT (LCY)", '%1', 100);
        TableMetadata.Get(DATABASE::"Purchase Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Purchase Line");
        EventConditions.SetView(EventConditions.Name(2), PurchaseLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetPurchaseDocCategoryTxt(), DATABASE::"Purchase Header");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedGenJournalBatch()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        GenJournalBatch: Record "Gen. Journal Batch";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a General Journal Batch Approval workflow, is does not generate a Sales/Purchase Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Gen. Journal Batch event codes Approvals (i.e. Sales Header/Lines, Purchase Header/Lines or Gen. Journal Lines do not have such fields).
        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoidGVtcGxhdGVUeXBlIiwiVmFsdWUiOiJHZW5lcmFsIn1dfQ==';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());

        // [THEN] Generate expected results.
        GenJournalBatch.Reset();
        GenJournalBatch.SetFilter("Template Type", 'General');
        TableMetadata.Get(DATABASE::"Gen. Journal Batch");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Gen. Journal Batch");
        EventConditions.SetView(EventConditions.Name(1), GenJournalBatch.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetFinCategoryTxt(), DATABASE::"Gen. Journal Batch");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedGenJournalLine()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        GenJournalLine: Record "Gen. Journal Line";
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a General Journal Line Approval workflow, is does not generate a Sales/Purchase Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Gen. Journal Line event codes Approvals (i.e. Sales Header/Lines, Purchase Header/Lines or Gen. Journal Batch do not have such fields).

        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoiZGF0YUV4Y2hMaW5lTnVtYmVyIiwiVmFsdWUiOiIxMDAwIn1dfQ==';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());

        // [THEN] Generate expected results.
        GenJournalLine.Reset();
        GenJournalLine.SetFilter("Data Exch. Line No.", '1000');
        TableMetadata.Get(DATABASE::"Gen. Journal Line");
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::"Gen. Journal Line");
        EventConditions.SetView(EventConditions.Name(1), GenJournalLine.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetFinCategoryTxt(), DATABASE::"Gen. Journal Line");

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedCustomer()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        Customer: Record Customer;
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a Customer Approval workflow, is does not generate a Sales/Purchase Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Customer Approval (i.e. Sales Header/Lines, Purchase Header/Lines, etc. do not have such fields).

        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoic2VhcmNoTmFtZSIsIlZhbHVlIjoibmFtZSB0byBzZWFyY2gifV19';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendCustomerForApprovalCode());

        // [THEN] Generate expected results.
        Customer.Reset();
        Customer.SetFilter("Search Name", 'name to search');
        TableMetadata.Get(DATABASE::Customer);
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::Customer);
        EventConditions.SetView(EventConditions.Name(1), Customer.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesMktCategoryTxt(), DATABASE::Customer);

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedItem()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        Item: Record Item;
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a Item Approval workflow, is does not generate a Sales/Purchase Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Item Approval (i.e. Sales Header/Lines, Purchase Header/Lines, etc. do not have such fields).

        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoiYXNzZW1ibHlCb20iLCJWYWx1ZSI6IlRSVUUifV19';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode());

        // [THEN] Generate expected results.
        Item.Reset();
        Item.SetFilter("Assembly BOM", 'TRUE');
        TableMetadata.Get(DATABASE::Item);
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::Item);
        EventConditions.SetView(EventConditions.Name(1), Item.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetSalesMktCategoryTxt(), DATABASE::Item);

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRightEventCodeGotProcessedVendor()
    var
        WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription";
        Vendor: Record Vendor;
        TableMetadata: Record "Table Metadata";
        EventConditions: FilterPageBuilder;
        ConditionsExpectedTxt: Text;
        ConditionsInputTxt: Text;
        ConditionsResultedTxt: Text;
    begin
        // [SCENARIO]
        // Verify that right request got processed, i.e. when creating a Vendor Approval workflow, is does not generate a Sales/Purchase Approval worflow, for example.

        // [GIVEN] Sample input with conditions unique for Vendor Approval (i.e. Sales Header/Lines, Purchase Header/Lines, etc. do not have such fields).

        ConditionsInputTxt :=
          'eyJDb25kaXRpb25zIjpbeyJOYW1lIjoibnVtYmVyT2ZQc3RkUmVjZWlwdHMiLCJWYWx1ZSI6Ijc1In1dfQ==';

        // [WHEN] Conditions received from Flow are parsed and Conditions XML is generated.
        ConditionsResultedTxt :=
          WorkflowWebhookSubscriptionRec.CreateEventConditions(
            ConditionsInputTxt, WorkflowEventHandling.RunWorkflowOnSendVendorForApprovalCode());

        // [THEN] Generate expected results.
        Vendor.Reset();
        Vendor.SetFilter("No. of Pstd. Receipts", '%1', 75);
        TableMetadata.Get(DATABASE::Vendor);
        EventConditions.AddTable(TableMetadata.Caption, DATABASE::Vendor);
        EventConditions.SetView(EventConditions.Name(1), Vendor.GetView());

        ConditionsExpectedTxt :=
          RequestPageParametersHelper.GetViewFromDynamicRequestPage(
            EventConditions, WorkflowWebhookSetup.GetPurchPayCategoryTxt(), DATABASE::Vendor);

        // [THEN] Compare received and expected results.
        Assert.AreEqual(ConditionsExpectedTxt, ConditionsResultedTxt, ConditionsDoNotAgreeErr);
    end;

    local procedure CreateWorkflowWebhookSubscriptionNoWorkflow()
    begin
        // workflowwebhooksubcription without details needed for workflow definition creation
        CreateTempWorkflowWebhookSubscription(WorkflowWebhookSubscription, DummyConditionsTxt);
    end;

    local procedure CreateWorkflowWebhookSubscriptionAndWorkflow()
    begin
        // workflow is created in addition to worflowwebhook subscription
        CreateTempWorkflowWebhookSubscription(WorkflowWebhookSubscription, DummyConditionsTxt);
        WorkflowWebhookSubscription.Modify(true);
        Commit();
    end;

    local procedure CreateTempWorkflowWebhookSubscription(var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription"; NewConditionsTxt: Text)
    begin
        WorkflowWebhookSubscriptionRec.Init();
        WorkflowWebhookSubscriptionRec."Client Type" := DummyClientTypeTxt;
        WorkflowWebhookSubscriptionRec."Client Id" := DummyClientIdTxt;
        WorkflowWebhookSubscriptionRec."Event Code" := WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode();
        WorkflowWebhookSubscriptionRec.SetConditions(NewConditionsTxt);
        WorkflowWebhookSubscriptionRec.SetNotificationUrl(DummyNotificationUrlTxt);
        WorkflowWebhookSubscriptionRec.Insert(true);
        Commit();
    end;

    local procedure CreateSalesOrderAndSendForApproval()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // Create sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(5000, 10000));
        SalesLine.Modify(true);

        // Send for approval
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SendApprovalRequest.Invoke();
        SalesOrder.Close();

        // Verify that sales order is pending approval
        SalesHeader.SetRecFilter();
        SalesHeader.FindFirst();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");
        Commit();
    end;

    local procedure VerifyWorkflowWebhookSubscriptionNoWorkflowProperties(WorkflowWebhookSubscriptionJSON: Text; var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription")
    begin
        Assert.AreNotEqual('', WorkflowWebhookSubscriptionJSON, EmptyJSONErr);
        VerifyPropertyInJSON(
          WorkflowWebhookSubscriptionJSON, 'clientId', LowerCase(Format(WorkflowWebhookSubscriptionRec."Client Id", 0, 4)));
        VerifyPropertyInJSON(WorkflowWebhookSubscriptionJSON, 'clientType', WorkflowWebhookSubscriptionRec."Client Type");
        VerifyPropertyInJSON(WorkflowWebhookSubscriptionJSON, 'eventCode', WorkflowWebhookSubscriptionRec."Event Code");
        VerifyPropertyInJSON(WorkflowWebhookSubscriptionJSON, 'conditions', WorkflowWebhookSubscriptionRec.GetConditions());
        VerifyPropertyInJSON(WorkflowWebhookSubscriptionJSON, 'notificationUrl', WorkflowWebhookSubscriptionRec.GetNotificationUrl());
    end;

    local procedure VerifyPropertyInJSON(JSON: Text; PropertyName: Text; ExpectedValue: Text)
    var
        PropertyValue: Text;
    begin
        LibraryGraphMgt.GetObjectIDFromJSON(JSON, PropertyName, PropertyValue);
        Assert.AreEqual(ExpectedValue, PropertyValue, StrSubstNo(WrongPropertyValueErr, PropertyName));
    end;

    [Normal]
    local procedure CreateTargetURL(ID: Text; PageNumber: Integer; ServiceNameTxt: Text): Text
    var
        TargetURL: Text;
        ReplaceWith: Text;
    begin
        TargetURL := GetODataV4TargetURL(PageNumber);
        if ID <> '' then begin
            ReplaceWith := StrSubstNo('%1(%2)', ServiceNameTxt, ID);
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    local procedure GetODataV4TargetURL(PageNumber: Integer) OdataV4Url: Text
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        TenantWebService.SetRange("Object ID", PageNumber);
        TenantWebService.SetRange(Published, true);
        TenantWebService.FindFirst();

        OdataV4Url := GetUrl(CLIENTTYPE::ODataV4, CompanyName, OBJECTTYPE::Page, PageNumber);
    end;

    local procedure GetJSONFromWorkflowWebhookSubscription(var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription") WorkflowWebhookSubscriptionJSON: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(
          JsonObject, 'clientId', LowerCase(Format(WorkflowWebhookSubscriptionRec."Client Id", 0, 4)));
        JSONManagement.AddJPropertyToJObject(JsonObject, 'clientType', WorkflowWebhookSubscriptionRec."Client Type");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'eventCode', WorkflowWebhookSubscriptionRec."Event Code");
        JSONManagement.AddJPropertyToJObject(JsonObject, 'conditions', WorkflowWebhookSubscriptionRec.GetConditions());
        JSONManagement.AddJPropertyToJObject(JsonObject, 'notificationUrl', WorkflowWebhookSubscriptionRec.GetNotificationUrl());

        WorkflowWebhookSubscriptionJSON := JSONManagement.WriteObjectToString();
    end;

    local procedure MockDeleteFromWebService(var WorkflowWebhookSubscriptionRec: Record "Workflow Webhook Subscription"): Text
    begin
        // When we make an actual delete call to the odata web service, we are unable to use our boundsubscription function for the event
        // published in the OnDelete trigger in WorkflowWebhookSubscription table, since a new session is opened for that web service call.
        // We therefore mock the Delete call to the webservice
        if not WorkflowWebhookSubscriptionRec.Delete(true) then
            exit('ERROR');
    end;

    [Normal]
    local procedure STRREPLACE(String: Text; ReplaceWhat: Text; ReplaceWith: Text): Text
    begin
        String := DelStr(String, StrPos(String, ReplaceWhat)) +
          ReplaceWith + CopyStr(String, StrPos(String, ReplaceWhat) + StrLen(ReplaceWhat));
        exit(String);
    end;
}

