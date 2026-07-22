// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Receivables;

codeunit 7000103 "CRT Sales Cr. Memo Header"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Cr.Memo Header", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        CustLedgEntry.SetRange("Bill No.", SalesCrMemoHeader."Applies-to Bill No.");
    end;
}