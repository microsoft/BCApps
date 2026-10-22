// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Agents;
using System.Email;
using System.Utilities;

// Aggregate over one accepted Payables Agent task. Its sole identity is the Agent Framework task ID.
// Loading resolves and validates the version-specific source backing; backing records never leave this contract.
codeunit 3341 "Payables Agent Task"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = RM, tabledata "Agent Task Message" = R,
        tabledata "E-Document" = RM, tabledata "E-Doc. Data Storage" = R, tabledata "Email Inbox" = R;

    internal procedure Load(AgentTaskId: BigInteger): Boolean
    var
        AgentTaskMessage: Record "Agent Task Message";
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
        EDocumentEntryNo: Integer;
        HasDraftBacking: Boolean;
        HasTaskBacking: Boolean;
    begin
        ClearLoaded();
        if not LoadedAgentTask.Get(AgentTaskId) then
            exit(false);
        if LoadedAgentTask."Company Name" <> CompanyName() then begin
            ClearLoaded();
            exit(false);
        end;

        StoredTask.SetRange("Agent Task ID", AgentTaskId);
        if StoredTask.FindFirst() then begin
            LoadedStoredTask := StoredTask;
            HasTaskBacking := true;
            if StoredTask.Next() <> 0 then
                Error(MultipleTaskBackingsErr, AgentTaskId);
        end;

        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        AgentTaskMessage.SetFilter("External ID", '<>%1', '');
        if AgentTaskMessage.FindFirst() then
            repeat
                if Evaluate(EDocumentEntryNo, AgentTaskMessage."External ID") then
                    if EDocument.Get(EDocumentEntryNo) then
                        if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                            if HasDraftBacking and (LoadedEDocument."Entry No" <> EDocument."Entry No") then
                                Error(MultipleTaskBackingsErr, AgentTaskId);
                            LoadedEDocument := EDocument;
                            HasDraftBacking := true;
                        end;
            until AgentTaskMessage.Next() = 0;
        // The framework task carries the same opaque correlation and survives loss of its initial message.
        if not HasDraftBacking then
            if Evaluate(EDocumentEntryNo, LoadedAgentTask."External ID") then
                if EDocument.Get(EDocumentEntryNo) then
                    if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                        LoadedEDocument := EDocument;
                        HasDraftBacking := true;
                    end;

        if HasTaskBacking and HasDraftBacking then
            Error(AmbiguousTaskBackingErr, AgentTaskId);
        if HasTaskBacking then
            LoadedVersion := "PA Version"::V2
        else
            if HasDraftBacking then
                LoadedVersion := "PA Version"::V1
            else begin
                ClearLoaded();
                exit(false);
            end;
        exit(true);
    end;

    internal procedure LoadCurrentSession(): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        Provider: Enum "Agent Metadata Provider";
    begin
        ClearLoaded();
        if not AgentSession.IsAgentSession(Provider) then
            exit(false);
        if Provider <> Provider::"Payables Agent" then
            exit(false);
        exit(Load(AgentSession.GetCurrentSessionAgentTaskId()));
    end;

    internal procedure Refresh()
    var
        AgentTaskId: BigInteger;
    begin
        AgentTaskId := GetAgentTaskId();
        if Load(AgentTaskId) then;
    end;

    internal procedure GetAgentTaskId(): BigInteger
    begin
        RequireLoaded();
        exit(LoadedAgentTask.ID);
    end;

    internal procedure GetVersion(): Enum "PA Version"
    begin
        RequireLoaded();
        exit(LoadedVersion);
    end;

    internal procedure GetSourceId(): Guid
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.SystemId);
        exit(LoadedEDocument.SystemId);
    end;

    internal procedure GetSourceType(): Enum "PA Source Type"
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then begin
            if LoadedStoredTask."Email Inbox Id" <> 0 then
                exit("PA Source Type"::Email);
            exit("PA Source Type"::Upload);
        end;
        if LoadedEDocument."Outlook Mail Message Id" <> '' then
            exit("PA Source Type"::Email);
        exit("PA Source Type"::Upload);
    end;

    internal procedure HasPdf(): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."File Content".HasValue());
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage."File Format" = Enum::"E-Doc. File Format"::PDF);
        exit(false);
    end;

    internal procedure CanExtractText(): Boolean
    begin
        exit((GetVersion() = "PA Version"::V2) and HasPdf());
    end;

    internal procedure CanRegisterOutcome(): Boolean
    begin
        exit(GetVersion() = "PA Version"::V2);
    end;

    internal procedure GetFileName(): Text
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."File Name");
        if Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(Storage.Name);
        exit('');
    end;

    internal procedure GetEmailFrom(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(LoadedEDocument."Source Details");
        if EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
            exit(EmailInbox."Sender Address");
        exit('');
    end;

    internal procedure GetSenderName(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            if EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
                exit(EmailInbox."Sender Name");
        exit('');
    end;

    internal procedure GetEmailSubject(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(LoadedEDocument."Additional Source Details");
        if EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
            exit(EmailInbox.Description);
        exit('');
    end;

    internal procedure GetEmailExternalId(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(LoadedEDocument."Outlook Mail Message Id");
        if EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
            exit(EmailInbox."External Message Id");
        exit('');
    end;

    internal procedure GetEmailReceivedAt(): DateTime
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(LoadedEDocument.SystemCreatedAt);
        if EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
            exit(EmailInbox."Received DateTime");
        exit(0DT);
    end;

    internal procedure GetSenderAddress(): Text[250]
    begin
        exit(CopyStr(GetEmailFrom(), 1, 250));
    end;

    internal procedure GetCreatedAt(): DateTime
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.SystemCreatedAt);
        exit(LoadedEDocument.SystemCreatedAt);
    end;

    internal procedure GetUpdatedAt(): DateTime
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.SystemModifiedAt);
        exit(LoadedEDocument.SystemModifiedAt);
    end;

    internal procedure GetOutcome(): RecordId
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.Outcome);
        exit(LoadedEDocument."Document Record ID");
    end;

    internal procedure GetAgentTaskStatus(): Enum "Agent Task Status"
    begin
        RequireLoaded();
        exit(LoadedAgentTask.Status);
    end;

    internal procedure GetState(): Enum "PA Task State"
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(GetDraftBasedState());
        if LoadedAgentTask."Needs Attention" then
            exit("PA Task State"::"Needs Attention");
        case LoadedAgentTask.Status of
            LoadedAgentTask.Status::Completed:
                exit("PA Task State"::Processed);
            LoadedAgentTask.Status::"Stopped by User", LoadedAgentTask.Status::"Stopped by System":
                exit("PA Task State"::"Needs Attention");
        end;
        exit("PA Task State"::"Pending Processing");
    end;

    internal procedure GetIntakeStatus(): Enum "PA Task Intake Status"
    begin
        RequireLoaded();
        exit("PA Task Intake Status"::Accepted);
    end;

    internal procedure GetSourceEmailBody(): Text
    var
        EmailMessage: Codeunit "Email Message";
        MessageId: Guid;
    begin
        if not TryGetEmailMessageId(MessageId) then
            exit('');
        if EmailMessage.Get(MessageId) then
            exit(EmailMessage.GetBody());
        exit('');
    end;

    internal procedure TryGetEmailHeader(HeaderName: Text; var HeaderValue: Text): Boolean
    var
        EmailMessage: Codeunit "Email Message";
        MessageId: Guid;
    begin
        Clear(HeaderValue);
        if not TryGetEmailMessageId(MessageId) then
            exit(false);
        if not EmailMessage.Get(MessageId) then
            exit(false);
        exit(EmailMessage.GetHeader(HeaderName, HeaderValue));
    end;

    internal procedure GetSourcePdf(var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        Clear(TempBlob);
        Clear(FileName);
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then begin
            if not LoadedStoredTask."File Content".HasValue() then
                exit(false);
            LoadedStoredTask.GetFileContent(TempBlob);
            FileName := LoadedStoredTask."File Name";
            exit(true);
        end;
        if not Storage.Get(LoadedEDocument."Unstructured Data Entry No.") then
            exit(false);
        TempBlob := Storage.GetTempBlob();
        FileName := Storage.Name;
        exit(true);
    end;

    internal procedure GetSourceText(): Text
    begin
        RequireLoaded();
        if LoadedVersion <> "PA Version"::V2 then
            exit('');
        exit(LoadedStoredTask.GetFileContentAsText());
    end;

    internal procedure SetSourceText(NewText: Text)
    var
        StoredTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if LoadedVersion <> "PA Version"::V2 then
            Error(SourceTextNotSupportedErr);
        if not StoredTask.Get(LoadedStoredTask."Entry No.") then
            Error(TaskNotFoundErr);
        StoredTask.SetFileContentAsText(NewText);
        StoredTask.Modify();
        Refresh();
    end;

    internal procedure IsResultRecord(Candidate: RecordId): Boolean
    begin
        RequireLoaded();
        if Candidate.TableNo = 0 then
            exit(false);
        if Candidate = GetOutcome() then
            exit(true);
        exit((LoadedVersion = "PA Version"::V1) and (Candidate = LoadedEDocument.RecordId()));
    end;

    internal procedure RegisterOutcome(OutcomeRecordId: RecordId)
    var
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        ValidateOutcome(OutcomeRecordId);
        if LoadedVersion = "PA Version"::V2 then begin
            if not StoredTask.Get(LoadedStoredTask."Entry No.") then
                Error(TaskNotFoundErr);
            StoredTask.Outcome := OutcomeRecordId;
            StoredTask.Modify();
        end else begin
            if not EDocument.Get(LoadedEDocument."Entry No") then
                Error(TaskNotFoundErr);
            EDocument."Document Record ID" := OutcomeRecordId;
            EDocument.Modify();
        end;
        Refresh();
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        exit(LoadedAgentTask."External ID");
    end;

    local procedure GetDraftBasedState(): Enum "PA Task State"
    begin
        LoadedEDocument.CalcFields("Import Processing Status");
        case LoadedEDocument."Import Processing Status" of
            "Import E-Doc. Proc. Status"::"Draft Ready":
                exit("PA Task State"::"Needs Attention");
            "Import E-Doc. Proc. Status"::"Ready for draft":
                exit("PA Task State"::"Ready For Review");
            "Import E-Doc. Proc. Status"::Processed:
                exit("PA Task State"::Processed);
        end;
        exit("PA Task State"::"Pending Processing");
    end;

    local procedure TryGetEmailMessageId(var MessageId: Guid): Boolean
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then begin
            if not EmailInbox.Get(LoadedStoredTask."Email Inbox Id") then
                exit(false);
            MessageId := EmailInbox."Message Id";
        end else
            MessageId := LoadedEDocument."Mail Message Id";
        exit(not IsNullGuid(MessageId));
    end;

    local procedure ValidateOutcome(OutcomeRecordId: RecordId)
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchaseHeader.ReadIsolation := IsolationLevel::UpdLock;
        case OutcomeRecordId.TableNo of
            Database::"Purchase Header":
                if PurchaseHeader.Get(OutcomeRecordId) then
                    if PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::Invoice, PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::"Credit Memo"] then
                        exit;
            Database::"Purch. Inv. Header":
                if PostedInvoice.Get(OutcomeRecordId) then
                    exit;
            Database::"Purch. Cr. Memo Hdr.":
                if PostedCreditMemo.Get(OutcomeRecordId) then
                    exit;
        end;
        Error(InvalidOutcomeErr);
    end;

    local procedure RequireLoaded()
    begin
        if LoadedVersion = "PA Version"::Unknown then
            Error(TaskNotFoundErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(LoadedAgentTask);
        Clear(LoadedStoredTask);
        Clear(LoadedEDocument);
        LoadedVersion := "PA Version"::Unknown;
    end;

    var
        LoadedAgentTask: Record "Agent Task";
        LoadedStoredTask: Record "Payables Agent Task";
        LoadedEDocument: Record "E-Document";
        LoadedVersion: Enum "PA Version";
        TaskNotFoundErr: Label 'The task does not exist.';
        MultipleTaskBackingsErr: Label 'Agent task %1 has more than one Payables Agent backing record.';
        AmbiguousTaskBackingErr: Label 'Agent task %1 has both version 1 and version 2 backing records.';
        InvalidOutcomeErr: Label 'The outcome must be an existing purchase invoice, purchase order, purchase credit memo, posted purchase invoice, or posted purchase credit memo.';
        SourceTextNotSupportedErr: Label 'Extracted source text cannot be stored for this task.';
        AgentEDocumentServiceTok: Label 'AGENT', Locked = true;
}
