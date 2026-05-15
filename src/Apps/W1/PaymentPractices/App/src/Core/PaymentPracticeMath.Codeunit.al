// ------------------------------------------------------------------------------------------------
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

    /// <summary>
    /// Calculates the mode (most frequent value) of the actual payment times across all closed invoices in the provided dataset.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate. Filters are temporarily adjusted but restored before returning.</param>
    /// <returns>The most frequently occurring number of actual payment days, or 0 if no closed invoices exist.</returns>
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
        exit(MostFrequentValue(ActualPaymentTimes));
    end;

    /// <summary>
    /// Calculates the smallest per-vendor mode of actual payment times across all vendors in the provided dataset.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate, grouped by vendor.</param>
    /// <returns>The minimum of all per-vendor modes, or 0 if no closed invoices exist.</returns>
    procedure GetModePaymentTimeMin(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ModesPerVendor: List of [Integer];
    begin
        GetModesPerVendor(PaymentPracticeData, ModesPerVendor);
        exit(MinOfList(ModesPerVendor));
    end;

    /// <summary>
    /// Calculates the largest per-vendor mode of actual payment times across all vendors in the provided dataset.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate, grouped by vendor.</param>
    /// <returns>The maximum of all per-vendor modes, or 0 if no closed invoices exist.</returns>
    procedure GetModePaymentTimeMax(var PaymentPracticeData: Record "Payment Practice Data"): Integer
    var
        ModesPerVendor: List of [Integer];
    begin
        GetModesPerVendor(PaymentPracticeData, ModesPerVendor);
        exit(MaxOfList(ModesPerVendor));
    end;

    /// <summary>
    /// Calculates the median, 80th percentile, and 95th percentile of actual payment times across all closed invoices in the provided dataset.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate. Filters are temporarily adjusted but restored before returning.</param>
    /// <param name="MedianPaymentTime">Output parameter that receives the median number of actual payment days, or 0 if no closed invoices exist.</param>
    /// <param name="P80PaymentTime">Output parameter that receives the 80th percentile of actual payment days, or 0 if no closed invoices exist.</param>
    /// <param name="P95PaymentTime">Output parameter that receives the 95th percentile of actual payment days, or 0 if no closed invoices exist.</param>
    procedure GetPaymentTimeStatistics(var PaymentPracticeData: Record "Payment Practice Data"; var MedianPaymentTime: Decimal; var P80PaymentTime: Integer; var P95PaymentTime: Integer)
    var
        ActualPaymentTimes: List of [Integer];
    begin
        MedianPaymentTime := 0;
        P80PaymentTime := 0;
        P95PaymentTime := 0;

        GetClosedInvoicePaymentTimes(PaymentPracticeData, ActualPaymentTimes);
        if ActualPaymentTimes.Count() = 0 then
            exit;

        SortIntegerList(ActualPaymentTimes);
        MedianPaymentTime := MedianFromSorted(ActualPaymentTimes);
        P80PaymentTime := PercentileFromSorted(ActualPaymentTimes, 80);
        P95PaymentTime := PercentileFromSorted(ActualPaymentTimes, 95);
    end;

    /// <summary>
    /// Calculates the percentage of closed-invoice transactions whose vendor is Peppol enabled (i.e. has a non-empty GLN).
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to evaluate. A per-vendor GLN cache is used to avoid repeated lookups.</param>
    /// <returns>The percentage (0-100) of closed-invoice rows from Peppol-enabled vendors, or 0 when there are no closed invoices.</returns>
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
                    Vendor.SetLoadFields(GLN);
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

    /// <summary>
    /// Calculates the percentage of total vendor invoice value (within the header period) that is paid to small-business vendors.
    /// </summary>
    /// <param name="PaymentPracticeHeader">The payment practice header providing the reporting period (Starting/Ending Date).</param>
    /// <returns>The percentage (0-100) of paid invoice value attributable to vendors flagged as Small Business, or 0 when no invoice value exists.</returns>
    procedure GetPctSmallBusinessPayments(PaymentPracticeHeader: Record "Payment Practice Header"): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntryForSum: Record "Vendor Ledger Entry";
        CompanySize: Record "Company Size";
        Vendor: Record Vendor;
        VendorCompanySizeCache: Dictionary of [Code[20], Code[10]];
        VendorExcludedCache: Dictionary of [Code[20], Boolean];
        SmallBusinessCache: Dictionary of [Code[10], Boolean];
        CompanySizeCode: Code[10];
        PaidAmount: Decimal;
        TotalAmountSmallBusinesses: Decimal;
        TotalAmountAllVendors: Decimal;
    begin
        // Walk the filtered Vendor Ledger Entries grouped by vendor. For each distinct vendor we
        // (a) look up "Company Size Code" / "Exclude from Pmt. Practices" once (cached in a Dictionary), and
        // (b) aggregate Amount / "Remaining Amount" with a single CalcSums call, instead of
        //     forcing the FlowFields to evaluate on every row via SetAutoCalcFields.
        VendorLedgerEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendorLedgerEntry.SetLoadFields("Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetRange("Posting Date", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
        if VendorLedgerEntry.FindSet() then
            repeat
                if not VendorCompanySizeCache.ContainsKey(VendorLedgerEntry."Vendor No.") then begin
                    Vendor.SetLoadFields("Company Size Code", "Exclude from Pmt. Practices");
                    if Vendor.Get(VendorLedgerEntry."Vendor No.") then begin
                        CompanySizeCode := Vendor."Company Size Code";
                        VendorExcludedCache.Add(VendorLedgerEntry."Vendor No.", Vendor."Exclude from Pmt. Practices");
                    end else begin
                        CompanySizeCode := '';
                        VendorExcludedCache.Add(VendorLedgerEntry."Vendor No.", false);
                    end;
                    VendorCompanySizeCache.Add(VendorLedgerEntry."Vendor No.", CompanySizeCode);

                    if not SmallBusinessCache.ContainsKey(CompanySizeCode) then
                        SmallBusinessCache.Add(CompanySizeCode, (CompanySizeCode <> '') and CompanySize.Get(CompanySizeCode) and CompanySize."Small Business");

                    if not VendorExcludedCache.Get(VendorLedgerEntry."Vendor No.") then begin
                        VendorLedgerEntryForSum.SetCurrentKey("Vendor No.", "Posting Date");
                        VendorLedgerEntryForSum.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
                        VendorLedgerEntryForSum.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
                        VendorLedgerEntryForSum.SetRange("Posting Date", PaymentPracticeHeader."Starting Date", PaymentPracticeHeader."Ending Date");
                        VendorLedgerEntryForSum.SetAutoCalcFields(Amount, "Remaining Amount");
                        PaidAmount := 0;
                        if VendorLedgerEntryForSum.FindSet() then
                            repeat
                                PaidAmount += VendorLedgerEntryForSum.Amount - VendorLedgerEntryForSum."Remaining Amount";
                            until VendorLedgerEntryForSum.Next() = 0;

                        if SmallBusinessCache.Get(CompanySizeCode) then
                            TotalAmountSmallBusinesses += PaidAmount;
                        TotalAmountAllVendors += PaidAmount;
                    end;
                end;
            until VendorLedgerEntry.Next() = 0;

        if TotalAmountAllVendors = 0 then
            exit(0);

        exit(TotalAmountSmallBusinesses / TotalAmountAllVendors * 100);
    end;

    /// <summary>
    /// Collects the actual payment days for all closed invoices in the dataset into a list. Filters are temporarily adjusted but restored before returning.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to scan.</param>
    /// <param name="ActualPaymentTimes">Output list that will receive one integer per closed invoice.</param>
    local procedure GetClosedInvoicePaymentTimes(var PaymentPracticeData: Record "Payment Practice Data"; var ActualPaymentTimes: List of [Integer])
    begin
        PaymentPracticeData.SetRange("Invoice Is Open", false);
        if PaymentPracticeData.FindSet() then
            repeat
                ActualPaymentTimes.Add(PaymentPracticeData."Actual Payment Days");
            until PaymentPracticeData.Next() = 0;
        PaymentPracticeData.SetRange("Invoice Is Open");
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
    /// Computes the mode of actual payment times for each vendor in the dataset and returns one mode value per vendor.
    /// Relies on the data being sorted by "CV No." which is set as the current key inside the procedure and restored before returning.
    /// </summary>
    /// <param name="PaymentPracticeData">The payment practice data to scan.</param>
    /// <param name="ModesPerVendor">Output list that will receive one mode value per vendor that has at least one closed invoice.</param>
    local procedure GetModesPerVendor(var PaymentPracticeData: Record "Payment Practice Data"; var ModesPerVendor: List of [Integer])
    var
        LocalPaymentPracticeData: Record "Payment Practice Data";
        ActualPaymentTimes: List of [Integer];
        CurrentVendor: Code[20];
    begin
        // Use a separate record variable so we don't mutate the caller's filters or current key.
        LocalPaymentPracticeData.CopyFilters(PaymentPracticeData);
        LocalPaymentPracticeData.SetRange("Invoice Is Open", false);
        LocalPaymentPracticeData.SetCurrentKey("CV No.");
        if LocalPaymentPracticeData.FindSet() then begin
            CurrentVendor := LocalPaymentPracticeData."CV No.";
            repeat
                if LocalPaymentPracticeData."CV No." <> CurrentVendor then begin
                    ModesPerVendor.Add(MostFrequentValue(ActualPaymentTimes));
                    Clear(ActualPaymentTimes);
                    CurrentVendor := LocalPaymentPracticeData."CV No.";
                end;
                ActualPaymentTimes.Add(LocalPaymentPracticeData."Actual Payment Days");
            until LocalPaymentPracticeData.Next() = 0;
            ModesPerVendor.Add(MostFrequentValue(ActualPaymentTimes));
        end;
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