// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

/// <summary>
/// Stores authentication configuration for an API test request.
/// </summary>
codeunit 131023 "API Test Auth Context"
{
    var
        BasicUserName: Text;
        BasicPassword: SecretText;
        BasicAuthenticationConfigured: Boolean;

    /// <summary>
    /// Configures Basic authentication for the API test request.
    /// </summary>
    /// <param name="UserName">The user name used for Basic authentication.</param>
    /// <param name="Password">The password used for Basic authentication.</param>
    procedure SetBasicAuthentication(UserName: Text; Password: SecretText)
    begin
        BasicUserName := UserName;
        BasicPassword := Password;
        BasicAuthenticationConfigured := true;
    end;

    /// <summary>
    /// Applies the configured authentication to the API test request.
    /// </summary>
    /// <param name="HttpWebRequestMgt">The request to authenticate.</param>
    internal procedure Apply(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        if BasicAuthenticationConfigured then
            HttpWebRequestMgt.AddBasicAuthentication(BasicUserName, BasicPassword);
    end;
}
