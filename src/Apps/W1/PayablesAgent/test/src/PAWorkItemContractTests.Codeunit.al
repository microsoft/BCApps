// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.Purchases.Document;

codeunit 133738 "PA Work Item Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReceivedWorkItemHasIdentityWithoutFrameworkTask()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        WorkItem: Codeunit "PA Work Item";
        Id: Guid;
    begin
        // [SCENARIO] A received work item has an identity without an agent task, and keeps it through refresh and rejection.
        // [GIVEN] A stored V2 work item without an agent task.
        StoredWorkItem."File Name" := 'received.pdf';
        StoredWorkItem.Insert();
        Id := StoredWorkItem.SystemId;

        // [WHEN] It is loaded.
        Check(WorkItem.Load(Id), 'A received work item must load without a framework task.');

        // [THEN] Its ID is the record SystemId, it has no agent task, is not accepted and cannot register an outcome.
        Check(WorkItem.GetId() = Id, 'Identity must be the SystemId of the existing stored record.');
        Check(not WorkItem.HasAgentTask(), 'Receipt must not manufacture a runtime task.');
        Check(not WorkItem.IsAccepted(), 'Receipt must not imply acceptance.');
        Check(WorkItem.GetAgentTaskId() = 0, 'An unassociated work item must have no runtime task ID.');
        Check(not WorkItem.CanRegisterOutcome(), 'Receipt alone must not permit execution-only mutations.');

        // [WHEN] It is refreshed and then rejected.
        WorkItem.Refresh();

        // [THEN] It keeps its ID and the same handle shows the persisted rejection.
        Check(WorkItem.GetId() = Id, 'Refresh must retain work item identity independently of runtime identity.');
        WorkItem.MarkRejected('Rejected by policy');
        Check(WorkItem.GetId() = Id, 'Rejecting a receipt must not change its identity.');
        Check(WorkItem.GetState() = "PA Work Item State"::Rejected, 'The same handle must represent the rejected lifecycle stage.');
        Check(WorkItem.GetAdmissionStatus() = "PA Work Item Admission Status"::Rejected, 'Rejection must be persisted.');
    end;

    [Test]
    procedure FailedRuntimeLookupClearsPreviouslyLoadedReceipt()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        WorkItem: Codeunit "PA Work Item";
    begin
        // [SCENARIO] A failed lookup by agent task clears the previously loaded work item.
        // [GIVEN] A handle with a loaded work item.
        StoredWorkItem.Insert();
        Check(WorkItem.Load(StoredWorkItem.SystemId), 'The receipt must load.');

        // [WHEN] The handle looks up a nonexistent agent task.
        // [THEN] The lookup fails and the handle no longer holds the old work item.
        Check(not WorkItem.LoadByAgentTaskId(-1), 'A missing framework task must not resolve a work item.');
        asserterror WorkItem.GetId();
        Check(StrPos(GetLastErrorText(), 'work item does not exist') > 0, 'Failed lookup must clear the old handle.');
    end;

    [Test]
    procedure V1ReceiptKeepsExistingEDocumentGuidBeforeAdmission()
    var
        Fixtures: Codeunit "PA Test Fixtures";
        WorkItem: Codeunit "PA Work Item";
        Reloaded: Codeunit "PA Work Item";
        Id: Guid;
    begin
        // [SCENARIO] A V1 work item uses its E-Document SystemId as identity, before and without admission.
        // [GIVEN] A V1 email work item received without admission.
        Check(Fixtures.ReceiveEmail('receipt@example.com', 'V1 receipt', WorkItem), 'The V1 receipt must be created without admission.');

        // [THEN] It has an ID, no agent task, and is received rather than rejected.
        Id := WorkItem.GetId();
        Check(not IsNullGuid(Id), 'Existing E-Document SystemId must provide work item identity.');
        Check(not WorkItem.HasAgentTask(), 'A V1 received document need not have an agent task.');
        Check(WorkItem.GetAdmissionStatus() = "PA Work Item Admission Status"::Received, 'No task must not be reinterpreted as historical policy rejection.');

        // [WHEN] It is loaded again by its ID.
        Check(Reloaded.Load(Id), 'The public GUID lookup must resolve V1 work items too.');

        // [THEN] The same ID and email facts are returned.
        Check(Reloaded.GetId() = Id, 'Reloading must not allocate or copy a new V1 identity.');
        Check(Reloaded.GetEmailSubject() = 'V1 receipt', 'V1 source facts must survive the unified facade.');
    end;

    [Test]
    procedure PurchaseOutcomeQueriesAreStatelessAndClearFailedOutput()
    var
        Header: Record "Purchase Header";
        Other: Record "Purchase Header";
        TempFacts: Record "PA Purchase Outcome Facts" temporary;
        Outcomes: Codeunit "PA Purchase Outcomes";
        Id: RecordId;
    begin
        // [SCENARIO] Purchase outcome queries keep no state between documents and clear their output when they fail.
        // [GIVEN] A purchase invoice and a purchase credit memo.
        Header."Document Type" := Header."Document Type"::Invoice;
        Header."No." := NewDocumentNo();
        Header."Vendor Invoice No." := 'VENDOR-INV';
        Header."Buy-from Vendor No." := 'VENDOR-1';
        Header."Buy-from Vendor Name" := 'Invoice vendor';
        Header.Insert();
        Other."Document Type" := Other."Document Type"::"Credit Memo";
        Other."No." := NewDocumentNo();
        Other."Vendor Cr. Memo No." := 'VENDOR-CREDIT';
        Other."Buy-from Vendor Name" := 'Credit vendor';
        Other.Insert();

        // [WHEN] Facts are queried for the invoice and then for the credit memo.
        // [THEN] Each query returns only that document's facts.
        Outcomes.ValidateForRegistration(Header.RecordId());
        Check(Outcomes.TryGetFacts(Header.RecordId(), TempFacts), 'An existing invoice must resolve.');
        Check(TempFacts."Vendor Document No." = 'VENDOR-INV', 'Invoice facts must use its vendor invoice number.');
        Check(Outcomes.TryGetFacts(Other.RecordId(), TempFacts), 'The same stateless helper must resolve a different document.');
        Check(TempFacts."Document Type" = TempFacts."Document Type"::"Credit Memo", 'No previous document kind may be retained.');
        Check(TempFacts."Vendor Document No." = 'VENDOR-CREDIT', 'Credit memo facts must use its vendor credit memo number.');
        Check(TempFacts."Vendor No." = '', 'Output must not retain fields from a previous successful query.');

        // [WHEN] The credit memo is deleted and queried again.
        Id := Other.RecordId();
        Other.Delete();

        // [THEN] The query fails with cleared output, and registering it as an outcome fails.
        Check(not Outcomes.TryGetFacts(Id, TempFacts), 'Missing history must be a best-effort query failure.');
        Check(TempFacts."Document No." = '', 'Failed queries must clear output facts.');
        asserterror Outcomes.ValidateForRegistration(Id);
        Check(StrPos(GetLastErrorText(), 'existing purchase') > 0, 'Registration must reject missing documents rather than silently accepting query failure.');
    end;

    [Test]
    procedure TableRenamePreservesSchemaIdentities()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
    begin
        // [SCENARIO] Renaming the work item table kept the persisted table, field and enum IDs.
        // [WHEN] The table, field and admission status IDs are read.
        // [THEN] They match the previously persisted values.
        Check(Database::"Payables Agent Work Item" = 3327, 'The rename must retain the existing table ID.');
        Check(StoredWorkItem.FieldNo("Agent Task ID") = 4, 'The association field ID must remain unchanged.');
        Check(StoredWorkItem.FieldNo(Outcome) = 5, 'The outcome field ID must remain unchanged.');
        Check(StoredWorkItem.FieldNo("Admission Status") = 6, 'The renamed admission field ID must remain unchanged.');
        Check(StoredWorkItem.FieldNo("Extracted Text") = 41, 'The renamed extracted text field ID must remain unchanged.');
        Check("PA Work Item Admission Status"::Received.AsInteger() = 0, 'Received must retain its persisted ordinal.');
        Check("PA Work Item Admission Status"::Accepted.AsInteger() = 1, 'Accepted must retain its persisted ordinal.');
        Check("PA Work Item Admission Status"::Rejected.AsInteger() = 2, 'Rejected must retain its persisted ordinal.');
    end;

    [Test]
    procedure CommonVersionQueryClassifiesStoredAndMissingIdentity()
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        Versions: Codeunit "PA V1V2 Flag";
        Fixtures: Codeunit "PA Test Fixtures";
        DraftWorkItem: Codeunit "PA Work Item";
    begin
        // [SCENARIO] The version query reports the version a work item is stored in, or 0 when it does not exist.
        // [GIVEN] A V2 work item.
        StoredWorkItem.Insert();

        // [THEN] It reports version 2.
        Check(Versions.GetVersion(StoredWorkItem.SystemId) = 2, 'A V2 work item must report version 2 regardless of active selection.');

        // [GIVEN] A V1 work item.
        Check(Fixtures.ReceiveEmail('version@example.com', 'V1 version', DraftWorkItem), 'The V1 receipt must be created.');

        // [THEN] It reports version 1.
        Check(Versions.GetVersion(DraftWorkItem.GetId()) = 1, 'A historical V1 work item must still report version 1.');

        // [THEN] An unknown ID reports version 0.
        Check(Versions.GetVersion(CreateGuid()) = 0, 'A missing identity must report version 0 rather than the active version.');
    end;

    local procedure NewDocumentNo(): Code[20]
    begin
        exit(CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 20));
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
