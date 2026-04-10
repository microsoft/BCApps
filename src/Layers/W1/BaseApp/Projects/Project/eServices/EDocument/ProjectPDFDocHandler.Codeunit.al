// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Projects.Project.Job;
using System.EMail;
using System.Utilities;

codeunit 5454 "Project PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        ProjectLbl: Label 'Project Quote';

    /// <summary>
    /// Generates a PDF blob for Job Quote (Project Quote)
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        Job: Record Job;
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not Job.GetBySystemId(DocumentId) then
            exit(false);

        Job.SetRange("No.", Job."No.");
        ReportUsage := "Report Selection Usage"::JQ;
        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, Job, Job."Bill-to Customer No.");
        DocumentMailing.GetAttachmentFileName(Name, Job."No.", ProjectLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}