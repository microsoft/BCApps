// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System.Environment;
using System.Security.AccessControl;

/// <summary>
/// Provides authentication for API tests running in Microsoft test environments.
/// </summary>
codeunit 131022 "Microsoft Test Auth Provider" implements "API Test Auth Provider"
{
    Access = Internal;

    var
        UnsupportedAuthenticationErr: Label 'API test web service keys require NavUserPassword authentication.';
        KeyRetrievalFailedErr: Label 'The API test web service key could not be retrieved. Check the current user permissions.';
        ExpiredKeyErr: Label 'The current user web service key has expired. Renew it explicitly before running API tests.';
        EmptyKeyErr: Label 'An empty API test web service key was returned.';

    /// <summary>
    /// Configures authentication for API test requests, preserving ambient authentication on Windows and SaaS.
    /// </summary>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(var Authentication: Codeunit "API Test Auth Context")
    var
        EnvironmentInfo: Codeunit "Environment Information";
        SecurityGroup: Codeunit "Security Group";
        IdentityManagement: Codeunit "Identity Management";
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit;
        if SecurityGroup.IsWindowsAuthentication() then
            exit;
        if not IdentityManagement.IsUserNamePasswordAuthentication() then
            Error(UnsupportedAuthenticationErr);

        Authentication.SetBasicAuthentication(UserId(), GetAuthenticationPassword());
    end;

    [NonDebuggable]
    local procedure GetAuthenticationPassword(): SecretText
    var
        CurrentUser: Record User;
        IdentityManagement: Codeunit "Identity Management";
        Password: SecretText;
        ExpiryDate: DateTime;
    begin
        Password := ReadAuthenticationPassword(ExpiryDate);
        if Password.IsEmpty() then begin
            // Serialize first-use provisioning by this provider, then recheck under the user lock.
            // Existing keys take the read-only path; the caller owns this transaction and its locks.
            CurrentUser.LockTable();
            CurrentUser.Get(UserSecurityId());
            Password := ReadAuthenticationPassword(ExpiryDate);
            if Password.IsEmpty() then begin
                ExpiryDate := CurrentDateTime() + 24 * 60 * 60 * 1000;
                Password := IdentityManagement.CreateWebServicesKey(UserSecurityId(), ExpiryDate);
            end;
        end;
        if Password.IsEmpty() then
            Error(EmptyKeyErr);
        if (ExpiryDate <> 0DT) and (ExpiryDate <= CurrentDateTime()) then
            Error(ExpiredKeyErr);
        exit(Password);
    end;

    [NonDebuggable]
    local procedure ReadAuthenticationPassword(var ExpiryDate: DateTime): SecretText
    var
        IdentityManagement: Codeunit "Identity Management";
        Password: SecretText;
        WebServiceKey: Text[80];
    begin
        // Identity Management.GetWebServicesKey returns error text on failure, not a failure flag.
        // Check fresh error state, never localized error text or the credential's format.
        ClearLastError();
        WebServiceKey := IdentityManagement.GetWebServicesKey(UserSecurityId());
        if GetLastErrorText() <> '' then begin
            Clear(WebServiceKey);
            Error(KeyRetrievalFailedErr);
        end;
        Password := WebServiceKey;
        Clear(WebServiceKey);

        // The expiry getter also substitutes a value on failure; validate its error state separately.
        ClearLastError();
        ExpiryDate := IdentityManagement.GetWebServiceExpiryDate(UserSecurityId());
        if GetLastErrorText() <> '' then begin
            Clear(Password);
            Error(KeyRetrievalFailedErr);
        end;
        exit(Password);
    end;
}
