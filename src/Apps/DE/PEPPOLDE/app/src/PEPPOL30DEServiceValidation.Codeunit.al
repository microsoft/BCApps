// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.DE;

using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

codeunit 37401 "PEPPOL30 DE Service Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Service Header";
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PEPPOL30ServiceValidation: Codeunit "PEPPOL30 Service Validation";
        PEPPOL30Management: Codeunit "PEPPOL30";
        DESalesValidation: Codeunit "PEPPOL30 DE Sales Validation";
        UnsupportedDocumentErr: Label 'The posted service document type is not supported for PEPPOL 3.0 validation.';

    trigger OnRun()
    begin
        ValidateDocument(Rec);
        ValidateDocumentLines(Rec);
    end;

    procedure ValidateDocument(RecordVariant: Variant)
    var
        ServiceHeader: Record "Service Header";
        SalesHeader: Record "Sales Header";
    begin
        ServiceHeader := RecordVariant;
        // Mirror W1 service validation: convert service to sales shape, then run DE sales rules.
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        SalesHeader."Sell-to E-Mail" := ServiceHeader."E-Mail";
        DESalesValidation.ValidateDocument(SalesHeader);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        PEPPOL30ServiceValidation.ValidateDocumentLines(RecordVariant);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        PEPPOL30ServiceValidation.ValidateDocumentLine(RecordVariant);
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        exit(PEPPOL30ServiceValidation.ValidateLineTypeAndDescription(RecordVariant));
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
    begin
        if not DataTypeMgt.GetRecordRef(RecordVariant, RecordRef) then
            exit;

        case RecordRef.Number() of
            Database::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := RecordVariant;
                    PEPPOL30Management.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    SalesHeader."Sell-to E-Mail" := ServiceInvoiceHeader."E-Mail";
                    DESalesValidation.ValidateDocument(SalesHeader);
                    PEPPOL30ServiceValidation.ValidateDocumentLines(ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := RecordVariant;
                    PEPPOL30Management.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    SalesHeader."Sell-to E-Mail" := ServiceCrMemoHeader."E-Mail";
                    DESalesValidation.ValidateDocument(SalesHeader);
                    PEPPOL30ServiceValidation.ValidateDocumentLines(ServiceCrMemoHeader);
                end;
            else
                Error(UnsupportedDocumentErr);
        end;
    end;
}
