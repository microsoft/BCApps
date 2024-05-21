// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

/// <summary>
/// A Page that allows the user to enter a password.
/// </summary>
page 9810 "Password Dialog"
{
    Extensible = false;
    Caption = 'Enter Password';
    PageType = StandardDialog;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(OldPassword; OldPasswordValue)
            {
                ApplicationArea = All;
                Caption = 'Old Password';
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the current password, before the user defines a new one.';
                Visible = ShowOldPassword;
                trigger OnValidate()
                begin
                    PasswordDialogImpl.ValidateOldPasswordMatch(CurrentPasswordToCompare, OldPasswordValue);
                end;
            }
            field(Password; PasswordValue)
            {
                ApplicationArea = All;
                Caption = 'Password';
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the password for this task. The password must consist of 8 or more characters, at least one uppercase letter, one lowercase letter, and one number.';

                trigger OnValidate()
                begin
                    if RequiresPasswordValidation then
                        PasswordDialogImpl.ValidatePasswordStrength(PasswordValue);

                    PasswordDialogImpl.ValidateNewPasswordUniqueness(CurrentPasswordToCompare, PasswordValue);
                end;
            }
            field(ConfirmPassword; ConfirmPasswordValue)
            {
                ApplicationArea = All;
                Caption = 'Confirm Password';
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the password repeated.';
                Visible = RequiresPasswordConfirmation;

                trigger OnValidate()
                begin
                    if RequiresPasswordConfirmation and (PasswordValue <> ConfirmPasswordValue) then
                        Error(PasswordMismatchErr);
                end;
            }
        }
    }


    trigger OnInit()
    begin
        RequiresPasswordValidation := true;
        RequiresPasswordConfirmation := true;
    end;

    trigger OnOpenPage()
    begin
        ValidPassword := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::OK then begin
            ValidPassword := PasswordDialogImpl.ValidatePassword(
                RequiresPasswordConfirmation,
                RequiresPasswordValidation,
                PasswordValue,
                ConfirmPasswordValue);
            exit(ValidPassword);
        end;
    end;

    var
        PasswordDialogImpl: Codeunit "Password Dialog Impl.";
        PasswordMismatchErr: Label 'The passwords that you entered do not match.';
        [NonDebuggable]
        PasswordValue: Text;
        [NonDebuggable]
        ConfirmPasswordValue: Text;
        [NonDebuggable]
        OldPasswordValue: Text;
        CurrentPasswordToCompare: SecretText;
        ShowOldPassword: Boolean;
        ValidPassword: Boolean;
        RequiresPasswordValidation: Boolean;
        RequiresPasswordConfirmation: Boolean;

#if not CLEAN24
    /// <summary>
    /// Gets the password value typed on the page.
    /// </summary>
    /// <returns>The password value typed on the page.</returns>
    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetPasswordSecretValue', '24.0')]
    procedure GetPasswordValue(): Text
    begin
        if ValidPassword then
            exit(PasswordValue);

        exit('');
    end;

    /// <summary>
    /// Gets the old password value typed on the page.
    /// </summary>
    /// <returns>The old password typed on the page.</returns>
    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by GetOldPasswordSecretValue', '24.0')]
    procedure GetOldPasswordValue(): Text
    begin
        if ValidPassword then
            exit(OldPasswordValue);

        exit('');
    end;
#endif

    /// <summary>
    /// Gets the password value typed on the page.
    /// </summary>
    /// <returns>The password value typed on the page.</returns>
    [Scope('OnPrem')]
    procedure GetPasswordSecretValue() Password: SecretText
    begin
        if ValidPassword then
            Password := PasswordValue;
    end;

    /// <summary>
    /// Gets the old password value typed on the page.
    /// </summary>
    /// <returns>The old password typed on the page.</returns>
    [Scope('OnPrem')]
    procedure GetOldPasswordSecretValue() Password: SecretText
    begin
        if ValidPassword then
            Password := OldPasswordValue;
    end;

    /// <summary>
    /// Set the old password value to compare with typed on the page.
    /// </summary>
    /// <param name="OldPasswordSecret">Old password to compare.</param>
    [Scope('OnPrem')]
    procedure SetCurrentPasswordToCompareSecretValue(CurrentPasswordSecret: SecretText)
    begin
        CurrentPasswordToCompare := CurrentPasswordSecret;
    end;

    /// <summary>
    /// Enables the Change password mode, it makes the old password field on the page visible.
    /// </summary>
    [Scope('OnPrem')]
    procedure EnableChangePassword()
    begin
        ShowOldPassword := true;
    end;

    /// <summary>
    /// Disables any password validation.
    /// </summary>
    [Scope('OnPrem')]
    procedure DisablePasswordValidation()
    begin
        RequiresPasswordValidation := false;
    end;

    /// <summary>
    /// Disables any password confirmation, it makes the Confirm Password field on the page hidden.
    /// </summary>
    [Scope('OnPrem')]
    procedure DisablePasswordConfirmation()
    begin
        RequiresPasswordConfirmation := false;
    end;
}

