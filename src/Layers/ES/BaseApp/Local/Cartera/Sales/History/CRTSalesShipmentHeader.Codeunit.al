// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;

codeunit 7000105 "CRT Sales Shipment Header"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Header", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        CustLedgEntry.SetRange("Bill No.", SalesShipmentHeader."Applies-to Bill No.");
    end;

}