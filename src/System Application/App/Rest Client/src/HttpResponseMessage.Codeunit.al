// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

/// <summary>Holder object for the HTTP response data.</summary>
codeunit 2356 "Http Response Message"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        HttpResponseMessageImpl: Codeunit "Http Response Message Impl.";

    #region Constructors
    /// <summary>Initializes a new instance of the HttpResponseMessage class.</summary>
    /// <param name="HttpResponseMessage">The HTTP response message.</param>
    /// <returns>The HttpResponseMessage object.</returns>
    procedure Create(HttpResponseMessage: HttpResponseMessage): Codeunit "Http Response Message"
    begin
        HttpResponseMessageImpl := HttpResponseMessageImpl.Create(HttpResponseMessage);
        exit(this);
    end;
    #endregion

    #region IsBlockedByEnvironment
    /// <summary>Sets whether the request is blocked by the environment.</summary>
    /// <param name="Value">True if the request is blocked by the environment; otherwise, false.</param>
    procedure SetIsBlockedByEnvironment(Value: Boolean)
    begin
        HttpResponseMessageImpl.SetIsBlockedByEnvironment(Value);
    end;

    /// <summary>Gets whether the request is blocked by the environment.</summary>
    /// <returns>True if the request is blocked by the environment; otherwise, false.</returns>
    procedure GetIsBlockedByEnvironment() ReturnValue: Boolean
    begin
        ReturnValue := HttpResponseMessageImpl.GetIsBlockedByEnvironment();
    end;
    #endregion

    #region HttpStatusCode
    procedure SetHttpStatusCode(Value: Integer)
    begin
        HttpResponseMessageImpl.SetHttpStatusCode(Value);
    end;

    /// <summary>Gets the HTTP status code of the response message.</summary>
    /// <returns>The HTTP status code.</returns>
    procedure GetHttpStatusCode() ReturnValue: Integer
    begin
        ReturnValue := HttpResponseMessageImpl.GetHttpStatusCode();
    end;
    #endregion

    #region IsSuccessStatusCode
    /// <summary>Sets whether the HTTP response message has a success status code.</summary>
    /// <param name="Value">True if the HTTP response message has a success status code; otherwise, false.</param>
    /// <remarks>Any value in the HTTP status code range 2xx is considered to be successful.</remarks>
    procedure SetIsSuccessStatusCode(Value: Boolean)
    begin
        HttpResponseMessageImpl.SetIsSuccessStatusCode(Value);
    end;

    /// <summary>Indicates whether the HTTP response message has a success status code.</summary>
    /// <returns>True if the HTTP response message has a success status code; otherwise, false.</returns>
    /// <remarks>Any value in the HTTP status code range 2xx is considered to be successful.</remarks>
    procedure GetIsSuccessStatusCode() Result: Boolean
    begin
        Result := HttpResponseMessageImpl.GetIsSuccessStatusCode();
    end;

    #endregion

    #region ReasonPhrase
    /// <summary>Sets the reason phrase which typically is sent by servers together with the status code.</summary>
    /// <param name="Value">The reason phrase sent by the server.</param>
    procedure SetReasonPhrase(Value: Text)
    begin
        HttpResponseMessageImpl.SetReasonPhrase(Value);
    end;

    /// <summary>Gets the reason phrase which typically is sent by servers together with the status code.</summary>
    /// <returns>The reason phrase sent by the server.</returns>
    procedure GetReasonPhrase() ReturnValue: Text
    begin
        ReturnValue := HttpResponseMessageImpl.GetReasonPhrase();
    end;
    #endregion

    #region HttpContent
    /// <summary>Sets the HTTP content sent back by the server.</summary>
    /// <param name="Content">The content of the HTTP response message.</param>
    procedure SetContent(Content: Codeunit "Http Content")
    begin
        HttpResponseMessageImpl.SetContent(Content);
    end;

    /// <summary>Gets the HTTP content sent back by the server.</summary>
    /// <returns>The content of the HTTP response message.</returns>
    procedure GetContent() ReturnValue: Codeunit "Http Content"
    begin
        ReturnValue := HttpResponseMessageImpl.GetContent();
    end;
    #endregion

    #region HttpResponseMessage
    /// <summary>Sets the HTTP response message.</summary>
    /// <param name="ResponseMessage">The HTTP response message.</param>
    procedure SetResponseMessage(ResponseMessage: HttpResponseMessage)
    begin
        HttpResponseMessageImpl.SetResponseMessage(ResponseMessage);
    end;

    /// <summary>Gets the HTTP response message.</summary>
    /// <returns>The HTTPResponseMessage object.</returns>
    procedure GetResponseMessage() ReturnValue: HttpResponseMessage
    begin
        ReturnValue := HttpResponseMessageImpl.GetResponseMessage();
    end;
    #endregion

    #region HttpHeaders
    /// <summary>Sets the HTTP headers.</summary>
    /// <param name="Headers">The HTTP headers.</param>
    procedure SetHeaders(Headers: HttpHeaders)
    begin
        HttpResponseMessageImpl.SetHeaders(Headers);
    end;

    /// <summary>Gets the HTTP headers.</summary>
    /// <returns>The HTTP headers.</returns>
    procedure GetHeaders() ReturnValue: HttpHeaders
    begin
        ReturnValue := HttpResponseMessageImpl.GetHeaders();

    end;
    #endregion

    #region Cookies
    /// <summary>Sets the cookies in the HTTP response message.</summary>
    /// <param name="Cookies">The cookies to set.</param>
    procedure SetCookies(Cookies: Dictionary of [Text, Cookie])
    begin
        HttpResponseMessageImpl.SetCookies(Cookies);
    end;

    /// <summary>Gets the cookies in the HTTP response message.</summary>
    /// <returns>The cookies in the HTTP response message.</returns>
    procedure GetCookies() ReturnValue: Dictionary of [Text, Cookie]
    begin
        ReturnValue := HttpResponseMessageImpl.GetCookies();
    end;

    /// <summary>Gets the names of the cookies that are set in the HTTP response message.</summary>
    /// <returns>The names of the cookies that are set in the HTTP response message.</returns>
    procedure GetCookieNames() ReturnValue: List of [Text]
    begin
        ReturnValue := HttpResponseMessageImpl.GetCookieNames();
    end;

    /// <summary>Gets the cookie with the given name from the HTTP response message.</summary>
    /// <param name="Name">The name of the cookie to get.</param>
    /// <returns>The cookie object.</returns>
    /// <remarks>If the cookie is not found, an empty cookie object is returned.</remarks>
    procedure GetCookie(Name: Text) ReturnValue: Cookie
    begin
        ReturnValue := HttpResponseMessageImpl.GetCookie(Name);
    end;

    /// <summary>Gets the cookie with the given name from the HTTP response message.</summary>
    /// <param name="Name">The name of the cookie to get.</param>
    /// <param name="Cookie">The cookie object to get.</param>
    /// <returns>True if the cookie was found, false otherwise.</returns>
    procedure GetCookie(Name: Text; var Cookie: Cookie) Success: Boolean
    begin
        Success := HttpResponseMessageImpl.GetCookie(Name, Cookie);
    end;
    #endregion

    #region ErrorMessage
    /// <summary>Sets an error message when the request failed.</summary>
    /// <param name="Value">The error message.</param>
    procedure SetErrorMessage(Value: Text)
    begin
        HttpResponseMessageImpl.SetErrorMessage(Value);
    end;

    /// <summary>Gets the error message when the request failed.</summary>
    /// <returns>The error message.</returns>
    procedure GetErrorMessage() ReturnValue: Text
    begin
        ReturnValue := HttpResponseMessageImpl.GetErrorMessage();
    end;

    /// <summary>Sets the exception information when the request failed.</summary>
    /// <param name="Exception">The exception information.</param>
    procedure SetException(Exception: ErrorInfo)
    begin
        HttpResponseMessageImpl.SetException(Exception);
    end;

    /// <summary>Gets the exception information when the request failed.</summary>
    /// <returns>The exception information.</returns>
    procedure GetException() Exception: ErrorInfo
    begin
        Exception := HttpResponseMessageImpl.GetException();
    end;
    #endregion
}