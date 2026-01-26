// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Analysis;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.RoleCenters;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

page 8907 "Sales & Marketing Manager RC"
{
    Caption = 'Sales & Marketing Manager RC';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Sales';
                action("Customers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                    Tooltip = 'Open the Customers page.';
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                    Tooltip = 'Open the Contacts page.';
                }
                action("Salespeople")
                {
                    ApplicationArea = Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = page "Salespersons/Purchasers";
                    Tooltip = 'Open the Salespeople/Purchasers page.';
                }
                action("Teams")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Teams';
                    RunObject = page "Teams";
                    Tooltip = 'Open the Teams page.';
                }
                action("Tasks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = page "Tasks";
                    Tooltip = 'Open the Tasks page.';
                }
                action("Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = page "Opportunity List";
                    Tooltip = 'Open the Opportunities page.';
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Sales Budgets")
                    {
                        ApplicationArea = SalesBudget;
                        Caption = 'Sales Budgets';
                        RunObject = page "Budget Names Sales";
                        Tooltip = 'Open the Sales Budgets page.';
                    }
                    action("Sales Analysis Reports")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Reports';
                        RunObject = page "Analysis Report Sale";
                        Tooltip = 'Open the Sales Analysis Reports page.';
                    }
                    action("Sales Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = page "Analysis View List Sales";
                        Tooltip = 'Open the Sales Analysis by Dimensions page.';
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = report "Item Dimensions - Detail";
                        Tooltip = 'Run the Item Dimensions - Detail report.';
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = report "Item Dimensions - Total";
                        Tooltip = 'Run the Item Dimensions - Total report.';
                    }
                    action("Opportunities Matrix")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Analysis';
                        RunObject = page "Opportunities";
                        Tooltip = 'Open the Opportunity Analysis page.';
                    }
                }
                group("Group2")
                {
                    Caption = 'Reports';
                    action("Sales Deferral Summary")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Sales Deferral Summary';
                        RunObject = report "Deferral Summary - Sales";
                        Tooltip = 'Run the Sales Deferral Summary report.';
                    }
                    group("Group3")
                    {
                        Caption = 'Salespeople/Teams';
                        action("Salesperson - Tasks")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Tasks';
                            RunObject = report "Salesperson - Tasks";
                            Tooltip = 'Run the Salesperson Tasks report.';
                        }
                        action("Salesperson - Commission")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Salesperson Commission';
                            RunObject = report "Salesperson - Commission";
                            Tooltip = 'Run the Salesperson Commission report.';
                        }
                        action("Salesperson - Opportunities")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Opportunities';
                            RunObject = report "Salesperson - Opportunities";
                            Tooltip = 'Run the Salesperson Opportunities report.';
                        }
                        action("Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Statistics';
                            RunObject = report "Sales Statistics";
                            Tooltip = 'Run the Sales Statistics report.';
                        }
                        action("Team - Tasks")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Team Tasks';
                            RunObject = report "Team - Tasks";
                            Tooltip = 'Run the Team Tasks report.';
                        }
                        action("Salesperson - Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Sales Statistics';
                            RunObject = report "Salesperson - Sales Statistics";
                            Tooltip = 'Run the Salesperson Sales Statistics report.';
                        }
                    }
                    group("Group4")
                    {
                        Caption = 'Contacts';
                        action("Contact - Labels")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact Labels';
                            RunObject = report "Contact - Labels";
                            Tooltip = 'Run the Contact Labels report.';
                        }
                        action("Contact - Company Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact - Company Summary';
                            RunObject = report "Contact - Company Summary";
                            Tooltip = 'Run the Contact - Company Summary report.';
                        }
                        action("Questionnaire - Handouts")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Questionnaire - Handouts';
                            RunObject = report "Questionnaire - Handouts";
                            Tooltip = 'Run the Questionnaire - Handouts report.';
                        }
                        action("Contact - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact List';
                            RunObject = report "Contact - List";
                            Tooltip = 'Run the Contact List report.';
                        }
                        action("Orgl. Profile Summary")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Person Summary';
                            RunObject = report "Contact - Person Summary";
                            Tooltip = 'Run the Contact - Person Summary report.';
                        }
                        action("Contact - Cover Sheet")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Cover Sheet';
                            RunObject = report "Contact - Cover Sheet";
                            Tooltip = 'Run the Contact - Cover Sheet report.';
                        }
                    }
                    group("Group5")
                    {
                        Caption = 'Customers';
                        action("Customer - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - List';
                            RunObject = report "Customer - List";
                            Tooltip = 'Run the Customer - List report.';
                        }
                        action("Customer - Labels")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Customer Labels';
                            RunObject = report "Customer - Labels";
                            Tooltip = 'Run the Customer Labels report.';
                        }
                        action("Customer - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Balance to Date';
                            RunObject = report "Customer - Balance to Date";
                            Tooltip = 'Run the Customer - Balance to Date report.';
                        }
                        action("Customer - Order Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Summary';
                            RunObject = report "Customer - Order Summary";
                            Tooltip = 'Run the Customer - Order Summary report.';
                        }
                        action("Customer/Item Sales")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer/Item Sales';
                            RunObject = report "Customer/Item Sales";
                            Tooltip = 'Run the Customer/Item Sales report.';
                        }
                        action("Customer Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Register';
                            RunObject = report "Customer Register";
                            Tooltip = 'Run the Customer Register report.';
                        }
                        action("Customer - Order Detail")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Detail';
                            RunObject = report "Customer - Order Detail";
                            Tooltip = 'Run the Customer - Order Detail report.';
                        }
