// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;
using System.Utilities;

// Represents a received source before admission creates an Agent Framework task.
// The source may later become the backing source of a Payables Agent Task, or remain rejected.
codeunit 3340 "PA Task Source"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = R;

    var
        LoadedStoredTask: Record "Payables Agent Task";
        DraftBasedSource: Codeunit "PA Draft Based Task Source";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
        LoadedVersion: Enum "PA Version";
        SourceNotFoundErr: Label 'The task source does not exist.';
        InvalidAgentTaskErr: Label 'A valid Agent Task ID is required.';
        AgentTaskAlreadyBoundErr: Label 'Agent task %1 is already bound to another Payables Agent source.', Comment = '%1 = Agent Task ID';
        SourceAlreadyBoundErr: Label 'The source is already bound to agent task %1.', Comment = '%1 = Agent Task ID';
        AcceptedSourceCannotBeRejectedErr: Label 'An accepted source cannot be rejected.';
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;

    internal procedure CreateFromPdf(FileName: Text; PdfInStream: InStream): Boolean
    var
        StoredTask: Record "Payables Agent Task";
    begin
        ClearLoaded();
        if PAV1V2Flag.GetVersion() = "PA Version"::V2 then begin
            StoredTask."File Name" := CopyStr(FileName, 1, MaxStrLen(StoredTask."File Name"));
            StoredTask."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
            StoredTask."Intake Status" := "PA Task Intake Status"::Received;
            StoredTask.Insert();
            exit(Load(StoredTask.SystemId));
        end;

        if not DraftBasedSource.CreateFromPdf(FileName, PdfInStream) then
            exit(false);
        LoadedVersion := "PA Version"::V1;
        exit(true);
    end;

    internal procedure Load(SourceId: Guid): Boolean
    var
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
        if not DraftBasedSource.Load(SourceId) then
            exit(false);
        LoadedVersion := "PA Version"::V1;
        exit(true);
    end;

    internal procedure LoadDraftBased(SourceId: Guid): Boolean
    begin
        ClearLoaded();
        if not DraftBasedSource.Load(SourceId) then
            exit(false);
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
        exit(DraftBasedSource.GetId());
    end;

    internal procedure GetVersion(): Enum "PA Version"
    begin
        RequireLoaded();
        exit(LoadedVersion);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."Agent Task ID");
        exit(DraftBasedSource.GetAgentTaskId());
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(CopyStr(LowerCase(Format(LoadedStoredTask.SystemId)).Replace('{', '').Replace('}', ''), 1, 2048));
        exit(DraftBasedSource.GetAgentTaskExternalId());
    end;

    internal procedure GetAgentTaskMessage(): Text
    var
        TaskMessageLbl: Label 'A new document has been received. Your task is to create a Purchase Invoice in Business Central.', Locked = true;
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(DraftBasedSource.GetAgentTaskMessage());
        exit(TaskMessageLbl);
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
        exit(DraftBasedSource.GetSourceType());
    end;

    internal procedure GetFileName(): Text
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."File Name");
        exit(DraftBasedSource.GetFileName());
    end;

    internal procedure HasPdf(): Boolean
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask."File Content".HasValue());
        exit(DraftBasedSource.HasPdf());
    end;

    internal procedure GetEmailFrom(): Text
    var
        EmailInbox: Record "Email Inbox";
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V1 then
            exit(DraftBasedSource.GetEmailFrom());
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
            exit(DraftBasedSource.GetEmailSubject());
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
            exit(DraftBasedSource.GetEmailExternalId());
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
            exit(DraftBasedSource.GetEmailReceivedAt());
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
        exit(DraftBasedSource.GetCreatedAt());
    end;

    internal procedure GetUpdatedAt(): DateTime
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.SystemModifiedAt);
        exit(DraftBasedSource.GetUpdatedAt());
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
        exit(DraftBasedSource.GetSourcePdf(TempBlob, FileName));
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
            exit(DraftBasedSource.TryGetEmailMessageId(MessageId));
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
        Clear(DraftBasedSource);
        LoadedVersion := "PA Version"::Unknown;
    end;
}
