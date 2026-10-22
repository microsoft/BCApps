// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Agents;
using System.Email;
using System.Utilities;

// Represents a received source before admission creates an Agent Framework task.
// The source may later become the backing source of a Payables Agent Task, or remain rejected.
codeunit 3340 "PA Task Source"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = R, tabledata "E-Document" = RM,
        tabledata "E-Doc. Data Storage" = R, tabledata "Email Inbox" = R;

    internal procedure CreateFromPdf(FileName: Text; PdfInStream: InStream): Boolean
    var
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
        EDocImport: Codeunit "E-Doc. Import";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        ClearLoaded();
        if PAV1V2Flag.GetVersion() = "PA Version"::V2 then begin
            StoredTask."File Name" := CopyStr(FileName, 1, MaxStrLen(StoredTask."File Name"));
            StoredTask."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
            StoredTask."Intake Status" := "PA Task Intake Status"::Received;
            StoredTask.Insert();
            exit(Load(StoredTask.SystemId));
        end;

        EDocImport.CreateFromType(EDocument, PADraftBasedSetup.GetOrCreateAgentEDocumentService(), "E-Doc. File Format"::PDF, FileName, PdfInStream);
        EDocument."Source Details" := CopyStr(FileName, 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
        exit(Load(EDocument.SystemId));
    end;

    internal procedure Load(SourceId: Guid): Boolean
    var
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
    begin
        ClearLoaded();
        if IsNullGuid(SourceId) then
            exit(false);
        if StoredTask.GetBySystemId(SourceId) then begin
            LoadedStoredTask := StoredTask;
            LoadedVersion := "PA Version"::V2;
            exit(true);
        end;
        if EDocument.GetBySystemId(SourceId) then begin
            LoadedEDocument := EDocument;
            LoadedVersion := "PA Version"::V1;
            exit(true);
        end;
        exit(false);
    end;

    internal procedure LoadDraftBased(EDocumentEntryNo: Integer): Boolean
    var
        EDocument: Record "E-Document";
    begin
        ClearLoaded();
        if not EDocument.Get(EDocumentEntryNo) then
            exit(false);
        LoadedEDocument := EDocument;
        LoadedVersion := "PA Version"::V1;
        exit(true);
    end;

    internal procedure Refresh()
    var
        SourceId: Guid;
    begin
        SourceId := GetId();
        if Load(SourceId) then;
    end;

    internal procedure GetId(): Guid
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.SystemId);
        exit(LoadedEDocument.SystemId);
    end;

    internal procedure GetVersion(): Enum "PA Version"
    begin
        RequireLoaded();
        exit(LoadedVersion);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    var
        AgentTask: Record "Agent Task";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."Agent Task ID");
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetRange("External ID", GetAgentTaskExternalId());
        if AgentTask.FindFirst() then
            exit(AgentTask.ID);
        exit(0);
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(CopyStr(LowerCase(Format(LoadedStoredTask.SystemId)).Replace('{', '').Replace('}', ''), 1, 2048));
        exit(Format(LoadedEDocument."Entry No"));
    end;

    internal procedure BindAgentTask(AgentTaskId: BigInteger)
    var
        StoredTask: Record "Payables Agent Task";
        OtherTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if AgentTaskId = 0 then
            Error(InvalidAgentTaskErr);
        if LoadedVersion = "PA Version"::V1 then
            exit;

        OtherTask.SetRange("Agent Task ID", AgentTaskId);
        OtherTask.SetFilter("Entry No.", '<>%1', LoadedStoredTask."Entry No.");
        if not OtherTask.IsEmpty() then
            Error(AgentTaskAlreadyBoundErr, AgentTaskId);

        if not StoredTask.Get(LoadedStoredTask."Entry No.") then
            Error(SourceNotFoundErr);
        if (StoredTask."Agent Task ID" <> 0) and (StoredTask."Agent Task ID" <> AgentTaskId) then
            Error(SourceAlreadyBoundErr, StoredTask."Agent Task ID");
        StoredTask."Agent Task ID" := AgentTaskId;
        StoredTask."Intake Status" := "PA Task Intake Status"::Accepted;
        Clear(StoredTask."Rejection Reason");
        StoredTask.Modify();
        LoadedStoredTask := StoredTask;
    end;

    internal procedure MarkRejected(Reason: Text)
    var
        StoredTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit;
        if not StoredTask.Get(LoadedStoredTask."Entry No.") then
            Error(SourceNotFoundErr);
        if StoredTask."Agent Task ID" <> 0 then
            Error(AcceptedSourceCannotBeRejectedErr);
        StoredTask."Intake Status" := "PA Task Intake Status"::Rejected;
        StoredTask."Rejection Reason" := CopyStr(Reason, 1, MaxStrLen(StoredTask."Rejection Reason"));
        StoredTask.Modify();
        LoadedStoredTask := StoredTask;
    end;

    internal procedure GetIntakeStatus(): Enum "PA Task Intake Status"
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then begin
            if GetAgentTaskId() <> 0 then
                exit("PA Task Intake Status"::Accepted);
            exit("PA Task Intake Status"::Received);
        end;
        exit(LoadedStoredTask."Intake Status");
    end;

    internal procedure GetRejectionReason(): Text
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."Rejection Reason");
        exit('');
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

    local procedure RequireLoaded()
    begin
        if LoadedVersion = "PA Version"::Unknown then
            Error(SourceNotFoundErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(LoadedStoredTask);
        Clear(LoadedEDocument);
        LoadedVersion := "PA Version"::Unknown;
    end;

    var
        LoadedStoredTask: Record "Payables Agent Task";
        LoadedEDocument: Record "E-Document";
        LoadedVersion: Enum "PA Version";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        SourceNotFoundErr: Label 'The task source does not exist.';
        InvalidAgentTaskErr: Label 'A valid Agent Task ID is required.';
        AgentTaskAlreadyBoundErr: Label 'Agent task %1 is already bound to another Payables Agent source.';
        SourceAlreadyBoundErr: Label 'The source is already bound to agent task %1.';
        AcceptedSourceCannotBeRejectedErr: Label 'An accepted source cannot be rejected.';
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;
}
