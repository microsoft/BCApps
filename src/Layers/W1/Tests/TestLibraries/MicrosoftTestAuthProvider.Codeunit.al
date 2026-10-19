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
        KeyCreationFailedErr: Label 'The API test web service key could not be created. Check the current user permissions.';
        StartSessionFailedErr: Label 'The background session that creates the API test web service key could not be started.';
        KeyCreationTimeoutErr: Label 'The API test web service key was not created within %1 seconds.', Comment = '%1 - Timeout in seconds';

    /// <summary>
    /// Uses the current user's web service key only with NavUserPassword authentication on-premises.
    /// Preserves ambient authentication for Windows, SaaS, and other authentication modes.
    /// Valid keys are reused; missing or expired keys are created with a 24-hour expiry in a background session,
    /// so the caller's transaction is not committed. Under a test runner with test isolation, which does not allow
    /// background sessions, the key is created and committed in the caller's session instead.
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
        WebServiceKey: SecretText;
        ExpiryDate: DateTime;
    begin
        WebServiceKey := ReadWebServiceKey(ExpiryDate);
        if IsMissingOrExpired(WebServiceKey, ExpiryDate) then begin
            // The request is authenticated by a separate server session, which only sees committed data.
            CreateWebServiceKey();
            SelectLatestVersion();
            WebServiceKey := ReadWebServiceKey(ExpiryDate);
            if IsMissingOrExpired(WebServiceKey, ExpiryDate) then
                Error(KeyCreationFailedErr);
        end;
        exit(WebServiceKey);
    end;

    local procedure IsMissingOrExpired(WebServiceKey: SecretText; ExpiryDate: DateTime): Boolean
    begin
        exit(WebServiceKey.IsEmpty() or ((ExpiryDate <> 0DT) and (ExpiryDate <= CurrentDateTime())));
    end;

    local procedure CreateWebServiceKey()
    var
        APITestWebServiceKey: Codeunit "API Test Web Service Key";
        SessionId: Integer;
    begin
        // A background session commits the new key without committing the caller's transaction.
        if TryStartWebServiceKeySession(SessionId) then begin
            WaitForWebServiceKeySession(SessionId);
            exit;
        end;

        // Test runners with test isolation do not allow background sessions. They roll back the test's
        // changes when the test ends, including committed ones, so the key is committed in this session.
        ClearLastError();
        APITestWebServiceKey.Run();
        Commit();
    end;

    [TryFunction]
    local procedure TryStartWebServiceKeySession(var SessionId: Integer)
    begin
        if not StartSession(SessionId, Codeunit::"API Test Web Service Key", CompanyName()) then
            Error(StartSessionFailedErr);
    end;

    local procedure WaitForWebServiceKeySession(SessionId: Integer)
    var
        ActiveSession: Record "Active Session";
        TimeoutSec: Integer;
        StartTime: DateTime;
    begin
        TimeoutSec := 60;
        StartTime := CurrentDateTime();
        while ActiveSession.Get(ServiceInstanceId(), SessionId) do begin
            if CurrentDateTime() - StartTime > TimeoutSec * 1000 then begin
                StopSession(SessionId);
                Error(KeyCreationTimeoutErr, TimeoutSec);
            end;
            Sleep(250);
        end;
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
