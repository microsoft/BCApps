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
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

page 5701 "Stockkeeping Unit List"
{
    AdditionalSearchTerms = 'sku';
    ApplicationArea = Warehouse;
    Caption = 'Stockkeeping Units';
    CardPageID = "Stockkeeping Unit Card";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Stockkeeping Units';
    AboutText = 'Manage item details and planning parameters for specific locations or variants, including inventory levels, replenishment methods, and warehouse information, to optimize stock control and supply processes.';
    SourceTable = "Stockkeeping Unit";
    UsageCategory = Lists;

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
                    ToolTip = 'Specifies the item number to which the SKU applies.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the location code (for example, the warehouse or distribution center) to which the SKU applies.';
                }
                field("Replenishment System"; Rec."Replenishment System")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the type of supply order that is created by the planning system when the SKU needs to be replenished.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the description from the Item Card.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Planning;
                    HideValue = IsNonInventoriable;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                }
                field("Reorder Point"; Rec."Reorder Point")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    Visible = false;
                }
                field("Reorder Quantity"; Rec."Reorder Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    Visible = false;
                }
                field("Maximum Inventory"; Rec."Maximum Inventory")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies for the SKU, the same as the field does on the item card.';
                    Visible = false;
                }
                field("Assembly Policy"; Rec."Assembly Policy")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies which default order flow is used to supply this SKU by assembly.';
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
                separator(Action1102601007)
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
                separator(Action1102601010)
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
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Item),
                                  "No." = field("Item No.");
                    ToolTip = 'View or add comments for the record.';
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
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action("Entry Statistics")
                    {
                        ApplicationArea = Suite;
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
                group("&Item Availability By")
                {
                    Caption = '&Item Availability By';
                    Image = ItemAvailability;
                    action("<Action5>")
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
                    action("Bill of Material")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Bill of Material';
                        Image = BOM;
                        ToolTip = 'View how many units of a parent you can make based on the availability of child items on underlying lines. Use the window to find out whether you can fulfill a sales order for an item on a specified date by looking at its current availability and the quantities that can be supplied by its components. You can also use the window to identify bottlenecks in related BOMs.';

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
                action(Action1102601046)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Stock. Unit Comment Sheet";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    ToolTip = 'View or add comments for the record.';
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
                        ApplicationArea = Planning;
                        Caption = 'Ledger E&ntries';
                        Image = CustomerLedger;
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
                        ApplicationArea = Planning;
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
        }
        area(creation)
        {
        }
        area(reporting)
        {
            action("Inventory - List")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory - List';
                Image = "Report";
                RunObject = Report "Inventory - List";
                ToolTip = 'View various information about the item, such as name, unit of measure, posting group, shelf number, vendor''s item number, lead time calculation, minimum inventory, and alternate item number. You can also see if the item is blocked.';
            }
            action("Inventory Availability")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory Availability';
                Image = "Report";
                RunObject = Report "Inventory Availability";
                ToolTip = 'View, print, or save a summary of historical inventory transactions with selected items, for example, to decide when to purchase the items. The report specifies quantity on sales order, quantity on purchase order, back orders from vendors, minimum inventory, and whether there are reorders.';
            }
            action("Inventory - Availability Plan")
            {
                ApplicationArea = Planning;
                Caption = 'Inventory - Availability Plan';
                Image = ItemAvailability;
                RunObject = Report "Inventory - Availability Plan";
                ToolTip = 'View a list of the quantity of each item in customer, purchase, and transfer orders and the quantity available in inventory. The list is divided into columns that cover six periods with starting and ending dates as well as the periods before and after those periods. The list is useful when you are planning your inventory purchases.';
            }
            action("Item/Vendor Catalog")
            {
                ApplicationArea = Planning;
                Caption = 'Item/Vendor Catalog';
                Image = "Report";
                RunObject = Report "Item/Vendor Catalog";
                ToolTip = 'View a list of the vendors for the selected items. For each combination of item and vendor, it shows direct unit cost, lead time calculation and the vendor''s item number.';
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                Image = NewItem;
                action("New Item")
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
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        SKU: Record "Stockkeeping Unit";
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        CurrPage.SetSelectionFilter(SKU);
                        PhysInvtCountMgt.UpdateSKUPhysInvtCount(SKU);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';
            }
            group(Category_Item)
            {
                Caption = 'Item';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group("Category_Item Availability by")
            {
                Caption = 'Item Availability by';

                actionref("<Action5>_Promoted"; "<Action5>")
                {
                }
                actionref(Period_Promoted; Period)
                {
                }
                actionref(Lot_Promoted; Lot)
                {
                }
                actionref("Bill of Material_Promoted"; "Bill of Material")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Inventory - List_Promoted"; "Inventory - List")
                {
                }
                actionref("Inventory Availability_Promoted"; "Inventory Availability")
                {
                }
                actionref("Inventory - Availability Plan_Promoted"; "Inventory - Availability Plan")
                {
                }
                actionref("Item/Vendor Catalog_Promoted"; "Item/Vendor Catalog")
                {
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        EnableControls();
    end;

    local procedure EnableControls()
    var
        Item: Record Item;
    begin
        Item.SetLoadFields(Type);
        Item.Get(Rec."Item No.");
        IsNonInventoriable := Item.IsNonInventoriableType();
    end;

    var
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        IsNonInventoriable: Boolean;
}

