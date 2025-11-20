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
using Microsoft.Foundation.Navigate;
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
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                }
                action("Salespeople")
                {
                    ApplicationArea = Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = page "Salespersons/Purchasers";
                }
                action("Teams")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Teams';
                    RunObject = page "Teams";
                }
                action("Tasks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = page "Tasks";
                }
                action("Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = page "Opportunity List";
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Sales Budgets")
                    {
                        ApplicationArea = SalesBudget;
                        Caption = 'Sales Budgets';
                        RunObject = page "Budget Names Sales";
                    }
                    action("Sales Analysis Reports")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Reports';
                        RunObject = page "Analysis Report Sale";
                    }
                    action("Sales Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = page "Analysis View List Sales";
                    }
                    action("Item Dimensions - Detail")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Detail';
                        RunObject = report "Item Dimensions - Detail";
                    }
                    action("Item Dimensions - Total")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Item Dimensions - Total';
                        RunObject = report "Item Dimensions - Total";
                    }
                    action("Opportunities Matrix")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Analysis';
                        RunObject = page "Opportunities";
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
                    }
                    group("Group3")
                    {
                        Caption = 'Salespeople/Teams';
                        action("Salesperson - Tasks")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Tasks';
                            RunObject = report "Salesperson - Tasks";
                        }
                        action("Salesperson - Commission")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Salesperson Commission';
                            RunObject = report "Salesperson - Commission";
                        }
                        action("Salesperson - Opportunities")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Opportunities';
                            RunObject = report "Salesperson - Opportunities";
                        }
                        action("Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Sales Statistics';
                            RunObject = report "Sales Statistics";
                        }
                        action("Team - Tasks")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Team Tasks';
                            RunObject = report "Team - Tasks";
                        }
                        action("Salesperson - Sales Statistics")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Salesperson Sales Statistics';
                            RunObject = report "Salesperson - Sales Statistics";
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
                        }
                        action("Contact - Company Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact - Company Summary';
                            RunObject = report "Contact - Company Summary";
                        }
                        action("Questionnaire - Handouts")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Questionnaire - Handouts';
                            RunObject = report "Questionnaire - Handouts";
                        }
                        action("Contact - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact List';
                            RunObject = report "Contact - List";
                        }
                        action("Orgl. Profile Summary")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Person Summary';
                            RunObject = report "Contact - Person Summary";
                        }
                        action("Contact - Cover Sheet")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Contact - Cover Sheet';
                            RunObject = report "Contact - Cover Sheet";
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
                        }
                        action("Customer - Labels")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Customer Labels';
                            RunObject = report "Customer - Labels";
                        }
                        action("Customer - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Balance to Date';
                            RunObject = report "Customer - Balance to Date";
                        }
                        action("Customer - Order Summary")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Summary';
                            RunObject = report "Customer - Order Summary";
                        }
                        action("Customer/Item Sales")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer/Item Sales';
                            RunObject = report "Customer/Item Sales";
                        }
                        action("Customer Register")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Register';
                            RunObject = report "Customer Register";
                        }
                        action("Customer - Order Detail")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Order Detail';
                            RunObject = report "Customer - Order Detail";
                        }
                        action("Customer - Top 10 List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Top 10 List';
                            RunObject = report "Customer - Top 10 List";
                        }
                        action("Customer - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer Trial Balance';
                            RunObject = report "Customer - Trial Balance";
                        }
                        action("Customer - Sales List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Customer - Sales List';
                            RunObject = report "Customer - Sales List";
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
                        }
                        action("Opportunity - Details")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Opportunity - Details';
                            RunObject = report "Opportunity - Details";
                        }
                        action("Sales Cycle - Analysis")
                        {
                            ApplicationArea = RelationshipMgmt;
                            Caption = 'Sales Cycle - Analysis';
                            RunObject = report "Sales Cycle - Analysis";
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
                }
                action("Contacts1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                }
                action("Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Quotes';
                    RunObject = page "Sales Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = page "Blanket Sales Orders";
                }
                action("Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    RunObject = page "Sales Return Order List";
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Invoices';
                    RunObject = page "Sales Invoice List";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Credit Memos';
                    RunObject = page "Sales Credit Memos";
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = page "Certificates of Supply";
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                }
                group("Group8")
                {
                    Caption = 'Posted Documents';
                    action("Posted Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Invoices';
                        RunObject = page "Posted Sales Invoices";
                    }
                    action("Posted Sales Shipments")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Shipments';
                        RunObject = page "Posted Sales Shipments";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Sales Credit Memos';
                        RunObject = page "Posted Sales Credit Memos";
                    }
                    action("Posted Return Receipts")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Posted Return Receipts';
                        RunObject = page "Posted Return Receipts";
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
                    }
                    action("Item Tracing")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Tracing';
                        RunObject = page "Item Tracing";
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
                    action("Customer Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Ledger Entries';
                        RunObject = page "Customer Ledger Entries";
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Customer Ledger Entries';
                        RunObject = page "Detailed Cust. Ledg. Entries";
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
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
                    }
                    action("Sales Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Sales Reservation Avail.';
                        RunObject = report "Sales Reservation Avail.";
                    }
                    action("Sales Statistics1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sales Statistics';
                        RunObject = report "Sales Statistics";
                    }
                    action("Customer - Sales List1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Sales List';
                        RunObject = report "Customer - Sales List";
                    }
                    action("EC Sales List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EC Sales List';
                        RunObject = report "EC Sales List";
                    }
                    action("Customer/Item Sales1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer/Item Sales';
                        RunObject = report "Customer/Item Sales";
                    }
                    action("Customer - Order Summary1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer - Order Summary';
                        RunObject = report "Customer - Order Summary";
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
                }
                action("Campaigns")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaigns';
                    RunObject = page "Campaign List";
                }
                action("Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segments';
                    RunObject = page "Segment List";
                }
                action("Logged Segments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Logged Segments';
                    RunObject = page "Logged Segments";
                }
                action("Opportunities1")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunities';
                    RunObject = page "Opportunity List";
                }
                action("Tasks1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tasks';
                    RunObject = page "Tasks";
                }
                action("Campaign - Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign - Details';
                    RunObject = report "Campaign - Details";
                }
                group("Group12")
                {
                    Caption = 'Registers/Entries';
                    action("Campaign Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Entries';
                        RunObject = page "Campaign Entries";
                    }
                    action("Opportunity Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Opportunity Entries';
                        RunObject = page "Opportunity Entries";
                    }
                    action("Interaction Log Entries")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Log Entries';
                        RunObject = page "Interaction Log Entries";
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
                }
                action("Nonstock Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Items';
                    RunObject = page "Catalog Item List";
                }
                action("Item Attributes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attributes';
                    RunObject = page "Item Attributes";
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
                }
                group("Group14")
                {
                    Caption = 'Reports';
                    action("Inventory - Sales Statistics")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Inventory Sales Statistics';
                        RunObject = report "Inventory - Sales Statistics";
                    }
                    action("Inventory Cost and Price List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Cost and Price List';
                        RunObject = report "Inventory Cost and Price List";
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                    }
                    action("Inventory - Customer Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Customer Sales';
                        RunObject = report "Inventory - Customer Sales";
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = report "Catalog Item Sales";
                    }
                    action("Inventory Availability")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Availability';
                        RunObject = report "Inventory Availability";
                    }
                    action("Inventory Order Details")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Order Details';
                        RunObject = report "Inventory Order Details";
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
                    }
                    action("Inventory - Top 10 List")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Top 10 List';
                        RunObject = report "Inventory - Top 10 List";
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
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
                }
                action("Quotes - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes - Dynamics 365 Sales';
                    RunObject = page "CRM Sales Quote List";
                }
                action("Cases - Dynamics 365 for Customer Service")
                {
                    ApplicationArea = Suite;
                    Caption = 'Cases - Dynamics 365 for Customer Service';
                    RunObject = page "CRM Case List";
                }
                action("Opportunities - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Opportunities - Dynamics 365 Sales';
                    RunObject = page "CRM Opportunity List";
                }
                action("Accounts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Accounts - Dynamics 365 Sales';
                    RunObject = page "CRM Account List";
                }
                action("Transaction Currencies - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Transaction Currencies - Dynamics 365 Sales';
                    RunObject = page "CRM TransactionCurrency List";
                }
                action("Unit Groups - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Unit Groups - Dynamics 365 Sales';
                    RunObject = page "CRM UnitGroup List";
                }
                action("Products - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Products - Dynamics 365 Sales';
                    RunObject = page "CRM Product List";
                }
                action("Contacts - Dynamics 365 for Sales")
                {
                    ApplicationArea = Suite;
                    Caption = 'Contacts - Dynamics 365 Sales';
                    RunObject = page "CRM Contact List";
                }
                action("Records Skipped For Synchronization")
                {
                    ApplicationArea = Suite;
                    Caption = 'Coupled Data Synchronization Errors';
                    RunObject = page "CRM Skipped Records";
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
                }
                action("Sales & Receivables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales & Receivables Setup';
                    RunObject = page "Sales & Receivables Setup";
                }
                action("report Selection Sales")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Sales';
                    RunObject = page "Report Selection - Sales";
                }
                action("Standard Sales Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Sales Codes';
                    RunObject = page "Standard Sales Codes";
                }
                action("Payment Terms")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Terms';
                    RunObject = page "Payment Terms";
                }
                action("Payment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Methods';
                    RunObject = page "Payment Methods";
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Discount Groups';
                    RunObject = page "Item Disc. Groups";
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = page "Shipment Methods";
                }
                action("Shipping Agents")
                {
                    ApplicationArea = Suite;
                    Caption = 'Shipping Agents';
                    RunObject = page "Shipping Agents";
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = page "Return Reasons";
                }
                action("Customer Templates")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Customer Templates';
                    RunObject = page "Customer Templ. List";
                }
                group("Group17")
                {
                    Caption = 'Sales Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Analysis Types';
                        RunObject = page "Analysis Types";
                    }
                    action("Sales Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, SalesAnalysis;
                        Caption = 'Sales Analysis by Dimensions';
                        RunObject = page "Analysis View List Sales";
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Column Templates';
                        RunObject = report "Run Sales Analysis Col. Temp.";
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = SalesAnalysis;
                        Caption = 'Sales Analysis Line Templates';
                        RunObject = report "Run Sales Analysis Line Templ.";
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
                    }
                    action("Customer Disc. Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Customer Discount Groups';
                        RunObject = page "Customer Disc. Groups";
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
                    }
                    action("Item Charges")
                    {
                        ApplicationArea = ItemCharges;
                        Caption = 'Item Charges';
                        RunObject = page "Item Charges";
                    }
                    action("Item Disc. Groups1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Discount Groups';
                        RunObject = page "Item Disc. Groups";
                    }
                    action("Inventory Setup")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Setup';
                        RunObject = page "Inventory Setup";
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
                    }
                    action("Interaction Template Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Template Setup';
                        RunObject = page "Interaction Template Setup";
                    }
                    action("Business Relations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Business Relations';
                        RunObject = page "Business Relations";
                    }
                    action("Industry Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Industry Groups';
                        RunObject = page "Industry Groups";
                    }
                    action("Web Sources")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Web Sources';
                        RunObject = page "Web Sources";
                    }
                    action("Job Responsibilities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Job Responsibilities';
                        RunObject = page "Job Responsibilities";
                    }
                    action("Organizational Levels")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Organizational Levels';
                        RunObject = page "Organizational Levels";
                    }
                    action("Interaction Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Groups';
                        RunObject = page "Interaction Groups";
                    }
                    action("Interaction Templates")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Templates';
                        RunObject = page "Interaction Templates";
                    }
                    action("Salutations")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Salutations';
                        RunObject = page "Salutations";
                    }
                    action("Mailing Groups")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Mailing Groups';
                        RunObject = page "Mailing Groups";
                    }
                    action("Status")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Campaign Status';
                        RunObject = page "Campaign Status";
                    }
                    action("Sales Cycles")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Sales Cycles';
                        RunObject = page "Sales Cycles";
                    }
                    action("Close Opportunity Codes")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Close Opportunity Codes';
                        RunObject = page "Close Opportunity Codes";
                    }
                    action("Questionnaire Setup")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Questionnaire Setup';
                        RunObject = page "Profile Questionnaires";
                    }
                    action("Activities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Activities';
                        RunObject = page "Activity List";
                    }
                }
            }
        }
    }
}
