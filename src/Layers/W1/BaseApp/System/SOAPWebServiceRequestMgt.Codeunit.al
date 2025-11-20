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
        Trace: Codeunit Trace;
        GlobalRequestBodyInStream: InStream;
        HttpWebResponse: DotNet HttpWebResponse;
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

    [TryFunction]
    procedure SendRequestToWebService()
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebRequest: DotNet HttpWebRequest;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseInStream: InStream;
    begin
        CheckGlobals();
        BuildWebRequest(GlobalURL, HttpWebRequest);
        Clear(TempBlobResponseInStream);
        TempBlobResponseInStream.CreateInStream(ResponseInStream, GlobalStreamEncoding);
        CreateSoapRequest(HttpWebRequest.GetRequestStream(), GlobalRequestBodyInStream, GlobalUsername, GlobalPassword);
        AddBasicAuthorizationHeader(GlobalURL, GlobalBasicUsername, GlobalBasicPassword, HttpWebRequest);
        AddSoapActionHeader(GlobalSoapAction, HttpWebRequest);
        WebRequestHelper.GetWebResponse(HttpWebRequest, HttpWebResponse, ResponseInStream,
          HttpStatusCode, ResponseHeaders, GlobalProgressDialogEnabled);
        ExtractContentFromResponse(ResponseInStream, TempBlobResponseBody);
    end;

    local procedure BuildWebRequest(ServiceUrl: Text; var HttpWebRequest: DotNet HttpWebRequest)
    var
        DecompressionMethods: DotNet DecompressionMethods;
    begin
        HttpWebRequest := HttpWebRequest.Create(ServiceUrl);
        HttpWebRequest.Method := 'POST';
        HttpWebRequest.KeepAlive := true;
        HttpWebRequest.AllowAutoRedirect := true;
        HttpWebRequest.UseDefaultCredentials := true;
        if GlobalContentType = '' then
            GlobalContentType := ContentTypeTxt;
        HttpWebRequest.ContentType := GlobalContentType;
        if GlobalTimeout <= 0 then
            GlobalTimeout := 600000;
        HttpWebRequest.Timeout := GlobalTimeout;
        HttpWebRequest.AutomaticDecompression := DecompressionMethods.GZip;
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
        WebRequestHelper: Codeunit "Web Request Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WebException: DotNet WebException;
        XmlNode: DotNet XmlNode;
        ResponseInputStream: InStream;
        ErrorText: Text;
        ServiceURL: Text;
    begin
        ErrorText := WebRequestHelper.GetWebResponseError(WebException, ServiceURL);

        if ErrorText <> '' then
            Error(ErrorText);

        ResponseInputStream := WebException.Response.GetResponseStream();
        if TraceLogEnabled then
            Trace.LogStreamToTempFile(ResponseInputStream, 'WebExceptionResponse', TempBlobDebugLog);

        XMLDOMMgt.LoadXMLNodeFromInStream(ResponseInputStream, XmlNode);

        ErrorText := XMLDOMMgt.FindNodeTextWithNamespace(XmlNode, FaultStringXmlPathTxt, 'soap', SoapNamespaceTxt);
        if ErrorText = '' then
            ErrorText := WebException.Message;
        ErrorText := InternalErr + ErrorText + ServiceURL;

        if SupportInfo <> '' then
            ErrorText += '\\' + SupportInfo;

        Error(ErrorText);
    end;
#if not CLEAN25

    [Obsolete('Replaced by SetGlobals(RequestBodyInStream: InStream; URL: Text; Username: Text; Password: SecretText)', '25.0')]
    [NonDebuggable]
    procedure SetGlobals(RequestBodyInStream: InStream; URL: Text; Username: Text; Password: Text)
    var
        PasswordAsSecretText: SecretText;
    begin
        PasswordAsSecretText := Password;
        SetGlobals(RequestBodyInStream, URL, Username, PasswordAsSecretText);
    end;
#endif

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
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by SetBasicCredentials(Username: Text; Password: SecretText)', '25.0')]
    procedure SetBasicCredentials(Username: Text; Password: Text)
    var
        PasswordAsSecretText: SecretText;
    begin
        PasswordAsSecretText := Password;
        SetBasicCredentials(Username, PasswordAsSecretText);
    end;
#endif

    [NonDebuggable]
    procedure SetBasicCredentials(Username: Text; Password: SecretText)
    begin
        GlobalBasicUsername := Username;
        GlobalBasicPassword := Password;
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
    local procedure AddBasicAuthorizationHeader(Uri: Text; Username: Text; Password: SecretText; var DotNet_HttpWebRequest: DotNet HttpWebRequest);
    var
        DotNet_Uri: DotNet Uri;
        DotNet_CredentialCache: DotNet CredentialCache;
        DotNet_NetworkCredential: DotNet NetworkCredential;
    begin
        if (Username = '') then
            exit;

        DotNet_Uri := DotNet_Uri.Uri(Uri);
        DotNet_NetworkCredential := DotNet_NetworkCredential.NetworkCredential(Username, Password.Unwrap());
        DotNet_CredentialCache := DotNet_CredentialCache.CredentialCache();
        DotNet_CredentialCache.Add(DotNet_Uri, 'Basic', DotNet_NetworkCredential);

        DotNet_HttpWebRequest.Credentials := DotNet_CredentialCache;
    end;

    local procedure AddSoapActionHeader(SoapAction: Text; var DotNet_HttpWebRequest: DotNet HttpWebRequest);
    begin
        if (SoapAction = '') then
            exit;

        DotNet_HttpWebRequest.Headers.Add('SOAPAction', SoapAction);
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
#if not CLEAN25

    [Obsolete('Replaced by HasJWTExpired(JsonWebToken: SecretText)', '25.0')]
    [NonDebuggable]
    procedure HasJWTExpired(JsonWebToken: Text): Boolean
    var
        JsonWebTokenAsSecretText: SecretText;
    begin
        JsonWebTokenAsSecretText := JsonWebToken;
        exit(HasJWTExpired(JsonWebTokenAsSecretText));
    end;
#endif

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
#if not CLEAN25

    [TryFunction]
    [NonDebuggable]
    [Obsolete('Replaced by GetTokenDetailsAsJson(JsonWebToken: SecretText; var WebTokenAsJson: Text)', '25.0')]
    procedure GetTokenDetailsAsJson(JsonWebToken: Text; var WebTokenAsJson: Text)
    var
        JsonWebTokenAsSecretText: SecretText;
    begin
        JsonWebTokenAsSecretText := JsonWebToken;
        GetTokenDetailsAsJson(JsonWebTokenAsSecretText, WebTokenAsJson);
    end;
#endif

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
#if not CLEAN25

    [TryFunction]
    [Obsolete('Replaced by GetTokenDetailsAsNameBuffer(JsonWebToken: SecretText; var Buffer: Record "Name/Value Buffer")', '25.0')]
    [NonDebuggable]
    procedure GetTokenDetailsAsNameBuffer(JsonWebToken: Text; var Buffer: Record "Name/Value Buffer")
    var
        JsonWebTokenAsSecretText: SecretText;
    begin
        JsonWebTokenAsSecretText := JsonWebToken;
        GetTokenDetailsAsNameBuffer(JsonWebTokenAsSecretText, Buffer)
    end;
#endif

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

