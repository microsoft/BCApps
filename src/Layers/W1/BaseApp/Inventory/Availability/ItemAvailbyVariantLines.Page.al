// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Item;

page 5415 "Item Avail. by Variant Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Item Variant";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code to identify the variant.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the item variant.';
                }
                field(GrossRequirement; GrossRequirement)
                {
                    ApplicationArea = Planning;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the all demand for the item.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(0);
                    end;
                }
                field(ScheduledRcpt; ScheduledRcpt)
                {
                    ApplicationArea = Planning;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment orders.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(2);
                    end;
                }
                field(PlannedOrderRcpt; PlannedOrderRcpt)
                {
                    ApplicationArea = Planning;
                    Caption = 'Planned Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity on planned production orders plus planning worksheet lines plus requisition worksheet lines.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(1);
                    end;
                }
                field(ProjAvailableBalance; ProjAvailableBalance)
                {
                    ApplicationArea = Planning;
                    Caption = 'Projected Available Balance';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(4);
                    end;
                }
                field("Item.Inventory"; Item.Inventory)
                {
                    ApplicationArea = Planning;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the inventory level of an item.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Purch. Order"""; Item."Qty. on Purch. Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. on Purch. Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are inbound on purchase orders, meaning listed on outstanding purchase order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchAvailabilityMgt: Codeunit "Purch. Availability Mgt.";
                    begin
                        PurchAvailabilityMgt.ShowPurchLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Sales Order"""; Item."Qty. on Sales Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. on Sales Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the item are allocated to sales orders, meaning listed on outstanding sales orders lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
                    begin
                        SalesAvailabilityMgt.ShowSalesLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Job Order"""; Item."Qty. on Job Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. on Project Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to projects, meaning listed on outstanding project planning lines. The field is automatically updated based on the Remaining Qty. field in the Project Planning Lines window.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
                    begin
                        JobPlanningAvailabilityMgt.ShowJobPlanningLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Trans. Ord. Shipment (Qty.)"""; Item."Trans. Ord. Shipment (Qty.)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Trans. Ord. Shipment (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Shipment (Qty.)"));
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Asm. Component"""; Item."Qty. on Asm. Component")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. on Asm. Comp. Lines';
                    ToolTip = 'Specifies how many units of the item are allocated to assembly component orders.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
                    begin
                        AssemblyAvailabilityMgt.ShowAsmCompLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Assembly Order"""; Item."Qty. on Assembly Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. on Assembly Order';
                    ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
                    begin
                        AssemblyAvailabilityMgt.ShowAsmOrders(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. in Transit"""; Item."Qty. in Transit")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Qty. in Transit';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that are currently in transit.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Qty. in Transit"));
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Trans. Ord. Receipt (Qty.)"""; Item."Trans. Ord. Receipt (Qty.)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Trans. Ord. Receipt (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remain to be received but are not yet shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Receipt (Qty.)"));
                    end;
                }
                field(ExpectedInventory; ExpectedInventory)
                {
                    ApplicationArea = Planning;
                    Caption = 'Expected Inventory';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be available for the current assembly order on the due date.';
                    Visible = false;
                }
                field(QtyAvailable; QtyAvailable)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Qty. on Hand';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                    Visible = false;
                }
                field(PlannedOrderReleases; PlannedOrderReleases)
                {
                    ApplicationArea = Planning;
                    Caption = 'Planned Order Releases';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment order proposals, which include planned production orders and planning or requisition worksheets lines, that are calculated according to the starting date in the planning worksheet and production order or the order date in the requisition worksheet. This sum is not included in the projected available inventory. However, it indicates which quantities should be converted from planned to scheduled receipts.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(3);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Net Change"""; Item."Net Change")
#pragma warning restore AA0100
                {
                    ApplicationArea = Planning;
                    Caption = 'Net Change';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies the net change in the inventory of the item during the period entered in the Date Filter field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, true);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        CalcAvailQuantities(
          GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, QtyAvailable);
    end;

    trigger OnOpenPage()
    begin
        PeriodStart := 0D;
        PeriodEnd := DMY2Date(31, 12, 1999);
    end;

    protected var
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        AmountType: Enum "Analysis Amount Type";
        PeriodStart: Date;
        PeriodEnd: Date;
        ExpectedInventory: Decimal;
        QtyAvailable: Decimal;
        PlannedOrderReleases: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;
        ProjAvailableBalance: Decimal;

    procedure Set(var NewItem: Record Item; NewAmountType: Enum "Analysis Amount Type")
    begin
        Item.Copy(NewItem);
        PeriodStart := Item.GetRangeMin("Date Filter");
        PeriodEnd := Item.GetRangeMax("Date Filter");
        AmountType := NewAmountType;
        OnAfterSet(Rec, Item, AmountType);
        CurrPage.Update(false);
    end;

    local procedure SetItemFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Item.SetRange("Date Filter", PeriodStart, PeriodEnd)
        else
            Item.SetRange("Date Filter", 0D, PeriodEnd);
        Item.SetRange("Variant Filter", Rec.Code);
    end;

    local procedure ShowItemAvailLineList(What: Integer)
    begin
        SetItemFilter();
        ItemAvailFormsMgt.ShowItemAvailLineList(Item, What);
    end;

    local procedure CalcAvailQuantities(var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal)
    var
        DummyQtyAvailable: Decimal;
    begin
        SetItemFilter();
        ItemAvailFormsMgt.CalcAvailQuantities(
          Item, AmountType = AmountType::"Balance at Date",
          GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, DummyQtyAvailable, AvailableInventory);
        OnAfterCalcQuantities(
          Rec, Item, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, AvailableInventory);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQuantities(ItemVariant: Record "Item Variant"; var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSet(var ItemVariant: record "Item Variant"; var Item: Record Item; AmountType: Enum "Analysis Amount Type")
    begin
    end;
}

