// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139493 "Mock API Test Auth Provider" implements "API Test Auth Provider"
{
    Access = Internal;

    var
        InvocationCount: Integer;
        PasswordTxt: Label 'Password', Locked = true;

    /// <summary>
    /// Records an invocation and configures Basic authentication for the request.
    /// </summary>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(var Authentication: Codeunit "API Test Auth Context")
    var
        Password: SecretText;
    begin
        InvocationCount += 1;
        Password := PasswordTxt;
        Authentication.SetBasicAuthentication('User', Password);
        OnAuthenticationConfigured(InvocationCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAuthenticationConfigured(InvocationNumber: Integer)
    begin
    end;
}
