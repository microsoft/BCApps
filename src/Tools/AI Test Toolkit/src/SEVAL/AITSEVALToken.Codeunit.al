// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149038 "AIT SEVAL Token"
{
    Access = Internal;

    procedure GetAccessToken() AccessToken: SecretText
    begin
        // TODO: Enable delegated SEVAL token acquisition after resolving the Cloud target boundary.
        // var
        //     OAuth2: Codeunit System.Security.Authentication.OAuth2;
        //     Scopes: List of [Text];
        // begin
        //     Scopes.Add('https://sevaldata.office.net/.default');
        //     if not OAuth2.AcquireOnBehalfOfToken('', Scopes, AccessToken) then
        //         Error(OAuth2.GetLastErrorMessage());
    end;
}