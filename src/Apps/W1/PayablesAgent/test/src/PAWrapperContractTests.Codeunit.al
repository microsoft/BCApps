// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Agents;
using System.Environment;
using System.Utilities;

// Focused contract tests: no LLM, mailbox, agent user or posting setup is required.
codeunit 133735 "PA Wrapper Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LoadsByAgentFrameworkTaskIdentity()
    var
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
    begin
        CreateTask(StoredTask, Task);
        StoredTask.Get(StoredTask."Entry No.");
        Check(Task.GetCreatedAt() = StoredTask.SystemCreatedAt, 'Creation time must come from the platform audit field.');
        Check(Task.GetUpdatedAt() = StoredTask.SystemModifiedAt, 'Update time must come from the platform audit field.');
        Check(Task.GetSourceType() = "PA Source Type"::Upload, 'A task without an email source must be an upload.');
        Check(Task.GetVersion() = "PA Version"::V2, 'The backing record must identify a v2 task.');
        Check(Task.Load(StoredTask."Agent Task ID"), 'The Agent Framework task identity must load the same task.');
    end;

    [Test]
    procedure TaskBasedDiagnosticsNormalizeTheRegisteredPurchaseInvoice()
    var
        StoredTask: Record "Payables Agent Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Task: Codeunit "Payables Agent Task";
        Fixtures: Codeunit "PA Test Fixtures";
        Diagnostics, Header, PurchaseInvoice : JsonObject;
        Errors, Lines : JsonArray;
    begin
        CreateTask(StoredTask, Task);
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."No." := NewDocumentNo();
        PurchaseHeader."Vendor Invoice No." := 'FIXTURE-INV';
        PurchaseHeader.Insert();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Description := 'Fixture line';
        PurchaseLine.Quantity := 2;
        PurchaseLine."Direct Unit Cost" := 10;
        PurchaseLine."Line Amount" := 20;
        PurchaseLine."Amount Including VAT" := 25;
        PurchaseLine."VAT %" := 25;
        PurchaseLine.Insert();
        Task.RegisterOutcome(PurchaseHeader.RecordId());

        Check(Fixtures.GetTaskDiagnosticEvidence(Task.GetAgentTaskId(), Diagnostics), 'Diagnostics must be available for the Payables Agent task.');
        Check(GetJsonText(Diagnostics, 'paVersion') = 'V2', 'Diagnostics must identify the task-based version.');
        Check(GetJsonText(Diagnostics, 'outcomeStatus') = 'InvoiceCreated', 'A registered purchase invoice must be classified as created.');
        PurchaseInvoice := GetJsonObject(Diagnostics, 'purchaseInvoice');
        Header := GetJsonObject(PurchaseInvoice, 'header');
        Check(GetJsonText(Header, 'number') = PurchaseHeader."No.", 'The normalized header must identify the purchase invoice.');
        Lines := GetJsonArray(PurchaseInvoice, 'lines');
        Check(Lines.Count() = 1, 'The purchase invoice line must be included in normalized diagnostics.');
        Errors := GetJsonArray(Diagnostics, 'errors');
        Check(Errors.Count() = 0, 'The registered purchase invoice must not produce diagnostic errors.');
    end;

    [Test]
    procedure MissingInboxRowDoesNotTurnAnEmailIntoAnUpload()
    var
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
    begin
        StoredTask."Email Inbox Id" := -1; // Represents a source inbox row that no longer exists.
        CreateTask(StoredTask, Task);
        Check(Task.Load(StoredTask."Agent Task ID"), 'The task must remain loadable after its email disappears.');
        Check(Task.GetSourceType() = "PA Source Type"::Email, 'Loss of source content must not change source identity.');
        Check(Task.GetSourceEmailBody() = '', 'Unavailable source content must be handled without backing errors.');
    end;

    [Test]
    procedure RefreshReloadsBackingWithoutChangingIdentity()
    var
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
        AgentTaskId: BigInteger;
    begin
        CreateTask(StoredTask, Task);
        AgentTaskId := Task.GetAgentTaskId();
        StoredTask.Get(StoredTask."Entry No.");
        StoredTask."File Name" := 'changed.pdf';
        StoredTask.Modify();
        Task.Refresh();
        Check(Task.GetAgentTaskId() = AgentTaskId, 'Refresh must preserve the Agent Framework task identity.');
        Check(Task.GetFileName() = 'changed.pdf', 'Refresh must reload the backing record.');
    end;

    [Test]
    procedure RejectedSourceRemainsVisibleWithoutAgentTask()
    var
        StoredTask: Record "Payables Agent Task";
        Collection: Codeunit "PA Task Collection";
        Source: Codeunit "PA Task Source";
        RejectedSourceIds: List of [Guid];
    begin
        StoredTask."File Name" := 'rejected.pdf';
        StoredTask.Insert();
        Check(Source.Load(StoredTask.SystemId), 'The received source must load before admission.');

        Source.MarkRejected('Rejected by policy');

        StoredTask.Get(StoredTask."Entry No.");
        Check(StoredTask."Agent Task ID" = 0, 'Rejection must not create or bind an Agent Framework task.');
        Check(StoredTask."Intake Status" = "PA Task Intake Status"::Rejected, 'The source must persist its rejected status.');
        Check(StoredTask."Rejection Reason" = 'Rejected by policy', 'The source must persist its rejection reason.');
        Collection.GetRejectedSourceIds(RejectedSourceIds);
        Check(RejectedSourceIds.Contains(StoredTask.SystemId), 'The rejected source must remain available to supervision.');
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
        CheckOutcome(StoredTask."Agent Task ID", Outcome);
        Outcome := CreatePurchaseDocument("Purchase Document Type"::Order);
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask."Agent Task ID", Outcome);
        Outcome := CreatePurchaseDocument("Purchase Document Type"::"Credit Memo");
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask."Agent Task ID", Outcome);
        Outcome := CreatePostedInvoice();
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask."Agent Task ID", Outcome);
        Outcome := CreatePostedCreditMemo();
        Task.RegisterOutcome(Outcome);
        CheckOutcome(StoredTask."Agent Task ID", Outcome);
    end;

    [Test]
    procedure RegistrationSetsTitleAndAttachesPdfOnlyOncePerTaskAndOutcome()
    var
        StoredTask: Record "Payables Agent Task";
        AgentTask: Record "Agent Task";
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        DocumentAttachment: Record "Document Attachment";
        Task: Codeunit "Payables Agent Task";
        Pdf: Codeunit "Temp Blob";
        OutcomeRef: RecordRef;
        PdfOut: OutStream;
        PdfIn: InStream;
    begin
        CreateTask(StoredTask, Task);
        Pdf.CreateOutStream(PdfOut);
        PdfOut.WriteText('PDF fixture');
        Pdf.CreateInStream(PdfIn);
        StoredTask."File Content".ImportStream(PdfIn, StoredTask."File Name", 'application/pdf');
        StoredTask.Modify();
        Task.Refresh();

        PurchaseHeader.Get(CreatePurchaseDocument("Purchase Document Type"::Invoice));
        PurchaseHeader."Vendor Invoice No." := 'SUPPLIER-123';
        PurchaseHeader."Buy-from Vendor Name" := 'Example Vendor';
        PurchaseHeader.Modify();
        Task.RegisterOutcome(PurchaseHeader.RecordId());
        AgentTask.Get(StoredTask."Agent Task ID");
        Check(AgentTask.Title = 'Invoice SUPPLIER-123 from Example Vendor', 'Registration must update the framework task title.');

        OutcomeRef.Get(PurchaseHeader.RecordId());
        DocumentAttachment.InitFieldsFromRecRef(OutcomeRef);
        DocumentAttachment.SetRange("Table ID", DocumentAttachment."Table ID");
        DocumentAttachment.SetRange("No.", DocumentAttachment."No.");
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type");
        Check(DocumentAttachment.Count() = 1, 'The source PDF must be attached to the invoice.');
        Task.RegisterOutcome(PurchaseHeader.RecordId());
        Check(DocumentAttachment.Count() = 1, 'Re-registering the same outcome must not duplicate the PDF.');

        PostedInvoice.Get(CreatePostedInvoice());
        Task.RegisterOutcome(PostedInvoice.RecordId());
        Clear(DocumentAttachment);
        OutcomeRef.Close();
        OutcomeRef.Get(PostedInvoice.RecordId());
        DocumentAttachment.InitFieldsFromRecRef(OutcomeRef);
        DocumentAttachment.SetRange("Table ID", DocumentAttachment."Table ID");
        DocumentAttachment.SetRange("No.", DocumentAttachment."No.");
        Check(DocumentAttachment.Count() = 1, 'The source PDF must also attach to a directly registered posted invoice.');
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
        StaleTask: Codeunit "Payables Agent Task";
        OtherTask: Codeunit "Payables Agent Task";
        Outcome: RecordId;
    begin
        CreateTask(StoredTask, StaleTask);
        Check(OtherTask.Load(StoredTask."Agent Task ID"), 'The second instance must load.');
        Outcome := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        OtherTask.RegisterOutcome(Outcome);
        StoredTask.Get(StoredTask."Entry No.");
        StoredTask."File Name" := 'changed-by-another-writer.pdf';
        StoredTask.Modify();
        StaleTask.SetSourceText('extracted text');
        Check(StaleTask.GetOutcome() = Outcome, 'A text update must preserve a newer outcome.');
        Check(StaleTask.GetFileName() = 'changed-by-another-writer.pdf', 'A text update must preserve unrelated changes.');
        Check(StaleTask.GetSourceText() = 'extracted text', 'The intended field must be updated.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure PostingReplacementIsConditionalAndIdempotent()
    var
        StoredA: Record "Payables Agent Task";
        StoredB: Record "Payables Agent Task";
        StoredC: Record "Payables Agent Task";
        Header: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
        TaskA: Codeunit "Payables Agent Task";
        TaskB: Codeunit "Payables Agent Task";
        TaskC: Codeunit "Payables Agent Task";
        Posting: Codeunit "PA Task Posting";
        Original: RecordId;
        Different: RecordId;
        Posted: RecordId;
    begin
        CreateTask(StoredA, TaskA);
        CreateTask(StoredB, TaskB);
        CreateTask(StoredC, TaskC);
        Original := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Different := CreatePurchaseDocument("Purchase Document Type"::Invoice);
        Header.Get(Original);
        PostedInvoice.Get(CreatePostedInvoice());
        Posted := PostedInvoice.RecordId();
        TaskA.RegisterOutcome(Original);
        TaskB.RegisterOutcome(Original);
        TaskC.RegisterOutcome(Original);
        TaskC.RegisterOutcome(Different); // Reassigned after the original reference was observed.
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredA."Agent Task ID", Posted);
        CheckOutcome(StoredB."Agent Task ID", Posted);
        CheckOutcome(StoredC."Agent Task ID", Different);
        PostedInvoice.Get(CreatePostedInvoice());
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredA."Agent Task ID", Posted);
        CheckOutcome(StoredB."Agent Task ID", Posted);
        CheckOutcome(StoredC."Agent Task ID", Different);
        TaskA.Refresh();
        Check(TaskA.GetState() = "PA Task State"::"Pending Processing", 'Posting or an audit timestamp update must not imply task completion.');
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
        CheckOutcome(StoredTask."Agent Task ID", Original);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredTask."Agent Task ID", PostedInvoice.RecordId());
        Original := CreatePurchaseDocument("Purchase Document Type"::Order);
        Header.Get(Original);
        Task.RegisterOutcome(Original);
        Posting.FollowPostedOutcome(Header, PostedInvoice, PostedCreditMemo, false);
        CheckOutcome(StoredTask."Agent Task ID", Original);
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
        CheckOutcome(StoredTask."Agent Task ID", Posted);
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
    procedure UnsupportedOrIncompleteMonitoringCannotBeApplied()
    var
        Proposal: Codeunit "PA Setup";
        MissingAccountId: Guid;
    begin
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.SetMailboxSelection(MissingAccountId, '', '');
        Proposal.SetEmailReviewPolicy("PA Email Review Policy"::Always);
        // V1 rejects the absent mailbox; a v2 build must reject monitoring itself before any writes.
        asserterror Proposal.ApplySetup(true);
        Check((StrPos(GetLastErrorText(), 'Select a mailbox') > 0) or
            (StrPos(GetLastErrorText(), 'not available for this version') > 0), 'The proposal must be rejected before application.');
    end;

    [Test]
    procedure MonitoringCannotBeAppliedWithoutEnabledAgent()
    var
        Proposal: Codeunit "PA Setup";
    begin
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.SetMailboxSelection(CreateGuid(), '', '');
        Proposal.SetEmailMonitoringConsent(true);
        Proposal.SetEmailReviewPolicy("PA Email Review Policy"::Always);
        Proposal.SetUserSecurityId(CreateGuid()); // No such runtime agent.
        asserterror Proposal.ApplySetup(true);
        Check((StrPos(GetLastErrorText(), 'requires an enabled Payables Agent') > 0) or
            (StrPos(GetLastErrorText(), 'not available for this version') > 0), 'The wrapper must not trust Enabling=true without an enabled agent.');
    end;

    [Test]
    procedure InstructionSelectionAndFingerprintResolveWithoutSecrets()
    var
        Setup: Codeunit "PA Setup";
        Instructions: Codeunit "PA Agent Instructions";
        Classic: Text;
        AgentDriven: Text;
        Fingerprint: Text;
    begin
        Classic := Setup.GetAgentInstructionsResource(false);
        AgentDriven := Setup.GetAgentInstructionsResource(true);
        if Classic = AgentDriven then
            Check(Classic = 'Prompts/PayablesAgent-AgentInstructions-V2.md', 'V2 must select its prompt independently of the v1 line-matching treatment.')
        else begin
            Check(Classic = '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', 'The classic resource must remain available.');
            Check(AgentDriven = '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', 'The agent-driven resource must remain available.');
        end;
        Fingerprint := Instructions.GetInstructionsConfigHash();
        Check(StrLen(Fingerprint) = 64, 'The selected prompt must produce a SHA256 fingerprint.');
        Check(Fingerprint = Instructions.GetInstructionsConfigHash(), 'An unchanged selected prompt must have a stable fingerprint.');
    end;

    local procedure CreateTask(var StoredTask: Record "Payables Agent Task"; var Task: Codeunit "Payables Agent Task")
    var
        AgentTask: Record "Agent Task";
    begin
        AgentTask.Init();
        AgentTask."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentTask."Company Name"));
        AgentTask."External ID" := CopyStr(LowerCase(Format(CreateGuid())).Replace('{', '').Replace('}', ''), 1, MaxStrLen(AgentTask."External ID"));
        AgentTask.Insert();

        StoredTask."Agent Task ID" := AgentTask.ID;
        StoredTask."Intake Status" := "PA Task Intake Status"::Accepted;
        if StoredTask."File Name" = '' then
            StoredTask."File Name" := 'fixture.pdf';
        StoredTask.Insert();
        Check(Task.Load(AgentTask.ID), 'The fixture must load through the Agent Framework task identity.');
    end;

    local procedure CheckOutcome(AgentTaskId: BigInteger; Expected: RecordId)
    var
        Task: Codeunit "Payables Agent Task";
    begin
        Check(Task.Load(AgentTaskId), 'The task must remain loadable.');
        Check(Task.GetOutcome() = Expected, 'The persisted outcome is incorrect.');
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

    local procedure GetJsonText(Object: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetJsonObject(Object: JsonObject; PropertyName: Text): JsonObject
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsObject());
    end;

    local procedure GetJsonArray(Object: JsonObject; PropertyName: Text): JsonArray
    var
        Token: JsonToken;
    begin
        Object.Get(PropertyName, Token);
        exit(Token.AsArray());
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
