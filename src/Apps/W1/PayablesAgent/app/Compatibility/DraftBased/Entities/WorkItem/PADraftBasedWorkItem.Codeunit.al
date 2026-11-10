// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Agents;
using System.Utilities;

codeunit 3332 "PA Draft Based Work Item"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "Agent Task Message" = R, tabledata "E-Document" = RM, tabledata "E-Doc. Data Storage" = R;

    var
        LoadedEDocument: Record "E-Document";
        Loaded: Boolean;
        SourceNotFoundErr: Label 'The work item does not exist.';
        MultipleTaskRecordsErr: Label 'Agent task %1 has more than one Payables Agent E-Document.', Comment = '%1 = Agent Task ID';
        AgentEDocumentServiceTok: Label 'AGENT', Locked = true;

    internal procedure CreateFromPdf(FileName: Text; PdfInStream: InStream): Boolean
    var
        EDocument: Record "E-Document";
        EDocImport: Codeunit "E-Doc. Import";
        DraftBasedSetupStore: Codeunit "PA Draft Based Setup Store";
    begin
        ClearLoaded();
        EDocImport.CreateFromType(EDocument, DraftBasedSetupStore.GetOrCreateService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        exit(Load(EDocument.SystemId));
    end;

    internal procedure Load(WorkItemId: Guid): Boolean
    begin
        ClearLoaded();
        if IsNullGuid(WorkItemId) then
            exit(false);
        if not LoadedEDocument.GetBySystemId(WorkItemId) then
            exit(false);
        if LoadedEDocument.GetEDocumentService().Code <> AgentEDocumentServiceTok then
            exit(false);
        Loaded := true;
        exit(true);
    end;

    internal procedure LoadForAgentTask(AgentTaskId: BigInteger): Boolean
    var
        OwningAgent: Record Agent;
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        EDocument: Record "E-Document";
        AgentAccess: Codeunit "PA Agent Access";
        EDocumentEntryNo: Integer;
        IsOwned: Boolean;
    begin
        ClearLoaded();
        if not AgentTask.Get(AgentTaskId) then
            exit(false);
        if AgentTask."Company Name" <> CompanyName() then
            exit(false);
        if AgentAccess.TryGetRuntimeTaskOwnership(AgentTask, IsOwned) then begin
            if not IsOwned then
                exit(false);
        end else begin
            if not OwningAgent.Get(AgentTask."Agent User Security ID") then
                exit(false);
            if OwningAgent."Agent Metadata Provider" <> "Agent Metadata Provider"::"Payables Agent" then
                exit(false);
        end;

        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        AgentTaskMessage.SetFilter("External ID", '<>%1', '');
        if AgentTaskMessage.FindSet() then
            repeat
                if Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
                    if EDocument.Get(EDocumentEntryNo) then
                        if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                            if Loaded and (LoadedEDocument."Entry No" <> EDocument."Entry No") then
                                Error(MultipleTaskRecordsErr, AgentTaskId);
                            LoadedEDocument := EDocument;
                            Loaded := true;
                        end;
            until AgentTaskMessage.Next() = 0;
        // The framework correlation survives loss of the initial message.
        if not Loaded then
            if Evaluate(EDocumentEntryNo, AgentTask."External ID") then
                if EDocument.Get(EDocumentEntryNo) then
                    if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                        LoadedEDocument := EDocument;
                        Loaded := true;
                    end;
        exit(Loaded);
    end;

    internal procedure GetId(): Guid
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemId);
    end;

    internal procedure FindAgentTaskId(): BigInteger
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        Resolved: Codeunit "PA Draft Based Work Item";
        WorkItemId: Guid;
    begin
        WorkItemId := GetId();
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", GetAgentTaskExternalId());
        if AgentTask.FindSet() then
            repeat
                if Resolved.LoadForAgentTask(AgentTask.ID) then
                    if Resolved.GetId() = WorkItemId then
                        exit(AgentTask.ID);
            until AgentTask.Next() = 0;

        // Preserve correlation in both directions for historical tasks that only retain their initial message.
        AgentTaskMessage.SetRange("External ID", GetAgentTaskExternalId());
        if AgentTaskMessage.FindSet() then
            repeat
                if Resolved.LoadForAgentTask(AgentTaskMessage."Task ID") then
                    if Resolved.GetId() = WorkItemId then
                        exit(AgentTaskMessage."Task ID");
            until AgentTaskMessage.Next() = 0;
        exit(0);
    end;

    internal procedure GetEntryNo(): Integer
    begin
        RequireLoaded();
        exit(LoadedEDocument."Entry No");
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        exit(Format(LoadedEDocument."Entry No"));
    end;

    internal procedure GetSourceType(): Enum "PA Source Type"
    begin
        RequireLoaded();
        if LoadedEDocument."Outlook Mail Message Id" <> '' then
            exit("PA Source Type"::Email);
        exit("PA Source Type"::Upload);
    end;

    internal procedure GetFileName(): Text
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage.Name);
        exit('');
    end;

    internal procedure HasPdf(): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage."File Format" = Enum::"E-Doc. File Format"::PDF);
        exit(false);
    end;

    internal procedure GetEmailFrom(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Source Details");
    end;

    internal procedure GetEmailSubject(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Additional Source Details");
    end;

    internal procedure GetEmailExternalId(): Text
    begin
        RequireLoaded();
        exit(LoadedEDocument."Outlook Mail Message Id");
    end;

    internal procedure GetEmailReceivedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemCreatedAt);
    end;

    internal procedure GetCreatedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemCreatedAt);
    end;

    internal procedure GetUpdatedAt(): DateTime
    begin
        RequireLoaded();
        exit(LoadedEDocument.SystemModifiedAt);
    end;

    internal procedure TryGetEmailMessageId(var MessageId: Guid): Boolean
    begin
        RequireLoaded();
        MessageId := LoadedEDocument."Mail Message Id";
        exit(not IsNullGuid(MessageId));
    end;

    internal procedure GetSourcePdf(var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        Clear(TempBlob);
        Clear(FileName);
        RequireLoaded();
        if not Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(false);
        TempBlob := Storage.GetTempBlob();
        FileName := Storage.Name;
        exit(true);
    end;

    internal procedure GetOutcome(): RecordId
    begin
        exit(LoadedEDocument."Document Record ID");
    end;

    internal procedure IsStoredRecord(Candidate: RecordId): Boolean
    begin
        exit(Candidate = LoadedEDocument.RecordId());
    end;

    internal procedure GetState(): Enum "PA Work Item State"
    begin
        // Keep the loaded document, but calculate its processing FlowField just as the task did.
        LoadedEDocument.CalcFields("Import Processing Status");
        case LoadedEDocument."Import Processing Status" of
            "Import E-Doc. Proc. Status"::"Draft Ready":
                exit("PA Work Item State"::"Needs Attention");
            "Import E-Doc. Proc. Status"::"Ready for draft":
                exit("PA Work Item State"::"Ready For Review");
            "Import E-Doc. Proc. Status"::Processed:
                exit("PA Work Item State"::Processed);
        end;
        exit("PA Work Item State"::"Pending Processing");
    end;

    // Set-level posting bridge only: no per-task registration, attachment, title update or commit.
    internal procedure ReplaceOutcomeReferences(PreviousOutcome: RecordId; PostedOutcome: RecordId)
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", PreviousOutcome);
        if EDocument.FindSet(true) then
            repeat
                if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                    EDocument."Document Record ID" := PostedOutcome;
                    EDocument.Modify();
                end;
            until EDocument.Next() = 0;
    end;

    local procedure RequireLoaded()
    begin
        if not Loaded then
            Error(SourceNotFoundErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(LoadedEDocument);
        Loaded := false;
    end;
}
