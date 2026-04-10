// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using System.EMail;
using System.Utilities;

codeunit 5026 "Asm. Order PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        AssemblyOrderLbl: Label 'Assembly Order';

    /// <summary>
    /// Generates a PDF blob for Assembly Order
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not AssemblyHeader.GetBySystemId(DocumentId) then
            exit(false);

        AssemblyHeader.SetRange("No.", AssemblyHeader."No.");
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type");
        ReportUsage := "Report Selection Usage"::"Asm.Order";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, AssemblyHeader, Database::"Assembly Header");
        DocumentMailing.GetAttachmentFileName(Name, AssemblyHeader."No.", AssemblyOrderLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
