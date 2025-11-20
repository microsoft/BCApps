namespace System.Integration;

using System;
using System.Environment;
using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;
using System.Xml;

codeunit 1297 "Http Web Request Mgt."
{
    var
        [NonDebuggable]
        HttpWebRequest: DotNet HttpWebRequest;
        TraceLogEnabled: Boolean;
        InvalidUrlErr: Label 'The URL is not valid.';
        NonSecureUrlErr: Label 'The URL is not secure.';
        GlobalSkipCheckHttps: Boolean;
        GlobalProgressDialogEnabled: Boolean;
        InternalErr: Label 'The remote service has returned the following error message:\\';
        NoCookieForYouErr: Label 'The web request has no cookies.';
        TimeoutErr: Label 'The server timed out waiting for the request.';

    [Scope('OnPrem')]
    procedure GetResponse(var ResponseInStream: InStream; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebResponse: DotNet HttpWebResponse;
    begin
        exit(WebRequestHelper.GetWebResponse(HttpWebRequest, HttpWebResponse, ResponseInStream, HttpStatusCode,
            ResponseHeaders, GlobalProgressDialogEnabled));
    end;

    [Scope('OnPrem')]
    procedure GetResponseStream(var ResponseInStream: InStream): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        HttpWebResponse: DotNet HttpWebResponse;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        exit(WebRequestHelper.GetWebResponse(HttpWebRequest, HttpWebResponse, ResponseInStream, HttpStatusCode,
            ResponseHeaders, GlobalProgressDialogEnabled));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ProcessFaultResponse(SupportInfo: Text)
    begin
        ProcessFaultXMLResponse(SupportInfo, '', '', '');
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ProcessFaultXMLResponse(SupportInfo: Text; NodePath: Text; Prefix: Text; NameSpace: Text)
    var
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        ProcessFaultXMLResponse(SupportInfo, NodePath, Prefix, NameSpace, HttpStatusCode, ResponseHeaders);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ProcessFaultXMLResponse(SupportInfo: Text; NodePath: Text; Prefix: Text; NameSpace: Text; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection)
    var
        TempBlobReturn: Codeunit "Temp Blob";
        WebRequestHelper: Codeunit "Web Request Helper";
        XMLDOMMgt: Codeunit "XML DOM Management";
        WebException: DotNet WebException;
        WebExceptionResponse: DotNet HttpWebResponse;
        XmlDoc: DotNet XmlDocument;
        ResponseInputStream: InStream;
        ErrorText: Text;
        ServiceURL: Text;
    begin
        ErrorText := WebRequestHelper.GetWebResponseError(WebException, ServiceURL);

        WebExceptionResponse := WebException.Response();
        if not IsNull(WebExceptionResponse) then begin
            HttpStatusCode := WebExceptionResponse.StatusCode();
            ResponseHeaders := WebExceptionResponse.Headers();
            ResponseInputStream := WebExceptionResponse.GetResponseStream();

            TraceLogStreamToTempFile(ResponseInputStream, 'WebExceptionResponse', TempBlobReturn);

            if NodePath <> '' then
                if TryLoadXMLResponse(ResponseInputStream, XmlDoc) then
                    if Prefix = '' then
                        ErrorText := XMLDOMMgt.FindNodeText(XmlDoc.DocumentElement, NodePath)
                    else
                        ErrorText := XMLDOMMgt.FindNodeTextWithNamespace(XmlDoc.DocumentElement, NodePath, Prefix, NameSpace);
        end;

        if ErrorText = '' then
            ErrorText := WebException.Message;

        ErrorText := InternalErr + ErrorText;

        if SupportInfo <> '' then
            ErrorText += '\\' + SupportInfo;

        Error(ErrorText);
    end;

    [TryFunction]
    procedure ProcessFaultJsonResponse(var ResponseJson: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        WebException: DotNet WebException;
        ServiceURL: Text;
        HttpError: Text;
    begin
        ResponseJson := '';
        HttpError := WebRequestHelper.GetWebResponseError(WebException, ServiceURL);
        ParseWebResponseError(ResponseJson, WebException);

        if ResponseJson = '' then
            Error(HttpError);
    end;

    procedure ParseFaultJsonResponse(ResponseJson: Text): Text
    var
        JSONMgt: Codeunit "JSON Management";
        "code": Text;
        name: Text;
        description: Text;
    begin
        if JSONMgt.GetJsonWebResponseError(ResponseJson, code, name, description) then
            exit(StrSubstNo('Http error %1 (%2)\%3', code, name, description));
    end;

    [TryFunction]
    procedure CheckUrl(Url: Text)
    var
        Uri: DotNet Uri;
        UriKind: DotNet UriKind;
    begin
        if not Uri.TryCreate(Url, UriKind.Absolute, Uri) then
            Error(InvalidUrlErr);

        if not GlobalSkipCheckHttps and not (Uri.Scheme = 'https') then
            Error(NonSecureUrlErr);
    end;

    [Scope('OnPrem')]
    procedure GetUrl(): Text
    begin
        exit(HttpWebRequest.RequestUri.AbsoluteUri);
    end;

    [Scope('OnPrem')]
    procedure GetUri(): Text
    begin
        exit(HttpWebRequest.RequestUri.PathAndQuery);
    end;

    [Scope('OnPrem')]
    procedure GetMethod(): Text
    begin
        exit(HttpWebRequest.Method);
    end;

    local procedure TraceLogStreamToTempFile(var ToLogInStream: InStream; Name: Text; var TempBlobTraceLog: Codeunit "Temp Blob")
    var
        Trace: Codeunit Trace;
    begin
        if TraceLogEnabled then
            Trace.LogStreamToTempFile(ToLogInStream, Name, TempBlobTraceLog);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure TryLoadXMLResponse(ResponseInputStream: InStream; var XmlDoc: DotNet XmlDocument)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
    begin
        XMLDOMManagement.LoadXMLDocumentFromInStream(ResponseInputStream, XmlDoc);
    end;

    procedure SetTraceLogEnabled(Enabled: Boolean)
    begin
        TraceLogEnabled := Enabled;
    end;

    procedure DisableUI()
    begin
        GlobalProgressDialogEnabled := false;
    end;

    [Scope('OnPrem')]
    procedure Initialize(URL: Text)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not EnvironmentInfo.IsSaaS() then
            OnOverrideUrl(URL);

        HttpWebRequest := HttpWebRequest.Create(URL);
        SetDefaults();
    end;

    local procedure SetDefaults()
    var
        CookieContainer: DotNet CookieContainer;
    begin
        HttpWebRequest.Method := 'GET';
        HttpWebRequest.KeepAlive := true;
        HttpWebRequest.AllowAutoRedirect := true;
        HttpWebRequest.UseDefaultCredentials := true;
        HttpWebRequest.Timeout := 60000;
        HttpWebRequest.Accept('application/xml');
        HttpWebRequest.ContentType('application/xml');
        CookieContainer := CookieContainer.CookieContainer();
        HttpWebRequest.CookieContainer := CookieContainer;

        GlobalSkipCheckHttps := true;
        GlobalProgressDialogEnabled := GuiAllowed;
        TraceLogEnabled := true;
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AddBodyAsText(BodyText: Text)
    var
        Encoding: DotNet Encoding;
    begin
        // Assume UTF8
        AddBodyAsTextWithEncoding(BodyText, Encoding.UTF8);
    end;

    [Scope('OnPrem')]
    procedure AddBodyAsAsciiText(BodyText: Text)
    var
        Encoding: DotNet Encoding;
    begin
        AddBodyAsTextWithEncoding(BodyText, Encoding.ASCII);
    end;

    internal procedure AddBodyAsTextWithEncoding(BodyText: Text; Encoding: DotNet Encoding)
    var
        RequestStr: DotNet Stream;
        StreamWriter: DotNet StreamWriter;
    begin
        RequestStr := HttpWebRequest.GetRequestStream();
        StreamWriter := StreamWriter.StreamWriter(RequestStr, Encoding);
        StreamWriter.Write(BodyText);
        StreamWriter.Flush();
        StreamWriter.Close();
        StreamWriter.Dispose();
    end;

    [Scope('OnPrem')]
    procedure SetTimeout(NewTimeout: Integer)
    begin
        HttpWebRequest.Timeout := NewTimeout;
    end;

    [Scope('OnPrem')]
    procedure SetMethod(Method: Text)
    begin
        HttpWebRequest.Method := Method;
    end;

    [Scope('OnPrem')]
    procedure SetDecompresionMethod(DecompressionMethod: DotNet DecompressionMethods)
    begin
        HttpWebRequest.AutomaticDecompression := DecompressionMethod;
    end;

    [Scope('OnPrem')]
    procedure SetContentType(ContentType: Text)
    begin
        HttpWebRequest.ContentType := ContentType;
    end;

    [Scope('OnPrem')]
    procedure SetReturnType(ReturnType: Text)
    begin
        HttpWebRequest.Accept := ReturnType;
    end;

    [Scope('OnPrem')]
    procedure SetProxy(ProxyUrl: Text)
    var
        WebProxy: DotNet WebProxy;
    begin
        if ProxyUrl = '' then
            exit;

        WebProxy := WebProxy.WebProxy(ProxyUrl);

        HttpWebRequest.Proxy := WebProxy;
    end;

    procedure SetExpect(expectValue: Boolean)
    begin
        HttpWebRequest.ServicePoint.Expect100Continue := expectValue;
    end;

    [Scope('OnPrem')]
    procedure SetContentLength(ContentLength: BigInteger)
    begin
        HttpWebRequest.ContentLength := ContentLength;
    end;

    [Scope('OnPrem')]
    procedure AddSecurityProtocolTls12()
    var
        Convert: DotNet Convert;
        SecurityProtocolType: DotNet SecurityProtocolType;
        SecurityProtocol: Integer;
    begin
        SecurityProtocol := Convert.ToInt32(SecurityProtocolType.Tls12);
        AddSecurityProtocol(SecurityProtocol);
    end;

    local procedure AddSecurityProtocol(SecurityProtocol: Integer)
    var
        TypeHelper: Codeunit "Type Helper";
        Convert: DotNet Convert;
        ServicePointManager: DotNet ServicePointManager;
        CurrentSecurityProtocol: Integer;
    begin
        CurrentSecurityProtocol := Convert.ToInt32(ServicePointManager.SecurityProtocol);
        if TypeHelper.BitwiseAnd(CurrentSecurityProtocol, SecurityProtocol) <> SecurityProtocol then
            ServicePointManager.SecurityProtocol := TypeHelper.BitwiseOr(CurrentSecurityProtocol, SecurityProtocol);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AddHeader("Key": Text; Value: Text)
    begin
        case Key of
            'Accept':
                SetReturnType(Value);
            'Content-Type':
                SetContentType(Value);
            else
                HttpWebRequest.Headers.Add(Key, Value);
        end;
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure AddHeader("Key": Text; Value: SecretText)
    begin
        HttpWebRequest.Headers.Add(Key, Value.Unwrap());
    end;

    [Scope('OnPrem')]
    procedure AddBody(BodyFilePath: Text)
    var
        FileManagement: Codeunit "File Management";
        FileStream: DotNet FileStream;
        FileMode: DotNet FileMode;
    begin
        if BodyFilePath = '' then
            exit;

        FileManagement.IsAllowedPath(BodyFilePath, false);

        FileStream := FileStream.FileStream(BodyFilePath, FileMode.Open);
        FileStream.CopyTo(HttpWebRequest.GetRequestStream());
    end;

    [Scope('OnPrem')]
    procedure AddBodyBlob(var TempBlob: Codeunit "Temp Blob")
    var
        RequestStr: DotNet Stream;
        BlobStr: InStream;
    begin
        if not TempBlob.HasValue() then
            exit;

        RequestStr := HttpWebRequest.GetRequestStream();
        TempBlob.CreateInStream(BlobStr);
        CopyStream(RequestStr, BlobStr);
        RequestStr.Flush();
        RequestStr.Close();
        RequestStr.Dispose();
    end;
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by AddBasicAuthentication(BasicUserId: Text; BasicUserPassword: SecretText)', '25.0')]
    procedure AddBasicAuthentication(BasicUserId: Text; BasicUserPassword: Text)
    var
        BasicUserPasswordAsSecretText: SecretText;
    begin
        BasicUserPasswordAsSecretText := BasicUserPassword;
        AddBasicAuthentication(BasicUserId, BasicUserPasswordAsSecretText);
    end;
#endif

    [NonDebuggable]
    procedure AddBasicAuthentication(BasicUserId: Text; BasicUserPassword: SecretText)
    var
        Credential: DotNet NetworkCredential;
    begin
        HttpWebRequest.UseDefaultCredentials(false);
        Credential := Credential.NetworkCredential();
        Credential.UserName := BasicUserId;
        Credential.Password := BasicUserPassword.Unwrap();
        HttpWebRequest.Credentials := Credential;
    end;

    [Scope('OnPrem')]
    procedure SetUserAgent(UserAgent: Text)
    begin
        HttpWebRequest.UserAgent := UserAgent;
    end;

    [Scope('OnPrem')]
    procedure SetCookie(var Cookie: DotNet Cookie)
    begin
        HttpWebRequest.CookieContainer.Add(Cookie);
    end;

    [Scope('OnPrem')]
    procedure GetCookie(var Cookie: DotNet Cookie)
    var
        CookieCollection: DotNet CookieCollection;
    begin
        if not HasCookie() then
            Error(NoCookieForYouErr);
        CookieCollection := HttpWebRequest.CookieContainer.GetCookies(HttpWebRequest.RequestUri);
        Cookie := CookieCollection.Item(0);
    end;

    [Scope('OnPrem')]
    procedure HasCookie(): Boolean
    begin
        exit(HttpWebRequest.CookieContainer.Count > 0);
    end;

    procedure CreateInstream(var InStr: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        TempBlob.CreateInStream(InStr);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnOverrideUrl(var Url: Text)
    begin
        // Provides an option to rewrite URL in non SaaS environments.
    end;

    [Scope('OnPrem')]
    procedure SendRequestAndReadTextResponse(var ResponseBody: Text; var ErrorMessage: Text; var ErrorDetails: Text; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
        TextLine: Text;
    begin
        if not SendRequestAndReadResponse(TempBlob, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then
            exit(false);

        TempBlob.CreateInStream(ResponseInStream);
        while ResponseInStream.ReadText(TextLine) > 0 do
            ResponseBody += TextLine;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SendRequestAndReadResponse(var TempBlob: Codeunit "Temp Blob"; var ErrorMessage: Text; var ErrorDetails: Text; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection): Boolean
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        WebException: DotNet WebException;
        WebExceptionResponse: DotNet HttpWebResponse;
        ResponseInStream: InStream;
        WebExceptionResponseText: Text;
        TextLine: Text;
        ServiceUrl: Text;
    begin
        TempBlob.CreateInStream(ResponseInStream);

        ClearLastError();
        if GetResponse(ResponseInStream, HttpStatusCode, ResponseHeaders) then
            exit(true);

        ErrorMessage := GetLastErrorText;

        WebRequestHelper.GetWebResponseError(WebException, ServiceUrl);
        WebExceptionResponse := WebException.Response;
        if SYSTEM.IsNull(WebExceptionResponse) then
            exit(false);

        HttpStatusCode := WebExceptionResponse.StatusCode;
        ResponseHeaders := WebExceptionResponse.Headers;
        WebExceptionResponse.GetResponseStream().CopyTo(ResponseInStream);
        while ResponseInStream.ReadText(TextLine) > 0 do
            WebExceptionResponseText += TextLine;

        ErrorDetails := WebExceptionResponseText;

        exit(false);
    end;

    local procedure SetJSONContent(var ResponseJson: Text; ResponseInStream: InStream): Boolean
    var
        JSONMgt: Codeunit "JSON Management";
        ContentJson: Text;
        Content: Text;
    begin
        if ResponseInStream.Read(Content) = 0 then
            exit(true);

        if not JSONMgt.InitializeFromString(Content) then
            exit(false);

        ContentJson := JSONMgt.WriteObjectToString();
        JSONMgt.InitializeObject(ResponseJson);
        JSONMgt.AddJson('Content', ContentJson);
        ResponseJson := JSONMgt.WriteObjectToString();
        exit(true);
    end;

    local procedure ParseWebResponseError(var ResponseJson: Text; WebException: DotNet WebException)
    var
        JSONMgt: Codeunit "JSON Management";
        HttpWebResponse: DotNet HttpWebResponse;
        Convert: DotNet Convert;
        WebExceptionStatus: DotNet WebExceptionStatus;
        ResponseInputStream: InStream;
        ErrorDescription: Text;
        StatusCode: Text;
        StatusCodeString: Text;
        WebExceptionResponse: Boolean;
    begin
        if IsNull(WebException) then
            exit;

        case true of
            WebException.Status.Equals(WebExceptionStatus.Timeout):
                begin
                    StatusCode := '408';
                    StatusCodeString := 'Request Timeout';
                    ErrorDescription := TimeoutErr;
                end;
            not IsNull(WebException.Response):
                begin
                    WebExceptionResponse := true;
                    HttpWebResponse := WebException.Response;
                    StatusCode := Format(Convert.ToInt32(HttpWebResponse.StatusCode));
                    StatusCodeString := HttpWebResponse.StatusCode.ToString();
                    ErrorDescription := HttpWebResponse.StatusDescription;
                end;
            else
                exit;
        end;

        JSONMgt.SetJsonWebResponseError(ResponseJson, StatusCode, StatusCodeString, ErrorDescription);

        // Try to get more details
        if WebExceptionResponse then begin
            ResponseInputStream := HttpWebResponse.GetResponseStream();
            if SetJSONContent(ResponseJson, ResponseInputStream) then
                if JSONMgt.InitializeFromString(ResponseJson) then begin
                    ErrorDescription := JSONMgt.GetValue('Content.error_description');
                    if ErrorDescription <> '' then begin
                        JSONMgt.SetValue('Error.description', ErrorDescription);
                        ResponseJson := JSONMgt.WriteObjectToString();
                    end;
                end;
        end;
    end;
}

