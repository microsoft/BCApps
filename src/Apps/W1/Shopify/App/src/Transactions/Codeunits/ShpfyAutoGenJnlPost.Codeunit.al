// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Posting;

/// <summary>
/// Codeunit Shpfy Auto Gen. Jnl.-Post (ID 30422).
/// Builds the general journal line(s) for a single Shopify order/refund payment transaction. It is invoked
/// through Codeunit.Run so that a failure while building is trapped and rolled back without leaving a line
/// behind. While bound, it also pre-confirms the "posting after working date" prompt so the automatic
/// posting stays non-interactive.
/// </summary>
codeunit 30422 "Shpfy Auto Gen. Jnl.-Post"
{
    Access = Internal;
    EventSubscriberInstance = Manual;
    TableNo = "Shpfy Order Transaction";

    trigger OnRun()
    begin
        BuildJournalLines(Rec);
    end;

    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        PostingDate: Date;

    internal procedure SetParameters(NewPaymentMethodMapping: Record "Shpfy Payment Method Mapping"; NewPostingDate: Date)
    begin
        PaymentMethodMapping := NewPaymentMethodMapping;
        PostingDate := NewPostingDate;
    end;

    local procedure BuildJournalLines(var OrderTransaction: Record "Shpfy Order Transaction")
    var
        SuggestPayments: Report "Shpfy Suggest Payments";
    begin
        SuggestPayments.SetJournalParameters(PaymentMethodMapping."Auto-Post Jnl. Template", PaymentMethodMapping."Auto-Post Jnl. Batch", PostingDate);
        SuggestPayments.GetOrderTransactions(OrderTransaction);
        SuggestPayments.CreateGeneralJournalLines();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeCheckLine', '', false, false)]
    local procedure PreconfirmWorkingDateOnBeforeCheckLine(var PostingAfterWorkingDateConfirmed: Boolean)
    begin
        PostingAfterWorkingDateConfirmed := true;
    end;
}
