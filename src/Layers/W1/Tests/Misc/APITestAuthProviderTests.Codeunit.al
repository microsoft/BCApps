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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        APITestAuthProviderTests: Codeunit "API Test Auth Provider Tests";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        SecondLibraryGraphMgt: Codeunit "Library - Graph Mgt";
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        IsInitialized: Boolean;
        TargetURLTok: Label 'http://127.0.0.1/', Locked = true;
        ProviderCallTok: Label 'Provider|%1', Locked = true, Comment = '%1 - Provider invocation number';
        EventCallTok: Label 'Event', Locked = true;
        UnexpectedCallErr: Label 'Unexpected authentication call.';

    [Test]
    procedure DefaultAuthenticationDoesNotConfigureRequest()
    begin
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mock API Test Auth Provider", OnAuthenticationConfigured, '', false, false)]
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
