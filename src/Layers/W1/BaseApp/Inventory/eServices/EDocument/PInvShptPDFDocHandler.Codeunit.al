// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.History;
using System.EMail;
using System.Utilities;

codeunit 5036 "P.Inv. Shpt. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        PostedInventoryShipmentLbl: Label 'Posted Inventory Shipment';

    /// <summary>
    /// Generates a PDF blob for Posted Inventory Shipment
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        InvtShipmentHeader: Record "Invt. Shipment Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not InvtShipmentHeader.GetBySystemId(DocumentId) then
            exit(false);

        InvtShipmentHeader.SetRange("No.", InvtShipmentHeader."No.");
        ReportUsage := "Report Selection Usage"::"P.Inventory Shipment";
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, InvtShipmentHeader, Database::"Invt. Shipment Header");
        DocumentMailing.GetAttachmentFileName(Name, InvtShipmentHeader."No.", PostedInventoryShipmentLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
