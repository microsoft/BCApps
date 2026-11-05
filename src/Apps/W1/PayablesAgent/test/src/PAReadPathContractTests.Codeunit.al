// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using System.Email;

codeunit 133737 "PA Read Path Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EnumerationRequiresOpen()
    var
        Collection: Codeunit "PA Work Item Collection";
        WorkItem: Codeunit "PA Work Item";
    begin
        asserterror Collection.Next(WorkItem);
        Check(StrPos(GetLastErrorText(), 'Open the work item collection') > 0, 'Source enumeration must require an explicit scope.');
    end;

    [Test]
    procedure RejectedCursorFiltersExhaustsAndReopens()
    var
        Collection: Codeunit "PA Work Item Collection";
        WorkItem: Codeunit "PA Work Item";
        RejectedId: Guid;
        ReceivedId: Guid;
        VisibleIds: List of [Guid];
    begin
        RejectedId := InsertWorkItem(true, 0);
        ReceivedId := InsertWorkItem(false, 0);
        Collection.OpenByState("PA Work Item State"::Rejected);
        while Collection.Next(WorkItem) do begin
            Check(not WorkItem.HasAgentTask(), 'Rejected work items must not pretend to have a framework task.');
            Check(not VisibleIds.Contains(WorkItem.GetId()), 'A source must be yielded only once.');
            VisibleIds.Add(WorkItem.GetId());
        end;
        Check(VisibleIds.Contains(RejectedId), 'Rejected sources must be visible.');
        Check(not VisibleIds.Contains(ReceivedId), 'Received sources must not be presented as rejected.');
        Check(not Collection.Next(WorkItem), 'An exhausted cursor must not restart.');
        asserterror WorkItem.GetId();
        Check(StrPos(GetLastErrorText(), 'does not exist') > 0, 'An exhausted cursor must clear the output handle.');

        Collection.OpenByState("PA Work Item State"::"Pending Processing");
        while Collection.Next(WorkItem) do
            Check(WorkItem.GetState() = "PA Work Item State"::"Pending Processing", 'A state scope must exclude rejected work items.');
        Collection.OpenAll();
        Check(Collection.Next(WorkItem), 'Reopening must reset the cursor.');
    end;

    [Test]
    procedure StateCountsResetOutputWithoutResettingCursor()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        Collection: Codeunit "PA Work Item Collection";
        WorkItem: Codeunit "PA Work Item";
        Counts: Dictionary of [Enum "PA Work Item State", Integer];
        FirstWorkItemId: Guid;
        Ordinal: Integer;
    begin
        InsertWorkItem(true, 0);
        InsertWorkItem(true, 0);
        InsertWorkItem(false, 0);
        Collection.OpenByState("PA Work Item State"::Rejected);
        Check(Collection.Next(WorkItem), 'The cursor must have a first rejected source.');
        FirstWorkItemId := WorkItem.GetId();
        Counts.Add("PA Work Item State"::Rejected, -1);
        Collection.GetCountsByState(Counts);
        foreach Ordinal in Enum::"PA Work Item State".Ordinals() do
            Check(Counts.ContainsKey(Enum::"PA Work Item State".FromInteger(Ordinal)), 'Every state must have a count, including zero.');
        StoredWorkItem.SetRange("Admission Status", "PA Work Item Admission Status"::Rejected);
        StoredWorkItem.SetRange("Agent Task ID", 0);
        Check(Counts.Get("PA Work Item State"::Rejected) = StoredWorkItem.Count(), 'Rejected counts must use the same source scope and replace stale output.');
        Check(Collection.Next(WorkItem), 'Counting must not exhaust the existing cursor.');
        Check(WorkItem.GetId() <> FirstWorkItemId, 'Counting must not rewind the existing cursor.');
    end;

    [Test]
    procedure EmailMetadataIsOneSnapshotUntilRefresh()
    var
        Inbox: Record "Email Inbox";
        WorkItem: Codeunit "PA Work Item";
        OtherWorkItemId: Guid;
    begin
        Inbox."Sender Address" := 'original@example.com';
        Inbox."Sender Name" := 'Original sender';
        Inbox.Description := 'Original subject';
        Inbox."External Message Id" := 'original-external-id';
        Inbox."Received DateTime" := CreateDateTime(DMY2Date(1, 1, 2026), 120000T);
        Inbox.Insert();
        Check(WorkItem.Load(InsertWorkItem(false, Inbox.Id)), 'The email source must load.');
        Check(WorkItem.GetEmailFrom() = 'original@example.com', 'The first getter must load metadata.');

        Inbox."Sender Address" := 'changed@example.com';
        Inbox."Sender Name" := 'Changed sender';
        Inbox.Description := 'Changed subject';
        Inbox."External Message Id" := 'changed-external-id';
        Inbox."Received DateTime" := CreateDateTime(DMY2Date(2, 1, 2026), 120000T);
        Inbox.Modify();
        Check(WorkItem.GetSenderName() = 'Original sender', 'Other getters must use the same metadata snapshot.');
        Check(WorkItem.GetEmailSubject() = 'Original subject', 'The subject must come from the snapshot.');
        Check(WorkItem.GetEmailExternalId() = 'original-external-id', 'The external ID must come from the snapshot.');
        Check(WorkItem.GetEmailReceivedAt() = CreateDateTime(DMY2Date(1, 1, 2026), 120000T), 'The received time must come from the snapshot.');

        WorkItem.Refresh();
        Check(WorkItem.GetEmailFrom() = 'changed@example.com', 'Refresh must invalidate cached metadata.');
        Check(WorkItem.GetSenderName() = 'Changed sender', 'Refreshed getters must agree.');
        OtherWorkItemId := InsertWorkItem(false, 0);
        Check(WorkItem.Load(OtherWorkItemId), 'The same handle must be reloadable for a different source.');
        Check(WorkItem.GetEmailFrom() = '', 'Reload must not leak the previous source metadata.');
        Check(WorkItem.GetEmailReceivedAt() = 0DT, 'Missing email metadata must retain its empty defaults.');
    end;

    [Test]
    procedure MissingEmailMetadataIsInvalidatedByRefresh()
    var
        Inbox: Record "Email Inbox";
        WorkItem: Codeunit "PA Work Item";
    begin
        Inbox."Sender Address" := 'restored@example.com';
        Inbox.Insert();
        Check(WorkItem.Load(InsertWorkItem(false, Inbox.Id)), 'The source must load.');
        Inbox.Delete();
        Check(WorkItem.GetEmailFrom() = '', 'A missing inbox row must return empty metadata.');
        Inbox.Insert();
        Check(WorkItem.GetEmailFrom() = '', 'A missing-row result must also be cached for this handle.');
        WorkItem.Refresh();
        Check(WorkItem.GetEmailFrom() = 'restored@example.com', 'Refresh must retry a previously missing inbox row.');
    end;

    [Test]
    procedure MissingFrameworkTaskCannotBeAssociated()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        WorkItem: Codeunit "PA Work Item";
        WorkItemId: Guid;
    begin
        WorkItemId := InsertWorkItem(false, 0);
        Check(WorkItem.Load(WorkItemId), 'The received source must load.');
        asserterror WorkItem.AssociateAgentTask(-1);
        Check(StrPos(GetLastErrorText(), 'existing Payables Agent task') > 0, 'Binding must reject a nonexistent framework task.');
        StoredWorkItem.GetBySystemId(WorkItemId);
        Check(StoredWorkItem."Agent Task ID" = 0, 'Rejected binding must not assign a task ID.');
        Check(StoredWorkItem."Admission Status" = "PA Work Item Admission Status"::Received, 'Rejected binding must not accept the source.');
    end;

    local procedure InsertWorkItem(Rejected: Boolean; EmailInboxId: BigInteger): Guid
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        WorkItem: Codeunit "PA Work Item";
    begin
        StoredWorkItem."Email Inbox Id" := EmailInboxId;
        StoredWorkItem.Insert();
        if Rejected then begin
            Check(WorkItem.Load(StoredWorkItem.SystemId), 'The received source must load.');
            WorkItem.MarkRejected('Rejected by policy');
        end;
        exit(StoredWorkItem.SystemId);
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
