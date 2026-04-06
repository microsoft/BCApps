// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Vendor;

codeunit 682 "Paym. Prac. Small Bus. Handler" implements PaymentPracticeDefaultPeriods, PaymentPracticeSchemeHandler
{
    Access = Internal;

    var
        WrongHeaderTypeErr: Label 'Payment Practice Header Type must be Vendor for the Small Business reporting scheme.';

    procedure GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)
    begin
        PeriodHeaderCode := 'AU-DEFAULT';
        PeriodHeaderDescription := 'AU/NZ Payment Periods (0-30, 31-60, 61+)';
        InsertTempLine(TempPaymentPeriodLine, 10000, 0, 30);
        InsertTempLine(TempPaymentPeriodLine, 20000, 31, 60);
        InsertTempLine(TempPaymentPeriodLine, 30000, 61, 0);
    end;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        if PaymentPracticeHeader."Header Type" in [PaymentPracticeHeader."Header Type"::Customer, PaymentPracticeHeader."Header Type"::"Vendor+Customer"] then
            Error(WrongHeaderTypeErr);
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    var
        Vendor: Record Vendor;
    begin
        if PaymentPracticeData."Source Type" <> PaymentPracticeData."Source Type"::Vendor then
            exit(false);

        if not Vendor.Get(PaymentPracticeData."CV No.") then
            exit(false);

        exit(Vendor."Small Business Supplier");
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

    local procedure InsertTempLine(var TempPaymentPeriodLine: Record "Payment Period Line" temporary; LineNo: Integer; DaysFrom: Integer; DaysTo: Integer)
    begin
        TempPaymentPeriodLine.Init();
        TempPaymentPeriodLine."Line No." := LineNo;
        TempPaymentPeriodLine."Days From" := DaysFrom;
        TempPaymentPeriodLine."Days To" := DaysTo;
        TempPaymentPeriodLine.UpdateDescription();
        TempPaymentPeriodLine.Insert();
    end;
}
