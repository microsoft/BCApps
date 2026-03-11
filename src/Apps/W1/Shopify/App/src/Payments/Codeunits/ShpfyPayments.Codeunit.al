// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Payments (ID 30169).
/// </summary>
codeunit 30169 "Shpfy Payments"
{
    Access = Internal;

    var
        Shop: Record "Shpfy Shop";
        PaymentsAPI: Codeunit "Shpfy Payments API";

    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        Shop := ShopifyShop;
        PaymentsAPI.SetShop(Shop);
    end;

    #region Payouts
    internal procedure SyncPayouts()
    begin
        UpdatePaymentTransactionPayoutIds();
        UpdatePendingPayouts();
        ImportNewPaymentTransactions();
        ImportNewPayouts();
    end;

    local procedure ImportNewPaymentTransactions()
    var
        PaymentTransaction: Record "Shpfy Payment Transaction";
        SinceId: BigInteger;
    begin
        PaymentTransaction.SetRange("Shop Code", Shop.Code);
        if PaymentTransaction.FindLast() then
            SinceId := PaymentTransaction.Id;
        PaymentsAPI.ImportPaymentTransactions(SinceId);
    end;

    local procedure ImportNewPayouts()
    var
        Payout: Record "Shpfy Payout";
        SinceId: BigInteger;
    begin
        if Payout.FindLast() then
            SinceId := Payout.Id;
        PaymentsAPI.ImportPayouts(SinceId);
    end;

    local procedure UpdatePaymentTransactionPayoutIds()
    var
        PaymentTransaction: Record "Shpfy Payment Transaction";
        PaymentTransactionIdFilter: Text;
        PaymentTransactionCount: Integer;
    begin
        PaymentTransaction.SetRange("Payout Id", 0);
        if PaymentTransaction.FindSet() then
            repeat
                if PaymentTransactionIdFilter <> '' then
                    PaymentTransactionIdFilter += ' OR ';
                PaymentTransactionIdFilter += Format(PaymentTransaction.Id);
                PaymentTransactionCount += 1;
                if PaymentTransactionCount = 200 then begin
                    PaymentsAPI.UpdatePaymentTransactionPayoutIds(PaymentTransactionIdFilter);
                    PaymentTransactionIdFilter := '';
                    PaymentTransactionCount := 0;
                end;
            until PaymentTransaction.Next() = 0;

        if PaymentTransactionIdFilter <> '' then
            PaymentsAPI.UpdatePaymentTransactionPayoutIds(PaymentTransactionIdFilter);
    end;

    local procedure UpdatePendingPayouts()
    var
        Payout: Record "Shpfy Payout";
        PayoutIdFilter: Text;
        PayoutCount: Integer;
    begin
        Payout.SetFilter(Status, '<>%1&<>%2', "Shpfy Payout Status"::Paid, "Shpfy Payout Status"::Canceled);
        if Payout.FindSet() then
            repeat
                if PayoutIdFilter <> '' then
                    PayoutIdFilter += ' OR ';
                PayoutIdFilter += Format(Payout.Id);
                PayoutCount += 1;
                if PayoutCount = 200 then begin
                    PaymentsAPI.UpdatePayoutStatuses(PayoutIdFilter);
                    PayoutIdFilter := '';
                    PayoutCount := 0;
                end;
            until Payout.Next() = 0;

        if PayoutIdFilter <> '' then
            PaymentsAPI.UpdatePayoutStatuses(PayoutIdFilter);
    end;
    #endregion

    #region Disputes
    internal procedure SyncDisputes()
    begin
        UpdateUnfinishedDisputes();
        ImportNewDisputes();
    end;

    local procedure UpdateUnfinishedDisputes()
    var
        Dispute: Record "Shpfy Dispute";
    begin
        Dispute.SetFilter("Status", '<>%1&<>%2', Dispute."Status"::Won, Dispute."Status"::Lost);
        if Dispute.FindSet() then
            repeat
                PaymentsAPI.UpdateDispute(Dispute.Id);
            until Dispute.Next() = 0;
    end;

    local procedure ImportNewDisputes()
    var
        Dispute: Record "Shpfy Dispute";
        SinceId: BigInteger;
    begin
        if Dispute.FindLast() then
            SinceId := Dispute.Id;
        PaymentsAPI.ImportDisputes(SinceId);
    end;
    #endregion
}