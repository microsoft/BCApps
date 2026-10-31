// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

// Authoritative flow from a received source through admission to an Agent Framework task.
codeunit 3345 "PA Task Intake"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "PA Known Sender" = R;

    var
        AgentNotActiveErr: Label 'The Payables Agent is not active.', Comment = 'Payables Agent is a term, and should not be translated.';
        SourceNotCreatedErr: Label 'The invoice source could not be created.';
        TaskNotLoadableErr: Label 'Agent task %1 was created but its Payables Agent backing could not be loaded.', Comment = '%1 = Agent Task ID';
        SenderRejectedReasonTxt: Label 'The sender policy rejected this source.';

    internal procedure CreateTask(FileName: Text; PdfInStream: InStream)
    var
        PATask: Codeunit "Payables Agent Task";
        Source: Codeunit "PA Task Source";
        DraftBasedIntake: Codeunit "PA Draft Based Source Intake";
        SourceId: Guid;
    begin
        if not Source.CreateFromPdf(FileName, PdfInStream) then
            Error(SourceNotCreatedErr);

        if Source.GetVersion() = "PA Version"::V1 then begin
            SourceId := Source.GetId();
            DraftBasedIntake.ProcessIncomingSource(SourceId);
            if not Source.LoadDraftBased(SourceId) then
                Error(SourceNotCreatedErr);
            exit;
        end;

        // No other module owns an uploaded v2 source: roll it back if the agent cannot take it.
        if not CreateTask(Source, PATask) then
            Error(AgentNotActiveErr);
    end;

    internal procedure CreateTask(FileName: Text; PdfInStream: InStream; var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        Source: Codeunit "PA Task Source";
        DraftBasedIntake: Codeunit "PA Draft Based Source Intake";
        SourceId: Guid;
        AgentTaskId: BigInteger;
    begin
        Clear(PATask);
        if not Source.CreateFromPdf(FileName, PdfInStream) then
            exit(false);

        if Source.GetVersion() = "PA Version"::V2 then
            exit(CreateTask(Source, PATask));

        // The draft-based import subscriber performs admission during e-document processing.
        SourceId := Source.GetId();
        DraftBasedIntake.ProcessIncomingSource(SourceId);
        if not Source.LoadDraftBased(SourceId) then
            exit(false);
        AgentTaskId := Source.GetAgentTaskId();
        if AgentTaskId = 0 then
            exit(false);
        exit(PATask.Load(AgentTaskId));
    end;

    internal procedure CreateTask(var Source: Codeunit "PA Task Source"): Boolean
    var
        PATask: Codeunit "Payables Agent Task";
    begin
        exit(CreateTask(Source, PATask));
    end;

    internal procedure CreateTask(var Source: Codeunit "PA Task Source"; var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        KnownSender: Record "PA Known Sender";
        PayablesAgentKPI: Record "Payables Agent KPI";
        PASetup: Codeunit "PA Setup";
        PAAgentInstructions: Codeunit "PA Agent Instructions";
        PATelemetry: Codeunit "PA Telemetry";
        PATrial: Codeunit "PA Trial";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        ExternalId: Text[2048];
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        UploadTitleLbl: Label 'Uploaded document %1', Comment = '%1 = file name';
        EmailTitleLbl: Label 'Document from %1', Comment = '%1 = sender';
        RequiresReview: Boolean;
        ExcludeBilling: Boolean;
    begin
        Clear(PATask);
        if Source.GetAgentTaskId() <> 0 then
            exit(false);
        ExternalId := Source.GetAgentTaskExternalId();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", ExternalId);
        if not AgentTask.IsEmpty() then
            exit(false);
        if not PASetup.FindAgentAndReconcileSetup(Agent) then
            exit(false);
        if Agent.State = Agent.State::Disabled then
            exit(false);

        // Admission policy runs against the received source before a framework task exists.
        if Source.GetSourceType() = "PA Source Type"::Email then
            if KnownSender.GetForSource(Source, KnownSender) then
                if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                    Source.MarkRejected(SenderRejectedReasonTxt);
                    PATelemetry.LogTaskSkippedSenderRejected(Source);
                    exit(false);
                end;

        // New tasks must use the selected prompt revision, including locally edited experiment variants.
        PAAgentInstructions.EnsureAgentInstructionsMatchConfiguration(Agent."User Security ID");
        RequiresReview := ShouldRequestReview(Source);
        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            PATelemetry.LogTrialTaskCreated(PATrial.GetTrialInvoiceCount(), PATrial.GetTrialInvoiceLimit());
            ExcludeBilling := true;
        end;

        MessageFrom := CopyStr(Source.GetFileName(), 1, 250);
        TaskTitle := CopyStr(StrSubstNo(UploadTitleLbl, MessageFrom), 1, 150);
        if Source.GetSourceType() = "PA Source Type"::Email then begin
            MessageFrom := CopyStr(Source.GetEmailFrom(), 1, 250);
            TaskTitle := CopyStr(StrSubstNo(EmailTitleLbl, MessageFrom), 1, 150);
        end;
        AgentTaskMessageBuilder
            .Initialize(MessageFrom, Source.GetAgentTaskMessage())
            .SetRequiresReview(RequiresReview)
            .SetMessageExternalID(ExternalId);
        AgentTask := AgentTaskBuilder
            .Initialize(Agent."User Security ID", TaskTitle)
            .SetExternalId(ExternalId)
            .AddTaskMessage(AgentTaskMessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
        Source.BindAgentTask(AgentTask.ID);
        if not PATask.Load(AgentTask.ID) then
            Error(TaskNotLoadableErr, AgentTask.ID);

        PATelemetry.LogTaskReceived(PATask, RequiresReview);
        PayablesAgentKPI.InsertKPIEntry("PA KPI Scenario"::"Agent Tasks Received");
        exit(true);
    end;

    /// <summary>
    /// Only emails are subject to review. A configured subfolder explicitly trusts its contents; otherwise
    /// sender authentication, policy and the known-senders list determine whether supervisor review is needed.
    /// </summary>
    local procedure ShouldRequestReview(Source: Codeunit "PA Task Source"): Boolean
    var
        KnownSender: Record "PA Known Sender";
        PASetup: Codeunit "PA Setup";
        HeaderValue: Text;
        SenderAuthenticated: Boolean;
    begin
        if Source.GetSourceType() <> "PA Source Type"::Email then
            exit(false);

        PASetup.GetSetup();
        case PASetup.GetEmailReviewPolicy() of
            "PA Email Review Policy"::Always,
            "PA Email Review Policy"::Unset:
                exit(true);
            "PA Email Review Policy"::Never:
                exit(false);
        end;
        if PASetup.GetEmailFolder() <> '' then
            exit(false);
        if Source.TryGetEmailHeader('Authentication-Results', HeaderValue) then
            SenderAuthenticated := CompAuthPassed(HeaderValue);
        if not SenderAuthenticated then
            SenderAuthenticated := IsSenderInternal(Source);
        if not SenderAuthenticated then
            exit(true);
        if KnownSender.GetForSource(Source, KnownSender) then
            exit(KnownSender."Sender Policy" <> "PA Sender Policy"::Approve);
        if IsSenderInternal(Source) then
            exit(false);
        exit(true);
    end;

    local procedure IsSenderInternal(Source: Codeunit "PA Task Source"): Boolean
    var
        HeaderValue: Text;
    begin
        if Source.TryGetEmailHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue) then
            exit(LowerCase(HeaderValue).Trim() = 'internal');
        exit(false);
    end;

    local procedure CompAuthPassed(AuthenticationResults: Text): Boolean
    begin
        exit(StrPos(LowerCase(AuthenticationResults), 'compauth=pass') > 0);
    end;
}
