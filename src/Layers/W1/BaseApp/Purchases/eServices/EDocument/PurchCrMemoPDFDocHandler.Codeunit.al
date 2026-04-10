// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using System.EMail;
using System.Utilities;

codeunit 5447 "Purch. Cr.Memo PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        UnpostedPurchaseCreditMemoErr: Label 'You must post purchase credit memo %1 before generating the PDF document.', Comment = '%1 - purchase credit memo id';
        CreditMemoLbl: Label 'Credit Memo';

    /// <summary>
    /// Generates a PDF blob for Purchase Credit Memo
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentMailing: Codeunit "Document-Mailing";
        GraphMgtPurchCrMemo: Codeunit "Graph Mgt - Purch. Cr. Memo";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if PurchaseHeader.GetBySystemId(DocumentId) then
            if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
                Error(UnpostedPurchaseCreditMemoErr, DocumentId);

        if not GraphMgtPurchCrMemo.GetPurchaseCrMemoHeaderFromId(DocumentId, PurchCrMemoHdr) then
            exit(false);

        PurchCrMemoHdr.SetRange("No.", PurchCrMemoHdr."No.");
        ReportUsage := "Report Selection Usage"::"P.Cr.Memo";
        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, PurchCrMemoHdr, PurchCrMemoHdr."Buy-from Vendor No.");
        DocumentMailing.GetAttachmentFileName(Name, PurchCrMemoHdr."No.", CreditMemoLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}