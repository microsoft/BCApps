// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.Agents;
using System.IO;
using System.Utilities;

// Aggregate over one accepted Payables Agent task. Its sole identity is the Agent Framework task ID.
// Loading resolves and validates the version-specific source backing; backing records never leave this contract.
codeunit 3341 "Payables Agent Task"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = RM,
        tabledata "Document Attachment" = RI;

    var
        LoadedAgentTask: Record "Agent Task";
        LoadedStoredTask: Record "Payables Agent Task";
        LoadedDraftBasedTask: Codeunit "PA Draft Based Task";
        LoadedSource: Codeunit "PA Task Source";
        LoadedVersion: Enum "PA Version";
        TaskNotFoundErr: Label 'The task does not exist.';
        MultipleTaskBackingsErr: Label 'Agent task %1 has more than one Payables Agent backing record.', Comment = '%1 = Agent Task ID';
        AmbiguousTaskBackingErr: Label 'Agent task %1 has both version 1 and version 2 backing records.', Comment = '%1 = Agent Task ID';
        InvalidOutcomeErr: Label 'The outcome must be an existing purchase invoice, purchase order, purchase credit memo, posted purchase invoice, or posted purchase credit memo.';
        OutcomeRegistrationNotSupportedErr: Label 'Outcome registration is only supported for version 2 Payables Agent tasks.', Comment = 'Payables Agent is a term, and should not be translated.';
        SourceTextNotSupportedErr: Label 'Extracted source text cannot be stored for this task.';
        OutcomeTitleLbl: Label '%1 %2 from %3', Comment = '%1 = document kind, %2 = vendor document number, %3 = vendor name';
        InvoiceTitleLbl: Label 'Invoice';
        CreditMemoTitleLbl: Label 'Credit memo';
        OrderTitleLbl: Label 'Order';

    internal procedure Load(AgentTaskId: BigInteger): Boolean
    var
        StoredTask: Record "Payables Agent Task";
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
        if StoredTask.FindSet() then begin
            LoadedStoredTask := StoredTask;
            HasTaskBacking := true;
            if StoredTask.Next() <> 0 then
                Error(MultipleTaskBackingsErr, AgentTaskId);
        end;

        HasDraftBacking := LoadedSource.LoadDraftBasedForTask(AgentTaskId);
        if HasDraftBacking then
            LoadedDraftBasedTask.LoadResolvedSource(LoadedSource.GetId());

        if HasTaskBacking and HasDraftBacking then
            Error(AmbiguousTaskBackingErr, AgentTaskId);
        if HasTaskBacking then begin
            if not LoadedSource.Load(LoadedStoredTask.SystemId) then
                Error(TaskNotFoundErr);
            LoadedVersion := "PA Version"::V2;
        end else
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

    internal procedure GetVersion(): Enum "PA Version" // TODO: I'm afraid this would leak and make the consumers encode v1/v2 decisions outside. can you audit the usages for that and brainstorm how to encapsulate differently so that we can remove this one? maybe having "capabilities" for a task
    begin
        RequireLoaded();
        exit(LoadedVersion);
    end;

    internal procedure GetSource(var Source: Codeunit "PA Task Source")
    begin
        RequireLoaded();
        // Give the caller its own handle so reloading it cannot change this task's source identity.
        Clear(Source);
        if LoadedVersion = "PA Version"::V1 then begin
            if not Source.LoadDraftBased(LoadedSource.GetId()) then
                Error(TaskNotFoundErr);
        end else
            if not Source.Load(LoadedSource.GetId()) then
                Error(TaskNotFoundErr);
    end;

    internal procedure CanExtractText(): Boolean
    begin
        exit((GetVersion() = "PA Version"::V2) and LoadedSource.HasPdf());
    end;

    internal procedure CanRegisterOutcome(): Boolean
    begin
        exit(GetVersion() = "PA Version"::V2);
    end;

    internal procedure GetOutcome(): RecordId
    begin
        RequireLoaded();
        if LoadedVersion = "PA Version"::V2 then
            exit(LoadedStoredTask.Outcome);
        exit(LoadedDraftBasedTask.GetOutcome());
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
            exit(LoadedDraftBasedTask.GetState());
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
        // SetFileContentAsText mutates this record's BLOB; CodeCop does not track the table-method write.
#pragma warning disable AA0214
        StoredTask.Modify();
