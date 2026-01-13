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

    procedure ResetMockHandler()
    begin
        Clear(this.MockHttpClientHandler);
    end;

    procedure GetMockHandler(): Interface "Http Client Handler"
    begin
        exit(this.MockHttpClientHandler);
    end;
}