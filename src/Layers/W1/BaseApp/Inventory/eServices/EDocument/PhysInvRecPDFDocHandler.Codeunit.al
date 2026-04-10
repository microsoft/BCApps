// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Counting.Recording;
using System.EMail;
using System.Utilities;

codeunit 5032 "Phys.Inv.Rec. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PhysInventoryRecordingLbl: Label 'Phys. Inventory Recording';

    /// <summary>
    /// Generates a PDF blob for Physical Inventory Recording
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PhysInvtRecordHeader.GetBySystemId(DocumentId) then
            exit(false);

        PhysInvtRecordHeader.SetRange("Order No.", PhysInvtRecordHeader."Order No.");
        PhysInvtRecordHeader.SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
        ReportUsage := "Report Selection Usage"::"Phys.Invt.Rec.";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, PhysInvtRecordHeader, Database::"Phys. Invt. Record Header");
        DocumentMailing.GetAttachmentFileName(Name, PhysInvtRecordHeader."Order No.", PhysInventoryRecordingLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
