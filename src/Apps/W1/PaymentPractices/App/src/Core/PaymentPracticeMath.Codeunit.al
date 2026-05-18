// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

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

    /// <summary>
    /// Aggregates all closed-invoice statistics required for a Small Business reporting-scheme header in a single
    /// pass over the filtered <see cref="Payment Practice Data"/> set. This consolidates what previously required
    /// 5+ independent full-table scans (mode, per-vendor mode min/max, median/P80/P95, % Peppol enabled, % small
    /// business payments) into one iteration plus one small in-memory post-processing step.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate. Filters are temporarily adjusted but restored before returning.</param>
    /// <param name="TotalCount">Output: number of closed invoice rows.</param>
    /// <param name="TotalValue">Output: sum of "Invoice Amount" across closed invoices.</param>
    /// <param name="ModePaymentTime">Output: most frequent "Actual Payment Days" across all closed invoices.</param>
    /// <param name="ModePaymentTimeMin">Output: smallest per-vendor mode of "Actual Payment Days".</param>
    /// <param name="ModePaymentTimeMax">Output: largest per-vendor mode of "Actual Payment Days".</param>
    /// <param name="MedianPaymentTime">Output: median of "Actual Payment Days" across closed invoices.</param>
    /// <param name="P80PaymentTime">Output: 80th percentile of "Actual Payment Days".</param>
    /// <param name="P95PaymentTime">Output: 95th percentile of "Actual Payment Days".</param>
    /// <param name="PctPeppolEnabled">Output: percentage of closed-invoice rows whose vendor has a GLN.</param>
    /// <param name="PctSmallBusinessPayments">Output: percentage of closed-invoice value attributable to small-business vendors.</param>
    procedure CalculateHeaderStatistics(var PaymentPracticeData: Record "Payment Practice Data"; var TotalCount: Integer; var TotalValue: Decimal; var ModePaymentTime: Integer; var ModePaymentTimeMin: Integer; var ModePaymentTimeMax: Integer; var MedianPaymentTime: Decimal; var P80PaymentTime: Integer; var P95PaymentTime: Integer; var PctPeppolEnabled: Decimal; var PctSmallBusinessPayments: Decimal)
    var
        Vendor: Record Vendor;
        CompanySize: Record "Company Size";
        AllPaymentTimes: List of [Integer];
        PerVendorTimes: Dictionary of [Code[20], List of [Integer]];
        VendorTimes: List of [Integer];
        ModesPerVendor: List of [Integer];
        VendorGLNCache: Dictionary of [Code[20], Boolean];
        SmallBusinessCache: Dictionary of [Code[20], Boolean];
        HasGLN: Boolean;
        IsSmallBusiness: Boolean;
        PeppolCount: Integer;
        SmallBusinessValue: Decimal;
        PaymentTime: Integer;
        CVNo: Code[20];
        CompanySizeCode: Code[20];
    begin
        TotalCount := 0;
        TotalValue := 0;
        ModePaymentTime := 0;
        ModePaymentTimeMin := 0;
        ModePaymentTimeMax := 0;
        MedianPaymentTime := 0;
        P80PaymentTime := 0;
        P95PaymentTime := 0;
        PctPeppolEnabled := 0;
        PctSmallBusinessPayments := 0;

        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                TotalCount += 1;
                TotalValue += PaymentPracticeData."Invoice Amount";

                PaymentTime := PaymentPracticeData."Actual Payment Days";
                AllPaymentTimes.Add(PaymentTime);

                CVNo := PaymentPracticeData."CV No.";
                if PerVendorTimes.Get(CVNo, VendorTimes) then begin
                    VendorTimes.Add(PaymentTime);
                    PerVendorTimes.Set(CVNo, VendorTimes);
                end else begin
                    Clear(VendorTimes);
                    VendorTimes.Add(PaymentTime);
                    PerVendorTimes.Add(CVNo, VendorTimes);
                end;

                // Peppol enabled (vendor GLN), cached per vendor
                if not VendorGLNCache.Get(CVNo, HasGLN) then begin
                    Vendor.SetLoadFields(GLN);
                    HasGLN := Vendor.Get(CVNo) and (Vendor.GLN <> '');
                    VendorGLNCache.Add(CVNo, HasGLN);
                end;
                if HasGLN then
                    PeppolCount += 1;

                // Small business value, using "Company Size Code" already stored on the data row (cached per code)
                CompanySizeCode := PaymentPracticeData."Company Size Code";
                if not SmallBusinessCache.Get(CompanySizeCode, IsSmallBusiness) then begin
                    IsSmallBusiness := (CompanySizeCode <> '') and CompanySize.Get(CompanySizeCode) and CompanySize."Small Business";
                    SmallBusinessCache.Add(CompanySizeCode, IsSmallBusiness);
                end;
                if IsSmallBusiness then
                    SmallBusinessValue += PaymentPracticeData."Invoice Amount";
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");

        if AllPaymentTimes.Count() > 0 then begin
            ModePaymentTime := MostFrequentValue(AllPaymentTimes);
            SortIntegerList(AllPaymentTimes);
            MedianPaymentTime := MedianFromSorted(AllPaymentTimes);
            P80PaymentTime := PercentileFromSorted(AllPaymentTimes, 80);
            P95PaymentTime := PercentileFromSorted(AllPaymentTimes, 95);
        end;

        foreach CVNo in PerVendorTimes.Keys() do begin
            VendorTimes := PerVendorTimes.Get(CVNo);
            ModesPerVendor.Add(MostFrequentValue(VendorTimes));
        end;
        ModePaymentTimeMin := MinOfList(ModesPerVendor);
        ModePaymentTimeMax := MaxOfList(ModesPerVendor);

        if TotalCount > 0 then
            PctPeppolEnabled := PeppolCount / TotalCount * 100;
        if TotalValue <> 0 then
            PctSmallBusinessPayments := SmallBusinessValue / TotalValue * 100;
    end;

    /// <summary>
    /// Calculates the median value from a list of integers that has already been sorted in ascending order.
    /// For lists with an even number of elements, returns the average of the two middle values.
    /// </summary>
    /// <param name="SortedList">The sorted list of integers to evaluate. Must be sorted in ascending order and contain at least one element.</param>
    /// <returns>The median value as a decimal.</returns>
    local procedure MedianFromSorted(var SortedList: List of [Integer]): Decimal
    var
        MiddleIndex: Integer;
    begin
        MiddleIndex := SortedList.Count() div 2;
        if SortedList.Count() mod 2 = 0 then
            exit((SortedList.Get(MiddleIndex) + SortedList.Get(MiddleIndex + 1)) / 2)
        else
            exit(SortedList.Get(MiddleIndex + 1));
    end;

    /// <summary>
    /// Returns the value at the specified percentile from a list of integers that has already been sorted in ascending order.
    /// The index is clamped to the valid range [1, Count].
    /// </summary>
    /// <param name="SortedList">The sorted list of integers to evaluate. Must be sorted in ascending order and contain at least one element.</param>
    /// <param name="P">The percentile to compute (e.g. 80 for the 80th percentile).</param>
    /// <returns>The integer value at the specified percentile.</returns>
    local procedure PercentileFromSorted(var SortedList: List of [Integer]; P: Integer): Integer
    var
        Index: Integer;
    begin
        Index := SortedList.Count() * P div 100;
        if Index < 1 then
            Index := 1;
        if Index > SortedList.Count() then
            Index := SortedList.Count();
        exit(SortedList.Get(Index));
    end;

    /// <summary>
    /// Returns the smallest value in the supplied integer list.
    /// </summary>
    /// <param name="List">The list of integers to evaluate.</param>
    /// <returns>The minimum value in the list, or 0 if the list is empty.</returns>
    local procedure MinOfList(var List: List of [Integer]): Integer
    var
        Value: Integer;
        MinValue: Integer;
    begin
        if List.Count() = 0 then
            exit(0);

        MinValue := List.Get(1);
        foreach Value in List do
            if Value < MinValue then
                MinValue := Value;

        exit(MinValue);
    end;

    /// <summary>
    /// Returns the largest value in the supplied integer list.
    /// </summary>
    /// <param name="List">The list of integers to evaluate.</param>
    /// <returns>The maximum value in the list, or 0 if the list is empty.</returns>
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

    /// <summary>
    /// Returns the most frequently occurring value (statistical mode) in the supplied integer list.
    /// When several values share the highest frequency, the smallest of those values is returned for deterministic behavior.
    /// </summary>
    /// <param name="List">The list of integers to evaluate.</param>
    /// <returns>The most frequent value, or 0 if the list is empty.</returns>
    local procedure MostFrequentValue(var List: List of [Integer]): Integer
    var
        ValueFrequencies: Dictionary of [Integer, Integer];
        CurrentValue: Integer;
        CurrentFrequency: Integer;
        HighestFrequency: Integer;
        MostFrequent: Integer;
    begin
        if List.Count() = 0 then
            exit(0);

        foreach CurrentValue in List do
            if ValueFrequencies.ContainsKey(CurrentValue) then
                ValueFrequencies.Set(CurrentValue, ValueFrequencies.Get(CurrentValue) + 1)
            else
                ValueFrequencies.Add(CurrentValue, 1);

        HighestFrequency := 0;
        MostFrequent := 0;
        foreach CurrentValue in ValueFrequencies.Keys() do begin
            CurrentFrequency := ValueFrequencies.Get(CurrentValue);
            if (CurrentFrequency > HighestFrequency) or ((CurrentFrequency = HighestFrequency) and (CurrentValue < MostFrequent)) then begin
                HighestFrequency := CurrentFrequency;
                MostFrequent := CurrentValue;
            end;
        end;

        exit(MostFrequent);
    end;

    /// <summary>
    /// Sorts the supplied integer list in ascending order in place using a simple insertion sort.
    /// </summary>
    /// <param name="List">The list of integers to sort. Modified in place.</param>
    local procedure SortIntegerList(var List: List of [Integer])
    var
        i: Integer;
        j: Integer;
        CurrentValue: Integer;
    begin
        // Insertion sort, O(n^2) worst case
        for i := 2 to List.Count() do begin
            CurrentValue := List.Get(i);
            j := i - 1;
            while j >= 1 do begin
                if List.Get(j) <= CurrentValue then
                    break;
                List.Set(j + 1, List.Get(j));
                j -= 1;
            end;
            List.Set(j + 1, CurrentValue);
        end;
    end;
}