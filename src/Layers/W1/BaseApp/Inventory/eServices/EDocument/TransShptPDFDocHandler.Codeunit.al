// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Transfer;
using System.EMail;
using System.Utilities;

codeunit 5018 "Trans. Shpt. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        TransferShipmentLbl: Label 'Transfer Shipment';

    /// <summary>
    /// Generates a PDF blob for Transfer Shipment
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not TransferShipmentHeader.GetBySystemId(DocumentId) then
            exit(false);

        TransferShipmentHeader.SetRange("No.", TransferShipmentHeader."No.");
        ReportUsage := "Report Selection Usage"::Inv2;
        ReportSelections.GetPdfReportForTable(TempBlob, ReportUsage, TransferShipmentHeader, Database::"Transfer Shipment Header");
        DocumentMailing.GetAttachmentFileName(Name, TransferShipmentHeader."No.", TransferShipmentLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}
