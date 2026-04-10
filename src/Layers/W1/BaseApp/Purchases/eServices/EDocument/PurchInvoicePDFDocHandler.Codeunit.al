// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.EMail;
using System.Utilities;

codeunit 5446 "Purch. Invoice PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        UnpostedPurchaseInvoiceErr: Label 'You must post purchase invoice %1 before generating the PDF document.', Comment = '%1 - purchase invoice id';
        PurchaseInvoiceLbl: Label 'Purchase Invoice';

    /// <summary>
    /// Generates a PDF blob for Purchase Invoice
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if PurchaseHeader.GetBySystemId(DocumentId) then
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
                Error(UnpostedPurchaseInvoiceErr, DocumentId);

        if not PurchInvAggregator.GetPurchaseInvoiceHeaderFromId(DocumentId, PurchInvHeader) then
            exit(false);

        PurchInvHeader.SetRange("No.", PurchInvHeader."No.");

        if PurchInvHeader."Self-Billing Invoice" then
            ReportUsage := "Report Selection Usage"::"P.Self Billing Invoice"
        else
            ReportUsage := "Report Selection Usage"::"P.Invoice";

        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, PurchInvHeader, PurchInvHeader."Buy-from Vendor No.");
        DocumentMailing.GetAttachmentFileName(Name, PurchInvHeader."No.", PurchaseInvoiceLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}