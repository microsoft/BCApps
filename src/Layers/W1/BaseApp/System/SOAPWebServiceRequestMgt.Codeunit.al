namespace System.Integration;

using Microsoft.Utilities;
using System;
using System.Reflection;
using System.Text;
using System.Utilities;
using System.Xml;

codeunit 1290 "SOAP Web Service Request Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        TempBlobDebugLog: Codeunit "Temp Blob";
        TempBlobResponseBody: Codeunit "Temp Blob";
        TempBlobResponseInStream: Codeunit "Temp Blob";
        TempBlobRequestContent: Codeunit "Temp Blob";
        TempBlobFaultResponse: Codeunit "Temp Blob";
        Trace: Codeunit Trace;
        GlobalRequestBodyInStream: InStream;
        GlobalRequestContentInStream: InStream;
        GlobalPassword: SecretText;
        GlobalURL: Text;
        [NonDebuggable]
        GlobalUsername: Text;
        [NonDebuggable]
        GlobalBasicUsername: Text;
        GlobalBasicPassword: SecretText;
        GlobalSoapAction: Text;
        GlobalStreamEncoding: TextEncoding;
        TraceLogEnabled: Boolean;
        GlobalTimeout: Integer;
        GlobalContentType: Text;
        GlobalSkipCheckHttps: Boolean;
        GlobalProgressDialogEnabled: Boolean;
        GlobalUseDefaultCredentials: Boolean;
        GlobalHttpRequestFailed: Boolean;
        GlobalHttpResponseReceived: Boolean;
        GlobalHttpStatusCode: Integer;
        GlobalHttpReasonPhrase: Text;
        GlobalHttpRequestUri: Text;
        GlobalHttpErrorText: Text;

        BodyPathTxt: Label '/soap:Envelope/soap:Body', Locked = true;
        ContentTypeTxt: Label 'multipart/form-data; charset=utf-8', Locked = true;
        FaultStringXmlPathTxt: Label '/soap:Envelope/soap:Body/soap:Fault/faultstring', Locked = true;
        NoRequestBodyErr: Label 'The request body is not set.';
        NoServiceAddressErr: Label 'The web service URI is not set.';
        ExpectedResponseNotReceivedErr: Label 'The expected data was not received from the web service.';
        SchemaNamespaceTxt: Label 'http://www.w3.org/2001/XMLSchema', Locked = true;
        SchemaInstanceNamespaceTxt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        SecurityUtilityNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd', Locked = true;
        SecurityExtensionNamespaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd', Locked = true;
        SoapNamespaceTxt: Label 'http://schemas.xmlsoap.org/soap/envelope/', Locked = true;
        UsernameTokenNamepsaceTxt: Label 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText', Locked = true;
        InternalErr: Label 'The remote service has returned the following error message:\\';
        InvalidTokenFormatErr: Label 'The token must be in JWS or JWE Compact Serialization Format.';
        ConnectionErr: Label 'Connection to the remote service could not be established.\\';
        ProcessingWindowMsg: Label 'Please wait while the server is processing your request.\This may take several minutes.';
        EnvironmentBlocksErr: Label 'Environment blocks an outgoing HTTP request to ''%1''.', Comment = '%1 - url, e.g. https://microsoft.com';
        RemoteServerErr: Label 'The remote server returned an error: (%1) %2.', Comment = '%1 - HTTP status code, e.g. 500, %2 - reason phrase, e.g. Internal Server Error';
        RemoteServerNoReasonErr: Label 'The remote server returned an error: (%1).', Comment = '%1 - HTTP status code, e.g. 500';
        ServiceURLTxt: Label '\\Service URL: %1.', Comment = '%1 - url, e.g. http://www.contoso.com/';

    [TryFunction]
    procedure SendRequestToWebService()
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        ResponseInStream: InStream;
    begin
        ClearResponseState();
        CheckGlobals();
        BuildWebRequest(GlobalURL, HttpClient, HttpRequestMessage);
        CreateRequestContent(HttpRequestMessage);
        AddBasicAuthorizationHeader(GlobalBasicUsername, GlobalBasicPassword, HttpRequestMessage);
        AddSoapActionHeader(GlobalSoapAction, HttpRequestMessage);
        SendWebRequest(HttpClient, HttpRequestMessage);
        TempBlobResponseInStream.CreateInStream(ResponseInStream, GlobalStreamEncoding);
        ExtractContentFromResponse(ResponseInStream, TempBlobResponseBody);
    end;

    local procedure ClearResponseState()
    begin
        Clear(TempBlobRequestContent);
        Clear(TempBlobResponseInStream);
        Clear(TempBlobFaultResponse);
        GlobalHttpRequestFailed := false;
        GlobalHttpResponseReceived := false;
        GlobalHttpStatusCode := 0;
        GlobalHttpReasonPhrase := '';
        GlobalHttpRequestUri := '';
        GlobalHttpErrorText := '';
    end;

    local procedure BuildWebRequest(ServiceUrl: Text; var HttpClient: HttpClient; var HttpRequestMessage: HttpRequestMessage)
    begin
        HttpRequestMessage.Method('POST');
        HttpRequestMessage.SetRequestUri(ServiceUrl);
        // Explicit Basic credentials take precedence over the service account's default credentials.
        if GlobalUseDefaultCredentials and (GlobalBasicUsername = '') then
            HttpClient.UseDefaultNetworkWindowsAuthentication();
        if GlobalContentType = '' then
            GlobalContentType := ContentTypeTxt;
        if GlobalTimeout <= 0 then
            GlobalTimeout := MaxHttpClientTimeoutMs();
        if GlobalTimeout > MaxHttpClientTimeoutMs() then
            GlobalTimeout := MaxHttpClientTimeoutMs();
        HttpClient.Timeout(GlobalTimeout);
    end;

    local procedure MaxHttpClientTimeoutMs(): Integer
    begin
        // HttpClient does not support timeouts above 5 minutes.
        exit(300000);
    end;

    local procedure CreateRequestContent(var HttpRequestMessage: HttpRequestMessage)
    var
        HttpContent: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestOutStream: OutStream;
    begin
        TempBlobRequestContent.CreateOutStream(RequestOutStream, TextEncoding::UTF8);
        CreateSoapRequest(RequestOutStream, GlobalRequestBodyInStream, GlobalUsername, GlobalPassword);
        TempBlobRequestContent.CreateInStream(GlobalRequestContentInStream);
        HttpContent.WriteFrom(GlobalRequestContentInStream);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.TryAddWithoutValidation('Content-Type', GlobalContentType);
        HttpRequestMessage.Content(HttpContent);
    end;

    local procedure SendWebRequest(var HttpClient: HttpClient; var HttpRequestMessage: HttpRequestMessage)
    var
        HttpResponseMessage: HttpResponseMessage;
        ProcessingWindow: Dialog;
        HttpResponseInStream: InStream;
        ResponseOutStream: OutStream;
        RequestSent: Boolean;
    begin
        if GlobalProgressDialogEnabled then
            ProcessingWindow.Open(ProcessingWindowMsg);

        ClearLastError();
        RequestSent := HttpClient.Send(HttpRequestMessage, HttpResponseMessage);

        if GlobalProgressDialogEnabled then
            ProcessingWindow.Close();

        GlobalHttpRequestUri := HttpRequestMessage.GetRequestUri();
        if not RequestSent then begin
            GlobalHttpRequestFailed := true;
            if HttpResponseMessage.IsBlockedByEnvironment() then
                GlobalHttpErrorText := StrSubstNo(EnvironmentBlocksErr, GlobalHttpRequestUri)
            else
                GlobalHttpErrorText := GetLastErrorText();
            Error(GlobalHttpErrorText);
        end;

        HttpResponseMessage.Content.ReadAs(HttpResponseInStream);
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            GlobalHttpRequestFailed := true;
            GlobalHttpResponseReceived := true;
            GlobalHttpStatusCode := HttpResponseMessage.HttpStatusCode();
            GlobalHttpReasonPhrase := HttpResponseMessage.ReasonPhrase();
            TempBlobFaultResponse.CreateOutStream(ResponseOutStream);
            CopyStream(ResponseOutStream, HttpResponseInStream);
            GlobalHttpErrorText := GetRemoteServerErrorText();
            Error(GlobalHttpErrorText);
        end;

        TempBlobResponseInStream.CreateOutStream(ResponseOutStream);
        CopyStream(ResponseOutStream, HttpResponseInStream);
    end;

    local procedure GetRemoteServerErrorText(): Text
    begin
        if GlobalHttpReasonPhrase = '' then
            exit(StrSubstNo(RemoteServerNoReasonErr, GlobalHttpStatusCode));
        exit(StrSubstNo(RemoteServerErr, GlobalHttpStatusCode, GlobalHttpReasonPhrase));
    end;

    local procedure CreateSoapRequest(RequestOutStream: OutStream; BodyContentInStream: InStream; Username: Text; Password: SecretText)
    var
        [NonDebuggable]
        XmlDoc: DotNet XmlDocument;
        BodyXmlNode: DotNet XmlNode;
        [NonDebuggable]
        PasswordFromEvent: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateSoapRequest(RequestOutStream, BodyContentInStream, XMLDoc, UserName, PasswordFromEvent, TraceLogEnabled, IsHandled);
        if PasswordFromEvent <> '' then
            Password := PasswordFromEvent;
        if IsHandled then
            exit;

        CreateEnvelope(XmlDoc, BodyXmlNode, Username, Password);
        AddBodyToEnvelope(BodyXmlNode, BodyContentInStream);
        XmlDoc.Save(RequestOutStream);
        TraceLogXmlDocToTempFile(XmlDoc, 'FullRequest');
    end;

    [NonDebuggable]
    local procedure CreateEnvelope(var XmlDoc: DotNet XmlDocument; var BodyXmlNode: DotNet XmlNode; Username: Text; Password: SecretText)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        EnvelopeXmlNode: DotNet XmlNode;
        HeaderXmlNode: DotNet XmlNode;
        SecurityXmlNode: DotNet XmlNode;
        UsernameTokenXmlNode: DotNet XmlNode;
        TempXmlNode: DotNet XmlNode;
        PasswordXmlNode: DotNet XmlNode;
    begin
        XmlDoc := XmlDoc.XmlDocument();
        XMLDOMMgt.AddRootElementWithPrefix(XmlDoc, 'Envelope', 's', SoapNamespaceTxt, EnvelopeXmlNode);
        XMLDOMMgt.AddAttribute(EnvelopeXmlNode, 'xmlns:u', SecurityUtilityNamespaceTxt);

        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Header', '', 's', SoapNamespaceTxt, HeaderXmlNode);

        if (Username <> '') or (not Password.IsEmpty()) then begin
            XMLDOMMgt.AddElementWithPrefix(HeaderXmlNode, 'Security', '', 'o', SecurityExtensionNamespaceTxt, SecurityXmlNode);
            XMLDOMMgt.AddAttributeWithPrefix(SecurityXmlNode, 'mustUnderstand', 's', SoapNamespaceTxt, '1');

            XMLDOMMgt.AddElementWithPrefix(SecurityXmlNode, 'UsernameToken', '', 'o', SecurityExtensionNamespaceTxt, UsernameTokenXmlNode);
            XMLDOMMgt.AddAttributeWithPrefix(UsernameTokenXmlNode, 'Id', 'u', SecurityUtilityNamespaceTxt, CreateUUID());

            XMLDOMMgt.AddElementWithPrefix(UsernameTokenXmlNode, 'Username', Username, 'o', SecurityExtensionNamespaceTxt, TempXmlNode);
            XMLDOMMgt.AddElementWithPrefix(UsernameTokenXmlNode, 'Password', Password.Unwrap(), 'o', SecurityExtensionNamespaceTxt, PasswordXmlNode);
            XMLDOMMgt.AddAttribute(PasswordXmlNode, 'Type', UsernameTokenNamepsaceTxt);
        end;

        XMLDOMMgt.AddElementWithPrefix(EnvelopeXmlNode, 'Body', '', 's', SoapNamespaceTxt, BodyXmlNode);
        XMLDOMMgt.AddAttribute(BodyXmlNode, 'xmlns:xsi', SchemaInstanceNamespaceTxt);
        XMLDOMMgt.AddAttribute(BodyXmlNode, 'xmlns:xsd', SchemaNamespaceTxt);
    end;

    local procedure CreateUUID(): Text
    begin
        exit('uuid-' + DelChr(LowerCase(Format(CreateGuid())), '=', '{}'));
    end;

    local procedure AddBodyToEnvelope(var BodyXmlNode: DotNet XmlNode; BodyInStream: InStream)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        BodyContentXmlDoc: DotNet XmlDocument;
    begin
        XMLDOMManagement.LoadXMLDocumentFromInStream(BodyInStream, BodyContentXmlDoc);
        TraceLogXmlDocToTempFile(BodyContentXmlDoc, 'RequestBodyContent');

        BodyXmlNode.AppendChild(BodyXmlNode.OwnerDocument.ImportNode(BodyContentXmlDoc.DocumentElement, true));
    end;

    local procedure ExtractContentFromResponse(ResponseInStream: InStream; var TempBlobBody: Codeunit "Temp Blob")
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        ResponseBodyXMLDoc: DotNet XmlDocument;
        ResponseBodyXmlNode: DotNet XmlNode;
        XmlNode: DotNet XmlNode;
        BodyOutStream: OutStream;
        Found: Boolean;
    begin
        TraceLogStreamToTempFile(ResponseInStream, 'FullResponse', TempBlobDebugLog);
        XMLDOMMgt.LoadXMLNodeFromInStream(ResponseInStream, XmlNode);

        Found := XMLDOMMgt.FindNodeWithNamespace(XmlNode, BodyPathTxt, 'soap', SoapNamespaceTxt, ResponseBodyXmlNode);
        if not Found then
            Error(ExpectedResponseNotReceivedErr);

        ResponseBodyXMLDoc := ResponseBodyXMLDoc.XmlDocument();
        ResponseBodyXMLDoc.AppendChild(ResponseBodyXMLDoc.ImportNode(ResponseBodyXmlNode.FirstChild, true));

        TempBlobBody.CreateOutStream(BodyOutStream, GlobalStreamEncoding);
        ResponseBodyXMLDoc.Save(BodyOutStream);
        TraceLogXmlDocToTempFile(ResponseBodyXMLDoc, 'ResponseBodyContent');
    end;

    procedure GetResponseContent(var ResponseBodyInStream: InStream)
    begin
        TempBlobResponseBody.CreateInStream(ResponseBodyInStream, GlobalStreamEncoding);
    end;

    procedure ProcessFaultResponse(SupportInfo: Text)
    var
        XMLDOMMgt: Codeunit "XML DOM Management";
        XmlNode: DotNet XmlNode;
        ResponseInputStream: InStream;
        ErrorText: Text;
        ServiceURL: Text;
    begin
        if not GlobalHttpRequestFailed then
            Error(GetLastErrorText());

        if not GlobalHttpResponseReceived then begin
            ErrorText := ConnectionErr + GlobalHttpErrorText;
            Error(ErrorText);
        end;

        ServiceURL := StrSubstNo(ServiceURLTxt, GlobalHttpRequestUri);
        if not (GlobalHttpStatusCode in [302, 500]) then begin
            ErrorText := ConnectionErr + GlobalHttpErrorText + ServiceURL;
            Error(ErrorText);
        end;

        TempBlobFaultResponse.CreateInStream(ResponseInputStream);
        if TraceLogEnabled then begin
            Trace.LogStreamToTempFile(ResponseInputStream, 'WebExceptionResponse', TempBlobDebugLog);
            TempBlobFaultResponse.CreateInStream(ResponseInputStream);
        end;

        XMLDOMMgt.LoadXMLNodeFromInStream(ResponseInputStream, XmlNode);

        ErrorText := XMLDOMMgt.FindNodeTextWithNamespace(XmlNode, FaultStringXmlPathTxt, 'soap', SoapNamespaceTxt);
        if ErrorText = '' then
            ErrorText := GlobalHttpErrorText;
        ErrorText := InternalErr + ErrorText + ServiceURL;

        if SupportInfo <> '' then
            ErrorText += '\\' + SupportInfo;

        Error(ErrorText);
    end;

    /// <summary>
    /// Gets the content of the response returned by the web service when the last request failed with an HTTP error status code.
    /// </summary>
    /// <param name="FaultResponseInStream">The stream that receives the content of the failed response.</param>
    /// <returns>True if the last request received a response with an HTTP error status code; otherwise, false.</returns>
    procedure GetFaultResponseContent(var FaultResponseInStream: InStream): Boolean
    begin
        if not GlobalHttpResponseReceived then
            exit(false);
        TempBlobFaultResponse.CreateInStream(FaultResponseInStream);
        exit(true);
    end;

    /// <summary>
    /// Gets the HTTP status code returned by the web service when the last request failed with an HTTP error status code.
    /// </summary>
    /// <returns>The HTTP status code, or 0 if no error response was received.</returns>
    procedure GetFaultResponseStatusCode(): Integer
    begin
        exit(GlobalHttpStatusCode);
    end;

    [NonDebuggable]
    procedure SetGlobals(RequestBodyInStream: InStream; URL: Text; Username: Text; Password: SecretText)
    begin
        GlobalRequestBodyInStream := RequestBodyInStream;

        GlobalSkipCheckHttps := false;

        GlobalURL := URL;
        GlobalUsername := Username;
        GlobalPassword := Password;

        GlobalStreamEncoding := TEXTENCODING::Windows;

        GlobalProgressDialogEnabled := true;

        TraceLogEnabled := false;
    end;

    [NonDebuggable]
    procedure SetBasicCredentials(Username: Text; Password: SecretText)
    begin
        GlobalBasicUsername := Username;
        GlobalBasicPassword := Password;
    end;

    /// <summary>
    /// Specifies whether the request is authenticated with the default credentials of the Business Central service account.
    /// Default credentials are not sent unless explicitly enabled. Only enable this for trusted endpoints that require Windows authentication.
    /// </summary>
    /// <param name="UseDefaultCredentials">True to send the default credentials; otherwise, false.</param>
    [Scope('OnPrem')]
    procedure SetUseDefaultCredentials(UseDefaultCredentials: Boolean)
    begin
        GlobalUseDefaultCredentials := UseDefaultCredentials;
    end;

    procedure SetAction(SoapAction: Text);
    begin
        GlobalSoapAction := SoapAction;
    end;

    procedure SetStreamEncoding(StreamEncoding: TextEncoding);
    begin
        GlobalStreamEncoding := StreamEncoding;
    end;

    procedure SetTimeout(NewTimeout: Integer)
    begin
        GlobalTimeout := NewTimeout;
    end;

    procedure SetContentType(NewContentType: Text)
    begin
        GlobalContentType := NewContentType;
    end;

    local procedure CheckGlobals()
    var
        WebRequestHelper: Codeunit "Web Request Helper";
    begin
        if GlobalRequestBodyInStream.EOS then
            Error(NoRequestBodyErr);

        if GlobalURL = '' then
            Error(NoServiceAddressErr);

        if GlobalSkipCheckHttps then
            WebRequestHelper.IsValidUri(GlobalURL)
        else
            WebRequestHelper.IsSecureHttpUrl(GlobalURL);
    end;

    local procedure TraceLogStreamToTempFile(var ToLogInStream: InStream; Name: Text; var TempBlobTraceLog: Codeunit "Temp Blob")
    begin
        if TraceLogEnabled then
            Trace.LogStreamToTempFile(ToLogInStream, Name, TempBlobTraceLog);
    end;

    local procedure TraceLogXmlDocToTempFile(var XmlDoc: DotNet XmlDocument; Name: Text)
    begin
        if TraceLogEnabled then
            Trace.LogXmlDocToTempFile(XmlDoc, Name);
    end;

    [NonDebuggable]
    local procedure AddBasicAuthorizationHeader(Username: Text; Password: SecretText; var HttpRequestMessage: HttpRequestMessage);
    var
        Base64Convert: Codeunit "Base64 Convert";
        RequestHeaders: HttpHeaders;
    begin
        if (Username = '') then
            exit;

        HttpRequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(SecretStrSubstNo('%1:%2', Username, Password))));
    end;

    local procedure AddSoapActionHeader(SoapAction: Text; var HttpRequestMessage: HttpRequestMessage);
    var
        RequestHeaders: HttpHeaders;
    begin
        if (SoapAction = '') then
            exit;

        HttpRequestMessage.GetHeaders(RequestHeaders);
        RequestHeaders.TryAddWithoutValidation('SOAPAction', SoapAction);
    end;

    procedure SetTraceMode(NewTraceMode: Boolean)
    begin
        TraceLogEnabled := NewTraceMode;
    end;

    procedure DisableHttpsCheck()
    begin
        GlobalSkipCheckHttps := true;
    end;

    procedure DisableProgressDialog()
    begin
        GlobalProgressDialogEnabled := false;
    end;

    procedure HasJWTExpired(JsonWebToken: SecretText): Boolean
    var
        WebTokenAsJson: Text;
    begin
        if JsonWebToken.IsEmpty() then
            exit(true);
        if not GetTokenDetailsAsJson(JsonWebToken, WebTokenAsJson) then
            Error(InvalidTokenFormatErr);
        exit(GetTokenDateTimeValue(WebTokenAsJson, 'exp') < CurrentDateTime);
    end;

    [NonDebuggable]
    procedure GetTokenValue(WebTokenAsJson: Text; ClaimType: Text): Text
    var
        JSONManagement: Codeunit "JSON Management";
        JObject: DotNet JObject;
        ClaimValue: Text;
    begin
        JSONManagement.InitializeObject(WebTokenAsJson);
        JSONManagement.GetJSONObject(JObject);
        if JSONManagement.GetStringPropertyValueFromJObjectByName(JObject, ClaimType, ClaimValue) then
            exit(ClaimValue);
    end;

    [NonDebuggable]
    procedure GetTokenDateTimeValue(WebTokenAsJson: Text; ClaimType: Text): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        Timestamp: Decimal;
    begin
        if not Evaluate(Timestamp, GetTokenValue(WebTokenAsJson, ClaimType)) then
            exit;
        exit(TypeHelper.EvaluateUnixTimestamp(Timestamp));
    end;

    [TryFunction]
    [NonDebuggable]
    procedure GetTokenDetailsAsJson(JsonWebToken: SecretText; var WebTokenAsJson: Text)
    var
        JSONManagement: Codeunit "JSON Management";
        JwtSecurityTokenHandler: DotNet JwtSecurityTokenHandler;
        JwtSecurityToken: DotNet JwtSecurityToken;
        Claim: DotNet Claim;
        JObject: DotNet JObject;
    begin
        if JsonWebToken.IsEmpty() then
            exit;

        JwtSecurityTokenHandler := JwtSecurityTokenHandler.JwtSecurityTokenHandler();
        JwtSecurityToken := JwtSecurityTokenHandler.ReadToken(JsonWebToken.Unwrap());

        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JObject);
        foreach Claim in JwtSecurityToken.Claims do
            JSONManagement.AddJPropertyToJObject(JObject, Claim.Type, Claim.Value);

        WebTokenAsJson := JObject.ToString();
    end;

    [TryFunction]
    [NonDebuggable]
    procedure GetTokenDetailsAsNameBuffer(JsonWebToken: SecretText; var Buffer: Record "Name/Value Buffer")
    var
        JwtSecurityTokenHandler: DotNet JwtSecurityTokenHandler;
        JwtSecurityToken: DotNet JwtSecurityToken;
        Claim: DotNet Claim;
    begin
        if JsonWebToken.IsEmpty() then
            exit;

        JwtSecurityTokenHandler := JwtSecurityTokenHandler.JwtSecurityTokenHandler();
        JwtSecurityToken := JwtSecurityTokenHandler.ReadToken(JsonWebToken.Unwrap());

        foreach Claim in JwtSecurityToken.Claims do
            Buffer.AddNewEntry(Claim.Type, Claim.Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSoapRequest(var RequestOutStream: OutStream; var BodyContentInStream: InStream; var XmlDoc: DotNet XmlDocument; var Username: Text; var Password: Text; var TraceLogEnabled: Boolean; var IsHandled: Boolean)
    begin
    end;
}
