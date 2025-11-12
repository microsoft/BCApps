// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;

page 917 "Component - Item FactBox"
{
    Caption = 'Component - Item';
    PageType = CardPart;
    SourceTable = "Assembly Line";

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
                    AssemblyInfoPaneManagement.LookupItem(Rec);
                end;
            }
            field("Required Quantity"; ShowRequiredQty())
            {
                ApplicationArea = Assembly;
                BlankZero = true;
                Caption = 'Required Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the component are required for a particular service item.';
            }
            group(Availability)
            {
                Caption = 'Availability';
                field("Due Date"; ShowDueDate())
                {
                    ApplicationArea = Assembly;
                    Caption = 'Due Date';
                    ToolTip = 'Specifies the due date for the relevant item number.';
                }
                field("Item Availability"; AssemblyInfoPaneManagement.CalcAvailability(Rec))
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Item Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are available.';

                    trigger OnDrillDown()
                    begin
                        AssemblyAvailabilityMgt.ShowItemAvailabilityFromAsmLine(Rec, "Item Availability Type"::"Event");
                        Clear(AssemblyAvailabilityMgt);
                    end;
                }
                field("Available Inventory"; AssemblyInfoPaneManagement.CalcAvailableInventory(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field("Scheduled Receipt"; AssemblyInfoPaneManagement.CalcScheduledReceipt(Rec))
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the component are inbound on orders.';
                }
                field("Reserved Receipt"; AssemblyInfoPaneManagement.CalcReservedReceipt(Rec))
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    Caption = 'Reserved Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies reservation quantities of component items.';
                }
                field("Gross Requirement"; AssemblyInfoPaneManagement.CalcGrossRequirement(Rec))
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s total demand.';
                }
                field("Reserved Requirement"; AssemblyInfoPaneManagement.CalcReservedRequirement(Rec))
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
                    ApplicationArea = Assembly;
                    Caption = 'Base Unit of Measure';
                    ToolTip = 'Specifies the base unit of measurement of the component.';
                }
                field("Unit of Measure Code"; ShowUoM())
                {
                    ApplicationArea = Assembly;
                    Caption = 'Unit of Measure Code';
                    ToolTip = 'Specifies the unit of measure that the item is shown in.';
                }
                field("Qty. per Unit of Measure"; ShowQtyPerUoM())
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Qty. per Unit of Measure';
                    ToolTip = 'Specifies the quantity per unit of measure of the component item.';
                }
                field("Unit Price"; Item."Unit Price")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Unit Price';
                    ToolTip = 'Specifies the item''s unit price.';
                }
                field("Unit Cost"; Item."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Unit Cost';
                    ToolTip = 'Specifies the unit cost for the component item.';
                }
                field("Standard Cost"; Item."Standard Cost")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'Standard Cost';
                    ToolTip = 'Specifies the standard cost for the component item.';
                }
                field("No. of Substitutes"; Item."No. of Substitutes")
                {
                    ApplicationArea = Assembly;
                    BlankZero = true;
                    Caption = 'No. of Substitutes';
                    ToolTip = 'Specifies the number of substitutions that have been registered for the item.';
                }
                field("Replenishment System"; ShowReplenishmentSystem())
                {
                    ApplicationArea = Assembly;
                    Caption = 'Replenishment System';
                    ToolTip = 'Specifies the type of supply order that is created by the planning system when the item needs to be replenished.';
                }
                field("Vendor No."; ShowVendorNo())
                {
                    ApplicationArea = Assembly;
                    Caption = 'Vendor No.';
                    ToolTip = 'Specifies the number of the vendor for the item.';
                }
                field("Reserved from Stock"; AssemblyInfoPaneManagement.GetQtyReservedFromStockState(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved from stock';
                    Tooltip = 'Specifies what part of the quantity is reserved from inventory.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(Item);
        AssemblyInfoPaneManagement.SetRecalculateItem();
        if (Rec.Type = Rec.Type::Item) and Item.Get(Rec."No.") then
            Item.CalcFields("No. of Substitutes");
    end;

    var
        AssemblyAvailabilityMgt: Codeunit "Assembly Availability Mgt.";
        AssemblyInfoPaneManagement: Codeunit "Assembly Info-Pane Management";

    protected var
        Item: Record Item;

    local procedure ShowNo(): Code[20]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Item."No.");
    end;

    local procedure ShowBaseUoM(): Code[10]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Item."Base Unit of Measure");
    end;

    local procedure ShowUoM(): Code[10]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Rec."Unit of Measure Code");
    end;

    local procedure ShowQtyPerUoM(): Decimal
    begin
        if Rec.Type <> Rec.Type::Item then
            exit(0);
        exit(Rec."Qty. per Unit of Measure");
    end;

    local procedure ShowReplenishmentSystem(): Text[50]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Format(Item."Replenishment System"));
    end;

    local procedure ShowVendorNo(): Code[20]
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Item."Vendor No.");
    end;

    local procedure ShowRequiredQty(): Decimal
    begin
        if Rec.Type <> Rec.Type::Item then
            exit(0);
        Rec.CalcFields("Reserved Quantity");
        exit(Rec.Quantity - Rec."Reserved Quantity");
    end;

    local procedure ShowDueDate(): Text
    begin
        if Rec.Type <> Rec.Type::Item then
            exit('');
        exit(Format(Rec."Due Date"));
    end;
}

