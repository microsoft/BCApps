// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.History;

/// <summary>
/// Codeunit Shpfy Auto Post Transactions (ID 30236).
/// </summary>
codeunit 30236 "Shpfy Auto Post Transactions"
{
    Access = Internal;

    internal procedure AutoPostTransactions(SalesInvoiceHeaderNo: Code[20]; SalesCrMemoHeaderNo: Code[20])
    begin
        if SalesInvoiceHeaderNo <> '' then
            PostOrderTransaction(SalesInvoiceHeaderNo);
        if SalesCrMemoHeaderNo <> '' then
            PostRefundTransaction(SalesCrMemoHeaderNo);
    end;

    local procedure PostOrderTransaction(SalesInvoiceHeaderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        if not SalesInvoiceHeader.Get(SalesInvoiceHeaderNo) then
            exit;

        if SalesInvoiceHeader."Shpfy Order Id" = 0 then
            exit;

        OrderTransaction.SetRange("Shopify Order Id", SalesInvoiceHeader."Shpfy Order Id");
        OrderTransaction.SetFilter(Type, '%1|%2', OrderTransaction.Type::Capture, OrderTransaction.Type::Sale);
        PostTransaction(OrderTransaction, SalesInvoiceHeader."Posting Date");
    end;

    local procedure PostRefundTransaction(SalesCrMemoHeaderNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        if not SalesCrMemoHeader.Get(SalesCrMemoHeaderNo) then
            exit;

        if SalesCrMemoHeader."Shpfy Refund Id" = 0 then
            exit;

        OrderTransaction.SetRange("Refund Id", SalesCrMemoHeader."Shpfy Refund Id");
        OrderTransaction.SetRange(Type, OrderTransaction.Type::Refund);
        PostTransaction(OrderTransaction, SalesCrMemoHeader."Posting Date");
    end;

    local procedure PostTransaction(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        if OrderTransaction.FindSet() then
            repeat
                if ShouldAutoPost(OrderTransaction) then
                    CreateAndPostJournalLine(OrderTransaction, PostingDate);
            until OrderTransaction.Next() = 0;
    end;

    local procedure ShouldAutoPost(OrderTransaction: Record "Shpfy Order Transaction"): Boolean
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        if not PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company") then
            exit(false);

        if not PaymentMethodMapping."Post Automatically" then
            exit(false);

        if (PaymentMethodMapping."Auto-Post Jnl. Template" = '') or
           (PaymentMethodMapping."Auto-Post Jnl. Batch" = '') then
            exit(false);

        exit(true);
    end;

    local procedure CreateAndPostJournalLine(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        SuggestPayments: Report "Shpfy Suggest Payments";
        AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post";
    begin
        PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company");
        SuggestPayments.SetJournalParameters(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch", PostingDate);
        SuggestPayments.GetOrderTransactions(OrderTransaction);
        SuggestPayments.CreateGeneralJournalLines();
        GenJournalLine.SetRange("Shpfy Transaction Id", OrderTransaction."Shopify Transaction Id");
        if GenJournalLine.FindFirst() then begin
            BindSubscription(AutoGenJnlPost);
            GenJournalLine.SendToPosting(Codeunit::"Gen. Jnl.-Post");
            UnbindSubscription(AutoGenJnlPost);
        end;
    end;
}