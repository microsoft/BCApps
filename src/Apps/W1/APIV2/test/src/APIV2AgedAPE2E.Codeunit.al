codeunit 139819 "APIV2 - Aged AP E2E"
{
    // version Test,ERM,W1,All

    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Purchase] [Aged Report]
    end;

    var
        Assert: Codeunit "Assert";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        ServiceNameTxt: Label 'agedAccountsPayable';

    [Test]
    [HandlerFunctions('LocalServerRequestHandler')]
    procedure TestGetAgedAPRecords()
    var
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] User can retrieve Aged Accounts Payable Report information from the agedAccountsPayable API.
        Initialize();

        // [WHEN] A GET request is made to the agedAccountsPayable API.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Aged AP", ServiceNameTxt);

        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response is empty.
        Assert.AreNotEqual('', ResponseText, 'GET response must not be empty.');
    end;

    [Test]
    [HandlerFunctions('LocalServerRequestHandler')]
    procedure TestCreateAgedAPRecord()
    var
        TempAgedReportEntity: Record "Aged Report Entity" temporary;
        AgedReportEntityJSON: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Create a agedAccountsPayable record through a POST method and check if it was created
        Initialize();

        // [GIVEN] The user has constructed a agedAccountsPayable JSON object to send to the service.
        AgedReportEntityJSON := GetAgedAPJSON(TempAgedReportEntity);

        // [WHEN] The user posts the JSON to the service.
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"APIV2 - Aged AP", ServiceNameTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, AgedReportEntityJSON, ResponseText);

        // [THEN] The response is empty.
        Assert.AreEqual('', ResponseText, 'CREATE response must be empty.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryApplicationArea.EnableFoundationSetup();
        IsInitialized := true;
    end;

    local procedure GetAgedAPJSON(var AgedReportEntity: Record "Aged Report Entity") AgedReportEntityJSON: Text
    begin
        if AgedReportEntity."No." = '' then
            AgedReportEntity."No." := LibraryUtility.GenerateRandomCode(AgedReportEntity.FieldNo("No."), Database::"Aged Report Entity");

        AgedReportEntityJSON := LibraryGraphMgt.AddPropertytoJSON('', 'vendorNumber', AgedReportEntity."No.");
    end;

    [HttpClientHandler]
    procedure LocalServerRequestHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Assert.IsTrue(LibraryGraphMgt.IsLocalServerRequest(Request), 'Only requests to the local Business Central server are allowed.');
        exit(true);
    end;
}








