// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

// Coordinates acquisition/admission policy, runtime setup, trial/billing and framework task construction.
// Work Item commands own only the validity of persisted receipt, association, text and outcome state.
codeunit 3345 "PA Work Item Intake"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "PA Known Sender" = R;

    var
        AgentNotActiveErr: Label 'The Payables Agent is not active.', Comment = 'Payables Agent is a term, and should not be translated.';
        WorkItemNotCreatedErr: Label 'The invoice work item could not be created.';
        SenderRejectedReasonTxt: Label 'The sender policy rejected this source.';

    internal procedure ReceivePdf(FileName: Text; PdfInStream: InStream): Guid
    var
        WorkItem: Codeunit "PA Work Item";
        DraftIntake: Codeunit "PA Draft Work Item Intake";
    begin
        if not WorkItem.CreateFromPdf(FileName, PdfInStream) then
            Error(WorkItemNotCreatedErr);
        if DraftIntake.TryProcessIncomingWorkItem(WorkItem.GetId()) then begin
            WorkItem.Refresh();
            exit(WorkItem.GetId());
        end;

        if not Admit(WorkItem) then
            Error(AgentNotActiveErr);
        exit(WorkItem.GetId());
    end;

    internal procedure ReceivePdf(FileName: Text; PdfInStream: InStream; var WorkItem: Codeunit "PA Work Item"): Boolean
    var
        DraftIntake: Codeunit "PA Draft Work Item Intake";
    begin
        Clear(WorkItem);
        if not WorkItem.CreateFromPdf(FileName, PdfInStream) then
            exit(false);
        if DraftIntake.TryProcessIncomingWorkItem(WorkItem.GetId()) then begin
            WorkItem.Refresh();
            exit(WorkItem.HasAgentTask());
        end;
        exit(Admit(WorkItem));
    end;

    internal procedure Admit(var WorkItem: Codeunit "PA Work Item"): Boolean
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        KnownSender: Record "PA Known Sender";
        KPI: Record "Payables Agent KPI";
        Setup: Codeunit "PA Setup";
        Instructions: Codeunit "PA Agent Instructions";
        Telemetry: Codeunit "PA Telemetry";
        Trial: Codeunit "PA Trial";
        KnownSenders: Codeunit "PA Known Senders";
        DraftIntake: Codeunit "PA Draft Work Item Intake";
        TaskBuilder: Codeunit "Agent Task Builder";
        MessageBuilder: Codeunit "Agent Task Message Builder";
        ExternalId: Text[2048];
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        Message: Text;
        RequiresReview: Boolean;
        ExcludeBilling: Boolean;
        UploadTitleLbl: Label 'Uploaded document %1', Comment = '%1 = file name';
        EmailTitleLbl: Label 'Document from %1', Comment = '%1 = sender';
        V2MessageLbl: Label 'A new document has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true;
    begin
        WorkItem.Refresh();
        if WorkItem.GetAgentTaskId() <> 0 then
            exit(false);
        if not Setup.FindAgentAndReconcileSetup(Agent) then
            exit(false);
        if Agent."Agent Metadata Provider" <> "Agent Metadata Provider"::"Payables Agent" then
            exit(false);
        if Agent.State = Agent.State::Disabled then
            exit(false);
        ExternalId := WorkItem.GetAgentTaskExternalId();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("Agent User Security ID", Agent."User Security ID");
        AgentTask.SetRange("External ID", ExternalId);
        if not AgentTask.IsEmpty() then
            exit(false);

        if WorkItem.GetSourceType() = "PA Source Type"::Email then
            if KnownSender.GetForWorkItem(WorkItem, KnownSender) then
                if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                    WorkItem.MarkRejected(SenderRejectedReasonTxt);
                    Telemetry.LogWorkItemRejected(WorkItem);
                    exit(false);
                end;

        Instructions.EnsureAgentInstructionsMatchConfiguration(Agent."User Security ID");
        RequiresReview := KnownSenders.ShouldRequestReview(WorkItem);
        ExcludeBilling := false;
        if Trial.CheckActiveAndEndIfExhausted() then begin
            Trial.IncrementTrialInvoiceCount();
            Telemetry.LogTrialTaskCreated(Trial.GetTrialInvoiceCount(), Trial.GetTrialInvoiceLimit());
            ExcludeBilling := true;
        end;

        MessageFrom := CopyStr(WorkItem.GetFileName(), 1, 250);
        TaskTitle := CopyStr(StrSubstNo(UploadTitleLbl, MessageFrom), 1, 150);
        if WorkItem.GetSourceType() = "PA Source Type"::Email then begin
            MessageFrom := CopyStr(WorkItem.GetEmailFrom(), 1, 250);
            TaskTitle := CopyStr(StrSubstNo(EmailTitleLbl, MessageFrom), 1, 150);
        end;
        if not DraftIntake.TryGetAgentTaskMessage(WorkItem.GetId(), Message) then
            Message := V2MessageLbl;
        MessageBuilder
            .Initialize(MessageFrom, Message)
            .SetRequiresReview(RequiresReview)
            .SetMessageExternalID(ExternalId);
        AgentTask := TaskBuilder
            .Initialize(Agent."User Security ID", TaskTitle)
            .SetExternalId(ExternalId)
            .AddTaskMessage(MessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
        WorkItem.AssociateAgentTask(AgentTask.ID);

        Telemetry.LogWorkItemAdmitted(WorkItem, RequiresReview);
        KPI.InsertKPIEntry("PA KPI Scenario"::"Agent Tasks Received");
        exit(true);
    end;
}
