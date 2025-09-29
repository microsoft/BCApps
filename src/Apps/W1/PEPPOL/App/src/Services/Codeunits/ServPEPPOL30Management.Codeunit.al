// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Service.History;

/// <summary>
/// Manages PEPPOL 3.0 operations for service documents.
/// Provides helper methods for converting service documents to sales document format for PEPPOL export.
/// </summary>
codeunit 37207 "Serv. PEPPOL30 Management"
{
    SingleInstance = true;

    var
        PEPPOLManagement: Codeunit "PEPPOL30 Management";

    /// <summary>
    /// Finds the next service invoice record and transfers it to a sales header format.
    /// </summary>
    /// <param name="ServiceInvoiceHeader">The service invoice header record to iterate through.</param>
    /// <param name="SalesHeader">The sales header record to populate with converted data.</param>
    /// <param name="Position">The position/index for finding the next record (1 for first).</param>
    /// <returns>True if a record was found, false otherwise.</returns>
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

    /// <summary>
    /// Finds the next service invoice line record and transfers it to a sales line format.
    /// </summary>
    /// <param name="ServiceInvoiceLine">The service invoice line record to iterate through.</param>
    /// <param name="SalesLine">The sales line record to populate with converted data.</param>
    /// <param name="Position">The position/index for finding the next line record (1 for first).</param>
    /// <returns>True if a line record was found, false otherwise.</returns>
    procedure FindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    var
        Found: Boolean;
    begin
        if Position = 1 then
            Found := ServiceInvoiceLine.FindSet()
        else
            Found := ServiceInvoiceLine.Next() <> 0;
        if Found then begin
            PEPPOLManagement.TransferLineToSalesLine(ServiceInvoiceLine, SalesLine);
            SalesLine.Type := MapServiceLineTypeToSalesLineType(ServiceInvoiceLine.Type);
        end;
        exit(Found);
    end;

    /// <summary>
    /// Finds the next service credit memo record and transfers it to a sales header format.
    /// </summary>
    /// <param name="ServiceCrMemoHeader">The service credit memo header record to iterate through.</param>
    /// <param name="SalesHeader">The sales header record to populate with converted data.</param>
    /// <param name="Position">The position/index for finding the next record (1 for first).</param>
    /// <returns>True if a record was found, false otherwise.</returns>
    procedure FindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    begin
        if Position = 1 then
            Found := ServiceCrMemoHeader.FindSet()
        else
            Found := ServiceCrMemoHeader.Next() <> 0;
        if Found then
            PEPPOLManagement.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);

        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
    end;

    /// <summary>
    /// Maps service line types to corresponding sales line types for PEPPOL export.
    /// </summary>
    /// <param name="ServiceLineType">The service line type to map.</param>
    /// <returns>The corresponding sales line type.</returns>
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

    /// <summary>
    /// Finds the next service credit memo line record and transfers it to a sales line format.
    /// </summary>
    /// <param name="ServiceCrMemoLine">The service credit memo line record to iterate through.</param>
    /// <param name="SalesLine">The sales line record to populate with converted data.</param>
    /// <param name="Position">The position/index for finding the next line record (1 for first).</param>
    /// <returns>True if a line record was found, false otherwise.</returns>
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