#pragma warning restore AA0214
        Refresh();
    end;

    internal procedure IsResultRecord(Candidate: RecordId): Boolean
    begin
        RequireLoaded();
        if Candidate.TableNo = 0 then
            exit(false);
        if Candidate = GetOutcome() then
            exit(true);
        exit((LoadedVersion = "PA Version"::V1) and LoadedDraftBasedTask.IsBackingRecord(Candidate));
    end;

    internal procedure RegisterOutcome(OutcomeRecordId: RecordId)
    var
        StoredTask: Record "Payables Agent Task";
    begin
        RequireLoaded();
        if not CanRegisterOutcome() then
            Error(OutcomeRegistrationNotSupportedErr);
        ValidateOutcome(OutcomeRecordId);
        if not StoredTask.Get(LoadedStoredTask."Entry No.") then
            Error(TaskNotFoundErr);
        AttachSourcePdf(LoadedStoredTask, OutcomeRecordId);
        StoredTask.Outcome := OutcomeRecordId;
        StoredTask.Modify();
        UpdateAgentTaskTitle(OutcomeRecordId);
        Refresh();
    end;

    internal procedure GetAgentTaskExternalId(): Text[2048]
    begin
        RequireLoaded();
        exit(LoadedAgentTask."External ID");
    end;

    #region Agent runtime limitations
    // Temporary bridge until the Agent Framework can attach the source PDF to an outcome itself.
    local procedure AttachSourcePdf(StoredTask: Record "Payables Agent Task"; Outcome: RecordId)
    var
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        Pdf: Codeunit "Temp Blob";
        OutcomeRef: RecordRef;
        PdfStream: InStream;
        FileName: Text;
        BaseName: Text;
        AttachmentNameLbl: Label 'Payables Agent %1 - %2', Comment = '%1 = task entry number, %2 = source PDF file name without extension';
    begin
        if not LoadedSource.GetSourcePdf(Pdf, FileName) then
            exit;

        OutcomeRef.Get(Outcome);
        // The task ID disambiguates PDFs from different tasks and makes repeat registration idempotent.
        BaseName := FileManagement.GetFileNameWithoutExtension(FileName);
        FileName := CopyStr(StrSubstNo(AttachmentNameLbl, StoredTask."Entry No.", BaseName), 1, 246) + '.pdf';
        DocumentAttachment.InitFieldsFromRecRef(OutcomeRef);
        DocumentAttachment.SetRange("Table ID", DocumentAttachment."Table ID");
        DocumentAttachment.SetRange("No.", DocumentAttachment."No.");
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type");
        DocumentAttachment.SetRange("Line No.", DocumentAttachment."Line No.");
        DocumentAttachment.SetRange("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(DocumentAttachment."File Name")));
        DocumentAttachment.SetRange("File Extension", 'pdf');
        if not DocumentAttachment.IsEmpty() then
            exit;

        Pdf.CreateInStream(PdfStream);
        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachmentFromStream(PdfStream, OutcomeRef, FileName, false);
    end;
    #endregion

    local procedure UpdateAgentTaskTitle(OutcomeRecordId: RecordId)
    var
        AgentTask: Record "Agent Task";
        PurchaseHeader: Record "Purchase Header";
        PostedInvoice: Record "Purch. Inv. Header";
        PostedCreditMemo: Record "Purch. Cr. Memo Hdr.";
        DocumentNo: Text;
        VendorName: Text;
        DocumentKind: Text;
    begin
        DocumentKind := InvoiceTitleLbl;
        case OutcomeRecordId.TableNo of
            Database::"Purchase Header":
                begin
                    PurchaseHeader.Get(OutcomeRecordId);
                    VendorName := PurchaseHeader."Buy-from Vendor Name";
                    case PurchaseHeader."Document Type" of
                        PurchaseHeader."Document Type"::Invoice:
                            DocumentNo := PurchaseHeader."Vendor Invoice No.";
                        PurchaseHeader."Document Type"::"Credit Memo":
                            begin
                                DocumentNo := PurchaseHeader."Vendor Cr. Memo No.";
                                DocumentKind := CreditMemoTitleLbl;
                            end;
                        else begin
                            DocumentNo := PurchaseHeader."No.";
                            DocumentKind := OrderTitleLbl;
                        end;
                    end;
                end;
            Database::"Purch. Inv. Header":
                begin
                    PostedInvoice.Get(OutcomeRecordId);
                    DocumentNo := PostedInvoice."Vendor Invoice No.";
                    VendorName := PostedInvoice."Buy-from Vendor Name";
                end;
            Database::"Purch. Cr. Memo Hdr.":
                begin
                    PostedCreditMemo.Get(OutcomeRecordId);
                    DocumentNo := PostedCreditMemo."Vendor Cr. Memo No.";
                    VendorName := PostedCreditMemo."Buy-from Vendor Name";
                    DocumentKind := CreditMemoTitleLbl;
                end;
        end;
        if DocumentNo = '' then
            case OutcomeRecordId.TableNo of
                Database::"Purchase Header":
                    DocumentNo := PurchaseHeader."No.";
                Database::"Purch. Inv. Header":
                    DocumentNo := PostedInvoice."No.";
                Database::"Purch. Cr. Memo Hdr.":
                    DocumentNo := PostedCreditMemo."No.";
            end;
        AgentTask.Get(LoadedAgentTask.ID);
        AgentTask.Title := CopyStr(StrSubstNo(OutcomeTitleLbl, DocumentKind, DocumentNo, VendorName), 1, MaxStrLen(AgentTask.Title));
        AgentTask.Modify(true);
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
        Clear(LoadedDraftBasedTask);
        Clear(LoadedSource);
        LoadedVersion := "PA Version"::Unknown;
    end;
}
