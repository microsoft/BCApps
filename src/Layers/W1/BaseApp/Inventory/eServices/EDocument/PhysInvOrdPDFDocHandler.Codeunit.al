// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Counting.Document;
using System.EMail;
using System.Utilities;

codeunit 5030 "Phys.Inv.Ord. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PhysInventoryOrderLbl: Label 'Phys. Inventory Order';

    /// <summary>
    /// Generates a PDF blob for Physical Inventory Order
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not PhysInvtOrderHeader.GetBySystemId(DocumentId) then
            exit(false);

        PhysInvtOrderHeader.SetRange("No.", PhysInvtOrderHeader."No.");
        ReportUsage := "Report Selection Usage"::"Phys.Invt.Order";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, PhysInvtOrderHeader, Database::"Phys. Invt. Order Header");
        DocumentMailing.GetAttachmentFileName(Name, PhysInvtOrderHeader."No.", PhysInventoryOrderLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
