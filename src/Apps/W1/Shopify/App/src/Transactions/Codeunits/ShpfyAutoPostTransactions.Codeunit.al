// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.History;

codeunit 30236 "Shpfy Auto Post Transactions"
{
    Access = Internal;
    Permissions = TableData "Gen. Journal Line" = imd,
                  TableData "Gen. Journal Batch" = r;

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
        SalesInvoiceHeader.SetLoadFields("Shpfy Order Id", "Posting Date");
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
        SalesCrMemoHeader.SetLoadFields("Shpfy Refund Id", "Posting Date");
        if not SalesCrMemoHeader.Get(SalesCrMemoHeaderNo) then
            exit;

        if SalesCrMemoHeader."Shpfy Refund Id" = 0 then
            exit;

        OrderTransaction.SetRange("Refund Id", SalesCrMemoHeader."Shpfy Refund Id");
        OrderTransaction.SetRange(Type, OrderTransaction.Type::Refund);
        PostTransaction(OrderTransaction, SalesCrMemoHeader."Posting Date");
    end;

    local procedure PostTransaction(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    var
        Committed: Boolean;
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        OrderTransaction.SetAutoCalcFields("Payment Method");
        OrderTransaction.SetLoadFields(
            "Shopify Transaction Id", "Shopify Order Id", Type, Amount, "Rounding Amount",
            "Presentment Amount", "Presentment Rounding Amount", Gateway, "Credit Card Company",
            Shop, "Gift Card Id", "Refund Id");
        if OrderTransaction.FindSet() then
            repeat
                if ShouldAutoPost(OrderTransaction) then begin
                    if not Committed then begin
                        // Firewall the just-completed sales post from any auto-post failure that follows.
                        Commit();
                        Committed := true;
                    end;
                    CreateAndPostJournalLine(OrderTransaction, PostingDate);
                end;
            until OrderTransaction.Next() = 0;
    end;

    local procedure ShouldAutoPost(OrderTransaction: Record "Shpfy Order Transaction"): Boolean
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        PaymentMethodMapping.SetLoadFields("Post Automatically", "Auto-Post Jnl. Template", "Auto-Post Jnl. Batch");
        if not PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company") then
            exit(false);

        if not PaymentMethodMapping."Post Automatically" then
            exit(false);

        if (PaymentMethodMapping."Auto-Post Jnl. Template" = '') or (PaymentMethodMapping."Auto-Post Jnl. Batch" = '') then
            exit(false);

        exit(true);
    end;

    local procedure CreateAndPostJournalLine(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        SuggestPayments: Report "Shpfy Suggest Payments";
    begin
        PaymentMethodMapping.SetLoadFields("Auto-Post Jnl. Template", "Auto-Post Jnl. Batch");
        PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company");
        SuggestPayments.SetJournalParameters(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch", PostingDate);
        SuggestPayments.GetOrderTransactions(OrderTransaction);
        SuggestPayments.CreateGeneralJournalLines();
        GenJournalLine.SetRange("Journal Template Name", PaymentMethodMapping."Auto-Post Jnl. Template");
        GenJournalLine.SetRange("Journal Batch Name", PaymentMethodMapping."Auto-Post Jnl. Batch");
        GenJournalLine.SetRange("Shpfy Transaction Id", OrderTransaction."Shopify Transaction Id");
        if GenJournalLine.FindFirst() then
            Codeunit.Run(Codeunit::"Gen. Jnl.-Post Line", GenJournalLine);
    end;
}
