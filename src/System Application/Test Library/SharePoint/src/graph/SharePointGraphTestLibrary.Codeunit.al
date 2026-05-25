// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.RestClient;

codeunit 132975 "SharePoint Graph Test Library"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MockHttpClientHandler: Codeunit "SharePoint Http Client Handler";

    procedure SetMockResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        MockHttpClientHandler.SetResponse(NewHttpResponseMessage);
    end;

    procedure GetHttpRequestMessage(var OutHttpRequestMessage: Codeunit "Http Request Message")
    begin
        MockHttpClientHandler.GetHttpRequestMessage(OutHttpRequestMessage);
    end;

    procedure ExpectRequestToFailWithError(ErrorText: Text)
    begin
        MockHttpClientHandler.ExpectSendToFailWithError(ErrorText);
    end;

    procedure AddMockResponse(StatusCode: Integer; ResponseBody: Text)
    begin
        MockHttpClientHandler.AddResponse(StatusCode, ResponseBody);
    end;

    procedure AddMockResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        MockHttpClientHandler.AddResponse(NewHttpResponseMessage);
    end;

    procedure GetMockHttpRequestUri(Index: Integer): Text
    begin
        exit(MockHttpClientHandler.GetHttpRequestUri(Index));
    end;

    procedure GetMockHttpRequestMethod(Index: Integer): Text
    begin
        exit(MockHttpClientHandler.GetHttpRequestMethod(Index));
    end;

    procedure GetMockRequestCount(): Integer
    begin
        exit(MockHttpClientHandler.GetRequestCount());
    end;

    procedure ResetMockHandler()
    begin
        Clear(this.MockHttpClientHandler);
    end;

    procedure GetMockHandler(): Interface "Http Client Handler"
    begin
        exit(this.MockHttpClientHandler);
    end;
}