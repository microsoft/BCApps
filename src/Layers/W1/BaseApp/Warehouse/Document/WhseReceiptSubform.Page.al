// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

page 5769 "Whse. Receipt Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    InsertAllowed = false;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Warehouse Receipt Line";

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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that is expected to be received.';
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
                    ToolTip = 'Specifies the code of the location where the items should be received.';
                    Visible = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone in which the items are being received.';
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
                field("Cross-Dock Zone Code"; Rec."Cross-Dock Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code that will be used for the quantity of items to be cross-docked.';
                    Visible = false;
                }
                field("Cross-Dock Bin Code"; Rec."Cross-Dock Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin code that will be used for the quantity of items to be cross-docked.';
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item for information use.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity that should be received.';
                }
                field("Qty. (Base)"; Rec."Qty. (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity to be received, in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Receive"; Rec."Qty. to Receive")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of items that remains to be received.';

                    trigger OnValidate()
                    begin
                        QtytoReceiveOnAfterValidate();
                    end;
                }
                field("Qty. to Cross-Dock"; Rec."Qty. to Cross-Dock")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the suggested quantity to put into the cross-dock bin on the put-away document when the receipt is posted.';
                    Visible = true;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShowCrossDockOpp(WhseCrossDockOpp2);
                        CurrPage.Update();
                    end;
                }
                field("Qty. Received"; Rec."Qty. Received")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity for this line that has been posted as received.';
                    Visible = true;
                }
                field("Qty. to Receive (Base)"; Rec."Qty. to Receive (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Qty. to Receive in the base unit of measure.';
                    Visible = false;
                }
                field("Qty. to Cross-Dock (Base)"; Rec."Qty. to Cross-Dock (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the suggested base quantity to put into the cross-dock bin on the put-away document hen the receipt is posted.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ShowCrossDockOpp(WhseCrossDockOpp2);
                        CurrPage.Update();
                    end;
                }
                field("Qty. Received (Base)"; Rec."Qty. Received (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity received, in the base unit of measure.';
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
                    ToolTip = 'Specifies the quantity that still needs to be handled, in the base unit of measure.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date on which you expect to receive the items on the line.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of base units of measure, that are in the unit of measure specified for the item on the line.';
                }
                field("Over-Receipt Quantity"; Rec."Over-Receipt Quantity")
                {
                    ApplicationArea = Warehouse;
                    Visible = OverReceiptAllowed;
                    ToolTip = 'Specifies over-receipt quantity.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = OverReceiptAllowed;
                    ToolTip = 'Specifies over-receip code.';
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
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailability("Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ItemAvailability("Item Availability Type"::Period);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ItemAvailability("Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Warehouse;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ItemAvailability("Item Availability Type"::Location);
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("Item No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
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
            }
        }
    }

    var
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Cross-docking has been disabled for item %1 or location %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HideBinFields: Boolean;

    protected var
        WhseCrossDockOpp2: Record "Whse. Cross-Dock Opportunity";
        OverReceiptAllowed: Boolean;

    trigger OnOpenPage()
    begin
        SetOverReceiptControlsVisibility();
    end;

    internal procedure SetHideBinFields(NewHideBinFields: Boolean)
    begin
        HideBinFields := NewHideBinFields;
    end;

    local procedure ShowSourceLine()
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        WMSMgt.ShowSourceDocLine(
          Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", 0);
    end;

    local procedure ShowSourceAttachedLines()
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        WMSMgt.ShowSourceDocAttachedLines(
          Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.");
    end;

    local procedure ShowBinContents()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.ShowBinContents(Rec."Location Code", Rec."Item No.", Rec."Variant Code", Rec."Bin Code");
    end;

    local procedure ItemAvailability(AvailabilityType: Enum "Item Availability Type")
    begin
        WarehouseAvailabilityMgt.ShowItemAvailFromWhseRcptLine(Rec, AvailabilityType);
    end;

    procedure WhsePostRcptYesNo()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt (Yes/No)", WhseRcptLine);
        Rec.Reset();
        Rec.SetCurrentKey("No.", "Sorting Sequence No.");

        OnAfterWhsePostRcptYesNo(Rec);
        CurrPage.Update(false);
    end;

    procedure Preview()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
    begin
        WhseRcptLine.Copy(Rec);
        WhsePostReceiptYesNo.Preview(WhseRcptLine);
        CurrPage.Update(false);
    end;

    procedure WhsePostRcptPrint()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt + Print", WhseRcptLine);
        Rec.Reset();
        Rec.SetCurrentKey("No.", "Sorting Sequence No.");
        CurrPage.Update(false);
    end;

    procedure WhsePostRcptPrintPostedRcpt()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt + Pr. Pos.", WhseRcptLine);
        Rec.Reset();

        OnAfterWhsePostRcptPrintPostedRcpt(Rec);
        CurrPage.Update(false);
    end;

    procedure AutofillQtyToReceive()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        WhseRcptLine.SetRange("No.", Rec."No.");
        Rec.AutofillQtyToReceive(WhseRcptLine);
    end;

    procedure DeleteQtyToReceive()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.Copy(Rec);
        WhseRcptLine.SetRange("No.", Rec."No.");
        Rec.DeleteQtyToReceive(WhseRcptLine);
    end;

    protected procedure ShowCrossDockOpp(var CrossDockOpp: Record "Whse. Cross-Dock Opportunity" temporary)
    var
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UseCrossDock: Boolean;
    begin
        CrossDockMgt.GetUseCrossDock(UseCrossDock, Rec."Location Code", Rec."Item No.");
        if not UseCrossDock then
            Error(Text001, Rec."Item No.", Rec."Location Code");
        CrossDockMgt.ShowCrossDock(CrossDockOpp, '', Rec."No.", Rec."Line No.", Rec."Location Code", Rec."Item No.", Rec."Variant Code");
    end;

    protected procedure BinCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    protected procedure QtytoReceiveOnAfterValidate()
    begin
        CurrPage.SaveRecord();
    end;

    local procedure SetOverReceiptControlsVisibility()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePostRcptPrintPostedRcpt(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePostRcptYesNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;
}

