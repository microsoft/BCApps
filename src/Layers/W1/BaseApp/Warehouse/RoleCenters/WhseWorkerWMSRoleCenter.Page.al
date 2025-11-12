// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reports;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Automation;
using System.Email;
using System.Threading;
using System.Visualization;
using Microsoft.Foundation.Task;

page 9009 "Whse. Worker WMS Role Center"
{
    Caption = 'Warehouse Worker - Warehouse Management System';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control7; "Headline RC Whse. Worker WMS")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1901138408; "Warehouse Worker Activities")
            {
                ApplicationArea = Warehouse;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Job Queue Tasks Activities"; "Job Queue Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Emails"; "Email Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control6; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part(Control1905989608; "My Items")
            {
                ApplicationArea = Suite;
            }
            part(Control1006; "My Job Queue")
            {
                ApplicationArea = Warehouse;
                Visible = false;
            }
            part(Control4; "Report Inbox Part")
            {
                ApplicationArea = Warehouse;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Warehouse;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Warehouse &Bin List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse &Bin List';
                Image = "Report";
                RunObject = Report "Warehouse Bin List";
                ToolTip = 'Get an overview of warehouse bins, their setup, and the quantity of items within the bins.';
            }
            action("Warehouse A&djustment Bin")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse A&djustment Bin';
                Image = "Report";
                RunObject = Report "Whse. Adjustment Bin";
                ToolTip = 'Get an overview of warehouse bins, their setup, and the quantity of items within the bins.';
            }
            action("Whse. P&hys. Inventory List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Whse. P&hys. Inventory List';
                Image = "Report";
                RunObject = Report "Whse. Phys. Inventory List";
                ToolTip = 'View or print the list of the lines that you have calculated in the Warehouse Physical Inventory Journal window. You can use this report during the physical inventory count to mark down actual quantities on hand in the warehouse and compare them to what is recorded in the program.';
            }
            action("Customer &Labels")
            {
                ApplicationArea = Warehouse;
                Caption = 'Customer &Labels';
                Image = "Report";
                RunObject = Report "Customer - Labels";
                ToolTip = 'View, save, or print mailing labels with the customers'' names and addresses. The report can be used to send sales letters, for example.';
            }
        }
        area(embedding)
        {
            action(Picks)
            {
                ApplicationArea = Warehouse;
                Caption = 'Picks';
                RunObject = Page "Warehouse Picks";
                ToolTip = 'View the list of ongoing warehouse picks. ';
            }
            action("Put-aways")
            {
                ApplicationArea = Warehouse;
                Caption = 'Put-aways';
                RunObject = Page "Warehouse Put-aways";
                ToolTip = 'View the list of ongoing put-aways.';
            }
            action(Movements)
            {
                ApplicationArea = Warehouse;
                Caption = 'Movements';
                RunObject = Page "Warehouse Movements";
                ToolTip = 'View the list of ongoing movements between bins according to an advanced warehouse configuration.';
            }
            action(WhseShpt)
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Shipments';
                RunObject = Page "Warehouse Shipment List";
                ToolTip = 'View the list of ongoing warehouse shipments.';
            }
            action(WhseShptReleased)
            {
                ApplicationArea = Warehouse;
                Caption = 'Released';
                RunObject = Page "Warehouse Shipment List";
                RunPageView = sorting("No.")
                              where(Status = filter(Released));
                ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
            }
            action(WhseShptPartPicked)
            {
                ApplicationArea = Warehouse;
                Caption = 'Partially Picked';
                RunObject = Page "Warehouse Shipment List";
                RunPageView = where("Document Status" = filter("Partially Picked"));
                ToolTip = 'View the list of ongoing warehouse picks that are partially completed.';
            }
            action(WhseShptComplPicked)
            {
                ApplicationArea = Warehouse;
                Caption = 'Completely Picked';
                RunObject = Page "Warehouse Shipment List";
                RunPageView = where("Document Status" = filter("Completely Picked"));
                ToolTip = 'View the list of completed warehouse picks.';
            }
            action(WhseShptPartShipped)
            {
                ApplicationArea = Warehouse;
                Caption = 'Partially Shipped';
                RunObject = Page "Warehouse Shipment List";
                RunPageView = where("Document Status" = filter("Partially Shipped"));
                ToolTip = 'View the list of ongoing warehouse shipments that are partially completed.';
            }
            action(WhseReceipts)
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Receipts';
                RunObject = Page "Warehouse Receipts";
                ToolTip = 'View the list of ongoing warehouse receipts.';
            }
            action(WhseReceiptsPartReceived)
            {
                ApplicationArea = Warehouse;
                Caption = 'Partially Received';
                RunObject = Page "Warehouse Receipts";
                RunPageView = where("Document Status" = filter("Partially Received"));
                ToolTip = 'View the list of ongoing warehouse receipts that are partially completed.';
            }
            action("Transfer Orders")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Orders';
                Image = Document;
                RunObject = Page "Transfer Orders";
                ToolTip = 'Move inventory items between company locations. With transfer orders, you ship the outbound transfer from one location and receive the inbound transfer at the other location. This allows you to manage the involved warehouse activities and provides more certainty that inventory quantities are updated correctly.';
            }
            action("Assembly Orders")
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly Orders';
                RunObject = Page "Assembly Orders";
                ToolTip = 'View ongoing assembly orders.';
            }
            action("Bin Contents")
            {
                ApplicationArea = Warehouse;
                Caption = 'Bin Contents';
                Image = BinContent;
                RunObject = Page "Bin Contents List";
                ToolTip = 'View items in the bin if the selected line contains a bin code.';
            }
        }
        area(sections)
        {
            group("Reference Data")
            {
                Caption = 'Reference Data';
                Image = ReferenceData;
                action(Items)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action(Customers)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customers';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
                action(Vendors)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Vendors';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
                }
                action("Shipping Agents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Shipping Agents';
                    RunObject = Page "Shipping Agents";
                    ToolTip = 'View the list of shipping companies that you use to transport goods.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(WhsePhysInvtJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Physical Inventory Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const("Physical Inventory"));
                    ToolTip = 'Prepare to count inventories by preparing the documents that warehouse employees use when they perform a physical inventory of selected items or of all the inventory. When the physical count has been made, you enter the number of items that are in the bins in this window, and then you register the physical inventory.';
                }
                action("WhseItem Journals")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Item Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const(Item));
                    ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
                }
            }
            group(Worksheet)
            {
                Caption = 'Worksheet';
                Image = Worksheets;
                action(PutawayWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const("Put-away"));
                    ToolTip = 'Plan and initialize item put-aways.';
                }
                action(MovementWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Movement Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const(Movement));
                    ToolTip = 'Plan and initiate movements of items between bins according to an advanced warehouse configuration.';
                }
                action(PickWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const(Pick));
                    ToolTip = 'Plan and initialize picks of items. ';
                }
            }
            group("Registered Documents")
            {
                Caption = 'Registered Documents';
                Image = RegisteredDocs;
                action("Registered Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Picks';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Picks";
                    ToolTip = 'View warehouse picks that have been performed.';
                }
                action("Registered Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Put-aways';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Put-aways";
                    ToolTip = 'View the list of completed put-away activities.';
                }
                action("Registered Movements")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Movements';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Movements";
                    ToolTip = 'View the list of completed warehouse movements.';
                }
                action("Posted Whse. Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Whse. Receipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Whse. Receipt List";
                    ToolTip = 'Open the list of posted warehouse receipts.';
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
        }
        area(processing)
        {
            action("Whse. P&hysical Invt. Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Whse. P&hysical Invt. Journal';
                Image = InventoryJournal;
                RunObject = Page "Whse. Phys. Invt. Journal";
                ToolTip = 'Prepare to count inventories by preparing the documents that warehouse employees use when they perform a physical inventory of selected items or of all the inventory. When the physical count has been made, you enter the number of items that are in the bins in this window, and then you register the physical inventory.';
            }
            action("Whse. Item &Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Whse. Item &Journal';
                Image = BinJournal;
                RunObject = Page "Whse. Item Journal";
                ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
            }
            action("Pick &Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'Pick &Worksheet';
                Image = PickWorksheet;
                RunObject = Page "Pick Worksheet";
                ToolTip = 'Plan and initialize picks of items. ';
            }
            action("Put-&away Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'Put-&away Worksheet';
                Image = PutAwayWorksheet;
                RunObject = Page "Put-away Worksheet";
                ToolTip = 'Plan and initialize item put-aways.';
            }
            action("M&ovement Worksheet")
            {
                ApplicationArea = Warehouse;
                Caption = 'M&ovement Worksheet';
                Image = MovementWorksheet;
                RunObject = Page "Movement Worksheet";
                ToolTip = 'Prepare to move items between bins within the warehouse.';
            }
            action(ItemInquiry)
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Inquiry';
                Image = MovementWorksheet;
                RunObject = Page "Item Inquiry";
                ToolTip = 'View detailed information about an item.';
            }
            action(ItemBinContentInquiry)
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Bin Content Inquiry';
                Image = MovementWorksheet;
                RunObject = Page "Item Bin Content Inquiry";
                ToolTip = 'View detailed information about an item in a bin.';
            }
        }
    }
}

