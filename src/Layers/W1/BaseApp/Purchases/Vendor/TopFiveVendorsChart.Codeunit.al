// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.RoleCenters;
using System.Visualization;

codeunit 9091 "Top Five Vendors Chart"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        VendorXCaptionTxt: Label 'Vendor Name';
        PurchasesLCYYCaptionTxt: Label 'Purchases (LCY)';
        AllOtherVendorsTxt: Label 'All Other Vendors';
        VendorNameNoLbl: Label '%1 - %2', Locked = true, Comment = ' %1 -  Vendor No. %2 - Vendor Name';
        VendorNo: array[5] of Code[20];

    /// <summary>
    /// Update the chart with the top 5 vendors by purchases.
    /// </summary>
    /// <param name="BusChartBuf">Return value: Business Chart Buffer record</param>
    procedure UpdateChart(var BusChartBuf: Record "Business Chart Buffer")
    var
        ColumnIndex: Integer;
        VendorName: array[11] of Text[100];
        PurchasesLCY: array[11] of Decimal;
    begin
        BusChartBuf.Initialize();
        BusChartBuf.AddDecimalMeasure(PurchasesLCYYCaptionTxt, 1, BusChartBuf."Chart Type"::Pie);
        BusChartBuf.SetXAxis(VendorXCaptionTxt, BusChartBuf."Data Type"::String);
        CalcTopPurchasesVendors(VendorName, PurchasesLCY);
        for ColumnIndex := 1 to 6 do begin
            if PurchasesLCY[ColumnIndex] = 0 then
                exit;
            BusChartBuf.AddColumn(VendorName[ColumnIndex]);
            BusChartBuf.SetValueByIndex(0, ColumnIndex - 1, PurchasesLCY[ColumnIndex]);
        end;
    end;

    /// <summary>
    /// Drill down to the vendor card or vendor list page based on the selected vendor.
    /// </summary>
    /// <param name="BusChartBuf">Return value: Business Chart Buffer record</param>
    procedure DrillDown(var BusChartBuf: Record "Business Chart Buffer")
    var
        VendorName: Variant;
    begin
        BusChartBuf.GetXValue(BusChartBuf."Drill-Down X Index", VendorName);
        // drill down only for top 5 vendors
        // for the 6th column "all other vendors", it drills down to vendor list of all other vendors
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" < 5) then
            DrillDownVendor(VendorNo[BusChartBuf."Drill-Down X Index" + 1]);
        if (BusChartBuf."Drill-Down Measure Index" = 0) and (BusChartBuf."Drill-Down X Index" = 5) then
            DrillDownOtherVendorList();
    end;

    local procedure CalcTopPurchasesVendors(var VendorName: array[6] of Text[100]; var PurchasesLCY: array[6] of Decimal)
    var
        TopVendorsByPurchases: Record "Top Vendors By Purchase";
        TopVendorsByPurchasesJob: Codeunit "Top Vendors By Purchases Job";
        PayablePerformance: Codeunit "Acc. Payable Performance";
        ColumnIndex: Integer;
        OtherVendorsPurchasesLCY: Decimal;
    begin
        if TopVendorsByPurchases.IsEmpty() then
            TopVendorsByPurchasesJob.UpdateVendorTop10List();

        if TopVendorsByPurchases.FindSet() then begin
            repeat
                ColumnIndex += 1;
                if ColumnIndex <= 5 then begin
                    VendorName[TopVendorsByPurchases.Ranking] :=
                        CopyStr(StrSubstNo(VendorNameNoLbl, TopVendorsByPurchases.VendorNo, TopVendorsByPurchases.VendorName),
                            1, MaxStrLen(VendorName[TopVendorsByPurchases.Ranking]));
                    PurchasesLCY[TopVendorsByPurchases.Ranking] := -TopVendorsByPurchases.PurchasesLCY;
                    VendorNo[TopVendorsByPurchases.Ranking] := TopVendorsByPurchases.VendorNo
                end else
                    OtherVendorsPurchasesLCY += -TopVendorsByPurchases.PurchasesLCY;
            until TopVendorsByPurchases.Next() = 0;

            if OtherVendorsPurchasesLCY <> 0 then begin
                VendorName[6] := AllOtherVendorsTxt;
                PurchasesLCY[6] := OtherVendorsPurchasesLCY
            end;

            PayablePerformance.ScheduleTopVendorListRefreshTask()
        end;
    end;

    local procedure DrillDownVendor(DrillDownVendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(DrillDownVendorNo);
        Page.Run(Page::"Vendor Card", Vendor);
    end;

    local procedure DrillDownOtherVendorList()
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetFilter("No.", GetFilterToExcludeTopFiveVendors());
        Vendor.SetCurrentKey(Name);
        Vendor.Ascending(true);
        Page.Run(Page::"Vendor List", Vendor);
    end;

    local procedure GetFilterToExcludeTopFiveVendors(): Text
    var
        VendorCounter: Integer;
        FilterToExcludeTopFiveVendors: Text;
    begin
        for VendorCounter := 1 to 5 do
            if VendorCounter = 1 then
                FilterToExcludeTopFiveVendors := StrSubstNo('<>%1', VendorNo[VendorCounter])
            else
                FilterToExcludeTopFiveVendors += StrSubstNo('&<>%1', VendorNo[VendorCounter]);
        exit(FilterToExcludeTopFiveVendors);
    end;
}
