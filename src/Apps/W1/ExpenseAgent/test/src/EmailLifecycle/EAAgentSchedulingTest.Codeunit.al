// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.Email;
using System.TestLibraries.Email;

codeunit 148335 "EA Agent Scheduling Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ConnectorMock: Codeunit "Connector Mock";
        IsolatedTestCompanyLbl: Label 'EA Email Lifecycle Test', Locked = true;

    [Test]
    procedure DisabledAgentIsNeverScheduled()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] The task is never scheduled when the agent is disabled, even if everything else is configured.
        // [GIVEN] Receipts on with a mailbox and communication on with a noreply account.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := true;

        // [THEN] Passing AgentEnabled = false never schedules.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(false), 'Disabled agent must not be scheduled.');
    end;

    [Test]
    procedure ReceiptsOnWithMailboxSchedules()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Inbound receipt processing schedules the task when a mailbox is configured.
        // [GIVEN] Enabled agent, receipts on with a mailbox, communication off.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := false;

        // [THEN] Scheduled.
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Receipts on with a mailbox should schedule.');
    end;

    [Test]
    procedure ReceiptsOnWithoutMailboxDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Receipts on but no mailbox does not schedule (nothing usable to do).
        // [GIVEN] Enabled agent, receipts on, no email account, communication off.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Clear(Setup."Email Account ID");
        Setup."Enable Communication" := false;

        // [THEN] Not scheduled.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Receipts on without a mailbox must not schedule.');
    end;

    [Test]
    procedure CommunicationOnWithNoreplySchedulesWhenReceiptsOff()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Outbound communication keeps the task alive even when receipts are off.
        // [GIVEN] Enabled agent, receipts off, communication on with a noreply account.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;

        // [THEN] Scheduled (the welcome/outbox path needs the task).
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Communication on with a noreply account should schedule.');
    end;

    [Test]
    procedure CommunicationOnWithoutNoreplyDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Outbound communication requires a dedicated noreply account; the main mailbox is not used as a fallback.
        // [GIVEN] Enabled agent, receipts off, communication on, only the main email account set (no noreply).
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");

        // [THEN] Not scheduled — a noreply account is required for outbound communication.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Communication requires a noreply account; the main account is not a fallback.');
    end;

    [Test]
    procedure CommunicationOnWithoutAnyAccountDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Communication on but no sender account does not schedule.
        // [GIVEN] Enabled agent, receipts off, communication on, no accounts.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");
        Clear(Setup."Email Account ID");

        // [THEN] Not scheduled.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Communication on without any account must not schedule.');
    end;

    [Test]
    procedure ReceiptsAndCommunicationOffDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] With both receipts and communication off, the task is stopped even if accounts exist.
        // [GIVEN] Enabled agent, both toggles off, but accounts configured.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := false;

        // [THEN] Not scheduled (no idle background task).
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Both toggles off must not schedule.');
    end;

    [Test]
    procedure ReceiptsWithoutMailboxButCommunicationOnStillSchedules()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Regression: turning off the inbound mailbox no longer stops the scheduler when communication is on.
        // [GIVEN] Enabled agent, receipts on but no mailbox, communication on with a noreply account.
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Clear(Setup."Email Account ID");
        Setup."Enable Communication" := true;

        // [THEN] Still scheduled via the outbound path.
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Communication must keep the scheduler alive without the inbound mailbox.');
    end;

    [Test]
    procedure OutgoingCommunicationConfiguredRequiresToggleAndNoreplyAccount()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Outgoing communication is only configured when the master toggle is on
        // and a no-reply account is registered; the no-reply account alone is not enough and there is no
        // fallback to the inbound mailbox.
        InitializeSetup(Setup);

        // [GIVEN] Communication on with a no-reply account. [THEN] Configured.
        Setup."Enable Communication" := true;
        Assert.IsTrue(Setup.IsOutgoingCommunicationConfigured(), 'Communication on with a noreply account is configured.');

        // [GIVEN] Communication off (account still set). [THEN] Not configured.
        Setup."Enable Communication" := false;
        Assert.IsFalse(Setup.IsOutgoingCommunicationConfigured(), 'Communication off must not be configured, even with an account.');

        // [GIVEN] Communication on but no no-reply account. [THEN] Not configured.
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");
        Assert.IsFalse(Setup.IsOutgoingCommunicationConfigured(), 'Communication on without a noreply account must not be configured.');
    end;

    [Test]
    procedure RegisteredChannelAvailabilityMatrix()
    var
        Setup: Record "Expense Agent Setup" temporary;
        RegisteredSetup: Record "Expense Agent Setup" temporary;
        IncomingState: Integer;
        OutgoingState: Integer;
        ReceiptsPreference: Integer;
        CommunicationPreference: Integer;
        IncomingAvailable: Boolean;
        OutgoingAvailable: Boolean;
    begin
        InitializeSetup(RegisteredSetup);

        // Each channel is empty, stale, registered under another connector, or registered.
        for IncomingState := 0 to 3 do
            for OutgoingState := 0 to 3 do
                for ReceiptsPreference := 0 to 1 do
                    for CommunicationPreference := 0 to 1 do begin
                        Setup := RegisteredSetup;
                        Setup."Enable Email with Receipts" := ReceiptsPreference = 1;
                        Setup."Enable Communication" := CommunicationPreference = 1;
                        SetIncomingAccountState(Setup, IncomingState);
                        SetOutgoingAccountState(Setup, OutgoingState);
                        IncomingAvailable := (ReceiptsPreference = 1) and (IncomingState = 3);
                        OutgoingAvailable := (CommunicationPreference = 1) and (OutgoingState = 3);

                        Assert.AreEqual(IncomingAvailable, Setup.IsIncomingCommunicationConfigured(), 'Incoming availability must use preference, ID and connector registration.');
                        Assert.AreEqual(OutgoingAvailable, Setup.IsOutgoingCommunicationConfigured(), 'Outgoing availability must use preference, ID and connector registration.');
                        Assert.AreEqual(IncomingAvailable or OutgoingAvailable, Setup.ShouldScheduleAgentTask(true), 'An enabled agent requires at least one available channel.');
                        Assert.IsFalse(Setup.ShouldScheduleAgentTask(false), 'No channel may schedule a disabled agent.');
                    end;
    end;

    [Test]
    procedure RegisteredButInaccessibleAccountsRemainConfigured()
    var
        Setup: Record "Expense Agent Setup" temporary;
    begin
        InitializeSetup(Setup);
        Setup."Enable Email with Receipts" := true;
        Setup."Enable Communication" := true;
        ConnectorMock.FailOnRetrieveEmails(true);

        Assert.IsTrue(Setup.IsIncomingCommunicationConfigured(), 'Mailbox access failure must not be treated as deleted incoming configuration.');
        Assert.IsTrue(Setup.IsOutgoingCommunicationConfigured(), 'Mailbox access failure must not be treated as deleted outgoing configuration.');
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Availability must use local registration, not a live mailbox probe.');
        Assert.IsFalse(Setup.RepairMissingEmailAccounts(), 'Registered but inaccessible accounts must not be cleared.');
    end;

    [Test]
    procedure SchedulingChangesDetectEveryEligibilityInputInBothDirections()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
        ChangedInput: Integer;
    begin
        PreviousSetup.Init();
        PreviousSetup."Email Address" := 'receipts@example.invalid';
        PreviousSetup."Noreply Email Address" := 'noreply@example.invalid';
        Assert.IsFalse(PreviousSetup.HasSchedulingChanges(PreviousSetup), 'Unchanged setup must not trigger reconciliation.');

        for ChangedInput := 1 to 7 do begin
            Setup := PreviousSetup;
            case ChangedInput of
                1:
                    Setup."Enable Agent" := not Setup."Enable Agent";
                2:
                    Setup."Enable Email with Receipts" := not Setup."Enable Email with Receipts";
                3:
                    Setup."Enable Communication" := not Setup."Enable Communication";
                4:
                    Setup."Email Account ID" := CreateGuid();
                5:
                    Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
                6:
                    Setup."Noreply Email Account ID" := CreateGuid();
                7:
                    Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
            end;

            Assert.IsTrue(Setup.HasSchedulingChanges(PreviousSetup), 'Changing any eligibility input must require reconciliation even when the address stays the same.');
            Assert.IsTrue(PreviousSetup.HasSchedulingChanges(Setup), 'Reversing a change must also require reconciliation.');
        end;
    end;

    [Test]
    procedure OtherSetupChangesDoNotRequireSchedulingReconciliation()
    var
        Setup: Record "Expense Agent Setup" temporary;
        PreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        PreviousSetup.Init();
        Setup := PreviousSetup;
        Setup."Email Address" := 'receipts@example.invalid';
        Setup."Noreply Email Address" := 'noreply@example.invalid';
        Setup."Email Folder" := 'Receipts';
        Setup."Email Folder Id" := 'folder-id';
        Setup."Enable Open Report Notif." := not Setup."Enable Open Report Notif.";
        Setup."Enable Approval Notif." := not Setup."Enable Approval Notif.";
        Setup."Use Rules" := not Setup."Use Rules";
        Setup."No. Series Applied" := not Setup."No. Series Applied";

        Assert.IsFalse(Setup.HasSchedulingChanges(PreviousSetup), 'Display values, notification preferences and accounting defaults do not change channel eligibility.');
    end;

    local procedure InitializeSetup(var Setup: Record "Expense Agent Setup" temporary)
    var
        TempEmailAccount: Record "Email Account" temporary;
    begin
        Assert.AreEqual(IsolatedTestCompanyLbl, CompanyName(), 'Email lifecycle tests must run only in their isolated test company.');
        ConnectorMock.Initialize();
        Setup.Init();
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        Setup."Email Account ID" := TempEmailAccount."Account Id";
        Setup."Email Connector" := TempEmailAccount.Connector;
        Setup."Email Address" := TempEmailAccount."Email Address";
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        Setup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        Setup."Noreply Email Connector" := TempEmailAccount.Connector;
        Setup."Noreply Email Address" := TempEmailAccount."Email Address";
    end;

    local procedure SetIncomingAccountState(var Setup: Record "Expense Agent Setup" temporary; AccountState: Integer)
    begin
        case AccountState of
            0:
                Setup.ClearIncomingMailbox();
            1:
                Setup."Email Account ID" := CreateGuid();
            2:
                Setup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        end;
    end;

    local procedure SetOutgoingAccountState(var Setup: Record "Expense Agent Setup" temporary; AccountState: Integer)
    begin
        case AccountState of
            0:
                Setup.ClearNoreplyMailbox();
            1:
                Setup."Noreply Email Account ID" := CreateGuid();
            2:
                Setup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        end;
    end;
}
