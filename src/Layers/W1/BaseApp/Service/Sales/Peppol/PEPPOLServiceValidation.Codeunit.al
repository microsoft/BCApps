// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Peppol;

using Microsoft.Service.Document;
using Microsoft.Sales.Document;
using Microsoft.Service.History;

codeunit 1621 "PEPPOL Service Validation"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        CheckServiceHeader(Rec);
    end;

    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        PEPPOLValidation: Codeunit "PEPPOL Validation";

    procedure CheckServiceHeader(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOLValidation.CheckSalesDocument(SalesHeader);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        OnAfterSetServiceLineFilter(ServiceLine, ServiceHeader);
        if ServiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceLine, SalesLine);
                OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(SalesLine, ServiceLine);
#if not CLEAN25
                PEPPOLValidation.RunOnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(SalesLine, ServiceLine);
#endif
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceLine.Next() = 0;
    end;

    procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        OnCheckServiceInvoiceOnBeforeCheckSalesDocument(SalesHeader, ServiceInvoiceHeader);
        PEPPOLValidation.CheckSalesDocument(SalesHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(SalesLine, ServiceInvoiceLine);
#if not CLEAN25
                PEPPOLValidation.RunOnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(SalesLine, ServiceInvoiceLine);
#endif
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceInvoiceLine.Next() = 0;
    end;

    procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOLValidation.CheckSalesDocument(SalesHeader);
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        if ServiceCrMemoLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::"Credit Memo";
                OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(SalesLine, ServiceCrMemoLine);
#if not CLEAN25
                PEPPOLValidation.RunOnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(SalesLine, ServiceCrMemoLine);
#endif
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceCrMemoLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceHeaderOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceInvoiceOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceInvoiceLine: Record "Service Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceCreditMemoOnBeforeCheckSalesDocumentLine(var SalesLine: Record "Sales Line"; ServiceCrMemoLine: Record "Service Cr.Memo Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceLineFilter(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServiceInvoiceOnBeforeCheckSalesDocument(var SalesHeader: Record "Sales Header"; ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
    end;
}

