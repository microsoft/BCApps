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
        SmallBusinessCache: Dictionary of [Code[20], Boolean];
        WrongHeaderTypeErr: Label 'Payment Practice Header Type must be Vendor for the Small Business reporting scheme.';
        WrongHeaderAggErr: Label 'Payment Practice Aggregation Type must be Period for the Small Business reporting scheme.';

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        if PaymentPracticeHeader."Header Type" <> PaymentPracticeHeader."Header Type"::Vendor then
            Error(WrongHeaderTypeErr);
        if PaymentPracticeHeader."Aggregation Type" <> PaymentPracticeHeader."Aggregation Type"::Period then
            Error(WrongHeaderAggErr);
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    var
        Vendor: Record Vendor;
        CompanySize: Record "Company Size";
        IsSmallBusiness: Boolean;
    begin
        if PaymentPracticeData."Source Type" <> PaymentPracticeData."Source Type"::Vendor then
            exit(false);

        if SmallBusinessCache.Get(PaymentPracticeData."CV No.", IsSmallBusiness) then
            exit(IsSmallBusiness);

        Vendor.SetLoadFields("Company Size Code");
        if not Vendor.Get(PaymentPracticeData."CV No.") then begin
            SmallBusinessCache.Add(PaymentPracticeData."CV No.", false);
            exit(false);
        end;

        if CompanySize.Get(Vendor."Company Size Code") then
            IsSmallBusiness := CompanySize."Small Business"
        else
            IsSmallBusiness := false;

        SmallBusinessCache.Add(PaymentPracticeData."CV No.", IsSmallBusiness);
        exit(IsSmallBusiness);
    end;

    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        TotalCount: Integer;
        TotalValue: Decimal;
        ModePaymentTime: Integer;
        ModePaymentTimeMin: Integer;
        ModePaymentTimeMax: Integer;
        MedianPaymentTime: Decimal;
        P80PaymentTime: Integer;
        P95PaymentTime: Integer;
        PctPeppolEnabled: Decimal;
        PctSmallBusinessPayments: Decimal;
    begin
        PaymentPracticeMath.CalculateHeaderStatistics(
            PaymentPracticeData, TotalCount, TotalValue,
            ModePaymentTime, ModePaymentTimeMin, ModePaymentTimeMax,
            MedianPaymentTime, P80PaymentTime, P95PaymentTime,
            PctPeppolEnabled, PctSmallBusinessPayments);

        PaymentPracticeHeader."Total Number of Payments" := TotalCount;
        PaymentPracticeHeader."Total Amount of Payments" := TotalValue;
        PaymentPracticeHeader."Mode Payment Time" := ModePaymentTime;
        PaymentPracticeHeader."Mode Payment Time Min." := ModePaymentTimeMin;
        PaymentPracticeHeader."Mode Payment Time Max." := ModePaymentTimeMax;
        PaymentPracticeHeader."Median Payment Time" := MedianPaymentTime;
        PaymentPracticeHeader."80th Percentile Payment Time" := P80PaymentTime;
        PaymentPracticeHeader."95th Percentile Payment Time" := P95PaymentTime;
        PaymentPracticeHeader."Pct Peppol Enabled" := PctPeppolEnabled;
        PaymentPracticeHeader."Pct Small Business Payments" := PctSmallBusinessPayments;
    end;

    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
    var
        InvoiceCount: Integer;
        InvoiceValue: Decimal;
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        InvoiceCount := PaymentPracticeData.Count();
        PaymentPracticeData.CalcSums("Invoice Amount");
        InvoiceValue := PaymentPracticeData."Invoice Amount";
        PaymentPracticeData.SetRange("Invoice Is Open");

        PaymentPracticeLine."Invoice Count" := InvoiceCount;
        PaymentPracticeLine."Invoice Value" := InvoiceValue;
    end;
}