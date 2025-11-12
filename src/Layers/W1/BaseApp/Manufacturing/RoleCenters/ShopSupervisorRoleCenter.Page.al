// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Foundation.Task;
using System.Threading;

page 9012 "Shop Supervisor Role Center"
{
    Caption = 'Shop Supervisor - Manufacturing Comprehensive';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1905423708; "Shop Supervisor Activities")
            {
                ApplicationArea = Manufacturing;
            }
            part("User Tasks Activities"; "User Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part("Job Queue Tasks Activities"; "Job Queue Tasks Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control1905989608; "My Items")
            {
                ApplicationArea = Manufacturing;
            }
            part(Control1; "My Job Queue")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            part(Control3; "Report Inbox Part")
            {
                ApplicationArea = Manufacturing;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Manufacturing;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Routing &Sheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routing &Sheet';
                Image = "Report";
                RunObject = Report "Routing Sheet";
                ToolTip = 'View basic information for routings, such as send-ahead quantity, setup time, run time and time unit. This report shows you the operations to be performed in this routing, the work or machine centers to be used, the personnel, the tools, and the description of each operation.';
            }
            separator(Action51)
            {
            }
            action("Inventory - &Availability Plan")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Inventory - &Availability Plan';
                Image = ItemAvailability;
                RunObject = Report "Inventory - Availability Plan";
                ToolTip = 'View a list of the quantity of each item in customer, purchase, and transfer orders and the quantity available in inventory. The list is divided into columns that cover six periods with starting and ending dates as well as the periods before and after those periods. The list is useful when you are planning your inventory purchases.';
            }
            separator(Action53)
            {
            }
            action("Capacity Tas&k List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Capacity Tas&k List';
                Image = "Report";
                RunObject = Report "Capacity Task List";
                ToolTip = 'View the production orders that are waiting to be processed at the work centers and machine centers. Printouts are made for the capacity of the work center or machine center. The report includes information such as starting and ending time, date per production order and input quantity.';
            }
            action("Subcontractor - Dis&patch List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontractor - Dis&patch List';
                Image = "Report";
                RunObject = Report "Subcontractor - Dispatch List";
                ToolTip = 'View the list of material to be sent to manufacturing subcontractors.';
            }
            separator(Action42)
            {
            }
#if not CLEAN27
            action("Production Order Ca&lculation")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order Ca&lculation (Obsolete)';
                Image = "Report";
                RunObject = Report "Prod. Order - Calculation";
                ToolTip = 'View a list of the production orders and their costs. Expected Operation Costs, Expected Component Costs and Total Costs are printed.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report has been replaced by the "Production Order Statistics" report and will be removed in a future release.';
                ObsoleteTag = '27.0';
            }
