// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 37210 "PEPPOL30 Serv. Valid. Impl."
{
    Access = Internal;
    TableNo = "Service Header";

    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";
        PEPPOLValidation: Codeunit "PEPPOL30 Validation";

    trigger OnRun()
    begin
        CheckServiceHeader(Rec);
    end;


    procedure CheckServiceHeader(ServiceHeader: Record "Service Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOLValidation.CheckSalesDocument(SalesHeader);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceLine, SalesLine);
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceLine.Next() = 0;
    end;

    procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        PEPPOLManagement.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."Shipment Date" := SalesHeader."Posting Date";
        PEPPOLValidation.CheckSalesDocument(SalesHeader);
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        if ServiceInvoiceLine.FindSet() then
            repeat
                PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
                SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceInvoiceLine.Next() = 0;
    end;

    procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
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
                PEPPOLValidation.CheckSalesDocumentLine(SalesLine);
            until ServiceCrMemoLine.Next() = 0;
    end;
}

