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
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Foundation.Task;
using System.Threading;

page 9011 "Shop Supervisor Mfg Foundation"
{
    Caption = 'Shop Supervisor - Manufacturing Foundation';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1907234908; "Shop Super. basic Activities")
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
            part(Control21; "My Job Queue")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            part(Control27; "Report Inbox Part")
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
            action("Production Order - &Shortage List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Order - &Shortage List';
                Image = "Report";
                RunObject = Report "Prod. Order - Shortage List";
                ToolTip = 'View a list of the missing quantity per production order. The report shows how the inventory development is planned from today until the set day - for example whether orders are still open.';
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
            action("Production &Order Calculation")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production &Order Calculation (Obsolete)';
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
            action("&Item Registers - Quantity")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Item Registers - Quantity';
                Image = "Report";
                RunObject = Report "Item Register - Quantity";
                ToolTip = 'View all item ledger entries.';
            }
            action("Inventory Valuation &WIP")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Inventory Valuation &WIP';
                Image = "Report";
                RunObject = Report "Inventory Valuation - WIP";
                ToolTip = 'View inventory valuation for selected production orders in your WIP inventory. The report also shows information about the value of consumption, capacity usage and output in WIP. The printed report only shows invoiced amounts, that is, the cost of entries that have been posted as invoiced.';
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
            action(ProductionBOM)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production BOM';
                Image = BOM;
                RunObject = Page "Production BOM List";
                ToolTip = 'Open the item''s production bill of material to view or edit its components.';
            }
            action(ProductionBOMUnderDevelopment)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Under Development';
                RunObject = Page "Production BOM List";
                RunPageView = where(Status = const("Under Development"));
                ToolTip = 'View the list of production BOMs that are not yet certified.';
            }
            action(ProductionBOMCertified)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Certified';
                RunObject = Page "Production BOM List";
                RunPageView = where(Status = const(Certified));
                ToolTip = 'View the list of certified production BOMs.';
            }
            action("Work Centers")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Centers';
                RunObject = Page "Work Center List";
                ToolTip = 'View or edit the list of work centers.';
            }
            action(Routings)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routings';
                RunObject = Page "Routing List";
                ToolTip = 'View or edit operation sequences and process times for produced items.';
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
            action("Inventory Put-aways")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Inventory Put-aways';
                RunObject = Page "Inventory Put-aways";
                ToolTip = 'View ongoing put-aways of items to bins according to a basic warehouse configuration. ';
            }
            action("Inventory Picks")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Inventory Picks';
                RunObject = Page "Inventory Picks";
                ToolTip = 'View ongoing picks of items from bins according to a basic warehouse configuration. ';
            }
            action("Standard Cost Worksheets")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Standard Cost Worksheets';
                RunObject = Page "Standard Cost Worksheet Names";
                ToolTip = 'Review or update standard costs. Purchasers, production or assembly managers can use the worksheet to simulate the effect on the cost of the manufactured or assembled item if the standard cost for consumption, production capacity usage, or assembly resource usage is changed. You can set a cost change to take effect on a specified date.';
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
            action(RequisitionWorksheets)
            {
                ApplicationArea = Planning;
                Caption = 'Requisition Worksheets';
                RunObject = Page "Req. Wksh. Names";
                RunPageView = where("Template Type" = const("Req."),
                                    Recurring = const(false));
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
        }
        area(sections)
        {
            group(Journals)
            {
                Caption = 'Journals';
                Image = Journals;
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
        area(creation)
        {
            action("Production &Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production &Order';
                Image = "Order";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Planned Production Order";
                RunPageMode = Create;
                ToolTip = 'Create a new production order to supply a produced item.';
            }
            action("P&urchase Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'P&urchase Order';
                Image = Document;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Purchase Order";
                RunPageMode = Create;
                ToolTip = 'Create a new purchase order.';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Co&nsumption Journal")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Co&nsumption Journal';
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
            separator(Action9)
            {
            }
            action("Requisition &Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Requisition &Worksheet';
                Image = Worksheet;
                RunObject = Page "Req. Worksheet";
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action("Order &Planning")
            {
                ApplicationArea = Planning;
                Caption = 'Order &Planning';
                Image = Planning;
                RunObject = Page "Order Planning";
                ToolTip = 'Plan supply orders order by order to fulfill new demand.';
            }
            separator(Action28)
            {
            }
            action("&Change Production Order Status")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Change Production Order Status';
                Image = ChangeStatus;
                RunObject = Page "Change Production Order Status";
                ToolTip = 'Change the status of multiple production orders, for example from Planned to Released.';
            }
            separator(Action110)
            {
                Caption = 'Administration';
                IsHeader = true;
            }
            action("Manu&facturing Setup")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Manu&facturing Setup';
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
