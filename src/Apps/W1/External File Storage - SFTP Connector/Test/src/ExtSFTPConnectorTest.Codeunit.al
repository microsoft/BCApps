// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.Environment;
using System.ExternalFileStorage;
using System.TestLibraries.Utilities;

codeunit 144591 "Ext. SFTP Connector Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountRegisterPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMultipleAccountsCanBeRegistered()
    var
        FileAccount: Record "File Account";
        ExtFileConnector: Codeunit "Ext. SFTP Connector Impl";
        FileAccounts: TestPage "File Accounts";
        AccountIds: array[3] of Guid;
        AccountName: array[3] of Text[250];
        Index: Integer;
    begin
        // [Scenario] Create multiple accounts
        Initialize();

        // [When] Multiple accounts are registered
        for Index := 1 to 3 do begin
            SetBasicAccount();

            Assert.IsTrue(ExtFileConnector.RegisterAccount(FileAccount), 'Failed to register account.');
            AccountIds[Index] := FileAccount."Account Id";
            AccountName[Index] := FileAccountMock.Name();

            // [Then] Accounts are retrieved from the GetAccounts method
            FileAccount.DeleteAll();
            ExtFileConnector.GetAccounts(FileAccount);
            Assert.RecordCount(FileAccount, Index);
        end;

        FileAccounts.OpenView();
        for Index := 1 to 3 do begin
            FileAccounts.GoToKey(AccountIds[Index], Enum::"Ext. File Storage Connector"::SFTP);
            Assert.AreEqual(AccountName[Index], FileAccounts.NameField.Value(), 'A different name was expected.');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountRegisterPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestEnvironmentCleanupDisablesAccounts()
    var
        FileAccount: Record "File Account";
        ExtSFTPAccount: Record "Ext. SFTP Account";
        ExtFileConnector: Codeunit "Ext. SFTP Connector Impl";
        EnvironmentTriggers: Codeunit "Environment Triggers";
        AccountIds: array[3] of Guid;
        Index: Integer;
    begin
        // [Scenario] Create multiple accounts
        Initialize();

        // [When] Multiple accounts are registered
        for Index := 1 to 3 do begin
            SetBasicAccount();

            Assert.IsTrue(ExtFileConnector.RegisterAccount(FileAccount), 'Failed to register account.');
            AccountIds[Index] := FileAccount."Account Id";

            // [Then] Accounts are retrieved from the GetAccounts method
            FileAccount.DeleteAll();
            ExtFileConnector.GetAccounts(FileAccount);
            Assert.RecordCount(FileAccount, Index);
        end;

        ExtSFTPAccount.SetRange(Disabled, true);
        Assert.IsTrue(ExtSFTPAccount.IsEmpty(), 'Accounts are already disabled.');

        EnvironmentTriggers.OnAfterCopyEnvironmentPerCompany(0, Any.AlphabeticText(30), 1, Any.AlphabeticText(30));

        Assert.IsFalse(ExtSFTPAccount.IsEmpty(), 'Accounts are not disabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('AccountRegisterPageHandler,AccountShowPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestShowAccountInformation()
    var
        FileAccount: Record "File Account";
        FileConnector: Codeunit "Ext. SFTP Connector Impl";
    begin
        // [Scenario] Account Information is displayed in the Account page.

        // [Given] An file account
        Initialize();
        SetBasicAccount();
        FileConnector.RegisterAccount(FileAccount);

        // [When] The ShowAccountInformation method is invoked
        FileConnector.ShowAccountInformation(FileAccount."Account Id");

        // [Then] The account page opens and displays the information
        // Verify in AccountModalPageHandler
    end;

    local procedure Initialize()
    var
        ExtSFTPAccount: Record "Ext. SFTP Account";
    begin
        ExtSFTPAccount.DeleteAll();
    end;

    local procedure SetBasicAccount()
    begin
        FileAccountMock.Name(CopyStr(Any.AlphanumericText(250), 1, 250));
        FileAccountMock.Hostname(CopyStr(Any.AlphanumericText(250), 1, 250));
        FileAccountMock.Username(CopyStr(Any.AlphanumericText(256), 1, 256));
        FileAccountMock.BaseRelativeFolderPath(CopyStr(Any.AlphanumericText(250), 1, 250));
        FileAccountMock.Port(Any.IntegerInRange(1, 65535));
        FileAccountMock.Fingerprints(CopyStr(Any.AlphanumericText(1024), 1, 1024));
        FileAccountMock.Password('testpassword');
    end;

    [ModalPageHandler]
    procedure AccountRegisterPageHandler(var AccountWizard: TestPage "Ext. SFTP Account Wizard")
    begin
        // Setup account
        AccountWizard.NameField.SetValue(FileAccountMock.Name());
        AccountWizard.Hostname.SetValue(FileAccountMock.Hostname());
        AccountWizard.Username.SetValue(FileAccountMock.Username());
        AccountWizard."Base Relative Folder Path".SetValue(FileAccountMock.BaseRelativeFolderPath());
        AccountWizard.Password.SetValue(FileAccountMock.Password());
        AccountWizard.Port.SetValue(FileAccountMock.Port());
        AccountWizard.Fingerprints.SetValue(FileAccountMock.Fingerprints());
        AccountWizard.Next.Invoke();
    end;

    [PageHandler]
    procedure AccountShowPageHandler(var Account: TestPage "Ext. SFTP Account")
    begin
        // Verify the account
        Assert.AreEqual(FileAccountMock.Name(), Account.NameField.Value(), 'A different name was expected.');
        Assert.AreEqual(FileAccountMock.Hostname(), Account.Hostname.Value(), 'A different hostname was expected.');
        Assert.AreEqual(FileAccountMock.Username(), Account.Username.Value(), 'A different username was expected.');
        Assert.AreEqual(Format(FileAccountMock.Port()), Account.Port.Value(), 'A different port was expected.');
        Assert.AreEqual(FileAccountMock.Fingerprints(), Account.Fingerprints.Value(), 'A different fingerprints was expected.');
        Assert.AreEqual(FileAccountMock.BaseRelativeFolderPath(), Account."Base Relative Folder Path".Value(), 'A different base relative folder path was expected.');
    end;

    var
        Any: Codeunit Any;
        Assert: Codeunit "Library Assert";
        FileAccountMock: Codeunit "Ext. SFTP Account Mock";
}