// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;

// PA-owned source, setup and instruction contracts that do not require the Agent Framework.
codeunit 133735 "PA Wrapper Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure RejectedSourceRemainsVisibleWithoutAgentTask()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        Collection: Codeunit "PA Work Item Collection";
        WorkItem: Codeunit "PA Work Item";
        VisibleWorkItem: Codeunit "PA Work Item";
        Found: Boolean;
    begin
        // [SCENARIO] A rejected work item is persisted without an agent task and stays visible to supervision.
        // [GIVEN] A received work item.
        StoredWorkItem."File Name" := 'rejected.pdf';
        StoredWorkItem.Insert();
        Check(WorkItem.Load(StoredWorkItem.SystemId), 'The received source must load before admission.');

        // [WHEN] It is rejected.
        WorkItem.MarkRejected('Rejected by policy');

        // [THEN] It has no agent task, persists its rejection and reason, and is listed among rejected work items.
        StoredWorkItem.Get(StoredWorkItem."Entry No.");
        Check(StoredWorkItem."Agent Task ID" = 0, 'Rejection must not create or bind an Agent Framework task.');
        Check(StoredWorkItem."Admission Status" = "PA Work Item Admission Status"::Rejected, 'The source must persist its rejected status.');
        Check(StoredWorkItem."Rejection Reason" = 'Rejected by policy', 'The source must persist its rejection reason.');
        Collection.OpenByState("PA Work Item State"::Rejected);
        while Collection.Next(VisibleWorkItem) do
            if VisibleWorkItem.GetId() = StoredWorkItem.SystemId then
                Found := true;
        Check(Found, 'The rejected source must remain available to supervision.');
    end;

    [Test]
    procedure SetupProposalDoesNotPersistUntilApplied()
    var
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
        BeforeMonitoring: Boolean;
    begin
        // [SCENARIO] Editing a setup proposal does not persist it, and preparing a deactivation turns monitoring off.
        // [GIVEN] A setup proposal.
        Proposal.LoadOrCreateSetup();
        BeforeMonitoring := Proposal.GetMonitorOutlook();

        // [WHEN] Its monitoring flag is changed.
        Proposal.SetMonitorOutlook(not BeforeMonitoring);

        // [THEN] The stored setup is unchanged.
        Stored.LoadOrCreateSetup();
        Check(Stored.GetMonitorOutlook() = BeforeMonitoring, 'Editing a proposal must not persist it.');

        // [WHEN] The proposal is prepared for applying with the agent deactivated.
        Proposal.PrepareForApply(false);

        // [THEN] Its monitoring flag is turned off.
        Check(not Proposal.GetMonitorOutlook(), 'Deactivation must normalize the proposed monitoring flag.');
    end;

    [Test]
    procedure DisabledSetupCannotPersistMonitoringEnabled()
    var
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        // [SCENARIO] A deactivated setup cannot persist mailbox monitoring as on.
        // [GIVEN] A setup proposal with monitoring on.
        Proposal.LoadOrCreateSetup();
        Proposal.SetMonitorOutlook(true);

        // [WHEN] It is applied with the agent deactivated.
        Proposal.ApplySetup(false);

        // [THEN] The stored setup has monitoring off.
        Stored.LoadOrCreateSetup();
        Check(not Stored.GetMonitorOutlook(), 'A disabled configuration cannot persist monitoring on.');
    end;

    [Test]
    procedure UnsupportedOrIncompleteMonitoringCannotBeApplied()
    var
        Proposal: Codeunit "PA Setup";
        MissingAccountId: Guid;
    begin
        // [SCENARIO] Monitoring without a mailbox, or monitoring in V2, cannot be applied.
        // [GIVEN] A setup proposal with monitoring on and no mailbox.
        Proposal.LoadOrCreateSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.SetMailboxSelection(MissingAccountId, '', '');
        Proposal.SetEmailReviewPolicy("PA Email Review Policy"::Always);

        // [WHEN] It is applied with the agent activated.
        // [THEN] It is rejected before anything is written.
        // V1 rejects the absent mailbox; a v2 build must reject monitoring itself before any writes.
        asserterror Proposal.ApplySetup(true);
        Check((StrPos(GetLastErrorText(), 'Select a mailbox') > 0) or
            (StrPos(GetLastErrorText(), 'not available for this version') > 0), 'The proposal must be rejected before application.');
    end;

    [Test]
    procedure InstructionSelectionAndFingerprintResolveWithoutSecrets()
    var
        Instructions: Codeunit "PA Agent Instructions";
        Classic: Text;
        AgentDriven: Text;
        Fingerprint: Text;
    begin
        // [SCENARIO] The agent instructions resolve to the expected bundled resource and have a stable fingerprint.
        // [WHEN] The instructions resource is resolved with and without agent-driven line matching.
        Classic := Instructions.ResolveResource(false);
        AgentDriven := Instructions.ResolveResource(true);

        // [THEN] V2 selects its own prompt, and V1 selects the classic or agent-driven prompt.
        if Classic = AgentDriven then
            Check(Classic = 'Prompts/PayablesAgent-AgentInstructions-V2.md', 'V2 must select its prompt independently of the v1 line-matching treatment.')
        else begin
            Check(Classic = 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', 'The classic resource must remain available.');
            Check(AgentDriven = 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', 'The agent-driven resource must remain available.');
        end;

        // [WHEN] The instructions fingerprint is computed twice.
        // [THEN] It is a SHA256 hash and stays the same.
        Fingerprint := Instructions.GetInstructionsConfigHash();
        Check(StrLen(Fingerprint) = 64, 'The selected prompt must produce a SHA256 fingerprint.');
        Check(Fingerprint = Instructions.GetInstructionsConfigHash(), 'An unchanged selected prompt must have a stable fingerprint.');
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
