// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Archive;
using System.EMail;
using System.Utilities;

codeunit 5020 "S.Arch.Quote PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        SalesArchivedQuoteLbl: Label 'Sales Archived Quote';

    /// <summary>
    /// Generates a PDF blob for Sales Archived Quote
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not SalesHeaderArchive.GetBySystemId(DocumentId) then
            exit(false);

        SalesHeaderArchive.SetRange("No.", SalesHeaderArchive."No.");
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesHeaderArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
        SalesHeaderArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        ReportUsage := "Report Selection Usage"::"S.Arch.Quote";
        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeaderArchive, SalesHeaderArchive."Bill-to Customer No.");
        DocumentMailing.GetAttachmentFileName(Name, SalesHeaderArchive."No.", SalesArchivedQuoteLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
