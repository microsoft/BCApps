// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.History;

/// <summary>
/// Provides iteration over posted PEPPOL sales documents needed during export.
/// Currently exposes a method to find the next posted Sales Credit Memo header
/// and transfer its fields to a working <see cref="Record &quot;Sales Header&quot;"/> buffer.
/// </summary>
interface "PEPPOL Posted Document Iterator"
{
    /// <summary>
    /// Finds and transfers the next posted Sales Credit Memo header record into a Sales Header buffer.
    /// </summary>
    /// <param name="SalesCrMemoHeader">The posted Sales Credit Memo header source record (enumerated by the caller).</param>
    /// <param name="SalesHeader">Return value: The target Sales Header buffer populated from the credit memo header.</param>
    /// <param name="Position">Enumeration position (1 = first call, >1 = subsequent calls using current cursor).</param>
    /// <returns>True if a record was found; otherwise false.</returns>
    procedure FindNextSalesCreditMemoRec(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean;
    procedure FindNextSalesCreditMemoLineRec(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    procedure FindNextSalesInvoiceRec(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    procedure FindNextSalesInvoiceLineRec(var SalesInvoiceLine: Record "Sales Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
    procedure FindNextServiceCreditMemoRec(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
    procedure FindNextServiceCreditMemoLineRec(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var SalesLine: Record "Sales Line"; Position: Integer) Found: Boolean
    procedure FindNextServiceInvoiceRec(var ServiceInvoiceHeader: Record "Service Invoice Header"; var SalesHeader: Record "Sales Header"; Position: Integer) Found: Boolean
procedure FindNextServiceInvoiceLineRec(var ServiceInvoiceLine: Record Microsoft.Service.History."Service Invoice Line"; var SalesLine: Record "Sales Line"; Position: Integer): Boolean
}
