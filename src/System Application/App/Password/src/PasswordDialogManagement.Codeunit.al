// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

/// <summary>
/// Exposes functionality to open dialogs for entering passwords with different settings.
/// </summary>
codeunit 9810 "Password Dialog Management"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PasswordDialogImpl: Codeunit "Password Dialog Impl.";

#if not CLEAN24
    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <param name="DisablePasswordValidation">Disables the checks for the password validity. Default value is false.</param>
    /// <param name="DisablePasswordConfirmation">If set to true the new password is only needed once. Default value is false.</param>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    [Obsolete('Replaced by OpenSecretPasswordDialog with SecretText return data type.', '24.0')]
    [NonDebuggable]
    procedure OpenPasswordDialog(DisablePasswordValidation: Boolean; DisablePasswordConfirmation: Boolean): Text
    begin
#pragma warning disable AL0432
        exit(PasswordDialogImpl.OpenPasswordDialog(DisablePasswordValidation, DisablePasswordConfirmation));
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <param name="DisablePasswordValidation">Disables the checks for the password validity. Default value is false.</param>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    [Obsolete('Replaced by OpenSecretPasswordDialog with SecretText return data type.', '24.0')]
    [NonDebuggable]
    procedure OpenPasswordDialog(DisablePasswordValidation: Boolean): Text
    begin
#pragma warning disable AL0432
        exit(PasswordDialogImpl.OpenPasswordDialog(DisablePasswordValidation, false));
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    [Obsolete('Replaced by OpenSecretPasswordDialog with SecretText return data type.', '24.0')]
    [NonDebuggable]
    procedure OpenPasswordDialog(): Text
    begin
#pragma warning disable AL0432
        exit(PasswordDialogImpl.OpenPasswordDialog(false, false));
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Opens a dialog for the user to change a password and returns the old and new typed passwords if there is no validation error,
    /// otherwise an empty text are returned.
    /// </summary>
    /// <param name="OldPassword">Out parameter, the old password user typed on the dialog.</param>
    /// <param name="Password">Out parameter, the new password user typed on the dialog.</param>
    [Obsolete('Replaced by OpenChangePassworDialog with SecretText parameter data type.', '24.0')]
    [NonDebuggable]
    procedure OpenChangePasswordDialog(var OldPassword: Text; var Password: Text)
    begin
#pragma warning disable AL0432
        PasswordDialogImpl.OpenChangePasswordDialog(OldPassword, Password);
#pragma warning restore AL0432
    end;

    /// <summary>
    /// Opens a dialog for the user to change a password and returns the old and new typed passwords if there is no validation error,
    /// otherwise an empty text are returned.
    /// </summary>
    /// <param name="OldPassword">Out parameter, the old password user typed on the dialog.</param>
    /// <param name="Password">Out parameter, the new password user typed on the dialog.</param>
    [Obsolete('Replaced by OpenPasswordChangeDialog without out OldPassword param', '25.0')]
    procedure OpenChangePasswordDialog(var OldPassword: SecretText; var Password: SecretText)
    begin
        PasswordDialogImpl.OpenChangePasswordDialog(OldPassword, Password);
    end;
#endif

    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <param name="DisablePasswordValidation">Disables the checks for the password validity. Default value is false.</param>
    /// <param name="DisablePasswordConfirmation">If set to true the new password is only needed once. Default value is false.</param>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    procedure OpenSecretPasswordDialog(DisablePasswordValidation: Boolean; DisablePasswordConfirmation: Boolean): SecretText
    begin
        exit(PasswordDialogImpl.OpenSecretPasswordDialog(DisablePasswordValidation, DisablePasswordConfirmation));
    end;

    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <param name="DisablePasswordValidation">Disables the checks for the password validity. Default value is false.</param>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    procedure OpenSecretPasswordDialog(DisablePasswordValidation: Boolean): SecretText
    begin
        exit(PasswordDialogImpl.OpenSecretPasswordDialog(DisablePasswordValidation, false));
    end;

    /// <summary>
    /// Opens a dialog for the user to enter a password and returns the typed password if there is no validation error,
    /// otherwise an empty text is returned.
    /// </summary>
    /// <returns>The typed password, or empty text if the password validations fail.</returns>
    procedure OpenSecretPasswordDialog(): SecretText
    begin
        exit(PasswordDialogImpl.OpenSecretPasswordDialog(false, false));
    end;

    /// <summary>
    /// Opens a dialog for the user to change a password and returns the new typed password if there is no validation error,
    /// otherwise an empty text are returned.
    /// </summary>
    /// <param name="CurrentPassword">In parameter, the current password to compare with the password user typed on the dialog.</param>
    /// <param name="NewPassword">Out parameter, the new password user typed on the dialog.</param>
    procedure OpenPasswordChangeDialog(CurrentPassword: SecretText; var NewPassword: SecretText)
    begin
        PasswordDialogImpl.OpenPasswordChangeDialog(CurrentPassword, NewPassword);
    end;

    /// <summary>
    /// Event to override the Minimum number of characters in the password.
    /// The Minimum length can only be increased not decreased. Default value is 8 characters long.
    /// </summary>
    /// <param name="MinPasswordLength">The number of characters to be set as minimum requirement.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnSetMinPasswordLength(var MinPasswordLength: Integer)
    begin
    end;
}

