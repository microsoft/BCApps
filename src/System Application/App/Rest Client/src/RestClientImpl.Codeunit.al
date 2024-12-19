// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2351 "Rest Client Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DefaultHttpClientHandler: Codeunit "Http Client Handler";
        HttpAuthenticationAnonymous: Codeunit "Http Authentication Anonymous";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        HttpAuthentication: Interface "Http Authentication";
        HttpClientHandler: Interface "Http Client Handler";
        CurrHttpClientInstance: HttpClient;
        IsInitialized: Boolean;
        EnvironmentBlocksErr: Label 'The outgoing HTTP request to "%1" was blocked by the environment.', Comment = '%1 = url, e.g. https://microsoft.com';
        ConnectionErr: Label 'Connection to the remote service "%1" could not be established.', Comment = '%1 = url, e.g. https://microsoft.com';
        RequestFailedErr: Label 'The request to "%1" failed with status code %2 %3.', Comment = '%1 = url, %2 = HTTP status code, %3 = Reason phrase';
        UserAgentLbl: Label 'Dynamics 365 Business Central - |%1| %2/%3', Locked = true, Comment = '%1 = App Publisher; %2 = App Name; %3 = App Version';
        TimeoutOutOfRangeErr: Label 'The timeout value must be greater than 0.';

    #region Constructors
    procedure Create() RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(DefaultHttpClientHandler, HttpAuthenticationAnonymous);
    end;

    procedure Create(HttpClientHandlerInstance: Interface "Http Client Handler") RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(HttpClientHandlerInstance, HttpAuthenticationAnonymous);
    end;

    procedure Create(HttpAuthenticationInstance: Interface "Http Authentication") RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(DefaultHttpClientHandler, HttpAuthenticationInstance);
    end;

    procedure Create(HttpClientHandlerInstance: Interface "Http Client Handler"; HttpAuthenticationInstance: Interface "Http Authentication"): Codeunit "Rest Client Impl."
    begin
        Initialize(HttpClientHandlerInstance, HttpAuthenticationInstance);
        exit(this);
    end;
    #endregion

    #region Initialization
    procedure Initialize()
    begin
        Initialize(DefaultHttpClientHandler, HttpAuthenticationAnonymous);
    end;

    procedure Initialize(HttpClientHandlerInstance: Interface "Http Client Handler")
    begin
        Initialize(HttpClientHandlerInstance, HttpAuthenticationAnonymous);
    end;

    procedure Initialize(HttpAuthenticationInstance: Interface "Http Authentication")
    begin
        Initialize(DefaultHttpClientHandler, HttpAuthenticationInstance);
    end;

    procedure Initialize(HttpClientHandlerInstance: Interface "Http Client Handler"; HttpAuthenticationInstance: Interface "Http Authentication")
    begin
        ClearAll();

        CurrHttpClientInstance.Clear();
        HttpClientHandler := HttpClientHandlerInstance;
        HttpAuthentication := HttpAuthenticationInstance;
        IsInitialized := true;
        SetDefaultUserAgentHeader();
    end;

    procedure SetDefaultRequestHeader(Name: Text; Value: Text)
    begin
        CheckInitialized();
        if CurrHttpClientInstance.DefaultRequestHeaders.Contains(Name) then
            CurrHttpClientInstance.DefaultRequestHeaders.Remove(Name);
        CurrHttpClientInstance.DefaultRequestHeaders.Add(Name, Value);
    end;

    procedure SetDefaultRequestHeader(Name: Text; Value: SecretText)
    begin
        CheckInitialized();
        if CurrHttpClientInstance.DefaultRequestHeaders.Contains(Name) then
            CurrHttpClientInstance.DefaultRequestHeaders.Remove(Name);
        CurrHttpClientInstance.DefaultRequestHeaders.Add(Name, Value);
    end;

    procedure SetBaseAddress(Url: Text)
    begin
        CheckInitialized();
        CurrHttpClientInstance.SetBaseAddress(Url);
    end;

    procedure GetBaseAddress() Url: Text
    begin
        CheckInitialized();
        Url := CurrHttpClientInstance.GetBaseAddress;
    end;

    procedure SetTimeOut(TimeOut: Duration)
    begin
        CheckInitialized();
        if TimeOut <= 0 then
            Error(TimeoutOutOfRangeErr);
        CurrHttpClientInstance.Timeout := TimeOut;
    end;

    procedure GetTimeOut() TimeOut: Duration
    begin
        CheckInitialized();
        TimeOut := CurrHttpClientInstance.Timeout;
    end;

    procedure AddCertificate(Certificate: Text)
    begin
        CheckInitialized();
        CurrHttpClientInstance.AddCertificate(Certificate);
    end;

    procedure AddCertificate(Certificate: Text; Password: SecretText)
    begin
        CheckInitialized();
        CurrHttpClientInstance.AddCertificate(Certificate, Password);
    end;

    procedure SetAuthorizationHeader(Value: SecretText)
    begin
        SetDefaultRequestHeader('Authorization', Value);
    end;

    procedure SetUserAgentHeader(Value: Text)
    begin
        SetDefaultRequestHeader('User-Agent', Value);
    end;

    procedure SetUseResponseCookies(Value: Boolean)
    begin
        CheckInitialized();
        CurrHttpClientInstance.UseResponseCookies(Value);
    end;
    #endregion

    #region BasicMethodsAsJson
    procedure GetAsJson(RequestUri: Text) JsonToken: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::GET, RequestUri);
        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetException());

        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        JsonToken := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure PostAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::POST, RequestUri, HttpContent.Create(Content));
        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetException());

        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        Response := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure PatchAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::PATCH, RequestUri, HttpContent.Create(Content));
        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetException());

        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        Response := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure PutAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::PUT, RequestUri, HttpContent.Create(Content));
        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetException());

        if IsCollectingErrors() then
            if HasCollectedErrors() then
                exit;

        Response := HttpResponseMessage.GetContent().AsJson();
    end;
    #endregion

    #region GenericSendMethods
    procedure Send(Method: Enum "Http Method"; RequestUri: Text) HttpResponseMessage: Codeunit "Http Response Message"
    var
        EmptyHttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Method, RequestUri, EmptyHttpContent);
    end;

    procedure Send(Method: Enum "Http Method"; RequestUri: Text; Content: Codeunit "Http Content") HttpResponseMessage: Codeunit "Http Response Message"
    var
        HttpRequestMessage: Codeunit "Http Request Message";
    begin
        HttpRequestMessage := CreateHttpRequestMessage(Method, RequestUri, Content);
        HttpResponseMessage := Send(HttpRequestMessage);
    end;

    procedure Send(var HttpRequestMessage: Codeunit "Http Request Message") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        CheckInitialized();

        if not SendRequest(HttpRequestMessage, HttpResponseMessage) then
            Error(HttpResponseMessage.GetException());
    end;

    #endregion

    #region Local Methods
    local procedure CheckInitialized()
    begin
        if not IsInitialized then
            Initialize();
    end;

    local procedure SetDefaultUserAgentHeader()
    var
        ModuleInfo: ModuleInfo;
        UserAgentString: Text;
    begin
        if NavApp.GetCurrentModuleInfo(ModuleInfo) then
            UserAgentString := StrSubstNo(UserAgentLbl, ModuleInfo.Publisher(), ModuleInfo.Name(), ModuleInfo.AppVersion());

        SetUserAgentHeader(UserAgentString);
    end;

    local procedure CreateHttpRequestMessage(Method: Enum "Http Method"; RequestUri: Text; Content: Codeunit "Http Content") HttpRequestMessage: Codeunit "Http Request Message"
    begin
        if not (RequestUri.StartsWith('http://') or RequestUri.StartsWith('https://')) then
            RequestUri := GetBaseAddress() + RequestUri;
        HttpRequestMessage := HttpRequestMessage.Create(Method, RequestUri, Content);
    end;

    local procedure SendRequest(var HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        Clear(HttpResponseMessage);

        if HttpAuthentication.IsAuthenticationRequired() then
            Authorize(HttpRequestMessage);

        if not HttpClientHandler.Send(CurrHttpClientInstance, HttpRequestMessage, HttpResponseMessage) then begin
            if HttpResponseMessage.GetIsBlockedByEnvironment() then
                HttpResponseMessage.SetException(
                    RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::BlockedByEnvironment,
                                                               StrSubstNo(EnvironmentBlocksErr, HttpRequestMessage.GetRequestUri())))
            else
                HttpResponseMessage.SetException(
                    RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::ConnectionFailed,
                                                               StrSubstNo(ConnectionErr, HttpRequestMessage.GetRequestUri())));
            exit(false);
        end;

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            HttpResponseMessage.SetException(
                RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::RequestFailed,
                                                           StrSubstNo(RequestFailedErr, HttpRequestMessage.GetRequestUri(), HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase())));

        exit(true);
    end;

    local procedure Authorize(HttpRequestMessage: Codeunit "Http Request Message")
    var
        AuthorizationHeaders: Dictionary of [Text, SecretText];
        HeaderName: Text;
        HeaderValue: SecretText;
    begin
        AuthorizationHeaders := HttpAuthentication.GetAuthorizationHeaders();
        foreach HeaderName in AuthorizationHeaders.Keys do begin
            HeaderValue := AuthorizationHeaders.Get(HeaderName);
            HttpRequestMessage.SetHeader(HeaderName, HeaderValue);
        end;
    end;
    #endregion
}