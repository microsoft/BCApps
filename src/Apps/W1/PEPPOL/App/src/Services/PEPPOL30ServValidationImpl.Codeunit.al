// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

codeunit 37220 "PEPPOL30 Serv. Validation Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CheckServiceDocument(ServiceHeader: Record "Service Header")
    var
        SalesHeader: Record "Sales Header";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30SalesValidationImpl.CheckSalesDocument(SalesHeader);
    end;

    procedure CheckServiceDocumentLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                CheckServiceDocumentLine(ServiceLine)
            until ServiceLine.Next() = 0;
    end;

    procedure CheckServiceDocumentLine(ServiceLine: Record "Service Line")
    var
        SalesLine: Record "Sales Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30Management.TransferLineToSalesLine(ServiceLine, SalesLine);
        PEPPOL30SalesValidationImpl.CheckSalesDocumentLine(SalesLine);
    end;

    procedure CheckPostedDocument(PostedDocumentVariant: Variant)
    var
        DataTypeMgt: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        UnsupportedDocumentErr: Label 'The posted service document type is not supported for PEPPOL 3.0 validation.';
    begin
        if not DataTypeMgt.GetRecordRef(PostedDocumentVariant, RecordRef) then
            exit;

        case RecordRef.Number() of
            Database::"Service Invoice Header":
                CheckServiceInvoice(PostedDocumentVariant);
            Database::"Service Cr.Memo Header":
                CheckServiceCreditMemo(PostedDocumentVariant);
            else
                Error(UnsupportedDocumentErr);
        end;
    end;

    local procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30SalesValidationImpl.CheckSalesDocument(SalesHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOL30Management.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                PEPPOL30SalesValidationImpl.CheckSalesDocumentLine(SalesLine);
            until ServiceInvoiceLine.Next() = 0;
    end;

    local procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30Management.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOL30SalesValidationImpl.CheckSalesDocument(SalesHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOL30Management.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                PEPPOL30SalesValidationImpl.CheckSalesDocumentLine(SalesLine);
            until ServiceCrMemoLine.Next() = 0;
    end;

    procedure CheckServiceLineTypeAndDescription(ServiceLine: Record "Service Line"): Boolean
    var
        SalesLine: Record "Sales Line";
        PEPPOL30Management: Codeunit "PEPPOL30";
        PEPPOL30SalesValidationImpl: Codeunit "PEPPOL30 Sales Validation Impl";
    begin
        PEPPOL30Management.TransferLineToSalesLine(ServiceLine, SalesLine);
        exit(PEPPOL30SalesValidationImpl.CheckSalesLineTypeAndDescription(SalesLine));
    end;
}
