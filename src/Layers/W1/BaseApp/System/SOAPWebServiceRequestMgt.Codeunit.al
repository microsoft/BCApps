namespace System.Integration;

using Microsoft.Utilities;
using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

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
        GlobalUseDefaultCredentials: Boolean;

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
        HttpWebRequest.UseDefaultCredentials := GlobalUseDefaultCredentials;
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
#if not CLEAN30
        [NonDebuggable]
        DotNetXmlDoc: DotNet XmlDocument;
        [NonDebuggable]
        PasswordFromObsoleteEvent: Text;
#endif
        [NonDebuggable]
        XmlDoc: XmlDocument;
        BodyXmlNode: XmlNode;
        PasswordFromEvent: SecretText;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN30
#pragma warning disable AL0432
        OnBeforeCreateSoapRequest(RequestOutStream, BodyContentInStream, DotNetXmlDoc, UserName, PasswordFromObsoleteEvent, TraceLogEnabled, IsHandled);
#pragma warning restore AL0432
        if PasswordFromObsoleteEvent <> '' then
            Password := PasswordFromObsoleteEvent;
        if IsHandled then
            exit;
#endif
        OnBeforeCreateSoapRequestXml(RequestOutStream, BodyContentInStream, XmlDoc, Username, PasswordFromEvent, TraceLogEnabled, IsHandled);
        if not PasswordFromEvent.IsEmpty() then
            Password := PasswordFromEvent;
        if IsHandled then
            exit;

        CreateEnvelope(XmlDoc, BodyXmlNode, Username, Password);
        AddBodyToEnvelope(BodyXmlNode, BodyContentInStream);
        WriteXmlDocumentWithoutDeclaration(XmlDoc, RequestOutStream);
        TraceLogXmlDocToTempFile(XmlDoc, 'FullRequest');
    end;

    [NonDebuggable]
    local procedure CreateEnvelope(var XmlDoc: XmlDocument; var BodyXmlNode: XmlNode; Username: Text; Password: SecretText)
    var
        EnvelopeXmlElement: XmlElement;
        HeaderXmlElement: XmlElement;
        SecurityXmlElement: XmlElement;
        UsernameTokenXmlElement: XmlElement;
        PasswordXmlElement: XmlElement;
        BodyXmlElement: XmlElement;
    begin
        XmlDoc := XmlDocument.Create();
        EnvelopeXmlElement := XmlElement.Create('Envelope', SoapNamespaceTxt);
        EnvelopeXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration('s', SoapNamespaceTxt));
        EnvelopeXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration('u', SecurityUtilityNamespaceTxt));
        XmlDoc.Add(EnvelopeXmlElement);

        HeaderXmlElement := XmlElement.Create('Header', SoapNamespaceTxt);
        EnvelopeXmlElement.Add(HeaderXmlElement);

        if (Username <> '') or (not Password.IsEmpty()) then begin
            SecurityXmlElement := XmlElement.Create('Security', SecurityExtensionNamespaceTxt);
            SecurityXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration('o', SecurityExtensionNamespaceTxt));
            SecurityXmlElement.Add(XmlAttribute.Create('mustUnderstand', SoapNamespaceTxt, '1'));
            HeaderXmlElement.Add(SecurityXmlElement);

            UsernameTokenXmlElement := XmlElement.Create('UsernameToken', SecurityExtensionNamespaceTxt);
            UsernameTokenXmlElement.Add(XmlAttribute.Create('Id', SecurityUtilityNamespaceTxt, CreateUUID()));
            SecurityXmlElement.Add(UsernameTokenXmlElement);

            UsernameTokenXmlElement.Add(CreateElementWithText('Username', SecurityExtensionNamespaceTxt, Username));
            PasswordXmlElement := CreateElementWithText('Password', SecurityExtensionNamespaceTxt, Password.Unwrap());
            PasswordXmlElement.SetAttribute('Type', UsernameTokenNamepsaceTxt);
            UsernameTokenXmlElement.Add(PasswordXmlElement);
        end;

        BodyXmlElement := XmlElement.Create('Body', SoapNamespaceTxt);
        BodyXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration('xsi', SchemaInstanceNamespaceTxt));
        BodyXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration('xsd', SchemaNamespaceTxt));
        EnvelopeXmlElement.Add(BodyXmlElement);
        BodyXmlNode := BodyXmlElement.AsXmlNode();
    end;

    [NonDebuggable]
    local procedure CreateElementWithText(Name: Text; Namespace: Text; Content: Text): XmlElement
    begin
        if Content = '' then
            exit(XmlElement.Create(Name, Namespace));
        exit(XmlElement.Create(Name, Namespace, Content));
    end;

    local procedure CreateUUID(): Text
    begin
        exit('uuid-' + DelChr(LowerCase(Format(CreateGuid())), '=', '{}'));
    end;

    local procedure AddBodyToEnvelope(var BodyXmlNode: XmlNode; BodyInStream: InStream)
    var
        BodyContentXmlDoc: XmlDocument;
        BodyContentXmlElement: XmlElement;
    begin
        XmlDocument.ReadFrom(BodyInStream, BodyContentXmlDoc);
        TraceLogXmlDocToTempFile(BodyContentXmlDoc, 'RequestBodyContent');

        BodyContentXmlDoc.GetRoot(BodyContentXmlElement);
        BodyXmlNode.AsXmlElement().Add(BodyContentXmlElement);
    end;

    local procedure ExtractContentFromResponse(ResponseInStream: InStream; var TempBlobBody: Codeunit "Temp Blob")
    var
        ResponseXmlDoc: XmlDocument;
        ResponseBodyXmlDoc: XmlDocument;
        ResponseBodyXmlNode: XmlNode;
        ResponseContentXmlNode: XmlNode;
        ResponseContentXmlElement: XmlElement;
        XmlNamespaceManager: XmlNamespaceManager;
        BodyOutStream: OutStream;
    begin
        TraceLogStreamToTempFile(ResponseInStream, 'FullResponse', TempBlobDebugLog);
        if not XmlDocument.ReadFrom(ResponseInStream, ResponseXmlDoc) then
            Error(ExpectedResponseNotReceivedErr);

        XmlNamespaceManager.NameTable(ResponseXmlDoc.NameTable());
        XmlNamespaceManager.AddNamespace('soap', SoapNamespaceTxt);
        if not ResponseXmlDoc.SelectSingleNode(BodyPathTxt, XmlNamespaceManager, ResponseBodyXmlNode) then
            Error(ExpectedResponseNotReceivedErr);

        ResponseBodyXmlNode.AsXmlElement().GetChildElements().Get(1, ResponseContentXmlNode);
        ResponseContentXmlElement := ResponseContentXmlNode.AsXmlElement();
        AddInScopeNamespaceDeclarations(ResponseContentXmlElement);
        ResponseBodyXmlDoc := XmlDocument.Create();
        ResponseBodyXmlDoc.Add(ResponseContentXmlElement);

        TempBlobBody.CreateOutStream(BodyOutStream, GlobalStreamEncoding);
        WriteXmlDocumentWithoutDeclaration(ResponseBodyXmlDoc, BodyOutStream);
        TraceLogXmlDocToTempFile(ResponseBodyXmlDoc, 'ResponseBodyContent');
    end;

    [NonDebuggable]
    local procedure WriteXmlDocumentWithoutDeclaration(XmlDoc: XmlDocument; var DestinationOutStream: OutStream)
    var
        TempBlobXml: Codeunit "Temp Blob";
        RootXmlElement: XmlElement;
        XmlOutStream: OutStream;
        XmlInStream: InStream;
        XmlText: Text;
    begin
        // Write UTF-8 without an XML declaration or byte order mark, as XmlDocument.WriteTo always adds a declaration.
        XmlDoc.GetRoot(RootXmlElement);
        RootXmlElement.WriteTo(XmlText);
        TempBlobXml.CreateOutStream(XmlOutStream, TextEncoding::UTF8);
        XmlOutStream.WriteText(XmlText);
        TempBlobXml.CreateInStream(XmlInStream);
        CopyStream(DestinationOutStream, XmlInStream);
    end;

    local procedure AddInScopeNamespaceDeclarations(var ContentXmlElement: XmlElement)
    var
        AncestorXmlElement: XmlElement;
        AncestorXmlAttribute: XmlAttribute;
        DeclaredPrefixes: List of [Text];
    begin
        // Keep the namespace prefixes declared on the SOAP envelope when the content is moved to a separate document.
        CollectDeclaredPrefixes(ContentXmlElement, DeclaredPrefixes);
        if not ContentXmlElement.GetParent(AncestorXmlElement) then
            exit;
        repeat
            foreach AncestorXmlAttribute in AncestorXmlElement.Attributes() do
                if IsPrefixedNamespaceDeclaration(AncestorXmlAttribute) then
                    if not DeclaredPrefixes.Contains(AncestorXmlAttribute.LocalName()) then begin
                        ContentXmlElement.Add(XmlAttribute.CreateNamespaceDeclaration(AncestorXmlAttribute.LocalName(), AncestorXmlAttribute.Value()));
                        DeclaredPrefixes.Add(AncestorXmlAttribute.LocalName());
                    end;
        until not AncestorXmlElement.GetParent(AncestorXmlElement);
    end;

    local procedure CollectDeclaredPrefixes(ContentXmlElement: XmlElement; var DeclaredPrefixes: List of [Text])
    var
        ContentXmlAttribute: XmlAttribute;
    begin
        foreach ContentXmlAttribute in ContentXmlElement.Attributes() do
            if IsPrefixedNamespaceDeclaration(ContentXmlAttribute) then
                DeclaredPrefixes.Add(ContentXmlAttribute.LocalName());
    end;

    local procedure IsPrefixedNamespaceDeclaration(CurrentXmlAttribute: XmlAttribute): Boolean
    begin
        exit(CurrentXmlAttribute.IsNamespaceDeclaration() and (StrPos(CurrentXmlAttribute.Name(), 'xmlns:') = 1));
    end;
    procedure GetResponseContent(var ResponseBodyInStream: InStream)
    begin
        TempBlobResponseBody.CreateInStream(ResponseBodyInStream, GlobalStreamEncoding);
    end;

    procedure ProcessFaultResponse(SupportInfo: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        WebException: DotNet WebException;
        ResponseXmlDoc: XmlDocument;
        XmlNamespaceManager: XmlNamespaceManager;
        FaultStringXmlNode: XmlNode;
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

        if XmlDocument.ReadFrom(ResponseInputStream, ResponseXmlDoc) then begin
            XmlNamespaceManager.NameTable(ResponseXmlDoc.NameTable());
            XmlNamespaceManager.AddNamespace('soap', SoapNamespaceTxt);
            if ResponseXmlDoc.SelectSingleNode(FaultStringXmlPathTxt, XmlNamespaceManager, FaultStringXmlNode) then
                ErrorText := FaultStringXmlNode.AsXmlElement().InnerText();
        end;
        if ErrorText = '' then
            ErrorText := WebException.Message;
        ErrorText := InternalErr + ErrorText + ServiceURL;

        if SupportInfo <> '' then
            ErrorText += '\\' + SupportInfo;

        Error(ErrorText);
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

    local procedure TraceLogXmlDocToTempFile(XmlDoc: XmlDocument; Name: Text)
    var
        FileManagement: Codeunit "File Management";
        TempBlobTraceLog: Codeunit "Temp Blob";
        TraceLogOutStream: OutStream;
        Filename: Text;
    begin
        if not TraceLogEnabled then
            exit;

        Filename := FileManagement.ServerTempFileName(Name + '.XML');
        FileManagement.IsAllowedPath(Filename, false);
        TempBlobTraceLog.CreateOutStream(TraceLogOutStream);
        XmlDoc.WriteTo(TraceLogOutStream);
        FileManagement.BLOBExportToServerFile(TempBlobTraceLog, Filename);
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

#if not CLEAN30
    [IntegrationEvent(false, false)]
    [Obsolete('Use OnBeforeCreateSoapRequestXml instead.', '30.0')]
    local procedure OnBeforeCreateSoapRequest(var RequestOutStream: OutStream; var BodyContentInStream: InStream; var XmlDoc: DotNet XmlDocument; var Username: Text; var Password: Text; var TraceLogEnabled: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSoapRequestXml(var RequestOutStream: OutStream; var BodyContentInStream: InStream; var XmlDoc: XmlDocument; var Username: Text; var Password: SecretText; var TraceLogEnabled: Boolean; var IsHandled: Boolean)
    begin
    end;
}
