// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.FileSystem;

using System.FileSystem;
using System.TestLibraries.FileSystem;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134686 "File Accounts Test"
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
        ConnectorMock: Codeunit "Connector Mock";
        AccountsPage: TestPage "File Accounts";
    begin
        // [Scenario] When there's a File account for a connector, it appears on the accounts page

        // [Given] A File account
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FileAccount);

        PermissionsMock.Set('File Edit');

        // [When] The accounts page is open
        AccountsPage.OpenView();

        // [Then] The email entry is visible on the page
        Assert.IsTrue(AccountsPage.GoToKey(FileAccount."Account Id", FileAccount.Connector), 'The File account should be on the page');

        Assert.AreEqual(FileAccount.Name, Format(AccountsPage.NameField), 'The account name on the page is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TwoAccountsAppearOnThePageTest()
    var
        FirstEmailAccount, SecondEmailAccount : Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        AccountsPage: TestPage "File Accounts";
    begin
        // [Scenario] When there's a File account for a connector, it appears on the accounts page

        // [Given] Two File accounts
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstEmailAccount);
        ConnectorMock.AddAccount(SecondEmailAccount);

        PermissionsMock.Set('Email Edit');

        // [When] The accounts page is open
        AccountsPage.OpenView();

        // [Then] The email entries are visible on the page
        Assert.IsTrue(AccountsPage.GoToKey(FirstEmailAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.AreEqual(FirstEmailAccount.Name, Format(AccountsPage.NameField), 'The first account name on the page is wrong');

        Assert.IsTrue(AccountsPage.GoToKey(SecondEmailAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.AreEqual(SecondEmailAccount.Name, Format(AccountsPage.NameField), 'The second account name on the page is wrong');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure IsAccountRegisteredTest()
    var
        EmailAccountRecord: Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccount: Codeunit "File Account";
    begin
        // [Scenario] When there's a File account for a connector, it should return true for IsAccountRegistered

        // [Given] An File account
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(EmailAccountRecord);

        PermissionsMock.Set('Email Edit');

        // [Then] The File account is registered
        Assert.IsTrue(EmailAccount.IsAccountRegistered(EmailAccountRecord."Account Id", EmailAccountRecord.Connector), 'The File account should be registered');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddNewAccountTest()
    var
        ConnectorMock: Codeunit "Connector Mock";
        AccountWizardPage: TestPage "File Account Wizard";
    begin
        // [SCENARIO] A new Account can be added through the Account Wizard
        PermissionsMock.Set('Email Admin');

        ConnectorMock.Initialize();

        // [WHEN] The AddAccount action is invoked
        AccountWizardPage.Trap();
        Page.Run(Page::"File Account Wizard");

        // [WHEN] The next field is invoked
        AccountWizardPage.Next.Invoke();

        // [THEN] The connector screen is shown and the test connector is shown
        Assert.IsTrue(AccountWizardPage.Logo.Visible(), 'Connector Logo should be visible');
        Assert.IsTrue(AccountWizardPage.Name.Visible(), 'Connector Name should be visible');
        Assert.IsTrue(AccountWizardPage.Details.Visible(), 'Connector Details should be visible');

        Assert.IsTrue(AccountWizardPage.GoToKey(Enum::"File System Connector"::"Test File System Connector"), 'Test Email connector was not shown in the page');

        // [WHEN] The Name field is drilled down
        AccountWizardPage.Next.Invoke();

        // [THEN] The Connector registers the Account and the last page is shown
        Assert.AreEqual(AccountWizardPage.EmailAddressfield.Value(), 'Test email address', 'A different Email address was expected');
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
        PermissionsMock.Set('Email Admin');

        AccountsPage.OpenView();
        // [WHEN] The AddAccount action is invoked
        AccountsPage.AddAccount.Invoke();

        // Verify with AddAccountModalPageHandler
    end;

    [Test]
    procedure OpenEditorFromAccountsPageTest()
    var
        TempAccount: Record "File Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        Accounts: TestPage "File Accounts";
        Editor: TestPage "Email Editor";
    begin
        // [SCENARIO] Email editor page can be opened from the Accounts page
        Editor.Trap();
        // [GIVEN] A connector is installed and an account is added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);

        PermissionsMock.Set('Email Edit');

        // [WHEN] The Send Email action is invoked
        Accounts.OpenView();
        Accounts.GoToKey(TempAccount."Account Id", TempAccount.Connector);
        Accounts.SendEmail.Invoke();

        // [THEN] The Editor page opens to create a new message
        Assert.AreEqual(StrSubstNo(AccountNameLbl, TempAccount.Name, TempAccount."Email Address"), Editor.Account.Value(), 'A different from was expected.');
    end;

    [Test]
    procedure OpenSentMailsFromAccountsPageTest()
    var
        TempAccount: Record "File Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        Accounts: TestPage "File Accounts";
        SentEmails: TestPage "Sent Emails";
    begin
        // [SCENARIO] Sent emails page can be opened from the Accounts page
        SentEmails.Trap();
        // [GIVEN] A connector is installed and an account is added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);

        PermissionsMock.Set('Email Edit');

        // [WHEN] The Sent Emails action is invoked
        Accounts.OpenView();
        Accounts.SentEmails.Invoke();

        // [THEN] The sent emails page opens
        // Verify with Trap
    end;

    [Test]
    procedure OpenOutBoxFromAccountsPageTest()
    var
        TempAccount: Record "File Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        Accounts: TestPage "File Accounts";
        Outbox: TestPage "Email Outbox";
    begin
        // [SCENARIO] Outbox page can be opened from the Accounts page
        Outbox.Trap();
        // [GIVEN] A connector is installed and an account is added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);

        PermissionsMock.Set('Email Edit');

        // [WHEN] The Outbox action is invoked
        Accounts.OpenView();
        Accounts.Outbox.Invoke();

        // [THEN] The outbox page opens
        // Verify with Trap
    end;

    [Test]
    procedure GetAllAccountsTest()
    var
        EmailAccountBuffer, EmailAccounts : Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccount: Codeunit "File Account";
    begin
        // [SCENARIO] GetAllAccounts retrieves all the registered accounts

        // [GIVEN] A connector is installed and no account is added
        ConnectorMock.Initialize();

        PermissionsMock.Set('Email Edit');

        // [WHEN] GetAllAccounts is called
        EmailAccount.GetAllAccounts(EmailAccounts);

        // [THEN] The returned record is empty (there are no registered accounts)
        Assert.IsTrue(EmailAccounts.IsEmpty(), 'Record should be empty');

        // [GIVEN] An account is added to the connector
        ConnectorMock.AddAccount(EmailAccountBuffer);

        // [WHEN] GetAllAccounts is called
        EmailAccount.GetAllAccounts(EmailAccounts);

        // [THEN] The returned record is not empty and the values are as expected
        Assert.AreEqual(1, EmailAccounts.Count(), 'Record should not be empty');
        EmailAccounts.FindFirst();
        Assert.AreEqual(EmailAccountBuffer."Account Id", EmailAccounts."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", EmailAccounts.Connector, 'Wrong connector');
        Assert.AreEqual(EmailAccountBuffer.Name, EmailAccounts.Name, 'Wrong account name');
    end;

    [Test]
    procedure IsAnyAccountRegisteredTest()
    var
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccount: Codeunit "File Account";
        AccountId: Guid;
    begin
        // [SCENARIO] File Account Exists works as expected

        // [GIVEN] A connector is installed and no account is added
        ConnectorMock.Initialize();

        PermissionsMock.Set('Email Edit');

        // [WHEN] Calling IsAnyAccountRegistered
        // [THEN] it evaluates to false
        Assert.IsFalse(EmailAccount.IsAnyAccountRegistered(), 'There should be no registered accounts');

        // [WHEN] An File account is added
        ConnectorMock.AddAccount(AccountId);

        // [WHEN] Calling IsAnyAccountRegistered
        // [THEN] it evaluates to true
        Assert.IsTrue(EmailAccount.IsAnyAccountRegistered(), 'There should be a registered account');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteAllAccountsTest()
    var
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When all accounts are deleted, the File Accounts page is empty
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccountId);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select all of the accounts
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(FirstAccountId);
        EmailAccountsSelectionMock.SelectAccount(SecondAccountId);
        EmailAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The page is empty
        Assert.IsFalse(EmailAccountsTestPage.First(), 'The File Accounts page should be empty');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure DeleteAllAccountsCancelTest()
    var
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When all accounts are about to be deleted but the action in canceled, the File Accounts page contains all of them.
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccountId);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select all of the accounts
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(FirstAccountId);
        EmailAccountsSelectionMock.SelectAccount(SecondAccountId);
        EmailAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is not confirmed (see ConfirmNoHandler)
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] All of the accounts are on the page
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(SecondAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteSomeAccountsTest()
    var
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        FirstAccountId, SecondAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When some accounts are deleted, they cannot be found on the page
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccountId);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select only two of the accounts
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(FirstAccountId);
        EmailAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsFalse(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should not be on the page');
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(SecondAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsFalse(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should not be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteNonDefaultAccountTest()
    var
        SecondAccount: Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        EmailScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the a non default account is deleted, the user is not prompted to choose a new default account.
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccount);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        EmailScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select a non-default account
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(FirstAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsFalse(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should not be on the page');

        Assert.IsTrue(EmailAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The second account should be marked as default');

        Assert.IsTrue(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteDefaultAccountTest()
    var
        SecondAccount: Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        EmailScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is not prompted to choose a new default account if there's only one account left
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccount);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        EmailScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select accounts including the default one
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");
        EmailAccountsSelectionMock.SelectAccount(ThirdAccountId);

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The deleted accounts are not on the page, the non-deleted accounts are on the page.
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The first account should be marked as default');

        Assert.IsFalse(EmailAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');
        Assert.IsFalse(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should not be on the page');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ChooseNewDefaultAccountCancelHandler')]
    procedure DeleteDefaultAccountPromptNewAccountCancelTest()
    var
        SecondAccount: Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        EmailScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is prompted to choose a new default account but they cancel.
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccount);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        EmailScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select the default account
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        AccountToSelect := ThirdAccountId; // The third account is selected as the new default account
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The default account was deleted and there is no new default account
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');

        Assert.IsFalse(EmailAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');

        Assert.IsTrue(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The third account should not be marked as default');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ChooseNewDefaultAccountHandler')]
    procedure DeleteDefaultAccountPromptNewAccountTest()
    var
        SecondAccount: Record "File Account";
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccountsSelectionMock: Codeunit "File System Acc Selection Mock";
        EmailScenario: Codeunit "File Scenario";
        FirstAccountId, ThirdAccountId : Guid;
        EmailAccountsTestPage: TestPage "File Accounts";
    begin
        // [SCENARIO] When the default account is deleted, the user is prompted to choose a new default account
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and three account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccount);
        ConnectorMock.AddAccount(ThirdAccountId);

        // [GIVEN] The second account is set as default
        EmailScenario.SetDefaultFileAccount(SecondAccount);

        // [WHEN] Open the File Accounts page
        EmailAccountsTestPage.OpenView();

        // [WHEN] Select the default account
        BindSubscription(EmailAccountsSelectionMock);
        EmailAccountsSelectionMock.SelectAccount(SecondAccount."Account Id");

        // [WHEN] Delete action is invoked and the action is confirmed (see ConfirmYesHandler)
        AccountToSelect := ThirdAccountId; // The third account is selected as the new default account
        EmailAccountsTestPage.Delete.Invoke();

        // [THEN] The second account is not on the page, the third account is set as default
        Assert.IsTrue(EmailAccountsTestPage.GoToKey(FirstAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The first File account should be on the page');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The first account should not be marked as default');

        Assert.IsFalse(EmailAccountsTestPage.GoToKey(SecondAccount."Account Id", Enum::"File System Connector"::"Test File System Connector"), 'The second File account should not be on the page');

        Assert.IsTrue(EmailAccountsTestPage.GoToKey(ThirdAccountId, Enum::"File System Connector"::"Test File System Connector"), 'The third File account should be on the page');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(EmailAccountsTestPage.DefaultField.Value), 'The third account should be marked as default');
    end;

    [Test]
    procedure DeleteAllAccountsWithoutUITest()
    var
        TempEmailAccount: Record "File Account" temporary;
        TempEmailAccountToDelete: Record "File Account" temporary;
        ConnectorMock: Codeunit "Connector Mock";
        EmailAccount: Codeunit "File Account";
        FirstAccountId, SecondAccountId : Guid;
    begin
        // [SCENARIO] When all accounts are deleted, the File Accounts page is empty
        PermissionsMock.Set('Email Admin');

        // [GIVEN] A connector is installed and two account are added
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(FirstAccountId);
        ConnectorMock.AddAccount(SecondAccountId);

        // [GIVEN] Mark first account for deletion
        EmailAccount.GetAllAccounts(TempEmailAccountToDelete);
        Assert.AreEqual(2, TempEmailAccountToDelete.Count(), 'Expected to have 2 accounts.');
        TempEmailAccountToDelete.SetRange("Account Id", FirstAccountId);

        // [WHEN] File Accounts are deleted
        EmailAccount.DeleteAccounts(TempEmailAccountToDelete, true);

        // [THEN] Verify second account still exists
        EmailAccount.GetAllAccounts(TempEmailAccount);
        Assert.AreEqual(1, TempEmailAccount.Count(), 'Expected to have 1 account.');
        TempEmailAccount.FindFirst();
        Assert.AreEqual(SecondAccountId, TempEmailAccount."Account Id", 'The second File account should still exist.');
    end;

    [ModalPageHandler]
    procedure AddAccountModalPageHandler(var AccountWizardTestPage: TestPage "File Account Wizard")
    begin

    end;

    [PageHandler]
    procedure SentEmailsPageHandler(var SentEmailsPage: TestPage "Sent Emails")
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
