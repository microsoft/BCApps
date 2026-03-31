// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Email;

using System.Email;
using System.TestLibraries.Email;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 134693 "Email Scenario Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Scenario" = r;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        ConnectorMock: Codeunit "Connector Mock";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
        EmailScenario: Codeunit "Email Scenario";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountScenarioNotExistsTest()
    var
        TempEmailAccount: Record "Email Account";
    begin
        // [Scenario] When the email scenario isn't mapped an email account, GetEmailAccount returns false
        PermissionsMock.Set('Email Admin');

        // [Given] No mappings between emails and scenarios
        Initialize();

        // [When] calling GetEmailAccount
        // [Then] false is returned
        Assert.IsFalse(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should not be any account');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountNotExistsTest()
    var
        TempEmailAccount: Record "Email Account";
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the email scenario is mapped non-existing email account, GetEmailAccount returns false
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario pointing to a non-existing email account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", NonExistentAccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] false is returned
        Assert.IsFalse(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountDefaultNotExistsTest()
    var
        TempEmailAccount: Record "Email Account";
        NonExistentAccountId: Guid;
    begin
        // [Scenario] When the default email scenario is mapped to a non-existing email account, GetEmailAccount returns false
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario isn't mapped to a account and the default scenario is mapped to a non-existing account
        Initialize();
        NonExistentAccountId := Any.GuidValue();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, NonExistentAccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] false is returned
        Assert.IsFalse(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should not be any account mapped to the scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountDefaultExistsTest()
    var
        TempEmailAccount: Record "Email Account";
        AccountId: Guid;
    begin
        // [Scenario] When the default email scenario is mapped to an existing email account, GetEmailAccount returns that account
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario isn't mapped to an account and the default scenario is mapped to an existing account
        Initialize();
        ConnectorMock.AddAccount(AccountId);
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, AccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] true is returned and the email account is as expected
        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(AccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');
    end;

    [Test]
    procedure IsThereEmailAccountSetForScenarioTest()
    var
        AccountId: Guid;
    begin
        // [Scenario] IsThereEmailAccountSetForScenario will check whether an email account is set for a given scenario
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario is assigned an account
        Initialize();
        ConnectorMock.AddAccount(AccountId);

        // [When] An email account is set for the default scenario
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, AccountId, Enum::"Email Connector"::"Test Email Connector");
        // [Then] false is returned for the test scenario
        Assert.IsFalse(EmailScenario.IsThereEmailAccountSetForScenario(Enum::"Email Scenario"::"Test Email Scenario"), 'No email account is set for the default scenario');

        // [When] An email account is set for the test scenario
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", AccountId, Enum::"Email Connector"::"Test Email Connector");
        // [Then] true is returned for the test scenario
        Assert.IsTrue(EmailScenario.IsThereEmailAccountSetForScenario(Enum::"Email Scenario"::"Test Email Scenario"), 'An email account is set for the test scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountExistsTest()
    var
        TempEmailAccount: Record "Email Account";
        AccountId: Guid;
    begin
        // [Scenario] When the email scenario is mapped to an existing email account, GetEmailAccount returns that account
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario is mapped to an account
        Initialize();
        ConnectorMock.AddAccount(AccountId);
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", AccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] true is returned and the email account is as expected
        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(AccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountDefaultDifferentTest()
    var
        TempEmailAccount: Record "Email Account";
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the email scenario and the default scenarion are mapped to different email accounts, GetEmailAccount returns the corrent account
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario is mapped to an account, the default scenarion is mapped to another account
        Initialize();
        ConnectorMock.AddAccount(AccountId);
        ConnectorMock.AddAccount(DefaultAccountId);
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", AccountId, Enum::"Email Connector"::"Test Email Connector");
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, DefaultAccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] true is returned and the email accounts are as expected
        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(AccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');

        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(DefaultAccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountDefaultDifferentNotExistTest()
    var
        TempEmailAccount: Record "Email Account";
        NonExistingAccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the email scenario is mapped to a non-existing account and the default scenarion is mapped to an existing accounts, GetEmailAccount returns the corrent account
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario is mapped to a non-exisitng account, the default scenarion is mapped to an existing account
        Initialize();
        ConnectorMock.AddAccount(DefaultAccountId);
        NonExistingAccountId := Any.GuidValue();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", NonExistingAccountId, Enum::"Email Connector"::"Test Email Connector");
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, DefaultAccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] true is returned and the email accounts are as expected
        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(DefaultAccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');

        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, TempEmailAccount), 'There should be an email account for the default scenario');
        Assert.AreEqual(DefaultAccountId, TempEmailAccount."Account Id", 'Wrong default account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong default account connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetEmailAccountDifferentDefaultNotExistTest()
    var
        TempEmailAccount: Record "Email Account";
        AccountId: Guid;
        DefaultAccountId: Guid;
    begin
        // [Scenario] When the email scenario is mapped to an existing account and the default scenarion is mapped to a non-existing accounts, GetEmailAccount returns the corrent account
        PermissionsMock.Set('Email Admin');

        // [Given] An email scenario is mapped to an exisitng account, the default scenarion is mapped to a non-existing account
        Initialize();
        ConnectorMock.AddAccount(AccountId);
        DefaultAccountId := Any.GuidValue();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::"Test Email Scenario", AccountId, Enum::"Email Connector"::"Test Email Connector");
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, DefaultAccountId, Enum::"Email Connector"::"Test Email Connector");

        // [When] calling GetEmailAccount
        // [Then] true is returned and the email account is as expected
        Assert.IsTrue(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount), 'There should be an email account');
        Assert.AreEqual(AccountId, TempEmailAccount."Account Id", 'Wrong account ID');
        Assert.AreEqual(Enum::"Email Connector"::"Test Email Connector", TempEmailAccount.Connector, 'Wrong connector');

        // [Then] there's no account for the default email scenario
        Assert.IsFalse(EmailScenario.GetEmailAccount(Enum::"Email Scenario"::Default, TempEmailAccount), 'There should not be an email account for the default scenario');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetEmailAccountTest()
    var
        TempEmailAccount: Record "Email Account";
        TempAnotherAccount: Record "Email Account";
        EmailScenarios: Record "Email Scenario";
        Scenario: Enum "Email Scenario";
    begin
        // [Scenario] When SetAccount is called, the entry in the database is as expected
        PermissionsMock.Set('Email Admin');

        // [Given] A random email account
        Initialize();
        TempEmailAccount."Account Id" := Any.GuidValue();
        TempEmailAccount.Connector := Enum::"Email Connector"::"Test Email Connector";
        Scenario := Scenario::Default;

        // [When] Setting the email account for the scenario
        EmailScenario.SetEmailAccount(Scenario, TempEmailAccount);

        // [Then] The scenario exists and is as expected
        Assert.IsTrue(EmailScenarios.Get(Scenario), 'The email scenario should exist');
        Assert.AreEqual(EmailScenarios."Account Id", TempEmailAccount."Account Id", 'Wrong accound ID');
        Assert.AreEqual(EmailScenarios.Connector, TempEmailAccount.Connector, 'Wrong connector');

        TempAnotherAccount."Account Id" := Any.GuidValue();
        TempAnotherAccount.Connector := Enum::"Email Connector"::"Test Email Connector";

        // [When] Setting overwting the email account for the scenario
        EmailScenario.SetEmailAccount(Scenario, TempAnotherAccount);

        // [Then] The scenario still exists and is as expected
        Assert.IsTrue(EmailScenarios.Get(Scenario), 'The email scenario should exist');
        Assert.AreEqual(EmailScenarios."Account Id", TempAnotherAccount."Account Id", 'Wrong accound ID');
        Assert.AreEqual(EmailScenarios.Connector, TempAnotherAccount.Connector, 'Wrong connector');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnassignScenarioTest()
    var
        TempEmailAccount: Record "Email Account";
        TempDefaultAccount: Record "Email Account";
        TempResultAccount: Record "Email Account";
    begin
        // [Scenario] When unassigning a scenario then it falls back to the default account.
        PermissionsMock.Set('Email Admin');

        // [Given] Two accounts, one default and one not 
        Initialize();
        ConnectorMock.AddAccount(TempEmailAccount);
        ConnectorMock.AddAccount(TempDefaultAccount);
        EmailScenario.SetDefaultEmailAccount(TempDefaultAccount);
        EmailScenario.SetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempEmailAccount);

        // mid-test verification
        EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempResultAccount);
        Assert.AreEqual(TempEmailAccount."Account Id", TempResultAccount."Account Id", 'Wrong account');

        // [When] Unassign the email scenario
        EmailScenario.UnassignScenario(Enum::"Email Scenario"::"Test Email Scenario");

        // [Then] The default account is returned for that account
        EmailScenario.GetEmailAccount(Enum::"Email Scenario"::"Test Email Scenario", TempResultAccount);
        Assert.AreEqual(TempDefaultAccount."Account Id", TempResultAccount."Account Id", 'The default account should have been returned');
    end;

    local procedure Initialize()
    begin
        EmailScenarioMock.DeleteAllMappings();
    end;
}