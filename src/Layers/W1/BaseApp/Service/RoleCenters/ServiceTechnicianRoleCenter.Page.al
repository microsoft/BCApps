// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.EServices.EDocument;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Loaner;
using Microsoft.Service.Reports;
using Microsoft.Foundation.Task;
using System.Threading;

page 9017 "Service Technician Role Center"
{
    Caption = 'Outbound Technician - Customer Service';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control1900744308; "Serv Outbound Technician Act.")
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
            part(Control8; "My Job Queue")
            {
                ApplicationArea = Service;
                Visible = false;
            }
            part(Control1907692008; "My Customers")
            {
                ApplicationArea = Service;
            }
            part(Control4; "Report Inbox Part")
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
            action("Service &Order")
            {
                ApplicationArea = Service;
                Caption = 'Service &Order';
                Image = Document;
                RunObject = Report "Service Order";
                ToolTip = 'Create a new service order to perform service on a customer''s item.';
            }
            action("Service Items Out of &Warranty")
            {
                ApplicationArea = Service;
                Caption = 'Service Items Out of &Warranty';
                Image = "Report";
                RunObject = Report "Service Items Out of Warranty";
                ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
            }
            action("Service Item &Line Labels")
            {
                ApplicationArea = Service;
                Caption = 'Service Item &Line Labels';
                Image = "Report";
                RunObject = Report "Service Item Line Labels";
                ToolTip = 'View the list of service items on service orders. The report shows the order number, service item number, serial number, and the name of the item.';
            }
            action("Service &Item Worksheet")
            {
                ApplicationArea = Service;
                Caption = 'Service &Item Worksheet';
                Image = ServiceItemWorksheet;
                RunObject = Report "Service Item Worksheet";
                ToolTip = 'View or edit information about service items, such as repair status, fault comments and codes, and cost. In this window, you can update information on the items such as repair status and fault and resolution codes. You can also enter new service lines for resource hours, for the use of spare parts and for specific service costs.';
            }
        }
        area(embedding)
        {
            action(ServiceOrders)
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                Image = Document;
                RunObject = Page "Service Orders";
                ToolTip = 'Open the list of ongoing service orders.';
            }
            action(ServiceOrdersInProcess)
            {
                ApplicationArea = Service;
                Caption = 'In Process';
                RunObject = Page "Service Orders";
                RunPageView = where(Status = filter("In Process"));
                ToolTip = 'View ongoing service orders. ';
            }
            action("Service Item Lines")
            {
                ApplicationArea = Service;
                Caption = 'Service Item Lines';
                RunObject = Page "Service Item Lines";
                ToolTip = 'View the list of ongoing service item lines.';
            }
            action(Customers)
            {
                ApplicationArea = Service;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Loaners)
            {
                ApplicationArea = Service;
                Caption = 'Loaners';
                Image = Loaners;
                RunObject = Page "Loaner List";
                ToolTip = 'View or select from items that you lend out temporarily to customers to replace items that they have in service.';
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
                ApplicationArea = Service;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
        }
        area(sections)
        {
        }
        area(creation)
        {
            action(Action3)
            {
                ApplicationArea = Service;
                Caption = 'Service &Order';
                Image = Document;
                RunObject = Page "Service Order";
                RunPageMode = Create;
                ToolTip = 'Create a new service order to perform service on a customer''s item.';
            }
            action("&Loaner")
            {
                ApplicationArea = Service;
                Caption = '&Loaner';
                Image = Loaner;
                RunObject = Page "Loaner Card";
                RunPageMode = Create;
                ToolTip = 'View or select from items that you lend out temporarily to customers to replace items that they have in service.';
            }
        }
        area(processing)
        {
            separator(Tasks)
            {
                Caption = 'Tasks';
                IsHeader = true;
            }
            action("Service Item &Worksheet")
            {
                ApplicationArea = Service;
                Caption = 'Service Item &Worksheet';
                Image = ServiceItemWorksheet;
                RunObject = Page "Service Item Worksheet";
                ToolTip = 'Prepare to record service hours and spare parts used, repair status, fault comments, and cost.';
            }
        }
    }
}
