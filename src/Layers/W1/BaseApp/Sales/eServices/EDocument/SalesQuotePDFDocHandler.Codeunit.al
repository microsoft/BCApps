// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Document;
using System.EMail;
using System.Utilities;

codeunit 5449 "Sales Quote PDF Doc.Handler" implements IPdfDocumentHandler
{
    /// <summary>
    /// Generates a PDF blob for Sales Quote
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not SalesHeader.GetBySystemId(DocumentId) then
            exit(false);

        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote then
            exit(false);

        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type");
        ReportUsage := "Report Selection Usage"::"S.Quote";
        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, SalesHeader, SalesHeader."Sell-to Customer No.");
        DocumentMailing.GetAttachmentFileName(Name, SalesHeader."No.", SalesHeader.GetDocTypeTxt(), ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}