namespace System.Integration;

using System;
using System.Utilities;

codeunit 1299 "Web Request Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ConnectionErr: Label 'Connection to the remote service could not be established.\\';
        InvalidEncodingErr: Label 'The text encoding is not specified or is not valid.';
        InvalidUriErr: Label 'The URI is not valid.';
        NonSecureUriErr: Label 'The URI is not secure.';
        ProcessingWindowMsg: Label 'Please wait while the server is processing your request.\This may take several minutes.';
#pragma warning disable AA0470
        ServiceURLTxt: Label '\\Service URL: %1.', Comment = 'Example: ServiceURL: http://www.contoso.com/';
#pragma warning restore AA0470
        GlobalHttpWebResponseError: DotNet HttpWebResponse;

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

    [TryFunction]
    [NonDebuggable]
    [Scope('OnPrem')]
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
#if not CLEAN25

    [TryFunction]
    [Scope('OnPrem')]
    [Obsolete('Replaced by GetResponseTextUsingCharset(Method: Text; Url: Text; AccessToken: SecretText; var ResponseText: Text)', '25.0')]
    procedure GetResponseTextUsingCharset(Method: Text; Url: Text; AccessToken: Text; var ResponseText: Text)
    var
        AccessTokenAsSecretText: SecretText;
    begin
        AccessTokenAsSecretText := AccessToken;
        GetResponseTextUsingCharset(Method, Url, AccessTokenAsSecretText, ResponseText);
    end;
#endif

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
        HttpWebRequest: DotNet HttpWebRequest;
        HttpWebResponse: DotNet HttpWebResponse;
        ResponseInputStream: InStream;
        TextEncodingVar: TextEncoding;
        ChunkText: Text;
    begin
        HttpWebRequest := HttpWebRequest.Create(Url);
        HttpWebRequest.Method := Method;
        HttpWebRequest.ContentLength := 0;
        // add the access token to the authorization bearer header
        HttpWebRequest.Headers().Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken).Unwrap());
        HttpWebResponse := HttpWebRequest.GetResponse();

        // We need to read using the right encoding, unless forced or unless no encoding can be determined
        if IgnoreCharSet then
            TempBlob.CreateInStream(ResponseInputStream)
        else
            if TryGetTextEncodingFromResponse(HttpWebResponse, TextEncodingVar) then
                TempBlob.CreateInStream(ResponseInputStream, TextEncodingVar)
            else
                TempBlob.CreateInStream(ResponseInputStream); // Fallback to default encoding

        HttpWebResponse.GetResponseStream().CopyTo(ResponseInputStream);

        // the READTEXT() function apparently only reads a single line, so we must loop through the stream to get the contents of every line.
        while not ResponseInputStream.EOS() do begin
            ResponseInputStream.ReadText(ChunkText);
            ResponseText += ChunkText;
        end;

        HttpWebResponse.Close(); // close connection
        HttpWebResponse.Dispose(); // cleanup of IDisposable
    end;

    [TryFunction]
    local procedure TryGetTextEncodingFromResponse(HttpWebResponse: DotNet HttpWebResponse; var EncodingToUse: TextEncoding)
    var
        HttpContentTypeHeader: Text;
        HttpContentType: DotNet HttpContentType;
    begin
        // Both the header name and the content are case insensitive; returns empty string if the header does not exist
        HttpContentTypeHeader := HttpWebResponse.GetResponseHeader('Content-Type').ToLowerInvariant();

        HttpContentType := HttpContentType.ContentType(HttpContentTypeHeader);

        if IsNull(HttpContentType.CharSet()) then
            Error(InvalidEncodingErr);

        if HttpContentType.CharSet() = '' then
            Error(InvalidEncodingErr);

        case HttpContentType.CharSet() of
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

