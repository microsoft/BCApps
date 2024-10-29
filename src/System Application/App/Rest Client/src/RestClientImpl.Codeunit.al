// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

using System.RestClient;

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
        HttpClient: HttpClient;
        IsInitialized: Boolean;
        BlockedByEnvironmentErrorTok: Label 'BlockedByEnvironmentError', Locked = true;
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 = url, e.g. https://microsoft.com';
        ConnectionErrorTok: Label 'NoConnectionError', Locked = true;
        ConnectionErr: Label 'Connection to the remote service ''%1'' could not be established.', Comment = '%1 = url, e.g. https://microsoft.com';
        RequestFailedErrorTok: Label 'RequestFailedError', Locked = true;
        RequestFailedErr: Label 'The request failed: %1 %2', Comment = '%1 = HTTP status code, %2 = Reason phrase';
        UserAgentLbl: Label 'Dynamics 365 Business Central - |%1| %2/%3', Locked = true, Comment = '%1 = App Publisher; %2 = App Name; %3 = App Version';
        TimeoutOutOfRangeErr: Label 'The timeout value must be greater than 0.';

    #region Constructors
    procedure Create() RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(DefaultHttpClientHandler, HttpAuthenticationAnonymous);
    end;

    procedure Create(HttpClientHandler: Interface "Http Client Handler") RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(HttpClientHandler, HttpAuthenticationAnonymous);
    end;

    procedure Create(HttpAuthentication: Interface "Http Authentication") RestClientImpl: Codeunit "Rest Client Impl."
    begin
        RestClientImpl := RestClientImpl.Create(DefaultHttpClientHandler, HttpAuthentication);
    end;

    procedure Create(HttpClientHandler: Interface "Http Client Handler"; HttpAuthentication: Interface "Http Authentication"): Codeunit "Rest Client Impl."
    begin
        Initialize(HttpClientHandler, HttpAuthentication);
        exit(this);
    end;

    #endregion

    #region Initialization
    procedure Initialize()
    begin
        Initialize(DefaultHttpClientHandler, HttpAuthenticationAnonymous);
    end;

#pragma warning disable AA0244
    procedure Initialize(HttpClientHandler: Interface "Http Client Handler")
    begin
        Initialize(HttpClientHandler, HttpAuthenticationAnonymous);
    end;

    procedure Initialize(HttpAuthentication: Interface "Http Authentication")
    begin
        Initialize(DefaultHttpClientHandler, HttpAuthentication);
    end;
#pragma warning restore AA0244

    procedure Initialize(HttpClientHandlerInstance: Interface "Http Client Handler"; HttpAuthenticationInstance: Interface "Http Authentication")
    begin
        ClearAll();

        HttpClient.Clear();
        HttpClientHandler := HttpClientHandlerInstance;
        HttpAuthentication := HttpAuthenticationInstance;
        IsInitialized := true;
        SetDefaultUserAgentHeader();
    end;

    procedure SetDefaultRequestHeader(Name: Text; Value: Text)
    begin
        CheckInitialized();
        if HttpClient.DefaultRequestHeaders.Contains(Name) then
            HttpClient.DefaultRequestHeaders.Remove(Name);
        HttpClient.DefaultRequestHeaders.Add(Name, Value);
    end;

    procedure SetDefaultRequestHeader(Name: Text; Value: SecretText)
    begin
        CheckInitialized();
        if HttpClient.DefaultRequestHeaders.Contains(Name) then
            HttpClient.DefaultRequestHeaders.Remove(Name);
        HttpClient.DefaultRequestHeaders.Add(Name, Value);
    end;

    procedure SetBaseAddress(Url: Text)
    begin
        CheckInitialized();
        HttpClient.SetBaseAddress(Url);
    end;

    procedure GetBaseAddress() Url: Text
    begin
        CheckInitialized();
        Url := HttpClient.GetBaseAddress;
    end;

    procedure SetTimeOut(TimeOut: Duration)
    begin
        CheckInitialized();
        if TimeOut <= 0 then
            Error(TimeoutOutOfRangeErr);
        HttpClient.Timeout := TimeOut;
    end;

    procedure GetTimeOut() TimeOut: Duration
    begin
        CheckInitialized();
        TimeOut := HttpClient.Timeout;
    end;

    procedure AddCertificate(Certificate: Text)
    begin
        CheckInitialized();
        HttpClient.AddCertificate(Certificate);
    end;

    procedure AddCertificate(Certificate: Text; Password: SecretText)
    begin
        CheckInitialized();
        HttpClient.AddCertificate(Certificate, Password);
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
        HttpClient.UseResponseCookies(Value);
    end;
    #endregion


    #region BasicMethodsAsJson
    procedure GetAsJson(RequestUri: Text) JsonToken: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::GET, RequestUri);
        if not HttpResponseMessage.GetIsSuccessStatusCode() then begin
            Error(HttpResponseMessage.GetException());
        end;

        JsonToken := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure GetAsJson(RequestUri: Text; var JsonToken: JsonToken) Success: Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        Clear(JsonToken);
        Success := Send(Enum::"Http Method"::GET, RequestUri, HttpResponseMessage);
        if not Success then begin
            exit;
        end;

        if Success and HttpResponseMessage.GetIsSuccessStatusCode() then
            JsonToken := HttpResponseMessage.GetContent().AsJson()
        else
            Error(ErrorInfo.Create(HttpResponseMessage.GetErrorMessage(), true));

        Success := not HasCollectedErrors();
    end;

    procedure PostAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::POST, RequestUri, HttpContent.Create(Content));

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetErrorMessage());

        Response := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure PatchAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::PATCH, RequestUri, HttpContent.Create(Content));

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetErrorMessage());

        Response := HttpResponseMessage.GetContent().AsJson();
    end;

    procedure PutAsJson(RequestUri: Text; Content: JsonToken) Response: JsonToken
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage := Send(Enum::"Http Method"::PUT, RequestUri, HttpContent.Create(Content));

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error(HttpResponseMessage.GetErrorMessage());

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
            Error(HttpResponseMessage.GetErrorMessage());
    end;

    procedure Send(Method: Enum "Http Method"; RequestUri: Text; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        EmptyHttpContent: Codeunit "Http Content";
    begin
        Success := Send(Method, RequestUri, EmptyHttpContent, HttpResponseMessage);
    end;

    procedure Send(Method: Enum "Http Method"; RequestUri: Text; Content: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpRequestMessage: Codeunit "Http Request Message";
    begin
        HttpRequestMessage := CreateHttpRequestMessage(Method, RequestUri, Content);
        Success := Send(HttpRequestMessage, HttpResponseMessage);
    end;

    procedure Send(var HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    begin
        CheckInitialized();
        Success := SendRequest(HttpRequestMessage, HttpResponseMessage);
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

        if not HttpClientHandler.Send(HttpClient, HttpRequestMessage, HttpResponseMessage) then begin
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
                                                           StrSubstNo(RequestFailedErr, HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase())));

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