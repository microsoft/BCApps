// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage;

codeunit 9089 "Stor. Serv. Auth. Entra ID" implements "Storage Service Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Authorize(var HttpRequest: HttpRequestMessage; StorageAccount: Text)
    var
        Headers: HttpHeaders;
    begin
        HttpRequest.GetHeaders(Headers);
        if Headers.Contains('Authorization') then
            Headers.Remove('Authorization');
        Headers.Add('Authorization', GetBearerToken(StorageAccount));
    end;

    [NonDebuggable]
    procedure SetAccessToken(AccessToken: Text)
    begin
        Secret := AccessToken;
    end;

    [NonDebuggable]
    local procedure GetBearerToken(AccessToken: Text): Text
    var
        SecretCanNotBeEmptyErr: Label 'Secret (Access Token) must be provided';
        BearerTok: Label 'Bearer %1', Locked = true;
    begin
        if Secret = '' then
            Error(SecretCanNotBeEmptyErr);

        exit(StrSubstNo(BearerTok, AccessToken));
    end;

    var
        [NonDebuggable]
        Secret: Text;
}