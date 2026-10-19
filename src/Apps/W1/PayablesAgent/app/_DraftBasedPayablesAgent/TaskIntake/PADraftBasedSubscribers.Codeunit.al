namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Agents;
using System.Telemetry;

codeunit 3312 "PA Draft Based Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure CreateAgentTask(EDocument: Record "E-Document"; StartState: Enum "Import E-Doc. Proc. Status"; DesiredEndState: Enum "Import E-Doc. Proc. Status")
    var
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        KnownSender: Record "PA Known Sender";
        PayablesAgentDetailedSetup: Record "PA Detailed Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PASetup: Codeunit "PA Setup";
        EDocumentPATask: Codeunit "PA Task";
        PAAgentTaskCreation: Codeunit "PA Agent Task Creation";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not PATask.IsEDocumentPipelineActive() then
            exit;
        if not EDocument.Get(EDocument."Entry No") then
            exit;
        if EDocument.GetEDocumentService().Code <> PayablesAgentEDocServiceTok then
            exit;
        if StartState <> "Import E-Doc. Proc. Status"::Unprocessed then
            exit;
        if (StartState = "Import E-Doc. Proc. Status"::Unprocessed) and (DesiredEndState <> "Import E-Doc. Proc. Status"::Unprocessed) then
            exit;

        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", Format(EDocument."Entry No"));
        if not AgentTask.IsEmpty() then
            exit;

        EDocument.CalcFields("Import Processing Status");
        if EDocument."Import Processing Status" in ["Import E-Doc. Proc. Status"::Processed] then
            exit;
        if not PAAgentTaskCreation.GetActiveAgent(Agent) then
            exit;

        PASetup.GetSetup(PayablesAgentDetailedSetup);
        CustomDimensions.Set('Category', PayablesAgentSetup.FeatureName());
        CustomDimensions.Set('SystemId', EDocImpSessionTelemetry.CreateSystemIdText(EDocument.SystemId));
        CustomDimensions.Set('EmailReviewPolicy', Format(PayablesAgentDetailedSetup."Email Review Policy", 0, 9));

        // A sender explicitly set to Reject is a blocklist: no agent task is created.
        EDocumentPATask.LoadForEDocument(EDocument);
        if KnownSender.GetForTask(EDocumentPATask, KnownSender) then
            if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
                exit;
            end;

        BuildAgentTask(EDocument, EDocumentPATask, Agent);

        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure RecordKnownSenderOnAgentProcessingStep(EDocument: Record "E-Document")
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        EDocumentPATask: Codeunit "PA Task";
        SessionID: BigInteger;
    begin
        if not PATask.IsEDocumentPipelineActive() then
            exit;
        if not WasEDocumentCreatedByAgent(EDocument) then
            exit;
        if not PayablesAgent.IsPayablesAgentSession(SessionID) then
            exit;
        EDocumentPATask.LoadForEDocument(EDocument);
        EDocumentPATask.RecordKnownSender();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Purchase Draft Utility", OnInsertedEDocumentPurchaseHeader, '', false, false)]
    local procedure UpdateAgentTaskTitleOnPurchaseDocumentDraftCreated(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        AgentTaskID: BigInteger;
    begin
        if not PATask.IsEDocumentPipelineActive() then
            exit;
        if EDocumentPurchaseHeader.IsTemporary() then
            exit;
        if not WasEDocumentCreatedByAgent(EDocument) then
            exit;
        if not TryFindAgentTaskID(EDocument, AgentTaskID) then
            exit;

        PATask.SetTitle(AgentTaskID, CopyStr(EDocumentPurchaseHeader."Sales Invoice No.", 1, 50), CopyStr(EDocumentPurchaseHeader."Vendor Company Name", 1, 100));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. M365 Conn. Events", OnGetOutlookCategoryDescription, '', false, false)]
    local procedure OnGetOutlookCategoryDescription(var CategoryDescription: Text)
    var
        ProcessedByPayablesAgentEmailCategoryTok: Label 'Processed by Payables Agent', Locked = true;
    begin
        CategoryDescription := ProcessedByPayablesAgentEmailCategoryTok;
    end;

    local procedure TryFindAgentTaskID(EDocument: Record "E-Document"; var AgentTaskID: BigInteger) Found: Boolean
    var
        AgentTaskMessage: Record "Agent Task Message";
    begin
        AgentTaskMessage.SetRange("External ID", Format(EDocument."Entry No"));
        Found := AgentTaskMessage.FindFirst();
        AgentTaskID := AgentTaskMessage."Task ID";
        exit(Found);
    end;

    local procedure BuildAgentTask(EDocument: Record "E-Document"; EDocumentPATask: Codeunit "PA Task"; Agent: Record Agent)
    var
        PayablesAgentSetupMgt: Codeunit "Payables Agent Setup";
        PAAgentTaskCreation: Codeunit "PA Agent Task Creation";
        TaskTitleLbl: Label 'E-Document from %1', Comment = '%1 is the sender''s email address.';
        MessageLbl: Label 'A new electronic document %1 has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true, Comment = '%1 is the e-document entry number.';
    begin
        PAAgentTaskCreation.Create(
            Agent,
            CopyStr(StrSubstNo(TaskTitleLbl, LowerCase(EDocument."Source Details")), 1, 150),
            CopyStr(EDocument."Source Details", 1, 250),
            StrSubstNo(MessageLbl, EDocument."Entry No"),
            Format(EDocument."Entry No"),
            PayablesAgentSetupMgt.ShouldRequestReview(EDocumentPATask));
    end;

    procedure WasEDocumentCreatedByAgent(EDocument: Record "E-Document"): Boolean
    begin
        exit(EDocument.GetEDocumentService().Code = PayablesAgentEDocServiceTok);
    end;

    var
        PATask: Codeunit "PA Task";
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
}