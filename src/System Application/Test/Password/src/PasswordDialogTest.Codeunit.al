// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Security.AccessControl;

using System.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 135033 "Password Dialog Test"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        PasswordDialogManagement: Codeunit "Password Dialog Management";
        PasswordDialogTest: Codeunit "Password Dialog Test";
        PermissionsMock: Codeunit "Permissions Mock";
        PasswordToUse: Text;
        MinimumPasswordLength: Integer;
        DisablePasswordConfirmation: Boolean;
        DisablePasswordValidation: Boolean;
        PasswordMissmatch: Boolean;
        ValidPasswordTxt: Label 'Some Password 2!';
        AnotherValidPasswordTxt: Label 'Some Password 3!';
        InValidPasswordTxt: Label 'Some Password';
        AnotherPasswordTxt: Label 'Another Password';
        PasswordSameAsNewErr: Label 'The new password cannot be the same as the current password.';
        CurrentPasswordMismatchErr: Label 'The current password does not match the entered password.';

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure TestValidPassword();
    var
        Password: SecretText;
    begin
        // [SCENARIO] A valid password must be at least 8 characters long and contain one capital case letter,
        PermissionsMock.Set('All Objects');
        // one lower case letter and one number.
        PasswordToUse := 'Password1@';
        Password := PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.AreEqual('Password1@', GetPasswordValue(Password), 'A different Passwword was expected');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure TestPasswordWithoutNumericCharacter();
    begin
        // [SCENARIO] A password without a numeric character cannot be entered.
        PermissionsMock.Set('All Objects');
        PasswordToUse := 'Password';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure TestPasswordWithoutCapitalCaseCharacter();
    begin
        // [SCENARIO] A password without a capital case character cannot be entered.
        PermissionsMock.Set('All Objects');
        PasswordToUse := 'password1';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');

        PasswordToUse := 'p@ssword1';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure TestPasswordWithoutLowerCaseCharacter();
    begin
        // [SCENARIO] A password without a lower case character cannot be entered.
        PermissionsMock.Set('All Objects');
        PasswordToUse := 'PASSWORD1';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure TestShortPassword();
    begin
        // [SCENARIO] A password with length less than 8 characters cannot be entered.
        PermissionsMock.Set('All Objects');
        PasswordToUse := 'Pass1';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure IncreaseMinimumCharactersTest();
    var
        Password: SecretText;
    begin
        // [SCENARIO] Minimum Password Length can be increased
        PermissionsMock.Set('All Objects');
        if BindSubscription(PasswordDialogTest) then;

        MinimumPasswordLength := 16;
        PasswordToUse := 'Password1@';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');

        PasswordToUse := 'PasswordPassword1@';
        Password := PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.AreEqual('PasswordPassword1@', GetPasswordValue(Password), 'A different Passwword was expected');

        if UnbindSubscription(PasswordDialogTest) then;
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure DecreaseMinimumCharactersTest();
    begin
        // [SCENARIO] Minimum Password Length can not be decreased
        PermissionsMock.Set('All Objects');
        if BindSubscription(PasswordDialogTest) then;
        MinimumPasswordLength := 5;
        PasswordToUse := 'Pass1';
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');

        if UnbindSubscription(PasswordDialogTest) then;
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure OpenSecretPasswordDialogDefaultTest();
    var
        Password: SecretText;
    begin
        // [SCENARIO] Password Confirmation and Validation are enabled and Blank password is not allowed
        PermissionsMock.Set('All Objects');
        DisablePasswordValidation := false;
        DisablePasswordConfirmation := false;
        PasswordMissmatch := false;

        // [WHEN] A valid password is given.
        PasswordToUse := ValidPasswordTxt;
        Password := PasswordDialogManagement.OpenSecretPasswordDialog();
        // [THEN] The password is retrieved.
        Assert.AreEqual(ValidPasswordTxt, GetPasswordValue(Password), 'A diferrent password was expected.');

        // [WHEN] An invalid password is given.
        PasswordToUse := InValidPasswordTxt;
        // [THEN] An error is thrown if only the password field is filled.
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');

        // [WHEN] Password and Confirm Password miss match.
        // [THEN] An error is thrown.
        PasswordMissmatch := true;
        PasswordToUse := ValidPasswordTxt;
        asserterror PasswordDialogManagement.OpenSecretPasswordDialog();
        Assert.ExpectedError('Validation error for Field');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler')]
    procedure OpenSecretPasswordDialogDisableConfirmationTest();
    var
        Password: SecretText;
    begin
        // [SCENARIO] Password dialog can be opened and Password confirmation can be disabled.
        PermissionsMock.Set('All Objects');

        // [WHEN] Password Confirmation and validation are disabled.
        // [THEN] An invalid password can be retrieved by only filling the password field.
        DisablePasswordValidation := true;
        DisablePasswordConfirmation := true;
        PasswordMissmatch := false;
        PasswordToUse := InValidPasswordTxt;
        Password := PasswordDialogManagement.OpenSecretPasswordDialog(DisablePasswordValidation, DisablePasswordConfirmation);
        Assert.AreEqual(InValidPasswordTxt, GetPasswordValue(Password), 'A diferrent password was expected.');
    end;

    [Test]
    [HandlerFunctions('PasswordDialogModalPageHandler,ConfirmHandler')]
    procedure OpenSecretPasswordDialogDisableValidationTest();
    var
        Password: SecretText;
    begin
        // [SCENARIO] Password dialog can be opened and Password Validation can be disabled.
        PermissionsMock.Set('All Objects');

        // [WHEN] Password Validation is disabled.
        // [THEN] An invalid password can be retrieved by filling both Password and Confirm Password fields.
        DisablePasswordValidation := true;
        DisablePasswordConfirmation := false;
        PasswordMissmatch := false;
        PasswordToUse := InValidPasswordTxt;
        Password := PasswordDialogManagement.OpenSecretPasswordDialog(DisablePasswordValidation, DisablePasswordConfirmation);
        Assert.AreEqual(InValidPasswordTxt, GetPasswordValue(Password), 'A diferrnt password was expected.');

        // [THEN] An empty password can be entered
        PasswordToUse := '';
        Password := PasswordDialogManagement.OpenSecretPasswordDialog(DisablePasswordValidation, DisablePasswordConfirmation);
        Assert.IsTrue(Password.IsEmpty(), 'Blank password was expected.');
    end;

    [Test]
    [HandlerFunctions('ChangePasswordDialogModalPageHandler')]
    procedure OpenChangePasswordDialogTest();
    var
        LibraryPassword: Codeunit "Library - Password";
        Password: SecretText;
        OldPassword: SecretText;
    begin
        // [SCENARIO] Open Password dialog in change password mode.
        // Used for "Change Password" OnPrem report.
        // Internal implementation to support OnPrem Database.ChangeUserPassword
        PermissionsMock.Set('All Objects');

        // [WHEN] The password dialog is opened in change password mode.
        LibraryPassword.OpenChangePasswordDialog(OldPassword, Password);

        // [THEN] The Old and New passwords are retrieved.
        Assert.AreEqual(InValidPasswordTxt, GetPasswordValue(OldPassword), 'A diferrent password was expected.');
        Assert.AreEqual(ValidPasswordTxt, GetPasswordValue(Password), 'A diferrent password was expected.')
    end;

    [Test]
    [HandlerFunctions('ChangePasswordDialogModalPageHandler')]
    procedure OpenPasswordChangeDialogTest();
    var
        Password: SecretText;
        CurrentPassword: SecretText;
    begin
        // [SCENARIO] Open Password dialog in change password mode.
        PermissionsMock.Set('All Objects');

        // [WHEN] The password dialog is opened in change password mode.
        PasswordDialogManagement.OpenPasswordChangeDialog(CurrentPassword, Password);

        // [THEN] The New passwords was retrieved.
        Assert.AreEqual('', GetPasswordValue(CurrentPassword), 'A diferrent password was expected.');
        Assert.AreEqual(ValidPasswordTxt, GetPasswordValue(Password), 'A diferrent password was expected.')
    end;

    [Test]
    [HandlerFunctions('ChangePasswordDialogWithCurrentPasswordModalPageHandler')]
    procedure OpenPasswordChangeDialogWithCurrentPasswordTest();
    var
        Password: SecretText;
        CurrentPassword: SecretText;
    begin
        // [SCENARIO] Open Password dialog in change password mode.
        // The old password has been passed on.
        PermissionsMock.Set('All Objects');

        // [GIVEN] The old password is for comparison that the old password matches the entered user and 
        // the new password does not match the old password.
        CurrentPassword := SecretStrSubstNo(ValidPasswordTxt);

        // [WHEN] The password dialog is opened in change password mode.
        PasswordDialogManagement.OpenPasswordChangeDialog(CurrentPassword, Password);

        // [THEN] The Old and New passwords are retrieved.
        Assert.AreEqual(ValidPasswordTxt, GetPasswordValue(CurrentPassword), 'A diferrent password was expected.');
        Assert.AreEqual(AnotherValidPasswordTxt, GetPasswordValue(Password), 'A diferrent password was expected.')
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Password Dialog Management", 'OnSetMinPasswordLength', '', true, true)]
    local procedure OnSetMinimumPAsswordLength(var MinPasswordLength: Integer);
    begin
        MinPasswordLength := MinimumPasswordLength;
    end;

    [ModalPageHandler]
    procedure PasswordDialogModalPageHandler(var PasswordDialog: TestPage "Password Dialog");
    begin
        Assert.IsFalse(PasswordDialog.OldPassword.Visible(), 'Old Password Field should not be visible');
        Assert.AreEqual(not DisablePasswordConfirmation, PasswordDialog.ConfirmPassword.Visible(), 'A different value was expected');
        PasswordDialog.Password.SetValue(PasswordToUse);
        if not DisablePasswordConfirmation then
            PasswordDialog.ConfirmPassword.SetValue(PasswordToUse);
        if PasswordMissmatch then
            PasswordDialog.ConfirmPassword.SetValue(AnotherPasswordTxt);
        PasswordDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ChangePasswordDialogModalPageHandler(var PasswordDialog: TestPage "Password Dialog");
    begin
        Assert.IsTrue(PasswordDialog.OldPassword.Visible(), 'Old Password Field should be visible.');
        Assert.IsTrue(PasswordDialog.ConfirmPassword.Visible(), 'Confirm Password Field should be visible.');
        PasswordDialog.OldPassword.SetValue(InValidPasswordTxt);
        PasswordDialog.Password.SetValue(ValidPasswordTxt);
        PasswordDialog.ConfirmPassword.SetValue(ValidPasswordTxt);
        PasswordDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ChangePasswordDialogWithCurrentPasswordModalPageHandler(var PasswordDialog: TestPage "Password Dialog");
    begin
        Assert.IsTrue(PasswordDialog.OldPassword.Visible(), 'Old Password Field should be visible.');
        Assert.IsTrue(PasswordDialog.ConfirmPassword.Visible(), 'Confirm Password Field should be visible.');
        asserterror PasswordDialog.OldPassword.SetValue(InValidPasswordTxt);
        Assert.ExpectedError(CurrentPasswordMismatchErr);
        PasswordDialog.OldPassword.SetValue(ValidPasswordTxt);
        asserterror PasswordDialog.Password.SetValue(ValidPasswordTxt);
        Assert.ExpectedError(PasswordSameAsNewErr);
        PasswordDialog.Password.SetValue(AnotherValidPasswordTxt);
        PasswordDialog.ConfirmPassword.SetValue(AnotherValidPasswordTxt);
        PasswordDialog.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean);
    begin
        Reply := true;
    end;

    [NonDebuggable]
    local procedure GetPasswordValue(Password: SecretText): Text
    begin
        exit(Password.Unwrap())
    end;

}

