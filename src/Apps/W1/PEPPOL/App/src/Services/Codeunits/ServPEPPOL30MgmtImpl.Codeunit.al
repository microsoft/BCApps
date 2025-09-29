// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 37208 "Serv. PEPPOL30 Mgmt. Impl."
{
    Access = Internal;
    SingleInstance = true;

    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";

    procedure FindNextServiceInvoiceRec(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceInvoiceHeader.Find('-')
        else
            Found := ServiceInvoiceHeader.Next() <> 0;
        if Found then
            PEPPOLManagement.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
    end;

    procedure FindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    var
        Found: Boolean;
    begin
        if Position = 1 then
            Found := ServiceInvoiceLine.Find('-')
        else
            Found := ServiceInvoiceLine.Next() <> 0;
        if Found then begin
            PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
            SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
        end;
        exit(Found);
    end;

    procedure FindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceCrMemoHeader.Find('-')
        else
            Found := ServiceCrMemoHeader.Next() <> 0;
        if Found then
            PEPPOLManagement.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);

        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
    end;

    procedure MapServiceLineTypeToSalesLineType(ServiceLineType: Enum "Service Line Type"): Enum "Sales Line Type"
    begin
        case ServiceLineType of
            "Service Line Type"::" ":
                exit("Sales Line Type"::" ");
            "Service Line Type"::Item:
                exit("Sales Line Type"::Item);
            "Service Line Type"::Resource:
                exit("Sales Line Type"::Resource);
            else
                exit("Sales Line Type"::"G/L Account");
        end;
    end;

    procedure FindNextServiceCreditMemoLineRec(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceCrMemoLine.Find('-')
        else
            Found := ServiceCrMemoLine.Next() <> 0;
        if Found then begin
            PEPPOLManagement.TransferLineToSalesLine(ServiceCrMemoLine, SalesLine);
            SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceCrMemoLine.Type);
        end;
    end;
}
