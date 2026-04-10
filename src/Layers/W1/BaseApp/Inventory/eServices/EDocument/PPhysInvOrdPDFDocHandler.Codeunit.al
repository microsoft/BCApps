// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Counting.History;
using System.EMail;
using System.Utilities;

codeunit 5031 "P.Phys.InvOrd PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PostedPhysInvtOrderLbl: Label 'Posted Phys. Invt. Order';

    /// <summary>
    /// Generates a PDF blob for Posted Physical Inventory Order
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PstdPhysInvtOrderHdr: Record "Pstd. Phys. Invt. Order Hdr";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PstdPhysInvtOrderHdr.GetBySystemId(DocumentId) then
            exit(false);

        PstdPhysInvtOrderHdr.SetRange("No.", PstdPhysInvtOrderHdr."No.");
        ReportUsage := "Report Selection Usage"::"P.Phys.Invt.Order";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, PstdPhysInvtOrderHdr, Database::"Pstd. Phys. Invt. Order Hdr");
        DocumentMailing.GetAttachmentFileName(Name, PstdPhysInvtOrderHdr."No.", PostedPhysInvtOrderLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
