namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.EServices.EDocumentConnector.Microsoft365;
using System.Agents;

// Rule: all subscribers only apply for v1 (they all need a guard)
codeunit 3312 "PA Draft Based Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        PayablesAgentEDocServiceTok: Label 'AGENT', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure ImportStepOfEDocumentCompleted(EDocument: Record "E-Document"; StartState: Enum "Import E-Doc. Proc. Status"; DesiredEndState: Enum "Import E-Doc. Proc. Status")
    var
        PATaskIntake: Codeunit "PA Task Intake";
        PATaskSource: Codeunit "PA Task Source";
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
        if not PATaskSource.LoadDraftBased(EDocument.SystemId) then
            exit;
        if PATaskIntake.CreateTask(PATaskSource) then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", OnAfterProcessIncomingEDocument, '', false, false)]
    local procedure RecordKnownSenderOnAgentProcessingStep(EDocument: Record "E-Document")
    var
        KnownSender: Record "PA Known Sender";
        PayablesAgent: Codeunit "Payables Agent Metadata";
        EDocumentPATask: Codeunit "Payables Agent Task";
        SessionID: BigInteger;
    begin
        if PAV1V2Flag.IsV2Active() then
            exit;
        if not WasEDocumentCreatedByAgent(EDocument) then
            exit;
        if not PayablesAgent.IsPayablesAgentSession(SessionID) then
            exit;
        if EDocumentPATask.Load(SessionID) then
            KnownSender.InsertIfNew(EDocumentPATask);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Purchase Draft Utility", OnInsertedEDocumentPurchaseHeader, '', false, false)]
    local procedure UpdateAgentTaskTitleOnPurchaseDocumentDraftCreated(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    var
        AgentTask: Record "Agent Task";
        AgentTaskID: BigInteger;
        NewTitle: Text;
        InvoiceTitleLbl: Label 'Invoice %1 from %2', Comment = '%1 = invoice number, %2 = vendor name';
        CreditMemoTitleLbl: Label 'Credit memo %1 from %2', Comment = '%1 = credit memo number, %2 = vendor name';
    begin
        if PAV1V2Flag.IsV2Active() then
            exit;
        if EDocumentPurchaseHeader.IsTemporary() then
            exit;
        if not WasEDocumentCreatedByAgent(EDocument) then
            exit;
        if not TryFindAgentTaskID(EDocument, AgentTaskID) then
            exit;
        if not AgentTask.Get(AgentTaskID) then
            exit;

        if IsCreditNote(EDocument) then
            NewTitle := StrSubstNo(CreditMemoTitleLbl, EDocumentPurchaseHeader."Sales Invoice No.", EDocumentPurchaseHeader."Vendor Company Name")
        else
            NewTitle := StrSubstNo(InvoiceTitleLbl, EDocumentPurchaseHeader."Sales Invoice No.", EDocumentPurchaseHeader."Vendor Company Name");
        NewTitle := CopyStr(NewTitle, 1, MaxStrLen(AgentTask.Title));
        if AgentTask.Title = NewTitle then
            exit;
        AgentTask.Title := CopyStr(NewTitle, 1, MaxStrLen(AgentTask.Title));
        AgentTask.Modify(true);
    end;

    local procedure IsCreditNote(EDocument: Record "E-Document"): Boolean
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        InStream: InStream;
        StructuredData: Text;
        SourceJsonObject: JsonObject;
    begin
        if not EDocDataStorage.Get(EDocument."Structured Data Entry No.") then
            exit(false);
        EDocDataStorage.GetTempBlob().CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(StructuredData);
        if not SourceJsonObject.ReadFrom(StructuredData) then
            exit(false);
        exit(EDocMLLMSchemaHelper.IsCreditNote(SourceJsonObject));
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
}