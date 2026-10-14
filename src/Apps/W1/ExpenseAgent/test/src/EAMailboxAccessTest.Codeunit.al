// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Email;
using System.TestLibraries.Email;

codeunit 148317 "EA Mailbox Access Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";

    [Test]
    procedure ValidateMailboxAccessTrueWhenNoEmailAccountsAreConfigured()
    var
        Setup: Record "Expense Agent Setup";
    begin
        InitEmptySetup(Setup);

        Assert.IsTrue(Setup.ValidateIncomingMailboxAccess(), 'Expected true when no incoming account is configured.');
        Assert.IsTrue(Setup.ValidateNoreplyMailboxAccess(), 'Expected true when no noreply account is configured.');
    end;

    [Test]
    procedure CheckMailboxAccessOrErrorIsNoOpWhenNoEmailAccountsAreConfigured()
    var
        Setup: Record "Expense Agent Setup";
    begin
        InitEmptySetup(Setup);

        Setup.CheckMailboxAccessOrError();
        Assert.IsTrue(IsNullGuid(Setup."Email Account ID"), 'Email Account ID should still be empty.');
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should still be empty.');
    end;

    [Test]
    procedure ValidateAccessFalseWhenRetrieveEmailsFails()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // The probe runs against a real test account; the connector is configured to fail
        // on RetrieveEmails to simulate the current user not having access to the mailbox.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsFalse(Setup.ValidateIncomingMailboxAccess(), 'Expected false when RetrieveEmails fails on the incoming account.');
        Assert.IsFalse(Setup.ValidateNoreplyMailboxAccess(), 'Expected false when RetrieveEmails fails on the noreply account.');
    end;

    [Test]
    procedure DeactivationWarningProceedsWhenNoMailbox()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // No mailbox -> warning skipped, deactivation proceeds.
        InitEmptySetup(Setup);
        Assert.IsTrue(Setup.ShowDeactivationAccessWarning(), 'Expected proceed when no mailbox is configured.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeactivationWarningProceedsWhenUserConfirms()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // Inaccessible mailbox -> warning shown; user clicks Yes -> proceed.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsTrue(Setup.ShowDeactivationAccessWarning(), 'Expected proceed when user confirms.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure DeactivationWarningCancelsWhenUserDeclines()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // Inaccessible mailbox -> warning shown; user clicks No -> cancel.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsFalse(Setup.ShowDeactivationAccessWarning(), 'Expected cancel when user declines.');
    end;

    [Test]
    procedure SchedulingAccessCheckIsNoOpWhenNoAccountsConfigured()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] The scheduling access check does nothing when the enabled features have no mailbox.
        // [GIVEN] Receipts and communication on, but no accounts configured.
        InitEmptySetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := true;

        // [THEN] The check is a no-op (no error) because there is no account to probe.
        Setup.CheckSchedulingMailboxAccessOrError();
        Assert.IsTrue(IsNullGuid(Setup."Email Account ID"), 'Email Account ID should still be empty.');
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should still be empty.');
    end;

    [Test]
    procedure SchedulingAccessCheckErrorsWhenReceiptsOnAndIncomingInaccessible()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Receipts on with an inaccessible incoming mailbox blocks scheduling.
        // [GIVEN] Receipts on with a mailbox the current user cannot access.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        Setup."Enable Email with Receipts" := true;
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check errors so the task is not scheduled to fail silently.
        asserterror Setup.CheckSchedulingMailboxAccessOrError();
    end;

    [Test]
    procedure SchedulingAccessCheckErrorsWhenCommunicationOnAndNoreplyInaccessible()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Communication on with an inaccessible no-reply mailbox blocks scheduling.
        // [GIVEN] Communication on with a no-reply account the current user cannot access, receipts off.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check errors on the no-reply account.
        asserterror Setup.CheckSchedulingMailboxAccessOrError();
    end;

    [Test]
    procedure SchedulingAccessCheckSkipsIncomingWhenReceiptsOff()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] An inaccessible incoming mailbox is ignored when receipts are off (the task won't read it).
        // [GIVEN] Receipts off with an inaccessible incoming account set, communication off.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        Setup."Enable Email with Receipts" := false;
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Enable Communication" := false;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error because the incoming mailbox is not needed.
        Setup.CheckSchedulingMailboxAccessOrError();
        Assert.IsFalse(Setup."Enable Email with Receipts", 'Receipts should remain off.');
    end;

    [Test]
    procedure SchedulingAccessCheckSkipsNoreplyWhenCommunicationOff()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] An inaccessible no-reply mailbox is ignored when communication is off (the task won't send).
        // [GIVEN] Communication off with an inaccessible no-reply account set, receipts off.
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        Setup."Enable Communication" := false;
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Setup."Enable Email with Receipts" := false;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error because the no-reply mailbox is not needed.
        Setup.CheckSchedulingMailboxAccessOrError();
        Assert.IsFalse(Setup."Enable Communication", 'Communication should remain off.');
    end;

    [Test]
    procedure SchedulingAccessCheckPassesWhenMailboxesAccessible()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] The scheduling access check succeeds (no error) when the enabled features
        // point at mailboxes the current user can access.
        // [GIVEN] Receipts and communication on with an accessible account (RetrieveEmails succeeds).
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        Setup."Enable Email with Receipts" := true;
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error.
        Setup.CheckSchedulingMailboxAccessOrError();
        Assert.IsTrue(Setup."Enable Communication", 'Communication should remain on after a successful check.');
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure AssistEditNoreplyClearsAccountWhenLookupCancelledAndConfirmed()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Cancelling the no-reply account lookup and confirming the prompt clears
        // the no-reply mailbox so the agent stops sending until a new account is chosen.
        // [GIVEN] A configured no-reply account (an account exists, so the wizard is skipped).
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Setup."Noreply Email Address" := 'noreply@contoso.com';
        Setup.Modify();
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the no-reply account.
        Setup.AssistEditNoreplyMailbox();

        // [THEN] The no-reply account fields are cleared.
        Setup.Get();
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should be cleared.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'Noreply Email Address should be cleared.');
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure AssistEditMailboxClearsAccountWhenLookupCancelledAndConfirmed()
    var
        Setup: Record "Expense Agent Setup";
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Cancelling the incoming (receipts) account lookup and confirming the
        // prompt clears the mailbox so the agent stops processing receipts until a new account is chosen.
        // [GIVEN] A configured incoming mailbox (an account exists, so the wizard is skipped).
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Email Address" := 'mailbox@contoso.com';
        Setup.Modify();
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the mailbox account.
        Setup.AssistEditMailbox();

        // [THEN] The incoming mailbox fields are cleared.
        Setup.Get();
        Assert.IsTrue(IsNullGuid(Setup."Email Account ID"), 'Email Account ID should be cleared.');
        Assert.AreEqual('', Setup."Email Address", 'Email Address should be cleared.');
    end;

    local procedure InitEmptySetup(var Setup: Record "Expense Agent Setup")
    begin
        Setup.DeleteAll();
        Setup.Init();
        Setup."Primary Key" := '';
        Setup.Insert();
    end;

    local procedure RegisterTestEmailAccount(var TempEmailAccount: Record "Email Account" temporary)
    begin
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
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

    [ModalPageHandler]
    procedure EmailAccountsCancelHandler(var EmailAccounts: TestPage "Email Accounts")
    begin
        EmailAccounts.Cancel().Invoke();
    end;
}
