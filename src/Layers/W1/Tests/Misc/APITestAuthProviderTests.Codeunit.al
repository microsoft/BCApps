// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

using System.Environment;
using System.Security.AccessControl;

codeunit 139494 "API Test Auth Provider Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    RequiredTestIsolation = Disabled;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API Test Authentication]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        APITestAuthProviderTests: Codeunit "API Test Auth Provider Tests";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryUtility: Codeunit "Library - Utility";
        WebServiceManagement: Codeunit "Web Service Management";
        IdentityManagement: Codeunit "Identity Management";
        SecondLibraryGraphMgt: Codeunit "Library - Graph Mgt";
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        IsInitialized: Boolean;
        TargetURLTok: Label 'http://127.0.0.1/', Locked = true;
        ProviderCallTok: Label 'Provider|%1', Locked = true, Comment = '%1 - Provider invocation number';
        EventCallTok: Label 'Event', Locked = true;
        UnexpectedCallErr: Label 'Unexpected authentication call.';
        ForcedRollbackErr: Label 'Roll back the API authentication fixture.';

    [Test]
    [NonDebuggable]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingKeyIsCommittedBeforeHttpRequest()
    var
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] First-use authentication creates a key visible to the independent HTTP session
        Initialize();

        // [GIVEN] The disposable test user's key is missing at a committed fixture boundary
        IdentityManagement.ClearWebServicesKey(UserSecurityId());
        Commit();
        TargetURL := GetUrl(ClientType::ODataV4);

        // [WHEN] A request uses the default provider without explicit selection
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The request authenticates and only NavUserPassword requires a generated key
        VerifyKeyPresenceForServerMode();
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    [NonDebuggable]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ExistingKeySurvivesLibraryReset()
    var
        ExistingKey: Text[80];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A committed non-expiring key is reused across Graph library instances
        Initialize();

        // [GIVEN] The disposable test user has a committed key without an expiry
        ExistingKey := IdentityManagement.CreateWebServicesKeyNoExpiry(UserSecurityId());
        Commit();
        TargetURL := GetUrl(ClientType::ODataV4);

        // [WHEN] Two independently initialized library instances authenticate
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);
        Clear(LibraryGraphMgt);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Neither the key nor its expiry is changed
        VerifyExistingKey(ExistingKey);
        Clear(ExistingKey);
        VerifyNextCall(EventCallTok);
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    [NonDebuggable]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MissingKeyDoesNotCommitFixture()
    var
        CurrentUser: Record User;
        OriginalFullName: Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Missing-key authentication cannot commit unrelated changes to user U
        Initialize();

        // [GIVEN] User U has no key and an uncommitted fixture change
        IdentityManagement.ClearWebServicesKey(UserSecurityId());
        Commit();
        CurrentUser.Get(UserSecurityId());
        OriginalFullName := CurrentUser."Full Name";
        CurrentUser."Full Name" := 'API authentication rollback fixture';
        CurrentUser.Modify();

        // [WHEN] Authentication rejects unsafe first use, or ambient authentication reaches the forced rollback
        asserterror InitializeRequestAndFail();

        // [THEN] The expected error leaves neither a committed fixture nor a newly created key
        Assert.ExpectedError(GetExpectedFixtureError());
        Assert.ExpectedErrorCode('Dialog');
        CurrentUser.Get(UserSecurityId());
        Assert.IsTrue(CurrentUser."Full Name" = OriginalFullName, 'Authentication must not commit the user fixture.');
        Assert.IsTrue(GetCurrentWebServiceKey() = '', 'Unsafe first use must not create a key.');
        VerifyFixtureRequestCalls();
        VerifyNoRemainingCalls();
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure DefaultAuthenticationRespectsServerAuthMode()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Default authentication uses the current user's committed key or ambient Windows credentials
        Initialize();

        // [GIVEN] An OnPrem service and a read-only test method with no fixture transaction to commit
        Assert.IsFalse(EnvironmentInfo.IsSaaSInfrastructure(), 'This HTTP scenario requires an OnPrem test environment.');
        TargetURL := GetUrl(ClientType::ODataV4);

        // [WHEN] The default provider sends a request without explicit provider selection
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Authentication completes before the independent HTTP session reads the key
        VerifyNextCall(EventCallTok);

        // [WHEN] A fresh library instance sends another request
        Clear(LibraryGraphMgt);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] Authentication does not depend on an instance-local credential cache
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure ExplicitNoneDoesNotConfigureRequest()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Explicit None retains ambient authentication without resolving the default provider
        Initialize();

        // [GIVEN] A Graph library instance with authentication explicitly disabled
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);

        // [WHEN] A web request is initialized
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the final request event is raised
        VerifyNextCall(EventCallTok);
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure ExtendedAuthenticationProviderRunsBeforeFinalEvent()
    begin
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
        // [SCENARIO] Authentication provider selection is scoped to a Graph library instance
        Initialize();

        // [GIVEN] Two Graph library instances with different explicit providers
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);
        SecondLibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);

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
        // The manually bound instance owns both recording and verification, including cleanup after a failed test.
        APITestAuthProviderTests.ClearRecordedCalls();
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

    [NonDebuggable]
    local procedure GetCurrentWebServiceKey(): Text[80]
    var
        WebServiceKey: Text[80];
    begin
        ClearLastError();
        WebServiceKey := IdentityManagement.GetWebServicesKey(UserSecurityId());
        Assert.IsTrue(GetLastErrorText() = '', 'The current user key must be readable.');
        exit(WebServiceKey);
    end;

    [NonDebuggable]
    local procedure VerifyKeyPresenceForServerMode()
    begin
        Assert.AreEqual(
            IdentityManagement.IsUserNamePasswordAuthentication(), GetCurrentWebServiceKey() <> '',
            'Only NavUserPassword authentication should provision a key for the request.');
    end;

    [NonDebuggable]
    local procedure VerifyExistingKey(ExistingKey: Text[80])
    begin
        Assert.IsTrue(ExistingKey = GetCurrentWebServiceKey(), 'Authentication must not rotate an existing key.');
        Assert.AreEqual(0DT, IdentityManagement.GetWebServiceExpiryDate(UserSecurityId()), 'A non-expiring key must stay non-expiring.');
    end;

    local procedure InitializeRequestAndFail()
    begin
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);
        Error(ForcedRollbackErr);
    end;

    local procedure GetExpectedFixtureError(): Text
    begin
        if IdentityManagement.IsUserNamePasswordAuthentication() then
            exit('The API test web service key is missing and cannot be created while the caller has uncommitted writes.');
        exit(ForcedRollbackErr);
    end;

    local procedure VerifyFixtureRequestCalls()
    begin
        if not IdentityManagement.IsUserNamePasswordAuthentication() then
            VerifyNextCall(EventCallTok);
    end;

    local procedure VerifyNextCall(ExpectedCall: Text)
    begin
        APITestAuthProviderTests.VerifyRecordedCall(ExpectedCall);
    end;

    local procedure VerifyNoRemainingCalls()
    begin
        APITestAuthProviderTests.VerifyRecordedCallsEmpty();
    end;

    internal procedure ClearRecordedCalls()
    begin
        LibraryVariableStorage.Clear();
    end;

    internal procedure VerifyRecordedCall(ExpectedCall: Text)
    begin
        Assert.AreEqual(ExpectedCall, LibraryVariableStorage.DequeueText(), UnexpectedCallErr);
    end;

    internal procedure VerifyRecordedCallsEmpty()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mock API Test Auth Provider", OnAfterConfigureAuthentication, '', false, false)]
    local procedure RecordProviderInvocation(InvocationNumber: Integer)
    begin
        LibraryVariableStorage.Enqueue(StrSubstNo(ProviderCallTok, InvocationNumber));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", OnAfterInitializeWebRequestWithURL, '', false, false)]
    local procedure RecordFinalRequestEvent(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        LibraryVariableStorage.Enqueue(EventCallTok);
    end;
}
