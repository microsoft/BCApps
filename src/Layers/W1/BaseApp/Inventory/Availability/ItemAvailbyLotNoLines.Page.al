// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

page 514 "Item Avail. by Lot No. Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Availability Info. Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;

                field(LotNo; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Code';
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(ExpirationDate; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Expiration Date';
                    ToolTip = 'Specifies expiration date for the specified lot.';
                }
                field(Quality; Rec.Quality)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Quality';
                    ToolTip = 'Specifies the test quality of the specified lot.';
                    Visible = false;
                }
                field(CertificateNumber; Rec."Certificate Number")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Certificate Number';
                    ToolTip = 'Specifies the certificate number of the specified lot.';
                    Visible = false;
                }

                field(Inventory; Rec."Qty. In Hand")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the inventory level of an item.';

                    trigger OnDrillDown()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                        IsHandled: Boolean;
                    begin
                        OnBeforeLookupInventory(IsHandled, Rec);
                        if IsHandled then
                            exit;

                        Rec.LookupInventory(ItemLedgerEntry);
                        if ItemLedgerEntry.FindSet() then
                            Page.RunModal(0, ItemLedgerEntry);
                    end;
                }
                field(GrossRequirement; Rec."Gross Requirement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the total demand for the item. The gross requirement consists of independent demand (which include sales orders, service orders, transfer orders, and demand forecasts) and dependent demand (which include production order components for planned, firm planned, and released production orders and requisition and planning worksheets lines).';

                    trigger OnDrillDown()
                    var
                        TempReservationEntry: Record "Reservation Entry" temporary;
                        IsHandled: Boolean;
                    begin
                        OnBeforeLookupGrossRequirement(IsHandled, Rec);
                        if IsHandled then
                            exit;

                        Rec.LookupGrossRequirement(TempReservationEntry);
                        if TempReservationEntry.FindSet() then
                            Page.RunModal(0, TempReservationEntry);
                    end;
                }
                field(ScheduledRcpt; Rec."Scheduled Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment orders.';

                    trigger OnDrillDown()
                    var
                        TempReservationEntry: Record "Reservation Entry" temporary;
                        IsHandled: Boolean;
                    begin
                        OnBeforeLookupScheduledReceipt(IsHandled, Rec);
                        if IsHandled then
                            exit;

                        Rec.LookupScheduledReceipt(TempReservationEntry);
                        if TempReservationEntry.FindSet() then
                            Page.RunModal(0, TempReservationEntry);
                    end;
                }
                field(PlannedOrderRcpt; Rec."Planned Order Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Order Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s availability figures for the planned order receipt.';

                    trigger OnDrillDown()
                    var
                        TempReservationEntry: Record "Reservation Entry" temporary;
                        IsHandled: Boolean;
                    begin
                        OnBeforeLookupPlannedOrderReceipt(IsHandled, Rec);
                        if IsHandled then
                            exit;

                        Rec.LookupPlannedOrderReceipt(TempReservationEntry);
                        if TempReservationEntry.FindSet() then
                            Page.RunModal(0, TempReservationEntry);
                    end;
                }
                field(QtyAvailable; Rec."Available Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Calculate();
    end;

    var
        Item: Record Item;
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;

    procedure SetItem(var NewItem: Record Item; NewAmountType: Enum "Analysis Amount Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetItem(Rec, NewItem, NewAmountType, IsHandled);
        if not IsHandled then begin

            Item.Copy(NewItem);
            GenerateLines();
            if Item.GetFilter("Location Filter") <> '' then
                Rec.SetRange("Location Code Filter", Item.GetFilter("Location Filter"));

            if Item.GetFilter("Variant Filter") <> '' then
                Rec.SetRange("Variant Code Filter", Item.GetFilter("Variant Filter"));

            if NewAmountType = NewAmountType::"Net Change" then
                Rec.SetRange("Date Filter", Item.GetRangeMin("Date Filter"), Item.GetRangeMax("Date Filter"))
            else
                Rec.SetRange("Date Filter", 0D, Item.GetRangeMax("Date Filter"));
        end;
        OnAfterSetItem(Item, NewAmountType);
        CurrPage.Update(false);
    end;

    procedure GetItem(var ItemOut: Record Item)
    begin
        ItemOut.Copy(Item);
    end;

    local procedure GenerateLines()
    begin
        BuildLotNoList(Rec, Item."No.");
    end;

    local procedure Calculate()
    var
        IsHandled: Boolean;
    begin
        Rec.SetRange("Lot No. Filter", Rec."Lot No.");
        OnBeforeCalcAvailQuantities(Rec, Item, IsHandled);

        if not IsHandled then
            Rec.CalcFields(
                Inventory,
                "Qty. on Sales Order",
                "Qty. on Service Order",
                "Qty. on Job Order",
                "Qty. on Component Lines",
                "Qty. on Trans. Order Shipment",
                "Qty. on Asm. Component",
                "Qty. on Purch. Return",
                "Planned Order Receipt (Qty.)",
                "Purch. Req. Receipt (Qty.)",
                "Qty. on Purch. Order",
                "Qty. on Prod. Receipt",
                "Qty. on Trans. Order Receipt",
                "Qty. on Assembly Order",
                "Qty. on Sales Return"
            );

        /*GrossRequirement :=
            "Qty. on Sales Order" + "Qty. on Service Order" + "Qty. on Job Order" + "Qty. on Component Lines" +
            TransOrdShipmentQty + "Planning Issues (Qty.)" + "Qty. on Asm. Component" + "Qty. on Purch. Return";*/
        GrossRequirement :=
            Rec."Qty. on Sales Order" +
            Rec."Qty. on Service Order" +
            Rec."Qty. on Job Order" +
            Rec."Qty. on Component Lines" +
            Rec."Qty. on Trans. Order Shipment" +
            Rec."Qty. on Asm. Component" +
            Rec."Qty. on Purch. Return";

        /*PlannedOrderReceipt := "Planned Order Receipt (Qty.)" + "Purch. Req. Receipt (Qty.)";*/
        PlannedOrderRcpt :=
            Rec."Planned Order Receipt (Qty.)" +
            Rec."Purch. Req. Receipt (Qty.)";

        /*ScheduledReceipt :=
            "FP Order Receipt (Qty.)" + "Rel. Order Receipt (Qty.)" + "Qty. on Purch. Order" +
            QtyinTransit + TransOrdReceiptQty + "Qty. on Assembly Order" + "Qty. on Sales Return";*/
        ScheduledRcpt :=
            Rec."Qty. on Prod. Receipt" +
            Rec."Qty. on Purch. Order" +
            Rec."Qty. on Trans. Order Receipt" +
            Rec."Qty. on Assembly Order" +
            Rec."Qty. on Sales Return";

        Rec."Qty. In Hand" := Rec.Inventory;
        Rec."Gross Requirement" := GrossRequirement;
        Rec."Planned Order Receipt" := PlannedOrderRcpt;
        Rec."Scheduled Receipt" := ScheduledRcpt;
        Rec."Available Inventory" := Rec.Inventory + PlannedOrderRcpt + ScheduledRcpt - GrossRequirement;

        OnAfterCalcAvailQuantities(Rec, Item);
    end;

    local procedure BuildLotNoList(var AvailabilityInfoBuffer: Record "Availability Info. Buffer"; ItemNo: Code[20])
    var
        ItemByLotNoRes: Query "Item By Lot No. Res.";
        ItemByLotNoItemLedg: Query "Item By Lot No. Item Ledg.";
        LotDictionary: Dictionary of [Code[50], Text];
    begin
        Clear(AvailabilityInfoBuffer);
        AvailabilityInfoBuffer.DeleteAll();

        ItemByLotNoItemLedg.SetRange(Item_No, ItemNo);
        ItemByLotNoItemLedg.SetFilter(Variant_Code, Item.GetFilter("Variant Filter"));
        ItemByLotNoItemLedg.SetFilter(Location_Code, Item.GetFilter("Location Filter"));
        ItemByLotNoItemLedg.Open();
        while ItemByLotNoItemLedg.Read() do
            if ItemByLotNoItemLedg.Lot_No <> '' then
                if not LotDictionary.ContainsKey(ItemByLotNoItemLedg.Lot_No) then begin
                    LotDictionary.Add(ItemByLotNoItemLedg.Lot_No, '');
                    AvailabilityInfoBuffer.Init();
                    AvailabilityInfoBuffer."Item No." := Item."No.";
                    AvailabilityInfoBuffer."Lot No." := ItemByLotNoItemLedg.Lot_No;
                    AvailabilityInfoBuffer."Expiration Date" := ItemByLotNoItemLedg.Expiration_Date;
                    AvailabilityInfoBuffer.Insert();
                end;

        // Expected Receipt Date for positive reservation entries.
        ItemByLotNoRes.SetRange(Item_No, ItemNo);
        ItemByLotNoRes.SetFilter(Quantity__Base_, '>0');
        ItemByLotNoRes.SetFilter(Expected_Receipt_Date, Item.GetFilter("Date Filter"));
        ItemByLotNoRes.SetFilter(Variant_Code, Item.GetFilter("Variant Filter"));
        ItemByLotNoRes.SetFilter(Location_Code, Item.GetFilter("Location Filter"));
        ItemByLotNoRes.Open();
        AddReservationEntryLotNos(AvailabilityInfoBuffer, ItemByLotNoRes, LotDictionary);

        // Shipment date for negative reservation entries.
        ItemByLotNoRes.SetRange(Item_No, ItemNo);
        ItemByLotNoRes.SetFilter(Quantity__Base_, '<0');
        ItemByLotNoRes.SetFilter(Expected_Receipt_Date, '');
        ItemByLotNoRes.SetFilter(Shipment_Date, Item.GetFilter("Date Filter"));
        ItemByLotNoRes.SetFilter(Variant_Code, Item.GetFilter("Variant Filter"));
        ItemByLotNoRes.SetFilter(Location_Code, Item.GetFilter("Location Filter"));
        AddReservationEntryLotNos(AvailabilityInfoBuffer, ItemByLotNoRes, LotDictionary);
    end;

    local procedure AddReservationEntryLotNos(
        var AvailabilityInfoBuffer: Record "Availability Info. Buffer";
        var ItemByLotNoRes: Query "Item By Lot No. Res.";
        var LotDictionary: Dictionary of [Code[50], Text]
    )
    begin
        ItemByLotNoRes.Open();
        while ItemByLotNoRes.Read() do
            if ItemByLotNoRes.Lot_No <> '' then
                if not LotDictionary.ContainsKey(ItemByLotNoRes.Lot_No) then begin
                    LotDictionary.Add(ItemByLotNoRes.Lot_No, '');
                    AvailabilityInfoBuffer.Init();
                    AvailabilityInfoBuffer."Item No." := Item."No.";
                    AvailabilityInfoBuffer."Lot No." := ItemByLotNoRes.Lot_No;
                    AvailabilityInfoBuffer."Expiration Date" := ItemByLotNoRes.Expiration_Date;
                    AvailabilityInfoBuffer.Insert();
                end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetItem(var Item: Record Item; NewAmountType: Enum "Analysis Amount Type")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcAvailQuantities(var AvailabilityInfoBuffer: Record "Availability Info. Buffer"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcAvailQuantities(var AvailabilityInfoBuffer: Record "Availability Info. Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupInventory(var IsHandled: Boolean; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupGrossRequirement(var IsHandled: Boolean; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupScheduledReceipt(var IsHandled: Boolean; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupPlannedOrderReceipt(var IsHandled: Boolean; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetItem(var AvailabilityInfoBuffer: Record "Availability Info. Buffer"; var Item: Record Item; AmountType: Enum "Analysis Amount Type"; var IsHandled: Boolean)
    begin
    end;
}

