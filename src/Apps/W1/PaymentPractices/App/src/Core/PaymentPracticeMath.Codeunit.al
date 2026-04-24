﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

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

    procedure GetModePaymentTime(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ActualPaymentTimes: List of [Integer];
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");
        exit(Mode(ActualPaymentTimes));
    end;

    procedure GetModePaymentTimeMin(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ModesPerVendor: List of [Integer];
    begin
        GetModesPerVendor(PaymentPracticeData, ModesPerVendor);
        exit(MinOfList(ModesPerVendor));
    end;

    procedure GetModePaymentTimeMax(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ModesPerVendor: List of [Integer];
    begin
        GetModesPerVendor(PaymentPracticeData, ModesPerVendor);
        exit(MaxOfList(ModesPerVendor));
    end;

    procedure GetMedianPaymentTime(var PaymentPracticeData: Record "Payment Practice Data"): Decimal
    var
        ActualPaymentTimes: List of [Integer];
        MiddleIndex: Integer;
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");

        if ActualPaymentTimes.Count() = 0 then
            exit(0);

        SortIntegerList(ActualPaymentTimes);

        MiddleIndex := ActualPaymentTimes.Count() div 2;
        if ActualPaymentTimes.Count() mod 2 = 0 then
            exit((ActualPaymentTimes.Get(MiddleIndex) + ActualPaymentTimes.Get(MiddleIndex + 1)) / 2)
        else
            exit(ActualPaymentTimes.Get(MiddleIndex + 1));
    end;

    procedure Get80thPercentilePaymentTime(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ActualPaymentTimes: List of [Integer];
    begin
        GetClosedInvoicePaymentTimes(PaymentPracticeData, ActualPaymentTimes);
        exit(Percentile(ActualPaymentTimes, 80));
    end;

    procedure Get95thPercentilePaymentTime(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ActualPaymentTimes: List of [Integer];
    begin
        GetClosedInvoicePaymentTimes(PaymentPracticeData, ActualPaymentTimes);
        exit(Percentile(ActualPaymentTimes, 95));
    end;

    procedure GetPctPeppolEnabled(var PaymentPracticeData: Record "Payment Practice Data"): Decimal
    var
        Vendor: Record Vendor;
        VendorGLNCache: Dictionary of [Code[20], Boolean];
        HasGLN: Boolean;
        Total: Integer;
        PeppolCount: Integer;
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat

                Total += 1;
                if not VendorGLNCache.Get(PaymentPracticeData."CV No.", HasGLN) then begin
                    HasGLN := Vendor.Get(PaymentPracticeData."CV No.") and (Vendor.GLN <> '');
                    VendorGLNCache.Add(PaymentPracticeData."CV No.", HasGLN);
                end;

                if HasGLN then
                    PeppolCount += 1;
            until PaymentPracticeData.Next() = 0;

        PaymentPracticeData.SetRange("Invoice Is Open");
        if Total = 0 then
            exit(0);

        exit(PeppolCount / Total * 100);
    end;

    procedure GetPctSmallBusinessPayments(var PaymentPracticeData: Record "Payment Practice Data"; PaymentPracticeHeader: Record "Payment Practice Header"): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CompanySize: Record "Company Size";
        Vendor: Record Vendor;
        TotalAmountSmallBusinesses: Decimal;
        TotalAmountAllVendors: Decimal;
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Posting Date", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
                Vendor.Get(VendorLedgerEntry."Vendor No.");
                if CompanySize.Get(Vendor."Company Size Code") then
                    if CompanySize."Small Business" then
                        TotalAmountSmallBusinesses += VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry.Amount;
                TotalAmountAllVendors += VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry.Amount;
            until VendorLedgerEntry.Next() = 0;

        if TotalAmountAllVendors = 0 then
            exit(0);

        exit(TotalAmountSmallBusinesses / TotalAmountAllVendors * 100);
    end;

    local procedure GetClosedInvoicePaymentTimes(var PaymentPracticeData: Record "Payment Practice Data"; var ActualPaymentTimes: List of [Integer])
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");
    end;

    local procedure Percentile(var List: List of [Integer]; P: Integer): Integer
    var
        Index: Integer;
    begin
        if List.Count() = 0 then
            exit(0);

        SortIntegerList(List);

        Index := List.Count() * P div 100;
        if Index < 1 then
            Index := 1;
        if Index > List.Count() then
            Index := List.Count();

        exit(List.Get(Index));
    end;

    local procedure GetModesPerVendor(var PaymentPracticeData: Record "Payment Practice Data"; var ModesPerVendor: List of [Integer])
    var
        ActualPaymentTimes: List of [Integer];
        CurrentVendor: Code[20];
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        PaymentPracticeData.SetCurrentKey("CV No.");
        if PaymentPracticeData.FindSet() then begin
            CurrentVendor := PaymentPracticeData."CV No.";
            repeat
                if PaymentPracticeData."CV No." <> CurrentVendor then begin
                    ModesPerVendor.Add(Mode(ActualPaymentTimes));
                    Clear(ActualPaymentTimes);
                    CurrentVendor := PaymentPracticeData."CV No.";
                end;
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
            ModesPerVendor.Add(Mode(ActualPaymentTimes));
        end;
        PaymentPracticeData.SetRange("Invoice Is Open");
        PaymentPracticeData.SetCurrentKey("Header No.", "Invoice Entry No.", "Source Type");
    end;

    local procedure MinOfList(var List: List of [Integer]): Integer
    var
        Value: Integer;
        MinValue: Integer;
        IsFirst: Boolean;
    begin
        if List.Count() = 0 then
            exit(0);

        IsFirst := true;
        foreach Value in List do
            if IsFirst then begin
                MinValue := Value;
                IsFirst := false;
            end else
                if Value < MinValue then
                    MinValue := Value;

        exit(MinValue);
    end;

    local procedure MaxOfList(var List: List of [Integer]): Integer
    var
        Value: Integer;
        MaxValue: Integer;
    begin
        if List.Count() = 0 then
            exit(0);

        MaxValue := List.Get(1);

        foreach Value in List do
            if Value > MaxValue then
                MaxValue := Value;

        exit(MaxValue);
    end;

    local procedure Mode(var List: List of [Integer]): Integer
    var
        Frequencies: Dictionary of [Integer, Integer];
        Value: Integer;
        Frequency: Integer;
        MaxFrequency: Integer;
        ModeValue: Integer;
    begin
        if List.Count() = 0 then
            exit(0);

        foreach Value in List do
            if Frequencies.ContainsKey(Value) then
                Frequencies.Set(Value, Frequencies.Get(Value) + 1)
            else
                Frequencies.Add(Value, 1);

        MaxFrequency := 0;
        ModeValue := 0;
        foreach Value in Frequencies.Keys() do begin
            Frequency := Frequencies.Get(Value);
            if (Frequency > MaxFrequency) or ((Frequency = MaxFrequency) and (Value < ModeValue)) then begin
                MaxFrequency := Frequency;
                ModeValue := Value;
            end;
        end;

        exit(ModeValue);
    end;

    local procedure SortIntegerList(var List: List of [Integer])
    var
        i: Integer;
        j: Integer;
        Temp: Integer;
    begin
        for i := 1 to List.Count() - 1 do
            for j := 1 to List.Count() - i do
                if List.Get(j) > List.Get(j + 1) then begin
                    Temp := List.Get(j);
                    List.Set(j, List.Get(j + 1));
                    List.Set(j + 1, Temp);
                end;
    end;
}