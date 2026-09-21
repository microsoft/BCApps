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
        TempSelectedEmailAccount: Record "Email Account" temporary;
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";
        IsolatedTestCompanyLbl: Label 'EA Email Lifecycle Test', Locked = true;
        CIIsolatedTestCompanyLbl: Label 'Empty Company', Locked = true;

    [Test]
    procedure ValidateMailboxAccessTrueWhenNoEmailAccountsAreConfigured()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        InitEmptySetup(TempSetup);

        Assert.IsTrue(TempSetup.ValidateIncomingMailboxAccess(), 'Expected true when no incoming account is configured.');
        Assert.IsTrue(TempSetup.ValidateNoreplyMailboxAccess(), 'Expected true when no noreply account is configured.');
    end;

    [Test]
    procedure CheckMailboxAccessOrErrorIsNoOpWhenNoEmailAccountsAreConfigured()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        InitEmptySetup(TempSetup);

        TempSetup.CheckMailboxAccessOrError();
        Assert.IsTrue(IsNullGuid(TempSetup."Email Account ID"), 'Email Account ID should still be empty.');
        Assert.IsTrue(IsNullGuid(TempSetup."Noreply Email Account ID"), 'Noreply Email Account ID should still be empty.');
    end;

    [Test]
    procedure ValidateAccessFalseWhenRetrieveEmailsFails()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // The probe runs against a real test account; the connector is configured to fail
        // on RetrieveEmails to simulate the current user not having access to the mailbox.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsFalse(TempSetup.ValidateIncomingMailboxAccess(), 'Expected false when RetrieveEmails fails on the incoming account.');
        Assert.IsFalse(TempSetup.ValidateNoreplyMailboxAccess(), 'Expected false when RetrieveEmails fails on the noreply account.');
    end;

    [Test]
    procedure DeactivationWarningProceedsWhenNoMailbox()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        // No mailbox -> warning skipped, deactivation proceeds.
        InitEmptySetup(TempSetup);
        Assert.IsTrue(TempSetup.ShowDeactivationAccessWarning(), 'Expected proceed when no mailbox is configured.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeactivationWarningProceedsWhenUserConfirms()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // Inaccessible mailbox -> warning shown; user clicks Yes -> proceed.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsTrue(TempSetup.ShowDeactivationAccessWarning(), 'Expected proceed when user confirms.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure DeactivationWarningCancelsWhenUserDeclines()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // Inaccessible mailbox -> warning shown; user clicks No -> cancel.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);

        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        Assert.IsFalse(TempSetup.ShowDeactivationAccessWarning(), 'Expected cancel when user declines.');
    end;

    [Test]
    procedure SchedulingAccessCheckIsNoOpWhenNoAccountsConfigured()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] The scheduling access check does nothing when the enabled features have no mailbox.
        // [GIVEN] Receipts and communication on, but no accounts configured.
        InitEmptySetup(TempSetup);
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Enable Communication" := true;

        // [THEN] The check is a no-op (no error) because there is no account to probe.
        TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.IsTrue(IsNullGuid(TempSetup."Email Account ID"), 'Email Account ID should still be empty.');
        Assert.IsTrue(IsNullGuid(TempSetup."Noreply Email Account ID"), 'Noreply Email Account ID should still be empty.');
    end;

    [Test]
    procedure SchedulingAccessCheckErrorsWhenReceiptsOnAndIncomingInaccessible()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Receipts on with an inaccessible incoming mailbox blocks scheduling.
        // [GIVEN] Receipts on with a mailbox the current user cannot access.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check errors so the task is not scheduled to fail silently.
        asserterror TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.ExpectedError('incoming receipts because the connection failed');
    end;

    [Test]
    procedure SchedulingAccessCheckErrorsWhenCommunicationOnAndNoreplyInaccessible()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] Communication on with an inaccessible no-reply mailbox blocks scheduling.
        // [GIVEN] Communication on with a no-reply account the current user cannot access, receipts off.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        TempSetup."Enable Email with Receipts" := false;
        TempSetup."Enable Communication" := true;
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check errors on the no-reply account.
        asserterror TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.ExpectedError('outgoing notifications because the connection failed');
    end;

    [Test]
    procedure SchedulingAccessCheckSkipsIncomingWhenReceiptsOff()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] An inaccessible incoming mailbox is ignored when receipts are off (the task won't read it).
        // [GIVEN] Receipts off with an inaccessible incoming account set, communication off.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        TempSetup."Enable Email with Receipts" := false;
        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        TempSetup."Enable Communication" := false;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error because the incoming mailbox is not needed.
        TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.IsFalse(TempSetup."Enable Email with Receipts", 'Receipts should remain off.');
    end;

    [Test]
    procedure SchedulingAccessCheckSkipsNoreplyWhenCommunicationOff()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] An inaccessible no-reply mailbox is ignored when communication is off (the task won't send).
        // [GIVEN] Communication off with an inaccessible no-reply account set, receipts off.
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        ConnectorMock.FailOnRetrieveEmails(true);
        TempSetup."Enable Communication" := false;
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        TempSetup."Enable Email with Receipts" := false;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error because the no-reply mailbox is not needed.
        TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.IsFalse(TempSetup."Enable Communication", 'Communication should remain off.');
    end;

    [Test]
    procedure SchedulingAccessCheckPassesWhenMailboxesAccessible()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO 636970] The scheduling access check succeeds (no error) when the enabled features
        // point at mailboxes the current user can access.
        // [GIVEN] Receipts and communication on with an accessible account (RetrieveEmails succeeds).
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        TempSetup."Enable Communication" := true;
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        Commit(); // Close the write transaction before running Codeunit.Run()

        // [THEN] The check does not error.
        TempSetup.CheckSchedulingMailboxAccessOrError();
        Assert.IsTrue(TempSetup."Enable Communication", 'Communication should remain on after a successful check.');
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure AssistEditNoreplyClearsAccountWhenLookupCancelledAndConfirmed()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Cancelling the no-reply account lookup and confirming the prompt clears
        // the no-reply mailbox so the agent stops sending until a new account is chosen.
        // [GIVEN] A configured no-reply account (an account exists, so the wizard is skipped).
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the no-reply account.
        TempSetup.AssistEditNoreplyMailbox();

        // [THEN] The no-reply account fields are cleared.
        TempSetup.Get();
        AssertNoreplyCleared(TempSetup);
        AssertIncomingUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure AssistEditMailboxClearsAccountWhenLookupCancelledAndConfirmed()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Cancelling the incoming (receipts) account lookup and confirming the
        // prompt clears the mailbox so the agent stops processing receipts until a new account is chosen.
        // [GIVEN] A configured incoming mailbox (an account exists, so the wizard is skipped).
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the mailbox account.
        TempSetup.AssistEditMailbox();

        // [THEN] The incoming mailbox fields are cleared.
        TempSetup.Get();
        AssertIncomingCleared(TempSetup);
        AssertNoreplyUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmNoHandler')]
    procedure DecliningIncomingClearPreservesConfiguration()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Declining the incoming-account clear confirmation preserves configuration.

        // [GIVEN] A configured temporary setup is loaded; the account selector is cancelled and the confirm handler replies No.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The incoming AssistEdit flow runs.
        TempSetup.AssistEditMailbox();


        // [THEN] Incoming, no-reply, and preference values remain unchanged in the temporary record.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        TempSetup.Get();
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmNoHandler')]
    procedure DecliningNoreplyClearPreservesConfiguration()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Declining the no-reply-account clear confirmation preserves configuration.

        // [GIVEN] A configured temporary setup is loaded; the account selector is cancelled and the confirm handler replies No.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The no-reply AssistEdit flow runs.
        TempSetup.AssistEditNoreplyMailbox();


        // [THEN] Incoming, no-reply, and preference values remain unchanged in the temporary record.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        TempSetup.Get();
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    procedure ExplicitCommunicationDisableStillClearsNotificationPreferences()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Explicitly disabling communication clears outgoing notification preferences without changing account identities.

        // [GIVEN] A configured temporary setup has receipts, communication, and notification preferences enabled.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;


        // [WHEN] The communication preference is validated to false.
        TempSetup.Validate("Enable Communication", false);


        // [THEN] Communication and notification preferences are off, while receipts, agent state, and both account identities are preserved.
        Assert.IsFalse(TempSetup."Enable Communication", 'The explicit communication preference must be off.');
        Assert.IsFalse(TempSetup."Enable Open Report Notif.", 'Explicitly disabling communication must still disable reminders.');
        Assert.IsFalse(TempSetup."Enable Approval Notif.", 'Explicitly disabling communication must still disable approval notifications.');
        Assert.IsTrue(TempSetup."Enable Email with Receipts", 'Disabling outgoing communication must not disable receipts.');
        Assert.AreEqual(TempPreviousSetup."Enable Agent", TempSetup."Enable Agent", 'The native agent state must not change.');
        AssertIncomingUnchanged(TempPreviousSetup, TempSetup);
        AssertNoreplyUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure SameAddressIncomingReplacementClearsOldFolders()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
        TestEmailAccount: Record "Test Email Account";
    begin
        // [SCENARIO] Replacing an incoming account clears folders even when the email address is unchanged.

        // [GIVEN] A configured temporary setup has old folder values, and the selector handler chooses a different registered account with the same address.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        ConnectorMock.AddAccount(TempSelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TestEmailAccount.Get(TempSelectedEmailAccount."Account Id");
        TestEmailAccount.Email := TempSetup."Email Address";
        TestEmailAccount.Modify();
        TempSelectedEmailAccount."Email Address" := TempSetup."Email Address";
        Commit();


        // [WHEN] The incoming AssistEdit flow applies the selected account.
        TempSetup.AssistEditMailbox();


        // [THEN] The account identity changes, stale folder values clear, and no-reply settings and preferences remain unchanged.
        TempSetup.Get();
        Assert.AreEqual(TempSelectedEmailAccount."Account Id", TempSetup."Email Account ID", 'The incoming identity must change even if the address is unchanged.');
        Assert.AreEqual(TempPreviousSetup."Email Address", TempSetup."Email Address", 'The replacement intentionally uses the same address.');
        Assert.AreEqual('', TempSetup."Email Folder", 'The previous account folder must be cleared.');
        Assert.AreEqual('', TempSetup."Email Folder Id", 'The previous account folder ID must be cleared.');
        AssertNoreplyUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure IncomingConnectorReplacementClearsOldFolders()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Replacing the connector for the same incoming account clears stale folders.

        // [GIVEN] A configured temporary setup holds the selected account ID under a different connector and has old folder values.
        InitConfiguredSetup(TempSetup);
        SelectIncomingAccount(TempSetup);
        TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The incoming AssistEdit flow applies the registered connector identity.
        TempSetup.AssistEditMailbox();


        // [THEN] The connector changes, folder values clear, and no-reply settings and preferences remain unchanged.
        TempSetup.Get();
        Assert.AreEqual(TempPreviousSetup."Email Account ID", TempSetup."Email Account ID", 'Only the connector identity changes.');
        Assert.AreEqual(TempSelectedEmailAccount.Connector, TempSetup."Email Connector", 'The selected connector must replace the stale connector.');
        Assert.AreEqual('', TempSetup."Email Folder", 'Changing the connector must clear the folder.');
        Assert.AreEqual('', TempSetup."Email Folder Id", 'Changing the connector must clear the folder ID.');
        AssertNoreplyUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure ReselectingIncomingPreservesFoldersAndDefaultsEmptyNoreply()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Reselecting the unchanged incoming account preserves folders and defaults an empty no-reply channel.

        // [GIVEN] A configured temporary setup has no no-reply identity, and the selector handler chooses the current incoming account.
        InitConfiguredSetup(TempSetup);
        TempSetup.ClearNoreplyMailbox();
        SelectIncomingAccount(TempSetup);
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The incoming AssistEdit flow runs.
        TempSetup.AssistEditMailbox();


        // [THEN] Incoming fields including folders remain unchanged, and the no-reply identity is copied from the incoming account.
        TempSetup.Get();
        AssertIncomingUnchanged(TempPreviousSetup, TempSetup);
        Assert.AreEqual(TempSetup."Email Account ID", TempSetup."Noreply Email Account ID", 'Reselecting the same incoming account must still default an empty no-reply account.');
        Assert.AreEqual(TempSetup."Email Connector", TempSetup."Noreply Email Connector", 'The defaulted no-reply connector must match.');
        Assert.AreEqual(TempSetup."Email Address", TempSetup."Noreply Email Address", 'The defaulted no-reply address must match.');
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure InaccessibleIncomingReplacementPreservesPreviousConfiguration()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] A replacement incoming account that fails its retrieval probe is rejected without changing configuration.

        // [GIVEN] A configured temporary setup is captured, and the selector handler chooses a registered replacement whose connector retrieval is configured to fail.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        ConnectorMock.AddAccount(TempSelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();


        // [WHEN] The incoming AssistEdit flow is invoked with asserterror.
        asserterror TempSetup.AssistEditMailbox();


        // [THEN] The specific incoming connection error is asserted and all temporary configuration values remain unchanged.
        Assert.ExpectedError('incoming receipts because the connection failed');
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        TempSetup.Get();
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure InaccessibleNoreplyReplacementPreservesPreviousConfiguration()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] A replacement no-reply account that fails its retrieval probe is rejected without changing configuration.

        // [GIVEN] A configured temporary setup is captured, and the selector handler chooses a registered replacement whose connector retrieval is configured to fail.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        ConnectorMock.AddAccount(TempSelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();


        // [WHEN] The no-reply AssistEdit flow is invoked with asserterror.
        asserterror TempSetup.AssistEditNoreplyMailbox();


        // [THEN] The specific outgoing connection error is asserted and all temporary configuration values remain unchanged.
        Assert.ExpectedError('outgoing notifications because the connection failed');
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        TempSetup.Get();
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    procedure MissingAccountRepairPreservesPreferencesAndOtherChannel()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempRegisteredSetup: Record "Expense Agent Setup" temporary;
        MissingChannels: Integer;
    begin
        // [SCENARIO] Missing-account repair clears only missing channel identities and preserves preferences.

        // [GIVEN] A configured registered setup is copied across incoming-only, outgoing-only, and both-missing account-ID cases.
        InitConfiguredSetup(TempRegisteredSetup);

        // [WHEN] RepairMissingEmailAccounts runs for each case and is repeated after repair.
        for MissingChannels := 1 to 3 do begin
            TempSetup := TempRegisteredSetup;
            if MissingChannels in [1, 3] then
                TempSetup."Email Account ID" := CreateGuid();
            if MissingChannels in [2, 3] then
                TempSetup."Noreply Email Account ID" := CreateGuid();


        // [THEN] Only missing identities clear, surviving channels and preferences remain unchanged, and repeated repair is a no-op.
            Assert.IsTrue(TempSetup.RepairMissingEmailAccounts(), 'Missing references must be repaired.');

            if MissingChannels in [1, 3] then
                AssertIncomingCleared(TempSetup)
            else
                AssertIncomingUnchanged(TempRegisteredSetup, TempSetup);
            if MissingChannels in [2, 3] then
                AssertNoreplyCleared(TempSetup)
            else
                AssertNoreplyUnchanged(TempRegisteredSetup, TempSetup);
            AssertPreferencesUnchanged(TempRegisteredSetup, TempSetup);
            Assert.IsFalse(TempSetup.RepairMissingEmailAccounts(), 'Repeated repair must be a no-op.');
        end;
    end;

    [Test]
    procedure WrongConnectorAndEmptyIdentityRepairClearsOrphanedFields()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Missing-account repair clears orphaned fields for wrong connectors and empty IDs.

        // [GIVEN] A configured setup is varied first to mismatched connectors and then to empty account IDs.
        InitConfiguredSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        TempSetup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";


        // [WHEN] RepairMissingEmailAccounts runs for each invalid identity state.
        Assert.IsTrue(TempSetup.RepairMissingEmailAccounts(), 'The ID must be registered under the selected connector.');

        // [THEN] Both channel identities clear while all preferences remain unchanged.
        AssertIncomingCleared(TempSetup);
        AssertNoreplyCleared(TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);

        TempSetup := TempPreviousSetup;
        Clear(TempSetup."Email Account ID");
        Clear(TempSetup."Noreply Email Account ID");
        Assert.IsTrue(TempSetup.RepairMissingEmailAccounts(), 'Empty IDs must not retain orphaned addresses, connectors or folders.');
        AssertIncomingCleared(TempSetup);
        AssertNoreplyCleared(TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    procedure SchedulingAccessSkipsStaleIncomingWithAvailableOutgoing()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Scheduling access checking skips a stale incoming reference when outgoing remains available.

        // [GIVEN] A configured temporary setup has a missing incoming account ID and a registered outgoing account.
        InitConfiguredSetup(TempSetup);
        TempSetup."Email Account ID" := CreateGuid();
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The scheduling mailbox access check runs.
        TempSetup.CheckSchedulingMailboxAccessOrError();


        // [THEN] Configuration remains unchanged and the outgoing channel keeps the agent eligible.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsTrue(TempSetup.ShouldScheduleAgentTask(true), 'The registered outgoing channel must remain usable.');
    end;

    [Test]
    procedure SchedulingAccessSkipsStaleOutgoingWithAvailableIncoming()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Scheduling access checking skips a stale outgoing reference when incoming remains available.

        // [GIVEN] A configured temporary setup has a missing no-reply account ID and a registered incoming account.
        InitConfiguredSetup(TempSetup);
        TempSetup."Noreply Email Account ID" := CreateGuid();
        TempPreviousSetup := TempSetup;
        Commit();


        // [WHEN] The scheduling mailbox access check runs.
        TempSetup.CheckSchedulingMailboxAccessOrError();


        // [THEN] Configuration remains unchanged and the incoming channel keeps the agent eligible.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsTrue(TempSetup.ShouldScheduleAgentTask(true), 'The registered incoming channel must remain usable.');
    end;

    [Test]
    procedure SchedulingAccessDoesNotProbeAccountsWithWrongConnector()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Scheduling access checking does not probe account IDs registered under another connector.

        // [GIVEN] Both saved channel identities use connector values that do not match their native mock registrations; retrieval is configured to fail if probed.
        InitConfiguredSetup(TempSetup);
        TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        TempSetup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        TempPreviousSetup := TempSetup;
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();


        // [WHEN] The scheduling mailbox access check runs.
        TempSetup.CheckSchedulingMailboxAccessOrError();


        // [THEN] Configuration remains unchanged and neither mismatched channel qualifies the agent for scheduling.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsFalse(TempSetup.ShouldScheduleAgentTask(true), 'Neither account is registered under its selected connector.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingIncomingAccountPreservesOutgoingSenderAndPreferences()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Deleting the registered incoming account preserves the outgoing channel and preferences.

        // [GIVEN] Persisted setup contains distinct registered incoming and no-reply accounts with enabled preferences.
        InitAccountDeletionSetup(TempSetup);
        TempPreviousSetup := TempSetup;


        // [WHEN] The native email-account API deletes the incoming account and setup is reloaded.
        DeleteTestEmailAccount(TempSetup."Email Account ID", TempSetup."Email Connector");
        ReloadAccountDeletionSetup(TempSetup);


        // [THEN] Only incoming identity and folder fields clear; outgoing identity, preferences, and outgoing readiness remain.
        AssertIncomingCleared(TempSetup);
        AssertNoreplyUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsTrue(TempSetup.IsOutgoingCommunicationConfigured(), 'The surviving registered sender must remain available.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingNoreplyAccountPreservesIncomingAndPreferences()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Deleting the registered no-reply account preserves the incoming channel and preferences.

        // [GIVEN] Persisted setup contains distinct registered incoming and no-reply accounts with enabled preferences.
        InitAccountDeletionSetup(TempSetup);
        TempPreviousSetup := TempSetup;


        // [WHEN] The native email-account API deletes the no-reply account and setup is reloaded.
        DeleteTestEmailAccount(TempSetup."Noreply Email Account ID", TempSetup."Noreply Email Connector");
        ReloadAccountDeletionSetup(TempSetup);


        // [THEN] Only no-reply identity clears; incoming identity, preferences, and incoming readiness remain.
        AssertNoreplyCleared(TempSetup);
        AssertIncomingUnchanged(TempPreviousSetup, TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsTrue(TempSetup.IsIncomingCommunicationConfigured(), 'The surviving registered incoming account must remain available.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingSharedAccountClearsBothChannelsWithoutChangingPreferences()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Deleting one registered account shared by both channels clears both identities without changing preferences.

        // [GIVEN] Persisted setup points incoming and no-reply identities to the same registered mock account.
        InitAccountDeletionSetup(TempSetup);
        TempSetup."Noreply Email Account ID" := TempSetup."Email Account ID";
        TempSetup."Noreply Email Connector" := TempSetup."Email Connector";
        TempSetup."Noreply Email Address" := TempSetup."Email Address";
        SaveAccountDeletionSetup(TempSetup);
        TempPreviousSetup := TempSetup;


        // [WHEN] The native email-account API deletes the shared account and setup is reloaded.
        DeleteTestEmailAccount(TempSetup."Email Account ID", TempSetup."Email Connector");
        ReloadAccountDeletionSetup(TempSetup);


        // [THEN] Both channel identities clear, preferences remain unchanged, and no channel remains schedulable.
        AssertIncomingCleared(TempSetup);
        AssertNoreplyCleared(TempSetup);
        AssertPreferencesUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsFalse(TempSetup.ShouldScheduleAgentTask(true), 'Deleting the shared account leaves no available channel.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingAccountWithMismatchedConnectorPreservesSelections()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
        RegisteredConnector: Enum "Email Connector";
    begin
        // [SCENARIO] Deleting an account registration under another connector does not clear saved mismatched selections.

        // [GIVEN] Persisted incoming and no-reply selections use a connector different from the account registration being deleted.
        InitAccountDeletionSetup(TempSetup);
        RegisteredConnector := TempSetup."Email Connector";
        TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        TempSetup."Noreply Email Account ID" := TempSetup."Email Account ID";
        TempSetup."Noreply Email Connector" := TempSetup."Email Connector";
        TempSetup."Noreply Email Address" := TempSetup."Email Address";
        SaveAccountDeletionSetup(TempSetup);
        TempPreviousSetup := TempSetup;


        // [WHEN] The native email-account API deletes the registered connector identity and setup is reloaded.
        DeleteTestEmailAccount(TempSetup."Email Account ID", RegisteredConnector);
        ReloadAccountDeletionSetup(TempSetup);


        // [THEN] Both saved channel selections and preferences remain unchanged.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingUnrelatedAccountPreservesBothChannels()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        // [SCENARIO] Deleting an unrelated registered account leaves both configured channels unchanged.

        // [GIVEN] Persisted setup contains two registered channels and the connector mock registers an additional unrelated account.
        InitAccountDeletionSetup(TempSetup);
        TempPreviousSetup := TempSetup;
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");


        // [WHEN] The native email-account API deletes the unrelated account and setup is reloaded.
        DeleteTestEmailAccount(TempEmailAccount."Account Id", TempEmailAccount.Connector);
        ReloadAccountDeletionSetup(TempSetup);


        // [THEN] Both configured channels, preferences, and channel readiness remain unchanged.
        AssertConfigurationUnchanged(TempPreviousSetup, TempSetup);
        Assert.IsTrue(TempSetup.IsIncomingCommunicationConfigured(), 'An unrelated deletion must not affect the incoming channel.');
        Assert.IsTrue(TempSetup.IsOutgoingCommunicationConfigured(), 'An unrelated deletion must not affect the outgoing channel.');
    end;

    local procedure InitAccountDeletionSetup(var TempSetup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        Assert.IsTrue(IsSafeTestCompany(), 'Account-deletion tests must run only in a dedicated disposable company.');
        PersistedSetup.ReadIsolation(IsolationLevel::UpdLock);
        if PersistedSetup.Get() then;
        ExpenseAgentStatus.ReadIsolation(IsolationLevel::UpdLock);
        if ExpenseAgentStatus.Get() then begin
            Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Task ID"), 'Account-deletion fixtures must not run with a dispatcher task ID.');
            Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID"), 'Account-deletion fixtures must not run with a recovery task ID.');
        end else begin
            ExpenseAgentStatus.Init();
            ExpenseAgentStatus.Insert();
        end;

        InitConfiguredSetup(TempSetup);
        SaveAccountDeletionSetup(TempSetup);
    end;

    local procedure SaveAccountDeletionSetup(TempSetup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
    begin
        PersistedSetup.ReadIsolation(IsolationLevel::UpdLock);
        if not PersistedSetup.Get() then
            PersistedSetup.Insert();
        PersistedSetup.TransferFields(TempSetup, false);
        PersistedSetup.Modify();
    end;

    local procedure DeleteTestEmailAccount(AccountId: Guid; Connector: Enum "Email Connector")
    var
        TempAccountsToDelete: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
    begin
        TempAccountsToDelete."Account Id" := AccountId;
        TempAccountsToDelete.Connector := Connector;
        TempAccountsToDelete.Insert();
        EmailAccount.DeleteAccounts(TempAccountsToDelete, true);
        Assert.IsFalse(EmailAccount.IsAccountRegistered(AccountId, Connector), 'The registered mock account must actually be deleted.');
    end;

    local procedure ReloadAccountDeletionSetup(var TempSetup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        PersistedSetup.Get();
        TempSetup := PersistedSetup;
        ExpenseAgentStatus.Get();
        Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Task ID"), 'Deletion must leave the dispatcher task ID empty.');
        Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID"), 'Deletion must leave the recovery task ID empty.');
    end;

    local procedure InitEmptySetup(var TempSetup: Record "Expense Agent Setup" temporary)
    begin
        TempSetup.DeleteAll();
        TempSetup.Init();
        TempSetup."Primary Key" := '';
        TempSetup.Insert();
    end;

    local procedure RegisterTestEmailAccount(var TempEmailAccount: Record "Email Account" temporary)
    begin
        Assert.IsTrue(IsSafeTestCompany(), 'Email lifecycle tests must run only in a dedicated disposable company.');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
    end;

    local procedure IsSafeTestCompany(): Boolean
    begin
        exit(CompanyName() in [IsolatedTestCompanyLbl, CIIsolatedTestCompanyLbl]);
    end;

    local procedure InitConfiguredSetup(var TempSetup: Record "Expense Agent Setup" temporary)
    var
        TempEmailAccount: Record "Email Account" temporary;
    begin
        InitEmptySetup(TempSetup);
        RegisterTestEmailAccount(TempEmailAccount);
        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        TempSetup."Email Address" := TempEmailAccount."Email Address";
        TempSetup."Email Folder" := 'Receipts';
        TempSetup."Email Folder Id" := 'old-folder-id';
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        TempSetup."Noreply Email Address" := TempEmailAccount."Email Address";
        TempSetup."Enable Agent" := true;
        TempSetup."User Security ID" := CreateGuid();
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Enable Communication" := true;
        TempSetup."Enable Open Report Notif." := true;
        TempSetup."Enable Approval Notif." := true;
        TempSetup."Open Report Notif. Freq." := TempSetup."Open Report Notif. Freq."::Weekly;
        TempSetup."Notif. Day of Week" := TempSetup."Notif. Day of Week"::Friday;
        TempSetup."Notif. Day In A Month" := 15;
        Evaluate(TempSetup."Custom Notif. Formula", '<2D>');
        Evaluate(TempSetup."Approval Reminder After", '<3D>');
        TempSetup.Modify();
    end;

    local procedure SelectIncomingAccount(TempSetup: Record "Expense Agent Setup" temporary)
    begin
        TempSelectedEmailAccount."Account Id" := TempSetup."Email Account ID";
        TempSelectedEmailAccount.Connector := TempSetup."Email Connector";
        TempSelectedEmailAccount."Email Address" := TempSetup."Email Address";
    end;

    local procedure AssertConfigurationUnchanged(ExpectedSetup: Record "Expense Agent Setup" temporary; ActualSetup: Record "Expense Agent Setup" temporary)
    begin
        AssertIncomingUnchanged(ExpectedSetup, ActualSetup);
        AssertNoreplyUnchanged(ExpectedSetup, ActualSetup);
        AssertPreferencesUnchanged(ExpectedSetup, ActualSetup);
    end;

    local procedure AssertIncomingUnchanged(ExpectedSetup: Record "Expense Agent Setup" temporary; ActualSetup: Record "Expense Agent Setup" temporary)
    begin
        Assert.AreEqual(ExpectedSetup."Email Account ID", ActualSetup."Email Account ID", 'The incoming account ID must be preserved.');
        Assert.AreEqual(ExpectedSetup."Email Connector", ActualSetup."Email Connector", 'The incoming connector must be preserved.');
        Assert.AreEqual(ExpectedSetup."Email Address", ActualSetup."Email Address", 'The incoming address must be preserved.');
        Assert.AreEqual(ExpectedSetup."Email Folder", ActualSetup."Email Folder", 'The incoming folder must be preserved.');
        Assert.AreEqual(ExpectedSetup."Email Folder Id", ActualSetup."Email Folder Id", 'The incoming folder ID must be preserved.');
    end;

    local procedure AssertNoreplyUnchanged(ExpectedSetup: Record "Expense Agent Setup" temporary; ActualSetup: Record "Expense Agent Setup" temporary)
    begin
        Assert.AreEqual(ExpectedSetup."Noreply Email Account ID", ActualSetup."Noreply Email Account ID", 'The no-reply account ID must be preserved.');
        Assert.AreEqual(ExpectedSetup."Noreply Email Connector", ActualSetup."Noreply Email Connector", 'The no-reply connector must be preserved.');
        Assert.AreEqual(ExpectedSetup."Noreply Email Address", ActualSetup."Noreply Email Address", 'The no-reply address must be preserved.');
    end;

    local procedure AssertPreferencesUnchanged(ExpectedSetup: Record "Expense Agent Setup" temporary; ActualSetup: Record "Expense Agent Setup" temporary)
    begin
        Assert.AreEqual(ExpectedSetup."Enable Email with Receipts", ActualSetup."Enable Email with Receipts", 'The receipts preference must be preserved.');
        Assert.AreEqual(ExpectedSetup."Enable Communication", ActualSetup."Enable Communication", 'The communication preference must be preserved.');
        Assert.AreEqual(ExpectedSetup."Enable Open Report Notif.", ActualSetup."Enable Open Report Notif.", 'The reminder preference must be preserved.');
        Assert.AreEqual(ExpectedSetup."Enable Approval Notif.", ActualSetup."Enable Approval Notif.", 'The approval notification preference must be preserved.');
        Assert.AreEqual(ExpectedSetup."Open Report Notif. Freq.", ActualSetup."Open Report Notif. Freq.", 'The reminder frequency must be preserved.');
        Assert.AreEqual(ExpectedSetup."Notif. Day of Week", ActualSetup."Notif. Day of Week", 'The reminder weekday must be preserved.');
        Assert.AreEqual(ExpectedSetup."Notif. Day In A Month", ActualSetup."Notif. Day In A Month", 'The reminder day must be preserved.');
        Assert.AreEqual(Format(ExpectedSetup."Custom Notif. Formula"), Format(ActualSetup."Custom Notif. Formula"), 'The custom reminder formula must be preserved.');
        Assert.AreEqual(Format(ExpectedSetup."Approval Reminder After"), Format(ActualSetup."Approval Reminder After"), 'The approval reminder formula must be preserved.');
        Assert.AreEqual(ExpectedSetup."Enable Agent", ActualSetup."Enable Agent", 'The native agent state must be preserved.');
        Assert.AreEqual(ExpectedSetup."User Security ID", ActualSetup."User Security ID", 'The native agent identity must be preserved.');
    end;

    local procedure AssertIncomingCleared(TempSetup: Record "Expense Agent Setup" temporary)
    var
        EmptyEmailConnector: Enum "Email Connector";
    begin
        Assert.IsTrue(IsNullGuid(TempSetup."Email Account ID"), 'The incoming account ID must be cleared.');
        Assert.AreEqual(EmptyEmailConnector, TempSetup."Email Connector", 'The incoming connector must be cleared.');
        Assert.AreEqual('', TempSetup."Email Address", 'The incoming address must be cleared.');
        Assert.AreEqual('', TempSetup."Email Folder", 'The incoming folder must be cleared.');
        Assert.AreEqual('', TempSetup."Email Folder Id", 'The incoming folder ID must be cleared.');
    end;

    local procedure AssertNoreplyCleared(TempSetup: Record "Expense Agent Setup" temporary)
    var
        EmptyEmailConnector: Enum "Email Connector";
    begin
        Assert.IsTrue(IsNullGuid(TempSetup."Noreply Email Account ID"), 'The no-reply account ID must be cleared.');
        Assert.AreEqual(EmptyEmailConnector, TempSetup."Noreply Email Connector", 'The no-reply connector must be cleared.');
        Assert.AreEqual('', TempSetup."Noreply Email Address", 'The no-reply address must be cleared.');
    end;

    [ModalPageHandler]
    procedure EmailAccountSelectionHandler(var EmailAccounts: TestPage "Email Accounts")
    begin
        Assert.IsTrue(EmailAccounts.GoToRecord(TempSelectedEmailAccount), 'The selected mock account must be listed.');
        EmailAccounts.OK().Invoke();
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
