// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Reporting;
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
        ReportSelections: Record "Report Selections";
        EDocCartaPorteReport: Report "EDoc CFDI Carta Porte MX";
        RecordRef: RecordRef;
    begin
        if EDocument."Document Record ID".TableNo() = 0 then
            Error(DocumentNotFoundErr);
        if not RecordRef.Get(EDocument."Document Record ID") then
            Error(DocumentNotFoundErr);

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
                    ReportSelections.SetRange(Usage, ReportSelections.Usage::"SM.Invoice");
                    ReportSelections.SetFilter("Report ID", '<>0');
                    if ReportSelections.FindFirst() then
                        Report.RunModal(ReportSelections."Report ID", true, false, ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    RecordRef.SetTable(ServiceCrMemoHeader);
                    ServiceCrMemoHeader.SetRecFilter();
                    ReportSelections.SetRange(Usage, ReportSelections.Usage::"SM.Credit Memo");
                    ReportSelections.SetFilter("Report ID", '<>0');
                    if ReportSelections.FindFirst() then
                        Report.RunModal(ReportSelections."Report ID", true, false, ServiceCrMemoHeader);
                end;
            Database::"Sales Shipment Header",
            Database::"Transfer Shipment Header":
                begin
                    EDocCartaPorteReport.SetRecord(RecordRef);
                    EDocCartaPorteReport.RunModal();
                end;
            else
                Error(DocumentTypeNotSupportedErr, RecordRef.Caption());
        end;
    end;

    var
        DocumentNotFoundErr: Label 'The source document for this E-Document could not be found.';
        DocumentTypeNotSupportedErr: Label 'Printing CFDI is not supported for document type %1.', Comment = '%1 = document type caption';
}
