// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Foundation.Attachment;
using System.Agents;
using System.IO;
using System.Utilities;

// Coordinates outcome registration with runtime presentation/attachment workarounds; the entity stores only valid state.
codeunit 3313 "PA Work Item Outcome"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = RM, tabledata "Document Attachment" = RI;

    internal procedure Register(var WorkItem: Codeunit "PA Work Item"; OutcomeId: RecordId)
    begin
        WorkItem.RegisterOutcome(OutcomeId);
        AttachSourcePdf(WorkItem, OutcomeId);
        UpdateAgentTaskTitle(WorkItem.GetAgentTaskId(), OutcomeId);
        WorkItem.Refresh();
    end;

    #region Agent runtime limitations
    // Remove this bridge when the agent can attach the received PDF through the normal document-attachment UI.
    local procedure AttachSourcePdf(WorkItem: Codeunit "PA Work Item"; OutcomeId: RecordId)
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        Pdf: Codeunit "Temp Blob";
        OutcomeRef: RecordRef;
        PdfStream: InStream;
        FileName: Text;
        BaseName: Text;
        AttachmentNameLbl: Label 'Payables Agent %1 - %2', Comment = '%1 = work item entry number, %2 = source PDF file name without extension';
    begin
        if not WorkItem.GetSourcePdf(Pdf, FileName) then
            exit;
        StoredWorkItem.GetBySystemId(WorkItem.GetId());
        OutcomeRef.Get(OutcomeId);
        // Retain the existing file-name scheme and deduplication for already registered V2 documents.
        BaseName := FileManagement.GetFileNameWithoutExtension(FileName);
        FileName := CopyStr(StrSubstNo(AttachmentNameLbl, StoredWorkItem."Entry No.", BaseName), 1, 246) + '.pdf';
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

    local procedure UpdateAgentTaskTitle(AgentTaskId: BigInteger; OutcomeId: RecordId)
    var
        AgentTask: Record "Agent Task";
        Facts: Record "PA Purchase Outcome Facts" temporary;
        PurchaseOutcomes: Codeunit "PA Purchase Outcomes";
        DocumentNo: Text;
        DocumentKind: Text;
        OutcomeTitleLbl: Label '%1 %2 from %3', Comment = '%1 = document kind, %2 = vendor document number, %3 = vendor name';
        InvoiceTitleLbl: Label 'Invoice';
        CreditMemoTitleLbl: Label 'Credit memo';
        OrderTitleLbl: Label 'Order';
    begin
        if not PurchaseOutcomes.TryGetFacts(OutcomeId, Facts) then
            exit;
        case Facts."Document Type" of
            Facts."Document Type"::Invoice:
                DocumentKind := InvoiceTitleLbl;
            Facts."Document Type"::"Credit Memo":
                DocumentKind := CreditMemoTitleLbl;
            else
                DocumentKind := OrderTitleLbl;
        end;
        DocumentNo := Facts."Vendor Document No.";
        if DocumentNo = '' then
            DocumentNo := Facts."Document No.";
        AgentTask.Get(AgentTaskId);
        AgentTask.Title := CopyStr(StrSubstNo(OutcomeTitleLbl, DocumentKind, DocumentNo, Facts."Vendor Name"), 1, MaxStrLen(AgentTask.Title));
        AgentTask.Modify(true);
    end;
}
