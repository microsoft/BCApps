// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Email;
using System.Utilities;

codeunit 3341 "PA Work Item"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "Email Inbox" = R;

    #region State
    var
        LoadedWorkItem: Record "Payables Agent Work Item";
        LoadedAgentTask: Record "Agent Task";
        LoadedEmailInbox: Record "Email Inbox";
        DraftBasedWorkItem: Codeunit "PA Draft Based Work Item";
        IsLoaded: Boolean;
        IsV2: Boolean;
        EmailInboxLoaded: Boolean;
        EmailInboxAvailable: Boolean;
        WorkItemNotFoundErr: Label 'The work item does not exist.';
        AgentTaskRequiredErr: Label 'An existing Payables Agent task in the current company is required.';
        MultipleRecordsErr: Label 'Agent task %1 has more than one Payables Agent work item.', Comment = '%1 = Agent Task ID';
        AmbiguousVersionErr: Label 'Agent task %1 has both a version 1 and a version 2 work item.', Comment = '%1 = Agent Task ID';
        AmbiguousIdentityErr: Label 'Work item %1 is stored as both a version 1 and a version 2 work item.', Comment = '%1 = Work Item ID';
        AssociationMismatchErr: Label 'The agent task is associated with a different work item.';
        AlreadyAssociatedErr: Label 'The work item is already associated with agent task %1.', Comment = '%1 = Agent Task ID';
        AcceptedCannotBeRejectedErr: Label 'An accepted work item cannot be rejected.';
        ExtractionNotSupportedErr: Label 'Extracted text cannot be stored for this work item.';
        OutcomeNotSupportedErr: Label 'Outcome registration is not supported for this work item.';
        PdfMimeTypeTok: Label 'application/pdf', Locked = true;
    #endregion

    #region Loading and identity
    internal procedure Load(WorkItemId: Guid): Boolean
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        AgentTaskId: BigInteger;
        FoundV2Record: Boolean;
        FoundV1Record: Boolean;
    begin
        ClearLoaded();
        if IsNullGuid(WorkItemId) then
            exit(false);
        FoundV2Record := StoredWorkItem.GetBySystemId(WorkItemId);
        FoundV1Record := DraftBasedWorkItem.Load(WorkItemId);
        if FoundV2Record and FoundV1Record then
            Error(AmbiguousIdentityErr, WorkItemId);
        if not FoundV2Record and not FoundV1Record then
            exit(false);

        if FoundV2Record then
            AgentTaskId := StoredWorkItem."Agent Task ID"
        else
            AgentTaskId := DraftBasedWorkItem.FindAgentTaskId();
        if AgentTaskId <> 0 then
            if LoadByAgentTaskId(AgentTaskId) then begin
                if GetId() <> WorkItemId then
                    Error(AssociationMismatchErr);
                exit(true);
            end;

        // Receipt/history can still be loaded when no usable framework task exists.
        if FoundV2Record then
            LoadedWorkItem := StoredWorkItem
        else
            if not DraftBasedWorkItem.Load(WorkItemId) then
                exit(false);
        IsV2 := FoundV2Record;
        IsLoaded := true;
        exit(true);
    end;

    internal procedure LoadByAgentTaskId(AgentTaskId: BigInteger): Boolean
    var
        AgentTask: Record "Agent Task";
        StoredWorkItem: Record "Payables Agent Work Item";
        FoundV2Record: Boolean;
        FoundV1Record: Boolean;
    begin
        ClearLoaded();
        if not TryGetOwnedAgentTask(AgentTaskId, AgentTask) then
            exit(false);
        StoredWorkItem.SetRange("Agent Task ID", AgentTaskId);
        if StoredWorkItem.FindSet() then begin
            LoadedWorkItem := StoredWorkItem;
            FoundV2Record := true;
            if StoredWorkItem.Next() <> 0 then
                Error(MultipleRecordsErr, AgentTaskId);
        end;
        FoundV1Record := DraftBasedWorkItem.LoadForAgentTask(AgentTaskId);
        if FoundV2Record and FoundV1Record then
            Error(AmbiguousVersionErr, AgentTaskId);
        if not FoundV2Record and not FoundV1Record then begin
            ClearLoaded();
            exit(false);
        end;
        IsV2 := FoundV2Record;
        IsLoaded := true;
        LoadedAgentTask := AgentTask;
        exit(true);
    end;

    // Real runtime session only; billing relies on this never resolving a development simulation.
    internal procedure LoadCurrentSession(): Boolean
    var
        AgentAccess: Codeunit "PA Agent Access";
        AgentTaskId: BigInteger;
    begin
        ClearLoaded();
        if not AgentAccess.TryGetRuntimeAgentTaskId(AgentTaskId) then
            exit(false);
        exit(LoadByAgentTaskId(AgentTaskId));
    end;

    internal procedure Refresh()
    var
        WorkItemId: Guid;
    begin
        WorkItemId := GetId();
        if not Load(WorkItemId) then
            Error(WorkItemNotFoundErr);
    end;

    internal procedure GetId(): Guid
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem.SystemId);
        exit(DraftBasedWorkItem.GetId());
    end;
    #endregion

    #region Queries
    internal procedure GetAdmissionStatus(): Enum "PA Work Item Admission Status"
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem."Admission Status");
        if HasAgentTask() then
            exit("PA Work Item Admission Status"::Accepted);
        // V1 has no persisted rejection decision; do not infer it from today's policy.
        exit("PA Work Item Admission Status"::Received);
    end;

    internal procedure IsAccepted(): Boolean
    begin
        exit(GetAdmissionStatus() = "PA Work Item Admission Status"::Accepted);
    end;

    internal procedure HasAgentTask(): Boolean
    begin
        RequireLoaded();
        exit(LoadedAgentTask.ID <> 0);
    end;

    internal procedure GetAgentTaskId(): BigInteger
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem."Agent Task ID");
        exit(LoadedAgentTask.ID);
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetAgentTaskExternalId());
        exit(CopyStr(LowerCase(Format(GetId())).Replace('{', '').Replace('}', ''), 1, 2048));
    end;

    internal procedure GetTitle(): Text[150]
    begin
        RequireLoaded();
        exit(LoadedAgentTask.Title);
    end;

    internal procedure GetAgentTaskStatus(): Enum "Agent Task Status"
    begin
        RequireAgentTask();
        exit(LoadedAgentTask.Status);
    end;

    internal procedure GetState(): Enum "PA Work Item State"
    begin
        RequireLoaded();
        if GetAdmissionStatus() = "PA Work Item Admission Status"::Rejected then
            exit("PA Work Item State"::Rejected);
        if not HasAgentTask() then
            exit("PA Work Item State"::"Pending Processing");
        if not IsV2 then
            exit(DraftBasedWorkItem.GetState());
        if LoadedAgentTask."Needs Attention" then
            exit("PA Work Item State"::"Needs Attention");
        case LoadedAgentTask.Status of
            LoadedAgentTask.Status::Completed:
                exit("PA Work Item State"::Processed);
            LoadedAgentTask.Status::"Stopped by User", LoadedAgentTask.Status::"Stopped by System":
                exit("PA Work Item State"::"Needs Attention");
        end;
        exit("PA Work Item State"::"Pending Processing");
    end;

    internal procedure GetRejectionReason(): Text
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem."Rejection Reason");
        exit('');
    end;

    internal procedure GetSourceType(): Enum "PA Source Type"
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetSourceType());
        if LoadedWorkItem."Email Inbox Id" <> 0 then
            exit("PA Source Type"::Email);
        exit("PA Source Type"::Upload);
    end;

    internal procedure GetFileName(): Text
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem."File Name");
        exit(DraftBasedWorkItem.GetFileName());
    end;

    internal procedure HasPdf(): Boolean
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem."File Content".HasValue());
        exit(DraftBasedWorkItem.HasPdf());
    end;

    internal procedure GetSourcePdf(var TempBlob: Codeunit "Temp Blob"; var FileName: Text): Boolean
    begin
        Clear(TempBlob);
        Clear(FileName);
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetSourcePdf(TempBlob, FileName));
        if not HasPdf() then
            exit(false);
        LoadedWorkItem.GetFileContent(TempBlob);
        FileName := GetFileName();
        exit(true);
    end;

    internal procedure GetEmailFrom(): Text
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetEmailFrom());
        if TryLoadEmailInbox() then
            exit(LoadedEmailInbox."Sender Address");
        exit('');
    end;

    internal procedure GetSenderAddress(): Text[250]
    begin
        exit(CopyStr(GetEmailFrom(), 1, 250));
    end;

    internal procedure GetSenderName(): Text
    begin
        RequireLoaded();
        if IsV2 then
            if TryLoadEmailInbox() then
                exit(LoadedEmailInbox."Sender Name");
        exit('');
    end;

    internal procedure GetEmailSubject(): Text
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetEmailSubject());
        if TryLoadEmailInbox() then
            exit(LoadedEmailInbox.Description);
        exit('');
    end;

    internal procedure GetEmailExternalId(): Text
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetEmailExternalId());
        if TryLoadEmailInbox() then
            exit(LoadedEmailInbox."External Message Id");
        exit('');
    end;

    internal procedure GetEmailReceivedAt(): DateTime
    begin
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.GetEmailReceivedAt());
        if TryLoadEmailInbox() then
            exit(LoadedEmailInbox."Received DateTime");
        exit(0DT);
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

    internal procedure GetCreatedAt(): DateTime
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem.SystemCreatedAt);
        exit(DraftBasedWorkItem.GetCreatedAt());
    end;

    internal procedure GetUpdatedAt(): DateTime
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem.SystemModifiedAt);
        exit(DraftBasedWorkItem.GetUpdatedAt());
    end;

    internal procedure CanExtractText(): Boolean
    begin
        RequireLoaded();
        exit(HasAgentTask() and IsV2 and HasPdf());
    end;

    internal procedure CanRegisterOutcome(): Boolean
    begin
        RequireLoaded();
        exit(HasAgentTask() and IsV2);
    end;

    internal procedure GetExtractedText(): Text
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem.GetExtractedText());
        exit('');
    end;

    internal procedure GetOutcome(): RecordId
    begin
        RequireLoaded();
        if IsV2 then
            exit(LoadedWorkItem.Outcome);
        exit(DraftBasedWorkItem.GetOutcome());
    end;

    internal procedure IsResultRecord(Candidate: RecordId): Boolean
    begin
        RequireLoaded();
        if Candidate.TableNo = 0 then
            exit(false);
        if Candidate = GetOutcome() then
            exit(true);
        if not IsV2 then
            exit(DraftBasedWorkItem.IsStoredRecord(Candidate));
        exit(false);
    end;
    #endregion

    #region Persisted commands
    internal procedure CreateFromPdf(FileName: Text; PdfInStream: InStream): Boolean
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        Version: Codeunit "PA V1V2 Flag";
    begin
        ClearLoaded();
        if Version.IsV2Active() then begin
            StoredWorkItem."File Name" := CopyStr(FileName, 1, MaxStrLen(StoredWorkItem."File Name"));
            StoredWorkItem."File Content".ImportStream(PdfInStream, FileName, PdfMimeTypeTok);
            StoredWorkItem."Admission Status" := "PA Work Item Admission Status"::Received;
            StoredWorkItem.Insert();
            exit(Load(StoredWorkItem.SystemId));
        end;
        if not DraftBasedWorkItem.CreateFromPdf(FileName, PdfInStream) then
            exit(false);
        IsLoaded := true;
        exit(true);
    end;

    internal procedure AssociateAgentTask(AgentTaskId: BigInteger)
    var
        AgentTask: Record "Agent Task";
        StoredWorkItem: Record "Payables Agent Work Item";
        OtherWorkItem: Record "Payables Agent Work Item";
        ResolvedDraft: Codeunit "PA Draft Based Work Item";
    begin
        RequireLoaded();
        if not TryGetOwnedAgentTask(AgentTaskId, AgentTask) then
            Error(AgentTaskRequiredErr);
        if (GetAgentTaskId() <> 0) and (GetAgentTaskId() <> AgentTaskId) then
            Error(AlreadyAssociatedErr, GetAgentTaskId());
        if not IsV2 then begin
            if not ResolvedDraft.LoadForAgentTask(AgentTaskId) then
                Error(AssociationMismatchErr);
            if ResolvedDraft.GetId() <> GetId() then
                Error(AssociationMismatchErr);
            LoadedAgentTask := AgentTask;
            exit;
        end;

        if AgentTask."External ID" <> GetAgentTaskExternalId() then
            Error(AssociationMismatchErr);
        StoredWorkItem.ReadIsolation := IsolationLevel::UpdLock;
        if not StoredWorkItem.GetBySystemId(GetId()) then
            Error(WorkItemNotFoundErr);
        if (StoredWorkItem."Agent Task ID" <> 0) and (StoredWorkItem."Agent Task ID" <> AgentTaskId) then
            Error(AlreadyAssociatedErr, StoredWorkItem."Agent Task ID");
        OtherWorkItem.SetRange("Agent Task ID", AgentTaskId);
        OtherWorkItem.SetFilter("Entry No.", '<>%1', StoredWorkItem."Entry No.");
        if not OtherWorkItem.IsEmpty() then
            Error(AssociationMismatchErr);
        if ResolvedDraft.LoadForAgentTask(AgentTaskId) then
            Error(AmbiguousVersionErr, AgentTaskId);
        StoredWorkItem."Agent Task ID" := AgentTaskId;
        StoredWorkItem."Admission Status" := "PA Work Item Admission Status"::Accepted;
        Clear(StoredWorkItem."Rejection Reason");
        StoredWorkItem.Modify();
        LoadedWorkItem := StoredWorkItem;
        LoadedAgentTask := AgentTask;
    end;

    internal procedure MarkRejected(Reason: Text)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
    begin
        RequireLoaded();
        if IsAccepted() then
            Error(AcceptedCannotBeRejectedErr);
        if not IsV2 then
            exit; // Preserve V1: no persisted rejection field is introduced on E-Documents.
        StoredWorkItem.ReadIsolation := IsolationLevel::UpdLock;
        if not StoredWorkItem.GetBySystemId(GetId()) then
            Error(WorkItemNotFoundErr);
        if StoredWorkItem."Agent Task ID" <> 0 then
            Error(AcceptedCannotBeRejectedErr);
        StoredWorkItem."Admission Status" := "PA Work Item Admission Status"::Rejected;
        StoredWorkItem."Rejection Reason" := CopyStr(Reason, 1, MaxStrLen(StoredWorkItem."Rejection Reason"));
        StoredWorkItem.Modify();
        LoadedWorkItem := StoredWorkItem;
    end;

    internal procedure SetExtractedText(NewText: Text)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
    begin
        RequireAgentTask();
        if not IsV2 then
            Error(ExtractionNotSupportedErr);
        if not StoredWorkItem.GetBySystemId(GetId()) then
            Error(WorkItemNotFoundErr);
        StoredWorkItem.SetExtractedText(NewText);
