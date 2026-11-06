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
        StoredWorkItem."File Name" := 'rejected.pdf';
        StoredWorkItem.Insert();
        Check(WorkItem.Load(StoredWorkItem.SystemId), 'The received source must load before admission.');

        WorkItem.MarkRejected('Rejected by policy');

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
        Proposal.LoadOrCreateSetup();
        BeforeMonitoring := Proposal.GetMonitorOutlook();
        Proposal.SetMonitorOutlook(not BeforeMonitoring);
        Stored.LoadOrCreateSetup();
        Check(Stored.GetMonitorOutlook() = BeforeMonitoring, 'Editing a proposal must not persist it.');
        Proposal.PrepareForApply(false);
        Check(not Proposal.GetMonitorOutlook(), 'Deactivation must normalize the proposed monitoring flag.');
    end;

    [Test]
    procedure DisabledSetupCannotPersistMonitoringEnabled()
    var
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        Proposal.LoadOrCreateSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);
        Stored.LoadOrCreateSetup();
        Check(not Stored.GetMonitorOutlook(), 'A disabled configuration cannot persist monitoring on.');
    end;

    [Test]
    procedure UnsupportedOrIncompleteMonitoringCannotBeApplied()
    var
        Proposal: Codeunit "PA Setup";
        MissingAccountId: Guid;
    begin
        Proposal.LoadOrCreateSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.SetMailboxSelection(MissingAccountId, '', '');
        Proposal.SetEmailReviewPolicy("PA Email Review Policy"::Always);
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
        Classic := Instructions.ResolveResource(false);
        AgentDriven := Instructions.ResolveResource(true);
        if Classic = AgentDriven then
            Check(Classic = 'Prompts/PayablesAgent-AgentInstructions-V2.md', 'V2 must select its prompt independently of the v1 line-matching treatment.')
        else begin
            Check(Classic = 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', 'The classic resource must remain available.');
            Check(AgentDriven = 'DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', 'The agent-driven resource must remain available.');
        end;
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
