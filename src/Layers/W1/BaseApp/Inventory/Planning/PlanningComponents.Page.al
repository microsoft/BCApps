// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

page 99000862 "Planning Components"
{
    AutoSplitKey = true;
    Caption = 'Planning Components';
    DataCaptionExpression = Rec.Caption();
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Planning Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item number of the component.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Due Date-Time"; Rec."Due Date-Time")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the due date and the due time, which are combined in a format called "due date-time".';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date when this planning component must be finished.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description of the component.';
                }
                field("Calculation Formula"; Rec."Calculation Formula")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how to calculate the Quantity field.';
                    Visible = false;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the width of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the depth of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the weight of one item unit when measured in the specified unit of measure.';
                    Visible = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how many units of the component are required to produce the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the expected quantity of this planning component line.';
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity of units that are reserved.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the inventory location, where the item on the planning component line will be registered.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the total cost for this planning component line.';
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the position of the component on the bill of material.';
                    Visible = false;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the second reference number for the component position, such as the alternate position number of a component on a circuit board.';
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the lead-time offset for the planning component.';
                    Visible = false;
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
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Component")
            {
                Caption = '&Component';
                Image = Components;
                group("&Item Availability by")
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action("&Period")
                    {
                        ApplicationArea = Planning;
                        Caption = '&Period';
                        Image = Period;
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time.';

                        trigger OnAction()
                        begin
                            PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(Rec, "Item Availability Type"::Period);
                        end;
                    }
                    action("&Variant")
                    {
                        ApplicationArea = Planning;
                        Caption = '&Variant';
                        Image = ItemVariant;
                        ToolTip = 'View any variants that exist for the item.';

                        trigger OnAction()
                        begin
                            PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action("&Location")
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = '&Location';
                        Image = Warehouse;
                        ToolTip = 'View detailed information about the location where the component exists.';

                        trigger OnAction()
                        begin
                            PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(Rec, "Item Availability Type"::Location);
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
                        ApplicationArea = Planning;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            PlanningCompAvailMgt.ShowItemAvailabilityFromPlanningComp(Rec, "Item Availability Type"::BOM);
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action(SelectMultiItems)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Planning;
                    Caption = 'Select items';
                    Ellipsis = true;
                    Image = NewItem;
                    ToolTip = 'Add two or more items from the list of your inventory items.';

                    trigger OnAction()
                    begin
                        Rec.SelectMultipleItems();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Reserve")
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowReservation();
                    end;
                }
                action(OrderTracking)
                {
                    ApplicationArea = Planning;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        OrderTracking: Page "Order Tracking";
                    begin
                        OrderTracking.SetPlanningComponent(Rec);
                        OrderTracking.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group("Category_Item Availability by")
                {
                    Caption = 'Item Availability by';

                    actionref(Event_Promoted; "Event")
                    {
                    }
                    actionref("&Period_Promoted"; "&Period")
                    {
                    }
                    actionref("&Variant_Promoted"; "&Variant")
                    {
                    }
                    actionref("&Location_Promoted"; "&Location")
                    {
                    }
                    actionref(Lot_Promoted; Lot)
                    {
                    }
                    actionref("BOM Level_Promoted"; "BOM Level")
                    {
                    }
                }
                actionref(OrderTracking_Promoted; OrderTracking)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref("&Reserve_Promoted"; "&Reserve")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    var
        PlanningCompAvailMgt: Codeunit "Planning Comp. Avail. Mgt.";
}

