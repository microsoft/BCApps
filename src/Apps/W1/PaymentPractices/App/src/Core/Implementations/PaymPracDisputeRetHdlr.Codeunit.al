// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;

codeunit 681 "Paym. Prac. Dispute Ret. Hdlr" implements PaymentPracticeSchemeHandler
{
    Access = Internal;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        // Dispute & Retention: no additional header type restrictions
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if PaymentPracticeData."Source Type" <> PaymentPracticeData."Source Type"::Vendor then
            exit(true);

        VendorLedgerEntry.SetLoadFields("SCF Payment Date", "Dispute Status");
        if VendorLedgerEntry.Get(PaymentPracticeData."Invoice Entry No.") then begin
            PaymentPracticeData."SCF Payment Date" := VendorLedgerEntry."SCF Payment Date";
            PaymentPracticeData."Dispute Status" := VendorLedgerEntry."Dispute Status";

            if PaymentPracticeData."SCF Payment Date" <> 0D then
                PaymentPracticeData."Actual Payment Days" := PaymentPracticeData."SCF Payment Date" - PaymentPracticeData."Invoice Received Date";
        end;

        exit(true);
    end;

    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        TotalPayments: Integer;
        TotalAmount: Decimal;
        TotalOverdueAmount: Decimal;
        OverdueCount: Integer;
        OverdueDueToDisputeCount: Integer;
    begin
        if PaymentPracticeData.FindSet() then
            repeat
                if not PaymentPracticeData."Invoice Is Open" then begin
                    TotalPayments += 1;
                    TotalAmount += PaymentPracticeData."Invoice Amount";
                    if PaymentPracticeData."Actual Payment Days" > PaymentPracticeData."Agreed Payment Days" then begin
                        OverdueCount += 1;
                        TotalOverdueAmount += PaymentPracticeData."Invoice Amount";
                        PaymentPracticeData."Overdue Due to Dispute" := PaymentPracticeData."Dispute Status" <> '';
                        PaymentPracticeData.Modify();
                        if PaymentPracticeData."Dispute Status" <> '' then
                            OverdueDueToDisputeCount += 1;
                    end;
                end;
            until PaymentPracticeData.Next() = 0;

        PaymentPracticeHeader."Total Number of Payments" := TotalPayments;
        PaymentPracticeHeader."Total Amount of Payments" := TotalAmount;
        PaymentPracticeHeader."Total Amt. of Overdue Payments" := TotalOverdueAmount;
        if OverdueCount > 0 then
            PaymentPracticeHeader."Pct Overdue Due to Dispute" := OverdueDueToDisputeCount / OverdueCount * 100;
    end;

    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
    begin
        // Dispute & Retention: no additional line totals
    end;
}
