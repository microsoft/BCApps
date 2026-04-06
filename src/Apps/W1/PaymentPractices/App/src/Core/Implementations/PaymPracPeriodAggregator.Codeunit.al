// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Reporting;
using System.Telemetry;

codeunit 685 "Paym. Prac. Period Aggregator" implements PaymentPracticeLinesAggregator
{
    Access = Internal;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";

    procedure PrepareLayout();
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedLayout('PaymentPractice_PeriodLayout');
        FeatureTelemetry.LogUsage('0000KSU', 'Payment Practices', 'Period layout used.')
    end;

    procedure GenerateLines(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header");
    var
        PaymentPracticeLine: Record "Payment Practice Line";
        PaymentPeriodLine: Record "Payment Period Line";
        SchemeHandler: Interface PaymentPracticeSchemeHandler;
        SourceType: Integer;
        NextLineNo: Integer;
    begin
        NextLineNo := 1;
        SchemeHandler := PaymentPracticeHeader."Reporting Scheme";
        PaymentPeriodLine.SetRange("Period Header Code", PaymentPracticeHeader."Payment Period Code");
        PaymentPeriodLine.SetCurrentKey("Days From");
        PaymentPeriodLine.SetAscending("Days From", true);
        foreach SourceType in PaymentPracticeData."Source Type".Ordinals() do begin
            PaymentPracticeData.SetRange("Source Type", SourceType);
            if not PaymentPracticeData.IsEmpty() then
                if PaymentPeriodLine.FindSet() then
                    repeat
                        InsertPeriodLine(PaymentPracticeLine, PaymentPracticeData, PaymentPeriodLine, PaymentPracticeHeader."No.", NextLineNo, SourceType);
                        SchemeHandler.CalculateLineTotals(PaymentPracticeLine, PaymentPracticeData);
                        if PaymentPracticeLine."Invoice Count" <> 0 then
                            PaymentPracticeLine.Modify();
                        if PaymentPracticeLine."Invoice Value" <> 0 then
                            PaymentPracticeLine.Modify();
                    until PaymentPeriodLine.Next() = 0;
        end;
    end;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin

    end;

    local procedure InsertPeriodLine(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data"; PaymentPeriodLine: Record "Payment Period Line"; HeaderNo: Integer; var NextLineNo: Integer; SourceType: Integer)
    begin
        PaymentPracticeLine.Init();
        PaymentPracticeLine."Header No." := HeaderNo;
        PaymentPracticeLine."Line No." := NextLineNo;
        NextLineNo += 1;
        PaymentPracticeLine."Aggregation Type" := PaymentPracticeLine."Aggregation Type"::Period;
        PaymentPracticeLine."Payment Period Code" := PaymentPeriodLine."Period Header Code";
        PaymentPracticeLine."Payment Period Description" := PaymentPeriodLine.Description;
        SetPercentPaidInPeriod(PaymentPracticeData, PaymentPeriodLine."Days From", PaymentPeriodLine."Days To", PaymentPracticeLine."Pct Paid in Period", PaymentPracticeLine."Pct Paid in Period (Amount)");
        PaymentPracticeLine."Source Type" := "Paym. Prac. Header Type".FromInteger(SourceType);
        PaymentPracticeLine.Insert();
    end;

    local procedure SetPercentPaidInPeriod(var PaymentPracticeData: Record "Payment Practice Data"; DaysFrom: Integer; DaysTo: Integer; var PercentPaidInPeriodByNumber: Decimal; var PercentPaidInPeriodByAmount: Decimal)
    var
        Total: Integer;
        PaidInPeriod: Integer;
        TotalAmount: Decimal;
        PaidInPeriodAmount: Decimal;
    begin
        // Paid in period is:
        // 1. Closed
        // 2. Actual Payment Days is between DayFrom and DayTo
        // Total is:
        // 1. All closed invoices
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                if (PaymentPracticeData."Actual Payment Days" >= DaysFrom) and ((PaymentPracticeData."Actual Payment Days" <= DaysTo) or (DaysTo = 0)) then begin
                    PaidInPeriodAmount += PaymentPracticeData."Invoice Amount";
                    PaidInPeriod += 1;
                end;
                TotalAmount += PaymentPracticeData."Invoice Amount";
                Total += 1;
            until PaymentPracticeData.Next() = 0;
        if Total > 0 then
            PercentPaidInPeriodByNumber := PaidInPeriod / Total * 100;
        if TotalAmount <> 0 then
            PercentPaidInPeriodByAmount := PaidInPeriodAmount / TotalAmount * 100;
        PaymentPracticeData.SetRange("Invoice Is Open");
    end;
}
