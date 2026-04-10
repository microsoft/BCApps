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

codeunit 4999 "Return Shpt. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        ReturnShipmentLbl: Label 'Return Shipment';

    /// <summary>
    /// Generates a PDF blob for Return Shipment
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        ReturnShipment: Record "Return Shipment Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not ReturnShipment.GetBySystemId(DocumentId) then
            exit(false);

        ReturnShipment.SetRange("No.", ReturnShipment."No.");
        ReportUsage := "Report Selection Usage"::"P.Return";
        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, ReturnShipment, ReturnShipment."Buy-from Vendor No.");
        DocumentMailing.GetAttachmentFileName(Name, ReturnShipment."No.", ReturnShipmentLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}