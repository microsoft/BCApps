// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.RoleCenters;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Reports;
using System.Automation;
using System.Email;
using System.Integration.PowerBI;
using Microsoft.Foundation.Task;
using System.Threading;
using System.Visualization;

page 9016 "Service Dispatcher Role Center"
{
    Caption = 'Service Manager';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control18; "Headline RC Serv. Dispatcher")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1904652008; "Service Dispatcher Activities")
            {
                ApplicationArea = Service;
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
            part(Control32; "Team Member Activities")
            {
                ApplicationArea = Suite;
            }
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                AccessByPermission = TableData "Power BI Context Settings" = I;
                ApplicationArea = Basic, Suite;
            }
            part(Control21; "My Job Queue")
            {
                ApplicationArea = Service;
                Visible = false;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1905989608; "My Items")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control31; "Report Inbox Part")
            {
                ApplicationArea = Service;
                Visible = false;
            }
            systempart(Control1901377608; MyNotes)
            {
                ApplicationArea = Service;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            group(Service)
            {
                Caption = 'Service';
                action("Service Ta&sks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ta&sks';
                    Image = ServiceTasks;
                    RunObject = Report "Service Tasks";
                    ToolTip = 'View or edit service task information, such as service order number, service item description, repair status, and service item. You can print a list of the service tasks that have been entered.';
                }
                action("Service &Load Level")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Load Level';
                    Image = "Report";
                    RunObject = Report "Service Load Level";
                    ToolTip = 'View the capacity, usage, unused, unused percentage, sales, and sales percentage of the resource. You can test what the service load is of your resources.';
                }
                action("Resource &Usage")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource &Usage';
                    Image = "Report";
                    RunObject = Report "Service Item - Resource Usage";
                    ToolTip = 'View details about the total use of service items, both cost and amount, profit amount, and profit percentage.';
                }
                action("Service I&tems Out of Warranty")
                {
                    ApplicationArea = Service;
                    Caption = 'Service I&tems Out of Warranty';
                    Image = "Report";
                    RunObject = Report "Service Items Out of Warranty";
                    ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
                }
            }
            group(Profit)
            {
                Caption = 'Profit';
                action("Profit Service &Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit Service &Contracts';
                    Image = "Report";
                    RunObject = Report "Service Profit (Contracts)";
                    ToolTip = 'View details about service amount, contract discount amount, service discount amount, service cost amount, profit amount, and profit. You can print information about service profit for service contracts, based on the difference between the service amount and service cost.';
                }
                action("Profit Service &Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit Service &Orders';
                    Image = "Report";
                    RunObject = Report "Service Profit (Serv. Orders)";
                    ToolTip = 'View the customer number, serial number, description, item number, contract number, and contract amount. You can print information about service profit for service orders, based on the difference between service amount and service cost.';
                }
                action("Profit Service &Items")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit Service &Items';
                    Image = "Report";
                    RunObject = Report "Service Profit (Service Items)";
                    ToolTip = 'View details about service amount, contract discount amount, service discount amount, service cost amount, profit amount, and profit. You can print information about service profit for service items.';
                }
            }
        }
        area(embedding)
        {
            action(Loaners)
            {
                ApplicationArea = Service;
                Caption = 'Loaners';
                Image = Loaners;
                RunObject = Page "Loaner List";
                ToolTip = 'View or select from items that you lend out temporarily to customers to replace items that they have in service.';
            }
            action(Customers)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action("Service Items")
            {
                ApplicationArea = Service;
                Caption = 'Service Items';
                Image = ServiceItem;
                RunObject = Page "Service Item List";
                ToolTip = 'View the list of service items.';
            }
            action(Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action("Item Journals")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Journals';
                RunObject = Page "Item Journal Batches";
                RunPageView = where("Template Type" = const(Item),
                                    Recurring = const(false));
                ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
            }
            action("Requisition Worksheets")
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
            group("Service Management")
            {
                Caption = 'Service Management';
                action("Service Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Quotes';
                    RunObject = Page "Service Contract Quotes";
                    ToolTip = 'View the list of ongoing service contract quotes.';
                }
                action("Service Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Service Contracts";
                    ToolTip = 'View the list of ongoing service contracts.';
                }
                action("Service Quotes")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Quotes';
                    Image = Quote;
                    RunObject = Page "Service Quotes";
                    ToolTip = 'View the list of ongoing service quotes.';
                }
                action("Service Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Orders';
                    Image = Document;
                    RunObject = Page "Service Orders";
                    ToolTip = 'Open the list of ongoing service orders.';
                }
                action("Service Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Invoices';
                    Image = Invoice;
                    RunObject = Page "Service Invoices";
                    ToolTip = 'Open the list of ongoing service invoices.';
                }
                action("Service Credit Memos")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Credit Memos';
                    Image = CreditMemo;
                    RunObject = Page "Service Credit Memos";
                    ToolTip = 'Open the list of ongoing service credit memos.';
                }
                action("Standard Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Standard Service Codes';
                    Image = ServiceCode;
                    RunObject = Page "Standard Service Codes";
                    ToolTip = 'View or edit service order lines that you have set up for recurring services. ';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                action("Posted Service Shipments")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Service Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Service Shipments";
                    ToolTip = 'Open the list of posted service shipments.';
                }
                action("Posted Service Invoices")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Service Invoices';
                    Image = PostedServiceOrder;
                    RunObject = Page "Posted Service Invoices";
                    ToolTip = 'Open the list of posted service invoices.';
                }
                action("Posted Service Credit Memos")
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Service Credit Memos';
                    RunObject = Page "Posted Service Credit Memos";
                    ToolTip = 'Open the list of posted service credit memos.';
                }
            }
        }
        area(creation)
        {
            action("Service Contract &Quote")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract &Quote';
                Image = AgreementQuote;
                RunObject = Page "Service Contract Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new quote to perform service on a customer''s item.';
            }
            action("Service &Contract")
            {
                ApplicationArea = Service;
                Caption = 'Service &Contract';
                Image = Agreement;
                RunObject = Page "Service Contract";
                RunPageMode = Create;
                ToolTip = 'Create a new service contract.';
            }
            action("Service Q&uote")
            {
                ApplicationArea = Service;
                Caption = 'Service Q&uote';
                Image = Quote;
                RunObject = Page "Service Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new service quote.';
            }
            action("Service &Order")
            {
                ApplicationArea = Service;
                Caption = 'Service &Order';
                Image = Document;
                RunObject = Page "Service Order";
                RunPageMode = Create;
                ToolTip = 'Create a new service order to perform service on a customer''s item.';
            }
            action("Sales Or&der")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Or&der';
                Image = Document;
                RunObject = Page "Sales Order";
                RunPageMode = Create;
                ToolTip = 'Create a new sales order for items or services that require partial posting or order confirmation.';
            }
            action("Transfer &Order")
            {
                ApplicationArea = Location;
                Caption = 'Transfer &Order';
                Image = Document;
                RunObject = Page "Transfer Order";
                RunPageMode = Create;
                ToolTip = 'Prepare to transfer items to another location.';
            }
        }
        area(processing)
        {
            group(Tasks)
            {
                Caption = 'Tasks';
                action("Service Tas&ks")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Tas&ks';
                    Image = ServiceTasks;
                    RunObject = Page "Service Tasks";
                    ToolTip = 'View or edit service task information, such as service order number, service item description, repair status, and service item. You can print a list of the service tasks that have been entered.';
                }
                action("C&reate Contract Service Orders")
                {
                    ApplicationArea = Service;
                    Caption = 'C&reate Contract Service Orders';
                    Image = "Report";
                    RunObject = Report "Create Contract Service Orders";
                    ToolTip = 'Copy information from an existing production order record to a new one. This can be done regardless of the status type of the production order. You can, for example, copy from a released production order to a new planned production order. Note that before you start to copy, you have to create the new record.';
                }
                action("Create Contract In&voices")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Contract In&voices';
                    Image = "Report";
                    RunObject = Report "Create Contract Invoices";
                    ToolTip = 'Create service invoices for service contracts that are due for invoicing. ';
                }
                action("Post &Prepaid Contract Entries")
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Prepaid Contract Entries';
                    Image = "Report";
                    RunObject = Report "Post Prepaid Contract Entries";
                    ToolTip = 'Transfers prepaid service contract ledger entries amounts from prepaid accounts to income accounts.';
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
                action("St&andard Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'St&andard Service Codes';
                    Image = ServiceCode;
                    RunObject = Page "Standard Service Codes";
                    ToolTip = 'View or edit service order lines that you have set up for recurring services. ';
                }
                action("Dispatch Board")
                {
                    ApplicationArea = Service;
                    Caption = 'Dispatch Board';
                    Image = ListPage;
                    RunObject = Page "Dispatch Board";
                    ToolTip = 'Get an overview of your service orders. Set filters, for example, if you only want to view service orders for a particular customer, service zone or you only want to view service orders needing reallocation.';
                }
            }
            group(History)
            {
                Caption = 'History';
                action("Item &Tracing")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item &Tracing';
                    Image = ItemTracing;
                    RunObject = Page "Item Tracing";
                    ToolTip = 'Trace where a serial, lot or package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
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
    }
}

