// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 134752 "File Scenario Test"
{
    Subtype = Test;

    var
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenario: Codeunit "File Scenario";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [Scope('OnPrem')]
    procedure SpecificAssignmentCheckDoesNotFallBackToDefault()
    var
        TempFileAccount: Record "File Account" temporary;
    begin
        PermissionsMock.Set('File Storage Admin');
        Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        FileScenario.SetDefaultFileAccount(TempFileAccount);

        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempFileAccount, false), 'A matching default account must not substitute for a specific assignment');
        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempFileAccount, true), 'Locked validation must not substitute the default account');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Assignment validation must not retrieve remote content');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecificAssignmentCheckMatchesAccountAndConnector()
    var
        TempFileAccount: Record "File Account" temporary;
        TempOtherAccount: Record "File Account" temporary;
    begin
        PermissionsMock.Set('File Storage Admin');
        Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        FileConnectorMock.AddAccount(TempOtherAccount);
        FileScenario.SetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount);

        Assert.IsTrue(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempFileAccount, false), 'The exact assignment must match');
        Assert.IsTrue(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempFileAccount, true), 'The exact assignment must also match under update isolation');
        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempOtherAccount, true), 'Another account must not match');
        TempOtherAccount."Account Id" := TempFileAccount."Account Id";
        TempOtherAccount.Connector := Enum::"Ext. File Storage Connector".FromInteger(0);
        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempOtherAccount, true), 'The account ID alone must not match another connector');

        FileScenario.SetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempOtherAccount);
        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempFileAccount, false), 'An assignment change must reject the original account');
        FileScenario.UnassignScenario(Enum::"File Scenario"::"Test File Scenario");
        Assert.IsFalse(FileScenario.IsSpecificFileAccountAssigned(Enum::"File Scenario"::"Test File Scenario", TempOtherAccount, true), 'An unassigned scenario must not match');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Assignment checks must not retrieve remote content');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountScenarioNotExistsTest()
    var
        TempFileAccount: Record "File Account" temporary;
    begin
        // [Scenario] When the File scenario isn't mapped an File account, GetFileAccount returns false
        PermissionsMock.Set('File Storage Admin');

        // [Given] No mappings between Files and scenarios
        Initialize();

        // [When] calling GetFileAccount
        // [Then] false is returned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should not be any account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountNotExistsTest()
    var
        TempFileAccount: Record "File Account" temporary;
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped non-existing File account, GetFileAccount returns false
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario pointing to a non-existing File account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", NonExistentAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] false is returned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultNotExistsTest()
    var
        TempFileAccount: Record "File Account" temporary;
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the default File scenario is mapped to a non-existing File account, GetFileAccount returns false
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario isn't mapped to a account and the default scenario is mapped to a non-existing account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, NonExistentAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] false is returned
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultExistsTest()
    var
        TempFileAccount: Record "File Account" temporary;
        AccountId: Guid;
    begin
        // [Scenario] When the default File scenario is mapped to an existing File account, GetFileAccount returns that account
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario isn't mapped to an account and the default scenario is mapped to an existing account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, AccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] true is returned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountExistsTest()
    var
        TempFileAccount: Record "File Account" temporary;
        AccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to an existing File account, GetFileAccount returns that account
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario is mapped to an account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] true is returned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultDifferentTest()
    var
        TempFileAccount: Record "File Account" temporary;
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the File scenario and the default scenario are mapped to different File accounts, GetFileAccount returns the correct account
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario is mapped to an account, the default scenario is mapped to another account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        FileConnectorMock.AddAccount(DefaultAccountId);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] true is returned and the File accounts are as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');

        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, TempFileAccount), 'There should be an File account');
        Assert.AreEqual(DefaultAccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDefaultDifferentNotExistTest()
    var
        TempFileAccount: Record "File Account" temporary;
        DefaultAccountId: Guid;
        NonExistingAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to a non-existing account and the default scenario is mapped to an existing accounts, GetFileAccount returns the correct account
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario is mapped to a non-existing account, the default scenario is mapped to an existing account
        Initialize();
        FileConnectorMock.AddAccount(DefaultAccountId);
        NonExistingAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", NonExistingAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] true is returned and the File accounts are as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should be an File account');
        Assert.AreEqual(DefaultAccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');

        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, TempFileAccount), 'There should be an File account for the default scenario');
        Assert.AreEqual(DefaultAccountId, TempFileAccount."Account Id", 'Wrong default account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong default account connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFileAccountDifferentDefaultNotExistTest()
    var
        TempFileAccount: Record "File Account" temporary;
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the File scenario is mapped to an existing account and the default scenario is mapped to a non-existing accounts, GetFileAccount returns the correct account
        PermissionsMock.Set('File Storage Admin');

        // [Given] An File scenario is mapped to an existing account, the default scenario is mapped to a non-existing account
        Initialize();
        FileConnectorMock.AddAccount(AccountId);
        DefaultAccountId := Any.GuidValue();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", AccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, DefaultAccountId, Enum::"Ext. File Storage Connector"::"Test File Storage Connector");

        // [When] calling GetFileAccount
        // [Then] true is returned and the File account is as expected
        Assert.IsTrue(FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount), 'There should be an File account');
        Assert.AreEqual(AccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');

        // [Then] there's no account for the default File scenario
        Assert.IsFalse(FileScenario.GetFileAccount(Enum::"File Scenario"::Default, TempFileAccount), 'There should not be an File account for the default scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetFileAccountTest()
    var
        TempFileAccount, TempAnotherAccount : Record "File Account" temporary;
        ExtFileStorageTestLib: Codeunit "Ext. File Storage Test Lib.";
        ExternalFileStorageConnector: Interface "External File Storage Connector";
        AccountId: Guid;
        Scenario: Enum "File Scenario";
    begin
        // [Scenario] When SetAccount is called, the entry in the database is as expected
        PermissionsMock.Set('File Storage Admin');

        // [Given] A random File account
        Initialize();
        TempFileAccount."Account Id" := Any.GuidValue();
        TempFileAccount.Connector := Enum::"Ext. File Storage Connector"::"Test File Storage Connector";
        Scenario := Scenario::Default;

        // [When] Setting the File account for the scenario
        FileScenario.SetFileAccount(Scenario, TempFileAccount);

        // [Then] The scenario exists and is as expected
        Assert.IsTrue(ExtFileStorageTestLib.GetFileScenarioAccountIdAndFileConnector(Scenario, AccountId, ExternalFileStorageConnector), 'The File scenario should exist');
        Assert.AreEqual(AccountId, TempFileAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempFileAccount.Connector, 'Wrong connector');

        TempAnotherAccount."Account Id" := Any.GuidValue();
        TempAnotherAccount.Connector := Enum::"Ext. File Storage Connector"::"Test File Storage Connector";

        // [When] Setting overwriting the File account for the scenario
        FileScenario.SetFileAccount(Scenario, TempAnotherAccount);

        // [Then] The scenario still exists and is as expected
        Assert.IsTrue(ExtFileStorageTestLib.GetFileScenarioAccountIdAndFileConnector(Scenario, AccountId, ExternalFileStorageConnector), 'The File scenario should exist');
        Assert.AreEqual(AccountId, TempAnotherAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Ext. File Storage Connector"::"Test File Storage Connector", TempAnotherAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnassignScenarioTest()
    var
        TempDefaultAccount, TempFileAccount, TempResultAccount : Record "File Account" temporary;
    begin
        // [Scenario] When unassigning a scenario then it falls back to the default account.
        PermissionsMock.Set('File Storage Admin');

        // [Given] Two accounts, one default and one not
        Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);
        FileConnectorMock.AddAccount(TempDefaultAccount);
        FileScenario.SetDefaultFileAccount(TempDefaultAccount);
        FileScenario.SetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempFileAccount);

        // mid-test verification
        FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempResultAccount);
        Assert.AreEqual(TempFileAccount."Account Id", TempResultAccount."Account Id", 'Wrong account');

        // [When] Unassign the File scenario
        FileScenario.UnassignScenario(Enum::"File Scenario"::"Test File Scenario");

        // [Then] The default account is returned for that account
        FileScenario.GetFileAccount(Enum::"File Scenario"::"Test File Scenario", TempResultAccount);
        Assert.AreEqual(TempDefaultAccount."Account Id", TempResultAccount."Account Id", 'The default account should have been returned');
    end;

    local procedure Initialize()
    begin
        FileScenarioMock.DeleteAllMappings();
    end;
}