// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

/// <summary>Holder object for the HTTP request data.</summary>
codeunit 2352 "Http Request Message"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        HttpRequestMessageImpl: Codeunit "Http Request Message Impl.";

    /// <summary>Creates a new instance of the HttpRequestMessage object.</summary>
    /// <param name="Method">The HTTP method to use. Valid options are GET, POST, PATCH, PUT, DELETE, HEAD, OPTIONS</param>
    /// <param name="RequestUri">The Uri to use for the HTTP request.</param>
    /// <param name="Content">The Http Content object to use for the HTTP request.</param>
    /// <returns>The create Http Request Message</returns>
    procedure Create(Method: Enum "Http Method"; RequestUri: Text; Content: Codeunit "Http Content") HttpRequestMessage: Codeunit "Http Request Message"
    begin
        HttpRequestMessageImpl := HttpRequestMessageImpl.Create(Method, RequestUri, Content);
        HttpRequestMessage := this;
    end;

    /// <summary>Sets the HTTP method or the HttpRequestMessage object.</summary>
    /// <param name="Method">The HTTP method to use. Valid options are GET, POST, PATCH, PUT, DELETE, HEAD, OPTIONS</param>
    /// <remarks>Default method is GET</remarks>
    procedure SetHttpMethod(Method: Text)
    begin
        HttpRequestMessageImpl.SetHttpMethod(Method);
    end;

    /// <summary>Sets the HTTP method for the HttpRequestMessage object.</summary>
    /// <param name="Method">The HTTP method to use.</param>
    /// <remarks>Default method is GET</remarks>
    procedure SetHttpMethod(Method: Enum "Http Method")
    begin
        HttpRequestMessageImpl.SetHttpMethod(Method);
    end;

    /// <summary>Gets the HTTP method for the HttpRequestMessage object.</summary>
    /// <returns>The HTTP method for the HttpRequestMessage object.</returns>
    procedure GetHttpMethod() Method: Text
    begin
        Method := HttpRequestMessageImpl.GetHttpMethod();
    end;

    /// <summary>Sets the Uri used for the HttpRequestMessage object.</summary>
    /// <param name="Uri">The Uri to use for the HTTP request.</param>
    /// <remarks>The valued must not be a relative URI.</remarks>
    procedure SetRequestUri(Uri: Text)
    begin
        HttpRequestMessageImpl.SetRequestUri(Uri);
    end;

    /// <summary>Gets the Uri used for the HttpRequestMessage object.</summary>
    /// <returns>The Uri used for the HttpRequestMessage object.</returns>
    procedure GetRequestUri() Uri: Text
    begin
        Uri := HttpRequestMessageImpl.GetRequestUri();
    end;

    /// <summary>Sets a new value for an existing header of the Http Request object, or addds the header if it does not already exist.</summary>
    /// <param name="HeaderName">The name of the header to add.</param>
    /// <param name="HeaderValue">The value of the header to add.</param>
    procedure SetHeader(HeaderName: Text; HeaderValue: Text)
    begin
        HttpRequestMessageImpl.SetHeader(HeaderName, HeaderValue);
    end;

    /// <summary>Sets a new value for an existing header of the Http Request object, or addds the header if it does not already exist.</summary>
    /// <param name="HeaderName">The name of the header to add.</param>
    /// <param name="HeaderValue">The value of the header to add.</param>
    procedure SetHeader(HeaderName: Text; HeaderValue: SecretText)
    begin
        HttpRequestMessageImpl.SetHeader(HeaderName, HeaderValue);
    end;

    /// <summary>Gets the values of the header with the given name from the HttpRequestMessage object.</summary>
    /// <param name="HeaderName">The name of the header to get.</param>
    /// <returns>A list of values of the header with the given name.</returns>
    /// <remarks>If the header is not found, an empty list is returned.</remarks>
    procedure GetHeaderValues(HeaderName: Text) Values: List of [Text]
    begin
        Values := HttpRequestMessageImpl.GetHeaderValues(HeaderName);
    end;

    /// <summary>Gets the secret values of the header with the given name from the HttpRequestMessage object.</summary>
    /// <param name="HeaderName">The name of the header to get.</param>
    /// <returns>A list of values of the header with the given name.</returns>
    /// <remarks>If the header is not found, an empty list is returned.</remarks>
    procedure GetSecretHeaderValues(HeaderName: Text) Values: List of [SecretText]
    begin
        Values := HttpRequestMessageImpl.GetSecretHeaderValues(HeaderName);
    end;

    /// <summary>Sets the cookie given a name and value</summary>
    /// <param name="Name">The name of the cookie to set.</param>
    /// <param name="Value">The value of the cookie to set.</param>
    procedure SetCookie(Name: Text; Value: Text) Success: Boolean
    begin
        Success := HttpRequestMessageImpl.SetCookie(Name, Value);
    end;

    /// <summary>Sets the cookie given a cookie object</summary>
    /// <param name="Cookie">The cookie object to set.</param>
    procedure SetCookie(Cookie: Cookie) Success: Boolean
    begin
        Success := HttpRequestMessageImpl.SetCookie(Cookie);
    end;

    /// <summary>Gets the names of the cookies that are set in the HttpRequestMessage object.</summary>
    /// <returns>The names of the cookies that are set in the HttpRequestMessage object.</returns>
    procedure GetCookieNames() CookieNames: List of [Text]
    begin
        CookieNames := HttpRequestMessageImpl.GetCookieNames();
    end;

    /// <summary>Gets the cookies that are set in the HttpRequestMessage object.</summary>
    /// <returns>The cookies that are set in the HttpRequestMessage object.</returns>
    procedure GetCookies() Cookies: List of [Cookie]
    begin
        Cookies := HttpRequestMessageImpl.GetCookies();
    end;

    /// <summary>Gets the cookie with the given name from the HttpRequestMessage object.</summary>
    /// <param name="Name">The name of the cookie to get.</param>
    /// <returns>The cookie object.</returns>
    /// <remarks>If the cookie is not found, an empty cookie object is returned.</remarks>
    procedure GetCookie(Name: Text) ReturnValue: Cookie
    begin
        ReturnValue := HttpRequestMessageImpl.GetCookie(Name);
    end;

    /// <summary>Gets the cookie with the given name from the HttpRequestMessage object.</summary>
    /// <param name="Name">The name of the cookie to get.</param>
    /// <param name="Cookie">The cookie object to get.</param>
    /// <returns>True if the cookie was found, false otherwise.</returns>
    procedure GetCookie(Name: Text; var Cookie: Cookie) Success: Boolean
    begin
        Success := HttpRequestMessageImpl.GetCookie(Name, Cookie);
    end;

    /// <summary>Removes the cookie with the given name from the HttpRequestMessage object.</summary>
    /// <param name="Name">The name of the cookie to remove.</param>
    /// <returns>True if the cookie was removed, false otherwise.</returns>
    procedure RemoveCookie(Name: Text) Success: Boolean
    begin
        Success := HttpRequestMessageImpl.RemoveCookie(Name);
    end;

    /// <summary>Sets the HttpRequestMessage that is represented by the HttpRequestMessage object.</summary>
    /// <param name="RequestMessage">The HttpRequestMessage to set.</param>
    procedure SetHttpRequestMessage(var RequestMessage: HttpRequestMessage)
    begin
        HttpRequestMessageImpl.SetHttpRequestMessage(RequestMessage);
    end;

    /// <summary>Gets the HttpRequestMessage that is represented by the HttpRequestMessage object.</summary>
    /// <returns>The HttpRequestMessage that is represented by the HttpRequestMessage object.</returns>
    procedure GetHttpRequestMessage() ReturnValue: HttpRequestMessage
    begin
        ReturnValue := HttpRequestMessageImpl.GetRequestMessage();
    end;

    /// <summary>Sets the content of the HttpRequestMessage that is represented by the HttpRequestMessage object.</summary>
    /// <param name="HttpContent">The Http Content object to set.</param>
    procedure SetContent(HttpContent: Codeunit "Http Content")
    begin
        HttpRequestMessageImpl.SetContent(HttpContent);
    end;
}