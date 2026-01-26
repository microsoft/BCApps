// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Receivables;

codeunit 10788 "Sales Document Subscr. ES"
{

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateAppliesToDocNo', '', true, true)]
    local procedure OnAfterValidateAppliesToDocNo(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        SalesHeader."Applies-to Bill No." := CustLedgEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterSetApplyToFilters', '', true, true)]
    local procedure OnAfterSetApplyToFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; SalesHeader: Record "Sales Header")
    begin
        if (SalesHeader."Applies-to Doc. No." <> '') and (SalesHeader."Applies-to Bill No." <> '') then begin
            CustLedgerEntry.SetRange("Bill No.", SalesHeader."Applies-to Bill No.");
            if CustLedgerEntry.FindFirst() then;
        end;
    end;
}