// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Purchases.History;
using System.Utilities;

codeunit 139778 "Self-Billing Format Mock" implements "E-Document", ISelfBillingFormatPolicy, IExportEligibilityEvaluator
{
    procedure HasRequiredSetup(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean
    begin
        exit(EDocumentService."Document Format" = Enum::"E-Document Format"::"Self-Billing Mock");
    end;

    procedure ShouldExport(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean
    begin
        exit(false);
    end;

    procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        EDocumentProcessing.GetSelfBillingDocumentType(SourceDocumentHeader);
    end;

    procedure Create(EDocumentService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeader: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocumentProcessing: Codeunit "E-Document Processing";
        Payload: JsonObject;
        SellerVendorNo: Code[20];
        PayToVendorNo: Code[20];
    begin
        EDocumentProcessing.CheckSelfBillingSource(SourceDocumentHeader, EDocument."Document Type");
        EDocumentProcessing.GetSelfBillingParties(SourceDocumentHeader, SellerVendorNo, PayToVendorNo);
        Payload.Add('service', EDocumentService.Code);
        Payload.Add('seller', SellerVendorNo);
        Payload.Add('payTo', PayToVendorNo);
        Payload.Add('documentType', EDocument."Document Type".AsInteger());
        if EDocument."Document Type" = EDocument."Document Type"::"Self-Billed Purch. Cr. Memo" then begin
            EDocumentProcessing.GetSelfBillingInvoiceReference(SourceDocumentHeader, PurchInvHeader);
            Payload.Add('originalInvoice', PurchInvHeader."No.");
        end;
        Payload.WriteTo(TempBlob.CreateOutStream(TextEncoding::UTF8));
    end;

    procedure CreateBatch(EDocumentService: Record "E-Document Service"; var EDocuments: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        Error(UnsupportedOperationErr);
    end;

    procedure GetBasicInfoFromReceivedDocument(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    begin
        Error(UnsupportedOperationErr);
    end;

    procedure GetCompleteInfoFromReceivedDocument(var EDocument: Record "E-Document"; var CreatedDocumentHeader: RecordRef; var CreatedDocumentLines: RecordRef; var TempBlob: Codeunit "Temp Blob")
    begin
        Error(UnsupportedOperationErr);
    end;

    var
        UnsupportedOperationErr: Label 'The self-billing mock supports only outgoing single documents.';
}
