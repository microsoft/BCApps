// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;

report 707 "Inventory - Availability Plan"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryAvailabilityPlan.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory - Availability Plan';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where(Type = const(Inventory));
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group", "Vendor No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TblCptItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2]))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3]))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4]))
            {
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5]))
            {
            }
            column(PeriodStartDate6; Format(PeriodStartDate[6]))
            {
            }
            column(PeriodStartDate7; Format(PeriodStartDate[7]))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1))
            {
            }
            column(PeriodStartDate51; Format(PeriodStartDate[5] - 1))
            {
            }
            column(PeriodStartDate61; Format(PeriodStartDate[6] - 1))
            {
            }
            column(PeriodStartDate71; Format(PeriodStartDate[7] - 1))
            {
            }
            column(PeriodStartDate81; Format(PeriodStartDate[8] - 1))
            {
            }
            column(UseStockkeepingUnit; UseStockkeepingUnit)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(VendorNo_Item; "Vendor No.")
            {
            }
            column(VendName; Vend.Name)
            {
            }
            column(VendorItemNo_Item; "Vendor Item No.")
            {
                IncludeCaption = true;
            }
            column(LeadTimeCalc_Item; "Lead Time Calculation")
            {
                IncludeCaption = true;
            }
            column(GrossReq1; GrossReq[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq2; GrossReq[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq3; GrossReq[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq4; GrossReq[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq5; GrossReq[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq6; GrossReq[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq7; GrossReq[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossReq8; GrossReq[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt1; SchedReceipt[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt2; SchedReceipt[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt3; SchedReceipt[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt4; SchedReceipt[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt5; SchedReceipt[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt6; SchedReceipt[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt7; SchedReceipt[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(SchedReceipt8; SchedReceipt[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(Inventory_Item; Inventory)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance1; ProjAvBalance[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance2; ProjAvBalance[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance3; ProjAvBalance[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance4; ProjAvBalance[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance5; ProjAvBalance[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance6; ProjAvBalance[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance7; ProjAvBalance[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(ProjAvBalance8; ProjAvBalance[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossRequirement; GrossRequirement)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ScheduledReceipt; ScheduledReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlannedReceipt; PlannedReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt1; PlanReceipt[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt2; PlanReceipt[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt3; PlanReceipt[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt4; PlanReceipt[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt5; PlanReceipt[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt6; PlanReceipt[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt7; PlanReceipt[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanReceipt8; PlanReceipt[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease1; PlanRelease[1])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlannedRelease; PlannedRelease)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease2; PlanRelease[2])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease3; PlanRelease[3])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease4; PlanRelease[4])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease5; PlanRelease[5])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease6; PlanRelease[6])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease7; PlanRelease[7])
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlanRelease8; PlanRelease[8])
            {
                DecimalPlaces = 0 : 5;
            }
            column(InventoryAvailabilityPlanCaption; InventoryAvailabilityPlanCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(GrossReq1Caption; GrossReq1CaptionLbl)
            {
            }
            column(GrossReq8Caption; GrossReq8CaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(GrossRequirementCaption; GrossRequirementCaptionLbl)
            {
            }
            column(ScheduledReceiptCaption; ScheduledReceiptCaptionLbl)
            {
            }
            column(InventoryCaption; InventoryCaptionLbl)
            {
            }
            column(PlannedReceiptCaption; PlannedReceiptCaptionLbl)
            {
            }
            column(PlannedReleasesCaption; PlannedReleasesCaptionLbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(Description1_Item; Item.Description)
                {
                }
                column(No1_Item; Item."No.")
                {
                }
                column(SKUPrintLoop; Format(SKUPrintLoop))
                {
                }
                column(ReplenishSys_SKU; Format("Replenishment System", 0, 2))
                {
                }
                column(VendName1; Vend.Name)
                {
                }
                column(VendorNo_SKU; "Vendor No.")
                {
                }
                column(LeadTimeCalc_SKU; "Lead Time Calculation")
                {
                    IncludeCaption = true;
                }
                column(VendItemNo_SKU; "Vendor Item No.")
                {
                    IncludeCaption = true;
                }
                column(LocationName; Location.Name)
                {
                }
                column(TransFrmCode_SKU; "Transfer-from Code")
                {
                }
                column(ShippingTime; ShippingTime)
                {
                }
                column(Inventory1_Item; Item.Inventory)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(PlannedRelease1; PlannedRelease)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(PlannedReceipt1; PlannedReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ScheduledReceipt1; ScheduledReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GrossReq139; GrossRequirement)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(LocCode_SKU; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(VariantCode_SKU; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(LocationCaption; LocationCaptionLbl)
                {
                }
                column(ShippingTimeCaption; ShippingTimeCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SKUPrintLoop := SKUPrintLoop + 1;

                    if "Replenishment System" = "Replenishment System"::Purchase then begin
                        if not Vend.Get("Vendor No.") then
                            Vend.Init();
                    end else
                        if not TransferRoute.Get("Transfer-from Code", "Location Code") then begin
                            if not Location.Get("Transfer-from Code") then
                                Location.Init();
                        end else
                            if ShippingAgentServices.Get(
                                 TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code")
                            then
                                ShippingTime := ShippingAgentServices."Shipping Time";

                    for i := 1 to 8 do
                        CalcNeed(Item, "Location Code", "Variant Code");

                    if not Print then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if not UseStockkeepingUnit then
                        CurrReport.Break();

                    SKUPrintLoop := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not UseStockkeepingUnit then begin
                    if not Vend.Get("Vendor No.") then
                        Vend.Init();
                    Print := false;
                    for i := 1 to 8 do
                        CalcNeed(Item, GetFilter("Location Filter"), GetFilter("Variant Filter"));

                    if not Print then
                        CurrReport.Skip();
                end;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Inventory - Availability Plan';
        AboutText = 'Get an overview of specific items and stock-keeping units, and their availability.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[2])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(UseStockkeepUnit; UseStockkeepingUnit)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want the report to list the availability of items by stockkeeping unit.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
            if PeriodStartDate[2] = 0D then
                PeriodStartDate[2] := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        for i := 2 to 7 do
            PeriodStartDate[i + 1] := CalcDate(PeriodLength, PeriodStartDate[i]);
        PeriodStartDate[9] := DMY2Date(31, 12, 9999);
    end;

    var
        Vend: Record Vendor;
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        ShippingAgentServices: Record "Shipping Agent Services";
        AvailToPromise: Codeunit "Available to Promise";
        PeriodLength: DateFormula;
        ShippingTime: DateFormula;
        ItemFilter: Text;
        SchedReceipt: array[8] of Decimal;
        PlanReceipt: array[8] of Decimal;
        PlanRelease: array[8] of Decimal;
        PeriodStartDate: array[9] of Date;
        ProjAvBalance: array[8] of Decimal;
        GrossReq: array[8] of Decimal;
        Print: Boolean;
        i: Integer;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PlannedReceipt: Decimal;
        PlannedRelease: Decimal;
        UseStockkeepingUnit: Boolean;
        SKUPrintLoop: Integer;

        InventoryAvailabilityPlanCaptionLbl: Label 'Inventory - Availability Plan';
        CurrReportPageNoCaptionLbl: Label 'Page';
        GrossReq1CaptionLbl: Label '...Before';
        GrossReq8CaptionLbl: Label 'After...';
        VendorCaptionLbl: Label 'Vendor';
        GrossRequirementCaptionLbl: Label 'Gross Requirement';
        ScheduledReceiptCaptionLbl: Label 'Scheduled Receipt';
        InventoryCaptionLbl: Label 'Inventory';
        PlannedReceiptCaptionLbl: Label 'Planned Receipt';
        PlannedReleasesCaptionLbl: Label 'Planned Releases';
        LocationCaptionLbl: Label 'Location';
        ShippingTimeCaptionLbl: Label 'Shipping Time';

    local procedure CalcNeed(Item: Record Item; LocationFilter: Text[250]; VariantFilter: Text[250])
    var
        PlannedOrderReleaseQty: Decimal;
    begin
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        Item.CalcFields(Inventory);
        if Item.Inventory <> 0 then
            Print := true;

        Item.SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);

        GrossReq[i] := AvailToPromise.CalcGrossRequirement(Item);
        SchedReceipt[i] := AvailToPromise.CalcScheduledReceipt(Item);

        Item.CalcFields("Planning Receipt (Qty.)", "Planning Release (Qty.)");
        PlannedOrderReleaseQty := Item.CalcPlannedOrderReceiptQty();

        SchedReceipt[i] := SchedReceipt[i] - PlannedOrderReleaseQty;
        PlanReceipt[i] := Item."Planning Receipt (Qty.)" + PlannedOrderReleaseQty;
        PlanRelease[i] := Item."Planning Release (Qty.)" + PlannedOrderReleaseQty;

        if i = 1 then
            ProjAvBalance[1] :=
              Item.Inventory - GrossReq[1] + SchedReceipt[1] + PlanReceipt[1]
        else
            ProjAvBalance[i] :=
              ProjAvBalance[i - 1] -
              GrossReq[i] + SchedReceipt[i] + PlanReceipt[i];

        if (GrossReq[i] <> 0) or
           (PlanReceipt[i] <> 0) or
           (SchedReceipt[i] <> 0) or
           (PlanRelease[i] <> 0)
        then
            Print := true;
    end;

    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: DateFormula; NewUseStockkeepingUnit: Boolean)
    begin
        PeriodStartDate[2] := NewPeriodStartDate;
        PeriodLength := NewPeriodLength;
        UseStockkeepingUnit := NewUseStockkeepingUnit;
    end;
}

