// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148335 "EA Agent Scheduling Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure DisabledAgentIsNeverScheduled()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] The task is never scheduled when the agent is disabled, even if everything else is configured.
        // [GIVEN] Receipts on with a mailbox and communication on with a noreply account.
        Setup.Init();
        Setup."Enable Email with Receipts" := true;
        Setup."Email Account ID" := CreateGuid();
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := CreateGuid();

        // [THEN] Passing AgentEnabled = false never schedules.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(false), 'Disabled agent must not be scheduled.');
    end;

    [Test]
    procedure ReceiptsOnWithMailboxSchedules()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Inbound receipt processing schedules the task when a mailbox is configured.
        // [GIVEN] Enabled agent, receipts on with a mailbox, communication off.
        Setup.Init();
        Setup."Enable Email with Receipts" := true;
        Setup."Email Account ID" := CreateGuid();
        Setup."Enable Communication" := false;

        // [THEN] Scheduled.
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Receipts on with a mailbox should schedule.');
    end;

    [Test]
    procedure ReceiptsOnWithoutMailboxDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Receipts on but no mailbox does not schedule (nothing usable to do).
        // [GIVEN] Enabled agent, receipts on, no email account, communication off.
        Setup.Init();
        Setup."Enable Email with Receipts" := true;
        Clear(Setup."Email Account ID");
        Setup."Enable Communication" := false;

        // [THEN] Not scheduled.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Receipts on without a mailbox must not schedule.');
    end;

    [Test]
    procedure CommunicationOnWithNoreplySchedulesWhenReceiptsOff()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Outbound communication keeps the task alive even when receipts are off.
        // [GIVEN] Enabled agent, receipts off, communication on with a noreply account.
        Setup.Init();
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := CreateGuid();

        // [THEN] Scheduled (the welcome/outbox path needs the task).
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Communication on with a noreply account should schedule.');
    end;

    [Test]
    procedure CommunicationOnWithoutNoreplyDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Outbound communication requires a dedicated noreply account; the main mailbox is not used as a fallback.
        // [GIVEN] Enabled agent, receipts off, communication on, only the main email account set (no noreply).
        Setup.Init();
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");
        Setup."Email Account ID" := CreateGuid();

        // [THEN] Not scheduled — a noreply account is required for outbound communication.
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Communication requires a noreply account; the main account is not a fallback.');
    end;

    [Test]
    procedure CommunicationOnWithoutAnyAccountDoesNotSchedule()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Communication on but no sender account does not schedule.
        // [GIVEN] Enabled agent, receipts off, communication on, no accounts.
        Setup.Init();
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
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] With both receipts and communication off, the task is stopped even if accounts exist.
        // [GIVEN] Enabled agent, both toggles off, but accounts configured.
        Setup.Init();
        Setup."Enable Email with Receipts" := false;
        Setup."Enable Communication" := false;
        Setup."Email Account ID" := CreateGuid();
        Setup."Noreply Email Account ID" := CreateGuid();

        // [THEN] Not scheduled (no idle background task).
        Assert.IsFalse(Setup.ShouldScheduleAgentTask(true), 'Both toggles off must not schedule.');
    end;

    [Test]
    procedure ReceiptsWithoutMailboxButCommunicationOnStillSchedules()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Regression: turning off the inbound mailbox no longer stops the scheduler when communication is on.
        // [GIVEN] Enabled agent, receipts on but no mailbox, communication on with a noreply account.
        Setup.Init();
        Setup."Enable Email with Receipts" := true;
        Clear(Setup."Email Account ID");
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := CreateGuid();

        // [THEN] Still scheduled via the outbound path.
        Assert.IsTrue(Setup.ShouldScheduleAgentTask(true), 'Communication must keep the scheduler alive without the inbound mailbox.');
    end;

    [Test]
    procedure OutgoingCommunicationConfiguredRequiresToggleAndNoreplyAccount()
    var
        Setup: Record "Expense Agent Setup";
    begin
        // [SCENARIO 636970] Outgoing communication is only configured when the master toggle is on
        // and a no-reply account is set; the no-reply account alone is not enough and there is no
        // fallback to the inbound mailbox.
        Setup.Init();

        // [GIVEN] Communication on with a no-reply account. [THEN] Configured.
        Setup."Enable Communication" := true;
        Setup."Noreply Email Account ID" := CreateGuid();
        Assert.IsTrue(Setup.IsOutgoingCommunicationConfigured(), 'Communication on with a noreply account is configured.');

        // [GIVEN] Communication off (account still set). [THEN] Not configured.
        Setup."Enable Communication" := false;
        Assert.IsFalse(Setup.IsOutgoingCommunicationConfigured(), 'Communication off must not be configured, even with an account.');

        // [GIVEN] Communication on but no no-reply account. [THEN] Not configured.
        Setup."Enable Communication" := true;
        Clear(Setup."Noreply Email Account ID");
        Assert.IsFalse(Setup.IsOutgoingCommunicationConfigured(), 'Communication on without a noreply account must not be configured.');
    end;
}
