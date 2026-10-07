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
/// Each transaction is posted through a dedicated, single-use journal batch so that only the generated
/// lines are posted and pre-existing lines in the configured batch are never touched.
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
        AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post";
        AutoPostEligibility: Codeunit "Shpfy Auto Post Eligibility";
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        OrderTransaction.SetLoadFields("Shopify Order Id", Shop, Gateway, "Credit Card Company", Type, Status, "Refund Id");
        OrderTransaction.SetAutoCalcFields(Used);
        if not OrderTransaction.FindSet() then
            exit;

        repeat
            if AutoPostEligibility.GetPaymentMethodMapping(OrderTransaction, PaymentMethodMapping) then
                if PaymentMethodMapping."Post Automatically" then
                    if not AutoPostEligibility.IsMappingConfigured(PaymentMethodMapping) then
                        RecordFailure(OrderTransaction, '', '', IncompleteSetupReasonLbl)
                    else
                        if AutoPostEligibility.IsTransactionPostable(OrderTransaction) then
                            PostTransaction(AutoGenJnlPost, OrderTransaction, PaymentMethodMapping, PostingDate);
        until OrderTransaction.Next() = 0;
    end;

    local procedure PostTransaction(var AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post"; OrderTransaction: Record "Shpfy Order Transaction"; PaymentMethodMapping: Record "Shpfy Payment Method Mapping"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        TemplateName: Code[10];
        BatchName: Code[10];
        ErrorText: Text;
        BuildSucceeded: Boolean;
        PostingSucceeded: Boolean;
    begin
        AutoGenJnlPost.SetParameters(PaymentMethodMapping, PostingDate);
        BindSubscription(AutoGenJnlPost);
        BuildSucceeded := AutoGenJnlPost.Run(OrderTransaction);
        if not BuildSucceeded then
            ErrorText := GetLastErrorText();
        UnbindSubscription(AutoGenJnlPost);
        if not BuildSucceeded then begin
            RecordFailure(OrderTransaction, '', '', ErrorText);
            exit;
        end;

        AutoGenJnlPost.GetIsolatedBatch(TemplateName, BatchName);
        if BatchName = '' then
            exit;

        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetRange("Journal Batch Name", BatchName);
        if not GenJournalLine.FindSet() then begin
            CleanupBatch(OrderTransaction, TemplateName, BatchName);
            exit;
        end;

        BindSubscription(AutoGenJnlPost);
        PostingSucceeded := GenJnlPostBatch.Run(GenJournalLine);
        if not PostingSucceeded then
            ErrorText := GetLastErrorText();
        UnbindSubscription(AutoGenJnlPost);
        if PostingSucceeded then begin
            CleanupBatch(OrderTransaction, TemplateName, BatchName);
            exit;
        end;

        RecordFailure(OrderTransaction, TemplateName, BatchName, ErrorText);
    end;

    local procedure RecordFailure(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; ErrorText: Text)
    begin
        if BatchName <> '' then
            CleanupBatch(OrderTransaction, TemplateName, BatchName);
        PersistFailure(OrderTransaction, ErrorText);
    end;

    local procedure CleanupBatch(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10])
    var
        AutoPostFinalize: Codeunit "Shpfy Auto Post Finalize";
        FinalizeErrorCode: Text;
    begin
        AutoPostFinalize.SetCleanupParameters(TemplateName, BatchName);
        if AutoPostFinalize.Run(OrderTransaction) then
            exit;

        FinalizeErrorCode := GetLastErrorCode();
        LogFinalizationFailureTelemetry(CleanupStageTok, FinalizeErrorCode);
    end;

    local procedure PersistFailure(OrderTransaction: Record "Shpfy Order Transaction"; ErrorText: Text)
    var
        AutoPostFinalize: Codeunit "Shpfy Auto Post Finalize";
        FinalizeErrorCode: Text;
    begin
        AutoPostFinalize.SetFailureParameters(ErrorText);
        if AutoPostFinalize.Run(OrderTransaction) then
            exit;

        FinalizeErrorCode := GetLastErrorCode();
        LogFinalizationFailureTelemetry(FailureLogStageTok, FinalizeErrorCode);
    end;

    local procedure LogFinalizationFailureTelemetry(Stage: Text; ErrorCode: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('Category', CategoryTok);
        CustomDimensions.Add('Stage', Stage);
        CustomDimensions.Add('ErrorCode', ErrorCode);
        Session.LogMessage('0000S2B', AutoPostFinalizationFailedTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    var
        AutoPostFinalizationFailedTelemetryMsg: Label 'Finalizing a failed automatic Shopify transaction posting attempt failed.', Locked = true;
        IncompleteSetupReasonLbl: Label 'Automatic posting is enabled, but the journal template or journal batch is not configured.';
        CategoryTok: Label 'Shopify Integration', Locked = true;
        CleanupStageTok: Label 'Cleanup journal batch', Locked = true;
        FailureLogStageTok: Label 'Log skipped record', Locked = true;
}
