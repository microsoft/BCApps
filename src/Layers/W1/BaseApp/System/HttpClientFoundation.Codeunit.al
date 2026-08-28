// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using System.RestClient;
using System.Utilities;

/// <summary>Shared native HTTP request and response helpers.</summary>
codeunit 49990 "Http Client Foundation"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RestClient: Codeunit "Rest Client";
        TraceEnabled: Boolean;
        InvalidUrlErr: Label 'The URL is not valid.';
        NonSecureUrlErr: Label 'The URL is not secure.';
        TransportErr: Label 'The request to "%1" could not be sent: %2';
        HttpFailureErr: Label 'The request to "%1" failed with status code %2 %3.';

    /// <summary>Initializes the helper with the default native HTTP client.</summary>
    procedure Initialize()
    begin
        RestClient := RestClient.Create();
    end;

    /// <summary>Initializes the helper with a testable or custom HTTP client handler.</summary>
    procedure Initialize(HttpClientHandler: Interface "Http Client Handler")
    begin
        RestClient := RestClient.Create(HttpClientHandler);
    end;

    /// <summary>Sets the native HTTP client timeout.</summary>
    procedure SetTimeout(Timeout: Duration)
    begin
        RestClient.SetTimeOut(Timeout);
    end;

    /// <summary>Enables or disables request tracing through the integration events.</summary>
    procedure SetTraceEnabled(Enabled: Boolean)
    begin
        TraceEnabled := Enabled;
    end;

    /// <summary>Creates a request with the supplied method, URI, and content.</summary>
    procedure CreateRequest(Method: Enum "Http Method"; Uri: Text; Content: Codeunit "Http Content"; var Request: Codeunit "Http Request Message")
    begin
        Request := Request.Create(Method, Uri, Content);
    end;

    /// <summary>Creates a request with no body.</summary>
    procedure CreateRequest(Method: Enum "Http Method"; Uri: Text; var Request: Codeunit "Http Request Message")
    var
        EmptyContent: Codeunit "Http Content";
    begin
        CreateRequest(Method, Uri, EmptyContent, Request);
    end;

    /// <summary>Creates a request whose URI remains secret.</summary>
    [NonDebuggable]
    procedure CreateSecretRequest(Method: Enum "Http Method"; Uri: SecretText; Content: Codeunit "Http Content"; var Request: Codeunit "Http Request Message")
    var
        NativeRequest: HttpRequestMessage;
    begin
        NativeRequest.Method := Format(Method);
        NativeRequest.SetSecretRequestUri(Uri);
        NativeRequest.Content := Content.GetHttpContent();
        Request.SetHttpRequestMessage(NativeRequest);
    end;

    /// <summary>Adds or replaces a request header.</summary>
    procedure AddHeader(var Request: Codeunit "Http Request Message"; Name: Text; Value: Text)
    begin
        Request.SetHeader(Name, Value);
    end;

    /// <summary>Adds or replaces a secret request header without materializing the secret.</summary>
    [NonDebuggable]
    procedure AddHeader(var Request: Codeunit "Http Request Message"; Name: Text; Value: SecretText)
    begin
        Request.SetHeader(Name, Value);
    end;

    /// <summary>Adds a Basic authorization header using a secret password.</summary>
    [NonDebuggable]
    procedure AddBasicAuthentication(var Request: Codeunit "Http Request Message"; Username: Text; Password: SecretText)
    var
        Base64Convert: Codeunit "Base64 Convert";
        Credentials: SecretText;
    begin
        Credentials := SecretStrSubstNo('%1:%2', Username, Password);
        AddHeader(Request, 'Authorization', SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(Credentials)));
    end;

    /// <summary>Sends a request and returns false for transport or HTTP-level failures.</summary>
    procedure Send(var Request: Codeunit "Http Request Message"; var Response: Codeunit "Http Response Message"; var ErrorMessage: Text; var ErrorDetails: Text): Boolean
    begin
        Clear(ErrorMessage);
        Clear(ErrorDetails);

        if TraceEnabled then
            OnBeforeSend(Request);

        if not TrySend(Request, Response) then begin
            ErrorMessage := StrSubstNo(TransportErr, Request.GetRequestUri(), GetLastErrorText());
            exit(false);
        end;

        if TraceEnabled then
            OnAfterSend(Request, Response);

        if Response.GetIsSuccessStatusCode() then
            exit(true);

        ErrorMessage := StrSubstNo(HttpFailureErr, Request.GetRequestUri(), Response.GetHttpStatusCode(), Response.GetReasonPhrase());
        ErrorDetails := Response.GetContent().AsText();
        exit(false);
    end;

    /// <summary>Reads a successful response as text.</summary>
    procedure SendAndReadText(var Request: Codeunit "Http Request Message"; var ResponseBody: Text; var ErrorMessage: Text; var ErrorDetails: Text; var Response: Codeunit "Http Response Message"): Boolean
    begin
        Clear(ResponseBody);
        if not Send(Request, Response, ErrorMessage, ErrorDetails) then
            exit(false);

        ResponseBody := Response.GetContent().AsText();
        exit(true);
    end;

    /// <summary>Reads a successful response into a temporary blob.</summary>
    procedure SendAndReadBlob(var Request: Codeunit "Http Request Message"; var ResponseBlob: Codeunit "Temp Blob"; var ErrorMessage: Text; var ErrorDetails: Text; var Response: Codeunit "Http Response Message"): Boolean
    begin
        Clear(ResponseBlob);
        if not Send(Request, Response, ErrorMessage, ErrorDetails) then
            exit(false);

        ResponseBlob := Response.GetContent().AsBlob();
        exit(true);
    end;

    /// <summary>Validates an absolute URL and requires HTTPS unless explicitly allowed.</summary>
    [TryFunction]
    procedure ValidateUrl(Uri: Text; AllowHttp: Boolean)
    var
        UriHelper: Codeunit Uri;
    begin
        if not UriHelper.IsWellFormedUriString(Uri, Enum::UriKind::Absolute) then
            Error(InvalidUrlErr);

        UriHelper.Init(Uri);
        if not AllowHttp and (UriHelper.GetScheme() <> 'https') then
            Error(NonSecureUrlErr);
    end;

    /// <summary>Returns the response headers from a native response.</summary>
    procedure GetResponseHeaders(Response: Codeunit "Http Response Message") Headers: HttpHeaders
    begin
        Headers := Response.GetHeaders();
    end;

    [TryFunction]
    local procedure TrySend(var Request: Codeunit "Http Request Message"; var Response: Codeunit "Http Response Message")
    begin
        Response := RestClient.Send(Request);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSend(var Request: Codeunit "Http Request Message")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSend(var Request: Codeunit "Http Request Message"; var Response: Codeunit "Http Response Message")
    begin
    end;
}
