// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System.Environment;
using System.Security.AccessControl;

/// <summary>
/// Provides API test authentication using the current user's web service key.
/// </summary>
codeunit 131022 "Microsoft Test Auth Provider" implements "API Test Auth Provider"
{
    Access = Internal;

    var
        KeyRetrievalFailedErr: Label 'The API test web service key could not be retrieved. Check the current user permissions.';
        EmptyKeyErr: Label 'An empty API test web service key was returned.';

    /// <summary>
    /// Uses the current user's web service key only with NavUserPassword authentication on-premises.
    /// Preserves ambient authentication for Windows, SaaS, and other authentication modes.
    /// Valid keys are reused; missing or expired keys are created with a 24-hour expiry.
    /// </summary>
    /// <param name="Authentication">The authentication context to configure.</param>
    procedure ConfigureAuthentication(var Authentication: Codeunit "API Test Auth Context")
    var
        EnvironmentInfo: Codeunit "Environment Information";
        IdentityManagement: Codeunit "Identity Management";
    begin
        if EnvironmentInfo.IsSaaSInfrastructure() then
            exit;
        if not IdentityManagement.IsUserNamePasswordAuthentication() then
            exit;

        Authentication.SetBasicAuthentication(UserId(), GetWebServiceKey());
    end;

    [NonDebuggable]
    local procedure GetWebServiceKey(): SecretText
    var
        IdentityManagement: Codeunit "Identity Management";
        WebServiceKey: SecretText;
        ExpiryDate: DateTime;
    begin
        WebServiceKey := ReadWebServiceKey(ExpiryDate);
        if WebServiceKey.IsEmpty() or ((ExpiryDate <> 0DT) and (ExpiryDate <= CurrentDateTime())) then begin
            ExpiryDate := CurrentDateTime() + 24 * 60 * 60 * 1000;
            WebServiceKey := IdentityManagement.CreateWebServicesKey(UserSecurityId(), ExpiryDate);
        end;
        if WebServiceKey.IsEmpty() then
            Error(EmptyKeyErr);
        exit(WebServiceKey);
    end;

    [NonDebuggable]
    local procedure ReadWebServiceKey(var ExpiryDate: DateTime): SecretText
    var
        IdentityManagement: Codeunit "Identity Management";
        WebServiceKey: Text[80];
        SecretWebServiceKey: SecretText;
    begin
        // Identity Management substitutes error text on failure. Check fresh error state, not key format.
        ClearLastError();
        WebServiceKey := IdentityManagement.GetWebServicesKey(UserSecurityId());
        if GetLastErrorText() <> '' then begin
            Clear(WebServiceKey);
            Error(KeyRetrievalFailedErr);
        end;
        SecretWebServiceKey := WebServiceKey;
        Clear(WebServiceKey);

        // The expiry getter also substitutes a value on failure.
        ClearLastError();
        ExpiryDate := IdentityManagement.GetWebServiceExpiryDate(UserSecurityId());
        if GetLastErrorText() <> '' then begin
            Clear(SecretWebServiceKey);
            Error(KeyRetrievalFailedErr);
        end;
        exit(SecretWebServiceKey);
    end;
}
