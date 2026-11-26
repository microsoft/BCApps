// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Customer;

/// <summary>
/// Handles Intercompany subscriber logic for Sales Header.
/// </summary>
codeunit 8480 "IC Sales Header"
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnValidateSellToCustomerNoOnBeforeValidateLocationCode', '', false, false)]
    local procedure OnValidateSellToCustomerNoOnBeforeValidateLocationCode(var SalesHeader: Record "Sales Header"; var Cust: Record Customer; var IsHandled: Boolean; xSalesHeader: Record "Sales Header"; var LocationCode: Code[10])
    begin
        SalesHeader."Sell-to IC Partner Code" := Cust."IC Partner Code";
        SalesHeader."Send IC Document" := (SalesHeader."Sell-to IC Partner Code" <> '') and (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnValidateBillToCustomerNoOnBeforeUpdateSendICDocument', '', false, false)]
    local procedure OnValidateBillToCustomerNoOnBeforeUpdateSendICDocument(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader."Bill-to IC Partner Code" := Customer."IC Partner Code";
        SalesHeader."Send IC Document" := (SalesHeader."Bill-to IC Partner Code" <> '') and (SalesHeader."IC Direction" = SalesHeader."IC Direction"::Outgoing);
    end;
}
