// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.CRM.Analysis;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Integration.D365Sales;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Reports;
using System.Automation;
using System.Email;
using System.Integration.PowerBI;
using Microsoft.Foundation.Task;
using System.Threading;
using System.Visualization;

page 9026 "Sales & Relationship Mgr. RC"
{
    Caption = 'Sales and Relationship Manager', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control60; "Headline RC Relationship Mgt.")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control1; "Sales & Relationship Mgr. Act.")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control56; "User Tasks Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part("Job Queue Tasks Activities"; "Job Queue Tasks Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part("Emails"; "Email Activities")
            {
                ApplicationArea = Basic, Suite;
            }
            part(ApprovalsActivities; "Approvals Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control16; "Team Member Activities")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control6; "Sales Pipeline Chart")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control4; "Opportunity Chart")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(Control11; "Relationship Performance")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                ApplicationArea = RelationshipMgmt;
            }
            part("My Job Queue"; "My Job Queue")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
            part("Report Inbox Part"; "Report Inbox Part")
            {
                ApplicationArea = Basic, Suite;
            }
            systempart(MyNotes; MyNotes)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Customer - &Order Summary")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customer - &Order Summary';
                Image = "Report";
                RunObject = Report "Customer - Order Summary";
                ToolTip = 'View the quantity not yet shipped for each customer in three periods of 30 days each, starting from a selected date. There are also columns with orders to be shipped before and after the three periods and a column with the total order detail for each customer. The report can be used to analyze a company''s expected sales volume.';
            }
            action("Customer - &Top 10 List")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customer - &Top 10 List';
                Image = "Report";
                RunObject = Report "Customer - Top 10 List";
                ToolTip = 'View which customers purchase the most or owe the most in a selected period. Only customers that have either purchases during the period or a balance at the end of the period will be included.';
            }
            separator(Action17)
            {
            }
            action("S&ales Statistics")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'S&ales Statistics';
                Image = "Report";
                RunObject = Report "Sales Statistics";
                ToolTip = 'View detailed information about sales to your customers.';
            }
            action("Salesperson - Sales &Statistics")
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salesperson - Sales &Statistics';
                Image = "Report";
                RunObject = Report "Salesperson - Sales Statistics";
                ToolTip = 'View amounts for sales, profit, invoice discount, and payment discount, as well as profit percentage, for each salesperson for a selected period. The report also shows the adjusted profit and adjusted profit percentage, which reflect any changes to the original costs of the items in the sales.';
            }
            action("Salesperson - &Commission")
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salesperson - &Commission';
                Image = "Report";
                RunObject = Report "Salesperson - Commission";
                ToolTip = 'View a list of invoices for each salesperson for a selected period. The following information is shown for each invoice: Customer number, sales amount, profit amount, and the commission on sales amount and profit amount. The report also shows the adjusted profit and the adjusted profit commission, which are the profit figures that reflect any changes to the original costs of the goods sold.';
            }
            separator(Action22)
            {
            }
            action("Campaign - &Details")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaign - &Details';
                Image = "Report";
                RunObject = Report "Campaign - Details";
                ToolTip = 'Show detailed information about the campaign.';
            }
        }
        area(embedding)
        {
            action(Contacts)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Contacts';
                Image = CustomerContact;
                RunObject = Page "Contact List";
                ToolTip = 'View a list of all your contacts.';
            }
            action(Opportunities)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Opportunities';
                RunObject = Page "Opportunity List";
                ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
            }
            action("Sales Quotes")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Quotes';
                Image = Quote;
                RunObject = Page "Sales Quotes";
                ToolTip = 'Make offers to customers to sell certain products on certain delivery and payment terms. While you negotiate with a customer, you can change and resend the sales quote as much as needed. When the customer accepts the offer, you convert the sales quote to a sales invoice or a sales order in which you process the sale.';
            }
            action("Sales Orders")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Sales Orders';
                Image = "Order";
                RunObject = Page "Sales Order List";
                ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
            }
            action(Customers)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Customers';
                Image = Customer;
                RunObject = Page "Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Items)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Items';
                Image = Item;
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action("Active Segments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Active Segments';
                RunObject = Page "Segment List";
                ToolTip = 'View the list of active segments. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
            }
            action("Logged Segments")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Logged Segments';
                RunObject = Page "Logged Segments";
                ToolTip = 'View the list of segments containing contacts for which you have logged interactions. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
            }
            action(Campaigns)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaigns';
                Image = Campaign;
                RunObject = Page "Campaign List";
                ToolTip = 'View a list of all your campaigns.';
            }
            action("Cases - Dynamics 365 Customer Service")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Cases - Dynamics 365 Customer Service';
                RunObject = Page "CRM Case List";
                ToolTip = 'View the list of cases that you manage with Microsoft Dynamics 365 Customer Service.';
            }
            action("Sales Orders - Microsoft Dynamics 365 Sales")
            {
                ApplicationArea = Suite;
                Caption = 'Sales Orders - Microsoft Dynamics 365 Sales';
                RunObject = Page "CRM Sales Order List";
                ToolTip = 'View sales orders in Dynamics 365 Sales that are coupled with sales orders in Business Central.';
            }
            action(Salespersons)
            {
                ApplicationArea = Suite, RelationshipMgmt;
                Caption = 'Salespeople';
                RunObject = Page "Salespersons/Purchasers";
                ToolTip = 'View or edit information about the salespeople.';
            }
        }
        area(sections)
        {
            group(Action257)
            {
                Caption = 'Sales';
                action(Action67)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contacts';
                    Image = CustomerContact;
                    RunObject = Page "Contact List";
                    ToolTip = 'View or edit detailed information about the contact persons at your business partners that you use to communicate business activities with or that you target marketing activities towards.';
                }
                action(Action66)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = Page "Opportunity List";
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action(Action65)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Quotes';
                    Image = Quote;
                    RunObject = Page "Sales Quotes";
                    ToolTip = 'Make offers to customers to sell certain products on certain delivery and payment terms. While you negotiate with a customer, you can change and resend the sales quote as much as needed. When the customer accepts the offer, you convert the sales quote to a sales invoice or a sales order in which you process the sale.';
                }
                action(Action64)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Orders';
                    Image = "Order";
                    RunObject = Page "Sales Order List";
                    ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
                }
                action("Blanket Sales Orders")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Blanket Sales Orders';
                    Image = Reminder;
                    RunObject = Page "Blanket Sales Orders";
                    ToolTip = 'Use blanket sales orders as a framework for a long-term agreement between you and your customers to sell large quantities that are to be delivered in several smaller shipments over a certain period of time. Blanket orders often cover only one item with predetermined delivery dates. The main reason for using a blanket order rather than a sales order is that quantities entered on a blanket order do not affect item availability and thus can be used as a worksheet for monitoring, forecasting, and planning purposes..';
                }
                action("Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = Page "Sales Invoice List";
                    ToolTip = 'Register your sales to customers and invite them to pay according to the delivery and payment terms by sending them a sales invoice document. Posting a sales invoice registers shipment and records an open receivable entry on the customer''s account, which will be closed when payment is received. To manage the shipment process, use sales orders, in which sales invoicing is integrated.';
                }
                action("Sales Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = Page "Sales Return Order List";
                    ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
                }
                action("Sales Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = Page "Sales Credit Memos";
                    ToolTip = 'Revert the financial transactions involved when your customers want to cancel a purchase or return incorrect or damaged items that you sent to them and received payment for. To include the correct information, you can create the sales credit memo from the related posted sales invoice or you can create a new sales credit memo with copied invoice information. If you need more control of the sales return process, such as warehouse documents for the physical handling, use sales return orders, in which sales credit memos are integrated. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
                }
                action(Action63)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customers';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
                action(Action62)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action("Item Charges")
                {
                    ApplicationArea = Suite;
                    Caption = 'Item Charges';
                    RunObject = Page "Item Charges";
                    ToolTip = 'View or edit the codes for item charges that you can assign to purchase and sales transactions to include any added costs, such as freight, physical handling, and insurance that you incur when purchasing or selling items. This is important to ensure correct inventory valuation. For purchases, the landed cost of a purchased item consists of the vendor''s purchase price and all additional direct item charges that can be assigned to individual receipts or return shipments. For sales, knowing the cost of shipping sold items can be as vital to your company as knowing the landed cost of purchased items.';
                }
                action("Item Attributes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attributes';
                    RunObject = Page "Item Attributes";
                    ToolTip = 'Assign item attribute values to your items to enable rich searching and sorting options. When customers inquire about an item, either in correspondence or in an integrated web shop, they can then ask or search according to characteristics, such as height and model year. You can also assign item attributes to item categories, which then apply to the items that use the item categories in question.';
                }
                action(Segments)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segments';
                    RunObject = Page "Segment List";
                    ToolTip = 'View the list of segments that are currently used in active campaigns. Segments represent a grouping of contacts, so that you can interact with several contacts at once, for example by direct mail.';
                }
                action(Action59)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaigns';
                    Image = Campaign;
                    RunObject = Page "Campaign List";
                    ToolTip = 'View the list of your marketing campaigns. A campaign organizes all the sales and marketing activities involving your contacts, such as a sales promotion campaign.';
                }
                action(Action58)
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salespeople';
                    RunObject = Page "Salespersons/Purchasers";
                    ToolTip = 'View or edit information about the salespeople that work for you.';
                }
            }
            group("Posted Documents")
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;
                ToolTip = 'View the posting history for sales, shipments, and inventory.';
                action(Action32)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Invoices";
                    ToolTip = 'Open the list of posted sales invoices.';
                }
                action(Action34)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    Image = PostedOrder;
                    RunObject = Page "Posted Sales Credit Memos";
                    ToolTip = 'Open the list of posted sales credit memos.';
                }
                action("Posted Return Receipts")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action(Action40)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action("Sales Quote Archive")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quote Archives';
                    RunObject = page "Sales Quote Archives";
                }
                action("Sales Order Archive")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Order Archives';
                    RunObject = page "Sales Order Archives";
                }
                action("Sales Return Order Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Return Order Archives';
                    RunObject = page "Sales Return List Archive";
                }
                action("Blanket Sales Order Archives")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Blanket Sales Order Archives';
                    RunObject = page "Blanket Sales Order Archives";
                }
                action("Issued Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issued Reminders';
                    RunObject = Page "Issued Reminder List";
                    ToolTip = 'Opens the list of issued reminders.';
                }
                action("Issued Finance Charge Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Issued Finance Charge Memos';
                    RunObject = Page "Issued Fin. Charge Memo List";
                    ToolTip = 'Opens the list of issued finance charge memos.';
                }
            }
            group("Administration Sales/Purchase")
            {
                Caption = 'Administration Sales/Purchase';
                Image = AdministrationSalesPurchases;
                action("Salespeople/Purchasers")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = Page "Salespersons/Purchasers";
                    ToolTip = 'View or edit information about the salespeople and purchasers that work for you and which customers and vendors they are assigned to.';
                }
                action("Customer Price Groups")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Customer Price Groups';
                    RunObject = Page "Customer Price Groups";
                    ToolTip = 'View a list of your customer price groups.';
                }
                action("Cust. Invoice Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Cust. Invoice Discounts';
                    RunObject = Page "Cust. Invoice Discounts";
                    ToolTip = 'View or edit invoice discounts that you grant to certain customers.';
                }
                action("Vend. Invoice Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Vend. Invoice Discounts';
                    RunObject = Page "Vend. Invoice Discounts";
                    ToolTip = 'View the invoice discounts that your vendors grant you.';
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Item Disc. Groups';
                    RunObject = Page "Item Disc. Groups";
                    ToolTip = 'View or edit discount group codes that you can use as criteria when you grant special discounts to customers.';
                }
                action("Sales Cycles")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Cycles';
                    RunObject = Page "Sales Cycles";
                    ToolTip = 'View the different sales cycles that you use to manage sales opportunities.';
                }
            }
            group(Analysis)
            {
                Caption = 'Analysis';
                action("Sales Analysis Reports")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Analysis Reports';
                    RunObject = Page "Analysis Report Sale";
                    ToolTip = 'Analyze the dynamics of your sales according to key sales performance indicators that you select, for example, sales turnover in both amounts and quantities, contribution margin, or progress of actual sales against the budget. You can also use the report to analyze your average sales prices and evaluate the sales performance of your sales force.';
                }
                action("Sales Analysis by Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Sales Analysis by Dimensions';
                    RunObject = Page "Analysis View List Sales";
                    ToolTip = 'View sales amounts in G/L accounts by their dimension values and other filters that you define in an analysis view and then show in a matrix window.';
                }
                action("Sales Budgets")
                {
                    ApplicationArea = SalesBudget;
                    Caption = 'Sales Budgets';
                    RunObject = Page "Budget Names Sales";
                    ToolTip = 'Enter item sales values of type amount, quantity, or cost for expected item sales in different time periods. You can create sales budgets by items, customers, customer groups, or other dimensions in your business. The resulting sales budgets can be reviewed here or they can be used in comparisons with actual sales data in sales analysis reports.';
                }
                action(Action38)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contacts';
                    Image = CustomerContact;
                    RunObject = Page "Contact List";
                    ToolTip = 'View a list of all your contacts.';
                }
                action(Action21)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customers';
                    Image = Customer;
                    RunObject = Page "Customer List";
                    ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
                }
            }
        }
        area(creation)
        {
            action("Sales &Quote")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Quote';
                Image = NewSalesQuote;
                RunObject = Page "Sales Quote";
                RunPageMode = Create;
                ToolTip = 'Create a new sales quote to offer items or services to a customer.';
            }
            action("Sales &Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Invoice';
                Image = NewSalesInvoice;
                RunObject = Page "Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create a new invoice for the sales of items or services. Invoice quantities cannot be posted partially.';
            }
            action("Sales &Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Order';
                Image = Document;
                RunObject = Page "Sales Order";
                RunPageMode = Create;
                ToolTip = 'Create a new sales order for items or services.';
            }
            action("Sales &Return Order")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Return Order';
                Image = ReturnOrder;
                RunObject = Page "Sales Return Order";
                RunPageMode = Create;
                ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
            }
            action("Sales &Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales &Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Sales Credit Memo";
                RunPageMode = Create;
                ToolTip = 'Create a new sales credit memo to revert a posted sales invoice.';
            }
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                action(NewContact)
                {
                    AccessByPermission = TableData Contact = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Image = AddContacts;
                    RunObject = Page "Contact Card";
                    RunPageMode = Create;
                    ToolTip = 'Create a new contact. Contacts are persons at your business partners that you use to communicate business activities with or that you target marketing activities towards.';
                }
                action(NewOpportunity)
                {
                    AccessByPermission = TableData Opportunity = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity';
                    Image = NewOpportunity;
                    RunObject = Page "Opportunity Card";
                    RunPageMode = Create;
                    ToolTip = 'View the sales opportunities that are handled by salespeople for the contact. Opportunities must involve a contact and can be linked to campaigns.';
                }
                action(NewSegment)
                {
                    AccessByPermission = TableData "Segment Header" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segment';
                    Image = Segment;
                    RunObject = Page Segment;
                    RunPageMode = Create;
                    ToolTip = 'Create a new segment where you manage interactions with a contact.';
                }
                action(NewCampaign)
                {
                    AccessByPermission = TableData Campaign = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Image = Campaign;
                    RunObject = Page "Campaign Card";
                    RunPageMode = Create;
                    ToolTip = 'Create a new campaign';
                }
            }
            group("Sales Prices")
            {
                Caption = 'Sales Prices';
                action("Sales Price &Worksheet")
                {
                    AccessByPermission = TableData "Sales Price Worksheet" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Price &Worksheet';
                    Image = PriceWorksheet;
                    RunPageView = where("Object Type" = const(Page), "Object ID" = const(7023)); // "Sales Price Worksheet";
                    RunObject = Page "Role Center Page Dispatcher";
                    ToolTip = 'Manage sales prices for individual customers, for a group of customers, for all customers, or for a campaign.';
                }
                action("Sales &Prices")
                {
                    AccessByPermission = TableData "Sales Price and Line Disc Buff" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Prices';
                    Image = SalesPrices;
                    RunPageView = where("Object Type" = const(Page), "Object ID" = const(7002)); // "Sales Prices";
                    RunObject = Page "Role Center Page Dispatcher";
                    ToolTip = 'Define how to set up sales price agreements. These sales prices can be for individual customers, for a group of customers, for all customers, or for a campaign.';
                }
                action("Sales Line &Discounts")
                {
                    AccessByPermission = TableData "Sales Price and Line Disc Buff" = IMD;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Line &Discounts';
                    Image = SalesLineDisc;
                    RunPageView = where("Object Type" = const(Page), "Object ID" = const(7004)); // "Sales Line Discounts";
                    RunObject = Page "Role Center Page Dispatcher";
                    ToolTip = 'View or edit sales line discounts that you grant when certain conditions are met, such as customer, quantity, or ending date. The discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';
                }
            }
            separator(History)
            {
                Caption = 'History';
                IsHeader = true;
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

