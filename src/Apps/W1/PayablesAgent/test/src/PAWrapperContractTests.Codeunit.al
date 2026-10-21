// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Environment;

// Focused contract tests: no LLM, mailbox, agent user or posting setup is required.
codeunit 133724 "PA Wrapper Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ProjectionUsesOpaqueIdentityAndLocalRowOrdinal()
    var
        StoredTask: Record "Payables Agent Task";
        Data: Record "PA Detailed Task" temporary;
        Task: Codeunit "Payables Agent Task";
    begin
        CreateTask(StoredTask, Task);
        Task.GetRecord(Data);
        Check(Data."Source Type" = "PA Source Type"::Upload, 'A task without an email source must be an upload.');
        Check(not IsNullGuid(Data."Task Id"), 'A logical task identity is required.');
        Check(Data."Entry No." = 0, 'The projection must not expose the storage entry number.');
        Check(IsNullGuid(Data.SystemId), 'The projection must not copy storage system fields.');
        Check(Task.Load(Data."Task Id"), 'The opaque identity must load the same task.');
    end;

    [Test]
    procedure MissingInboxRowDoesNotTurnAnEmailIntoAnUpload()
    var
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
    begin
        StoredTask."Email Inbox Id" := -1; // Represents a source inbox row that no longer exists.
        StoredTask.Insert();
        Check(Task.Load(StoredTask.SystemId), 'The task must remain loadable after its email disappears.');
        Check(Task.GetSourceType() = "PA Source Type"::Email, 'Loss of source content must not change source identity.');
        Check(Task.GetSourceEmailBody() = '', 'Unavailable source content must be handled without backing errors.');
    end;

    [Test]
    procedure DraftBasedUploadRemainsUploadAndMatchesOnlyItsOwnResult()
    var
        Document: Record "E-Document";
        OtherDocument: Record "E-Document";
        Task: Codeunit "Payables Agent Task";
    begin
        Document."Source Details" := 'fixture.pdf';
        Document.Insert();
        OtherDocument.Insert();
        Check(Task.Load(Document.SystemId), 'The draft-based task must load through opaque identity.');
        Check(Task.GetSourceType() = "PA Source Type"::Upload, 'A draft-based upload must not be treated as email.');
        Check(Task.IsResultRecord(Document.RecordId()), 'The source document is the draft-based review result.');
        Check(not Task.IsResultRecord(OtherDocument.RecordId()), 'A different source of the same table is not this task result.');
    end;

    [Test]
    procedure RefreshPreservesTemporaryProjectionRowIdentity()
    var
        StoredTask: Record "Payables Agent Task";
        Data: Record "PA Detailed Task" temporary;
        Task: Codeunit "Payables Agent Task";
        RowSystemId: Guid;
    begin
        CreateTask(StoredTask, Task);
        Task.GetRecord(Data);
        Data."Entry No." := 1;
        Data.Insert();
        RowSystemId := Data.SystemId;
        Task.GetRecord(Data);
        Data."Entry No." := 1;
        Data.Modify();
        Check(Data.SystemId = RowSystemId, 'Refreshing a projection must preserve its own row identity.');
    end;

    [Test]
    procedure AcceptsAllFiveOutcomeKinds()
    var
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
        Outcome: RecordId;
    begin
        CreateTask(StoredTask, Task);
        Outcome := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask.SystemId, Outcome);
        Outcome := CreatePurchaseDocument("Purchase Document Type"::Order);
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask.SystemId, Outcome);
        Outcome := CreatePurchaseDocument("Purchase Document Type"::"Credit Memo");
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask.SystemId, Outcome);
        Outcome := CreatePostedInvoice();
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask.SystemId, Outcome);
        Outcome := CreatePostedCreditMemo();
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask.SystemId, Outcome);
    end;

    [Test]
    procedure RejectsUnsupportedOutcomeType()
    var
        StoredTask: Record "Payables Agent Task";
        Company: Record Company;
        Task: Codeunit "Payables Agent Task";
    begin
        CreateTask(StoredTask, Task);
        Company.Get(CompanyName());
        asserterror Task.RegisterOutcome(Company.RecordId());
        Check(StrPos(GetLastErrorText(), 'outcome must be an existing') > 0, 'The entity must reject unsupported outcome types.');
    end;

    [Test]
    procedure RejectsMissingOutcomeAndPurchaseQuotes()
    var
        StoredTask: Record "Payables Agent Task";
        MissingInvoice: Record "Purchase Header";
        Task: Codeunit "Payables Agent Task";
        Quote: RecordId;
    begin
        CreateTask(StoredTask, Task);
        MissingInvoice."Document Type" := MissingInvoice."Document Type"::Invoice;
        MissingInvoice."No." := NewDocumentNo();
        asserterror Task.RegisterOutcome(MissingInvoice.RecordId());
        Check(StrPos(GetLastErrorText(), 'outcome must be an existing') > 0, 'A missing record must be rejected.');
        Quote := CreatePurchaseDocument("Purchase Document Type"::Quote);
        asserterror Task.RegisterOutcome(Quote);
        Check(StrPos(GetLastErrorText(), 'outcome must be an existing') > 0, 'Unsupported purchase document kinds must be rejected.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure StaleTextUpdatePreservesOutcomeAndOtherFields()
    var
        StoredTask: Record "Payables Agent Task";
        Data: Record "PA Detailed Task" temporary;
        StaleTask: Codeunit "Payables Agent Task";
        OtherTask: Codeunit "Payables Agent Task";
        Outcome: RecordId;
    begin
        CreateTask(StoredTask, StaleTask);
        Check(OtherTask.Load(StoredTask.SystemId), 'The second instance must load.');
        Outcome := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        OtherTask.RegisterOutcome(Outcome);
        StoredTask.Get(StoredTask."Entry No.");
        StoredTask."File Name" := 'changed-by-another-writer.pdf';
        StoredTask.Modify();
        StaleTask.SetSourceText('extracted text');
        StaleTask.GetRecord(Data);
        Check(Data.Outcome = Outcome, 'A text update must preserve a newer outcome.');
        Check(Data."File Name" = 'changed-by-another-writer.pdf', 'A text update must preserve unrelated changes.');
        Check(StaleTask.GetSourceText() = 'extracted text', 'The intended field must be updated.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure PostingReplacementIsConditionalAndIdempotent()
    var
        StoredA: Record "Payables Agent Task";
        StoredB: Record "Payables Agent Task";
        StoredC: Record "Payables Agent Task";
        TaskA: Codeunit "Payables Agent Task";
        TaskB: Codeunit "Payables Agent Task";
        TaskC: Codeunit "Payables Agent Task";
        Original: RecordId;
        Different: RecordId;
        Posted: RecordId;
    begin
        CreateTask(StoredA, TaskA);
        CreateTask(StoredB, TaskB);
        CreateTask(StoredC, TaskC);
        Original := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Different := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Posted := CreatePostedInvoice();
        TaskA.RegisterOutcome(Original);
        TaskB.RegisterOutcome(Original);
        TaskC.RegisterOutcome(Original);
        TaskC.RegisterOutcome(Different); // Reassigned after the original reference was observed.
        TaskA.ReplaceOutcomeReferences(Original, Posted);
        CheckOutcome(StoredA.SystemId, Posted);
        CheckOutcome(StoredB.SystemId, Posted);
        CheckOutcome(StoredC.SystemId, Different);
        TaskA.ReplaceOutcomeReferences(Original, CreatePostedInvoice());
        CheckOutcome(StoredA.SystemId, Posted);
        CheckOutcome(StoredB.SystemId, Posted);
        CheckOutcome(StoredC.SystemId, Different);
        StoredA.Get(StoredA."Entry No.");
        Check(StoredA."Completed At" = 0DT, 'Posting must not implicitly complete a task.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure PostingHandlerSkipsPreviewAndOrders()
    var
        StoredTask: Record "Payables Agent Task";
        Header: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
        Task: Codeunit "Payables Agent Task";
        Posting: Codeunit "PA Task Posting";
        Original: RecordId;
    begin
        CreateTask(StoredTask, Task);
        Original := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Header.Get(Original);
        PostedInvoice.Get(CreatePostedInvoice());
        Task.RegisterOutcome(Original);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, true);
        CheckOutcome(StoredTask.SystemId, Original);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredTask.SystemId, PostedInvoice.RecordId());
        Original := CreatePurchaseDocument("Purchase Document Type"::Order);
        Header.Get(Original);
        Task.RegisterOutcome(Original);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredTask.SystemId, Original);
    end;

    [Test]
    procedure CreditMemoReplacementAcceptsPostedReference()
    var
        StoredTask: Record "Payables Agent Task";
        Header: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
        Task: Codeunit "Payables Agent Task";
        Posting: Codeunit "PA Task Posting";
        Original: RecordId;
        Posted: RecordId;
    begin
        CreateTask(StoredTask, Task);
        Original := CreatePurchaseDocument("Purchase Document Type"::"Credit Memo");
        Posted := CreatePostedCreditMemo();
        Task.RegisterOutcome(Original);
        Header.Get(Original);
        PostedCreditMemo.Get(Posted);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredTask.SystemId, Posted);
    end;

    [Test]
    procedure EmptyReplacementSourceCannotMatchUnassignedTasks()
    var
        Task: Codeunit "Payables Agent Task";
        EmptyOutcome: RecordId;
    begin
        asserterror Task.ReplaceOutcomeReferences(EmptyOutcome, CreatePostedInvoice());
        Check(StrPos(GetLastErrorText(), 'existing outcome reference is required') > 0, 'An empty old reference must be rejected.');
    end;

    [Test]
    procedure SetupProposalDoesNotPersistUntilApplied()
    var
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
        BeforeMonitoring: Boolean;
    begin
        Proposal.GetSetup();
        BeforeMonitoring := Proposal.GetMonitorOutlook();
        Proposal.SetMonitorOutlook(not BeforeMonitoring);
        Stored.GetSetup();
        Check(Stored.GetMonitorOutlook() = BeforeMonitoring, 'Editing a proposal must not persist it.');
        Proposal.PrepareForApply(false);
        Check(not Proposal.GetMonitorOutlook(), 'Deactivation must normalize the proposed monitoring flag.');
    end;

    [Test]
    procedure DisabledSetupCannotPersistMonitoringEnabled()
    var
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);
        Stored.GetSetup();
        Check(not Stored.GetMonitorOutlook(), 'A disabled configuration cannot persist monitoring on.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure DeactivationStopsBackingImporter()
    var
        Service: Record "E-Document Service";
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        if not Service.Get('AGENT') then begin
            Service.Code := 'AGENT';
            Service.Insert();
        end;
        // Seed configured state without scheduling a real background task.
        Service."Auto Import" := true;
        Clear(Service."Import Recurrent Job Id");
        Service.Modify();
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);
        Stored.GetSetup();
        Service.Get('AGENT');
        Check(not Stored.GetMonitorOutlook(), 'Deactivation must persist monitoring off.');
        Check(not Service."Auto Import", 'Deactivation must also turn the backing importer off.');
    end;

    [Test]
    procedure UnsupportedOrIncompleteMonitoringCannotBeApplied()
    var
        Proposal: Codeunit "PA Setup";
        PageRecord: Record "Payables Agent Setup" temporary;
    begin
        Proposal.GetSetup();
        PageRecord := Proposal.GetPageRecord();
        PageRecord."Monitor Outlook" := true;
        Clear(PageRecord."Email Account Id");
        PageRecord."Email Review Policy" := "PA Email Review Policy"::Always;
        Proposal.SetPageRecord(PageRecord);
        // V1 rejects the absent mailbox; a v2 build must reject monitoring itself before any writes.
        asserterror Proposal.ApplySetup(true);
        Check((StrPos(GetLastErrorText(), 'Select a mailbox') > 0) or
            (StrPos(GetLastErrorText(), 'not available for this version') > 0), 'The proposal must be rejected before application.');
    end;

    [Test]
    procedure MonitoringCannotBeAppliedWithoutEnabledAgent()
    var
        Proposal: Codeunit "PA Setup";
        PageRecord: Record "Payables Agent Setup" temporary;
    begin
        Proposal.GetSetup();
        PageRecord := Proposal.GetPageRecord();
        PageRecord."Monitor Outlook" := true;
        PageRecord."Email Account Id" := CreateGuid();
        PageRecord."Email Monitoring Consent" := true;
        PageRecord."Email Review Policy" := "PA Email Review Policy"::Always;
        PageRecord."User Security Id" := CreateGuid(); // No such runtime agent.
        Proposal.SetPageRecord(PageRecord);
        asserterror Proposal.ApplySetup(true);
        Check((StrPos(GetLastErrorText(), 'requires an enabled Payables Agent') > 0) or
            (StrPos(GetLastErrorText(), 'not available for this version') > 0), 'The wrapper must not trust Enabling=true without an enabled agent.');
    end;

    local procedure CreateTask(var StoredTask: Record "Payables Agent Task"; var Task: Codeunit "Payables Agent Task")
    begin
        StoredTask.Init();
        StoredTask."Entry No." := 0;
        StoredTask."File Name" := 'fixture.pdf';
        StoredTask.Insert();
        Check(Task.Load(StoredTask.SystemId), 'The fixture must load through the shared contract.');
    end;

    local procedure CheckOutcome(TaskId: Guid; Expected: RecordId)
    var
        Data: Record "PA Detailed Task" temporary;
        Task: Codeunit "Payables Agent Task";
    begin
        Check(Task.Load(TaskId), 'The task must remain loadable.');
        Task.GetRecord(Data);
        Check(Data.Outcome = Expected, 'The persisted outcome is incorrect.');
    end;

    local procedure CreatePurchaseDocument(DocumentType: Enum "Purchase Document Type"): RecordId
    var
        Header: Record "Purchase Header";
    begin
        Header."Document Type" := DocumentType;
        Header."No." := NewDocumentNo();
        Header.Insert();
        exit(Header.RecordId());
    end;

    local procedure CreatePostedInvoice(): RecordId
    var
        Header: Record "Purch. Inv. Header";
    begin
        Header."No." := NewDocumentNo();
        Header.Insert();
        exit(Header.RecordId());
    end;

    local procedure CreatePostedCreditMemo(): RecordId
    var
        Header: Record "Purch. Cr. Memo Hdr.";
    begin
        Header."No." := NewDocumentNo();
        Header.Insert();
        exit(Header.RecordId());
    end;

    local procedure NewDocumentNo(): Code[20]
    begin
        exit(CopyStr(Format(CreateGuid()).Replace('{', '').Replace('}', '').Replace('-', ''), 1, 20));
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
