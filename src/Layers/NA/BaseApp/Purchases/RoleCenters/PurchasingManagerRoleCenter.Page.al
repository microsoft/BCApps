// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
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
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Analysis;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.RoleCenters;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

page 8905 "Purchasing Manager Role Center"
{
    Caption = 'Purchasing Manager Role Center';
    PageType = RoleCenter;
    actions
    {
        area(Sections)
        {
            group("Group")
            {
                Caption = 'Purchasing';
                action("Vendors")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page "Vendor List";
                }
                action("Contacts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contacts';
                    RunObject = page "Contact List";
                }
                action("Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Quotes';
                    RunObject = page "Purchase Quotes";
                }
                action("Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Purchase Orders';
                    RunObject = page "Blanket Purchase Orders";
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    RunObject = page "Purchase Return Order List";
                }
                action("Transfer Orders")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                }
                action("Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Invoices';
                    RunObject = page "Purchase Invoices";
                }
                action("Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Credit Memos';
                    RunObject = page "Purchase Credit Memos";
                }
                action("Certificates of Supply")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificates of Supply';
                    RunObject = page "Certificates of Supply";
                }
                action("Purchase Journals")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Journals';
                    RunObject = page "Purchase Journal";
                }
                group("Group1")
                {
                    Caption = 'Budgets & Analysis';
                    action("Purchase Budgets")
                    {
                        ApplicationArea = PurchaseBudget;
                        Caption = 'Purchase Budgets';
                        RunObject = page "Budget Names Purchase";
                    }
                    action("Purchase Analysis Reports")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purchase Analysis Reports';
                        RunObject = page "Analysis Report Purchase";
                    }
                    action("Analysis by Dimensions")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = page "Analysis View List Purchase";
                    }
                    action("Purch. Order Perf. Analysis")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Analyze Purchase Orders';
                        Image = Purchase;
                        RunObject = query "Purch. Order Perf. Analysis";
                        ToolTip = 'Analyze (group, summarize, pivot) your Purchase Order performance against vendors and goods/services bought, including outstanding vs. posted quantities and amounts.';
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
                }
                group("Group2")
                {
                    Caption = 'Registers/Entries';
                    action("Purchase Quote Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Quote Archives';
                        RunObject = page "Purchase Quote Archives";
                    }
                    action("Purchase Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Order Archives';
                        RunObject = page "Purchase Order Archives";
                    }
                    action("Posted Purchase Invoices")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Invoices';
                        RunObject = page "Posted Purchase Invoices";
                    }
                    action("Posted Return Shipments")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Posted Purchase Return Shipments';
                        RunObject = page "Posted Return Shipments";
                    }
                    action("Posted Credit Memos")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posted Purchase Credit Memos';
                        RunObject = page "Posted Purchase Credit Memos";
                    }
                    action("Posted Purchase Receipts")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Posted Purchase Receipts';
                        RunObject = page "Posted Purchase Receipts";
                    }
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
                    action("Purchase Return Order Archives")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Return Order Archives';
                        RunObject = page "Purchase Return List Archive";
                    }
                    action("Vendor Ledger Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Ledger Entries';
                        RunObject = page "Vendor Ledger Entries";
                    }
                    action("Detailed Cust. Ledg. Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Vendor Ledger Entries';
                        RunObject = page "Detailed Vendor Ledg. Entries";
                    }
                    action("Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Value Entries';
                        RunObject = page "Value Entries";
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
                group("Group3")
                {
                    Caption = 'Reports';
                    action("Inventory Purchase Orders")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Advice';
                        RunObject = Report "Purchase Advice";
                    }
                    action("Inventory - Transaction Detail")
                    {
                        Caption = 'Inventory Transaction Detail';
                        RunObject = Report "Item Transaction Detail";
                    }
                    action("Inventory - Reorders")
                    {
                        Caption = 'Inventory Reorders';
                        RunObject = report "Inventory - Reorders";
                    }
                    action("Item/Vendor Catalog")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = Report "Item/Vendor Catalog";
                    }
                    action("Vendor - Summary Aging")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged Accounts Payable';
                        RunObject = Report "Aged Accounts Payable NA";
                    }
                    action("Vendor/Item Purchases")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Purchases by Item';
                        RunObject = Report "Vendor Purchases by Item";
                    }
                    action("List Price Sheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'List Price Sheet';
                        RunPageView = where("Object Type" = const(Report), "Object ID" = const(10148)); // "List Price Sheet"
                        RunObject = Page "Role Center Page Dispatcher";
                    }
                    action("Item Charges - Specification")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                    }
                    action("Inventory - Vendor Purchases")
                    {
                        Caption = 'Inventory - Vendor Purchases';
                        RunObject = Report "Vendor Purchases by Item";
                    }
                    action("Item Substitutions")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                    }
                    action("Inventory Purchase Orders1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Advice';
                        RunObject = Report "Purchase Advice";
                    }
                    action("Purchase Order Status")
                    {
                        Caption = 'Purchase Order Status';
                        RunObject = Report "Purchase Order Status";
                    }
                    // action("Order")
                    // {
                    //     ApplicationArea = Suite;
                    //     Caption = 'Order';
                    //     RunObject = codeunit 8815;
                    // }
                    action("Purchasing Deferral Summary")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchasing Deferral Summary';
                        RunObject = report "Deferral Summary - Purchasing";
                    }
                }
            }
            group("Group4")
            {
                Caption = 'Planning';
                action("Items")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Items';
                    RunObject = page "Item List";
                }
                action("Vendors1")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendors';
                    RunObject = page "Vendor List";
                }
                action("Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    RunObject = page "Purchase Order List";
                }
                action("Orders2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    RunObject = page "Sales Order List";
                }
                action("Blanket Orders1")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Sales Orders';
                    RunObject = page "Blanket Sales Orders";
                }
                action("Assembly Orders")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Assembly Orders';
                    RunObject = page "Assembly Orders";
                }
                action("Jobs")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Projects';
                    RunObject = page "Job List";
                }
                action("Transfer Orders1")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Orders';
                    RunObject = page "Transfer Orders";
                }
                action("Requisition Worksheets")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = page "Req. Worksheet";
                }
                action("Recurring Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Recurring Requisition Worksheets';
                    RunObject = page "Recurring Req. Worksheet";
                }
                action("Order Planning")
                {
                    ApplicationArea = Planning;
                    Caption = 'Order Planning';
                    RunObject = page "Order Planning";
                }
                group("Group5")
                {
                    Caption = 'Reports';
                    action("Purchase Reservation Avail.")
                    {
                        ApplicationArea = Reservation;
                        Caption = 'Purchase Reservation Avail.';
                        RunObject = report "Purchase Reservation Avail.";
                    }
                    action("Nonstock Item Sales")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nonstock Item Sales';
                        RunObject = report "Catalog Item Sales";
                    }
                    action("Item/Vendor Catalog1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item/Vendor Catalog';
                        RunObject = Report "Item/Vendor Catalog";
                    }
                    action("Purchase Statistics")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendor Purchase Statistics';
                        RunObject = Report "Vendor Purchase Statistics";
                    }
                    action("Item Substitutions1")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Item Substitutions';
                        RunObject = report "Item Substitutions";
                    }
                    group("Group6")
                    {
                        Caption = 'Vendor';
                        action("Vendor - Balance to Date")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Balance to Date';
                            RunObject = report "Vendor - Balance to Date";
                        }
                        action("Vendor/Item Purchases1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Purchases by Item';
                            RunObject = Report "Vendor Purchases by Item";
                        }
                        action("Vendor - Purchase List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Purchase List';
                            RunObject = report "Vendor - Purchase List";
                        }
                        action("Vendor - Trial Balance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Trial Balance';
                            RunObject = report "Vendor - Trial Balance";
                        }
                        action("Vendor - Top 10 List")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Top __ Vendor List';
                            RunObject = Report "Top __ Vendor List";
                        }
                        action("Vendor - List")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor - Listing';
                            RunObject = Report "Vendor - Listing";
                        }
                        action("Vendor - Summary Aging1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Aged Accounts Payable';
                            RunObject = Report "Aged Accounts Payable NA";
                        }
                        action("Purchase Statistics1")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Vendor Purchase Statistics';
                            RunObject = Report "Vendor Purchase Statistics";
                        }
                    }
                    group("Group7")
                    {
                        Caption = 'Inventory';
                        action("Inventory - Cost Variance")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Cost Variance';
                            RunObject = report "Inventory - Cost Variance";
                        }
                        action("Inventory - Vendor Purchases1")
                        {
                            Caption = 'Inventory - Vendor Purchases';
                            RunObject = Report "Vendor Purchases by Item";
                        }
                        action("Inventory - Availability Plan")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Availability Plan';
                            RunObject = report "Inventory - Availability Plan";
                        }
                        action("Inventory Purchase Orders2")
                        {
                            ApplicationArea = Suite;
                            Caption = 'Purchase Advice';
                            RunObject = Report "Purchase Advice";
                        }
                        action("Inventory - Inbound Transfer")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Inventory - Inbound Transfer';
                            RunObject = report "Inventory - Inbound Transfer";
                        }
                    }
                }
            }
            group("Group8")
            {
                Caption = 'Inventory & Costing';
                action("Items1")
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
                action("Stock keeping Units")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Stockkeeping Units';
                    RunObject = page "Stockkeeping Unit List";
                }
                action("Adjust Cost - Item Entries...")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Cost Item Entries';
                    RunObject = report "Adjust Cost - Item Entries";
                }
                action("Standard Costs Worksheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Standard Costs Worksheet';
                    RunObject = page Microsoft.Manufacturing.StandardCost."Standard Cost Worksheet";
                }
                action("Adjust Item Costs/Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Item Costs/Prices';
                    RunObject = report "Adjust Item Costs/Prices";
                }
                group("Group9")
                {
                    Caption = 'Journals';
                    action("Item Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Journals';
                        RunObject = page "Item Journal";
                    }
                    action("Item Reclass. Journals")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Reclassification Journals';
                        RunObject = page "Item Reclass. Journal";
                    }
                    action("Recurring Item Journals")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Recurring Item Journals';
                        RunObject = page "Recurring Item Jnl.";
                    }
                }
                group("Group10")
                {
                    Caption = 'Reports';
                    action("Inventory Valuation")
                    {
                        Caption = 'Inventory Valuation';
                        RunObject = Report "Inventory Valuation";
                    }
                    action("Item Cost and Price List")
                    {
                        Caption = 'Item Cost and Price List';
                        RunObject = Report "Item Cost and Price List";
                    }
                    action("Item Age Composition - Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Qty.';
                        RunObject = report "Item Age Composition - Qty.";
                    }
                    action("Inventory - Cost Variance1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Cost Variance';
                        RunObject = report "Inventory - Cost Variance";
                    }
                    action("Item Charges - Specification1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Charges - Specification';
                        RunObject = report "Item Charges - Specification";
                    }
                    action("Inventory - Inbound Transfer1")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory - Inbound Transfer';
                        RunObject = report "Inventory - Inbound Transfer";
                    }
                    action("Invt. Valuation - Cost Spec.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invt. Valuation - Cost Spec.';
                        RunObject = report "Invt. Valuation - Cost Spec.";
                    }
                    action("Item Age Composition - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Age Composition - Value';
                        RunObject = report "Item Age Composition - Value";
                    }
                    action("Item Register - Value")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Register - Value';
                        RunObject = report "Item Register - Value";
                    }
                    action("Item Expiration - Quantity")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item Expiration - Quantity';
                        RunObject = report "Item Expiration - Quantity";
                    }
                    action("Item Turnover")
                    {
                        Caption = 'Item Turnover';
                        RunObject = Report "Item Turnover";
                    }
                    action("Over Stock")
                    {
                        Caption = 'Over Stock';
                        RunObject = Report "Over Stock";
                    }
                    action("Inventory Purchase Orders3")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Purchase Advice';
                        RunObject = Report "Purchase Advice";
                    }
                    action("Purchase Order Status1")
                    {
                        Caption = 'Purchase Order Status';
                        RunObject = Report "Purchase Order Status";
                    }
                    action("Serial Number Status/Aging")
                    {
                        Caption = 'Serial Number Status/Aging';
                        RunObject = Report "Serial Number Status/Aging";
                    }
                }
            }
            group("Group11")
            {
                Caption = 'Setup';
                action("Purchases & Payables Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases & Payables Setup';
                    RunObject = page "Purchases & Payables Setup";
                }
                action("Standard Purchase Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Standard Purchase Codes';
                    RunObject = page "Standard Purchase Codes";
                }
                action("Purchasing Codes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchasing Codes';
                    RunObject = page "Purchasing Codes";
                }
                action("Shipment Methods")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Methods';
                    RunObject = page "Shipment Methods";
                }
                action("Return Reasons")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Reasons';
                    RunObject = page "Return Reasons";
                }
                action("Report Selection Purchase")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Selections Purchase';
                    RunObject = page "Report Selection - Purchase";
                }
                action("Req. Worksheet")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheet Templates';
                    RunObject = page "Req. Worksheet Templates";
                }
                action("Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Units of Measure';
                    RunObject = page "Units of Measure";
                }
                action("Manufacturers")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Manufacturers';
                    RunObject = page "Manufacturers";
                }
                action("Nonstock Item Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Nonstock Item Setup';
                    RunObject = page "Catalog Item Setup";
                }
                action("Item Journal Templates")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Journal Templates';
                    RunObject = page "Item Journal Templates";
                }
                action("Salespeople")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Salespeople/Purchasers';
                    RunObject = page "Salespersons/Purchasers";
                }
                action("Item Disc. Groups")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Discount Groups';
                    RunObject = page "Item Disc. Groups";
                }
                action("Item Tracking Codes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Tracking Codes';
                    RunObject = page "Item Tracking Codes";
                }
                action("Inventory Setup")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Inventory Setup';
                    RunObject = page "Inventory Setup";
                }
                action("Requisition Worksheets1")
                {
                    ApplicationArea = Planning;
                    Caption = 'Requisition Worksheets';
                    RunObject = page "Req. Worksheet";
                }
                group("Group12")
                {
                    Caption = 'Purchase Analysis';
                    action("Analysis Types")
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Analysis Types';
                        RunObject = page "Analysis Types";
                    }
                    action("Analysis by Dimensions1")
                    {
                        ApplicationArea = Dimensions, PurchaseAnalysis;
                        Caption = 'Purchase Analysis by Dimensions';
                        RunObject = page "Analysis View List Purchase";
                    }
                    action("Analysis Column Templates")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purch. Analysis Column Templates';
                        RunObject = report "Run Purch. Analysis Col. Temp.";
                    }
                    action("Analysis Line Templates")
                    {
                        ApplicationArea = PurchaseAnalysis;
                        Caption = 'Purch. Analysis Line Templates';
                        RunObject = report "Run Purch. Analysis Line Temp.";
                    }
                }
            }
        }
    }
}
