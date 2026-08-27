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

    internal procedure AutoPostTransactions(SalesInvoiceHeaderNo: Code[20]; SalesCrMemoHeaderNo: Code[20]; HasJournalPermissions: Boolean)
    begin
        if SalesInvoiceHeaderNo <> '' then
            PostOrderTransactions(SalesInvoiceHeaderNo, HasJournalPermissions);
        if SalesCrMemoHeaderNo <> '' then
            PostRefundTransactions(SalesCrMemoHeaderNo, HasJournalPermissions);
    end;

    local procedure PostOrderTransactions(SalesInvoiceHeaderNo: Code[20]; HasJournalPermissions: Boolean)
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
        PostTransactions(OrderTransaction, SalesInvoiceHeader."Posting Date", HasJournalPermissions);
    end;

    local procedure PostRefundTransactions(SalesCrMemoHeaderNo: Code[20]; HasJournalPermissions: Boolean)
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
        PostTransactions(OrderTransaction, SalesCrMemoHeader."Posting Date", HasJournalPermissions);
    end;

    local procedure PostTransactions(var OrderTransaction: Record "Shpfy Order Transaction"; PostingDate: Date; HasJournalPermissions: Boolean)
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post";
        AutoPostEligibility: Codeunit "Shpfy Auto Post Eligibility";
    begin
        OrderTransaction.SetRange(Status, OrderTransaction.Status::Success);
        OrderTransaction.SetRange(Used, false);
        if not OrderTransaction.FindSet() then
            exit;

        repeat
            if AutoPostEligibility.GetPaymentMethodMapping(OrderTransaction, PaymentMethodMapping) then
                if PaymentMethodMapping."Post Automatically" then
                    if not AutoPostEligibility.IsMappingConfigured(PaymentMethodMapping) then
                        RecordFailure(OrderTransaction, '', '', ConfigurationStageTok, IncompleteSetupReasonLbl, '')
                    else
                        if AutoPostEligibility.IsTransactionPostable(OrderTransaction) then
                            if HasJournalPermissions then
                                PostTransaction(AutoGenJnlPost, OrderTransaction, PaymentMethodMapping, PostingDate)
                            else
                                RecordFailure(OrderTransaction, '', '', AuthorizationStageTok, InsufficientPermissionsReasonLbl, '');
        until OrderTransaction.Next() = 0;
    end;

    local procedure PostTransaction(var AutoGenJnlPost: Codeunit "Shpfy Auto Gen. Jnl.-Post"; OrderTransaction: Record "Shpfy Order Transaction"; PaymentMethodMapping: Record "Shpfy Payment Method Mapping"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        TemplateName: Code[10];
        BatchName: Code[10];
        ErrorText: Text;
        ErrorCallStack: Text;
        BuildSucceeded: Boolean;
        PostingSucceeded: Boolean;
    begin
        AutoGenJnlPost.SetParameters(PaymentMethodMapping, PostingDate);
        BindSubscription(AutoGenJnlPost);
        BuildSucceeded := AutoGenJnlPost.Run(OrderTransaction);
        if not BuildSucceeded then begin
            ErrorText := GetLastErrorText();
            ErrorCallStack := GetLastErrorCallStack();
        end;
        UnbindSubscription(AutoGenJnlPost);
        if not BuildSucceeded then begin
            RecordFailure(OrderTransaction, '', '', BuildStageTok, ErrorText, ErrorCallStack);
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
        if not PostingSucceeded then begin
            ErrorText := GetLastErrorText();
            ErrorCallStack := GetLastErrorCallStack();
        end;
        UnbindSubscription(AutoGenJnlPost);
        if PostingSucceeded then begin
            CleanupBatch(OrderTransaction, TemplateName, BatchName);
            exit;
        end;

        RecordFailure(OrderTransaction, TemplateName, BatchName, PostingStageTok, ErrorText, ErrorCallStack);
    end;

    local procedure RecordFailure(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; Stage: Text; ErrorText: Text; ErrorCallStack: Text)
    begin
        LogFailureTelemetry(OrderTransaction, TemplateName, BatchName, Stage, ErrorText, ErrorCallStack);
        if BatchName <> '' then
            CleanupBatch(OrderTransaction, TemplateName, BatchName);
        PersistFailure(OrderTransaction, TemplateName, BatchName, ErrorText);
    end;

    local procedure CleanupBatch(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10])
    var
        AutoPostFinalize: Codeunit "Shpfy Auto Post Finalize";
        FinalizeErrorText: Text;
        FinalizeErrorCallStack: Text;
    begin
        AutoPostFinalize.SetCleanupParameters(TemplateName, BatchName);
        if AutoPostFinalize.Run(OrderTransaction) then
            exit;

        FinalizeErrorText := GetLastErrorText();
        FinalizeErrorCallStack := GetLastErrorCallStack();
        LogFinalizationFailureTelemetry(OrderTransaction, TemplateName, BatchName, CleanupStageTok, FinalizeErrorText, FinalizeErrorCallStack);
    end;

    local procedure PersistFailure(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; ErrorText: Text)
    var
        AutoPostFinalize: Codeunit "Shpfy Auto Post Finalize";
        FinalizeErrorText: Text;
        FinalizeErrorCallStack: Text;
    begin
        AutoPostFinalize.SetFailureParameters(ErrorText);
        if AutoPostFinalize.Run(OrderTransaction) then
            exit;

        FinalizeErrorText := GetLastErrorText();
        FinalizeErrorCallStack := GetLastErrorCallStack();
        LogFinalizationFailureTelemetry(OrderTransaction, TemplateName, BatchName, FailureLogStageTok, FinalizeErrorText, FinalizeErrorCallStack);
    end;

    local procedure LogFailureTelemetry(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; Stage: Text; ErrorText: Text; ErrorCallStack: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CustomDimensions, OrderTransaction, TemplateName, BatchName, Stage, ErrorText, ErrorCallStack);
        Session.LogMessage('0000S2A', AutoPostFailedTelemetryMsg, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure LogFinalizationFailureTelemetry(OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; Stage: Text; ErrorText: Text; ErrorCallStack: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        AddTelemetryDimensions(CustomDimensions, OrderTransaction, TemplateName, BatchName, Stage, ErrorText, ErrorCallStack);
        Session.LogMessage('0000S2B', AutoPostFinalizationFailedTelemetryMsg, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure AddTelemetryDimensions(var CustomDimensions: Dictionary of [Text, Text]; OrderTransaction: Record "Shpfy Order Transaction"; TemplateName: Code[10]; BatchName: Code[10]; Stage: Text; ErrorText: Text; ErrorCallStack: Text)
    begin
        CustomDimensions.Add('Category', CategoryTok);
        CustomDimensions.Add('Stage', Stage);
        CustomDimensions.Add('Shop Code', OrderTransaction.Shop);
        CustomDimensions.Add('Shopify Transaction Id', Format(OrderTransaction."Shopify Transaction Id"));
        CustomDimensions.Add('Journal Template Name', TemplateName);
        CustomDimensions.Add('Journal Batch Name', BatchName);
        CustomDimensions.Add('Error Text', CopyStr(ErrorText, 1, 250));
        CustomDimensions.Add('Error Call Stack', CopyStr(ErrorCallStack, 1, 2048));
    end;

    var
        AutoPostFailedTelemetryMsg: Label 'Automatic Shopify transaction posting failed.', Locked = true;
        AutoPostFinalizationFailedTelemetryMsg: Label 'Finalizing a failed automatic Shopify transaction posting attempt failed.', Locked = true;
        IncompleteSetupReasonLbl: Label 'Automatic posting is enabled, but the journal template or journal batch is not configured.';
        InsufficientPermissionsReasonLbl: Label 'Automatic posting requires permission to read and write general journal batches and lines.';
        CategoryTok: Label 'Shopify Integration', Locked = true;
        AuthorizationStageTok: Label 'Authorization', Locked = true;
        BuildStageTok: Label 'Build journal lines', Locked = true;
        CleanupStageTok: Label 'Cleanup journal batch', Locked = true;
        ConfigurationStageTok: Label 'Configuration', Locked = true;
        FailureLogStageTok: Label 'Log skipped record', Locked = true;
        PostingStageTok: Label 'Post journal batch', Locked = true;
}
