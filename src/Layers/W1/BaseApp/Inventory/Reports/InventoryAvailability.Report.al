// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 705 "Inventory Availability"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryAvailability.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Availability';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = where(Type = const(Inventory));
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Search Description", "Assembly BOM", "Inventory Posting Group", "Statistics Group", "Vendor No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TableItemFilter; TableCaption + ': ' + GlobalItemFilter)
            {
            }
            column(ItemFilter; GlobalItemFilter)
            {
            }
            column(GetCurrentKey; GlobalGetCurrentKey)
            {
            }
            column(UseStockkeepingUnit; GlobalUseStockkeepingUnit)
            {
            }
            column(InventPostGroup_Item; "Inventory Posting Group")
            {
            }
            column(InvtReorder; Format(GlobalInvtReorder))
            {
            }
            column(ReorderPoint_Item; "Reorder Point")
            {
                IncludeCaption = true;
            }
            column(ProjAvailBalance; GlobalProjAvailBalance)
            {
                DecimalPlaces = 0 : 5;
            }
            column(PlannedOrderReceipt; GlobalPlannedOrderReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BackOrderQty; GlobalBackOrderQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ScheduledReceipt; GlobalScheduledReceipt)
            {
                DecimalPlaces = 0 : 5;
            }
            column(GrossRequirement; GlobalGrossRequirement)
            {
                DecimalPlaces = 0 : 5;
            }
            column(BaseUnitofMeasure_Item; "Base Unit of Measure")
            {
                IncludeCaption = true;
            }
            column(AssemblyBOM_Item; Format("Assembly BOM"))
            {
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(InventoryAvailabilityCaption; InventoryAvailabilityCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BOMCaption; BOMCaptionLbl)
            {
            }
            column(GrossRequirementCaption; GrossRequirementCaptionLbl)
            {
            }
            column(ScheduledReceiptCaption; ScheduledReceiptCaptionLbl)
            {
            }
            column(PlannedOrderReceiptCaption; PlannedOrderReceiptCaptionLbl)
            {
            }
            column(QuantityOnBackOrderCaption; QuantityOnBackOrderCaptionLbl)
            {
            }
            column(ProjectedAvailableBalCaption; ProjectedAvailableBalCaptionLbl)
            {
            }
            column(ReorderCaption; ReorderCaptionLbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(AssemblyBOMStock_Item; Format(Item."Assembly BOM"))
                {
                }
                column(UnitofMeasure_Item; Item."Base Unit of Measure")
                {
                }
                column(InvtReorder2; Format(GlobalInvtReorder))
                {
                }
                column(ReordPoint_StockkeepUnit; "Reorder Point")
                {
                }
                column(ProjAvailBalance2; GlobalProjAvailBalance)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(BackOrderQty2; GlobalBackOrderQty)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(PlannedOrderReceipt2; GlobalPlannedOrderReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ScheduledReceipt2; GlobalScheduledReceipt)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GrossRequirement2; GlobalGrossRequirement)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VariantCode_StockkeepUnit; "Variant Code")
                {
                    IncludeCaption = true;
                }
                column(LocCode_StockkeepUnit; "Location Code")
                {
                    IncludeCaption = true;
                }
                column(SKUPrintLoop; GlobalSKUPrintLoop)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    GlobalSKUPrintLoop := GlobalSKUPrintLoop + 1;
                    if "Reordering Policy" in ["Reordering Policy"::Order, "Reordering Policy"::"Lot-for-Lot"] then
                        "Reorder Point" := 0;
                    CalcNeed(Item, "Location Code", "Variant Code", "Reorder Point");
                end;

                trigger OnPreDataItem()
                begin
                    if not GlobalUseStockkeepingUnit then
                        CurrReport.Break();

                    GlobalSKUPrintLoop := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not GlobalUseStockkeepingUnit then begin
                    if "Reordering Policy" in ["Reordering Policy"::Order, "Reordering Policy"::"Lot-for-Lot"] then
                        "Reorder Point" := 0;
                    CalcNeed(Item, GetFilter("Location Filter"), GetFilter("Variant Filter"), "Reorder Point");
                end;
            end;

            trigger OnPreDataItem()
            begin
                GlobalGetCurrentKey := CurrentKey;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UseStockkeepingUnit; GlobalUseStockkeepingUnit)
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
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GlobalItemFilter := Item.GetFilters();
    end;

    var
        AvailToPromise: Codeunit "Available to Promise";
        GlobalItemFilter: Text;
        GlobalBackOrderQty: Decimal;
        GlobalInvtReorder: Boolean;
        GlobalGrossRequirement: Decimal;
        GlobalPlannedOrderReceipt: Decimal;
        GlobalScheduledReceipt: Decimal;
        GlobalProjAvailBalance: Decimal;
        GlobalUseStockkeepingUnit: Boolean;
        GlobalSKUPrintLoop: Integer;
        GlobalGetCurrentKey: Text;
        InventoryAvailabilityCaptionLbl: Label 'Inventory Availability';
        PageCaptionLbl: Label 'Page';
        BOMCaptionLbl: Label 'BOM';
        GrossRequirementCaptionLbl: Label 'Gross Requirement';
        ScheduledReceiptCaptionLbl: Label 'Scheduled Receipt';
        PlannedOrderReceiptCaptionLbl: Label 'Planned Order Receipt';
        QuantityOnBackOrderCaptionLbl: Label 'Quantity on Back Order';
        ProjectedAvailableBalCaptionLbl: Label 'Projected Available Balance';
        ReorderCaptionLbl: Label 'Reorder';

    procedure CalcNeed(Item: Record Item; LocationFilter: Text; VariantFilter: Text; ReorderPoint: Decimal)
    begin
        Item.SetFilter("Location Filter", LocationFilter);
        Item.SetFilter("Variant Filter", VariantFilter);
        Item.SetRange("Drop Shipment Filter", false);

        Item.SetRange("Date Filter", 0D, WorkDate());
        Item.CalcFields(
          "Qty. on Purch. Order",
          "Planning Receipt (Qty.)",
          "Purch. Req. Receipt (Qty.)",
          "Qty. in Transit",
          "Trans. Ord. Receipt (Qty.)",
          "Reserved Qty. on Inventory");
        GlobalBackOrderQty :=
          Item."Qty. on Purch. Order" + Item.CalcPlannedOrderReceiptQty() +
          Item."Qty. in Transit" + Item."Trans. Ord. Receipt (Qty.)" +
          Item."Planning Receipt (Qty.)" + Item."Purch. Req. Receipt (Qty.)" +
          Item.CalcScheduledReceiptQty();

        Item.SetRange("Date Filter", 0D, DMY2Date(31, 12, 9999));
        GlobalGrossRequirement :=
          AvailToPromise.CalcGrossRequirement(Item);
        GlobalScheduledReceipt :=
          AvailToPromise.CalcScheduledReceipt(Item);

        Item.CalcFields(
          Inventory,
          "Planning Receipt (Qty.)",
          "Purch. Req. Receipt (Qty.)",
          "Res. Qty. on Req. Line");

        GlobalScheduledReceipt := GlobalScheduledReceipt - Item.CalcPlannedOrderReceiptQty();

        GlobalPlannedOrderReceipt := Item.CalcPlannedOrderReceiptQty() + Item."Purch. Req. Receipt (Qty.)";

        GlobalProjAvailBalance :=
          Item.Inventory +
          GlobalScheduledReceipt -
          GlobalGrossRequirement +
          Item."Purch. Req. Receipt (Qty.)" -
          Item."Res. Qty. on Req. Line";

        GlobalInvtReorder := GlobalProjAvailBalance < ReorderPoint;

        OnAfterCalcNeed(Item, LocationFilter, VariantFilter, ReorderPoint, GlobalInvtReorder)
    end;

    procedure InitializeRequest(NewUseStockkeepingUnit: Boolean)
    begin
        GlobalUseStockkeepingUnit := NewUseStockkeepingUnit;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcNeed(var Item: Record Item; LocationFilter: Text; VariantFilter: Text; ReorderPoint: Decimal; var GlobalInvtReorder: Boolean)
    begin
    end;
}

