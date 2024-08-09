// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.FileSystem;

using System.FileSystem;
using System.TestLibraries.FileSystem;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134750 "File Accounts Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        AccountToSelect: Guid;
        AccountNameLbl: Label '%1 (%2)', Locked = true;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AccountsAppearOnThePageTest()
    var
        FileAccount: Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        AccountsPage: TestPage "File Accounts";
    begin
        // [Scenario] When there's a File account for a connector, it appears on the accounts page

        // [Given] A File account
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FileAccount);

        PermissionsMock.Set('File System Edit');

        // [When] The accounts page is open
        AccountsPage.OpenView();

        // [Then] The file entry is visible on the page
        Assert.IsTrue(AccountsPage.GoToKey(FileAccount."Account Id", FileAccount.Connector), 'The File account should be on the page');

        Assert.AreEqual(FileAccount.Name, Format(AccountsPage.NameField), 'The account name on the page is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoAccountsAppearOnThePageTest()
    var
        FirstFileAccount, SecondFileAccount : Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        AccountsPage: TestPage "File Accounts";
    begin
        // [Scenario] When there's a File account for a connector, it appears on the accounts page

        // [Given] Two File accounts
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstFileAccount);
        FileConnectorMock.AddAccount(SecondFileAccount);

        PermissionsMock.Set('File System Edit');

        // [When] The accounts page is open
        AccountsPage.OpenView();

        // [Then] The file entries are visible on the page
        Assert.IsTrue(AccountsPage.GoToKey(FirstFileAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.AreEqual(FirstFileAccount.Name, Format(AccountsPage.NameField), 'The first account name on the page is wrong');

        Assert.IsTrue(AccountsPage.GoToKey(SecondFileAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.AreEqual(SecondFileAccount.Name, Format(AccountsPage.NameField), 'The second account name on the page is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNewAccountTest()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        AccountWizardPage: TestPage "File Account Wizard";
    begin
        // [SCENARIO] A new Account can be added through the Account Wizard
        PermissionsMock.Set('File System Admin');

        FileConnectorMock.Initialize();

        // [WHEN] The AddAccount action is invoked
        AccountWizardPage.Trap();
        Page.Run(Page::"File Account Wizard");

        // [WHEN] The next field is invoked
        AccountWizardPage.Next.Invoke();

        // [THEN] The connector screen is shown and the test connector is shown
        Assert.IsTrue(AccountWizardPage.Logo.Visible(), 'Connector Logo should be visible');
        Assert.IsTrue(AccountWizardPage.Name.Visible(), 'Connector Name should be visible');
        Assert.IsTrue(AccountWizardPage.Details.Visible(), 'Connector Details should be visible');

        Assert.IsTrue(AccountWizardPage.GoToKey(Enum::"File System Connector"::"Test File System Connector"), 'Test File connector was not shown in the page');

        // [WHEN] The Name field is drilled down
        AccountWizardPage.Next.Invoke();

        // [THEN] The Connector registers the Account and the last page is shown
        Assert.AreEqual(AccountWizardPage.NameField.Value(), 'Test account', 'A different name was expected');
        Assert.AreEqual(AccountWizardPage.DefaultField.AsBoolean(), true, 'Default should be set to true if it''s the first account to be set up');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('AddAccountModalPageHandler')]
    procedure AddNewAccountActionRunsPageInModalTest()
    var
        AccountsPage: TestPage "File Accounts";
    begin
        // [SCENARIO] The add Account action open the Account Wizard page in modal mode
        PermissionsMock.Set('File System Admin');

        AccountsPage.OpenView();
        // [WHEN] The AddAccount action is invoked
        AccountsPage.AddAccount.Invoke();

        // Verify with AddAccountModalPageHandler
    end;

    [Test]
    procedure GetAllAccountsTest()
    var
        FileAccountBuffer, FileAccounts : Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccount: Codeunit "File Account";
    begin
        // [SCENARIO] GetAllAccounts retrieves all the registered accounts

        // [GIVEN] A connector is installed and no account is added
        FileConnectorMock.Initialize();

        PermissionsMock.Set('File System Edit');

        // [WHEN] GetAllAccounts is called
        FileAccount.GetAllAccounts(FileAccounts);

        // [THEN] The returned record is empty (there are no registered accounts)
        Assert.IsTrue(FileAccounts.IsEmpty(), 'Record should be empty');

        // [GIVEN] An account is added to the connector
        FileConnectorMock.AddAccount(FileAccountBuffer);

        // [WHEN] GetAllAccounts is called
        FileAccount.GetAllAccounts(FileAccounts);

        // [THEN] The returned record is not empty and the values are as expected
        Assert.AreEqual(1, FileAccounts.Count(), 'Record should not be empty');
        FileAccounts.FindFirst();
        Assert.AreEqual(FileAccountBuffer."Account Id", FileAccounts."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccounts.Connector, 'Wrong connector');
        Assert.AreEqual(FileAccountBuffer.Name, FileAccounts.Name, 'Wrong account name');
    end;

    [Test]
    procedure IsAnyAccountRegisteredTest()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccount: Codeunit "File Account";
        AccountId: Guid;
    begin
        // [SCENARIO] File Account Exists works as expected

        // [GIVEN] A connector is installed and no account is added
        FileConnectorMock.Initialize();

        PermissionsMock.Set('File System Edit');

        // [WHEN] Calling IsAnyAccountRegistered
        // [THEN] it evaluates to false
        Assert.IsFalse(FileAccount.IsAnyAccountRegistered(), 'There should be no registered accounts');

        // [WHEN] An File account is added
        FileConnectorMock.AddAccount(AccountId);

        // [WHEN] Calling IsAnyAccountRegistered
        // [THEN] it evaluates to true
        Assert.IsTrue(FileAccount.IsAnyAccountRegistered(), 'There should be a registered account');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteAllAccountsTest()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When all accounts are deleted, the File Accounts page is empty
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccountId);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select all of the accounts
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(FirstAccountId);
        FileAccountsSelectionMock.SelectAccount(SecondAccountId);
        FileAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The page is empty
        Assert.IsFalse(FileAccountsTestPage.First(), 'The File Accounts page should be empty');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure DeleteAllAccountsCancelTest()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When all accounts are about to be deleted but the action in canceled, the File Accounts page contains all of them.
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccountId);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select all of the accounts
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(FirstAccountId);
        FileAccountsSelectionMock.SelectAccount(SecondAccountId);
        FileAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is not confirmed (see ConfirmNoHandler)
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] All of the accounts are on the page
        Assert.IsTrue(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsTrue(FileAccountsTestPage.GoToKey(SecondAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsTrue(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteSomeAccountsTest()
    var
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When some accounts are deleted, they cannot be found on the page
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccountId);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select only two of the accounts
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(FirstAccountId);
        FileAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsFalse(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should not be on the page');
        Assert.IsTrue(FileAccountsTestPage.GoToKey(SecondAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsFalse(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should not be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteNonDefaultAccountTest()
    var
        SecondAccount: Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FileScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the a non default account is deleted, the user is not prompted to choose a new default account.
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccount);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        FileScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select a non-default account
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(FirstAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsFalse(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should not be on the page');

        Assert.IsTrue(FileAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The second account should be marked as default');

        Assert.IsTrue(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteDefaultAccountTest()
    var
        SecondAccount: Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FileScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is not prompted to choose a new default account if there's only one account left
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccount);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        FileScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select accounts including the default one
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");
        FileAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsTrue(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The first account should be marked as default');

        Assert.IsFalse(FileAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');
        Assert.IsFalse(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should not be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ChooseNewDefaultAccountCancelHandler')]
    procedure DeleteDefaultAccountPromptNewAccountCancelTest()
    var
        SecondAccount: Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FileScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is prompted to choose a new default account but they cancel.
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccount);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        FileScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select the default account
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        AccountToSelect := ThirdAccountId; // The third account is selected as the new default account
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The default account was deleted and there is no new default account
        Assert.IsTrue(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');

        Assert.IsFalse(FileAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');

        Assert.IsTrue(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ChooseNewDefaultAccountHandler')]
    procedure DeleteDefaultAccountPromptNewAccountTest()
    var
        SecondAccount: Record "File Account";
        FileConnectorMock: Codeunit "File Connector Mock";
        FileAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FileScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        FileAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is prompted to choose a new default account
        PermissionsMock.Set('File System Admin');

        // [GIVEN] A connector is installed and three account are added
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(FirstAccountId);
        FileConnectorMock.AddAccount(SecondAccount);
        FileConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        FileScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        FileAccountsTestPage.OpenView();

        // [WHEN] Select the default account
        BindSubscription(FileAccountsSelectionMock);
        FileAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        AccountToSelect := ThirdAccountId; // The third account is selected as the new default account
        FileAccountsTestPage.Delete.Invoke();

        // [THEN] The second account is not on the page, the third account is set as default
        Assert.IsTrue(FileAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The first account should not be marked as default');

        Assert.IsFalse(FileAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');

        Assert.IsTrue(FileAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileAccountsTestPage.DefaultField.Value), 'The third account should be marked as default');
    end;

    [ModalPageHandler]
    procedure AddAccountModalPageHandler(var AccountWizardTestPage: TestPage "File Account Wizard")
    begin
    end;

    [ModalPageHandler]
    procedure ChooseNewDefaultAccountCancelHandler(var AccountsPage: TestPage "File Accounts")
    begin
        AccountsPage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure ChooseNewDefaultAccountHandler(var AccountsPage: TestPage "File Accounts")
    begin
        AccountsPage.GoToKey(AccountToSelect, Enum::"File System Connector"::"Test File System Connector");
        AccountsPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure GetDefaultFieldValueAsBoolean(DefaultFieldValue: Text): Boolean
    begin
        exit(DefaultFieldValue = '✓');
    end;
}
