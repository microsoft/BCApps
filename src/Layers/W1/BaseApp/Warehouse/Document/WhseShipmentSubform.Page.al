// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

page 7336 "Whse. Shipment Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Warehouse Shipment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Document"; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                }
                field("Source Line No."; Rec."Source Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the line number of the source document that the entry originates from.';
                    Visible = false;
                }
                field("Destination Type"; Rec."Destination Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of destination associated with the warehouse shipment line.';
                    Visible = false;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the customer, vendor, or location to which the items should be shipped.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that should be shipped.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item in the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies information in addition to the description of the item in the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location from which the items on the line are being shipped.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone where the bin on this shipment line is located.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = not HideBinFields;

                    trigger OnValidate()
                    begin
                        BinCodeOnAfterValidate();
                    end;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for informational use.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be shipped.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be shipped, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                }
                field("Qty. Shipped"; Rec."Qty. Shipped")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item on the line that is posted as shipped.';
                }
                field("Qty. to Ship (Base)"; Rec."Qty. to Ship (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity, in base units of measure, that will be shipped when the warehouse shipment is posted.';
                    Visible = false;
                }
                field("Qty. Shipped (Base)"; Rec."Qty. Shipped (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that is posted as shipped expressed in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. Outstanding"; Rec."Qty. Outstanding")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled.';
                    Visible = true;
                }
                field("Qty. Outstanding (Base)"; Rec."Qty. Outstanding (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that still needs to be handled, expressed in the base unit of measure.';
                    Visible = false;
                }
                field("Pick Qty."; Rec."Pick Qty.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in pick instructions assigned to be picked for the warehouse shipment line.';
                    Visible = false;
                }
                field("Pick Qty. (Base)"; Rec."Pick Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity, in the base unit of measure, in pick instructions, that is assigned to be picked for the warehouse shipment line.';
                    Visible = false;
                }
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many of the total shipment quantity have been registered as picked.';
                    Visible = false;
                }
                field("Qty. Picked (Base)"; Rec."Qty. Picked (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many of the total shipment quantity in the base unit of measure have been registered as picked.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the related warehouse activity, such as a pick, must be completed to ensure items can be shipped by the shipment date.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure that are in the unit of measure specified for the item on the line.';
                }
                field(QtyCrossDockedUOM; QtyCrossDockedUOM)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock Bin';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of all the outbound lines requesting the item within the look-ahead period, minus the quantity of the items that have already been placed in the cross-dock area.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked(Rec."Item No.", Rec."Variant Code", Rec."Unit of Measure Code", Rec."Location Code", true);
                    end;
                }
                field(QtyCrossDockedUOMBase; QtyCrossDockedUOMBase)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock Bin (Base)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of all the outbound lines requesting the item within the look-ahead period, minus the quantity of the items that have already been placed in the cross-dock area.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked(Rec."Item No.", Rec."Variant Code", Rec."Unit of Measure Code", Rec."Location Code", true);
                    end;
                }
                field(QtyCrossDockedAllUOMBase; QtyCrossDockedAllUOMBase)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Qty. on Cross-Dock Bin (Base all UOM)';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the sum of all the outbound lines requesting the item within the look-ahead period, minus the quantity of the items that have already been placed in the cross-dock area.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        CrossDockMgt.ShowBinContentsCrossDocked(Rec."Item No.", Rec."Variant Code", Rec."Unit of Measure Code", Rec."Location Code", false);
                    end;
                }
                field(Control3; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the warehouse shipment line is for items that are assembled to a sales order before it is shipped.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Source &Document Line")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source &Document Line';
                    Image = SourceDocLine;
                    ToolTip = 'View the line on a released source document that the warehouse activity is for. ';

                    trigger OnAction()
                    begin
                        ShowSourceLine();
                    end;
                }
                action("Source Document Attached Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source Document - Attached Lines';
                    Image = AllLines;
                    ToolTip = 'View the lines on a released source document that are attached to this item line.';

                    trigger OnAction()
                    begin
                        ShowSourceAttachedLines();
                    end;
                }
                action("&Bin Contents List")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents List';
                    Image = BinContent;
                    ToolTip = 'View the contents of each bin and the parameters that define how items are routed through the bin.';

                    trigger OnAction()
                    begin
                        ShowBinContents();
                    end;
                }
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action("Assemble to Order")
                {
                    AccessByPermission = TableData "BOM Component" = R;
                    ApplicationArea = Assembly;
                    Caption = 'Assemble to Order';
                    Image = AssemblyBOM;
                    ToolTip = 'View the linked assembly order if the shipment was for an assemble-to-order sale.';

                    trigger OnAction()
                    var
                        ATOLink: Record "Assemble-to-Order Link";
                        ATOSalesLine: Record "Sales Line";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeAssembleToOrder(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.TestField("Assemble to Order", true);
                        Rec.TestField("Source Type", Database::"Sales Line");
                        ATOSalesLine.Get(Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.");
                        ATOLink.ShowAsm(ATOSalesLine);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CrossDockMgt.CalcCrossDockedItems(Rec."Item No.", Rec."Variant Code", Rec."Unit of Measure Code", Rec."Location Code",
          QtyCrossDockedUOMBase,
          QtyCrossDockedAllUOMBase);
        QtyCrossDockedUOM := 0;
        if Rec."Qty. per Unit of Measure" <> 0 then
            QtyCrossDockedUOM := Round(QtyCrossDockedUOMBase / Rec."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.CheckDirectTransfer(false, true);
    end;

    var
        WMSMgt: Codeunit "WMS Management";
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyCrossDockedUOM: Decimal;
        QtyCrossDockedAllUOMBase: Decimal;
        QtyCrossDockedUOMBase: Decimal;
        HideBinFields: Boolean;

    local procedure ShowSourceLine()
    begin
        WMSMgt.ShowSourceDocLine(Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", 0);
    end;

    local procedure ShowSourceAttachedLines()
    begin
        WMSMgt.ShowSourceDocAttachedLines(
          Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.");
    end;

    internal procedure SetHideBinFields(NewHideBinFields: Boolean)
    begin
        HideBinFields := NewHideBinFields;
    end;

    procedure PostShipmentYesNo()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment (Yes/No)", WhseShptLine);
        Rec.Reset();
        Rec.SetCurrentKey("No.", "Sorting Sequence No.");
        CurrPage.Update(false);
    end;

    procedure Preview()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
    begin
        WhseShptLine.Copy(Rec);
        WhsePostShipmentYesNo.Preview(WhseShptLine);
        CurrPage.Update(false);
    end;

    procedure PostShipmentPrintYesNo()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment + Print", WhseShptLine);
        Rec.Reset();
        Rec.SetCurrentKey("No.", "Sorting Sequence No.");
        CurrPage.Update(false);
    end;

    procedure AutofillQtyToHandle()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        WhseShptLine.SetRange("No.", Rec."No.");
        Rec.AutofillQtyToHandle(WhseShptLine);
    end;

    procedure DeleteQtyToHandle()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        WhseShptLine.SetRange("No.", Rec."No.");
        Rec.DeleteQtyToHandle(WhseShptLine);
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."Bin Code");
    end;

    procedure PickCreate()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        ReleaseWhseShipment: Codeunit "Whse.-Shipment Release";
    begin
        OnBeforePickCreate(Rec);

        WhseShptLine.Copy(Rec);
        WhseShptHeader.Get(WhseShptLine."No.");
        if WhseShptHeader.Status = WhseShptHeader.Status::Open then
            ReleaseWhseShipment.Release(WhseShptHeader);
        Rec.CreatePickDoc(WhseShptLine, WhseShptHeader);

        OnAfterPickCreate(WhseShptLine);
    end;

    protected procedure BinCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPickCreate(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickCreate(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssembleToOrder(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;
}

