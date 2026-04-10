// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Document;
using System.EMail;
using System.Utilities;

codeunit 5035 "Inv. Rcpt. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        InventoryReceiptLbl: Label 'Inventory Receipt';

    /// <summary>
    /// Generates a PDF blob for Inventory Receipt
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not InvtDocumentHeader.GetBySystemId(DocumentId) then
            exit(false);

        InvtDocumentHeader.SetRange("No.", InvtDocumentHeader."No.");
        InvtDocumentHeader.SetRange("Document Type", InvtDocumentHeader."Document Type");
        ReportUsage := "Report Selection Usage"::"Inventory Receipt";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, InvtDocumentHeader, Database::"Invt. Document Header");
        DocumentMailing.GetAttachmentFileName(Name, InvtDocumentHeader."No.", InventoryReceiptLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