#endif
            action("Production Order Statistics")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order Statistics';
                Image = "Report";
                RunObject = report "Production Order Statistics";
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
            }
            action("S&tatus")
            {
                ApplicationArea = Manufacturing;
                Caption = 'S&tatus';
                Image = "Report";
                RunObject = Report Status;
                ToolTip = 'View production orders by status.';
            }
        }
        area(embedding)
        {
            action("Simulated Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Simulated Production Orders';
                RunObject = Page "Simulated Production Orders";
                ToolTip = 'View the list of ongoing simulated production orders.';
            }
            action("Planned Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Planned Production Orders';
                RunObject = Page "Planned Production Orders";
                ToolTip = 'View the list of production orders with status Planned.';
            }
            action("Firm Planned Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Firm Planned Production Orders';
                RunObject = Page "Firm Planned Prod. Orders";
                ToolTip = 'View completed production orders. ';
            }
            action("Released Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Orders';
                RunObject = Page "Released Production Orders";
                ToolTip = 'View the list of released production order that are ready for warehouse activities.';
            }
            action("Finished Production Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Finished Production Orders';
                RunObject = Page "Finished Production Orders";
                ToolTip = 'View completed production orders. ';
            }
            action(Routings)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routings';
                RunObject = Page "Routing List";
                ToolTip = 'View or edit operation sequences and process times for produced items.';
            }
            action("Registered Absence")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Registered Absence';
                RunObject = Page "Registered Absences";
                ToolTip = 'View absence hours for work or machine centers.';
            }
            action(Items)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(ItemsProduced)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Produced';
                RunObject = Page "Item List";
                RunPageView = where("Replenishment System" = const("Prod. Order"));
                ToolTip = 'View the list of production items.';
            }
            action(ItemsRawMaterials)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Raw Materials';
                RunObject = Page "Item List";
                RunPageView = where("Low-Level Code" = filter(> 0),
                                    "Replenishment System" = const(Purchase),
                                    "Production BOM No." = filter(= ''));
                ToolTip = 'View the list of items that are not bills of material.';
            }
            action("Stockkeeping Units")
            {
                ApplicationArea = Warehouse;
                Caption = 'Stockkeeping Units';
                Image = SKU;
                RunObject = Page "Stockkeeping Unit List";
                ToolTip = 'Open the list of item SKUs to view or edit instances of item at different locations or with different variants. ';
            }
            action("Sales Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action("Purchase Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action("Transfer Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Transfer Orders';
                Image = Document;
                RunObject = Page "Transfer Orders";
                ToolTip = 'Move inventory items between company locations. With transfer orders, you ship the outbound transfer from one location and receive the inbound transfer at the other location. This allows you to manage the involved warehouse activities and provides more certainty that inventory quantities are updated correctly.';
            }
            action("Work Centers")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Centers';
                RunObject = Page "Work Center List";
                ToolTip = 'View or edit the list of work centers.';
            }
            action("Machine Centers")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Machine Centers';
                RunObject = Page "Machine Center List";
                ToolTip = 'View the list of machine centers.';
            }
            action("Inventory Put-aways")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Put-aways';
                RunObject = Page "Inventory Put-aways";
                ToolTip = 'View ongoing put-aways of items to bins according to a basic warehouse configuration. ';
            }
            action("Inventory Picks")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory Picks';
                RunObject = Page "Inventory Picks";
                ToolTip = 'View ongoing picks of items from bins according to a basic warehouse configuration. ';
            }
            action(RequisitionWorksheets)
            {
                ApplicationArea = Planning;
                Caption = 'Requisition Worksheets';
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const("Req."),
                                    Recurring = const(false));
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action(SubcontractingWorksheets)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Worksheets';
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const("For. Labor"),
                                    Recurring = const(false));
                ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
            }
        }
        area(sections)
        {
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(ConsumptionJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Consumption Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Consumption),
                                        Recurring = const(false));
                    ToolTip = 'Post the consumption of material as operations are performed.';
                }
                action(OutputJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Output Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Output),
                                        Recurring = const(false));
                    ToolTip = 'Post finished end items and time spent in production. ';
                }
                action(CapacityJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Capacity),
                                        Recurring = const(false));
                    ToolTip = 'Post consumed capacities that are not assigned to the production order. For example, maintenance work must be assigned to capacity, but not to a production order.';
                }
                action(RecurringCapacityJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Recurring Capacity Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Capacity),
                                        Recurring = const(true));
                    ToolTip = 'Post consumed capacities that are not posted as part of production order output, such as maintenance work.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                Image = Administration;
                action("Work Shifts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Shifts';
                    RunObject = Page "Work Shifts";
                    ToolTip = 'View or edit the work shifts that can be assigned to shop calendars.';
                }
                action("Shop Calendars")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Shop Calendars';
                    RunObject = Page "Shop Calendars";
                    ToolTip = 'View or edit the list of machine or work center calendars.';
                }
                action("Capacity Constrained Resources")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Constrained Resources';
                    RunObject = Page "Capacity Constrained Resources";
                    ToolTip = 'Define the finite loading of a work center or machine center. You must set up production resources that you regard as critical and mark them to accept a finite load instead of the default infinite load that other production resources accept.';
                }
                action("Work Center Groups")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Center Groups';
                    RunObject = Page "Work Center Groups";
                    ToolTip = 'View or edit the list of work center groups.';
                }
                action("Stop Codes")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Stop Codes';
                    RunObject = Page "Stop Codes";
                    ToolTip = 'View or edit codes to identify different machine or shop center failure reasons, which you can post with output journal and capacity journal lines.';
                }
                action("Scrap Codes")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Scrap Codes';
                    RunObject = Page "Scrap Codes";
                    ToolTip = 'Define scrap codes to identify different reasons for why scrap has been produced. After you have set up the scrap codes, you can enter them in the posting lines of the output journal and the capacity journal.';
                }
                action("Standard Tasks")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Standard Tasks';
                    RunObject = Page "Standard Tasks";
                    ToolTip = 'View or edit standard production operations.';
                }
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Consumptio&n Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Consumptio&n Journal';
                Image = ConsumptionJournal;
                RunObject = Page "Consumption Journal";
                ToolTip = 'Post the consumption of material as operations are performed.';
            }
            action("Output &Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Output &Journal';
                Image = OutputJournal;
                RunObject = Page "Output Journal";
                ToolTip = 'Post finished end items and time spent in production. ';
            }
            action("&Capacity Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Capacity Journal';
                Image = CapacityJournal;
                RunObject = Page "Capacity Journal";
                ToolTip = 'Post consumed capacities that are not posted as part of production order output, such as maintenance work.';
            }
            separator(Action27)
            {
            }
            action("Change &Production Order Status")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Change &Production Order Status';
                Image = ChangeStatus;
                RunObject = Page "Change Production Order Status";
                ToolTip = 'Change the production order to another status, such as Released.';
            }
            separator(Action55)
            {
            }
            action("Update &Unit Cost")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Update &Unit Cost';
                Image = UpdateUnitCost;
                RunObject = Report "Update Unit Cost";
                ToolTip = 'Recalculate the unit cost of production items on production orders. The value in the Unit Cost field on the production order line is updated according to the selected options.';
            }
            separator(Action84)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("&Manufacturing Setup")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Manufacturing Setup';
                Image = ProductionSetup;
                RunObject = Page "Manufacturing Setup";
                ToolTip = 'Define company policies for manufacturing, such as the default safety lead time and whether warnings are displayed in the planning worksheet.';
            }
            separator(History)
            {
                Caption = 'History';
                IsHeader = true;
            }
            action("Item &Tracing")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Item &Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a serial, lot or package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
            action("Navi&gate")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Find entries...';
                Image = Navigate;
                RunObject = Page Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
            }
        }
    }
}
