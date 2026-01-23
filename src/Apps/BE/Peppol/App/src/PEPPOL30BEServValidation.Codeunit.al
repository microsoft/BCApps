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

    procedure ValidateDocument(RecordVariant: Variant)
    var
        SalesHeader: Record "Sales Header";
        ServiceHeader: Record "Service Header";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        ServiceHeader := RecordVariant;
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader := RecordVariant;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                ValidateDocumentLine(ServiceLine)
            until ServiceLine.Next() = 0;
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        ServiceLine := RecordVariant;
        PEPPOL30Management.TransferLineToSalesLine(ServiceLine, SalesLine);
        PEPPOL30BESalesValidation.ValidateDocumentLine(SalesLine);
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        UnsupportedDocumentErr: Label 'The posted service document type is not supported for PEPPOL 3.0 validation.';
    begin
        if not DataTypeMgt.GetRecordRef(RecordVariant, RecordRef) then
            exit;

        case RecordRef.Number() of
            Database::"Service Invoice Header":
                CheckServiceInvoice(RecordVariant);
            Database::"Service Cr.Memo Header":
                CheckServiceCreditMemo(RecordVariant);
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    var
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        ServiceLine := RecordVariant;
        PEPPOL30Management.TransferLineToSalesLine(ServiceLine, SalesLine);
        exit(PEPPOL30BESalesValidation.ValidateLineTypeAndDescription(SalesLine));
    end;

    local procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOL30Management.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                PEPPOL30BESalesValidation.ValidateDocumentLine(SalesLine);
            until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
    begin
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30BESalesValidation.ValidateDocument(SalesHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOL30Management.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                PEPPOL30BESalesValidation.ValidateDocumentLine(SalesLine);
            until ServiceCrMemoLine.Next() = 0;
    end;
}
