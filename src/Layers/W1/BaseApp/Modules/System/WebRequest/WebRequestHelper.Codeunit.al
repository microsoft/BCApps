namespace System.Integration;

using System;
using System.Utilities;

codeunit 1299 "Web Request Helper"
{

    trigger OnRun()
    begin
    end;

    var
        FileSchemeNotAllowedErr: Label 'The file scheme is not allowed.';
        InvalidEncodingErr: Label 'The text encoding is not specified or is not valid.';
        InvalidUriErr: Label 'The URI is not valid.';
        NonSecureUriErr: Label 'The URI is not secure.';
        RemoteServerErr: Label 'The remote server returned an error: (%1) %2.', Comment = '%1 = HTTP status code, for example 404; %2 = HTTP reason phrase, for example Not Found';
#if not CLEAN30
        ConnectionErr: Label 'Connection to the remote service could not be established.\\';
        ProcessingWindowMsg: Label 'Please wait while the server is processing your request.\This may take several minutes.';
#pragma warning disable AA0470
        ServiceURLTxt: Label '\\Service URL: %1.', Comment = 'Example: ServiceURL: http://www.contoso.com/';
#pragma warning restore AA0470
        GlobalHttpWebResponseError: DotNet HttpWebResponse;
#endif

    [TryFunction]
    procedure IsValidUri(Url: Text)
    var
        ResultUri: DotNet Uri;
        Uri: DotNet Uri;
        UriKind: DotNet UriKind;
    begin
        if not Uri.IsWellFormedUriString(Url, UriKind.Absolute) then
            if not Uri.TryCreate(Url, UriKind.Absolute, ResultUri) then
                Error(InvalidUriErr);
    end;

    [TryFunction]
    procedure IsValidUriWithoutProtocol(Url: Text)
    begin
        if not IsValidUri(Url) then
            if not IsValidUri('http://' + Url) then
                Error(InvalidUriErr);
    end;

    [TryFunction]
    procedure IsSecureHttpUrl(Url: Text)
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        if Uri.Scheme <> 'https' then
            Error(NonSecureUriErr);
    end;

    [TryFunction]
    procedure IsHttpUrl(Url: Text)
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        if (Uri.Scheme <> 'http') and (Uri.Scheme <> 'https') then
            Error(InvalidUriErr);
    end;

#if not CLEAN30
    [TryFunction]
    [NonDebuggable]
    [Scope('OnPrem')]
    [Obsolete('GetWebResponse relies on the .NET HttpWebRequest and HttpWebResponse types and is being phased out. Use the native HttpClient, HttpRequestMessage and HttpResponseMessage data types instead.', '30.0')]
    procedure GetWebResponse(var HttpWebRequest: DotNet HttpWebRequest; var HttpWebResponse: DotNet HttpWebResponse; var ResponseInStream: InStream; var HttpStatusCode: DotNet HttpStatusCode; var ResponseHeaders: DotNet NameValueCollection; ProgressDialogEnabled: Boolean)
    var
        ProcessingWindow: Dialog;
    begin
        if ProgressDialogEnabled then
            ProcessingWindow.Open(ProcessingWindowMsg);

        ClearLastError();
        HttpWebResponse := HttpWebRequest.GetResponse();
        HttpWebResponse.GetResponseStream().CopyTo(ResponseInStream);
        HttpStatusCode := HttpWebResponse.StatusCode;
        ResponseHeaders := HttpWebResponse.Headers;

        if ProgressDialogEnabled then
            ProcessingWindow.Close();
    end;

    [Scope('OnPrem')]
    [Obsolete('GetWebResponseError relies on the .NET WebException and HttpWebResponse types and is being phased out. Use the native HttpClient and HttpResponseMessage data types and inspect HttpResponseMessage.HttpStatusCode and HttpResponseMessage.Content instead.', '30.0')]
    procedure GetWebResponseError(var WebException: DotNet WebException; var ServiceURL: Text): Text
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebExceptionStatus: DotNet WebExceptionStatus;
        HttpStatusCode: DotNet HttpStatusCode;
        ErrorText: Text;
    begin
        DotNetExceptionHandler.Collect();

        if not DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)) then
            DotNetExceptionHandler.Rethrow();

        if not IsNull(WebException.Response) then
            if not IsNull(WebException.Response.ResponseUri) then
                ServiceURL := StrSubstNo(ServiceURLTxt, WebException.Response.ResponseUri.AbsoluteUri);

        ErrorText := ConnectionErr + WebException.Message + ServiceURL;
        if not WebException.Status.Equals(WebExceptionStatus.ProtocolError) then
            exit(ErrorText);

        if IsNull(WebException.Response) then
            DotNetExceptionHandler.Rethrow();

        GlobalHttpWebResponseError := WebException.Response;
        if not (GlobalHttpWebResponseError.StatusCode.Equals(HttpStatusCode.Found) or
                GlobalHttpWebResponseError.StatusCode.Equals(HttpStatusCode.InternalServerError))
        then
            exit(ErrorText);

        exit('');
    end;
