// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Inventory.Transfer;
using Microsoft.Sales.History;
using Microsoft.Service.History;

codeunit 3364 "EDoc CFDI Print MX"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure PrintCFDI(EDocument: Record "E-Document")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        CFDIWriteBackMX: Codeunit "CFDI Write-Back MX";
        EDocCartaPortePrintBuffer: Codeunit "EDoc Carta Porte Print Buffer";
        EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
        EDocCartaPorteReport: Report "EDoc CFDI Carta Porte MX";
        RecordRef: RecordRef;
    begin
        if EDocument."Document Record ID".TableNo() = 0 then
            Error(DocumentNotFoundErr);
        if not RecordRef.Get(EDocument."Document Record ID") then
            Error(DocumentNotFoundErr);

        if CFDIWriteBackMX.GetUUIDForDocument(EDocument."Document Record ID") = '' then
            if not Confirm(PrintNotStampedQst, false) then
                exit;

        case RecordRef.Number of
            Database::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.SetRecFilter();
                    Report.RunModal(Report::"EDoc CFDI Sales Invoice MX", true, false, SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    RecordRef.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.SetRecFilter();
                    Report.RunModal(Report::"EDoc CFDI Sales Credit Memo MX", true, false, SalesCrMemoHeader);
                end;
            Database::"Service Invoice Header":
                begin
                    RecordRef.SetTable(ServiceInvoiceHeader);
                    ServiceInvoiceHeader.SetRecFilter();
                    Report.RunModal(Report::"EDoc CFDI Service Invoice MX", true, false, ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.SetRecFilter();
                    Report.RunModal(Report::"EDoc CFDI Service Cr. Memo MX", true, false, ServiceCrMemoHeader);
                end;
            Database::"Sales Shipment Header":
                begin
                    RecordRef.SetTable(SalesShipmentHeader);
                    EDocCFDIDataMX.ApplyToDocument(EDocument, SalesShipmentHeader);
                    EDocCartaPortePrintBuffer.SetSalesShipment(SalesShipmentHeader);
                    SetTransportOperatorsSource(EDocument, EDocCartaPortePrintBuffer);
                    EDocCartaPorteReport.RunModal();
                    EDocCartaPortePrintBuffer.Clear();
                end;
            Database::"Transfer Shipment Header":
                begin
                    RecordRef.SetTable(TransferShipmentHeader);
                    EDocCFDIDataMX.ApplyToDocument(EDocument, TransferShipmentHeader);
                    EDocCartaPortePrintBuffer.SetTransferShipment(TransferShipmentHeader);
                    SetTransportOperatorsSource(EDocument, EDocCartaPortePrintBuffer);
                    EDocCartaPorteReport.RunModal();
                    EDocCartaPortePrintBuffer.Clear();
                end;
            else
                Error(DocumentTypeNotSupportedErr, RecordRef.Caption());
        end;
    end;

    local procedure SetTransportOperatorsSource(EDocument: Record "E-Document"; var EDocCartaPortePrintBuffer: Codeunit "EDoc Carta Porte Print Buffer")
    var
        EDocCFDIDataMX: Codeunit "EDoc CFDI Data MX";
    begin
        EDocCartaPortePrintBuffer.SetTransportOperatorsEDocumentNo(EDocCFDIDataMX.GetTransportOperatorDocumentNo(EDocument));
    end;

    var
        DocumentNotFoundErr: Label 'The source document for this E-Document could not be found.';
        DocumentTypeNotSupportedErr: Label 'Printing CFDI is not supported for document type %1.', Comment = '%1 = document type caption';
        PrintNotStampedQst: Label 'This CFDI document has not been stamped and does not have a UUID. The printed document will not include the fiscal stamp data. Do you want to continue?';
}
