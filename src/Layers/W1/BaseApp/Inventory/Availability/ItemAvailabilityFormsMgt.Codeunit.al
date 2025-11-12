// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;

codeunit 353 "Item Availability Forms Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        ItemAvailByBOMLevel: Page "Item Availability by BOM Level";
        ForecastName: Code[10];
        QtyByUnitOfMeasure: Decimal;

#pragma warning disable AA0074
        Text012: Label 'Do you want to change %1 from %2 to %3?', Comment = '%1=FieldCaption, %2=OldDate, %3=NewDate';
#pragma warning restore AA0074

    procedure CalcItemPlanningFields(var Item: Record Item; CalculateTransferQuantities: Boolean)
    begin
        Item.Init();
        if not CalculateTransferQuantities then
            Item.CalcFields(
              Inventory,
              "Net Change",
              "Purch. Req. Receipt (Qty.)",
              "Planning Issues (Qty.)",
              "Purch. Req. Release (Qty.)")
        else
            Item.CalcFields(
              Inventory,
              "Net Change",
              "Purch. Req. Receipt (Qty.)",
              "Planning Issues (Qty.)",
              "Purch. Req. Release (Qty.)",
              "Trans. Ord. Shipment (Qty.)", "Qty. in Transit", "Trans. Ord. Receipt (Qty.)");

        OnAfterCalcItemPlanningFields(Item);
    end;

    procedure CalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal)
    var
        TransOrdShipmentQty: Decimal;
        QtyinTransit: Decimal;
        TransOrdReceiptQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateNeed(Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases, IsHandled);
        if not IsHandled then begin
            CalcItemPlanningFields(Item, true);

            if Item.GetFilter("Location Filter") = '' then begin
                TransOrdShipmentQty := 0;
                QtyinTransit := 0;
                TransOrdReceiptQty := 0;
            end else begin
                TransOrdShipmentQty := Item."Trans. Ord. Shipment (Qty.)";
                QtyinTransit := Item."Qty. in Transit";
                TransOrdReceiptQty := Item."Trans. Ord. Receipt (Qty.)";
            end;
            GrossRequirement :=
                Item."Qty. on Sales Order" + Item."Qty. on Job Order" + Item.CalcQtyOnComponentLines() +
                TransOrdShipmentQty + Item."Planning Issues (Qty.)" + Item."Qty. on Asm. Component" + Item."Qty. on Purch. Return";
            OnCalculateNeedOnAfterCalcGrossRequirement(Item, GrossRequirement);
            PlannedOrderReceipt :=
                Item.CalcPlannedOrderReceiptQty() + Item."Purch. Req. Receipt (Qty.)";
            ScheduledReceipt :=
                Item.CalcFPOrderReceiptQty() + Item.CalcRelOrderReceiptQty() + Item."Qty. on Purch. Order" +
                QtyinTransit + TransOrdReceiptQty + Item."Qty. on Assembly Order" + Item."Qty. on Sales Return";
            OnCalculateNeedOnAfterCalcScheduledReceipt(Item, ScheduledReceipt, QtyinTransit, TransOrdReceiptQty);
            PlannedOrderReleases :=
                Item.CalcPlannedOrderReceiptQty() + Item."Purch. Req. Release (Qty.)";
        end;

        OnAfterCalculateNeed(Item, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
    end;

    local procedure CalcProjAvailableBalance(var Item: Record Item): Decimal
    var
        Item2: Record Item;
        GrossRequirement: Decimal;
        PlannedOrderReceipt: Decimal;
        ScheduledReceipt: Decimal;
        PlannedOrderReleases: Decimal;
    begin
        Item2.Copy(Item);
        Item2.SetRange("Date Filter", 0D, Item.GetRangeMax("Date Filter"));
        CalculateNeed(Item2, GrossRequirement, PlannedOrderReceipt, ScheduledReceipt, PlannedOrderReleases);
        exit(Item2.Inventory + PlannedOrderReceipt + ScheduledReceipt - GrossRequirement);
    end;

    local procedure CalcProjAvailableBalance(Inventory: Decimal; GrossRequirement: Decimal; PlannedOrderReceipt: Decimal; ScheduledReceipt: Decimal): Decimal
    begin
        exit(Inventory + PlannedOrderReceipt + ScheduledReceipt - GrossRequirement);
    end;

    procedure CalcAvailQuantities(var Item: Record Item; IsBalanceAtDate: Boolean; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal)
    var
        AvailableMgt: Codeunit "Available Management";
    begin
        CalculateNeed(Item, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt, PlannedOrderReleases);
        if IsBalanceAtDate then
            ProjAvailableBalance :=
              CalcProjAvailableBalance(Item.Inventory, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt)
        else
            ProjAvailableBalance := CalcProjAvailableBalance(Item);

        OnAfterCalculateProjAvailableBalance(Item, ProjAvailableBalance);

        ExpectedInventory := AvailableMgt.ExpectedQtyOnHand(Item, true, 0, QtyAvailable, DMY2Date(31, 12, 9999));
    end;

    procedure CalcAvailQuantities(var Item: Record Item; IsBalanceAtDate: Boolean; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal; var AvailableInventory: Decimal)
    var
        AvailableToPromise: Codeunit "Available to Promise";
    begin
        CalcAvailQuantities(
            Item, isBalanceAtDate, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
            PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, QtyAvailable);
        AvailableInventory := AvailableToPromise.CalcAvailableInventory(Item);
    end;

    procedure ShowItemLedgerEntries(var Item: Record Item; NetChange: Boolean)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.FindLinesWithItemToPlan(Item, NetChange);
        PAGE.Run(0, ItemLedgEntry);
    end;

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Sales Availability Mgt.', '25.0')]
    procedure ShowSalesLines(var Item: Record Item)
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.ShowSalesLines(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Serv. Availability Mgt.', '25.0')]
    procedure ShowServLines(var Item: Record Item)
    var
        ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
    begin
        ServAvailabilityMgt.ShowServiceLines(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Job Planning Availability Mgt.', '25.0')]
    procedure ShowJobPlanningLines(var Item: Record Item)
    var
        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
    begin
        JobPlanningAvailabilityMgt.ShowJobPlanningLines(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Purch. Availability Mgt.', '25.0')]
    procedure ShowPurchLines(var Item: Record Item)
    var
        PurchAvailabilityMgt: Codeunit Microsoft.Purchases.Document."Purch. Availability Mgt.";
    begin
        PurchAvailabilityMgt.ShowPurchLines(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Availability Mgt.', '25.0')]
    procedure ShowSchedReceipt(var Item: Record Item)
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.ShowSchedReceipt(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Prod. Order Availability Mgt.', '25.0')]
    procedure ShowSchedNeed(var Item: Record Item)
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.ShowSchedNeed(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Transfer Availability Mgt.', '25.0')]
    procedure ShowTransLines(var Item: Record Item; What: Integer)
    var
        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
    begin
        TransferAvailabilityMgt.ShowTransLines(Item, What);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Assembly Availability Mgt.', '25.0')]
    procedure ShowAsmOrders(var Item: Record Item)
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.ShowAsmOrders(Item);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by same procedure in codeunit Assembly Availability Mgt.', '25.0')]
    procedure ShowAsmCompLines(var Item: Record Item)
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.ShowAsmCompLines(Item);
    end;
#endif

    procedure ShowItemAvailLineList(var Item: Record Item; What: Integer)
    var
        ItemCopy: Record Item;
        ItemAvailLineList: Page "Item Availability Line List";
    begin
        ItemCopy.Copy(Item);
        CalcItemPlanningFields(ItemCopy, ItemCopy.GetFilter("Location Filter") <> '');
        if QtyByUnitOfMeasure <> 0 then
            ItemAvailLineList.SetQtyByUnitOfMeasure(QtyByUnitOfMeasure);
        ItemAvailLineList.Init(What, ItemCopy);
        OnShowItemAvailLineListOnAfterItemAvailabilityLineListInit(ItemCopy, ItemAvailLineList);
        ItemAvailLineList.RunModal();
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityFromItem with enum', '25.0')]
    procedure ShowItemAvailFromItem(var Item: Record Item; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
        ShowItemAvailabilityFromItem(Item, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

    procedure ShowItemAvailabilityFromItem(var Item: Record Item; AvailabilityType: Enum "Item Availability Type")
    var
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        Item.TestField(Item."No.");
        if IsNullGuid(Item.SystemId) then begin
            Item.SecurityFiltering(SecurityFilter::Filtered);
            Item.Get(Item."No.");
        end;

        OnBeforeShowItemAvailFromItem(Item);
        case AvailabilityType of
            AvailabilityType::Period:
                ShowItemAvailabilityByPeriod(Item, '', NewDate, NewDate);
            AvailabilityType::Variant:
                ShowItemAvailabilityByVariant(Item, '', NewVariantCode, NewVariantCode);
            AvailabilityType::Location:
                ShowItemAvailabilityByLocation(Item, '', NewLocationCode, NewLocationCode);
            AvailabilityType::"Event":
                ShowItemAvailabilityByEvent(Item, '', NewDate, NewDate, false);
            AvailabilityType::BOM:
                ShowItemAvailabilityByBOMLevel(Item, '', NewDate, NewDate);
            AvailabilityType::UOM:
                ShowItemAvailabilityByUOM(Item, '', NewUnitOfMeasureCode, NewUnitOfMeasureCode);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromSalesLine in Sales Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromSalesLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(SalesLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromPurchLine in Purch. Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromPurchLine(var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        PurchAvailabilityMgt: Codeunit Microsoft.Purchases.Document."Purch. Availability Mgt.";
    begin
        PurchAvailabilityMgt.ShowItemAvailabilityFromPurchLine(PurchLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromReqLine in Req. Line Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromReqLine(var ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line"; AvailabilityType: Enum "Item Availability Type")
    var
        ReqLineAvailabilityMgt: Codeunit Microsoft.Inventory.Requisition."Req. Line Availability Mgt.";
    begin
        ReqLineAvailabilityMgt.ShowItemAvailabilityFromReqLine(ReqLine, AvailabilityType);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailFromProdOrderLine in Prod. Order Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderLine(ProdOrderLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailFromProdOrderComp in Prod. Order Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(ProdOrderComp, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromTransLine in Transfer Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromTransLine(var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
    begin
        TransferAvailabilityMgt.ShowItemAvailabilityFromTransLine(TransLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromWhseActivLine in Warehouse Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromWhseActivLine(var WhseActivLine: Record Microsoft.Warehouse.Activity."Warehouse Activity Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        WarehouseAvailabilityMgt: Codeunit Microsoft.Warehouse.Availability."Warehouse Availability Mgt.";
    begin
        WarehouseAvailabilityMgt.ShowItemAvailabilityFromWhseActivLine(WhseActivLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromServLine in Serv. Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromServLine(var ServLine: Record Microsoft.Service.Document."Service Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
    begin
        ServAvailabilityMgt.ShowItemAvailabilityFromServLine(ServLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailFromWhseRcptLine in Warehouse Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromWhseRcptLine(var WhseRcptLine: Record Microsoft.Warehouse.Document."Warehouse Receipt Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        WarehouseAvailabilityMgt: Codeunit Microsoft.Warehouse.Availability."Warehouse Availability Mgt.";
    begin
        WarehouseAvailabilityMgt.ShowItemAvailFromWhseRcptLine(WhseRcptLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityFromItemJnlLine()', '25.0')]
    procedure ShowItemAvailFromItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
        ShowItemAvailFromItemJnlLine(ItemJnlLine, AvailabilityType);
    end;
#endif

    procedure ShowItemAvailabilityFromItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        ItemJnlLine.TestField("Item No.");
        Item.Reset();
        Item.Get(ItemJnlLine."Item No.");
        FilterItem(Item, ItemJnlLine."Location Code", ItemJnlLine."Variant Code", ItemJnlLine."Posting Date");

        OnBeforeShowItemAvailabilityFromItemJnlLine(Item, ItemJnlLine, AvailabilityType);
#if not CLEAN25
        OnBeforeShowItemAvailFromItemJnlLine(Item, ItemJnlLine, AvailabilityType.AsInteger());
#endif
        case AvailabilityType of
            AvailabilityType::Period:
                if ShowItemAvailabilityByPeriod(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Posting Date"), ItemJnlLine."Posting Date", NewDate) then
                    ItemJnlLine.Validate(ItemJnlLine."Posting Date", NewDate);
            AvailabilityType::Variant:
                if ShowItemAvailabilityByVariant(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Variant Code"), ItemJnlLine."Variant Code", NewVariantCode) then
                    ItemJnlLine.Validate(ItemJnlLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ShowItemAvailabilityByLocation(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Location Code"), ItemJnlLine."Location Code", NewLocationCode) then
                    ItemJnlLine.Validate(ItemJnlLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ShowItemAvailabilityByEvent(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Posting Date"), ItemJnlLine."Posting Date", NewDate, false) then
                    ItemJnlLine.Validate(ItemJnlLine."Posting Date", NewDate);
            AvailabilityType::BOM:
                if ShowItemAvailabilityByBOMLevel(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Posting Date"), ItemJnlLine."Posting Date", NewDate) then
                    ItemJnlLine.Validate(ItemJnlLine."Posting Date", NewDate);
            AvailabilityType::UOM:
                if ShowItemAvailabilityByUOM(Item, ItemJnlLine.FieldCaption(ItemJnlLine."Unit of Measure Code"), ItemJnlLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    ItemJnlLine.Validate(ItemJnlLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromAsmHeader in Assembly Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromAsmHeader(var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmHeader(AsmHeader, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromAsmLine in Assembly Availability Mgt.', '25.0')]
    procedure ShowItemAvailFromAsmLine(var AsmLine: Record Microsoft.Assembly.Document."Assembly Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(AsmLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by ShowItemAvailabilityFromPlanningComp in Planning Comp. Avail. Mgt.', '25.0')]
    procedure ShowItemAvailFromPlanningComp(var PlanningComp: Record Microsoft.Inventory.Planning."Planning Component"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    var
        PlanningCompAvailMgt: Codeunit Microsoft.Inventory.Planning."Planning Comp. Avail. Mgt.";
    begin
        PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(PlanningComp, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityFromInvtDocLine()', '25.0')]
    procedure ShowItemAvailFromInvtDocLine(var InvtDocLine: Record "Invt. Document Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM)
    begin
        ShowItemAvailabilityFromInvtDocLine(InvtDocLine, "Item Availability Type".FromInteger(AvailabilityType));
    end;
#endif

    procedure ShowItemAvailabilityFromInvtDocLine(var InvtDocLine: Record "Invt. Document Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        CaptionText: Text[80];
    begin
        InvtDocLine.TestField("Item No.");
        Item.Reset();
        Item.Get(InvtDocLine."Item No.");
        FilterItem(Item, InvtDocLine."Location Code", InvtDocLine."Variant Code", InvtDocLine."Posting Date");

        case AvailabilityType of
            AvailabilityType::Period:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailabilityByPeriod(Item, CaptionText, InvtDocLine."Posting Date", NewDate) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
            AvailabilityType::Variant:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Variant Code"), 1, 80);
                    if ShowItemAvailabilityByVariant(Item, CaptionText, InvtDocLine."Variant Code", NewVariantCode) then
                        InvtDocLine.Validate("Variant Code", NewVariantCode);
                end;
            AvailabilityType::Location:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Location Code"), 1, 80);
                    if ShowItemAvailabilityByLocation(Item, CaptionText, InvtDocLine."Location Code", NewLocationCode) then
                        InvtDocLine.Validate("Location Code", NewLocationCode);
                end;
            AvailabilityType::"Event":
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailabilityByEvent(Item, CaptionText, InvtDocLine."Posting Date", NewDate, false) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
            AvailabilityType::BOM:
                begin
                    CaptionText := CopyStr(InvtDocLine.FieldCaption("Posting Date"), 1, 80);
                    if ShowItemAvailabilityByBOMLevel(Item, CaptionText, InvtDocLine."Posting Date", NewDate) then
                        InvtDocLine.Validate("Posting Date", NewDate);
                end;
            else
                OnShowItemAvailabilityFromInvtDocLineOnAvailabilityTypeCaseElse(AvailabilityType, Item, InvtDocLine);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByEvent()', '25.0')]
    procedure ShowItemAvailByEvent(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; IncludeForecast: Boolean): Boolean
    begin
        exit(ShowItemAvailByEvent(Item, FieldCaption, OldDate, NewDate, IncludeForecast));
    end;
#endif

    procedure ShowItemAvailabilityByEvent(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; IncludeForecast: Boolean): Boolean
    var
        ItemAvailByEvent: Page "Item Availability by Event";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByEvent(Item, FieldCaption, OldDate, NewDate, IncludeForecast, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailByEvent(Item, FieldCaption, OldDate, NewDate, IncludeForecast, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if FieldCaption <> '' then
            ItemAvailByEvent.LookupMode(true);
        ItemAvailByEvent.SetItem(Item);
        if IncludeForecast then begin
            ItemAvailByEvent.SetIncludePlan(true);
            if ForecastName <> '' then
                ItemAvailByEvent.SetForecastName(ForecastName);
        end;
        if ItemAvailByEvent.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByEvent.GetSelectedDate();
            if (NewDate <> 0D) and (NewDate <> OldDate) then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByLocation()', '25.0')]
    procedure ShowItemAvailByLoc(var Item: Record Item; FieldCaption: Text[80]; OldLocationCode: Code[20]; var NewLocationCode: Code[20]): Boolean
    begin
        exit(ShowItemAvailabilityByLocation(Item, FieldCaption, OldLocationCode, NewLocationCode));
    end;
#endif

    procedure ShowItemAvailabilityByLocation(var Item: Record Item; FieldCaption: Text; OldLocationCode: Code[10]; var NewLocationCode: Code[10]): Boolean
    var
        ItemAvailabilityByLocation: Page "Item Availability by Location";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByLocation(Item, FieldCaption, OldLocationCode, NewLocationCode, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailByLoc(Item, FieldCaption, OldLocationCode, NewLocationCode, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Item.SetRange("Location Filter");
        if FieldCaption <> '' then
            ItemAvailabilityByLocation.LookupMode(true);
        ItemAvailabilityByLocation.SetRecord(Item);
        ItemAvailabilityByLocation.SetTableView(Item);
        if ItemAvailabilityByLocation.RunModal() = Action::LookupOK then begin
            NewLocationCode := ItemAvailabilityByLocation.GetLastLocation();
            if OldLocationCode <> NewLocationCode then
                if Confirm(Text012, true, FieldCaption, OldLocationCode, NewLocationCode) then
                    exit(true);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByPeriod()', '25.0')]
    procedure ShowItemAvailByDate(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    begin
        exit(ShowItemAvailabilityByPeriod(Item, FieldCaption, OldDate, NewDate));
    end;
#endif

    procedure ShowItemAvailabilityByPeriod(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date): Boolean
    var
        ItemAvailByPeriods: Page "Item Availability by Periods";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByPeriod(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailByDate(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Item.SetRange("Date Filter");
        if FieldCaption <> '' then
            ItemAvailByPeriods.LookupMode(true);
        ItemAvailByPeriods.SetRecord(Item);
        ItemAvailByPeriods.SetTableView(Item);
        if ItemAvailByPeriods.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByPeriods.GetLastDate();
            if OldDate <> NewDate then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByVariant()', '25.0')]
    procedure ShowItemAvailVariant(var Item: Record Item; FieldCaption: Text[80]; OldVariant: Code[20]; var NewVariant: Code[20]): Boolean
    begin
        exit(ShowItemAvailabilityByVariant(Item, FieldCaption, OldVariant, NewVariant));
    end;
#endif

    procedure ShowItemAvailabilityByVariant(var Item: Record Item; FieldCaption: Text; OldVariantCode: Code[10]; var NewVariantCode: Code[10]): Boolean
    var
        ItemAvailByVariant: Page "Item Availability by Variant";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByVariant(Item, FieldCaption, OldVariantCode, NewVariantCode, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailVariant(Item, FieldCaption, OldVariantCode, NewVariantCode, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Item.SetRange("Variant Filter");
        if FieldCaption <> '' then
            ItemAvailByVariant.LookupMode(true);
        ItemAvailByVariant.SetRecord(Item);
        ItemAvailByVariant.SetTableView(Item);
        if ItemAvailByVariant.RunModal() = ACTION::LookupOK then begin
            NewVariantCode := ItemAvailByVariant.GetLastVariant();
            if OldVariantCode <> NewVariantCode then
                if Confirm(Text012, true, FieldCaption, OldVariantCode, NewVariantCode) then
                    exit(true);
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByBOMLevel()', '25.0')]
    procedure ShowItemAvailByBOMLevel(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date): Boolean
    begin
        exit(ShowItemAvailabilityByBOMLevel(Item, FieldCaption, OldDate, NewDate));
    end;
#endif

    procedure ShowItemAvailabilityByBOMLevel(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByBOMLevel(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailByBOMLevel(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Clear(ItemAvailByBOMLevel);
        Item.SetRange("Date Filter");
        ItemAvailByBOMLevel.InitItem(Item);
        ItemAvailByBOMLevel.InitDate(OldDate);
        exit(ShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate));
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure ShowItemAvailabilityByUOM()', '25.0')]
    procedure ShowItemAvailByUOM(var Item: Record Item; FieldCaption: Text[80]; OldUoMCode: Code[10]; var NewUoMCode: Code[10]): Boolean
    begin
        exit(ShowItemAvailabilityByUOM(Item, FieldCaption, OldUoMCode, NewUoMCode));
    end;
#endif

    procedure ShowItemAvailabilityByUOM(var Item: Record Item; FieldCaption: Text; OldUoMCode: Code[10]; var NewUoMCode: Code[10]): Boolean
    var
        ItemAvailByUOM: Page "Item Availability by UOM";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByUOM(Item, FieldCaption, OldUoMCode, NewUoMCode, Result, IsHandled);
#if not CLEAN25
        OnBeforeShowItemAvailByUOM(Item, FieldCaption, OldUoMCode, NewUoMCode, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        Item.SetRange("Base Unit of Measure");
        if FieldCaption <> '' then
            ItemAvailByUOM.LookupMode(true);
        ItemAvailByUOM.SetRecord(Item);
        ItemAvailByUOM.SetTableView(Item);
        if ItemAvailByUOM.RunModal() = ACTION::LookupOK then begin
            NewUoMCode := ItemAvailByUOM.GetLastUOM();
            if OldUoMCode <> NewUoMCode then
                if Confirm(Text012, true, FieldCaption, OldUoMCode, NewUoMCode) then
                    exit(true);
        end;
    end;

    local procedure ShowBOMLevelAbleToMake(FieldCaption: Text; OldDate: Date; var NewDate: Date): Boolean
    begin
        OnBeforeShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate);

        if FieldCaption <> '' then
            ItemAvailByBOMLevel.LookupMode(true);
        if ItemAvailByBOMLevel.RunModal() = ACTION::LookupOK then begin
            NewDate := ItemAvailByBOMLevel.GetSelectedDate();
            if OldDate <> NewDate then
                if Confirm(Text012, true, FieldCaption, OldDate, NewDate) then
                    exit(true);
        end;
    end;

    procedure SetQtyByUnitOfMeasure(NewQtyByUnitOfMeasure: Decimal);
    begin
        QtyByUnitOfMeasure := NewQtyByUnitOfMeasure;
    end;

    procedure SetForecastName(NewForecastName: Code[10])
    begin
        ForecastName := NewForecastName;
    end;

    procedure FilterItem(var Item: Record Item; LocationCode: Code[20]; VariantCode: Code[20]; Date: Date)
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Date Filter", 0D, Date);
        Item.SetRange("Variant Filter", VariantCode);
        Item.SetRange("Location Filter", LocationCode);

        OnAfterFilterItem(Item, LocationCode, VariantCode, Date);
    end;

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByEvent(): Integer
    begin
        exit("Item Availability Type"::"Event".AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByLocation(): Integer
    begin
        exit("Item Availability Type"::Location.AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByVariant(): Integer
    begin
        exit("Item Availability Type"::Variant.AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByPeriod(): Integer
    begin
        exit("Item Availability Type"::Period.AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByBOM(): Integer
    begin
        exit("Item Availability Type"::BOM.AsInteger());
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by enum "Item Availability Type"', '25.0')]
    procedure ByUOM(): Integer
    begin
        exit("Item Availability Type"::UOM.AsInteger());
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateProjAvailableBalance(var Item: Record Item; var ProjAvailableBalance: Decimal)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByBOMLevel', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByBOMLevel(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByBOMLevel(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByPeriod', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByDate(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByPeriod(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByEvent', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByEvent(var Item: Record Item; FieldCaption: Text[80]; OldDate: Date; var NewDate: Date; var IncludeForecast: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByEvent(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var IncludeForecast: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByLocation', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByLoc(var Item: Record Item; FieldCaption: Text[80]; OldLocationCode: Code[20]; var NewLocationCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByLocation(var Item: Record Item; FieldCaption: Text; OldLocationCode: Code[10]; var NewLocationCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByUOM', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailByUOM(var Item: Record Item; FieldCaption: Text[80]; OldUoMCode: Code[20]; var NewUoMCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByUOM(var Item: Record Item; FieldCaption: Text; OldUoMCode: Code[10]; var NewUoMCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromItem(var Item: Record Item)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityFromItemJnlLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromItemJnlLine(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityFromItemJnlLine(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromSalesLine(var Item: Record Item; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var IsHandled: Boolean; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromSalesLine(Item, SalesLine, IsHandled, AvailabilityType.AsInteger());
    end;

    [Obsolete('Replaced by same event in codeunit Sales Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromSalesLine(var Item: Record Item; var SalesLine: Record Microsoft.Sales.Document."Sales Line"; var IsHandled: Boolean; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromPurchLine(var Item: Record Item; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromPurchLine(Item, PurchLine, IsHandled, AvailabilityType.AsInteger());
    end;

    [Obsolete('Replaced by same event in codeunit Purch. Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPurchLine(var Item: Record Item; var PurchLine: Record Microsoft.Purchases.Document."Purchase Line"; var IsHandled: Boolean; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromServLine(var Item: Record Item; var ServLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnBeforeShowItemAvailFromServLine(Item, ServLine);
    end;

    [Obsolete('Replaced by same event in codeunit Serv. Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromServLine(var Item: Record Item; var ServLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromReqLine(var Item: Record Item; var ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line"; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromReqLine(Item, ReqLine, AvailabilityType.AsInteger());
    end;

    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityFromReqLine', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromReqLine(var Item: Record Item; var ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromProdOrderLine(var Item: Record Item; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnBeforeShowItemAvailFromProdOrderLine(Item, ProdOrderLine);
    end;

    [Obsolete('Replaced by same event in codeunit Prod. Order Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderLine(var Item: Record Item; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromProdOrderComp(var Item: Record Item; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnBeforeShowItemAvailFromProdOrderComp(Item, ProdOrderComp);
    end;

    [Obsolete('Replaced by same event in codeunit Prod. Order Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromProdOrderComp(var Item: Record Item; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromTransLine(var Item: Record Item; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromTransLine(Item, TransLine, AvailabilityType.AsInteger());
    end;

    [Obsolete('Replaced by same event in codeunit Transfer Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromTransLine(var Item: Record Item; var TransLine: Record Microsoft.Inventory.Transfer."Transfer Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromWhseActivLine(var Item: Record Item; var WhseActivLine: Record Microsoft.Warehouse.Activity."Warehouse Activity Line"; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromWhseActivLine(Item, WhseActivLine, AvailabilityType.AsInteger());

    end;

    [Obsolete('Replaced by same event in codeunit Warehouse Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromWhseActivLine(var Item: Record Item; var WhseActivLine: Record Microsoft.Warehouse.Activity."Warehouse Activity Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromWhseRcptLine(var Item: Record Item; var WhseRcptLine: Record Microsoft.Warehouse.Document."Warehouse Receipt Line"; AvailabilityType: Enum "Item Availability Type")
    begin
        OnBeforeShowItemAvailFromWhseRcptLine(Item, WhseRcptLine, AvailabilityType.AsInteger());

    end;

    [Obsolete('Replaced by same event in codeunit Warehouse Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromWhseRcptLine(var Item: Record Item; var WhseRcptLine: Record Microsoft.Warehouse.Document."Warehouse Receipt Line"; AvailabilityType: Option Date,Variant,Location,Bin,"Event",BOM,UOM)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromAsmHeader(var Item: Record Item; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnBeforeShowItemAvailFromAsmHeader(Item, AssemblyHeader);
    end;

    [Obsolete('Replaced by same event in codeunit Assembly Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmHeader(var Item: Record Item; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromAsmLine(var Item: Record Item; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnBeforeShowItemAvailFromAsmLine(Item, AssemblyLine);
    end;

    [Obsolete('Replaced by same event in codeunit Assembly Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromAsmLine(var Item: Record Item; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeShowItemAvailFromPlanningComp(var Item: Record Item; var PlanningComp: Record Microsoft.Inventory.Planning."Planning Component")
    begin
        OnBeforeShowItemAvailFromPlanningComp(Item, PlanningComp);
    end;

    [Obsolete('Replaced by same event in codeunit Assembly Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromPlanningComp(var Item: Record Item; var PlanningComp: Record Microsoft.Inventory.Planning."Planning Component")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeShowItemAvailabilityByVariant', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailVariant(var Item: Record Item; FieldCaption: Text[80]; OldVariant: Code[20]; var NewVariant: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByVariant(var Item: Record Item; FieldCaption: Text; OldVariant: Code[10]; var NewVariant: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateNeedOnAfterCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateNeedOnAfterCalcScheduledReceipt(var Item: Record Item; var ScheduledReceipt: Decimal; QtyinTransit: Decimal; TransOrdReceiptQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterItem(var Item: Record Item; LocationCode: Code[20]; VariantCode: Code[20]; Date: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateNeed(var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderReceipt: Decimal; var ScheduledReceipt: Decimal; var PlannedOrderReleases: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemAvailLineListOnAfterItemAvailabilityLineListInit(var Item: Record Item; var ItemAvailabilityLineList: Page "Item Availability Line List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemAvailabilityFromInvtDocLineOnAvailabilityTypeCaseElse(ItemAvailabilityType: Enum "Item Availability Type"; var Item: Record Item; var InvtDocumentLine: Record "Invt. Document Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowBOMLevelAbleToMake(FieldCaption: Text; OldDate: Date; var NewDate: Date)
    begin
    end;
}

