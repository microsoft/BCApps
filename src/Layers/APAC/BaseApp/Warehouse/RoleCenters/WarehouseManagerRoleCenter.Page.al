// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Reports;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reports;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

page 8909 "Warehouse Manager Role Center"
{
    Caption = 'Warehouse Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Orders & Contacts';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page "Vendor List";
                }
                action("Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    RunObject = page "Purchase Return Order List";
                }
                action("Customers")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                }
                action("Orders1")
                {
                    ApplicationArea = Assembly, Warehouse;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                }
                action("Return Orders1")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = page "Sales Return Order List";
                }
                action("Transfer Orders")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                }
                action("Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                }
                group("Group1")
                {
                    Caption = 'Posted Documents';
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = page "Posted Purchase Invoices";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = page "Posted Purchase Credit Memos";
                    }
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = page "Posted Sales Invoices";
                    }
                    action("Posted Credit Memos1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = page "Posted Sales Credit Memos";
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Return Order Confirmation")
                    {
                        ApplicationArea = SalesReturnOrder, PurchReturnOrder;
                        Caption = 'Return Order Confirmation';
                        RunObject = report "Return Order Confirmation";
                    }
                }
            }
            group("Group3")
            {
                Caption = 'Planning & Operations';
                action("Items")
                {
                    ApplicationArea = Assembly, Warehouse;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = page "Catalog Item List";
                }
                action("Stock keeping Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeeping Units';
                    RunObject = page "Stockkeeping Unit List";
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    RunObject = page "Bin Contents";
                    AccessByPermission = TableData "Bin" = R;
                }
                action("Create Invt. Put-away/Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Invt. Put-away/Pick';
                    RunObject = report "Create Invt Put-away/Pick/Mvmt";
                    AccessByPermission = TableData "Location" = R;
                }
                action("Pick Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Worksheets';
                    RunObject = page "Pick Worksheet";
                }
                action("Put-away Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Worksheets';
                    RunObject = page "Put-away Worksheet";
                }
                action("Movement Worksheets")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Movement Worksheets';
                    RunObject = page "Movement Worksheet";
                }
                action("Internal Movement List")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Internal Movements';
                    RunObject = page "Internal Movement List";
                }
                action("Item Reclass. Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Reclassification Journals';
                    RunObject = page "Item Reclass. Journal";
                }
                action("Item Tracing")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracing';
                    RunObject = page "Item Tracing";
                }
                action("Inventory Receipts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Receipts';
                    RunObject = page "Invt. Receipts";
                    Tooltip = 'Open the Item Receipts page.';
                }
                action("Inventory Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Shipments';
                    RunObject = page "Invt. Shipments";
                    Tooltip = 'Open the Item Shipments page.';
                }
                group("Group4")
                {
                    Caption = 'Warehouse Documents';
                    action("Transfer Orders1")
                    {
                        ApplicationArea = Location;
                        Caption = 'Transfer Orders';
                        RunObject = page "Transfer Orders";
                    }
                    action("Receipts")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Receipts';
                        RunObject = page "Warehouse Receipts";
                    }
                    action("Shipments")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Shipments';
                        RunObject = page "Warehouse Shipment List";
                    }
                    action("Assembly Orders1")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly Orders';
                        RunObject = page "Assembly Orders";
                    }
                }
                group("Group5")
                {
                    Caption = 'Posted Documents';
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = page "Posted Purchase Receipts";
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = page "Posted Return Shipments";
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = page "Posted Sales Shipments";
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = page "Posted Return Receipts";
                    }
                    action("Posted Assembly Orders")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posted Assembly Orders';
                        RunObject = page "Posted Assembly Orders";
                    }
                    action("Posted Transfer Receipts")
                    {
                        ApplicationArea = Location;
                        Caption = 'Posted Transfer Receipts';
                        RunObject = page "Posted Transfer Receipts";
                    }
                    action("Posted Transfer Shipments")
                    {
                        ApplicationArea = Location;
                        Caption = 'Posted Transfer Shipments';
                        RunObject = page "Posted Transfer Shipments";
                    }
                    action("Posted Direct Transfers")
                    {
                        ApplicationArea = Location;
                        Caption = 'Posted Direct Transfers';
                        RunObject = page "Posted Direct Transfers";
                    }
                    action("Posted Receipts")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Whse. Receipts';
                        RunObject = page "Posted Whse. Receipt List";
                    }
                    action("Posted Shipments")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Whse. Shipments';
                        RunObject = page "Posted Whse. Shipment List";
                    }
                    action("Posted Invt. Put-away")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Invt. Put-away';
                        RunObject = page "Posted Invt. Put-away List";
                    }
                    action("Posted Invt. Pick")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Posted Invt. Pick';
                        RunObject = page "Posted Invt. Pick List";
                    }
                    action("Posted Invt. Receipts")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Inventory Receipts';
                        RunObject = page "Posted Invt. Receipts";
                        Tooltip = 'Open the Posted Inventory Receipts page.';
                    }
                    action("Posted Invt. Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Inventory Shipments';
                        RunObject = page "Posted Invt. Shipments";
                        Tooltip = 'Open the Posted Inventory Shipments page.';
                    }
                }
                group("Group6")
                {
                    Caption = 'Registers/Entries';
                    action("Registered Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Put-aways';
                        RunObject = page "Registered Whse. Put-aways";
                    }
                    action("Registered Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Picks';
                        RunObject = page "Registered Whse. Picks";
                    }
                    action("Registered Movement")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Movements';
                        RunObject = page "Registered Whse. Movements";
                    }
                    action("Page7386")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Registered Invt. Movement';
                        RunObject = page "Registered Invt. Movement List";
                    }
                    action("Registers")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Registers';
                        RunObject = page "Warehouse Registers";
                    }
                    action("Item Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Registers';
                        RunObject = page "Item Registers";
                    }
                    action("Item Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Ledger Entries';
                        RunObject = page "Item Ledger Entries";
                    }
                    action("Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Physical Inventory Ledger Entries';
                        RunObject = page "Phys. Inventory Ledger Entries";
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
                    }
                    action("Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Entries';
                        RunObject = page "Warehouse Entries";
                    }
                    action("Navi&gate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        Image = Navigate;
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
                group("Group7")
                {
                    Caption = 'Reports';
                    action("Whse. Shipment Status")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment Status';
                        RunObject = report "Whse. Shipment Status";
                    }
                    action("Customer - List")
                    {
                        ApplicationArea = Basic, Suite, Warehouse;
                        Caption = 'Customer - List';
                        RunObject = report "Customer - List";
                    }
                    action("Inventory Picking List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Picking List';
                        RunObject = report "Inventory Picking List";
                        AccessByPermission = TableData "Location" = R;
                    }
                    action("Item Expiration - Quantity")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Expiration - Quantity';
                        RunObject = report "Item Expiration - Quantity";
                    }
                }
            }
            group("Group8")
            {
                Caption = 'Goods Handling';
                group("Group9")
                {
                    Caption = 'Order by Order';
                    action("Inventory Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Put-aways';
                        RunObject = page "Inventory Put-aways";
                    }
                    action("Inventory Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Picks';
                        RunObject = page "Inventory Picks";
                    }
                    action("Page9330")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Movements';
                        RunObject = page "Inventory Movements";
                    }
                }
                group("Group10")
                {
                    Caption = 'Multiple Orders';
                    action("Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Put-aways';
                        RunObject = page "Warehouse Put-aways";
                    }
                    action("Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Picks';
                        RunObject = page "Warehouse Picks";
                    }
                    action("Movements")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Movements';
                        RunObject = page "Warehouse Movements";
                    }
                    action("Internal Picks")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Internal Picks';
                        RunObject = page "Whse. Internal Pick List";
                    }
                    action("Internal Put-aways")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Internal Put-aways';
                        RunObject = page "Whse. Internal Put-away List";
                    }
                }
                group("Group11")
                {
                    Caption = 'Bins';
                    action("Bin Contents1")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Contents';
                        RunObject = page "Bin Contents";
                        AccessByPermission = TableData "Bin" = R;
                    }
                    action("Bin Creation Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Creation Worksheet';
                        RunObject = page "Bin Creation Worksheet";
                        AccessByPermission = TableData "Bin" = R;
                    }
                    action("Bin Content Creation Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Content Creation Worksheet';
                        RunObject = page "Bin Content Creation Worksheet";
                        AccessByPermission = TableData "Bin" = R;
                    }
                }
                group("Group12")
                {
                    Caption = 'Journals';
                    action("Whse. Item Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Item Journals';
                        RunObject = page "Whse. Item Journal";
                    }
                    action("Item Reclass. Journals1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = page "Item Reclass. Journal";
                    }
                    action("Whse. Reclass. Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Reclass. Journals';
                        RunObject = page "Whse. Reclassification Journal";
                    }
                    action("Whse. Phys. Invt. Journals")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Phys. Invt. Journals';
                        RunObject = page "Whse. Phys. Invt. Journal";
                    }
                }
                group("Group13")
                {
                    Caption = 'Reports';
                    action("Whse. Shipment Status1")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment Status';
                        RunObject = report "Whse. Shipment Status";
                    }
                    action("Customer - List1")
                    {
                        ApplicationArea = Basic, Suite, Warehouse;
                        Caption = 'Customer - List';
                        RunObject = report "Customer - List";
                    }
                    action("Customer - Labels")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Customer Labels';
                        RunObject = report "Customer - Labels";
                    }
                    action("Whse. Phys. Inventory List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Phys. Inventory List';
                        RunObject = report "Whse. Phys. Inventory List";
                    }
                    action("Warehouse Register - Quantity")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Register - Quantity';
                        RunObject = report "Warehouse Register - Quantity";
                        AccessByPermission = TableData "Location" = R;
                    }
                    action("Warehouse Bin List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Bin List';
                        RunObject = report "Warehouse Bin List";
                    }
                    action("Whse. Adjustment Bin")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Adjustment Bin';
                        RunObject = report "Whse. Adjustment Bin";
                        AccessByPermission = TableData "Bin" = R;
                    }
                    action("Inventory Put-away List")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Inventory Put-away List';
                        RunObject = report "Inventory Put-away List";
                        AccessByPermission = TableData "Location" = R;
                    }
                    action("Warehouse Movement")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Warehouse Movement';
                        RunObject = report "Movement List";
                        AccessByPermission = TableData "Location" = R;
                    }
                    action("Whse. - Posted Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Posted Receipt';
                        RunObject = report "Whse. - Posted Receipt";
                    }
                    action("Whse. - Posted Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Posted Shipment';
                        RunObject = report "Whse. - Posted Shipment";
                    }
                    action("Whse. - Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Receipt';
                        RunObject = report "Whse. - Receipt";
                    }
                    action("Whse. - Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Shipment';
                        RunObject = report "Whse. - Shipment";
                    }
                }
            }
            group("Group14")
            {
                Caption = 'Inventory';
                action("Phys. Invt. Counting Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Physical Inventory Counting Periods';
                    RunObject = page "Phys. Invt. Counting Periods";
                }
                action("Item Journal")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Journals';
                    RunObject = page "Item Journal";
                }
                action("Item Reclass. Journals2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Reclassification Journals';
                    RunObject = page "Item Reclass. Journal";
                }
                action("Phys. Inventory Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Physical Inventory Journals';
                    RunObject = page "Phys. Inventory Journal";
                }
                action("Revaluation Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Revaluation Journals';
                    RunObject = page "Revaluation Journal";
                }
                group("Group15")
                {
                    Caption = 'Setup';
                    action("Inventory Setup")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
                    }
                    action("Assembly Setup")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assembly Setup';
                        RunObject = page "Assembly Setup";
                    }
                    action("Locations")
                    {
                        ApplicationArea = Location;
                        Caption = 'Locations';
                        RunObject = page "Location List";
                    }
                    action("Item Tracking Codes")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracking Codes';
                        RunObject = page "Item Tracking Codes";
                    }
                    action("Item Journal Templates")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journal Templates';
                        RunObject = page "Item Journal Templates";
                    }
                    action("Nonstock Item Setup")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Nonstock Item Setup';
                        RunObject = page "Catalog Item Setup";
                    }
                    action("Transfer Routes")
                    {
                        ApplicationArea = Location;
                        Caption = 'Transfer Routes';
                        RunObject = page "Transfer Routes";
                    }
                    action("Create Stockkeeping Unit")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Create Stockkeeping Unit';
                        RunObject = report "Create Stockkeeping Unit";
                    }
                    action("Report Selections Inventory")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Selections Inventory';
                        RunObject = page "Report Selection - Inventory";
                    }
                }
                group("Reports")
                {
                    Caption = 'Reports';
                    action("Inventory by Location")
                    {
                        ApplicationArea = InventoryAnalysis;
                        Caption = 'Analyze Inventory by Location';
                        RunObject = Query "Inventory by Location";
                        ToolTip = 'Analyze (group, summarize, pivot) your Item Ledger Entries with related Location master data.';
                    }
                }
            }
            group("Group16")
            {
                Caption = 'Assembly';
                action("Items1")
                {
                    ApplicationArea = Assembly, Warehouse;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Resources")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Resources';
                    RunObject = page "Resource List";
                }
                action("Assembly Orders2")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                }
                action("Orders3")
                {
                    ApplicationArea = Assembly, Warehouse;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                }
                action("Planning Worksheets")
                {
                    ApplicationArea = Planning;
                    Caption = 'Planning Worksheets';
                    RunObject = page "Planning Worksheet";
                }
                action("Assembly Setup1")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Setup';
                    RunObject = page "Assembly Setup";
                }
                group("Group17")
                {
                    Caption = 'Posted Documents';
                    action("Posted Assembly Orders1")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Posted Assembly Orders';
                        RunObject = page "Posted Assembly Orders";
                    }
                }
                group("Group18")
                {
                    Caption = 'Reports';
                    action("Assemble to Order - Sales")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Assemble to Order - Sales';
                        RunObject = report "Assemble to Order - Sales";
                    }
                    action("Item - Able to Make (Timeline)")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Item - Able to Make (Timeline)';
                        RunObject = report "Item - Able to Make (Timeline)";
                    }
                    action("BOM Cost Share Distribution")
                    {
                        ApplicationArea = Assembly;
                        Caption = 'BOM Cost Share Distribution';
                        RunObject = report "BOM Cost Share Distribution";
                    }
                    group("Group19")
                    {
                        Caption = 'Assembly BOM';
                        action("Where-Used List")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Where-Used List';
                            RunObject = report "Where-Used List";
                        }
                        action("Assembly BOMs")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOMs';
                            RunObject = report "Assembly BOMs";
                        }
                        action("Assembly BOM - Raw Materials")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - Raw Materials';
                            RunObject = report "Assembly BOM - Raw Materials";
                        }
                        action("Assembly BOM - Sub-Assemblies")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - Subassemblies';
                            RunObject = report "Assembly BOM - Subassemblies";
                        }
                        action("Assembly BOM - Finished Goods")
                        {
                            ApplicationArea = Assembly;
                            Caption = 'Assembly BOM - End Items';
                            RunObject = report "Assembly BOM - End Items";
                        }
                    }
                }
            }
            group("Group20")
            {
                Caption = 'Warehouse';
                action("Bin Types")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Types';
                    RunObject = page "Bin Types";
                    AccessByPermission = TableData "Bin" = R;
                }
                action("Warehouse Classes")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Classes';
                    RunObject = page "Warehouse Classes";
                }
                action("Special Equipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Special Equipment';
                    RunObject = page "Special Equipment";
                }
                action("Warehouse Employees")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Employees';
                    RunObject = page "Warehouse Employees";
                }
                action("Warehouse Setup")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Setup';
                    RunObject = page "Warehouse Setup";
                }
                action("Locations1")
                {
                    ApplicationArea = Location;
                    Caption = 'Locations';
                    RunObject = page "Location List";
                }
                group("Group21")
                {
                    Caption = 'Templates';
                    action("Bin Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Templates';
                        RunObject = page "Bin Templates";
                        AccessByPermission = TableData "Bin" = R;
                    }
                    action("Put-away Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Put-away Templates';
                        RunObject = page "Put-away Template List";
                    }
                    action("Bin Creation Worksheet Templat")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Bin Creation Worksheet Templates';
                        RunObject = page "Bin Creation Wksh. Templates";
                        AccessByPermission = TableData "Bin" = R;
                    }
                    action("Whse. Journal Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Journal Templates';
                        RunObject = page "Whse. Journal Templates";
                    }
                    action("Whse. Worksheet Templates")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Whse. Worksheet Templates';
                        RunObject = page "Whse. Worksheet Templates";
                    }
                }
                group("Group22")
                {
                    Caption = 'ADCS';
                    action("ADCS Users")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'ADCS Users';
                        RunObject = page "ADCS Users";
                    }
                    action("Miniforms")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Miniforms';
                        RunObject = page "Miniforms";
                    }
                    action("Miniform Functions Group")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Miniform Functions Group';
                        RunObject = page "Functions";
                    }
                }
            }
        }
    }
}
