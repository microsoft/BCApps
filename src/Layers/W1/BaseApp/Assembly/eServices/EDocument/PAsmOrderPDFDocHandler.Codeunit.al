// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Assembly.History;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using System.EMail;
using System.Utilities;

codeunit 5027 "P.Asm. Order PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PostedAssemblyOrderLbl: Label 'Posted Assembly Order';

    /// <summary>
    /// Generates a PDF blob for Posted Assembly Order
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PostedAssemblyHeader.GetBySystemId(DocumentId) then
            exit(false);

        PostedAssemblyHeader.SetRange("No.", PostedAssemblyHeader."No.");
        ReportUsage := "Report Selection Usage"::"P.Asm.Order";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, PostedAssemblyHeader, Database::"Posted Assembly Header");
        DocumentMailing.GetAttachmentFileName(Name, PostedAssemblyHeader."No.", PostedAssemblyOrderLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
