// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Codeunit Shpfy Auto Post Eligibility (ID 30424).
/// Keeps automatic-posting and transaction-list filtering predicates aligned.
/// </summary>
codeunit 30424 "Shpfy Auto Post Eligibility"
{
    Access = Internal;

    internal procedure IsReadyToPost(OrderTransaction: Record "Shpfy Order Transaction"; var PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    begin
        exit(
            GetPaymentMethodMapping(OrderTransaction, PaymentMethodMapping) and
            IsMappingConfigured(PaymentMethodMapping) and
            IsTransactionPostable(OrderTransaction));
    end;

    internal procedure GetPaymentMethodMapping(OrderTransaction: Record "Shpfy Order Transaction"; var PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    begin
        exit(PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company"));
    end;

    internal procedure IsMappingConfigured(PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    begin
        exit(
            PaymentMethodMapping."Post Automatically" and
            (PaymentMethodMapping."Auto-Post Jnl. Template" <> '') and
            (PaymentMethodMapping."Auto-Post Jnl. Batch" <> ''));
    end;

    internal procedure IsTransactionPostable(OrderTransaction: Record "Shpfy Order Transaction"): Boolean
    begin
        if OrderTransaction.Status <> OrderTransaction.Status::Success then
            exit(false);
        if not (OrderTransaction.Type in [OrderTransaction.Type::Capture, OrderTransaction.Type::Sale, OrderTransaction.Type::Refund]) then
            exit(false);

        if OrderTransaction.Used then
            exit(false);
        if OpenSalesDocumentExists(OrderTransaction) then
            exit(false);
        exit(PostedDocumentExists(OrderTransaction));
    end;

    local procedure OpenSalesDocumentExists(OrderTransaction: Record "Shpfy Order Transaction"): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        if OrderTransaction.Type = OrderTransaction.Type::Refund then begin
            if OrderTransaction."Refund Id" = 0 then
                exit(true);
            SalesHeader.SetRange("Shpfy Refund Id", OrderTransaction."Refund Id");
            exit(not SalesHeader.IsEmpty());
        end;

        if OrderTransaction."Shopify Order Id" = 0 then
            exit(true);
        SalesHeader.SetRange("Shpfy Order Id", OrderTransaction."Shopify Order Id");
        exit(not SalesHeader.IsEmpty());
    end;

    local procedure PostedDocumentExists(OrderTransaction: Record "Shpfy Order Transaction"): Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if OrderTransaction.Type = OrderTransaction.Type::Refund then begin
            SalesCrMemoHeader.SetRange("Shpfy Refund Id", OrderTransaction."Refund Id");
            exit(not SalesCrMemoHeader.IsEmpty());
        end;

        SalesInvoiceHeader.SetRange("Shpfy Order Id", OrderTransaction."Shopify Order Id");
        exit(not SalesInvoiceHeader.IsEmpty());
    end;
}
