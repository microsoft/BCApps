// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2360 "Http Client Handler" implements "Http Client Handler"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Send(CurrHttpClientInstance: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean;
    var
        ResponseMessage: HttpResponseMessage;
    begin
        Success := CurrHttpClientInstance.Send(HttpRequestMessage.GetHttpRequestMessage(), ResponseMessage);
        HttpResponseMessage := HttpResponseMessage.Create(ResponseMessage);
    end;
}