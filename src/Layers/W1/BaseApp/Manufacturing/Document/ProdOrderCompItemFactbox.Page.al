// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

page 874 "Prod. Order Comp. Item FactBox"
{
    Caption = 'Component - Item';
    PageType = CardPart;
    SourceTable = "Prod. Order Component";

    layout
    {
        area(content)
        {
            field("Item No."; ShowNo())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the component item.';

                trigger OnDrillDown()
                begin
                    Rec.TestField("Item No.");
                    Item.Get(Rec."Item No.");
                    PAGE.RunModal(PAGE::"Item Card", Item);
                    SetRecalculateItem();
                    GetItem();
                end;
            }
            field("Required Quantity"; ShowRequiredQty())
            {
                ApplicationArea = Manufacturing;
                BlankZero = true;
                Caption = 'Required Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the component are required.';
            }
            group(Availability)
            {
                Caption = 'Availability';
                field("Due Date"; ShowDueDate())
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date for the relevant item number.';
                }
                field("Item Availability"; CalcAvailability(Rec))
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Item Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are available.';

                    trigger OnDrillDown()
                    var
                        ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
                    begin
                        ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::"Event");
                        SetRecalculateItem();
                        GetItem();
                    end;
                }
                field("Available Inventory"; CalcAvailableInventory())
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field("Scheduled Receipt"; CalcScheduledReceipt())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the component are inbound on orders.';
                }
                field("Reserved Receipt"; CalcReservedReceipt())
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Reserved Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies reservation quantities of component items.';
                }
                field("Gross Requirement"; CalcGrossRequirement())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s total demand.';
                }
                field("Reserved Requirement"; CalcReservedRequirement())
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Reserved Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies reservation quantities of component items.';
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field("Base Unit of Measure"; ShowBaseUoM())
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Base Unit of Measure';
                    ToolTip = 'Specifies the base unit of measurement of the component.';
                }
                field("Unit of Measure Code"; ShowUoM())
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Unit of Measure Code';
                    ToolTip = 'Specifies the unit of measure that the item is shown in.';
                }
                field("Qty. per Unit of Measure"; ShowQtyPerUoM())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Qty. per Unit of Measure';
                    ToolTip = 'Specifies the quantity per unit of measure of the component item.';
                }
                field("Unit Price"; ShowUnitPrice())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Unit Price';
                    ToolTip = 'Specifies the item''s unit price.';
                }
                field("Unit Cost"; ShowUnitCost())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Unit Cost';
                    ToolTip = 'Specifies the unit cost for the component item.';
                }
                field("Standard Cost"; ShowStandardCost())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'Standard Cost';
                    ToolTip = 'Specifies the standard cost for the component item.';
                }
                field("No. of Substitutes"; ShowNoOfSubstitutes())
                {
                    ApplicationArea = Manufacturing;
                    BlankZero = true;
                    Caption = 'No. of Substitutes';
                    ToolTip = 'Specifies the number of substitutions that have been registered for the item.';
                }
                field("Replenishment System"; ShowReplenishmentSystem())
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Replenishment System';
                    ToolTip = 'Specifies the type of supply order that is created by the planning system when the item needs to be replenished.';
                }
                field("Vendor No."; ShowVendorNo())
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Vendor No.';
                    ToolTip = 'Specifies the number of the vendor for the item.';
                }
                field("Reserved from Stock"; GetQtyReservedFromStockState())
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved from stock';
                    Tooltip = 'Specifies what part of the quantity is reserved from inventory.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetRecalculateItem();
        if (Rec."Item No." <> '') then begin
            Item.SetAutoCalcFields("No. of Substitutes");
            if Item.Get(Rec."Item No.") then;
        end;
    end;

    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";

    local procedure GetItem(): Boolean
    begin
        Item.Reset();
        if Rec."Item No." <> '' then
            exit(Item.Get(Rec."Item No."));
        exit(false);
    end;

    #region show procedures
    local procedure ShowNo(): Code[20]
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Item."No.");
    end;

    local procedure ShowBaseUoM(): Code[10]
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Item."Base Unit of Measure");
    end;

    local procedure ShowUoM(): Code[10]
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Rec."Unit of Measure Code");
    end;

    local procedure ShowQtyPerUoM(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        exit(Rec."Qty. per Unit of Measure");
    end;

    local procedure ShowReplenishmentSystem(): Text[50]
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Format(Item."Replenishment System"));
    end;

    local procedure ShowVendorNo(): Code[20]
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Item."Vendor No.");
    end;

    local procedure ShowRequiredQty(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        Rec.CalcFields("Reserved Quantity");
        exit(Rec."Expected Quantity" - Rec."Reserved Quantity");
    end;

    local procedure ShowDueDate(): Text
    begin
        if Rec."Item No." = '' then
            exit('');
        exit(Format(Rec."Due Date"));
    end;

    local procedure ShowUnitPrice(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        exit(Item."Unit Price");
    end;

    local procedure ShowUnitCost(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        exit(Item."Unit Cost");
    end;

    local procedure ShowStandardCost(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        exit(Item."Standard Cost");
    end;

    local procedure ShowNoOfSubstitutes(): Decimal
    begin
        if Rec."Item No." = '' then
            exit(0);
        exit(Item."No. of Substitutes");
    end;
    #endregion

    #region calc procedures
    local procedure CalcAvailability(var ProdOrderComponent: Record "Prod. Order Component"): Decimal
    var
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Enum "Analysis Period Type";
    begin
        if GetItem() then begin

            SetItemFilter();
            Evaluate(LookaheadDateformula, '<0D>');

            exit(
              AvailableToPromise.CalcQtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                CalcAvailabilityDate(ProdOrderComponent),
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    local procedure SetItemFilter()
    begin
        Item.Reset();
        Item.SetRange("Date Filter", 0D, CalcAvailabilityDate(Rec));
        Item.SetRange("Variant Filter", Rec."Variant Code");
        Item.SetRange("Location Filter", Rec."Location Code");
    end;

    local procedure CalcAvailabilityDate(ProdOrderComponent: Record "Prod. Order Component"): Date
    begin
        if ProdOrderComponent."Due Date" <> 0D then
            exit(ProdOrderComponent."Due Date");

        exit(WorkDate());
    end;

    local procedure CalcAvailableInventory(): Decimal
    begin
        if Rec."Item No." <> '' then begin
            SetItemFilter();
            exit(AvailableToPromise.CalcAvailableInventory(Item));
        end;
    end;

    local procedure CalcScheduledReceipt(): Decimal
    begin
        if Rec."Item No." <> '' then begin
            SetItemFilter();
            exit(AvailableToPromise.CalcScheduledReceipt(Item));
        end;
    end;

    local procedure CalcGrossRequirement(): Decimal
    begin
        if Rec."Item No." <> '' then begin
            SetItemFilter();
            exit(AvailableToPromise.CalcGrossRequirement(Item));
        end;
    end;

    local procedure CalcReservedReceipt(): Decimal
    begin
        if Rec."Item No." <> '' then begin
            SetItemFilter();
            exit(AvailableToPromise.CalcReservedReceipt(Item));
        end;
    end;

    local procedure CalcReservedRequirement(): Decimal
    begin
        if Rec."Item No." <> '' then begin
            SetItemFilter();
            exit(AvailableToPromise.CalcReservedRequirement(Item));
        end;
    end;

    local procedure GetQtyReservedFromStockState() Result: Enum "Reservation From Stock"
    var
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        if not GetItem() then
            exit(Result::None);

        if Item.IsNonInventoriableType() then
            exit(Result::None);

        QtyReservedFromStock := ProdOrderCompReserve.GetReservedQtyFromInventory(Rec);
        case QtyReservedFromStock of
            0:
                exit(Result::None);
            Rec."Remaining Qty. (Base)":
                exit(Result::Full);
            else
                exit(Result::Partial);
        end;
    end;

    local procedure SetRecalculateItem()
    begin
        Clear(Item);
        AvailableToPromise.SetRecalculateFields();
    end;
    #endregion
}

