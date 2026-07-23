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
/// Automatically posts Shopify order and refund payment transactions as general journal lines when
/// the related sales invoice or credit memo is posted, provided the transaction's payment method
/// mapping is configured for automatic posting. Posting is synchronous and best-effort: a failure to
/// post a payment is logged as a skipped record and never blocks or reverses the document posting.
/// </summary>
codeunit 30236 "Shpfy Auto Post Transactions"
{
    Access = Internal;

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

        OrderTransaction.SetRange("Refund Id", SalesCrMemoHeader."Shpfy Refund Id");
        OrderTransaction.SetRange(Type, OrderTransaction.Type::Refund);
        PostTransactions(OrderTransaction, SalesCrMemoHeader."Posting Date");
    end;

    local procedure PostTransactions(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date)
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        BoundaryCommitted: Boolean;
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        if not OrderTransaction.FindSet() then
            exit;

        repeat
            if GetAutoPostMapping(OrderTransaction, PaymentMethodMapping) then begin
                if not BoundaryCommitted then begin
                    // The posted document has already been committed by Sales-Post at this point.
                    // Commit again to establish a rollback boundary before best-effort payment posting,
                    // so a posting failure only rolls back to here and preserves the posted document and
                    // its Shopify document links.
                    Commit();
                    BoundaryCommitted := true;
                end;
                PostTransaction(OrderTransaction, PaymentMethodMapping, PostingDate);
            end;
        until OrderTransaction.Next() = 0;
    end;

    local procedure GetAutoPostMapping(OrderTransaction: Record "Shpfy Order Transaction"; var PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    begin
        if not PaymentMethodMapping.Get(OrderTransaction.Shop, OrderTransaction.Gateway, OrderTransaction."Credit Card Company") then
            exit(false);
        if not PaymentMethodMapping."Post Automatically" then
            exit(false);
        exit((PaymentMethodMapping."Auto-Post Jnl. Template" <> '') and (PaymentMethodMapping."Auto-Post Jnl. Batch" <> ''));
    end;

    local procedure PostTransaction(OrderTransaction: Record "Shpfy Order Transaction"; PaymentMethodMapping: Record "Shpfy Payment Method Mapping"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post";
        TemplateName: Code[10];
        BatchName: Code[10];
        ErrorText: Text;
    begin
        TemplateName := PaymentMethodMapping."Auto-Post Jnl. Template";
        BatchName := PaymentMethodMapping."Auto-Post Jnl. Batch";

        // Guard against lines left behind by a previously interrupted attempt for this transaction.
        RemoveJournalLines(TemplateName, BatchName, OrderTransaction."Shopify Transaction Id");

        AutoGenJnlPost.SetParameters(PaymentMethodMapping, PostingDate);
        BindSubscription(AutoGenJnlPost);

        // Build the journal line(s) through Codeunit.Run so a failure while building is trapped and rolled
        // back to the boundary commit instead of blocking the document posting.
        if not AutoGenJnlPost.Run(OrderTransaction) then begin
            ErrorText := GetLastErrorText();
            UnbindSubscription(AutoGenJnlPost);
            LogFailureAndCommit(OrderTransaction, ErrorText);
            exit;
        end;

        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Shpfy Transaction Id", OrderTransaction."Shopify Transaction Id");
        if GenJournalLine.IsEmpty() then begin
            UnbindSubscription(AutoGenJnlPost);
            exit;
        end;
        GenJournalLine.SetRange("Shpfy Transaction Id");
        GenJournalLine.FindSet();

        // Commit the built line(s) so the batch posting - which commits internally - runs in a valid
        // transaction context (matching the platform's own SendToPosting behavior).
        Commit();

        if GenJnlPostBatch.Run(GenJournalLine) then begin
            UnbindSubscription(AutoGenJnlPost);
            exit;
        end;
        ErrorText := GetLastErrorText();
        UnbindSubscription(AutoGenJnlPost);

        // Posting failed after the line(s) were committed: remove them and log the failure without
        // blocking or reversing the document posting.
        RemoveJournalLines(TemplateName, BatchName, OrderTransaction."Shopify Transaction Id");
        LogFailureAndCommit(OrderTransaction, ErrorText);
    end;

    local procedure RemoveJournalLines(TemplateName: Code[10]; BatchName: Code[10]; ShopifyTransactionId: BigInteger)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        GenJournalLine.SetRange("Shpfy Transaction Id", ShopifyTransactionId);
        if not GenJournalLine.IsEmpty() then
            GenJournalLine.DeleteAll(true);
    end;

    local procedure LogFailureAndCommit(OrderTransaction: Record "Shpfy Order Transaction"; ErrorText: Text)
    var
        Shop: Record "Shpfy Shop";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
    begin
        if Shop.Get(OrderTransaction.Shop) then
            SkippedRecord.LogSkippedRecord(OrderTransaction."Shopify Transaction Id", OrderTransaction.RecordId, CopyStr(ErrorText, 1, 250), Shop);
        // Commit the log (and any cleanup) so a subsequent transaction's rollback cannot discard it.
        Commit();
    end;
}
