// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

/// <summary>
/// Codeunit Shpfy Auto Post Transactions (ID 30236).
/// Automatically posts Shopify order and refund payment transactions as general journal lines when
/// the related sales invoice or credit memo is posted, provided the transaction's payment method
/// mapping is configured for automatic posting. Posting is synchronous and best-effort: a failure to
/// post a payment is logged as a skipped record and never blocks or reverses the document posting.
/// Each transaction is posted through a dedicated, single-use journal batch so that only the generated
/// lines are posted and pre-existing lines in the configured batch are never touched.
/// </summary>
codeunit 30236 "Shpfy Auto Post Transactions"
{
    Access = Internal;
    Permissions = tabledata "Gen. Journal Batch" = rimd,
                  tabledata "Gen. Journal Line" = rimd;

    internal procedure AutoPostTransactions(SalesInvoiceHeaderNo: Code[20]; SalesCrMemoHeaderNo: Code[20])
    begin
        if SalesInvoiceHeaderNo <> '' then
            PostOrderTransactions(SalesInvoiceHeaderNo);
        if SalesCrMemoHeaderNo <> '' then
            PostRefundTransactions(SalesCrMemoHeaderNo);
    end;

    local procedure PostOrderTransactions(SalesInvoiceHeaderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        if not SalesInvoiceHeader.Get(SalesInvoiceHeaderNo) then
            exit;
        if SalesInvoiceHeader."Shpfy Order Id" = 0 then
            exit;

        // Defer until all sales documents for the order are posted, so a partial invoice can't consume the whole transaction.
        if OpenSalesDocumentExistsForOrder(SalesInvoiceHeader."Shpfy Order Id") then
            exit;

        OrderTransaction.SetRange("Shopify Order Id", SalesInvoiceHeader."Shpfy Order Id");
        OrderTransaction.SetFilter(Type, '%1|%2', OrderTransaction.Type::Capture, OrderTransaction.Type::Sale);
        PostTransactions(OrderTransaction, SalesInvoiceHeader."Posting Date");
    end;

    local procedure PostRefundTransactions(SalesCrMemoHeaderNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OrderTransaction: Record "Shpfy Order Transaction";
    begin
        if not SalesCrMemoHeader.Get(SalesCrMemoHeaderNo) then
            exit;
        if SalesCrMemoHeader."Shpfy Refund Id" = 0 then
            exit;

        // Defer until all credit memos for the refund are posted.
        if OpenSalesDocumentExistsForRefund(SalesCrMemoHeader."Shpfy Refund Id") then
            exit;

        OrderTransaction.SetRange("Refund Id", SalesCrMemoHeader."Shpfy Refund Id");
        OrderTransaction.SetRange(Type, OrderTransaction.Type::Refund);
        PostTransactions(OrderTransaction, SalesCrMemoHeader."Posting Date");
    end;

    local procedure OpenSalesDocumentExistsForOrder(ShopifyOrderId: BigInteger): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Shpfy Order Id", ShopifyOrderId);
        exit(not SalesHeader.IsEmpty());
    end;

    local procedure OpenSalesDocumentExistsForRefund(ShopifyRefundId: BigInteger): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Shpfy Refund Id", ShopifyRefundId);
        exit(not SalesHeader.IsEmpty());
    end;

    local procedure PostTransactions(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post";
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        if not OrderTransaction.FindSet() then
            exit;

        // Bind once per document; unbind after the loop is safe because PostTransaction never raises.
        BindSubscription(AutoGenJnlPost);
        repeat
            if GetAutoPostMapping(OrderTransaction, PaymentMethodMapping) then
                PostTransaction(AutoGenJnlPost, OrderTransaction, PaymentMethodMapping, PostingDate);
        until OrderTransaction.Next() = 0;
        UnbindSubscription(AutoGenJnlPost);
    end;

    local procedure GetAutoPostMapping(OrderTransaction: Record "Shpfy Order Transaction"; var PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    begin
        if not PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company") then
            exit(false);
        if not PaymentMethodMapping."Post Automatically" then
            exit(false);
        exit((PaymentMethodMapping."Auto-Post Jnl. Template" <> '') and (PaymentMethodMapping."Auto-Post Jnl. Batch" <> ''));
    end;

    local procedure PostTransaction(var AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post"; OrderTransaction: Record "Shpfy Order Transaction"; PaymentMethodMapping: Record "Shpfy Payment Method Mapping"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        TemplateName: Code[10];
        BatchName: Code[10];
        ErrorText: Text;
    begin
        // Build into a single-use batch via Codeunit.Run so any failure is trapped and rolled back.
        AutoGenJnlPost.SetParameters(PaymentMethodMapping, PostingDate);
        if not AutoGenJnlPost.Run(OrderTransaction) then begin
            LogFailure(OrderTransaction, GetLastErrorText());
            exit;
        end;

        AutoGenJnlPost.GetIsolatedBatch(TemplateName, BatchName);
        if BatchName = '' then
            exit;

        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if not GenJournalLine.FindSet() then begin
            RemoveIsolatedBatch(TemplateName, BatchName);
            exit;
        end;

        // Commit the lines first: batch posting commits internally.
        Commit();

        if GenJnlPostBatch.Run(GenJournalLine) then begin
            RemoveIsolatedBatch(TemplateName, BatchName);
            exit;
        end;

        // Posting failed after commit: drop the batch and log, without affecting the posted document.
        ErrorText := GetLastErrorText();
        RemoveIsolatedBatch(TemplateName, BatchName);
        LogFailure(OrderTransaction, ErrorText);
    end;

    local procedure RemoveIsolatedBatch(TemplateName: Code[10]; BatchName: Code[10])
    var
        IsolatedBatch: Record "Gen. Journal Batch";
    begin
        // Delete cascades to leftover lines; commit so a later rollback can't resurrect the batch.
        if IsolatedBatch.Get(TemplateName, BatchName) then
            IsolatedBatch.Delete(true);
        Commit();
    end;

    local procedure LogFailure(OrderTransaction: Record "Shpfy Order Transaction"; ErrorText: Text)
    var
        Shop: Record "Shpfy Shop";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
    begin
        if Shop.Get(OrderTransaction.Shop) then
            SkippedRecord.LogSkippedRecord(OrderTransaction."Shopify Transaction Id", OrderTransaction.RecordId, CopyStr(ErrorText, 1, 250), Shop);
        Commit();
    end;
}
