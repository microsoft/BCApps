// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.EMail;
using System.Utilities;

codeunit 5450 "Sales Invoice PDF Doc.Handler" implements IPdfDocumentHandler
{
    /// <summary>
    /// Generates a PDF blob for Sales Invoice
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if SalesHeader.GetBySystemId(DocumentId) then
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then begin
                SalesHeader.SetRange("No.", SalesHeader."No.");
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
                ReportUsage := "Report Selection Usage"::"S.Invoice Draft";
                ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
                DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
            end;

        if SalesInvoiceAggregator.GetSalesInvoiceHeaderFromId(DocumentId, SalesInvoiceHeader) then begin
            SalesInvoiceHeader.SetRange("No.", SalesInvoiceHeader."No.");
            ReportUsage := "Report Selection Usage"::"S.Invoice";
            ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesInvoiceHeader, SalesInvoiceHeader."Sell-to Customer No.");
            DocumentMailing.GetAttachmentFileName(Name, SalesInvoiceHeader."No.", SalesInvoiceHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
        end;

        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}