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


    procedure ShowItemAvailabilityByBOMLevel(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        // Do not make global
        // Request to make function global has been rejected as it is a skeleton function of the codeunit
        IsHandled := false;
        OnBeforeShowItemAvailabilityByBOMLevel(Item, FieldCaption, OldDate, NewDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Clear(ItemAvailByBOMLevel);
        Item.SetRange("Date Filter");
        ItemAvailByBOMLevel.InitItem(Item);
        ItemAvailByBOMLevel.InitDate(OldDate);
        exit(ShowBOMLevelAbleToMake(FieldCaption, OldDate, NewDate));
    end;


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


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByBOMLevel(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByPeriod(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByEvent(var Item: Record Item; FieldCaption: Text; OldDate: Date; var NewDate: Date; var IncludeForecast: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByLocation(var Item: Record Item; FieldCaption: Text; OldLocationCode: Code[10]; var NewLocationCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityByUOM(var Item: Record Item; FieldCaption: Text; OldUoMCode: Code[10]; var NewUoMCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailFromItem(var Item: Record Item)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityFromItemJnlLine(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line"; AvailabilityType: Enum "Item Availability Type")
    begin
    end;














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
