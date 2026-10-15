namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Agents;
using System.Telemetry;

codeunit 3312 "PA Draft Based Events"
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
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        PASetup: Codeunit "PA Setup";
        EDocumentPATask: Codeunit "PA Task";
        PayablesAgentKPI: Codeunit "Payables Agent KPI";
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
        ReviewIncomingInvoice: Boolean;
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
        if not PayablesAgentSetup.GetAgent(Agent) then
            exit;
        if Agent.State = Agent.State::Disabled then
            exit;

        ReviewIncomingInvoice := PASetup.GetReviewIncomingInvoice();
        CustomDimensions.Set('Category', PayablesAgentSetup.FeatureName());
        CustomDimensions.Set('SystemId', EDocImpSessionTelemetry.CreateSystemIdText(EDocument.SystemId));
        CustomDimensions.Set('EmailReviewPolicy', Format(PASetup.GetEmailReviewPolicy(), 0, 9));

        // A sender explicitly set to Reject is a blocklist: no agent task is created.
        EDocumentPATask.LoadForEDocument(EDocument);
        if KnownSender.GetForTask(EDocumentPATask, KnownSender) then
            if KnownSender."Sender Policy" = "PA Sender Policy"::Reject then begin
                Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
                exit;
            end;

        BuildAgentTask(EDocument, EDocumentPATask, Agent);

        CustomDimensions.Set('ReviewIncomingInvoice', Format(ReviewIncomingInvoice, 0, 9));
        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure RecordKnownSenderOnAgentProcessingStep(EDocument: Record "E-Document")
    var
        PayablesAgent: Codeunit "Payables Agent";
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
        PayablesAgent: Codeunit "Payables Agent";
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        PATrial: Codeunit "PA Trial";
        AgentTaskTitle: Text[150];
        Message: Text;
        MustRequestReviewOfMessage: Boolean;
        ExcludeBilling: Boolean;
        TelemetryDictionary: Dictionary of [Text, Text];
        TaskTitleLbl: Label 'E-Document from %1', Comment = '%1 is the sender''s email address.';
        MessageLbl: Label 'A new electronic document %1 has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true, Comment = '%1 is the e-document entry number.';
        TrialModeTok: Label 'Agent Task created in trial mode. Skipping billing for invoice.', Locked = true;
    begin
        MustRequestReviewOfMessage := PayablesAgentSetupMgt.ShouldRequestReview(EDocumentPATask);
        Message := StrSubstNo(MessageLbl, EDocument."Entry No");
        AgentTaskTitle := CopyStr(StrSubstNo(TaskTitleLbl, LowerCase(EDocument."Source Details")), 1, MaxStrLen(AgentTaskTitle));

        ExcludeBilling := false;
        if PATrial.IsActive() then begin
            PATrial.IncrementTrialInvoiceCount();
            TelemetryDictionary := PayablesAgent.GetCustomDimensions();
            TelemetryDictionary.Add('TrialInvoiceCount', Format(PATrial.GetTrialInvoiceCount(), 0, 9));
            TelemetryDictionary.Add('TrialInvoiceLimit', Format(PATrial.GetTrialInvoiceLimit(), 0, 9));
            TelemetryDictionary.Add('ExcludeBilling', Format(ExcludeBilling, 0, 9));
            Session.LogMessage('0000SEE', TrialModeTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDictionary);
            ExcludeBilling := true;
        end;

        AgentTaskMessageBuilder
            .Initialize(CopyStr(EDocument."Source Details", 1, 250), Message)
            .SetRequiresReview(MustRequestReviewOfMessage)
            .SetMessageExternalID(Format(EDocument."Entry No"));

        AgentTaskBuilder
            .Initialize(Agent."User Security ID", AgentTaskTitle)
            .SetExternalId(Format(EDocument."Entry No"))
            .AddTaskMessage(AgentTaskMessageBuilder)
            .SetBillingContext(ExcludeBilling ? Enum::"Agent Task Billing Context"::Excluded : Enum::"Agent Task Billing Context"::Default)
            .Create();
    end;

    procedure WasEDocumentCreatedByAgent(EDocument: Record "E-Document"): Boolean
    begin
        exit(EDocument.GetEDocumentService().Code = PayablesAgentEDocServiceTok);
    end;

    var
        PATask: Codeunit "PA Task";
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
}