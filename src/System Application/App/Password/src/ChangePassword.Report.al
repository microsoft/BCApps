// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

/// <summary>
/// Report to change the current user's login password for OnPrem scenarios.
/// </summary>
report 9810 "Change Password"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    Permissions = tabledata User = r;
    InherentEntitlements = X;
    InherentPermissions = X;

    dataset
    {
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        User: Record User;
        PasswordDialogImpl: Codeunit "Password Dialog Impl.";
        Password: SecretText;
        OldPassword: SecretText;
    begin
        PasswordDialogImpl.OpenChangePasswordDialog(OldPassword, Password);
        if Password.IsEmpty() then
            exit;

        User.SetFilter("User Security ID", UserSecurityId());
        if User.IsEmpty() then
            error(UserDoesNotExistErr, User.FieldCaption("User Security ID"), User."User Security ID");

        if ChangePassword(OldPassword, Password) then
            Message(PasswordUpdatedMsg);
    end;

    var
        PasswordUpdatedMsg: Label 'Your Password has been updated.';
        UserDoesNotExistErr: Label 'The user with %1 %2 does not exist.', Comment = '%1 = Label User Security Id, %2 = User Security ID';

    [NonDebuggable]
    local procedure ChangePassword(OldPassword: SecretText; Password: SecretText): Boolean
    begin
        exit(ChangeUserPassword(OldPassword.Unwrap(), Password.Unwrap()));
    end;
}

