// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.FileSystem;

using System.FileSystem;
using System.TestLibraries.FileSystem;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134752 "File Scenario Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        FileScenario: Codeunit "File Scenario";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountScenarioNotExistsTest()
    var
        FileAccount: Record "File Account";
    begin
        // [Scenario] When the File scenario isn't mapped an File account, GetFileAccount returns false
        PermissionsMock.Set('File System Admin');

        // [Given] No mappings between Files and scenarios
        Initialize();

        // [When] calling GetFileAccount
        // [Then] false is retuned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should not be any account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountNotExistsTest()
    var
        FileAccount: Record "File Account";
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped non-existing File account, GetFileAccount returns false
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario pointing to a non-existing File account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", NonExistentAccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] false is retuned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultNotExistsTest()
    var
        FileAccount: Record "File Account";
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the default File scenario is mapped to a non-existing File account, GetFileAccount returns false
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario isn't mapped to a account and the default scenario is mapped to a non-existing account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, NonExistentAccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] false is retuned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultExistsTest()
    var
        FileAccount: Record "File Account";
        AccountId: Guid;
    begin
        // [Scenario] When the default File scenario is mapped to an existing File account, GetFileAccount returns that account
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario isn't mapped to an account and the default scenario is mapped to an existing account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, AccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] true is retuned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountExistsTest()
    var
        FileAccount: Record "File Account";
        AccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to an existing File account, GetFileAccount returns that account
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario is mapped to an account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] true is retuned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultDifferentTest()
    var
        FileAccount: Record "File Account";
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the File scenario and the default scenarion are mapped to different File accounts, GetFileAccount returns the corrent account
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario is mapped to an account, the default scenarion is mapped to another account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileConnectorMock.AddAccount(DefaultAccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"File System Connector"::"Test File System Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] true is retuned and the File accounts are as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');

        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, FileAccount), 'There should be an File account');
        Assert.AreEqual(DefaultAccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultDifferentNotExistTest()
    var
        FileAccount: Record "File Account";
        NonExistingAccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to a non-existing account and the default scenarion is mapped to an existing accounts, GetFileAccount returns the corrent account
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario is mapped to a non-exisitng account, the default scenarion is mapped to an existing account
        Initialize();
        FileConnectorMock.AddAccount(DefaultAccountId);
        NonExistingAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", NonExistingAccountId, Enum::"File System Connector"::"Test File System Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] true is retuned and the File accounts are as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should be an File account');
        Assert.AreEqual(DefaultAccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');

        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, FileAccount), 'There should be an File account for the default scenario');
        Assert.AreEqual(DefaultAccountId, FileAccount."Account Id", 'Wrong default account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong default account connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDifferentDefaultNotExistTest()
    var
        FileAccount: Record "File Account";
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to an existing account and the default scenarion is mapped to a non-existing accounts, GetFileAccount returns the corrent account
        PermissionsMock.Set('File System Admin');

        // [Given] An File scenario is mapped to an exisitng account, the default scenarion is mapped to a non-existing account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        DefaultAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"File System Connector"::"Test File System Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"File System Connector"::"Test File System Connector");

        // [When] calling GetFileAccount
        // [Then] true is retuned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, FileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"File System Connector"::"Test File System Connector", FileAccount.Connector, 'Wrong connector');

        // [Then] there's no account for the default File scenario
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, FileAccount), 'There should not be an File account for the default scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFileAccountTest()
    var
        FileAccount: Record "File Account";
        AnotherAccount: Record "File Account";
        FileSystemTestLib: Codeunit "File System Test Lib.";
        FileSystemConnector: Interface "File System Connector";
        AccountId: Guid;
        Scenario: Enum "File Scenario";
    begin
        // [Scenario] When SetAccount is called, the entry in the database is as expected
        PermissionsMock.Set('File System Admin');

        // [Given] A random File account
        Initialize();
        FileAccount."Account Id" := Any.GuidValue();
        FileAccount.Connector := Enum::"File System Connector"::"Test File System Connector";
        Scenario := Scenario::Default;

        // [When] Setting the File account for the scenario
        FileScenario.SetFileAccount(Scenario, FileAccount);

        // [Then] The scenario exists and is as expected
        Assert.IsTrue(FileSystemTestLib.GetFileScenarioAccountIdAndFileConnector(Scenario, AccountId, FileSystemConnector), 'The File scenario should exist');
        Assert.AreEqual(AccountId, FileAccount."Account Id", 'Wrong accound ID');
        Assert.AreEqual(FileSystemConnector, FileAccount.Connector, 'Wrong connector');

        AnotherAccount."Account Id" := Any.GuidValue();
        AnotherAccount.Connector := Enum::"File System Connector"::"Test File System Connector";

        // [When] Setting overwting the File account for the scenario
        FileScenario.SetFileAccount(Scenario, AnotherAccount);

        // [Then] The scenario still exists and is as expected
        Assert.IsTrue(FileSystemTestLib.GetFileScenarioAccountIdAndFileConnector(Scenario, AccountId, FileSystemConnector), 'The File scenario should exist');
        Assert.AreEqual(AccountId, AnotherAccount."Account Id", 'Wrong accound ID');
        Assert.AreEqual(FileSystemConnector, AnotherAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnassignScenarioTest()
    var
        FileAccount: Record "File Account";
        DefaultAccount: Record "File Account";
        ResultAccount: Record "File Account";
    begin
        // [Scenario] When unassigning a scenario then it falls back to the default account.
        PermissionsMock.Set('File System Admin');

        // [Given] Two accounts, one default and one not 
        Initialize();
        FileConnectorMock.AddAccount(FileAccount);
        FileConnectorMock.AddAccount(DefaultAccount);
        FileScenario.SetDefaultFileAccount(DefaultAccount);
        FileScenario.SetFileAccount(Enum::"File Scenario"::"Test File Scenario", FileAccount);

        // mid-test verification
        FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", ResultAccount);
        Assert.AreEqual(FileAccount."Account Id", ResultAccount."Account Id", 'Wrong account');

        // [When] Unassign the File scenario
        FileScenario.UnassignScenario(Enum::"File Scenario"::"Test File Scenario");

        // [Then] The default account is returned for that account
        FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", ResultAccount);
        Assert.AreEqual(DefaultAccount."Account Id", ResultAccount."Account Id", 'The default account should have been returned');
    end;

    local procedure Initialize()
    begin
        FileScenarioMock.DeleteAllMappings();
    end;
}