#if not CLEAN28
                        action("Customer - Top 10 List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Top 10 List (Obsolete)';
                            RunObject = report "Customer - Top 10 List";
                            Tooltip = 'Run the Customer Top 10 List report.';
                            ObsoleteState = Pending;
                            ObsoleteReason = 'This report has been replaced by the report Customer - Top List (Excel). This report will be removed in a future release.';
                            ObsoleteTag = '28.0';
                        }
#endif
                        action("Customer - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Trial Balance';
                            RunObject = report "Customer - Trial Balance";
                            Tooltip = 'Run the Customer Trial Balance report.';
                        }
                        action("Customer - Sales List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Sales List';
                            RunObject = report "Customer - Sales List";
                            Tooltip = 'Run the Customer - Sales List report.';
                        }
                    }
                    group("Group6")
                    {
                        Caption = 'Opportunities';
                        action("Opportunity - List")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Opportunity - List';
                            RunObject = report "Opportunity - List";
                            Tooltip = 'Run the Opportunity - List report.';
                        }
                        action("Opportunity - Details")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Opportunity - Details';
                            RunObject = report "Opportunity - Details";
                            Tooltip = 'Run the Opportunity - Details report.';
                        }
                        action("Sales Cycle - Analysis")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Sales Cycle - Analysis';
                            RunObject = report "Sales Cycle - Analysis";
                            Tooltip = 'Run the Sales Cycle - Analysis report.';
                        }
                    }
                }
            }
            group("Group7")
            {
                Caption = 'Order Processing';
                action("Customers1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customers';
                    RunObject = page "Customer List";
                    Tooltip = 'Open the Customers page.';
                }
                action("Contacts1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                    Tooltip = 'Open the Contacts page.';
                }
                action("Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quotes';
                    RunObject = page "Sales Quotes";
                    Tooltip = 'Open the Sales Quotes page.';
                }
                action("Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                    Tooltip = 'Open the Sales Orders page.';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = page "Blanket Sales Orders";
                    Tooltip = 'Open the Blanket Sales Orders page.';
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = page "Sales Return Order List";
                    Tooltip = 'Open the Sales Return Orders page.';
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = page "Sales Invoice List";
                    Tooltip = 'Open the Sales Invoices page.';
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = page "Sales Credit Memos";
                    Tooltip = 'Open the Sales Credit Memos page.';
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = page "Certificates of Supply";
                    Tooltip = 'Open the Certificates of Supply page.';
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                    Tooltip = 'Open the Order Planning page.';
                }
                group("Group8")
                {
                    Caption = 'Posted Documents';
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = page "Posted Sales Invoices";
                        Tooltip = 'Open the Posted Sales Invoices page.';
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = page "Posted Sales Shipments";
                        Tooltip = 'Open the Posted Sales Shipments page.';
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = page "Posted Sales Credit Memos";
                        Tooltip = 'Open the Posted Sales Credit Memos page.';
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = page "Posted Return Receipts";
                        Tooltip = 'Open the Posted Return Receipts page.';
                    }
                }
                group("Group9")
                {
                    Caption = 'Registers/Entries';
                    action("G/L Registers")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Registers';
                        RunObject = page "G/L Registers";
                        Tooltip = 'Open the G/L Registers page.';
                    }
                    action("Item Tracing")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracing';
                        RunObject = page "Item Tracing";
                        Tooltip = 'Open the Item Tracing page.';
                    }
                    action("Sales Quote Archive")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Quote Archives';
                        RunObject = page "Sales Quote Archives";
                        Tooltip = 'Open the Sales Quote Archives page.';
                    }
                    action("Sales Order Archive")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Order Archives';
                        RunObject = page "Sales Order Archives";
                        Tooltip = 'Open the Sales Order Archives page.';
                    }
                    action("Sales Return Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Return Order Archives';
                        RunObject = page "Sales Return List Archive";
                        Tooltip = 'Open the Sales Return Order Archives page.';
                    }
                    action("Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        RunObject = page "Customer Ledger Entries";
                        Tooltip = 'Open the Customer Ledger Entries page.';
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Customer Ledger Entries';
                        RunObject = page "Detailed Cust. Ledg. Entries";
                        Tooltip = 'Open the Detailed Customer Ledger Entries page.';
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
                        Tooltip = 'Open the Value Entries page.';
                    }
                    action("Navigate")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Find entries...';
                        Image = Navigate;
                        RunObject = Page Navigate;
                        ShortCutKey = 'Ctrl+Alt+Q';
                        ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Customer - Order Detail1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Detail';
                        RunObject = report "Customer - Order Detail";
                        Tooltip = 'Run the Customer - Order Detail report.';
                    }
                    action("Sales Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Sales Reservation Avail.';
                        RunObject = report "Sales Reservation Avail.";
                        Tooltip = 'Run the Sales Reservation Avail. report.';
                    }
                    action("Sales Order Picking List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Order Picking List';
                        RunObject = report "Sales Order Picking List";
                        Tooltip = 'Run the Sales Order Picking List report.';
                    }
                    action("Sales Statistics1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Statistics';
                        RunObject = report "Sales Statistics";
                        Tooltip = 'Run the Sales Statistics report.';
                    }
                    action("Customer - Sales List1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Sales List';
                        RunObject = report "Customer - Sales List";
                        Tooltip = 'Run the Customer - Sales List report.';
                    }
                    action("EC Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List';
                        RunObject = report "EC Sales List";
                        Tooltip = 'Run the EC Sales List report.';
                    }
                    action("Customer/Item Sales1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Item Sales';
                        RunObject = report "Customer/Item Sales";
                        Tooltip = 'Run the Customer/Item Sales report.';
                    }
                    action("Customer - Order Summary1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Summary';
                        RunObject = report "Customer - Order Summary";
                        Tooltip = 'Run the Customer - Order Summary report.';
                    }
                }
            }
            group("Group11")
            {
                Caption = 'Marketing';
                action("Contacts2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                    Tooltip = 'Open the Contacts page.';
                }
                action("Campaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaigns';
                    RunObject = page "Campaign List";
                    Tooltip = 'Open the Campaigns page.';
                }
                action("Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segments';
                    RunObject = page "Segment List";
                    Tooltip = 'Open the Segments page.';
                }
                action("Logged Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Logged Segments';
                    RunObject = page "Logged Segments";
                    Tooltip = 'Open the Logged Segments page.';
                }
                action("Opportunities1")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = page "Opportunity List";
                    Tooltip = 'Open the Opportunities page.';
                }
                action("Tasks1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = page "Tasks";
                    Tooltip = 'Open the Tasks page.';
                }
                action("Campaign - Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign - Details';
                    RunObject = report "Campaign - Details";
                    Tooltip = 'Run the Campaign - Details report.';
                }
                group("Group12")
                {
                    Caption = 'Registers/Entries';
                    action("Campaign Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Entries';
                        RunObject = page "Campaign Entries";
                        Tooltip = 'Open the Campaign Entries page.';
                    }
                    action("Opportunity Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Entries';
                        RunObject = page "Opportunity Entries";
                        Tooltip = 'Open the Opportunity Entries page.';
                    }
                    action("Interaction Log Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Log Entries';
                        RunObject = page "Interaction Log Entries";
                        Tooltip = 'Open the Interaction Log Entries page.';
                    }
                }
            }
            group("Group13")
            {
                Caption = 'Inventory & Pricing';
                action("Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Items';
                    RunObject = page "Item List";
                    Tooltip = 'Open the Items page.';
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = page "Catalog Item List";
                    Tooltip = 'Open the Nonstock Items page.';
                }
                action("Item Attributes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attributes';
                    RunObject = page "Item Attributes";
                    Tooltip = 'Open the Item Attributes page.';
                }
                action("Sales Price Worksheet")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Price Worksheet';
                    RunPageView = where("Object Type" = const(Page), "Object ID" = const(7023)); // "Sales Price Worksheet";
                    RunObject = Page "Role Center Page Dispatcher";
                }
                action("Adjust Item Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Item Costs/Prices';
                    RunObject = report "Adjust Item Costs/Prices";
                    Tooltip = 'Run the Adjust Item Costs/Prices report.';
                }
                group("Group14")
                {
                    Caption = 'Reports';
                    action("Inventory - Sales Statistics")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Sales Statistics';
                        RunObject = report "Inventory - Sales Statistics";
                        Tooltip = 'Run the Inventory Sales Statistics report.';
                    }
                    action("Inventory Cost and Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Cost and Price List';
                        RunObject = report "Inventory Cost and Price List";
                        Tooltip = 'Run the Inventory Cost and Price List report.';
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                        Tooltip = 'Run the Item Charges - Specification report.';
                    }
                    action("Inventory - Customer Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Customer Sales';
                        RunObject = report "Inventory - Customer Sales";
                        Tooltip = 'Run the Inventory Customer Sales report.';
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = report "Catalog Item Sales";
                        Tooltip = 'Run the Nonstock Item Sales report.';
                    }
                    action("Inventory Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = report "Inventory Availability";
                        Tooltip = 'Run the Inventory Availability report.';
                    }
                    action("Inventory Order Details")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Order Details';
                        RunObject = report "Inventory Order Details";
                        Tooltip = 'Run the Inventory Order Details report.';
                    }
                    action("Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price List';
                        RunPageView = where("Object Type" = const(Report), "Object ID" = const(715)); // "Price List";
                        RunObject = Page "Role Center Page Dispatcher";
                    }
                    action("Inventory - Sales Back Orders")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Sales Back Orders';
                        RunObject = report "Inventory - Sales Back Orders";
                        Tooltip = 'Run the Inventory - Sales Back Orders report.';
                    }
                    action("Inventory - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Top 10 List';
                        RunObject = report "Inventory - Top 10 List";
                        Tooltip = 'Run the Inventory Top 10 List report.';
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                        Tooltip = 'Run the Item Substitutions report.';
                    }
                }
            }
            group("Group15")
            {
                Caption = 'Sales - Dataverse';
                action("Sales Order List - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Orders - Dynamics 365 Sales';
                    RunObject = page "CRM Sales Order List";
                    Tooltip = 'Open the Sales Orders - Dynamics 365 Sales page.';
                }
                action("Quotes - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes - Dynamics 365 Sales';
                    RunObject = page "CRM Sales Quote List";
                    Tooltip = 'Open the Quotes - Dynamics 365 Sales page.';
                }
                action("Cases - Dynamics 365 for Customer Service")
                {
                    ApplicationArea = Suite;
                    Caption = 'Cases - Dynamics 365 for Customer Service';
                    RunObject = page "CRM Case List";
                    Tooltip = 'Open the Cases - Dynamics 365 for Customer Service page.';
                }
                action("Opportunities - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunities - Dynamics 365 Sales';
                    RunObject = page "CRM Opportunity List";
                    Tooltip = 'Open the Opportunities - Dynamics 365 Sales page.';
                }
                action("Accounts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Accounts - Dynamics 365 Sales';
                    RunObject = page "CRM Account List";
                    Tooltip = 'Open the Accounts - Dynamics 365 Sales page.';
                }
                action("Transaction Currencies - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currencies - Dynamics 365 Sales';
                    RunObject = page "CRM TransactionCurrency List";
                    Tooltip = 'Open the Transaction Currencies - Dynamics 365 Sales page.';
                }
                action("Unit Groups - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit Groups - Dynamics 365 Sales';
                    RunObject = page "CRM UnitGroup List";
                    Tooltip = 'Open the Unit Groups - Dynamics 365 Sales page.';
                }
                action("Products - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Products - Dynamics 365 Sales';
                    RunObject = page "CRM Product List";
                    Tooltip = 'Open the Products - Dynamics 365 Sales page.';
                }
                action("Contacts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Contacts - Dynamics 365 Sales';
                    RunObject = page "CRM Contact List";
                    Tooltip = 'Open the Contacts - Dynamics 365 Sales page.';
                }
                action("Records Skipped For Synchronization")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    RunObject = page "CRM Skipped Records";
                    Tooltip = 'Open the Coupled Data Synchronization Errors page.';
                    AccessByPermission = TableData "CRM Integration Record" = R;
                }
            }
            group("Group16")
            {
                Caption = 'Setup';
                action("Order Promising Setup")
                {
                    ApplicationArea = OrderPromising;
                    Caption = 'Order Promising Setup';
                    RunObject = page "Order Promising Setup";
                    Tooltip = 'Open the Order Promising Setup page.';
                }
                action("Sales & Receivables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales & Receivables Setup';
                    RunObject = page "Sales & Receivables Setup";
                    Tooltip = 'Open the Sales & Receivables Setup page.';
                }
                action("report Selection Sales")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Sales';
                    RunObject = page "Report Selection - Sales";
                    Tooltip = 'Open the Report Selections Sales page.';
                }
                action("Standard Sales Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Sales Codes';
                    RunObject = page "Standard Sales Codes";
                    Tooltip = 'Open the Standard Sales Codes page.';
                }
                action("Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Terms';
                    RunObject = page "Payment Terms";
                    Tooltip = 'Open the Payment Terms page.';
                }
                action("Payment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Methods';
                    RunObject = page "Payment Methods";
                    Tooltip = 'Open the Payment Methods page.';
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Discount Groups';
                    RunObject = page "Item Disc. Groups";
                    Tooltip = 'Open the Item Discount Groups page.';
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = page "Shipment Methods";
                    Tooltip = 'Open the Shipment Methods page.';
                }
                action("Shipping Agents")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping Agents';
                    RunObject = page "Shipping Agents";
                    Tooltip = 'Open the Shipping Agents page.';
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = page "Return Reasons";
                    Tooltip = 'Open the Return Reasons page.';
                }
                action("Recurring Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recurring Groups';
                    RunObject = page "Recurring Group Overview";
                }
                action("Customer Templates")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customer Templates';
                    RunObject = page "Customer Templ. List";
                    Tooltip = 'Open the Customer Templates page.';
                }
                group("Group17")
                {
                    Caption = 'Sales Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Analysis Types';
                        RunObject = page "Analysis Types";
                        Tooltip = 'Open the Analysis Types page.';
                    }
                    action("Sales Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = page "Analysis View List Sales";
                        Tooltip = 'Open the Sales Analysis by Dimensions page.';
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Column Templates';
                        RunObject = report "Run Sales Analysis Col. Temp.";
                        Tooltip = 'Run the Sales Analysis Column Templates report.';
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Line Templates';
                        RunObject = report "Run Sales Analysis Line Templ.";
                        Tooltip = 'Run the Sales Analysis Line Templates report.';
                    }
                }
                group("Group18")
                {
                    Caption = 'Customer';
                    action("Customer Price Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Price Groups';
                        RunObject = page "Customer Price Groups";
                        Tooltip = 'Open the Customer Price Groups page.';
                    }
                    action("Customer Disc. Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Discount Groups';
                        RunObject = page "Customer Disc. Groups";
                        Tooltip = 'Open the Customer Discount Groups page.';
                    }
                }
                group("Group19")
                {
                    Caption = 'Item';
                    action("Nonstock Item Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Setup';
                        RunObject = page "Catalog Item Setup";
                        Tooltip = 'Open the Nonstock Item Setup page.';
                    }
                    action("Item Charges")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges';
                        RunObject = page "Item Charges";
                        Tooltip = 'Open the Item Charges page.';
                    }
                    action("Item Disc. Groups1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Discount Groups';
                        RunObject = page "Item Disc. Groups";
                        Tooltip = 'Open the Item Discount Groups page.';
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
                        Tooltip = 'Open the Inventory Setup page.';
                    }
                }
                group("Group20")
                {
                    Caption = 'Marketing';
                    action("Marketing Setup")
                    {
                        ApplicationArea = Basic, Suite, RelationshipMgmt;
                        Caption = 'Marketing Setup';
                        RunObject = page "Marketing Setup";
                        Tooltip = 'Open the Marketing Setup page.';
                    }
                    action("Interaction Template Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Template Setup';
                        RunObject = page "Interaction Template Setup";
                        Tooltip = 'Open the Interaction Template Setup page.';
                    }
                    action("Business Relations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Business Relations';
                        RunObject = page "Business Relations";
                        Tooltip = 'Open the Business Relations page.';
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        RunObject = page "Industry Groups";
                        Tooltip = 'Open the Industry Groups page.';
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        RunObject = page "Web Sources";
                        Tooltip = 'Open the Web Sources page.';
                    }
                    action("Job Responsibilities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Job Responsibilities';
                        RunObject = page "Job Responsibilities";
                        Tooltip = 'Open the Job Responsibilities page.';
                    }
                    action("Organizational Levels")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Organizational Levels';
                        RunObject = page "Organizational Levels";
                        Tooltip = 'Open the Organizational Levels page.';
                    }
                    action("Interaction Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Groups';
                        RunObject = page "Interaction Groups";
                        Tooltip = 'Open the Interaction Groups page.';
                    }
                    action("Interaction Templates")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Templates';
                        RunObject = page "Interaction Templates";
                        Tooltip = 'Open the Interaction Templates page.';
                    }
                    action("Salutations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Salutations';
                        RunObject = page "Salutations";
                        Tooltip = 'Open the Salutations page.';
                    }
                    action("Mailing Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Mailing Groups';
                        RunObject = page "Mailing Groups";
                        Tooltip = 'Open the Mailing Groups page.';
                    }
                    action("Status")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Status';
                        RunObject = page "Campaign Status";
                        Tooltip = 'Open the Campaign Status page.';
                    }
                    action("Sales Cycles")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycles';
                        RunObject = page "Sales Cycles";
                        Tooltip = 'Open the Sales Cycles page.';
                    }
                    action("Close Opportunity Codes")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Close Opportunity Codes';
                        RunObject = page "Close Opportunity Codes";
                        Tooltip = 'Open the Close Opportunity Codes page.';
                    }
                    action("Questionnaire Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Questionnaire Setup';
                        RunObject = page "Profile Questionnaires";
                        Tooltip = 'Open the Questionnaire Setup page.';
                    }
                    action("Activities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Activities';
                        RunObject = page "Activity List";
                        Tooltip = 'Open the Activities page.';
                    }
                }
            }
        }
    }
}
