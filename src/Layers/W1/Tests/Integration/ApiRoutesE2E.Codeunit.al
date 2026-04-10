codeunit 135548 "API Routes E2E"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API] [Route]
    end;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        ApiRoutesTxt: Label 'apiRoutes', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetApiRoutesMany()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns many routes in the payload
        // [GIVEN] apiRoutes URI without filters
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"API Routes", ApiRoutesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains routes
        Assert.IsTrue(StrPos(ResponseText, '"route":') > 0, 'Response does not contain routes');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetApiRoutesSingle()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] GET returns a single route in the payload
        // [GIVEN] apiRoutes URI for a single route
        TargetURL := LibraryGraphMgt.CreateTargetURL('''beta''', PAGE::"API Routes", ApiRoutesTxt);

        // [WHEN] User sends a GET request
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Response code is 200 and response body contains the specified route
        Assert.IsTrue(StrPos(ResponseText, '"beta"') > 0, 'Route "beta" is not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostApiRoutesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] POST is not allowed for apiRoutes
        // [GIVEN] apiRoutes URI for a single route
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"API Routes", ApiRoutesTxt);

        // [WHEN] User send a POST request
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '{"route":"new"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPatchApiRoutesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] PATCH is not allowed for apiRoutes
        // [GIVEN] apiRoutes URI for a single route
        TargetURL := LibraryGraphMgt.CreateTargetURL('''beta''', PAGE::"API Routes", ApiRoutesTxt);

        // [WHEN] User send a PATCH request
        asserterror LibraryGraphMgt.PatchToWebServiceAndCheckResponseCode(TargetURL, '{"route":"changed"}', ResponseText, 405);

        // [THEN] Expecting response code 405
        Assert.ExpectedError('405 (MethodNotAllowed)');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteApiRoutesNotAllowed()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] DELETE is not allowed for apiRoutes
        // [GIVEN] apiRoutes URI for a single route
        TargetURL := LibraryGraphMgt.CreateTargetURL('''beta''', PAGE::"API Routes", ApiRoutesTxt);

        // [WHEN] User send a DELETE request
        asserterror LibraryGraphMgt.DeleteFromWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 400);

        // [THEN] Expecting response code 400
        Assert.ExpectedError('400 (BadRequest)');
    end;
}

