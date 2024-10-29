// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

using System.RestClient;

codeunit 2357 "Http Response Message Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Constructors
    procedure Create(HttpResponseMessage: HttpResponseMessage): Codeunit "Http Response Message Impl."
    begin
        this.SetResponseMessage(HttpResponseMessage);
        exit(this);
    end;
    #endregion

    #region IsBlockedByEnvironment
    var
        IsBlockedByEnvironment: Boolean;

    procedure SetIsBlockedByEnvironment(Value: Boolean)
    begin
        this.IsBlockedByEnvironment := Value;
    end;

    procedure GetIsBlockedByEnvironment() ReturnValue: Boolean
    begin
        ReturnValue := this.IsBlockedByEnvironment;
    end;
    #endregion

    #region HttpStatusCode
    var
        HttpStatusCode: Integer;

    procedure SetHttpStatusCode(Value: Integer)
    begin
        this.HttpStatusCode := Value;
        this.IsSuccessStatusCode := Value in [200 .. 299];
    end;

    procedure GetHttpStatusCode() ReturnValue: Integer
    begin
        ReturnValue := this.HttpStatusCode
    end;
    #endregion

    #region IsSuccessStatusCode
    var
        IsSuccessStatusCode: Boolean;

    procedure GetIsSuccessStatusCode() Result: Boolean
    begin
        Result := this.IsSuccessStatusCode;
    end;

    procedure SetIsSuccessStatusCode(Value: Boolean)
    begin
        this.IsSuccessStatusCode := Value;
    end;
    #endregion

    #region ReasonPhrase
    var
        ReasonPhrase: Text;

    procedure SetReasonPhrase(Value: Text)
    begin
        this.ReasonPhrase := Value;
    end;

    procedure GetReasonPhrase() ReturnValue: Text
    begin
        ReturnValue := this.ReasonPhrase;
    end;
    #endregion

    #region HttpContent
    var
        HttpContent: Codeunit "Http Content";

    procedure SetContent(Content: Codeunit "Http Content")
    begin
        this.HttpContent := Content;
    end;

    procedure GetContent() ReturnValue: Codeunit "Http Content"
    begin
        ReturnValue := this.HttpContent;
    end;
    #endregion

    #region HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;

    procedure SetResponseMessage(var ResponseMessage: HttpResponseMessage)
    var
        Cookie: Cookie;
        Cookies: Dictionary of [Text, Cookie];
        CookieName: Text;
    begin
        ClearAll();
        this.HttpResponseMessage := ResponseMessage;
        SetIsBlockedByEnvironment(ResponseMessage.IsBlockedByEnvironment);
        SetHttpStatusCode(ResponseMessage.HttpStatusCode);
        SetReasonPhrase(ResponseMessage.ReasonPhrase);
        SetIsSuccessStatusCode(ResponseMessage.IsSuccessStatusCode);
        SetHeaders(ResponseMessage.Headers);
        SetContent(HttpContent.Create(ResponseMessage.Content));
        foreach CookieName in ResponseMessage.GetCookieNames() do begin
            ResponseMessage.GetCookie(CookieName, Cookie);
            Cookies.Add(CookieName, Cookie);
        end;
        SetCookies(Cookies);
    end;

    procedure GetResponseMessage() ReturnValue: HttpResponseMessage
    begin
        ReturnValue := this.HttpResponseMessage;
    end;
    #endregion

    #region HttpHeaders
    var
        HttpHeaders: HttpHeaders;

    procedure SetHeaders(Headers: HttpHeaders)
    begin
        this.HttpHeaders := Headers;
    end;

    procedure GetHeaders() ReturnValue: HttpHeaders
    begin
        ReturnValue := this.HttpHeaders;
    end;
    #endregion

    #region Cookies
    var
        Cookies: Dictionary of [Text, Cookie];

    procedure SetCookies(Cookies: Dictionary of [Text, Cookie])
    begin
        this.Cookies := Cookies;
    end;

    procedure GetCookies() Cookies: Dictionary of [Text, Cookie]
    begin
        Cookies := this.Cookies;
    end;

    procedure GetCookieNames() CookieNames: List of [Text]
    begin
        CookieNames := this.Cookies.Keys;
    end;

    procedure GetCookie(Name: Text) Cookie: Cookie
    begin
        if this.Cookies.Get(Name, Cookie) then;
    end;

    procedure GetCookie(Name: Text; var Cookie: Cookie) Success: Boolean
    begin
        Success := this.Cookies.Get(Name, Cookie);
    end;
    #endregion

    #region ErrorMessage
    var
        ErrorMessage: Text;
        Exception: ErrorInfo;

    procedure SetErrorMessage(Value: Text)
    begin
        this.ErrorMessage := Value;
    end;

    procedure GetErrorMessage(): Text
    begin
        if this.Exception.Message <> '' then
            exit(this.Exception.Message);

        if this.ErrorMessage <> '' then
            exit(this.ErrorMessage);

        exit(GetLastErrorText());
    end;

    procedure SetException(Exception: ErrorInfo)
    begin
        this.Exception := Exception;
    end;

    procedure GetException() Exception: ErrorInfo
    var
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
    begin
        if this.Exception.Message = '' then
            Exception := RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::UnknownException, GetErrorMessage())
    end;

    procedure GetExceptionCode() ReturnValue: Enum "Rest Client Exception"
    var
        IntValue: Integer;
        Execption: ErrorInfo;
    begin
        Exception := this.GetException();
        Evaluate(IntValue, Exception.CustomDimensions.Get('ExceptionCode'));
        ReturnValue := Enum::"Rest Client Exception".FromInteger(IntValue);
    end;

    procedure GetExceptionName() ReturnValue: Text
    var
        Exception: ErrorInfo;
    begin
        Exception := this.GetException();
        ReturnValue := Exception.CustomDimensions.Get('ExceptionName');
    end;

    #endregion
}