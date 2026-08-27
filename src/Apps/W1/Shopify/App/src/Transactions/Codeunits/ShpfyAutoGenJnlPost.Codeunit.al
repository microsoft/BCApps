// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

/// <summary>
/// Codeunit Shpfy Auto Gen. Jnl.-Post (ID 30422).
/// Creates a dedicated, single-use journal batch (cloned from the configured one) and builds the general
/// journal line(s) for a single Shopify order/refund payment transaction into it. It is invoked through
/// Codeunit.Run so that any failure while creating the batch or building lines is trapped and rolled back
/// without leaving a batch or line behind. While bound, it also pre-confirms the "posting after working
/// date" prompt so the automatic posting stays non-interactive.
/// </summary>
codeunit 30422 "Shpfy Auto Gen. Jnl.-Post"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    TableNo = "Shpfy Order Transaction";

    trigger OnRun()
    begin
        CreateBatchAndBuildLines(Rec);
    end;

    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        PostingDate: Date;
        IsolatedTemplateName: Code[10];
        IsolatedBatchName: Code[10];

    internal procedure SetParameters(NewPaymentMethodMapping: Record "Shpfy Payment Method Mapping"; NewPostingDate: Date)
    begin
        PaymentMethodMapping := NewPaymentMethodMapping;
        PostingDate := NewPostingDate;
        Clear(IsolatedTemplateName);
        Clear(IsolatedBatchName);
    end;

    internal procedure GetIsolatedBatch(var NewTemplateName: Code[10]; var NewBatchName: Code[10])
    begin
        NewTemplateName := IsolatedTemplateName;
        NewBatchName := IsolatedBatchName;
    end;

    local procedure CreateBatchAndBuildLines(var OrderTransaction: Record "Shpfy Order Transaction")
    var
        SuggestPayments: Report "Shpfy Suggest Payments";
    begin
        CreateIsolatedBatch();
        SuggestPayments.SetJournalParameters(IsolatedTemplateName, IsolatedBatchName, PostingDate);
        SuggestPayments.GetOrderTransactions(OrderTransaction);
        SuggestPayments.CreateGeneralJournalLines();
    end;

    local procedure CreateIsolatedBatch()
    var
        ConfiguredBatch: Record "Gen. Journal Batch";
        IsolatedBatch: Record "Gen. Journal Batch";
    begin
        ConfiguredBatch.Get(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch");
        IsolatedBatch := ConfiguredBatch;
        IsolatedBatch.Name := GetUniqueBatchName(ConfiguredBatch."Journal Template Name");
        IsolatedBatch.Insert(true);
        IsolatedTemplateName := IsolatedBatch."Journal Template Name";
        IsolatedBatchName := IsolatedBatch.Name;
    end;

    local procedure GetUniqueBatchName(TemplateName: Code[10]): Code[10]
    var
        ExistingBatch: Record "Gen. Journal Batch";
        CandidateName: Code[10];
    begin
        repeat
            CandidateName := CopyStr('SHPFY' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 5), 1, 10);
        until not ExistingBatch.Get(TemplateName, CandidateName);
        exit(CandidateName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeCheckLine', '', false, false)]
    local procedure PreconfirmWorkingDateOnBeforeCheckLine(var PostingAfterWorkingDateConfirmed: Boolean)
    begin
        PostingAfterWorkingDateConfirmed := true;
    end;
}
