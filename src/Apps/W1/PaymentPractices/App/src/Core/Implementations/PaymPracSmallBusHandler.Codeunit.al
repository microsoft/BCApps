// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Vendor;

codeunit 682 "Paym. Prac. Small Bus. Handler" implements PaymentPracticeSchemeHandler
{
    Access = Internal;

    var
        PaymentPracticeMath: Codeunit "Payment Practice Math";
        WrongHeaderTypeErr: Label 'Payment Practice Header Type must be Vendor for the Small Business reporting scheme.';
        WrongHeaderAggErr: Label 'Payment Practice Aggregation Type must be Period for the Small Business reporting scheme.';

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        if PaymentPracticeHeader."Header Type" in [PaymentPracticeHeader."Header Type"::Customer, PaymentPracticeHeader."Header Type"::"Vendor+Customer"] then
            Error(WrongHeaderTypeErr);
        if PaymentPracticeHeader."Aggregation Type" = PaymentPracticeHeader."Aggregation Type"::"Company Size" then
            Error(WrongHeaderAggErr);
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    var
        Vendor: Record Vendor;
        CompanySize: Record "Company Size";
    begin
        if PaymentPracticeData."Source Type" <> PaymentPracticeData."Source Type"::Vendor then
            exit(false);

        Vendor.SetLoadFields("Company Size Code");
        if not Vendor.Get(PaymentPracticeData."CV No.") then
            exit(false);

        if CompanySize.Get(Vendor."Company Size Code") then
            exit(CompanySize."Small Business")
        else
            exit(false);
    end;

    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        TotalCount: Integer;
        TotalValue: Decimal;
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                TotalCount += 1;
                TotalValue += PaymentPracticeData."Invoice Amount";
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");

        PaymentPracticeHeader."Total Number of Payments" := TotalCount;
        PaymentPracticeHeader."Total Amount of Payments" := TotalValue;
        PaymentPracticeHeader."Mode Payment Time" := PaymentPracticeMath.GetModePaymentTime(PaymentPracticeData);
        PaymentPracticeHeader."Mode Payment Time Min." := PaymentPracticeMath.GetModePaymentTimeMin(PaymentPracticeData);
        PaymentPracticeHeader."Mode Payment Time Max." := PaymentPracticeMath.GetModePaymentTimeMax(PaymentPracticeData);
        PaymentPracticeHeader."Median Payment Time" := PaymentPracticeMath.GetMedianPaymentTime(PaymentPracticeData);
        PaymentPracticeHeader."80th Percentile Payment Time" := PaymentPracticeMath.Get80thPercentilePaymentTime(PaymentPracticeData);
        PaymentPracticeHeader."95th Percentile Payment Time" := PaymentPracticeMath.Get95thPercentilePaymentTime(PaymentPracticeData);
        PaymentPracticeHeader."Pct Peppol Enabled" := PaymentPracticeMath.GetPctPeppolEnabled(PaymentPracticeData);
        PaymentPracticeHeader."Pct Small Business Payments" := PaymentPracticeMath.GetPctSmallBusinessPayments(PaymentPracticeData, PaymentPracticeHeader);
    end;

    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        InvoiceCount: Integer;
        InvoiceValue: Decimal;
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                InvoiceCount += 1;
                InvoiceValue += PaymentPracticeData."Invoice Amount";
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");

        PaymentPracticeLine."Invoice Count" := InvoiceCount;
        PaymentPracticeLine."Invoice Value" := InvoiceValue;
    end;
}