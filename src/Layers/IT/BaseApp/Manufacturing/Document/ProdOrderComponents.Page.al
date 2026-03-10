// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Reports;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Structure;

page 99000818 "Prod. Order Components"
{
    AutoSplitKey = true;
    Caption = 'Prod. Order Components';
    DataCaptionExpression = Rec.Caption();
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Prod. Order Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        ItemNoOnAfterValidate();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Due Date-Time"; Rec."Due Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Scrap %"; Rec."Scrap %")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        ScrapPercentOnAfterValidate();
                    end;
                }
                field("Calculation Formula"; Rec."Calculation Formula")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CalculationFormulaOnAfterValidate();
                    end;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        LengthOnAfterValidate();
                    end;
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        WidthOnAfterValidate();
                    end;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        WeightOnAfterValidate();
                    end;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DepthOnAfterValidate();
                    end;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        QuantityperOnAfterValidate();
                    end;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReservationEntries(true);
                        CurrPage.Update(false);
                    end;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValidate();
                    end;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Manufacturing;
                }
#if not CLEAN27
                field("Qty. on Transfer Order (Base)"; Rec."Qty. on Transfer Order (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item amount that is on the transfer order.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Qty. in Transit (Base)"; Rec."Qty. in Transit (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the items that are in transit.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Qty. transf. to Subcontractor"; Rec."Qty. transf. to Subcontractor")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item amount that will be transferred to the subcontractor.';
                    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Routing Link Code"; Rec."Routing Link Code")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Qty. Picked"; Rec."Qty. Picked")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Qty. Picked (Base)"; Rec."Qty. Picked (Base)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the quantity of the item you have picked for the component line.';
                    Visible = false;
                }
                field("Substitution Available"; Rec."Substitution Available")
                {
                    ApplicationArea = Manufacturing;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            part(Control44; "Prod. Order Comp. Item FactBox")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = Status = field(Status),
                              "Prod. Order No." = field("Prod. Order No."),
                              "Prod. Order Line No." = field("Prod. Order Line No."),
                              "Line No." = field("Line No."),
                              "Item No." = field("Item No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::Period);
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
                            ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::Location);
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
                    action("BOM Level")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ProdOrderAvailabilityMgt.ShowItemAvailFromProdOrderComp(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comp. Cmt. Sheet";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("Prod. Order No."),
                                  "Prod. Order Line No." = field("Prod. Order Line No."),
                                  "Prod. Order BOM Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
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
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Location Code", "Bin Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
                action(SelectItemSubstitution)
                {
                    AccessByPermission = TableData "Item Substitution" = R;
                    ApplicationArea = Manufacturing;
                    Caption = '&Select Item Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemSub();
                        CurrPage.Update(true);
                        ReserveComp();
                    end;
                }
                action("Put-away/Pick Lines/Movement Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away/Pick Lines/Movement Lines';
                    Image = PutawayLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Source Type" = const(5407),
                                  "Source Subtype" = const("3"),
                                  "Source No." = field("Prod. Order No."),
                                  "Source Line No." = field("Prod. Order Line No."),
                                  "Source Subline No." = field("Line No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk");
                    ToolTip = 'View the list of ongoing inventory put-aways, picks, or movements for the order.';
                }
                action("Item Ledger E&ntries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item Ledger E&ntries';
                    Image = ItemLedger;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Order Type" = const(Production),
                                  "Order No." = field("Prod. Order No."),
                                  "Order Line No." = field("Prod. Order Line No."),
                                  "Prod. Order Comp. Line No." = field("Line No.");
                    RunPageView = sorting("Order Type", "Order No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the item ledger entries of the item on the document or journal line.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        if Rec.Status in [Rec.Status::Simulated, Rec.Status::Planned] then
                            Error(Text000, Rec.Status);

                        CurrPage.SaveRecord();
                        Rec.ShowReservation();
                    end;
                }
                action(ReserveFromInventory)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserve from Inventory';
                    Image = LineReserve;
                    ToolTip = 'Reserve items for the selected line from inventory.';

                    trigger OnAction()
                    var
                        ProdOrderComponent: Record "Prod. Order Component";
                    begin
                        CurrPage.SetSelectionFilter(ProdOrderComponent);
                        Rec.ReserveFromInventory(ProdOrderComponent);
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        Rec.ShowOrderTracking();
                    end;
                }
            }
            action(SelectMultiItems)
            {
                AccessByPermission = TableData Item = R;
                ApplicationArea = Manufacturing;
                Caption = 'Select items';
                Ellipsis = true;
                Image = NewItem;
                ToolTip = 'Add two or more items from the list of your inventory items.';

                trigger OnAction()
                begin
                    Rec.SelectMultipleItems();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ProdOrderComp: Record "Prod. Order Component";
                begin
                    ProdOrderComp.Copy(Rec);
                    REPORT.RunModal(REPORT::"Prod. Order - Picking List", true, true, ProdOrderComp);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Reserve_Promoted; Reserve)
                {
                }
                actionref(OrderTracking_Promoted; OrderTracking)
                {
                }
                group(Category_Category5)
                {
                    Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                    actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                    {
                    }
                    actionref(SelectItemSubstitution_Promoted; SelectItemSubstitution)
                    {
                    }
                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref("Put-away/Pick Lines/Movement Lines_Promoted"; "Put-away/Pick Lines/Movement Lines")
                    {
                    }
                    actionref("Item Ledger E&ntries_Promoted"; "Item Ledger E&ntries")
                    {
                    }
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        Commit();
        if not ProdOrderCompReserve.DeleteLineConfirm(Rec) then
            exit(false);
        ProdOrderCompReserve.DeleteLine(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
        VariantCodeMandatory: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot reserve components with status %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ShortcutDimCode: array[8] of Code[20];

    procedure ReserveComp()
    var
        Item: Record Item;
        ShouldReserve: Boolean;
    begin
        ShouldReserve :=
            (xRec."Remaining Qty. (Base)" <> Rec."Remaining Qty. (Base)") or
            (xRec."Item No." <> Rec."Item No.") or
            (xRec."Location Code" <> Rec."Location Code");

        OnBeforeReserveComp(Rec, xRec, ShouldReserve);

        if ShouldReserve then
            if Item.Get(Rec."Item No.") then
                if Item.Reserve = Item.Reserve::Always then begin
                    CurrPage.SaveRecord();
                    Rec.AutoReserve();
                    CurrPage.Update(false);
                end;
    end;

    protected procedure ItemNoOnAfterValidate()
    begin
        ReserveComp();
    end;

    local procedure ScrapPercentOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure CalculationFormulaOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure LengthOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure WidthOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure WeightOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure DepthOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure QuantityperOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure UnitofMeasureCodeOnAfterValidate()
    begin
        ReserveComp();
    end;

    protected procedure LocationCodeOnAfterValidate()
    begin
        ReserveComp();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeReserveComp(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component"; var ShouldReserve: Boolean)
    begin
    end;
}

