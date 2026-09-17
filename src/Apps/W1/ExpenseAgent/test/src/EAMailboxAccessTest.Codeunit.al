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
        SelectedEmailAccount: Record "Email Account" temporary;
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";
        IsolatedTestCompanyLbl: Label 'EA Email Lifecycle Test', Locked = true;

    [Test]
    procedure ValidateMailboxAccessTrueWhenNoEmailAccountsAreConfigured()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        InitEmptySetup(Setup);

        Assert.IsTrue(Setup.ValidateIncomingMailboxAccess(), 'Expected true when no incoming account is configured.');
        Assert.IsTrue(Setup.ValidateNoreplyMailboxAccess(), 'Expected true when no noreply account is configured.');
    end;

    [Test]
    procedure CheckMailboxAccessOrErrorIsNoOpWhenNoEmailAccountsAreConfigured()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        InitEmptySetup(Setup);

        Setup.CheckMailboxAccessOrError();
        Assert.IsTrue(IsNullGuid(Setup."Email Account ID"), 'Email Account ID should still be empty.');
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'Noreply Email Account ID should still be empty.');
    end;

    [Test]
    procedure ValidateAccessFalseWhenRetrieveEmailsFails()
    var
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // No mailbox -> warning skipped, deactivation proceeds.
        InitEmptySetup(Setup);
        Assert.IsTrue(Setup.ShowDeactivationAccessWarning(), 'Expected proceed when no mailbox is configured.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeactivationWarningProceedsWhenUserConfirms()
    var
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
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
        Assert.ExpectedError('incoming receipts because the connection failed');
    end;

    [Test]
    procedure SchedulingAccessCheckErrorsWhenCommunicationOnAndNoreplyInaccessible()
    var
        Setup: Record "Expense Agent Setup" temporary;
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
        Assert.ExpectedError('outgoing notifications because the connection failed');
    end;

    [Test]
    procedure SchedulingAccessCheckSkipsIncomingWhenReceiptsOff()
    var
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
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
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Cancelling the no-reply account lookup and confirming the prompt clears
        // the no-reply mailbox so the agent stops sending until a new account is chosen.
        // [GIVEN] A configured no-reply account (an account exists, so the wizard is skipped).
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the no-reply account.
        Setup.AssistEditNoreplyMailbox();

        // [THEN] The no-reply account fields are cleared.
        Setup.Get();
        AssertNoreplyCleared(Setup);
        AssertIncomingUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure AssistEditMailboxClearsAccountWhenLookupCancelledAndConfirmed()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Cancelling the incoming (receipts) account lookup and confirming the
        // prompt clears the mailbox so the agent stops processing receipts until a new account is chosen.
        // [GIVEN] A configured incoming mailbox (an account exists, so the wizard is skipped).
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        Commit();

        // [WHEN] The user cancels the account lookup and confirms clearing the mailbox account.
        Setup.AssistEditMailbox();

        // [THEN] The incoming mailbox fields are cleared.
        Setup.Get();
        AssertIncomingCleared(Setup);
        AssertNoreplyUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmNoHandler')]
    procedure DecliningIncomingClearPreservesConfiguration()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        Commit();

        Setup.AssistEditMailbox();

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmNoHandler')]
    procedure DecliningNoreplyClearPreservesConfiguration()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        Commit();

        Setup.AssistEditNoreplyMailbox();

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure IncomingClearOnlyChangesIdentityInRecordBuffer()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;

        Setup.ClearIncomingMailbox();

        AssertIncomingCleared(Setup);
        AssertNoreplyUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure NoreplyClearOnlyChangesIdentityInRecordBuffer()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;

        Setup.ClearNoreplyMailbox();

        AssertNoreplyCleared(Setup);
        AssertIncomingUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure ExplicitCommunicationDisableStillClearsNotificationPreferences()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;

        Setup.Validate("Enable Communication", false);

        Assert.IsFalse(Setup."Enable Communication", 'The explicit communication preference must be off.');
        Assert.IsFalse(Setup."Enable Open Report Notif.", 'Explicitly disabling communication must still disable reminders.');
        Assert.IsFalse(Setup."Enable Approval Notif.", 'Explicitly disabling communication must still disable approval notifications.');
        Assert.IsTrue(Setup."Enable Email with Receipts", 'Disabling outgoing communication must not disable receipts.');
        Assert.AreEqual(PreviousSetup."Enable Agent", Setup."Enable Agent", 'The native agent state must not change.');
        AssertIncomingUnchanged(PreviousSetup, Setup);
        AssertNoreplyUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure SameAddressIncomingReplacementClearsOldFolders()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
        TestEmailAccount: Record "Test Email Account";
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        ConnectorMock.AddAccount(SelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TestEmailAccount.Get(SelectedEmailAccount."Account Id");
        TestEmailAccount.Email := Setup."Email Address";
        TestEmailAccount.Modify();
        SelectedEmailAccount."Email Address" := Setup."Email Address";
        Commit();

        Setup.AssistEditMailbox();

        Setup.Get();
        Assert.AreEqual(SelectedEmailAccount."Account Id", Setup."Email Account ID", 'The incoming identity must change even if the address is unchanged.');
        Assert.AreEqual(PreviousSetup."Email Address", Setup."Email Address", 'The replacement intentionally uses the same address.');
        Assert.AreEqual('', Setup."Email Folder", 'The previous account folder must be cleared.');
        Assert.AreEqual('', Setup."Email Folder Id", 'The previous account folder ID must be cleared.');
        AssertNoreplyUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure IncomingConnectorReplacementClearsOldFolders()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        SelectIncomingAccount(Setup);
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        PreviousSetup := Setup;
        Commit();

        Setup.AssistEditMailbox();

        Setup.Get();
        Assert.AreEqual(PreviousSetup."Email Account ID", Setup."Email Account ID", 'Only the connector identity changes.');
        Assert.AreEqual(SelectedEmailAccount.Connector, Setup."Email Connector", 'The selected connector must replace the stale connector.');
        Assert.AreEqual('', Setup."Email Folder", 'Changing the connector must clear the folder.');
        Assert.AreEqual('', Setup."Email Folder Id", 'Changing the connector must clear the folder ID.');
        AssertNoreplyUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure ReselectingIncomingPreservesFoldersAndDefaultsEmptyNoreply()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        Setup.ClearNoreplyMailbox();
        SelectIncomingAccount(Setup);
        PreviousSetup := Setup;
        Commit();

        Setup.AssistEditMailbox();

        Setup.Get();
        AssertIncomingUnchanged(PreviousSetup, Setup);
        Assert.AreEqual(Setup."Email Account ID", Setup."Noreply Email Account ID", 'Reselecting the same incoming account must still default an empty no-reply account.');
        Assert.AreEqual(Setup."Email Connector", Setup."Noreply Email Connector", 'The defaulted no-reply connector must match.');
        Assert.AreEqual(Setup."Email Address", Setup."Noreply Email Address", 'The defaulted no-reply address must match.');
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure InaccessibleIncomingReplacementPreservesPreviousConfiguration()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        ConnectorMock.AddAccount(SelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();

        asserterror Setup.AssistEditMailbox();

        Assert.ExpectedError('incoming receipts because the connection failed');
        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountSelectionHandler')]
    procedure InaccessibleNoreplyReplacementPreservesPreviousConfiguration()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        ConnectorMock.AddAccount(SelectedEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();

        asserterror Setup.AssistEditNoreplyMailbox();

        Assert.ExpectedError('outgoing notifications because the connection failed');
        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure MissingAccountRepairPreservesPreferencesAndOtherChannel()
    var
        Setup: Record "Expense Agent Setup" temporary;
        RegisteredSetup: Record "Expense Agent Setup" temporary;
        MissingChannels: Integer;
    begin
        InitConfiguredSetup(RegisteredSetup);
        for MissingChannels := 1 to 3 do begin
            Setup := RegisteredSetup;
            if MissingChannels in [1, 3] then
                Setup."Email Account ID" := CreateGuid();
            if MissingChannels in [2, 3] then
                Setup."Noreply Email Account ID" := CreateGuid();

            Assert.IsTrue(Setup.RepairMissingEmailAccounts(), 'Missing references must be repaired.');

            if MissingChannels in [1, 3] then
                AssertIncomingCleared(Setup)
            else
                AssertIncomingUnchanged(RegisteredSetup, Setup);
            if MissingChannels in [2, 3] then
                AssertNoreplyCleared(Setup)
            else
                AssertNoreplyUnchanged(RegisteredSetup, Setup);
            AssertPreferencesUnchanged(RegisteredSetup, Setup);
            Assert.IsFalse(Setup.RepairMissingEmailAccounts(), 'Repeated repair must be a no-op.');
        end;
    end;

    [Test]
    procedure WrongConnectorAndEmptyIdentityRepairClearsOrphanedFields()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";

        Assert.IsTrue(Setup.RepairMissingEmailAccounts(), 'The ID must be registered under the selected connector.');
        AssertIncomingCleared(Setup);
        AssertNoreplyCleared(Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);

        Setup := PreviousSetup;
        Clear(Setup."Email Account ID");
        Clear(Setup."Noreply Email Account ID");
        Assert.IsTrue(Setup.RepairMissingEmailAccounts(), 'Empty IDs must not retain orphaned addresses, connectors or folders.');
        AssertIncomingCleared(Setup);
        AssertNoreplyCleared(Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure StagedRepairCanBeDiscardedWithoutChangingOriginalSetup()
    var
        Setup: Record "Expense Agent Setup" temporary;
        StagedSetup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        Setup."Email Account ID" := CreateGuid();
        Setup."Noreply Email Account ID" := CreateGuid();
        Setup.Modify();
        PreviousSetup := Setup;
        StagedSetup := Setup;
        StagedSetup.Insert();

        Assert.IsTrue(StagedSetup.RepairMissingEmailAccounts(), 'Opening a temporary wizard buffer must stage missing-account repair.');
        AssertIncomingCleared(StagedSetup);
        AssertNoreplyCleared(StagedSetup);
        AssertPreferencesUnchanged(PreviousSetup, StagedSetup);
        StagedSetup.Get();
        AssertConfigurationUnchanged(PreviousSetup, StagedSetup);
        StagedSetup.RepairMissingEmailAccounts();
        StagedSetup.Modify();
        StagedSetup.DeleteAll();

        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [HandlerFunctions('EmailAccountsCancelHandler,ConfirmYesHandler')]
    procedure DiscardingStagedIncomingClearPreservesOriginalSetup()
    var
        Setup: Record "Expense Agent Setup" temporary;
        StagedSetup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;
        StagedSetup := Setup;
        StagedSetup.Insert();
        Commit();

        StagedSetup.AssistEditMailbox();
        StagedSetup.Get();
        AssertIncomingCleared(StagedSetup);
        AssertPreferencesUnchanged(PreviousSetup, StagedSetup);
        StagedSetup.DeleteAll();

        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure TemporaryDisableOnlyChangesAgentStateInBuffer()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        PreviousSetup := Setup;

        Setup.Validate("Enable Agent", false);

        Assert.IsFalse(Setup."Enable Agent", 'The pending disable must be staged.');
        Setup.Get();
        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    procedure SchedulingAccessSkipsStaleIncomingWithAvailableOutgoing()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        Setup."Email Account ID" := CreateGuid();
        PreviousSetup := Setup;
        Commit();

        Setup.CheckSchedulingMailboxAccessOrError();

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'The registered outgoing channel must remain usable.');
    end;

    [Test]
    procedure SchedulingAccessSkipsStaleOutgoingWithAvailableIncoming()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        Setup."Noreply Email Account ID" := CreateGuid();
        PreviousSetup := Setup;
        Commit();

        Setup.CheckSchedulingMailboxAccessOrError();

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'The registered incoming channel must remain usable.');
    end;

    [Test]
    procedure SchedulingAccessDoesNotProbeAccountsWithWrongConnector()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitConfiguredSetup(Setup);
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        PreviousSetup := Setup;
        ConnectorMock.FailOnRetrieveEmails(true);
        Commit();

        Setup.CheckSchedulingMailboxAccessOrError();

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Neither account is registered under its selected connector.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingIncomingAccountPreservesOutgoingSenderAndPreferences()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitAccountDeletionSetup(Setup);
        PreviousSetup := Setup;

        DeleteTestEmailAccount(Setup."Email Account ID", Setup."Email Connector");
        ReloadAccountDeletionSetup(Setup);

        AssertIncomingCleared(Setup);
        AssertNoreplyUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
        Assert.IsTrue(Setup.IsOutgoingCommunicationConfigured(), 'The surviving registered sender must remain available.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingNoreplyAccountPreservesIncomingAndPreferences()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitAccountDeletionSetup(Setup);
        PreviousSetup := Setup;

        DeleteTestEmailAccount(Setup."Noreply Email Account ID", Setup."Noreply Email Connector");
        ReloadAccountDeletionSetup(Setup);

        AssertNoreplyCleared(Setup);
        AssertIncomingUnchanged(PreviousSetup, Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
        Assert.IsTrue(Setup.IsIncomingCommunicationConfigured(), 'The surviving registered incoming account must remain available.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingSharedAccountClearsBothChannelsWithoutChangingPreferences()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        InitAccountDeletionSetup(Setup);
        Setup."Noreply Email Account ID" := Setup."Email Account ID";
        Setup."Noreply Email Connector" := Setup."Email Connector";
        Setup."Noreply Email Address" := Setup."Email Address";
        SaveAccountDeletionSetup(Setup);
        PreviousSetup := Setup;

        DeleteTestEmailAccount(Setup."Email Account ID", Setup."Email Connector");
        ReloadAccountDeletionSetup(Setup);

        AssertIncomingCleared(Setup);
        AssertNoreplyCleared(Setup);
        AssertPreferencesUnchanged(PreviousSetup, Setup);
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Deleting the shared account leaves no available channel.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingAccountWithMismatchedConnectorPreservesSelections()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
        RegisteredConnector: Enum "Email Connector";
    begin
        InitAccountDeletionSetup(Setup);
        RegisteredConnector := Setup."Email Connector";
        Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        Setup."Noreply Email Account ID" := Setup."Email Account ID";
        Setup."Noreply Email Connector" := Setup."Email Connector";
        Setup."Noreply Email Address" := Setup."Email Address";
        SaveAccountDeletionSetup(Setup);
        PreviousSetup := Setup;

        DeleteTestEmailAccount(Setup."Email Account ID", RegisteredConnector);
        ReloadAccountDeletionSetup(Setup);

        AssertConfigurationUnchanged(PreviousSetup, Setup);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DeletingUnrelatedAccountPreservesBothChannels()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
        TempEmailAccount: Record "Email Account" temporary;
    begin
        InitAccountDeletionSetup(Setup);
        PreviousSetup := Setup;
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");

        DeleteTestEmailAccount(TempEmailAccount."Account Id", TempEmailAccount.Connector);
        ReloadAccountDeletionSetup(Setup);

        AssertConfigurationUnchanged(PreviousSetup, Setup);
        Assert.IsTrue(Setup.IsIncomingCommunicationConfigured(), 'An unrelated deletion must not affect the incoming channel.');
        Assert.IsTrue(Setup.IsOutgoingCommunicationConfigured(), 'An unrelated deletion must not affect the outgoing channel.');
    end;

    local procedure InitAccountDeletionSetup(var Setup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        Assert.AreEqual(IsolatedTestCompanyLbl, CompanyName(), 'Account-deletion tests must run only in their isolated test company.');
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

        InitConfiguredSetup(Setup);
        SaveAccountDeletionSetup(Setup);
    end;

    local procedure SaveAccountDeletionSetup(Setup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
    begin
        PersistedSetup.ReadIsolation(IsolationLevel::UpdLock);
        if not PersistedSetup.Get() then
            PersistedSetup.Insert();
        PersistedSetup.TransferFields(Setup, false);
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

    local procedure ReloadAccountDeletionSetup(var Setup: Record "Expense Agent Setup" temporary)
    var
        PersistedSetup: Record "Expense Agent Setup";
        ExpenseAgentStatus: Record "Expense Agent Status";
    begin
        PersistedSetup.Get();
        Setup := PersistedSetup;
        ExpenseAgentStatus.Get();
        Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Task ID"), 'Deletion must leave the dispatcher task ID empty.');
        Assert.IsTrue(IsNullGuid(ExpenseAgentStatus."Agent Recovery Task ID"), 'Deletion must leave the recovery task ID empty.');
    end;

    local procedure InitEmptySetup(var Setup: Record "Expense Agent Setup" temporary)
    begin
        Setup.DeleteAll();
        Setup.Init();
        Setup."Primary Key" := '';
        Setup.Insert();
    end;

    local procedure RegisterTestEmailAccount(var TempEmailAccount: Record "Email Account" temporary)
    begin
        Assert.AreEqual(IsolatedTestCompanyLbl, CompanyName(), 'Email lifecycle tests must run only in their isolated test company.');
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
    end;

    local procedure InitConfiguredSetup(var Setup: Record "Expense Agent Setup" temporary)
    var
        TempEmailAccount: Record "Email Account" temporary;
    begin
        InitEmptySetup(Setup);
        RegisterTestEmailAccount(TempEmailAccount);
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Email Address" := TempEmailAccount."Email Address";
        Setup."Email Folder" := 'Receipts';
        Setup."Email Folder Id" := 'old-folder-id';
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Setup."Noreply Email Address" := TempEmailAccount."Email Address";
        Setup."Enable Agent" := true;
        Setup."User Security ID" := CreateGuid();
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := true;
        Setup."Enable Open Report Notif." := true;
        Setup."Enable Approval Notif." := true;
        Setup."Open Report Notif. Freq." := Setup."Open Report Notif. Freq."::Weekly;
        Setup."Notif. Day of Week" := Setup."Notif. Day of Week"::Friday;
        Setup."Notif. Day In A Month" := 15;
        Evaluate(Setup."Custom Notif. Formula", '<2D>');
        Evaluate(Setup."Approval Reminder After", '<3D>');
        Setup.Modify();
    end;

    local procedure SelectIncomingAccount(Setup: Record "Expense Agent Setup" temporary)
    begin
        SelectedEmailAccount."Account Id" := Setup."Email Account ID";
        SelectedEmailAccount.Connector := Setup."Email Connector";
        SelectedEmailAccount."Email Address" := Setup."Email Address";
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

    local procedure AssertIncomingCleared(Setup: Record "Expense Agent Setup" temporary)
    var
        EmptyEmailConnector: Enum "Email Connector";
    begin
        Assert.IsTrue(IsNullGuid(Setup."Email Account ID"), 'The incoming account ID must be cleared.');
        Assert.AreEqual(EmptyEmailConnector, Setup."Email Connector", 'The incoming connector must be cleared.');
        Assert.AreEqual('', Setup."Email Address", 'The incoming address must be cleared.');
        Assert.AreEqual('', Setup."Email Folder", 'The incoming folder must be cleared.');
        Assert.AreEqual('', Setup."Email Folder Id", 'The incoming folder ID must be cleared.');
    end;

    local procedure AssertNoreplyCleared(Setup: Record "Expense Agent Setup" temporary)
    var
        EmptyEmailConnector: Enum "Email Connector";
    begin
        Assert.IsTrue(IsNullGuid(Setup."Noreply Email Account ID"), 'The no-reply account ID must be cleared.');
        Assert.AreEqual(EmptyEmailConnector, Setup."Noreply Email Connector", 'The no-reply connector must be cleared.');
        Assert.AreEqual('', Setup."Noreply Email Address", 'The no-reply address must be cleared.');
    end;

    [ModalPageHandler]
    procedure EmailAccountSelectionHandler(var EmailAccounts: TestPage "Email Accounts")
    begin
        Assert.IsTrue(EmailAccounts.GoToRecord(SelectedEmailAccount), 'The selected mock account must be listed.');
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
