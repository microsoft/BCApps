// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Foundation.Reporting;
using System.Automation;
using System.Environment.Configuration;
using System.Utilities;

codeunit 6148 "E-Document Helper"
{

    procedure GetEDocumentBlob(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; var TempBlob: Codeunit "Temp Blob");
    var
        EDocumentLog: Codeunit "E-Document Log";
    begin
        if not EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, Enum::"E-Document Service Status"::Imported) then
            Error(FailedToGetBlobErr);
    end;

    /// <summary>
    /// Returns the inbound PDF preview (unstructured E-Doc. Data Storage entry) for a posted purchase
    /// document that originated from an E-Document, matching by the document's RecordId.
    /// Returns 0 when the document has no linked PDF preview.
    /// </summary>
    /// <param name="SourceRecordId">The RecordId of the source purchase document.</param>
    /// <returns>The unstructured PDF data storage entry number, or 0 when there is none.</returns>
    procedure GetInboundPdfPreviewEntryNo(SourceRecordId: RecordId): Integer
    var
        EmptyLink: Guid;
    begin
        exit(GetInboundPdfPreviewEntryNo(SourceRecordId, EmptyLink));
    end;

    /// <summary>
    /// Returns the inbound PDF preview (unstructured E-Doc. Data Storage entry) for a purchase document
    /// that originated from an E-Document. The E-Document is located by its SystemId (open documents that
    /// carry an "E-Document Link") or, as a fallback, by the document's RecordId (posted documents).
    /// Returns 0 when the document has no linked PDF preview.
    /// </summary>
    /// <param name="SourceRecordId">The RecordId of the source purchase document.</param>
    /// <param name="EDocumentLink">The "E-Document Link" GUID from the source document, or an empty GUID.</param>
    /// <returns>The unstructured PDF data storage entry number, or 0 when there is none.</returns>
    procedure GetInboundPdfPreviewEntryNo(SourceRecordId: RecordId; EDocumentLink: Guid): Integer
    var
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
    begin
        if not FindLinkedEDocument(SourceRecordId, EDocumentLink, EDocument) then
            exit(0);
        if EDocument."Unstructured Data Entry No." = 0 then
            exit(0);
        EDocDataStorage.SetLoadFields("File Format");
        if not EDocDataStorage.Get(EDocument."Unstructured Data Entry No.") then
            exit(0);
        if EDocDataStorage."File Format" <> Enum::"E-Doc. File Format"::PDF then
            exit(0);
        exit(EDocDataStorage."Entry No.");
    end;

    local procedure FindLinkedEDocument(SourceRecordId: RecordId; EDocumentLink: Guid; var EDocument: Record "E-Document"): Boolean
    begin
        EDocument.SetLoadFields("Document Record ID", "Unstructured Data Entry No.");
        if not IsNullGuid(EDocumentLink) then
            if EDocument.GetBySystemId(EDocumentLink) then
                exit(true);
        EDocument.SetRange("Document Record ID", SourceRecordId);
        exit(EDocument.FindFirst());
    end;


    /// <summary>
    /// Use it to check if the source document is an E-Document.
    /// </summary>
    /// <param name="RecRef">Source document record reference.</param>
    /// <returns> True if the source document is an E-Document.</returns>
    procedure IsElectronicDocument(var RecRef: RecordRef): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        exit(IsElectronicDocument(RecRef, DocumentSendingProfile));
    end;

    procedure IsElectronicDocument(var RecRef: RecordRef; var DocumentSendingProfile: Record "Document Sending Profile"): Boolean
    var
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        DocumentSendingProfile := EDocumentProcessing.GetDocSendingProfileForDocRef(RecRef);
        exit(DocumentSendingProfile."Electronic Document" = DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow");
    end;

    /// <summary>
    /// Returns the EDocuments services used in a workflow.
    /// E-Document service record has code filter set.
    /// </summary>
    procedure GetServicesInWorkflow(Workflow: Record Workflow; var EDocumentService: Record "E-Document Service"): Boolean
    var
        EDocumentWorkFlowProcessing: Codeunit "E-Document Workflow Processing";
    begin
        exit(EDocumentWorkFlowProcessing.DoesFlowHasEDocService(EDocumentService, Workflow.Code));
    end;

    /// <summary>
    /// Use it to set allow EDocument CoreHttpCalls.
    /// </summary>
    procedure AllowEDocumentCoreHttpCalls()
    var
        NavAppSettings: Record "NAV App Setting";
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);

        // E-Document Core extension ID
        if not NavAppSettings.Get('e1d97edc-c239-46b4-8d84-6368bdf67c8b') then begin
            NavAppSettings."App ID" := CurrentModuleInfo.Id();
            NavAppSettings."Allow HttpClient Requests" := true;
            if NavAppSettings.Insert() then;
        end
        else begin
            NavAppSettings."Allow HttpClient Requests" := true;
            NavAppSettings.Modify();
        end;
    end;

    /// <summary>
    /// Use it to get E-Document Service for an Edocument.
    /// </summary>
    /// <param name="Edocument">Edocument record.</param>
    /// <param name="EdocumentService">Edocument service record by reference.</param>
    procedure GetEdocumentService(Edocument: Record "E-Document"; var EdocumentService: Record "E-Document Service")
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        WorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        WorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        EDocServiceStatus: Record "E-Document Service Status";
    begin
        if Edocument.Direction = Edocument.Direction::Outgoing then begin
            WorkflowStepInstanceArchive.SetRange(Type, WorkflowStepInstanceArchive.Type::Response);
            WorkflowStepInstanceArchive.SetRange(ID, EDocument."Workflow Step Instance ID");
            WorkflowStepInstanceArchive.SetRange("Workflow Code", EDocument."Workflow Code");
            if WorkflowStepInstanceArchive.FindFirst() then;
            if WorkflowStepArgumentArchive.Get(WorkflowStepInstanceArchive.Argument) then;
            if EdocumentService.Get(WorkflowStepArgumentArchive."E-Document Service") then;

            WorkflowStepInstance.SetRange(Type, WorkflowStepInstanceArchive.Type::Response);
            WorkflowStepInstance.SetRange(ID, EDocument."Workflow Step Instance ID");
            WorkflowStepInstance.SetRange("Workflow Code", EDocument."Workflow Code");
            if WorkflowStepInstance.FindFirst() then;
            if WorkflowStepArgument.Get(WorkflowStepInstance.Argument) then;
            if EdocumentService.Get(WorkflowStepArgument."E-Document Service") then;
        end else begin
            EDocServiceStatus.SetRange("E-Document Entry No", Edocument."Entry No");
            if EDocServiceStatus.FindLast() then
                EdocumentService.Get(EDocServiceStatus."E-Document Service Code");
        end;
    end;

    internal procedure EnsureInboundEDocumentHasService(var EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocument.TestField(Direction, "E-Document Direction"::Incoming);
        if EDocument.Service <> '' then
            exit(true);

        if Page.RunModal(Page::"E-Document Services", EDocumentService) <> Action::LookupOK then
            exit(false);

        EDocument.Service := EDocumentService.Code;
        exit(true);
    end;

    procedure OpenDraftPage(var EDocument: Record "E-Document")
    var
        IProcessStructuredData: Interface IProcessStructuredData;
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if EDocument.GetEDocumentService().GetImportProcessVersion() = "E-Document Import Process"::"Version 1.0" then begin
            Page.Run(Page::"E-Document", EDocument);
            exit;
        end;
#pragma warning restore AL0432
#endif
        IProcessStructuredData := EDocument."Process Draft Impl.";
        IProcessStructuredData.OpenDraftPage(EDocument);
    end;


    var
        FailedToGetBlobErr: Label 'Failed to get E-Document Blob.', Locked = true;
}
