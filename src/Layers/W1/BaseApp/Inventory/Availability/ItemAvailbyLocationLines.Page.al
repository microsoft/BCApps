// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 515 "Item Avail. by Location Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = Location;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(LocationCode; LocationCode)
                {
                    ApplicationArea = Location;
                    Caption = 'Code';
                    ToolTip = 'Specifies a location code for the warehouse or distribution center where your items are handled and stored before being sold.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name or address of the location.';
                }
                field(GrossRequirement; GrossRequirement)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the total demand for the item. The gross requirement consists of independent demand (which include sales orders, service orders, transfer orders, and demand forecasts) and dependent demand, which include production order components for planned, firm planned, and released production orders and requisition and planning worksheets lines.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(0);
                    end;
                }
                field(ScheduledRcpt; ScheduledRcpt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of items from replenishment orders. This includes firm planned and released production orders, purchase orders, and transfer orders.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(2);
                    end;
                }
                field(PlannedOrderRcpt; PlannedOrderRcpt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Planned Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity on planned production orders plus planning worksheet lines plus requisition worksheet lines.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(1);
                    end;
                }
                field("Item.Inventory"; Item.Inventory)
                {
                    ApplicationArea = Location;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies the inventory level of an item.';

                    trigger OnDrillDown()
                    begin
                        SetItemFilter();
                        ItemAvailFormsMgt.ShowItemLedgerEntries(Item, false);
                    end;
                }
                field(ProjAvailableBalance; ProjAvailableBalance)
                {
                    ApplicationArea = Location;
                    Caption = 'Projected Available Balance';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the item''s availability. This quantity includes all known supply and demand but does not include anticipated demand from demand forecasts or blanket sales orders or suggested supplies from planning or requisition worksheets.';

                    trigger OnDrillDown()
                    begin
                        ShowItemAvailLineList(4);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Purch. Order"""; Item."Qty. on Purch. Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Purch. Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item are inbound on purchase orders, meaning listed on outstanding purchase order lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        PurchAvailabilityMgt: Codeunit "Purch. Availability Mgt.";
                    begin
                        SetItemFilter();
                        PurchAvailabilityMgt.ShowPurchLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Sales Order"""; Item."Qty. on Sales Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Sales Order';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how many units of the item are allocated to sales orders, meaning listed on outstanding sales orders lines.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
                    begin
                        SetItemFilter();
                        SalesAvailabilityMgt.ShowSalesLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Job Order"""; Item."Qty. on Job Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Caption = 'Qty. on Project Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to projects, meaning listed on outstanding project planning lines. The field is automatically updated based on the Remaining Qty. field in the Project Planning Lines window.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
                    begin
                        SetItemFilter();
                        JobPlanningAvailabilityMgt.ShowJobPlanningLines(Item);
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Trans. Ord. Shipment (Qty.)"""; Item."Trans. Ord. Shipment (Qty.)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trans. Ord. Shipment (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        SetItemFilter();
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Shipment (Qty.)"));
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Qty. on Asm. Component"""; Item."Qty. on Asm. Component")
#pragma warning restore AA0100
                {
                    ApplicationArea = Assembly;
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
                    ApplicationArea = Assembly;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. in Transit';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that are currently in transit.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        SetItemFilter();
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Qty. in Transit"));
                    end;
                }
#pragma warning disable AA0100
                field("Item.""Trans. Ord. Receipt (Qty.)"""; Item."Trans. Ord. Receipt (Qty.)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Trans. Ord. Receipt (Qty.)';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the items that remain to be received but are not yet shipped. The program calculates this quantity as the difference between the Quantity and the Quantity Shipped fields. It automatically updates the field each time you either update the Quantity or Quantity Shipped field.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
                    begin
                        SetItemFilter();
                        TransferAvailabilityMgt.ShowTransLines(Item, Item.FieldNo("Trans. Ord. Receipt (Qty.)"));
                    end;
                }
                field(ExpectedInventory; ExpectedInventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expected Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are expected to be available for the current assembly order on the due date.';
                    Visible = false;
                }
                field(QtyAvailable; QtyAvailable)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                    Visible = false;
                }
                field(PlannedOrderReleases; PlannedOrderReleases)
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Change';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies the net change in the inventory of the item during the period entered in the Date Filter field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        SetItemFilter();
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

    trigger OnInit()
    begin
        PeriodStart := 0D;
        PeriodEnd := DMY2Date(31, 12, 1999);

        Rec.GetLocationsIncludingUnspecifiedLocation(false, false);
    end;

    protected var
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        AmountType: Enum "Analysis Amount Type";
        ExpectedInventory: Decimal;
        QtyAvailable: Decimal;
        PlannedOrderReleases: Decimal;
        GrossRequirement: Decimal;
        PlannedOrderRcpt: Decimal;
        ScheduledRcpt: Decimal;
        ProjAvailableBalance: Decimal;
        PeriodStart: Date;
        PeriodEnd: Date;
        LocationCode: Code[10];

    procedure SetLines(var NewItem: Record Item; NewAmountType: Enum "Analysis Amount Type")
    begin
        OnBeforeSet(Rec, NewItem, NewAmountType.AsInteger());
        Item.Copy(NewItem);
        PeriodStart := Item.GetRangeMin("Date Filter");
        PeriodEnd := Item.GetRangeMax("Date Filter");
        AmountType := NewAmountType;
        CurrPage.Update(false);

        OnAfterSetLines(Item, AmountType);
    end;

    procedure GetItem(var ItemOut: Record Item)
    begin
        ItemOut.Copy(Item);
    end;

    protected procedure SetItemFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            Item.SetRange("Date Filter", PeriodStart, PeriodEnd)
        else
            Item.SetRange("Date Filter", 0D, PeriodEnd);
        LocationCode := Rec.Code;
        Item.SetRange("Location Filter", Rec.Code);

        OnAfterSetItemFilter(Item, PeriodStart, PeriodEnd);
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
        OnAfterCalcAvailQuantities(Rec, Item, GrossRequirement, PlannedOrderRcpt, ScheduledRcpt,
          PlannedOrderReleases, ProjAvailableBalance, ExpectedInventory, DummyQtyAvailable, AvailableInventory);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailQuantities(var Location: Record Location; var Item: Record Item; var GrossRequirement: Decimal; var PlannedOrderRcpt: Decimal; var ScheduledRcpt: Decimal; var PlannedOrderReleases: Decimal; var ProjAvailableBalance: Decimal; var ExpectedInventory: Decimal; var QtyAvailable: Decimal; var AvailableInventory: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLines(var Item: Record Item; AmountType: Enum "Analysis Amount Type");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilter(var Item: Record Item; var PeriodStart: Date; var PeriodEnd: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSet(var Location: Record Location; var Item: Record Item; NewAmountType: Option "Net Change","Balance at Date");
    begin
    end;
}

