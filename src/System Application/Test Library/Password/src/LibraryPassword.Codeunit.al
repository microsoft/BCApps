// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Security.AccessControl;

using System.Security.AccessControl;

codeunit 132528 "Library - Password"
{
    var
        PasswordDialogImpl: Codeunit "Password Dialog Impl.";

    /// <summary>
    /// Opens a dialog for the user to change a password and returns the old and new typed passwords if there is no validation error,
    /// otherwise an empty text are returned. Used for OnPrem report "Change Password"
    /// </summary>
    /// <param name="OldPassword">Out parameter, the old password user typed on the dialog.</param>
    /// <param name="Password">Out parameter, the new password user typed on the dialog.</param>
    procedure OpenChangePasswordDialog(var OldPassword: SecretText; var Password: SecretText)
    begin
        PasswordDialogImpl.OpenChangePasswordDialog(OldPassword, Password);
    end;
}