// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

page 5700 "Stockkeeping Unit Card"
{
    Caption = 'Stockkeeping Unit Card';
    PageType = Card;
    SourceTable = "Stockkeeping Unit";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item number to which the SKU applies.';
                    trigger OnValidate()
                    begin
                        EnableControls();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description from the Item Card.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location code (for example, the warehouse or distribution center) to which the SKU applies.';
                    trigger OnValidate()
                    begin
                        if xRec."Location Code" <> Rec."Location Code" then
                            EnableControls();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Assembly BOM"; Rec."Assembly BOM")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the item is an assembly BOM.';
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies where to find the SKU in the warehouse.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies when the SKU card was last modified.';
                }
                field("Qty. on Purch. Order"; Rec."Qty. on Purch. Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Qty. in Transit"; Rec."Qty. in Transit")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the quantity of the SKUs in transit. These items have been shipped, but not yet received.';
                }
                field("Qty. on Sales Order"; Rec."Qty. on Sales Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    HideValue = IsNonInventoriable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Qty. on Blanket Sales Order"; Rec."Qty. on Blanket Sales Order")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Qty. on Blanket Purch. Order"; Rec."Qty. on Blanket Purch. Order")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Qty. on Job Order"; Rec."Qty. on Job Order")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how many units of the item are allocated to projects, meaning listed on outstanding project planning lines.';
                }
                field("Qty. on Assembly Order"; Rec."Qty. on Assembly Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the SKU are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
                }
                field("Qty. on Asm. Component"; Rec."Qty. on Asm. Component")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many item units are allocated as assembly components, which is how many units are on outstanding assembly order lines.';
                }
                field("Trans. Ord. Receipt (Qty.)"; Rec."Trans. Ord. Receipt (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item units that remains to be received but are not yet shipped as the difference between the Quantity and the Quantity Shipped fields.';
                    Visible = false;
                }
                field("Trans. Ord. Shipment (Qty.)"; Rec."Trans. Ord. Shipment (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the item units that remains to be shipped as the difference between the Quantity and the Quantity Shipped fields.';
                    Visible = false;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Standard Cost"; Rec."Standard Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = StandardCostEnable;
                    ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary. Warning: If the SKU is supplied through production, then this field is not used when invoicing and adjusting the actual cost of the produced item. Instead, the Standard Cost field on the underlying item card is used, and any variances are calculated against the cost shares of that item.';

                    trigger OnDrillDown()
                    var
                        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                    begin
                        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Item);
                    end;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    Enabled = UnitCostEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';

                    trigger OnDrillDown()
                    var
                        ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                    begin
                        ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Item);
                    end;
                }
                field("Last Direct Cost"; Rec."Last Direct Cost")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the most recent direct unit cost that was paid for the SKU.';
                }
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; SKUReplenishmentSystem)
                {
                    ApplicationArea = Planning;
                    Caption = 'Replenishment System';
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of supply order that is created by the planning system when the SKU needs to be replenished.';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Replenishment System", SKUReplenishmentSystem);
                    end;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    }
                    field("Vendor Item No."; Rec."Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the number that the vendor uses for this item.';
                    }
                }
                group(Transfer)
                {
                    Caption = 'Transfer';
                    field("Transfer-from Code"; Rec."Transfer-from Code")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies the code of the location that items are transferred from.';
                    }
                }
                group(Production)
                {
                    Caption = 'Production';
                    field("Manufacturing Policy"; Rec."Manufacturing Policy")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies if additional orders for any related components are calculated.';
                    }
                    field("Flushing Method"; Rec."Flushing Method")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    }
                    field("Components at Location"; Rec."Components at Location")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies the inventory location from where the production order components are to be taken when producing this SKU.';
                    }
                    field("Lot Size"; Rec."Lot Size")
                    {
                        ApplicationArea = Manufacturing;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    }
                }
                group(Assembly)
                {
                    Caption = 'Assembly';
                    field("Assembly Policy"; Rec."Assembly Policy")
                    {
                        ApplicationArea = Assembly;
                        ToolTip = 'Specifies which default order flow is used to supply this SKU by assembly.';
                    }
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                Visible = IsInventoriable;
                field("Reordering Policy"; Rec."Reordering Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';

                    trigger OnValidate()
                    begin
                        EnablePlanningControls();
                    end;
                }
                field("Dampener Period"; Rec."Dampener Period")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerPeriodEnable;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward. The dampener period limits the number of insignificant rescheduling of existing supply to a later date if that new date is within the dampener period. The dampener period function is only initiated if the supply can be rescheduled to a later date and not if the supply can be rescheduled to an earlier date. Accordingly, if the suggested new supply date is after the dampener period, then the rescheduling suggestion is not blocked. If the lot accumulation period is less than the dampener period, then the dampener period is dynamically set to equal the lot accumulation period. This is not shown in the value that you enter in the Dampener Period field. The last demand in the lot accumulation period is used to determine whether a potential supply date is in the dampener period. If this field is empty, then the value in the Default Dampener Period field in the Manufacturing Setup window applies. The value that you enter in the Dampener Period field must be a date formula, and one day (1D) is the shortest allowed period.';
                }
                field("Dampener Quantity"; Rec."Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerQtyEnable;
                    ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions, if the quantity by which the supply would change is lower than the dampener quantity.';
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyLeadTimeEnable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyStockQtyEnable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                group("Lot-for-Lot Parameters")
                {
                    Caption = 'Lot-for-Lot Parameters';
                    field("Include Inventory"; Rec."Include Inventory")
                    {
                        ApplicationArea = Planning;
                        Enabled = IncludeInventoryEnable;
                        ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';

                        trigger OnValidate()
                        begin
                            EnablePlanningControls();
                        end;
                    }
                    field("Lot Accumulation Period"; Rec."Lot Accumulation Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = LotAccumulationPeriodEnable;
                        ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';
                    }
                    field("Rescheduling Period"; Rec."Rescheduling Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = ReschedulingPeriodEnable;
                        ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';
                    }
                }
                group("Reorder-Point Parameters")
                {
                    Caption = 'Reorder-Point Parameters';
                    grid(Control39)
                    {
                        GridLayout = Rows;
                        ShowCaption = false;
                        group(Control41)
                        {
                            ShowCaption = false;
                            field("Reorder Point"; Rec."Reorder Point")
                            {
                                ApplicationArea = Planning;
                                Enabled = ReorderPointEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Reorder Quantity"; Rec."Reorder Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = ReorderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Maximum Inventory"; Rec."Maximum Inventory")
                            {
                                ApplicationArea = Planning;
                                Enabled = MaximumInventoryEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                        }
                    }
                    field("Overflow Level"; Rec."Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Enabled = OverflowLevelEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point before the system suggests to decrease existing supply orders.';
                    }
                    field("Time Bucket"; Rec."Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Enabled = TimeBucketEnable;
                        Importance = Additional;
                        ToolTip = 'Specifies a time period for the recurring planning horizon of the SKU when you use Fixed Reorder Qty. or Maximum Qty. reordering policies.';
                    }
                }
                group("Order Modifiers")
                {
                    Caption = 'Order Modifiers';
                    Enabled = MinimumOrderQtyEnable;
                    grid(Control21)
                    {
                        GridLayout = Rows;
                        ShowCaption = false;
                        group(Control23)
                        {
                            ShowCaption = false;
                            field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = MinimumOrderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Maximum Order Quantity"; Rec."Maximum Order Quantity")
                            {
                                ApplicationArea = Planning;
                                Enabled = MaximumOrderQtyEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                            field("Order Multiple"; Rec."Order Multiple")
                            {
                                ApplicationArea = Planning;
                                Enabled = OrderMultipleEnable;
                                ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                            }
                        }
                    }
                }
            }
            group(Control1907509201)
            {
                Caption = 'Warehouse';
                Visible = IsInventoriable;
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the code of the equipment that you need to use when working with the SKU.';
                }
                field("Put-away Template Code"; Rec."Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the put-away template that the program uses when it performs a put-away for the SKU.';
                }
                field("Put-away Unit of Measure Code"; Rec."Put-away Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the unit of measure that the program uses when it performs a put-away for the SKU.';
                }
                field("Phys Invt Counting Period Code"; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the SKU in a physical inventory.';
                }
                field("Last Phys. Invt. Date"; Rec."Last Phys. Invt. Date")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the date on which you last posted the results of a physical inventory for the SKU to the item ledger.';
                }
                field("Last Counting Period Update"; Rec."Last Counting Period Update")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the last date on which you calculated the counting period.';
                }
                field("Next Counting Start Date"; Rec."Next Counting Start Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the starting date of the next counting period.';
                }
                field("Next Counting End Date"; Rec."Next Counting End Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ending date of the next counting period.';
                }
                field("Use Cross-Docking"; Rec."Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the SKU can be cross-docked.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Planning;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action89)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Statistics';
                        Image = Statistics;
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                        trigger OnAction()
                        var
                            ItemStatistics: Page "Item Statistics";
                        begin
                            ItemStatistics.SetItem(Item);
                            ItemStatistics.RunModal();
                        end;
                    }
                }
                action("Co&mments")
                {
                    ApplicationArea = Planning;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Item),
                                  "No." = field("Item No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(27),
                                  "No." = field("Item No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("&Picture")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Picture';
                    Image = Picture;
                    RunObject = Page "Item Picture";
                    RunPageLink = "No." = field("Item No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Location Filter" = field("Location Code"),
                                  "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                  "Variant Filter" = field("Variant Code");
                    ToolTip = 'View or add a picture of the item or, for example, the company''s logo.';
                }
                separator(Action103)
                {
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Planning;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    RunObject = Page "Item Units of Measure";
                    RunPageLink = "Item No." = field("Item No.");
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "Item Variants";
                    RunPageLink = "Item No." = field("Item No.");
                    ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                }
                separator(Action106)
                {
                }
                action(Translations)
                {
                    ApplicationArea = Planning;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field(filter("Variant Code"));
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Planning;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const(Item),
                                  "No." = field("Item No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'Select or set up additional text for the description of the item. Extended text can be inserted under the Description field on document lines for the item.';
                }
            }
            group("&SKU")
            {
                Caption = '&SKU';
                Image = SKU;
                group(Action92)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action("Entry Statistics")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Entry Statistics';
                        Image = EntryStatistics;
                        RunObject = Page "Item Entry Statistics";
                        RunPageLink = "No." = field("Item No."),
                                      "Date Filter" = field("Date Filter"),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Code"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Code");
                        ToolTip = 'View entry statistics for the record.';
                    }
                    action("T&urnover")
                    {
                        ApplicationArea = Planning;
                        Caption = 'T&urnover';
                        Image = Turnover;
                        RunObject = Page "Item Turnover";
                        RunPageLink = "No." = field("Item No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Code"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Code");
                        ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
                    }
                }
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
                        var
                            Item: Record Item;
                        begin
                            Item.Get(Rec."Item No.");
                            Item.SetRange("Location Filter", Rec."Location Code");
                            Item.SetRange("Variant Filter", Rec."Variant Code");
                            Rec.CopyFilter("Date Filter", Item."Date Filter");
                            Rec.CopyFilter("Global Dimension 1 Filter", Item."Global Dimension 1 Filter");
                            Rec.CopyFilter("Global Dimension 2 Filter", Item."Global Dimension 2 Filter");
                            Rec.CopyFilter("Drop Shipment Filter", Item."Drop Shipment Filter");
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Item, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = field("Item No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Code"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';
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
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            Item.Get(Rec."Item No.");
                            Item.SetRange("Location Filter", Rec."Location Code");
                            Item.SetRange("Variant Filter", Rec."Variant Code");
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Item, "Item Availability Type"::BOM);
                        end;
                    }
                }
                action(Action124)
                {
                    ApplicationArea = All;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Stock. Unit Comment Sheet";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                group("E&ntries")
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Item No." = field("Item No."),
                                      "Location Code" = field("Location Code"),
                                      "Variant Code" = field("Variant Code");
                        RunPageView = sorting("Item No.", Open, "Variant Code");
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "Reservation Entries";
                        RunPageLink = "Item No." = field("Item No."),
                                      "Location Code" = field("Location Code"),
                                      "Variant Code" = field("Variant Code"),
                                      "Reservation Status" = const(Reservation);
                        RunPageView = sorting("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        RunObject = Page "Phys. Inventory Ledger Entries";
                        RunPageLink = "Item No." = field("Item No."),
                                      "Location Code" = field("Location Code"),
                                      "Variant Code" = field("Variant Code");
                        RunPageView = sorting("Item No.", "Variant Code");
                        ToolTip = 'View how many units of the item you had in stock at the last physical count.';
                    }
                    action("&Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Item No." = field("Item No."),
                                      "Location Code" = field("Location Code"),
                                      "Variant Code" = field("Variant Code");
                        RunPageView = sorting("Item No.", "Valuation Date", "Location Code", "Variant Code");
                        ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                    }
                    action("Item &Tracking Entries")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                        trigger OnAction()
                        var
                            ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                        begin
                            ItemTrackingDocMgt.ShowItemTrackingForEntity(0, '', Rec."Item No.", Rec."Variant Code", Rec."Location Code");
                        end;
                    }
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("&Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                Image = NewItem;
                action(NewItem)
                {
                    ApplicationArea = Planning;
                    Caption = 'New Item';
                    Image = NewItem;
                    RunObject = Page "Item Card";
                    RunPageMode = Create;
                    ToolTip = 'Create an item card based on the stockkeeping unit.';
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("C&alculate Counting Period")
                {
                    AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        PhysInvtCountMgt.UpdateSKUPhysInvtCount(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("C&alculate Counting Period_Promoted"; "C&alculate Counting Period")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("&Picture_Promoted"; "&Picture")
                {
                }
            }
            group(Category_SKU)
            {
                Caption = 'SKU';

                group(Category_Statistics)
                {
                    Caption = 'Statistics';

                    actionref(Action89_Promoted; Action89)
                    {
                    }
                    actionref("Entry Statistics_Promoted"; "Entry Statistics")
                    {
                    }
                    actionref("T&urnover_Promoted"; "T&urnover")
                    {
                    }
                }
                actionref(Action124_Promoted; Action124)
                {
                }
                group("Category_Item Availability by")
                {
                    Caption = 'Item Availability by';

                    actionref(Event_Promoted; "Event")
                    {
                    }
                    actionref(Period_Promoted; Period)
                    {
                    }
                    actionref(Lot_Promoted; Lot)
                    {
                    }
                    actionref("BOM Level_Promoted"; "BOM Level")
                    {
                    }
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetItemFilters();
        EnableControls();
        EnablePlanningControls();
        EnableCostingControls();

        SKUReplenishmentSystem := Rec."Replenishment System";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SKUReplenishmentSystem := Rec."Replenishment System";
    end;

    trigger OnInit()
    begin
        UnitCostEnable := true;
        StandardCostEnable := true;
        OverflowLevelEnable := true;
        DampenerQtyEnable := true;
        DampenerPeriodEnable := true;
        LotAccumulationPeriodEnable := true;
        ReschedulingPeriodEnable := true;
        IncludeInventoryEnable := true;
        OrderMultipleEnable := true;
        MaximumOrderQtyEnable := true;
        MinimumOrderQtyEnable := true;
        MaximumInventoryEnable := true;
        ReorderQtyEnable := true;
        ReorderPointEnable := true;
        SafetyStockQtyEnable := true;
        SafetyLeadTimeEnable := true;
        TimeBucketEnable := true;
    end;

    var
        InvtSetup: Record "Inventory Setup";
        Item: Record Item;
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        SKUReplenishmentSystem: Enum "SKU Replenishment System";

    protected var
        TimeBucketEnable: Boolean;
        SafetyLeadTimeEnable: Boolean;
        SafetyStockQtyEnable: Boolean;
        ReorderPointEnable: Boolean;
        ReorderQtyEnable: Boolean;
        MaximumInventoryEnable: Boolean;
        MinimumOrderQtyEnable: Boolean;
        MaximumOrderQtyEnable: Boolean;
        OrderMultipleEnable: Boolean;
        IncludeInventoryEnable: Boolean;
        ReschedulingPeriodEnable: Boolean;
        LotAccumulationPeriodEnable: Boolean;
        DampenerPeriodEnable: Boolean;
        DampenerQtyEnable: Boolean;
        OverflowLevelEnable: Boolean;
        StandardCostEnable: Boolean;
        UnitCostEnable: Boolean;
        IsInventoriable: Boolean;
        IsNonInventoriable: Boolean;

    local procedure EnablePlanningControls()
    var
        PlanningParameters: Record "Planning Parameters";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningParameters."Reordering Policy" := Rec."Reordering Policy";
        PlanningParameters."Include Inventory" := Rec."Include Inventory";
        PlanningGetParameters.SetPlanningParameters(PlanningParameters);

        TimeBucketEnable := PlanningParameters."Time Bucket Enabled";
        SafetyLeadTimeEnable := PlanningParameters."Safety Lead Time Enabled";
        SafetyStockQtyEnable := PlanningParameters."Safety Stock Qty Enabled";
        ReorderPointEnable := PlanningParameters."Reorder Point Enabled";
        ReorderQtyEnable := PlanningParameters."Reorder Quantity Enabled";
        MaximumInventoryEnable := PlanningParameters."Maximum Inventory Enabled";
        MinimumOrderQtyEnable := PlanningParameters."Minimum Order Qty Enabled";
        MaximumOrderQtyEnable := PlanningParameters."Maximum Order Qty Enabled";
        OrderMultipleEnable := PlanningParameters."Order Multiple Enabled";
        IncludeInventoryEnable := PlanningParameters."Include Inventory Enabled";
        ReschedulingPeriodEnable := PlanningParameters."Rescheduling Period Enabled";
        LotAccumulationPeriodEnable := PlanningParameters."Lot Accum. Period Enabled";
        DampenerPeriodEnable := PlanningParameters."Dampener Period Enabled";
        DampenerQtyEnable := PlanningParameters."Dampener Quantity Enabled";
        OverflowLevelEnable := PlanningParameters."Overflow Level Enabled";
    end;

    local procedure EnableCostingControls()
    begin
        StandardCostEnable := Item."Costing Method" = Item."Costing Method"::Standard;
        UnitCostEnable := Item."Costing Method" <> Item."Costing Method"::Standard;
    end;

    local procedure SetItemFilters()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetItemFilters(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        InvtSetup.Get();
        Item.Reset();
        if Item.Get(Rec."Item No.") then begin
            if InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant" then begin
                Item.SetRange("Location Filter", Rec."Location Code");
                Item.SetRange("Variant Filter", Rec."Variant Code");
            end;
            Item.SetFilter("Date Filter", Rec.GetFilter("Date Filter"));
        end;
    end;

    local procedure EnableControls()
    begin
        IsInventoriable := Item.IsInventoriableType();
        IsNonInventoriable := Item.IsNonInventoriableType();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetItemFilters(var StockkeepingUnit: Record "Stockkeeping Unit"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;
}

