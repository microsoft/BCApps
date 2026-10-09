// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.TestLibraries.ERP;

using System.Environment;
using System.Security.AccessControl;
using System.TestTools.TestRunner;

/// <summary>
/// Provides authentication for API tests running in Microsoft test environments.
/// </summary>
codeunit 131022 "Microsoft Test Auth Provider" implements "API Test Auth Provider"
{
    Access = Internal;

    var
        KeyRetrievalFailedErr: Label 'The API test web service key could not be retrieved. Check the current user permissions.';
        ExpiredKeyErr: Label 'The current user web service key has expired. Renew it explicitly before running API tests.';
        EmptyKeyErr: Label 'An empty API test web service key was returned.';
        KeyCreationInWriteTransactionErr: Label 'The API test web service key is missing and cannot be created while the caller has uncommitted writes. Initialize API authentication before fixture writes or use an existing committed fixture boundary.';
        KeyCreationFailedErr: Label 'The API test web service key could not be created in an isolated transaction. Check the current user permissions and test environment.';

    /// <summary>
    /// Uses the current user's web service key only with NavUserPassword authentication on-premises.
    /// Preserves ambient authentication for Windows, SaaS, and other authentication modes.
    /// Existing keys are reused without caching; missing keys are created with a 24-hour expiry.
    /// First use requires a read-only caller so the isolated key transaction cannot commit fixture data.
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
        KeyCreationSucceeded: Boolean;
    begin
        WebServiceKey := ReadWebServiceKey(ExpiryDate);
        if WebServiceKey.IsEmpty() then begin
            if Database.IsInWriteTransaction() then
                Error(KeyCreationInWriteTransactionErr);

            // Isolated events commit only their subscriber transaction, never caller fixture writes.
            OnCreateWebServiceKey(KeyCreationSucceeded);
            if not KeyCreationSucceeded then
                Error(KeyCreationFailedErr);

            // VAR changes survive subscriber rollback. Never use a credential returned by the event.
            WebServiceKey := ReadWebServiceKey(ExpiryDate);
        end;
        if WebServiceKey.IsEmpty() then
            Error(EmptyKeyErr);
        if (ExpiryDate <> 0DT) and (ExpiryDate <= CurrentDateTime()) then
            Error(ExpiredKeyErr);
        exit(WebServiceKey);
    end;

    [InternalEvent(false, true)]
    local procedure OnCreateWebServiceKey(var Succeeded: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    [NonDebuggable]
    local procedure PrepareTestUserWebServiceKey(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var Skip: Boolean)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        IdentityManagement: Codeunit "Identity Management";
    begin
        if Skip or EnvironmentInfo.IsSaaSInfrastructure() then
            exit;
        if not IdentityManagement.IsUserNamePasswordAuthentication() then
            exit;

        // OnBeforeTestRun commits its own transaction before the test's fixture transaction starts.
        EnsureWebServiceKey();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Microsoft Test Auth Provider", 'OnCreateWebServiceKey', '', false, false)]
    [NonDebuggable]
    [CommitBehavior(CommitBehavior::Error)]
    local procedure CreateWebServiceKeyIsolated(var Succeeded: Boolean)
    begin
        EnsureWebServiceKey();
        Succeeded := true;
    end;

    [NonDebuggable]
    local procedure EnsureWebServiceKey()
    var
        CurrentUser: Record User;
        IdentityManagement: Codeunit "Identity Management";
        WebServiceKey: SecretText;
        ExpiryDate: DateTime;
    begin
        WebServiceKey := ReadWebServiceKey(ExpiryDate);
        if not WebServiceKey.IsEmpty() then
            exit;

        // Serialize first use for this tenant/user; native key creation otherwise replaces an existing key.
        CurrentUser.LockTable();
        CurrentUser.Get(UserSecurityId());
        WebServiceKey := ReadWebServiceKey(ExpiryDate);
        if WebServiceKey.IsEmpty() then begin
            ExpiryDate := CurrentDateTime() + 24 * 60 * 60 * 1000;
            WebServiceKey := IdentityManagement.CreateWebServicesKey(UserSecurityId(), ExpiryDate);
        end;
        if WebServiceKey.IsEmpty() then
            Error(EmptyKeyErr);
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
