// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.Authentication;
using System.Utilities;

codeunit 6904 "Expense OAuth Client"
{
    Access = Internal;

    var
        OAuth2: Codeunit OAuth2;
        UrlHelper: Codeunit "Url Helper";
        Scopes: List of [Text];
        GraphScopesLbl: Label '/.default', Locked = true;
        FailedToAcquireAccessTokenErr: Label 'Failed to acquire access token for Microsoft Graph API from OAuth2.';
        FailedToAcquireAccessTokenEmptyErr: Label 'Access token is empty for Microsoft Graph API from OAuth2.';

    procedure GetAccessToken(var AccessToken: SecretText)
    begin
        Scopes.Add(BuildGraphScopes());
        if not OAuth2.AcquireOnBehalfOfToken('', Scopes, AccessToken) then
            Error(FailedToAcquireAccessTokenErr);

        if AccessToken.IsEmpty() then
            Error(FailedToAcquireAccessTokenEmptyErr);
    end;

    local procedure BuildGraphScopes() GraphScope: Text
    begin
        GraphScope := DelChr(UrlHelper.GetGraphUrl(), '>', '/') + GraphScopesLbl
    end;
}