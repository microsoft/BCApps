// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139566 "Shpfy Payments Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure UnitTestImportPayoutWithExternalTraceId()
    var
        Payout: Record "Shpfy Payout";
        PaymentsAPI: Codeunit "Shpfy Payments API";
        Id: BigInteger;
        ExpectedExternalTraceId: Text;
        JPayout: JsonObject;
    begin
        // [SCENARIO] Import payout correctly imports the externalTraceId field (2026-01 API)
        // [GIVEN] A random Generated Payout with externalTraceId
        Id := Any.IntegerInRange(10000, 99999);
        ExpectedExternalTraceId := Any.AlphanumericText(50);
        JPayout := GetRandomPayout(Id, ExpectedExternalTraceId);

        // [WHEN] Invoke the function ImportPayout(JPayout)
        PaymentsAPI.ImportPayout(JPayout);

        // [THEN] We must find the "Shpfy Payout" record with the correct externalTraceId
        LibraryAssert.IsTrue(Payout.Get(Id), 'Get "Shpfy Payout" record');
        LibraryAssert.AreEqual(ExpectedExternalTraceId, Payout."External Trace Id", 'External Trace Id should match');
    end;

    local procedure GetRandomPayout(Id: BigInteger; ExternalTraceId: Text): JsonObject
    var
        JPayout: JsonObject;
        JNet: JsonObject;
        JSummary: JsonObject;
        JAmount: JsonObject;
        PayoutGidTxt: Label 'gid://shopify/ShopifyPaymentsPayout/%1', Comment = '%1 = id', Locked = true;
    begin
        JPayout.Add('id', StrSubstNo(PayoutGidTxt, Id));
        JPayout.Add('status', 'SCHEDULED');
        JPayout.Add('externalTraceId', ExternalTraceId);
        JPayout.Add('issuedAt', Format(Today, 0, 9));
        JNet.Add('amount', Any.DecimalInRange(1000, 2));
        JNet.Add('currencyCode', 'USD');
        JPayout.Add('net', JNet);
        
        // Add summary with fee/gross amounts
        JAmount.Add('amount', 0);
        JSummary.Add('adjustmentsFee', JAmount);
        JSummary.Add('adjustmentsGross', JAmount);
        JSummary.Add('chargesFee', JAmount);
        JSummary.Add('chargesGross', JAmount);
        JSummary.Add('refundsFee', JAmount);
        JSummary.Add('refundsFeeGross', JAmount);
        JSummary.Add('reservedFundsFee', JAmount);
        JSummary.Add('reservedFundsGross', JAmount);
        JSummary.Add('retriedPayoutsFee', JAmount);
        JSummary.Add('retriedPayoutsGross', JAmount);
        JPayout.Add('summary', JSummary);
        
        exit(JPayout);
    end;

    [Test]
    procedure UnitTestImportPayment()
    var
        PaymentTransaction: Record "Shpfy Payment Transaction";
        PaymentsAPI: Codeunit "Shpfy Payments API";
        Id: BigInteger;
        JPayment: JsonObject;
    begin
        // [SCENARIO] Extract the data out json token that contains a payment info into the "Shpfy Payment Transaction" record.
        // [GIVEN] A random Generated Payment
        Id := Any.IntegerInRange(10000, 99999);
        JPayment := GetRandomPayment(Id);

        // [WHEN] Invoke the function ImportPaymentTransaction(JPayment)
        PaymentsAPI.ImportPaymentTransaction(JPayment);

        // [THEN] We must find the "Shpfy Payment" record with the same id
        LibraryAssert.IsTrue(PaymentTransaction.Get(Id), 'Get "Shpfy Payment Transaction" record');
    end;

    [Test]
    procedure UnitTestImportDispute()
    var
        Dispute: Record "Shpfy Dispute";
        PaymentsAPI: Codeunit "Shpfy Payments API";
        JDispute: JsonObject;
        DisputeStatus: Enum "Shpfy Dispute Status";
        FinalizedOn: DateTime;
        Id: BigInteger;
    begin
        // [SCENARIO] Extract the data out json token that contains a Dispute info into the "Shpfy Dispute" record.
        // [GIVEN] A random Generated Dispute
        Id := Any.IntegerInRange(10000, 99999);
        JDispute := GetRandomDispute(Id, DisputeStatus, FinalizedOn);

        // [WHEN] Invoke the function ImportDispute(JToken)
        PaymentsAPI.ImportDispute(JDispute);

        // // [THEN] A dispute record is created and the dispute status and finalized on should match the generated one
        Dispute.Get(Id);
        LibraryAssert.AreEqual(DisputeStatus, Dispute.Status, 'Dispute status should match the generated one');
        LibraryAssert.AreEqual(FinalizedOn, Dispute."Finalized On", 'Dispute finalized on should match the generated one');
    end;

    local procedure GetRandomPayment(id: BigInteger): JsonObject
    var
        JPayment: JsonObject;
        JAssociatedPayout: JsonObject;
        JAmount: JsonObject;
        JFee: JsonObject;
        JNet: JsonObject;
        JAssociatedOrder: JsonObject;
        PaymentGidTxt: Label 'gid://shopify/ShopifyPaymentsBalanceTransaction/%1', Comment = '%1 = id', Locked = true;
        PayoutGidTxt: Label 'gid://shopify/ShopifyPaymentsPayout/%1', Comment = '%1 = id', Locked = true;
        OrderGidTxt: Label 'gid://shopify/Order/%1', Comment = '%1 = id', Locked = true;
        Amount: Decimal;
        Fee: Decimal;
    begin
        Amount := Any.DecimalInRange(100, 2);
        Fee := Any.DecimalInRange(Round(Amount, 1, '<'), 2);
        JPayment.Add('id', StrSubstNo(PaymentGidTxt, id));
        JPayment.Add('transactionDate', Format(CurrentDateTime - 1, 0, 9));
        JPayment.Add('test', false);
        JAssociatedPayout.Add('id', StrSubstNo(PayoutGidTxt, Any.IntegerInRange(10000, 99999)));
        JPayment.Add('associatedPayout', JAssociatedPayout);
        JAmount.Add('amount', Amount);
        JAmount.Add('currencyCode', 'USD');
        JPayment.Add('amount', JAmount);
        JFee.Add('amount', Fee);
        JFee.Add('currencyCode', 'USD');
        JPayment.Add('fee', JFee);
        JNet.Add('amount', Amount - Fee);
        JNet.Add('currencyCode', 'USD');
        JPayment.Add('net', JNet);
        JPayment.Add('type', Format(Enum::"Shpfy Payment Trans. Type".FromInteger(Any.IntegerInRange(0, 6))));
        JPayment.Add('sourceId', Any.IntegerInRange(10000, 99999));
        JAssociatedOrder.Add('id', StrSubstNo(OrderGidTxt, Any.IntegerInRange(10000, 99999)));
        JPayment.Add('associatedOrder', JAssociatedOrder);
        JPayment.Add('sourceOrderTransactionId', Any.IntegerInRange(10000, 99999));
        exit(JPayment);
    end;

    local procedure GetRandomDispute(Id: BigInteger; var DisputeStatus: Enum "Shpfy Dispute Status"; var FinalizedOn: DateTime): JsonObject
    var
        JDispute: JsonObject;
        JOrder: JsonObject;
        JAmount: JsonObject;
        JReasonDetails: JsonObject;
        DisputeGidTxt: Label 'gid://ShopifyPaymentsDispute/Order/%1', Comment = '%1 = id', Locked = true;
        OrderGidTxt: Label 'gid://shopify/Order/%1', Comment = '%1 = id', Locked = true;
    begin
        DisputeStatus := Enum::"Shpfy Dispute Status".FromInteger(Any.IntegerInRange(0, 6));
        FinalizedOn := CurrentDateTime - 1;
        JDispute.Add('id', StrSubstNo(DisputeGidTxt, Id));
        JOrder.Add('id', StrSubstNo(OrderGidTxt, Any.IntegerInRange(10000, 99999)));
        JDispute.Add('order', JOrder);
        JDispute.Add('type', 'chargeback');
        JAmount.Add('amount', Any.DecimalInRange(100, 2));
        JAmount.Add('currencyCode', 'USD');
        JDispute.Add('amount', JAmount);
        JReasonDetails.Add('reason', 'fraudulent');
        JReasonDetails.Add('networkReasonCode', Any.IntegerInRange(10000, 99999));
        JDispute.Add('reasonDetails', JReasonDetails);
        JDispute.Add('status', Format(DisputeStatus));
        JDispute.Add('evidenceDueBy', Format(CurrentDateTime - 1, 0, 9));
        JDispute.Add('evidenceSentOn', Format(CurrentDateTime - 1, 0, 9));
        JDispute.Add('finalizedOn', Format(FinalizedOn, 0, 9));
        exit(JDispute);
    end;
}