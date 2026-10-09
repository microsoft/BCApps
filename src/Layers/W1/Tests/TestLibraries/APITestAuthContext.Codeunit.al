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
    /// <remarks>
    /// The test server is reached over plain HTTP, and the platform refuses to send secret headers to non-HTTPS endpoints.
    /// </remarks>
    /// <param name="HttpRequestMessage">The request to authenticate.</param>
    [NonDebuggable]
    internal procedure Apply(var HttpRequestMessage: HttpRequestMessage)
    var
        Base64Convert: Codeunit "Base64 Convert";
        RequestHeaders: HttpHeaders;
    begin
        if not BasicAuthenticationConfigured then
            exit;

        HttpRequestMessage.GetHeaders(RequestHeaders);
        if RequestHeaders.Contains('Authorization') or RequestHeaders.ContainsSecret('Authorization') then
            RequestHeaders.Remove('Authorization');
        RequestHeaders.Add('Authorization', SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(SecretStrSubstNo('%1:%2', BasicUserName, BasicPassword))).Unwrap());
    end;
}
