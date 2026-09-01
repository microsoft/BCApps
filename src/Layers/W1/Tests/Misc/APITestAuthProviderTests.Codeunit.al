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
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        APITestAuthProviderTests: Codeunit "API Test Auth Provider Tests";
        IsInitialized: Boolean;
        TargetURLTok: Label 'http://127.0.0.1/', Locked = true;
        RewrittenTargetURLTok: Label 'http://127.0.0.2/', Locked = true;
        ProviderCallTok: Label 'Provider|%1|%2', Locked = true;
        EventCallTok: Label 'Event|%1', Locked = true;
        UnexpectedCallErr: Label 'Unexpected authentication call.';

    [Test]
    procedure DefaultAuthenticationDoesNotConfigureRequest()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] The default API test authentication does not configure the request
        Initialize();

        // [GIVEN] A Graph library instance without an explicitly selected provider

        // [WHEN] A web request is initialized
        LibraryGraphMgt.InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the final request event is raised
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure ExtendedAuthenticationProviderReceivesRewrittenURL()
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An enum extension can provide API test authentication
        Initialize();

        // [GIVEN] A Graph library instance using the mock authentication provider
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);

        // [WHEN] A web request is initialized and its URL is rewritten
        LibraryGraphMgt.InitializeWebRequestWithURL(HttpWebRequestMgt, TargetURLTok);

        // [THEN] The provider receives the rewritten URL
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1, RewrittenTargetURLTok));

        // [THEN] The final request event runs after the provider
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure AuthenticationProviderInstanceIsReused()
    var
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
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
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1, RewrittenTargetURLTok));
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNextCall(StrSubstNo(ProviderCallTok, 2, RewrittenTargetURLTok));
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNoRemainingCalls();
    end;

    [Test]
    procedure AuthenticationProviderSelectionIsInstanceScoped()
    var
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        FirstLibraryGraphMgt: Codeunit "Library - Graph Mgt";
        SecondLibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Authentication provider selection is scoped to a Graph library instance
        Initialize();

        // [GIVEN] Two Graph library instances where only the first uses the mock provider
        FirstLibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::Mock);

        // [WHEN] Each Graph library instance initializes a web request
        FirstLibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURLTok);
        SecondLibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURLTok);

        // [THEN] Only the first request uses the mock provider
        VerifyNextCall(StrSubstNo(ProviderCallTok, 1, RewrittenTargetURLTok));
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNextCall(StrSubstNo(EventCallTok, RewrittenTargetURLTok));
        VerifyNoRemainingCalls();
    end;

    local procedure Initialize()
    begin
        APITestAuthRecorder.Reset();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        if IsInitialized then
            exit;

        BindSubscription(APITestAuthProviderTests);
        IsInitialized := true;
    end;

    local procedure VerifyNextCall(ExpectedCall: Text)
    begin
        Assert.AreEqual(ExpectedCall, APITestAuthRecorder.DequeueCall(), UnexpectedCallErr);
    end;

    local procedure VerifyNoRemainingCalls()
    begin
        Assert.AreEqual(0, APITestAuthRecorder.Count(), UnexpectedCallErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Http Web Request Mgt.", OnOverrideUrl, '', false, false)]
    local procedure RewriteTargetURL(var URL: Text)
    begin
        URL := RewrittenTargetURLTok;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Library - Graph Mgt", OnAfterInitializeWebRequestWithURL, '', false, false)]
    local procedure RecordFinalRequestEvent(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        APITestAuthRecorder.RecordCall(StrSubstNo(EventCallTok, HttpWebRequestMgt.GetUrl()));
    end;
}
