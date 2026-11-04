codeunit 139921 "APIV2 - Workflows E2E"
{

    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        ServiceNameTxt: Label 'workflows', Locked = true;


    [Test]
    [HandlerFunctions('LocalServerRequestHandler')]
    procedure TestGetApprovalEntries()
    var
        Workflow: Record Workflow;
        WorkflowId: Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Check that workflows can be retrieved via API
        // [GIVEN] A workflow exists
        LibraryWorkflow.CreateWorkflow(Workflow);
        WorkFlowId := Format(Workflow.SystemId);
        Commit();

        // [WHEN] we GET the entry from the web service
        ClearLastError();
        TargetURL := LibraryGraphMgt.CreateTargetURL(WorkFlowId, Page::"APIV2 - Workflows", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] entry should exist in the response
        if GetLastErrorText() <> '' then
            Assert.ExpectedError('Request failed with error: ' + GetLastErrorText());

        Assert.IsTrue(LibraryGraphMgt.GetObjectIDFromJSON(ResponseText, 'id', WorkFlowId), 'Could not find workflow');
    end;

    [HttpClientHandler]
    internal procedure LocalServerRequestHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Assert.IsTrue(LibraryGraphMgt.IsLocalServerRequest(Request), 'Only requests to the local Business Central server are allowed.');
        exit(true);
    end;
}