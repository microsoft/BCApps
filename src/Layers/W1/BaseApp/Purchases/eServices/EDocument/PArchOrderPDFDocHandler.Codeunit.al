// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Purchases.Archive;
using System.EMail;
using System.Utilities;

codeunit 5023 "P.Arch.Order PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PurchaseArchivedOrderLbl: Label 'Purchase Archived Order';

    /// <summary>
    /// Generates a PDF blob for Purchase Archived Order
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PurchaseHeaderArchive.GetBySystemId(DocumentId) then
            exit(false);

        PurchaseHeaderArchive.SetRange("No.", PurchaseHeaderArchive."No.");
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type");
        PurchaseHeaderArchive.SetRange("Doc. No. Occurrence", PurchaseHeaderArchive."Doc. No. Occurrence");
        PurchaseHeaderArchive.SetRange("Version No.", PurchaseHeaderArchive."Version No.");
        ReportUsage := "Report Selection Usage"::"P.Arch.Order";
        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, PurchaseHeaderArchive, PurchaseHeaderArchive."Buy-from Vendor No.");
        DocumentMailing.GetAttachmentFileName(Name, PurchaseHeaderArchive."No.", PurchaseArchivedOrderLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
