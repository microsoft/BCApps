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
        WrongHeaderTypeErr: Label 'Payment Practice Header Type must be Vendor for the Small Business reporting scheme.';

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

        Vendor.SetLoadFields("Small Business Supplier");
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
}
