// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Reporting;
using System.Telemetry;

codeunit 686 "Paym. Prac. Size Aggregator" implements PaymentPracticeLinesAggregator
{
    Access = Internal;

    var
        PaymentPracticeMath: Codeunit "Payment Practice Math";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        WrongHeaderTypeErr: Label 'Payment Practice Header Type must be Vendor for this aggregation type.';
        WrongHeaderAggErr: Label 'Payment Practice Aggregation Type must be Period for the Small Business reporting scheme.';

    procedure PrepareLayout(ReportingScheme: Enum "Paym. Prac. Reporting Scheme");
    var
        DesignTimeReportSelection: Codeunit "Design-time Report Selection";
    begin
        DesignTimeReportSelection.SetSelectedLayout('PaymentPractice_VendorSizeLayout');
        FeatureTelemetry.LogUsage('0000KSX', 'Payment Practices', 'Vendor Size Layout used.');
    end;

    procedure GenerateLines(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header");
    var
        PaymentPracticeLine: Record "Payment Practice Line";
        CompanySize: Record "Company Size";
        SchemeHandler: Interface PaymentPracticeSchemeHandler;
        NextLineNo: Integer;
    begin
        NextLineNo := 1;
        SchemeHandler := PaymentPracticeHeader."Reporting Scheme";
        if CompanySize.FindSet() then
            repeat
                PaymentPracticeLine.Init();
                PaymentPracticeLine."Header No." := PaymentPracticeHeader."No.";
                PaymentPracticeLine."Line No." := NextLineNo;
                NextLineNo += 1;
                PaymentPracticeLine."Aggregation Type" := PaymentPracticeLine."Aggregation Type"::"Company Size";
                PaymentPracticeLine."Source Type" := PaymentPracticeLine."Source Type"::Vendor;
                PaymentPracticeLine."Company Size Code" := CompanySize.Code;

                PaymentPracticeData.Setrange("Company Size Code", CompanySize.Code);
                PaymentPracticeLine."Average Actual Payment Period" := PaymentPracticeMath.GetAverageActualPaymentTime(PaymentPracticeData);
                PaymentPracticeLine."Average Agreed Payment Period" := PaymentPracticeMath.GetAverageAgreedPaymentTime(PaymentPracticeData);
                PaymentPracticeLine."Pct Paid on Time" := PaymentPracticeMath.GetPercentOfOnTimePayments(PaymentPracticeData);

                PaymentPracticeLine.Insert();
                SchemeHandler.CalculateLineTotals(PaymentPracticeLine, PaymentPracticeData);
                if (PaymentPracticeLine."Invoice Count" <> 0) or (PaymentPracticeLine."Invoice Value" <> 0) then
                    PaymentPracticeLine.Modify();
                PaymentPracticeData.SetRange("Company Size Code");
            until CompanySize.Next() = 0;
    end;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        if PaymentPracticeHeader."Header Type" in [PaymentPracticeHeader."Header Type"::Customer, PaymentPracticeHeader."Header Type"::"Vendor+Customer"] then
            Error(WrongHeaderTypeErr);
        if PaymentPracticeHeader."Aggregation Type" = PaymentPracticeHeader."Aggregation Type"::"Company Size" then
            Error(WrongHeaderAggErr);
    end;
}