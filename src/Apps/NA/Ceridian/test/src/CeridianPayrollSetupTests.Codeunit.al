// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Payroll.Ceridian;

codeunit 139547 "Ceridian Payroll Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        MockPasswordLbl: Label 'CeridianTestFixture', Locked = true;

    [Test]
    procedure SavePasswordCreatesAndReusesKey()
    var
        CeridianSetup: Record "MS Ceridian Payroll Setup";
        Password: SecretText;
        PasswordKey: Guid;
        OriginalKey: Guid;
    begin
        Password := Format(MockPasswordLbl);
        CeridianSetup.SavePassword(PasswordKey, Password);
        Assert.IsFalse(IsNullGuid(PasswordKey), 'Saving a password must allocate a key.');
        OriginalKey := PasswordKey;

        CeridianSetup.SavePassword(PasswordKey, Password);

        Assert.AreEqual(OriginalKey, PasswordKey, 'Updating a stored password must reuse its key.');
    end;

    [Test]
    procedure SavePasswordReplacesMissingKey()
    var
        CeridianSetup: Record "MS Ceridian Payroll Setup";
        Password: SecretText;
        PasswordKey: Guid;
        MissingKey: Guid;
    begin
        MissingKey := CreateGuid();
        PasswordKey := MissingKey;
        Password := Format(MockPasswordLbl);

        CeridianSetup.SavePassword(PasswordKey, Password);

        Assert.IsFalse(IsNullGuid(PasswordKey), 'The replacement key must not be empty.');
        Assert.AreNotEqual(MissingKey, PasswordKey, 'A key without stored data must be replaced.');
    end;

    [Test]
    procedure SaveEmptyPasswordRetainsStoredKey()
    var
        CeridianSetup: Record "MS Ceridian Payroll Setup";
        EmptyPassword: SecretText;
        EmptyPasswordText: Text;
        PasswordKey: Guid;
        OriginalKey: Guid;
    begin
        EmptyPasswordText := '';
        EmptyPassword := EmptyPasswordText;
        CeridianSetup.SavePassword(PasswordKey, EmptyPassword);
        Assert.IsFalse(IsNullGuid(PasswordKey), 'An empty password must retain the existing storage behavior.');
        OriginalKey := PasswordKey;

        CeridianSetup.SavePassword(PasswordKey, EmptyPassword);

        Assert.AreEqual(OriginalKey, PasswordKey, 'An existing key must also be reused for an empty password.');
    end;
}
