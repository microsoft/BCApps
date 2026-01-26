// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.BE;

using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

codeunit 37312 "PEPPOL30 BE Serv. Validation" implements "PEPPOL30 Validation"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30BESalesValidation: Codeunit "PEPPOL30 BE Sales Validation";
        PEPPOL30ServiceValidation: Codeunit "PEPPOL30 Service Validation";

    procedure ValidateDocument(RecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        // BE-specific: Use BE sales validation for document header (includes Enterprise No. check)
        ServiceHeader := RecordVariant;
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        // Delegate to W1 - no BE-specific line validation needed
        PEPPOL30ServiceValidation.ValidateDocumentLines(RecordVariant);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        // Delegate to W1 - no BE-specific line validation needed
        PEPPOL30ServiceValidation.ValidateDocumentLine(RecordVariant);
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        DataTypeMgt: Codeunit "Data Type Management";
        PEPPOL30Management: Codeunit "PEPPOL30";
        RecordRef: RecordRef;
        UnsupportedDocumentErr: Label 'The posted service document type is not supported for PEPPOL 3.0 validation.';
    begin
        if not DataTypeMgt.GetRecordRef(RecordVariant, RecordRef) then
            exit;

        // BE-specific: Validate document header with Enterprise No. check, then delegate line validation to W1
        case RecordRef.Number() of
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := RecordVariant;
                    PEPPOL30Management.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
                    PEPPOL30BESalesValidation.ValidateDocumentLines(SalesHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := RecordVariant;
                    PEPPOL30Management.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
                    PEPPOL30BESalesValidation.ValidateDocumentLines(SalesHeader);
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        // Delegate to W1 - no BE-specific line validation needed
        exit(PEPPOL30ServiceValidation.ValidateLineTypeAndDescription(RecordVariant));
    end;
}
