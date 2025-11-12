// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Document;
using System.Automation;
using System.Email;
using System.Integration.PowerBI;
using Microsoft.Foundation.Task;
using System.Threading;
using System.Visualization;

page 9010 "Production Planner Role Center"
{
    Caption = 'Manufacturing Manager';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control45; "Headline RC Prod. Planner")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1905113808; "Production Planner Activities")
            {
                ApplicationArea = Manufacturing;
            }
            part("Machine Operator Activities"; "Machine Operator Activities")
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
            part("Emails"; "Email Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = Suite;
            }
            part(Control58; "Team Member Activities No Msgs")
            {
                ApplicationArea = Suite;
            }
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                AccessByPermission = TableData "Power BI Context Settings" = I;
                ApplicationArea = Basic, Suite;
            }
            part(Control54; "My Job Queue")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            part(Control1905989608; "My Items")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control55; "Report Inbox Part")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
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
            group(Capacity)
            {
                Caption = 'Capacity';
                action("Routing Sheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Routing Sheet';
                    Image = "Report";
                    RunObject = Report "Routing Sheet";
                    ToolTip = 'View basic information for routings, such as send-ahead quantity, setup time, run time and time unit. This report shows you the operations to be performed in this routing, the work or machine centers to be used, the personnel, the tools, and the description of each operation.';
                }
                action("Inventory - &Availability Plan")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Inventory - &Availability Plan';
                    Image = ItemAvailability;
                    RunObject = Report "Inventory - Availability Plan";
                    ToolTip = 'View a list of the quantity of each item in customer, purchase, and transfer orders and the quantity available in inventory. The list is divided into columns that cover six periods with starting and ending dates as well as the periods before and after those periods. The list is useful when you are planning your inventory purchases.';
                }
#if not CLEAN27
                action("Planning Availability")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Planning Availability (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Planning Availability";
                    ToolTip = 'View all known existing requirements and receipts for the items that you select on a specific date. You can use the report to get a quick picture of the current demand-supply situation for an item. The report displays the item number and description plus the actual quantity in inventory.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report has been deprecated and will be removed in a future release.';
                    ObsoleteTag = '27.0';
                }
#endif
                action("Capacity Task List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Task List';
                    Image = "Report";
                    RunObject = Report "Capacity Task List";
                    ToolTip = 'View the production orders that are waiting to be processed at the work centers and machine centers. Printouts are made for the capacity of the work center or machine center). The report includes information such as starting and ending time, date per production order and input quantity.';
                }
                action("Subcontractor - Dispatch List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontractor - Dispatch List';
                    Image = "Report";
                    RunObject = Report "Subcontractor - Dispatch List";
                    ToolTip = 'View the list of material to be sent to manufacturing subcontractors.';
                }
            }
            group(Production)
            {
                Caption = 'Production';
                action("Production Order - &Shortage List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production Order - &Shortage List';
                    Image = "Report";
                    RunObject = Report "Prod. Order - Shortage List";
                    ToolTip = 'View a list of the missing quantity per production order. The report shows how the inventory development is planned from today until the set day - for example whether orders are still open.';
                }
                action("D&etailed Calculation")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'D&etailed Calculation';
                    Image = "Report";
                    RunObject = Report "Detailed Calculation";
                    ToolTip = 'View a cost list per item taking into account the scrap.';
                }
