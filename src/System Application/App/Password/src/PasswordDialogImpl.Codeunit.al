// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

codeunit 9811 "Password Dialog Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PasswordMismatchErr: Label 'The passwords that you entered do not match.';
        PasswordTooSimpleErr: Label 'The password that you entered does not meet the minimum requirements. It must be at least %1 characters long and contain at least one uppercase letter, one lowercase letter, one number and one special character. It must not have a sequence of 3 or more ascending, descending or repeating characters.', Comment = '%1: The minimum number of characters required in the password';
        ConfirmBlankPasswordQst: Label 'Do you want to exit without entering a password?';
        PasswordSameAsNewErr: Label 'The new password cannot be the same as the current password.';
        CurrentPasswordMismatchErr: Label 'The current password does not match the entered password.';

    procedure ValidatePasswordStrength(Password: SecretText)
    var
        PasswordHandler: Codeunit "Password Handler";
    begin
        if not PasswordHandler.IsPasswordStrong(Password) then
            Error(PasswordTooSimpleErr, PasswordHandler.GetPasswordMinLength());
    end;

#if not CLEAN24
    [Obsolete('Replaced by OpenSecretPasswordDialog with SecretText return data type.', '24.0')]
    procedure OpenPasswordDialog(DisablePasswordValidation: Boolean; DisablePasswordConfirmation: Boolean): Text
    var
        PasswordDialog: Page "Password Dialog";
    begin
        if DisablePasswordValidation then
            PasswordDialog.DisablePasswordValidation();
        if DisablePasswordConfirmation then
            PasswordDialog.DisablePasswordConfirmation();
        if PasswordDialog.RunModal() = Action::OK then
#pragma warning disable AL0432
            exit(PasswordDialog.GetPasswordValue());
#pragma warning restore AL0432
        exit('');
    end;

    [Obsolete('Replaced by OpenChangePassworDialog with SecretText parameter data type.', '24.0')]
    procedure OpenChangePasswordDialog(var OldPassword: Text; var Password: Text)
    var
        PasswordDialog: Page "Password Dialog";
    begin
        PasswordDialog.EnableChangePassword();
        if PasswordDialog.RunModal() = Action::OK then begin
#pragma warning disable AL0432
            Password := PasswordDialog.GetPasswordValue();
            OldPassword := PasswordDialog.GetOldPasswordValue();
#pragma warning restore AL0432
        end;
    end;
#endif

    procedure OpenSecretPasswordDialog(DisablePasswordValidation: Boolean; DisablePasswordConfirmation: Boolean): SecretText
    var
        PasswordDialog: Page "Password Dialog";
    begin
        if DisablePasswordValidation then
            PasswordDialog.DisablePasswordValidation();
        if DisablePasswordConfirmation then
            PasswordDialog.DisablePasswordConfirmation();
        if PasswordDialog.RunModal() = Action::OK then
            exit(PasswordDialog.GetPasswordSecretValue());
    end;

    procedure OpenChangePasswordDialog(var OldPassword: SecretText; var Password: SecretText)
    var
        PasswordDialog: Page "Password Dialog";
    begin
        PasswordDialog.EnableChangePassword();
        if PasswordDialog.RunModal() = Action::OK then begin
            Password := PasswordDialog.GetPasswordSecretValue();
            OldPassword := PasswordDialog.GetOldPasswordSecretValue();
        end;
    end;

    procedure OpenPasswordChangeDialog(CurrentPassword: SecretText; var NewPassword: SecretText)
    var
        PasswordDialog: Page "Password Dialog";
    begin
        PasswordDialog.EnableChangePassword();
        PasswordDialog.SetCurrentPasswordToCompareSecretValue(CurrentPassword);
        if PasswordDialog.RunModal() = Action::OK then
            NewPassword := PasswordDialog.GetPasswordSecretValue();
    end;

    [NonDebuggable]
    procedure ValidatePassword(RequiresPasswordConfirmation: Boolean; RequiresPasswordValidation: Boolean; Password: SecretText; ConfirmPassword: SecretText): Boolean
    begin
        if RequiresPasswordConfirmation and (Password.Unwrap() <> ConfirmPassword.Unwrap()) then
            Error(PasswordMismatchErr);

        if RequiresPasswordValidation then
            ValidatePasswordStrength(Password);
        if Password.IsEmpty() then
            if not Confirm(ConfirmBlankPasswordQst) then
                exit(false);
        exit(true);
    end;

    [NonDebuggable]
    procedure ValidateOldPasswordMatch(CurrentPasswordToCompare: SecretText; OldPasswordEntered: SecretText)
    begin
        if CurrentPasswordToCompare.IsEmpty() then
            exit;
        if CurrentPasswordToCompare.Unwrap() <> OldPasswordEntered.Unwrap() then
            Error(CurrentPasswordMismatchErr);
    end;

    [NonDebuggable]
    procedure ValidateNewPasswordUniqueness(CurrentPasswordToCompare: SecretText; NewPassword: SecretText)
    begin
        if CurrentPasswordToCompare.IsEmpty() then
            exit;
        if CurrentPasswordToCompare.Unwrap() = NewPassword.Unwrap() then
            Error(PasswordSameAsNewErr);
    end;
}

