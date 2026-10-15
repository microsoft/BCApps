// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Customer;

/// <summary>
/// NL-specific event subscribers for the Sales Header table.
/// Sets NL telebanking fields when the bill-to customer is updated.
/// </summary>
codeunit 11474 "Sales Header NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterSetFieldsBilltoCustomer', '', false, false)]
    local procedure OnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer; xSalesHeader: Record "Sales Header"; SkipBillToContact: Boolean; CurrentFieldNo: Integer)
    begin
        SalesHeader."Transaction Mode Code" := Customer."Transaction Mode Code";
        SalesHeader."Bank Account Code" := Customer."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateBillToCustomerPaymentFields', '', false, false)]
    local procedure OnAfterValidateBillToCustomerPaymentFields(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Transaction Mode Code");
    end;
}
