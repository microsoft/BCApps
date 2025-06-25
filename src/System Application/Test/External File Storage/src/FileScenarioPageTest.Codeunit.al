// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.ExternalFileStorage;

using System.TestLibraries.ExternalFileStorage;
using System.ExternalFileStorage;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 134751 "File Scenario Page Test"
{
    Subtype = Test;

    var
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        DisplayNameTxt: Label '%1', Locked = true;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageOpenNoData()
    var
        FileScenarioPage: TestPage "File Scenario Setup";
    begin
        // [Scenario] The "File Scenario Setup" shows no data when there are no file accounts
        PermissionsMock.Set('File Storage Admin');

        // [Given] No file account is registered.
        FileConnectorMock.Initialize();

        // [When] Opening the the page
        FileScenarioPage.Trap();
        FileScenarioPage.OpenView();

        // [Then] There is no data on the page
        Assert.IsFalse(FileScenarioPage.First(), 'There should be no data on the page');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageOpenOneEntryTest()
    var
        TempFileAccount: Record "File Account" temporary;
        FileScenarioPage: TestPage "File Scenario Setup";
    begin
        // [Scenario] The "File Scenario Setup" shows one entry when there is only one file account and no scenarios
        PermissionsMock.Set('File Storage Admin');

        // [Given] One file account is registered.
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);

        // [When] Opening the the page
        FileScenarioPage.Trap();
        FileScenarioPage.OpenView();

        // [Then] There is one entry on the page  and it is not set as default
        Assert.IsTrue(FileScenarioPage.First(), 'There should be an entry on the page');

        // Properties are as expected
        Assert.AreEqual(StrSubstNo(DisplayNameTxt, TempFileAccount.Name), FileScenarioPage.Name.Value, 'Wrong entry name');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should not be marked as default');

        // Actions visibility is as expected
        Assert.IsTrue(FileScenarioPage.AddScenario.Visible(), 'The action "Add Scenarios" should be visible');
        Assert.IsFalse(FileScenarioPage.ChangeAccount.Visible(), 'The action "Change Accounts" should not be visible');
        Assert.IsFalse(FileScenarioPage.Unassign.Visible(), 'The action "Unassign" should not be visible');

        Assert.IsFalse(FileScenarioPage.Next(), 'There should not be another entry on the page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageOpenOneDefaultEntryTest()
    var
        TempFileAccount: Record "File Account" temporary;
        FileScenarioPage: TestPage "File Scenario Setup";
    begin
        // [Scenario] The "File Scenario Setup" shows one entry when there is only one file account and no scenarios
        PermissionsMock.Set('File Storage Admin');

        // [Given] One file account is registered and it's set as default.
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);

        FileScenarioMock.DeleteAllMappings();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, TempFileAccount."Account Id", TempFileAccount.Connector);

        // [When] Opening the the page
        FileScenarioPage.Trap();
        FileScenarioPage.OpenView();

        // [Then] There is one entry on the page and it is set as default
        Assert.IsTrue(FileScenarioPage.First(), 'There should be an entry on the page');

        // Properties are as expected
        Assert.AreEqual(StrSubstNo(DisplayNameTxt, TempFileAccount.Name), FileScenarioPage.Name.Value, 'Wrong entry name');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should be marked as default');

        // Actions visibility is as expected
        Assert.IsTrue(FileScenarioPage.AddScenario.Visible(), 'The action "Add Scenarios" should be visible');
        Assert.IsFalse(FileScenarioPage.ChangeAccount.Visible(), 'The action "Change Accounts" should not be visible');
        Assert.IsFalse(FileScenarioPage.Unassign.Visible(), 'The action "Unassign" should not be visible');

        Assert.IsFalse(FileScenarioPage.Next(), 'There should not be another entry on the page');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageOpenOneAcountsTwoScenariosTest()
    var
        TempFileAccount: Record "File Account" temporary;
        FileScenarioPage: TestPage "File Scenario Setup";
    begin
        // [Scenario] Having one default account with a non-default scenario assigned displays properly on "File Scenario Setup"
        PermissionsMock.Set('File Storage Admin');

        // [Given] One file account is registered and it's set as default.
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFileAccount);

        FileScenarioMock.DeleteAllMappings();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, TempFileAccount."Account Id", TempFileAccount.Connector);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", TempFileAccount."Account Id", TempFileAccount.Connector);

        // [When] Opening the the page
        FileScenarioPage.Trap();
        FileScenarioPage.OpenView();

        // [Then] There is one entry on the page and it is set as default. There's another entry for the other assigned scenario
        Assert.IsTrue(FileScenarioPage.First(), 'There should be data on the page');

        // Properties are as expected
        Assert.AreEqual(StrSubstNo(DisplayNameTxt, TempFileAccount.Name), FileScenarioPage.Name.Value, 'Wrong entry name');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should be marked as default');

        // Actions visibility is as expected
        Assert.IsTrue(FileScenarioPage.AddScenario.Visible(), 'The action "Add Scenarios" should be visible');
        Assert.IsFalse(FileScenarioPage.ChangeAccount.Visible(), 'The action "Change Accounts" should not be visible');
        Assert.IsFalse(FileScenarioPage.Unassign.Visible(), 'The action "Unassign" should not be visible');

        FileScenarioPage.Expand(true);
        Assert.IsTrue(FileScenarioPage.Next(), 'There should be another entry on the page');

        // Properties are as expected
        Assert.AreEqual(Format(Enum::"File Scenario"::"Test File Scenario"), FileScenarioPage.Name.Value, 'Wrong entry name');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should not be marked as default');

        // Actions visibility is as expected
        Assert.IsFalse(FileScenarioPage.AddScenario.Visible(), 'The action "Add Scenarios" should be visible');
        Assert.IsTrue(FileScenarioPage.ChangeAccount.Visible(), 'The action "Change Accounts" should not be visible');
        Assert.IsTrue(FileScenarioPage.Unassign.Visible(), 'The action "Unassign" should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageOpenTwoAcountsTwoScenariosTest()
    var
        TempFirstFileAccount, TempSecondFileAccount : Record "File Account" temporary;
        FileScenarioPage: TestPage "File Scenario Setup";
    begin
        // [Scenario] The "File Scenario Setup" shows three entries when there are two accounts - one with the default scenario and one with a non-default scenario
        PermissionsMock.Set('File Storage Admin');

        // [Given] Two file accounts are registered. One is set as default.
        FileConnectorMock.Initialize();
        FileConnectorMock.AddAccount(TempFirstFileAccount);
        FileConnectorMock.AddAccount(TempSecondFileAccount);

        FileScenarioMock.DeleteAllMappings();
        FileScenarioMock.AddMapping(Enum::"File Scenario"::Default, TempFirstFileAccount."Account Id", TempFirstFileAccount.Connector);
        FileScenarioMock.AddMapping(Enum::"File Scenario"::"Test File Scenario", TempSecondFileAccount."Account Id", TempSecondFileAccount.Connector);

        // [When] Opening the the page
        FileScenarioPage.Trap();
        FileScenarioPage.OpenView();

        // [Then] There are three entries on the page. One is set as default
        Assert.IsTrue(FileScenarioPage.GoToKey(-1, TempFirstFileAccount."Account Id", TempFirstFileAccount.Connector), 'There should be data on the page');
        Assert.AreEqual(StrSubstNo(DisplayNameTxt, TempFirstFileAccount.Name), FileScenarioPage.Name.Value, 'Wrong first entry name');
        Assert.IsTrue(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should be marked as default');

        Assert.IsTrue(FileScenarioPage.GoToKey(-1, TempSecondFileAccount."Account Id", TempSecondFileAccount.Connector), 'There should be another entry on the page');
        Assert.AreEqual(StrSubstNo(DisplayNameTxt, TempSecondFileAccount.Name), FileScenarioPage.Name.Value, 'Wrong second entry name');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should not be marked as default');

        FileScenarioPage.Expand(true);
        Assert.IsTrue(FileScenarioPage.Next(), 'There should be a third entry on the page');
        Assert.AreEqual(Format(Enum::"File Scenario"::"Test File Scenario"), FileScenarioPage.Name.Value, 'Wrong third entry name');
        Assert.IsFalse(GetDefaultFieldValueAsBoolean(FileScenarioPage.Default.Value), 'The account should not be marked as default');
    end;

    local procedure GetDefaultFieldValueAsBoolean(DefaultFieldValue: Text): Boolean
    begin
        exit(DefaultFieldValue = '✓');
    end;
}