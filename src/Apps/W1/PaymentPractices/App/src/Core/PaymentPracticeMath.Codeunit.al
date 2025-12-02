// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

codeunit 693 "Payment Practice Math"
{
    Access = internal;

    procedure GetPercentOfOnTimePayments(var PaymentPracticeData: Record "Payment Practice Data") Result: Decimal
    var
        Total: Integer;
        OnTimePayments: Integer;
    begin
        // On time payment is:
        // 1. Closing Payment date is less or equal to due date
        // Total is:
        // 1. All closed invoices
        // 2. Non-closed with due date in the past
        if PaymentPracticeData.FindSet() then
            repeat
                if (PaymentPracticeData."Pmt. Posting Date" <= PaymentPracticeData."Due Date") and (not PaymentPracticeData."Invoice Is Open") then
                    OnTimePayments += 1;
                if not PaymentPracticeData."Invoice Is Open" then
                    Total += 1
                else
                    if PaymentPracticeData."Due Date" < WorkDate() then
                        Total += 1;
            until PaymentPracticeData.Next() = 0;
        if Total > 0 then
            Result := OnTimePayments / Total * 100;
    end;

    procedure GetAverageActualPaymentTime(var PaymentPracticeData: Record "Payment Practice Data") Result: Integer
    var
        ActualPaymentTimes: List of [Integer];
    begin
        // Consider only closed invoices, because only they have actual payment time
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
        Result := Average(ActualPaymentTimes);
        PaymentPracticeData.SetRange("Invoice Is Open");
    end;

    procedure GetAverageAgreedPaymentTime(var PaymentPracticeData: Record "Payment Practice Data") Result: Integer
    var
        AgreedPaymentTimes: List of [Integer];
    begin
        // Consider all invoices, because all of them have some agreed payment time
        if PaymentPracticeData.FindSet() then
            repeat
                AgreedPaymentTimes.Add(PaymentPracticeData."Agreed Payment Days");
            until PaymentPracticeData.Next() = 0;
        Result := Average(AgreedPaymentTimes);
    end;

    procedure Average(var List: List of [Integer]): Integer
    begin
        if List.Count() = 0 then
            exit(0);
        exit(Round(Sum(List) / List.Count(), 1));
    end;

    procedure Sum(var List: List of [Integer]) Total: Integer
    var
        Number: Integer;
    begin
        foreach Number in List do
            Total += Number;
    end;

    procedure GetTotalNumberOfPayments(HeaderNo: Integer; StartingDate: Date; EndingDate: Date) Result: Integer
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
    begin
        // Count payment applications made during the reporting period
        PaymentPracticePmtData.SetRange("Header No.", HeaderNo);
        PaymentPracticePmtData.SetRange("Payment Posting Date", StartingDate, EndingDate);
        Result := PaymentPracticePmtData.Count();
    end;

    procedure GetTotalAmountOfPayments(HeaderNo: Integer; StartingDate: Date; EndingDate: Date) Result: Decimal
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
    begin
        // Sum of applied amounts for payments made during the reporting period
        PaymentPracticePmtData.SetRange("Header No.", HeaderNo);
        PaymentPracticePmtData.SetRange("Payment Posting Date", StartingDate, EndingDate);
        PaymentPracticePmtData.CalcSums("Applied Amount");
        Result := PaymentPracticePmtData."Applied Amount";
    end;

    procedure GetTotalAmountOfLatePayments(HeaderNo: Integer; StartingDate: Date; EndingDate: Date) Result: Decimal
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
    begin
        // Sum of applied amounts for late payments made during the reporting period
        PaymentPracticePmtData.SetRange("Header No.", HeaderNo);
        PaymentPracticePmtData.SetRange("Payment Posting Date", StartingDate, EndingDate);
        PaymentPracticePmtData.SetRange("Is Late", true);
        PaymentPracticePmtData.CalcSums("Applied Amount");
        Result := PaymentPracticePmtData."Applied Amount";
    end;

    procedure GetPctLateDueToDispute(HeaderNo: Integer; StartingDate: Date; EndingDate: Date) Result: Decimal
    var
        PaymentPracticePmtData: Record "Payment Practice Pmt. Data";
        TotalLate: Integer;
        LateDueToDispute: Integer;
    begin
        // Percentage of late payments (during reporting period) that are due to disputes
        PaymentPracticePmtData.SetRange("Header No.", HeaderNo);
        PaymentPracticePmtData.SetRange("Payment Posting Date", StartingDate, EndingDate);
        PaymentPracticePmtData.SetRange("Is Late", true);
        TotalLate := PaymentPracticePmtData.Count();
        if TotalLate > 0 then begin
            PaymentPracticePmtData.SetRange("Late Due to Dispute", true);
            LateDueToDispute := PaymentPracticePmtData.Count();
            Result := LateDueToDispute / TotalLate * 100;
        end;
    end;
}