#endif

    local procedure GetHttpStatusErrorMessage(HttpResponseMessage: HttpResponseMessage): Text
    begin
        exit(StrSubstNo(RemoteServerErr, HttpResponseMessage.HttpStatusCode(), HttpResponseMessage.ReasonPhrase()));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetResponseTextUsingCharset(Method: Text; Url: Text; AccessToken: SecretText; var ResponseText: Text)
    begin
        GetResponseTextInternal(Method, Url, AccessToken, ResponseText, false);
    end;

    [TryFunction]
    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure GetResponseTextInternal(Method: Text; Url: Text; AccessToken: SecretText; var ResponseText: Text; IgnoreCharSet: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        Uri: Codeunit Uri;
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        ResponseContentInStream: InStream;
        ResponseInputStream: InStream;
        ResponseOutStream: OutStream;
        TextEncodingVar: TextEncoding;
        ChunkText: Text;
    begin
        IsValidUri(Url);
        Uri.Init(Url);
        if Uri.GetScheme() = 'file' then
            Error(FileSchemeNotAllowedErr);

        HttpRequestMessage.Method(Method);
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.GetHeaders(RequestHeaders);
        // add the access token to the authorization bearer header
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));

        HttpClient.Send(HttpRequestMessage, HttpResponseMessage);
        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error(GetHttpStatusErrorMessage(HttpResponseMessage));

        HttpResponseMessage.Content().ReadAs(ResponseContentInStream);
        TempBlob.CreateOutStream(ResponseOutStream);
        CopyStream(ResponseOutStream, ResponseContentInStream);

        // We need to read using the right encoding, unless forced or unless no encoding can be determined
        if IgnoreCharSet then
            TempBlob.CreateInStream(ResponseInputStream)
        else
            if TryGetTextEncodingFromResponse(HttpResponseMessage, TextEncodingVar) then
                TempBlob.CreateInStream(ResponseInputStream, TextEncodingVar)
            else
                TempBlob.CreateInStream(ResponseInputStream); // Fallback to default encoding

        // the READTEXT() function apparently only reads a single line, so we must loop through the stream to get the contents of every line.
        while not ResponseInputStream.EOS() do begin
            ResponseInputStream.ReadText(ChunkText);
            ResponseText += ChunkText;
        end;
    end;

    [TryFunction]
    local procedure TryGetTextEncodingFromResponse(HttpResponseMessage: HttpResponseMessage; var EncodingToUse: TextEncoding)
    var
        ContentHeaders: HttpHeaders;
        ContentTypeValues: List of [Text];
        ContentTypeParameter: Text;
        CharSet: Text;
    begin
        // Both the header name and the content are case insensitive
        HttpResponseMessage.Content().GetHeaders(ContentHeaders);
        if not ContentHeaders.GetValues('Content-Type', ContentTypeValues) then
            Error(InvalidEncodingErr);

        if ContentTypeValues.Count() = 0 then
            Error(InvalidEncodingErr);

        foreach ContentTypeParameter in LowerCase(ContentTypeValues.Get(1)).Split(';') do begin
            ContentTypeParameter := DelChr(ContentTypeParameter, '<>', ' ');
            if ContentTypeParameter.StartsWith('charset=') then
                CharSet := DelChr(CopyStr(ContentTypeParameter, StrLen('charset=') + 1), '<>', ' "');
        end;

        case CharSet of
            'utf-8':
                EncodingToUse := TextEncoding::UTF8;
            else
                Error(InvalidEncodingErr);
        end;
    end;

    procedure GetHostNameFromUrl(Url: Text): Text
    var
        Uri: DotNet Uri;
    begin
        IsValidUri(Url);
        Uri := Uri.Uri(Url);
        exit(Uri.Host);
    end;

    procedure IsFailureStatusCode(TextStatusCode: Text): Boolean
    var
        IntStatusCode: Integer;
    begin
        if not Evaluate(IntStatusCode, TextStatusCode) then
            exit(false);

        exit(IntStatusCode > 399);
    end;
}
