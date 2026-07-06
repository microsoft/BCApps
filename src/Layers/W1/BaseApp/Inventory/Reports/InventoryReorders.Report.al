// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;

report 717 "Inventory - Reorders"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryReorders.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Inventory Reorders';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Vendor No.");
            RequestFilterFields = "No.", "Location Filter", "Variant Filter", "Assembly BOM", "Inventory Posting Group", "Shelf No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTableCaption; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(VendPhoneNo; Vend."Phone No.")
            {
            }
            column(VendName; Vend.Name)
            {
            }
            column(VendNo_Item; "Vendor No.")
            {
            }
            column(ReorderQty; ReorderQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ReorderQty_Qty; "Reorder Quantity")
            {
            }
            column(QtyAvailable; QtyAvailable)
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrder_Item; "Qty. on Purch. Order")
            {
            }
            column(LeadTimeCalc_Item; "Lead Time Calculation")
            {
            }
            column(VendorItemNo_Item; "Vendor Item No.")
            {
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
            }
            column(Desc_Item; Description)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(InventoryReordersCaption; InventoryReordersCaptionLbl)
            {
            }
            column(LeadTimeCalculationCaption; LeadTimeCalculationCaptionLbl)
            {
            }
            column(VendPhoneNoCaption; VendPhoneNoCaptionLbl)
            {
            }
            column(VendorCaption; VendorCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(BaseUnitofMeasureCaption; BaseUnitofMeasureCaptionLbl)
            {
            }
            column(VendorItemNoCaption; VendorItemNoCaptionLbl)
            {
            }
            column(AvailableInventoryCaption; AvailableInventoryCaptionLbl)
            {
            }
            column(ReorderQuantityCaption; ReorderQuantityCaptionLbl)
            {
            }
            column(QtytoOrderCaption; QtytoOrderCaptionLbl)
            {
            }
            column(QtyonPurchOrderCaption; QtyonPurchOrderCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TransferPlanningParameters2(Item);

                CalcQuantities(Item);

                if not Vend.Get("Vendor No.") then
                    Vend.Init();
            end;

            trigger OnPreDataItem()
            begin
                if UseStockkeepingUnit then
                    CurrReport.Break();

                SetFilter("Vendor No.", BuyFromVendorNo);
            end;
        }
        dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
        {
            DataItemTableView = sorting("Replenishment System", "Vendor No.", "Transfer-from Code");
            column(StockkeepingUnitTableCaption; TableCaption + ': ' + SKUFIlter)
            {
            }
            column(SKUFIlter; SKUFIlter)
            {
            }
            column(CompanyName_SKU; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PageCaption_SKU; PageCaptionLbl)
            {
            }
            column(InventoryReordersCaption_SKU; InventoryReordersCaptionLbl)
            {
            }
            column(VendName_StockKeepingUnit; Vend.Name)
            {
            }
            column(VendorNo_SKU; "Vendor No.")
            {
            }
            column(LocationPhoneNo; Location."Phone No.")
            {
            }
            column(LocationName; Location.Name)
            {
            }
            column(TrnsfrFrmCode_SKU; "Transfer-from Code")
            {
            }
            column(ReOrderQty_StockKeepingUnit; ReorderQty)
            {
                DecimalPlaces = 0 : 5;
            }
            column(ReorderQty_SKU; "Reorder Quantity")
            {
            }
            column(QtyAvailable_StockKeepingUnit; QtyAvailable)
            {
                DecimalPlaces = 0 : 5;
            }
            column(QtyOnPurchOrder_SKU; "Qty. on Purch. Order")
            {
            }
            column(TimeCalculation; TimeCalculation)
            {
            }
            column(VendItemNo_SKU; "Vendor Item No.")
            {
            }
            column(Item2BaseUnitOfMeasure; Item2."Base Unit of Measure")
            {
            }
            column(Item2Description; Item2.Description)
            {
            }
            column(ItemNo_SKU; "Item No.")
            {
            }
            column(TransOrdRcptQty_SKU; "Trans. Ord. Receipt (Qty.)")
            {
            }
            column(QtyInTransit_SKU; "Qty. in Transit")
            {
            }
            column(VariantCode_SKU; "Variant Code")
            {
            }
            column(LocCOde_SKU; "Location Code")
            {
            }
            column(UseStockkeepingUnit; UseStockkeepingUnit)
            {
            }
            column(RplnshSys_SKU; "Replenishment System")
            {
            }
            column(TimeCalculationCaption; TimeCalculationCaptionLbl)
            {
            }
            column(TransOrdReceiptQtyCaption; TransOrdReceiptQtyCaptionLbl)
            {
            }
            column(QtyinTransitCaption; QtyinTransitCaptionLbl)
            {
            }
            column(LocationCodeCaption; LocationCodeCaptionLbl)
            {
            }
            column(VariantCodeCaption; VariantCodeCaptionLbl)
            {
            }
            column(TransferfromCaption; TransferfromCaptionLbl)
            {
            }
            column(AvailableInventoryCaption_SKU; AvailableInventoryCaptionLbl)
            {
            }
            column(ReorderQuantityCaption_SKU; ReorderQuantityCaptionLbl)
            {
            }
            column(QtytoOrderCaption_SKU; QtytoOrderCaptionLbl)
            {
            }
            column(NoCaption_SKU; NoCaptionLbl)
            {
            }
            column(DescriptionCaption_SKU; DescriptionCaptionLbl)
            {
            }
            column(BaseUnitofMeasureCaption_SKU; BaseUnitofMeasureCaptionLbl)
            {
            }
            column(VendorItemNoCaption_SKU; VendorItemNoCaptionLbl)
            {
            }
            column(QtyonPurchOrderCaption_SKU; QtyonPurchOrderCaptionLbl)
            {
            }
            column(VendPhoneNoCaption_SKU; VendPhoneNoCaptionLbl)
            {
            }
            column(VendorCaption_SKU; VendorCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TransferPlanningParameters("Stockkeeping Unit");

                if "Item No." <> Item2."No." then
                    if not Item2.Get("Item No.") then
                        Item2.Init();
                CopySKUToItem("Stockkeeping Unit", Item2);
                Item2.SetRange("Location Filter", "Location Code");
                Item2.SetRange("Variant Filter", "Variant Code");

                CalcQuantities(Item2);

                Evaluate(TimeCalculation, '');
                if "Replenishment System" = "Replenishment System"::Purchase then
                    TimeCalculation := "Lead Time Calculation"
                else
                    if TransferRoute.Get("Transfer-from Code", "Location Code") then
                        if ShippingAgentServices.Get(
                             TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code")
                        then
                            TimeCalculation := ShippingAgentServices."Shipping Time";

                if not Vend.Get("Vendor No.") then
                    Vend.Init();
                if not Location.Get("Transfer-from Code") then
                    Location.Init();
            end;

            trigger OnPreDataItem()
            begin
                if not UseStockkeepingUnit then
                    CurrReport.Break();

                SetFilter("Item No.", Item.GetFilter("No."));
                SetFilter("Location Code", Item.GetFilter("Location Filter"));
                SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                SetFilter("Assembly BOM", Item.GetFilter("Assembly BOM"));
                SetFilter("Shelf No.", Item.GetFilter("Shelf No."));
                SetFilter("Vendor No.", BuyFromVendorNo);
                SetFilter("Transfer-from Code", TransferFromCode);
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
                    field(UseStockkeepUnit; UseStockkeepingUnit)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want to only include items that are set up as SKUs. This adds SKU-related fields, such as the Location Code, Variant Code, and Qty. in Transit fields, to the report.';
                    }
                    field(BuyFromVendNo; BuyFromVendorNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Buy-from Vendor No.';
                        TableRelation = Vendor;
                        ToolTip = 'Specifies a filter for the vendor or vendors that you want to view items for.';
                    }
                    field(TransferFromCode; TransferFromCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transfer-from Code';
                        Enabled = TransferFromCodeEnable;
                        TableRelation = Location where("Use As In-Transit" = const(false));
                        ToolTip = 'Specifies a filter for the location or locations from which you want to see inbound SKU quantities.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            TransferFromCodeEnable := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        ItemFilter := Item.GetFilters();
        SKUFIlter := "Stockkeeping Unit".GetFilters();
    end;

    var
        Vend: Record Vendor;
        Item2: Record Item;
        Location: Record Location;
        TransferRoute: Record "Transfer Route";
        ShippingAgentServices: Record "Shipping Agent Services";
        AvailabilityMgt: Codeunit "Available Management";
        TimeCalculation: DateFormula;
        ItemFilter: Text;
        QtyAvailable: Decimal;
        ReorderQty: Decimal;
        UseStockkeepingUnit: Boolean;
        SKUFIlter: Text;
        BuyFromVendorNo: Code[20];
        TransferFromCode: Code[10];
        TransferFromCodeEnable: Boolean;
        PageCaptionLbl: Label 'Page';
        InventoryReordersCaptionLbl: Label 'Inventory - Reorders';
        LeadTimeCalculationCaptionLbl: Label 'Lead Time Calculation';
        VendPhoneNoCaptionLbl: Label 'Phone No.';
        VendorCaptionLbl: Label 'Vendor';
        NoCaptionLbl: Label 'No.';
        DescriptionCaptionLbl: Label 'Description';
        BaseUnitofMeasureCaptionLbl: Label 'Base Unit of Measure';
        VendorItemNoCaptionLbl: Label 'Vendor Item No.';
        AvailableInventoryCaptionLbl: Label 'Available Inventory';
        ReorderQuantityCaptionLbl: Label 'Reorder Quantity';
        QtytoOrderCaptionLbl: Label 'Qty. to Order';
        QtyonPurchOrderCaptionLbl: Label 'Qty. on Purch. Order';
        TimeCalculationCaptionLbl: Label 'Time Calculation';
        TransOrdReceiptQtyCaptionLbl: Label 'Trans. Ord. Receipt (Qty.)';
        QtyinTransitCaptionLbl: Label 'Qty. in Transit';
        LocationCodeCaptionLbl: Label 'Location Code';
        VariantCodeCaptionLbl: Label 'Variant Code';
        TransferfromCaptionLbl: Label 'Transfer from';

    local procedure CopySKUToItem(SKU: Record "Stockkeeping Unit"; var NewItem: Record Item)
    begin
        NewItem."Reordering Policy" := SKU."Reordering Policy";
        NewItem."Safety Stock Quantity" := SKU."Safety Stock Quantity";
        NewItem."Reorder Point" := SKU."Reorder Point";
        NewItem."Maximum Inventory" := SKU."Maximum Inventory";
        NewItem."Reorder Quantity" := SKU."Reorder Quantity";
        NewItem."Minimum Order Quantity" := SKU."Minimum Order Quantity";
        NewItem."Maximum Order Quantity" := SKU."Maximum Order Quantity";
        NewItem."Order Multiple" := SKU."Order Multiple";
    end;

    local procedure TransferPlanningParameters(var SKU: Record "Stockkeeping Unit")
    var
        SKU2: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
    begin
        GetPlanningParameters.AtSKU(SKU2, SKU."Item No.", SKU."Variant Code", SKU."Location Code");
        SKU := SKU2;
        SKU.CalcFields(
          Inventory, "Qty. on Purch. Order", "Qty. on Sales Order",
          "Trans. Ord. Shipment (Qty.)", "Qty. in Transit", "Trans. Ord. Receipt (Qty.)");
    end;

    local procedure TransferPlanningParameters2(var NewItem: Record Item)
    var
        SKU: Record "Stockkeeping Unit";
    begin
        SKU.Init();
        SKU."Item No." := NewItem."No.";
        TransferPlanningParameters(SKU);
        CopySKUToItem(SKU, NewItem);
    end;

    local procedure CalcQuantities(var NewItem: Record Item)
    var
        AvailToPromise: Codeunit "Available to Promise";
        Demand: Decimal;
        Supply: Decimal;
        ProjectedInventory: Decimal;
    begin
        NewItem.SetRange("Date Filter", 0D, DMY2Date(31, 12, 9999));
        NewItem.CalcFields(Inventory);
        Demand :=
          AvailToPromise.CalcGrossRequirement(NewItem);
        Supply :=
          AvailToPromise.CalcScheduledReceipt(NewItem);

        QtyAvailable := NewItem.Inventory + Supply - Demand - NewItem."Safety Stock Quantity";
        if QtyAvailable >= NewItem."Reorder Point" then
            CurrReport.Skip();

        case NewItem."Reordering Policy" of
            NewItem."Reordering Policy"::"Maximum Qty.",
          NewItem."Reordering Policy"::"Fixed Reorder Qty.":
                ProjectedInventory := QtyAvailable + NewItem."Safety Stock Quantity";
            else
                ProjectedInventory := QtyAvailable;
        end;
        ReorderQty :=
          AvailabilityMgt.GetItemReorderQty(NewItem, ProjectedInventory);
    end;

    procedure InitializeRequest(NewUseStockkeepingUnit: Boolean; NewBuyFromVendorNo: Code[20]; NewTransferFromCode: Code[10])
    begin
        UseStockkeepingUnit := NewUseStockkeepingUnit;
        BuyFromVendorNo := NewBuyFromVendorNo;
        TransferFromCode := NewTransferFromCode;
    end;
}

