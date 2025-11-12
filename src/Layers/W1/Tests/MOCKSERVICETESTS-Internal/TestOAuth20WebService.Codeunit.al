codeunit 134781 "Test OAuth 2.0 WebService"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [OAuth 2.0] [Web Service]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AuthRequiredNotificationMsg: Label 'Choose the Request Authorization Code action to complete the authorization process.';
        RefreshSuccessfulTxt: Label 'Refresh token successful.';
        RefreshFailedTxt: Label 'Refresh token failed.';
        AuthorizationSuccessfulTxt: Label 'Authorization successful.';
        AuthorizationFailedTxt: Label 'Authorization failed.';
        ReasonTxt: Label 'Reason: ';
        RequestAccessTokenTxt: Label 'Request access token.', Locked = true;
        RefreshAccessTokenTxt: Label 'Refresh access token.', Locked = true;
        InvokeRequestTxt: Label 'Invoke %1 request.', Locked = true, Comment = '%1 - request type, e.g. GET, POST';
        LimitExceededTxt: Label 'Http daily request limit is exceeded.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with success result
        // MockServicePacket237 MockService\OAuth20\200_authorize.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket237', '');

        Assert.IsTrue(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        Assert.AreEqual(AuthorizationSuccessfulTxt, MessageText, '');
        Assert.AreEqual('123', AccessToken, '');
        Assert.AreEqual('456', RefreshToken, '');

        VerifyHttpLog(OAuth20Setup, TRUE, RequestAccessTokenTxt, AuthorizationSuccessfulTxt);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Failure_Reason()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
        Reason: Text;
        ExpectedMessage: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with failure result (reason)
        // MockServicePacket235 MockService\OAuth20\400_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket235', '');
        Reason := 'HTTP error 400 (Bad Request)';
        ExpectedMessage := STRSUBSTNO('%1\%2%3', AuthorizationFailedTxt, ReasonTxt, Reason);

        Assert.IsFalse(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        Assert.AreEqual(ExpectedMessage, MessageText, ''); // Authorization failed. Reason: ...
        Assert.AreEqual('', AccessToken, '');
        Assert.AreEqual('', RefreshToken, '');

        VerifyHttpLog(OAuth20Setup, false, RequestAccessTokenTxt, ExpectedMessage);
        VerifyHttpLogWithOnlyRequestMaskedDetails(OAuth20Setup, 'POST', 400, 'Bad Request');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Failure_Parsing_Blanked()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with failure result (parsing blanked response)
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket236', '');

        Assert.IsFalse(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRequestAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLog(OAuth20Setup, false, RequestAccessTokenTxt, AuthorizationFailedTxt);
        VerifyHttpLogWithOnlyRequestMaskedDetails(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Failure_Parsing_Wrong()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with failure result (parsing wrong response)
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket238', '');

        Assert.IsFalse(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRequestAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLog(OAuth20Setup, false, RequestAccessTokenTxt, AuthorizationFailedTxt);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Failure_Parsing_Partial_OnlyAccessToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with failure result (parsing partial response, only access token)
        // MockServicePacket239 MockService\OAuth20\200_authorize_onlyaccesstoken.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket239', '');

        Assert.IsFalse(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRequestAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLog(OAuth20Setup, false, RequestAccessTokenTxt, AuthorizationFailedTxt);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequestAccessToken_Failure_Parsing_Partial_OnlyRefreshToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Request Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RequestAccessToken() with failure result (parsing partial response, only refresh token)
        // MockServicePacket240 MockService\OAuth20\200_authorize_onlyrefreshtoken.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket240', '');

        Assert.IsFalse(InvokeRequestAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRequestAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLog(OAuth20Setup, false, RequestAccessTokenTxt, AuthorizationFailedTxt);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with success result
        // MockServicePacket237 MockService\OAuth20\200_authorize.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket237', '');

        Assert.IsTrue(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        Assert.AreEqual(RefreshSuccessfulTxt, MessageText, '');
        Assert.AreEqual('123', AccessToken, '');
        Assert.AreEqual('456', RefreshToken, '');

        VerifyHttpLog(OAuth20Setup, TRUE, RefreshAccessTokenTxt, RefreshSuccessfulTxt);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Failure_Reason()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
        Reason: Text;
        ExpetedMessage: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with failure result (reason)
        // MockServicePacket235 MockService\OAuth20\400_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket235', '');
        Reason := 'HTTP error 400 (Bad Request)';
        ExpetedMessage := STRSUBSTNO('%1\%2%3', RefreshFailedTxt, ReasonTxt, Reason);

        Assert.IsFalse(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        Assert.AreEqual(ExpetedMessage, MessageText, ''); // Refresh token failed. Reason: ...
        Assert.AreEqual('', AccessToken, '');
        Assert.AreEqual('', RefreshToken, '');

        VerifyHttpLog(OAuth20Setup, false, RefreshAccessTokenTxt, ExpetedMessage);
        VerifyHttpLogWithOnlyRequestMaskedDetails(OAuth20Setup, 'POST', 400, 'Bad Request');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Failure_Parsing_Blanked()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with failure result (parsing blanked response)
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket236', '');

        Assert.IsFalse(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRefreshAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLogWithOnlyRequestMaskedDetails(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Failure_Parsing_Wrong()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with failure result (parsing wrong response)
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket238', '');

        Assert.IsFalse(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRefreshAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Failure_Parsing_Partial_OnlyAccessToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with failure result (parsing partial response, only access token)
        // MockServicePacket239 MockService\OAuth20\200_authorize_onlyaccesstoken.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket239', '');

        Assert.IsFalse(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRefreshAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshAccessToken_Failure_Parsing_Partial_OnlyRefreshToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        MessageText: Text;
        AccessToken: Text;
        RefreshToken: Text;
    begin
        // [FEATURE] [Refresh Access Token]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".RefreshAccessToken() with failure result (parsing partial response, only refresh token)
        // MockServicePacket240 MockService\OAuth20\200_authorize_onlyrefreshtoken.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket240', '');

        Assert.IsFalse(InvokeRefreshAccessToken(OAuth20Setup, MessageText, AccessToken, RefreshToken), '');

        VerifyFailureResponseOnRefreshAccessToken(MessageText, AccessToken, RefreshToken);
        VerifyHttpLogWithMaskedContents(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_FromCOD_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".InvokeRequest() with success result
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket238');

        Assert.IsTrue(InvokeRequestFromCOD(OAuth20Setup, GetRequestJsonTestString('POST'), ResponseJson, HttpError), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.AreEqual('', HttpError, '');

        VerifyHttpLog(OAuth20Setup, TRUE, STRSUBSTNO(InvokeRequestTxt, 'POST'), '');
        VerifyHttpLogWithRequestAndResponseDetails(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_FromTAB_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() with success result
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket238');

        Assert.IsTrue(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, false), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.AreEqual('', HttpError, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_Success_BlankedRequest()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        JToken: JsonToken;
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".InvokeRequest() with success result, blanked request
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket238');

        Assert.IsTrue(InvokeRequestFromCOD(OAuth20Setup, '{"Method":"GET"}', ResponseJson, HttpError), '');

        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        AssertBlankedJsonValue(JToken, 'Request.Content');
        Assert.AreEqual('', HttpError, '');

        VerifyHttpLog(OAuth20Setup, TRUE, STRSUBSTNO(InvokeRequestTxt, 'GET'), '');
        VerifyHttpLogWithOnlyResponseDetails(OAuth20Setup, 'GET', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_Success_BlankedResponse()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        JToken: JsonToken;
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".InvokeRequest() with success result, blanked response
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');

        Assert.IsTrue(InvokeRequestFromCOD(OAuth20Setup, GetRequestJsonTestString('POST'), ResponseJson, HttpError), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        Assert.AreEqual('', HttpError, '');
        Assert.IsTrue(JToken.ReadFrom(ResponseJson), '');
        AssertBlankedJsonValue(JToken, 'Content');

        VerifyHttpLog(OAuth20Setup, TRUE, STRSUBSTNO(InvokeRequestTxt, 'POST'), '');
        VerifyHttpLogWithOnlyRequestDetails(OAuth20Setup, 'POST', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_Success_BlankedRequestAndResponse()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        JToken: JsonToken;
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".InvokeRequest() with success result, blanked request and response
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');

        Assert.IsTrue(InvokeRequestFromCOD(OAuth20Setup, '{"Method":"GET"}', ResponseJson, HttpError), '');

        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        AssertBlankedJsonValue(JToken, 'Request.Content');
        Assert.AreEqual('', HttpError, '');
        Assert.IsTrue(JToken.ReadFrom(ResponseJson), '');
        AssertBlankedJsonValue(JToken, 'Content');

        VerifyHttpLog(OAuth20Setup, TRUE, STRSUBSTNO(InvokeRequestTxt, 'GET'), '');
        VerifyHttpLogWithBlankedRequestAndResponseDetails(OAuth20Setup, 'GET', 200, 'OK');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvokeRequest_Failure_HttpError()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        JToken: JsonToken;
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 258181] COD 1140 "OAuth 2.0 Mgt.".InvokeRequest() with failure result, HTTP error
        // MockServicePacket241 MockService\OAuth20\400_dummyjson.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket241');

        Assert.IsFalse(InvokeRequestFromCOD(OAuth20Setup, GetRequestJsonTestString('POST'), ResponseJson, HttpError), '');

        Assert.AreEqual('HTTP error 400 (Bad Request)', HttpError, '');
        Assert.IsTrue(JToken.ReadFrom(ResponseJson), '');

        VerifyHttpLog(OAuth20Setup, false, STRSUBSTNO(InvokeRequestTxt, 'POST'), 'HTTP error 400 (Bad Request)');
        VerifyHttpLogWithRequestAndResponseDetails(OAuth20Setup, 'POST', 400, 'Bad Request');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_EnterAuthorizationCode_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Request Access Token]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" validation of "Enter Authorization Code" with success result
        // MockServicePacket237 MockService\OAuth20\200_authorize.txt
        Initialize();
        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled, 'MockServicePacket237', '', 0DT);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        OAuth20SetupPage."Enter Authorization Code".SETVALUE('TestAuthCode');
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(AuthRequiredNotificationMsg, LibraryVariableStorage.DequeueText()); // Notification message
        Assert.ExpectedMessage(OAuth20Setup.Code, LibraryVariableStorage.DequeueText()); // Notification data
        Assert.ExpectedMessage(AuthorizationSuccessfulTxt, LibraryVariableStorage.DequeueText()); // Authorization successful
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_EnterAuthorizationCode_Failure_Reason()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
        Reason: Text;
    begin
        // [FEATURE] [UI] [Request Access Token]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" validation of "Enter Authorization Code" with failure result with reason
        // MockServicePacket235 MockService\OAuth20\400_blanked.txt
        Initialize();
        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled, 'MockServicePacket235', '', 0DT);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        Reason := 'HTTP error 400 (Bad Request)';
        asserterror OAuth20SetupPage."Enter Authorization Code".SETVALUE('TestAuthCode');
        OAuth20SetupPage.Close();

        Assert.ExpectedErrorCode('TestValidation');
        Assert.ExpectedError(STRSUBSTNO('%1\%2%3', AuthorizationFailedTxt, ReasonTxt, Reason)); // Authorization failed. Reason: ...
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UI_RefreshAccessToken_Success()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
    begin
        // [FEATURE] [UI] [Refresh Access Token]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Refresh Access Token" with success result
        // MockServicePacket237 MockService\OAuth20\200_authorize.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, 'MockServicePacket237', '');
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);

        OAuth20SetupPage.RefreshAccessToken.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedMessage(RefreshSuccessfulTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure UI_RefreshAccessToken_Failure_Reason()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        OAuth20SetupPage: TestPage "OAuth 2.0 Setup";
        Reason: Text;
    begin
        // [FEATURE] [UI] [Refresh Access Token]
        // [SCENARIO 258181] PAG 1140 "OAuth 2.0 Setup" action "Refresh Access Token" with failure result with reason
        // MockServicePacket235 MockService\OAuth20\400_blanked.txt
        Initialize();
        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Disabled, 'MockServicePacket235', '', 0DT);
        OpenOAuthSetupPage(OAuth20SetupPage, OAuth20Setup);
        Reason := 'HTTP error 400 (Bad Request)';

        asserterror OAuth20SetupPage.RefreshAccessToken.Invoke();
        OAuth20SetupPage.Close();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(STRSUBSTNO('%1\%2%3', RefreshFailedTxt, ReasonTxt, Reason)); // Refresh token failed. Reason: ...
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitBlankedLatestDateTime()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of blanked Latest DateTime
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 10, 10, 0DT);

        Assert.IsTrue(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');
        VerifyDailyLimit(OAuth20Setup, 10, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitBlankedLimit()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of blanked Daily Limit
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 0, 10, CurrentDateTime());

        Assert.IsTrue(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');
        VerifyDailyLimit(OAuth20Setup, 0, 11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitBlankedLimitYesterday()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of blanked Daily Limit and yesturady Latest Datetime
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 0, 10, CreateDateTime(Today() - 1, 0T));

        Assert.IsTrue(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');
        VerifyDailyLimit(OAuth20Setup, 0, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitNotExceeded()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of Daily Limit not exceeded
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 10, 1, CurrentDateTime());

        Assert.IsTrue(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');
        VerifyDailyLimit(OAuth20Setup, 10, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitExceeded()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of Daily Limit exceeded today
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 10, 10, CurrentDateTime());

        Assert.IsFalse(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.ExpectedMessage(LimitExceededTxt, HttpError);
        VerifyDailyLimit(OAuth20Setup, 10, 10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DailyLimitExceededYesterday()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJSON: Text;
        HttpError: Text;
    begin
        // [FEATURES] [Daily Limit]
        // [SCENARIO 316966] OAuth 2.0 Setup invoke request in case of Daily Limit exceeded yesterday
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');
        UpdateDailyLimit(OAuth20Setup, 10, 10, CreateDateTime(Today() - 1, 0T));

        Assert.IsTrue(OAuth20Setup.InvokeRequest('{"Method":"GET"}', ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');
        VerifyDailyLimit(OAuth20Setup, 10, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure HttpLogWithMaskedHeaders()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        JObject: JsonObject;
        HeaderJObject: JsonObject;
        JToken: JsonToken;
        ResponseJSON: Text;
        HttpError: Text;
        JsonString: Text;
    begin
        // [FEATURES] [Http Log]
        // [SCENARIO 316966] OAuth 2.0 Http Log contains masked Header values
        // MockServicePacket236 MockService\OAuth20\200_blanked.txt
        Initialize();
        CreateOAuthSetup(OAuth20Setup, '', 'MockServicePacket236');

        HeaderJObject.Add('Name1', 'Value1');
        HeaderJObject.Add('Name2', 'Value2');
        JObject.Add('Method', 'GET');
        JObject.Add('Header', HeaderJObject);
        JObject.WriteTo(JsonString);

        Assert.IsTrue(OAuth20Setup.InvokeRequest(JsonString, ResponseJSON, HttpError, false), '');
        Assert.AreEqual('', HttpError, '');

        JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup));
        Assert.ExpectedMessage('***', ReadJsonValue(JToken, 'Request.Header.Authorization'));
        Assert.ExpectedMessage('***', ReadJsonValue(JToken, 'Request.Header.Name1'));
        Assert.ExpectedMessage('***', ReadJsonValue(JToken, 'Request.Header.Name2'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotExpiredAccessToken()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 324828] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() in case of not expired access token and positive response
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateCustomOAuthSetup(
            OAuth20Setup, OAuth20Setup.Status::Enabled, '', 'MockServicePacket238', CreateDateTime(Today() + 1, Time()));

        Assert.IsTrue(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, false), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.AreEqual('', HttpError, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotExpiredAccessTokenIsAutoRefreshedOn401Error()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 324828] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() in case of not expired access token, 401 response and auto refreshed (RetryOnCredentialsFailure = true)
        // MockServicePacket243 MockService\OAuth20\401_unauthorized.txt
        // MockServicePacket242 MockService\OAuth20\200_authorize_238.txt
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateCustomOAuthSetup(
            OAuth20Setup, OAuth20Setup.Status::Enabled, 'MockServicePacket242', 'MockServicePacket243', CreateDateTime(Today() + 1, Time()));

        Assert.IsTrue(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, true), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.AreEqual('', HttpError, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotExpiredAccessTokenIsNotAutoRefreshedOn401Error()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 324828] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() in case of not expired access token, 401 response and not auto refreshed (RetryOnCredentialsFailure = false)
        // MockServicePacket243 MockService\OAuth20\401_unauthorized.txt
        Initialize();
        CreateCustomOAuthSetup(
            OAuth20Setup, OAuth20Setup.Status::Enabled, '', 'MockServicePacket243', CreateDateTime(Today() + 1, Time()));

        Assert.IsFalse(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, false), '');

        Assert.ExpectedMessage('HTTP error 401', HttpError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpiredAccessTokenIsAutoRefreshed()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 324828] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() in case of expired access token and auto refreshed (RetryOnCredentialsFailure = true)
        // MockServicePacket242 MockService\OAuth20\200_authorize_238.txt
        // MockServicePacket238 MockService\OAuth20\200_dummyjson.txt
        Initialize();
        CreateCustomOAuthSetup(
            OAuth20Setup, OAuth20Setup.Status::Enabled, 'MockServicePacket242', '', CreateDateTime(Today() - 1, Time()));

        Assert.IsTrue(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, true), '');

        VerifyResponseJsonOnInvokeRequest(ResponseJson);
        Assert.AreEqual('', HttpError, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpiredAccessTokenIsNotAutoRefreshed()
    var
        OAuth20Setup: Record "OAuth 2.0 Setup";
        ResponseJson: Text;
        HttpError: Text;
    begin
        // [FEATURE] [Invoke Request]
        // [SCENARIO 324828] TAB 1140 "OAuth 2.0 Setup".InvokeRequest() in case of expired access token and not auto refreshed (RetryOnCredentialsFailure = false)
        // MockServicePacket243 MockService\OAuth20\401_unauthorized.txt
        Initialize();
        CreateCustomOAuthSetup(
            OAuth20Setup, OAuth20Setup.Status::Enabled, '', 'MockServicePacket243', CreateDateTime(Today() - 1, Time()));

        Assert.IsFalse(OAuth20Setup.InvokeRequest(GetRequestJsonTestString('POST'), ResponseJson, HttpError, false), '');

        VerifyRequestJsonOnInvokeRequest(OAuth20Setup);
        Assert.ExpectedMessage('HTTP error 401', HttpError);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    local procedure CreateOAuthSetup(var OAuth20Setup: Record "OAuth 2.0 Setup"; ClientToken: Text; AccessToken: Text)
    begin
        CreateCustomOAuthSetup(OAuth20Setup, OAuth20Setup.Status::Enabled, ClientToken, AccessToken, 0DT);
    end;

    local procedure CreateCustomOAuthSetup(var OAuth20Setup: Record "OAuth 2.0 Setup"; NewStatus: Option; ClientToken: Text; AccessToken: Text; AccessTokenDueDateTime: DateTime)
    begin
        OAuth20Setup.Code := LibraryUtility.GenerateGUID();
        OAuth20Setup.Status := NewStatus;
        OAuth20Setup.Description := LibraryUtility.GenerateGUID();
        OAuth20Setup."Service URL" := 'https://localhost:8080/oauth20';
        OAuth20Setup."Redirect URL" := 'https://TestRedirectURL';
        OAuth20Setup.Scope := LibraryUtility.GenerateGUID();
        OAuth20Setup."Authorization URL Path" := '/TestAuthorizationURLPath';
        OAuth20Setup."Access Token URL Path" := '/TestAccessTokenURLPath';
        OAuth20Setup."Refresh Token URL Path" := '/TestRefreshTokenURLPath';
        OAuth20Setup."Authorization Response Type" := LibraryUtility.GenerateGUID();
        OAuth20Setup."Token DataScope" := OAuth20Setup."Token DataScope"::Company;
        SetOAuthSetupTestTokens(OAuth20Setup, ClientToken, AccessToken);
        OAuth20Setup."Access Token Due DateTime" := AccessTokenDueDateTime;
        OAuth20Setup.Insert();
    end;

    local procedure OpenOAuthSetupPage(var OAuth20SetupPage: TestPage "OAuth 2.0 Setup"; OAuth20Setup: Record "OAuth 2.0 Setup")
    begin
        OAuth20SetupPage.Trap();
        PAGE.Run(PAGE::"OAuth 2.0 Setup", OAuth20Setup);
    end;

    local procedure UpdateDailyLimit(var OAuth20Setup: Record "OAuth 2.0 Setup"; NewDailyLimit: Integer; NewDailyCount: Integer; NewLatestDateTime: DateTime)
    begin
        OAuth20Setup."Daily Limit" := NewDailyLimit;
        OAuth20Setup."Daily Count" := NewDailyCount;
        OAuth20Setup."Latest Datetime" := NewLatestDateTime;
        OAuth20Setup.Modify();
    end;

    local procedure ReadHttpLogDetails(OAuth20Setup: Record "OAuth 2.0 Setup"): Text
    var
        ActivityLog: Record "Activity Log";
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        OAuth20Setup.Find();
        ActivityLog.Get(OAuth20Setup."Activity Log ID");
        ActivityLog.CalcFields("Detailed Info");
        ActivityLog."Detailed Info".CreateInStream(InStream);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
    end;

    local procedure SetOAuthSetupTestTokens(var OAuth20Setup: Record "OAuth 2.0 Setup"; ClientToken: Text; AccessToken: Text)
    var
        ClientSecret: SecretText;
        RefreshTokenSecret: SecretText;
        ClientTokenSecret: SecretText;
        AccessTokenSecret: SecretText;
        ClientSecretText: Text;
        RefreshTokenText: Text;
    begin
        ClientSecretText := 'Dummy Test Client Secret';
        RefreshTokenText := 'Dummy Test Refresh Token';
        ClientSecret := ClientSecretText;
        RefreshTokenSecret := RefreshTokenText;
        ClientTokenSecret := ClientToken;
        AccessTokenSecret := AccessToken;

        OAuth20Setup.SetToken(OAuth20Setup."Client ID", ClientTokenSecret);
        OAuth20Setup.SetToken(OAuth20Setup."Client Secret", ClientSecret);
        OAuth20Setup.SetToken(OAuth20Setup."Access Token", AccessTokenSecret);
        OAuth20Setup.SetToken(OAuth20Setup."Refresh Token", RefreshTokenSecret);
    end;

    [NonDebuggable]
    local procedure InvokeRequestAccessToken(OAuth20Setup: Record "OAuth 2.0 Setup"; VAR MessageText: Text; VAR AccessToken: Text; VAR RefreshToken: Text): Boolean
    VAR
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
        AuthCodeText: Text;
        AuthCode: SecretText;
        AccessTokenSecretText: SecretText;
        RefreshTokenSecretText: SecretText;
    begin
        AuthCodeText := 'TestAuthCode';
        AuthCode := AuthCodeText;
        AccessTokenSecretText := AccessToken;
        RefreshTokenSecretText := RefreshToken;
        if OAuth20Mgt.RequestAccessToken(
            OAuth20Setup, MessageText, AuthCode,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap(),
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client Secret"),
            AccessTokenSecretText, RefreshTokenSecretText) then begin
            AccessToken := AccessTokenSecretText.Unwrap();
            RefreshToken := RefreshTokenSecretText.Unwrap();
            exit(true);
        end;
        exit(false);
    end;

    [NonDebuggable]
    local procedure InvokeRefreshAccessToken(OAuth20Setup: Record "OAuth 2.0 Setup"; var MessageText: Text; var AccessToken: Text; var RefreshToken: Text): Boolean
    var
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
        AccessTokenSecretText: SecretText;
        RefreshTokenSecretText: SecretText;
    begin
        AccessTokenSecretText := AccessToken;
        RefreshTokenSecretText := RefreshToken;
        if OAuth20Mgt.RefreshAccessToken(
            OAuth20Setup, MessageText,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client ID").Unwrap(),
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Client Secret"),
            AccessTokenSecretText, RefreshTokenSecretText) then begin
            AccessToken := AccessTokenSecretText.Unwrap();
            RefreshToken := RefreshTokenSecretText.Unwrap();
            exit(true);
        end;
        exit(false);

    end;

    local procedure InvokeRequestFromCOD(OAuth20Setup: Record "OAuth 2.0 Setup"; OriginalRequestJson: Text; VAR ResponseJson: Text; VAR HttpError: Text): Boolean
    VAR
        OAuth20Mgt: Codeunit "OAuth 2.0 Mgt.";
    begin
        exit(
          OAuth20Mgt.InvokeRequest(
            OAuth20Setup, OriginalRequestJson, ResponseJson, HttpError,
            OAuth20Setup.GetTokenAsSecretText(OAuth20Setup."Access Token"), false));
    end;

    local procedure GetRequestJsonTestString(Method: Text): Text
    begin
        exit(StrSubstNo('{"Method":"%1",Content:{"RequestName1":"RequestValue1","RequestName2":"RequestValue2"}}', Method));
    end;

    internal procedure ReadJsonValue(JToken: JsonToken; Path: Text) Result: Text
    begin
        if JToken.SelectToken(Path, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText())
            else
                JToken.WriteTo(Result);
    end;

    internal procedure ReadIntJsonValue(JToken: JsonToken; Path: Text): Integer
    begin
        if JToken.SelectToken(Path, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsInteger());
    end;

    local procedure VerifyFailureResponseOnRequestAccessToken(MessageText: Text; AccessToken: Text; RefreshToken: Text)
    begin
        Assert.AreEqual(AuthorizationFailedTxt, MessageText, '');
        Assert.AreEqual('', AccessToken, '');
        Assert.AreEqual('', RefreshToken, '');
    end;

    local procedure VerifyFailureResponseOnRefreshAccessToken(MessageText: Text; AccessToken: Text; RefreshToken: Text)
    begin
        Assert.AreEqual(RefreshFailedTxt, MessageText, '');
        Assert.AreEqual('', AccessToken, '');
        Assert.AreEqual('', RefreshToken, '');
    end;

    local procedure VerifyRequestJsonOnInvokeRequest(OAuth20Setup: Record "OAuth 2.0 Setup")
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        VerifyRequestJson(ReadJsonValue(JToken, 'Request.Content'));
    end;

    local procedure VerifyResponseJsonOnInvokeRequest(ResponseJson: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ResponseJson), '');
        VerifyResponseJson(ReadJsonValue(JToken, 'Content'));
    end;

    local procedure VerifyRequestJson(SourceJsonString: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(SourceJsonString), '');
        Assert.IsTrue(JToken.ReadFrom(SourceJsonString), '');
        Assert.AreEqual('RequestValue1', ReadJsonValue(JToken, 'RequestName1'), '');
        Assert.AreEqual('RequestValue2', ReadJsonValue(JToken, 'RequestName2'), '');
    end;

    local procedure VerifyResponseJson(SourceJsonString: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(SourceJsonString), '');
        Assert.AreEqual('ResponseValue1', ReadJsonValue(JToken, 'ResponseName1'), '');
        Assert.AreEqual('ResponseValue2', ReadJsonValue(JToken, 'ResponseName2'), '');
    end;

    local procedure VerifyHttpLog(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedStatusBool: Boolean; ExpectedDescription: Text; ExpectedActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
        ExpectedStatusOption: Option;
    begin
        OAuth20Setup.Find();
        if ExpectedStatusBool then
            ExpectedStatusOption := ActivityLog.Status::Success
        else
            ExpectedStatusOption := ActivityLog.Status::Failed;

        ActivityLog.Get(OAuth20Setup."Activity Log ID");
        ActivityLog.TestField(Status, ExpectedStatusOption);
        ActivityLog.TestField(Context, StrSubstNo('OAuth 2.0 %1', OAuth20Setup.Code));
        ActivityLog.TestField(Description, CopyStr(ExpectedDescription, 1, MaxStrLen(ActivityLog.Description)));
        ActivityLog.TestField("Activity Message", CopyStr(ExpectedActivityMessage, 1, MaxStrLen(ActivityLog."Activity Message")));
    end;

    local procedure VerifyHttpLogWithMaskedContents(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        Assert.AreEqual('***', ReadJsonValue(JToken, 'Request.Content'), 'Request.Content');
        Assert.AreEqual('***', ReadJsonValue(JToken, 'Response.Content'), 'Response.Content');
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyHttpLogWithOnlyRequestMaskedDetails(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        Assert.AreEqual('***', ReadJsonValue(JToken, 'Request.Content'), 'Request.Content');
        AssertBlankedJsonValue(JToken, 'Response.Content');
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyHttpLogWithRequestAndResponseDetails(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        VerifyRequestJson(ReadJsonValue(JToken, 'Request.Content'));
        VerifyResponseJson(ReadJsonValue(JToken, 'Response.Content'));
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyHttpLogWithOnlyRequestDetails(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        AssertBlankedJsonValue(JToken, 'Response.Content');
        VerifyRequestJson(ReadJsonValue(JToken, 'Request.Content'));
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyHttpLogWithOnlyResponseDetails(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        AssertBlankedJsonValue(JToken, 'Request.Content');
        VerifyResponseJson(ReadJsonValue(JToken, 'Response.Content'));
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyHttpLogWithBlankedRequestAndResponseDetails(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedMethod: Text; ExpectedStatus: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        Assert.AreEqual(ExpectedMethod, ReadJsonValue(JToken, 'Request.Method'), '');
        AssertBlankedJsonValue(JToken, 'Request.Content');
        AssertBlankedJsonValue(JToken, 'Response.Content');
        VerifyResponseStatus(OAuth20Setup, ExpectedStatus, ExpectedReason);
    end;

    local procedure VerifyResponseStatus(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedCode: Integer; ExpectedReason: Text)
    var
        JToken: JsonToken;
    begin
        Assert.IsTrue(JToken.ReadFrom(ReadHttpLogDetails(OAuth20Setup)), '');
        JToken.SelectToken('Response.Status', JToken);
        Assert.AreEqual(ExpectedCode, ReadIntJsonValue(JToken, 'code'), '');
        Assert.AreEqual(ExpectedReason, ReadJsonValue(JToken, 'reason'), '');
        AssertBlankedJsonValue(JToken, 'details')
    end;

    procedure VerifyDailyLimit(OAuth20Setup: Record "OAuth 2.0 Setup"; ExpectedDailyLimit: Integer; ExpectedDailyCount: Integer)
    begin
        OAuth20Setup.Find();
        OAuth20Setup.TestField("Daily Limit", ExpectedDailyLimit);
        OAuth20Setup.TestField("Daily Count", ExpectedDailyCount);
        Assert.IsTrue(CurrentDateTime() - OAuth20Setup."Latest Datetime" < 1000 * 60, ''); // < 1 min
    end;

    internal procedure AssertBlankedJsonValue(JToken: JsonToken; Path: Text)
    begin
        if JToken.SelectToken(Path, JToken) then
            Error('Json value for the path ''%1'' should be blanked.', Path);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var TheNotification: Notification): Boolean
    var
        DummyOAuth20Setup: Record "OAuth 2.0 Setup";
    begin
        LibraryVariableStorage.Enqueue(TheNotification.Message());
        LibraryVariableStorage.Enqueue(TheNotification.GetData(DummyOAuth20Setup.FieldName(Code)));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}

