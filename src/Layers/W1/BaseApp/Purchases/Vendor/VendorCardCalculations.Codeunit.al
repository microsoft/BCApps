// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

codeunit 33 "Vendor Card Calculations"
{
    trigger OnRun()
    var
        Vendor: Record Vendor;
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        VendorNo: Code[20];
        VendorFilters: Text;
        NewWorkDate: Date;
        BalanceAsCustomer: Decimal;
        LinkedCustomerNo: Code[20];
    begin
        Params := Page.GetBackgroundParameters();
        VendorNo := CopyStr(Params.Get(GetVendorNoLabel()), 1, MaxStrLen(VendorNo));
        if not Vendor.Get(VendorNo) then
            exit;
        VendorFilters := Params.Get(GetFiltersLabel());
        if VendorFilters <> '' then
            Vendor.SetView(VendorFilters);
        if Evaluate(NewWorkDate, Params.Get(GetWorkDateLabel())) then
            WorkDate := NewWorkDate;

        BalanceAsCustomer := Vendor.GetBalanceAsCustomer(LinkedCustomerNo);

        Results.Add(GetLinkedCustomerNoLabel(), Format(LinkedCustomerNo));
        Results.Add(GetBalanceAsCustomerLabel(), Format(BalanceAsCustomer));

        Page.SetBackgroundTaskResult(Results);
    end;

    var
        VendorNoLbl: label 'Vendor No.', Locked = true;
        FiltersLbl: label 'Filters', Locked = true;
        BalanceAsCustomerLbl: Label 'BalanceAsCustomer', Locked = true;
        LinkedCustomerNoLbl: Label 'LinkedCustomerNo', Locked = true;
        WorkDateLbl: label 'Work Date', Locked = true;

    internal procedure GetWorkDateLabel(): Text
    begin
        exit(WorkDateLbl);
    end;

    internal procedure GetVendorNoLabel(): Text
    begin
        exit(VendorNoLbl);
    end;

    internal procedure GetFiltersLabel(): Text
    begin
        exit(FiltersLbl);
    end;

    internal procedure GetBalanceAsCustomerLabel(): Text
    begin
        exit(BalanceAsCustomerLbl);
    end;

    internal procedure GetLinkedCustomerNoLabel(): Text
    begin
        exit(LinkedCustomerNoLbl);
    end;
}
