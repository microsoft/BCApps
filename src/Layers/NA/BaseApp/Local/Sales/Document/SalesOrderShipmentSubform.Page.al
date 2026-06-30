// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.Document;

page 10027 "Sales Order Shipment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = filter(Order),
                            "Outstanding Quantity" = filter(<> 0));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the record on the document line. ';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Variant CodeEditable";
                    ToolTip = 'Specifies the variant number of the items sold.';
                    Visible = false;
                }
                field("Substitution Available"; Rec."Substitution Available")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that a substitute is available for the item on the sales line.';
                    Visible = false;
                }
                field("Purchasing Code"; Rec."Purchasing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a purchasing code that indicates actions that need to be taken to purchase this item. ';
                    Visible = false;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the item on the sales line is a catalog item (an item not normally kept in inventory).';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a description of the shipment line.';
                }
                field(Control26; Rec."Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether to ship the items on the line directly to your customer.';
                    Visible = false;
                }
                field(Control106; Rec."Special Order")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the item on the sales line is a special-order item.';
                    Visible = false;
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Package Tracking No.Editable";
                    ToolTip = 'Specifies the shipping agent''s package number.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the location from where inventory items are to be shipped by default, to the customer on the sales document.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bin from where items on the sales order line are taken from when they are shipped.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies the quantity of items on document line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = false;
                    ToolTip = 'Specifies how many of the units in the Quantity field are reserved.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item''s unit of measure. ';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValidate();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item''s unit of measure. ';
                    Visible = false;
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Editable = "Qty. to ShipEditable";
                    ToolTip = 'Specifies how many of the units in the Quantity field to post as shipped. ';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many of the units in the Quantity field have been posted as shipped.';
                }
                field("Allow Item Charge Assignment"; Rec."Allow Item Charge Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = AllowItemChargeAssignmentEdita;
                    ToolTip = 'Specifies that you can assign item charges to this line.';
                    Visible = false;
                }
                field("Qty. to Assign"; Rec."Qty. to Assign")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the units in the Quantity field to assign.';
                    Visible = false;
                }
                field("Qty. Assigned"; Rec."Qty. Assigned")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many of the units in the Quantity field have been assigned.';
                    Visible = false;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the requested delivery date for the sales order shipment.';
                    Visible = false;
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Promised Delivery DateEditable";
                    ToolTip = 'Specifies the promised delivery date for the sales order shipment.';
                    Visible = false;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Planned Delivery DateEditable";
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address.';
                }
                field("Planned Shipment Date"; Rec."Planned Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Planned Shipment DateEditable";
                    ToolTip = 'Specifies the date that the shipment should ship from the warehouse.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipment DateEditable";
                    ToolTip = 'Specifies the date that the items on the line are in inventory and available to be picked. The shipment date is the date you expect to ship the items on the line.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipping Agent CodeEditable";
                    ToolTip = 'Specifies which shipping company will be used when you ship items to the customer.';
                    Visible = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = ShippingAgentServiceCodeEditab;
                    ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                    Visible = false;
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipping TimeEditable";
                    ToolTip = 'Specifies the shipping time for the order. This is the time it takes from when the order is shipped from the warehouse, to when the order is delivered to the customer''s address.';
                    Visible = false;
                }
                field("Whse. Outstanding Qty. (Base)"; Rec."Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the variant number of the items sold.';
                    Visible = false;
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outbound warehouse handling time, which is used to calculate the planned shipment date.';
                    Visible = false;
                }
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "FA Posting DateEditable";
                    ToolTip = 'Specifies the posting date for the fixed asset.';
                    Visible = false;
                }
                field("Appl.-from Item Entry"; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Appl.-from Item EntryEditable";
                    ToolTip = 'Specifies the number of the item ledger entry that the sales credit memo line is applied from. This means that the inventory increase from this sales credit memo line is linked to the inventory decrease in the item ledger entry that you indicate in this field.';
                    Visible = false;
                }
                field("Appl.-to Item Entry"; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Appl.-to Item EntryEditable";
                    ToolTip = 'Specifies the number of a particular item ledger entry that the line should be applied to. This means that the inventory decrease from this sales line will be taken from the inventory increase in the item ledger entry that you select in this field. This creates a link so that the cost of the applied-to item ledger entry is carried over to this line.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Purchase &Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'Purchase goods or services from a vendor.';

                        trigger OnAction()
                        begin
                            OpenPurchOrderForm();
                        end;
                    }
                }
                group("Special Order")
                {
                    Caption = 'Special Order';
                    Image = SpecialOrder;
                    action(Action1902080804)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase &Order';
                        Image = Document;
                        ToolTip = 'Purchase goods or services from a vendor.';

                        trigger OnAction()
                        begin
                            OpenPurchOrderForm();
                        end;
                    }
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Item Charge &Assignment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Charge &Assignment';
                    Enabled = Rec.Type = Rec.Type::"Charge (Item)";
                    ToolTip = 'Record additional direct costs, for example for freight. This action is available only for Charge (Item) line types.';

                    trigger OnAction()
                    begin
                        ItemChargeAssgnt();
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Enabled = Rec.Type = Rec.Type::Item;
                    ToolTip = 'View or edit serial, lot and package numbers for the selected item. This action is available only for lines that contain an item.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        "Appl.-to Item EntryEditable" := true;
        "Appl.-from Item EntryEditable" := true;
        "FA Posting DateEditable" := true;
        "Shipping TimeEditable" := true;
        ShippingAgentServiceCodeEditab := true;
        "Shipping Agent CodeEditable" := true;
        "Shipment DateEditable" := true;
        "Planned Shipment DateEditable" := true;
        "Planned Delivery DateEditable" := true;
        "Promised Delivery DateEditable" := true;
        AllowItemChargeAssignmentEdita := true;
        "Qty. to ShipEditable" := true;
        "Package Tracking No.Editable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := xRec.Type;
        Clear(ShortcutDimCode);
    end;

    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ShortcutDimCode: array[8] of Code[20];
        "Variant CodeEditable": Boolean;
        "Package Tracking No.Editable": Boolean;
        "Qty. to ShipEditable": Boolean;
        AllowItemChargeAssignmentEdita: Boolean;
        "Promised Delivery DateEditable": Boolean;
        "Planned Delivery DateEditable": Boolean;
        "Planned Shipment DateEditable": Boolean;
        "Shipment DateEditable": Boolean;
        "Shipping Agent CodeEditable": Boolean;
        ShippingAgentServiceCodeEditab: Boolean;
        "Shipping TimeEditable": Boolean;
        "FA Posting DateEditable": Boolean;
        "Appl.-from Item EntryEditable": Boolean;
        "Appl.-to Item EntryEditable": Boolean;

    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
    end;

    procedure CalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", Rec);
    end;

    procedure ExplodeBOM()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", Rec);
    end;

    procedure OpenPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchOrder: Page "Purchase Order";
    begin
        PurchHeader.SetRange("No.", Rec."Purchase Order No.");
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := false;
        PurchOrder.Run();
    end;

    procedure OpenSpecialPurchOrderForm()
    var
        PurchHeader: Record "Purchase Header";
        PurchOrder: Page "Purchase Order";
    begin
        PurchHeader.SetRange("No.", Rec."Special Order Purchase No.");
        PurchOrder.SetTableView(PurchHeader);
        PurchOrder.Editable := false;
        PurchOrder.Run();
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            TransferExtendedText.InsertSalesExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            UpdateForm(true);
    end;

    procedure ShowLineReservation()
    begin
        Rec.Find();
        Rec.ShowReservation();
    end;

    procedure ItemAvailability(AvailabilityType: Option Date,Variant,Location,Bin)
    begin
        ItemAvailability(AvailabilityType);
    end;

    procedure ShowReservationEntries()
    begin
        Rec.ShowReservationEntries(true);
    end;

    procedure ShowNonstockItems()
    begin
        Rec.ShowNonstock();
    end;

    procedure ShowTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."No.", Rec."Outstanding Qty. (Base)", Rec."Shipment Date", Rec."Shipment Date");
        OrderTracking.RunModal();
    end;

    procedure ItemChargeAssgnt()
    begin
        Rec.ShowItemChargeAssgnt();
    end;

    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    procedure OrderOnHold(OnHold: Boolean)
    begin
        "Variant CodeEditable" := not OnHold;
        "Package Tracking No.Editable" := not OnHold;
        "Qty. to ShipEditable" := not OnHold;
        AllowItemChargeAssignmentEdita := not OnHold;
        "Promised Delivery DateEditable" := not OnHold;
        "Planned Delivery DateEditable" := not OnHold;
        "Planned Shipment DateEditable" := not OnHold;
        "Shipment DateEditable" := not OnHold;
        "Shipping Agent CodeEditable" := not OnHold;
        ShippingAgentServiceCodeEditab := not OnHold;
        "Shipping TimeEditable" := not OnHold;
        "FA Posting DateEditable" := not OnHold;
        "Appl.-from Item EntryEditable" := not OnHold;
        "Appl.-to Item EntryEditable" := not OnHold;
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);
        if (Rec.Type = Rec.Type::"Charge (Item)") and (Rec."No." <> xRec."No.") and
           (xRec."No." <> '')
        then
            CurrPage.SaveRecord();
    end;

    local procedure QuantityOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    local procedure UnitofMeasureCodeOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;
}

