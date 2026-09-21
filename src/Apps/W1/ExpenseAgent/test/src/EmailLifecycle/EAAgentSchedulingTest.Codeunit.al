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
        CIIsolatedTestCompanyLbl: Label 'Empty Company', Locked = true;
        CombinationMsg: Label 'Incoming state %1, outgoing state %2, receipts preference %3, communication preference %4.', Comment = '%1 = incoming account state, %2 = outgoing account state, %3 = receipts preference, %4 = communication preference';
        ChangeInputMsg: Label 'Changing eligibility input %1 must require reconciliation even when the address stays the same.', Comment = '%1 = changed input index';
        ReverseInputMsg: Label 'Reversing eligibility input %1 must also require reconciliation.', Comment = '%1 = changed input index';

    [Test]
    procedure DisabledAgentIsNeverScheduled()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] The task is never scheduled when the agent is disabled, even if everything else is configured.
        // [GIVEN] Receipts on with a mailbox and communication on with a noreply account.
        InitializeSetup(TempSetup);
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Enable Communication" := true;

        // [THEN] Passing AgentEnabled = false never schedules.
        Assert.IsFalse(TempSetup.ShouldScheduleAgentTask(false), 'Disabled agent must not be scheduled.');
    end;

    [Test]
    procedure ReceiptsWithoutMailboxButCommunicationOnStillSchedules()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO 636970] Regression: turning off the inbound mailbox no longer stops the scheduler when communication is on.
        // [GIVEN] Enabled agent, receipts on but no mailbox, communication on with a noreply account.
        InitializeSetup(TempSetup);
        TempSetup."Enable Email with Receipts" := true;
        Clear(TempSetup."Email Account ID");
        TempSetup."Enable Communication" := true;

        // [THEN] Still scheduled via the outbound path.
        Assert.IsTrue(TempSetup.ShouldScheduleAgentTask(true), 'Communication must keep the scheduler alive without the inbound mailbox.');
    end;

    [Test]
    procedure RegisteredChannelAvailabilityMatrix()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempRegisteredSetup: Record "Expense Agent Setup" temporary;
        IncomingState: Integer;
        OutgoingState: Integer;
        ReceiptsPreference: Integer;
        CommunicationPreference: Integer;
        IncomingAvailable: Boolean;
        OutgoingAvailable: Boolean;
        Combination: Text;
    begin
        // [SCENARIO] Channel readiness and scheduling use preferences plus local account registration.

        // [GIVEN] The connector mock provides registered accounts, and each channel is varied across empty, stale, wrong-connector, and registered states with both preference values.
        InitializeSetup(TempRegisteredSetup);


        // [WHEN] Incoming readiness, outgoing readiness, and enabled or disabled scheduling are evaluated for every combination.
        for IncomingState := 0 to 3 do
            for OutgoingState := 0 to 3 do
                for ReceiptsPreference := 0 to 1 do
                    for CommunicationPreference := 0 to 1 do begin
                        TempSetup := TempRegisteredSetup;
                        TempSetup."Enable Email with Receipts" := ReceiptsPreference = 1;
                        TempSetup."Enable Communication" := CommunicationPreference = 1;
                        SetIncomingAccountState(TempSetup, IncomingState);
                        SetOutgoingAccountState(TempSetup, OutgoingState);
                        IncomingAvailable := (ReceiptsPreference = 1) and (IncomingState = 3);
                        OutgoingAvailable := (CommunicationPreference = 1) and (OutgoingState = 3);
                        Combination := StrSubstNo(
                            CombinationMsg,
                            IncomingState, OutgoingState, ReceiptsPreference, CommunicationPreference);


        // [THEN] Each decision matches the expected local registration matrix without probing external mailbox connectivity.
                        Assert.AreEqual(IncomingAvailable, TempSetup.IsIncomingCommunicationConfigured(), 'Incoming availability must use preference, ID and connector registration. ' + Combination);
                        Assert.AreEqual(OutgoingAvailable, TempSetup.IsOutgoingCommunicationConfigured(), 'Outgoing availability must use preference, ID and connector registration. ' + Combination);
                        Assert.AreEqual(IncomingAvailable or OutgoingAvailable, TempSetup.ShouldScheduleAgentTask(true), 'An enabled agent requires at least one available channel. ' + Combination);
                        Assert.IsFalse(TempSetup.ShouldScheduleAgentTask(false), 'No channel may schedule a disabled agent. ' + Combination);
                    end;
    end;

    [Test]
    procedure RegisteredButInaccessibleAccountsRemainConfigured()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Transient mailbox access failure does not erase registered channel configuration.

        // [GIVEN] Both preferences use locally registered connector accounts, and the connector mock is configured to fail retrieval.
        InitializeSetup(TempSetup);
        TempSetup."Enable Email with Receipts" := true;
        TempSetup."Enable Communication" := true;
        ConnectorMock.FailOnRetrieveEmails(true);


        // [WHEN] Readiness, scheduling eligibility, and missing-account repair are evaluated.

        // [THEN] Both channels remain configured, scheduling stays eligible, and repair reports no missing account.
        Assert.IsTrue(TempSetup.IsIncomingCommunicationConfigured(), 'Mailbox access failure must not be treated as deleted incoming configuration.');
        Assert.IsTrue(TempSetup.IsOutgoingCommunicationConfigured(), 'Mailbox access failure must not be treated as deleted outgoing configuration.');
        Assert.IsTrue(TempSetup.ShouldScheduleAgentTask(true), 'Availability must use local registration, not a live mailbox probe.');
        Assert.IsFalse(TempSetup.RepairMissingEmailAccounts(), 'Registered but inaccessible accounts must not be cleared.');
    end;

    [Test]
    procedure SchedulingChangesDetectEveryEligibilityInputInBothDirections()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
        ChangedInput: Integer;
    begin
        // [SCENARIO] Every scheduling eligibility input triggers reconciliation when changed in either direction.

        // [GIVEN] A baseline temporary setup has unchanged display addresses and no eligibility differences.
        TempPreviousSetup.Init();
        TempPreviousSetup."Email Address" := 'receipts@example.invalid';
        TempPreviousSetup."Noreply Email Address" := 'noreply@example.invalid';
        Assert.IsFalse(TempPreviousSetup.HasSchedulingChanges(TempPreviousSetup), 'Unchanged setup must not trigger reconciliation.');


        // [WHEN] Each agent, preference, account ID, and connector input is changed and compared in both directions.
        for ChangedInput := 1 to 7 do begin
            TempSetup := TempPreviousSetup;
            case ChangedInput of
                1:
                    TempSetup."Enable Agent" := not TempSetup."Enable Agent";
                2:
                    TempSetup."Enable Email with Receipts" := not TempSetup."Enable Email with Receipts";
                3:
                    TempSetup."Enable Communication" := not TempSetup."Enable Communication";
                4:
                    TempSetup."Email Account ID" := CreateGuid();
                5:
                    TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
                6:
                    TempSetup."Noreply Email Account ID" := CreateGuid();
                7:
                    TempSetup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector v4";
            end;


        // [THEN] Every eligibility change requires reconciliation, while the unchanged baseline does not.
            Assert.IsTrue(TempSetup.HasSchedulingChanges(TempPreviousSetup), StrSubstNo(ChangeInputMsg, ChangedInput));
            Assert.IsTrue(TempPreviousSetup.HasSchedulingChanges(TempSetup), StrSubstNo(ReverseInputMsg, ChangedInput));
        end;
    end;

    [Test]
    procedure OtherSetupChangesDoNotRequireSchedulingReconciliation()
    var
        TempSetup: Record "Expense Agent Setup" temporary;
        TempPreviousSetup: Record "Expense Agent Setup" temporary;
    begin
        // [SCENARIO] Non-eligibility setup changes do not trigger scheduling reconciliation.

        // [GIVEN] Only addresses, folder values, notification preferences, rules, and number-series settings differ from the baseline.
        TempPreviousSetup.Init();
        TempSetup := TempPreviousSetup;
        TempSetup."Email Address" := 'receipts@example.invalid';
        TempSetup."Noreply Email Address" := 'noreply@example.invalid';
        TempSetup."Email Folder" := 'Receipts';
        TempSetup."Email Folder Id" := 'folder-id';
        TempSetup."Enable Open Report Notif." := not TempSetup."Enable Open Report Notif.";
        TempSetup."Enable Approval Notif." := not TempSetup."Enable Approval Notif.";
        TempSetup."Use Rules" := not TempSetup."Use Rules";
        TempSetup."No. Series Applied" := not TempSetup."No. Series Applied";


        // [WHEN] The changed setup is compared with the baseline for scheduling changes.

        // [THEN] No scheduling reconciliation is required.
        Assert.IsFalse(TempSetup.HasSchedulingChanges(TempPreviousSetup), 'Display values, notification preferences and accounting defaults do not change channel eligibility.');
    end;

    local procedure InitializeSetup(var TempSetup: Record "Expense Agent Setup" temporary)
    var
        TempEmailAccount: Record "Email Account" temporary;
    begin
        Assert.IsTrue(IsSafeTestCompany(), 'Email lifecycle tests must run only in a dedicated disposable company.');
        ConnectorMock.Initialize();
        TempSetup.Init();
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TempSetup."Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Email Connector" := TempEmailAccount.Connector;
        TempSetup."Email Address" := TempEmailAccount."Email Address";
        ConnectorMock.AddAccount(TempEmailAccount, Enum::"Email Connector"::"Test Email Connector v4");
        TempSetup."Noreply Email Account ID" := TempEmailAccount."Account Id";
        TempSetup."Noreply Email Connector" := TempEmailAccount.Connector;
        TempSetup."Noreply Email Address" := TempEmailAccount."Email Address";
    end;

    local procedure IsSafeTestCompany(): Boolean
    begin
        exit(CompanyName() in [IsolatedTestCompanyLbl, CIIsolatedTestCompanyLbl]);
    end;

    local procedure SetIncomingAccountState(var TempSetup: Record "Expense Agent Setup" temporary; AccountState: Integer)
    begin
        case AccountState of
            0:
                TempSetup.ClearIncomingMailbox();
            1:
                TempSetup."Email Account ID" := CreateGuid();
            2:
                TempSetup."Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        end;
    end;

    local procedure SetOutgoingAccountState(var TempSetup: Record "Expense Agent Setup" temporary; AccountState: Integer)
    begin
        case AccountState of
            0:
                TempSetup.ClearNoreplyMailbox();
            1:
                TempSetup."Noreply Email Account ID" := CreateGuid();
            2:
                TempSetup."Noreply Email Connector" := Enum::"Email Connector"::"Test Email Connector";
        end;
    end;
}
