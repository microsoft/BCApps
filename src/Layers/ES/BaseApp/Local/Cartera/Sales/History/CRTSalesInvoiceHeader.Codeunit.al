// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;

codeunit 7000104 "CRT Sales Invoice Header"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CustLedgEntry.SetRange("Bill No.", SalesInvoiceHeader."Applies-to Bill No.");
    end;

}