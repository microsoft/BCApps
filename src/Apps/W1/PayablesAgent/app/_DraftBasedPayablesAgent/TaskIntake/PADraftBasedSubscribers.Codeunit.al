namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;
using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Agents;
using System.Telemetry;

// Rule: all subscribers only apply for v1 (they all need a guard)
codeunit 3312 "PA Draft Based Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        PAV1V2Flag: Codeunit "PA V1V2 Flag";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure ImportStepOfEDocumentCompleted(EDocument: Record "E-Document"; StartState: Enum "Import E-Doc. Proc. Status"; DesiredEndState: Enum "Import E-Doc. Proc. Status")
    var
        EDocumentPATask: Codeunit "PA Task";
        PASourceType: Enum "PA Source Type";
    begin
        if PAV1V2Flag.IsV2Active() then
            exit;
        if not EDocument.Get(EDocument."Entry No") then
            exit;
        if EDocument.GetEDocumentService().Code <> PayablesAgentEDocServiceTok then
            exit;
        if StartState <> "Import E-Doc. Proc. Status"::Unprocessed then
            exit;
        if (StartState = "Import E-Doc. Proc. Status"::Unprocessed) and (DesiredEndState <> "Import E-Doc. Proc. Status"::Unprocessed) then
            exit;
        EDocument.CalcFields("Import Processing Status");
        if EDocument."Import Processing Status" in ["Import E-Doc. Proc. Status"::Processed] then
            exit;

        // Hand the e-document to the agent. Everything beyond the e-document specifics above (agent, duplicates,
        // rejected senders, review, trial, billing and telemetry) is decided in "PA Task". Under v1 both emails and
        // uploads reach the agent as e-documents; only emails carry an Outlook message id.
        if EDocument."Outlook Mail Message Id" <> '' then
            PASourceType := "PA Source Type"::Email
        else
            PASourceType := "PA Source Type"::Upload;
        if EDocumentPATask.CreateTask(PASourceType, Format(EDocument."Entry No")) then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure RecordKnownSenderOnAgentProcessingStep(EDocument: Record "E-Document")
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        EDocumentPATask: Codeunit "PA Task";
        SessionID: BigInteger;
    begin
        if PAV1V2Flag.IsV2Active() then
            exit;
        if not WasEDocumentCreatedByAgent(EDocument) then
            exit;
        if not PayablesAgent.IsPayablesAgentSession(SessionID) then
            exit;
        if EDocumentPATask.Load(Format(EDocument."Entry No")) then
            EDocumentPATask.RecordKnownSender();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Purchase Draft Utility", OnInsertedEDocumentPurchaseHeader, '', false, false)]
    local procedure UpdateAgentTaskTitleOnPurchaseDocumentDraftCreated(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        AgentTaskID: BigInteger;
    begin
        if PAV1V2Flag.IsV2Active() then
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
        if PAV1V2Flag.IsV2Active() then
            exit;
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

    local procedure WasEDocumentCreatedByAgent(EDocument: Record "E-Document"): Boolean
    begin
        exit(EDocument.GetEDocumentService().Code = PayablesAgentEDocServiceTok);
    end;

    var
        PATask: Codeunit "PA Task";
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;
}