#pragma warning disable AA0214
        StoredWorkItem.Modify();
#pragma warning restore AA0214
        Refresh();
    end;

    internal procedure RegisterOutcome(OutcomeId: RecordId)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        PurchaseOutcomes: Codeunit "PA Purchase Outcomes";
    begin
        if not CanRegisterOutcome() then
            Error(OutcomeNotSupportedErr);
        PurchaseOutcomes.ValidateForRegistration(OutcomeId);
        if not StoredWorkItem.GetBySystemId(GetId()) then
            Error(WorkItemNotFoundErr);
        StoredWorkItem.Outcome := OutcomeId;
        StoredWorkItem.Modify();
        Refresh();
    end;

    internal procedure ReplaceOutcomeReferences(PreviousOutcome: RecordId; NewOutcome: RecordId)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        DraftBasedReferences: Codeunit "PA Draft Based Work Item";
    begin
        if (PreviousOutcome.TableNo = 0) or (PreviousOutcome = NewOutcome) then
            exit;

        StoredWorkItem.SetRange(Outcome, PreviousOutcome);
        if not StoredWorkItem.IsEmpty() then
            StoredWorkItem.ModifyAll(Outcome, NewOutcome);
        if DraftBasedReferences.HasOutcomeReferences(PreviousOutcome) then
            DraftBasedReferences.ReplaceOutcomeReferences(PreviousOutcome, NewOutcome);
    end;
    #endregion

    #region Agent task validation
    local procedure TryGetOwnedAgentTask(AgentTaskId: BigInteger; var AgentTask: Record "Agent Task"): Boolean
    var
        OwningAgent: Record Agent;
        AgentAccess: Codeunit "PA Agent Access";
        IsOwned: Boolean;
    begin
        if AgentTaskId = 0 then
            exit(false);
        if not AgentTask.Get(AgentTaskId) then
            exit(false);
        if AgentTask."Company Name" <> CompanyName() then
            exit(false);
        if AgentAccess.TryGetRuntimeTaskOwnership(AgentTask, IsOwned) then
            exit(IsOwned);
        if not OwningAgent.Get(AgentTask."Agent User Security ID") then
            exit(false);
        exit(OwningAgent."Agent Metadata Provider" = "Agent Metadata Provider"::"Payables Agent");
    end;

    #endregion

    #region Email metadata cache
    local procedure TryGetEmailMessageId(var MessageId: Guid): Boolean
    begin
        Clear(MessageId);
        RequireLoaded();
        if not IsV2 then
            exit(DraftBasedWorkItem.TryGetEmailMessageId(MessageId));
        if not TryLoadEmailInbox() then
            exit(false);
        MessageId := LoadedEmailInbox."Message Id";
        exit(not IsNullGuid(MessageId));
    end;

    local procedure TryLoadEmailInbox(): Boolean
    begin
        if not EmailInboxLoaded then begin
            EmailInboxAvailable := LoadedEmailInbox.Get(LoadedWorkItem."Email Inbox Id");
            EmailInboxLoaded := true;
        end;
        exit(EmailInboxAvailable);
    end;

    #endregion

    #region Handle lifecycle guards and reset
    local procedure RequireLoaded()
    begin
        if not IsLoaded then
            Error(WorkItemNotFoundErr);
    end;

    local procedure RequireAgentTask()
    begin
        RequireLoaded();
        if not HasAgentTask() then
            Error(AgentTaskRequiredErr);
    end;

    local procedure ClearLoaded()
    begin
        Clear(LoadedWorkItem);
        Clear(LoadedAgentTask);
        Clear(LoadedEmailInbox);
        Clear(DraftBasedWorkItem);
        IsLoaded := false;
        IsV2 := false;
        EmailInboxLoaded := false;
        EmailInboxAvailable := false;
    end;
    #endregion
}
