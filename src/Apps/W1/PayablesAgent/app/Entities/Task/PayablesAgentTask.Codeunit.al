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

// Owns task data and narrow mutations; identities are opaque and backing records never leave this contract.
codeunit 3341 "Payables Agent Task"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = RM, tabledata "Agent Task Message" = R,
        tabledata "E-Document" = RM, tabledata "E-Doc. Data Storage" = R, tabledata "Email Inbox" = R;

    var
        TempLoadedTask: Record "PA Detailed Task" temporary;
        LoadedEDocument: Record "E-Document";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        LoadedKey: BigInteger;
        LoadedIsV2: Boolean;
        EmailInboxId: BigInteger;
        TaskNotFoundErr: Label 'The task does not exist.';
        InvalidOutcomeErr: Label 'The outcome must be an existing purchase invoice, purchase order, purchase credit memo, posted purchase invoice, or posted purchase credit memo.';
        SourceTextNotSupportedErr: Label 'Extracted source text cannot be stored for this task.';
        EmptyPreviousOutcomeErr: Label 'An existing outcome reference is required for replacement.';
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;
        AgentEDocumentServiceTok: Label 'AGENT', Locked = true;

    internal procedure Load(AgentTaskId: BigInteger): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        AgentTask: Record "Agent Task";
    begin
        ClearLoaded();
        if not AgentTask.Get(AgentTaskId) then
            exit(false);
        if AgentTask."Company Name" <> CompanyName() then
            exit(false);
        PayablesAgentTask.SetRange("Agent Task ID", AgentTaskId);
        if PayablesAgentTask.FindFirst() then
            exit(LoadByKey(PayablesAgentTask."Entry No.", true));
        AgentTaskMessage.SetRange("Task ID", AgentTaskId);
        AgentTaskMessage.SetFilter("External ID", '<>%1', '');
        if not AgentTaskMessage.FindFirst() then
            exit(false);
        exit(Load(AgentTaskMessage."External ID"));
    end;

    internal procedure Load(TaskId: Guid): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        ClearLoaded();
        if IsNullGuid(TaskId) then
            exit(false);
        if PayablesAgentTask.GetBySystemId(TaskId) then
            exit(LoadByKey(PayablesAgentTask."Entry No.", true));
        if EDocument.GetBySystemId(TaskId) then
            exit(LoadByKey(EDocument."Entry No", false));
        exit(false);
    end;

    // Runtime correlation tokens are opaque to consumers, irrespective of their historical encoding.
    internal procedure Load(ExternalId: Text[2048]): Boolean
    var
        TaskId: Guid;
        EDocumentEntryNo: Integer;
    begin
        ClearLoaded();
        if Evaluate(TaskId, ExternalId) then
            exit(Load(TaskId));
        if Evaluate(EDocumentEntryNo, ExternalId) then
            exit(LoadByKey(EDocumentEntryNo, false));
        exit(false);
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
        KeyToRefresh: BigInteger;
        IsV2: Boolean;
    begin
        KeyToRefresh := LoadedKey;
        IsV2 := LoadedIsV2;
        if LoadByKey(KeyToRefresh, IsV2) then;
    end;

    internal procedure CreateUploadBacking(FileName: Text; PdfInStream: InStream): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        ClearLoaded();
        if not PAV1V2Flag.IsV2Active() then
            exit(false);
        PayablesAgentTask."Received At" := CurrentDateTime();
        PayablesAgentTask."File Name" := CopyStr(FileName, 1, MaxStrLen(PayablesAgentTask."File Name"));
        PayablesAgentTask."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
        PayablesAgentTask.Insert();
        exit(LoadByKey(PayablesAgentTask."Entry No.", true));
    end;

    internal procedure BindAgentTask(AgentTaskId: BigInteger)
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if LoadedIsV2 then begin
            if not PayablesAgentTask.Get(LoadedKey) then
                Error(TaskNotFoundErr);
            PayablesAgentTask."Agent Task ID" := AgentTaskId;
            PayablesAgentTask.Modify();
        end;
        Refresh();
    end;

    internal procedure GetRecord(var PADetailedTask: Record "PA Detailed Task")
    begin
        // Preserve the receiving temporary row's system fields; none come from backing storage.
        PADetailedTask.TransferFields(TempLoadedTask);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    begin
        exit(TempLoadedTask."Agent Task ID");
    end;

    internal procedure GetSourceType(): Enum "PA Source Type"
    begin
        exit(TempLoadedTask."Source Type");
    end;

    internal procedure HasPdf(): Boolean
    begin
        exit(TempLoadedTask."Has Pdf");
    end;

    internal procedure GetFileName(): Text
    begin
        exit(TempLoadedTask."File Name");
    end;

    internal procedure GetEmailFrom(): Text
    begin
        exit(TempLoadedTask."Email From");
    end;

    internal procedure GetEmailSubject(): Text
    begin
        exit(TempLoadedTask."Email Subject");
    end;

    internal procedure GetSenderAddress(): Text[250]
    begin
        exit(TempLoadedTask."Email From");
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
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        Clear(TempBlob);
        Clear(FileName);
        if LoadedKey = 0 then
            exit(false);
        if LoadedIsV2 then begin
            if not PayablesAgentTask.Get(LoadedKey) then
                exit(false);
            if not PayablesAgentTask."File Content".HasValue() then
                exit(false);
            PayablesAgentTask.GetFileContent(TempBlob);
            FileName := PayablesAgentTask."File Name";
            exit(true);
        end;
        if not EDocument.Get(LoadedKey) then
            exit(false);
        if not Storage.Get(EDocument."Unstructured Data Entry No.") then
            exit(false);
        TempBlob := Storage.GetTempBlob();
        FileName := Storage.Name;
        exit(true);
    end;

    internal procedure GetSourceText(): Text
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        if not LoadedIsV2 or (LoadedKey = 0) then
            exit('');
        if PayablesAgentTask.Get(LoadedKey) then
            exit(PayablesAgentTask.GetFileContentAsText());
        exit('');
    end;

    internal procedure SetSourceText(NewText: Text)
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if not LoadedIsV2 then
            Error(SourceTextNotSupportedErr);
        if not PayablesAgentTask.Get(LoadedKey) then
            Error(TaskNotFoundErr);
        PayablesAgentTask.SetFileContentAsText(NewText);
        PayablesAgentTask.Modify();
        Refresh();
    end;

    internal procedure IsResultRecord(Candidate: RecordId): Boolean
    begin
        if (LoadedKey = 0) or (Candidate.TableNo = 0) then
            exit(false);
        if Candidate = TempLoadedTask.Outcome then
            exit(true);
        // The draft-based review operates on the source document before finalization.
        exit(not LoadedIsV2 and (Candidate = LoadedEDocument.RecordId()));
    end;

    internal procedure RegisterOutcome(OutcomeRecordId: RecordId)
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        RequireLoaded();
        ValidateOutcome(OutcomeRecordId);
        if LoadedIsV2 then begin
            if not PayablesAgentTask.Get(LoadedKey) then
                Error(TaskNotFoundErr);
            PayablesAgentTask.Outcome := OutcomeRecordId;
            PayablesAgentTask.Modify();
        end else begin
            if not EDocument.Get(LoadedKey) then
                Error(TaskNotFoundErr);
            EDocument."Document Record ID" := OutcomeRecordId;
            EDocument.Modify();
        end;
        Refresh();
    end;

    // A conditional field update preserves unrelated changes and outcomes reassigned since posting began.
    internal procedure ReplaceOutcomeReferences(PreviousOutcome: RecordId; PostedOutcome: RecordId)
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        if PreviousOutcome.TableNo = 0 then
            Error(EmptyPreviousOutcomeErr);
        ValidateOutcome(PostedOutcome);
        if PreviousOutcome = PostedOutcome then
            exit;
        PayablesAgentTask.SetRange(Outcome, PreviousOutcome);
        PayablesAgentTask.ModifyAll(Outcome, PostedOutcome);
        EDocument.SetRange("Document Record ID", PreviousOutcome);
        if EDocument.FindSet(true) then
            repeat
                if EDocument.GetEDocumentService().Code = AgentEDocumentServiceTok then begin
                    EDocument."Document Record ID" := PostedOutcome;
                    EDocument.Modify();
                end;
            until EDocument.Next() = 0;
    end;

    internal procedure Complete()
    var
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if not LoadedIsV2 then
            exit;
        if not PayablesAgentTask.Get(LoadedKey) then
            Error(TaskNotFoundErr);
        PayablesAgentTask."Completed At" := CurrentDateTime();
        PayablesAgentTask.Modify();
        Refresh();
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        if LoadedIsV2 then
            exit(CopyStr(LowerCase(Format(TempLoadedTask."Task Id")).Replace('{', '').Replace('}', ''), 1, 2048));
        exit(Format(LoadedKey));
    end;

    local procedure ValidateOutcome(OutcomeRecordId: RecordId)
    var
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
    begin
        // Serialize registration against posting/deletion of the unposted document so posting can see the new reference.
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
        if LoadedKey = 0 then
            Error(TaskNotFoundErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(TempLoadedTask);
        TempLoadedTask."Source Type" := "PA Source Type"::Upload;
        Clear(LoadedEDocument);
        Clear(LoadedKey);
        Clear(LoadedIsV2);
        Clear(EmailInboxId);
    end;

    local procedure LoadByKey(TaskKey: BigInteger; IsV2: Boolean): Boolean
    var
        PayablesAgentTask: Record "Payables Agent Task";
        EDocument: Record "E-Document";
    begin
        ClearLoaded();
        if TaskKey = 0 then
            exit(false);
        if IsV2 then begin
            if not PayablesAgentTask.Get(TaskKey) then
                exit(false);
            LoadedKey := TaskKey;
            LoadedIsV2 := true;
            TempLoadedTask.TransferFields(PayablesAgentTask);
            TempLoadedTask."Entry No." := 0;
            TempLoadedTask."Task Id" := PayablesAgentTask.SystemId;
            TempLoadedTask."Has Pdf" := PayablesAgentTask."File Content".HasValue();
            TempLoadedTask."Can Extract Text" := true;
            EmailInboxId := PayablesAgentTask."Email Inbox Id";
            TempLoadedTask.State := TempLoadedTask.State::"Pending Processing";
            if PayablesAgentTask."Completed At" <> 0DT then
                TempLoadedTask.State := TempLoadedTask.State::Processed;
        end else begin
            if not EDocument.Get(TaskKey) then
                exit(false);
            LoadedKey := TaskKey;
            LoadedEDocument := EDocument;
            TempLoadedTask."Task Id" := EDocument.SystemId;
            TempLoadedTask.Outcome := EDocument."Document Record ID";
            TempLoadedTask."Received At" := EDocument.SystemCreatedAt;
            PopulateDocumentSource(EDocument);
            TempLoadedTask."Agent Task ID" := FindAgentTaskIdForExternalId(Format(TaskKey));
        end;
        PopulateEmail();
        PopulateAgentTaskStatus();
        exit(true);
    end;

    local procedure PopulateDocumentSource(EDocument: Record "E-Document")
    var
        Storage: Record "E-Doc. Data Storage";
    begin
        if Storage.Get(EDocument."Unstructured Data Entry No.") then begin
            TempLoadedTask."File Name" := Storage.Name;
            TempLoadedTask."Has Pdf" := Storage."File Format" = Enum::"E-Doc. File Format"::PDF;
        end;
        if EDocument."Outlook Mail Message Id" <> '' then begin
            TempLoadedTask."Source Type" := "PA Source Type"::Email;
            TempLoadedTask."Email From" := CopyStr(EDocument."Source Details", 1, 250);
            TempLoadedTask."Email Subject" := CopyStr(EDocument."Additional Source Details", 1, 250);
            TempLoadedTask."Email External Id" := EDocument."Outlook Mail Message Id";
        end;
        EDocument.CalcFields("Import Processing Status");
        case EDocument."Import Processing Status" of
            "Import E-Doc. Proc. Status"::"Draft Ready":
                TempLoadedTask.State := TempLoadedTask.State::"Needs Attention";
            "Import E-Doc. Proc. Status"::"Ready for draft":
                TempLoadedTask.State := TempLoadedTask.State::"Ready For Review";
            "Import E-Doc. Proc. Status"::Processed:
                TempLoadedTask.State := TempLoadedTask.State::Processed;
        end;
    end;

    local procedure PopulateEmail()
    var
        EmailInbox: Record "Email Inbox";
    begin
        if EmailInboxId = 0 then
            exit;
        // Source identity survives loss of the referenced inbox row.
        TempLoadedTask."Source Type" := "PA Source Type"::Email;
        if not EmailInbox.Get(EmailInboxId) then
            exit;
        TempLoadedTask."Email From" := CopyStr(EmailInbox."Sender Address", 1, 250);
        TempLoadedTask."Sender Name" := CopyStr(EmailInbox."Sender Name", 1, 250);
        TempLoadedTask."Email Subject" := CopyStr(EmailInbox.Description, 1, 250);
        TempLoadedTask."Email External Id" := EmailInbox."External Message Id";
        TempLoadedTask."Received At" := EmailInbox."Received DateTime";
    end;

    local procedure TryGetEmailMessageId(var MessageId: Guid): Boolean
    var
        EmailInbox: Record "Email Inbox";
    begin
        if LoadedKey = 0 then
            exit(false);
        if LoadedIsV2 then begin
            if not EmailInbox.Get(EmailInboxId) then
                exit(false);
            MessageId := EmailInbox."Message Id";
        end else
            MessageId := LoadedEDocument."Mail Message Id";
        exit(not IsNullGuid(MessageId));
    end;

    local procedure PopulateAgentTaskStatus()
    var
        AgentTask: Record "Agent Task";
    begin
        if TempLoadedTask."Agent Task ID" = 0 then
            exit;
        if AgentTask.Get(TempLoadedTask."Agent Task ID") then begin
            TempLoadedTask."Agent Task Status" := AgentTask.Status;
            TempLoadedTask."Has Agent Task" := true;
        end;
    end;

    local procedure FindAgentTaskIdForExternalId(ExternalId: Text[2048]): BigInteger
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", ExternalId);
        if AgentTask.FindFirst() then
            exit(AgentTask.ID);
        exit(0);
    end;
}
