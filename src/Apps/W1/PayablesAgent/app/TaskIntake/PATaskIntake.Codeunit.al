// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Agents;

codeunit 3345 "PA Task Intake"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "PA Known Sender" = R;

    internal procedure CreateTask(FileName: Text; PdfInStream: InStream)
    var
        EDocument: Record "E-Document";
        PATask: Codeunit "Payables Agent Task";
        EDocImport: Codeunit "E-Doc. Import";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        if PATask.CreateUploadBacking(FileName, PdfInStream) then begin
            // No other module owns the uploaded PDF in v2: roll back its backing records if the agent cannot take it.
            if not MaterializeAgentTask(PATask) then
                Error(AgentNotActiveErr);
            exit;
        end;

        EDocImport.CreateFromType(EDocument, PADraftBasedSetup.GetOrCreateAgentEDocumentService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
    end;

    internal procedure CreateTask(ExternalId: Text[2048]): Boolean
    var
        PATask: Codeunit "Payables Agent Task";
    begin
        if not PATask.Load(ExternalId) then
            exit(false);
        exit(MaterializeAgentTask(PATask));
    end;

    local procedure MaterializeAgentTask(var PATask: Codeunit "Payables Agent Task"): Boolean
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        KnownSender: Record "PA Known Sender";
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
        PATelemetry: Codeunit "PA Telemetry";
        PayablesAgentKPI: Codeunit "Payables Agent KPI";
        PATrial: Codeunit "PA Trial";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        ExternalId: Text[2048];
        TaskTitle: Text[150];
        MessageFrom: Text[250];
        MessageText: Text;
        UploadTitleLbl: Label 'Uploaded document %1', Comment = '%1 = file name';
        EmailTitleLbl: Label 'Document from %1', Comment = '%1 = sender';
        TaskMessageLbl: Label 'A new document has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true;
        RequiresReview: Boolean;
        ExcludeBilling: Boolean;
    begin
        if PATask.GetAgentTaskId() <> 0 then
            exit(false);
        ExternalId := PATask.GetAgentTaskExternalId();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", ExternalId);
        if not AgentTask.IsEmpty() then
            exit(false);
        if not PAAgentConfiguration.GetAgent(Agent) then
            exit(false);
        if Agent.State = Agent.State::Disabled then
            exit(false);

        // Rejected email senders are blocked before a framework task is created.
        if PATask.GetSourceType() = "PA Source Type"::Email then
            if KnownSender.GetForTask(PATask, KnownSender) then
                if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                    PATelemetry.LogTaskSkippedSenderRejected(PATask);
                    exit(false);
                end;

        RequiresReview := ShouldRequestReview(PATask);
        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            PATelemetry.LogTrialTaskCreated(PATrial.GetTrialInvoiceCount(), PATrial.GetTrialInvoiceLimit());
            ExcludeBilling := true;
        end;

        MessageFrom := CopyStr(PATask.GetFileName(), 1, 250);
        TaskTitle := CopyStr(StrSubstNo(UploadTitleLbl, MessageFrom), 1, 150);
        if PATask.GetSourceType() = "PA Source Type"::Email then begin
            MessageFrom := CopyStr(PATask.GetEmailFrom(), 1, 250);
            TaskTitle := CopyStr(StrSubstNo(EmailTitleLbl, MessageFrom), 1, 150);
        end;
        MessageText := TaskMessageLbl;
        AgentTaskMessageBuilder
            .Initialize(MessageFrom, MessageText)
            .SetRequiresReview(RequiresReview)
            .SetMessageExternalID(ExternalId);
        AgentTask := AgentTaskBuilder
            .Initialize(Agent."User Security ID", TaskTitle)
            .SetExternalId(ExternalId)
            .AddTaskMessage(AgentTaskMessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
        PATask.BindAgentTask(AgentTask.ID);

        PATelemetry.LogTaskReceived(PATask, RequiresReview);
        PayablesAgentKPI.InsertKPIEntry("PA KPI Scenario"::"Agent Tasks Received");
        exit(true);
    end;

    /// <summary>
    /// Only emails are subject to review. A configured subfolder explicitly trusts its contents; otherwise
    /// sender authentication, policy and the known-senders list determine whether supervisor review is needed.
    /// </summary>
    local procedure ShouldRequestReview(PATask: Codeunit "Payables Agent Task"): Boolean
    var
        KnownSender: Record "PA Known Sender";
        PASetup: Codeunit "PA Setup";
        HeaderValue: Text;
        SenderAuthenticated: Boolean;
    begin
        if PATask.GetSourceType() <> "PA Source Type"::Email then
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
        if PATask.TryGetEmailHeader('Authentication-Results', HeaderValue) then
            SenderAuthenticated := CompAuthPassed(HeaderValue);
        if not SenderAuthenticated then
            SenderAuthenticated := IsSenderInternal(PATask);
        if not SenderAuthenticated then
            exit(true);
        if KnownSender.GetForTask(PATask, KnownSender) then
            exit(KnownSender."Sender Policy" <> "PA Sender Policy"::Approve);
        if IsSenderInternal(PATask) then
            exit(false);
        exit(true);
    end;

    local procedure IsSenderInternal(PATask: Codeunit "Payables Agent Task"): Boolean
    var
        HeaderValue: Text;
    begin
        if PATask.TryGetEmailHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue) then
            exit(LowerCase(HeaderValue).Trim() = 'internal');
        exit(false);
    end;

    local procedure CompAuthPassed(AuthenticationResults: Text): Boolean
    begin
        exit(StrPos(LowerCase(AuthenticationResults), 'compauth=pass') > 0);
    end;

    var
        AgentNotActiveErr: Label 'The Payables Agent is not active.', Comment = 'Payables Agent is a term, and should not be translated.';
}
