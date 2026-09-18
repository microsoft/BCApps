// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139494 "API Test Auth Provider Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API Test Authentication]
    end;

    var
        Assert: Codeunit Assert;
        APITestAuthRecorder: Codeunit "API Test Auth Recorder";
        APITestAuthProviderTests: Codeunit "API Test Auth Provider Tests";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        WebServiceManagement: Codeunit "Web Service Management";
        SecondLibraryGraphMgt: Codeunit "Library - Graph Mgt";
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        IsInitialized: Boolean;
        TargetURLTok: Label 'http://127.0.0.1/', Locked = true;
        ProviderCallTok: Label 'Provider|%1', Locked = true;
        EventCallTok: Label 'Event', Locked = true;
        UnexpectedCallErr: Label 'Unexpected authentication call.';

    [Test]
    procedure DefaultAuthenticationDoesNotConfigureRequest()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The default API test authentication does not configure the request
        Initialize();

        // [GIVEN] A Graph library instance without an explicitly selected provider

        // [WHEN] A web request is initialized
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the final request event is raised
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure ExtendedAuthenticationProviderRunsBeforeFinalEvent()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An enum extension can provide API test authentication
        Initialize();

        // [GIVEN] A Graph library instance using the mock authentication provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);

        // [WHEN] A web request is initialized
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);

        // [THEN] The selected provider configures authentication
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1));

        // [THEN] The final request event runs after the provider
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure AuthenticationProviderInstanceIsReused()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A selected authentication provider instance is reused across requests
        Initialize();

        // [GIVEN] A Graph library instance using the mock authentication provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);

        // [WHEN] Two web requests are initialized through the same Graph library instance
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);
        LibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURLTok);

        // [THEN] The same provider instance handles both requests
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1));
        VerifyNextCall(EventCallTok);
        VerifyNextCall(StrSubstNo(ProviderCallTok, 2));
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure AuthenticationProviderSelectionIsInstanceScoped()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Authentication provider selection is scoped to a Graph library instance
        Initialize();

        // [GIVEN] Two Graph library instances where only the first uses the mock provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);

        // [WHEN] Each Graph library instance initializes a web request
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);
        SecondLibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the first request uses the mock provider
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1));
        VerifyNextCall(EventCallTok);
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure RepeatedProviderSelectionPreservesInstance()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Repeated initialization with the same provider preserves its state
        Initialize();

        // [GIVEN] A request has used the selected provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);

        // [WHEN] Initialization selects the same provider before another request
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);
        LibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURLTok);

        // [THEN] The provider instance retains its invocation count
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1));
        VerifyNextCall(EventCallTok);
        VerifyNextCall(StrSubstNo(ProviderCallTok, 2));
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure SelectingNoneStopsConfiguringRequests()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Selecting None replaces the previously selected provider
        Initialize();

        // [GIVEN] A request has used the mock provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);

        // [WHEN] Authentication is deselected before another request
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);
        LibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the first request invokes the mock provider
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1));
        VerifyNextCall(EventCallTok);
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure EmptySubpagesPreserveTargetURL()
    var
        ExpectedURL: Text;
        ActualURL: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Empty subpage segments do not append a slash to the original URL
        Initialize();

        // [GIVEN] A published page with its original target URL
        ExpectedURL := CreatePageTargetURL();

        // [WHEN] Neither subpage segment nor subpage ID is supplied
        ActualURL := LibraryGraphMgt.CreateTargetURLWithTwoSubpages('', '', Page::"Customer List", '', '', '');

        // [THEN] The original URL is unchanged
        Assert.AreEqual(ExpectedURL, ActualURL, 'Empty subpages must preserve the original URL.');
    end;

    [Test]
    procedure EmptyFirstSubpageDoesNotAddExtraSlash()
    var
        ExpectedURL: Text;
        ActualURL: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An empty first subpage does not add a slash before the second subpage
        Initialize();

        // [GIVEN] A published page followed by the second subpage only
        ExpectedURL := LibraryGraphMgt.AppendPathToTargetURL(CreatePageTargetURL(), '/attachments');

        // [WHEN] Only the second subpage segment is supplied
        ActualURL := LibraryGraphMgt.CreateTargetURLWithTwoSubpages('', '', Page::"Customer List", '', '', 'attachments');

        // [THEN] There is only one separator before the second subpage
        Assert.AreEqual(ExpectedURL, ActualURL, 'An empty first subpage must not add a path separator.');
    end;

    [Test]
    procedure TwoSubpagesPreserveSegmentsAndIdentifier()
    var
        ExpectedURL: Text;
        ActualURL: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Both subpage segments and the bracket-free subpage ID precede any query
        Initialize();

        // [GIVEN] A published page followed by two subpages and a subpage ID
        ExpectedURL := LibraryGraphMgt.AppendPathToTargetURL(
            CreatePageTargetURL(), '/lines(11111111-1111-1111-1111-111111111111)/attachments');

        // [WHEN] Both subpages and a bracketed subpage ID are supplied
        ActualURL := LibraryGraphMgt.CreateTargetURLWithTwoSubpages(
            '', '{11111111-1111-1111-1111-111111111111}', Page::"Customer List", '', 'lines', 'attachments');

        // [THEN] Both segments and the stripped ID are preserved
        Assert.AreEqual(ExpectedURL, ActualURL, 'Subpage segments and IDs must precede the query.');
    end;

    [Test]
    procedure SubpagePathPrecedesExistingQuery()
    var
        ActualURL: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Appending a subpage path preserves the query after the entire path
        Initialize();

        // [GIVEN] A URL with an existing tenant and filter query
        ActualURL := 'http://127.0.0.1/customers?tenant=test&$filter=active';

        // [WHEN] Two subpage segments are appended
        ActualURL := LibraryGraphMgt.AppendPathToTargetURL(ActualURL, '/lines(1)/attachments');

        // [THEN] The original query follows the complete subpage path unchanged
        Assert.AreEqual(
            'http://127.0.0.1/customers/lines(1)/attachments?tenant=test&$filter=active',
            ActualURL, 'Appending subpages must preserve the query after the path.');
    end;

    [Test]
    procedure SubpagePathWithoutQueryPreservesSegments()
    var
        ActualURL: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Appending subpages to a URL without a query preserves all path segments
        Initialize();

        // [GIVEN] A URL without a query
        ActualURL := 'http://127.0.0.1/customers';

        // [WHEN] Two subpage segments are appended
        ActualURL := LibraryGraphMgt.AppendPathToTargetURL(ActualURL, '/lines(1)/attachments');

        // [THEN] Both subpages follow the original path without a query separator
        Assert.AreEqual(
            'http://127.0.0.1/customers/lines(1)/attachments',
            ActualURL, 'Appending subpages must not add a query separator.');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryGraphMgt);
        Clear(SecondLibraryGraphMgt);
        Clear(FirstHttpWebRequestMgt);
        Clear(SecondHttpWebRequestMgt);
        APITestAuthRecorder.Reset();
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthProviderTests);
        IsInitialized := true;
    end;

    local procedure CreatePageTargetURL(): Text
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        WebServiceManagement.CreateTenantWebService(
            TenantWebService."Object Type"::Page, Page::"Customer List", LibraryUtility.GenerateGUID(), true);
        exit(LibraryGraphMgt.CreateTargetURL('', Page::"Customer List", ''));
    end;

    local procedure VerifyNextCall(ExpectedCall: Text)
    begin
        Assert.AreEqual(ExpectedCall, APITestAuthRecorder.DequeueCall(), UnexpectedCallErr);
    end;

    local procedure VerifyNoRemainingCalls()
    begin
        Assert.AreEqual(0, APITestAuthRecorder.Count(), UnexpectedCallErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", OnAfterInitializeWebRequestWithURL, '', false, false)]
    local procedure RecordFinalRequestEvent(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        APITestAuthRecorder.RecordCall(EventCallTok);
    end;
}