#if not CLEAN27
                action("P&roduction Order - Calculation")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'P&roduction Order - Calculation (Obsolete)';
                    Image = "Report";
                    RunObject = Report "Prod. Order - Calculation";
                    ToolTip = 'View a list of the production orders and their costs, such as expected operation costs, expected component costs, and total costs.';
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
                action("Sta&tus")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Sta&tus';
                    Image = "Report";
                    RunObject = Report Status;
                    ToolTip = 'View production orders by status.';
                }
                action("Inventory &Valuation WIP")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Inventory &Valuation WIP';
                    Image = "Report";
                    RunObject = Report "Inventory Valuation - WIP";
                    ToolTip = 'View inventory valuation for selected production orders in your WIP inventory. The report also shows information about the value of consumption, capacity usage and output in WIP.';
                }
                action("Prod. Order - &Job Card")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Prod. Order - &Job Card';
                    Image = "Report";
                    RunObject = Report "Prod. Order - Job Card";
                    ToolTip = 'View a list of the work in progress of a production order. Output, Scrapped Quantity and Production Lead Time are shown or printed depending on the operation.';
                }
            }
        }
        area(embedding)
        {
            action("Demand Forecast")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Demand Forecast';
                RunObject = Page "Demand Forecast Names";
                ToolTip = 'View or edit a demand forecast for your sales items, components, or both.';
            }
            action("Transfer Orders")
            {
                ApplicationArea = Location;
                Caption = 'Transfer Orders';
                Image = Document;
                RunObject = Page "Transfer Orders";
                ToolTip = 'Move inventory items between company locations. With transfer orders, you ship the outbound transfer from one location and receive the inbound transfer at the other location. This allows you to manage the involved warehouse activities and provides more certainty that inventory quantities are updated correctly.';
            }
        }
        area(sections)
        {
            group("Production Orders")
            {
                Caption = 'Production Orders';
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
            }
            group("Sales & Purchases")
            {
                Caption = 'Sales & Purchases';
                action("Blanket Sales Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Blanket Sales Orders';
                    RunObject = Page "Blanket Sales Orders";
                    ToolTip = 'Use blanket sales orders as a framework for a long-term agreement between you and your customers to sell large quantities that are to be delivered in several smaller shipments over a certain period of time. Blanket orders often cover only one item with predetermined delivery dates. The main reason for using a blanket order rather than a sales order is that quantities entered on a blanket order do not affect item availability and thus can be used as a worksheet for monitoring, forecasting, and planning purposes..';
                }
                action("Sales Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Sales Orders';
                    Image = "Order";
                    RunObject = Page "Sales Order List";
                    ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
                }
                action("Blanket Purchase Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Blanket Purchase Orders';
                    RunObject = Page "Blanket Purchase Orders";
                    ToolTip = 'Use blanket purchase orders as a framework for a long-term agreement between you and your vendors to buy large quantities that are to be delivered in several smaller shipments over a certain period of time. Blanket orders often cover only one item with predetermined delivery dates. The main reason for using a blanket order rather than a purchase order is that quantities entered on a blanket order do not affect item availability and thus can be used as a worksheet for monitoring, forecasting, and planning purposes..';
                }
                action("Purchase Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                    ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
                }
            }
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
                action(ItemJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Item),
                                        Recurring = const(false));
                    ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
                }
                action(ItemReclassificationJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item Reclassification Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Transfer),
                                        Recurring = const(false));
                    ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Serial, lot or package numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
                }
                action(RevaluationJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Revaluation Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Revaluation),
                                        Recurring = const(false));
                    ToolTip = 'Change the inventory value of items, for example after doing a physical inventory.';
                }
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
                action(RecurringConsumptionJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Recurring Consumption Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Consumption),
                                        Recurring = const(true));
                    ToolTip = 'Post the consumption of material as operations are performed.';
                }
                action(RecurringOutputJournals)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Recurring Output Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Output),
                                        Recurring = const(true));
                    ToolTip = 'View all recurring output journals.';
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
            group(Worksheets)
            {
                Caption = 'Worksheets';
                Image = Worksheets;
                action(PlanningWorksheets)
                {
                    ApplicationArea = Planning;
                    Caption = 'Planning Worksheets';
                    RunObject = Page "Req. Wksh. Names";
                    RunPageView = where("Template Type" = const(Planning),
                                        Recurring = const(false));
                    ToolTip = 'Plan supply orders automatically to fulfill new demand.';
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
                action("Standard Cost Worksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Standard Cost Worksheet';
                    RunObject = Page "Standard Cost Worksheet Names";
                    ToolTip = 'Review or update standard costs. Purchasers, production or assembly managers can use the worksheet to simulate the effect on the cost of the manufactured or assembled item if the standard cost for consumption, production capacity usage, or assembly resource usage is changed. You can set a cost change to take effect on a specified date.';
                }
            }
            group("Product Design")
            {
                Caption = 'Product Design';
                Image = ProductDesign;
                action(ProductionBOM)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    Image = BOM;
                    RunObject = Page "Production BOM List";
                    ToolTip = 'Open the item''s production bill of material to view or edit its components.';
                }
                action(ProductionBOMCertified)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Certified';
                    RunObject = Page "Production BOM List";
                    RunPageView = where(Status = const(Certified));
                    ToolTip = 'View the list of certified production BOMs.';
                }
                action(ProductionBOMUnderDevelopment)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Under Development';
                    RunObject = Page "Production BOM List";
                    RunPageView = where(Status = const("Under Development"));
                    ToolTip = 'View the list of production BOMs that are not yet certified.';
                }
                action(Routings)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Routings';
                    Image = Route;
                    RunObject = Page "Routing List";
                    ToolTip = 'View or edit operation sequences and process times for produced items.';
                }
                action("Routing Links")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Routing Links';
                    RunObject = Page "Routing Links";
                    ToolTip = 'View or edit links that are set up between production BOM lines and routing lines to ensure just-in-time flushing of components.';
                }
                action("Standard Tasks")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Standard Tasks';
                    Image = TaskList;
                    RunObject = Page "Standard Tasks";
                    ToolTip = 'View or edit standard production operations.';
                }
                action(Families)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Families';
                    RunObject = Page "Family List";
                    ToolTip = 'View or edit a grouping of production items whose relationship is based on the similarity of their manufacturing processes. By forming production families, some items can be manufactured twice or more in one production, which will optimize material consumption.';
                }
                action(ProdDesign_Items)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action(ProdDesign_ItemsProduced)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Produced';
                    RunObject = Page "Item List";
                    RunPageView = where("Replenishment System" = const("Prod. Order"));
                    ToolTip = 'View the list of production items.';
                }
                action(ProdDesign_ItemsRawMaterials)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Raw Materials';
                    RunObject = Page "Item List";
                    RunPageView = where("Low-Level Code" = filter(> 0),
                                        "Replenishment System" = const(Purchase));
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
            }
            group(Capacities)
            {
                Caption = 'Capacities';
                Image = Capacities;
                action(WorkCenters)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Work Centers';
                    Image = WorkCenter;
                    RunObject = Page "Work Center List";
                    ToolTip = 'View or edit the list of work centers.';
                }
                action(WorkCentersInternal)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Internal';
                    Image = Comment;
                    RunObject = Page "Work Center List";
                    RunPageView = where("Subcontractor No." = filter(= ''));
                    ToolTip = 'View or register internal comments for the service item. Internal comments are for internal use only and are not printed on reports.';
                }
                action(WorkCentersSubcontracted)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracted';
                    RunObject = Page "Work Center List";
                    RunPageView = where("Subcontractor No." = filter(<> ''));
                    ToolTip = 'View the list of ongoing purchase orders for subcontracted production orders.';
                }
                action("Machine Centers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Machine Centers';
                    Image = MachineCenter;
                    RunObject = Page "Machine Center List";
                    ToolTip = 'View the list of machine centers.';
                }
                action("Registered Absence")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Registered Absence';
                    Image = Absence;
                    RunObject = Page "Registered Absences";
                    ToolTip = 'View absence hours for work or machine centers.';
                }
                action(Vendors)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Vendors';
                    Image = Vendor;
                    RunObject = Page "Vendor List";
                    ToolTip = 'View or edit detailed information for the vendors that you trade with. From each vendor card, you can open related information, such as purchase statistics and ongoing orders, and you can define special prices and line discounts that the vendor grants you if certain conditions are met.';
                }
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


            }
        }
        area(creation)
        {
            action("&Item")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Item';
                Image = Item;
                RunObject = Page "Item Card";
                RunPageMode = Create;
                ToolTip = 'Create a new item.';
            }
            action("Production &Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Planned Production &Order';
                Image = "Order";
                RunObject = Page "Planned Production Order";
                RunPageMode = Create;
                ToolTip = 'Create a new planned production order to supply a produced item.';
            }
            action("Firm Planned Production Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Firm Planned Production Order';
                RunObject = Page "Firm Planned Prod. Order";
                RunPageMode = Create;
                ToolTip = 'Create a new firm planned production order to supply a produced item.';
            }
            action("Released Production Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Order';
                RunObject = Page "Released Production Order";
                RunPageMode = Create;
                ToolTip = 'Create a new released production order to supply a produced item.';
            }
            action("Production &BOM")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production &BOM';
                Image = BOM;
                RunObject = Page "Production BOM";
                RunPageMode = Create;
                ToolTip = 'Create a new bill of material for a produced item.';
            }
            action("&Routing")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Routing';
                Image = Route;
                RunObject = Page Routing;
                RunPageMode = Create;
                ToolTip = 'Create a routing defining the operations that are required to produce an end item.';
            }
            action("&Purchase Order")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageMode = Create;
                ToolTip = 'Purchase goods or services from a vendor.';
            }
        }
        area(processing)
        {
            group(Tasks)
            {
                Caption = 'Tasks';
                action("Item &Journal")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Item &Journal';
                    Image = Journals;
                    RunObject = Page "Item Journal";
                    ToolTip = 'Adjust the physical quantity of items on inventory.';
                }
                action("Re&quisition Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Re&quisition Worksheet';
                    Image = Worksheet;
                    RunObject = Page "Req. Worksheet";
                    ToolTip = 'Plan supply orders automatically to fulfill new demand. This worksheet can plan purchase and transfer orders only.';
                }
                action("Planning Works&heet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Planning Works&heet';
                    Image = PlanningWorksheet;
                    RunObject = Page "Planning Worksheet";
                    ToolTip = 'Plan supply orders automatically to fulfill new demand.';
                }
                action("Subcontracting &Worksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting &Worksheet';
                    Image = SubcontractingWorksheet;
                    RunObject = Page "Subcontracting Worksheet";
                    ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
                }
                action("Change Pro&duction Order Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change Pro&duction Order Status';
                    Image = ChangeStatus;
                    RunObject = Page "Change Production Order Status";
                    ToolTip = 'Change the production order to another status, such as Released.';
                }
                action("Order Pla&nning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Pla&nning';
                    Image = Planning;
                    RunObject = Page "Order Planning";
                    ToolTip = 'Plan supply orders order by order to fulfill new demand.';
                }
            }
            group(Administration)
            {
                Caption = 'Administration';
                action("Order Promising S&etup")
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Order Promising S&etup';
                    Image = OrderPromisingSetup;
                    RunObject = Page "Order Promising Setup";
                    ToolTip = 'Configure your company''s policies for calculating delivery dates.';
                }
                action("&Manufacturing Setup")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Manufacturing Setup';
                    Image = ProductionSetup;
                    RunObject = Page "Manufacturing Setup";
                    ToolTip = 'Define company policies for manufacturing, such as the default safety lead time and whether warnings are displayed in the planning worksheet.';
                }
            }
            group(History)
            {
                Caption = 'History';
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
}
