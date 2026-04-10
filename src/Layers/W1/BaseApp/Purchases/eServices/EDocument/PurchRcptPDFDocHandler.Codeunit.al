// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Purchases.History;
using System.EMail;
using System.Utilities;

codeunit 5007 "Purch. Rcpt. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PurchRcptLbl: Label 'Purchase Receipt';

    /// <summary>
    /// Generates a PDF blob for Purchase Receipt
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PurchRcptHeader.GetBySystemId(DocumentId) then
            exit(false);

        PurchRcptHeader.SetRange("No.", PurchRcptHeader."No.");
        ReportUsage := "Report Selection Usage"::"P.Receipt";
        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, PurchRcptHeader, PurchRcptHeader."Buy-from Vendor No.");
        DocumentMailing.GetAttachmentFileName(Name, PurchRcptHeader."No.", PurchRcptLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}